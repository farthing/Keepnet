# Smudges parts of a picture so that what is written there can't be read: the name over
# another player's head in a capture of the game world, for one.
#
#   powershell -ExecutionPolicy Bypass -File tools\smudge.ps1 -In media\raw\shot.png -Boxes "2081,682,82,22; 2189,652,84,24" -Out media\raw\shot-clean.png
#
# -Boxes   one or more areas, each "left,top,width,height" in the picture's own pixels,
#          separated by semicolons
# -Out     where the result goes (the picture given is never changed); .png or .jpg
# -Strength  how far each area is shrunk before it is blown up again (8 by default: text
#          a dozen pixels high is gone; a bigger number for bigger writing)
#
# How: each area is shrunk to a few pixels and stretched back over itself, which keeps the
# colours of the place and loses its detail. Look at the result at full size afterwards.
param(
    [Parameter(Mandatory = $true)][string]$In,
    [Parameter(Mandatory = $true)][string]$Boxes,
    [Parameter(Mandatory = $true)][string]$Out,
    [int]$Strength = 8
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$source = [System.Drawing.Image]::FromFile((Resolve-Path $In))
$picture = New-Object System.Drawing.Bitmap $source.Width, $source.Height, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$canvas = [System.Drawing.Graphics]::FromImage($picture)
$canvas.DrawImage($source, 0, 0, $source.Width, $source.Height)
$source.Dispose()

$count = 0
foreach ($entry in ($Boxes -split ';')) {
    $numbers = @($entry -split '[ ,x]+' | Where-Object { $_ -ne '' } | ForEach-Object { [int]$_ })
    if ($numbers.Count -eq 0) { continue }
    if ($numbers.Count -ne 4) { throw "A box needs four numbers (left, top, width, height): '$entry'" }
    $box = New-Object System.Drawing.Rectangle $numbers[0], $numbers[1], $numbers[2], $numbers[3]
    $box.Intersect((New-Object System.Drawing.Rectangle 0, 0, $picture.Width, $picture.Height))
    if ($box.Width -lt 2 -or $box.Height -lt 2) { throw "Box outside the picture: '$entry'" }

    # Shrunk ...
    $smallWidth = [Math]::Max(1, [int]($box.Width / $Strength))
    $smallHeight = [Math]::Max(1, [int]($box.Height / $Strength))
    $small = New-Object System.Drawing.Bitmap $smallWidth, $smallHeight
    $shrink = [System.Drawing.Graphics]::FromImage($small)
    $shrink.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $shrink.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $shrink.DrawImage($picture, (New-Object System.Drawing.Rectangle 0, 0, $smallWidth, $smallHeight), $box,
        [System.Drawing.GraphicsUnit]::Pixel)
    $shrink.Dispose()

    # ... and stretched back over the same place. Tiling the edges keeps the smudge from
    # fading into black along its border.
    $canvas.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBilinear
    $canvas.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $edges = New-Object System.Drawing.Imaging.ImageAttributes
    $edges.SetWrapMode([System.Drawing.Drawing2D.WrapMode]::TileFlipXY)
    $canvas.DrawImage($small, $box, 0, 0, $smallWidth, $smallHeight, [System.Drawing.GraphicsUnit]::Pixel, $edges)
    $edges.Dispose()
    $small.Dispose()
    $count++
}
$canvas.Dispose()

$target = $Out
if (-not [System.IO.Path]::IsPathRooted($Out)) { $target = Join-Path (Get-Location) $Out }
$format = [System.Drawing.Imaging.ImageFormat]::Png
if ($target -match '\.jpe?g$') { $format = [System.Drawing.Imaging.ImageFormat]::Jpeg }
$picture.Save($target, $format)
Write-Output ("{0}  ({1} x {2}, {3} areas smudged)" -f $target, $picture.Width, $picture.Height, $count)
$picture.Dispose()
