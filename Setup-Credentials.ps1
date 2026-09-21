#Requires -Version 5.1

<#
    Run this ONCE, interactively, before using shares.ps1 for the first
    time (and again any time the NAS password changes).

    It prompts for your NAS credentials and stores them in Windows
    Credential Manager under the target below. shares.ps1 then relies
    on that stored credential and never contains the password itself -
    keep it that way if this repo is ever pushed to GitHub.
#>

$NasHost = "media"

$Cred = Get-Credential -Message "Enter your credentials for \\$NasHost"

if (-not $Cred)
{
    Write-Host "Cancelled - no credentials saved." -ForegroundColor Yellow
    exit 1
}

$PlainPassword = $Cred.GetNetworkCredential().Password

cmd /c "cmdkey /add:$NasHost /user:$($Cred.UserName) /pass:$PlainPassword" | Out-Null

# Clear the plaintext copy from memory as soon as we're done with it
$PlainPassword = $null

Write-Host ""
Write-Host "Credentials for \\$NasHost saved to Windows Credential Manager." -ForegroundColor Green
Write-Host "You can now run shares.ps1." -ForegroundColor Green
