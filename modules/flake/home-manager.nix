{
  config,
  inputs,
  lib,
  ...
}:
let
  cfg = config.flake.modules;
  user = config.username;

  hmBuckets =
    buckets:
    lib.attrValues (lib.getAttrs (lib.filter (b: cfg.homeManager ? ${b}) buckets) cfg.homeManager);
  nixosBuckets =
    buckets: lib.attrValues (lib.getAttrs (lib.filter (b: cfg.nixos ? ${b}) buckets) cfg.nixos);

  mkHost =
    {
      system ? "x86_64-linux",
      buckets,
      modules ? [ ],
    }:
    (inputs.nixpkgs or builtins.scoped.commonInputs.nixpkgs).lib.nixosSystem {
      specialArgs = { inherit inputs; };
      modules =
        nixosBuckets ([ "home-manager" ] ++ buckets)
        ++ [
          { nixpkgs.hostPlatform = lib.mkDefault system; }
          { home-manager.users.${user}.imports = hmBuckets buckets; }
        ]
        ++ modules;
    };
in
{
  options.home.stateVersion = lib.mkOption {
    type = lib.types.str;
    default = "23.11";
    description = "Home Manager state version for the primary user.";
  };

  config = {
    _module.args.mkHost = mkHost;

    flake.modules.nixos.home-manager = {
      imports = [ builtins.scoped.commonInputs.home-manager.nixosModules.home-manager ];
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        extraSpecialArgs = { inherit inputs; };
        users.${user}.home.stateVersion = config.home.stateVersion;
      };
    };
  };
}
