local _, addon = ...

function addon.StartEffects(deps)
    local driver = CreateFrame("Frame")
    local model, view, pendingToggle
    local dirty, elapsedSinceEvent = false, 0
    local needsObservation = false
    local inCombat = false
    local initializationFailed = false
    local function CanConfigure()
        return not inCombat and not InCombatLockdown() and not UnitAffectingCombat("player")
    end
    local function RequestRefresh(observe)
        if initializationFailed then return end
        if observe == true then needsObservation = true end
        dirty = true
        driver:Show()
    end
    local function OpenFromHealthBar(button)
        if button ~= "LeftButton" or not IsShiftKeyDown()
            or IsControlKeyDown() or IsAltKeyDown() or not CanConfigure() then return end
        pendingToggle = true
        RequestRefresh()
    end
    local function UpdateAccess()
        deps.SetPlayerClickHandler(CanConfigure() and OpenFromHealthBar or nil)
        if not CanConfigure() then
            pendingToggle = false
            if view then view.Close() end
        end
    end
    local function Refresh()
        if not model then return end
        UpdateAccess()
        if not view then
            view = addon.EffectsView.Create({
                Model = model, Cooldowns = deps.Cooldowns,
                OnChanged = RequestRefresh, CanConfigure = CanConfigure,
                OnCleared = function()
                    -- Stay empty until a new gameplay observation, rather than
                    -- immediately rediscovering the unchanged target.
                    dirty, pendingToggle, needsObservation = false, false, false
                    driver:Hide()
                end,
                OnVisibility = function(shown)
                    deps.SetDemo(shown, model.GetEntries)
                end,
            })
        end
        if needsObservation then
            local valid = UnitExists("target") and UnitCanAttack("player", "target")
                and not UnitIsDeadOrGhost("target")
            local auras = valid and addon.Auras.ReadPlayerHarmful("target") or nil
            if auras then model.Observe(auras) end
        end
        local presentations = {}
        for _, row in ipairs(deps.GetRows()) do
            presentations[#presentations + 1] = {
                anchor = row.anchor, missingAnchor = row.missingAnchor, guid = row.guid,
                missing = row.demoMissing or model.GetMissing(row.playerAuras, row.live),
            }
        end
        view.Render(presentations)
        if pendingToggle then
            pendingToggle = false
            if CanConfigure() then view.Toggle() end
        end
        dirty, needsObservation = false, false
        driver:Hide()
    end
    driver:SetScript("OnEvent", function(_, event, unit)
        if initializationFailed then return end
        if event == "PLAYER_LOGIN" and not model then
            local reason
            model, reason = addon.EffectsModel.Create(ApogeeTankEffectsDB)
            if not model then
                initializationFailed = true
                deps.SetPlayerClickHandler(nil)
                driver:Hide()
                print("Apogee Tank: Debuff reminders and picker disabled. " .. reason)
                return
            end
            ApogeeTankEffectsDB = model.GetSaved()
        elseif event == "PLAYER_ENTERING_WORLD" then
            inCombat = UnitAffectingCombat("player") == true
        elseif event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
            inCombat = event == "PLAYER_REGEN_DISABLED"
            UpdateAccess()
            RequestRefresh()
            return
        elseif event == "PLAYER_LEAVING_WORLD" then
            if view then view.Hide() end
            dirty, pendingToggle, needsObservation = false, false, false
            driver:Hide()
            deps.SetPlayerClickHandler(nil)
            return
        elseif event == "UNIT_AURA" or event == "UNIT_HEALTH"
            or event == "UNIT_FACTION" or event == "UNIT_FLAGS" then
            if not unit or not UnitIsUnit(unit, "target") then return end
        end
        RequestRefresh(event == "UNIT_AURA" or event == "PLAYER_TARGET_CHANGED"
            or event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD")
    end)
    for _, event in ipairs({ "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD",
        "PLAYER_LEAVING_WORLD", "PLAYER_TARGET_CHANGED", "UNIT_AURA", "UNIT_HEALTH",
        "UNIT_FACTION", "UNIT_FLAGS", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED" }) do
        driver:RegisterEvent(event)
    end
    driver:SetScript("OnUpdate", function(_, elapsed)
        if not dirty then driver:Hide(); return end
        elapsedSinceEvent = elapsedSinceEvent + elapsed
        if elapsedSinceEvent < 0.05 then return end
        elapsedSinceEvent = 0
        Refresh()
    end)
    deps.SetRowsChangedHandler(function()
        -- Update accessories with the row assignment itself, so a recycled row
        -- never temporarily displays the previous enemy's missing effects.
        RequestRefresh()
        if model then Refresh() end
    end)
    driver:Hide()
end
