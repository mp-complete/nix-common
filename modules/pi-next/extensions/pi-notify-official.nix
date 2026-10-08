{ ... }:
{
  pi-next.extensions.pi-notify-official = {
    kind = "extension";
    build =
      pkgs:
      let
        # Use the official example from the same locked source as the runtime.
        source =
          builtins.scoped.commonInputs.pi-nix-wrapper.inputs.pi-nix.packages.${pkgs.stdenv.hostPlatform.system}.coding-agent.src;
      in
      "${source}/packages/coding-agent/examples/extensions/notify.ts";
  };
}
