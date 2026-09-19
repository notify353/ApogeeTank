local _, addon = ...
local Access = addon.Access
local UnitExists = Access.Global("UnitExists")
local UnitHealth = Access.Global("UnitHealth")
local UnitHealthMax = Access.Global("UnitHealthMax")
local UnitCastingInfo = Access.Global("UnitCastingInfo")
local UnitChannelInfo = Access.Global("UnitChannelInfo")
local UnitGUID = Access.Global("UnitGUID")
local UnitPowerType = Access.Global("UnitPowerType")
local UnitPowerMax = Access.Global("UnitPowerMax")
local UnitPower = Access.Global("UnitPower")
local U = {}
addon.UnitAPI = U

-- Display-only native sinks explicitly accept secret values in Forever.
-- These values never enter snapshots, calculations, discovery or saved data.
function U.PaintNativeHealth(bar, unit, colorCurve)
    if not U.Exists(unit) then return false end
    local painted = pcall(function()
        bar:SetMinMaxValues(0, _G.UnitHealthMax(unit))
        bar:SetValue(_G.UnitHealth(unit))
    end)
    if painted and colorCurve then
        -- Evaluate through the unit API: EvaluateUnpacked cannot accept a
        -- secret percentage in addon execution, even though native bars can.
        local colored = pcall(function()
            local color = UnitHealthPercent(unit, true, colorCurve)
            bar:SetStatusBarColor(color:GetRGBA())
        end)
        if not colored then bar:SetStatusBarColor(0.7, 0.7, 0.7, 1) end
    end
    return painted
end

function U.PaintNativePower(bar, unit)
    local kind, token = UnitPowerType(unit)
    if kind == nil then return false end
    return pcall(function()
        bar:SetMinMaxValues(0, _G.UnitPowerMax(unit, kind))
        bar:SetValue(_G.UnitPower(unit, kind))
        bar:SetStatusBarColor(U.GetPowerColor(kind, token))
    end)
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

function U.GetHealth(unitId)
    if not U.Exists(unitId) then return 0, 1 end
    local value = UnitHealth(unitId)
    local maximum = UnitHealthMax(unitId)
    if value == nil or maximum == nil then return 0, 1, false end
    if type(value) ~= "number" then value = 0 end
    local validMaximum = type(maximum) == "number" and maximum > 0
    if not validMaximum then maximum = 1 end
    return value, maximum, validMaximum
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

function U.GetGUID(unitId)
    if not U.Exists(unitId) or not UnitGUID then return nil end
    return UnitGUID(unitId)
end

function U.GetPowerChannels(unitId)
    local channels = {}
    if not U.Exists(unitId) then return channels end

    local powerType, powerToken
    if UnitPowerType then powerType, powerToken = UnitPowerType(unitId) end
    if powerType == nil then powerType, powerToken = 0, "MANA" end

    local function add(channelType, channelToken)
        local maximum = UnitPowerMax and UnitPowerMax(unitId, channelType) or 0
        if type(maximum) ~= "number" or maximum <= 0 then return end
        local value = UnitPower(unitId, channelType)
        if type(value) ~= "number" then return end
        channels[#channels + 1] = {
            powerType = channelType,
            powerToken = channelToken,
            value = value,
            maximum = maximum,
        }
    end

    add(powerType, powerToken)
    return channels
end

function U.GetPowerColor(powerType, powerToken)
    if powerType == 0 then return 0.32, 0.52, 0.88, 1 end
    local standard = PowerBarColor and (PowerBarColor[powerToken] or PowerBarColor[powerType])
    if standard then
        return standard.r or standard[1] or 0.7,
            standard.g or standard[2] or 0.7,
            standard.b or standard[3] or 0.7, 1
    end
    return 0.70, 0.70, 0.70, 1
end


function U.GetHealthColor(pct)
    pct = tonumber(pct) or 0
    if pct > 0.60 then
        return 0.28, 0.74, 0.46, 1
    elseif pct > 0.35 then
        return 0.90, 0.74, 0.22, 1
    elseif pct > 0.15 then
        return 0.92, 0.48, 0.24, 1
    end
    return 0.86, 0.30, 0.30, 1
end
