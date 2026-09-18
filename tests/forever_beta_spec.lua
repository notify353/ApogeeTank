local addon = {}
function CreateFrame() end
local secret = setmetatable({}, {
    __tostring = function() error("secret formatted") end,
    __add = function() error("secret arithmetic") end,
    __lt = function() error("secret compared") end,
})
function issecretvalue(value) return rawequal(value, secret) end
function canaccessvalue(value) return not issecretvalue(value) end
local version, build, interface = "1.60.1", "69913", 16001
WOW_PROJECT_ID, WOW_PROJECT_CLASSIC = 1, 2
function GetBuildInfo() return version, build, "", interface end
local function Load(path) assert(loadfile(path))("ApogeeTank", addon) end
Load("Core/Access.lua")
Load("Core/Client.lua")
assert(addon.Client == "foreverBeta")
local originalPrint, warnings=print,0
print=function() warnings=warnings+1 end
build="99999"; Load("Core/Client.lua"); Load("Core/Client.lua")
assert(addon.Client=="foreverBeta" and warnings==1,"Patched builds continue with one warning")
local create=CreateFrame; CreateFrame=nil; Load("Core/Client.lua")
assert(not addon.Client,"Missing frame capability must stop startup")
CreateFrame=create; print=originalPrint
for _, change in ipairs({
    { "1.60.2", "69913", 16002, 1 },
    { "1.60.1", "69913", 16001, 2 }, { "12.0.0", "69913", 120000, 1 },
}) do
    version, build, interface, WOW_PROJECT_ID = unpack(change)
    addon.Client = nil; Load("Core/Client.lua")
    assert(addon.Client == nil, "unknown client admitted")
end
version, build, interface, WOW_PROJECT_ID = "1.60.1", "69913", 16001, 1
local savedGuard = canaccessvalue
canaccessvalue = nil; Load("Core/Client.lua")
assert(addon.Client == nil, "beta enabled without secret guards")
canaccessvalue = savedGuard
Load("Core/Client.lua")
assert(not addon.Access.CanRead(secret))
assert(not addon.Access.Try(function() error("restricted") end))
assert(not addon.Access.Try(function() return 1, secret end))
function UnitExists() return true end
function UnitHealth() return secret end
function UnitHealthMax() return 100 end
function UnitGUID() return secret end
function UnitPowerType() return 0, "MANA" end
function UnitPower() return secret end
function UnitPowerMax() return 100 end
function UnitCastingInfo() return "Cast", nil, 1, secret, 1000 end
function UnitChannelInfo() return nil end
Load("Core/UnitAPI.lua")
local health, maximum, valid = addon.UnitAPI.GetHealth("player")
assert(health == 0 and maximum == 1 and valid == false)
assert(addon.UnitAPI.GetGUID("target") == nil)
assert(addon.UnitAPI.GetCast("target") == nil)
assert(#addon.UnitAPI.GetPowerChannels("player") == 0)
local bar = {}
function bar:SetMinMaxValues(low, high) self.maximum = high end
function bar:SetValue(value) self.value = value end
function bar:SetStatusBarColor() end
assert(addon.UnitAPI.PaintNativeHealth(bar, "player"))
assert(rawequal(bar.value, secret), "native health did not receive original value")
assert(addon.UnitAPI.PaintNativePower(bar, "player"))
assert(rawequal(bar.value, secret), "native power did not receive original value")
local aura = { spellId = 1, sourceUnit = "player", name = "Effect" }
C_UnitAuras = { GetAuraDataByIndex = function(_, index) if index == 1 then return aura end end }
function UnitIsUnit() return true end
Load("Core/Auras.lua")
assert(#addon.Auras.ReadPlayerHarmful("target") == 1)
for _, field in ipairs({ "sourceUnit", "spellId", "expirationTime", "applications" }) do
    local previous = aura[field]; aura[field] = secret
    assert(addon.Auras.ReadPlayerHarmful("target") == nil, "restricted aura became absence")
    aura[field] = previous
end
function UnitIsUnit() return secret end
assert(addon.Auras.ReadPlayerHarmful("target") == nil, "unknown ownership became absence")
function UnitIsUnit() return false end
assert(#addon.Auras.ReadPlayerHarmful("target") == 0)
local cooldown = { isEnabled = true, startTime = 1, duration = 10, modRate = 1,
    isActive = true, isOnGCD = false }
local charges
C_Spell = {
    GetSpellInfo = function() return { name = "Spell", iconID = 1 } end,
    GetSpellCooldown = function() return cooldown end,
    GetSpellCharges = function() return charges end,
}
Load("Core/Cooldowns.lua")
assert(addon.CooldownAPI.Read(1, true).realCooldown)
cooldown.duration = secret
assert(addon.CooldownAPI.Read(1, true).unknown and addon.CooldownAPI.Read(1, true).realCooldown)
cooldown.duration = 10
charges = { maxCharges = 2, currentCharges = secret, isActive = true }
assert(addon.CooldownAPI.Read(1, true).unknown and addon.CooldownAPI.Read(1, true).realCooldown)
charges = nil
cooldown.isOnGCD = true
assert(not addon.CooldownAPI.Read(1, true).realCooldown)
assert(addon.CooldownAPI.Read(secret, true) == nil)
Load("Threat/Observer.lua")
function UnitDetailedThreatSituation(unit)
    if unit == "party1" then return false, 1, secret end
    return true, 3, 100
end
assert(next((addon.ThreatObserver.GetThreatDetails("target", { "player", "party1" }, true))) == nil,
    "restricted challenger became zero threat")
print("Forever exact gate, secret rejection, native display sinks and unknown-state tests passed")
