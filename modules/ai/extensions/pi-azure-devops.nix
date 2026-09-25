{ ... }:
{
  # @patimweb/pi-azure-devops — Azure DevOps integration for pi: work
  # items, boards, repos, pull requests, pipelines, and test plans.
  # https://github.com/Smotherer007/pi-azure-devops
  pi.extensions.pi-azure-devops = {
    pname = "@patimweb/pi-azure-devops";
    version = "1.4.1";
    hash = "sha512-X5AnA8prSXwTpDkiPVitmrYpbjPxA44h82/lHaAbkin+ep0u8XBpOQJBXKyzyw9dDSPBsVohRLLtlZpIPwleIg==";
    meta = {
      description = "Pi coding agent extension: Azure DevOps work items, repos, PRs, pipelines, and test plans";
      homepage = "https://github.com/Smotherer007/pi-azure-devops";
    };

    build =
      {
        pkgs,
        fetchNpm,
        src,
        meta,
        passthru,
        ...
      }:
      let
        packageLock = pkgs.fetchurl {
          url = "https://raw.githubusercontent.com/Smotherer007/pi-azure-devops/v1.4.1/package-lock.json";
          hash = "sha256-ZDeWHwAyhUMggEzbi8P1jjp/bHoAY4AFNn69HLm4tfA=";
        };
        typebox = fetchNpm {
          pname = "typebox";
          version = "1.1.38";
          hash = "sha512-pZ0aQPmMmXoUvSbeuWf/Hzsc+avNw/Zd6VeE8CFgkVGWyuHPJvqeJJDeJqLve+K70LvjYIoleGcoJHPT17cWoA==";
        };
      in
      pkgs.buildNpmPackage {
        inherit (passthru) pname version;
        inherit src meta passthru;
        npmDepsHash = "sha256-8Sr+XVSXvwV00Q/3UsJ3CcYO73/RBFMS5zXJDMZAawk=";

        postPatch = ''
          cp ${packageLock} package-lock.json
        '';

        # The upstream lock includes peer/dev dependencies (including an
        # older pi-coding-agent used only for local typechecking). Runtime
        # only needs azure-devops-node-api plus typebox, which we add below.
        npmInstallFlags = [
          "--omit=dev"
          "--omit=peer"
        ];
        dontNpmBuild = true;
        dontNpmCheck = true;
        installPhase = ''
          runHook preInstall
          mkdir -p $out
          cp -r . $out/
          rm -f $out/package-lock.json $out/node_modules/.package-lock.json
          rm -rf $out/node_modules/@earendil-works
          mkdir -p $out/node_modules/typebox
          tar -xzf ${typebox} --strip-components=1 -C $out/node_modules/typebox
          runHook postInstall
        '';
      };
  };
}
