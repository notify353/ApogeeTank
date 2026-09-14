-- Startup composition; each feature owns its state and event lifecycle.
local _, addon = ...
local _, _, _, interface = GetBuildInfo()
if WOW_PROJECT_ID ~= WOW_PROJECT_CLASSIC or tonumber(interface) ~= 11509 then return end
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
