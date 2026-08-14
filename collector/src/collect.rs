//! Série → archive. Ne connaît ni SQL ni MQTT : sait écrire des lignes.

use std::collections::HashMap;
use std::fs::{File, OpenOptions};
use std::io::{BufRead, BufReader, Write};
use std::path::{Path, PathBuf};
use std::time::Duration;

use anyhow::{Context, Result};
use chrono::Utc;

use crate::frame;

/// Réouvre le port après une coupure. Une carte débranchée puis rebranchée ne
/// doit pas demander d'intervention.
const ATTENTE_RECONNEXION: Duration = Duration::from_secs(5);

pub fn executer(port: &Path, baud: u32, data_dir: &Path) -> Result<()> {
    eprintln!("collecte : {} @ {baud} bauds -> {}", port.display(), data_dir.display());

    let mut archive = Archive::new(data_dir.to_path_buf());

    loop {
        match lire_jusqua_coupure(port, baud, &mut archive) {
            Ok(()) => eprintln!("port fermé, réouverture dans {ATTENTE_RECONNEXION:?}"),
            Err(e) => eprintln!("erreur sur {} : {e:#}", port.display()),
        }
        std::thread::sleep(ATTENTE_RECONNEXION);
    }
}

fn lire_jusqua_coupure(port: &Path, baud: u32, archive: &mut Archive) -> Result<()> {
    let serie = serialport::new(port.to_string_lossy(), baud)
        .timeout(Duration::from_secs(3600))
        .open()
        .with_context(|| format!("ouverture de {}", port.display()))?;

    eprintln!("port ouvert");
    let mut lecteur = BufReader::new(serie);
    let mut ligne = Vec::new();

    loop {
        ligne.clear();
        // read_until plutôt que lines() : une trame tronquée ou un octet non
        // UTF-8 ne doit pas interrompre la collecte.
        let n = lecteur.read_until(b'\n', &mut ligne)?;
        if n == 0 {
            return Ok(()); // fin de flux : la carte a été débranchée
        }

        let brut = String::from_utf8_lossy(&ligne);
        let brut = brut.trim();
        if brut.is_empty() {
            continue;
        }

        match frame::vers_archive(brut, Utc::now()) {
            Ok((node, sortie)) => archive.ecrire(&node, &sortie)?,
            Err(e) => {
                // Bruit de démarrage de la carte, trame tronquée : on le note
                // et on continue. Ce n'est pas une erreur de la collecte.
                eprintln!("ignorée ({e}) : {}", tronquer(brut, 100));
            }
        }
    }
}

fn tronquer(s: &str, n: usize) -> String {
    if s.chars().count() <= n {
        s.to_string()
    } else {
        format!("{}…", s.chars().take(n).collect::<String>())
    }
}

/// Les fichiers de l'archive, un par nœud et par mois, ouverts en ajout.
struct Archive {
    racine: PathBuf,
    ouverts: HashMap<PathBuf, File>,
}

impl Archive {
    fn new(racine: PathBuf) -> Self {
        Self { racine, ouverts: HashMap::new() }
    }

    fn ecrire(&mut self, node: &str, ligne: &str) -> Result<()> {
        let mois = Utc::now().format("%Y-%m").to_string();
        let chemin = self.racine.join(&mois).join(format!("{node}.ndjson"));

        if !self.ouverts.contains_key(&chemin) {
            if let Some(parent) = chemin.parent() {
                std::fs::create_dir_all(parent)
                    .with_context(|| format!("création de {}", parent.display()))?;
            }
            let f = OpenOptions::new()
                .create(true)
                .append(true)
                .open(&chemin)
                .with_context(|| format!("ouverture de {}", chemin.display()))?;
            eprintln!("archive : {}", chemin.display());
            self.ouverts.insert(chemin.clone(), f);
        }

        let f = self.ouverts.get_mut(&chemin).expect("inséré juste au-dessus");
        writeln!(f, "{ligne}")?;
        // Vidage à chaque ligne : une coupure de courant ne doit pas coûter les
        // mesures encore en tampon. Le débit est de quelques lignes par minute,
        // le coût est nul.
        f.flush()?;
        Ok(())
    }
}
