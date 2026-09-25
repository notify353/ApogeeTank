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

-- Compile only outside combat; native macro conditions handle target changes.
function API.TargetMacro(id)
    if InCombatLockdown() or not C_Spell then return nil end
    if Access.Call(C_Spell.IsSpellHarmful, id) ~= true then return nil end
    local info = Access.Call(C_Spell.GetSpellInfo, id)
    if not Access.Fields(info, { "name" }) or type(info.name) ~= "string"
        or info.name:find("[;\r\n]") then return nil end
    return "[harm,nodead] /cast " .. info.name .. "; /targetenemy\n/cast " .. info.name
end

function API.Castable(id)
    if not C_Spell then return nil end
    local usable, insufficientPower = Access.Call(C_Spell.IsSpellUsable, id)
    local inRange = Access.Call(C_Spell.IsSpellInRange, id, "target")
    if usable == false or insufficientPower == true or inRange == false then return false end
    if usable == true then return true end
end
function API.WatchRange(id, enable)
    if C_Spell then Access.Call(C_Spell.EnableSpellRangeCheck, id, enable) end
end

function API.Read(id, fromCooldownEvent)
    if not C_Spell or not C_Spell.GetSpellCooldown then return nil end
    if not Access.CanRead(id) then return nil end
    local info = Access.Call(C_Spell.GetSpellInfo, id)
    if not Access.Fields(info, { "name", "iconID" }) then return nil end
    local cooldown = Access.Call(C_Spell.GetSpellCooldown, id)
    if not Access.Fields(cooldown, { "isEnabled", "isActive", "isOnGCD" }) then return nil end
    -- The native contract only guarantees this optional flag during its event.
    local onGCD
    if fromCooldownEvent then onGCD = cooldown.isOnGCD end
    local ok, charges = Access.Try(C_Spell.GetSpellCharges, id)
    if not ok then return nil end
    if charges and not Access.Fields(charges, { "maxCharges", "isActive" }) then return nil end
    -- Public classification can establish idle/GCD-only state even when
    -- scalar timestamps are restricted. Do not turn a GCD into an unknown timer.
    if (not charges or charges.maxCharges == 0) and cooldown.isEnabled ~= false
        and (cooldown.isActive == false or onGCD == true) then
        return { spellId = id, name = info.name, icon = info.iconID,
            enabled = cooldown.isEnabled, start = 0, duration = 0,
            gcdOnly = onGCD, coolingDown = false,
            castable = API.Castable(id) }
    end
    local timerReadable = Access.Fields(cooldown, { "startTime", "duration", "modRate" })
        and (not charges or Access.Fields(charges, { "currentCharges",
            "cooldownStartTime", "cooldownDuration", "chargeModRate" }))
    -- Let the native widget interpret rate changes, just as it does opaque timers.
    -- Applying start + duration in Lua would silently assume a rate of one.
    local rateAdjusted = timerReadable and (
        (charges and charges.maxCharges > 0 and charges.isActive
            and charges.chargeModRate ~= nil and charges.chargeModRate ~= 1)
        or ((not charges or charges.maxCharges == 0) and cooldown.isActive
            and cooldown.modRate ~= nil and cooldown.modRate ~= 1))
    if not timerReadable or rateAdjusted then
        -- The export marks classification flags NeverSecret. They can confirm
        -- learning without exposing a timer or asserting readiness/charge count.
        local state = { spellId = id, name = info.name, icon = info.iconID,
            enabled = cooldown.isEnabled, start = 0, duration = 0, unknown = true, castable = API.Castable(id) }
        if charges and charges.maxCharges > 0 then
            state.realCooldown = charges.isActive == true
            if Access.CanRead(charges.currentCharges) then state.charges = charges.currentCharges end
        elseif onGCD ~= nil then
            state.realCooldown = cooldown.isActive and not onGCD
        end
        -- These opaque objects let the native widget render restricted
        -- timers. Never read their values or persist them as spell data.
        if charges and charges.maxCharges > 0 then
            state.nativeDuration = Access.Call(C_Spell.GetSpellChargeDuration, id)
        else
            state.nativeDuration = Access.Call(C_Spell.GetSpellCooldownDuration, id, true)
        end
        if charges and charges.maxCharges > 0 then
            state.coolingDown = charges.isActive == true
        elseif onGCD ~= nil then
            state.coolingDown = cooldown.isActive == true and not onGCD
        end
        return state
    end
    local state = { spellId = id, name = info.name, icon = info.iconID,
        enabled = cooldown.isEnabled, start = cooldown.startTime,
        duration = cooldown.duration, rate = cooldown.modRate or 1, castable = API.Castable(id) }
    if charges and charges.maxCharges > 0 then
        state.charges = charges.currentCharges
        state.start, state.duration = charges.cooldownStartTime, charges.cooldownDuration
        state.rate = charges.chargeModRate or 1
        state.realCooldown = charges.isActive and charges.cooldownDuration > 0
    elseif onGCD ~= nil then
        state.coolingDown = cooldown.isActive and not onGCD
        if fromCooldownEvent then state.realCooldown = state.coolingDown end
        state.gcdOnly = onGCD
    end
    return state
end

-- Explicitly requested Paladin defaults. Identity only: timers still come from
-- Read, never from a hard-coded duration. Rank order is low to high.
function API.GetDefaultSpells()
    if InCombatLockdown and InCombatLockdown() then return {} end
    local _, class = Access.Call(UnitClass, "player")
    if class ~= "PALADIN" or not C_SpellBook or not C_Spell or not Enum
        or not Enum.SpellBookSpellBank then return {} end
    local result = {}
    for order, ranks in ipairs({ { 679, 678, 1866, 680, 2495, 5569, 10332, 10333 },
        { 20271 }, { 853, 5588, 5589, 10308 },
        { 26573, 20116, 20922, 20923, 20924 },
        { 20925, 20927, 20928 }, { 407632 } }) do
        for index = #ranks, 1, -1 do
            local id = ranks[index]
            if Access.Call(C_SpellBook.IsSpellKnown, id, Enum.SpellBookSpellBank.Player) == true then
                local info = Access.Call(C_Spell.GetSpellInfo, id)
                if Access.Fields(info, { "name", "iconID" }) and type(info.name) == "string" then
                    result[#result + 1] = { spellId = id, name = info.name, icon = info.iconID, ranks = ranks,
                        defaultOrder = order, previousDefaultOrder = order == 2 and 3 or order == 3 and 2 or order }
                end
                break
            end
        end
    end
    return result
end
