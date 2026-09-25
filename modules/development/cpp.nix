{
  flake.modules.nixos.dev =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        gcc
        cmake
        resterm
        openapi-tui
      ];
    };
}
