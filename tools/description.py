"""Makes the text-only copy of the CurseForge description.

    .venv\\Scripts\\python tools\\description.py

media\\curseforge-description.html is the description as it is on the site, pictures included
(their addresses are the gallery's own). media\\curseforge-description-text.html is the same
without the pictures and their captions, on one line: for an editor that is to get the text
first and the pictures by hand, and for seeing what changed in the wording alone.

The script also stops if a picture's address is still a placeholder (@@name@@), which is how
a new picture is written into the description before it has been uploaded.
"""
import re
import sys
from pathlib import Path

MEDIA = Path(__file__).resolve().parent.parent / "media"
SOURCE = MEDIA / "curseforge-description.html"
TEXT = MEDIA / "curseforge-description-text.html"


def main():
    html = SOURCE.read_text(encoding="utf-8")
    waiting = sorted(set(re.findall(r"@@([\w-]+)@@", html)))
    if waiting:
        sys.exit("Pictures without an address yet: " + ", ".join(waiting))
    # A picture and the caption under it (a paragraph that is all emphasis)
    text = re.sub(r"<img\b[^>]*>\s*(<p><em>.*?</em></p>)?", "", html, flags=re.S)
    text = re.sub(r">\s*\n\s*<", "><", text).strip()
    TEXT.write_text(text, encoding="utf-8", newline="")
    print("%s: %d pictures, %d characters" % (SOURCE.name, len(re.findall(r"<img\b", html)), len(html)))
    print("%s: %d characters" % (TEXT.name, len(text)))


if __name__ == "__main__":
    main()
