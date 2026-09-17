local _, addon = ...
local DISCOVERY_WINDOW, UPDATE_INTERVAL = 10, 0.1

function addon.StartCooldowns(anchor)
    local driver = CreateFrame("Frame")
    local model, view
    local candidates, states = {}, {}
    local stances = {}
    local elapsed = 0
    local inCombat = false
    local initializationFailed = false
    local function UpdateStances()
        stances = addon.CooldownAPI.GetStanceSpells()
        for id in pairs(stances) do
            candidates[id], states[id] = nil, nil
            if model then model.Forget(id) end
        end
    end
    local entries, revision = {}, nil
    local function Entries()
        if model.GetRevision() ~= revision then
            entries, revision = model.GetEntries(), model.GetRevision()
        end
        return entries
    end
    local function Refresh()
        if not model then return end
        local now = GetTime()
        if inCombat then view.Render(Entries(), states, now)
        else view.Hide() end
        local active = next(candidates) ~= nil
        if inCombat and not active then
            for _, state in pairs(states) do
                if state.enabled and state.duration > 0
                    and state.start + state.duration > now then
                    active = true
                    break
                end
            end
        end
        driver:SetShown(active)
    end
    local function Sample(fromEvent)
        if not model then return end
        local now = GetTime()
        local sampled = {}
        for id, expires in pairs(candidates) do
            if expires <= now then
                candidates[id] = nil
            else
                local state = addon.CooldownAPI.Read(id, fromEvent)
                sampled[id] = state or false
                if state and state.realCooldown then
                    model.Observe({ state })
                    candidates[id] = nil
                end
            end
        end
        local nextStates = {}
        for _, entry in ipairs(Entries()) do
            local state
            if entry.watched then
                state = sampled[entry.spellId]
                if state == nil then state = addon.CooldownAPI.Read(entry.spellId, fromEvent) end
                if state == false then state = nil end
            end
            if state and state.gcdOnly then
                state.start, state.duration = 0, 0
            elseif state and not state.charges and state.enabled
                and state.duration > 0 and state.realCooldown == nil then
                -- Only active timers need GCD classification. Ready and held
                -- states are authoritative even outside a cooldown event.
                local previous = states[entry.spellId]
                if previous then
                    state.start, state.duration = previous.start, previous.duration
                else state = nil end
            end
            nextStates[entry.spellId] = state
        end
        states = nextStates
        Refresh()
    end
    driver:SetScript("OnEvent", function(_, event, unit, _, id)
        if initializationFailed then return end
        if event == "PLAYER_LOGIN" then
            inCombat = UnitAffectingCombat("player") == true
            local reason
            model, reason = addon.ObservedSpellList.Create(ApogeeTankCooldownsDB)
            if not model then
                initializationFailed = true
                driver:Hide()
                print("Apogee Tank: Cooldown tracking disabled. " .. reason)
                return
            end
            ApogeeTankCooldownsDB = model.GetSaved()
            view = addon.CooldownView.Create(anchor)
            UpdateStances()
            Sample(false)
        elseif event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
            inCombat = event == "PLAYER_REGEN_DISABLED"
            Sample(false)
        elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
            if model and unit == "player" and type(id) == "number" and not stances[id] then
                candidates[id] = GetTime() + DISCOVERY_WINDOW
                driver:Show()
            end
        elseif event == "PLAYER_LEAVING_WORLD" then
            inCombat = false
            candidates = {}
            driver:Hide()
            if view then view.Hide() end
        elseif event == "SPELL_UPDATE_COOLDOWN" or event == "SPELL_UPDATE_CHARGES" then
            Sample(event == "SPELL_UPDATE_COOLDOWN")
        elseif event == "PLAYER_ENTERING_WORLD" or event == "UPDATE_SHAPESHIFT_FORMS"
            or event == "SPELLS_CHANGED" then
            if event == "PLAYER_ENTERING_WORLD" then
                inCombat = UnitAffectingCombat("player") == true
            end
            UpdateStances()
            Sample(false)
        end
    end)
    for _, event in ipairs({ "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "PLAYER_LEAVING_WORLD",
        "UNIT_SPELLCAST_SUCCEEDED", "SPELL_UPDATE_COOLDOWN", "SPELL_UPDATE_CHARGES",
        "UPDATE_SHAPESHIFT_FORMS", "SPELLS_CHANGED",
        "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED" }) do
        driver:RegisterEvent(event)
    end
    driver:SetScript("OnUpdate", function(_, delta)
        elapsed = elapsed + delta
        if elapsed < UPDATE_INTERVAL then return end
        elapsed = 0
        local now = GetTime()
        for id, expires in pairs(candidates) do
            if expires <= now then candidates[id] = nil end
        end
        Refresh()
    end)
    driver:Hide()
    return {
        GetModel = function() return model end,
        -- Picker changes need fresh state; animation ticks only render caches.
        Refresh = function() Sample(false) end,
        Clear = function() candidates, states = {}, {}; Refresh() end,
    }
end
