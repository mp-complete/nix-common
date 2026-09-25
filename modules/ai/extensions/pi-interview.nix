{ ... }:
{
  # pi-interview — interview-mode extension for pi. Ships no lockfile, so
  # vendor its one runtime dep (typebox, itself dependency-free).
  # https://www.npmjs.com/package/pi-interview
  pi.extensions.pi-interview = {
    pname = "pi-interview";
    version = "0.8.7";
    hash = "sha512-25Ti4JodqajFmoBBZ8E/45eIf6kdD0gPNcDY2Lw+JwclTdNo09TpCjIjPOHdMoMKzFk3oX0I7QjFScsiCiBdHA==";
    vendor = [
      {
        dir = "typebox";
        pname = "typebox";
        version = "1.2.14";
        hash = "sha512-/ogVtZUOjV69aeVvrTCmBtDNDfvXPPi28rkrQlID+bhz1dEJ9YkcnoSqCYaPIqiNifMVuTycZlZx5X82734s7w==";
      }
    ];
  };
}
