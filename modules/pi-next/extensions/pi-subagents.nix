{ lib, ... }:
{
  pi-next.extensions.pi-subagents.build =
    pkgs:
    let
      npmSource = import ./_npm-source.nix { inherit pkgs lib; };
      # Compiled JS and ready-to-load dependencies; keep the agent definitions,
      # skills, prompts and docs together. Never invoke the npm installer.
      jsbi = npmSource {
        npmPackage = "jsbi";
        version = "4.3.2";
        hash = "sha512-9fqMSQbhJykSeii05nxKl4m6Eqn2P6rOlYiS+C5Dr/HPIU/7yZxu5qzbs40tgaFORiw2Amd0mirjxatXYMkIew==";
      };
      temporalPolyfill = npmSource {
        npmPackage = "@js-temporal/polyfill";
        version = "0.5.1";
        hash = "sha512-hloP58zRVCRSpgDxmqCWJNlizAlUgJFqG2ypq79DCvyv9tHjRYMDOcPFjzfl/A1/YxDvRCZz8wvZvmapQnKwFQ==";
        nodeModules = { inherit jsbi; };
      };
      acorn = npmSource {
        npmPackage = "acorn";
        version = "8.18.0";
        hash = "sha512-lGq+9yr1/GuAWaVYIHRjvvySG5/4VfKIvC8EWxStPdcDh/Ka7FG3twP6v4d5BkravUilhIAsG4Qj83t02LWUPQ==";
      };
      jiti = npmSource {
        npmPackage = "jiti";
        version = "2.7.0";
        hash = "sha512-AC/7JofJvZGrrneWNaEnJeOLUx+JlGt7tNa0wZiRPT4MY1wmfKjt2+6O2p2uz2+skll8OZZmJMNqeke7kKbNgQ==";
      };
      undici = npmSource {
        npmPackage = "undici";
        version = "8.10.2";
        hash = "sha512-/y4/bH9YNU5hi9NIrpOuvGXFcxrj3CMrV+/AYpowAYTpHn8gX/XPFjNy766FPoYY0miQhdW977JFWKGNhBdwyQ==";
      };
      yaml = npmSource {
        npmPackage = "yaml";
        version = "2.8.3";
        hash = "sha512-AvbaCLOO2Otw/lW5bmh9d/WEdcDFdQp2Z2ZUH3pX9U2ihyUY0nvLv7J6TrWowklRGPYbB/IuIMfYgxaCPg5Bpg==";
      };
    in
    npmSource {
      npmPackage = "pi-subagents";
      version = "0.76.1";
      hash = "sha512-DTHVUUyLx5KfwikpSQF4sWIKaazbxanAoKd8v4ZGt9OqLM2xNQ79BrPHjaqOARipoUb0kZIKyEYwTPItPqYq1g==";
      nodeModules = {
        inherit
          acorn
          jiti
          undici
          yaml
          ;
        "@js-temporal/polyfill" = temporalPolyfill;
      };
    };
}
