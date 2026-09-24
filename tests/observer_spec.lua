local addon = {}
local now, target = 10, { guid = "first", hostile = true }
local secret = {}
function issecretvalue(value) return rawequal(value, secret) end
function canaccessvalue(value) return not issecretvalue(value) end
function UnitExists(unit) return unit == "target" and target ~= nil or unit == "player" or unit == "party1" end
function UnitCanAttack(_, unit) assert(unit == "target"); return target and target.hostile end
function UnitIsDeadOrGhost() return target and target.dead == true end
function UnitCreatureType() return "Humanoid", 7 end
function UnitGUID(unit) assert(unit == "target"); return target.guid end
function UnitName() return target.name or target.guid end
function GetRaidTargetIndex() return target.marker end
local held, challenger, progress, restricted = true, 60, 100, false
local calls = 0
function UnitDetailedThreatSituation(unit, mob)
    assert(mob == "target", "observed a secondary enemy")
    calls = calls + 1
    if restricted and unit == "party1" then return secret end
    if progress == nil then return nil end
    if unit == "player" then return held, held and 3 or 1, progress end
    return not held, 1, challenger
end
for _, path in ipairs({ "Core/Access.lua", "Threat/Observer.lua" }) do assert(loadfile(path))("ApogeeTank", addon) end
local observer = addon.ThreatObserver
observer.Initialize({ Now = function() return now end, UnitAPI = { GetCast = function() return nil end } })
local snapshot = observer.Refresh()
assert(snapshot.total == 1 and snapshot.currentTarget == snapshot.enemies[1] and calls == 2)
assert(snapshot.currentTarget.control == 40 and snapshot.currentTarget.severity == "safe")
challenger = 95
assert(observer.Refresh().currentTarget.severity == "critical")
challenger = 80
assert(observer.Refresh().currentTarget.severity == "slipping")
held, progress = false, 45
assert(observer.Refresh().currentTarget.control == -55 and observer.GetSnapshot().currentTarget.severity == "lost")
restricted = true
assert(observer.Refresh().currentTarget.control == nil and observer.GetSnapshot().currentTarget.severity == "unknown")
restricted, progress = false, nil
assert(observer.Refresh().currentTarget.severity == "unknown", "precombat absence faked safety")
target = { guid = "second", hostile = true, name = "Second", marker = 8 }
assert(observer.Refresh().currentTarget.guid == "second" and observer.GetSnapshot().total == 1)
snapshot = observer.GetSnapshot(); snapshot.currentTarget.guid = "mutated"
assert(observer.GetSnapshot().currentTarget.guid == "second", "snapshot exposed internal state")
target.guid = secret
assert(observer.Refresh().total == 0, "unreadable identity retained previous enemy")
target.guid, target.dead = "second", true
assert(observer.Refresh().total == 0)
target.dead, target.hostile = false, false
assert(observer.Refresh().total == 0)
target = nil
assert(observer.Refresh().total == 0)
observer.Reset()
assert(observer.GetSnapshot().total == 0)
assert(not observer.OnNamePlateAdded and not observer.InvalidateAuras, "obsolete observer features remain")
print("Forever target-only observation, neutral unknown threat and identity isolation passed")

target = { guid = "uncertain", hostile = true }
function UnitIsDeadOrGhost() return secret end
assert(observer.Refresh().total == 0, "unknown death status treated as alive")
function UnitIsDeadOrGhost() error("temporarily unavailable") end
assert(observer.Refresh().total == 0, "failed death read treated as alive")
function UnitIsDeadOrGhost() return false end
assert(observer.Refresh().total == 1, "target did not recover from unavailable death read")
