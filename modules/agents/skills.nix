{ ... }:
{
  flake.modules.homeManager.skills =
    { config, lib, ... }:
    let
      builtinSkills = [
        "writing-skills"
        "html-report"
        "ado-pr-markdown"
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
      availableSkills = [
        "figma-to-spec"
        "fluent-ui-v9"
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
          type = lib.types.listOf (lib.types.enum (availableSkills ++ config.skills.availableExtra));
          default = [ ];
          description = "Optional skills enabled from the shared or consumer registry.";
        };
      };

      config = {
        programs.agent-skills = {
          enable = true;
          sources = {
            nix-common.path = ./_skills;
            matt-pocock.path = builtins.scoped.commonInputs.matt-pocock-skills + "/skills";
          };
          skills.enable =
            builtinSkills ++ config.skills.builtinExtra ++ mattPocockSkills ++ config.skills.extra;
          targets.agents = {
            enable = true;
            structure = "link";
            dest = ".agents/skills";
          };
        };
        home.sessionVariables.AGENTS_SKILLS_DIR = "${config.home.homeDirectory}/.agents/skills";
      };
    };
}
