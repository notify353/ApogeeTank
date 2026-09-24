local _, addon = ...
local Access = addon.Access
local UnitExists = Access.Global("UnitExists")
local UnitCastingInfo = Access.Global("UnitCastingInfo")
local UnitChannelInfo = Access.Global("UnitChannelInfo")
local U = {}
addon.UnitAPI = U

-- Display-only native sinks explicitly accept secret values in Forever.
-- These values never enter snapshots, calculations, discovery or saved data.
function U.PaintNativeHealth(bar, unit)
    if not U.Exists(unit) then return false end
    local painted = pcall(function()
        bar:SetMinMaxValues(0, _G.UnitHealthMax(unit))
        bar:SetValue(_G.UnitHealth(unit))
    end)
    return painted
end

function U.PaintNativeRaidMarker(texture, unit)
    if not U.Exists(unit) then return false end
    local ok, painted = pcall(function()
        local index = _G.GetRaidTargetIndex(unit)
        if Access.CanRead(index) and index == nil then return false end
        texture:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
        -- Forever's native texture accepts restricted cells directly. Never
        -- copy the index into a snapshot or calculate texture coordinates.
        texture:SetSpriteSheetCell(index, 4, 4)
        return true
    end)
    return ok and painted == true
end

function U.Exists(unitId)
    if unitId == nil or UnitExists == nil then return false end
    local exists = UnitExists(unitId)
    return exists == true or exists == 1
end

local function NormalizeCast(name, icon, startTimeMs, endTimeMs, notInterruptible,
        spellId, isChannel)
    local startTime = tonumber(startTimeMs)
    local endTime = tonumber(endTimeMs)
    if not name or not startTime or not endTime or endTime <= startTime then return nil end
    return {
        name = name,
        icon = icon,
        startTime = startTime / 1000,
        endTime = endTime / 1000,
        notInterruptible = notInterruptible == true,
        spellId = spellId,
        isChannel = isChannel == true,
    }
end

function U.GetCast(unitId)
    if not U.Exists(unitId) then return nil end
    if UnitCastingInfo then
        local name, _, icon, startTimeMs, endTimeMs, _, _, notInterruptible, spellId =
            UnitCastingInfo(unitId)
        local cast = NormalizeCast(name, icon, startTimeMs, endTimeMs,
            notInterruptible, spellId, false)
        if cast then return cast end
    end
    if UnitChannelInfo then
        local name, _, icon, startTimeMs, endTimeMs, _, notInterruptible, spellId =
            UnitChannelInfo(unitId)
        return NormalizeCast(name, icon, startTimeMs, endTimeMs,
            notInterruptible, spellId, true)
    end
    return nil
end
