{ lib, ... }:
{
  pi-next.extensions.pi-interactive-shell.build =
    pkgs:
    let
      npmSource = import ./_npm-source.nix { inherit pkgs lib; };
      # Dependencies ship built output. Pin the serializer's non-Pi peer too;
      # Pi-provided peers are resolved from the host runtime, not private copies.
      re2js = npmSource {
        npmPackage = "re2js";
        version = "2.8.6";
        hash = "sha512-xLgQil4kIUCrAzVk9fRSkxkFNwmygLFjVxXrLc65aE1F0+Zsb8rxumFBy4XKyvgMCTL6kilDq3EZ0piE2dP/Dg==";
      };
      typesafeSdk = npmSource {
        npmPackage = "@typesafe-ai/sdk";
        version = "0.6.0";
        hash = "sha512-IddX+Q0XM+VagOUZFeP7wZjaO4SHMdvnh2zEBdrZZnXedWI3BNK1lKhMx3ayrkFWvVLbVcUHJy6AVZlY+e6Jaw==";
      };
      xterm = npmSource {
        npmPackage = "@xterm/xterm";
        version = "5.5.0";
        hash = "sha512-hqJHYaQb5OptNunnyAnkHyM8aCjZ1MEIDTQu1iIbbTD/xops91NB5yq1ZK/dC2JDbVWtF23zUtl9JE2NqwT87A==";
      };
      xtermHeadless = npmSource {
        npmPackage = "@xterm/headless";
        version = "5.5.0";
        hash = "sha512-5xXB7kdQlFBP82ViMJTwwEc3gKCLGKR/eoxQm4zge7GPBl86tCdI0IdPJjoKd8mUSFXz5V7i/25sfsEkP4j46g==";
      };
      xtermSerialize = npmSource {
        npmPackage = "@xterm/addon-serialize";
        version = "0.13.0";
        hash = "sha512-kGs8o6LWAmN1l2NpMp01/YkpxbmO4UrfWybeGu79Khw5K9+Krp7XhXbBTOTc3GJRRhd6EmILjpR8k5+odY39YQ==";
        nodeModules."@xterm/xterm" = xterm;
      };
      zigpty =
        (npmSource {
          npmPackage = "zigpty";
          # ^0.1.6 does not allow the newer 0.2.x releases.
          version = "0.1.6";
          hash = "sha512-0B+6Xa4mKgyTNMq87HoGEUb30jQ08DZLEshSlgXPvUv+GB3E0zuTM+IUuYqe0CiaZyaZvCyx9snvGqxIKhl0sA==";
        }).overrideAttrs
          (old: {
            nativeBuildInputs =
              old.nativeBuildInputs ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.patchelf ];
            # Keep the package-relative location used by the import.meta.url loader.
            buildCommand =
              old.buildCommand
              + lib.optionalString pkgs.stdenv.hostPlatform.isLinux ''
                patchelf --set-rpath ${lib.makeLibraryPath [ pkgs.stdenv.cc.libc ]} \
                  "$out/prebuilds/zigpty.${
                    {
                      x86_64-linux = "linux-x64";
                      aarch64-linux = "linux-arm64";
                    }
                    .${pkgs.stdenv.hostPlatform.system}
                  }.node"
              '';
          });
    in
    npmSource {
      npmPackage = "pi-interactive-shell";
      version = "0.17.0";
      hash = "sha512-GRNitYwNpJMG8Kcg9heaD//4aT6taWyCt1ZOkvhgCFI/zPkpARJ8nefrX2URHG5RytRAvss09ZsTg7rM5NaPDQ==";
      nodeModules = {
        inherit re2js zigpty;
        "@typesafe-ai/sdk" = typesafeSdk;
        "@xterm/headless" = xtermHeadless;
        "@xterm/addon-serialize" = xtermSerialize;
      };
    };
}
