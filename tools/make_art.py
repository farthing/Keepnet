"""Draws the pictures the "Keepnet rounded" look is put together from, and Keepnet's icon,
into Keepnet\\Media.

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

three for the mark over the fishing bobber (see "bobber mark" below):

    BobberRing.tga     a ring with a soft glow on both sides, 64 dots across
    BobberDisc.tga     a filled circle that sits dark behind the ring, 64 dots across
    BobberArrow.tga    a V pointing down at the bobber, 32 dots across

and the addon's icon, in its own colours (see "the icon" below):

    Icon.tga           64 dots across: the addon list, the minimap button, the addon menu

The files are 32-bit TGA, not compressed, which every version of the game reads. Nothing here
is taken from anywhere: the shapes are circles, and the icon is Keepnet's own logo.
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


# ------------------------------------------------------------------------------------- the icon
# Keepnet's own icon: the picture of the logo (media\logo.svg: a landing net with a fish in
# it), drawn again for the size an icon is seen at. On the minimap it is 18 dots across, where
# the logo's thin mesh and hoop would be gone, so the lines here are two to three times as
# thick, the mesh is coarser and the fish is bigger. The measures are the logo's (400 across).
ICON_SIZE = 64
ICON_SAMPLES = 6
ICON_VIEW = (203, 214, 396)   # the part of the logo's square that is drawn: centre x, y, width
ICON_TILT = 9                 # degrees the net leans back, as in the logo
HOOP = (196, 150, 134, 46)    # centre x, y, half width, half height
HOOP_LINE = 30
BAG_LINE = 22
MESH_STEP, MESH_LINE = 67, 10
FISH_AT, FISH_TILT, FISH_SCALE = (187, 257), 24, 1.28
FISH_EDGE = 9                 # the dark line round the fish
HANDLE = ((322, 140), (398, 80))
HANDLE_LINE = 30

WATER_TOP, WATER_BOTTOM = (0x1D, 0x38, 0x50), (0x0A, 0x11, 0x18)
GLOW = (0x4F, 0xC3, 0xF7)
MESH = (0x4F, 0xC3, 0xF7)
RIM = (0xD8, 0xF1, 0xFD)
DEEP = (0x0C, 0x1A, 0x26)
FISH = (0xFF, 0xD1, 0x00)
WOOD, WOOD_LIGHT = (0xE7, 0xB5, 0x48), (0xF6, 0xD5, 0x81)


def curve(p0, p1, p2, p3, steps=14):
    """A curve between p0 and p3, pulled towards p1 and p2, as a row of points."""
    points = []
    for i in range(steps + 1):
        t = i / steps
        u = 1 - t
        points.append((u * u * u * p0[0] + 3 * u * u * t * p1[0] + 3 * u * t * t * p2[0] + t * t * t * p3[0],
                       u * u * u * p0[1] + 3 * u * u * t * p1[1] + 3 * u * t * t * p2[1] + t * t * t * p3[1]))
    return points


def inside(outline, x, y):
    """Whether the point lies inside the closed outline."""
    hit = False
    xj, yj = outline[-1]
    for xi, yi in outline:
        if (yi > y) != (yj > y) and x < (xj - xi) * (y - yi) / (yj - yi) + xi:
            hit = not hit
        xj, yj = xi, yi
    return hit


def near(line, x, y, reach):
    """Whether the point is within `reach` of the line through the points."""
    limit = reach * reach
    for (ax, ay), (bx, by) in zip(line, line[1:]):
        dx, dy = bx - ax, by - ay
        along = ((x - ax) * dx + (y - ay) * dy) / ((dx * dx + dy * dy) or 1)
        along = 0 if along < 0 else 1 if along > 1 else along
        px, py = ax + along * dx - x, ay + along * dy - y
        if px * px + py * py <= limit:
            return True
    return False


def turn(x, y, degrees, about=(0, 0)):
    """The point turned clockwise on the screen (y runs down) about another."""
    angle = math.radians(degrees)
    x, y = x - about[0], y - about[1]
    return (about[0] + x * math.cos(angle) - y * math.sin(angle),
            about[1] + x * math.sin(angle) + y * math.cos(angle))


def icon(size=ICON_SIZE, samples=ICON_SAMPLES, clear=False):
    """The icon as rows of (red, green, blue), top row first. With `clear`, the net and fish
    alone with nothing behind them (no water, nothing in the hoop's opening), as rows of
    (red, green, blue, how solid): for the bobber mark, whose colour shows through the net."""
    cx, cy, rx, ry = HOOP
    # The bag: down from the left of the hoop, round the bottom, up to the right, and back
    # over the far side of the hoop
    left = curve((cx - rx, cy), (cx - rx + 4, cy + 102), (cx - 68, cy + 188), (cx, cy + 202))
    right = curve((cx, cy + 202), (cx + 68, cy + 188), (cx + rx - 4, cy + 102), (cx + rx, cy))
    sides = left + right[1:]
    far = [(cx + rx * math.cos(math.pi * i / 24), cy - ry * math.sin(math.pi * i / 24)) for i in range(1, 24)]
    bag = sides + far
    body = (curve((-62, 0), (-40, -34), (22, -34), (48, 0), 10)
            + curve((48, 0), (22, 34), (-40, 34), (-62, 0), 10)[1:-1])
    tail = [(40, 0), (82, -30), (74, 0), (82, 30)]
    edge = body + [body[0]] + tail + [tail[0]]
    shine = [(HANDLE[0][0] - 4, HANDLE[0][1] - 7), (HANDLE[1][0] - 4, HANDLE[1][1] - 7)]
    half = MESH_STEP / 2

    def colour(x, y):
        # The water: darker downwards, with a little light behind the net
        depth = min(1, max(0, y / 400))
        back = [WATER_TOP[i] + (WATER_BOTTOM[i] - WATER_TOP[i]) * depth for i in range(3)]
        light = 0.22 * max(0, 1 - math.hypot(x - 200, y - 168) / 240)
        back = tuple(back[i] + (GLOW[i] - back[i]) * light for i in range(3))
        # Everything else leans back with the net
        x, y = turn(x, y, ICON_TILT, (200, 200))
        ex, ey = (x - cx), (y - cy)
        out = (ex / (rx + HOOP_LINE / 2)) ** 2 + (ey / (ry + HOOP_LINE / 2)) ** 2
        if out <= 1 and (ex / (rx - HOOP_LINE / 2)) ** 2 + (ey / (ry - HOOP_LINE / 2)) ** 2 >= 1:
            return RIM
        if cy - 4 <= y <= cy + 220 and near(sides, x, y, BAG_LINE / 2):
            return MESH
        # The fish lies in front of the far side of the mesh, with a dark edge so that it
        # stands clear of it at any size
        fx, fy = turn((x - FISH_AT[0]) / FISH_SCALE, (y - FISH_AT[1]) / FISH_SCALE, FISH_TILT)
        if -70 <= fx <= 90 and -42 <= fy <= 42:
            if math.hypot(fx + 36, fy + 7) <= 7.5:
                return DEEP
            if inside(body, fx, fy) or inside(tail, fx, fy):
                return FISH
            if near(edge, fx, fy, FISH_EDGE / FISH_SCALE):
                return DEEP
        if cx - rx - 2 <= x <= cx + rx + 2 and cy - ry - 2 <= y <= cy + 206 and inside(bag, x, y):
            mx, my = turn(x - cx, y - cy, -45)
            if abs((mx + half) % MESH_STEP - half) <= MESH_LINE / 2 or abs((my + half) % MESH_STEP - half) <= MESH_LINE / 2:
                return MESH
        if out <= 1:
            return None if clear else DEEP  # the far side of the hoop, seen through the opening
        if x > HANDLE[0][0] - HANDLE_LINE and y < HANDLE[0][1] + HANDLE_LINE:
            if near(shine, x, y, HANDLE_LINE / 8):
                return WOOD_LIGHT
            if near(HANDLE, x, y, HANDLE_LINE / 2):
                return WOOD
        return None if clear else back

    vx, vy, span = ICON_VIEW
    rows = []
    for row in range(size):
        line = []
        for column in range(size):
            total = [0.0, 0.0, 0.0]
            solid = 0
            for sy in range(samples):
                for sx in range(samples):
                    x = vx + ((column + (sx + 0.5) / samples) / size - 0.5) * span
                    y = vy + ((row + (sy + 0.5) / samples) / size - 0.5) * span
                    dot = colour(x, y)
                    if dot is None:
                        continue
                    solid += 1
                    total[0] += dot[0]
                    total[1] += dot[1]
                    total[2] += dot[2]
            if clear:
                # The colour of the solid part only (no dark fringe), and how much is solid
                rgb = tuple(round(value / solid) for value in total) if solid else (0, 0, 0)
                line.append(rgb + (solid / (samples * samples),))
            else:
                line.append(tuple(round(value / (samples * samples)) for value in total))
        rows.append(line)
    return rows


def write_rgba(path, rows):
    """A picture in its own colours that can be see-through: `rows` of (red, green, blue, how
    solid from 0 to 1)."""
    size = len(rows)
    header = struct.pack("<BBBHHBHHHHBB", 0, 0, 2, 0, 0, 0, 0, 0, size, size, 32, 8)
    body = bytearray()
    for row in reversed(rows):  # the file starts with the bottom row
        for red, green, blue, alpha in row:
            body += bytes((blue, green, red, round(alpha * 255)))
    path.write_bytes(header + bytes(body))
    print(path.name, size, "x", size, len(header) + len(body), "bytes")


def write_picture(path, rows):
    """A picture in its own colours, nothing of it see-through: `rows` of (red, green, blue)."""
    size = len(rows)
    header = struct.pack("<BBBHHBHHHHBB", 0, 0, 2, 0, 0, 0, 0, 0, size, size, 32, 8)
    body = bytearray()
    for row in reversed(rows):  # the file starts with the bottom row
        for red, green, blue in row:
            body += bytes((blue, green, red, 255))
    path.write_bytes(header + bytes(body))
    print(path.name, size, "x", size, len(header) + len(body), "bytes")


# -------------------------------------------------------------------------------- bobber mark
# The mark that hangs over the bobber (BobberMark.lua): a ring with a soft glow, a disc to sit
# dark behind it, and an arrow pointing down at the bobber. White on nothing, so the mark takes
# the look's accent colour. Plain geometry, nothing taken from anywhere.
def supersample(size, value):
    """Each dot's average of value(x, y) over SAMPLES x SAMPLES points inside it."""
    rows = []
    for y in range(size):
        row = []
        for x in range(size):
            total = 0.0
            for sy in range(SAMPLES):
                for sx in range(SAMPLES):
                    total += value(x + (sx + 0.5) / SAMPLES, y + (sy + 0.5) / SAMPLES)
            row.append(total / (SAMPLES * SAMPLES))
        rows.append(row)
    return rows


def ring(size, radius, width, glow):
    """A ring `width` dots thick at `radius` from the centre, with a glow fading over `glow`
    dots on both sides of it."""
    c = size / 2

    def value(px, py):
        edge = abs(math.hypot(px - c, py - c) - radius) - width / 2
        if edge <= 0:
            return 1.0
        if edge < glow:
            return 0.45 * (1 - edge / glow) ** 2
        return 0.0
    return supersample(size, value)


def disc(size, radius):
    c = size / 2
    return supersample(size, lambda px, py: 1.0 if math.hypot(px - c, py - c) <= radius else 0.0)


def segment_distance(px, py, a, b):
    ax, ay = a
    bx, by = b
    dx, dy = bx - ax, by - ay
    t = max(0.0, min(1.0, ((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy)))
    return math.hypot(px - (ax + t * dx), py - (ay + t * dy))


def chevron(size, line):
    """A V pointing down, its strokes `line` dots thick with round ends."""
    left, tip, right = (size * 0.18, size * 0.28), (size * 0.5, size * 0.72), (size * 0.82, size * 0.28)

    def value(px, py):
        d = min(segment_distance(px, py, left, tip), segment_distance(px, py, tip, right))
        return 1.0 if d <= line / 2 else 0.0
    return supersample(size, value)


def main():
    MEDIA.mkdir(exist_ok=True)
    # The bobber mark: ring and disc 64 dots across, the arrow 32
    write_tga(MEDIA / "BobberRing.tga", ring(64, 23, 5, 7))
    write_tga(MEDIA / "BobberDisc.tga", disc(64, 21))
    write_tga(MEDIA / "BobberArrow.tga", chevron(32, 6))
    # (1.1.9 also wrote BobberIcon.tga, the net and fish alone, for the middle of the mark:
    # `write_rgba(MEDIA / "BobberIcon.tga", icon(clear=True))`. The owner preferred the colour
    # alone, so it is no longer made; icon(clear=True) and write_rgba stay for another use.)
    # (measures across, dots across): four dots to a measure
    for measures, size in ((8, 32), (4, 16)):
        write_tga(MEDIA / ("RoundFill%d.tga" % measures), coverage(size, 0))
        write_tga(MEDIA / ("RoundRing%d.tga" % measures), coverage(size, size - size / measures))
    # 8 measures of corner and 12 of shadow, 64 dots across
    write_tga(MEDIA / "GlassShadow8.tga", shadow(64, 8, 12))
    # The addon's icon: the addon list, the minimap button, the addon menu
    write_picture(MEDIA / "Icon.tga", icon())


if __name__ == "__main__":
    main()
