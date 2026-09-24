-- Current-target observation; restricted reads never become guessed threat.
local _, addon = ...
local Access = addon.Access
local UnitExists = Access.Global("UnitExists")
local UnitCreatureType = Access.Global("UnitCreatureType")
local UnitCanAttack = Access.Global("UnitCanAttack")
local UnitIsDeadOrGhost = Access.Global("UnitIsDeadOrGhost")
local UnitGUID = Access.Global("UnitGUID")
local GetRaidTargetIndex = Access.Global("GetRaidTargetIndex")
local O = {}
addon.ThreatObserver = O
local nowFn = function() return GetTime() end
local unitAPI
local TOTEM_CREATURE_TYPE_ID = 11
local CHALLENGER_UNITS = {
    "player", "party1", "party2", "party3", "party4",
    "pet", "partypet1", "partypet2", "partypet3", "partypet4",
}


local function NewSnapshot(limitedCoverage, refreshedAt)
    return {
        enemies = {},
        counts = { safe = 0, slipping = 0, critical = 0, lost = 0 },
        total = 0,
        limitedCoverage = limitedCoverage == true,
        refreshedAt = refreshedAt,
    }
end

local snapshot = NewSnapshot(true)

local function DeepCopy(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local result = {}
    seen[value] = result
    for key, child in pairs(value) do result[DeepCopy(key, seen)] = DeepCopy(child, seen) end
    return result
end

local function IsTotem(unit)
    if not UnitCreatureType then return false end
    local _, creatureTypeID = UnitCreatureType(unit)
    return creatureTypeID == TOTEM_CREATURE_TYPE_ID
end

local function IsHostileLiving(unit)
    return UnitExists and UnitExists(unit) == true
        and UnitCanAttack and UnitCanAttack("player", unit) == true
        and UnitIsDeadOrGhost and UnitIsDeadOrGhost(unit) == false
        and not IsTotem(unit)
end

function O.GetThreatDetails(mobUnit, activeChallengers, assumeValidMob)
    local details = {}
    if not UnitDetailedThreatSituation
        or (not assumeValidMob and not IsHostileLiving(mobUnit)) then
        return details
    end
    for _, unit in ipairs(activeChallengers or CHALLENGER_UNITS) do
        if activeChallengers or UnitExists(unit) then
            local readable, isTanking, status, scaledPercent, rawPercent, rawThreat =
                Access.Try(UnitDetailedThreatSituation, unit, mobUnit)
            -- A hidden challenger cannot be treated as zero threat.
            if not readable then return {}, true end
            if type(scaledPercent) == "number" then
                details[unit] = {
                    isTanking = isTanking == true,
                    status = status,
                    scaledPercent = scaledPercent,
                    rawPercent = rawPercent,
                    rawThreat = rawThreat,
                }
            end
        end
    end
    return details
end

local function GetClosestChallenger(details)
    local closest = 0
    for unit, detail in pairs(details) do
        if unit ~= "player" then closest = math.max(closest, detail.scaledPercent or 0) end
    end
    return closest
end

local function BuildEnemy(unit, guid, now, activeChallengers)
    local details, unavailable = O.GetThreatDetails(unit, activeChallengers, true)
    local threatKnown = not unavailable and next(details) ~= nil
    local player = details.player
    local isTanking = player and player.isTanking == true or false
    local control
    if isTanking then
        control = math.max(0, math.min(100, 100 - GetClosestChallenger(details)))
    elseif threatKnown then
        local recoveryProgress = player and math.max(0, math.min(100,
            player.scaledPercent or 0)) or 0
        control = -(100 - recoveryProgress)
    end
    local severity
    if not threatKnown then
        severity = "unknown"
    elseif not isTanking then
        severity = "lost"
    elseif control <= 10 then
        severity = "critical"
    elseif control <= 30 then
        severity = "slipping"
    else
        severity = "safe"
    end

    local cast
    if unitAPI and type(unitAPI.GetCast) == "function" then
        cast = unitAPI.GetCast(unit)
    end
    return {
        guid = guid,
        unit = unit,
        raidMarker = GetRaidTargetIndex and GetRaidTargetIndex(unit) or nil,
        isTanking = isTanking,
        control = control,
        severity = severity,
        lastSeen = now,
        live = true,
        stale = false,
        cast = cast,
    }
end

function O.Refresh()
    local nextSnapshot = NewSnapshot(true, nowFn())
    -- Rebuild from the literal target each time. There is no retained enemy queue
    -- or last-seen identity to leak through a target switch or restricted GUID.
    if IsHostileLiving("target") then
        local guid = UnitGUID and UnitGUID("target")
        if guid then
            local challengers = {}
            for _, unit in ipairs(CHALLENGER_UNITS) do
                if UnitExists and UnitExists(unit) then challengers[#challengers + 1] = unit end
            end
            local enemy = BuildEnemy("target", guid, nextSnapshot.refreshedAt, challengers)
            nextSnapshot.currentTarget = enemy
            nextSnapshot.enemies[1] = enemy
            nextSnapshot.total = 1
            nextSnapshot.counts[enemy.severity] = 1
            nextSnapshot.worst = enemy
        end
    end
    snapshot = nextSnapshot
    return O.GetSnapshot()
end

function O.GetSnapshot() return DeepCopy(snapshot) end
function O.Initialize(deps)
    nowFn, unitAPI = deps.Now, deps.UnitAPI
end
function O.Reset() snapshot = NewSnapshot(true) end
