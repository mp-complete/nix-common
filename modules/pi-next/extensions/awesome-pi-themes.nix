{ lib, ... }:
{
  pi-next.extensions.awesome-pi-themes.build =
    pkgs:
    (import ./_npm-source.nix { inherit pkgs lib; }) {
      npmPackage = "awesome-pi-themes";
      version = "1.2.19";
      hash = "sha512-e14/2nlmHMqJ2G/4qq1DamrVcMqGhNM2gICplSJgxQXGyhq2NAYRLlO5i8C30NxDxMwur0KOia7OtFxHxUEdkQ==";
    };
}
