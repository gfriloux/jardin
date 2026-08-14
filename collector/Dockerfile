# Image du collecteur.
#
# Le binaire ne dépend dynamiquement que de libc, libgcc et libm : retirer
# libudev de `serialport` a supprimé la seule dépendance système gênante.
# Une base `debian:*-slim` suffit donc largement.
#
# Piste pour plus tard : une cible `x86_64-unknown-linux-musl` donnerait un
# binaire statique et une image `scratch` de quelques mégaoctets. Ça demande
# d'ajouter la cible et son éditeur de liens au devshell — à faire le jour où
# la taille de l'image devient un sujet, pas avant.
#
# Pour un Raspberry Pi :
#   docker buildx build --platform linux/arm64 -t jardin-collector .

FROM rust:1-bookworm AS build

WORKDIR /src

# Les dépendances dans leur propre couche : elles ne changent presque jamais,
# le code change à chaque itération. Sans ça, chaque build recompile tout
# l'arbre de dépendances.
COPY Cargo.toml Cargo.lock ./
RUN mkdir src \
 && echo 'fn main() {}' > src/main.rs \
 && cargo build --release \
 && rm -rf src

COPY src ./src
# Sans ce touch, cargo croit que main.rs n'a pas changé depuis la couche
# précédente et livre le binaire vide.
RUN touch src/main.rs && cargo build --release


FROM debian:bookworm-slim

COPY --from=build /src/target/release/jardin /usr/local/bin/jardin

# L'utilisateur est imposé par le compose, pour que les fichiers de l'archive
# appartiennent à l'utilisateur de l'hôte et restent lisibles hors conteneur.
ENTRYPOINT ["jardin"]
CMD ["--help"]
