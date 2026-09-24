local addon = {}
assert(loadfile("UI/Style.lua"))("ApogeeTank", addon)
assert(loadfile("Threat/Hud.lua"))("ApogeeTank", addon)
local awareness = addon.ThreatHud
local function Enemy(guid, severity, control, isTanking, live)
    return {
        guid = guid, name = guid, severity = severity, control = control,
        isTanking = isTanking, live = live ~= false,
    }
end

local positive = awareness.GetControlDisplay(Enemy("safe", "safe", 41.6, true))
local negative = awareness.GetControlDisplay(Enemy("lost", "lost", -27.6, false))
local heldZero = awareness.GetControlDisplay(Enemy("held-zero", "critical", 0, true))
local lostZero = awareness.GetControlDisplay(Enemy("lost-zero", "lost", 0, false))
assert(positive.direction == "positive" and positive.progress == 41.6
        and negative.direction == "negative" and negative.progress == 27.6
        and heldZero.progress == 0 and lostZero.progress == 0
        and awareness.GetControlDisplay({ control = -40, live = false }) == nil,
    "directional tank-control display calculation changed")
assert(awareness.GetSmoothedControlWidth(nil, 40, 0.01) == 40
        and awareness.GetSmoothedControlWidth(0, 100, 0.02) == 48
        and awareness.GetSmoothedControlWidth(99.95, 100, 0.01) == 100
        and awareness.GetSmoothedControlWidth(40, nil, 0.01) == nil,
    "Tank Threat Control width interpolation changed")
local castDisplay = awareness.GetCastDisplay({ live = true, cast = {
    name = "Fireball", startTime = 10, endTime = 14,
} }, 11)
local channelDisplay = awareness.GetCastDisplay({ live = true, cast = {
    name = "Drain Life", startTime = 10, endTime = 14, isChannel = true,
    notInterruptible = true,
} }, 11)
assert(castDisplay and castDisplay.progress == 0.25 and castDisplay.name == "Fireball"
        and not castDisplay.isChannel and not castDisplay.notInterruptible
        and channelDisplay and channelDisplay.progress == 0.75
        and channelDisplay.isChannel and channelDisplay.notInterruptible
        and awareness.GetCastDisplay({ live = true, cast = {
            startTime = 10, endTime = 14,
        } }, 14) == nil
        and awareness.GetCastDisplay({ live = false, cast = {
            startTime = 10, endTime = 14,
        } }, 11) == nil,
    "Tank Threat Control cast and channel progress changed")
print("Forever threat direction, smoothing and cast display passed")
