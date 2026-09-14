local _, addon = ...
local U = {}
addon.UnitAPI = U

function U.Exists(unitId)
    if unitId == nil or UnitExists == nil then return false end
    local exists = UnitExists(unitId)
    return exists == true or exists == 1
end

function U.GetHealth(unitId)
    if not U.Exists(unitId) then return 0, 1 end
    local value = UnitHealth and UnitHealth(unitId) or 0
    local maximum = UnitHealthMax and UnitHealthMax(unitId) or 1
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
        local value = UnitPower and UnitPower(unitId, channelType) or 0
        if type(value) ~= "number" then value = 0 end
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
