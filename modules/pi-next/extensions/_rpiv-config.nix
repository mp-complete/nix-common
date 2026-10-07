{ pkgs, lib }:
# Shared by the question and todo extensions. Optional rpiv-i18n is omitted;
# English fallback is intentional and Pi/TypeBox peers remain host-provided.
(import ./_npm-source.nix { inherit pkgs lib; }) {
  npmPackage = "@juicesharp/rpiv-config";
  version = "2.12.0";
  hash = "sha512-eGjoCDCKz2JtKIUIpZ2y8CAVjxZYXCKa2D64ByozhkAWVblXsgyFLrQMk5k5Bv5RXRrA3GY66XNG5ExtEuGASA==";
}
