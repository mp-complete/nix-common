{ config, ... }:
let
  outer = config;
  upstream = builtins.scoped.commonInputs.pi-nix-wrapper;
in
{
  flake.wrappers.pi-next =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      imports = [ upstream.wrapperModules.pi ];
      # Keep the upstream runtime separate from the legacy pi package overlay.
      # Export only its launcher: copying its lib/node_modules tree into the
      # wrapper collides with legacy Pi in Home Manager's package environment.
      # The launcher refers to its runtime and libraries by absolute store paths.
      package = pkgs.buildEnv {
        name = "pi-next-runtime";
        paths = [ upstream.inputs.pi-nix.packages.${pkgs.stdenv.hostPlatform.system}.coding-agent ];
        pathsToLink = [ "/bin" ];
        meta.mainProgram = "pi";
      };
      binName = lib.mkDefault "pi-next";
      configDir = lib.mkDefault "\${XDG_CONFIG_HOME:-$HOME/.config}/${config.binName}";
      # Hosted anonymous access is rate-limited; no credentials enter the store.
      mcpServers.exa = {
        url = lib.mkDefault "https://mcp.exa.ai/mcp";
        description = lib.mkDefault "Search the web and fetch webpage content with Exa";
        exposure = lib.mkDefault "codemode";
      };
    };

  # A standalone feature bucket: usable without ai, desktop, WSL or base.
  flake.modules.homeManager.pi-next =
    { pkgs, ... }:
    {
      home.packages = [ (outer.flake.wrappers.pi-next.wrap { inherit pkgs; }) ];
    };

}
