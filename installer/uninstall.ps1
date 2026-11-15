<#
  Uninstalls Voicehau: deletes the .pak and removes the ClientMods line from Game.ini.
  The autoloader and other mods (LuteMod...) are left untouched.
#>
param(
    [string]$MordhauPath,
    [string]$GameIni,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Common.ps1')

Write-Host ''
Write-Host "  Uninstalling $ModName" -ForegroundColor White
Write-Host ''
if ($DryRun) { Write-Warn2 'DryRun mode: no file will be modified.' }

if (-not (Assert-MordhauClosed)) { exit 1 }

Write-Step 'Deleting the .pak'
if (-not $MordhauPath) { $MordhauPath = Find-MordhauRoot }
if (Test-MordhauRoot $MordhauPath) {
    $pakTarget = Join-Path (Get-CustomPaksPath $MordhauPath) $PakName
    if (Test-Path -LiteralPath $pakTarget) {
        if (-not $DryRun) { Remove-Item -LiteralPath $pakTarget -Force }
        Write-Ok "Deleted: $pakTarget"
    } else {
        Write-Ok 'No .pak to delete'
    }
} else {
    Write-Warn2 'Mordhau not found, .pak not deleted.'
}

Write-Step 'Cleaning up Game.ini'
if (-not $GameIni) { $GameIni = Get-DefaultGameIni }
if (Test-Path -LiteralPath $GameIni) {
    $lines = Read-IniLines $GameIni
    $before = $lines.Count
    $lines.RemoveAll([Predicate[string]]{ param($l) $l.Trim() -eq $ClientModLine }) | Out-Null
    if ($lines.Count -ne $before) {
        if (-not $DryRun) {
            $bak = Backup-File $GameIni
            Write-IniLines $GameIni $lines
            Write-Ok "ClientMods line removed (backup: $bak)"
        } else {
            Write-Ok 'DryRun: the ClientMods line would be removed'
        }
    } else {
        Write-Ok 'Nothing to remove'
    }
} else {
    Write-Warn2 "Game.ini not found: $GameIni"
}

Write-Host ''
Write-Host "  $ModName is uninstalled." -ForegroundColor Green
Write-Host ''
exit 0
