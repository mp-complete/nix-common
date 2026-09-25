final: prev:
let
  version = "8.16.2";
  pythonDeps = with prev.python313Packages; [
    tzdata
    tzlocal
  ];
in
{
  calibre = prev.calibre.overrideAttrs (old: rec {
    inherit version;

    src = prev.fetchurl {
      url = "https://download.calibre-ebook.com/${version}/calibre-${version}.tar.xz";
      hash = "sha256-AYfQQ1T1PMB0EUHaAml37jCnfvoMN7GDm94FiCIsHGw=";
    };

    propagatedBuildInputs = (old.propagatedBuildInputs or [ ]) ++ pythonDeps;

    nativeCheckInputs = (old.nativeCheckInputs or [ ]) ++ pythonDeps;
  });
}
