{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";
    tre-cli-tools = {
      url = "github:regular/tre-cli-tools-nixos";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, systems, nixpkgs, ... }@inputs: let
    eachSystem = f: nixpkgs.lib.genAttrs (import systems) (system: f rec {
      inherit system;
      pkgs = nixpkgs.legacyPackages.${system};
      pkg_deps = with pkgs; [
        bash
      ];
      path = pkgs.lib.makeBinPath pkg_deps;
    });
  in {
    nixosConfigurations.demo = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        self.nixosModules.default
        {
          services.tre-track-station = {
            enable = true;
            debounce = 4000;
            tre-server-name = "my-network";
          };
        }
      ];
    };
    nixosModules.default = (import ./service.nix) self;
    packages = eachSystem ( { pkgs, system, path, ... }: let 
      cli-tools = inputs.tre-cli-tools.packages.${system}.default;
      extraModulePath = "${cli-tools}/lib/node_modules/tre-cli-tools/node_modules";
      version = "2.0.0";
      pname = "tre-track-station";
      meta = {
        description = "Monitoring a station onject and sync its content to /etc";
        mainProgram = "track-station";
        maintainers = [ "jan@lagomorph.de" ];
      };
    in {
      default = pkgs.buildNpmPackage rec {
        inherit version pname meta;

        dontNpmBuild = true;
        makeCacheWritable = true;
        npmFlags = [ "--omit=dev" "--omit=optional"];

        src = ./.;

        npmDepsHash = "sha256-pFCsYV7arMtDE19BesVU3XbOsl7LGYdSxxeR7sKzq6A=";
        postBuild = ''
          mkdir -p $out/lib/node_modules/${pname}
          cat <<EOF > $out/lib/node_modules/${pname}/extra-modules-path.js
          process.env.NODE_PATH += ':${extraModulePath}' 
          require('module').Module._initPaths()
          EOF
          '';

        nativeBuildInputs = [ pkgs.makeWrapper ];
        postInstall = ''
          wrapProgram $out/bin/track-station \
          --set SHELL ${pkgs.bash}/bin/bash \
          --set PATH ${path}
          '';
      };
    });

    devShells = eachSystem ( { pkgs, system, ... }: {
      default = pkgs.mkShell {
        buildInputs = [
          pkgs.nodejs
          pkgs.python3
        ];
      };
    });
  };
}
