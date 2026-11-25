# Changes

What changed for players, newest first. The section for a version becomes the changelog of
its file on CurseForge (`tools\release.py --upload`).

## 1.0.3

- With the game's interface hidden you could not see how long the line had left, or what it
  brought up. Now a small strip hangs under the live panel while a line is out: a bar that
  runs down, with the seconds the line has left, and under it what the cast brought up,
  for a few seconds (or "Nothing on the line").
- It shows while Keepnet has the interface hidden, when the game's own cast bar and loot
  window can't be seen. Settings, "Live panel", "Line timer and catch" changes that to
  always or never.

## 1.0.2

- New colours, Matrix, for the Keepnet, Keepnet rounded and Glass looks: black, with green
  borders and everything written in the green of the falling code. White text is the full
  green, dim text a darker green and headings the palest, almost white. Red stays red, so a
  warning still reads as one. Pick it in the "Colours" list on the Appearance tab.

## 1.0.1

Looks. Keepnet can be dressed several ways now, each in colours of its own, and it has a
font of its own.

- The Appearance tab has two lists where it had one list of themes: "Look", and "Colours"
  for the colours that look comes in. A colour theme you had chosen carries over as the
  Keepnet look in those colours.
- New look, Keepnet rounded: the Keepnet look with round corners, in the same six colours.
- New look, Glass: round panes you can see the game through, with a rim of light and a soft
  shadow. Five colours: Smoked, Deep water, Midnight, Moss, Amber. The glass is 65% dense to
  begin with; in this look the two "Backgrounds" sliders set how dense it is, for the live
  panel and for the window, and what you set there is kept apart from the other looks.
- New look, for fun, Windows 95: grey bevelled windows with a title bar, tabs, tick boxes
  and dark text, in the nineteen colour schemes of that system under their own names
  (Windows Standard, Rainy Day, Desert, Rose, High Contrast Black and the rest). It is
  drawn by Keepnet; nothing of Windows is in it.
- A font for Keepnet's own looks (Keepnet, Keepnet rounded and Glass): Overpass, which is
  the default from now on. The new "Font" list on the Appearance tab also has the game's
  own font, as it was until now, and every font that another addon you have installed
  shares (interface suites and font packs do). Overpass is used for the western languages
  and Russian; the other languages keep the game's font.
- A look that is drawn another way asks to reload the interface. Colours and fonts change
  at once.
- The ElvUI look is gone. Without that suite it was the Forever look, and that is what it
  becomes if you had it chosen.

## 1.0.0

Two things. Every character is its own: until now an account's characters shared one running
session, one history and one set of settings, and on this client two characters with the
same first name were taken for the same character. And Keepnet can now tell you when a
newer version is out.

- Every character has its own sessions. The live panel, the Session tab, History, the
  history search and the Zones tab show the character you are playing, and a session you
  left running on one character carries on when you are back on it in time.
- Searchable sessions for each character. History and its "Find a fish or item" search work
  on one character's sessions at a time. History and Zones have a list of your characters
  (top left in History, top right in Zones): pick another character to see and search its
  sessions, or "All characters" for everyone's. It only changes those lists. The live panel
  always follows the character you are playing.
- Everything you set is kept per character. That is every setting: the fishing key, the
  lure, the food and the other items, fishing gear on or off and the gear chosen per slot,
  the fishing sound and its volume, the alerts and their sounds, everything on the
  Appearance tab (theme, accent, opacity, size, borders), hiding the interface and its
  parts, where prices come from, the session gap and the rest. The live panel's place and
  size are kept per character too.
- A character Keepnet sees for the first time is told so once in chat. It starts with a copy
  of the settings, and the panel's place and size, of the character you played last. From
  then on, what you change on one character stays with that character.
- After the update, the settings the account shared until now become those of the first
  character you log in. Sessions from earlier versions go to the character they were fished
  on the first time that character logs in; where two of your characters share a first
  name, a session stays with the one whose level fits it.
- Still shared by the account: what Keepnet has learned about which buff an item gives.
- Keepnet tells you when a newer version is out: "Keepnet 1.0.1 is out (you have 1.0.0).
  Update it with the CurseForge app." You get it as one chat line after logging in, as a
  line on the live panel the first time the pole goes on, and under "New versions" on the
  Settings tab.
- An addon cannot look anything up on the internet, so it hears this from other players.
  Copies of Keepnet tell each other their version in hidden messages: on a chat channel of
  Keepnet's own (KeepersNet), which reaches every Keepnet player on the realm, and to your
  guild and your party or raid. Nothing shows in chat: the channel is on no chat window and
  none of its lines are printed. It does take one of your channel places.
- A newer version is only believed once two different players have announced it, so one
  odd message cannot raise the notice. What was heard is remembered for a week.
- It only works between copies that have it. Versions before 1.0.0 neither tell nor listen,
  so the first notice you can get is for the version after this one.
- To turn it off: Settings, "New versions", untick "Tell me when a newer Keepnet is out".
  Keepnet then leaves the channel, tells nobody its version and listens to nobody.

## 0.9.9

- The catch list on the live panel scrolls. With more catches than fit, the mouse wheel moves
  through all of them (a small mark at the right shows where you are), where the last row used
  to add the rest up as "3 more".
- The live panel can be sized: drag its bottom right corner. Sideways sets its width; up and
  down sets how many catches show before the list scrolls (3 to 30). The panel still only
  takes the room of the catches there are. The size is remembered. A locked panel has no
  corner to drag.
- "Reset position" in Settings is now "Reset panel": it and `/kn reset` also put the panel's
  size back.

## 0.9.8

- The Lure, Food and Gear lines of the live panel have a colon after their names too
  ("Lure: Bright Baubles x5").

## 0.9.7

- The skill bar shows your total Fishing skill in green brackets after the bonus: "Fishing
  283 / 300  +105 (388)" is 283 trained plus 105 from lure, gear and food.

## 0.9.6

- The numbers on the live panel have a colon after their names: "Casts: 74", "Catches: 69",
  "Empty: 5", "Value: 1g 11s", "Per hour: 3g 13s", "Skill gains this session: 3".

## 0.9.5

- The line under the skill bar now reads "Skill gains this session", then the number.

## 0.9.4

- The live panel has a new line under the skill bar: how many points of Fishing skill you
  gained in the running session.
- The "Auto on" / "Auto off" button beside the lure is now a small "A": lit while the
  fishing key applies lures, plain while it doesn't. The lure line has more room for it.

## 0.9.3

- The live panel shows how many of your lure are left in your bags, next to its name
  ("Bright Baubles x5").
- The live panel shows which version of Keepnet you are running, in small print beside
  the value.

## 0.9.2

- The sample sessions of `/kn demo` now include opened catches (clams and a chest), so you
  can see how those show on the Session tab.

## 0.9.1

- Fixed: the lists that open from the lure, food and gear lines of the live panel were
  see-through and their entries could not be read. They now have a solid background, and
  open upwards when the panel is near the bottom of the screen.

## 0.9.0

- The zone list is in a more useful order: the zones you have fished first, A to Z, then
  the ones you haven't by the Fishing skill they ask for, lowest first.

## 0.8.9

- On the Zones tab, click a session to open it with all of its details: its numbers and
  everything caught in it. A "Back to Zones" button takes you back to the list.
- A session opened from History has the same button back to History, and a finished
  session now shows when it ended.

## 0.8.8

- What comes out of a catch you open now counts: trunks, chests, clams, bloated fish and
  anything else you fished and then open. The items and coins are added to the gold of the
  session that caught it, even if you open it days later.
- The Session tab lists those items and coins as "from an opened catch", and an opened trunk
  no longer shows as an item without a price.

## 0.8.7

- The Zones tab is now a list of zones with the Fishing skill each one asks for and your
  number of sessions there. Every zone with a known skill is listed from the start; the
  ones you have fished come first.
- Click a zone to see its last 20 sessions with their time, casts, catches, gold and gold
  per hour.

## 0.8.6

- The live panel has a cog that opens the settings.
- Click the lure, food or gear line on the live panel to change it there: a list opens with
  every lure or food you have, and for gear each slot with the pieces you could wear.
- Fishing gear can be chosen per slot: the best you have, a piece you pick, or leave the slot
  alone. Before, it was always the best.

## 0.8.5

First public release.

- One key casts and reels in, puts on a lure, eats fishing food and wears fishing gear.
- A live panel with your Fishing skill, casts and catches, what the catch is worth, gold per
  hour, and everything caught this session.
- Sessions with history, by zone, and a search that shows where you caught a fish most.
- Alerts for 121 rare fishing catches, with a sound for each kind.
- Prices from Auctionator, TradeSkillMaster, Auctioneer, aux or Oribos Exchange.
- Hide the game's interface while fishing.
- Theming is a work in progress.
