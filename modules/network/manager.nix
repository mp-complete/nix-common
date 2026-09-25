{
  # NetworkManager is a per-host opt-in via the `networkmanager` bucket. It
  # pulls in wpa_supplicant.service, which fails on hosts without wireless
  # (e.g. the WSL host), so only hosts that actually use NetworkManager
  # (laplace's wifi) include it. Wired hosts fall back to `networking.useDHCP`.
  flake.modules.nixos.networkmanager.networking.networkmanager.enable = true;

  # systemd-resolved is harmless everywhere and gives consistent DNS, so it
  # stays global (incl. hosts on plain DHCP).
  flake.modules.nixos.base.services.resolved.enable = true;
}
