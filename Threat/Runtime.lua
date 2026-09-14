-- Classic Era only. One fixed HUD, no SavedVariables or configuration surface.
local _, addon = ...

function addon.StartThreat()

    local api, observer, hud = addon.UnitAPI, addon.ThreatObserver, addon.ThreatHud
    local driver = CreateFrame("Frame")
    local started, dirty, elapsedSinceRefresh = false, true, 0
    local inCombat = false

    local function GetUnitHarmfulAuraSnapshot(unit)
        local auras = addon.Auras.ReadPlayerHarmful(unit)
        if auras == nil then return nil end
        return { playerAuras = auras }
    end

    local function SeedNameplates()
        for _, plate in ipairs(C_NamePlate.GetNamePlates()) do
            observer.OnNamePlateAdded(plate.namePlateUnitToken)
        end
    end

    local function Refresh()
        hud.Refresh()
        dirty, elapsedSinceRefresh = false, 0
    end

    local function Start()
        if started then return end
        started = true
        inCombat = UnitAffectingCombat("player") == true
        observer.Initialize({
            Now = GetTime,
            UnitAPI = api,
            Auras = { GetUnitHarmfulAuraSnapshot = GetUnitHarmfulAuraSnapshot },
            DebuffData = addon.ThreatDebuffData,
            GetClassToken = function() return select(2, UnitClass("player")) end,
        })
        hud.Initialize({
            Observer = observer, UnitAPI = api, UnitBar = api,
            Now = GetTime, IsInCombat = function() return inCombat end,
        })
        SeedNameplates()
        Refresh()
    end

    local events = {
        "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "PLAYER_LEAVING_WORLD",
        "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED",
        "PLAYER_TARGET_CHANGED", "PLAYER_FOCUS_CHANGED", "UPDATE_MOUSEOVER_UNIT",
        "GROUP_ROSTER_UPDATE", "UNIT_TARGET", "UNIT_PET", "RAID_TARGET_UPDATE",
        "NAME_PLATE_UNIT_ADDED", "NAME_PLATE_UNIT_REMOVED",
        "UNIT_THREAT_LIST_UPDATE", "UNIT_THREAT_SITUATION_UPDATE", "UNIT_AURA",
        "UNIT_HEALTH", "UNIT_MAXHEALTH", "UNIT_POWER_FREQUENT", "UNIT_MAXPOWER",
        "UNIT_DISPLAYPOWER", "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_STOP",
        "UNIT_SPELLCAST_FAILED", "UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_DELAYED",
        "UNIT_SPELLCAST_CHANNEL_START", "UNIT_SPELLCAST_CHANNEL_UPDATE",
        "UNIT_SPELLCAST_CHANNEL_STOP", "UNIT_SPELLCAST_INTERRUPTIBLE",
        "UNIT_SPELLCAST_NOT_INTERRUPTIBLE",
    }
    for _, event in ipairs(events) do driver:RegisterEvent(event) end

    driver:SetScript("OnEvent", function(_, event, unit)
        if event == "PLAYER_LOGIN" then Start(); return end
        if not started then return end
        if event == "PLAYER_LEAVING_WORLD" then
            observer.Reset()
            driver:Hide()
            hud.Hide()
            return
        elseif event == "PLAYER_ENTERING_WORLD" then
            observer.Reset()
            inCombat = UnitAffectingCombat("player") == true
            SeedNameplates()
            driver:Show()
            Refresh()
            return
        elseif event == "PLAYER_REGEN_DISABLED" then
            inCombat = true
            Refresh()
            return
        elseif event == "PLAYER_REGEN_ENABLED" then
            inCombat = false
            Refresh()
            return
        elseif event == "NAME_PLATE_UNIT_ADDED" then
            observer.OnNamePlateAdded(unit)
        elseif event == "NAME_PLATE_UNIT_REMOVED" then
            observer.OnNamePlateRemoved(unit)
        elseif event == "UNIT_AURA" then
            observer.InvalidateAuras(unit)
        end
        if unit == "player" then hud.RefreshPlayer() end
        -- Coalesce bursty unit events; polling also covers target-chain changes
        -- and ends the original observer's short last-seen retention window.
        dirty = true
    end)

    driver:SetScript("OnUpdate", function(_, elapsed)
        if not started then return end
        elapsedSinceRefresh = elapsedSinceRefresh + elapsed
        if elapsedSinceRefresh >= 0.1 and (dirty or inCombat) then Refresh() end
        if inCombat then hud.Tick(elapsed) end
    end)

end
