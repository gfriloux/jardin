# jardin — tâches courantes.
# Tout est prévu pour tourner dans `nix develop`.

set shell := ["bash", "-euo", "pipefail", "-c"]

docs := "docs"

# Liste les tâches disponibles.
default:
    @just --list --unsorted

# ─── Documentation ──────────────────────────────────────────────────────────

# Serveur de développement, avec rechargement à chaud.
dev: _docs-deps
    cd {{ docs }} && npm run dev

# Construit le site statique dans docs/dist.
build: _docs-deps
    cd {{ docs }} && npm run build

# Sert le site construit, tel qu'il sera publié.
preview: build
    cd {{ docs }} && npm run preview

# Vérifie le typage et les références de contenu Astro.
check: _docs-deps
    cd {{ docs }} && npm run check

# Vérifie les liens internes et les ancres du site construit.
links: build
    cd {{ docs }} && node scripts/check-links.mjs

# Typage + build + liens : à passer avant de committer.
ci: check links

# (Ré)installe les dépendances de la doc.
install:
    cd {{ docs }} && npm install --no-audit --no-fund

# Met à jour les dépendances npm de la doc.
update:
    cd {{ docs }} && npm update

# Supprime le site construit et les caches Astro.
clean:
    rm -rf {{ docs }}/dist {{ docs }}/.astro

# ─── Firmware ───────────────────────────────────────────────────────────────

# Liste les croquis disponibles, dans l'ordre où les faire.
fw-list:
    @sed -n 's/^\[env:\(.*\)\]/  \1/p' firmware/platformio.ini

# Liste les cartes détectées sur les ports USB.
fw-ports:
    pio device list

# Compile, téléverse et ouvre le moniteur série (ex : just fw 01-blink).
fw croquis:
    cd firmware && pio run -e {{ croquis }} -t upload && pio device monitor -e {{ croquis }}

# Compile un croquis sans le téléverser (ex : just fw-build 03-radio).
fw-build croquis:
    cd firmware && pio run -e {{ croquis }}

# Ouvre le moniteur série sans recompiler (ex : just fw-monitor 04-sonde).
fw-monitor croquis:
    cd firmware && pio device monitor -e {{ croquis }}

# Compile tous les croquis. Ne nécessite aucune carte branchée.
fw-check:
    cd firmware && pio run

# Supprime les objets de compilation du firmware.
fw-clean:
    rm -rf firmware/.pio

# ─── Coque des sondes ───────────────────────────────────────────────────────

# Génère les STL des deux coquilles dans hardware/coque/build/.
coque-stl:
    mkdir -p hardware/coque/build
    openscad -o hardware/coque/build/coque-avant.stl -D 'piece="avant"' hardware/coque/coque.scad
    openscad -o hardware/coque/build/coque-arriere.stl -D 'piece="arriere"' hardware/coque/coque.scad
    @ls -lh hardware/coque/build/

# Ouvre le modèle dans OpenSCAD pour le manipuler.
coque-preview:
    openscad hardware/coque/coque.scad

# Supprime les STL générés.
coque-clean:
    rm -rf hardware/coque/build

# ─── Collecteur ─────────────────────────────────────────────────────────────

# Compile le collecteur.
col-build:
    cd collector && cargo build --release

# Tests unitaires et clippy.
col-check:
    cd collector && cargo test && cargo clippy --all-targets -- -D warnings

# Collecte depuis le port série simulé, vers l'archive (Ctrl-C pour arrêter).
col-collect port="/tmp/jardin-gateway":
    cd collector && cargo run --quiet -- collect --port {{ port }} --data-dir ../stack/data

# Importe l'archive dans la base, depuis l'hôte.
col-import *args:
    cd collector && cargo run --quiet -- import --data-dir ../stack/data \
        --db-url "mysql://jardin:$(grep '^MARIADB_PASSWORD=' ../stack/.env | cut -d= -f2-)@127.0.0.1:3306/jardin" {{ args }}

# ─── Simulateur de nœud ─────────────────────────────────────────────────────

# Port série virtuel, comme si GATEWAY-001 était branchée (Ctrl-C pour arrêter).
# Le collecteur l'ouvrira sur /tmp/jardin-gateway.
sim-serie vitesse="600":
    tools/simulateur-noeud.py --out pty --link /tmp/jardin-gateway --speed {{ vitesse }}

# Fabrique un historique synthétique dans l'archive (ex : just sim-archive 21).
sim-archive jours="14":
    tools/simulateur-noeud.py --archive-dir stack/data --duration {{ jours }}
    @find stack/data -name '*.ndjson' -exec wc -l {} +

# Regarde passer quelques trames, sans rien écrire.
sim-voir:
    tools/simulateur-noeud.py --speed 0 --duration 0.02

# Efface l'archive synthétique. À ne PAS lancer sur des mesures réelles.
sim-clean:
    rm -rf stack/data/[0-9]*

# ─── Stack serveur ──────────────────────────────────────────────────────────

# Démarre MariaDB et Grafana (http://localhost:3000).
stack-up: _stack-env
    cd stack && docker compose up -d

# Démarre la stack complète, collecteur et importeur compris.
stack-up-collector: _stack-env
    cd stack && docker compose --profile collector up -d --build

# Arrête la stack, en conservant les volumes.
stack-down:
    cd stack && docker compose --profile collector --profile ha down

# Suit les journaux de la stack.
stack-logs:
    cd stack && docker compose --profile collector logs -f

# Vérifie la syntaxe du compose.
stack-check: _stack-env
    cd stack && docker compose --profile collector --profile ha config --quiet && echo "compose.yaml OK"

# Ouvre un shell SQL sur la base.
db:
    cd stack && docker compose exec mariadb mariadb -ujardin -p"$(grep '^MARIADB_PASSWORD=' .env | cut -d= -f2-)" jardin

# Affiche le câblage courant : quelle sonde est branchée où.
db-wiring:
    cd stack && docker compose exec -T mariadb mariadb -ujardin -p"$(grep '^MARIADB_PASSWORD=' .env | cut -d= -f2-)" jardin --table -e 'SELECT * FROM v_current_wiring'

# Recrée la base de zéro. DÉTRUIT l'index, jamais l'archive NDJSON.
db-reset:
    cd stack && docker compose down && docker volume rm jardin_mariadb-data && docker compose up -d mariadb

# Copie stack/.env.example en stack/.env si absent.
_stack-env:
    @[ -f stack/.env ] || (cp stack/.env.example stack/.env && echo "stack/.env créé depuis l'exemple — pense à changer les mots de passe")

# ─── Nix ────────────────────────────────────────────────────────────────────

# Vérifie que le flake évalue.
flake-check:
    nix flake check

# Met à jour nixpkgs.
flake-update:
    nix flake update

# Formate les fichiers Nix.
fmt:
    nix fmt

# ─── Interne ────────────────────────────────────────────────────────────────

# Installe les dépendances si node_modules est absent.
_docs-deps:
    @[ -d {{ docs }}/node_modules ] || (cd {{ docs }} && npm install --no-audit --no-fund)
