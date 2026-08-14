{
  description = "Jardin — réseau de télémétrie du terrain (sondes d'humidité du sol, LoRa)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          name = "jardin";

          packages = with pkgs; [
            # lanceur de tâches — voir le justfile à la racine
            just

            # docs/ — Astro + Starlight
            nodejs_22

            # firmware/ — ESP32-S3 + SX1262.
            # `platformio` et non `platformio-core` : le premier est un
            # environnement FHS (bwrap), indispensable sous NixOS car les
            # toolchains téléchargées par PlatformIO (xtensa-esp32s3-elf-g++)
            # sont liées dynamiquement pour une distribution classique et
            # échouent sinon sur « Could not start dynamically linked
            # executable ».
            platformio
            esptool
            picocom

            # collector/ — daemon Rust GATEWAY → MQTT
            cargo
            rustc
            rustfmt
            clippy
            rust-analyzer
            pkg-config

            # hardware/ — coque des sondes, modèle paramétrique
            openscad

            # stack de test locale
            mosquitto
            jq
          ];

          # serialport-rs se lie à libudev via pkg-config
          buildInputs = [ pkgs.udev ];

          shellHook = ''
            echo "jardin — devshell. Tâches disponibles : just --list"
          '';
        };
      });

      # Règles udev à installer côté système pour accéder aux cartes en USB :
      #   services.udev.packages = [ inputs.jardin.packages.x86_64-linux.udev-rules ];
      packages = forAllSystems (pkgs: {
        udev-rules = pkgs.platformio-core.udev;
      });

      formatter = forAllSystems (pkgs: pkgs.nixpkgs-fmt);
    };
}
