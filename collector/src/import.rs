//! Archive → MariaDB. Rejouable, idempotent.
//!
//! La base n'est qu'un index dérivé : tout ce qu'elle contient peut être
//! reconstruit depuis l'archive. C'est ce qui rend le choix du moteur peu
//! risqué, et ce qui permet de tout recalculer après un changement de
//! calibration.

use std::collections::HashMap;
use std::path::{Path, PathBuf};
use std::time::Duration;

use anyhow::{Context, Result};
use mysql::prelude::*;
use mysql::{Conn, Opts, TxOpts};

use crate::frame::LigneArchive;

pub struct Options {
    pub data_dir: PathBuf,
    pub db_url: String,
    pub follow: bool,
    pub interval: u64,
    pub rejouer: bool,
}

pub fn executer(o: &Options) -> Result<()> {
    let mut conn = Conn::new(Opts::from_url(&o.db_url).context("URL de base invalide")?)
        .context("connexion à la base")?;
    eprintln!("import : {} -> base", o.data_dir.display());

    if o.rejouer {
        // On efface les repères, pas les données : l'unicité de
        // (source_file, source_line) fera le reste, chaque ligne déjà connue
        // sera simplement ignorée.
        conn.query_drop("DELETE FROM import_state")?;
        eprintln!("repères d'avancement effacés : relecture complète de l'archive");
    }

    loop {
        let conventions = charger_conventions(&mut conn)?;
        let mut total = 0usize;

        for fichier in fichiers_archive(&o.data_dir)? {
            let relatif = relatif(&o.data_dir, &fichier);
            total += importer_fichier(&mut conn, &fichier, &relatif, &conventions)
                .with_context(|| format!("import de {relatif}"))?;
        }

        if total > 0 {
            eprintln!("{total} trames importées");
        }
        if !o.follow {
            return Ok(());
        }
        std::thread::sleep(Duration::from_secs(o.interval));
    }
}

// ---------------------------------------------------------------------------
// Conventions de nommage des voies
// ---------------------------------------------------------------------------

/// Préfixes triés du plus long au plus court, pour que le plus spécifique
/// l'emporte : `soiltemp-` doit gagner contre `soil-`.
type Conventions = Vec<(String, String, String)>;

fn charger_conventions(conn: &mut Conn) -> Result<Conventions> {
    let mut c: Conventions = conn.query_map(
        "SELECT prefix, measurement_type, unit FROM channel_convention",
        |(p, t, u)| (p, t, u),
    )?;
    c.sort_by_key(|(p, _, _)| std::cmp::Reverse(p.len()));
    Ok(c)
}

fn resoudre<'a>(conventions: &'a Conventions, canal: &str) -> Option<(&'a str, &'a str)> {
    conventions
        .iter()
        .find(|(p, _, _)| canal.starts_with(p.as_str()))
        .map(|(_, t, u)| (t.as_str(), u.as_str()))
}

// ---------------------------------------------------------------------------
// Parcours de l'archive
// ---------------------------------------------------------------------------

fn fichiers_archive(racine: &Path) -> Result<Vec<PathBuf>> {
    let mut out = Vec::new();
    if !racine.exists() {
        return Ok(out);
    }
    for mois in std::fs::read_dir(racine)? {
        let mois = mois?.path();
        if !mois.is_dir() {
            continue;
        }
        for f in std::fs::read_dir(&mois)? {
            let f = f?.path();
            if f.extension().is_some_and(|e| e == "ndjson") {
                out.push(f);
            }
        }
    }
    out.sort();
    Ok(out)
}

fn relatif(racine: &Path, fichier: &Path) -> String {
    fichier
        .strip_prefix(racine)
        .unwrap_or(fichier)
        .to_string_lossy()
        .into_owned()
}

// ---------------------------------------------------------------------------
// Import d'un fichier
// ---------------------------------------------------------------------------

fn importer_fichier(
    conn: &mut Conn,
    fichier: &Path,
    relatif: &str,
    conventions: &Conventions,
) -> Result<usize> {
    let deja: Option<u32> = conn.exec_first(
        "SELECT last_line FROM import_state WHERE source_file = ?",
        (relatif,),
    )?;
    let deja = deja.unwrap_or(0) as usize;

    let contenu = std::fs::read_to_string(fichier)?;
    let lignes: Vec<&str> = contenu.lines().collect();
    if lignes.len() <= deja {
        return Ok(0);
    }

    let mut noeuds: HashMap<String, u32> = HashMap::new();
    let mut tx = conn.start_transaction(TxOpts::default())?;
    let mut importees = 0usize;
    let mut derniere = deja;

    for (i, ligne) in lignes.iter().enumerate().skip(deja) {
        let numero = i + 1;
        derniere = numero;

        if ligne.trim().is_empty() {
            continue;
        }

        let l: LigneArchive = match serde_json::from_str(ligne) {
            Ok(l) => l,
            Err(e) => {
                // Une ligne illisible ne doit pas bloquer le reste de
                // l'archive : on la signale et on avance. Elle reste dans le
                // fichier, donc récupérable si on veut y revenir.
                eprintln!("{relatif}:{numero} ignorée ({e})");
                continue;
            }
        };

        let node_id = match noeuds.get(&l.frame.node) {
            Some(id) => *id,
            None => {
                let id = id_du_noeud(&mut tx, &l.frame.node)?;
                noeuds.insert(l.frame.node.clone(), id);
                id
            }
        };

        let recu = l.received_at.format("%Y-%m-%d %H:%M:%S%.3f").to_string();

        tx.exec_drop(
            "INSERT INTO frame (node_id, seq, received_at, rssi_dbm, snr_db,
                                source_file, source_line)
             VALUES (?, ?, ?, ?, ?, ?, ?)
             ON DUPLICATE KEY UPDATE id = id",
            (node_id, l.frame.seq, &recu, l.rssi, l.snr, relatif, numero as u32),
        )?;

        let frame_id: Option<u64> = tx.exec_first(
            "SELECT id FROM frame WHERE source_file = ? AND source_line = ?",
            (relatif, numero as u32),
        )?;
        let Some(frame_id) = frame_id else { continue };

        let mut mesures: Vec<(u64, &str, &str, f64, &str)> = Vec::new();
        for (canal, valeur) in &l.frame.sensors {
            match resoudre(conventions, canal) {
                Some((t, u)) => mesures.push((frame_id, canal, t, *valeur, u)),
                None => eprintln!(
                    "{relatif}:{numero} voie inconnue « {canal} » — \
                     ajouter un préfixe dans channel_convention"
                ),
            }
        }
        // La batterie est une mesure comme une autre : le modèle est générique.
        if let Some(v) = l.frame.battery {
            if let Some((t, u)) = resoudre(conventions, "battery") {
                mesures.push((frame_id, "battery", t, v, u));
            }
        }

        tx.exec_batch(
            "INSERT INTO measurement (frame_id, channel, measurement_type, value, unit)
             VALUES (?, ?, ?, ?, ?)
             ON DUPLICATE KEY UPDATE value = VALUES(value)",
            mesures,
        )?;

        importees += 1;
    }

    tx.exec_drop(
        "INSERT INTO import_state (source_file, last_line) VALUES (?, ?)
         ON DUPLICATE KEY UPDATE last_line = VALUES(last_line)",
        (relatif, derniere as u32),
    )?;
    tx.commit()?;

    Ok(importees)
}

/// Rend l'identifiant du nœud, en le créant s'il est inconnu.
///
/// Créer plutôt que refuser : une trame ne doit jamais être perdue parce que
/// le matériel n'a pas encore été déclaré. Le nœud apparaît alors avec un
/// libellé explicite, et `v_current_wiring` montrera ses voies sans sonde
/// attachée — ce qui est le rappel qu'il reste à le déclarer.
fn id_du_noeud<C: Queryable>(conn: &mut C, uid: &str) -> Result<u32> {
    if let Some(id) = conn.exec_first("SELECT id FROM node WHERE uid = ?", (uid,))? {
        return Ok(id);
    }
    eprintln!("nœud « {uid} » inconnu : créé automatiquement, à déclarer");
    conn.exec_drop(
        "INSERT INTO node (uid, label) VALUES (?, ?)",
        (uid, format!("{uid} (non déclaré)")),
    )?;
    conn.exec_first("SELECT id FROM node WHERE uid = ?", (uid,))?
        .context("nœud introuvable après insertion")
}
