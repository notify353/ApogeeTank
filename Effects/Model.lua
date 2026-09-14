-- No spell catalog: exact aura identities come only from observed game data.
-- Observe/GetMissing receive only player-owned auras from the read boundary.
local _, addon = ...
local Model = {}
addon.EffectsModel = Model

local function Identity(effect)
    if type(effect) ~= "table" then return nil end
    local id = tonumber(effect.spellId)
    if not id or id <= 0 or id ~= math.floor(id) then return nil end
    local name = type(effect.name) == "string" and effect.name or ("Effect " .. id)
    local icon = effect.icon
    if type(icon) ~= "number" and type(icon) ~= "string" then icon = nil end
    return { spellId = id, name = name, icon = icon }
end

function Model.Create(saved)
    local watched, ignored = {}, {}
    local store = { version = 2, watched = {}, ignored = {} }
    if type(saved) == "table" and type(saved.watched) == "table" then
        for _, raw in ipairs(saved.watched) do
            local effect = Identity(raw)
            if effect and not watched[effect.spellId] then
                store.watched[#store.watched + 1] = effect
                watched[effect.spellId] = effect
            end
        end
    end
    if type(saved) == "table" and type(saved.ignored) == "table" then
        for _, raw in ipairs(saved.ignored) do
            local effect = Identity(raw)
            if effect and not watched[effect.spellId] and not ignored[effect.spellId] then
                ignored[effect.spellId] = effect
                store.ignored[#store.ignored + 1] = effect
            end
        end
    end
    local self = {}
    function self.GetSaved() return store end
    function self.IsWatched(id) return watched[id] ~= nil end
    function self.Clear()
        watched, ignored = {}, {}
        -- Preserve the table owned by SavedVariables while clearing its contents.
        store.watched, store.ignored = {}, {}
    end
    function self.Observe(auras)
        for _, aura in ipairs(auras or {}) do
            local effect = Identity(aura)
            if effect then
                local id = effect.spellId
                if watched[id] then
                    watched[id].name, watched[id].icon = effect.name, effect.icon
                elseif ignored[id] then
                    ignored[id].name, ignored[id].icon = effect.name, effect.icon
                else
                    watched[id] = effect
                    store.watched[#store.watched + 1] = effect
                end
            end
        end
    end
    function self.SetWatched(id, value)
        if not value then
            if not watched[id] then return true end
            local effect = watched[id]
            watched[id] = nil
            for index, selected in ipairs(store.watched) do
                if selected.spellId == id then table.remove(store.watched, index); break end
            end
            ignored[id] = effect
            store.ignored[#store.ignored + 1] = effect
            return true
        end
        if watched[id] then return true end
        local effect = ignored[id]
        if not effect then return false, "Observe this effect on a target first." end
        effect = Identity(effect)
        ignored[id] = nil
        for index, disabled in ipairs(store.ignored) do
            if disabled.spellId == id then table.remove(store.ignored, index); break end
        end
        watched[id] = effect
        store.watched[#store.watched + 1] = effect
        return true
    end
    function self.GetEntries()
        local entries, remaining = {}, {}
        for _, effect in ipairs(store.watched) do
            local entry = Identity(effect); entry.watched = true
            entries[#entries + 1] = entry
        end
        for _, effect in ipairs(store.ignored) do
            remaining[#remaining + 1] = Identity(effect)
        end
        table.sort(remaining, function(a, b)
            if a.name ~= b.name then return a.name < b.name end
            return a.spellId < b.spellId
        end)
        for _, effect in ipairs(remaining) do entries[#entries + 1] = effect end
        return entries
    end
    function self.GetMissing(auras, validTarget)
        local result = {}
        if not validTarget or auras == nil then return result end
        local present = {}
        for _, aura in ipairs(auras) do present[aura.spellId or false] = true end
        for _, effect in ipairs(store.watched) do
            if not present[effect.spellId] then result[#result + 1] = Identity(effect) end
        end
        return result
    end
    return self
end
