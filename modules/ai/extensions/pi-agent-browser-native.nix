{ ... }:
{
  # pi-agent-browser-native — exposes the `agent-browser` CLI to pi as a
  # native tool for browser automation. Requires `agent-browser` on PATH
  # (added to the pi wrappers' runtimePkgs).
  # https://github.com/fitchmultz/pi-agent-browser-native
  pi.extensions.pi-agent-browser-native = {
    pname = "pi-agent-browser-native";
    version = "0.2.52";
    hash = "sha512-IcL36M00v/I/iQY7+8F2dIvsmpEjRsnuGnXQLnkEtSVqWkxy39+UDTAP9lYfnt5x+YYUIJXbp1qIDaLqQY/DZQ==";
  };
}
