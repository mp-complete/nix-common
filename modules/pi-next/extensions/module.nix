{ config, lib, ... }:
let
  registry = config.pi-next.extensions;
  overlay = final: prev: {
    piExtensions =
      (prev.piExtensions or { }) // lib.mapAttrs (_: extension: extension.build final) registry;
  };
  resources =
    kind: pkgs:
    lib.mapAttrsToList (name: _: pkgs.piExtensions.${name}) (
      lib.filterAttrs (_: extension: extension.kind == kind) registry
    );
in
{
  options.pi-next.extensions = lib.mkOption {
    default = { };
    description = "Pinned Pi-next resources, with one declaration per extension file.";
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          kind = lib.mkOption {
            type = lib.types.enum [
              "package"
              "extension"
            ];
            default = "package";
            description = "Load a complete Pi package root or a single extension entrypoint.";
          };
          build = lib.mkOption {
            type = lib.types.functionTo (lib.types.either lib.types.package lib.types.str);
            description = "Build the pinned resource using the wrapper's package set.";
          };
        };
      }
    );
  };

  config = {
    flake.overlays.pi-next-extensions = overlay;

    # Only extend this wrapper's package set, preserving the legacy wrappers.
    # Also works when .wrap receives bare standalone Home Manager pkgs.
    flake.wrappers.pi-next = { pkgs, ... }: {
      options.pkgs = lib.mkOption {
        apply = pkgs: pkgs.extend overlay;
      };
      config.piPackages = resources "package" pkgs;
      config.extensions = resources "extension" pkgs;
    };

    flake.modules.nixos.pi-next.nixpkgs.overlays = [ overlay ];
  };
}
