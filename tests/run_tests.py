"""Runs Keepnet outside the game.

    .venv\\Scripts\\python tests\\run_tests.py

For every tests\\test_*.lua it starts a fresh Lua 5.1 (the version the game uses), loads the
stand-in game (wowstub.lua), loads the addon's files in the order the TOC file lists them, and
runs the test. It also checks that the TOC and the files on disk agree, that every file is
valid Lua 5.1, and that the addon leaves no accidental global variables behind.

A pass means the addon's own logic holds together against a model of the game. It does not
prove the real client behaves like the model: bindings, sound settings and loot events still
need a run in the game.
"""
import pathlib
import sys

import lupa.lua51 as lupa

ROOT = pathlib.Path(__file__).resolve().parent.parent
ADDON = ROOT / "Keepnet"
TESTS = ROOT / "tests"
TOC = ADDON / "Keepnet.toc"

# Globals the addon is meant to create
ALLOWED_GLOBALS = {
    "KeepnetDB",
    "SLASH_KEEPNET1",
    "SLASH_KEEPNET2",
    "Keepnet_OnAddonCompartmentClick",
    "Keepnet_OnAddonCompartmentEnter",
    "Keepnet_OnAddonCompartmentLeave",
    "KeepnetMinimapButton",
    "KeepnetCastButton",
    "KeepnetPanel",
    "KeepnetWindow",
    "KeepnetPicker",
    "KeepnetGearButton",
    "KeepnetRetroFont",  # the Windows 95 look's font: the game names every font an addon makes
    # Keepnet's copies of the game's fonts, for the font of its own looks
    "KeepnetGameFontHighlightSmall", "KeepnetGameFontNormalSmall", "KeepnetGameFontDisableSmall",
    "KeepnetGameFontNormal", "KeepnetGameFontHighlight", "KeepnetGameFontDisable",
    "KeepnetGameFontNormalLarge",
    "KeepnetWindowTab1", "KeepnetWindowTab2", "KeepnetWindowTab3", "KeepnetWindowTab4",
    "KeepnetWindowTab5", "KeepnetWindowTab6", "KeepnetWindowTab7",
}

# Globals the tests themselves create and remove (stand-ins for other addons)
TEST_GLOBALS = {"TSM_API", "AucAdvanced", "RECrystallize_PriceCheck", "OEMarketInfo", "AuxForeverAPI",
                "EllesmereUI"}


def toc_files():
    files = []
    for line in TOC.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if line and not line.startswith("#"):
            files.append(line.replace("\\", "/"))
    return files


def new_lua():
    lua = lupa.LuaRuntime(unpack_returned_tuples=True)
    compile_chunk = lua.eval(
        "function(source, name) "
        "local fn, err = loadstring(source, name) "
        "if not fn then error(err, 0) end "
        "return fn end"
    )

    def load(path, *args):
        return compile_chunk(path.read_text(encoding="utf-8"), "@" + path.name)(*args)

    return lua, load


def global_names(lua):
    return {str(key) for key in lua.globals()}


def check_files():
    """The TOC lists exactly the Lua files on disk, and each one compiles."""
    problems = []
    listed = set(toc_files())
    on_disk = {p.relative_to(ADDON).as_posix() for p in ADDON.rglob("*.lua")}
    for name in sorted(listed - on_disk):
        problems.append(f"TOC lists {name}, which doesn't exist")
    for name in sorted(on_disk - listed):
        problems.append(f"{name} exists but the TOC doesn't load it")
    lua, _ = new_lua()
    loadstring = lua.eval("loadstring")
    for name in sorted(on_disk):
        result = loadstring((ADDON / name).read_text(encoding="utf-8"), "@" + name)
        if isinstance(result, tuple) and result[0] is None:
            problems.append(f"syntax error: {result[1]}")
    return len(on_disk), problems


def run(test):
    lua, load = new_lua()
    load(TESTS / "wowstub.lua")
    stub = lua.globals().Stub
    scenario = load(test)
    if scenario.before:
        scenario.before()
    before = global_names(lua)

    def load_addon():
        ns = lua.table()
        for name in toc_files():
            load(ADDON / name, "Keepnet", ns)
        return ns

    stub.loadAddon = load_addon  # for Stub.reload()
    try:
        scenario.run(load_addon())
        crashed = None
    except lupa.LuaError as error:
        crashed = str(error)
    failures = [str(message) for message in stub.failed.values()]
    if crashed:
        failures.append("stopped by an error: " + crashed)
    leaked = sorted(global_names(lua) - before - ALLOWED_GLOBALS - TEST_GLOBALS)
    for name in leaked:
        failures.append(f"accidental global variable: {name}")
    missing = sorted(str(key) for key in stub.missing)
    return int(stub.passed), failures, missing


def main():
    ok = True
    count, problems = check_files()
    print(f"files: {count} Lua files, TOC and disk agree, all valid Lua 5.1"
          if not problems else "files: PROBLEMS")
    for problem in problems:
        ok = False
        print("  FAIL", problem)

    undefined = set()
    for test in sorted(TESTS.glob("test_*.lua")):
        passed, failures, missing = run(test)
        undefined.update(missing)
        print(f"{test.name}: {passed} checks passed, {len(failures)} failed")
        for failure in failures:
            ok = False
            print("  FAIL", failure)

    # For reading, not a failure: names the addon looked up that the stand-in game doesn't
    # define. Expected here are the old-client fallbacks; a misspelt game function would show
    # up in this list too.
    print("undefined globals read (old-client fallbacks expected):", ", ".join(sorted(undefined)) or "none")
    print("RESULT:", "all passed" if ok else "FAILED")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
