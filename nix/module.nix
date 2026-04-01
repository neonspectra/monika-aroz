# Aroz NixOS service module
#
# Configures ArozOS as a systemd service with:
# - Immutable assets symlinked from the Nix store (web/, subservice/)
# - Mutable state directory with version-gated seeding (system/)
# - Sysadmin features disabled by default (hardware mgmt, discovery, pkg install)
# - Process group management for subservice children (ttyd)
#
# Usage in a NixOS configuration:
#   services.aroz = {
#     enable = true;
#     port = 8090;
#     dataDir = "/persist/aroz";
#   };

{ config, lib, pkgs, ... }:

let
  cfg = config.services.aroz;

  # Build the flag string from module options.
  # Sysadmin features are disabled by default — this is a web desktop,
  # not a system management tool. NixOS handles that layer.
  flagList = [
    "-port ${toString cfg.port}"
    "-hostname \"${cfg.hostname}\""
    "-root \"${cfg.dataDir}/files/\""
    "-tmp \"${cfg.dataDir}/\""
    "-max_upload_size ${toString cfg.maxUploadSize}"
    # Disable sysadmin features by default
    "-allow_pkg_install=false"
    "-enable_hwman=false"
    "-enable_pwman=false"
    "-allow_mdns=false"
    "-allow_ssdp=false"
    "-allow_upnp=false"
    "-disable_ip_resolver=true"
  ] ++ lib.optionals cfg.tls.enable [
    "-tls=true"
    "-tls_port ${toString cfg.tls.port}"
    "-cert \"${cfg.tls.certFile}\""
    "-key \"${cfg.tls.keyFile}\""
  ] ++ lib.optionals cfg.tls.disableHttp [
    "-disable_http=true"
  ] ++ cfg.extraFlags;

  flagString = lib.concatStringsSep " " flagList;

  # The package provides the binary and the static assets.
  pkg = cfg.package;
in
{
  options.services.aroz = {
    enable = lib.mkEnableOption "Aroz web desktop";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.aroz or (pkgs.callPackage ../nix/package.nix {});
      defaultText = lib.literalExpression "pkgs.aroz";
      description = "The Aroz package to use.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = "HTTP listening port.";
    };

    hostname = lib.mkOption {
      type = lib.types.str;
      default = "Aroz";
      description = "Display name for this host.";
    };

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/aroz";
      description = ''
        Working directory for Aroz. Contains mutable state (databases, logs,
        user files) and symlinks to immutable assets in the Nix store.
        On impermanence hosts, set this to a path under /persist.
      '';
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "aroz";
      description = "User account to run Aroz under.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "aroz";
      description = "Group to run Aroz under.";
    };

    tls = {
      enable = lib.mkEnableOption "TLS for Aroz";

      port = lib.mkOption {
        type = lib.types.port;
        default = 8443;
        description = "HTTPS listening port.";
      };

      certFile = lib.mkOption {
        type = lib.types.path;
        description = "Path to TLS certificate.";
      };

      keyFile = lib.mkOption {
        type = lib.types.path;
        description = "Path to TLS private key.";
      };

      disableHttp = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Disable HTTP entirely (HTTPS only). Requires tls.enable.";
      };
    };

    maxUploadSize = lib.mkOption {
      type = lib.types.int;
      default = 8192;
      description = "Maximum upload size in MB.";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Open the configured port(s) in the firewall.";
    };

    extraFlags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = ''
        Additional CLI flags passed to arozos.
        See docs/admins/configuration.md for the full list.
      '';
      example = [ "-console" "-public_reg=true" ];
    };
  };

  config = lib.mkIf cfg.enable {
    # Create system user/group if using the defaults.
    # When user/group are overridden (e.g. to "monika"), the caller is
    # responsible for ensuring they exist.
    users.users.${cfg.user} = lib.mkIf (cfg.user == "aroz") {
      isSystemUser = true;
      group = cfg.group;
      home = cfg.dataDir;
      description = "Aroz service user";
    };

    users.groups.${cfg.group} = lib.mkIf (cfg.group == "aroz") {};

    # Create the data directory structure.
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir}          0755 ${cfg.user} ${cfg.group} -"
      "d ${cfg.dataDir}/files    0755 ${cfg.user} ${cfg.group} -"
      "d ${cfg.dataDir}/tmp      0755 ${cfg.user} ${cfg.group} -"
    ];

    # Activation script: symlink immutable assets, seed mutable system/ dir.
    system.activationScripts.aroz-assets = {
      text = ''
        # Symlink immutable assets — always points to current package version.
        ln -sfn "${pkg}/share/aroz/web" "${cfg.dataDir}/web"
        ln -sfn "${pkg}/share/aroz/subservice" "${cfg.dataDir}/subservice"

        # Seed system/ on first run. On upgrades, copy new files without
        # overwriting existing state (databases, logs, configs).
        MARKER="${cfg.dataDir}/.aroz-pkg-version"
        CURRENT_VERSION="${pkg.version}"

        if [ ! -d "${cfg.dataDir}/system" ]; then
          # First run: copy everything
          cp -r "${pkg}/share/aroz/system" "${cfg.dataDir}/system"
          chown -R ${cfg.user}:${cfg.group} "${cfg.dataDir}/system"
          echo "$CURRENT_VERSION" > "$MARKER"
        elif [ ! -f "$MARKER" ] || [ "$(cat "$MARKER")" != "$CURRENT_VERSION" ]; then
          # Upgrade: copy new files only (no-clobber)
          cp -rn "${pkg}/share/aroz/system/." "${cfg.dataDir}/system/"
          chown -R ${cfg.user}:${cfg.group} "${cfg.dataDir}/system"
          echo "$CURRENT_VERSION" > "$MARKER"
        fi
      '';
      deps = [ "specialfs" "users" ];
    };

    # Systemd service.
    systemd.services.aroz = {
      description = "Aroz Web Desktop";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.dataDir;
        ExecStart = "${pkg}/bin/arozos ${flagString}";

        # Kill the entire cgroup on stop — this catches subservice children
        # (ttyd, etc.) that ArozOS spawns via exec.Command.
        KillMode = "control-group";
        TimeoutStopSec = "10s";

        Restart = "on-failure";
        RestartSec = "10s";

        # Hardening
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ReadWritePaths = [ cfg.dataDir ];
        PrivateTmp = false; # ArozOS manages its own tmp via -tmp flag
      };
    };

    # Firewall
    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall (
      [ cfg.port ] ++ lib.optionals cfg.tls.enable [ cfg.tls.port ]
    );
  };
}
