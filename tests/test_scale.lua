-- The window has a size slider of its own on the Appearance tab, apart from the live panel's.
local T = {}

function T.run(ns)
    Stub.login()
    ns.UI.Show("appearance")
    eq(KeepnetWindow:GetScale(), 1, "the window opens at its own size")
    local slider = ns.UI.scaleSlider
    check(slider ~= nil, "the Appearance tab has the slider")

    ns.settings.windowScale = 1.25
    ns.UI.ApplyScale()
    eq(KeepnetWindow:GetScale(), 1.25, "the window takes its own size")
    ns.settings.windowScale = 9
    ns.UI.ApplyScale()
    eq(KeepnetWindow:GetScale(), 1.5, "never past the largest")
    ns.settings.windowScale = 0.1
    ns.UI.ApplyScale()
    eq(KeepnetWindow:GetScale(), 0.7, "nor under the smallest")

    -- Letting go of the slider is what resizes the window
    ns.settings.windowScale = 0.9
    slider:GetScript("OnMouseUp")(slider)
    eq(KeepnetWindow:GetScale(), 0.9, "letting go of the slider resizes the window")

    -- The live panel's size is another setting and leaves the window alone
    ns.settings.panelScale = 1.4
    ns.UI.ApplyScale()
    eq(KeepnetWindow:GetScale(), 0.9, "the live panel's size doesn't size the window")
    check(ns.UI.panelScaleSlider ~= nil and ns.UI.panelScaleSlider ~= slider, "two sliders")

    -- And it is there again the next time the window opens
    ns.settings.windowScale = 1.1
    ns.UI.Toggle()
    ns.UI.Show("session")
    eq(KeepnetWindow:GetScale(), 1.1, "opening the window applies the saved size")
end

return T
