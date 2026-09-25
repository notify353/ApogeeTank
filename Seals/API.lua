local _, addon = ...
local A = addon.Access
addon.SealAPI = {}
-- Family references resolve localized names; only learned spellbook entries appear.
-- Fury reference: Forever spellbook, build 69913 (60.tools/spellbook/paladin).
local families = { 1311649, 21084, 21082, 20375, 20164, 20165, 20166 }
function addon.SealAPI.Learn()
    if InCombatLockdown() then return nil end
    local _, class = A.Call(UnitClass, "player")
    if class ~= "PALADIN" then return {} end
    if not C_Spell or not C_SpellBook or not Enum or not Enum.SpellBookSpellBank then return nil end
    local names, found, result = {}, {}, {}
    for order, id in ipairs(families) do
        local info = A.Call(C_Spell.GetSpellInfo, id)
        if A.Fields(info, { "name" }) and type(info.name) == "string" then names[info.name] = order end
    end
    local bank = Enum.SpellBookSpellBank.Player
    local count = A.Call(C_SpellBook.GetNumSpellBookSkillLines)
    if type(count) ~= "number" then return nil end
    for line = 1, count do
        local info = A.Call(C_SpellBook.GetSpellBookSkillLineInfo, line)
        if not A.Fields(info, { "itemIndexOffset", "numSpellBookItems" })
            or type(info.itemIndexOffset) ~= "number" or type(info.numSpellBookItems) ~= "number" then return nil end
        for slot = info.itemIndexOffset + 1, info.itemIndexOffset + info.numSpellBookItems do
            local spell = A.Call(C_SpellBook.GetSpellBookItemInfo, slot, bank)
            if not A.Fields(spell, { "name", "spellID", "iconID", "isPassive", "isOffSpec" }) then return nil end
            local order = type(spell.name) == "string" and names[spell.name]
            if order and type(spell.spellID) == "number" and not spell.isPassive and not spell.isOffSpec
                and A.Call(C_SpellBook.IsSpellKnown, spell.spellID, bank) == true then
                found[order] = { spellId = spell.spellID, familyId = families[order], name = spell.name, icon = spell.iconID }
            end
        end
    end
    for order = 1, #families do if found[order] then result[#result + 1] = found[order] end end
    return result
end

-- Read only public identity. Secret aura timing is handed to a native widget,
-- never inspected, reconstructed from casts, or persisted.
function addon.SealAPI.Active(entries)
    if not C_Secrets or not C_UnitAuras then return nil end
    local unknown = false
    for _, entry in ipairs(entries) do
        local restricted = A.Call(C_Secrets.ShouldSpellAuraBeSecret, entry.spellId)
        if restricted ~= false then
            unknown = true
        else
            local ok, aura = A.Try(C_UnitAuras.GetPlayerAuraBySpellID, entry.spellId)
            if not ok then
                unknown = true
            elseif aura then
                if not A.Fields(aura, { "spellId" }) or aura.spellId ~= entry.spellId then
                    unknown = true
                else
                    local state = { spellId = entry.spellId }
                    if A.Fields(aura, { "duration", "expirationTime" })
                        and type(aura.duration) == "number" and type(aura.expirationTime) == "number"
                        and aura.duration > 0 then
                        state.duration, state.start = aura.duration, aura.expirationTime - aura.duration
                    elseif A.Fields(aura, { "auraInstanceID" }) and type(aura.auraInstanceID) == "number" then
                        state.durationObject = A.Call(C_UnitAuras.GetAuraDuration, "player", aura.auraInstanceID)
                    end
                    return state
                end
            end
        end
    end
    if not unknown then return { absent = true } end
end
