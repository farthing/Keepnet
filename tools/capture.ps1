# Takes a picture of the game's window (only that window, not the rest of the desktop) and
# saves it as a PNG. For screenshots of the addon: have the game showing what you want, then
#
#   powershell -ExecutionPolicy Bypass -File tools\capture.ps1 -Name live-panel
#
# Pictures go to  <project>\media\raw\  (not committed: they can show other players' names).
# The game must be in a window or "Windowed (Fullscreen)"; exclusive fullscreen comes out black.
param(
    [string]$Name = ('shot-' + (Get-Date -Format 'HHmmss')),
    [string]$OutDir = (Join-Path (Split-Path $PSScriptRoot -Parent) 'media\raw'),
    # Left, top, width, height inside the game window, to save only part of it
    [string]$Crop
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class KeepnetCapture {
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
    [StructLayout(LayoutKind.Sequential)] public struct POINT { public int X, Y; }
    [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr hWnd, out RECT rect);
    [DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr hWnd, ref POINT point);
    [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
    [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr hWnd);
}
'@
[KeepnetCapture]::SetProcessDPIAware() | Out-Null

$game = Get-Process | Where-Object { $_.Name -eq 'Wow' -and $_.MainWindowHandle -ne 0 } | Select-Object -First 1
if (-not $game) { throw 'The game is not running.' }
$window = $game.MainWindowHandle
if ([KeepnetCapture]::IsIconic($window)) { throw 'The game window is minimised.' }

$rect = New-Object KeepnetCapture+RECT
[KeepnetCapture]::GetClientRect($window, [ref]$rect) | Out-Null
$origin = New-Object KeepnetCapture+POINT
[KeepnetCapture]::ClientToScreen($window, [ref]$origin) | Out-Null
$left, $top, $width, $height = $origin.X, $origin.Y, $rect.Right, $rect.Bottom
if ($Crop) {
    $box = @($Crop -split '[ ,;x]+' | Where-Object { $_ -ne '' } | ForEach-Object { [int]$_ })
    if ($box.Count -ne 4) { throw 'Crop needs four numbers: left, top, width, height.' }
    $left += $box[0]; $top += $box[1]; $width = $box[2]; $height = $box[3]
}
if ($width -le 0 -or $height -le 0) { throw 'The game window has no size.' }

$bitmap = New-Object System.Drawing.Bitmap $width, $height
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.CopyFromScreen($left, $top, 0, 0, $bitmap.Size)
New-Item -ItemType Directory -Force $OutDir | Out-Null
$path = Join-Path $OutDir ($Name + '.png')
$bitmap.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
$graphics.Dispose(); $bitmap.Dispose()
Write-Output "$path  ($width x $height)"
