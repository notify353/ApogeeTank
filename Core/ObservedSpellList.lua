-- Shared exact spell identities, selections and character persistence.
-- Features decide what observations qualify and how selections are used.
local _, addon = ...
local Model = {}
addon.ObservedSpellList = Model
local SCHEMA_VERSION = 3

local function Identity(effect)
    if type(effect) ~= "table" then return nil end
    local id = tonumber(effect.spellId)
    if not id or id <= 0 or id ~= math.floor(id) then return nil end
    local name = type(effect.name) == "string" and effect.name or ("Spell " .. id)
    local icon = effect.icon
    if type(icon) ~= "number" and type(icon) ~= "string" then icon = nil end
    return { spellId = id, name = name, icon = icon, explicit = effect.explicit == true or nil }
end

function Model.Create(saved)
    local version = type(saved) == "table" and tonumber(saved.version)
    if version and version > SCHEMA_VERSION then
        return nil, "Saved data is newer than this addon. Update Apogee Tank to use it; your data was preserved."
    end
    local watched, ignored = {}, {}
    local store = { version = SCHEMA_VERSION, watched = {}, ignored = {} }
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
                -- Before schema 3, ignored identities were user opt-outs (or
                -- inherited rank opt-outs), not automatic default-off choices.
                if not version or version < 3 then effect.explicit = true end
                ignored[effect.spellId] = effect
                store.ignored[#store.ignored + 1] = effect
            end
        end
    end
    local self = {}
    local revision = 0
    function self.GetRevision() return revision end
    function self.GetSaved() return store end
    function self.IsWatched(id) return watched[id] ~= nil end
    function self.Forget(id)
        if not watched[id] and not ignored[id] then return end
        watched[id], ignored[id] = nil, nil
        for _, list in ipairs({ store.watched, store.ignored }) do
            for index = #list, 1, -1 do
                if list[index].spellId == id then table.remove(list, index) end
            end
        end
        revision = revision + 1
    end
    function self.Clear()
        revision = revision + 1
        watched, ignored = {}, {}
        -- Preserve the table owned by SavedVariables while clearing its contents.
        store.watched, store.ignored = {}, {}
    end
    function self.Observe(spells)
        for _, spell in ipairs(spells or {}) do
            local effect = Identity(spell)
            if effect then
                local id = effect.spellId
                if watched[id] then
                    if watched[id].name ~= effect.name or watched[id].icon ~= effect.icon then revision = revision + 1 end
                    watched[id].name, watched[id].icon = effect.name, effect.icon
                elseif ignored[id] then
                    if ignored[id].name ~= effect.name or ignored[id].icon ~= effect.icon then revision = revision + 1 end
                    ignored[id].name, ignored[id].icon = effect.name, effect.icon
                else
                    revision = revision + 1
                    watched[id] = effect
                    store.watched[#store.watched + 1] = effect
                end
            end
        end
    end
    function self.SetWatched(id, value, automatic)
        local choice = watched[id] or ignored[id]
        if choice and not automatic and not choice.explicit then
            choice.explicit = true
            revision = revision + 1
        end
        if not value then
            if not watched[id] then return true end
            local effect = watched[id]
            revision = revision + 1
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
        if not effect then return false, "Observe this spell before selecting it." end
        effect = Identity(effect)
        revision = revision + 1
        ignored[id] = nil
        for index, disabled in ipairs(store.ignored) do
            if disabled.spellId == id then table.remove(store.ignored, index); break end
        end
        watched[id] = effect
        store.watched[#store.watched + 1] = effect
        return true
    end
    function self.GetWatched()
        local entries = {}
        for _, effect in ipairs(store.watched) do
            local entry = Identity(effect); entry.watched = true
            entries[#entries + 1] = entry
        end
        return entries
    end
    -- Reorder only the named selections, keeping every other slot and opt-out.
    function self.OrderWatched(ids)
        local ordered, included = {}, {}
        for _, id in ipairs(ids) do
            if watched[id] and not included[id] then
                ordered[#ordered + 1], included[id] = watched[id], true
            end
        end
        local nextIndex, changed = 1, false
        for index, effect in ipairs(store.watched) do
            if included[effect.spellId] then
                if effect ~= ordered[nextIndex] then changed = true end
                store.watched[index] = ordered[nextIndex]
                nextIndex = nextIndex + 1
            end
        end
        if changed then revision = revision + 1 end
    end
    function self.GetEntries()
        local entries, remaining = self.GetWatched(), {}
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
    return self
end
