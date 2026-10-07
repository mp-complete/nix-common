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
  # Extend the shared skills feature; keep upstream skill implementations in
  # their pinned source rather than copying them into this repository.
  flake.modules.homeManager.skills.programs.agent-skills = {
    inherit sources;
    skills.enableAll = [ "pi-nix-wrapper" ];
  };

  # Reuse the source and builder without coupling the standalone wrapper to
  # Home Manager. The shared target resolves to the same canonical skill files,
  # so Pi can deduplicate ambient discovery after a Home Manager deployment.
  flake.wrappers.pi-next =
    { pkgs, ... }:
    let
      bundle = skillLib.mkBundle { inherit pkgs selection; };
    in
    {
      skills = [ (bundle.forTarget "pi") ];
    };
}
