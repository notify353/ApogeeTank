local _, addon = ...
local Access = addon.Access
local GetNumShapeshiftForms = Access.Global("GetNumShapeshiftForms")
local GetShapeshiftFormInfo = Access.Global("GetShapeshiftFormInfo")
local API = {}
addon.CooldownAPI = API

function API.GetStanceSpells()
    local result = {}
    if not GetNumShapeshiftForms or not GetShapeshiftFormInfo then return result end
    for index = 1, (GetNumShapeshiftForms() or 0) do
        local id = select(4, GetShapeshiftFormInfo(index))
        if type(id) == "number" then result[id] = true end
    end
    return result
end

function API.Read(id, fromCooldownEvent)
    if not C_Spell or not C_Spell.GetSpellCooldown then return nil end
    if not Access.CanRead(id) then return nil end
    local info = Access.Call(C_Spell.GetSpellInfo, id)
    if not Access.Fields(info, { "name", "iconID" }) then return nil end
    local cooldown = Access.Call(C_Spell.GetSpellCooldown, id)
    if not Access.Fields(cooldown, { "isEnabled", "isActive", "isOnGCD" }) then return nil end
    local ok, charges = Access.Try(C_Spell.GetSpellCharges, id)
    if not ok then return nil end
    if charges and not Access.Fields(charges, { "maxCharges", "isActive" }) then return nil end
    local timerReadable = Access.Fields(cooldown, { "startTime", "duration", "modRate" })
        and (not charges or Access.Fields(charges, { "currentCharges",
            "cooldownStartTime", "cooldownDuration", "chargeModRate" }))
    if not timerReadable then
        -- The export marks classification flags NeverSecret. They can confirm
        -- learning without exposing a timer or asserting readiness/charge count.
        local state = { spellId = id, name = info.name, icon = info.iconID,
            enabled = cooldown.isEnabled, start = 0, duration = 0, unknown = true }
        if charges and charges.maxCharges > 0 then
            state.realCooldown = charges.isActive == true
        elseif fromCooldownEvent and cooldown.isOnGCD ~= nil then
            state.realCooldown = cooldown.isActive and not cooldown.isOnGCD
        end
        return state
    end
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
