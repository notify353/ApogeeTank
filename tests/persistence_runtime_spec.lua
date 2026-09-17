-- Fresh feature drivers per case; no installed character data is accessed.
local realPrint = print
local function RunCase(blockEffects, blockCooldowns)
    local addon, frames, messages, callbacks = {}, {}, {}, {}
    local effectViews, cooldownViews = 0, 0
    function CreateFrame()
        local frame = { scripts = {}, events = {}, shown = true }
        function frame:SetScript(event, callback) self.scripts[event] = callback end
        function frame:RegisterEvent(event) self.events[event] = true end
        function frame:Show() self.shown = true end
        function frame:Hide() self.shown = false end
        function frame:SetShown(shown) self.shown = shown end
        frames[#frames + 1] = frame
        return frame
    end
    function GetTime() return 10 end
    function UnitAffectingCombat() return false end
    function InCombatLockdown() return false end
    function UnitExists() return true end
    function UnitCanAttack() return true end
    function UnitIsDeadOrGhost() return false end
    function UnitIsUnit(left, right) return left == right end
    function IsShiftKeyDown() return true end
    function IsControlKeyDown() return false end
    function IsAltKeyDown() return false end
    print = function(message) messages[#messages + 1] = message end
    for _, path in ipairs({ "Core/ObservedSpellList.lua", "Effects/Model.lua",
        "Cooldowns/Runtime.lua", "Effects/Runtime.lua" }) do
        assert(loadfile(path))("ApogeeTank", addon)
    end
    addon.CooldownAPI = {
        GetStanceSpells = function() return {} end,
        Read = function() return nil end,
    }
    addon.Auras = { ReadPlayerHarmful = function() return {} end }
    addon.CooldownView = { Create = function()
        cooldownViews = cooldownViews + 1
        return { Render = function() end, Hide = function() end }
    end }
    addon.EffectsView = { Create = function()
        effectViews = effectViews + 1
        return { Render = function() end, Toggle = function() end,
            Close = function() end, Hide = function() end }
    end }
    local function Saved(blocked)
        return { version = blocked and 99 or 2,
            watched = { { spellId = 1, name = "Selected", icon = 1 } },
            ignored = { { spellId = 2, name = "Unchecked", icon = 2 } },
            futureField = { untouched = true } }
    end
    local effectSaved, cooldownSaved = Saved(blockEffects), Saved(blockCooldowns)
    ApogeeTankEffectsDB, ApogeeTankCooldownsDB = effectSaved, cooldownSaved
    local cooldowns = addon.StartCooldowns(function() end)
    addon.StartEffects({
        Cooldowns = cooldowns, SetDemo = function() end,
        GetRows = function() return {} end,
        SetRowsChangedHandler = function(callback) callbacks.rowsChanged = callback end,
        SetPlayerClickHandler = function(callback) callbacks.click = callback end,
    })
    local function Event(event, ...)
        for _, frame in ipairs(frames) do
            if frame.events[event] then frame.scripts.OnEvent(frame, event, ...) end
        end
        for _, frame in ipairs(frames) do
            if frame.shown and frame.scripts.OnUpdate then frame.scripts.OnUpdate(frame, 0.1) end
        end
    end
    Event("PLAYER_LOGIN")
    Event("PLAYER_ENTERING_WORLD")
    Event("PLAYER_REGEN_DISABLED")
    Event("UNIT_SPELLCAST_SUCCEEDED", "player", "cast", 3)
    Event("SPELL_UPDATE_COOLDOWN")
    Event("UNIT_AURA", "target")
    callbacks.rowsChanged()
    cooldowns.Refresh()
    cooldowns.Clear()
    Event("PLAYER_LEAVING_WORLD")
    Event("PLAYER_ENTERING_WORLD")

    local function AssertPreserved(actual, original)
        assert(actual == original and actual.version == 99
            and actual.futureField.untouched and #actual.watched == 1
            and actual.watched[1].spellId == 1 and #actual.ignored == 1
            and actual.ignored[1].spellId == 2,
            "unsupported saved schema was replaced or mutated")
    end
    if blockEffects then
        AssertPreserved(ApogeeTankEffectsDB, effectSaved)
        assert(effectViews == 0 and callbacks.click == nil and not frames[2].shown,
            "disabled effects must not build a picker or wake on row changes")
    else
        assert(effectViews == 1 and callbacks.click, "healthy effects did not initialize")
    end
    if blockCooldowns then
        AssertPreserved(ApogeeTankCooldownsDB, cooldownSaved)
        assert(cooldowns.GetModel() == nil and cooldownViews == 0 and not frames[1].shown,
            "disabled cooldowns must not build a view or keep their driver awake")
    else
        assert(cooldowns.GetModel().IsWatched(1) and cooldownViews == 1,
            "healthy cooldowns did not initialize independently")
    end
    assert(#messages == (blockEffects and 1 or 0) + (blockCooldowns and 1 or 0),
        "each disabled feature should explain the preserved data once")
    print = realPrint
end
RunCase(true, false)
RunCase(false, true)
RunCase(true, true)
RunCase(false, false)
print("Future saved schemas remain intact across feature events and independent startup passed")
