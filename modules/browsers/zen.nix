{ ... }:
{
  flake.modules.homeManager.desktop-core = {
    imports = [ builtins.scoped.commonInputs.zen-browser.homeModules.beta ];
    programs.zen-browser.enable = true;
  };
}
