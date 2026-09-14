local _, addon = ...
local API = {}
addon.CooldownAPI = API

function API.GetStanceSpells()
    local result = {}
    if not GetNumShapeshiftForms or not GetShapeshiftFormInfo then return result end
    for index = 1, GetNumShapeshiftForms() do
        local id = select(4, GetShapeshiftFormInfo(index))
        if type(id) == "number" then result[id] = true end
    end
    return result
end

function API.Read(id, fromCooldownEvent)
    if not C_Spell or not C_Spell.GetSpellCooldown then return nil end
    local info = C_Spell.GetSpellInfo(id)
    if not info then return nil end
    local cooldown = C_Spell.GetSpellCooldown(id)
    if not cooldown then return nil end
    local charges = C_Spell.GetSpellCharges(id)
    local state = { spellId = id, name = info.name, icon = info.iconID,
        enabled = cooldown.isEnabled, start = cooldown.startTime,
        duration = cooldown.duration, rate = cooldown.modRate or 1 }
    if charges and charges.maxCharges > 0 then
        state.charges = charges.currentCharges
        state.start, state.duration = charges.cooldownStartTime, charges.cooldownDuration
        state.rate = charges.chargeModRate or 1
        state.realCooldown = charges.isActive and charges.cooldownDuration > 0
    elseif fromCooldownEvent and cooldown.isOnGCD ~= nil then
        state.realCooldown = cooldown.isActive and not cooldown.isOnGCD
        state.gcdOnly = cooldown.isOnGCD
    end
    return state
end
