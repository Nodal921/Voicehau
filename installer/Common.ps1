# Shared helpers for install.ps1 and uninstall.ps1
# Game detection logic inspired by LuteBot3 (LuteBotForm.GetPakPath / InstallLuteMod).

$script:ModName       = 'Voicehau'
$script:PakName       = 'VoicehauWindowsClient.pak'
$script:LoaderPakName = 'AutoLoaderWindowsClient.pak'
$script:LoaderHeader  = '[/AutoLoader/BP_AutoLoaderActor.BP_AutoLoaderActor_C]'
$script:ClientModLine = 'ClientMods=/Voicehau/BP_VoicehauClient.BP_VoicehauClient_C'
$script:StayTimeLine  = 'ModListWidgetStayTime=5.0'
$script:ModsHeader    = '[Mods]'
$script:StartupMapLine = 'ModStartupMap=/AutoLoader/ClientModNew_MainMenu.ClientModNew_MainMenu'
$script:AutoLoaderUrl = 'https://mordhau.mod.io/clientside-mod-autoloader'

function Write-Step($msg)  { Write-Host "==> $msg" -ForegroundColor Cyan }
function Write-Ok($msg)    { Write-Host "    OK  $msg" -ForegroundColor Green }
function Write-Warn2($msg) { Write-Host "    /!\ $msg" -ForegroundColor Yellow }
function Write-Err($msg)   { Write-Host "    ERROR  $msg" -ForegroundColor Red }

function Test-MordhauRoot([string]$root) {
    # $root = folder that contains Mordhau.exe (e.g. ...\steamapps\common\Mordhau)
    if ([string]::IsNullOrWhiteSpace($root)) { return $false }
    return (Test-Path -LiteralPath (Join-Path $root 'Mordhau.exe'))
}

function Get-SteamRoots {
    $roots = @()
    foreach ($k in 'HKLM:\SOFTWARE\Wow6432Node\Valve\Steam', 'HKLM:\SOFTWARE\Valve\Steam') {
        try { $v = (Get-ItemProperty -LiteralPath $k -ErrorAction Stop).InstallPath; if ($v) { $roots += $v } } catch {}
    }
    try { $v = (Get-ItemProperty -LiteralPath 'HKCU:\Software\Valve\Steam' -ErrorAction Stop).SteamPath; if ($v) { $roots += ($v -replace '/', '\') } } catch {}
    return $roots | Select-Object -Unique
}

function Find-MordhauRoot {
    # 1) Steam libraries (libraryfolders.vdf lists every library)
    foreach ($steam in Get-SteamRoots) {
        $vdf = Join-Path $steam 'steamapps\libraryfolders.vdf'
        $libs = @($steam)
        if (Test-Path -LiteralPath $vdf) {
            $content = Get-Content -LiteralPath $vdf -Raw
            foreach ($m in [regex]::Matches($content, '"path"\s*"([^"]+)"')) {
                $libs += ($m.Groups[1].Value -replace '\\\\', '\')
            }
        }
        foreach ($lib in ($libs | Select-Object -Unique)) {
            $candidate = Join-Path $lib 'steamapps\common\Mordhau'
            if (Test-MordhauRoot $candidate) { return $candidate }
        }
    }
    # 2) Default Epic Games location
    $epic = 'C:\Program Files\Epic Games\Mordhau'
    if (Test-MordhauRoot $epic) { return $epic }

    # 3) Ask the user
    Add-Type -AssemblyName System.Windows.Forms
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg.Description = 'Select your Mordhau install folder (the one that contains Mordhau.exe)'
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK -and (Test-MordhauRoot $dlg.SelectedPath)) {
        return $dlg.SelectedPath
    }
    return $null
}

function Get-CustomPaksPath([string]$mordhauRoot) {
    return (Join-Path $mordhauRoot 'Mordhau\Content\CustomPaks')
}

function Get-DefaultGameIni {
    return (Join-Path $env:LOCALAPPDATA 'Mordhau\Saved\Config\WindowsClient\Game.ini')
}

function Assert-MordhauClosed {
    # Mordhau rewrites Game.ini when it exits: it must be closed or our changes get overwritten.
    if (Get-Process -Name 'Mordhau', 'Mordhau-Win64-Shipping' -ErrorAction SilentlyContinue) {
        Write-Err 'Mordhau is running. Close the game, then run this script again.'
        return $false
    }
    return $true
}

function Read-IniLines([string]$path) {
    # Keep the content as is (ASCII/UTF-8, CRLF); work line by line.
    $text = [System.IO.File]::ReadAllText($path)
    $list = New-Object 'System.Collections.Generic.List[string]'
    $list.AddRange([string[]]($text -split "\r?\n"))
    return ,$list   # the comma stops PowerShell from unrolling the list into an array
}

function Write-IniLines([string]$path, $lines) {
    $text = ($lines -join "`r`n")
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($path, $text, $utf8NoBom)
}

function Backup-File([string]$path) {
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $bak = "$path.voicehau-$stamp.bak"
    Copy-Item -LiteralPath $path -Destination $bak
    return $bak
}

function Find-LineIndex($lines, [string]$exact) {
    for ($i = 0; $i -lt $lines.Count; $i++) { if ($lines[$i].Trim() -eq $exact) { return $i } }
    return -1
}

function Find-SectionEnd($lines, [int]$headerIndex) {
    # Index of the first line of the next section (or end of file)
    for ($i = $headerIndex + 1; $i -lt $lines.Count; $i++) { if ($lines[$i] -match '^\s*\[') { return $i } }
    return $lines.Count
}

function Test-SectionHasKey($lines, [int]$headerIndex, [string]$keyPrefix) {
    $end = Find-SectionEnd $lines $headerIndex
    for ($i = $headerIndex + 1; $i -lt $end; $i++) { if ($lines[$i].Trim().StartsWith($keyPrefix)) { return $true } }
    return $false
}
