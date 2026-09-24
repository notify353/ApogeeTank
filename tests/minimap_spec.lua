local addon, frames, named = {}, {}, {}
local combat, ready, toggles, cursorX, cursorY = false, false, 0, 100, 260
local function Frame(_, name, parent)
    local f = { scripts = {}, events = {}, parent = parent }
    function f:SetSize() end
    function f:EnableMouse() end
    function f:SetFrameStrata() end
    function f:SetFrameLevel() end
    function f:GetFrameLevel() return 1 end
    function f:RegisterForClicks() end
    function f:RegisterForDrag(...) self.drag = {...} end
    function f:CreateTexture() return Frame() end
    function f:SetPoint(...) self.point = {...} end
    function f:ClearAllPoints() end
    function f:SetTexture() end
    function f:SetHighlightTexture() end
    function f:SetAlpha(a) self.alpha = a end
    function f:SetEnabled(b) self.enabled = b end
    function f:SetScript(k, v) self.scripts[k] = v end
    function f:RegisterEvent(e) self.events[e] = true end
    function f:GetCenter() return 100, 100 end
    function f:GetEffectiveScale() return 2 end
    frames[#frames + 1] = f
    if name then named[name] = f end
    return f
end
CreateFrame = Frame
Minimap = Frame()
GameTooltip = { Hide = function(self) self.shown = false end,
    IsOwned = function(self, frame) return self.owner == frame end }
function IsShiftKeyDown() return false end
function IsControlKeyDown() return false end
function IsAltKeyDown() return false end
function GetCursorPosition() return cursorX, cursorY end
assert(loadfile("Minimap/Runtime.lua"))("ApogeeTank", addon)
local function Start()
    addon.StartMinimap({ CanConfigure = function() return ready and not combat end,
        Toggle = function() toggles = toggles + 1 end })
end
local function Event(e)
    for _, frame in ipairs(frames) do
        if frame.events[e] then frame.scripts.OnEvent(frame, e) end
    end
end
ApogeeTankUIDB = nil
Start(); Event("PLAYER_LOGIN")
local button = named.ApogeeTankMinimapButton
assert(button and not button.enabled, "uninitialized picker was available")
assert(button.point[4] < 0 and button.point[5] > 0, "default is not upper-left")
ready = true; Event("PLAYER_ENTERING_WORLD")
button.scripts.OnClick(button, "LeftButton")
button.scripts.OnClick(button, "RightButton")
assert(toggles == 1 and button.enabled, "minimap click mapping incorrect")
button.scripts.OnDragStart()
assert(button.scripts.OnUpdate)
cursorX, cursorY = 200, 400 -- screen coordinates, scale two: directly above center
button.scripts.OnUpdate()
assert(math.abs(ApogeeTankUIDB.minimapAngle - 90) < 0.001, "scaled cursor saved wrong angle")
local saved = ApogeeTankUIDB
GameTooltip.owner, GameTooltip.shown = {}, true
combat = true; Event("PLAYER_REGEN_DISABLED")
assert(GameTooltip.shown, "minimap hid another UI tooltip on combat entry")
assert(not button.enabled and not button.scripts.OnUpdate, "combat left drag or picker active")
button.scripts.OnClick(button, "LeftButton"); button.scripts.OnDragStart()
assert(toggles == 1 and not button.scripts.OnUpdate, "combat callback bypassed guard")
combat = false; Event("PLAYER_REGEN_ENABLED")
button.scripts.OnDragStart(); Event("PLAYER_LEAVING_WORLD")
assert(not button.enabled and not button.scripts.OnUpdate, "zoning left drag running")
Event("PLAYER_ENTERING_WORLD")
assert(button.enabled and toggles == 1, "world entry unexpectedly reopened picker")
frames, named = {}, {}
Start(); Event("PLAYER_LOGIN")
button = named.ApogeeTankMinimapButton
assert(ApogeeTankUIDB == saved and math.abs(button.point[4]) < 0.001 and button.point[5] == 80,
    "reload lost saved minimap placement")
for _, invalid in ipairs({ "broken", math.huge, 0/0 }) do
    frames, named = {}, {}
    ApogeeTankUIDB = { minimapAngle = invalid }
    Start(); Event("PLAYER_LOGIN")
    button = named.ApogeeTankMinimapButton
    assert(button.point[4] < 0 and button.point[5] > 0, "invalid angle did not use safe default")
end
print("Minimap access, scaled dragging, persistence, combat/zoning and invalid data passed")
