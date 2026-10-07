# Media Share Mapper

Scripts to map a Synology NAS's shares to drive letters on Windows, keep them
reconnected reliably across reboots, and optionally apply custom drive icons.

## Files

- **Setup-Credentials.ps1** — run once, interactively. Prompts for your NAS
  username/password and stores them in Windows Credential Manager. No
  credentials are stored in this repo.
- **shares.ps1** — deletes and re-creates the mapped drives listed in
  `$Mappings`, retrying automatically if Windows hasn't released a drive
  letter yet. Also imports `Drive_Icons.reg` if present (needs admin rights
  — see note below).
- **Setup-AutoMapTask.ps1** — run once, as Administrator. Registers a
  Scheduled Task that runs `shares.ps1` ~30 seconds after logon. This works
  around Windows' unreliable built-in "reconnect persistent network drives
  at logon" behaviour for non-domain NAS shares.
- **Drive_Icons.reg** — optional custom icons for the mapped drives.

## Setup order

1. Edit the `$Mappings` list in `shares.ps1` and the `$NasHost` value in
   both `shares.ps1` and `Setup-Credentials.ps1` to match your NAS.
2. Run `Setup-Credentials.ps1` once, interactively, and enter your NAS
   credentials when prompted.
3. Run `shares.ps1` to map the drives immediately.
4. Run `Setup-AutoMapTask.ps1` **as Administrator** once, to make step 3
   happen automatically after every login.

## Notes

- **Never hardcode credentials into `shares.ps1`.** It's designed to pull
  them from Windows Credential Manager instead, specifically so this repo
  is safe to commit and push.
- The Scheduled Task created by `Setup-AutoMapTask.ps1` runs **non-elevated**
  on purpose. If it ran elevated, drives would map into a separate
  "elevated" logon session and be invisible to normal Explorer windows.
  As a result, the `Drive_Icons.reg` import step in `shares.ps1` will fail
  silently when run via the task (harmless) — import that `.reg` file
  manually, once, via right-click → Merge, if you want custom icons.
- If a drive fails to map, check the auto-generated
  `MapMediaShares_<timestamp>.log` file next to the script for the exact
  `net use` error.

## License

MIT — see [LICENSE](LICENSE).
