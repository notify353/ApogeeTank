local _, addon = ...
addon.EffectsModel = {}

function addon.EffectsModel.Create(saved)
    local model, reason = addon.ObservedSpellList.Create(saved)
    if not model then return nil, reason end
    -- Coverage receives complete player-owned auras, never visible icon slots.
    function model.GetMissing(auras, validTarget)
        local result = {}
        if not validTarget or auras == nil then return result end
        local present = {}
        for _, aura in ipairs(auras) do present[aura.spellId or false] = true end
        for _, effect in ipairs(model.GetWatched()) do
            if not present[effect.spellId] then
                effect.watched = nil
                result[#result + 1] = effect
            end
        end
        return result
    end
    return model
end
