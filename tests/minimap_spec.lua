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
    function f:SetTexture(texture) self.texture = texture end
    function f:SetTexCoord(...) self.texCoord = {...} end
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
assert(ApogeeTankUIDB == nil, "minimap initialized saved data")
assert(button.width == 32 and button.height == 32 and button.icon.width == 20 and button.icon.height == 20)
assert(button.icon.texture == "Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES",
    "minimap icon is not the native role shield texture")
assert(table.concat(button.icon.texCoord, ",") == table.concat({0, 19/64, 22/64, 41/64}, ","),
    "minimap icon does not crop the native tank shield")
ready = true; Event("PLAYER_ENTERING_WORLD")
button.scripts.OnClick(button, "LeftButton")
button.scripts.OnClick(button, "RightButton")
assert(toggles == 1 and button.enabled, "minimap click mapping incorrect")
button.scripts.OnDragStart()
assert(button.scripts.OnUpdate)
cursorX, cursorY = 200, 400 -- screen coordinates, scale two: directly above center
button.scripts.OnUpdate()
assert(math.abs(button.point[4]) < 0.001 and button.point[5] == 90, "scaled cursor produced wrong session angle")
assert(ApogeeTankUIDB == nil, "drag created saved data")
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
assert(ApogeeTankUIDB == saved and button.point[4] < 0 and button.point[5] < 0,
    "reload did not restore default placement")
for _, invalid in ipairs({ 90, 135, 225, "broken", math.huge, 0/0 }) do
    frames, named = {}, {}
    ApogeeTankUIDB = { minimapAngle = invalid }
    Start(); Event("PLAYER_LOGIN")
    button = named.ApogeeTankMinimapButton
    assert(button.point[4] < 0 and button.point[5] < 0, "invalid angle did not use safe default")
end
print("Minimap access, session dragging, reload reset, combat/zoning and ignored historical data passed")

local nativeSizes = 0
local function DefaultAngle(radius)
    return 220 + math.max(15, math.deg(2 * math.asin(math.min(1, 46 / (2 * radius)))))
end
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
    b.scripts.OnDragStart()
    cursorX = (centerX + 100 * math.cos(math.rad(degrees))) * mapScale
    cursorY = (centerY + 100 * math.sin(math.rad(degrees))) * mapScale
    b.scripts.OnUpdate()
    b.scripts.OnDragStop()
    local x, y = b.point[4], b.point[5]
    local radius = math.max(width, height) / 2 + 20
    assert(math.abs(math.sqrt(x * x + y * y) - radius) < 0.00001,
        "minimap orbit did not maintain constant circular radius")
    assert(math.abs(x - radius * math.cos(math.rad(degrees))) < 0.00001
        and math.abs(y - radius * math.sin(math.rad(degrees))) < 0.00001,
        "minimap placement changed the requested angle")
    assert(radius - math.max(width, height) / 2 - 16 >= 4, "button lost circular rim clearance")
    assert(ApogeeTankUIDB.minimapAngle == degrees, "session drag rewrote historical data")
    return {x, y}
end
for _, dimensions in ipairs({{120,120,80}, {140,140,90}, {200,200,120}, {120,200,120}, {200,120,120}, {300,100,170}, {100,300,170}, {400,400,220}}) do
    for _, degrees in ipairs({0, 12, 45, 90, 135, 180, 225, 270, 315, 333, -30, 732}) do
        local point = PointAt(degrees, dimensions[1], dimensions[2])
        assert(math.abs(math.sqrt(point[1]^2 + point[2]^2) - dimensions[3]) < 0.00001)
    end
    local defaultButton = Fresh(nil, dimensions[1], dimensions[2])
    assert(math.abs(defaultButton.point[4] - dimensions[3] * math.cos(math.rad(DefaultAngle(dimensions[3])))) < 0.00001
        and math.abs(defaultButton.point[5] - dimensions[3] * math.sin(math.rad(DefaultAngle(dimensions[3])))) < 0.00001
        and ApogeeTankUIDB.minimapAngle == nil, "fresh Tank default geometry changed or was persisted")
    local positions = {}
    local spacing = DefaultAngle(dimensions[3]) - 220
    -- Screenshot artwork order: Heals upper-left, Keybinds middle, Tank lower-right.
    for _, degrees in ipairs({220 - spacing, 220, 220 + spacing}) do
        positions[#positions + 1] = PointAt(degrees, dimensions[1], dimensions[2])
    end
    assert(positions[1][1] < positions[2][1] and positions[2][1] < positions[3][1]
        and positions[1][2] > positions[2][2] and positions[2][2] > positions[3][2],
        "family defaults lost upper-left to lower-right order")
    for i = 1, 3 do
        for j = i + 1, 3 do
            assert(math.abs(positions[i][1] - positions[j][1]) >= 32
                or math.abs(positions[i][2] - positions[j][2]) >= 32, "default family buttons overlap")
        end
    end
end
for _, degrees in ipairs({0, 90, 135, 180, 270, -30, 720 + 12}) do PointAt(degrees, 200, 140) end
button = Fresh(135, 140, 140)
assert(button.point[4] < 0 and button.point[5] < 0 and ApogeeTankUIDB.minimapAngle == 135,
    "historical angle affected placement or was overwritten")
local oldPoint, previousNative = button.point, nativeSizes
mapWidth, mapHeight = 400, 300
Minimap.scripts.OnSizeChanged(Minimap)
assert(nativeSizes == previousNative + 1 and button.point ~= oldPoint,
    "resize hook replaced native handler or failed to reposition")
assert(math.abs(button.point[4] - 220 * math.cos(math.rad(235))) < 0.00001
    and math.abs(button.point[5] - 220 * math.sin(math.rad(235))) < 0.00001,
    "undragged default did not adapt to resized reference cluster")
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
assert(ApogeeTankUIDB.minimapAngle == nil and math.abs(button.point[4]) < 0.00001 and button.point[5] == 90)
button.scripts.OnDragStop(); button.scripts.OnClick(button, "LeftButton")
assert(toggles == oldToggles and not button.scripts.OnUpdate, "drag release triggered a click")
button.scripts.OnMouseDown(button, "LeftButton"); button.scripts.OnClick(button, "LeftButton")
assert(toggles == oldToggles + 1, "new intentional click remained suppressed")
button.scripts.OnMouseDown(button, "RightButton"); button.scripts.OnDragStart(); button:Hide()
assert(not button.scripts.OnUpdate and ApogeeTankUIDB.minimapAngle == nil)
button:Show()
-- No post-drag click was emitted; the next genuine mouse-down must still work.
button.scripts.OnMouseDown(button, "LeftButton"); button.scripts.OnClick(button, "LeftButton")
assert(toggles == oldToggles + 2)
assert(not button.scripts.OnUpdate, "idle minimap button kept polling")
print("Circular minimap orbit, exact default radii, default separation, session angles, native resize hooks and drag/click guards passed")

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
assert(ApogeeTankUIDB.minimapAngle == nil and math.abs(button.point[4]) < 0.00001 and button.point[5] == 90,
    "valid session drag did not recover after restricted inputs")
cursorX, cursorY = 0, 200 -- candidate180 must not persist or replace last valid90
oldPoint = button.point
mapFrameLevel = restricted; button.scripts.OnUpdate()
assert(ApogeeTankUIDB.minimapAngle == nil and button.point == oldPoint,
    "restricted frame level persisted failed drag placement")
mapFrameLevel = 1; mapWidth = restricted; button.scripts.OnUpdate()
assert(ApogeeTankUIDB.minimapAngle == nil and button.point == oldPoint,
    "restricted dimensions persisted failed drag placement")
mapWidth = 0; button.scripts.OnUpdate()
assert(ApogeeTankUIDB.minimapAngle == nil and button.point == oldPoint,
    "invalid dimensions persisted failed drag placement")
button.scripts.OnDragStop()
mapWidth = 140; Event("UI_SCALE_CHANGED")
assert(math.abs(button.point[4]) < 0.00001 and button.point[5] == 90
    and ApogeeTankUIDB.minimapAngle == nil, "failed drag replaced the remembered session angle")
print("Restricted frame level, dimensions, center, scale and cursor inputs defer safely")

-- Session angle survives world/size changes, but a new UI instance resets to the cluster.
button = Fresh(135, 140, 140)
button.scripts.OnDragStart(); cursorX, cursorY = 200, 400; button.scripts.OnUpdate(); button.scripts.OnDragStop()
mapWidth = 200; Minimap.scripts.OnSizeChanged(Minimap)
Event("PLAYER_LEAVING_WORLD"); Event("PLAYER_ENTERING_WORLD")
assert(math.abs(button.point[4]) < 0.00001 and button.point[5] == 120
    and ApogeeTankUIDB.minimapAngle == 135, "session angle lost on resize/zoning or saved field mutated")
frames, named = {}, {}; Start(); Event("PLAYER_LOGIN")
button = named.ApogeeTankMinimapButton
assert(math.abs(button.point[4] - 120 * math.cos(math.rad(DefaultAngle(120)))) < 0.00001
    and math.abs(button.point[5] - 120 * math.sin(math.rad(DefaultAngle(120)))) < 0.00001
    and ApogeeTankUIDB.minimapAngle == 135, "reload reused drag or changed historical data")
-- Any accidental read/write of the old saved field fails, including during drag.
frames, named = {}, {}
ApogeeTankUIDB = setmetatable({}, {__index = function() error("historical UI data read") end,
    __newindex = function() error("historical UI data written") end})
Start(); Event("PLAYER_LOGIN")
button = named.ApogeeTankMinimapButton
button.scripts.OnDragStart(); button.scripts.OnUpdate(); button.scripts.OnDragStop()
print("Adaptive reference cluster, session continuity, reload reset and zero saved-field access passed")
