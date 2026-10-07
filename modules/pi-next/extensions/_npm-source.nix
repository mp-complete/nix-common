{ pkgs, lib }:
{
  npmPackage,
  version,
  hash,
  nodeModules ? { },
}:
let
  tarball = pkgs.fetchurl {
    url = "https://registry.npmjs.org/${npmPackage}/-/${baseNameOf npmPackage}-${version}.tgz";
    inherit hash;
  };
in
# Preserve complete package roots and package-relative dependency links. Never
# run npm lifecycle scripts or install private copies of Pi-provided peers.
# Hashes are npm dist.integrity values over the original tarballs.
pkgs.runCommand "${lib.strings.sanitizeDerivationName npmPackage}-${version}-source"
  {
    nativeBuildInputs = [
      pkgs.gnutar
      pkgs.gzip
    ];
  }
  ''
    mkdir -p "$out"
    tar -xzf ${tarball} --strip-components=1 -C "$out"
    ${lib.concatStringsSep "\n" (
      lib.mapAttrsToList (name: source: ''
        mkdir -p "$out/node_modules/$(dirname ${lib.escapeShellArg name})"
        ln -s ${source} "$out/node_modules/${name}"
      '') nodeModules
    )}
  ''
