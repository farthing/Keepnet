-- Text says good, careful and bad in the colours of the colour blind set chosen for the bobber
-- mark: green, yellow and red only while none is chosen.
local T = {}

function T.run(ns)
    Stub.login()
    local Waters = ns.Waters
    eq(ns.Tone("ok") .. ns.Tone("some") .. ns.Tone("none"), "40ff40ffd100ff6060", "no set chosen: green, yellow, red")
    eq(Waters.COLORS.ok, "40ff40", "the zone skill uses the same")

    local seen = {}
    for _, key in ipairs({ "protanopia", "deuteranopia", "tritanopia", "mono" }) do
        ns.settings.bobberPalette = key
        local ok, some, none = ns.Tone("ok"), ns.Tone("some"), ns.Tone("none")
        check(#ok == 6 and #some == 6 and #none == 6, key .. ": three colours")
        check(ok ~= some and some ~= none and ok ~= none, key .. ": all different")
        check(ok ~= "40ff40" and none ~= "ff6060", key .. ": not the green and red")
        eq(Waters.COLORS[Waters.Standing(300, 300)], ok, key .. ": the zone skill follows")
        seen[key] = ok
    end
    check(seen.tritanopia ~= seen.protanopia, "the sets differ")

    ns.settings.bobberPalette = "game"
    eq(ns.Tone("ok"), "40ff40", "the game's own mode, when it has none on: green")
    ns.settings.bobberPalette = "no such set"
    eq(ns.Tone("ok"), "40ff40", "an unknown choice falls back")
    eq(ns.Tone("no such kind"), "ffffff", "and an unknown kind is white")
    ns.settings.bobberPalette = "normal"
end

return T
