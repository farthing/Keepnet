# Colour blind colours for the bobber mark

Researched 2026-11-27 for Keepnet 1.2.1. **[V]** checked against a primary source, **[E]** my
own estimate or inference, **[U]** not checked.

## What games offer

- **The usual set is Protanopia / Deuteranopia / Tritanopia**, often with a strength slider.
  Greyscale is mostly a system-level filter (Windows).
- **World of Warcraft** (also this client), under Accessibility:
  - a "Colorblind Filter" (None / Protanopia / Deuteranopia / Tritanopia) with an "Adjust
    Strength" slider;
  - a separate "UI Colorblind Mode" that adds text to tooltips, a cue that isn't colour.
  [V] [Blizzard's settings source, `forever` branch](https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_SettingsDefinitions_Frame/Colorblind.lua)
- **Apex Legends:** the three modes, recolouring friend and foe colours only. [V] [EA](https://www.ea.com/able/resources/apex-legends/pc/features)
- **The Last of Us Part II:** a "HUD colorblind mode" (Off / Protanopia / Deuteranopia /
  Tritanopia) that changes the HUD's accent colours. [V] [PlayStation](https://playstation.com/en-us/games/the-last-of-us-part-ii/accessibility/)
- **Fortnite:** the three modes and a strength slider. [U]
- **Valorant:** a choice of enemy highlight colour per type. [U]
- **Overwatch:** free choice of the enemy and friendly colours. [U]
- **Two ways to do it:** whole-screen *filters* (WoW, Fortnite, Windows, Xbox) and alternative
  *palettes* for interface parts (TLOU2, Apex, Valorant, Overwatch). An addon can only offer a
  palette.
  - The [Game Accessibility Guidelines](https://gameaccessibilityguidelines.com/ensure-no-essential-information-is-conveyed-by-a-colour-alone/)
    call filters "a blunt instrument". They prefer a cue besides colour, then preset palettes
    plus a free colour choice. [V]

## The game's own settings on this client

[V] Ketho/BlizzardInterfaceResources, `forever` branch, `CVars.lua`:

| Setting | Default | Meaning |
|---|---|---|
| `colorblindSimulator` | 0 | The filter: 0 none, 1 protanopia, 2 deuteranopia, 3 tritanopia |
| `colorblindWeaknessFactor` | 0.5 | Its strength, 0 to 1 |
| `colorblindMode` | 0 | "UI Colorblind Mode" (the extra tooltip text) |
| `daltonize` | 1 | The filter *corrects* for the colour weakness rather than simulating it |

Keepnet's "As the game's colour blind mode" maps 1, 2 and 3 to its own sets.

**Not known:** whether the game's filter also recolours addon pictures. If it does, Keepnet's
set plus the game's filter correct twice. That needs one look in the game. [U]

## The sets Keepnet uses

The middle's three colours run from the line going out (to 10 s), fading to the second at
20 s and the third at 29.9 s. The research agent checked the colour blind sets with a
Machado 2009 simulation at full strength and CIEDE2000 colour differences. The smallest
difference between any two colours is 24 or more for the type each set is for (10 and up is
usually easy to tell apart). [E]

| Set | First | Second | Third | Circle | Arrow |
|---|---|---|---|---|---|
| Off (the owner's) | green 0.20, 0.78, 0.25 | yellow 1.00, 0.82, 0.10 | red 0.90, 0.16, 0.12 | the look's accent | darker green 0.00, 0.63, 0.24 |
| Protanopia | sky blue 0.34, 0.71, 0.91 | yellow 0.94, 0.89, 0.26 | vermillion 0.84, 0.37, 0.00 | white | white |
| Deuteranopia | sky blue 0.34, 0.71, 0.91 | yellow 0.94, 0.89, 0.26 | dark vermillion 0.67, 0.24, 0.00 | white | white |
| Tritanopia | cyan 0.31, 0.82, 0.82 | pink 1.00, 0.63, 0.78 | red 0.86, 0.08, 0.08 | white | white |
| Monochrome | light grey 0.78 | mid grey 0.50 | dark grey 0.22 | white | white |

- **Protanopia and deuteranopia** use the
  [Okabe-Ito](https://jfly.uni-koeln.de/color/) colours along the blue-yellow axis that
  red-weak and green-weak eyes keep. Deuteranopia's third is darker because yellow against
  vermillion is the weakest pair for green-weak eyes.
- **Tritanopia** runs along the red-cyan axis and never sets blue against yellow.
- **Monochrome** uses brightness only, about 27 L* apart.
  [Paul Tol](https://sronpersonalpages.nl/~pault/) warns that cyan, pink and grey can clash. [V]
- **The arrow:** in the normal set it is a darker green than the first colour, so the two
  don't merge at the start.
  - The agent suggested a near-black arrow for the colour blind sets. I chose white: black
    has a contrast of only about 2:1 against deep water, and the circle and the arrow already
    differ by shape. [E]
- **The player's own circle and arrow colours** (Settings tab) win over any set.

## Not done (suggestions)

- **A cue besides colour for the last stage:** for example a gentle pulse in size or
  brightness from 20 s, kept under three flashes a second
  ([WCAG 2.3.1](https://www.w3.org/WAI/WCAG21/Understanding/three-flashes-or-below-threshold)).
  Not built: the owner hasn't asked for it.
- **Red and dark middles on blue-green water** have almost no lightness contrast; the ring
  around them keeps them readable. [E]
