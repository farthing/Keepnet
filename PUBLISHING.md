# Publishing on CurseForge

Notes gathered 2026-11-23 before the addon was released; it is on CurseForge since
2026-11-24 (https://www.curseforge.com/wow/addons/keepnet). The two "Where it stands"
sections and "The listing's pictures and text" say what was done and how.
Sources are numbered at the end; "my reading" marks what a source doesn't state outright.

## Before anything else

- **The name is Keepnet** (since 0.6.0). Checked 2026-11-23: no addon by that name at
  CurseForge's `/wow/addons/keepnet`, on Wago or on GitHub; WoWInterface was not checked.
  CurseForge wants a unique English name without the game's name or version numbers in it [2].
  The working name before that, "Tacklebox", was already taken there, by an addon that also
  supports this client, which is why it was dropped. The folder name matters as much as the
  listing: two addons can't share a folder in `Interface\AddOns`, and addon managers match
  installed addons by folder name.
- **Pick a licence.** CurseForge has a dropdown plus a custom option [1]. Other addons' methods
  are credited in `CREDITS.md`; no code or media from them is in the addon.
- **Nothing bundled that isn't ours.** Copyrighted content needs a licence or explicit
  permission, and music needs redistribution rights [2]. The addon ships no sound files;
  `sounds-local\` is git-ignored for this reason and must stay out of the zip.
- **Blizzard's addon policy:** free, code not hidden or obfuscated, no in-game ads or donation
  requests [17].
- **A logo:** 400x400, not a solid colour, no copyrighted imagery, not WebP [2]. Drawn
  2026-11-23: `media\logo.svg` (source) and `media\logo.png` (400x400). The in-game icon
  was one of the game's (`INV_Misc_Net_01`, the game's art, which can't be the logo) until
  1.1.5. Since then it is Keepnet's own: `Keepnet\Media\Icon.tga`, the logo's picture drawn
  again for the size an icon is seen at (thicker lines, coarser mesh, bigger fish) by
  `tools\make_art.py`. The logo on the listing is unchanged.

## Decided for the listing (2026-11-23)

- **Categories:** Fishing as the main one, plus Professions and Auction & Economy. All three
  are in CurseForge's filter list (Fishing sits under Professions) [21]. Five fishing addons
  checked: all are in Fishing, two add Professions, one adds Audio & Video [22].
- **Licence:** MIT suggested, not yet confirmed by the owner. Four of the five addons checked
  are "All Rights Reserved" and one has a custom licence [22]. MIT lets others fix, fork and
  carry the addon on with the copyright line kept; All Rights Reserved is the choice if nobody
  else should be able to republish it. When confirmed: add a `LICENSE` file and pick the same
  in CurseForge's dropdown.
- **Pictures:** `media\screens`, taken with `/kn demo` showing. The demo uses the sample
  character name "Vale", so no real name is on screen. The Session and History pictures were
  taken before that and had the name edited out.
- **Description draft:** `media\curseforge-preview.html`. Themes are left out of it apart from
  one line saying theming is a work in progress.

## Steps

1. Log in at authors.curseforge.com and create a project: World of Warcraft, then name, summary
   (one sentence, not copied from the description), description, licence, class, main category
   (up to four more) and logo [1][2].
2. Build a zip with the addon folder at its root: `Keepnet/Keepnet.toc`, the folder and TOC
   names matching exactly, a real `.zip` under 2 GB [5][1]. Only the `Keepnet` folder goes in:
   no `tests`, `tools`, docs or `sounds-local`.
3. Upload it on the project's Files tab: type Release, a changelog, supported version 1.60.1,
   and Auctionator under Related Projects as an optional dependency. A project is not reviewed
   until it has a file [1][4].
4. Wait for moderation (8:00 to 15:00 CET, every day, first in first out; no typical wait is
   published) [3]. "Changes Required" means fix and resubmit; "Rejected" is final [4]. The most
   common cause of change requests is the description: it must say plainly what the addon does
   [1][16].
5. After approval, later files skip manual review once the project has 5 clean file uploads,
   1,000+ downloads and an update within 90 days [20].

## Where it stands (2026-11-23)

Submitted. The owner said to publish and logged in to their CurseForge account (Farthing) in
Chrome; the rest was done through the author site:

- Project **1825443**, slug `keepnet`, edit page
  https://authors.curseforge.com/#/projects/1825443 . Name, logo, summary; main category
  Fishing, plus Professions and Auction & Economy; licence MIT; distribution to third-party
  apps allowed (my choice, changeable on the License tab); comments left off (the form's
  default).
- Eight pictures in its gallery (all of `media\screens` but the Appearance tab), and the
  description from `media\curseforge-description.html`, which now holds their addresses.
- First file **Keepnet 0.8.5** (`dist\Keepnet-0.8.5.zip`): WoW Forever 1.60.1, release,
  Auctionator as an optional dependency, published automatically once approved. Status when
  last looked: "Under Review"; the project's status: "New". Nobody else can see it until a
  moderator approves it.

## Where it stands (2026-11-24)

**0.8.5 was approved** (seen "Approved" on the Files tab, 2026-11-24, when the owner said the
approval had come and asked for the listing and files to be updated). Done that day, through
the author site in Chrome (still no API token):

- **Keepnet 0.9.1 uploaded** as the second file (`dist\Keepnet-0.9.1.zip`): release, 1.60.1,
  Auctionator optional, published automatically once approved. Its changelog on the site is
  one list of everything since 0.8.5 under three headings (Live panel, Zones, Opened
  catches), written for the site: the "fixed" line of 0.9.1 is left out, since no player
  ever had the see-through lists. **The last version on CurseForge is 0.9.1**; the next
  upload's changelog starts after it (`release.py --since 0.9.1`).
- **Keepnet 0.9.2 uploaded** later the same day as the third file (`dist\Keepnet-0.9.2.zip`),
  when the owner said "upload 9.2": release, 1.60.1, Auctionator optional (the form copies
  game version and relations from the previous file), published automatically once approved.
  Its changelog is the one 0.9.2 section (`release.py --notes --since 0.9.1`). Status when
  last looked: "Processing". **The last version on CurseForge is now 0.9.2**; the next
  upload's changelog starts after it (`release.py --since 0.9.2`).
- **Keepnet 0.9.7 uploaded** that evening as the fourth file (`dist\Keepnet-0.9.7.zip`), when
  the owner, having tried the development copy, said "the changes look good. push to
  curseforge. no need to add media or description items": release, 1.60.1, Auctionator
  optional (copied by the form from 0.9.2), published automatically once approved. By then
  0.9.2 showed "Approved". Its changelog on the site is one list of what is new on the live
  panel since 0.9.2 (skill gains, total skill, lure count, the "A" button, colons, version),
  written for the site rather than version by version: no player had 0.9.3 to 0.9.6. The
  description and the gallery were left alone, as asked, so they do not show or mention
  these additions. The form names a file after its zip ("Keepnet-0.9.7.zip"); the display
  name was typed over as "Keepnet 0.9.7" like the others. Status a few minutes later:
  "Under Review" (it read "Uploading" for the first minutes). **The last version on CurseForge is now 0.9.7**; the next upload's changelog
  starts after it (`release.py --since 0.9.7`).
- **Keepnet 0.9.9 uploaded** later that evening as the fifth file (`dist\Keepnet-0.9.9.zip`),
  when the owner, having tried the development copy, said "that works well. push 0.9.9 to
  curse": release, 1.60.1, Auctionator optional (copied by the form from 0.9.7), published
  automatically once approved, display name typed over as "Keepnet 0.9.9". By then 0.9.7
  showed "Approved". Its changelog on the site is one list of four points covering 0.9.8 and
  0.9.9 (the scrolling catch list, sizing the panel by its corner, "Reset panel", the colons
  after Lure, Food and Gear). Status right after: "Uploading"; **"Approved" within about
  ten minutes.** **The last version on CurseForge is now 0.9.9**; the next upload's changelog
  starts after it (`release.py --since 0.9.9`).
- **The description says the panel can be resized** (saved on the site right after, when the
  owner said "fix the line so it indicates resizable window"): the feature list reads "A live
  panel you can resize, ..."; under "The live panel" the catch line ends "A long list scrolls
  with the mouse wheel." and a new line "Resizable: drag the panel's bottom right corner to
  make it wider, or to show more catches before the list scrolls." follows it.
  `media\curseforge-description.html` holds it. (The description never said that the last
  row adds up the rest; that was the README, already changed in 0.9.9. I told the owner
  wrongly that it did.)
- **A new picture of the live panel** (the same evening; the owner: "i have a good session
  onscreen right now for the live screenshot"). It is the owner's own session, not the
  samples of `/kn demo`: Tanaris, 51 minutes, eleven different catches all on show in a panel
  dragged taller, the corner's dots, v0.9.9, the interface hidden; no name is on it. Taken
  with `tools\capture.ps1 -Name live-0.9.9` and `tools\cut.ps1 -Frame panel`, saved over
  `media\screens\01-live-panel.png`. In the gallery it is a thirteenth picture, titled "The
  live panel" and featured (`attachments/2267/165/01-live-panel-png.png`), and the
  description's picture under "The live panel" now points at it. **The old picture of the
  panel (`attachments/2265/892/...`, 0.9.1's panel with the "Auto on" button) is still in the
  gallery, also titled "The live panel" and featured:** deleting it waits for the owner's yes.
  Nothing in the description uses it any more. The other pictures were not touched: "Keepnet
  in the game" and "Changing the lure from the live panel" still show the older panel, and
  no picture shows the scroll mark.
- **Four more pictures redone for 0.9.9, an hour later** (the owner: "which other
  screenshots need updating, i can do them quick", then set each screen up and said when it
  showed). All in `media\screens` under their old names, in the gallery as new pictures with
  the old titles, and in the description in place of the old ones:
  - `11-panel-lists.png`, "Changing the lure from the live panel" (`2267/302`, featured):
    the owner's own session, lure list open.
  - `12-interface-hidden.jpg`, "The interface hidden while fishing" (`2267/303`, featured):
    the owner's own session over open water in fog, cut from the capture with
    `cut.ps1 -Box 200,150,2560,1440 -ShrinkTo 1920`. Duller than the harbour picture it
    replaces; the owner was told and can send a brighter one.
  - `00-in-game.png`, "Keepnet in the game" (`2267/301`, featured): panel and Session tab
    with `/kn demo` on ("Vale"), `cut.ps1 -Frame both`.
  - `08-settings.png`, "Settings" (`2267/304`, not featured): the button reads "Reset panel".
  **The five old pictures they replaced were deleted** from the gallery later that evening
  (`2265/891`, `892`, `898`, `902`, `905`), on the owner's "delete the old screenshots", and
  the gallery was put back in its old order with "Reorder gallery": in the game, live panel,
  session, history, zones, gear, alerts, settings, find a fish, zone session, lure list,
  interface hidden. Twelve pictures again, the same seven featured.
- **The picture of the hidden interface was taken again in Stormwind** that night (the
  owner: "I'm in storm wind, hidden ui is on, it is a little foggy but better than tanaris
  from earlier"): the canals from a bridge, the panel over the water, the fishing trainer's
  dock behind it. It is `2267/450` in the gallery (same title, featured, last in the order)
  and in the description; the foggy one (`2267/303`) was deleted. The panel on it still
  says "Tanaris [300]": it is the Tanaris session, shown while standing in Stormwind.
  **Five other players stood in the shot with their names over their heads, readable at
  full size.** They were smudged with the new `tools\smudge.ps1` before the cut (`-Boxes`
  with each name's area; the game's own characters, the guards and the two fishing
  vendors, keep theirs). A city picture needs that look at full size every time: cut the
  busy parts out of the capture with `cut.ps1 -Box` and read them before anything goes up.
- Deleting and reordering from a script: the second button on a card (after `mouseover`)
  is the bin; it opens a "Delete media" dialog of the page's own, OK deletes ("Delete
  successful"). "Reorder gallery" makes every card a keyboard-draggable item: focus the
  card (`li[aria-roledescription=draggable]`), then real key presses Space (pick up), arrow
  keys, Space (drop), with a second's wait after each key, and "Done" saves ("Edit
  successful"). The grid was three cards wide at that window size, so an arrow up or down
  moves three places; a live region on the page says which card the held one is over.
  The seven window-only pictures (session, history, zones, gear, alerts, find a fish, zone
  session) were left: nothing on them changed but the version label.
- Titles and stars can be set from a script, without the mouse: fire `mouseover` on the
  card so its pencil appears, click it, set the title with the input's own value setter and
  an `input` event, click the star's parent, click Apply ("Edit successful"). A card's
  "Add to Featured" label exists on any card the mouse has been over, so it does not say
  whether the card is featured; reload the Media tab and read it then.
- How the gallery behaved this time: "Add media" opens a small dialog first; its "Upload or
  Drag Image" button is the one that makes the hidden file field. The edit form of a picture
  (the pencil shows only with the mouse on the card) has a star beside "Feature Media", not
  a tick box: the star itself takes the click, not the words. On the Description tab, Save
  stays disabled after `setContent` unless the editor is marked changed
  (`ed.setDirty(true)` before firing `change`): the first save of the evening did nothing
  and showed no message, the second said "Changes saved successfully". Reload and read the
  editor back before believing a save. Screenshots of the tab time out while the game has
  the screen; reading the page with scripts still works.
- The owner's own game gets the addon from the CurseForge app since that day: the copy made
  by `tools\install.ps1` was taken out (`install.ps1 -Remove`) at their request. Running
  `install.ps1` again would put a development copy over the app's install, so ask first.
- The description and the gallery: see "The listing's pictures and text" below.

The upload form has no file field until "Choose File" is pressed, and pressing it opens the
system's file dialog, which the browser tools can't drive. What worked: replace
`HTMLInputElement.prototype.click` in the page for a moment so the form's own file field is
kept on the page instead of opening the dialog, give the zip to that field, put the function
back. The changelog box is a TinyMCE editor (`tinymce.get()[0].setContent(html)`).

**Updates go up when the owner says so**, after a batch of changes ("when we make enough
changes here"), never by themselves.

**Keepnet 0.9.1 was approved within half an hour** of the upload (seen "Approved" the same
afternoon), so the public page offers it.

## The listing's pictures and text (redone 2026-11-24)

The owner, when the approval came: "we need new/more screenshoots", and "at the beginning of
the description of the plugin, start with a bullet list of features".

- **Description:** `media\curseforge-description.html` is what is on the site, word for word:
  a "Features" list first, then the sections as before, with new parts for changing the
  lure, food and gear from the panel, opened catches, the history search as numbered steps
  and the zone list. `tools\description.py` makes the `-text` copy from it. To put a changed
  description on the site: Description tab, `tinymce.get()[0].setContent(html)`, fire
  `change`, Save. (The file got into the page through a file field made for the purpose,
  read with `File.text()`: nothing typed by hand.)
- **Gallery:** the 12 pictures in `media\screens` except `07-appearance.png` (themes are
  still a work in progress). Each has a title written for people; the featured ones are the
  in-game one, the live panel, the zone list, the fish search, the session with opened
  catches, the lure list and the hidden interface. The 8 pictures from 2026-11-23 were
  deleted from the gallery with the owner's yes. The description's pictures are the gallery's
  own (`media.forgecdn.net/attachments/2265/...`); deleting a gallery picture breaks it in
  the description.
- **How the pictures are taken** (the owner clicks, the tools catch it):
  1. In the game: `/kn demo` first, **every time after a `/reload`** (a reload switches the
     samples off, and then the screens show the owner's own sessions and character name: one
     whole round of captures was thrown away for that). The Session tab must say "Vale".
  2. `tools\capture-watch.ps1 -Crop <the window's area> -Full -Ticks 1.5 -Seconds 300` saves
     the whole game window whenever the watched area changes and settles, and every 1.5 s
     while the world shows through it. The owner clicks through the screens meanwhile.
  3. `tools\cut.ps1 -In <capture> -Frame window|panel|both -Out media\screens\<name>.png`
     finds the window or the panel in the capture by its black border and cuts it out, so
     it does not matter where they stood. Look at every cut before it goes anywhere: the
     player's own unit frame sits just beside the panel on the owner's screen.
  4. Pictures are taken in the Keepnet theme. A cut of the game world goes up as a JPEG
     (`-Out ....jpg`): the gallery silently dropped a 2.8 MB PNG.
- **The gallery's quirks:** "Add media" has the same hidden file field as the file upload
  (same trick). A new picture's title is `image-attachment_<id>.png` until edited (pencil on
  the card: title, "Feature Media", Apply). For some minutes after edits and deletes the
  site answers from stale copies: a delete can say "There was an error" and still have
  worked, and titles can show as file names on one reload and right on the next. Reload a
  few times before redoing anything.
- The pictures' small version label reads v0.9.1 on some and v0.9.2 on others (two rounds);
  the sample sessions with opened catches only exist from 0.9.2.

## Where it stands (2026-11-25)

The owner, with 1.0.0 finished: "publish to git and fix, make repo public. push to curse",
and while the upload form was open: "add bullet point about searchable character sessions".

- **Keepnet 1.0.0 uploaded** as the sixth file (`dist\Keepnet-1.0.0.zip`), through the
  author site in Chrome as before (no API token): release, 1.60.1, Auctionator optional
  (copied by the form from 0.9.9), published automatically once approved, display name typed
  over as "Keepnet 1.0.0". Its changelog on the site is written for the site under two
  headings, "Each character its own" (four points, the second of them the searchable
  sessions per character the owner asked for) and "New versions" (four points, the hidden
  channel and its switch among them). Status right after: "Uploading". **The last version on
  CurseForge is now 1.0.0**; the next upload's changelog starts after it
  (`release.py --since 1.0.0`).
- **1.0.0 went up without the update notice ever having run in the real game.** The
  per-character half was seen there by the owner; the notice was only tested offline (the
  owner's game still held the build before it). Watch the comments and the error reports.
- **One line added to the description's feature list**, after "Sessions and history":
  "Searchable sessions for each character: every character keeps its own session history,
  which you can search for a fish or item; a list switches to another character's sessions,
  or to all of them." Saved ("Changes saved successfully") and read back after a reload;
  `media\curseforge-description.html` holds it.
- **The description says what the update notice does**, added a few minutes later (offered
  to the owner, who said "add those details in there"): a last line in the feature list,
  "Tells you when a newer version is out, heard from other Keepnet players. You can turn it
  off.", and a section "New versions" before "Commands" with five points: how it knows (the
  hidden messages, the channel KeepersNet that Keepnet joins by itself, guild and group),
  that nothing shows in chat and that it takes a channel place until logout, the two
  announcers, how to turn it off, and that it works between copies of 1.0.0 or newer. Saved
  ("Changes saved successfully") and read back. The gallery was not touched.
- The upload form this time: the Chrome extension was not connected until Chrome was
  started; the zip went in the way described above (the form's own file field kept on the
  page by replacing `HTMLInputElement.prototype.click` for a moment).
- **The source is public since that day**: https://github.com/farthing/Keepnet, one commit
  for 1.0.0. The listing's "Source" tab does not point at it yet.

## 1.0.1 (2026-11-25, evening)

The owner, with the Glass look in their game: "publish to curse as 1.0.0.1, add a not early
on that the themes are in and there is a gimmick one (windows 95)", then "also git it all".
The number became 1.0.1 on the owner's choice, after being told that copies of 1.0.0 only
understand versions of three parts.

- **Keepnet 1.0.1 uploaded** as the seventh file (`dist\Keepnet-1.0.1.zip`, 41 files, 351
  KB: the first with files that are not code, in `Keepnet\Media`: five small pictures, two
  font files and the font's licence text). Through the author site in Chrome as before:
  release, 1.60.1, Auctionator optional (copied by the form from 1.0.0), published
  automatically once approved, display name typed over as "Keepnet 1.0.1". Its changelog on
  the site is the 1.0.1 section of `CHANGELOG.md`, seven points. "File uploaded
  successfully"; status "Under Review" a minute later. **The last version on CurseForge is
  now 1.0.1**; the next upload's changelog starts after it (`release.py --since 1.0.1`).
- **The description starts with a note**, before "Features": "New in 1.0.1: looks. Keepnet
  can now be dressed several ways, each in colours of its own: Keepnet, Keepnet rounded,
  Glass, the game's own windows, EllesmereUI's, and one for fun, Windows 95. Pick one on the
  Appearance tab." And the feature list has a line "Looks and colours: ..." after the one
  about hiding the interface. Saved ("Changes saved successfully") and read back after a
  reload; `media\curseforge-description.html` holds both. **The gallery has no picture of
  any of the new looks**, and the picture of the Appearance tab shows the old one list.
- The upload form this time: the form's file field was kept on the page the same way
  (`HTMLInputElement.prototype.click` replaced for a moment, then "Choose File" pressed);
  the display name went in through the input's own value setter and an `input` event.
- **1.0.1 went up with only the Glass look seen in the game** (the owner's saved settings
  said Glass in Amber with Overpass, and the error log held nothing from Keepnet). Windows
  95, Keepnet rounded, the other colours and the Font list with shared fonts were only
  tested offline. Watch the comments and the error reports.
- The source on GitHub is at the same commit, tagged `v1.0.1`.
- **"Approved"** within about twenty minutes (seen on the Media tab's file list).

## 1.1.4 (2026-11-25, evening)

The owner, with the gear key seen working in a fight: "document, save, publish to curse.
publish to public git."

- **Keepnet 1.1.4 uploaded** as the eighth file (`dist/Keepnet-1.1.4.zip`, 42 files, 364
  KB), through the author site in Chrome as before: release, 1.60.1, Auctionator optional
  (copied by the form from 1.0.1), published automatically once approved, display name
  "Keepnet 1.1.4". Its changelog on the site is written for the site, everything since 1.0.1
  under four headings: "Lures bought for you", "A gear key", "The line's time and what it
  brought up", "Looks" (the Matrix colours). "File uploaded successfully"; "Processing"
  right after. **The last version on CurseForge is now 1.1.4**; the next upload's changelog
  starts after it (`release.py --since 1.1.4`).
- **The description is up to date with it** (saved, "Changes saved successfully", read back
  after a reload): the opening note is "New in 1.1: ...", the feature list has the points
  for buying lures (the owner: "this should be a dot point feature, pointing out the auto
  purchase and customization of said purchase"), the gear key and the line's countdown, the
  section "Lures bought for you" stands before "Out of your way", and "Theming is a work in
  progress" is gone. `media/curseforge-description.html` is the same text.
- **Buying lures went up without having bought anything in the real game.** The gear key
  (also in combat), recording key combinations, the line's strip and the looks were seen
  there by the owner. Watch the comments and the error reports for the vendor part.
- No new pictures: the gallery shows nothing of the lure buying, the gear key's button or
  the strip.
- The source on GitHub is at the same commit, tagged `v1.1.4`.

## 1.1.5 (2026-11-25, about 22:10)

The owner, after a restart with the development copy of 1.1.5 in the game: "works well,
push to curse".

- **Keepnet 1.1.5 uploaded** as the ninth file (`dist/Keepnet-1.1.5.zip`, 44 files, 373
  KB; built from the project, so without the development mark), through the author site in
  Chrome as before: release, 1.60.1, Auctionator optional (copied by the form from 1.1.4),
  published automatically once approved, display name "Keepnet 1.1.5". Its changelog on the
  site is the 1.1.5 section of `CHANGELOG.md`, two points (the minimap button, the icon).
  "File uploaded successfully"; "Uploading" right after. **The last version on CurseForge
  is now 1.1.5**; the next upload's changelog starts after it (`release.py --since 1.1.5`).
- **The description was left as it is**, on purpose: a minimap button is a given, like
  settings per character. The logo on the listing is unchanged too.
- The upload form this time: 1.1.4 read "Approved" on the Files tab. The form's file field
  was kept on the page the same way (`HTMLInputElement.prototype.click` replaced for a
  moment, "Choose File" pressed, the zip given to the field that appeared, the function put
  back); the display name went in through the browser tool's form fill, the changelog
  through `tinymce.get()[0].setContent(html)`.
- What the owner tried before saying so was not said. See DEVLOG for what is still unseen.
- The source on GitHub is at the same code, tagged `v1.1.5`.
- **Pictures are still owed** from 1.1.4 (lure buying, the gear key's button, the line's
  strip); a picture with the minimap button in it could go up with them.

## 1.2.5 (2026-11-27, about 17:00)

The owner, with the 65 % bobber mark in their game: "that... is MUCH better. push to curse with
bullets updated. the new short description".

- **Keepnet 1.2.5 uploaded** as the tenth file (`dist/Keepnet-1.2.5.zip`, 49 files, 384 KB,
  built from the project without the development mark), through the author site in Chrome
  as before:
  - release, 1.60.1, Auctionator optional (copied by the form from 1.1.5), published
    automatically once approved, display name "Keepnet 1.2.5";
  - the file field kept on the page by replacing `HTMLInputElement.prototype.click` for a
    moment, the zip given to it with the browser tool's file upload.
  - **Its changelog on the site** is written for the site (`dist/changelog-1.2.5-site.html`,
    not tracked): "A bobber you can always see" and "Its settings", covering 1.1.6 to 1.2.5
    as a whole. No player had the steps in between.
  - "Uploading", then "Under Review" two minutes later. **The last version on CurseForge is
    now 1.2.5**; the next upload's changelog starts after it (`release.py --since 1.2.5`).
- **The summary (short description)** went from "One-key fishing with a live panel that shows
  what your catch is worth, session history by zone, and alerts for rare catches." to "Fish
  smarter: see which zones your skill can fish, search every catch by character, spot your
  bobber at a glance, and pick your own sounds."
  - The owner chose it from four drafts, after saying the bobber should be one point among
    zones with skill requirements, searchable history per character and customisable sounds.
  - The TOC's `## Notes` (the line in the game's addon list) is the same text since 1.2.5.
  - Saved; read back after a reload.
- **The description** (`media/curseforge-description.html`, put in through a temporary file
  field and `tinymce.get()[0].setContent`):
  - the opening note is "New in 1.2: a bobber you can always see…";
  - the feature list has "A bobber you can always see" after the gear key;
  - a new section of the same name stands before "Out of your way". It says plainly that
    Keepnet turns on the game's soft target settings while the line is out, puts them back
    after, and keeps the nameplates showing while the whole interface is hidden.
  - "Changes saved successfully"; read back after a reload.
- **No new pictures** ("media we can worry about later"). The gallery shows no bobber mark,
  and the Settings tab picture still shows the Live panel options there (they're on the
  Appearance tab since 1.2.1).
- The source on GitHub is at the same commit, tagged `v1.2.5`.

## 1.2.7 and the new pictures (2026-11-27, about 18:00)

The owner: "push to curse".

- **Keepnet 1.2.7 uploaded** as the eleventh file (`dist/Keepnet-1.2.7.zip`, 49 files, 384 KB, no
  development mark), as before: release, 1.60.1, Auctionator optional (copied from 1.2.5),
  display name "Keepnet 1.2.7". Its changelog is two points: the cog faded under the mark, and
  the Settings spacing. **"Approved" within about ten minutes. The last version on CurseForge
  is now 1.2.7** (`release.py --since 1.2.7` next).
- **Gallery: 17 pictures.** Five were added, in one go through the "Add media" dialog's
  "Upload or Drag Image" file field (it takes several files):
  - `2284/290` "The bobber mark: the line's time at a glance" (featured);
  - `2284/291` "Gear & food, and lures bought from vendors";
  - `2284/292` "Settings, with the bobber mark's options";
  - `2284/293` "The interface hidden: the panel, its line timer and the bobber mark"
    (featured);
  - `2284/294` "Appearance: looks, colours, size and the live panel".
  - Titles and stars were set in the edit dialog, stepping with its arrow; wait for Apply
    to grey out before stepping, or a "discard changes?" box comes up.
- **Four old pictures deleted** (the clean-up rule): `2265/896` Gear & food, `2271/922`
  Settings, `2267/450` the interface hidden, and `2272/275` an older Appearance picture that
  was in the gallery but not in the description.
  - The bin only appears on hover: hover the card first, then click about 25 px in from its
    right edge and 26 down from its top (CSS px; screenshot coordinates are those × 1120 /
    innerWidth).
  - It asks "Delete media … OK" in the page itself (no browser pop-up).
- **Order put back** with "Reorder gallery":
  - in the game, live panel, **bobber timer**, session, history, zones, **gear & food**,
    alerts, **settings**, find a fish, zone session, panel lists, **interface hidden**,
    **appearance**, Windows 95, Glass, rounded.
  - **Reload before reordering:** right after the deletes, the reorder list still held the
    four deleted pictures (the stale copies).
  - It is a dnd-kit list: focus the item (`li.sortable-screenshot-element`), Space to pick
    up, the arrow keys (three columns: Up is three places), Space to drop, then Done.
    Reliable where dragging blind isn't.
- **The logo trap:** the General tab's "Upload image" (the project logo) stays in the page.
  A script that grabs the first file field behind an "Upload…" button gets the logo's. Use
  the gallery's own field (the multiple one behind "Add media", "Upload or Drag Image").
  Nothing went into the logo.
- **Description:**
  - the five placeholders filled with the new addresses (`description.py`: 14 pictures);
  - put in through a temporary file field and `setContent`;
  - "Changes saved successfully". The first reload still showed the old text (stale); the
    one 20 s later showed the new one.
- Screenshots of the author site often time out in this browser; reading the page with
  scripts worked throughout.

### Waiting for the next upload (written 2026-11-25, night; done with 1.1.4, see above)

`media\curseforge-description.html` is ahead of the site: it has what 1.0.2 to 1.0.8 add
(lines in the feature list for buying lures, the gear key, and the line's countdown and
catch list; a section "Lures bought for you"; a line each under "One key does the fishing"
and "Out of your way"), and it no longer says "Theming is a work in progress", which the
site still does. The owner asked for the lure buying "added as a feature, the auto buy, the
selection, the gate". **The site was not touched**: it describes the file players can
download, which is 1.0.1. Put the description on the site with the upload that brings these
versions, and bring its opening note ("New in 1.0.1: looks") up to date then.

### Four pictures for the looks (the same evening)

The owner set each screen up and said when it showed ("i think we only need a single image
for each, live tracking and main window together for each. don't need sub tabs"). Each is
the window and the live panel together, taken with `tools\capture.ps1`; all say v1.0.1 (the
development copy in the game had to be made again first: it still said 1.0.0).

- `07-appearance.png`, "Appearance: looks, colours and font" (`2272/275`, not featured): the
  Keepnet look, Overpass, the Appearance tab with its three lists and the Font list. The
  gallery never had a picture of this tab before.
- `13-look-win95.png`, "The Windows 95 look" (`2272/276`, featured): the Session tab with
  the sample character. **A name stood in the world just above the window's corner: it was
  smudged** (`tools\smudge.ps1`) and the place looked at up close before the cut.
- `14-look-glass.png`, "The Glass look" (`2272/277`, featured): Amber, the Session tab with
  the sample character.
- `15-look-rounded.png`, "The Keepnet rounded look" (`2272/278`, not featured): Dusk, the
  Appearance tab.

Which two are featured was my choice. They stand last in the gallery's order, sixteen
pictures now, nine featured. The description does not show them.

What this taught: `cut.ps1 -Frame both` does not find the Windows 95 or the Glass window (it
looks for the dark flat frames): cut those with `-Box left,top,width,height` read off the
capture. And **the gallery's edit form stays open after "Apply"**: a second edit sent
straight after goes to the same picture (two titles landed on the wrong one and were put
right). Press Cancel, or check that the form's title is the picture's own, before every
edit; read all titles back after a reload.

## Four pictures redone for 1.0.0 (2026-11-25, evening)

The owner set each screen up with `/kn demo` on and said when it showed; each was taken with
`tools\capture.ps1` and cut with `tools\cut.ps1 -Frame window`, and looked at before it went
anywhere (only "Vale" on them). In `media\screens` under their old names, in the gallery as
new pictures with the old titles and stars, and in the description in place of the old ones:

- `03-history.png`, "History: one row per session" (`2271/920`, not featured): the list of
  characters at the top left.
- `04-zones.png`, "Zones: the skill each one asks for, and your sessions there" (`2271/921`,
  featured): the list of characters at the top right. Taken on a character with Fishing 10,
  so most skill numbers are red or yellow.
- `08-settings.png`, "Settings" (`2271/922`, not featured): the "New versions" block. Taken
  on the copy from the CurseForge app: a development copy adds a sentence there that no
  player sees, so a picture of Settings must come from a released copy. Cut with
  `-Margin 0`, because the live panel's corner showed in the margin.
- `09-find-a-fish.png`, "History: where a fish was caught" (`2271/923`, featured).

**The four old pictures were deleted** (`2265/894`, `2265/895`, `2267/304`, `2265/899`;
"Delete successful" each time) and the gallery put back in its order: in the game, live
panel, session, history, zones, gear, alerts, settings, find a fish, zone session, lure
list, interface hidden. Twelve pictures, the same seven featured, read back after a reload.

**The owner's rule since that day: "always clean up images when we update them".** A picture
that is replaced is deleted in the same job, once nothing uses it any more, and the order is
put back. No asking first.

What reordering taught this time:

- Right after deletes, "Reorder gallery" can still list the deleted pictures (it listed
  sixteen cards for twelve). Cancel, leave the project's pages and come back, and count the
  cards before moving anything.
- The arrow keys move the held card across the grid, not along the order: Left and Right
  stop at the ends of a row, Up and Down move a whole row (three places at this window
  size). A Left on the first card of a row does nothing, and says nothing.
- Before the Space that picks a card up: `blur()`, `focus()`, and a second's wait. Without
  them the Space was ignored once. Two seconds after each key, and read the order back (the
  cards that are not `position: fixed`) and the page's live region ("was moved over ...")
  before the next one: Chrome was minimised behind the game and slow to redraw.
- Done saves ("Edit successful").

What the edit form taught this time: whether a picture is featured can be read from its
star in the form (the pencil): the star's path is filled orange (`#F16436`) when it is, and
only an outline (`fill="none"`) when it is not. The star is the icon in the box before the
words "Feature Media"; that box takes the click. Several pictures can be given to "Add
media" at once.

## For the next description (written 2026-11-25; the update notice and the searchable sessions are on the site since, see above)

The new pictures of the History, Zones and Settings tabs are on the site since that evening
(see the section above). That every
setting and the panel's place are kept per character stays out of the description on the
owner's word (2026-11-25: "the kept per character is actually sort of a given in any
addon"): don't offer it again.

The description on the site stops at 0.9.9. When 1.0.0 goes up and the owner asks for the
listing to be brought up to date, it should cover:

- **Each character its own.** Sessions, the running session, History and Zones belong to
  the character being played. The list of characters on the History and Zones tabs shows
  another character's sessions, or everyone's; the live panel always follows the character
  being played. Every setting, and the live panel's place and size, are kept per character;
  a new character starts with a copy of the settings of the character played last.
- **The update notice.** Keepnet tells the player when a newer version is out (chat, the
  live panel, Settings). Say plainly how: copies tell each other their version in hidden
  messages, over a chat channel of Keepnet's own (KeepersNet) that it joins by itself, and
  to the guild and the group. Nothing shows in chat, and the channel takes one of the
  player's channel places. Say how to turn it off: Settings, "New versions", untick "Tell
  me when a newer Keepnet is out", and Keepnet leaves the channel. Say that it only works
  between copies of 1.0.0 or newer.
- The feature list at the top needs a line for each of the two.
- Pictures: the History and Zones tabs now carry the list of characters, and Settings has
  the "New versions" block, so the pictures of those three tabs are out of date. Take new
  ones with `/kn demo` on: the list then offers only the sample character, so no real name
  is on screen.

CurseForge's reviewers look for a description that says plainly what an addon does. An
addon that joins a chat channel on the player's behalf should say so there, not only in the
changelog.

## Updating the listing after a release

One command builds the zip and uploads it as a new file [9][23]:

    .venv\Scripts\python tools\release.py --upload --since <last version on CurseForge>

`--since` makes the changelog cover every version after that one (uploads follow batches of
versions, so there are usually several); without it only the newest section goes up.
`--notes --since <version>` prints that changelog without building or sending anything, for
pasting into the site's form while there is no token.

It needs, once:

- `## X-Curse-Project-ID: <number>` in `Keepnet.toc` (the number is in the project's "About
  Project" box once the project exists).
- An API token from https://authors.curseforge.com/#/settings/api-tokens in
  `keys\curseforge-token.txt` (git-ignored) [23].

And every time: a `## <version>` section in `CHANGELOG.md`, written for players. Without it the
script stops before sending anything. The upload part has never run (no project or token yet);
the first use is its test. Not confirmed: whether the game versions list is at
`/api/game/versions` (CurseForge's article, used by the script) or `/api/game/wow/versions`
(the packager) [9][23].

## This client ("Forever")

- CurseForge has a Forever flavour with game version 1.60.1 [14]; its own author docs don't
  mention it, so this comes from a live project page.
- The game accepts a plain TOC with `## Interface: 16001`, which is what the addon has [12].
- Alpha and Beta files don't reach the CurseForge app by default: the project needs at least
  one Release file [1].

## Automatic releases (optional, later)

The BigWigs packager builds the zip and uploads it when a tag is pushed [8][10]. Version 2.7.0
(5 Nov 2026) maps interface 16xxx to the Forever flavour [9].

What it needs:

- `## X-Curse-Project-ID: <id>` in the TOC (the ID is in the project's "About Project" box) [8].
- An API token from authors.curseforge.com, API tokens page, stored as the GitHub secret
  `CF_API_TOKEN` [8][10].
- `## Version: @project-version@` in the TOC, so the tag becomes the version [13].
- A `.pkgmeta` file and a workflow file. The packager expects the TOC at the repository root;
  this project keeps the addon in a subfolder, so it needs `move-folders` (my reading of the
  script, untested) or the addon moved to the root [9][11]:

```yaml
# .pkgmeta
package-as: Keepnet
move-folders:
  Keepnet/Keepnet: Keepnet
ignore:
  - tests
  - tools
  - sounds-local
  - "*.md"
optional-dependencies:
  - auctionator
```

```yaml
# .github/workflows/release.yml
name: Package and release
on:
  push:
    tags: ['**']
permissions:
  contents: write
jobs:
  release:
    runs-on: ubuntu-latest
    env:
      CF_API_TOKEN: ${{ secrets.CF_API_TOKEN }}
      GH_API_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    steps:
      - uses: actions/checkout@v7
        with:
          fetch-depth: 0
      - uses: BigWigsMods/packager@v2
```

- A tag containing "alpha" or "beta" is uploaded as that type; any other tag is a release [9].
- The changelog is the commits since the previous tag (hence `fetch-depth: 0`), or a file named
  by `manual-changelog:` [8][11].
- Pushing a workflow file needs a GitHub login with the `workflow` permission.

## Other sites

- **Wago Addons:** the same packager run uploads there with `## X-Wago-ID` and the secret
  `WAGO_API_TOKEN`; its API lists Forever 1.60.1 [19].
- **WoWInterface:** the packager skips Forever as not supported [9].
- **GitHub Releases:** made by the same run [10].

## Not confirmed

- How long approval usually takes, and any WoW-specific rejection reasons.
- The exact label for Forever on the manual upload form.
- Whether the packager can upload the very first file before the project is approved.
- Whether CurseForge's own older "automatic packaging" webhook [7] handles Forever.
- Any CurseForge rule on addons that automate play; only Blizzard's policy [17] was found.

## Sources

1. https://support.curseforge.com/support/solutions/articles/9000197241-creating-and-submitting-a-project
2. https://support.curseforge.com/support/solutions/articles/9000197279
3. https://support.curseforge.com/support/solutions/articles/9000198422-world-of-warcraft-addons-faq-and-troubleshooting
4. https://support.curseforge.com/support/solutions/articles/9000197905-project-statuses-101
5. https://support.curseforge.com/support/solutions/articles/9000210425-curseforge-file-processor-errors-per-game
7. https://support.curseforge.com/support/solutions/articles/9000197281-automatic-packaging
8. https://github.com/BigWigsMods/packager
9. https://github.com/BigWigsMods/packager/blob/master/release.sh
10. https://github.com/BigWigsMods/packager/wiki/GitHub-Actions-workflow
11. https://github.com/BigWigsMods/packager/wiki/Preparing-the-PackageMeta-File
12. https://warcraft.wiki.gg/wiki/TOC_format
13. https://warcraft.wiki.gg/wiki/Using_the_BigWigs_Packager_with_GitHub_Actions
14. https://www.curseforge.com/wow/addons/xe-qol-forever/files
16. https://blog.curseforge.com/how-to-pass-moderation-review-on-curseforge-2/
17. https://us.forums.blizzard.com/en/wow/t/ui-add-on-development-policy/24534
19. https://docs.wago.io and https://addons.wago.io/api/data/game
20. https://support.curseforge.com/support/solutions/articles/9000278720-project-whitelisting-how-trusted-projects-skip-moderation
21. https://www.curseforge.com/wow/addons/auction-economy (category filter list in the sidebar)
22. https://www.curseforge.com/wow/addons/namazu-fishing, /forever-fishing, /easy-fishing,
    /fishing-buddy, /modern-fishing ("Class & Categories" and "Details" boxes, read 2026-11-23)
23. https://support.curseforge.com/support/solutions/articles/9000197321-curseforge-upload-api
