{ config, ... }:
{
  # agent-browser-edge-bridge — local (non-npm) pi extension. Routes the
  # WSL-only pi-chrome-use tool exclusively to a dedicated Windows Edge profile.
  # Source lives under ./_local (a `/_` path, so not auto-imported as a
  # flake-parts module); built via callPackage.
  pi.extensions.agent-browser-edge-bridge = {
    pname = "agent-browser-edge-bridge";
    version = "0.3.2";
    # No npm tarball: leave hash empty and build from the local source.
    build = { pkgs, ... }: pkgs.callPackage ./_local/agent-browser-edge-bridge { };
  };

  perSystem =
    { pkgs, ... }:
    let
      bridge = config.flake.lib.buildPiExtension pkgs config.pi.extensions.agent-browser-edge-bridge;
    in
    {
      checks.edge-cdp-bootstrap =
        pkgs.runCommand "edge-cdp-bootstrap-tests"
          {
            nativeBuildInputs = with pkgs; [
              bash
              coreutils
              diffutils
              gnugrep
              jq
              nodejs
              shellcheck
            ];
          }
          ''
            bash -n ${bridge}/scripts/bootstrap.sh
            # The two port guards intentionally use A && B || die.
            shellcheck --exclude=SC2015 ${bridge}/scripts/bootstrap.sh
            # Windows commands and CDP are stubbed. Do not start Pi or a browser.
            unset PI_TEST_BINARY EDGE_BRIDGE_SOURCE
            node --test ${bridge}/test/*.test.mjs
            touch "$out"
          '';
    };
}
