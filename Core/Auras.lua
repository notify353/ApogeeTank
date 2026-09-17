-- Shared read boundary. nil means unavailable, not an empty aura list.
local _, addon = ...
local Access = addon.Access
local fields = { "name", "icon", "spellId", "applications", "duration",
    "expirationTime", "sourceUnit" }
addon.Auras = {}
function addon.Auras.ReadHarmful(unit)
    if not UnitExists(unit) or not C_UnitAuras
        or not C_UnitAuras.GetAuraDataByIndex then return nil end
    local ok, result = pcall(function()
        local auras, index = {}, 1
        while true do
            local aura = C_UnitAuras.GetAuraDataByIndex(unit, index, "HARMFUL")
            if not Access.CanRead(aura) then return nil end
            if not aura then return auras end
            if not Access.Fields(aura, fields) then return nil end
            auras[#auras + 1] = aura
            index = index + 1
        end
    end)
    if ok then return result end
    return nil
end

-- Exact player ownership, including aliases of the player unit. Pets and
-- unidentified casters do not qualify; preserve nil for unavailable reads.
function addon.Auras.ReadPlayerHarmful(unit)
    local auras = addon.Auras.ReadHarmful(unit)
    if auras == nil then return nil end
    local owned = {}
    for _, aura in ipairs(auras) do
        if aura.sourceUnit then
            local ok, isPlayer = Access.Try(UnitIsUnit, aura.sourceUnit, "player")
            if not ok then return nil end
            if isPlayer then owned[#owned + 1] = aura end
        end
    end
    return owned
end
