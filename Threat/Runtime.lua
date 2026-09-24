-- Current-target HUD lifecycle.
local _, addon = ...

function addon.StartThreat()

    local api, observer, hud = addon.UnitAPI, addon.ThreatObserver, addon.ThreatHud
    local driver = CreateFrame("Frame")
    local started, dirty, elapsedSinceRefresh = false, true, 0
    local inCombat, inWorld = false, true
    local watchingTarget = false

    local function Refresh()
        local snapshot = hud.Refresh()
        watchingTarget = snapshot.currentTarget ~= nil
        dirty, elapsedSinceRefresh = false, 0
        driver:SetShown(inCombat or watchingTarget)
    end

    local function Start()
        if started then return end
        started = true
        inCombat = UnitAffectingCombat("player") == true
        observer.Initialize({
            Now = GetTime,
            UnitAPI = api,
        })
        hud.Initialize({
            Observer = observer, UnitAPI = api,
            Now = GetTime,
        })
        Refresh()
    end

    local events = {
        "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "PLAYER_LEAVING_WORLD",
        "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED",
        "PLAYER_TARGET_CHANGED",
        "GROUP_ROSTER_UPDATE", "UNIT_TARGET", "UNIT_PET", "RAID_TARGET_UPDATE",
        "UNIT_FACTION", "UNIT_FLAGS", "UNIT_NAME_UPDATE",
        "UNIT_THREAT_LIST_UPDATE", "UNIT_THREAT_SITUATION_UPDATE",
        "UNIT_HEALTH", "UNIT_MAXHEALTH", "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_STOP",
        "UNIT_SPELLCAST_FAILED", "UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_DELAYED",
        "UNIT_SPELLCAST_CHANNEL_START", "UNIT_SPELLCAST_CHANNEL_UPDATE",
        "UNIT_SPELLCAST_CHANNEL_STOP", "UNIT_SPELLCAST_INTERRUPTIBLE",
        "UNIT_SPELLCAST_NOT_INTERRUPTIBLE",
    }
    for _, event in ipairs(events) do driver:RegisterEvent(event) end

    driver:SetScript("OnEvent", function(_, event, unit)
        if event == "PLAYER_LOGIN" then Start(); return end
        if not started then return end
        if not inWorld and event ~= "PLAYER_ENTERING_WORLD" then return end
        if event == "PLAYER_LEAVING_WORLD" then
            inWorld, watchingTarget = false, false
            observer.Reset()
            driver:Hide()
            hud.Hide()
            return
        elseif event == "PLAYER_ENTERING_WORLD" then
            inWorld = true
            observer.Reset()
            inCombat = UnitAffectingCombat("player") == true
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
        elseif event == "PLAYER_TARGET_CHANGED" then
            -- Clear cached ownership/identity before reusing the target token.
            -- Refresh synchronously so no old target accessories linger.
            Refresh()
            return
        end
        -- Coalesce bursty events; combat polling refreshes current-target threat.
        dirty = true
        driver:Show()
    end)

    driver:SetScript("OnUpdate", function(_, elapsed)
        if not started then return end
        elapsedSinceRefresh = elapsedSinceRefresh + elapsed
        -- Precombat data changes arrive through events. Keep combat polling for
        -- current-target threat freshness.
        if elapsedSinceRefresh >= 0.1 and (dirty or inCombat) then Refresh() end
        if inCombat or watchingTarget then hud.Tick(elapsed) end
    end)

end
