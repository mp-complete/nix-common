{
  flake.modules.homeManager.ai =
    { lib, pkgs, ... }:
    {
      _module.args.aiLib = import ./_impl/lib.nix { inherit lib pkgs; };
    };
}
