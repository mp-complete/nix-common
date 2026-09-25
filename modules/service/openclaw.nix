{ config, lib, ... }:
let
  outer = config;
in
{
  options.openclaw = {
    gatewayTokenFile = lib.mkOption {
      type = lib.types.path;
      description = "Required consumer-provided runtime path containing the system gateway authentication token.";
    };
    model = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Optional default OpenClaw model identifier; null leaves the upstream default unchanged.";
    };
    publicUrl = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Optional public WebSocket URL advertised by device pairing.";
    };
  };

  config.flake.modules.nixos.openclaw =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      tokenFile = outer.openclaw.gatewayTokenFile;
      openclawAdmin = pkgs.writeShellApplication {
        name = "openclaw-admin";
        text = ''
          env_args=(
            "HOME=/var/lib/openclaw"
            "OPENCLAW_CONFIG_PATH=/etc/openclaw/openclaw.json"
            "OPENCLAW_STATE_DIR=/var/lib/openclaw"
            "OPENCLAW_NIX_MODE=1"
            "TERM=''${TERM:-xterm-256color}"
          )
          [[ -n "''${COLORTERM:-}" ]] && env_args+=("COLORTERM=$COLORTERM")
          [[ -n "''${OPENCLAW_THEME:-}" ]] && env_args+=("OPENCLAW_THEME=$OPENCLAW_THEME")
          exec ${config.security.wrapperDir}/sudo -u openclaw --set-home \
            ${pkgs.coreutils}/bin/env "''${env_args[@]}" \
            ${pkgs.openclaw}/bin/openclaw "$@"
        '';
      };
      openclawTui = pkgs.writeShellApplication {
        name = "openclaw-tui";
        runtimeInputs = [ openclawAdmin ];
        text = ''exec openclaw-admin tui "$@"'';
      };
    in
    {
      imports = [ builtins.scoped.commonInputs.nix-openclaw.nixosModules.openclaw-gateway ];
      nixpkgs.overlays = [ builtins.scoped.commonInputs.nix-openclaw.overlays.default ];

      services.openclaw-gateway = {
        enable = true;
        user = "openclaw";
        group = "openclaw";
        createUser = true;
        stateDir = "/var/lib/openclaw";
        package = pkgs.openclaw-gateway;
        config = lib.mkMerge [
          {
            secrets.providers.gateway_token_file = {
              source = "file";
              path = tokenFile;
              mode = "singleValue";
            };
            gateway = {
              mode = "local";
              bind = "loopback";
              auth = {
                mode = "token";
                token = {
                  source = "file";
                  provider = "gateway_token_file";
                  id = "value";
                };
              };
            };
          }
          (lib.mkIf (outer.openclaw.model != null) {
            agents.defaults.model.primary = outer.openclaw.model;
          })
          (lib.mkIf (outer.openclaw.publicUrl != null) {
            plugins.entries."device-pair" = {
              enabled = true;
              config.publicUrl = outer.openclaw.publicUrl;
            };
          })
        ];
      };

      systemd.services.openclaw-gateway.serviceConfig = {
        NoNewPrivileges = true;
        CapabilityBoundingSet = "";
        ProtectSystem = "strict";
        ProtectHome = true;
        InaccessiblePaths = [ "-/mnt" ];
        ReadWritePaths = [ config.services.openclaw-gateway.stateDir ];
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectProc = "invisible";
        ProtectClock = true;
        ProtectHostname = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectKernelLogs = true;
        ProtectControlGroups = true;
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
        ];
        LockPersonality = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = [ "@system-service" ];
        UMask = "0077";
        MemoryDenyWriteExecute = false;
      };

      environment.systemPackages = [
        pkgs.openclaw
        openclawAdmin
        openclawTui
      ];
    };
}
