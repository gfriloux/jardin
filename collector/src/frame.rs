//! Les trames, et rien d'autre.
//!
//! Deux formes, correspondant à deux points de la chaîne :
//!
//! - ce que la passerelle écrit sur la liaison série ;
//! - ce que le collecteur écrit dans l'archive, c'est-à-dire la même chose
//!   précédée d'un horodatage de réception.
//!
//! Le collecteur traite la première **sans la comprendre** : il valide que
//! c'est du JSON, en extrait le nom du nœud pour choisir le fichier, et
//! recopie le reste tel quel. C'est délibéré — le jour où le firmware ajoute
//! un champ, il traverse l'archive intact au lieu d'être silencieusement
//! perdu.
//!
//! L'importeur, lui, doit comprendre : il utilise les types de ce module.

use std::collections::BTreeMap;

use anyhow::{bail, Context, Result};
use chrono::{DateTime, SecondsFormat, Utc};
use serde::Deserialize;
use serde_json::{Map, Value};

/// Ce que le nœud a émis.
#[derive(Debug, Deserialize)]
pub struct Trame {
    pub node: String,
    pub seq: Option<u32>,
    pub battery: Option<f64>,
    #[serde(default)]
    pub sensors: BTreeMap<String, f64>,
}

/// Une ligne de l'archive NDJSON.
#[derive(Debug, Deserialize)]
pub struct LigneArchive {
    pub received_at: DateTime<Utc>,
    pub rssi: Option<i32>,
    pub snr: Option<f64>,
    pub frame: Trame,
}

/// Rend le nom d'un nœud utilisable comme nom de fichier.
///
/// Le nœud contrôle cette chaîne, et elle sert à construire un chemin. Sans
/// filtrage, une trame malformée — ou malveillante — annonçant
/// `"node": "../../etc/cron.d/x"` ferait écrire le collecteur hors de son
/// répertoire. On ne garde que ce qui est manifestement sûr.
pub fn nom_de_fichier_sur(node: &str) -> Result<String> {
    let propre: String = node
        .chars()
        .filter(|c| c.is_ascii_alphanumeric() || *c == '-' || *c == '_')
        .take(64)
        .collect();

    if propre.is_empty() {
        bail!("nom de nœud inutilisable : {node:?}");
    }
    Ok(propre)
}

/// Transforme une ligne de passerelle en ligne d'archive.
///
/// Rend le nom du nœud (pour le routage) et la ligne à écrire. Les champs
/// d'origine sont recopiés sans être interprétés ; seul `received_at` est
/// ajouté, en tête.
pub fn vers_archive(brut: &str, recu: DateTime<Utc>) -> Result<(String, String)> {
    let valeur: Value = serde_json::from_str(brut).context("ligne non JSON")?;

    let objet = valeur
        .as_object()
        .context("la ligne n'est pas un objet JSON")?;

    let node = objet
        .get("frame")
        .and_then(|f| f.get("node"))
        .and_then(|n| n.as_str())
        .context("champ frame.node absent")?;

    let node = nom_de_fichier_sur(node)?;

    let mut sortie = Map::with_capacity(objet.len() + 1);
    sortie.insert(
        "received_at".to_string(),
        Value::String(recu.to_rfc3339_opts(SecondsFormat::Millis, true)),
    );
    for (cle, val) in objet {
        if cle != "received_at" {
            sortie.insert(cle.clone(), val.clone());
        }
    }

    Ok((node, serde_json::to_string(&Value::Object(sortie))?))
}

#[cfg(test)]
mod tests {
    use super::*;

    fn instant() -> DateTime<Utc> {
        "2026-08-20T12:00:00.123Z".parse().unwrap()
    }

    #[test]
    fn recopie_les_champs_sans_les_interpreter() {
        let brut = r#"{"rssi":-91,"snr":9.5,"frame":{"node":"NODE-001","seq":182,"sensors":{"soil-01":1834}}}"#;
        let (node, ligne) = vers_archive(brut, instant()).unwrap();

        assert_eq!(node, "NODE-001");
        assert!(ligne.starts_with(r#"{"received_at":"2026-08-20T12:00:00.123Z""#));
        // Les entiers restent entiers : pas de 1834.0 dans l'archive.
        assert!(ligne.contains(r#""soil-01":1834"#));
    }

    #[test]
    fn laisse_passer_un_champ_inconnu() {
        // Le jour où le firmware ajoute quelque chose, ça ne doit pas se perdre.
        let brut = r#"{"rssi":-91,"frame":{"node":"N1","firmware":"0.4.2"}}"#;
        let (_, ligne) = vers_archive(brut, instant()).unwrap();
        assert!(ligne.contains(r#""firmware":"0.4.2""#));
    }

    #[test]
    fn refuse_une_ligne_sans_noeud() {
        assert!(vers_archive(r#"{"rssi":-91}"#, instant()).is_err());
    }

    #[test]
    fn refuse_le_bruit_de_demarrage() {
        assert!(vers_archive("ets Jul 29 2019 12:21:46", instant()).is_err());
        assert!(vers_archive("", instant()).is_err());
    }

    #[test]
    fn neutralise_une_traversee_de_repertoire() {
        assert_eq!(nom_de_fichier_sur("../../etc/passwd").unwrap(), "etcpasswd");
        assert_eq!(nom_de_fichier_sur("NODE-001").unwrap(), "NODE-001");
        assert!(nom_de_fichier_sur("../..").is_err());
        assert!(nom_de_fichier_sur("").is_err());
    }
}
