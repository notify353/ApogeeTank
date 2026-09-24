-- Startup composition; each feature owns its state and event lifecycle.
local _, addon = ...
if not addon.Client then return end
addon.StartThreat()
local stance = addon.StartStance(addon.ThreatHud.GetStanceAnchor, addon.ThreatHud.GetStanceGeometry)
local cooldowns = addon.StartCooldowns(addon.ThreatHud.GetCooldownAnchor, addon.ThreatHud.GetCooldownGeometry)
local picker = addon.StartPicker(cooldowns)
addon.StartMinimap(picker)

addon.StartGuidance(addon.ThreatHud.GetGuidanceAnchor, stance)

addon.StartSeals(addon.ThreatHud.GetSealGeometry)
