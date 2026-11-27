# Finding fishing pools without Find Fish

Research note, 2026-11-27. Nothing here has been run in the game by us yet; the checks at the end
are what settles the open parts. Marks: **[V]** verified against a primary source (the game's
documented API, an addon's source code, or a published in-game probe report), **[E]** inference,
**[U]** unverified.

## Key findings

1. **The game gives an addon no list of nearby game objects and no minimap blip positions.**
   Pools are drawn on the minimap by the engine; an addon cannot read where a pool is. The only live
   signals are: the name in the tooltip when the mouse is over a pool, the one object the soft
   interact target picks (and that has never been a pool in published tests), and the source GUID of
   a loot window. [V for the API surface; see "Hard limits"]
2. **The mouseover tooltip is the one signal known to work on this client.** A published probe on
   the Forever beta (build 1.60.1.70338) saw "Oily Blackmouth School" as line 1 of the game tooltip,
   with tooltip data type 4 (Object) and **no object ID** (`data.id` nil). GatherMate2 records pools
   the same way: the tooltip's first line while Fishing is being cast. [V]
3. **Soft targeting did not pick a pool.** In that probe, with `SoftTargetInteract` 3, range 60 and
   arc 2, `PLAYER_SOFT_INTERACT_CHANGED` named the bobber, a mailbox, a food crate and NPCs, but never
   the pool that was hovered five times. Fishing pools are not interactable objects, so this is
   expected. [V for that probe; one run only]
4. **The loot source of a pool catch is not settled.** In the same probe all 15 fishing windows
   gave `GetLootSourceInfo` the bobber (`GameObject-…-35591-…`), including two catches right after
   hovering the school; whether those bobbers were in the pool is not recorded. Server emulators send
   pool loot under the pool's own GUID, and at least one addon for this client is written expecting
   that. Check 3 below decides it. [U]
5. **Pools have fixed spawn points.** Each pool type has a set of points per zone, of which only a few
   are up at once; a fished-out pool respawns at another point of the set. Published Forever data
   exists (Wowhead's Forever object pages; pfQuest and Questie Forever object spawns; an AzerothCore
   based set in one Forever addon), so a map of known points plus a route works without Find Fish.
   [V that the data and addons exist; E for how exact Forever's points are]
6. **Find Fish does exist on Forever** (spell 43308 is in Wowhead's Forever database, and several
   Forever guides say it is new there and shows pools on the minimap), **but no public source says
   what teaches it on Forever.** On Classic Era it does not exist at all: the Weather-Beaten Journal
   that teaches it was added in patch 2.3.0. [V spell exists; U what teaches it here]
7. **An addon cannot switch on tracking the character has not learned.** The minimap's tracking list
   only holds the character's own tracking types. [V for the API shape, E that Forever behaves like
   the modern game]

## What World of Warcraft: Forever is, for an addon

- A Blizzard game type ("forever", internally "camelot", `WOW_PROJECT_ID` 18) in the **Mainline
  code family**, sharing Midnight's interface code. Client 1.60.1, interface 16001, expansion level
  0, level cap 60. Classic content on a modern engine. [V: warcraft.wiki.gg Patch 1.60.1 API changes;
  the probe report's `GetBuildInfo` and `WOW_PROJECT_*` rows]
- **Not** a Classic Era 1.15.x client: modern APIs are present (`C_TooltipInfo`,
  `TooltipDataProcessor`, soft targeting, `C_Minimap.GetTrackingInfo` returning a table,
  `issecretvalue`). [V]
- Midnight's "secret value" rules are active: inside instances and in combat many unit values read as
  secret. Out in the world, fishing loot and tooltips were not secret in the probe. [V]
- **GUIDs of game objects are partly obfuscated since Beta 5 (2026-10-16):** "The server ID and spawn
  ID portions of creature, vehicle, pet and game object GUIDs have been replaced with obfuscated
  values to prevent comparison to determine layer. They remain stable and unique within your own
  session." The entry ID (the object's type number) is still readable. So a GUID tells *what kind* of
  pool, never *which spawn point* across sessions. [V]

## What works and what does not, signal by signal

| Signal | On this client | Gives | Mark |
|---|---|---|---|
| Mouse over a pool: `GameTooltip` line 1, or `TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Object, …)`, or `C_TooltipInfo.GetWorldCursor()` | Works (probe saw the school's name; the post-call hook for type Object fired) | The pool's **name** only, localised; `data.id` was nil | V |
| `UnitExists/UnitName/UnitGUID("softinteract")`, `PLAYER_SOFT_INTERACT_CHANGED` | Works for interactable objects: the bobber (entry 35591), mailboxes, crates, herbs, ore. The GUID carries the entry ID (`GameObject-0-…-<entry>-<spawn>`) | Not a pool in the one published test | V (objects), U (pools never) |
| `GetLootSourceInfo(slot)` at `LOOT_READY` with `IsFishingLoot()` | Works, never secret out in the world (15 of 15) | Bobber 35591 seen; a pool's GUID not yet seen | V / U |
| `UnitIsGameObject("softinteract")`, game-object nameplates (`SoftTargetIconGameObject`) | Exist and are used by Forever addons | Only the soft target, so no pools | V |
| `C_Minimap.GetNumTrackingTypes`, `C_Minimap.GetTrackingInfo(i)`, `C_Minimap.SetTracking(i, on)` | Exist (Mainline API); the list is the character's own tracking. The wiki marks `GetTrackingInfo` "AllowedWhenUntainted" under the secret-values rules | Whether Find Fish is known and on; cannot add it | V shape, U behaviour here |
| Minimap blips, or any object's world position | No API | Nothing. Hovering the minimap shows a tooltip with the names under the cursor, but no positions | V (no such API) |
| Vignettes (`C_VignetteInfo`) | Exist | Rares and treasures, not pools | E |
| The bobber's world position | No API | Only the player's position and facing (`C_Map.GetPlayerMapPosition`, `GetPlayerFacing`) | V |

**Hard limits:** no scan of nearby objects, no reading of the minimap's blips, no object
coordinates, no ID in an object tooltip, no persistent spawn identity in GUIDs. A pool's place can
only be estimated as "where the player stood and faced when the pool's name showed or a catch came
from it".

## How existing addons do it

| Addon | Client | Pool locations from | Live detection | Licence |
|---|---|---|---|---|
| GatherMate2 (1.52.5 or later for Forever; TOC lists 16001) | Forever and retail | What the player gathers; GatherMate2_Data 42.0 is tagged for Forever (whether it has fish nodes is not said) | Tooltip line 1 while Fishing is cast (`UNIT_SPELLCAST_SENT`, `CURSOR_CHANGED`, `UNIT_SPELLCAST_STOP`), matched to a list of English pool names; position = player plus 15 yards ahead. Its fishing pins can be shown "only while tracking" Find Fish (spell 43308) | TOC says ARR, `LICENSE.txt` is GPL-2 |
| GatherLite (Forever build) | Forever | Wowhead's Forever object pages (a generator script); five fishing object kinds | Gathering casts plus `LOOT_OPENED`; nothing pool-specific | MIT (route terrain GPL-3) |
| Forever Nodes | Forever | GatherLite's data (MIT) | Adds spots the player gathers | MIT |
| Hooked - Fishing Helper & Journal | Forever (1.60.1) | About 400 pool spots in 17 zones, "from the AzerothCore world database, placed on the map with QuestieDB's coordinates" | "Hover a pool so its name shows and catch something in it": tooltip plus catch; dot placed from where the bobber landed, refined over time | All Rights Reserved |
| Polestar (guide addon) | Forever | pfQuest and Questie Forever object spawns | Takes a fishing loot source that is a game object other than the bobber 35591 as the pool | see its repository |
| PoolPing | Retail (Midnight) only | Its own list of pool object IDs | "world cursor, minimap mouseover, tooltips, soft interact, new Find Fish blips, periodic scan for known pool object IDs"; it says there is no "fly over and ping everything" with today's API | ARR |
| Fishing Buddy / Routes | Retail and Classic lineages | Fishing Buddy keeps no pool map; Routes draws routes over GatherMate2's nodes | not checked on Forever | |

No addon was found that reads pools from the minimap or from a world scan on Forever.

## Do pools have fixed spawn points?

Yes in Classic and its emulators: each pool type has a group of spawn points per zone with a cap on
how many are up at once, and a pool that is fished out despawns and comes back at another point of
the group. [E: emulator pool tables; consistent with every Forever guide and addon above] For Forever:

- Wowhead's Forever object pages carry spawn coordinates for the pool objects (GatherLite's export
  has, for example, 31 points for one pool kind in Darkshore). [V]
- Forever added pools and changed some: School of Whimsyfin (object 572928) is new, with comments of
  about 10 spawn points and 2 up at a time east of Lake Everstill. [U, from player comments]
- One guide says the number of active pools per subzone is limited. [U]

So a database of points is a good map of *where to look*, never a promise that a pool is up.

## A pool finder for Keepnet, within the rules

Everything below only reads and shows; nothing casts, moves, targets or clicks for the player.

1. **Seeing a pool (works today).** Hook `TooltipDataProcessor.AddTooltipPostCall` for
   `Enum.TooltipDataType.Object` (fall back to `GameTooltip` `OnShow` and line 1). If line 1 is a known
   pool name for the client's locale, note name, map (`C_Map.GetBestMapForUnit("player")`), player
   position and facing, and the time. Optional: a short sound and a line in the live panel ("Oily
   Blackmouth School under the cursor"). Skip secret values with `issecretvalue`.
2. **A catch from a pool.** At `LOOT_READY` with `IsFishingLoot()`, read `GetLootSourceInfo` for each
   slot. If check 3 shows that a pool catch names the pool (entry ID not 35591), that is the proof and
   the entry ID gives the pool kind. If it always names the bobber, use: a pool name hovered within
   the last 30 seconds in the same place, or a pool-only catch (Speckled Tastyfish, the Extravaganza
   fish, Bloated Whitescale Salmon and the like).
3. **Spawn points from Keepnet's own catches.** Estimated point = player position plus about 15 to 20
   yards along the facing. Merge estimates of the same kind within about 20 yards into one point and
   keep a count, which makes it more exact. Key points by map, pool kind and position, never by the
   GUID's spawn part (obfuscated and only stable for a session). Shared by all characters.
4. **Showing them.** World-map and minimap pins (Keepnet bundles no map library today; HereBeDragons
   is what GatherMate2 and GatherLite use), a list per zone in the Zones tab, and a simple route:
   nearest point next, through the zone's known points.
5. **Imported data, optional.** Two clean ways: (a) at run time, read the nodes of an installed
   gathering addon through its own API or saved data, bundling nothing; (b) bundle a points file
   built from a source whose licence allows it, with credit in `CREDITS.md`. Licences: pfQuest MIT,
   GatherLite MIT (its Wowhead-derived data), Questie mixed and moving to GPL-3, AzerothCore GPL-2,
   CMaNGOS classic-db GPL-3, VMaNGOS GPL-2, Hooked and PoolPing all rights reserved (do not use).
   GPL data inside the MIT-licensed addon would need a separate, GPL-licensed data file or a
   licence change. Wowhead's own terms on reuse of its database were not checked. [U]
6. **If the character knows Find Fish.** Show whether it is on (`C_Minimap.GetTrackingInfo`) and offer
   a button that turns it on; never switch it on unasked.

**Policy.** Blizzard's UI Add-On Development Policy asks for free, readable code that does not harm
realms or other players. The game enforces the rest through protected functions: casting, targeting
and moving need a hardware event and secure templates, which this feature does not use.
`SoftTarget*` settings are protected in combat. Reading tooltips, loot sources and the player's own
position is ordinary addon work out in the world. Nothing here automates fishing.

## Checks the owner can paste (no addon needed)

Each is one line for the chat box.

1. **Soft interact at a pool.** Line not in the water (or the bobber is the target), standing at a
   pool and facing it:

   ```
   /run local u="softinteract" print(GetCVar("SoftTargetInteract"),GetCVar("SoftTargetInteractRange"),UnitExists(u),UnitName(u),UnitGUID(u))
   ```

   The first number is 0 when soft targeting is off; then this check says nothing. Keepnet raises it
   only while the line is out. A `GameObject-…` GUID with the pool's name would mean pools can be
   soft targets after all.

2. **What the tooltip says.** Type the line, then put the mouse over the pool and press Enter:

   ```
   /run local d=C_TooltipInfo and C_TooltipInfo.GetWorldCursor() print(GameTooltipTextLeft1:GetText(),d and d.type,d and d.id,d and d.guid)
   ```

   Expected: the pool's name, 4, nil, nil. A number or a GUID would give the pool kind directly.

3. **Where a pool catch comes from (the important one).** Run it, then cast into the middle of a
   pool and catch something. It prints once and switches itself off; works with auto loot on:

   ```
   /run local f=CreateFrame("Frame") f:RegisterEvent("LOOT_READY") f:SetScript("OnEvent",function(s) for i=1,GetNumLootItems() do print(i,GetLootSourceInfo(i)) end s:UnregisterAllEvents() end) print("armed")
   ```

   A GUID whose fifth number is 35591 is the bobber; any other `GameObject-…` number is the pool's
   entry ID. Run it once in open water too, to compare.

4. **Find Fish and the tracking list.**

   ```
   /run print("Find Fish known:",IsPlayerSpell(43308)) for i=1,C_Minimap.GetNumTrackingTypes() do local t=C_Minimap.GetTrackingInfo(i) if t then print(i,t.name,t.type,t.spellID,t.active) end end
   ```

## Sources

- warcraft.wiki.gg, [Patch 1.60.1/API changes](https://warcraft.wiki.gg/wiki/Patch_1.60.1/API_changes):
  Mainline code family, Midnight's secrets active, the Beta 5 GUID obfuscation note.
- warcraft.wiki.gg, [UnitId](https://warcraft.wiki.gg/wiki/UnitId) (soft target tokens, added in
  10.0.0; `softinteract` "may be ... a game object like a mailbox or a gathering node"),
  [GetLootSourceInfo](https://warcraft.wiki.gg/wiki/API_GetLootSourceInfo),
  [C_Minimap.GetTrackingInfo](https://warcraft.wiki.gg/wiki/API_C_Minimap.GetTrackingInfo),
  [Weather-Beaten Journal](https://warcraft.wiki.gg/wiki/Weather-Beaten_Journal) (added in 2.3.0).
- Pagle's published probe on the Forever beta, build 70338, 2026-10-11:
  [results/2026-10-11-build70338-report.md](https://github.com/timemir/pagle-addon/blob/main/probes/fishing-signals/results/2026-10-11-build70338-report.md)
  (sections 4 and 7: loot sources, object tooltips, soft targets, CVars). Its
  [forever-content-data.md](https://github.com/timemir/pagle-addon/blob/main/docs/research/forever-content-data.md)
  lists the 14 pool types and School of Whimsyfin.
- [GatherMate2](https://github.com/Nevcairiel/GatherMate2) source, `Collector.lua` and `Constants.lua`
  (commit of 2026-11-14); [GatherMate2 on Forever](https://wowforeveraddons.com/articles/gathermate2-wow-forever).
- [GatherLite](https://github.com/wuild/gatherlite) source (`scripts/methods.lua`, `scripts/nodes.lua`,
  `tools/update_forever_wowhead.py`, `tools/wowhead/forever.json`);
  [Forever Nodes](https://www.curseforge.com/wow/addons/forever-nodes).
- [Hooked - Fishing Helper & Journal](https://www.curseforge.com/wow/addons/hooked-forever) listing
  (2.9.17, 2026-11-26).
- Polestar source, [`Polestar_Recorder/Finds.lua`](https://github.com/fitzforge/polestar) and
  `Polestar/Core/Gather.lua`, `GatherData.lua`.
- Lueur (a Forever addon, in [wow-forever-addons](https://github.com/anhys/wow-forever-addons)) and
  NodeSight: soft-interact GUIDs read as `GameObject-…-<entry>`, bobber entry 35591,
  `C_TooltipInfo.GetWorldCursor`.
- [PoolPing](https://www.curseforge.com/wow/addons/poolping) listing (retail).
- AzerothCore `GameObject.cpp` (`LookupFishingHoleAround`, `SendLoot(GetGUID(), LOOT_FISHINGHOLE)`):
  how emulators hand out pool loot. Emulator behaviour, not Blizzard's.
- Wowhead, [Find Fish on Forever](https://www.wowhead.com/forever/spell=43308/find-fish) (no "taught
  by"); [classicwowforever.com](https://classicwowforever.com/professions/fishing/),
  [foreverwow.com](https://foreverwow.com/professions/fishing/) and
  [wowforeverinfo.com](https://wowforeverinfo.com/guides/fishing/) fishing guides ("new in Forever").
- Blizzard, [UI Add-On Development Policy](https://us.forums.blizzard.com/en/wow/t/ui-add-on-development-policy/24534).
