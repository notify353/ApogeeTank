local _, addon = ...
local M = {}
addon.Guidance = M
-- Reference IDs resolve localized family names; only learned spellbook entries
-- become recommendations. This catalog is independent of cooldown discovery.
M.families = {
    devotion = 465, retribution = 7294, concentration = 19746,
    resistanceFire = 19891, resistanceFrost = 19888, resistanceShadow = 19876,
    sanctity = 20218, defensive = 71, bear = 5487, direBear = 9634,
}
function M.Role(value)
    if value == "NONE" then return "DAMAGER" end
    if value == "TANK" or value == "HEALER" or value == "DAMAGER" then return value end
end
function M.Evaluate(class, role, known, active)
    local result = {}
    local function missing(keys, text)
        for _, key in ipairs(keys) do if active[key] then return end end
        for _, key in ipairs(keys) do
            if known[key] then
                result[#result + 1] = { spell = known[key], text = text }
                return
            end
        end
    end
    if not role then return result end
    if class == "PALADIN" then
        local auras = { "devotion", "retribution", "concentration", "resistanceFire",
            "resistanceFrost", "resistanceShadow", "sanctity" }
        if role == "HEALER" then auras[1], auras[3] = auras[3], auras[1] end
        missing(auras, "Activate aura")
    elseif class == "WARRIOR" then
        if role == "TANK" then missing({ "defensive" }, "Enter tank stance") end
    elseif class == "DRUID" then
        if role == "TANK" then missing({ "direBear", "bear" }, "Enter bear form") end
    end
    return result
end
