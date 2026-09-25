local _, addon = ...
addon.SealSelection = {}

-- Persist family choices: true hides, false explicitly shows, nil uses defaults.
-- Learned ranks and artwork stay session-local.
function addon.SealSelection.Create(saved, canConfigure)
    local version = type(saved) == "table" and tonumber(saved.version)
    if version and version > 2 then
        return nil, "Saved seal data is newer than this addon; your data was preserved."
    end
    local store, entries, revision = { version = 2, hidden = {} }, {}, 0
    if type(saved) == "table" and type(saved.hidden) == "table" then
        for id, hidden in pairs(saved.hidden) do
            if type(id) == "number" and id > 0 and id == math.floor(id)
                and (hidden == true or (version == 2 and hidden == false)) then
                store.hidden[id] = hidden
            end
        end
    end
    -- Schema 1 erased opt-in provenance. An absent Crusader choice therefore
    -- migrates to the new default; schema 2 explicit opt-ins remain visible.
    if store.hidden[21082] == nil then store.hidden[21082] = true end
    local self = {}
    function self.GetSaved() return store end
    function self.GetRevision() return revision end
    function self.Reconcile(learned)
        local changed = #entries ~= #learned
        for index, entry in ipairs(learned) do
            local old = entries[index]
            if not old or old.spellId ~= entry.spellId or old.familyId ~= entry.familyId
                or old.name ~= entry.name or old.icon ~= entry.icon then changed = true end
        end
        if not changed then return end
        entries = {}
        for _, entry in ipairs(learned) do
            entries[#entries + 1] = { spellId = entry.spellId, familyId = entry.familyId,
                name = entry.name, icon = entry.icon }
        end
        revision = revision + 1
    end
    function self.IsWatched(id)
        for _, entry in ipairs(entries) do
            if entry.spellId == id then return not store.hidden[entry.familyId] end
        end
        return false
    end
    function self.SetWatched(id, value)
        if not canConfigure() then return false, "Seal choices can only change outside combat." end
        for _, entry in ipairs(entries) do
            if entry.spellId == id then
                local hidden = not value
                if store.hidden[entry.familyId] ~= hidden then
                    store.hidden[entry.familyId] = hidden
                    revision = revision + 1
                end
                return true
            end
        end
        return false, "Learn this seal before selecting it."
    end
    function self.GetEntries()
        local result = {}
        for _, entry in ipairs(entries) do
            result[#result + 1] = { spellId = entry.spellId, name = entry.name,
                icon = entry.icon, watched = not store.hidden[entry.familyId] }
        end
        return result
    end
    return self
end
