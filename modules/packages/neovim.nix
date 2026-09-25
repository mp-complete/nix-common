{ ... }:
{
  # pkgs.nvim — the fennel/lua neovim config from pkgs/neovim (outside the
  # import tree). Overlay in base so it's available everywhere; installed
  # system-wide (every host uses nvim as EDITOR).
  flake.modules.nixos.base =
    { pkgs, ... }:
    {
      nixpkgs.overlays = [
        (final: _prev: {
          nvim = final.callPackage ../../pkgs/neovim {
            inherit (builtins.scoped.commonInputs) fennel-ls-nvim-docs;
          };
        })
      ];
      environment.systemPackages = [ pkgs.nvim ];
      environment.variables.EDITOR = "nvim";
    };
}
