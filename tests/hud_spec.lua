local addon = {}
assert(loadfile("Threat/Hud.lua"))("ApogeeTank", addon)
local awareness = addon.ThreatHud
local healthProgress, powerProgress, powerChannel = awareness.GetPlayerStatusDisplay(
    72, 100, true, { { value = 58, maximum = 100, powerToken = "MANA" } })
assert(healthProgress == 0.72 and powerProgress == 0.58
        and powerChannel.powerToken == "MANA"
        and awareness.GetPlayerStatusDisplay(10, 0, false, {}) == nil,
    "Tank Threat Control player-status normalization changed")

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
assert(awareness.GetHealthDisplay({ live = true, health = 75, healthMaximum = 100,
            healthValid = true }) == 0.75
        and awareness.GetHealthDisplay({ live = true, health = 150, healthMaximum = 100,
            healthValid = true }) == 1
        and awareness.GetHealthDisplay({ live = true, health = -10, healthMaximum = 100,
            healthValid = true }) == 0
        and awareness.GetHealthDisplay({ live = false, health = 75, healthMaximum = 100,
            healthValid = true }) == nil
        and awareness.GetHealthDisplay({ live = true, health = 75, healthMaximum = 0,
            healthValid = true }) == nil,
    "Tank Threat Control health-strip normalization changed")
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
-- Fill five additional stable slots so overflow cases exercise the ten-row cap.
local function Expand(snapshot)
    for i = 1, 5 do table.insert(snapshot.enemies, #snapshot.enemies,
        Enemy("extra-" .. i, "safe", 30, true)) end
    snapshot.total = snapshot.total + 5
    return snapshot
end
local function Previous(slots)
    for i = 1, 5 do slots[#slots + 1] = "extra-" .. i end
    return slots
end
local initial = {
    total = 6,
    enemies = {
        Enemy("lost", "lost", -60, false),
        Enemy("critical", "critical", 5, true),
        Enemy("slipping", "slipping", 20, true),
        Enemy("safe-a", "safe", 40, true),
        Enemy("safe-b", "safe", 50, true),
        Enemy("safe-c", "safe", 70, true),
    },
}
local first = awareness.ReconcileQueue(Expand(initial), {})
assert(first.visible == 10 and first.overflow == 1
        and first.slotGuids[1] == "lost" and first.slotGuids[5] == "safe-b",
    "initial tank-control queue did not select the ten most urgent enemies")

local changed = {
    total = 6,
    enemies = {
        Enemy("safe-c", "critical", 2, true),
        Enemy("safe-b", "safe", 80, true),
        Enemy("safe-a", "safe", 65, true),
        Enemy("slipping", "slipping", 12, true),
        Enemy("critical", "safe", 55, true),
        Enemy("lost", "lost", -10, false),
    },
}
local stable = awareness.ReconcileQueue(Expand(changed), first.slotGuids)
for index = 1, 10 do
    assert(stable.slotGuids[index] == first.slotGuids[index],
        "ordinary threat changes reordered a stable queue slot")
end

changed.total = 10
table.remove(changed.enemies, 5) -- Remove the former "critical" enemy.
local filled = awareness.ReconcileQueue(changed, stable.slotGuids)
assert(filled.slotGuids[2] == "safe-c"
        and filled.slotGuids[1] == "lost" and filled.slotGuids[3] == "slipping",
    "vacated queue slot was not filled without shifting retained enemies")

local overflowLoss = {
    total = 6,
    enemies = {
        Enemy("a", "critical", 5, true), Enemy("b", "slipping", 20, true),
        Enemy("c", "safe", 35, true), Enemy("d", "safe", 60, true),
        Enemy("e", "safe", 80, true), Enemy("hidden-lost", "lost", -75, false),
    },
}
local promoted = awareness.ReconcileQueue(Expand(overflowLoss), Previous({ "a", "b", "c", "d", "e" }))
assert(promoted.slotGuids[5] == "hidden-lost" and promoted.overflow == 1
        and promoted.slotGuids[1] == "a" and promoted.slotGuids[4] == "d",
    "hidden lost enemy did not replace the safest visible held enemy in place")

local staleOverflow = {
    total = 6,
    enemies = {
        Enemy("stale-lost", "lost", nil, false, false),
        Enemy("held-a", "critical", 5, true), Enemy("held-b", "slipping", 20, true),
        Enemy("held-c", "safe", 40, true), Enemy("held-d", "safe", 60, true),
        Enemy("live-lost", "lost", -70, false),
    },
}
local staleReplaced = awareness.ReconcileQueue(Expand(staleOverflow),
    Previous({ "stale-lost", "held-a", "held-b", "held-c", "held-d" }))
assert(staleReplaced.slotGuids[1] == "live-lost"
        and staleReplaced.slotGuids[5] == "held-d",
    "hidden live loss did not replace a non-live last-seen warning first")

local staleVacancy = {
    total = 6,
    enemies = {
        Enemy("hidden-stale", "lost", nil, false, false),
        Enemy("visible-a", "critical", 5, true), Enemy("visible-b", "slipping", 20, true),
        Enemy("visible-c", "safe", 40, true), Enemy("visible-d", "safe", 60, true),
        Enemy("hidden-live", "safe", 80, true),
    },
}
local liveFilled = awareness.ReconcileQueue(staleVacancy,
    { "visible-a", "visible-b", "visible-c", "visible-d", "resolved" })
assert(liveFilled.slotGuids[5] == "hidden-live",
    "vacant queue slot preferred a stale warning over an observable enemy")

local empty = awareness.ReconcileQueue({ enemies = {}, total = 0 }, promoted.slotGuids)
assert(empty.visible == 0 and empty.overflow == 0 and next(empty.slotGuids) == nil,
    "empty pack did not reset stable queue slots")

assert(awareness.IsCurrentTarget({ guid = "enemy-1" }, "enemy-1")
        and not awareness.IsCurrentTarget({ guid = "enemy-2" }, "enemy-1")
        and awareness.IsCurrentTarget({ isCurrentTarget = true }, nil)
        and not awareness.IsCurrentTarget(nil, "enemy-1"),
    "Tank Threat Control current-target matching changed")
assert(awareness.GetEnemyName({ name = "Dark Iron Bombardier" }) == "Dark Iron Bombardier"
        and awareness.GetEnemyName({}) == "Enemy",
    "Tank Threat Control enemy names are being artificially truncated")
local left, right, top, bottom = awareness.GetRaidMarkerTexCoords(8)
assert(left == 0.75 and right == 1 and top == 0.5 and bottom == 1,
    "Tank Threat Control fallback raid-marker atlas coordinates changed")


print("HUD regression tests passed")
