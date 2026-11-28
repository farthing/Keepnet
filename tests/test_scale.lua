-- One size for both: the Scale slider on the Appearance tab sizes the live panel and the window.
local T = {}

function T.run(ns)
    Stub.login()
    ns.UI.Show("appearance")
    eq(KeepnetWindow:GetScale(), 1, "the window opens at its own size")
    local slider = ns.UI.scaleSlider
    check(slider ~= nil, "the Appearance tab has the slider")

    ns.settings.panelScale = 1.25
    ns.UI.ApplyScale()
    eq(KeepnetWindow:GetScale(), 1.25, "the window takes the size the panel has")
    ns.settings.panelScale = 9
    ns.UI.ApplyScale()
    eq(KeepnetWindow:GetScale(), 1.5, "never past the largest")
    ns.settings.panelScale = 0.1
    ns.UI.ApplyScale()
    eq(KeepnetWindow:GetScale(), 0.7, "nor under the smallest")

    -- Letting go of the slider is what resizes the window
    ns.settings.panelScale = 0.9
    slider:GetScript("OnMouseUp")(slider)
    eq(KeepnetWindow:GetScale(), 0.9, "letting go of the slider resizes the window")

    -- And it is there again the next time the window opens
    ns.settings.panelScale = 1.1
    ns.UI.Toggle()
    ns.UI.Show("session")
    eq(KeepnetWindow:GetScale(), 1.1, "opening the window applies the saved size")
end

return T
