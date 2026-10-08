{ ... }:
{
  flake.modules.homeManager.skills =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      builtinSkills = [
        "writing-skills"
        "html-report"
        "context-reflect"
      ];
      mattPocockSkills = [
        "engineering/diagnosing-bugs"
        "engineering/domain-modeling"
        "engineering/grill-with-docs"
        "engineering/prototype"
        "engineering/research"
        "engineering/setup-matt-pocock-skills"
        "engineering/wayfinder"
        "productivity/grill-me"
        "productivity/grilling"
      ];
    in
    {
      imports = [ builtins.scoped.commonInputs.agent-skills.homeManagerModules.default ];

      options.skills = {
        builtinExtra = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Consumer-owned always-enabled skills.";
        };
        availableExtra = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Additional consumer-owned names accepted by skills.extra.";
        };
        extra = lib.mkOption {
          type = lib.types.listOf (lib.types.enum config.skills.availableExtra);
          default = [ ];
          description = "Optional skills enabled from the consumer registry.";
        };
      };

      config = {
        programs.agent-skills = {
          enable = true;
          sources = {
            nix-common.path = ./_skills;
            matt-pocock.path = builtins.scoped.commonInputs.matt-pocock-skills + "/skills";
            unslop = {
              path = builtins.scoped.commonInputs.unslop;
              # The repository root is the skill; keep its scripts and references together.
              filter.maxDepth = 0;
            };
          };
          skills.enable =
            builtinSkills
            ++ config.skills.builtinExtra
            ++ mattPocockSkills
            ++ [ "unslop" ]
            ++ config.skills.extra;
          targets.agents = {
            enable = true;
            structure = "link";
            dest = ".agents/skills";
          };
        };
        # Unslop invokes its stdlib-only scanners with python3.
        home.packages = [ pkgs.python3 ];
        home.sessionVariables.AGENTS_SKILLS_DIR = "${config.home.homeDirectory}/.agents/skills";
      };
    };
}
