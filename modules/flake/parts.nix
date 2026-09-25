{ ... }:
{
  imports = [
    builtins.scoped.commonInputs.flake-parts.flakeModules.modules
    builtins.scoped.commonInputs.nix-wrapper-modules.flakeModules.wrappers
  ];

  systems = [ "x86_64-linux" ];

  perSystem = { pkgs, ... }: {
    formatter = pkgs.nixfmt-tree;
  };
}
