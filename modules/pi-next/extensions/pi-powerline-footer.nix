{ lib, ... }:
{
  pi-next.extensions.pi-powerline-footer.build =
    pkgs:
    (import ./_npm-source.nix { inherit pkgs lib; }) {
      npmPackage = "pi-powerline-footer";
      version = "0.19.1";
      hash = "sha512-oFaLY6oBgg5B3JxuEzWstw2ixEi1jlm/Q4B6cQ1isW5KnENbCLVbmzCtNaoaNPnntT5Te8kUo+CJwdQ+m5NDRQ==";
    };
}
