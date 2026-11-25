# Copies the addon into the game. Run it after every edit, then /reload in the game.
#
#   powershell -ExecutionPolicy Bypass -File tools\install.ps1            # copy
#   powershell -ExecutionPolicy Bypass -File tools\install.ps1 -Remove    # take it out again
#
# It mirrors  <project>\Keepnet  to  <game>\Interface\AddOns\Keepnet  (files removed from
# the project are removed from the copy too). A brand-new addon needs a full restart of the game
# to be seen; after that /reload is enough. The saved data lives elsewhere (WTF\...) and is
# never touched.
#
# Your own sounds for the rare-catch alert: put .ogg or .mp3 files in  <project>\sounds-local\
# (never committed) and this script copies them to  <game>\Interface\AddOns\KeepnetSounds\
# and writes the little list there that tells Keepnet their names. That folder is separate
# from the addon's own, so installing a new version never removes them. The game only sees a
# new sound file after a restart.
#
# Why a copy and not a folder link: on this Windows build a link made without administrator
# rights is an "untrusted mount point", and some programs refuse to read through it (PowerShell
# and Python do: error 448). Whether the game would is unknown, so no link.
param(
    [string]$AddOns = 'D:\Games\World of Warcraft\_forever_\Interface\AddOns',
    [switch]$Remove
)

$ErrorActionPreference = 'Stop'
$source = Join-Path (Split-Path $PSScriptRoot -Parent) 'Keepnet'
$target = Join-Path $AddOns 'Keepnet'

if (-not (Test-Path $AddOns)) { throw "AddOns folder not found: $AddOns" }
if (-not (Test-Path (Join-Path $source 'Keepnet.toc'))) { throw "Addon source not found: $source" }

if (Test-Path $target) {
    $item = Get-Item $target -Force
    if ($item.LinkType) {
        # An old folder link: delete the link only, never what it points to
        [System.IO.Directory]::Delete($target, $false)
        Write-Output "Removed old link $target"
    }
    elseif ((Get-ChildItem $target -Force | Measure-Object).Count -gt 0 -and
            -not (Test-Path (Join-Path $target 'Keepnet.toc'))) {
        # Mirroring deletes what isn't in the project, so only ever mirror onto our own copy
        throw "$target exists and is not a Keepnet copy. Move it away first."
    }
}

if ($Remove) {
    if (Test-Path $target) {
        Remove-Item $target -Recurse -Force -Confirm:$false
        Write-Output "Removed $target"
    }
    return
}

robocopy $source $target /MIR /NJH /NJS /NDL /NP /NFL | Out-Null
# robocopy: 0 to 7 are success (nothing to do, files copied, extras removed), 8 and up are errors
if ($LASTEXITCODE -ge 8) { throw "robocopy failed with code $LASTEXITCODE" }
# Mark the copy as a development build (Updates.lua reads this line of the TOC): it hears
# about newer versions like any copy, but never tells other players about its own, which
# may be a version nobody can download yet. The zip release.py builds has no such line.
$tocPath = Join-Path $target 'Keepnet.toc'
$tocLines = [System.IO.File]::ReadAllLines($tocPath)
$marked = @()
foreach ($line in $tocLines) {
    $marked += $line
    if ($line -like '## Version:*') { $marked += '## X-Keepnet-Build: dev' }
}
# No byte-order mark: the game reads the TOC as plain text
[System.IO.File]::WriteAllLines($tocPath, $marked, (New-Object System.Text.UTF8Encoding($false)))

$count = (Get-ChildItem $target -Recurse -File | Measure-Object).Count
Write-Output "Copied $count files to $target (marked as a development build)"

# Your own sounds, if there are any
$soundSource = Join-Path (Split-Path $PSScriptRoot -Parent) 'sounds-local'
$soundTarget = Join-Path $AddOns 'KeepnetSounds'
$sounds = @()
if (Test-Path $soundSource) {
    $sounds = @(Get-ChildItem $soundSource -File | Where-Object { $_.Extension -in '.ogg', '.mp3' } | Sort-Object Name)
}
if ($sounds.Count -gt 0) {
    New-Item -ItemType Directory -Force $soundTarget | Out-Null
    foreach ($sound in $sounds) { Copy-Item $sound.FullName (Join-Path $soundTarget $sound.Name) -Force }
    # Every sound file in the folder is listed, including ones put there by hand
    $names = @(Get-ChildItem $soundTarget -File | Where-Object { $_.Extension -in '.ogg', '.mp3' } |
        Sort-Object Name | ForEach-Object { '    "' + $_.Name.Replace('\', '').Replace('"', '') + '",' })
    $lua = @('-- Written by Keepnet''s tools\install.ps1: the sound files in this folder.', 'KeepnetSoundFiles = {') + $names + @('}')
    $toc = @('## Interface: 16001', '## Title: Keepnet sounds', '## Notes: Your own sound files for Keepnet''s rare-catch alert', '', 'Files.lua')
    # No byte-order mark: the game reads these as plain text
    $utf8 = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllLines((Join-Path $soundTarget 'Files.lua'), $lua, $utf8)
    [System.IO.File]::WriteAllLines((Join-Path $soundTarget 'KeepnetSounds.toc'), $toc, $utf8)
    Write-Output "Copied $($sounds.Count) of your own sounds to $soundTarget ($($names.Count) listed)"
}
exit 0
