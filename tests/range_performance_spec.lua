local addon, frames = {}, {}
local usableReads, rangeReads, timerReads, renders = 0, 0, 0, 0
local ranges, rendered = {}, nil
function GetTime() return 100 end
function InCombatLockdown() return false end
function UnitClass() return "Warrior", "WARRIOR" end
function CreateFrame()
    local f = { scripts = {} }
    function f:SetScript(event, fn) self.scripts[event] = fn end
    function f:RegisterEvent() end
    function f:SetShown() end
    function f:Hide() end
    frames[#frames + 1] = f
    return f
end
C_Spell = {
    GetSpellInfo = function(id) return { name = "Spell " .. id, iconID = id } end,
    GetSpellCooldown = function()
        timerReads = timerReads + 1
        return { isEnabled = true, isActive = false, startTime = 0, duration = 0 }
    end,
    GetSpellCharges = function() return nil end,
    IsSpellUsable = function() usableReads = usableReads + 1; return true, false end,
    IsSpellInRange = function(id) rangeReads = rangeReads + 1; return ranges[id] ~= false end,
    EnableSpellRangeCheck = function() end,
}
addon.CooldownView = { Create = function() return {
    Render = function(_, states) renders = renders + 1; rendered = states end,
    Hide = function() end,
} end }
for _, path in ipairs({ "Core/Access.lua", "Core/ObservedSpellList.lua", "Core/Cooldowns.lua", "Cooldowns/Runtime.lua" }) do
    assert(loadfile(path))("test", addon)
end
ApogeeTankCooldownsDB = { watched = {} }
for id = 1, 6 do ApogeeTankCooldownsDB.watched[id] = { spellId = id, name = "Spell " .. id } end
local runtime = addon.StartCooldowns(function() end)
local driver = frames[1]
local function Event(event, id) driver.scripts.OnEvent(driver, event, id) end
Event("PLAYER_LOGIN")
usableReads, rangeReads, timerReads, renders = 0, 0, 0, 0
for i = 1, 100 do
    ranges[1] = i % 2 == 0
    Event("SPELL_RANGE_CHECK_UPDATE", 1)
    assert(rendered[1].castable == ranges[1], "range change was not visible synchronously")
    assert(rendered[2].castable == true, "range update changed unrelated spell")
end
print("100 range events / six spells: " .. (usableReads + rangeReads) .. " usability/range API calls")
assert(usableReads == 100 and rangeReads == 100, "one spell's range event queried unrelated spells")
assert(timerReads == 0, "range events queried cooldown timers")
local oldRenders = renders
Event("SPELL_RANGE_CHECK_UPDATE", 999)
assert(usableReads == 100 and renders == oldRenders, "unwatched range event performed display work")
ranges[2] = false
Event("PLAYER_TARGET_CHANGED")
assert(rendered[2].castable == false and usableReads == 106, "target change failed full refresh")
local secret = {}
issecretvalue = function(value) return rawequal(value, secret) end
Event("SPELL_RANGE_CHECK_UPDATE", secret)
assert(usableReads == 112, "unreadable identifier must fall back to guarded full refresh")
Event("PLAYER_LEAVING_WORLD")
Event("SPELL_RANGE_CHECK_UPDATE", 1)
assert(usableReads == 112, "late range event queried APIs during zoning")
print("Targeted range updates preserve immediate state, broad invalidation and zoning guards")
