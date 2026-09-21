#Requires -Version 5.1

Clear-Host
$Host.UI.RawUI.WindowTitle = "Map Media Network Drives"

# $PSScriptRoot can be blank depending on how the script is launched
# (e.g. certain shortcuts, right-click "Run with PowerShell" variants,
# or pasting into a console). Fall back to MyInvocation if needed.
$ScriptDir = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($ScriptDir))
{
    $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
}
if ([string]::IsNullOrWhiteSpace($ScriptDir))
{
    $ScriptDir = Get-Location
}

Write-Host "Script directory: $ScriptDir" -ForegroundColor DarkGray

$NasHost  = "media"

# Credentials for $NasHost are expected to already be stored in Windows
# Credential Manager - run Setup-Credentials.ps1 once first if you
# haven't. This script deliberately does not contain the password.

$Mappings = @(
    @{Drive="A"; Share="\\media\jason\audiobooks"},
    @{Drive="F"; Share="\\media\docker"},
    @{Drive="J"; Share="\\media\home"},
    @{Drive="M"; Share="\\media\jason\more"},
    @{Drive="N"; Share="\\media\downloads"},
    @{Drive="R"; Share="\\media\jason\comics"},
    @{Drive="S"; Share="\\media\jason\music"},
    @{Drive="T"; Share="\\media\jason\tv"},
    @{Drive="V"; Share="\\media\jason\movies"},
    @{Drive="W"; Share="\\media\jason\web"},
    @{Drive="Y"; Share="\\media\jason\youtube"}
)

Clear-Host

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "     Map Media Network Drives" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

$Log = @()

Write-Host "Removing existing mappings..." -ForegroundColor Yellow

foreach($M in $Mappings)
{
    $Drive = "$($M.Drive):"

    # Try deleting, then verify the letter is actually free.
    # Retry a few times with a short backoff - Windows doesn't always
    # release a drive letter instantly, especially over a slow network.
    $MaxAttempts = 5
    $Attempt = 0
    $Released = $false

    do
    {
        $Attempt++

        cmd /c "net use $Drive /delete /y" *> $null

        Start-Sleep -Milliseconds 500

        # If the drive letter no longer shows up in `net use`, it's free
        $StillMapped = (cmd /c "net use $Drive" 2>&1) -join ' '

        if ($StillMapped -match "not.*(a|an).*(network|valid)|not found|no such")
        {
            $Released = $true
        }
    }
    while (-not $Released -and $Attempt -lt $MaxAttempts)

    if (-not $Released)
    {
        Write-Host "  Warning: could not confirm $Drive was released" -ForegroundColor DarkYellow
    }
}

$Success = 0
$Failed = 0
$Count = $Mappings.Count
$Current = 0

foreach($M in $Mappings)
{
    $Current++

    Write-Progress `
        -Activity "Mapping Network Drives" `
        -Status "$Current of $Count" `
        -PercentComplete (($Current/$Count)*100)

    Write-Host ""
    Write-Host "Mapping $($M.Drive): -> $($M.Share)" -NoNewline

    $MapAttempts = 0
    $MaxMapAttempts = 3

    do
    {
        $MapAttempts++

        $Output = cmd /c "net use $($M.Drive): `"$($M.Share)`" /persistent:yes" 2>&1
        $Exit = $LASTEXITCODE

        # Error 85 = "local device name is already in use".
        # Force-delete and try again before giving up.
        if ($Exit -eq 85 -and $MapAttempts -lt $MaxMapAttempts)
        {
            cmd /c "net use $($M.Drive): /delete /y" *> $null
            Start-Sleep -Milliseconds 750
        }
    }
    while ($Exit -eq 85 -and $MapAttempts -lt $MaxMapAttempts)

    if($Exit -eq 0)
    {
        $Success++
        Write-Host "   SUCCESS" -ForegroundColor Green
    }
    else
    {
        $Failed++

        Write-Host "   FAILED ($Exit)" -ForegroundColor Red

        $Log += [PSCustomObject]@{
            Time   = Get-Date
            Drive  = "$($M.Drive):"
            Share  = $M.Share
            Error  = $Exit
            Output = ($Output -join ' ')
        }
    }
}

Write-Progress -Activity "Mapping Network Drives" -Completed

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Completed" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Successful : $Success" -ForegroundColor Green
Write-Host "Failed     : $Failed" -ForegroundColor Red

if($Failed -gt 0)
{
    $LogFile = Join-Path $ScriptDir ("MapMediaShares_{0}.log" -f (Get-Date -Format "yyyyMMdd_HHmmss"))

    $Log | Format-List | Out-File $LogFile

    Write-Host ""
    Write-Host "Log written to:" -ForegroundColor Yellow
    Write-Host $LogFile -ForegroundColor Yellow

    exit 1
}

# ------------------------------------------------------------
# Import custom drive icons
# ------------------------------------------------------------

$RegFile = Join-Path $ScriptDir "Drive_Icons.reg"

Write-Host ""
Write-Host "Looking for reg file at:" -ForegroundColor DarkGray
Write-Host $RegFile -ForegroundColor DarkGray

if (Test-Path $RegFile)
{
    Write-Host ""
    Write-Host "Importing drive icons..." -ForegroundColor Cyan

    $Result = Start-Process `
        -FilePath "reg.exe" `
        -ArgumentList "import `"$RegFile`"" `
        -Wait `
        -PassThru `
        -NoNewWindow

    if ($Result.ExitCode -eq 0)
    {
        Write-Host "Drive icons imported successfully." -ForegroundColor Green

        Write-Host "Refreshing Explorer..." -ForegroundColor Cyan

        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
        Start-Process explorer.exe
    }
    else
    {
        Write-Host "Failed to import Drive_Icons.reg." -ForegroundColor Red
    }
}
else
{
    Write-Host ""
    Write-Host "Drive_Icons.reg not found:" -ForegroundColor Yellow
    Write-Host $RegFile -ForegroundColor Yellow
}

exit 0