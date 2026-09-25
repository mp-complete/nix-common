# Troubleshooting

Run the diagnostic chain in order:

```bash
# A. Is Edge listening on the Windows CDP port?
powershell.exe -NoProfile -Command \
  "Get-NetTCPConnection -LocalPort 9222 -State Listen -ErrorAction SilentlyContinue"

# B. Is the forwarder listening on the WSL-reachable port?
powershell.exe -NoProfile -Command \
  "Get-NetTCPConnection -LocalPort 9223 -State Listen -ErrorAction SilentlyContinue"

# C. Can WSL reach it?
WIN_HOST=$(ip route show default | awk '/default/ {print $3}')
curl -v "http://$WIN_HOST:9223/json/version"
```

## Symptoms → fixes

| Symptom                                                              | Likely cause                                                                                                          | Fix                                                                                                                                                  |
| -------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| `Could not locate msedge.exe`                                        | Edge installed in a non-default path.                                                                                 | Set `WSL_BROWSER_EDGE_EXE` to its Windows path.                                                                                                      |
| `No Python found on Windows`                                         | No `python.exe` on Windows PATH and none at `C:\Python31{2,3,4}`.                                                     | Install Python or set `WSL_BROWSER_PYTHON_EXE`.                                                                                                       |
| `Edge CDP port 9222 never came up`                                   | Another Edge instance with the same `User Data - CDP` profile is already open without `--remote-debugging-port`.       | Close all windows of that profile (titles contain "Profile 1") and rerun.                                                                            |
| (A) shows the port listening, (C) hangs                               | Forwarder not running, or Windows Defender Firewall blocks `python.exe` inbound from the Hyper-V vSwitch subnet.       | Confirm (B) is empty → relaunch with debug logs. Otherwise allow `python.exe` through Windows Firewall for private networks.                          |
| `chromium.connect_over_cdp` returns but `browser.contexts` is empty   | Edge launched headlessly or all profile windows were closed.                                                          | Rerun `bootstrap.sh` — it always reopens an `about:blank` window for the profile.                                                                    |
| Capture `.txt` is very short / missing visible content                | Page lazy-loads content as you scroll, or renders via canvas.                                                         | Increase `--wait-ms`, or fall back to reading the `.png`. Some sites also paint content into shadow DOM that `inner_text` can't see.                  |
| `open_url.py` opens the page but title is "Sign in to your account"  | First-time use of this profile against an AAD-protected site.                                                         | Use `ask_user` to ask the user to sign in to the Edge window, then re-call your next helper. The cookies persist in the profile for future sessions. |
| Subsequent sessions still ask to sign in                              | Conditional access / device-bound auth → cookies don't persist across new device-state checks.                        | Sign in again. Consider enrolling Edge as a managed/registered browser if your org permits.                                                          |
| Wrong tab gets focused / captured                                     | Multiple tabs match your `--match` substring.                                                                          | Pass a more specific substring (e.g., include the query string), or use `list_tabs.py` to find the right URL first.                                  |
| Helpers say `playwright` is not importable                            | Running them with a Python that lacks Playwright (e.g., system Python).                                                | Run inside a nix-shell / venv that has `playwright` + the Chromium driver. Example: `nix-shell -p python3 python3Packages.playwright playwright-driver.browsers`. |

## Hard reset

If state is wedged, nuke the forwarder and the CDP-profile Edge:

```bash
powershell.exe -NoProfile -Command \
  "Get-CimInstance Win32_Process -Filter \"Name='python.exe'\" \
   | Where-Object { \$_.CommandLine -like '*wsl_browser_cdp_forwarder*' } \
   | ForEach-Object { Stop-Process -Id \$_.ProcessId -Force }"

powershell.exe -NoProfile -Command \
  "Get-Process msedge -ErrorAction SilentlyContinue \
   | Where-Object { \$_.MainWindowTitle -like '*Profile 1*' } \
   | Stop-Process -Force"
```

Then `bootstrap.sh` again.
