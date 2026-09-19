-- Startup composition; each feature owns its state and event lifecycle.
local _, addon = ...
if not addon.Client then return end
addon.StartThreat()
addon.StartStance(addon.ThreatHud.GetPlayerStatusAnchor)
local cooldowns = addon.StartCooldowns(addon.ThreatHud.GetPlayerStatusAnchor)
local effectsEnabled = addon.Client ~= "foreverBeta"
local demo = effectsEnabled and addon.CreateThreatDemo() or nil
addon.StartEffects({
    EffectsEnabled = effectsEnabled,
    Cooldowns = cooldowns,
    SetDemo = demo and demo.SetShown or function() end,
    GetRows = addon.ThreatHud.GetEnemyRows,
    SetRowsChangedHandler = addon.ThreatHud.SetRowsChangedHandler,
    SetPlayerClickHandler = addon.ThreatHud.SetPlayerClickHandler,
})
