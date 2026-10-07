{ lib, ... }:
{
  pi-next.extensions.pi-btw.build =
    pkgs:
    (import ./_npm-source.nix { inherit pkgs lib; }) {
      npmPackage = "pi-btw";
      version = "0.7.1";
      hash = "sha512-XVHTwc6QNYHEXvdobqbUrlkvoEo/pq3pWgq4OPT/BMiyjZpjlhUW/aBO+NjFdyu1app9QL8kyGP+tsB18S1GqA==";
    };
}
