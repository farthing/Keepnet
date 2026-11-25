"""Builds the zip that goes to CurseForge, and uploads it as a new file of the project.

    .venv\\Scripts\\python tools\\release.py              build dist\\Keepnet-<version>.zip
    .venv\\Scripts\\python tools\\release.py --upload     build it, then upload it
    .venv\\Scripts\\python tools\\release.py --upload --since 0.8.5
                                                        the same, when versions were skipped: the
                                                        changelog covers everything after 0.8.5
    .venv\\Scripts\\python tools\\release.py --notes --since 0.8.5
                                                        only print that changelog, for the site's form

The version is the one in Keepnet.toc. The zip holds the Keepnet folder and nothing else.

Uploading needs three things:
  - the project's number: "## X-Curse-Project-ID: <number>" in Keepnet.toc (it is in the
    "About Project" box of the project's page), or --project <number>
  - an API token from https://authors.curseforge.com/#/settings/api-tokens, in the file
    keys\\curseforge-token.txt (never committed) or in the CF_API_TOKEN environment variable
  - a section for this version in CHANGELOG.md: it becomes the file's changelog

The upload calls (which address, which fields, how the game version is picked) follow the
BigWigs packager's release.sh and CurseForge's own upload API article; see CREDITS.md.
"""
import argparse
import json
import os
import re
import sys
import urllib.error
import urllib.request
import uuid
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ADDON = ROOT / "Keepnet"
TOC = ADDON / "Keepnet.toc"
SITE = "https://wow.curseforge.com"
FOREVER_TYPE = 88568          # CurseForge's "game version type" for the Forever client
OPTIONAL = ["auctionator"]    # project slugs shown as optional dependencies
NOT_SHIPPED = {".ogg", ".mp3", ".wav", ".zip", ".png", ".jpg"}


def toc_field(name):
    match = re.search(r"^## %s:[ \t]*(.+?)[ \t]*$" % re.escape(name), TOC.read_text(encoding="utf-8"), re.M)
    return match.group(1) if match else None


def game_version():
    """16001 -> "1.60.1", the way the packager reads an interface number"""
    interface = toc_field("Interface")
    return "%d.%d.%d" % (int(interface[:-4]), int(interface[-4:-2]), int(interface[-2:]))


def build(version):
    out = ROOT / "dist" / ("Keepnet-%s.zip" % version)
    out.parent.mkdir(exist_ok=True)
    files = sorted(p for p in ADDON.rglob("*") if p.is_file())
    for path in files:
        if path.suffix.lower() in NOT_SHIPPED:
            sys.exit("Not building: %s does not belong in the addon folder." % path.relative_to(ROOT))
    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as archive:
        for path in files:
            archive.write(path, "Keepnet/" + path.relative_to(ADDON).as_posix())
        archive.write(ROOT / "LICENSE", "Keepnet/LICENSE.txt")
    with zipfile.ZipFile(out) as archive:
        names = archive.namelist()
    if "Keepnet/Keepnet.toc" not in names or any(not n.startswith("Keepnet/") or "\\" in n for n in names):
        sys.exit("The zip is not laid out as CurseForge wants it.")
    print("built %s  (%d files, %d KB)" % (out.relative_to(ROOT), len(names), out.stat().st_size // 1024))
    return out


def changelog(version, since=None):
    """The section of this version. With since, every section newer than that version as well,
    each under its own heading: for an upload that follows versions which never went up."""
    path = ROOT / "CHANGELOG.md"
    text = path.read_text(encoding="utf-8") if path.exists() else ""
    sections = [(m.group(1), m.group(2).strip())
                for m in re.finditer(r"^## (\S+)[^\n]*\n(.*?)(?=^## |\Z)", text, re.M | re.S)]
    names = [name for name, _ in sections]
    if version not in names or not dict(sections)[version]:
        sys.exit("CHANGELOG.md has no section '## %s': write what changed for players first." % version)
    if not since:
        return dict(sections)[version]
    if since not in names or names.index(since) < names.index(version):
        sys.exit("--since %s: CHANGELOG.md has no such section below '## %s'." % (since, version))
    covered = sections[names.index(version):names.index(since)]
    return "\n\n".join("## %s\n\n%s" % section for section in covered)


def token():
    value = os.environ.get("CF_API_TOKEN")
    path = ROOT / "keys" / "curseforge-token.txt"
    if not value and path.exists():
        value = path.read_text(encoding="utf-8").strip()
    if not value:
        sys.exit("No API token: put it in keys\\curseforge-token.txt or CF_API_TOKEN.")
    return value


def call(url, key, data=None, content_type=None):
    request = urllib.request.Request(url, data=data, headers={"X-Api-Token": key, "User-Agent": "addon-release-script"})
    if content_type:
        request.add_header("Content-Type", content_type)
    try:
        with urllib.request.urlopen(request, timeout=120) as response:
            return json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as error:
        sys.exit("CurseForge answered %d for %s\n%s" % (error.code, url, error.read().decode("utf-8", "replace")[:600]))


def upload(archive, version, project, since=None):
    key = token()
    wanted = game_version()
    versions = call(SITE + "/api/game/versions", key)
    ours = [v for v in versions if v.get("gameVersionTypeID") == FOREVER_TYPE]
    ids = [v["id"] for v in ours if v.get("name") == wanted]
    if not ids:
        sys.exit("CurseForge has no Forever game version named %s. It has: %s"
                 % (wanted, ", ".join(sorted(v["name"] for v in ours)) or "none"))
    metadata = {
        "displayName": "Keepnet %s" % version,
        "gameVersions": ids,
        "releaseType": "release",
        "changelog": changelog(version, since),
        "changelogType": "markdown",
        "relations": {"projects": [{"slug": slug, "type": "optionalDependency"} for slug in OPTIONAL]},
    }
    boundary = uuid.uuid4().hex
    body = b"".join([
        ("--%s\r\nContent-Disposition: form-data; name=\"metadata\"\r\n\r\n" % boundary).encode(),
        json.dumps(metadata).encode("utf-8"), b"\r\n",
        ("--%s\r\nContent-Disposition: form-data; name=\"file\"; filename=\"%s\"\r\n"
         "Content-Type: application/zip\r\n\r\n" % (boundary, archive.name)).encode(),
        archive.read_bytes(), b"\r\n",
        ("--%s--\r\n" % boundary).encode(),
    ])
    answer = call("%s/api/projects/%s/upload-file" % (SITE, project), key, body,
                  "multipart/form-data; boundary=" + boundary)
    print("uploaded as file %s (game version %s)" % (answer.get("id"), wanted))


def main():
    parser = argparse.ArgumentParser(description="Build the CurseForge zip, and upload it with --upload")
    parser.add_argument("--upload", action="store_true")
    parser.add_argument("--project", help="CurseForge project number (default: X-Curse-Project-ID in the TOC)")
    parser.add_argument("--since", metavar="VERSION",
                        help="the last version that is on CurseForge: the changelog then covers every version after it")
    parser.add_argument("--notes", action="store_true",
                        help="only print the changelog that would go up (to paste into the site's upload form)")
    arguments = parser.parse_args()

    version = toc_field("Version")
    if arguments.notes:
        sys.stdout.buffer.write((changelog(version, arguments.since) + "\n").encode("utf-8"))
        return
    archive = build(version)
    if arguments.upload:
        project = arguments.project or toc_field("X-Curse-Project-ID")
        if not project:
            sys.exit("No project number: add '## X-Curse-Project-ID: <number>' to Keepnet.toc.")
        changelog(version, arguments.since)  # stop before anything is sent if there is nothing to say
        upload(archive, version, project, arguments.since)


if __name__ == "__main__":
    main()
