# Keepnet

A fishing addon for World of Warcraft: Forever (client 1.60.1, interface 16001). A keepnet is
the net an angler keeps the catch in.

- **One key.** While a fishing pole is equipped, one key (F by default) casts when the line is
  in and reels in when it's out. One press does one thing.
- **Lures.** Off, Auto (the strongest lure in your bags that your skill allows) or Specific (one
  lure you choose). With no lure on the pole, the next press applies it and the press after casts.
- **Fishing gear.** While the pole is equipped, clothing in your bags that raises Fishing (a
  fishing hat, boots, gloves with a fishing enchant) is put on, and what it replaced is put back
  when the pole comes off. On by default.
- **Food and other buff items.** Fishing food (Off, Auto or Specific) and any other item you put
  on the list (a coin, a toy, a trinket) are used through the same key when their buff is
  missing, before the lure and the cast. Off until you turn them on.
- **Skill bar.** The live panel shows your Fishing skill as a bar with numbers: trained skill,
  the cap, the bonus on top and, in brackets, the two added up. Under it, the skill points gained in the running session.
- **What is in use.** The live panel names the lure the key applies, how many of it are left
  in your bags and its time left, with an "A" button that turns applying lures off and on
  (lit while they are applied); the food and whether you are fed; and the fishing gear that
  was put on. A second button switches the sound between "Splash only" and "Game audio".
  Keepnet's version is in small print beside the value.
- **Change it from the panel.** Click the lure, food or gear line and a list opens with
  everything you have for it: pick another lure or food, turn either off, or choose per slot
  which fishing gear to wear (the best, a piece you name, or leave the slot alone). Gear
  changes at once; a lure goes on when the one on the pole runs out. The cog in the panel's
  corner opens the settings.
- **Zone skill.** Next to the zone, the live panel shows in brackets the Fishing skill that
  water asks for before nothing gets away any more, such as "Tanaris [300]". Green: your skill
  (with lure, gear and food) is enough. Yellow: you can fish there but some fish will get away.
  Red: you can't cast there yet. Harder waters inside a zone, such as the Bay of Storms, show
  their own number.
- **Catch list.** The live panel lists what you caught this session, most first: each item's
  count and its share of everything caught. With more than eight different items the list
  scrolls with the mouse wheel. Can be turned off in Settings.
- **Sizing the live panel.** Drag the panel's bottom right corner: sideways for its width, up
  and down for how many catches show before the list scrolls (3 to 30). The panel still only
  takes the room of the catches there are. `/kn reset` puts it back.
- **Rare catches.** A sound, a line in the middle of the screen, a chat line and a highlight on
  the live panel for a rare catch. Rare means: on Keepnet's list of fishing rarities (every
  trophy fish, The 1 Ring and the fish weapons, Message in a Bottle and the quest catches, the
  tournament fish, bloated fish, the chests and crates of open water, the named coins, and
  trunks; you tick which kinds), or at least the item quality you chose, or worth at least the
  gold you chose. Green, blue, purple and worth-gold catches each have their own sound: one of the game's,
  one of your own files, or one another addon shares through LibSharedMedia.
- **Looks.** Chosen in the Appearance tab, each with the colours it comes in:
  - **Keepnet** (the default): Keepnet's own flat look, in seven colours. One of them,
    Matrix, writes everything in green on black; Glass has it too.
  - **Keepnet rounded**: the same with round corners.
  - **Glass**: round panes you can see the game through, with a rim of light and a soft
    shadow, in five colours. How dense the glass is, is yours to set (65% to begin with).
  - **Windows 95**, for fun: grey bevelled windows, a title bar, tick boxes and dark text,
    in that system's nineteen colour schemes. Drawn by Keepnet; nothing of Windows is in it.
  - **Forever**: built entirely from the game's own windows, buttons, tick boxes, sliders,
    drop-downs and tabs, so it looks like the rest of the game.
  - **EllesmereUI**: if that is the interface suite you use, Keepnet hands its pieces to it
    to paint like the rest of your interface, accent colour included.
  A look that is drawn another way reloads the interface (you are asked); colours switch at
  once. Keepnet's own three looks are written in the Overpass font; the game's own font and
  any font another installed addon shares can be chosen in its place. Also: an accent colour
  (the colours' own, your class colour or one you pick), how solid the backgrounds are,
  borders on or off, and the size of the live panel.
- **Hide the game's interface while fishing.** Either everything except the live panel, with
  nothing left behind, or only the parts you tick (action bars, unit frames, buffs, minimap,
  chat, quest tracker) plus anything you pick on screen with the mouse. Off by default.
- **Fishing sound.** While the pole is equipped: sound effects at full volume so the splash is
  loud; music, ambience and dialog off; sound keeps playing with the game in the background.
  Your own sound settings come back when the pole comes off.
- **Sessions.** A session starts with your first cast and ends after a break (30 minutes by
  default), when you fish another zone, or when you press New session. History lists them,
  sortable by any column and listable by zone.
- **Each character its own.** Sessions, the running session, History and Zones belong to the
  character you are playing. A list on the History and Zones tabs shows another of your
  characters instead, or all of them together, and the history search looks through the
  sessions on show; the live panel always follows the character you are playing. Everything you set is kept per character as well: every setting (the
  key, lure, food, gear, sound, alerts, appearance, hiding the interface, prices) and the
  live panel's place and size. A character Keepnet sees for the first time starts with a
  copy of the settings of the character you played last; after that, what you change on
  one character stays with it.
- **Zones.** Every zone whose Fishing skill is known, whether you have fished it or not, with
  the skill its water asks for (in the live panel's colours) and how many sessions you have
  there. The zones you have fished come first, A to Z; the others follow by the skill they
  ask for, lowest first, greyed until you fish them (click a heading to sort another way).
  Click a zone and its last 20 sessions are listed beside it, each with its time, casts,
  catches, gold and gold per hour. Point at a zone for the skill to cast there and any
  harder water inside it. Click a session to open it with all of its details (a
  button there takes you back), or double-click a zone for all of its
  sessions in History.
- **Where to catch it.** Type a fish or item name in History (part of a name is enough) and the
  list becomes the zones you caught it in, the zone where it made up the largest share of your
  catch first, with how many that was out of how many.
- **Live gold.** What the session's catch is worth, priced from the auction addon you choose
  (Auctionator, TradeSkillMaster, Auctioneer, aux, RECrystallize or Oribos Exchange), updated every
  few seconds, with gold per hour of fishing time.
- **Opened catches count.** Open a trunk, chest, clam or bloated fish you fished and what comes
  out, coins included, is added to the gold of the session that caught it, whether you open
  it at the water or days later in town. The Session tab lists those items as "from an opened
  catch"; the catch list and the search still show only what was on the hook. Only things
  Keepnet saw you fish count: a clam you bought does not.
- **New versions.** Keepnet tells you when a newer version is out: a chat line after logging
  in, a line on the live panel the first time the pole goes on, and a line on the Settings
  tab. An addon cannot reach the internet, so copies of Keepnet tell each other their
  version in hidden messages: on a chat channel of Keepnet's own (KeepersNet), which reaches
  every Keepnet player on the realm, and to your guild and your party or raid. Nothing shows
  in chat; the channel takes one of your channel places. A newer version is believed only
  once two different players have announced it. Turn it off in Settings ("Tell me when a
  newer Keepnet is out") and Keepnet leaves the channel, says nothing and hears nothing.

## Using it

| | |
|---|---|
| `/kn` or `/keepnet` | open the window (also in the addon menu on the minimap) |
| `/kn new` | end the session; a new one starts with the next cast |
| `/kn panel` | hide or show the live panel |
| `/kn reset` | put the live panel back in the middle, at the size it started with |
| `/kn ui` | hide the game's interface, or bring it back (once turned on in Appearance) |

Disable FishyWashy and Forever Fishing while you use it: they bind the same key and change the
same game settings. Keepnet warns in chat if either is enabled.

### How gold is counted

- The price from your auction addon; if it has none, or the item is grey or binds when picked
  up, the vendor price.
- Which addon: Settings, "Prices from". Automatic uses the first one installed, in this order:
  Auctionator, TradeSkillMaster (market value), Auctioneer, aux (latest price), RECrystallize,
  Oribos Exchange. TradeSkillMaster can be asked for its market value, lowest buyout or region
  average, and aux for its latest or its usual price. "Vendor prices only" ignores auction prices
  altogether. RECrystallize is a Retail addon and is listed for that client.
- If you choose an addon that isn't installed, every item counts at the vendor price and the
  screens say so: another addon is never used in its place without telling you.
- An item with neither is left out of the total and shown as "n without price".
- A running session is re-priced every 5 seconds. A finished session keeps the value it had when
  it ended; tick "Today's prices" in History to see old sessions at current prices.
- The auction house's 5 % cut is off by default (Settings).
- Gold per hour uses fishing time: a gap of more than 2 minutes between casts is a break and
  isn't counted. No per-hour figure in the first minute.

### What one key press does

The first of these that is needed, one per press: eat fishing food, use an item from the "other
items" list, apply the lure, cast. With the line out the key reels in. While you are eating
(about ten seconds) the key does nothing, because casting would interrupt the meal.

### Hiding the interface

Turn it on in `/kn`, Appearance tab. By default it hides when you cast and comes back when you
move; untick that to use only the panel's Hide UI button or `/kn ui`.

**Everything except the live panel** uses the game's own switch for the whole interface, the
one its "toggle interface" key calls, so no art, shadow or other addon's frame is left behind.
Name plates over characters go with it.
While it is hidden:

- the fishing key works as usual, and catches are picked up for you (the loot window can't be
  seen), including items that bind;
- a whisper and the game's red error lines ("Inventory is full") show on the live panel;
- it comes back by itself when combat starts, when you die, on Escape, when the pole comes off,
  and for anything that needs an answer: an invite, a trade, a summon, a resurrection, a loot
  roll, a ready check, a duel;
- the game's own toggle key brings it back too.

**Only the parts I tick** makes those parts see-through instead of removing them, because the
game forbids removing many of them in combat. They can still be clicked where they were. The
ticks find the game's own frames by name; for anything else, such as another addon's bars, use
"Pick something on screen": point at it, Up and Down choose a wider or narrower piece, Enter
adds it. This way can leave pieces behind that sit outside the frame they seem to belong to;
pick those as well, or use "everything".

### Your own sounds

1. Make the folder `Interface\AddOns\KeepnetSounds` in your game folder and put `.ogg` or
   `.mp3` files in it. It sits beside Keepnet, not inside it, so updating the addon never
   deletes your files.
2. Restart the game: it only sees new files at start-up.
3. In `/kn`, Alerts tab, type each file's name and press Add. It then appears in the sound
   lists, with a Test button.

If you install from this project with `tools\install.ps1`, put the files in `sounds-local\`
instead: the script copies them to that folder and writes the list for you, so step 3 isn't
needed. `sounds-local\` is never committed.

### Things to know

- Fishing gear is found by reading each item's tooltip ("Equip: Increased Fishing +5.",
  "Fishing +2"), so enchants count. The pole itself is never swapped: equipping it is what turns
  fishing mode on. A slot you change by hand while fishing is left alone afterwards. If a slot
  was empty before, the fishing item stays on.
- Clothing can't be changed in combat. If the pole comes off in combat, your own gear goes back
  on when combat ends.
- A lure hat (Wide-Brimmed Fishing Hat) only works while worn. The gear option wears it when no
  item with a standing Fishing bonus wants the head slot; worn, it is used like any other lure.
- Keepnet learns which buff an item gives the first time it uses it, and after that uses the
  item only when that buff is missing. Until then it goes by a Fishing buff of the same strength,
  or by the time since it last used the item.
- An item that can't be used (or a lure that won't go on) is tried twice, then the key casts
  anyway.

- The splash is an ordinary sound effect. Game settings can't separate it from spells, creatures
  or other anglers' bobbers, so those are loud too.
- If you change your sound options by hand while the pole is on, they are put back to what they
  were before when the pole comes off.
- In combat the key goes back to whatever it normally does, and returns when combat ends (the
  game doesn't allow key changes in combat).
- Lures are recognised from their tooltip ("Use: When applied to your fishing pole ..."), which
  is English wording; on another language only the built-in list of known lures is found.

## Files

```
Keepnet\            the addon (this folder is copied into the game)
  Keepnet.toc
  Util.lua            shared helpers, messages between files
  Sessions.lua        sessions (pure logic)
  Prices.lua          what a catch is worth (pure logic)
  Waters.lua          the Fishing skill each zone asks for (pure data)
  Rares.lua           the list of rare fishing catches (pure data)
  Core.lua            saved data, game events, fishing mode, slash commands
  Fishing.lua         sees casts and catches
  Lures.lua           lures
  Buffs.lua           fishing food and other buff items
  Gear.lua            fishing gear on with the pole, off with it
  Skill.lua           the Fishing skill
  Alerts.lua          rare catches
  HideUI.lua          hiding the game's interface while fishing
  Sound.lua           the fishing sound profile
  OneKey.lua          the one key
  Updates.lua         hearing from other players' copies that a newer Keepnet is out
  UI\                 live panel, window, the seven tabs; Widgets.lua (the flat building blocks
                      and the themes), Native.lua (the same blocks from the game's own
                      templates), Adopt.lua (handing them to an interface suite)
sounds-local\         your own alert sounds (not committed; copied by install.ps1)
tools\install.ps1     copies the addon into the game, marked as a development build (it
                      hears of newer versions and never announces its own)
tools\release.py      builds the zip for CurseForge; --upload sends it, --notes prints its changelog
tools\capture.ps1, capture-watch.ps1, cut.ps1
                      pictures of the game window, and the window or panel cut out of them
tools\description.py  the text-only copy of the CurseForge description
media\                the logo, the pictures on the listing, the description as it is on the site
tests\                runs the addon outside the game
CREDITS.md            whose methods it learned from
PUBLISHING.md         the CurseForge listing: what is there, and how to update it
DEVLOG.md             state of the work, what is verified, what is next
```

Saved data: `WTF\Account\<account>\SavedVariables\Keepnet.lua` (`KeepnetDB`), one for the
whole account. Each session is filed under its character's key (`session.char`, the
character's GUID), `KeepnetDB.current` holds each character's running session, and
`KeepnetDB.chars` holds what is kept per character (its name, the gear swapped, the gear
chosen per slot). `KeepnetDB.settings`, `KeepnetDB.panel` and `KeepnetDB.panelSize` are
those of the character named in `KeepnetDB.owner`, the one played last; every other
character's are parked in `KeepnetDB.chars[key].kit` and swapped in when that character
logs in. Shared by the whole account: the sessions store itself, what Keepnet has learned
about which buff an item gives (`buffOf`), the backups of the game's own sound and
interact settings that put them back after a crash (`soundBackup`, `interactBackup`), and
which newer versions other players' copies have announced (`KeepnetDB.updates.heard`: the
player, the version and when, forgotten after a week).

## Install

```
powershell -ExecutionPolicy Bypass -File tools\install.ps1
```

copies this project's `Keepnet` folder to the game's `Interface\AddOns\Keepnet`. Run it after
every edit, then `/reload`. A new addon needs one full restart of the game to be seen. `-Remove`
takes the copy out. Another install path: `-AddOns "<path>"`.

It is a copy, not a folder link: on this Windows build a link made without administrator rights
is an "untrusted mount point" that some programs refuse to read through.

## Tests

```
py -m venv .venv
.venv\Scripts\pip install lupa
.venv\Scripts\python tests\run_tests.py
```

`tests\wowstub.lua` is a stand-in for the game (frames, events, timers, settings, bindings, bags,
loot, a fake Auctionator). The runner loads the addon into Lua 5.1 exactly as the TOC lists it
and runs:

- `test_logic.lua`: session rules, pricing rules, sorting, text.
- `test_session.lua`: a whole fishing session: pole on, lure, cast, reel in, a miss, a recast,
  combat with the line out, a `/reload`, a hidden catch, another zone, a break, a chosen lure
  running out, every screen opened and everything on it clicked, pole off.
- `test_recovery.lua`: the game crashed while fishing; the next login puts the settings back.
- `test_hide_ui.lua`: hiding everything and every way it comes back (moving, combat, Escape,
  dialogs, the game's own key, the pole coming off), loot picked up while hidden, hiding parts,
  picking a frame with the mouse.
- `test_native.lua`: the Forever theme: every piece comes from the game's templates, the
  game's own drop-down menu and tabs work, a missing template falls back to the flat piece.
- `test_adopt.lua`: the interface suite look, against a stand-in for EllesmereUI's skinning
  interface.
- `test_looks.lua`: the looks Keepnet draws itself besides its flat one: Windows 95, Keepnet
  rounded and Glass.
- `test_gear_key.lua`: the gear key: pole and clothing on, weapons and clothing back, combat,
  a pole put on by hand, no pole, the two keys kept apart.
- `test_line_strip.lua`: the strip under the live panel: the line's time running down, what
  each cast brought up, and when it shows.
- `test_vendor.lua`: buying lures from a vendor: the number, the ticked lures, the Attractor's
  own rule, too little money, things not sold for coins.
- `test_look_sounds.lua`: looks, colours, font, accent, opacity and size; a sound per kind of rare catch;
  your own files (and names that try to leave the sounds folder); shared sounds.
- `test_gear_food.lua`: gear on and off with the pole (also through a reload and combat), eating
  and waiting, a coin, a toy, an item that can't be used, a worn lure hat, rare-catch alerts.

It also fails on a file missing from the TOC, a Lua syntax error, an accidental global variable,
or a misspelt widget method. A pass shows the addon's own logic holds together against a model of
the game. It does not show that the real client agrees with the model: see DEVLOG.md for what
has been checked in the game.
