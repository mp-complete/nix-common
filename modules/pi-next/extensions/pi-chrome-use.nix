{ lib, ... }:
{
  pi-next.extensions.pi-chrome-use.build =
    pkgs:
    let
      npmSource = import ./_npm-source.nix { inherit pkgs lib; };
    in
    (npmSource {
      npmPackage = "pi-chrome-use";
      version = "1.1.1";
      hash = "sha512-dSxkSuKImPkNp3WPIDIaEaUIxYzvG1WtH+8sTb/Bp3fBAIDCndn8LK1JerV3VMlVX1OHqFvuhgf8k7jjmr644g==";
    }).overrideAttrs
      (old: {
        # Keep the package root and host-provided peers. No browser starts on load.
        # Pi 1.0 uses sessionManager.getSessionId(), not ctx.sessionId/cwd.
        nativeBuildInputs = old.nativeBuildInputs ++ [ pkgs.patch ];
        buildCommand = old.buildCommand + ''
          patch --fuzz=0 -d "$out" -p1 < ${./_patches/pi-chrome-use-lifecycle.patch}
        '';
      });
}
