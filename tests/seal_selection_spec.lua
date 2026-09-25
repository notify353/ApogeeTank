local addon = {}
assert(loadfile("Seals/Selection.lua"))("test", addon)
local allowed = true
local function CanConfigure() return allowed end
local function Seal(rank, family, name)
    return { spellId = rank, familyId = family, name = name, icon = rank }
end
local first, second = Seal(21084, 21084, "Righteousness"), Seal(21082, 21082, "Crusader")
local model = addon.SealSelection.Create(nil, CanConfigure)
model.Reconcile({first, second})
assert(model.IsWatched(21084) and not model.IsWatched(21082), "Crusader did not default unchecked")
assert(#model.GetEntries() == 2, "unchecked Crusader vanished from the checklist")
assert(model.SetWatched(21082, true))
assert(model.GetSaved().hidden[21082] == false, "explicit opt-in provenance was not recorded")
assert(model.SetWatched(21084, false))
local saved = model.GetSaved()
assert(saved.hidden[21084] and not saved.hidden[21082])
local reloaded = addon.SealSelection.Create(saved, CanConfigure)
reloaded.Reconcile({Seal(20287, 21084, "Righteousness"), second})
assert(not reloaded.IsWatched(20287) and reloaded.IsWatched(21082), "rank/reload lost family opt-out")
local revision = reloaded.GetRevision()
reloaded.Reconcile({Seal(20287, 21084, "Righteousness"), second})
assert(reloaded.GetRevision() == revision, "unchanged spellbook invalidated picker")
reloaded.Reconcile({second})
assert(reloaded.GetSaved().hidden[21084], "temporarily missing family lost its opt-out")
reloaded.Reconcile({first, second, Seal(1311649, 1311649, "Fury")})
assert(not reloaded.IsWatched(21084) and reloaded.IsWatched(1311649))
allowed = false
assert(not reloaded.SetWatched(21084, true) and not reloaded.IsWatched(21084))
allowed = true
assert(not reloaded.SetWatched(999, false), "unknown seal accepted a visibility choice")
assert(reloaded.SetWatched(21084, true) and not reloaded.GetSaved().hidden[21084])
local copy = reloaded.GetEntries()
copy[1].name = "mutated"
assert(reloaded.GetEntries()[1].name == "Righteousness")
local future = { version = 99, hidden = { [21084] = true }, extra = "preserve" }
assert(addon.SealSelection.Create(future, CanConfigure) == nil)
assert(future.version == 99 and future.hidden[21084] and future.extra == "preserve")
local malformed = addon.SealSelection.Create({hidden = {bad = true, [0] = true, [1.5] = true,
    [21084] = true, [21082] = false}}, CanConfigure)
assert(malformed.GetSaved().hidden[21084] and not malformed.GetSaved().hidden.bad
    and not malformed.GetSaved().hidden[0] and not malformed.GetSaved().hidden[1.5])
local legacy = {version = 1, hidden = {[21084] = true}}
local migrated = addon.SealSelection.Create(legacy, CanConfigure)
migrated.Reconcile({first, second})
assert(not migrated.IsWatched(21084) and not migrated.IsWatched(21082))
assert(legacy.version == 1 and legacy.hidden[21082] == nil, "migration mutated its input")
assert(migrated.SetWatched(21082, true))
local upgraded = addon.SealSelection.Create(migrated.GetSaved(), CanConfigure)
upgraded.Reconcile({first, Seal(20162, 21082, "Crusader")})
assert(upgraded.IsWatched(20162) and not upgraded.IsWatched(21084), "rank/reload lost explicit Crusader opt-in")
upgraded.Reconcile({first})
upgraded.Reconcile({first, second})
assert(upgraded.IsWatched(21082), "temporary unlearning lost explicit Crusader choice")
assert(upgraded.SetWatched(21082, false))
local optedOut = addon.SealSelection.Create(upgraded.GetSaved(), CanConfigure)
optedOut.Reconcile({first, second})
assert(not optedOut.IsWatched(21082), "explicit Crusader opt-out was lost")
print("Seal visibility defaults, rank/reload persistence, reconciliation, guarded choices and future schemas passed")
