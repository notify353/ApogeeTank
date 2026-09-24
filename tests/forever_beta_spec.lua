local addon = {}
function CreateFrame() end
local secret = setmetatable({}, {
    __tostring = function() error("secret formatted") end,
    __add = function() error("secret arithmetic") end,
    __lt = function() error("secret compared") end,
})
function issecretvalue(value) return rawequal(value, secret) end
function canaccessvalue(value) return not issecretvalue(value) end
local version, build, interface = "1.60.1", "69977", 16001
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
    { "1.15.9", "69722", 11509, 2 },
    { "1.60.2", "69977", 16002, 1 },
    { "1.60.1", "69977", 16001, 2 }, { "12.0.0", "69977", 120000, 1 },
}) do
    version, build, interface, WOW_PROJECT_ID = unpack(change)
    addon.Client = nil; Load("Core/Client.lua")
    assert(addon.Client == nil, "unknown client admitted")
end
version, build, interface, WOW_PROJECT_ID = "1.60.1", "69977", 16001, 1
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
assert(addon.UnitAPI.GetCast("target") == nil)
local bar = {}
function bar:SetMinMaxValues(low, high) self.maximum = high end
function bar:SetValue(value) self.value = value end
function bar:SetStatusBarColor() end
assert(addon.UnitAPI.PaintNativeHealth(bar, "player"))
assert(rawequal(bar.value, secret), "native health did not receive original value")
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
local durationObject = setmetatable({}, {
    __index = function() error("duration object inspected") end,
    __tostring = function() error("duration object formatted") end,
})
C_Spell.GetSpellCooldownDuration = function(id, ignoreGCD)
    assert(id == 1 and ignoreGCD == true, "native duration must exclude GCD")
    return durationObject
end
C_Spell.GetSpellChargeDuration = function(id)
    assert(id == 1)
    return durationObject
end
assert(addon.CooldownAPI.Read(1, true).nativeDuration == durationObject,
    "restricted charge duration was discarded")
charges = nil
cooldown.duration = secret
assert(addon.CooldownAPI.Read(1, true).nativeDuration == durationObject,
    "restricted spell duration was discarded")
cooldown.duration, cooldown.modRate = 10, 2
assert(addon.CooldownAPI.Read(1, true).nativeDuration == durationObject,
    "non-default numeric rate bypassed native timing")
charges = { maxCharges = 2, currentCharges = 0, isActive = true,
    cooldownStartTime = 1, cooldownDuration = 10, chargeModRate = 0.5 }
assert(addon.CooldownAPI.Read(1, true).nativeDuration == durationObject,
    "non-default charge rate bypassed native timing")
charges = nil
cooldown.duration, cooldown.modRate = secret, 1
C_Spell.GetSpellCooldownDuration = function() error("temporarily unavailable") end
assert(addon.CooldownAPI.Read(1, true).unknown
    and not addon.CooldownAPI.Read(1, true).nativeDuration,
    "failed native duration claimed numeric readiness")
cooldown.duration = 10
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
