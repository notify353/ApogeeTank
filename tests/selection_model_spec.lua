local addon = {}
assert(loadfile("Core/ObservedSpellList.lua"))("ApogeeTank", addon)
local Model = addon.ObservedSpellList
local future = { version = 99, watched = { { spellId = 1 } }, futureField = true }
local unsupported, reason = Model.Create(future)
assert(unsupported == nil and reason and future.version == 99 and future.futureField,
    "future effects schema was accepted or mutated")
assert(addon.ObservedSpellList.Create(future) == nil,
    "shared selection loader accepted a future schema")
assert(addon.ObservedSpellList.Create(nil).GetMissing == nil,
    "effect coverage policy leaked into the shared selection model")
local neutral = addon.ObservedSpellList.Create(nil)
neutral.Observe({ { spellId = 1, name = "Observed spell" } })
local selected = neutral.GetWatched()
selected[1].name = "Changed copy"
assert(neutral.GetWatched()[1].name == "Observed spell",
    "watched-list copies exposed mutable stored identities")
local model = Model.Create(nil)
assert(#model.GetEntries() == 0 and #model.GetSaved().watched == 0)
assert(not model.SetWatched(123, true), "unobserved identity was selectable")
-- Model input is already player-filtered by the aura boundary.
local a = { spellId = 1001, name = "Example armor effect", icon = 12, sourceUnit = "player" }
local b = { spellId = 1002, name = "Example slow effect", icon = 13, sourceUnit = "player" }
model.Observe({ a, a, b })
assert(#model.GetEntries() == 2 and #model.GetSaved().watched == 2,
    "discovery did not automatically watch both unique effects")
assert(model.SetWatched(a.spellId, true))
assert(model.SetWatched(b.spellId, true))
local saved = model.GetSaved()
assert(saved.version == 2 and saved.watched[1].sourceUnit == nil
    and saved.watched[1].applications == nil and saved.watched[1].expirationTime == nil)
local restored = Model.Create(saved)
assert(#restored.GetEntries() == 2 and restored.IsWatched(1001))
assert(restored.SetWatched(1001, false))
assert(#restored.GetSaved().watched == 1 and not restored.IsWatched(1001))
local reloaded = Model.Create(restored.GetSaved())
assert(#reloaded.GetEntries() == 2 and not reloaded.IsWatched(1001),
    "unchecked effect did not remain available and disabled after reload")
reloaded.Observe({ a })
assert(not reloaded.IsWatched(1001), "observing an unchecked effect re-enabled it")
assert(reloaded.SetWatched(1001, true) and reloaded.IsWatched(1001)
    and #reloaded.GetSaved().ignored == 0, "explicit re-enable did not clear the exclusion")
local legacy = Model.Create({ version = 1, watched = { a } })
assert(legacy.IsWatched(1001) and legacy.GetSaved().version == 2,
    "old selected identities were not preserved")
local entries = restored.GetEntries()
entries[1].name = "mutation"
assert(restored.GetEntries()[1].name ~= "mutation", "view mutated persisted identity")

local corrupt = Model.Create({ watched = { false, { spellId = -3 }, { spellId = 1.5 },
    { spellId = 7, name = "Valid", icon = {} }, { spellId = 7, name = "Duplicate" } } })
assert(#corrupt.GetSaved().watched == 1 and corrupt.GetSaved().watched[1].icon == nil)
for id = 1, 20 do model.Observe({ { spellId = id, name = "Effect " .. id } }) end
assert(#model.GetSaved().watched == 22 and model.IsWatched(20),
    "automatic selection silently stopped at a hidden limit")
model.SetWatched(1001, false)
model.Observe({ a, a })
assert(not model.IsWatched(1001) and #model.GetSaved().ignored == 1,
    "repeated observations overrode or duplicated an exclusion")
local beforeClear = model.GetSaved()
model.Clear()
assert(model.GetSaved() == beforeClear and #beforeClear.watched == 0
    and #beforeClear.ignored == 0 and #model.GetEntries() == 0,
    "Clear All did not erase watched and ignored identities in place")
assert(#Model.Create(beforeClear).GetEntries() == 0, "cleared choices returned on reload")
model.Observe({ a })
assert(model.IsWatched(1001), "a cleared opt-out prevented learning from starting fresh")
print("Automatic discovery, persistent opt-outs, migration and ordering tests passed")

local revisionModel = Model.Create(nil)
local effect = { spellId = 999, name = "Revision test", icon = 1 }
revisionModel.Observe({effect})
local revision = revisionModel.GetRevision()
revisionModel.Observe({effect})
assert(revisionModel.GetRevision() == revision, "unchanged observations rebuilt the picker")
revisionModel.SetWatched(999, false)
assert(revisionModel.GetRevision() > revision, "selection change did not invalidate picker")
revision = revisionModel.GetRevision()
revisionModel.Clear()
assert(revisionModel.GetRevision() > revision, "clear did not invalidate picker")
