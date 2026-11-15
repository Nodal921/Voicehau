<#
  Installs Voicehau (Mordhau client-side mod):
    1. copies VoicehauWindowsClient.pak into Mordhau\Content\CustomPaks
    2. registers the mod with the Clientside Mod Autoloader in Game.ini
  Same mechanism as LuteMod/LuteBot3.

  Parameters (all optional):
    -MordhauPath  folder that contains Mordhau.exe (otherwise auto-detected from Steam/Epic)
    -GameIni      path to Game.ini (otherwise %LOCALAPPDATA%\Mordhau\Saved\Config\WindowsClient\Game.ini)
    -PakSource    path to the .pak to install (otherwise ..\pak\VoicehauWindowsClient.pak)
    -DryRun       writes nothing, only shows what would be done
#>
param(
    [string]$MordhauPath,
    [string]$GameIni,
    [string]$PakSource,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Common.ps1')

Write-Host ''
Write-Host "  Installing $ModName" -ForegroundColor White
Write-Host ''
if ($DryRun) { Write-Warn2 'DryRun mode: no file will be modified.' }

if (-not (Assert-MordhauClosed)) { exit 1 }

# --- 1. Mod .pak ----------------------------------------------------------
Write-Step 'Looking for the mod file'
if (-not $PakSource) { $PakSource = Join-Path $PSScriptRoot "..\pak\$PakName" }
if (-not (Test-Path -LiteralPath $PakSource)) {
    Write-Err "Not found: $PakSource"
    Write-Host '    Download the release zip (Voicehau-vX.Y.zip) from the Releases page of the'
    Write-Host '    GitHub repository instead of the source code: it includes the .pak.'
    exit 1
}
$PakSource = (Resolve-Path -LiteralPath $PakSource).Path
Write-Ok $PakSource

# --- 2. Mordhau folder ----------------------------------------------------
Write-Step 'Looking for Mordhau'
if (-not $MordhauPath) { $MordhauPath = Find-MordhauRoot }
if (-not (Test-MordhauRoot $MordhauPath)) {
    Write-Err 'Could not find Mordhau.exe. Run again with -MordhauPath "C:\...\steamapps\common\Mordhau".'
    exit 1
}
$customPaks = Get-CustomPaksPath $MordhauPath
Write-Ok $MordhauPath

# --- 3. Autoloader --------------------------------------------------------
Write-Step 'Checking the Clientside Mod Autoloader'
$loaderPak = Join-Path $customPaks $LoaderPakName
if (Test-Path -LiteralPath $loaderPak) {
    Write-Ok 'Autoloader found'
} else {
    Write-Warn2 "The autoloader is not installed ($LoaderPakName missing from CustomPaks)."
    Write-Host  "        Without it, Mordhau will not load $ModName. Subscribe to / download it here:"
    Write-Host  "        $AutoLoaderUrl"
    Write-Host  '        Installation continues.'
}

# --- 4. Copy the .pak -----------------------------------------------------
Write-Step "Copying $PakName to CustomPaks"
$pakTarget = Join-Path $customPaks $PakName
if (-not $DryRun) {
    New-Item -ItemType Directory -Force -Path $customPaks | Out-Null
    try {
        Copy-Item -LiteralPath $PakSource -Destination $pakTarget -Force
    } catch {
        Write-Err "Could not copy to $customPaks : $($_.Exception.Message)"
        Write-Host '    Try running the installer as administrator.'
        exit 1
    }
}
Write-Ok $pakTarget

# --- 5. Game.ini ----------------------------------------------------------
Write-Step 'Registering the mod in Game.ini'
if (-not $GameIni) { $GameIni = Get-DefaultGameIni }
if (-not (Test-Path -LiteralPath $GameIni)) {
    Write-Err "Game.ini not found: $GameIni"
    Write-Host '    Start Mordhau once (up to the main menu), close it, then run the installer again.'
    exit 1
}

$lines = Read-IniLines $GameIni
$changed = $false

# 5a. Autoloader section + our ClientMods line
$alreadyRegistered = (Find-LineIndex $lines $ClientModLine) -ge 0
if ($alreadyRegistered) {
    Write-Ok 'Mod already registered with the autoloader'
} else {
    $h = Find-LineIndex $lines $LoaderHeader
    if ($h -ge 0) {
        # Insert right below the header, next to the other ClientMods (LuteMod, etc.)
        $lines.Insert($h + 1, $ClientModLine)
        if (-not (Test-SectionHasKey $lines $h 'ModListWidgetStayTime=')) {
            $lines.Insert($h + 2, $StayTimeLine)
        }
    } else {
        $lines.Add('')
        $lines.Add($LoaderHeader)
        $lines.Add($ClientModLine)
        $lines.Add($StayTimeLine)
    }
    $changed = $true
    Write-Ok "Added: $ClientModLine"
}

# 5b. [Mods] ModStartupMap (required for the autoloader to start)
$m = Find-LineIndex $lines $ModsHeader
if ($m -lt 0) {
    $lines.Add('')
    $lines.Add($ModsHeader)
    $lines.Add($StartupMapLine)
    $changed = $true
    Write-Ok "Added: $ModsHeader $StartupMapLine"
} elseif (-not (Test-SectionHasKey $lines $m 'ModStartupMap=')) {
    $lines.Insert($m + 1, $StartupMapLine)
    $changed = $true
    Write-Ok "Added: $StartupMapLine"
} else {
    Write-Ok 'ModStartupMap already set'
}

if ($changed) {
    if ($DryRun) {
        Write-Warn2 'DryRun: Game.ini not modified.'
    } else {
        $bak = Backup-File $GameIni
        Write-IniLines $GameIni $lines
        Write-Ok "Game.ini updated (backup: $bak)"
    }
}

Write-Host ''
Write-Host "  $ModName is installed." -ForegroundColor Green
Write-Host '  Start Mordhau: the autoloader mod list should show Voicehau at startup.'
Write-Host '  Keys: numpad 1-9 = voicelines, numpad 0 = repeat the last one (see README.md).'
Write-Host ''
exit 0
