-- Startup composition; each feature owns its state and event lifecycle.
local _, addon = ...
if not addon.Client then return end
addon.StartThreat()
addon.StartStance(addon.ThreatHud.GetPlayerStatusAnchor)
local cooldowns = addon.StartCooldowns(addon.ThreatHud.GetPlayerStatusAnchor)
local demo = addon.CreateThreatDemo()
addon.StartEffects({
    Cooldowns = cooldowns,
    SetDemo = demo.SetShown,
    GetRows = addon.ThreatHud.GetEnemyRows,
    SetRowsChangedHandler = addon.ThreatHud.SetRowsChangedHandler,
    SetPlayerClickHandler = addon.ThreatHud.SetPlayerClickHandler,
})
