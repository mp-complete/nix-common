{ ... }:
let
  inputs = builtins.scoped.commonInputs;
  skillLib = inputs.agent-skills.lib.agent-skills;
  sources.pi-nix-wrapper = {
    path = inputs.pi-nix-wrapper;
    subdir = "skills";
  };
  selection = skillLib.selectSkills {
    inherit sources;
    catalog = skillLib.discoverCatalog sources;
    allowlist = [ "mk-pi-extension" ];
  };
in
{
  # Keep the skill inside the wrapper's resources. Importing common must not
  # add Pi-specific sources or selections to the shared Home Manager skills
  # bucket; consumers own any separate global skill installation.
  flake.wrappers.pi-next =
    { pkgs, ... }:
    let
      bundle = skillLib.mkBundle { inherit pkgs selection; };
    in
    {
      skills = [ (bundle.forTarget "pi") ];
    };
}
