{ ... }:
{
  flake.modules.nixos.openclaw-node =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      cfg = config.services.openclaw-node;

      nodeRun = pkgs.writeShellApplication {
        name = "openclaw-node-run";
        runtimeInputs = [
          pkgs.openclaw
          pkgs.coreutils
        ];
        text = ''
          token_file=${lib.escapeShellArg cfg.gatewayTokenFile}
          if [[ ! -s "$token_file" ]]; then
            echo "openclaw-node: gateway token file $token_file is missing or empty" >&2
            exit 1
          fi
          OPENCLAW_GATEWAY_TOKEN="$(tr -d '[:space:]' < "$token_file")"
          export OPENCLAW_GATEWAY_TOKEN

          args=(node run --host ${lib.escapeShellArg cfg.gatewayHost} --port ${toString cfg.gatewayPort})
          ${lib.optionalString cfg.gatewayTls "args+=(--tls)"}
          ${lib.optionalString (!cfg.gatewayTls) "args+=(--no-tls)"}
          ${lib.optionalString (
            cfg.contextPath != null
          ) "args+=(--context-path ${lib.escapeShellArg cfg.contextPath})"}
          ${lib.optionalString (
            cfg.displayName != null
          ) "args+=(--display-name ${lib.escapeShellArg cfg.displayName})"}
          ${lib.optionalString (
            cfg.tlsFingerprint != null
          ) "args+=(--tls-fingerprint ${lib.escapeShellArg cfg.tlsFingerprint})"}
          exec openclaw "''${args[@]}"
        '';
      };

      nodeAdmin = pkgs.writeShellApplication {
        name = "openclaw-node-admin";
        text = ''
          env_args=(
            "HOME=${cfg.stateDir}"
            "OPENCLAW_STATE_DIR=${cfg.stateDir}"
            "OPENCLAW_NIX_MODE=1"
            "TERM=''${TERM:-xterm-256color}"
          )
          [[ -n "''${COLORTERM:-}" ]] && env_args+=("COLORTERM=$COLORTERM")
          exec ${config.security.wrapperDir}/sudo -u ${cfg.user} --set-home \
            ${pkgs.coreutils}/bin/env "''${env_args[@]}" \
            ${pkgs.openclaw}/bin/openclaw "$@"
        '';
      };
    in
    {
      options.services.openclaw-node = with lib; {
        gatewayHost = mkOption {
          type = types.str;
          default = "127.0.0.1";
          description = "OpenClaw gateway host.";
        };
        gatewayPort = mkOption {
          type = types.port;
          default = 18789;
          description = "OpenClaw gateway port.";
        };
        gatewayTls = mkOption {
          type = types.bool;
          default = false;
          description = "Use TLS for the gateway connection.";
        };
        contextPath = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Optional gateway WebSocket context path.";
        };
        tlsFingerprint = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Optional expected gateway TLS certificate fingerprint.";
        };
        displayName = mkOption {
          type = types.nullOr types.str;
          default = config.networking.hostName;
          defaultText = literalExpression "config.networking.hostName";
          description = "Node display name.";
        };
        user = mkOption {
          type = types.str;
          default = "openclaw-node";
          description = "System user running the node.";
        };
        group = mkOption {
          type = types.str;
          default = "openclaw-node";
          description = "System group running the node.";
        };
        stateDir = mkOption {
          type = types.path;
          default = "/var/lib/openclaw-node";
          description = "Node state directory.";
        };
        gatewayTokenFile = mkOption {
          type = types.path;
          description = "Required consumer-provided runtime path containing the shared gateway authentication token.";
        };
      };

      config = {
        nixpkgs.overlays = [ builtins.scoped.commonInputs.nix-openclaw.overlays.default ];
        users.groups.${cfg.group} = { };
        users.users.${cfg.user} = {
          isSystemUser = true;
          group = cfg.group;
          home = cfg.stateDir;
          createHome = true;
          shell = pkgs.bashInteractive;
        };
        systemd.tmpfiles.rules = [ "d ${cfg.stateDir} 0750 ${cfg.user} ${cfg.group} - -" ];
        systemd.services.openclaw-node = {
          description = "OpenClaw node host";
          wantedBy = [ "multi-user.target" ];
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];
          environment = {
            HOME = cfg.stateDir;
            OPENCLAW_STATE_DIR = cfg.stateDir;
            OPENCLAW_NIX_MODE = "1";
          };
          serviceConfig = {
            User = cfg.user;
            Group = cfg.group;
            WorkingDirectory = cfg.stateDir;
            ExecStart = "${nodeRun}/bin/openclaw-node-run";
            Restart = "on-failure";
            RestartSec = 5;
            NoNewPrivileges = true;
            CapabilityBoundingSet = "";
            ProtectSystem = "strict";
            ProtectHome = true;
            InaccessiblePaths = [ "-/mnt" ];
            ReadWritePaths = [ cfg.stateDir ];
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
          path = [
            pkgs.bash
            pkgs.coreutils
          ];
        };
        environment.systemPackages = [
          pkgs.openclaw
          nodeAdmin
        ];
      };
    };
}
