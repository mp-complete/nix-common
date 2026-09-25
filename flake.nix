{
  description = "Reusable dendritic NixOS and Home Manager modules";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:denful/import-tree";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agent-skills = {
      url = "github:Kyure-A/agent-skills-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    matt-pocock-skills = {
      url = "github:mattpocock/skills";
      flake = false;
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix.url = "github:Mic92/sops-nix";
    nix-openclaw = {
      url = "github:openclaw/nix-openclaw";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    nix-wrapper-modules = {
      url = "github:milespossing/nix-wrapper-modules/fix/television-themes";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    llm-agents.url = "github:numtide/llm-agents.nix";
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia.url = "github:noctalia-dev/noctalia/cachix";
    worktrunk-flake = {
      url = "github:max-sixty/worktrunk";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
    fennel-ls-nvim-docs = {
      url = "git+https://git.sr.ht/~micampe/fennel-ls-nvim-docs";
      flake = false;
    };
  };

  outputs =
    inputs:
    let
      commonInputs = builtins.removeAttrs inputs [ "self" ];
      commonModule = {
        imports = [ (inputs.import-tree.addScoped { inherit commonInputs; } ./modules) ];
      };
    in
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ commonModule ];
      # Producer settings are only for standalone package/check outputs.
      # Consumers import commonModule unevaluated and supply their own identity.
      username = "example";
      git = {
        userName = "Example User";
        userEmail = "example@example.invalid";
        forgejoUrls = [ ];
      };
      flake.flakeModules.default = commonModule;
    };
}
