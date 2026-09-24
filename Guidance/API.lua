local _, addon = ...
local A, M = addon.Access, addon.Guidance
local API = {}
addon.GuidanceAPI = API
function API.Role()
    return M.Role(A.Call(UnitGroupRolesAssigned, "player"))
end
function API.Learn()
    if InCombatLockdown() then return end
    local book, spells = C_SpellBook, C_Spell
    if not book or not spells or not Enum or not Enum.SpellBookSpellBank then return end
    local names, known = {}, {}
    for key, id in pairs(M.families) do
        local info = A.Call(spells.GetSpellInfo, id)
        if A.Fields(info, { "name" }) and type(info.name) == "string" then names[info.name] = key end
    end
    local count = A.Call(book.GetNumSpellBookSkillLines)
    if type(count) ~= "number" then return end
    for line = 1, count do
        local info = A.Call(book.GetSpellBookSkillLineInfo, line)
        if not A.Fields(info, { "itemIndexOffset", "numSpellBookItems" })
            or type(info.itemIndexOffset) ~= "number" or type(info.numSpellBookItems) ~= "number" then return end
        for slot = info.itemIndexOffset + 1, info.itemIndexOffset + info.numSpellBookItems do
            local spell = A.Call(book.GetSpellBookItemInfo, slot, Enum.SpellBookSpellBank.Player)
            if not A.Fields(spell, { "name", "spellID", "iconID", "isPassive", "isOffSpec" }) then return end
            local key = type(spell.name) == "string" and names[spell.name]
            if key and type(spell.spellID) == "number" and not spell.isPassive and not spell.isOffSpec
                and A.Call(book.IsSpellKnown, spell.spellID, Enum.SpellBookSpellBank.Player) == true then
                known[key] = { name = spell.name, icon = spell.iconID, id = spell.spellID }
            end
        end
    end
    return known, names
end
function API.Active(names)
    -- A restricted scan can look empty. Never turn combat opacity into a
    -- missing-buff claim, or retain pre-combat absence as current information.
    if InCombatLockdown() or not C_UnitAuras then return end
    local active = {}
    for index = 1, 255 do
        local ok, aura = A.Try(C_UnitAuras.GetAuraDataByIndex, "player", index, "HELPFUL")
        if not ok then return end
        if aura == nil then return active end
        if not A.Fields(aura, { "name" }) or type(aura.name) ~= "string" then return end
        local key = names[aura.name]
        if key then active[key] = true end
    end
end
