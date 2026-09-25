final: prev: {
  mkZellijPlugin =
    {
      name,
      version,
      url,
      sha256,
      meta ? { },
    }:
    prev.stdenvNoCC.mkDerivation {
      pname = name;
      inherit version;

      src = prev.fetchurl { inherit url sha256; };
      dontUnpack = true;

      installPhase = ''
        runHook preInstall
        install -Dm444 $src $out/bin/${name}.wasm
        runHook postInstall
      '';

      meta = {
        description = "Zellij plugin: ${name}";
        platforms = prev.lib.platforms.all;
      }
      // meta;
    };

  zellij-forgot = final.mkZellijPlugin {
    name = "zellij_forgot";
    version = "0.4.2";
    url = "https://github.com/karimould/zellij-forgot/releases/download/0.4.2/zellij_forgot.wasm";
    sha256 = "1ns9wjn1ncjapqpp9nn9kyhqydvl0fbnyiavd0lc3gcxa52l269i";
  };

  zellij-autolock = final.mkZellijPlugin {
    name = "zellij-autolock";
    version = "0.2.2";
    url = "https://github.com/fresh2dev/zellij-autolock/releases/download/0.2.2/zellij-autolock.wasm";
    sha256 = "194fgd421w2j77jbpnq994y2ma03qzdlz932cxfhfznrpw3mdjb9";
  };
}
