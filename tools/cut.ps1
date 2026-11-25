# Cuts the addon's window or live panel out of a capture of the whole game window
# (tools\capture.ps1, or tools\capture-watch.ps1 -Full), wherever they stood on the screen.
#
#   powershell -ExecutionPolicy Bypass -File tools\cut.ps1 -In media\raw\shot-04.png -List
#   powershell -ExecutionPolicy Bypass -File tools\cut.ps1 -In media\raw\shot-04.png -Frame window -Out media\screens\04-zones.png
#
# -Frame window   the main window
# -Frame panel    the live panel (with -Below <pixels> to keep what hangs under it, a list)
# -Frame both     one picture holding both, with the game around them (-Margin, 60 by default)
# -Box l,t,w,h    no searching: cut exactly this
# -ShrinkTo <pixels>  shrink the result to this width
#
# How they are found: in the flat "Keepnet" theme each of them is a rectangle with a border of
# pure black, two pixels thick. Pure black in a straight line hundreds of pixels long does not
# happen in the game world, so the rows that hold such a line are the tops and bottoms of our
# frames. Other themes draw other borders: take the pictures in the Keepnet theme.
param(
    [Parameter(Mandatory = $true)][string]$In,
    [string]$Out,
    [ValidateSet('window', 'panel', 'both')][string]$Frame = 'window',
    [int]$Margin = -1,
    [int]$Below = 0,
    [string]$Box,
    # Shrink the result to this many pixels across (for a cut of most of the screen)
    [int]$ShrinkTo = 0,
    [switch]$List
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing @'
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
public static class KeepnetCut {
    // Every horizontal line of pure black at least "least" pixels long: { y, first x, last x }
    public static List<int[]> BlackRuns(Bitmap bitmap, int least) {
        var runs = new List<int[]>();
        var area = new Rectangle(0, 0, bitmap.Width, bitmap.Height);
        BitmapData data = bitmap.LockBits(area, ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
        try {
            var row = new byte[data.Stride];
            for (int y = 0; y < bitmap.Height; y++) {
                Marshal.Copy(IntPtr.Add(data.Scan0, y * data.Stride), row, 0, data.Stride);
                int start = -1;
                for (int x = 0; x <= bitmap.Width; x++) {
                    bool black = x < bitmap.Width && row[x * 4] == 0 && row[x * 4 + 1] == 0 && row[x * 4 + 2] == 0;
                    if (black && start < 0) start = x;
                    if (!black && start >= 0) {
                        if (x - start >= least) runs.Add(new int[] { y, start, x - 1 });
                        start = -1;
                    }
                }
            }
        } finally { bitmap.UnlockBits(data); }
        return runs;
    }
}
'@

$source = New-Object System.Drawing.Bitmap (Resolve-Path $In).Path

# Lines with the same ends belong to one frame: its first row is the top, its last the bottom
$frames = @()
if (-not $Box) {
    $groups = @{}
    foreach ($run in [KeepnetCut]::BlackRuns($source, 200)) {
        $key = '{0},{1}' -f $run[1], $run[2]
        if (-not $groups.ContainsKey($key)) { $groups[$key] = @($run[0], $run[0]) }
        $groups[$key][1] = $run[0]
    }
    foreach ($key in $groups.Keys) {
        $x0, $x1 = $key -split ',' | ForEach-Object { [int]$_ }
        $y0, $y1 = $groups[$key]
        if ($y1 - $y0 -ge 100) {
            $frames += [pscustomobject]@{ Left = $x0; Top = $y0; Width = $x1 - $x0 + 1; Height = $y1 - $y0 + 1 }
        }
    }
    $frames = @($frames | Sort-Object Width -Descending)
}
if ($List) {
    $frames | ForEach-Object { '{0},{1},{2},{3}' -f $_.Left, $_.Top, $_.Width, $_.Height }
    $source.Dispose()
    return
}
if (-not $Out) { throw 'Say where the picture goes: -Out <file>.' }

if ($Box) {
    $left, $top, $width, $height = $Box -split '[ ,;x]+' | Where-Object { $_ -ne '' } | ForEach-Object { [int]$_ }
} else {
    # The window is the wide one; the panel the widest that is clearly narrower
    $window = $frames | Where-Object { $_.Width -ge 1000 } | Select-Object -First 1
    $panel = $frames | Where-Object { $_.Width -lt 1000 -and $_.Height -ge 300 } | Select-Object -First 1
    $wanted = switch ($Frame) {
        'window' { , @($window) }
        'panel' { , @($panel) }
        'both' { , @($window, $panel) }
    }
    if ($wanted -contains $null) { throw "No $Frame in this picture. Frames found: $($frames.Count)" }
    if ($Margin -lt 0) { $Margin = if ($Frame -eq 'both') { 60 } else { 10 } }
    $left = ($wanted | ForEach-Object { $_.Left } | Measure-Object -Minimum).Minimum - $Margin
    $top = ($wanted | ForEach-Object { $_.Top } | Measure-Object -Minimum).Minimum - $Margin
    $right = ($wanted | ForEach-Object { $_.Left + $_.Width } | Measure-Object -Maximum).Maximum + $Margin
    $bottom = ($wanted | ForEach-Object { $_.Top + $_.Height } | Measure-Object -Maximum).Maximum + $Margin + $Below
    $left = [math]::Max(0, $left); $top = [math]::Max(0, $top)
    $width = [math]::Min($source.Width, $right) - $left
    $height = [math]::Min($source.Height, $bottom) - $top
}

$picture = $source.Clone((New-Object System.Drawing.Rectangle $left, $top, $width, $height), $source.PixelFormat)
if ($ShrinkTo -gt 0 -and $ShrinkTo -lt $width) {
    $small = New-Object System.Drawing.Bitmap $ShrinkTo, ([int]($height * $ShrinkTo / $width))
    $graphics = [System.Drawing.Graphics]::FromImage($small)
    $graphics.InterpolationMode = 'HighQualityBicubic'
    $graphics.DrawImage($picture, 0, 0, $small.Width, $small.Height)
    $graphics.Dispose(); $picture.Dispose()
    $picture = $small
    $width, $height = $small.Width, $small.Height
}
$target = if ([System.IO.Path]::IsPathRooted($Out)) { $Out } else { Join-Path (Get-Location) $Out }
if ($target -match '\.jpe?g$') {
    # A cut of the game world is several MB as a PNG; CurseForge's gallery refused one of 2.8 MB
    $codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
    $quality = New-Object System.Drawing.Imaging.EncoderParameters 1
    $quality.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter ([System.Drawing.Imaging.Encoder]::Quality), 92L
    $picture.Save($target, $codec, $quality)
} else {
    $picture.Save($target, [System.Drawing.Imaging.ImageFormat]::Png)
}
$picture.Dispose(); $source.Dispose()
Write-Output ('{0}  ({1} x {2}, from {3},{4})' -f $Out, $width, $height, $left, $top)
