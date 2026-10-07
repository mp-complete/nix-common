{ lib, ... }:
{
  pi-next.extensions.rpiv-todo.build =
    pkgs:
    (import ./_npm-source.nix { inherit pkgs lib; }) {
      npmPackage = "@juicesharp/rpiv-todo";
      version = "2.12.0";
      hash = "sha512-bTILerGqMGrWMUkahHzXTuYa4iPkRX/LTl12HPppcCdPg7pGwrC1K7/ZtPfp7Xi4cXzqEoyZpeUM6IA8y5gtEQ==";
      nodeModules."@juicesharp/rpiv-config" = import ./_rpiv-config.nix { inherit pkgs lib; };
    };
}
