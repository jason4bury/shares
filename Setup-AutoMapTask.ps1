#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
    Run this ONCE (as Administrator) to register a scheduled task that
    automatically re-maps the media drives ~30 seconds after you log in.

    Why: Windows' built-in "reconnect at logon" for persistent network
    drives is unreliable for NAS/workgroup shares - if the network or
    Credential Manager isn't fully ready yet, the reconnect silently
    fails and the drive just doesn't appear. Running shares.ps1 as a
    scheduled task after a short delay avoids that race condition.

    NOTE: this task runs NON-elevated on purpose. If it ran elevated,
    the drives would map inside a separate "elevated" logon session and
    become invisible to your normal (non-elevated) Explorer windows -
    Windows treats elevated and non-elevated processes as different
    sessions for network drive purposes. Because of this, the
    Drive_Icons.reg import inside shares.ps1 will fail silently here
    (it needs admin rights) - that's expected and harmless. Import that
    .reg file manually, once, by right-clicking it if you want the
    custom icons; it only needs to be done once, not on every logon.
#>

$ScriptPath = Join-Path $PSScriptRoot "shares.ps1"

if (-not (Test-Path $ScriptPath))
{
    Write-Host "Could not find shares.ps1 next to this script at:" -ForegroundColor Red
    Write-Host $ScriptPath -ForegroundColor Red
    exit 1
}

$TaskName = "Map Media Network Drives"

$Action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$ScriptPath`""

$Trigger = New-ScheduledTaskTrigger -AtLogOn
$Trigger.Delay = "PT30S"   # wait 30 seconds after logon before running

$Settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -ExecutionTimeLimit (New-TimeSpan -Minutes 5)

$Principal = New-ScheduledTaskPrincipal `
    -UserId $env:USERNAME `
    -LogonType Interactive `
    -RunLevel Limited

# Remove any existing task with the same name first
Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue

Register-ScheduledTask `
    -TaskName $TaskName `
    -Action $Action `
    -Trigger $Trigger `
    -Settings $Settings `
    -Principal $Principal `
    -Description "Re-maps media NAS network drives shortly after logon (works around unreliable Windows persistent-drive reconnect)."

Write-Host ""
Write-Host "Scheduled task '$TaskName' created." -ForegroundColor Green
Write-Host "It will run shares.ps1 (hidden) 30 seconds after you log in." -ForegroundColor Green
Write-Host ""
Write-Host "You can view/edit it any time in Task Scheduler, or test it now with:" -ForegroundColor DarkGray
Write-Host "  Start-ScheduledTask -TaskName `"$TaskName`"" -ForegroundColor DarkGray
