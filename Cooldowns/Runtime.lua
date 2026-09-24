local _, addon = ...
local Access = addon.Access
local DISCOVERY_WINDOW, UPDATE_INTERVAL = 10, 0.1

function addon.StartCooldowns(anchor, getGeometry)
    local driver = CreateFrame("Frame")
    local model, view
    local candidates, states = {}, {}
    local stances = {}
    local rangeWatched, registeringRange = {}, false
    local elapsed = 0
    local inWorld = true
    local initializationFailed = false
    local changedHandler, notifiedRevision
    local function UpdateStances()
        stances = addon.CooldownAPI.GetStanceSpells()
        for id in pairs(stances) do
            candidates[id], states[id] = nil, nil
            if model then model.Forget(id) end
        end
    end
    local function SeedDefaults()
        if not model then return end
        for _, spell in ipairs(addon.CooldownAPI.GetDefaultSpells()) do
            local ignored = false
            for _, entry in ipairs(model.GetEntries()) do
                for _, id in ipairs(spell.ranks) do
                    if entry.spellId == id and not entry.watched then ignored = true end
                end
            end
            model.Observe({ spell })
            if ignored then model.SetWatched(spell.spellId, false) end
        end
    end
    local entries, revision = {}, nil
    local function Entries()
        if model.GetRevision() ~= revision then
            entries, revision = model.GetEntries(), model.GetRevision()
            local wanted = {}
            for _, entry in ipairs(entries) do if entry.watched then wanted[entry.spellId] = true end end
            registeringRange = true
            for id in pairs(rangeWatched) do
                if not wanted[id] then addon.CooldownAPI.WatchRange(id, false) end
            end
            for id in pairs(wanted) do
                if not rangeWatched[id] then addon.CooldownAPI.WatchRange(id, true) end
            end
            rangeWatched = wanted
            registeringRange = false
        end
        return entries
    end
    local function Refresh()
        if not model then return end
        local currentRevision = model.GetRevision()
        if currentRevision ~= notifiedRevision then
            notifiedRevision = currentRevision
            if changedHandler then changedHandler() end
        end
        local now = GetTime()
        if inWorld then view.Render(Entries(), states, now)
        else view.Hide() end
        local active = next(candidates) ~= nil
        if inWorld and not active then
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
                and state.duration > 0 and state.realCooldown == nil
                and state.coolingDown == nil then
                -- Unclassified activity cannot reuse old readiness. Retain only
                -- a confirmed timer that is still running, otherwise show unknown.
                local previous = states[entry.spellId]
                if previous and previous.enabled and previous.duration > 0
                    and previous.start + previous.duration > now then
                    previous.castable = state.castable
                    state = previous
                else state = nil end
            end
            nextStates[entry.spellId] = state
        end
        states = nextStates
        Refresh()
    end
    local function UpdateCastability()
        if not model then return end
        for _, entry in ipairs(Entries()) do
            local state = states[entry.spellId]
            if entry.watched and state and addon.CooldownAPI.Castable then
                state.castable = addon.CooldownAPI.Castable(entry.spellId)
            end
        end
        Refresh()
    end
    driver:SetScript("OnEvent", function(_, event, unit, _, id)
        if initializationFailed or registeringRange then return end
        if not inWorld and event ~= "PLAYER_ENTERING_WORLD" and event ~= "PLAYER_LOGIN" then return end
        if event == "PLAYER_LOGIN" then
            inWorld = true
            local reason
            model, reason = addon.ObservedSpellList.Create(ApogeeTankCooldownsDB)
            if not model then
                initializationFailed = true
                driver:Hide()
                print("Apogee Tank: Cooldown tracking disabled. " .. reason)
                return
            end
            ApogeeTankCooldownsDB = model.GetSaved()
            view = addon.CooldownView.Create(anchor, getGeometry)
            UpdateStances()
            SeedDefaults()
            Sample(false)
        elseif event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
            if event == "PLAYER_REGEN_ENABLED" then SeedDefaults() end
            Sample(false)
        elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
            if not Access.CanRead(unit, id) then return end
            if model and unit == "player" and type(id) == "number" and not stances[id] then
                candidates[id] = GetTime() + DISCOVERY_WINDOW
                driver:Show()
            end
        elseif event == "PLAYER_LEAVING_WORLD" then
            inWorld = false
            candidates = {}
            driver:Hide()
            if view then view.Hide() end
        elseif event == "SPELL_UPDATE_USABLE" or event == "SPELL_RANGE_CHECK_UPDATE"
            or event == "PLAYER_TARGET_CHANGED" then
            UpdateCastability()
        elseif event == "SPELL_UPDATE_COOLDOWN" or event == "SPELL_UPDATE_CHARGES" then
            Sample(event == "SPELL_UPDATE_COOLDOWN")
        elseif event == "PLAYER_ENTERING_WORLD" or event == "UPDATE_SHAPESHIFT_FORMS"
            or event == "SPELLS_CHANGED" then
            if event == "PLAYER_ENTERING_WORLD" then
                inWorld = true
            end
            UpdateStances()
            SeedDefaults()
            Sample(false)
        end
    end)
    for _, event in ipairs({ "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "PLAYER_LEAVING_WORLD",
        "UNIT_SPELLCAST_SUCCEEDED", "SPELL_UPDATE_COOLDOWN", "SPELL_UPDATE_CHARGES",
        "UPDATE_SHAPESHIFT_FORMS", "SPELLS_CHANGED",
        "SPELL_UPDATE_USABLE", "SPELL_RANGE_CHECK_UPDATE", "PLAYER_TARGET_CHANGED",
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
        SetChangedHandler = function(handler) changedHandler = handler end,
        -- Picker changes need fresh state; animation ticks only render caches.
        Refresh = function() Sample(false) end,
        Clear = function() candidates, states = {}, {}; Refresh() end,
    }
end
