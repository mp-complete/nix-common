{ ... }:
{
  pi-next.extensions.pi-notify-official = {
    kind = "extension";
    build =
      pkgs:
      let
        # Use the official example from the same locked source as the runtime.
        source = pkgs.pi-coding-agent.src;
      in
      "${source}/packages/coding-agent/examples/extensions/notify.ts";
  };
}
