# Watches one part of the game's window and saves a picture each time what is shown there
# changes and has settled. For screenshots of several screens in a row: start it, then click
# through the screens at your own pace.
#
#   powershell -ExecutionPolicy Bypass -File tools\capture-watch.ps1 -Crop 742,206,1445,862 -Seconds 150
#
# Add -Full to save the whole game window each time (the crop is then only what is watched),
# for cutting the pictures out afterwards.
#
# -Crop is left, top, width, height inside the game window. Pictures go to
# <project>\media\raw\watch-NN.png  (not committed).
param(
    # As one piece of text, e.g. "742,206,1445,862": that is how it arrives from the command line
    [Parameter(Mandatory = $true)][string]$Crop,
    [int]$Seconds = 120,
    [string]$Prefix = 'watch',
    [string]$OutDir = '',
    [int]$Most = 40,
    # Watch the -Crop part for changes, but save the whole game window each time
    [switch]$Full,
    # While the watched part keeps moving (the addon's window is closed and the world shows
    # there), also save the whole game window every so many seconds, as <prefix>-tick-NN.png.
    # For pictures of the live panel, which sits over moving water. 0 = off.
    [double]$Ticks = 0
)

$ErrorActionPreference = 'Stop'
if (-not $OutDir) { $OutDir = Join-Path (Split-Path $PSScriptRoot -Parent) 'media\raw' }
Add-Type -AssemblyName System.Drawing
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class KeepnetWatch {
    [StructLayout(LayoutKind.Sequential)] public struct POINT { public int X, Y; }
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
    [DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr hWnd, ref POINT point);
    [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr hWnd, out RECT rect);
    [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
}
'@
[KeepnetWatch]::SetProcessDPIAware() | Out-Null

$game = Get-Process | Where-Object { $_.Name -eq 'Wow' -and $_.MainWindowHandle -ne 0 } | Select-Object -First 1
if (-not $game) { throw 'The game is not running.' }
$origin = New-Object KeepnetWatch+POINT
[KeepnetWatch]::ClientToScreen($game.MainWindowHandle, [ref]$origin) | Out-Null
$box = @($Crop -split '[ ,;x]+' | Where-Object { $_ -ne '' } | ForEach-Object { [int]$_ })
if ($box.Count -ne 4) { throw 'Crop needs four numbers: left, top, width, height.' }
$left, $top, $width, $height = ($origin.X + $box[0]), ($origin.Y + $box[1]), $box[2], $box[3]
New-Item -ItemType Directory -Force $OutDir | Out-Null
$client = New-Object KeepnetWatch+RECT
[KeepnetWatch]::GetClientRect($game.MainWindowHandle, [ref]$client) | Out-Null

function Get-Part($x, $y, $w, $h) {
    $bitmap = New-Object System.Drawing.Bitmap $w, $h
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.CopyFromScreen($x, $y, 0, 0, $bitmap.Size)
    $graphics.Dispose()
    return $bitmap
}

function Get-Shot { return Get-Part $left $top $width $height }

# A fingerprint: the brightness at a grid of points
function Get-Print($bitmap) {
    $print = New-Object 'int[]' (64 * 40)
    $i = 0
    for ($y = 0; $y -lt 40; $y++) {
        for ($x = 0; $x -lt 64; $x++) {
            $pixel = $bitmap.GetPixel([int](($x + 0.5) * $width / 64), [int](($y + 0.5) * $height / 40))
            $print[$i] = $pixel.R + $pixel.G + $pixel.B
            $i++
        }
    }
    return , $print
}

# How many of the points differ clearly. Counting points, not averaging brightness: a small
# list opening inside a large watched area must count, and slow water behind it must not.
function Get-Difference($a, $b) {
    if (-not $a -or -not $b) { return 9999 }
    $count = 0
    for ($i = 0; $i -lt $a.Length; $i++) { if ([math]::Abs($a[$i] - $b[$i]) -gt 45) { $count++ } }
    return $count
}

$saved = $null      # fingerprint of the last picture saved
$previous = $null   # fingerprint of the last frame looked at
$count = 0
$ticked = 0
$nextTick = Get-Date
$until = (Get-Date).AddSeconds($Seconds)
while ((Get-Date) -lt $until -and $count -lt $Most) {
    $shot = Get-Shot
    $print = Get-Print $shot
    # Different from what was saved last, and the same as a moment ago (not mid-change)
    if ((Get-Difference $print $saved) -ge 6 -and (Get-Difference $print $previous) -lt 3) {
        $count++
        $path = Join-Path $OutDir ('{0}-{1:00}.png' -f $Prefix, $count)
        if ($Full) {
            $whole = Get-Part $origin.X $origin.Y $client.Right $client.Bottom
            $whole.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
            $whole.Dispose()
        } else {
            $shot.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
        }
        $saved = $print
        Write-Output ("saved {0}" -f (Split-Path $path -Leaf))
    }
    if ($Ticks -gt 0 -and $previous -and (Get-Difference $print $previous) -ge 10 -and (Get-Date) -ge $nextTick) {
        $ticked++
        $whole = Get-Part $origin.X $origin.Y $client.Right $client.Bottom
        $whole.Save((Join-Path $OutDir ('{0}-tick-{1:00}.png' -f $Prefix, $ticked)), [System.Drawing.Imaging.ImageFormat]::Png)
        $whole.Dispose()
        $nextTick = (Get-Date).AddSeconds($Ticks)
        Write-Output ("saved {0}-tick-{1:00}.png" -f $Prefix, $ticked)
    }
    $previous = $print
    $shot.Dispose()
    Start-Sleep -Milliseconds 450
}
Write-Output "done: $count pictures"
