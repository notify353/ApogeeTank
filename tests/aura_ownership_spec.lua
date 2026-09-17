local addon = {}
assert(loadfile("Core/Access.lua"))("ApogeeTank", addon)
assert(loadfile("Core/Auras.lua"))("ApogeeTank", addon)
assert(loadfile("Core/ObservedSpellList.lua"))("ApogeeTank", addon)
assert(loadfile("Effects/Model.lua"))("ApogeeTank", addon)
local guids = { player = "P", target = "E", party1 = "OTHER", pet = "PET", alias = "P" }
function UnitExists(unit) return guids[unit] ~= nil end
function UnitIsUnit(a, b) return guids[a] ~= nil and guids[a] == guids[b] end
local current, failed = {}, false
C_UnitAuras = { GetAuraDataByIndex = function(unit, index, filter)
    assert(unit == "target" and filter == "HARMFUL")
    if failed then error("Unavailable") end
    return current[index]
end }
local model = addon.EffectsModel.Create(nil)
current = {
    { spellId = 1, name = "Foreign", sourceUnit = "party1" },
    { spellId = 2, name = "Pet", sourceUnit = "pet" },
    { spellId = 3, name = "Unknown" },
    { spellId = 4, name = "Self", sourceUnit = "player" },
    { spellId = 5, name = "Alias", sourceUnit = "alias" },
}
local owned = addon.Auras.ReadPlayerHarmful("target")
assert(#owned == 2 and owned[1].spellId == 4 and owned[2].spellId == 5)
assert(#addon.Auras.ReadHarmful("target") == 5, "ownership filter mutated the shared aura list")
model.Observe(owned)
assert(#model.GetEntries() == 2 and not model.SetWatched(1, true)
    and not model.SetWatched(2, true) and not model.SetWatched(3, true))
assert(model.SetWatched(4, true))
assert(model.IsWatched(4) and model.IsWatched(5), "own effects were not auto-checked")
model.SetWatched(5, false)
current = { { spellId = 4, name = "Same effect", sourceUnit = "party1" } }
assert(#model.GetMissing(addon.Auras.ReadPlayerHarmful("target"), true) == 1)
current[#current + 1] = { spellId = 4, name = "Same effect", sourceUnit = "alias" }
assert(#model.GetMissing(addon.Auras.ReadPlayerHarmful("target"), true) == 0,
    "coexisting foreign and own copies did not count the own copy")
failed = true
assert(addon.Auras.ReadPlayerHarmful("target") == nil)
assert(#model.GetMissing(addon.Auras.ReadPlayerHarmful("target"), true) == 0)
assert(addon.Auras.ReadPlayerHarmful("missing") == nil)
print("Player-only aura discovery and coverage tests passed")
