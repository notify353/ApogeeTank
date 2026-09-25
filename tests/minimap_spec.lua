local addon, frames, named = {}, {}, {}
local combat, ready, toggles, cursorX, cursorY = false, false, 0, 100, 260
local mapWidth, mapHeight, mapScale = 140, 140, 2
local mapFrameLevel, centerX, centerY = 1, 100, 100
function InCombatLockdown() return combat end
function UnitAffectingCombat() return combat end
local function Frame(_, name, parent)
    local f = { scripts = {}, events = {}, parent = parent }
    function f:SetSize(w, h) self.width, self.height = w, h end
    function f:GetWidth() return mapWidth end
    function f:GetHeight() return mapHeight end
    function f:EnableMouse() end
    function f:SetFrameStrata() end
    function f:SetFrameLevel(level) self.level = level end
    function f:GetFrameLevel() return mapFrameLevel end
    function f:RegisterForClicks() end
    function f:RegisterForDrag(...) self.drag = {...} end
    function f:CreateTexture() return Frame() end
    function f:SetPoint(...) assert(not combat); self.point = {...} end
    function f:ClearAllPoints() end
    function f:SetTexture() end
    function f:SetHighlightTexture() end
    function f:SetAlpha(a) self.alpha = a end
    function f:SetEnabled(b) self.enabled = b end
    function f:SetScript(k, v) self.scripts[k] = v end
    function f:HookScript(k, v)
        local original = self.scripts[k]
        self.scripts[k] = function(...) if original then original(...) end; v(...) end
    end
    function f:Hide() self.shown = false; if self.scripts.OnHide then self.scripts.OnHide(self) end end
    function f:Show() self.shown = true end
    function f:RegisterEvent(e) self.events[e] = true end
    function f:GetCenter() return centerX, centerY end
    function f:GetEffectiveScale() return mapScale end
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
assert(button.point[4] < 0 and button.point[5] < 0, "default is not lower-left")
assert(ApogeeTankUIDB.minimapAngle == nil, "default angle was persisted as a user choice")
assert(button.width == 32 and button.height == 32 and button.icon.width == 20 and button.icon.height == 20)
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
assert(ApogeeTankUIDB == saved and math.abs(button.point[4]) < 0.001 and button.point[5] == 110,
    "reload lost saved minimap placement")
for _, invalid in ipairs({ "broken", math.huge, 0/0 }) do
    frames, named = {}, {}
    ApogeeTankUIDB = { minimapAngle = invalid }
    Start(); Event("PLAYER_LOGIN")
    button = named.ApogeeTankMinimapButton
    assert(button.point[4] < 0 and button.point[5] < 0, "invalid angle did not use safe default")
end
print("Minimap access, scaled dragging, persistence, combat/zoning and invalid data passed")

local nativeSizes = 0
local function Fresh(savedAngle, width, height)
    frames, named = {}, {}
    mapWidth, mapHeight, mapScale, combat, ready = width, height, 2, false, true
    mapFrameLevel, centerX, centerY = 1, 100, 100
    Minimap = Frame()
    Minimap:SetScript("OnSizeChanged", function() nativeSizes = nativeSizes + 1 end)
    ApogeeTankUIDB = savedAngle ~= nil and {minimapAngle = savedAngle} or {}
    Start(); Event("PLAYER_LOGIN")
    return named.ApogeeTankMinimapButton
end
local function PointAt(degrees, width, height)
    local b = Fresh(degrees, width, height)
    local x, y = b.point[4], b.point[5]
    assert(math.abs(x) >= width / 2 + 20 - 0.00001
        or math.abs(y) >= height / 2 + 20 - 0.00001, "button intersected expanded minimap bounds")
    assert(x * x + y * y >= 110 * 110 - 0.00001)
    assert(ApogeeTankUIDB.minimapAngle == degrees, "build rewrote a prior drag angle")
    return {x, y}
end
for _, dimensions in ipairs({{120,120}, {140,140}, {200,200}, {120,200}, {200,120}, {300,100}, {100,300}}) do
    local positions = {}
    for _, degrees in ipairs({190, 225, 260}) do
        positions[#positions + 1] = PointAt(degrees, dimensions[1], dimensions[2])
    end
    for i = 1, 3 do
        for j = i + 1, 3 do
            assert(math.abs(positions[i][1] - positions[j][1]) >= 32
                or math.abs(positions[i][2] - positions[j][2]) >= 32, "default family buttons overlap")
        end
    end
end
for _, degrees in ipairs({0, 90, 135, 180, 270, -30, 720 + 12}) do PointAt(degrees, 200, 140) end
button = Fresh(135, 140, 140)
assert(button.point[4] < 0 and button.point[5] > 0, "old135 drag was mistaken for a default")
local oldPoint, previousNative = button.point, nativeSizes
mapWidth, mapHeight = 400, 300
Minimap.scripts.OnSizeChanged(Minimap)
assert(nativeSizes == previousNative + 1 and button.point ~= oldPoint,
    "resize hook replaced native handler or failed to reposition")
oldPoint = button.point
combat = true; mapWidth = 500; Minimap.scripts.OnSizeChanged(Minimap)
Event("UI_SCALE_CHANGED")
assert(button.point == oldPoint, "combat reposition was not deferred")
combat = false; Event("PLAYER_REGEN_ENABLED")
assert(button.point ~= oldPoint, "combat exit lost pending reposition")
oldPoint = button.point
Event("PLAYER_LEAVING_WORLD"); mapWidth = 600; Event("DISPLAY_SIZE_CHANGED")
assert(button.point == oldPoint)
Event("PLAYER_ENTERING_WORLD"); assert(button.point ~= oldPoint)

button = Fresh(nil, 0, 140)
assert(not button.point and not button.shown and ApogeeTankUIDB.minimapAngle == nil,
    "invalid dimensions fabricated initial placement")
mapWidth = 140; Minimap.scripts.OnSizeChanged(Minimap)
assert(button.point and button.shown and ApogeeTankUIDB.minimapAngle == nil)
oldPoint = button.point
for _, invalid in ipairs({0, -1, math.huge, 0/0, "bad"}) do
    mapWidth = invalid; Event("UI_SCALE_CHANGED")
    assert(button.point == oldPoint, "invalid dimensions changed placement")
end
mapWidth = 140
local oldToggles = toggles
button.scripts.OnMouseDown(button, "RightButton")
GameTooltip.owner, GameTooltip.shown = button, true
button.scripts.OnDragStart()
assert(not GameTooltip.shown)
cursorX, cursorY, mapScale = math.huge, 400, 2
button.scripts.OnUpdate(); assert(ApogeeTankUIDB.minimapAngle == nil)
cursorX, cursorY, mapScale = 200, 400, 0
button.scripts.OnUpdate(); assert(ApogeeTankUIDB.minimapAngle == nil)
mapScale = 2; button.scripts.OnUpdate()
assert(math.abs(ApogeeTankUIDB.minimapAngle - 90) < 0.00001)
button.scripts.OnDragStop(); button.scripts.OnClick(button, "LeftButton")
assert(toggles == oldToggles and not button.scripts.OnUpdate, "drag release triggered a click")
button.scripts.OnMouseDown(button, "LeftButton"); button.scripts.OnClick(button, "LeftButton")
assert(toggles == oldToggles + 1, "new intentional click remained suppressed")
button.scripts.OnMouseDown(button, "RightButton"); button.scripts.OnDragStart(); button:Hide()
assert(not button.scripts.OnUpdate and ApogeeTankUIDB.minimapAngle == 90)
button:Show()
-- No post-drag click was emitted; the next genuine mouse-down must still work.
button.scripts.OnMouseDown(button, "LeftButton"); button.scripts.OnClick(button, "LeftButton")
assert(toggles == oldToggles + 2)
assert(not button.scripts.OnUpdate, "idle minimap button kept polling")
print("Shared minimap bounds, default separation, preserved angles, native resize hooks and drag/click guards passed")

local restricted = setmetatable({}, {__add = function() error("restricted arithmetic") end,
    __div = function() error("restricted arithmetic") end, __lt = function() error("restricted comparison") end})
issecretvalue = function(value) return rawequal(value, restricted) end
button = Fresh(nil, 140, 140)
oldPoint = button.point
mapFrameLevel = restricted; Event("UI_SCALE_CHANGED")
assert(button.point == oldPoint and button.level == 21, "restricted frame level was used")
mapFrameLevel = 1; mapWidth = restricted; Minimap.scripts.OnSizeChanged(Minimap)
assert(button.point == oldPoint, "restricted dimensions were used")
mapWidth = 140; Event("DISPLAY_SIZE_CHANGED")
button.scripts.OnMouseDown(button, "RightButton"); button.scripts.OnDragStart()
centerX = restricted; button.scripts.OnUpdate(); assert(ApogeeTankUIDB.minimapAngle == nil)
centerX = nil; button.scripts.OnUpdate(); assert(ApogeeTankUIDB.minimapAngle == nil)
centerX = 100; mapScale = restricted; button.scripts.OnUpdate(); assert(ApogeeTankUIDB.minimapAngle == nil)
mapScale = 2; cursorX = restricted; button.scripts.OnUpdate(); assert(ApogeeTankUIDB.minimapAngle == nil)
cursorX, cursorY = 200, 400; button.scripts.OnUpdate()
assert(ApogeeTankUIDB.minimapAngle == 90, "valid drag did not recover after restricted inputs")
button.scripts.OnDragStop()
print("Restricted frame level, dimensions, center, scale and cursor inputs defer safely")
