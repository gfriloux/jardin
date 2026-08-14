//! Collecteur du projet jardin.
//!
//! Un binaire, deux sous-commandes, deux responsabilités qui ne se mélangent
//! jamais :
//!
//! ```text
//! GATEWAY-001 --serie--> collect --> archive NDJSON --> import --> MariaDB
//!                                    (source de verite)
//! ```
//!
//! `collect` ne connaît pas SQL. `import` ne connaît pas le port série. La
//! seule chose qui les relie est un répertoire de fichiers texte, et c'est
//! délibéré : l'archive survit à tout le reste.

mod collect;
mod frame;
mod import;

use std::path::PathBuf;

use anyhow::Result;
use clap::{Parser, Subcommand};

#[derive(Parser)]
#[command(name = "jardin", version, about = "Collecteur du réseau de télémétrie du jardin")]
struct Cli {
    #[command(subcommand)]
    commande: Commande,
}

#[derive(Subcommand)]
enum Commande {
    /// Lit la passerelle et écrit l'archive. Tourne indéfiniment.
    Collect {
        /// Port série de la passerelle.
        #[arg(long, env = "JARDIN_SERIAL_PORT", default_value = "/dev/jardin-gateway")]
        port: PathBuf,

        #[arg(long, env = "JARDIN_BAUD", default_value_t = 115_200)]
        baud: u32,

        /// Racine de l'archive NDJSON.
        #[arg(long, env = "JARDIN_DATA_DIR", default_value = "data")]
        data_dir: PathBuf,
    },

    /// Relit l'archive et alimente MariaDB. Rejouer est sans effet de bord.
    Import {
        #[arg(long, env = "JARDIN_DATA_DIR", default_value = "data")]
        data_dir: PathBuf,

        /// mysql://utilisateur:motdepasse@hôte:3306/jardin
        #[arg(long, env = "JARDIN_DB_URL")]
        db_url: String,

        /// Reste à l'écoute des nouvelles lignes au lieu de s'arrêter.
        #[arg(long)]
        follow: bool,

        /// Secondes entre deux passages, avec --follow.
        #[arg(long, default_value_t = 30)]
        interval: u64,

        /// Oublie l'avancement et relit toute l'archive. Les lignes déjà
        /// connues sont ignorées : c'est sans risque.
        #[arg(long)]
        rejouer: bool,
    },
}

fn main() -> Result<()> {
    let cli = Cli::parse();

    match cli.commande {
        Commande::Collect { port, baud, data_dir } => collect::executer(&port, baud, &data_dir),
        Commande::Import { data_dir, db_url, follow, interval, rejouer } => {
            import::executer(&import::Options { data_dir, db_url, follow, interval, rejouer })
        }
    }
}
