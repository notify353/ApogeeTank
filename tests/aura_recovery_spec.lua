-- A fresh observer proves recovery without a second aura-change event.
local addon = {}
assert(loadfile("Threat/Observer.lua"))("ApogeeTank", addon)
function UnitExists(unit) return unit == "player" or unit == "target" end
function UnitGUID(unit) return unit == "target" and "enemy" or "player" end
function UnitCanAttack(_, unit) return unit == "target" end
function UnitIsDeadOrGhost() return false end
function UnitName(unit) return unit end
function UnitDetailedThreatSituation(unit)
    if unit == "player" then return true, 3, 100 end
end

local observer = addon.ThreatObserver
local available, auras, reads = false, {}, 0
observer.Initialize({
    Now = function() return 10 end,
    Auras = { GetUnitHarmfulAuraSnapshot = function()
        reads = reads + 1
        if available then return { playerAuras = auras } end
    end },
})
assert(observer.Refresh().enemies[1].playerAuras == nil)
assert(observer.Refresh().enemies[1].playerAuras == nil and reads == 2,
    "unavailable reads must remain unknown and retry on the next refresh")
available = true
auras = { { spellId = 1, name = "Existing aura" } }
local recovered = observer.Refresh().enemies[1]
assert(recovered.playerAuras[1].spellId == 1 and reads == 3,
    "recovered aura read required an unrelated invalidation event")
observer.Refresh()
assert(reads == 3, "successful aura recovery was not cached")

-- A successful empty list is absence, not a reason to keep polling.
auras = {}
observer.InvalidateAuras("target")
assert(#observer.Refresh().enemies[1].playerAuras == 0 and reads == 4)
observer.Refresh()
assert(reads == 4, "successful empty aura lists must stay cached")
print("Unavailable aura recovery and successful-empty caching passed")
