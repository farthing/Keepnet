# Keepnet dev log

Newest state first. Read this before working on the addon.

## RESUME HERE

**1.2.21 (2026-11-28): reporting a problem can be found.** My three suggestions, taken by the
owner ("do all 3"): the Settings button is "Report a problem" (was "Collect logs"); the log
window and the report's header name a second way to send it, a comment on the CurseForge page,
for players with no GitHub account; README and `media/curseforge-description.html` have a
"Something not working?" section. The SITE description still waits for the next upload.
Tests pass; committed, tagged; not uploaded; not seen in the game (the window is 12 taller
for the extra line).

**1.2.20 (2026-11-28): the log window explains itself (the tag v1.2.19 is a broken commit: its LogWindow.lua does not load; never use it)** (the owner: "add explanation text to
the log window, that they need to copy the text, that click selects all and so on"): five
lines above the text (Select all, Ctrl+C, where to paste with Ctrl+V, names taken out); the
window is 40 taller and the text box starts 70 lower. Not seen in the game: whether the five
lines fit above the box. Tests pass; committed, tagged; not uploaded.

**1.2.18 (2026-11-28): "Select all" in the log window and a "Copied." line on Ctrl+C.** The
owner asked for a copy button. An addon can not copy: `CopyToClipboard` is refused for addon
code on this client (ADDON_ACTION_FORBIDDEN, as a note in Mastercraft's Core.lua records), so
it is never called. The button selects everything and the copy stays the player's Ctrl+C;
`OnKeyDown` on the box only notices it. Not seen in the game: whether OnKeyDown fires for
Ctrl+C in an EditBox here. Tests pass; committed, tagged; not uploaded.

**1.2.17 (2026-11-28): the collected log is made for sending to GitHub issues, without the
player in it.** The owner asked whether the button could email the log (it can't: an addon
has no network and writes no files), then: "copy and paste looks good, and use github
issues ... make sure the log does not have any dangerous data of the player".
- `ns.LogReport()`: a header (Keepnet version, game build and interface, language, look,
  colour blind set, where to paste it) and the lines with every character name Keepnet knows
  on the account, the played character's name and anything shaped like a player GUID taken
  out. The saved log itself is unchanged; the scrub is on the way out.
- What the log holds at all: Keepnet's own events (tables show as "<table>"), the lines it
  prints, vendor sums (the player's gold, in copper), NPC names clicked. No chat, no other
  players, no account or realm. Gold was left in on purpose: it is what explains a purchase.
- The repo is already public with issues on (checked with gh that day).
- Tests pass; committed, tagged; not uploaded.

**1.2.16 (2026-11-28): two size sliders; general vendors behind a tick box.** Both were my
objections to my own earlier work, and the owner agreed ("lets make two sliders, and do the
switch to include/exclude general vendors").
- Appearance, Size: "Window" (`windowScale`, new, applied on letting go) and "Live panel"
  (`panelScale`, as before 1.2.12). The block is 14 taller (rows 22 apart); the Live panel
  block under it starts 14 lower and should end about 6 above the window's bottom edge. NOT
  seen in the game: whether it fits.
- Zones tab: `Anglers.General(row)` = a vendor whose title has none of fish, tackle, bait,
  angl. Left out unless "General vendors too" is ticked (`anglersGeneral`, off by default); the
  tick box sits where the character list is while the sessions show. Gubber Blump (no title)
  counts as general.
- Tests pass; committed, tagged; not uploaded.

**1.2.15 (2026-11-28): "Collect logs" moved up beside the "New versions" heading** (seen in
the game by the owner: at the bottom right it lay over the note about updates, which runs
to the bottom of the tab). Its right edge is the note's (right + 360). Tests pass; committed,
tagged; not uploaded; the new place not yet seen in the game.

**1.2.14 (2026-11-28): text follows the colour blind set** (the owner: "make the text conform
to colour blind settings"). `ns.Tone("ok" / "some" / "none")` in `Util.lua` gives the hex for
the set chosen as `bobberPalette` (or the game's mode); every fixed 40ff40 / ffd100 / ff6060
in the screens now asks it (about 26 places; `Waters.COLORS` too). The gold "g" keeps its
coin colour. The text tones are lighter than the mark's where small text needs it (the
vermillion; monochrome is white, light grey, mid grey): my choice, not checked by a colour
blind person. A text already on screen changes at its next redraw. Tests pass
(`test_tones.lua`); committed, tagged; not uploaded; not seen in the game.

**1.2.13 (2026-11-28): the "Click one:" line under the Trainers & vendors button is green**
(40ff40, the highlight font; the owner: "more visible, green text maybe"). The Matrix colour
set inks every text green anyway. Tests pass; committed, tagged; not uploaded.

**1.2.12 (2026-11-28): one "Scale" slider for the window and the live panel** (the owner: "a
scale slider added to appearance. which adjust the scale of the settings and live window").
The Appearance tab already had a "Live panel" size slider (`panelScale`, 70 to 150 %) and no
room for a second row, so that slider was renamed and the window follows the same setting
(`UI.ApplyScale`: on showing the window, on letting go of the slider, on the reset button).
The log window is not scaled. Not seen in the game: how the window behaves when it rescales
around its centre, and whether its place on screen still suits at 150 %. Tests pass;
committed, tagged; not uploaded.

**1.2.11 (2026-11-28): a line under the "Trainers & vendors" button, only while that list
shows** (the owner asked for it): "Click one: Keepnet makes a targeting macro for them, and a
waypoint when you are in their zone." Right-aligned in the 12 px between the button row and
the table; whether it fits there without touching either has not been seen in the game.
Tests pass; committed, tagged; not uploaded.

**1.2.10 (2026-11-28): a log with a "Collect logs" button, and a click on a trainer or vendor.
Passes its offline tests (`test_log.lua` 11 checks, `test_anglers.lua` 40); committed and
tagged; NOT uploaded; nothing of it seen in the game.**
- **The log** (the owner: "add logging for everything the add-on does, with a button under
  settings to collect logs"; it came out of a purchase of 17 lures instead of 20, which was the
  gold kept back: 7 g with 4 g kept).
  - `ns.Log(...)` in `Util.lua`: the newest 1500 lines, kept in `KeepnetDB.log` so a reload
    keeps them. Logged: every `ns.Fire` with what it sends (except TICK), every line Keepnet
    prints, an error in a listener, loading, and at a vendor the money, the gold kept, and per
    lure the number wanted, in the bags, the price and how many can be paid for.
  - "Collect logs" at the bottom right of the Settings tab opens `UI\LogWindow.lua`: the text
    in a box, selected, to copy with Ctrl+C (an addon can't write a file); Refresh, Clear.
  - Not logged on purpose: nothing leaves the game. Character names can be in the lines (a
    session's key), so a pasted log may hold them: keep pasted logs out of the public repo.
  - Never seen in the game: the box, its scrolling (mouse wheel, a plain ScrollFrame) and how
    1500 lines behave in it.
- **A click on a trainer or vendor** (the owner: "have either a targeting macro created and
  potentially a waypoint add (if in its zone)"): `Anglers.Go`. One macro, "KeepnetTarget"
  (`/target Name`), made or rewritten at every click, never in combat; and
  `C_Map.SetUserWaypoint` at the spot when the character's zone is the person's. A chat line
  says what was done and what not. One macro rewritten rather than one per person: my choice
  (the macro list is short). Neither call has run on this client.
- `ns.VERSION` in `Util.lua` had stayed at 1.2.8 through 1.2.9 (the TOC said 1.2.9): both say
  1.2.10 now. Bump both by hand.

**1.2.9 (2026-11-28): fishing trainers and tackle vendors by zone, for the character's side;
new tag line and feature order. Passes its offline tests (`test_anglers.lua`, 38 checks);
committed and tagged; NOT installed, NOT uploaded (1.2.7 is the last on CurseForge), never
seen in the game.**
- **The owner:** "an area that has a list of each fishing vendor and trainer per zone. for the
  faction the character is" (Horde sees Horde and neutral, Alliance sees Alliance and neutral).
- **Where:** the Zones tab. The window has no room for an eighth tab (7 x 104 wide), so a
  button beside the character list ("Trainers & vendors" / "Sessions") swaps the right side.
  A zone clicked: that zone's people; none clicked: everybody. Columns Name, What, Zone,
  Where; the tooltip adds the title, what is sold and a note. My choice, not the owner's.
- **Data:** `Keepnet\Anglers.lua`, 101 people (26 train, 3 of them also sell; the rest
  vendors), from Wowhead's Forever NPC pages, gathered by a helper agent through the browser.
  "Vendor" = sells a fishing pole or a lure, which takes in about 70 general trade vendors; say
  the word and they are cut down to dedicated tackle sellers. Coordinates are the first spot
  Wowhead lists. Left out: two with no clear side (Dala Fairmaw in Mount Hyjal, Kenneth
  "Kirby" Millstead in Riverglades) and six with no spawn. Wowhead lists no seller for the
  Aquadynamic Fish Lens or Flesh Eating Worm.
- Mastercraft (installed, all rights reserved) holds a trainer table; it was seen while
  looking for a source and NOT used. Nothing was checked in the game.
- The side comes from `UnitFactionGroup("player")`; when the game gives neither, nobody is
  left out.
- **Tag line** (TOC Notes; the owner gave the framework: easy fishing, searchable history and
  tracking, zone requirements, vendors/trainers by faction, visible bobber): "Easy one-key
  fishing, searchable session history and tracking, the skill every zone asks for, fishing
  trainers and vendors by zone for your faction, and a bobber you can't miss." My wording;
  the owner has not seen it yet. `media/curseforge-description.html` has those features first
  in its list, then the others. The SITE still has the old summary and description: put both
  up with the next upload.
- **Ideas:** a click on a person sets a map waypoint; learn people the list lacks when a
  trainer or vendor window opens.

**Decided 2026-11-27: no cast after the lure.** The owner asked for "apply lure if available,
after applying, auto cast".
- A cast by itself isn't possible (protected; one key press, one action) and would be
  automation.
- I offered a press queued in the lure's last moments (the game's spell queue) and a "lure on"
  cue.
- The owner: "that sounds like it is complicating the addon. my design idea was clean and
  simple. i think we have achieved that as is." Keep the key as it is; don't propose this again.

**1.2.8 (2026-11-27, about 18:20): the strip's catch list stays 10 s (was 8). Installed as the
development copy (/reload); passes its offline tests; committed and tagged; NOT uploaded (1.2.7 is
the last on CurseForge, and uploads wait for a batch).** The owner: "i want the loot list to stay
on screen 2 seconds longer". `CAME_SECONDS` in `UI\LivePanel.lua`; "Nothing on the line" keeps
its 3 s. The owner also asked whether the list shows counts: it does ("  x2" when more than one,
nothing for one; three kinds, then "and N more").

**1.2.7 and the new pictures are on CurseForge (2026-11-27, about 18:00; the owner: "push to
curse"). 1.2.7 approved; 17 pictures in the gallery in order; the description holds them all. See
`PUBLISHING.md`, "1.2.7 and the new pictures". Nothing is owed on the listing now.**

**Pictures (2026-11-27, from about 17:20; the owner: "let's do media"). DONE.**
- The list agreed:
  1. the bobber mark close up at green, yellow and red (joined into one picture);
  2. the mark with the interface hidden and the panel's strip (replaces `12-interface-hidden`);
  3. a colour blind set on the water (optional);
  4. Settings (redo);
  5. Gear & food with "Lures from vendors" (redo);
  6. optional: Appearance, the minimap button, the live panel at v1.2.x.
- **Done so far** (taken in the Keepnet theme, cut with `tools\cut.ps1`, from captures in
  `media\raw`):
  - `media\screens\08-settings.png` (1.2.6; the New versions note's last sentence "This is a
    development copy: it listens and never announces." painted over with the window's own
    background 19,23,29, at the owner's word "blank it");
  - `05-gear-food.png` (Bright Baubles, keep 20, floor 4 g, attractors on).
  - No names in either.
  - `16-bobber-timer.png`: three close-ups at the same crop, labelled "Line just out", "About
    20 seconds" and "Nearly done (pulsing)", joined side by side. Green and yellow came from
    single captures; red from a capture run of 19 frames, 2.4 s apart, over one cast
    (`tools\capture-watch.ps1 -Full -Ticks 1.5 -Seconds 45`), since two "red ready" calls
    came too late.
  - `12-interface-hidden.jpg`: frame 13 of that run, scaled to 1920 wide. The orange mark is
    over the bobber; the panel's strip reads "Line out: 8 s". It replaces the old picture.
  - `07-appearance.png` (v1.2.6 in its corner): look and colours, hiding the interface,
    backgrounds, size, and the Live panel block in its new place.
- **The owner settled the rest:** "we don't need media for colour blind, we can add text to the
  description page to indicate this. also, just mention the map icon." The live panel picture
  was not retaken.
- **The description** (`media/curseforge-description.html`):
  - a "Colour blind colours" point in the bobber section naming each set;
  - a "A minimap button" point in the feature list;
  - the bobber timer picture with a caption under the bobber section;
  - the Appearance picture after the interface-hidden one, whose caption now mentions the
    timer and the mark;
  - new alt texts for Gear & food, Settings and the hidden interface.
  - **Five pictures wait as `@@name@@` placeholders:** 05-gear-food, 07-appearance,
    08-settings, 12-interface-hidden, 16-bobber-timer. `tools/description.py` refuses until
    they have the gallery's addresses.
- **The upload batch (when the owner says to push):**
  1. Add the five pictures to the gallery, with titles; feature the bobber timer.
  2. Delete the three old ones they replace (05, 08, 12; the owner said yes to that pattern
     before, and the "clean up replaced images" rule applies).
  3. Put the gallery order back with the new ones in their places.
  4. Fill the placeholders with the new addresses, run `description.py`, and put the
     description on the site.
  5. Upload 1.2.7 (the changelog covers 1.2.6 and 1.2.7: the cog faded, the Settings
     spacing).
- Not uploaded yet: the gallery goes up in one batch at the end; delete the old pictures and
  put the order back.

**1.2.7 (same time): 10 more above "New versions" on the Settings tab** (the owner: "nudge the
spacing"; the pulse checkbox sat right on its heading). Installed as the development copy
(/reload). The Settings picture above shows 1.2.6's spacing; retake it if the gap matters.

**1.2.6 (2026-11-27, about 17:15): the game's cog under the mark faded. Installed as the
development copy (/reload); passes its offline tests (`test_bobber_mark.lua` 124 checks);
committed and tagged; NOT uploaded (1.2.5 is the last on CurseForge). The owner: "we will
wait for more changes before pushing updates", so the next upload waits for a batch and covers
everything after 1.2.5 (`release.py --since 1.2.5`).**
- **The owner:** "one issue, the game's cog icon is still below our mark. can that be removed?"
- **How:** while the mark hangs from a plate, `plate.UnitFrame.SoftTargetFrame:SetAlpha(0)` (in
  pcall), applied again at every look (the game may redraw it).
  - Its own alpha is saved first and given back when the mark leaves that plate (another
    target, no target, line in, combat, logout), since plates are re-used.
  - Mastercraft and OneCast fade the same frame on this client.
- **Chose this over** `SoftTargetNameplateSize` 0 (a game setting that turns the icon off),
  because it isn't known whether the plate stays without the icon, and the mark needs the
  plate.
- **The mark sits lower:** 6 above the plate's top instead of 20.
- **Not seen in the game:** whether the fade holds; the agents' code reading says the game
  only redraws the icon on target or plate events, and Keepnet re-fades every 0.25 s anyway.
  Also whether the lower height looks right.

**1.2.5 is on CurseForge (uploaded 2026-11-27, about 17:00; "Under Review" when last
looked), with the description and the new summary; see `PUBLISHING.md`, "1.2.5".** The owner,
after trying the 65 % mark: "that... is MUCH better. push to curse with bullets updated. the
new short description".
- The summary is "Fish smarter: see which zones your skill can fish, search every catch by
  character, spot your bobber at a glance, and pick your own sounds." The owner picked it
  from four drafts built on their points: zones with skill requirements, searchable history
  per character, visible bobber, customisable sounds. It is also the TOC's `## Notes` since
  1.2.5.
- **Still owed:** pictures of the bobber mark, and a new Settings/Appearance tab picture.
  Also the older 1.1.4 pictures, see below.

**DONE with 1.2.5 (kept for the wording): the CurseForge description and short description
updated for the bobber mark.**
- **The description:** a new bullet point in the feature list at the top, for the bobber mark.
  Draft: "**A clearer bobber:** a mark over your bobber while the line is out, its middle
  fading green to yellow to red as the line's 30 seconds run out. Pick the circle's and
  arrow's colours, or colour blind colours."
- **The short description (summary)** should mention a clearer bobber. The owner: "our short
  description is too generic and too like other addon's 'hook'". The TOC's `## Notes` reads
  the same and should change with it. Drafts for the owner to choose from (not yet shown to
  them):
  1. "See your bobber at a glance: a colour-timed mark over it, one-key casting with lures and
     food, and live gold for every catch."
  2. "A bobber you can't lose: a mark that counts down the line in colour, plus one-key fishing,
     auto lures and food, and gold per hour."
  3. "Never lose your bobber again. Keepnet marks it, times the line in colour, and handles
     lures, food and gear on one key."
- Do it through the author site in Chrome as before (`PUBLISHING.md`).

**DONE 2026-11-27 (was: TO DO AS SOON AS POSSIBLE, gallery pictures for 1.1.4): the Gear & food
and Settings pictures were retaken and the line's strip shows in the interface-hidden one.** Nothing on the listing shows the lure buying (Gear &
food tab, "Lures from vendors"), the gear key's button (Settings tab, top row) or the line's
strip under the live panel (a cast with the interface hidden, and one with a catch listed).
The existing pictures of the Gear & food and Settings tabs are from before and should be
replaced by the new ones (delete the old, restore the order). Raise it at the start of the
next session. Also still open from before: the lure buying has not bought anything in the
real game.

**1.2.4 (2026-11-27, about 16:35): the mark at 65 %. Installed as the development copy
(/reload).** The owner, after 1.2.3: "drop more. say 65%".
- **How:** `mark:SetAlpha(0.65)`. The middle ends up at 0.85 × 0.65 ≈ 0.55, or 0.65 at the
  top of a pulse.

**1.2.3 (2026-11-27, about 16:30): the mark 10 % see-through. Installed as the development
copy (/reload).** The owner: "we need a little bit more transparency on the markers. not a
lot. maybe like 10% more transparent".
- **How:** `mark:SetAlpha(0.9)` on the whole mark. The ring, the arrow and the middle all
  lose 10 %; the middle is 0.85 × 0.9, or up to 0.9 at the top of a pulse.
- **Not a setting.**

**1.2.2 (2026-11-27, about 16:20): the pulse. Installed as the development copy (/reload is
enough). Passes its offline tests (`test_bobber_mark.lua` 118 checks); committed and tagged.**
- **The owner:** "do the pulse" (my suggestion in 1.2.1: a cue besides colour for the last
  stage).
- **How:** `BobberMark.Pulse(seconds)` returns (size, brightness).
  - From 20 s: a cosine swell at 1.5 Hz, up to +18 % size and a fully solid middle.
  - Its strength runs from 40 % at 20 s to 100 % at 29.9 s.
  - The body (not the anchor) is scaled, so the mark swells from its foot and the arrow's tip
    stays at the bobber.
  - It's in the same per-frame update as the bob and the colour.
- **Setting:** `bobberPulse` (on). The checkbox "Pulse as the line runs out (from 20 seconds)"
  is on the Settings tab, replacing the note line in the Bobber mark section.
- **My choices:** the start at 20 s, the speed, the 18 %, the 40 % start, and on by default.
- **Not seen in the game.**

**1.2.1 (2026-11-27, about 16:00): the mark's colours, colour blind sets, and a Bobber mark
section on the Settings tab. Installed as the development copy (/reload is enough: no new
files in the addon). Passes its offline tests (`test_bobber_mark.lua` 107 checks); committed
and tagged.**
- **The owner:** "change the colour of the arrow to green, add a settings section on the
  settings tab. to change the colour of both the circle and arrow independently. add a colour
  blind option for the arrow, circle and the three fading colours. look up what the standard
  colour blind options are for anything in other games." Then "green, by default".
- **The layout:** the Settings tab was full. Asked; the owner chose "Swap a section":
  - the **Live panel** options (lock, catches, kit, line strip, Reset panel) moved to the
    Appearance tab, right column, where the bobber block was;
  - the **Bobber mark** section took their place on Settings, right column, between Sessions
    and New versions.
  - Rows:
    - the switch;
    - Size (a slider 60–200 %), Circle (swatch), Arrow (swatch);
    - Colour blind (a drop-down) with the three middle colours as squares;
    - a one-line note.
  - A swatch click opens the game's colour picker; a right click goes back to the default.
- **The colours** (`UI\BobberMark.lua`: PALETTES, `Palette()`, `Colours()`, `Colour(s)`):
  - normal: the owner's green, yellow and red; the circle in the accent; the arrow a darker
    green (0, 0.63, 0.24), so it doesn't merge with the middle's first green;
  - protanopia, deuteranopia, tritanopia and monochrome sets;
  - "game" follows `colorblindSimulator` (1, 2, 3; 0 or missing means normal);
  - the player's own circle and arrow colours (`bobberRingColor`, `bobberArrowColor`) win
    over any set.
  - Research and values: `docs\research\colour-blind.md`, credited in `CREDITS.md`.
  - **My choice against the agent's advice:** the arrow is white, not near black, in the
    colour blind sets, because black is lost on deep water.
- **Not seen in the game:**
  - the new section's layout (hand-placed: the swatches at right+196 and right+272 might
    crowd the slider's value);
  - the colour picker from a swatch;
  - whether the game's own colour blind filter also recolours the mark (that would be a
    double correction with "As the game's").
- **Suggested, not built:** a pulse in the last stage, as a cue besides colour.

**1.2.0 (2026-11-27, about 15:15): the icon out of the mark again. Installed as the
development copy (/reload is enough: a picture was removed, none added). Passes its offline
tests; committed and tagged.**
- **The owner, after trying 1.1.9:** "maybe remove the icon, if the colour can just fade
  between the three that would be nice".
- **What changed:**
  - The middle is the coloured disc alone; the fade is unchanged (it already faded).
  - `Media\BobberIcon.tga` is deleted, and `make_art.py` no longer writes it.
    `icon(clear=True)` and `write_rgba` stay, with a note.
- **Version:** 1.1.9 → 1.2.0 (as 1.0.9 → 1.1.0).

**1.1.9 (2026-11-27, about 15:00): the net and fish in the mark, on a colour that runs with
the line's time. Installed as the development copy; a NEW picture (`Media\BobberIcon.tga`),
so the game needs a full restart, not /reload. Passes its offline tests; committed and
tagged.**
- **The owner (after 1.1.8):** "ok mark is there. i want the addon's icon in the circle. can we
  progressivly change the background colour in the circle as the line timer runs out? green
  for the first 10 seconds, yellow for when it gets to 20, red when it hits 29.9. gradient
  fade if possible".
- **The icon:** `tools\make_art.py` draws the icon again with `clear=True`, which gives the net
  and fish with no water and nothing in the hoop's opening, so the colour shows through the
  net. It writes `BobberIcon.tga` (straight alpha, each dot coloured by its solid part only).
  - `Icon.tga` came out byte-identical.
  - It sits at 62 % of the ring, between the disc and the ring.
- **The colour** (`BobberMark.Colour(seconds)`):
  - green (0.20, 0.78, 0.25) up to 10 s, fading to yellow (1.00, 0.82, 0.10) at 20 s, then to
    red (0.90, 0.16, 0.12) at 29.9 s, red after that;
  - the disc at 85 %;
  - counted from the channel's start (`Fishing.Line()`), updated every frame with the bob.
- **Absolute seconds, as the owner said them:** if a line here lasts 20 s, it would never go
  red. Not measured.
- **Preview:** I rendered a preview from the real TGA files (scratchpad, not kept): the
  icon reads on all three colours; the yellow fish is the weakest but keeps its dark edge.
- **Not seen in the game yet.**

**1.1.8 (2026-11-27, about 14:30): the bobber mark with the interface hidden. Installed as the
development copy (needs /reload only); passes its offline tests; committed and tagged.**
- **Seen in the game (the owner, on 1.1.7):** "that shows the mark", "but only when the ui is
  visible". So the plate, the anchor and the pictures work on this client.
- **Why it vanished:** the game's `SetUIVisibility(false)` (Keepnet's "all" hide, and Alt-Z)
  takes the nameplates with it. Blizzard's own commentator code for this client says so
  ("UI visibility controls whether nameplates are visible"). It brings them back with
  `SetInWorldUIVisibility(true)`, which is in this client's API ("enables nameplates, etc.
  but doesn't affect the actual UI frames").
- **The fix** (`HideUI.lua`): after an "all" hide, call `SetInWorldUIVisibility(true)` if the
  mark is on.
  - The cost: the player's other nameplates show while the interface is hidden. That's in
    the changelog; switching the mark off restores the old behaviour.
  - The "parts" hide never touched nameplates.
  - Not covered: the player's own Alt-Z (Keepnet doesn't call anything then), and turning
    the mark on while the interface is already hidden.
- **The stub** now ties in-world visibility to `SetUIVisibility`, and has
  `SetInWorldUIVisibility`, `IsVisible` and `GetScale`.
- **1.1.7** (same afternoon): `/kn bobber` reports every step, from the setting to the mark on
  screen, for when it doesn't show.
- **Researched for the owner's "can the mark flash or grow when it bobs for a catch":** there
  is no bite signal for addons on this client.
  - Blizzard's Forever interface source has no bobber or fishing event, and the soft-target
    icon is only refreshed on target or plate events.
  - Mastercraft removed its test "bite" ding ("the game hides where the bobber is").
  - Campfire Angler's page says addons can't detect a bite.
  - Classic addons' "bite" flashes were worked out afterwards from the channel stop.
  - Still "maybe", only an in-game probe can tell: whether the bobber's plate moves with the
    model's bob, or whether its cursor or icon changes at the splash. Not built; the owner
    hasn't said whether to.

**1.1.6 (2026-11-27, afternoon): a mark over the bobber. Passes its offline tests (21 files;
the new `tests\test_bobber_mark.lua` 61 checks), committed and tagged; NOT installed in the
game yet and NOT uploaded.** The owner: "i think the mastercraft addon's angler function
places an icon over the fishing bobber to make it more visible. i would like something like
that in keepnet" (researched with four agents first).
- **How** (`Keepnet\UI\BobberMark.lua`, new):
  - While the line is out, the game is asked for `SoftTargetInteract` 3, arc 2, range 30,
    `SoftTargetIconGameObject` 1 and `SoftTargetNameplateInteract` 1. The bobber becomes the
    soft interact target with a nameplate.
  - Keepnet's own frame (under WorldFrame, so the hidden interface keeps it) is anchored to
    that plate. The plate comes from `C_NamePlate.GetNamePlateForUnit("softinteract")`, or by
    `UnitIsUnit(token, "softinteract")` over `GetNamePlates()`.
  - The target counts as the bobber when its GUID is `GameObject-…-35591-…`, checked with
    `Util.Hidden` first.
  - Refreshed on `PLAYER_SOFT_INTERACT_CHANGED`, `NAME_PLATE_UNIT_ADDED`/`REMOVED` and a
    0.25 s ticker.
  - Blizzard's plate parts are never touched (taint); the game's own small gear icon still
    shows under the mark.
- **The mark** (pictures drawn by `tools\make_art.py`, white and tinted):
  - `Media\BobberRing.tga` in the accent colour (re-tinted on THEME);
  - `BobberDisc.tga` dark at 50 % behind it;
  - `BobberArrow.tga` pointing down;
  - 44 measures, 20 above the plate's top, bobbing 4 measures every 1.4 s.
- **The soft-target settings are shared now** (`Keepnet\SoftTarget.lua`, new):
  - `Want(who, list)` / `Release(who)` for the key ("key") and the mark ("mark");
  - the same `interactBackup` in the saved data as before;
  - a setting is put back only once nothing wants it;
  - a refused restore (combat) keeps its saved value for a later try (before, it was
    dropped).
  - `OneKey.lua` calls it; its behaviour is unchanged (all its old tests pass).
  - **New behaviour:** with the mark on, Keepnet raises `SoftTargetInteract` while the line
    is out even with no fishing key set.
- **Settings:** `bobberMark` (on) and `bobberMarkSize` (1, from 0.6 to 2). They are on the
  Appearance tab, right column, a new "Bobber mark" block under Size. The Settings tab was
  full. The looks reset button also puts the size back.
- **My choices, not the owner's:** on by default; the look (ring, dark disc, arrow, bob); its
  size and height; where the setting sits.
- **Credits:** Mastercraft (Shadowblade, all rights reserved) for the idea. Nothing of its
  code or media was used: its licence forbids copying. Also CorpseBeacon (MIT), Rubber Ducky,
  OneCast and Plumber for the method, and Lueur for the reset note. All in `CREDITS.md` and
  the file's header.
- **NOT seen in the game, all of it.** The facts behind it come from other addons' code and
  Blizzard's interface source for this client, not from a test here:
  - whether the plate appears for the bobber at all with these settings (Rubber Ducky's
    notes say only within about 10 yards on Forever);
  - where the plate's top sits above the bobber, so whether 20 is the right height;
  - whether `SetPoint` to the plate is ever refused;
  - whether the plate stays while the interface is hidden;
  - how the mark looks on the water.
- **Next:** the owner installs the development copy (`tools\install.ps1`). It has three new
  pictures and two new Lua files, so the game needs a full restart, not /reload. Then they
  fish and say how it looks. No upload until the owner says so; the changelog for the next
  upload starts after 1.1.5.

**1.1.5 is on CurseForge (uploaded 2026-11-25, about 22:10; "Uploading" when last looked)
and on GitHub (`main`, tag `v1.1.5`).** The owner, after restarting the game with the
development copy: "works well, push to curse". What went up and how is in `PUBLISHING.md`,
"1.1.5". The next changelog starts after 1.1.5. The owner's game holds the development copy
of the same files (it says 1.1.5 and never announces itself), until they take the app's.
Which parts the owner tried was not said: taken as the button and the icon showing and the
clicks working in their game, where the button is LibDBIcon's. Still unseen by anyone:
Keepnet's own button (no other addon bringing the library), a square minimap, the broker
launcher, the addon menu's tooltip and right click.

**1.1.5 (2026-11-25, about 20:45): a minimap button, and an icon of Keepnet's own. Passes
its offline tests, committed and tagged; installed as the development copy at 22:00.** The
owner: "i want keepnet to have a loaded addon icon, and button, like
master craft currently does in the ui. or dungeon journal etc etc. one that sits with the
minimap".

- **The button** (`Keepnet\Minimap.lua`, new; `ns.MinimapButton`). Left click: the window.
  Right click: the live panel (what `/kn panel` does). Drag: round the minimap. Which click
  does what, the tooltip's wording and the starting place (190 degrees, left of the
  minimap) are my choices, not the owner's.
- **Made in one of two ways, decided once at the first entry into the world.** Through
  LibDBIcon when another addon has loaded it with LibDataBroker (Keepnet brings neither):
  the button is then `LibDBIcon10_Keepnet`, and Keepnet is a launcher for broker bars. A
  button of Keepnet's own otherwise (`KeepnetMinimapButton`, the game's disc, ring and
  highlight round the icon; on a square or part-square minimap it keeps to the square's
  side, read from `GetMinimapShape`). **In the owner's game it will be LibDBIcon's**: five
  installed addons bring that library (BugSack's copy is the newest, 57), and
  EllesmereUIMinimap gathers every `LibDBIcon10_` button, which is how Mastercraft's and the
  Dungeon Journal's get where they are. That is why this way was taken and no library is
  bundled.
- **Settings** (each character's own, like the rest): `minimapButton` (on unless changed)
  and `minimapAngle`. LibDBIcon wants a table of its own to keep a button's place in;
  Keepnet hands it one that holds nothing and reads and writes those two settings
  (`place`, a metatable), so nothing of the library's is saved and a character's own place
  is what the library sees. The library is only told to show, hide or move when what it was
  last told changed: by then its button may be in a minimap addon's keeping. A button of
  Keepnet's own that something has taken off the minimap is not put back on it either.
- **Where it is switched:** the Settings tab, bottom left, "Minimap button" / "Show
  Keepnet's button on the minimap"; `/kn minimap`.
- **The icon:** `Keepnet\Media\Icon.tga`, 64 across, drawn by `tools\make_art.py`: the
  logo's picture (net, fish, handle) drawn again for small sizes, since the logo itself
  loses its mesh and hoop at 18 dots: lines two to three times as thick, a coarser mesh,
  the fish bigger and in front of the mesh with a dark edge. Looked at only as a picture
  (blown up, and shrunk to 32 and 18 dots), never in the game. The TOC's `IconTexture` is
  that file now (it was the game's `INV_Misc_Net_01`), so the addon list and the minimap's
  addon menu show it too.
- **The addon menu on the minimap:** pointing at Keepnet shows the same lines
  (`AddonCompartmentFuncOnEnter`, `...OnLeave` in the TOC), and a right click there is the
  live panel. `Keepnet_OnAddonCompartmentClick` moved from `Core.lua` to `Minimap.lua`.
- **Tests:** `tests\test_minimap.lua` (121 checks): both ways of making the button, the
  clicks, dragging, every kind of minimap shape, hidden and shown, per character, a library
  that refuses. The stand-in game has a `Minimap`, and `Stub.libs` for another addon's
  libraries.
- **Not known until it runs in the game:** that the game shows a TGA of an addon's own as
  the `IconTexture` (Mastercraft's does, without the file ending, which is how Keepnet's is
  written); how the icon reads at the button's size; where EllesmereUI's minimap puts the
  button; that the addon menu passes "RightButton" on this client (the Dungeon Journal
  relies on it).
- **In the game as the development copy since 2026-11-25, 22:00.** The game was running and
  held 1.1.4 without the development mark in its TOC: the CurseForge copy. `install.ps1`
  puts a development copy over that, so the owner was asked first and chose to install.
  Two files are new (`Minimap.lua`, `Media\Icon.tga`) and the game was running at the time:
  it needs a full restart, not `/reload`, before any of this shows. Until the owner takes
  a version from the CurseForge app again, the game's copy is this one.
- Left out of the listing's description on purpose: a minimap button is as much a given as
  settings per character, which the owner did not want there. It is in the README.

**1.1.4 is on CurseForge (uploaded 2026-11-25, about 19:55; "Processing" when last looked)
and on GitHub (`main`, tag `v1.1.4`).** It brings everything from 1.0.2 to 1.1.4. The
listing's description was brought up to date in the same go. What went up and how is in
`PUBLISHING.md`, "1.1.4". The owner's game holds the development copy of the same files.
The next changelog starts after 1.1.4.

**The gear key in combat, seen in the game by the owner on 1.1.4 (2026-11-25, about 19:45):**
"yep that works". Then: "document, save, publish to curse. publish to public git." **Buying
lures has still not bought anything in the real game** when 1.1.4 went up: the owner was
told so.

**1.1.4 (2026-11-25, evening): the gear key on a protected button.** The owner tried 1.1.3
in a fight: "tried, first bug grabbed by the addon". Seen on their screen: "Back in your
hands: ..." and "Your clothing changes when combat ends", the pole still on, then three
times "Keepnet didn't put this pole on". So **an addon's own equip call is refused in combat
on this client** (the error itself was not read; the error log is only written at a reload),
and 1.1.3 had already said it was done and dropped its note of the hands.

Now `KeepnetGearButton` is a `SecureActionButtonTemplate` whose macro does the change
(`/equipslot 16 item:<id>`, and `/equipslot 17 ...` for the other hand), the way the game
lets weapons be changed in combat. A macro can only be written out of combat, so it is
written ahead whenever what it should do changes (`Prepare`: at "MODE", "GEAR", "COMBAT"
end, "SETTINGS", "CHARACTER", "WORLD"). The press (`PreClick`) only writes down the hands
and talks; "Fishing pole on" and "Back in your hands" are said when the pole has really gone
on or come off ("MODE"), and the note of the hands is only dropped then. A press the game
did not act on drops its note after three seconds. Clothing still goes through the addon's
own equip calls, out of combat only. **Not seen in the game.** The stand-in game now refuses
an addon's equip call in combat for every slot, and a protected button's attributes too.

**1.1.3 (2026-11-25, evening): the gear key works in combat.** The owner: "one bug, the gear
swap combo, does not work when in combat. but i can equip my weapon in combat". `Gear.Toggle`
no longer refuses in combat: the hands are changed at once (the game allows that), the
clothing by the listeners that were already there when combat ends, and chat says "Your
clothing changes when combat ends". Not seen in the game: that the equip call from the
key's click is let through in combat on this client.

**1.1.2 (2026-11-25, evening): the kept money in gold and silver.** The owner: "need to
seperate gold and silver, in the never spend my last section". A second box, silver (0 to
99, `settings.buyLureFloorSilver`); `Vendor.FloorCopper()` is the two together and is what
`Vendor.Shop` keeps. Offline tests only.

**1.1.1 (2026-11-25, evening): the Maintain box and the flat number are out again.** The
owner: "so the everytime i open a vendor in flat mode, can end up being multiple purchases.
i think we need to reduce this logic. so let's remove the maintain tickbox. let's assume,
that is the default. so whenever I visit a vendor that sells whatever lure i have selected.
i buy enough to make the number selected". `buyLureFlat` is no longer read. One lure, one
number to keep, the kept gold, the Attractor's switch. Not seen in the game.

**1.1.0 (2026-11-25, evening): the lure buying's tab section reworded. Passes its offline
tests, committed and tagged; not on CurseForge.** The owner, before trying the buying: "the
text is a bit ambigious, i also thought about it differently now. replace tick boxes with a
drop down to select one. i want the auto buy option to be 'keep this many in my bag at all
time' so if i have less than 20 say bright baubles, it will buy enought to make up what I am
missing. change the colour of the text on the tick box for the attractor, to stand out more."
One lure from a list (`Vendor.Choose`, `Vendor.Chosen`; the setting is still the table
`buyLureItems`, holding one), "Keep [20] in my bags at all times" (what the number always
did: buying what is missing), "Never spend my last [ ] gold", and the Attractor's box
written in the accent colour and reworded "Also buy every ...". Then, the same hour: "maybe add
a maintain tick box, and a flat, buy this X many option": a "Maintain" box beside the number
(`settings.buyLureFlat` is its opposite, false by default). Unticked, that many are bought at
every vendor visit whatever is in the bags (still at most 200, still never the kept gold,
and the window sent twice in a row counts as one visit). The owner also confirmed the
line's strip in the game that evening: the countdown ("the cast bar is awesome") and the
catches listed under it.

**Seen in the game by the owner, 2026-11-25 about 19:05, on the development copy of 1.0.9:**
"keybinds seem to work" (the gear key and recording key combinations, 1.0.4 and 1.0.5;
which combination and how much of the gear swap was tried was not said). Buying lures was
about to be tried ("will test lures"); the line's strip has not been reported on.

**1.0.9 (2026-11-25, night): buying lures can't run away. Passes its offline tests,
committed and tagged; not on CurseForge.** The owner asked: "this will not by accident buy
like 500 baubles no?" Looked at for that, `Vendor.lua` had two ways to buy more than was
meant, both closed now (`Have`, `OnItsWay`, `MOST_ATTRACTORS`):

- A purchase reaches the bags a moment after it is asked for. Anything that ran
  `Vendor.Shop` twice inside that moment (the vendor's window sent twice, a lure listed
  twice by one vendor) counted the bags as they were and bought again. What was just bought
  now counts as in the bags at once, for ten seconds or until it is really there.
- "Every Attractor a vendor has" took the vendor's word for how many. It is never more than
  20 in one visit now.

What limited it already: a lure is bought up to a number in the bags (not that many each
time), the number is at most 200, and the gold that is kept is never spent. **Still true:
nothing of this has bought anything in the real game.** Not known there: that
`BuyMerchantItem(index, n)` buys n single lures on this client (it is how restocking addons
call it), and what the vendor calls answer. The owner was told to try it first with a small
number and gold kept.

**1.0.8 (2026-11-25, night): the gold limit is gold that is never spent. Passes its offline
tests, committed and tagged; not on CurseForge.** Offered the choice between a gate and a
reserve, the owner: "never past the limit please". `Vendor.Shop` now spends only what lies
above `buyLureFloor`: with that much or less nothing is bought (as in 1.0.7, with its line
in chat), and with more, each lure is bought only as far as the money above it reaches,
lures sold several at a time included (a purchase that would go under it is not made). When
that leaves a wanted lure short, chat says "Not enough money above the ... you keep". The
tab's line reads "Always keep [ ] gold", with a tooltip on the box. Not seen in the game.

**1.0.7 (2026-11-25, night): a gold limit for buying lures. Passes its offline tests,
committed and tagged; not on CurseForge.** The owner: "maybe add a field, where someone can
set a 'if i have less than this amount of money, don't buy anything' option and then if the
person has that amount or less, it does not buy". `settings.buyLureFloor`, in gold, 0 unless
changed (`Vendor.Floor`). With that much or less (the amount itself counts, as asked)
`Vendor.Shop` buys nothing, the Attractors neither, and says so once in chat, only where
there was something it would have bought. It is a gate, not a reserve: with more than the
limit, a purchase may still take the money under it (my reading; the owner asked for the
gate). The box is on the number's line of the Gear & food tab ("Not with [ ] gold or less").
Not seen in the game.

**1.0.6 (2026-11-25, night): buying lures. Passes its offline tests, committed and tagged;
not on CurseForge (the changelog for the next upload starts after 1.0.1). A file was added
(`Vendor.lua`), so the game needs a full restart after `tools/install.ps1`, not a
`/reload`.** The owner: "under the gear and food tab, i want a setting that can be turned on
and off which is automatically buy lures, when lures are available. i want it to have a
number, so if i say yes buy automatically, and buy 20. the addon automatically buys the
lures when it sees them. add the three basic lure options. add an extra option to always buy
Aquadynamic Fish Attractor, as many as are available at the vendor. automatically.", then
"correction, there are 5 basic lures, look up the names".

- The five, as looked up (Mastercraft's list in the owner's game and two guides for this
  client; in `CREDITS.md`): Shiny Bauble 6529, Nightcrawlers 6530, Aquadynamic Fish Lens
  6811, Bright Baubles 6532, Flesh Eating Worm 7307. The sixth lure of this client is the
  Aquadynamic Fish Attractor 6533, which has the rule of its own. One of the guides says
  vendors sell only the Bauble, the Nightcrawlers, the Bright Baubles and (a few of) the
  Attractor; the Lens and the Worm are offered anyway, as asked, and are simply never
  bought where no vendor has them.
- `Vendor.lua`: at `MERCHANT_SHOW` the vendor's list is gone through once. A ticked lure is
  bought up to the number **in the bags** (so opening a vendor twice does not buy twice;
  my reading of "buy 20"), a stack at a time, no more than the vendor has, no more than the
  money pays for (then a line in chat). With "Buy every Aquadynamic Fish Attractor a vendor
  has" ticked, all the vendor has are bought, whatever is in the bags. Things not sold for
  coins are left. What was bought and its cost is said in chat.
- Settings (per character): `buyLures` (off), `buyLureItems` ({ [item] = true }, none
  ticked), `buyLureCount` (20, at most 200), `buyAttractors` (off).
- Gear & food tab, left column: "Lures from vendors" under "Fishing skill now", which moved
  up (the gear list shows five lines at most now, the skill lines five). A switch, a box
  for the number, five tick boxes, the Attractor's tick box.
- Tests: `tests\test_vendor.lua`. The stand-in game has a vendor.
- **Not seen in the game:** all of it. In particular what the vendor calls answer on this
  client (`C_MerchantFrame.GetItemInfo` is used where it exists, the older
  `GetMerchantItemInfo` otherwise), that `BuyMerchantItem` takes a count up to a stack, and
  the new section's place on the tab.

**1.0.5 (2026-11-25, night): key combinations can be recorded. Passes its offline tests,
committed and tagged; not on CurseForge.** The owner, with 1.0.4 in the game: "i cannot
record something like CTRL and F for the gear key. we will need key combos. whether that is
ctrl and something, alt and something, or even three or four keys".

- **Why it failed is not known**: what the owner saw on the button was not said, and the
  screen at the time showed another tab. The recording had never been tested offline (the
  stand-in game always answered "no key is held"), and it took the held keys only from the
  game's own `IsAltKeyDown`, `IsControlKeyDown`, `IsShiftKeyDown` at the moment the last
  key went down. My guesses, none checked: those answers are not usable on this client;
  another addon's frame took the key first; or the combination was recorded but its
  binding lost to the fishing key's, which had the higher standing.
- So all three were dealt with (`KeyButton` in `UI\SettingsTab.lua`). The held keys are
  followed key by key (`OnKeyDown` and `OnKeyUp` of the button: "LCTRL" and "RCTRL" are
  CTRL, and so on for ALT, SHIFT, META), and the game is asked as well, guarded: either is
  enough. The button shows what is held as it is held ("CTRL-SHIFT-...") and takes the
  combination when a key that is not one of the four goes down, written in the game's own
  order (ALT-CTRL-SHIFT-META-key). While it listens the button is in the topmost layer.
  The gear key's binding has the same standing as the fishing key's.
- A combination is up to those four held keys and one more key or mouse side button: that
  is what the game can bind. Two ordinary keys at once is not something it can.
- Tests: the second half of `tests\test_gear_key.lua`. The stand-in game can be told which
  keys are held, or to keep it to itself.
- **Not seen in the game.** If it still fails, the button's text while the keys are held
  says how far the game's key events got: ask the owner what it showed.

**1.0.4 (2026-11-25, night): the gear key. Passes its offline tests, committed and tagged;
NOT in the owner's game and NOT on CurseForge (the changelog for the next upload starts
after 1.0.1).** The owner: "i want a configurable hot key or set of keys, for equiping
fishing gear (as configured by the player) and then swapping back to whatever gear they
had before, once they are done fishing", then "this keybind should be outside of the cast
and real button".

- `settings.gearKey` (none by default; per character like every setting). Settings tab,
  beside the fishing key, a second button "Gear key": click, press a key (with Alt, Ctrl,
  Shift, or a side button of the mouse); a right click sets none. The two keys can't be the
  same: each button refuses the other's key, and `Gear.UpdateKey` never binds the fishing
  key as the gear key. The capture code of the two buttons is one function now
  (`KeyButton` in `UI\SettingsTab.lua`).
- The key is bound for as long as it is set, pole or no pole (an override binding on a plain
  button, `KeepnetGearButton`, with no parent, so it works with the interface hidden). While
  it is set, the game's own use of that key is out of reach: the changelog says so.
- What a press does (`Gear.Toggle`, second half of `Gear.lua`). No pole on: the pole in the
  bags goes into the main hand, the one last fished with (`ns.char.pole`, noted whenever a
  pole goes on) or else the one that raises Fishing most; what the two hands held is written
  to `ns.char.hands` first. The pole going on turns fishing mode on, which puts the fishing
  clothing on as it always did: "as configured by the player" is the gear choices that were
  already there. Pole on: the main hand's weapon goes back, the off hand's half a second
  later; the pole coming off turns fishing mode off, which puts the clothing back.
- Left to the player, with a line in chat saying why: a pole put on by hand (nothing written
  down), hands that were empty before the pole, a weapon no longer in the bags, combat
  ("press the gear key again afterwards"), no pole in the bags.
- A press arrives as key down and key up: a second call within half a second is ignored.
- Tests: `tests\test_gear_key.lua`. The stand-in game's main hand can be equipped into, a
  pole empties the off hand, and a plain button's click script is run by a key.
- **Not seen in the game:** all of it. In particular that a plain button bound with
  `SetOverrideBindingClick` gets its click from the key on this client, that equipping into
  the main hand by name puts a two-handed pole on and sends the off hand to the bags, that
  the off hand goes back half a second later, and the Settings tab's top row with two
  buttons and a longer note.

**1.0.3 (2026-11-25, night): the line's strip. Passes its offline tests, committed and
tagged; NOT in the owner's game and NOT on CurseForge (the changelog for the next upload
starts after 1.0.1).** The owner: "i know the ui is hidden. but we need some sort of either
a counter on screen, or a progress bar counting backwards, showing the length of time the
line is out and when it expires. secondary to that i want either the loot window to show up
or, a text list to appear showing what was fished up".

- A small pane hangs under the live panel (`panel.strip`, `CreateStrip` in
  `UI\LivePanel.lua`; it is the panel's child, so it goes where the panel goes, also out of
  the hidden interface). A bar runs down from full to empty and says "Line out: 14 s"; under
  it, for 8 seconds, what the last cast brought up, a line a kind (icon, name, "x2"; four
  lines, the fourth "and N more"), or for 3 seconds "Nothing on the line". Between casts it
  says "Line in" for as long as there is something to list, then goes.
- When the line ends is the Fishing channel's own end (`UnitChannelInfo`, read when the
  line goes out: `Fishing.Line()`). When the game won't say, the strip counts up instead
  ("Line out for 6 s"). **Not seen in the game: what `UnitChannelInfo` answers here**, so
  which of the two the owner will see.
- `settings.lineStrip`: `hidden` (the default: only while Keepnet has the interface hidden,
  in either hiding mode), `always`, `off`. Settings tab, "Live panel", a list "Line timer
  and catch"; the "New versions" block moved down for it.
- The list was chosen over the loot window: the game's loot window is part of the hidden
  interface and taken out of it only with trouble, and Keepnet already takes the loot
  itself while everything is hidden. My choice of the two the owner offered.
- `Fishing.lua`: "LINE" false is now sent after the cast is marked as stopped.
- Tests: `tests\test_line_strip.lua`. The stand-in game's Fishing channel has a start and
  an end.
- **Not seen in the game:** all of it. The strip's place under the panel when the panel
  sits low on the screen, how it looks in each look, the new row on the Settings tab.

**1.0.2 (2026-11-25, late evening): a colour set called Matrix. Passes its offline tests,
committed and tagged; NOT in the owner's game (the development copy there is 1.0.1:
`tools/install.ps1`, which is usually blocked for me, then `/reload`, no file was added) and
NOT on CurseForge (uploads wait for the owner's word; the changelog for the next upload
starts after 1.0.1).** The owner: "i want a colour scheme added to both keepnet and glass.
call it Matrix. i want it to use the same colour scheme/looks that the code in the movies
of the matrix used."

- It is in the "Colours" list of Keepnet and Keepnet rounded (they share one list) and of
  Glass: black panes, green borders (a green rim on the glass), green buttons, the accent
  the green usually given for that code (`00FF41`).
- **The writing is green too, which no set of colours could do before.** A set of colours
  may now name an "ink": a function every text colour goes through (`MatrixInk` in
  `UI\Widgets.lua`). White becomes the full green, greys and other colours darker greens by
  how bright they are, the game's gold (headings, the yellow of a caution) the palest green,
  almost white, as the first sign of each falling line was; red stays red and green stays
  green, so "none left", "can't fish here" and "fed" still mean something. My choices, all
  of them: the owner asked for the look, not for these rules.
- How: every text of Keepnet's own looks (not the game's looks, not Windows 95, which has
  its own way) now remembers what it was given, because its `SetText` and `SetTextColor`
  are stood in for (`Remember` in `UI\Widgets.lua`), and Keepnet's copies of the game's
  fonts remember the game's colour. Choosing other colours goes over all of it at once
  (`SetInk`), so Matrix needs no reload and going back puts every text as it was. **This
  touches every text of the default look**, ink or none: watch for a text that reads wrong
  or is not updated.
- Not coloured: item pictures, the cog, the game's tooltips, chat lines.
- Tests: `tests\test_look_sounds.lua` ("Matrix") and `tests\test_looks.lua` (on glass).
- **Not seen in the game.** How the greens read against each other, and on glass over a
  bright scene, is untried.

**1.0.1 (2026-11-25, evening): the looks are released.** The owner, an hour after calling
them an experiment that might never see the light of day, with the Glass look in their game:
"publish to curse as 1.0.0.1, add a not early on that the themes are in and there is a
gimmick one (windows 95)", "also git it all". The number is 1.0.1: asked, because copies of
1.0.0 only understand versions of three parts and would never have told their players about
a "1.0.0.1", the owner chose 1.0.1 ("sorry i added an extra zero by mistake"). The branch
`looks` was merged into `main`. What the owner had seen in the game by then: the Glass look
in Amber with Overpass (their saved settings said so, and the error log held nothing from
Keepnet). **Not known to have been looked at in the game: Windows 95, Keepnet rounded, the
other colours, the Font list with shared fonts, the Appearance tab's new rows.** Everything
below about "the branch only" was true until this release.

**1.0.1 is on CurseForge** (uploaded 2026-11-25, about 18:00; "Under Review" a minute
later) and on GitHub (`main`, tag `v1.0.1`). The listing's description starts with a note
about the looks. What went up and how is in `PUBLISHING.md`, "1.0.1". The owner's game
holds the development copy made from the same files a few minutes before the version number
changed (it says 1.0.0 and is marked as a development build); the CurseForge app will offer
1.0.1 once it is approved, and `tools/install.ps1 -Remove` takes the development copy out
first. The owner also asked where else the addon could be published (Wago Addons: see
`PUBLISHING.md`, "Other sites").

**Seen in the game that evening, in captures for the gallery (the development copy, made
again as 1.0.1):** all four of Keepnet's own looks run. Keepnet with Overpass: text sits in
the middle of buttons and rows, the Appearance tab's new rows fit. Windows 95: the title
bars, the tabs on their page, the white list with its headings, the progress bar and the
dots button are as meant; the greys inside texts (percentages, "next press", "off") are
faint on the grey face, and the font is the game's Arial Narrow. Glass in Amber: the scene
shows through, rim, wash and shadow are there, text reads at 65 % over dark water (a
bright scene is still untried). Keepnet rounded in Dusk: round corners everywhere. The
error log held nothing from Keepnet. Four pictures of these are in the gallery
(`PUBLISHING.md`, "1.0.1"). **1.0.1 is "Approved".**

**What the looks are (written while they were an experiment on the branch `looks`, before
the release above):** The owner: "for now,
the tinkering with these themes and stuff is purely development, i am not sure if it will see
the light of day. depends on how much of what we can take from other ui's". `main` is still
the released 1.0.0. Everything in this entry passes its offline tests and has never run in
the game.

What the owner asked for, in order: looks like the ten most popular interface packs "using
their assets" (see "What can be taken from other packs" below: almost nothing); then "one
theme, called windows 95 ... to look exactly like windows 95 dialogues"; then round corners
for the Keepnet look "as an option? so keepnet, keepnet rounded. then have a seperate
selector for the colours? windows 95 would sit in the first selection"; then "a few different
colour schemes, for each theme"; then a font "that sort of fits with the fishing theme ...
the default for the keepnet theme" and a "glass skin/theme" (both only researched so far).

What is built:

- **Look and colours are two choices** (Appearance tab: "Look", "Colours", then the accent).
  The setting `theme` now names the look: `keepnet`, `rounded`, `win95`, `forever`,
  `ellesmereui`. (**The ElvUI look is gone**, on this branch: the owner, "remove elvui as it
  just does the forever look anyway". Its adapter in `UI\Adopt.lua` was never run against
  that suite. A saved `elvui` becomes `forever`; `main`, the released 1.0.0, still has it.) The colours are in `settings.schemes[family]` (`keepnet` for both
  Keepnet looks, which share the six sets that used to be themes; `win95` for its own). A
  saved theme that was one of the old colours (`slate`, `forest`, `ember`, `dusk`, `black`)
  becomes the Keepnet look in those colours the first time it is applied. Forever and the
  suite looks have only their own colours: the list says "The look's own" and is dimmed.
  Colours change at once; a look drawn another way asks for a reload (`W.look`: `flat`,
  `round`, `retro`, `native`).
- **A frame can be drawn by a look instead of by its backdrop.** `W.Skin(frame, color,
  group, kind)` now replaces the frame's `SetBackdropColor` and `SetBackdropBorderColor`
  with ones that reach whatever draws it, so the screens go on colouring frames the way
  they did. `kind` says what the frame is (`button`, `header`, `field`, `list`, `menu`,
  `slot`, `thin`, `track`) for looks that draw each differently.
- **Keepnet rounded** (`UI\Round.lua`): a quarter circle in each corner with plain colour
  between, the border the same way from a quarter ring. Four small pictures in
  `Keepnet\Media` (`RoundFill8/4.tga`, `RoundRing8/4.tga`), white so they take any colour,
  made by `tools\make_art.py`: the first files in the addon that are not code. Corners 8
  wide for the window and the live panel, 4 for everything else; column headings stay
  square.
- **Windows 95** (`UI\Retro.lua`): nothing but plain colour. Two-line bevels (out for
  windows and buttons, in for text boxes, lists and tick boxes), a title bar with a close
  box, tabs on a framed page with the front one taller, a tick, a drop-down with an arrow
  button, a slider with a groove and a raised handle, a progress bar whose text is light
  over the filling and dark beside it, lists on a white sheet with the chosen line in the
  selection colour, menus that turn the line under the mouse that colour, buttons that go
  in while held. The live panel gets a title bar too: the zone and the clock stand on it and
  the cog is a small button with three dots. Text is dark: every text made by `W.Text` is
  "dressed" (`Retro.Dress`), which swaps each colour, the ones written inside a text too,
  for the nearest dark one of that screen's sixteen. All nineteen of that system's colour
  schemes are there with its own numbers (source in `CREDITS.md`). An accent of the
  player's own colours the title bar and the selection.
- Tests: `tests\test_looks.lua` (all three drawn looks), `tests\test_look_sounds.lua` changed for the
  two choices. The stand-in game now remembers text and picture colours.

**Not seen in the game: any of it.** The first things to look at: whether the bevel lines
come out even (one measure of the interface is about 2.8 dots on the owner's screen, so a
line may be 2 or 3 dots); the font (see below); the tabs' place on the page's edge; the
Appearance tab, whose left column is one row longer; texts that are a size larger than
before in the Windows 95 look and may run into each other; the round corners against a
bright scene. The game holds the copy from the CurseForge app: installing this branch
needs the owner's word (`tools\install.ps1`), and a full restart, because files were added.

**Open, waiting for the owner:**

- **The Windows 95 font.** Until a file of its own is there the look uses the game's Arial
  Narrow, which is close but not it. `Retro.lua` already asks for `Media\W95FA.otf`: W95FA
  (Alina Sava / FontsArena, a redrawing of that system's font, SIL Open Font License 1.1
  according to Fontsource). Fetching a file from the web needs the owner's yes, and its
  licence text has to be read and shipped with it.
- **A font for the Keepnet look: built, with Overpass** (the owner: "a font that is not
  default that sort of fits with the fishing theme ... the default for the keepnet theme",
  then "i like overpass for the default font", and a yes to fetching its files).
  `Keepnet\Media` holds `Overpass-Regular.ttf`, `Overpass-SemiBold.ttf` (headings) and the
  licence text `Overpass-OFL.txt`, as published in the project's own repository. Keepnet's
  two own looks are written in it; the Appearance tab has a "Font" list (Overpass, the
  game's own; `settings.font`, changes at once). How: `W.FontObject` keeps a copy of each
  game font the texts are made in and draws the copy from the chosen file, so sizes and
  colours stay the game's. Used for the western languages and Russian; the others keep the
  game's font, and so do the small numbers on item pictures. **The list also offers every
  font another addon on the computer shares through LibSharedMedia** (the owner: "i think
  we should a few more, but i am not sure what options to include, unless we target what
  are installed on a machine, if that is safe and doable?"). An addon cannot see the
  computer's own fonts, only files inside the game's folders; what other addons share is
  the nearest thing, and it costs Keepnet nothing to ship and nothing to license: the file
  stays in the addon that brought it. Saved as `shared:` and the name; when that addon is
  gone the default shows in its place (the choice is kept), and one that loads after
  Keepnet is taken up when it shares its fonts (the library's "registered" callback). On
  the owner's computer the library is there (EllesmereUI, Questie, RareScanner and BugSack
  bring it) and EllesmereUI shares its fonts through it, so the list should hold those and
  the game's own four. **Not seen in the game:**
  whether the text sits in the middle of buttons and rows (this font is known for sitting a
  little high or low), how its size compares, and that its digits are not all one width,
  so changing numbers may shift a little. What the research said, for the record: no free
  text face has a real history at sea; the honest links are signs. In order: **Overpass** (from American road-sign lettering; Latin and Cyrillic; OFL 1.1 with
  no reserved name; static files about 210 KB each in its own repository; its digits are
  probably not all one width, and text may sit a little off centre), **Signika Negative**
  (made for signs and for light text on dark, digits all one width; no Cyrillic; about 344
  KB each), **National Park** (drawn from carved trail signs in a national park, the one
  with a real outdoors history; 110 KB; small sizes and digits untried). For a title only:
  **Spinnaker**, from lettering on posters for travel by ship (OFL with a reserved name,
  one weight, no Cyrillic). A font without Cyrillic needs the game's own font for the
  Russian client. Each needs its licence text shipped beside it.
- **A glass look** (the owner: "i've seen the option for a glass skin/theme somewhere in
  some addon/ui. i wouldn't mind being able to do something like that"). Researched
  2026-11-25, nothing built; the owner has not yet said whether to build it or how.
  - What they most likely saw: Spotnick's "Glass" addons for this very client (Glass UI,
    Glass Unit Frames, Glass Panel), all drawn by one library, **LibGlass-1.0**
    (https://github.com/Spotnick2/LibGlass), which is **MIT** and writes its whole method
    down (`docs/GLASS-MATERIAL.md`). Two other glass interfaces for this client (Fantasy
    Glass UI, Lattice) are all rights reserved.
  - There is no blur for addons: what is behind a frame always shows through sharp. Glass
    is layers: a soft shadow outside, a dark see-through tint, a faint white wash that
    grows upwards, a bright thin rim strongest along the top, round corners by a mask,
    and text with a solid dark shadow. For reading, the tint has to be dense (0.5 to 0.8);
    0.24 only where there is little text.
  - Two ways were open: carry LibGlass (MIT, with credit), or draw its own from the same
    ingredients. **The owner chose the second ("go with 1"), and it is built:** the look
    "Glass" (`glass`, third in the list), in `UI\Round.lua` beside the rounded look, whose
    pieces it uses. A pane is the round fill at the tint's density; the border is a rim of
    light (0.55 along the top, fading down the sides to 0.12 along the bottom; fainter on
    small pieces); panes and buttons get a wash of light over the top; the window and the
    live panel get a soft shadow from one more picture (`Media\GlassShadow8.tga`). Buttons
    are lighter patches (white at 0.09, 0.20 under the mouse), what is set into a pane
    (bars, text boxes) darker ones (black at 0.32), menus and drop-down lists nearly solid
    (0.93) so they read over what they cover. Five colours: Smoked, Deep water, Midnight,
    Moss, Amber. **The tint is 65 % dense by default and the player's to change** (the
    owner: "set the tint to default to 65%, but allow it to be changed"): in this look the
    two "Backgrounds" sliders set `glassPanel` and `glassWindow`, kept apart from the other
    looks' `panelOpacity` and `windowOpacity`. A scheme's colour may now carry a fourth
    number, how solid it is. Text is the game's light text with its own shadow. No sheen.
    **Not seen in the game:** all of it; first of all whether text reads at 65 % over a
    bright scene, whether the sides' fading (a gradient) works on this client (if not they
    are evenly faint), and whether the shadow's sides meet its corners without a seam.
  - Facts worth keeping, as LibGlass measured them on this client: a gradient ignores
    `SetAlpha` (the alpha goes in its colours); a mask only reaches textures of its own
    frame; a sliced mask fails on small boxes; `SetTextureSliceMargins` and
    `CreateMaskTexture` exist here; pictures as uncompressed 32-bit TGA.

**What can be taken from other packs (researched 2026-11-25; figures and licences as read
that day):** almost nothing. Of sixteen packs looked at, nine are "all rights reserved" or
forbid redistribution outright (ElvUI, Tukui, EllesmereUI's own art, BenikUI, GW2 UI,
ToxiUI, NDui, RealUI, and one more whose licence also forbids any use of its content by an
AI assistant: it was not read past its licence and must not be worked from); AzeriteUI is
MIT for code but says its artwork may not be shared; WindTools limits its GPL to its own
family of addons; only ShestakUI (MIT) and a pack dead since 2019 would allow it on paper,
and the origin of their pictures is unknown. Fonts are a separate question in every pack:
several ship commercial ones. CurseForge's own rule is permission or licence, plus credit.
What others do instead, and what is open to Keepnet: draw the style with plain colour
(BigWigs' "ElvUI" and "TukUI" bar styles are numbers, not pictures), or use the pack's own
pictures at run time when the pack is installed, which is what the EllesmereUI and ElvUI
looks already do. Naming a look after a pack has precedent (BigWigs, Details).

**The repository is public since 2026-11-25** (the owner: "publish to git and fix, make repo
public. push to curse"). Its history starts again from one commit of 1.0.0: the history from
before is kept by the owner, privately, and is not part of the public repository. From here
on everything in this repository is public the moment it is pushed: no player's or
character's real name in any file, picture or commit message (the samples' "Vale" and
made-up names only), and a look at every picture at full size before it is committed.

**1.0.0 is on CurseForge since the same hour** (uploaded 2026-11-25; "Under Review" a
minute later, approval not seen yet). The next upload's changelog starts after 1.0.0
(`release.py --since 1.0.0`). The owner also had one line added to the listing's feature
list ("add bullet point about searchable character sessions"). What went up and how is in
`PUBLISHING.md`, "Where it stands (2026-11-25)". **The update notice went out without ever
having run in the real game**: the owner's game still held the build from before it (the
per-character half was seen there and "works well"). Where the entries below say 1.0.0 is
not on CurseForge, or that the owner has not confirmed the number, that was before. Open:
the owner's game needs `tools\install.ps1` and a full restart to get the notice; the first
things to look at there are in the notice's own entry below ("Not seen in the game"). The
listing's description says what the notice does and how to turn it off since a few minutes
after the upload (the owner: "add those details in there").

**The development copy is out of the owner's game since later on 2026-11-25**
(`install.ps1 -Remove`, on the owner's "remove dev copy so i can install the curse
version"; `KeepnetSounds\` and the saved data were left alone). The game is to get Keepnet
from the CurseForge app from here on, so ask before running `tools\install.ps1` again: it
would put a development copy over the app's install. **CurseForge shows 1.0.0 as
"Approved"** (seen about 25 minutes after the upload), so the app offers it. A copy from
the app is a released one: it announces its version like any player's.

**Seen in the game later on 2026-11-25, in captures taken for new pictures** (the owner set
the screens up, sample sessions on): the History tab's top row (list of characters, zone
list, "Today's prices", totals) and the Zones tab's (hint, heading, list of characters) fit
without touching; the history search works on the list of characters' choice; and, after
the owner installed the build with the notice and restarted the game, the "New versions"
block sits at the bottom of the right column of Settings with room to spare, the module
loads, and its note ends "This is a development copy: it listens and never announces": so
`C_AddOns.GetAddOnMetadata` does read the custom TOC line on this client. Not yet known from
that run: whether the channel was joined and stayed out of chat (ask, or read
`!BugGrabber.lua` and the saved data after the owner's next logout). New pictures in
`media\screens`: `03-history.png`, `04-zones.png`, `09-find-a-fish.png` (not in the gallery
yet). The capture of Settings carries the development-copy sentence, which no player's copy
shows, so it is not a picture for the gallery as it is.

**The update notice on the released copy, the owner's report (2026-11-25, on 1.0.0 from the
CurseForge app):** "i saw no joined channel message, nor did I see a chat tab". So the
channel prints nothing and sits on no chat window, on a copy that announces. Read after
the owner quit the game: `!BugGrabber.lua` holds no error that names Keepnet (its newest
error of any addon is six game sessions old), and `KeepnetDB.updates.heard` is empty, as it
must be while no version newer than 1.0.0 exists. **The channel is joined:** another addon
the owner runs keeps a log of the game's channel notices in its saved data, and it holds
the game's own "you joined" notice (`YOU_CHANGED`) for `KeepersNet` as channel 7, twice
that afternoon, each a few seconds after a login. So `JoinTemporaryChannel` is allowed from
a timer here, the channel takes a number after the game's own, and the notice the game
sends about it is kept out of chat by Keepnet's filter. The owner then asked the game itself on the released copy, on another character:
`/dump GetChannelName("KeepersNet")` printed `7, "KeepersNet", 0, false` (the number, the
name, no instance, not a community channel), with the chat tabs still only the usual four. **Still not seen:** announcing and
being told, which needs a version after 1.0.0 and two players running it; what
`SendAddonMessage` answers; and leaving the channel from the switch in Settings.

**1.0.0, the update notice (2026-11-25): Keepnet tells the player that a newer version is
out. It passes its offline tests and is in the repo. It is NOT yet in the owner's game: the
game holds the 1.0.0 development copy without the notice until `tools\install.ps1` is run
again, and then the game must be restarted fully, not `/reload`, because a file was added
(`Updates.lua`, so the TOC changed). It is not on CurseForge, and the next upload's
changelog still starts after 0.9.9.**

The owner, after trying the per-character changes: "works well, the update feature would
roll into 1.0.0". So it is part of 1.0.0, not a version of its own. Earlier the same day:
"let's stick to the custom channel" (asked whether General could carry it), and the
channel's name came from the owner's "what about keeper's net for the channel?", written
`KeepersNet` because a channel name is one word. The owner's other answers are in "Update
notice" further down: on by default with a switch, development copies silent, guild and
group too, two announcers needed.

What it does, all of it in `Keepnet\Updates.lua`:

- **What the player sees.** "Keepnet X is out (you have Y). Update it with the CurseForge
  app." Once in chat per login (and again if a still newer version comes to be believed), on
  the live panel for 20 seconds the first time the pole goes on (`LivePanel.Notice`; the
  short form there, "Keepnet X is out (you have Y)", because the panel's line is narrow), and
  under the new "New versions" heading on the Settings tab for as long as it is known.
- **How copies talk.** Hidden addon messages, prefix `Keepnet`, text `V1 <version> <mark>`
  (the mark is 8 hex digits made at load, so a copy knows its own message when it comes
  back). Three routes: a chat channel of Keepnet's own named `KeepersNet`, which is
  realm-wide; the guild; and the party or raid.
- **The channel.** Looked at 10 s after entering the world, then every 5 s. It is joined
  only once the game's own channels are in, so theirs keep their numbers; joined anyway
  after 120 s; the looking stops after 180 s. It is a temporary channel
  (`JoinTemporaryChannel`): gone at logout, nothing left behind if Keepnet is removed. It is
  taken off every chat window (at once, and 1 s and 5 s later, and after any notice about
  it), and its join, leave and chat lines are filtered out of chat. Its number is looked up
  before every send. It uses one of the player's channel places.
- **When a copy speaks.** Once per login on each route that is open, and once to each group
  it joins. An older copy heard is answered on the same route after a random 1 to 5 s. No
  route gets more than one message in 10 s: an answer that comes due sooner waits its turn.
  The answer is not given at all when two other copies of this version or newer spoke there
  first.
- **When a newer version is believed.** Only when two different players have announced it:
  what is believed is the newest version two of them vouch for (the second highest claim).
  Each player's newest claim is kept for 7 days in `KeepnetDB.updates.heard` (`[player] =
  { version, at }`), which is the account's and not a character's. A claim this copy has
  caught up with is dropped.
- **What is taken for a version.** Only "a.b.c", each part 99 at most, and at most one major
  ahead of this copy. A message of another prefix, shape or chat type counts for nothing,
  nor does one with no sender.
- **Held back.** Nothing is joined, left or sent in combat or while the game holds chat
  back (`C_ChatInfo.InChatMessagingLockdown`). A hidden value is never read.
- **The switch.** Settings, "New versions", "Tell me when a newer Keepnet is out":
  `settings.updates`, on by default, per character like every setting. Off: Keepnet leaves
  the channel, says nothing and hears nothing.
- **Development copies.** `tools\install.ps1` now adds the line `## X-Keepnet-Build: dev`
  to the copied TOC. Such a copy joins and listens, and never announces or answers; the
  line in Settings says so. The zip `release.py` builds has no such line.

**What follows from that, and matters for testing:**

- The owner's own game always holds a development copy, so it never announces. Announcing
  can only be seen in the game with a released zip, on another account or by another player.
- 0.9.9 and older have no listener. Nobody can be told about 1.0.0 itself: the notice first
  does something for the version after 1.0.0.

**My choices, not the owner's words:**

- 7 days of memory for what a player announced.
- The timings: 10 s to settle, 5 s between looks, 120 s before joining without the game's
  channels, 180 s before giving up.
- "Two others answered" as the rule for staying silent. It had to be two and not one: with
  one, an older copy would only ever hear one answer, and the two-announcer rule could
  never be met.
- The panel line lasting 20 s, and the wording of the notice.
- A temporary channel rather than a permanent one (LayerSwap's note on what a permanent one
  leaves behind; see `CREDITS.md`).

**Not seen in the game:** all of it. In particular:

- that `JoinTemporaryChannel` is allowed from a timer here;
- that the channel really stays off every chat window and prints nothing;
- what `C_ChatInfo.SendAddonMessage` answers (0 is taken as sent);
- what the sender's name looks like (it is used as it comes, as the player's key);
- that `C_AddOns.GetAddOnMetadata` reads the custom TOC line. If it does not, a development
  copy would announce; the two-announcer rule still keeps one copy from raising a notice;
- that leaving the channel works from the click in Settings;
- the place of the "New versions" block at the bottom of the right column of Settings,
  worked out by arithmetic.

Tests: `tests\test_updates.lua` (83 checks: versions, the login, what is ignored, the
answer and its turn, staying silent, two announcers, the memory, the game's channels coming
late or never, guild and group, combat and lockdown, the switch, a development copy). The
stand-in game got chat channels, addon messages, guild and group, and TOC metadata
(`tests\wowstub.lua`).

Credits for the facts and patterns are in `CREDITS.md` (Mastercraft, Forever Dungeon
Journal, MapUtils, LayerSwap) and at the top of `Updates.lua`.

What follows was written before the update notice was built.

**The owner, 2026-11-25: "we will combine all the current unsubmitted changes into version
1.0.0". So there is no 1.0.1: everything since 0.9.9 (each character its own sessions, the
list of characters on History and Zones, and every setting and the panel's place per
character) is version 1.0.0, one section in `CHANGELOG.md`, and the tag `v1.0.0` points at
the combined work (the tag `v1.0.1` is deleted). That also settles the number: the owner
has now said 1.0.0. In the two entries below, written while the work was still two
versions, read "1.0.1" as "the second half of 1.0.0". The state is unchanged: passes its
offline tests, not on CurseForge, and the next upload's changelog starts after 0.9.9.
Since 14:47 on 2026-11-25 it is in the owner's game as the development copy
(`tools\install.ps1` ran once the owner had tried to run it themselves; a `/reload` loads
it). Where the entries below say it is not in the game, that was before.**

**Seen in the game on 2026-11-25, by the owner after a `/reload` on the main character:**
"reloaded, sessions show under [the main character's full name]". So the character is identified, the four
sessions from before were taken over by the right character, and History shows the full
name. **Not yet reported:** a login on another character (its empty history, the "first
time on" line, the settings copied over and then kept apart), the list of characters on
History and Zones and how it sits in the header, and the saved data after the change
(written at the next logout or reload; read it and `!BugGrabber.lua` then).

**1.0.1 (2026-11-25): everything a player sets is kept per character. Passes its offline
tests. It is NOT in the owner's game (the game still holds the development copy of 0.9.9:
`tools\install.ps1` could not be run in that session, so the owner runs it
or allows it; then a `/reload` loads it, no file was added), and it is not on CurseForge
(uploads wait for the owner's word; the changelog for the next upload starts after 0.9.9).**
The 1.0 number is still not confirmed by the owner: ask before anything goes up under it.

The owner, after 1.0.0: "i want everything per character", then "settings, keybinds,
appearance, sound the lot".

What 1.0.1 does:

- **Every setting is the character's own**: the fishing key, the lure, food and other-item
  choices, gear on or off, the fishing sound and its volume, the alerts and their sounds, the
  whole Appearance tab (theme, accent, opacity, scale, borders), the hide-interface mode and
  its parts, the price source, the session gap, the zone split, today's prices, the panel
  lock and the rest. So are the live panel's place and size.
- **How it is kept**: `KeepnetDB.settings`, `KeepnetDB.panel` and `KeepnetDB.panelSize` are
  always those of the character named in `KeepnetDB.owner`, the one played last. Every other
  character's are parked in `KeepnetDB.chars[key].kit = { settings, panel, panelSize }`.
- **The swap** is in `Core.Identify()`, at login, when the character is not
  `KeepnetDB.owner`: the previous owner's three are copied into its kit, this character's
  kit (if it has one) is loaded IN PLACE into the same settings table, and the defaults are
  filled in again. `ns.settings` stays one table for the whole session, so nothing that
  holds it goes stale. A character with no kit keeps what is there. An account with one
  character never swaps anything.
- **A new character** therefore starts with a copy of the settings, and the panel's place
  and size, of the character played last. After the update, the settings the account shared
  become those of the first character logged in. The chat line reads: "first time on
  <name>. It has its own sessions and history, and starts with the settings of the character
  you played last; from here on its settings are its own."
- `gearChoice`, `gearSwap` and `usedAt` stay in `KeepnetDB.chars[key]`, as in 1.0.0.
- **When the game says late who is playing** (identification at `PLAYER_LOGIN` instead of at
  load, after the addon's frames exist), the swap fires `SETTINGS` and applies the theme and
  the panel's place again. A theme of another kind (flat, native, suite) then needs a
  `/reload`, as changing between kinds always did.

**My choices, not the owner's words:**

- A new character starts with a copy of the last played character's settings, not with the
  defaults. The owner said "everything per character", not where a new one starts. The
  reason: the key, the theme and the sounds are set up once and would otherwise have to be
  set again on every character. If the owner wants a clean start, that is the "no kit" case
  in `Core.Identify()`.
- What stays shared by the account: the sessions store itself (each session is filed under
  its character), what Keepnet has learned about which buff an item gives
  (`KeepnetDB.buffOf`: a fact, not a preference), and the backups of the game's own sound
  and interact settings for crash recovery (`soundBackup`, `interactBackup`: those game
  settings are the account's).

**Not seen in the game:** any of it. In particular the late swap (`SETTINGS`, the theme and
the panel's place applied after the frames exist), and whether a key bound for one character
is let go when another character with a different key logs in.

Tests: `tests\test_characters.lua` covers it offline, the late swap too (the test's
`Stub.guidLate` makes the game answer only at login): there the last character's key is let
go, this character's is bound, and the panel is placed again. The swap itself is
`TakeSettings` in `Core.lua`.

What follows was written before 1.0.1.

**1.0.0 (2026-11-25): every character has its own sessions. Passes its offline tests. It
is NOT in the owner's game yet (the game still holds the development copy of 0.9.9:
`tools\install.ps1` was not allowed to run in that session, so the owner runs it or says to;
then a `/reload` loads it, no file was added), and it is not on CurseForge (uploads wait for
the owner's word; the changelog for the next upload starts after 0.9.9).** The number is the next one after 0.9.9 the way 0.9.0 followed 0.8.9;
the owner has not said "1.0", so ask before it goes up under that number.

The owner, in four messages: "does not account for more than one character on an account";
"i want it to know when someone is on another character or new character. each character
should have their own session history (zones et al)"; "make it possible to switch which
character's history/sessions are viewable with a dropdown showing any detected characters";
"the drop down should only affect the session list and history, not the live tracking of
course".

What was wrong, read from the owner's saved data: all four sessions were filed under a
first name with no realm, and the account has two characters with that first name (and two
more). On this client `GetRealmName()` is "" and the second
value of `UnitName("player")` is a surname, so the old key (first name, plus the realm when
there is one) could not tell the two apart. And apart from the key, the account had one
running session (`KeepnetDB.currentId`), so any character logging in saw the last one's
session on the live panel until it cast, and History and Zones listed everybody's.

What 1.0.0 does:

- **The key is the character's GUID** (`Core.Character()`, set once by `Core.Identify()` at
  load, login and each loading screen until the game answers). `KeepnetDB.chars[key]` holds
  the name for the screen (first name and surname, `Core.CharacterName`) and what is kept per
  character; `ns.char` is that table for the character playing. Without `UnitGUID` at all
  (the stand-in game) the key is the full name with the realm.
- **A running session per character**: `KeepnetDB.current[key]` replaces `currentId`.
  `Sessions.Current()` and `IsCurrent` are the playing character's (`Sessions.SetCharacter`).
  A cast on one character no longer ends another's session: back within the session gap, it
  carries on.
- **Own lists**: `Sessions.List`, `ZoneNames`, `Zones` and `FindCatches` take a character.
  History, its search and Zones show `UI.Viewed()`: the character playing unless the list
  says otherwise.
- **The list of characters** (`UI.CharacterPicker`, `MainWindow.lua`): top left on History,
  top right on Zones, one choice for both. It offers the character playing first, then
  every character in `KeepnetDB.chars` and anyone else with sessions, A to Z, then "All
  characters". The choice is not saved: a login or reload starts on the character playing.
  The live panel and the Session tab's running session never look at it. With the sample
  sessions on it offers only "Vale", so pictures carry no real name.
- **Sessions from before**: `Sessions.Adopt` gives the sessions under the old label to the
  character that label fits, at its first login. Two characters can fit one label here, so a
  session whose item links carry a higher level than the character has now is left for the
  other (`Sessions.Level` reads the level out of the links). Replayed offline on a copy of
  the owner's saved data: the namesake, if below level 37, takes nothing, and the level 38
  character that fished them takes all four and its running session. **If the namesake is
  level 38 or more and logs in first, it would take them**: its level is not known here. The owner's saved
  data from before the change is kept beside the file as `Keepnet.lua.pre-1.0.0`.
- **A new character** is told once in chat ("first time on ..."), unless it is the first
  character seen or it took over old sessions.
- **Per character too** (my additions; the owner asked for the sessions): the gear chosen per
  slot (`ns.char.gearChoice`, was `settings.gearChoice`; an old account-wide choice goes to
  the first character seen), what the gear replaced (`ns.char.gearSwap`, was
  `KeepnetDB.gearSwap`; an old note goes to the character wearing what it names), and when
  an item was last used (`ns.char.usedAt`). In 1.0.0 every setting was still shared by the
  account, the chosen lure and food among them, so a lure chosen on one character read "none
  left" on one that carried none. **1.0.1 changed that:** the owner asked for everything per
  character (see the entry above).
- Going back to 0.9.9 after 1.0.0 has run would show the sessions under "Player" (the old
  code shortens the key at its first hyphen) and with no running session; nothing is lost.

**Not seen in the game:** all of it. In particular that `UnitGUID("player")` answers at load
or login (if it never does, the character is not identified and nothing of it is saved under
a key: the lists stay empty), the two lists' places (worked out by arithmetic: History's zone
list is 170 wide now, the Zones heading 168 narrower and cut off sooner), and the native
themes' version of the list.

Tests: `tests\test_characters.lua` (two characters with one first name, a third never seen,
the takeover, the lists, the sample sessions). The stand-in game plays a character from
`Stub.player` and `Stub.realm`; a test that wants GUIDs defines `UnitGUID` itself.

What follows was written before 1.0.0.

**0.9.9 is on CurseForge (uploaded late on 2026-11-24, "Approved" within about ten
minutes), and the owner has seen it in the game:** "that works well. push 0.9.9 to
curse". What exactly they tried was not said (the wheel over the panel's buttons, the native
themes and the widest panel are still unconfirmed). The upload covers 0.9.8 too. The
listing's description says since that evening that the panel can be resized and that a long
catch list scrolls (the owner: "fix the line so it indicates resizable window"), and its
pictures that show the live panel or the Settings tab are new ones of 0.9.9 (five in all;
the owner set the screens up, three are from their own session); the old ones were deleted
on the owner's word and the gallery is in its old order, twelve pictures. The picture of
the hidden interface was taken once more in Stormwind, with other players' names smudged
out (new tool `tools\smudge.ps1`; see `PUBLISHING.md`). Nothing about the listing is open. The game holds the
development copy of 0.9.9, the same files as the upload apart from the `LICENSE.txt` the zip
adds. The next upload's changelog starts after 0.9.9 (`release.py --since 0.9.9`). Details in
`PUBLISHING.md`. What follows was written before the upload.

**0.9.9 (2026-11-24): the catch list scrolls and the live panel can be sized. Passes its
offline tests; not on CurseForge (it waits with 0.9.8 for the owner's word; the changelog for
the upload starts after 0.9.7).** The owner: "the current session in the live window should
be scrollable, currently it is showing 3 more and i can't see what it is. maybe make the
window's size adjustable by dragging the corner?" **The development copy in the
game is 0.9.9** (the owner: "run it, we will wait for a few more changes before publishing
again"; `tools\install.ps1` ran with the game open, a `/reload` loads it, no file was added
to the addon). So 0.9.8 and 0.9.9 both wait for more changes before an upload. Both changes
are in `UI\LivePanel.lua`:

- Scrolling: `Sessions.CatchList` no longer adds the rest up in a last row (its `maxRows` is
  gone); the panel shows `MaxRows()` rows of the whole list from `listOffset`, and the mouse
  wheel moves it (a third of the rows on show per notch, at least one). The panel takes the
  wheel only while there is something to scroll (`EnableMouseWheel` is set at every refresh),
  so the camera zooms as usual over it the rest of the time. A track and a mark in the accent
  colour (`scrollTrack`, `scrollThumb`, 3 wide in the right margin) show where the rows are
  in the list; they can't be dragged.
- Sizing: `panel.grip`, a 12 by 12 button in the bottom right corner drawn as six dots (no
  picture file). The drag is followed by hand in the grip's `OnUpdate` (`StartSizing`, `Size`,
  `StopSizing`), not with the game's `StartSizing`, so the panel keeps its top left corner
  and the height moves a row at a time. Sideways: the width, 260 (the old fixed width, still
  the narrowest) to 480; `LayoutWidth()` sets every width that follows it, the lists' too
  (`menu:SetMenuWidth`). Up and down: how many catches show before the list scrolls, 3 to 30
  (8 until it is dragged). Saved as `KeepnetDB.panelSize = { width, rows }`.
- **My choice, not the owner's words:** the height is a most, not a fixed size. The panel
  still grows with the list and stops at the chosen rows; while the corner is held the chosen
  room shows empty, with a line "Up to N catches, then the list scrolls", and on letting go
  the panel takes the room of the catches there are. A drag up or down starts from the rows
  on show, so dragging down from a list of 2 by 3 rows gives a most of 5 (less than the 8 it
  had). If the owner wants the height to stay where it was dragged, that is `room` in
  `RefreshList`.
- Also my choices: a locked panel has no grip; "Reset position" in Settings became "Reset
  panel", and it and `/kn reset` put the size back too; a drag that stays within half a row
  of level changes only the width.
- **Not seen in the game:** all of it. In particular whether the wheel reaches the panel when
  the mouse is over one of its buttons or lines, whether the grip gets its mouse-up when the
  button is let go off it (`IsMouseButtonDown` each frame is the net), how the dots and the
  scroll mark look in each theme (on the native themes the border art is thicker), and the
  panel wider than 260 in general.

**0.9.8 (2026-11-24, after the upload of 0.9.7): not on CurseForge, and not to go up yet.**
The owner: "another change, we will make it and not push yet. until more changes happen.
colons after the word Lure, Food and Gear". The three lines read "Lure: ...", "Food: ...",
"Gear: ..." (they had two spaces). The development copy in the game is 0.9.8. It waits for
more changes before an upload; the changelog then starts after 0.9.7.

**0.9.7 is on CurseForge (uploaded the evening of 2026-11-24; "Under Review" when last
looked, approval not seen).** The owner had tried the development copy: "the changes look
good. push to curseforge. no need to add media or description items". So 0.9.3 to 0.9.7
are seen in the game by the owner, in their words "look good"; what exactly they looked at
was not said (the skill-gain events firing, and the native theme, are still unconfirmed).
The listing's description and pictures were not touched and do not show the new lines.
The game still holds the development copy of 0.9.7, the same files as the upload apart
from the `LICENSE.txt` the zip adds. The next upload's changelog starts after 0.9.7
(`release.py --since 0.9.7`). Details in `PUBLISHING.md`.

**0.9.7 (2026-11-24): the total skill on the bar, and the development copy in the game is
now 0.9.7.** The owner: "in the skill bar. add a number in green in brackets next to where
the number for the lure addition is, that shows the existing skill+all buffs value. just the
number". The bar reads "Fishing 283 / 300  +105 (388)", bonus and brackets in the same
green. With no bonus there is no "+N" and no brackets either (my choice: the total would
only repeat the skill). The bonus is what the game reports on top of the trained skill,
the same number the zone colour already uses.

**0.9.6 (2026-11-24): colons on the live panel, and the development copy in the game is
now 0.9.6.** The owner: "add a seperator between the text and each number value... use a
colon i think. so gains: number, casts: catches: and so on". Done for the six number lines:
Skill gains this session, Casts, Catches, Empty, Value, Per hour. Left as they were, my
reading of "number value": the skill bar's own text ("Fishing 283 / 300"), the Lure / Food /
Gear lines (names, not numbers) and the Session tab's summary line in the window.

**0.9.5 (2026-11-24): one wording change, and the development copy in the game is now
0.9.5.** The owner: "change the wording on the skill gains to be Skill gains this session
then the number". The line reads "Skill gains this session  3" (two spaces before the
number, as on the Value line; my choice). Where the text below says 0.9.4 is in the game,
read 0.9.5.

**0.9.4 (2026-11-24) passes its offline tests and is in the owner's game as a development
copy; it is not on CurseForge.** The owner, offered an upload or the copy: "let's do the dev
copy first". `tools\install.ps1` was run with the game open (a `/reload` loads it; no file
was added). It went over the CurseForge app's install, which was 0.9.1, and took out the
`LICENSE.txt` the app's package carries; the app may offer its own version again. Nothing
of 0.9.3 or 0.9.4 has been reported seen yet. Two more asks for the live panel, on top of 0.9.3 below:

- "add a line below the skill bar, showing the number of skill gains for the running
  session". The line "Skill gains 3" sits under the bar; everything below it moved down 16
  and the panel is 16 taller (`HEIGHT` 178). Gains were not tracked before, so this is new
  data: `session.skillUps`, added by `Sessions.SkillGained`. `Skill.Check` (in `Skill.lua`)
  compares the trained skill with the last reading and gives a rise to the running session
  of this character. It runs on `CHAT_MSG_SKILL` and `SKILL_LINES_CHANGED` (Mastercraft,
  installed here, reads the skill on both; registered with `pcall` in case one is unknown),
  and again at each cast, tick and loading screen, so a rise no event told of is found at
  the next cast. The first reading after a login only sets the mark. Sessions from before
  0.9.4 have no `skillUps` and read as 0. Only the live panel shows it; the Session tab and
  History do not (not asked; the number is saved, so they could). `/kn demo` gives its
  sample sessions a point per dozen catches.
- "change auto on, to just a button called A, with a highlight when on and no highlight when
  off". The button is 18 wide (`LURE_TOGGLE`); `lureToggle.lit` is a texture in the accent
  colour (55 %) over the button, shown while lures are applied; the letter is white when
  on, grey when off; the tooltip says which and what a click does. The lure text is now 192
  wide, so the room problem of 0.9.3 is gone.
- **Not seen in the game:** that either event really fires on a skill point here (the
  cast-time check is the net if not), how the lit "A" looks in each theme (on the native
  theme the game's button may recolour the letter on hover), and the new spacing.

**0.9.3 (2026-11-24), the same day, also only tested offline.** The owner: "add the version number of keepnet to the live window, also add a
counter next to the lure somewhere, showing the number of the selected lure in a player's
bags". Both are in `UI\LivePanel.lua`:

- The version: `panel.version`, "v0.9.3" in the small dim font the window's title uses,
  right-aligned in the free corner beside the Value line (above the sound button). My choice
  of place; it costs no height.
- The count: the lure line reads "Lure  Bright Baubles x5  +75  9:42". It is the count of the
  lure the key will put on (the chosen one, or the strongest usable one on automatic), from
  `Lures.InBags()`, so it follows the bags. A worn item that puts a lure on (the hat) gets no
  count, and a chosen lure that has run out still says "none left".
- 0.9.3 narrowed the "Auto on" button to make room; 0.9.4 replaced it with the "A" button
  (above). **Not seen in the game:** how the version reads in its corner.

(Written before the upload of 0.9.7: see the top.)

**Planned on 2026-11-24, design choices settled 2026-11-25, and built that day as part of
1.0.0: telling the player in the game that a newer Keepnet exists.** The owner chose the
realm-wide way. What was built is at the top of this file; the research and the plan are
in "Update notice" further down.

**2026-11-24: CurseForge approved 0.8.5, and the owner had the listing brought up to date.
Keepnet 0.9.1 is on CurseForge (uploaded and approved that day), the description starts with
a feature list and covers everything up to 0.9.1, and the gallery holds 12 new pictures.
How all of that was done, and how to do it again, is in `PUBLISHING.md` ("Where it stands
(2026-11-24)" and "The listing's pictures and text").**

**Later on 2026-11-24: 0.9.2 was uploaded to CurseForge** (the owner: "upload 9.2"; third
file, "Processing" when last looked), **and the development copy was taken out of the
owner's game** so they can install the addon with the CurseForge app (`install.ps1
-Remove`; `KeepnetSounds\` and the saved data were left alone). Ask before running
`tools\install.ps1` again: it would put a development copy over the app's install. The next
upload's changelog starts after 0.9.2 (`release.py --since 0.9.2`). The paragraph below is
the state before that.

**0.9.2 (2026-11-24) is installed in the game, passes its offline tests and is not on
CurseForge.** Its one change: two of the sample sessions of `/kn demo` have opened catches
(the older Tanaris one: 21 clams and a chest, with pearls, cloth and coins; the running
one: 4 of 6 clams), so the Session tab has "from an opened catch" rows to show in pictures.
It goes up with the next batch (`release.py --upload --since 0.9.1`, or `--notes` for the
site's form), when the owner says so.

**Seen in the game on 2026-11-24, in the captures for the pictures** (sample sessions, so
this is the drawing and the screens, not real fishing): the rebuilt lists of 0.9.1 have a
solid background and can be read (food list and lure list both), the cog, the zone order of
0.9.0, a click on a session opening it with "Back to Zones" (0.8.9), the rows and coins of
opened catches on the Session tab (drawn from sample data), the history search, and the
interface hidden with the panel left. **Still not seen with real play:** an opened clam or
trunk being counted (0.8.8), and gear chosen per slot (0.8.6: the owner's bags held no
fishing gear, the gear list was empty).

New tools from that day: `tools\cut.ps1` (cuts the window or panel out of a capture),
`tools\description.py` (the text-only copy of the description), `capture-watch.ps1 -Full
-Ticks`, `release.py --since / --notes`.

**0.9.1 (2026-11-23): what follows is the state before the listing was updated.** Seen in
the game by then: the Zones tab of 0.8.7 (the owner: "the zones work well"), and the lists
on the live panel of 0.8.6, which came out see-through and were rebuilt in 0.9.1 (see below).

**0.9.1: the live panel's lists came out see-through in the game.** The owner, with 0.9.0:
"the drop down menus in the live tracking window for lures and gear and the rest are
transparent and you cannot see the menu options". Their settings at the time: theme Keepnet
(flat), panel background at 45 %, interface hidden while fishing; the error log named nothing
of ours. **The cause was not found.** Read on paper the old menu (a child of the live panel,
hidden itself, in the topmost layer, its labels anchored to the figures on their right)
should have drawn a solid background; the stand-in game has no drawing, so the tests could
not show it. What was done instead of a diagnosis: `W.Menu` is rebuilt the way the
drop-down's own list is built, which the owner has used without complaint (a frame of its
own under a click catcher that covers the screen, parented to the interface, or to the world
frame while the interface is hidden; never hidden itself), plus a plain filled texture as
its background, labels given a width instead of an anchor to another text, and rows
anchored by their two top corners. The click-elsewhere catcher replaces the
`GLOBAL_MOUSE_DOWN` listener, so a click outside the list is swallowed, as with the
drop-downs. It also opens upwards near the bottom of the screen now (it was clamped
before). **If it is still wrong, ask for a picture of it open before changing anything
else**: guessing twice is worse than looking once. A capture taken at the time
(`tools\capture.ps1`) showed the owner in combat with no panel up, so it told nothing.

**0.9.0: the zone list's order**, as the owner asked: "sort zones list in order of ascending
skill requirement, if the zones have zero sessions. if there are sessions in a zone, sort
them alphabetically". Fished zones first, A to Z (I kept them on top, which the owner did
not say either way); then the unfished by skill, lowest first, A to Z within a skill. The
table starts in that order (`sort = 0` in `W.Table`: no column) and a click on a heading
sorts by that column, with this order breaking ties; there is no way back to it short of
a reload.

**0.8.9: one click on a session shows all of it.** The owner, after trying the Zones tab:
"i additionally want to be able to click a specific session and see all of its details". A
click on a session in the Zones tab's list now opens it in the Session tab (it took a
double-click before, which the owner had not found), and the Session tab has a "Back to
Zones" button; a session opened from History gets "Back to History" (`SessionTab.View(id,
from)`). The Session tab's heading also says when a finished session ended. My choice, not
the owner's wording: the details are the Session tab, not a new panel inside the Zones tab;
if they want them beside the list instead, that is the thing to change.

**0.8.8 counts what comes out of opened catches.** The owner: "i want keepnet to count
trunks/chests and everything fished that gets opened as well ... like bloated fish, clams etc".
How it works is written at the top of the second half of `Fishing.lua`; in short:

- Opening an item from the bags gives an ordinary loot window (not fishing loot) whose source
  is the item (`GetLootSourceInfo`, a GUID starting "Item-"); the item's ID comes from
  `C_Item.GetItemIDByGUID` / `GetItemLinkByGUID`. If a session of this character caught that
  item and hasn't seen it opened, the slots taken (`LOOT_SLOT_CLEARED`) go to that session,
  and the catch is marked opened when it leaves the bags. Coins are the change in `GetMoney()`
  from the window opening to half a second after it closes.
- The data: `session.opened[itemID]` (what came out), `session.money` (coins),
  `session.items[id].opened` (how many of that catch were opened). `Prices.Rows` values a
  catch only for the ones not opened, and adds the contents and coins. The catch list on the
  live panel, the history search and the number of catches are untouched on purpose.
- It goes to the session that caught it, not the one running: the running one first if it
  holds one unopened, else the character's newest that does. A finished session's kept value
  moves by what the opening changes at today's prices (`Amend` in `Core.lua`).

Evidence that the game behaves this way, without a run of our own: Mastercraft (installed
here) counts fished chests exactly so; Open Sesame's list for this client has the trunks,
clams, bloated fish and the bottle answering with a loot window; warcraft.wiki.gg lists
`GetLootSourceInfo` and both GUID lookups for 1.60.1. **To check in the game:** open a fished
clam or trunk with the pole on and look for the panel's line "<item> opened: added to this
session", then the Session tab's rows.

Known limits, none of them seen yet:
- A container that hands over its contents without a loot window is not counted. Some do on
  the modern game; none of the classic ones fished here is known to.
- Catches opened before 0.8.8 still read as unopened, so a clam of the same kind from
  elsewhere, opened later, would be put down to an old session.
- When the game won't say which item a window is from, the catch that leaves the bags within
  2 seconds of the window closing is taken to be it; another item-loot window just before
  it could be mistaken for it.
- With the bags lagging and one kind of catch spread over two sessions, clams opened in a
  burst can all land in the newer session.
- Things worn are never "opened": disenchanting a fished ring is left alone. The owner, the same day: "we will only
send the update to curseforge once i have approval for the existing version". So no
`release.py --upload` until 0.8.5 is approved, and then only when the owner says so.

What 0.8.6 added, at the owner's request ("a settings button in the live tracking window ...
a cog icon", and the lure and gear lines "to allow you to switch out to whatever is
available ... so you don't have to go into settings"):

- A cog in the live panel's top right corner (`Interface\Buttons\UI-OptionsButton`, which
  ForeverXP, MapUtils and Forever Dungeon Journal use on this client). It opens the window on
  Settings; pressed again with Settings showing, it closes the window.
- The lure, food and gear lines are buttons (a small "v" at the right end). Each opens a list
  under it (`W.Menu` in `Widgets.lua`): automatic, every lure or food on the character, off.
  Food got a list too, though only the lure and gear were asked for: it is the same section.
- Gear per slot, which is new behaviour and not only a new screen: `settings.gearChoice[slot]`
  is an item ID (wear that one whatever its bonus), `false` (leave the slot alone) or absent
  (the best, as before). `Gear.Choose` acts at once, and after combat when in combat. A chosen
  item that is gone is ignored. Only the live panel sets it; the Gear & food tab still only
  lists what is on, and does not say that a slot has a choice.

To look at in the game: whether the cog reads as a cog at 14 px; that the list sits under the
line and stays on screen when the panel is near the bottom edge (it is clamped to the screen);
that a click elsewhere closes it (`GLOBAL_MOUSE_DOWN`, as EllesmereUI uses it here); that the
lists show while the interface is hidden (the list is a child of the panel for that reason);
and that a chosen hat really swaps at once.

Known limit: a newly chosen lure does not replace the one on the pole. The key only puts a
lure on a bare pole (replacing one makes the game ask for confirmation), so the choice takes
effect when the current lure runs out; the panel says so for a few seconds.

**0.8.7 (2026-11-23) rebuilt the Zones tab**, as the owner then spelled it out: "a list of
zones ... just name, required fishing skill, number of sessions. when you click on a zone, it
should list all the sessions from that zone, say going back 20 sessions. this listing should
have the stats of the session", and "prepopulate the zone list with all the existing zones
and their required fishing skill". So: the left table is every zone in `Waters.lua` (52 of
them; "Sunken Temple" is a second name for one and not listed) plus any fished zone that isn't in
it, fished ones first, the rest greyed A to Z; the right table is the clicked zone's newest
20 sessions with date, time, casts, catches, gold and per hour. The per-zone totals the tab
used to show (time, casts, catches, gold, per hour) are gone from the screen on purpose;
`Sessions.Zones` still adds them up. My additions, not asked for: the skill is coloured as
on the live panel, a row's tooltip gives the cast-from skill and the harder waters inside
the zone (they have no rows of their own: sessions are kept per zone), and the zones new to
this client have no number so they only appear once fished. Installed, offline tests pass
(`tests\test_zones_tab.lua`), not seen in the game; `media\screens\04-zones.png` is the old
tab. Not on CurseForge either (see above).

Still asked for later, not done: the store description should explain how the history is
searched, and now also describe this zone list. See "For the next description" in
`PUBLISHING.md`.

**Submitted to CurseForge on 2026-11-23: project 1825443, first file Keepnet 0.8.5, "Under
Review".** Details and what comes next are in "Where it stands" in `PUBLISHING.md`. The
submitted version is 0.8.5 (MIT licence, the project number in the TOC, `/kn demo` sample sessions under the
sample name "Vale", `tools\release.py` for the zip and for later uploads, `CHANGELOG.md` for
what players see). 0.8.2 ran in the
game on 2026-11-23: the window, all seven tabs, the live panel and `/kn demo` showed without
errors (that is where `media\screens` come from). Still not confirmed in the game: lures, food
and gear being applied, hiding the interface, the rare-catch alert, and every theme but Keepnet.

**0.6.0 (2026-11-23) is written and passes its offline tests. Versions 0.2.0 and 0.2.2 have run
in the game; nothing newer has been confirmed there.** 0.6.0 is the rename to Keepnet and the
net icon; nothing else changed in it. 0.6.1 added the theme presets Keepnet and Forever, and aux
as a price source. 0.8.1 grew the rarity list to eight kinds after the research
(coins, the newer bloated fish, more quest catches, chests split from trunks). 0.6.2 put the player's own sounds first in the sound lists (they were below
the fold of a list that didn't say it scrolled). 0.7.0 added the list of fishing rarities behind
the rare-catch alert. 0.8.0 rebuilt theming into three kinds of look (flat, the game's own,
handed to an interface suite), and gave the live panel a section for the lure, food and gear in
use and a sound switch.

### What the first run in the game shows (0.2.0, 2026-11-23, read from the saved data)

The owner fished with 0.2.0 for about three minutes in Desolace. The saved data and the error
log from that run show:

- The addon loaded, and the error log (BugGrabber) holds no entry that names it.
- A session was recorded: 13 casts, 6 catches, 7 without a catch, 167 seconds of fishing time.
- The catch was read correctly: 6 Firefin Snapper, with link, icon, quality and vendor price.
- It was priced from Auctionator: 96 copper for the six, 16 each (the vendor pays 5).
- The live panel was dragged and its position saved.
- The sound and interact settings were put back on exit: no backup was left in the saved data.
- A setting changed on the Gear & food tab (food set to Auto) was saved, so that tab works.

A later run the same day (0.6.x, after the rename) left this in the saved data: the addon loaded
under its new name with the carried-over session intact, the Appearance tab was used (the theme
was set to Plain black and hiding the interface to "everything"), and the error log again holds
no entry naming the addon. So the tabs, the theme switch between flat themes and the settings
written from them work in the game. Nothing from 0.7.0 on (the rarity list, the native and
suite themes, the in-use section, the sound button) has been confirmed there.

Not shown by either run: lures, food actually eaten, gear swapped, rare alerts. Seven casts without a catch out of thirteen is high: either fish got away
at that skill (Desolace asks 225 for none to get away) or misses are over-counted. Worth
watching against what the owner sees.

**After updating, restart the game fully.** Versions that add files (0.3.0, 0.4.0) change the
TOC, and a `/reload` in a game started before the update may load the new code against the old
file list.
0.5.1 added searching the history for a fish or item: the zones it was caught in, highest
share of the catch first. 0.5.0 added the choice of auction addon for prices (Settings, "Prices
from"). 0.4.1 moved the
whole-interface hide to the game's own switch.
0.4.0 added hiding the game's interface while fishing (everything except the live panel, or
chosen parts), borders on/off, more game sounds, and a sound plays as it is chosen.
0.3.0 added the Appearance tab (themes, accent, opacity, panel size) and the Alerts tab (a
sound per kind of rare catch, the player's own sound files).
0.2.1 added the catch list on the live panel (count and share per item). 0.2.2 added the skill
for guaranteed catches next to the zone ("Tanaris [300]").
0.2.0 added, at the owner's request the same day: fishing gear, food and other buff items, the
skill bar on the live panel, and rare-catch alerts.
The next step is the first in-game test below; expect to fix things after it.

### First in-game test (needs the owner)

The addon is copied into the game (`tools\install.ps1`, done 2026-11-23). It is new, so the game
needs a full restart (not `/reload`) to see it.

1. In the addon list: enable Keepnet, disable FishyWashy and Forever Fishing.
2. Equip the pole: the live panel appears; Options > Audio shows effects at 100 %, music and
   ambience at 0.
3. F applies a lure, F casts, F reels in. Repeat with the lure mode on Specific and on Off.
4. Unequip the pole: Options > Audio is back to your own values (effects were off, master 100 %).
5. Fish a few casts, change zone, cast again: History shows two sessions; sort by a few
   columns; pick a zone in the Zone list.
6. Compare one item's value with Auctionator's tooltip price times the count.
7. `/reload` in the middle of a session: the session carries on.
8. Gear (on by default): with a fishing hat, boots or enchanted gloves in the bags, equipping the
   pole puts them on and chat says which; unequipping the pole puts your own back.
9. The live panel's bar reads "Fishing <skill> / <cap>" and matches the profession window.
10. Gear & food tab: set Food to Auto with fishing food in the bags. The next press eats, the key
    does nothing for about ten seconds, then casts. It must not eat again while the buff is on.
11. Put the Shiny Silver Coin on the "other items" list: one press uses it, and not again until
    the buff runs out.
12. Catch something green or better: sound, screen line, chat line, panel highlight.
13. The live panel lists each catch with its count and percentage, and grows downwards as the
    list fills (it is held by its top-left corner).
14. The zone on the panel has its number in brackets, and the colour matches what happens:
    green and nothing gets away, yellow and some do.
15. Appearance tab: each theme repaints the window and the panel at once; the opacity sliders
    change only the backgrounds; the size slider resizes the panel.
16. Alerts tab: Test plays each sound. The game's sounds are chosen by number; one this client
    lacks says "didn't play" and the alert falls back to the raid warning.
17. Your own sounds: after a game restart they are in the lists (from `KeepnetSounds\Files.lua`)
    and Test plays them. "Keepnet sounds" must be enabled in the addon list.
18. Appearance, hide "Everything except the live panel": cast, and the whole interface goes while
    the panel stays where it was at the same size. F still reels in and the catch arrives in the
    bags. Move: everything is back. Then check each way back: Escape, combat, `/kn ui`.
20. Settings, "Prices from": the list marks addons that aren't installed; choosing one of those
    turns the session's values to vendor prices and the Session tab says why.
19. Hide "Only the parts I tick": the ticked parts vanish on a cast and return on moving. Pick
    another addon's bar with "Pick something on screen".

After that run, read from `D:\Games\World of Warcraft\_forever_\WTF\Account\<account>\SavedVariables\`:
`Keepnet.lua` (what was recorded) and `!BugGrabber.lua` (any Lua errors; BugGrabber and BugSack
are installed).

### What is verified, and how

| Part | State |
|---|---|
| Session rules, pricing rules, sorting, text | Tested offline (`tests\test_logic.lua`) |
| The addon's flow through a session: mode on/off, lure, cast, reel, miss, recast, combat, reload, zone change, break, crash recovery, every screen opened and clicked | Tested offline against the stand-in game (`test_session.lua`, `test_recovery.lua`) |
| Every game function and widget name used | Each one is used by another addon installed on this client (checked by search), so they exist; their behaviour here is not tested |
| Key binding, cast and reel-in in the real client | **Worked in the 0.2.0 run** (13 casts, 6 catches recorded). The lure macro wasn't exercised |
| Sound profile in the real client | Applied and put back without leaving a backup in the 0.2.0 run; how it sounded is the owner's to say |
| Loot events | **Worked in the 0.2.0 run.** The hidden-value guard wasn't exercised |
| How the screens look | Seen by the owner in the 0.2.0 run, who then asked for additions rather than fixes. Not seen by the author; positions were worked out by arithmetic |
| Gear swap, eating, buff items, toys, the skill reading, the alert sound in the real client | **Not tested.** Offline only (`test_gear_food.lua`) |
| Reel-in inside dungeons | **Unknown.** Forever Fishing's broke there |

### Watch for in the first run

- **Eating.** Keepnet takes a use as done when the game reports a spell, the item count drops
  or a new buff appears within 2 seconds. If none of the three happens on this client, it would
  eat a second time and then cast. Check `KeepnetDB.buffOf` afterwards: it should hold the
  food's buff.
- **The skill bonus on the bar** is what the game reports as the profession's modifier.
  FishyWashy treats that as the lure only; whether it also holds gear and food here isn't known.
- **Zone skill numbers** are the classic ones (cast from 95 below the number). Every guide and
  addon for this client repeats them, but nobody has published a measurement made here: if fish
  still get away on green, the table in `Waters.lua` is wrong for that water. Zones are matched
  by their English names; a zone that isn't in the table shows no number (the zones new to this
  client have none published). The colour uses trained skill plus the bonus the game reports.
  One forum post (2026-11-22) describes a character sheet showing 433 while the profession page
  said 300+93 and fish still got away at a 425 water: a displayed bonus may not count, so trust
  the catches over the colour.
- **Hiding everything** rests on four things the stand-in game can't prove: an addon may call
  `SetUIVisibility` out of combat; a frame under the world frame stays visible and keeps its
  place and size (the panel is scaled by the interface's scale over the world frame's to match);
  key bindings and the cast button keep working while it is hidden; and `LootSlot` picks up a
  fishing catch. Luredon ships the same approach on this client, which is the best evidence
  there is short of a run. If
  the panel jumps or changes size when the interface hides, the scale or anchor assumption is
  the one that is wrong.
- **Escape while hidden** needs the panel to listen to the keyboard while passing every key on.
  If keys stop reaching the game while the interface is hidden, that is the cause.
- **The Forever theme** (0.8.0) builds every piece from the game's templates:
  `BasicFrameTemplateWithInset` (window), `UIPanelButtonTemplate`, `UICheckButtonTemplate`,
  `OptionsSliderTemplate`, `InputBoxTemplate`, `WowStyle1DropdownTemplate` with the game's menu,
  `PanelTabButtonTemplate` (tabs hang under the window); table headers use the game's list
  header art and the live panel the tooltip frame art. All of these are used by other addons
  on this client, so they exist; how Keepnet's layout sits inside them has not been seen.
  Things to look at in the game: the tick boxes are 20 px in rows laid out for 16, the sliders
  are 17 px tall, the window's content starts 28 px higher than in the flat look, and the
  drop-downs are the game's width for the given size. Each piece falls back to the flat one if
  its template is missing.
- **The EllesmereUI theme** follows that suite's own guide for addons (`SKINNING_API.md` in its
  folder): Keepnet registers under its name, and EllesmereUI lists it under Blizzard Skins+ >
  Window Skins > Third-Party Addons, where it can be turned off. The suite has no primitive for
  sliders or table headers: sliders stay the game's, headers are Keepnet's flat ones.
- **The ElvUI theme** is written from ElvUI's Skins module (`HandleFrame`, `HandleButton`,
  `HandleCheckBox`, `HandleEditBox`, `HandleSliderFrame`, `HandleDropDownBox`, `HandleTab`,
  `HandleCloseButton`) and has never run against ElvUI. Every call is guarded.
- **What the price research found (2026-11-23):** Auctionator, Auctioneer (classic lineage;
  "Auctioneer (Forever)" exists), aux for this client (`AuxForeverAPI.GetLatestPrice` /
  `GetUsualPrice`, returning price and age in days) and Oribos Exchange were confirmed from
  their own source. TradeSkillMaster's calls are as three other addons use them; its own
  documentation could not be read. RECrystallize is Retail only. Auctionator's v1 API also has
  `RegisterForDBUpdate`, which would let the session re-price the moment a scan ends instead of
  on the 5 second timer; not used yet.
- **Auction addons other than Auctionator** are asked through their published calls, written
  from knowledge of those addons and not run against them: only Auctionator is installed here.
  TradeSkillMaster `TSM_API.GetCustomPriceValue("DBMarket" / "DBMinBuyout" / "DBRegionMarketAvg",
  "i:<id>")`, Auctioneer `AucAdvanced.API.GetMarketValue(link)`, RECrystallize
  `RECrystallize_PriceCheck(link)`, Oribos Exchange `OEMarketInfo(link, table)`. Each call is
  guarded, so a wrong one gives "no price" (vendor price) and never an error. Whether each of
  those addons has a build for this client isn't known.
- **The game's alert sounds** are picked by sound kit number (31578 loot toast, 888 level up,
  8959 raid warning, 8960 ready check, 878 quest complete, 5274 auction house, 120 coins, 416
  murloc). These come from the modern client; which of them this client has isn't known. Press
  Test on each.
- **Toys** are used through the secure "toy" action (a `/use item` macro doesn't fire a learned
  toy). Not known: whether this client has a toy box at all, and whether a toy can be dropped on
  the list from it.
- **A press while the lure is going on** does nothing, by design.
- **Camper's Lure (item 291005).** Its strength is read from its tooltip; the built-in fallback
  of 60 matches Wowhead's Forever data (+60 for 5 minutes).
- **The game's "act on key down" setting.** Handled for both values; the stand-in game tests
  both, the real client only has one of them set.

## Decisions

- **Rare catches come from a list, not from item quality.** The trophy fish, the quest fish and
  Message in a Bottle are ordinary white items and the named coins are grey, so quality never
  found them. `Rares.lua` lists them by item ID in eight kinds (trophy, gear, quest, tournament,
  bloated, chest, coin, trunk), each of which the player can turn off; trunks start off because
  wreckage and schools hand them out constantly (about 60 % of those pools' catches). The
  open-water chests and crates are 1 catch in 200 to 500 and start on.
- **What the rarity research found (2026-11-23), beyond the list itself:** this client renamed
  some classic items (13876 to 13880 are Yellowtail, not Grouper); Darkwood Fishing Pole does
  not exist here; the Shiny Silver Coin and Camper's Lure are not fished (a quest reward; looted
  from a placed Fishing Rack or Hut); Message in a Bottle opens for recipes and scrolls and
  starts no quest; under a Fishing Rack or Hut buff, bloated fish arrive as a second loot slot
  beside the ordinary fish (the alert already reads every slot); 32 Pound Salmon, Bloated
  Mackerel, Bloated Albacore and Pale Ghoulfish exist on the client but no source says where
  they are caught (the first three are listed, the Ghoulfish is not). Catch chances come from
  emulator tables and from players' logged catches, none from Blizzard. Every ID and name was checked against the public item data for this client. The
  quality and gold rules remain as extra triggers. A listed rarity is the one announced when a
  catch holds several things.

- **One price source at a time, chosen by the player.** "Automatic" is the first installed. A
  chosen addon that is missing means vendor prices and a visible note, never a silent switch to
  another addon: two addons can disagree a lot, and a total that changes source without saying
  so can't be trusted.
- **Finished sessions keep the value they had**, whatever the source was then. Changing the
  source re-prices the running session and anything shown at "today's prices".

- **0.4.1 after research:** the whole-interface hide uses `SetUIVisibility` (the game's own
  toggle; showing is reported to be allowed even in combat) instead of hiding the root frame,
  the panel goes under `WorldFrame` instead of having no parent (parentless frames had a
  rendering bug on some clients), more events bring the interface back, and the picker never
  offers a whole-screen container (interface suites keep everything in one).
- **"Hide everything" hides the interface root**, not a list of frames. A list always misses
  something (other addons, separate shadow frames, pieces that ignore their parent's alpha), and
  the installed interface suite parents its frames to the root, so the root takes them all.
- **"Parts" uses alpha 0, not Hide**: many of the game's frames are protected in combat and
  managed by its layout code, and alpha is the one thing that is always allowed and always
  restorable. The cost is that they stay clickable and that pieces outside the frame remain;
  the picker exists for those. Alpha is re-applied twice a second because the game fades some
  frames back in by itself.
- **Hidden is never a trap.** Every exit is automatic or one key away, the logout path brings
  the interface back, and nothing about "hidden" is saved, so a reload or crash starts visible.

- **Three kinds of look, one set of screens.** The screens only ever ask `Widgets.lua` for a
  panel, button, tick box, slider, text box, drop-down, tab or header. A flat theme gets
  Keepnet's own; a native theme (`native = true`) gets the same piece made from the game's
  template (`UI\Native.lua`), with the same fields and methods; a suite theme (`adopt =
  "<suite>"`) is a native theme whose pieces are then handed to that suite (`UI\Adopt.lua`).
  The owner's wording, 2026-11-23: Forever should "use only the forever elements, windows,
  buttons, borders and so forth"; Keepnet is the flat look as it was; and other people should
  "select whichever UI they have and have the addon skin itself based on that".
- **The look is fixed when the first frame is built.** Changing between kinds of look needs
  every frame rebuilt, so the choice is saved and the player is asked to reload. Themes of
  the same kind switch at once.
- **A suite is a theme the player picks**, not something detected. Each suite needs an adapter
  in `Adopt.lua` and a theme entry; a suite theme without the suite is the Forever look.
- **The lure button on the live panel** turns applying lures off, and back to whatever it was
  (automatic, or the chosen lure). **The sound button** is the same setting as "Fishing sound"
  in Settings.
- **Themes are all dark.** The text is the game's own light fonts; a light theme would need
  every font swapped. A theme is six colours; frames register when they are skinned and are
  repainted in place, so no reload is needed.
- **Opacity is the background only**, never the text, and separate for the panel and the window.
- **The player's own sounds live outside the addon folder** (`Interface\AddOns\KeepnetSounds`)
  so an update never deletes them, and are named either in the Alerts tab or by a `Files.lua`
  that `install.ps1` writes. File names are checked so a setting can never point outside that
  folder.
- **No sound files ship with the addon.** `sounds-local\` is git-ignored: clips people want for
  this are usually someone else's work and can't be redistributed.

- **Gear is found by tooltip, not by a list**, per item in the bags (not per item ID), so an
  enchant counts and items new to this client are found. Weapons are never touched.
- **What gear replaced is saved before the swap** (`KeepnetDB.gearSwap`), like the sound and
  interact settings. Gone Fishing's readme names the lack of this as its restore bug.
- **Defaults:** gear on (nothing is used up, and it is undone); food off and the item list
  empty (they use things up, so the owner turns them on).
- **Food and items are learned, not listed.** No table of buff spell IDs exists for this client.
  The first use of an item records which new Fishing buff appeared (`KeepnetDB.buffOf`).
- **The key waits while eating** (11 seconds from the confirmed use, or until the buff shows).
  No addon that was looked at protects a meal from the next cast.
- **Rare = the owner's choice of quality and/or gold each**, not a list of rare fish. Forever
  Fishing has such a list; it is its author's work and was not used.

- **Named Keepnet since 0.6.0.** It was built under the working name "Tacklebox", which turned
  out to be taken on CurseForge. The name is in the folder, the TOC, the saved variable
  (`KeepnetDB`), the slash commands (`/keepnet`, `/kn`), the frame names and the sounds folder
  (`KeepnetSounds`). The owner's saved data from the working name was carried over by copying
  the SavedVariables file with the variable renamed.
- **Fishing mode = pole equipped.** No Start/Stop button and no gear swapping (the owner chose
  lure handling only).
- **A session belongs to one zone** (owner's choice: a break or a new zone ends it), so History
  and Zones group cleanly. "A different zone starts a new session" can be turned off.
- **Sound profile for the whole time the pole is on**, not per cast: steady levels and no
  sound-system restart on every cast.
- **The player's own settings are saved to `KeepnetDB` before the first change** (sound and
  interact settings) and put back on pole off, logout, and the next login. The game only writes
  its settings file on a clean exit, so this is what makes a crash recoverable.
- **Prices:** finished sessions keep the value they had; "Today's prices" re-prices them.
  Auctionator has no "prices changed" message, so the running session is re-priced on a 5 second
  timer.
- **Fishing time** ignores gaps over 2 minutes between casts (Luredon uses 90 s; a cast here can
  take over 20 s, so 2 minutes leaves room for a lure and a short pause).
- **The game gets a copy, not a folder link.** A junction was the plan and was tried: on this
  Windows build a junction made without administrator rights is an "untrusted mount point", and
  PowerShell and Python refuse to read through it (error 448). Whether the game would is
  unknown, so `tools\install.ps1` mirrors the folder instead. **Run it after every edit.** The
  copy in the game is never edited by hand.
- **Tables are plain frames** (own sortable list, drop-down, tick box, slider): no dependence on
  game templates that differ between client versions.
- **Tests:** Lua 5.1 through Python `lupa` in `.venv` (no Lua is installed on this PC).

## Research (2026-11-23)

- Forever is the modern engine (API family of 12.x) with hidden "secret" values; comparing a
  hidden value is a Lua error. Out in the world the player's own casts and loot are not hidden;
  inside instances unit identity is. Source: warcraft.wiki.gg, Patch 1.60.1 API changes.
- `SoftTargetInteract*` settings are protected in combat; `Sound_*` are not.
- `MuteSoundFile` exists on Forever. Nobody has published the splash sound file IDs and no
  fishing addon uses it. **Idea for later:** mute everything on the effects channel except the
  bobber, which would close the "other effects are loud too" gap. Needs the file IDs first.
- Auctionator 352 (installed): `Auctionator.API.v1.GetAuctionPriceByItemLink/ByItemID`,
  `GetVendorPriceByItemID`, `GetAuctionAgeByItemID`; caller name first, throws on bad arguments,
  no update callback.
- Luredon (github.com/WoW-Forever-Addons/luredon, MIT, Forever-only) is the closest existing
  addon: one key, sound mode, live session value; no history or zone views in its readme. The
  owner had not tried it when this was started.
- Not confirmed anywhere: the auction house cut on Forever (5 % assumed), whether loot can be
  hidden out in the world.

## Research for 0.2.0 (2026-11-23)

- What exists on this client (Wowhead Forever tooltips, method.gg, Forever Fishing's guide):
  Lucky Fishing Hat 19972 (+5), Nat Pagle's Extreme Anglin' Boots 19969 (+5), Worn Fishing Hat
  7996 (+5), glove enchant +2 (spell 13620), High Test Eternium Fishing Line 19971 (+5, a
  permanent pole enchant, nothing to automate). Wide-Brimmed Fishing Hat 259846 (use: lure +25,
  10 min cooldown, must be worn). Shiny Silver Coin 286732 (+30 for 30 min, buff spell 1321323,
  stacks to 20). Camper's Lure 291005 (+60, 5 min), "Secret" Bait 268880 (+25). Foods, all
  15 min: 6316 +3, 5476 +5, 4593 +8, 4594 +12, 13930 +18, 8957 +18. Hook of the Master Angler
  19979 and Surfer Shoes 276274 help with water, not skill.
- `C_Item.EquipItemByName(link, slot)` is callable by addons out of combat on 1.60.1
  (warcraft.wiki.gg); in combat it picks the item up instead, so it is never called then.
  Fishing Buddy, Luredon and GearMenu ship gear swaps on modern clients.
- Player buffs are readable out of combat; `C_Secrets.ShouldAurasBeSecret()` says when not.
- Not confirmed: whether the coin is used up, whether a "Food" buff shows while eating, any
  minimum delay between gear swaps (Extreme FishingKit waits 1 s and retries; so does this).

## Update notice (planned 2026-11-24, built 2026-11-25 as part of 1.0.0)

**Built on 2026-11-25 as part of 1.0.0: `Keepnet\Updates.lua`, tested by
`tests\test_updates.lua`. What it does, what was chosen and what has not been seen in the
game are in the first entry under "RESUME HERE". What follows is the plan and the research
it was built from, kept as they were written.**

The owner: "keepnet needs a way to find it needs updating while ingame", and after the
research below: "realm wide would be the way, with curseforge when we do." So when this is
built, a copy hears about a newer version from any Keepnet user on the realm, not only from
its guild or group. My reading of the second half, not confirmed: it goes out in a
CurseForge upload, and the notice sends the player to CurseForge (the app or the site) for
the update. (Written on 2026-11-24, when nothing was built.)

### What the research found (2026-11-24)

- An addon cannot reach the internet, so it cannot ask CurseForge anything. Every addon that
  tells you it is out of date heard a higher version number from another player's copy.
- **The usual way** is the hidden addon-message channel to guild, party and raid
  (`C_ChatInfo.RegisterAddonMessagePrefix`, `SendAddonMessage`, `CHAT_MSG_ADDON`). On this
  client: Forever Dungeon Journal (`Systems\VersionCheck.lua`) and D4Lib inside MapUtils and
  MoveAny (`libs\D4Lib\D4Versions.lua`). Shared libraries do the same for several addons at
  once (VersionCheck, LibVersionCheck on CurseForge). It only reaches people you share a
  guild or group with, which is why the owner chose realm-wide: fishing is done alone and
  Keepnet has few users.
- **Realm-wide** means a chat channel of our own and addon messages of chat type `CHANNEL`
  with the channel's number. Mastercraft sends its whole network this way on this client
  (`Network.lua`), so it works on Forever. Classic Era disabled it in 1.13.3 (and added SAY
  and YELL instead); Questie's old `questiecom` channel is commented out in its source.
- **What Mastercraft's code shows a channel needs**, read from its source, not run by us:
  wait until the game's own channels (General, Trade) are in before joining, or ours takes a
  low number and theirs shift; take the channel off every chat window
  (`GetChatWindowChannels`, `RemoveChatWindowChannel`) so the player never sees it; look the
  number up by name before every send (`GetChannelName`), since it can change; send inside
  `pcall` and read the result code; keep to a slow rate (it uses a bucket of 3, one back
  every 1.25 s).
- **What Forever Dungeon Journal does that is worth doing too:** announces 8 s after login
  (the loading screen eats earlier lines); at most one send per 10 s per channel; a copy
  that hears an older version answers after a random 1 to 5 s and drops the answer if
  someone else got there first; accepts only a plain dotted number within small bounds, so a
  broken or hostile message cannot raise the notice; tells the player once per session, and
  again at login only while the newer version was heard in the last 3 days.
- **Limits on this client.** Addon messages are refused or dropped while the chat system is
  locked down (instances, encounters): check `C_ChatInfo.InChatMessagingLockdown()` and send
  inside `pcall` (the sources disagree on whether it fails silently or with an error). The
  text of an incoming message can be a hidden value in that state, and comparing a hidden
  value is a Lua error: check it before parsing. D4Lib stops listening in combat altogether.
- **What does not do the job:** the game's own "out of date" mark in the addon list only
  says the game's interface number moved on. No example was found of an addon that nags by
  its own age. The CurseForge app updates the files but tells the running game nothing.

### What to build

(The plan as written on 2026-11-24. It was built on 2026-11-25; the name is `KeepersNet`.)

1. A channel of Keepnet's own, joined after the game's channels, hidden from every chat
   window, left again when the feature is turned off. The name is not chosen.
2. Announce the version after login and then seldom; answer an older copy after a random
   wait, dropped when someone else answered. With a whole realm listening this rule matters
   more than it does in a guild.
3. Show it where a fishing player looks: a line on the live panel and in Settings ("0.9.4 is
   out, you have 0.9.2, update with the CurseForge app"), since chat is hidden when the
   interface is. Once per session, remembered for a few days.
4. Offline tests: the stand-in game needs the channel calls, the prefix, the send and
   `CHAT_MSG_ADDON`, the lockdown answer and a hidden text.
5. Credit Forever Dungeon Journal and Mastercraft for the patterns in `CREDITS.md` and at
   the point of use; write it fresh, copy nothing.

**Decided by the owner on 2026-11-25** (at 38 downloads: "i think it's time to start
thinking about an update announcement method"), answering four questions: build it only
after the owner has tried 1.0.0 in the game (said as "1.0.1", before the two were combined); on by default, with a switch in Settings that
turns it off and leaves the channel; and all three safeguards below are wanted (development
copies listen and never announce; guild, party and raid as well as the channel; a newer
version is believed only once two different players have announced it). The channel's
name: the owner proposed "keeper's net" the same day. A channel name is one word (a space
ends it: what follows is taken as the password), and the other addons' channels on this
client are plain words ("layer", "MapUtils"); whether an apostrophe is accepted was not
tried. So the form put back to the owner is `KeepersNet`; they did not object, and did not
say yes to the spelling in so many words. The owner also asked whether General could carry
it ("can this message not be sent through the general chat tab?") and, told why not (an
addon can't post there without a key press, General is one channel per zone, and hidden
messages to it are undocumented and untested here), decided: "let's stick to the custom
channel".

My additions, as they were put to the owner (the first, third and fourth are accepted, see
above; the second follows from the third):

- A switch in Settings, on by default. Joining a channel on a player's behalf uses one of
  their channel places, so they should be able to say no.
- Guild, party and raid as well as the channel: it costs nothing and still works when the
  channel cannot be joined.
- **Only versions that are on CurseForge may be announced.** Version numbers here run ahead
  of the uploads (0.9.2 was in the owner's game while 0.9.1 was the newest file on the
  site), so a development copy would tell the realm about a version nobody can get.
  `install.ps1` should mark its copy as a development build that listens and never
  announces. Forever Dungeon Journal's 3-day rule exists for the same trouble.
- Believe a newer version only when two different players have announced it, to make a
  forged message harder. Not checked against any addon's source.

Sources: warcraft.wiki.gg (`API_C_ChatInfo.SendAddonMessage`,
`API_C_ChatInfo.SendAddonMessageLogged`); curseforge.com/wow/addons/versioncheck and
/libversioncheck; curseforge.com/wow/addons/dim (the 12.0 lockdown); the Blizzard forum
thread "Classic Patch 1.13.3 LUA API Change" (eu.forums.blizzard.com/en/wow/t/111998); and
the three addons' own files named above, as installed on this client.

## Ideas, not started

- Everything caught in a zone, added up over its sessions. This was my first reading of the
  owner's "zone list" on 2026-11-23 and it was wrong: they wanted the zone's sessions, which
  0.8.7 built. The catch per zone was never asked for; listed here only as a possible extra.
- Wear the strongest fishing pole from the bags too (needs a way to start fishing mode that
  isn't "a pole is equipped").
- Count rare catches per session and show them in History.

- Mute non-fishing sound files (see above).
- Per-item exclude or manual price (Haul and FarmLog have it).
- Pause on AFK (Farmin' Forever has it).
- Catch rate per zone and "time since last rare" on the Zones tab.
- Mouse-over tooltip on History rows with the session's top items.
