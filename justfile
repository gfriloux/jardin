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
    #!/usr/bin/env bash
    set -uo pipefail
    # `ls` sort en erreur dès qu'un de ses motifs ne correspond à rien, même
    # s'il a listé les autres. Tester son code de retour annoncerait « aucun
    # port » alors qu'une carte est là : c'est la sortie qu'on regarde.
    ports=$(ls /dev/ttyUSB* /dev/ttyACM* 2>/dev/null || true)
    if [ -z "$ports" ]; then
      echo "aucun port série USB"
    else
      echo "$ports"
    fi
    pio device list

# Compile, téléverse et ouvre le moniteur série (ex : just fw 01-blink).
fw croquis:
    #!/usr/bin/env bash
    set -euo pipefail
    port=$(just _fw-port)
    echo "carte détectée sur $port"
    cd firmware
    pio run -e {{ croquis }} -t upload --upload-port "$port"
    pio device monitor -e {{ croquis }} --port "$port"

# Compile un croquis sans le téléverser (ex : just fw-build 03-radio).
fw-build croquis:
    cd firmware && pio run -e {{ croquis }}

# Enregistre une session de mesure dans mesures/ (ex : just fw-log 05-caracterisation air-libre).
fw-log croquis etiquette="sans-etiquette":
    #!/usr/bin/env bash
    set -euo pipefail
    # Une mesure qu'on ne peut pas relire est une mesure perdue : le moniteur
    # défile et le terminal tronque. Le fichier permet d'y revenir, de comparer
    # deux sessions, et de passer le tout à tools/analyse-mesures.py.
    port=$(just _fw-port)
    mkdir -p mesures
    fichier="mesures/$(date +%Y%m%d-%H%M%S)-{{ croquis }}-{{ etiquette }}.log"
    echo "carte détectée sur $port"
    cd firmware
    # Téléverser d'abord, comme `fw`. Sans ça, on enregistre la sortie du
    # croquis précédemment flashé sous le nom du croquis demandé — un journal
    # faux, et qui a l'air juste.
    pio run -e {{ croquis }} -t upload --upload-port "$port"
    # L'en-tête sert de preuve : si la sortie ne ressemble pas au croquis
    # annoncé ici, c'est que le téléversement a échoué.
    printf '# croquis   : %s\n# etiquette : %s\n# date      : %s\n\n' \
      '{{ croquis }}' '{{ etiquette }}' "$(date -Is)" > "../$fichier"
    echo "enregistrement dans $fichier — Ctrl-C pour arrêter"
    pio device monitor -e {{ croquis }} --port "$port" | tee -a "../$fichier"

# Ouvre le moniteur série sans recompiler (ex : just fw-monitor 04-sonde).
fw-monitor croquis:
    #!/usr/bin/env bash
    set -euo pipefail
    cd firmware && pio device monitor -e {{ croquis }} --port "$(just _fw-port)"

# Trouve le port USB de la carte, ou échoue en expliquant pourquoi.
#
# Sans ce garde-fou, PlatformIO se rabat sur le premier port série venu — et
# /dev/ttyS0, le port série de la carte mère, en est un. Il tente alors d'y
# téléverser un firmware ESP32, ce qui ne peut pas marcher et produit un
# message d'erreur qui n'évoque à aucun moment l'absence de carte.
_fw-port:
    #!/usr/bin/env bash
    set -euo pipefail
    port=$(ls /dev/ttyUSB* /dev/ttyACM* 2>/dev/null | head -1 || true)
    if [ -z "$port" ]; then
      echo "Aucune carte sur un port USB." >&2
      echo >&2
      echo "  - la carte est-elle branchée ?" >&2
      echo "  - le câble transporte-t-il les données ? Beaucoup de câbles" >&2
      echo "    fournis avec des téléphones ne transportent que le courant." >&2
      echo "  - /dev/ttyS0 est le port série de la carte mère, pas la carte." >&2
      exit 1
    fi
    if [ ! -r "$port" ] || [ ! -w "$port" ]; then
      echo "$port existe mais n'est pas accessible." >&2
      echo "Les règles udev le mettent normalement en 0666 — reconnecter la" >&2
      echo "session si le groupe dialout vient d'être ajouté." >&2
      exit 1
    fi
    echo "$port"

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

# Banc d'essai des ergots : la carte factice doit se poser libre à la cote
# nominale, et buter sur les ergots dès qu'on la décale le long de son axe.
# C'est ce test qui aurait dû tourner avant la première impression : le modèle
# se rendait, la carte n'entrait pas.
coque-test:
    #!/usr/bin/env bash
    set -euo pipefail
    tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
    echec=0
    # décalage:attendu — "libre" = aucun volume commun, "bute" = contact
    for cas in 0:libre 0.5:libre -0.5:libre 0.6:bute -0.6:bute 1.5:bute -1.5:bute; do
      d=${cas%:*}; attendu=${cas#*:}
      rm -f "$tmp/i.stl"
      # Volume commun nul : OpenSCAD n'écrit aucun fichier, sort en 1 et le
      # dit sur stderr. Il faut lire ce message, sinon une vraie erreur de
      # syntaxe passerait pour un montage qui tombe juste.
      err=$(openscad -o "$tmp/i.stl" -D 'piece="interference"' -D "essai=$d" \
            hardware/coque/coque.scad 2>&1 >/dev/null || true)
      if [ -s "$tmp/i.stl" ] && grep -q '^ *facet' "$tmp/i.stl"; then
        obtenu=bute
      elif printf '%s' "$err" | grep -q 'top level object is empty'; then
        obtenu=libre
      else
        printf '%s\n' "$err" >&2
        echo "openscad n'a produit ni volume ni « objet vide »" >&2
        exit 1
      fi
      if [ "$obtenu" = "$attendu" ]; then
        printf '  ok    décalage %+5s mm : %s\n' "$d" "$obtenu"
      else
        printf '  ÉCHEC décalage %+5s mm : %s, attendu %s\n' "$d" "$obtenu" "$attendu"
        echec=1
      fi
    done
    [ $echec -eq 0 ] && echo "ergots OK" || (echo "les ergots ne tiennent pas la carte" >&2; exit 1)

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
