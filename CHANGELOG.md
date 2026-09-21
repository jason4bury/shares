# Changelog

All notable changes to this project are documented here.

## [Unreleased]

### Added
- `LICENSE` (MIT).
- `Setup-Credentials.ps1` — one-time interactive script that prompts for NAS
  credentials and stores them in Windows Credential Manager.
- `README.md` and `.gitignore` for the repo.

### Changed
- `Drive_Icons.reg` is now tracked in the repo (removed from `.gitignore`)
  and included in `README.md`'s file list, rather than being treated as a
  local-only file.
- `shares.ps1` no longer contains a hardcoded username/password. It now
  relies entirely on the credential stored via `Setup-Credentials.ps1`,
  so the script is safe to commit to source control.

### Fixed
- `Setup-AutoMapTask.ps1` scheduled task reverted to running **non-elevated**.
  Running it elevated caused drives to be mapped into a separate elevated
  logon session, making them invisible in normal Explorer windows, and
  triggered an unwanted Explorer restart when the (now-successful) registry
  import ran.

## [0.4.0] - 2026-08-02

### Added
- `Setup-AutoMapTask.ps1` to register a Scheduled Task that runs
  `shares.ps1` ~30 seconds after logon, working around Windows' unreliable
  built-in reconnect-at-logon behaviour for non-domain NAS shares.
- Credentials saved to Windows Credential Manager via `cmdkey` so mapped
  drives can reconnect without a password prompt after reboot.

### Changed
- `net use` calls no longer pass `/user:`/password inline; they rely on
  the stored Credential Manager entry instead.

## [0.3.0] - 2026-07-28

### Added
- Retry/backoff logic when deleting existing mappings, verifying each
  drive letter is actually released before moving on.
- Retry logic when mapping a drive: on error 85 ("device already in use"),
  force-delete and retry up to 3 times before logging a failure.

### Fixed
- Intermittent `System error 85` when a drive letter hadn't been fully
  released before the script tried to remap it.

## [0.2.0] - 2026-07-28

### Changed
- Reverted to explicit NAS credentials (`/user:` + password) instead of
  relying on the current Windows login, since the NAS account differs
  from the Windows account.
- Robust script-directory resolution (`$ScriptDir`) added, falling back
  from `$PSScriptRoot` to `$MyInvocation.MyCommand.Path` to the current
  location, to fix `Drive_Icons.reg` not being found depending on how
  the script was launched. Added debug output showing the resolved path.

## [0.1.0] - Initial version

### Added
- Base script to map a set of Synology NAS shares to drive letters via
  `net use`, originally using `Get-Credential` to prompt for credentials
  interactively.
- Drive icon import from `Drive_Icons.reg` after mapping completes.
- Failure logging to a timestamped `MapMediaShares_<timestamp>.log` file.
