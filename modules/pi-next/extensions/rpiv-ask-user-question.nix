{ lib, ... }:
{
  pi-next.extensions.rpiv-ask-user-question.build =
    pkgs:
    (import ./_npm-source.nix { inherit pkgs lib; }) {
      npmPackage = "@juicesharp/rpiv-ask-user-question";
      version = "2.12.0";
      hash = "sha512-DilWc7u25SwnK6ytuAWOTerP0AmOEfK4HXpgS1oEzkgv9d5g5T+PbLG+zcLn18M3B/J3poMG14iydG5O6iBsnw==";
      nodeModules."@juicesharp/rpiv-config" = import ./_rpiv-config.nix { inherit pkgs lib; };
    };
}
