self: { config, lib, pkgs, ... }: let
  cfg = config.services.tre-track-station;
in with lib; {
  options.services.tre-track-station = {
    enable = mkEnableOption "monitoring tre station content";

    tre-server-name = mkOption {
      type = types.str;
      default = "";
      defaultText = "";
      description = "name of tre-server";
    };

    socket-path = mkOption rec {
      type = types.path;
      default = "/run/tre-server/${cfg.tre-server-name}/socket";
      defaultText = default;
      description = "Path to tre-server's control socket";
    };

    debounce = mkOption {
      type = types.ints.positive;
      default = 2000;
      description = "debounce period in milliseconds";
    };

    package = mkOption {
      type = types.package;
      default = self.packages.${pkgs.stdenv.system}.default;
      defaultText = literalExpression "pkgs.tre-track-station";
      description = "package to use";
    };

  };

  config = let
    treOpts = "--socketPath ${cfg.socket-path} --debounce ${builtins.toString cfg.debounce}";
  in mkIf cfg.enable {
    
    systemd.services.tre-track-station = {
      description = "monitoring tre station";
      after = [ 
        "tre-server-${cfg.tre-server-name}.service"
      ];
      requires = [ "tre-server-${cfg.tre-server-name}.service"];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        ExecStart = "${cfg.package}/bin/track-station ${treOpts}";
        Restart = "always";
        WorkingDirectory = "/tmp";
        StandardOutput = "journal";
        StandardError = "journal";
        #ProtectSystem = "strict";
        
        DynamicUser = true;
        SupplementaryGroups = [
          "ssb-${cfg.tre-server-name}"
        ];
        BindPaths = [ 
          cfg.socket-path
          "/etc/tre-station.json"
        ];
        Environment = [
          "DEBUG=tre-track-station:bin"
          "DEBUG_HIDE_DATE=1"
        ];
      };
    };
  };
}
