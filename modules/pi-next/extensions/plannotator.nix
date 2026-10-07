{ lib, ... }:
{
  pi-next.extensions.plannotator.build =
    pkgs:
    let
      npmSource = import ./_npm-source.nix { inherit pkgs lib; };
      lock = builtins.fromJSON (builtins.readFile ./plannotator-dependencies.json);
      # Each dependency retains its own links, not a flattened node_modules.
      deps = lib.mapAttrs (
        _: spec:
        let
          source = npmSource {
            inherit (spec) npmPackage version hash;
            nodeModules = lib.mapAttrs (_: key: deps.${key}) spec.dependencies;
          };
        in
        if spec.npmPackage == "node-pty" && pkgs.stdenv.hostPlatform.isLinux then
          source.overrideAttrs (old: {
            nativeBuildInputs = old.nativeBuildInputs ++ [ pkgs.stdenv.cc ];
            # node-pty 1.1.0 has no Linux prebuild. Compile its N-API module
            # directly, with Nix headers/libraries; never run its npm hooks.
            buildCommand = old.buildCommand + ''
              mkdir -p "$out/build/Release"
              c++ -std=c++17 -shared -fPIC -O2 -Wall -D_FORTIFY_SOURCE=2 \
                -DNAPI_CPP_EXCEPTIONS -pthread \
                -I${pkgs.nodejs}/include/node \
                -I${deps.${spec.dependencies.node-addon-api}} \
                "$out/src/unix/pty.cc" -lutil -o "$out/build/Release/pty.node"
            '';
          })
        else
          source
      ) lock.packages;
    in
    npmSource {
      npmPackage = "@plannotator/pi-extension";
      version = "0.28.7";
      hash = "sha512-AoabuWzli1Tws9a5SUzU6Mx8f1HQMLZBhH/PBKVbBSqc9WBSpwcwgfKPZtC1E1/nkmfF8ikSlAm2+EXn3UI3Mw==";
      nodeModules = lib.mapAttrs (_: key: deps.${key}) lock.root;
    };
}
