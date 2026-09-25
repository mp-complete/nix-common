{ lib, config, ... }:
# Pi extension registry (the engine).
#
# Extensions are declared as pure-data *specs* in the `pi.extensions`
# namespace (one file per extension under ./). Derivations are built
# lazily by `flake.lib.buildPiExtension pkgs spec` at wrapper wrap-time,
# so nothing here lands in `packages.*`. For debugging, every built
# extension is also exposed under `legacyPackages.<system>.piExtensions.<name>`
# — buildable with `nix build .#piExtensions.x86_64-linux.<name>` but
# hidden from `nix flake show` (collapsed to "omitted").
let
  # Scoped/unscoped npm name + version -> registry tarball URL. Scoped
  # packages live at .../@scope/name/-/name-<version>.tgz (no @scope in
  # the filename).
  npmTarballUrl =
    pname: version:
    let
      unscoped = lib.last (lib.splitString "/" pname);
    in
    "https://registry.npmjs.org/${pname}/-/${unscoped}-${version}.tgz";

  # spec -> derivation, parameterized by the wrap-time pkgs.
  #
  # Three shapes, in order of escalation:
  #   * simple   : pname/version/hash            -> unpack tarball
  #   * vendored : + vendor = [ { dir; pname; version; hash; } ]
  #                                              -> also drop tarballs into node_modules/<dir>
  #   * bespoke  : build = { pkgs; lib; fetchNpm; src; meta; passthru; }: drv
  #                                              -> full escape hatch (lockfiles, substituteInPlace, …)
  buildPiExtension =
    pkgs: spec:
    let
      fetchNpm =
        {
          pname,
          version,
          hash,
        }:
        pkgs.fetchurl {
          url = npmTarballUrl pname version;
          inherit hash;
        };

      unscoped = lib.last (lib.splitString "/" spec.pname);
      # Lazy: only forced when a builder actually uses it. Bespoke local
      # extensions (no npm tarball) leave hash = "" and never touch src.
      src = fetchNpm { inherit (spec) pname version hash; };

      meta = {
        description = "Pi coding agent extension: ${spec.pname}";
        homepage = "https://www.npmjs.com/package/${spec.pname}";
        license = lib.licenses.mit; # most pi extensions are MIT; override per-spec
      }
      // spec.meta;

      passthru = {
        inherit (spec) pname version;
        piExtension = true;
      };
    in
    if spec.build != null then
      spec.build {
        inherit
          pkgs
          lib
          fetchNpm
          src
          meta
          passthru
          unscoped
          ;
      }
    else
      pkgs.runCommand "pi-ext-${unscoped}-${spec.version}"
        {
          inherit src meta passthru;
        }
        (
          ''
            mkdir -p $out
            tar -xzf $src --strip-components=1 -C $out
          ''
          + lib.concatMapStrings (v: ''
            mkdir -p $out/node_modules/${v.dir}
            tar -xzf ${
              fetchNpm { inherit (v) pname version hash; }
            } --strip-components=1 -C $out/node_modules/${v.dir}
          '') spec.vendor
        );

  vendorType = lib.types.submodule {
    options = {
      dir = lib.mkOption {
        type = lib.types.str;
        description = "node_modules subdirectory to unpack into (e.g. \"typebox\" or \"@scope/pkg\").";
      };
      pname = lib.mkOption { type = lib.types.str; };
      version = lib.mkOption { type = lib.types.str; };
      hash = lib.mkOption { type = lib.types.str; };
    };
  };

  specType = lib.types.submodule {
    options = {
      pname = lib.mkOption {
        type = lib.types.str;
        description = "npm package name (scoped or unscoped).";
      };
      version = lib.mkOption {
        type = lib.types.str;
        default = "0.0.0";
      };
      hash = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "SRI integrity of the npm tarball (registry dist.integrity). Empty for bespoke local extensions.";
      };
      vendor = lib.mkOption {
        type = lib.types.listOf vendorType;
        default = [ ];
        description = "Extra tarballs to unpack into node_modules (deps the package ships without a lockfile for).";
      };
      build = lib.mkOption {
        type = lib.types.nullOr (lib.types.functionTo lib.types.package);
        default = null;
        description = ''
          Escape hatch. A function `{ pkgs, lib, fetchNpm, src, meta, passthru, unscoped }: drv`
          returning the extension derivation. Use for lockfile installs,
          substituteInPlace hotfixes, or local (non-npm) extensions.
        '';
      };
      meta = lib.mkOption {
        type = lib.types.attrsOf lib.types.raw;
        default = { };
        description = "Merged into the derivation meta (e.g. platforms, license).";
      };
    };
  };
in
{
  options.pi.extensions = lib.mkOption {
    type = lib.types.attrsOf specType;
    default = { };
    description = ''
      Declarative pi extension registry. Each entry is a pure-data spec;
      derivations are built lazily at wrapper wrap-time via
      `flake.lib.buildPiExtension`. One file per extension under
      modules/ai/extensions/.
    '';
  };

  config = {
    flake.lib.buildPiExtension = buildPiExtension;

    perSystem =
      { pkgs, ... }:
      {
        # Debug handle, hidden from `nix flake show`.
        legacyPackages.piExtensions = lib.mapAttrs (_: buildPiExtension pkgs) config.pi.extensions;
      };
  };
}
