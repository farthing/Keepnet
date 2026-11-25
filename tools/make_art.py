"""Draws the pictures the "Keepnet rounded" look is put together from, into Keepnet\\Media.

    .venv\\Scripts\\python tools\\make_art.py

Four small pictures, each the top left corner of a round-cornered frame, white on nothing so
the game can give them any colour (UI\\Round.lua turns the one picture over for the other
three corners):

    RoundFill8.tga, RoundFill4.tga   a quarter circle, for the inside of the frame
    RoundRing8.tga, RoundRing4.tga   a quarter ring, for its border

and one more for the "Glass" look, black's shape in white like the others:

    GlassShadow8.tga   the soft shadow beyond the top left corner of a big frame: nothing
                       where the frame is, then fading over 12 measures. Its last column and
                       last row are the shadow of a straight edge.

The number is how many of the interface's measures the corner is drawn across (8 for a
window, 4 for a button); the border is one measure thick in both, which is why the two rings
are two pictures and not one drawn at two sizes. Edges are smoothed by measuring how much of
each dot the shape covers.

The files are 32-bit TGA, not compressed, which every version of the game reads. Nothing here
is taken from anywhere: the shapes are circles.
"""
import math
import pathlib
import struct

MEDIA = pathlib.Path(__file__).resolve().parent.parent / "Keepnet" / "Media"
SAMPLES = 8  # per dot, each way


def coverage(size, inner):
    """How much of each dot lies between `inner` and `size` from the bottom right corner."""
    rows = []
    for y in range(size):
        row = []
        for x in range(size):
            inside = 0
            for sy in range(SAMPLES):
                for sx in range(SAMPLES):
                    px = x + (sx + 0.5) / SAMPLES
                    py = y + (sy + 0.5) / SAMPLES
                    distance = math.hypot(size - px, size - py)
                    if inner <= distance <= size:
                        inside += 1
            row.append(inside / (SAMPLES * SAMPLES))
        rows.append(row)
    return rows


def shadow(size, radius, reach):
    """The shadow beyond a round corner: `radius` and `reach` in measures, `size` dots across.

    The corner's circle is centred on the picture's bottom right corner. Inside it there is
    nothing; from its edge the shadow fades, fast at first, to nothing at `reach`.
    """
    per = size / (radius + reach)  # dots to a measure
    rows = []
    for y in range(size):
        row = []
        for x in range(size):
            total = 0.0
            for sy in range(SAMPLES):
                for sx in range(SAMPLES):
                    px = x + (sx + 0.5) / SAMPLES
                    py = y + (sy + 0.5) / SAMPLES
                    beyond = math.hypot(size - px, size - py) / per - radius
                    if 0 <= beyond < reach:
                        total += (1 - beyond / reach) ** 2.2
            row.append(0.6 * total / (SAMPLES * SAMPLES))
        rows.append(row)
    return rows


def write_tga(path, rows):
    """White, with `rows` (top row first, 0 to 1) as how solid each dot is."""
    size = len(rows)
    header = struct.pack("<BBBHHBHHHHBB", 0, 0, 2, 0, 0, 0, 0, 0, size, size, 32, 8)
    body = bytearray()
    for row in reversed(rows):  # the file starts with the bottom row
        for value in row:
            body += bytes((255, 255, 255, round(value * 255)))
    path.write_bytes(header + bytes(body))
    print(path.name, size, "x", size, len(header) + len(body), "bytes")


def main():
    MEDIA.mkdir(exist_ok=True)
    # (measures across, dots across): four dots to a measure
    for measures, size in ((8, 32), (4, 16)):
        write_tga(MEDIA / ("RoundFill%d.tga" % measures), coverage(size, 0))
        write_tga(MEDIA / ("RoundRing%d.tga" % measures), coverage(size, size - size / measures))
    # 8 measures of corner and 12 of shadow, 64 dots across
    write_tga(MEDIA / "GlassShadow8.tga", shadow(64, 8, 12))


if __name__ == "__main__":
    main()
