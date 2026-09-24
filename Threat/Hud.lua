-- Passive, fixed-position tank threat-control HUD.
local _, addon = ...
local A = {}
addon.ThreatHud = A
local Style = addon.Style

local ROW_INSET = 5
local CONTROL_BAR_WIDTH, CONTROL_BAR_HEIGHT, CONTROL_RIGHT = 112, 16, 7
local STATUS_BAR_HEIGHT = 5
-- Keep the original target meter screen position after removing the old layout.
local MARKER_WIDTH, WIDTH = Style.iconSize, 389
local ROW_HEIGHT = 24
local FIXED_ANCHOR_Y = 55
-- Preserve the existing target hit area; spells occupy the space above it.
local SPELL_SECTION_HEIGHT = 24
local COLORS = {
    unknown = { 0.5, 0.5, 0.5 },
    safe = Style.heldThreatColor, slipping = { 1.00, 0.82, 0.15 },
    critical = { 1.00, 0.35, 0.08 }, lost = { 1.00, 0.10, 0.10 },
}
local CAST_COLOR = { 1.00, 0.68, 0.12 }
local PROTECTED_CAST_COLOR = { 0.58, 0.58, 0.62 }
local D, frame, stanceAnchor, cooldownAnchor, guidanceAnchor
local rows = {}

local markerButton, markerSetupDriver
local function InitializeMarkerButton()
    if markerButton then return end
    if InCombatLockdown() then
        if not markerSetupDriver then
            markerSetupDriver = CreateFrame("Frame")
            markerSetupDriver:RegisterEvent("PLAYER_REGEN_ENABLED")
            markerSetupDriver:SetScript("OnEvent", InitializeMarkerButton)
        end
        return
    end
    local scale = Style.GetScale()
    -- Independent of the HUD: protected parent/anchor
    -- relationships must not prevent ordinary HUD updates during combat.
    local button = CreateFrame("Button", "ApogeeTankTargetMarkerButton", UIParent,
        "SecureActionButtonTemplate")
    button:SetScale(scale)
    button:SetSize(CONTROL_BAR_WIDTH, CONTROL_BAR_HEIGHT)
    button:SetPoint("TOPRIGHT", UIParent, "CENTER",
        WIDTH / 2 - ROW_INSET - CONTROL_RIGHT,
        FIXED_ANCHOR_Y / scale + (-SPELL_SECTION_HEIGHT) - 1)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(1)
    -- This native-visible meter remains an honest marking affordance even
    -- when the observer cannot read identity. It owns no threat estimate.
    -- Ordinary HUD content renders above it without protected relationships.
    Style.Background(button, Style.headerColor)
    local zeroLine = button:CreateTexture(nil, "OVERLAY")
    zeroLine:SetPoint("TOP", button, "TOP", 0, -1)
    zeroLine:SetPoint("BOTTOM", button, "BOTTOM", 0, 1)
    zeroLine:SetWidth(1); zeroLine:SetColorTexture(0.72, 0.72, 0.76, 0.9)
    button:RegisterForClicks("AnyDown")
    button:SetAttribute("useOnKeyDown", true)
    button:SetAttribute("unit", "target")
    button:SetAttribute("*action*", "set")
    button:SetAttribute("*type*", "")
    for _, prefix in ipairs({ "shift-", "ctrl-", "alt-", "ctrl-shift-",
        "alt-shift-", "alt-ctrl-", "alt-ctrl-shift-" }) do
        button:SetAttribute(prefix .. "harmbutton1", "")
        button:SetAttribute(prefix .. "harmbutton2", "")
    end
    -- Native secure-button remapping checks hostility at activation. Numeric
    -- buttons have no action, so friendly targets cannot fall through to one.
    -- No restricted snippet: this beta's snippet compiler failed live.
    button:SetAttribute("harmbutton1", "skull")
    button:SetAttribute("harmbutton2", "cross")
    button:SetAttribute("shift-harmbutton1", "moon")
    for name, id in pairs({ skull = 8, cross = 7, moon = 5 }) do
        button:SetAttribute("*type-" .. name, "raidtarget")
        button:SetAttribute("*marker-" .. name, id)
    end
    button:Hide()
    RegisterStateDriver(button, "visibility", "[@target,harm,nodead] show; hide")
    markerButton = button
    if rows[1] then rows[1].controlBg:Hide(); rows[1].zeroLine:Hide() end
    if markerSetupDriver then markerSetupDriver:UnregisterEvent("PLAYER_REGEN_ENABLED") end
end

local function NativeBar(parent)
    local bar = CreateFrame("StatusBar", nil, parent)
    bar:SetAllPoints()
    bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    bar:EnableMouse(false)
    return bar
end

local function SetHealthyHealthColor(texture)
    texture:SetColorTexture(unpack(Style.enemyHealthColor))
end


local function Clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

local function CreateRow(index)
    local row = CreateFrame("Frame", nil, frame)
    row:SetPoint("TOPLEFT", frame, "TOPLEFT", ROW_INSET,
        (-SPELL_SECTION_HEIGHT))
    row:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -ROW_INSET,
        (-SPELL_SECTION_HEIGHT))
    row:SetHeight(ROW_HEIGHT)
    row:EnableMouse(false)

    local marker = row:CreateTexture(nil, "ARTWORK")
    marker:SetSize(MARKER_WIDTH, MARKER_WIDTH)

    local statusBar = CreateFrame("Frame", nil, row)
    statusBar:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -CONTROL_RIGHT, 1)
    statusBar:SetSize(CONTROL_BAR_WIDTH, STATUS_BAR_HEIGHT)
    statusBar:EnableMouse(false)
    local statusBackground = statusBar:CreateTexture(nil, "BACKGROUND")
    statusBackground:SetAllPoints()
    statusBackground:SetColorTexture(unpack(Style.slotColor))
    local statusFill = statusBar:CreateTexture(nil, "ARTWORK")
    statusFill:SetPoint("TOPLEFT", statusBar, "TOPLEFT", 0, 0)
    statusFill:SetPoint("BOTTOMLEFT", statusBar, "BOTTOMLEFT", 0, 0)
    statusFill:SetWidth(0)
    SetHealthyHealthColor(statusFill)

    local controlBar = CreateFrame("Frame", nil, row)
    controlBar:SetPoint("TOPRIGHT", row, "TOPRIGHT", -CONTROL_RIGHT, -1)
    controlBar:SetSize(CONTROL_BAR_WIDTH, CONTROL_BAR_HEIGHT)
    controlBar:EnableMouse(false)
    -- Preserve the accessory gutter; the marker stay outside the meter.
    marker:SetPoint("LEFT", controlBar, "RIGHT", Style.iconGap, -(Style.iconSize - CONTROL_BAR_HEIGHT) / 2)

    local controlBg = controlBar:CreateTexture(nil, "BACKGROUND")
    controlBg:SetAllPoints(); controlBg:SetColorTexture(unpack(Style.headerColor))
    controlBg:SetShown(not markerButton)
    local controlFill = controlBar:CreateTexture(nil, "ARTWORK")
    controlFill:SetWidth(0)
    local zeroLine = controlBar:CreateTexture(nil, "OVERLAY")
    zeroLine:SetPoint("TOP", controlBar, "TOP", 0, -1)
    zeroLine:SetPoint("BOTTOM", controlBar, "BOTTOM", 0, 1)
    zeroLine:SetWidth(1); zeroLine:SetColorTexture(0.72, 0.72, 0.76, 0.9)
    zeroLine:SetShown(not markerButton)
    row.marker = marker
    row.statusBar, row.statusFill = statusBar, statusFill
    row.nativeHealth = NativeBar(statusBar)
    row.nativeHealth:SetStatusBarColor(unpack(Style.enemyHealthColor))
    row.controlBar, row.controlFill = controlBar, controlFill
    row.controlBg = controlBg
    row.zeroLine = zeroLine
    rows[index] = row
    return row
end

function A.GetControlDisplay(enemy)
    if not enemy or enemy.live == false or type(enemy.control) ~= "number" then return nil end
    local magnitude = Clamp(math.abs(enemy.control), 0, 100)
    local held = enemy.isTanking == true
    return {
        direction = held and "positive" or "negative",
        progress = magnitude,
    }
end

function A.GetSmoothedControlWidth(current, target, elapsed)
    current, target = tonumber(current), tonumber(target)
    if not target then return nil end
    if not current or math.abs(target - current) <= 0.1 then return target end
    local blend = Clamp((tonumber(elapsed) or 0) * 24, 0, 1)
    return current + (target - current) * blend
end

local function GetCastProgress(enemy, now)
    local cast = enemy and enemy.live ~= false and enemy.cast or nil
    local startTime = tonumber(cast and cast.startTime)
    local endTime = tonumber(cast and cast.endTime)
    now = tonumber(now)
    if not startTime or not endTime or not now or endTime <= startTime
        or now >= endTime then
        return nil
    end
    local progress
    if cast.isChannel == true then
        progress = (endTime - now) / (endTime - startTime)
    else
        progress = (now - startTime) / (endTime - startTime)
    end
    return Clamp(progress, 0, 1), cast.notInterruptible == true,
        cast.isChannel == true, cast.name
end

function A.GetCastDisplay(enemy, now)
    local progress, notInterruptible, isChannel, name = GetCastProgress(enemy, now)
    if progress == nil then return nil end
    return {
        progress = progress,
        notInterruptible = notInterruptible,
        isChannel = isChannel,
        name = name,
    }
end


local function RenderStatusBar(row, enemy, now)
    local castProgress, notInterruptible = GetCastProgress(enemy, now)
    row.nativeHealth:SetShown(castProgress == nil)
    if castProgress == nil then
        row.statusFill:Hide()
        row.statusBar:SetShown(D.UnitAPI.PaintNativeHealth(row.nativeHealth, "target"))
        return false
    end
    row.statusBar:Show()
    row.statusFill:Show()
    row.statusFill:SetWidth(CONTROL_BAR_WIDTH * castProgress)
    local color = notInterruptible and PROTECTED_CAST_COLOR or CAST_COLOR
    row.statusFill:SetColorTexture(color[1], color[2], color[3], 1)
    return castProgress ~= nil
end

local function ResetControlState(row)
    row.controlDirection = nil
    row.controlCurrentWidth = nil
    row.controlTargetWidth = nil
    row.controlFill:SetWidth(0)
end

local function SetControlDirection(row, direction)
    row.controlDirection = direction
    row.controlCurrentWidth = 0
    row.controlFill:SetWidth(0)
    row.controlFill:ClearAllPoints()
    if direction == "positive" then
        row.controlFill:SetPoint("TOPLEFT", row.controlBar, "TOP", 1, -1)
        row.controlFill:SetPoint("BOTTOMLEFT", row.controlBar, "BOTTOM", 1, 1)
    else
        row.controlFill:SetPoint("TOPRIGHT", row.controlBar, "TOP", -1, -1)
        row.controlFill:SetPoint("BOTTOMRIGHT", row.controlBar, "BOTTOM", -1, 1)
    end
end

local function HideRow(row)
    row.enemy = nil
    ResetControlState(row)
    row:Hide()
end

local function RenderRow(row, enemy, now)
    if not row.enemy or row.enemy.guid ~= enemy.guid then ResetControlState(row) end
    row.enemy = enemy
    local color = COLORS[enemy.severity] or COLORS.unknown
    row.marker:SetShown(D.UnitAPI.PaintNativeRaidMarker(row.marker, "target"))
    RenderStatusBar(row, enemy, now)

    local display = A.GetControlDisplay(enemy)
    row.controlBar:Show()
    if display then
        if row.controlDirection ~= display.direction then
            SetControlDirection(row, display.direction)
        end
        row.controlTargetWidth = (CONTROL_BAR_WIDTH / 2 - 2) * display.progress / 100
        if row.controlCurrentWidth == nil then
            row.controlCurrentWidth = row.controlTargetWidth
            row.controlFill:SetWidth(row.controlCurrentWidth)
        end
        row.controlFill:SetColorTexture(color[1], color[2], color[3], 1)
    else
        ResetControlState(row)
    end
    row:Show()
end


local function Render(snapshot)
    if not frame then return end
    local enemy = snapshot.currentTarget
    if enemy then RenderRow(rows[1], enemy, D.Now())
    else HideRow(rows[1]) end
    frame:Show()
end

function A.Tick(elapsed)
    if not frame or not frame:IsShown() then return end
    local now = D.Now()
    for _, row in ipairs(rows) do
        local enemy = row.enemy
        if enemy and enemy.cast then
            if not RenderStatusBar(row, enemy, now) then enemy.cast = nil end
        end
        local targetWidth = row.controlTargetWidth
        if targetWidth ~= nil and row.controlCurrentWidth ~= targetWidth then
            local width = A.GetSmoothedControlWidth(
                row.controlCurrentWidth, targetWidth, elapsed)
            row.controlCurrentWidth = width
            row.controlFill:SetWidth(width)
        end
    end
end

function A.Refresh()
    A.Build()
    local snapshot = D.Observer.Refresh()
    Render(snapshot)
    return snapshot
end

function A.Hide() if frame then frame:Hide() end end

function A.Build()
    InitializeMarkerButton()
    if frame then return frame end
    frame = CreateFrame("Frame", "ApogeeTankThreatHud", UIParent, "BackdropTemplate")
    local scale = Style.GetScale()
    frame:SetScale(scale)
    frame:SetSize(WIDTH, SPELL_SECTION_HEIGHT + ROW_HEIGHT + 5)
    -- The fixed top edge keeps spells and the protected target hit area stable.
    frame:SetPoint("TOP", UIParent, "CENTER", 0, FIXED_ANCHOR_Y / scale)
    frame:SetMovable(false); frame:EnableMouse(false); frame:SetFrameStrata("MEDIUM")
    frame:SetFrameLevel(10)
    local stride = Style.iconSize + Style.iconGap
    local stripWidth = Style.iconSize + 6 + 6 * stride + 20
    local stripLeft = WIDTH - ROW_INSET - CONTROL_RIGHT - CONTROL_BAR_WIDTH / 2 - stripWidth / 2
    local row = CreateRow(1)
    stanceAnchor = CreateFrame("Frame", nil, frame)
    stanceAnchor:SetPoint("RIGHT", row.controlBar, "LEFT", -Style.iconGap, -(Style.iconSize - CONTROL_BAR_HEIGHT) / 2)
    stanceAnchor:SetSize(Style.iconSize, Style.iconSize)
    cooldownAnchor = CreateFrame("Frame", nil, frame)
    cooldownAnchor:SetPoint("TOPLEFT", frame, "TOPLEFT", WIDTH - ROW_INSET - CONTROL_RIGHT - CONTROL_BAR_WIDTH, -1)
    cooldownAnchor:SetSize(6 * stride + 20, Style.iconSize)
    guidanceAnchor = CreateFrame("Frame", nil, frame)
    guidanceAnchor:SetPoint("TOPLEFT", frame, "TOPLEFT", stripLeft, -1)
    guidanceAnchor:SetSize(Style.iconSize, Style.iconSize)
    HideRow(row)
    frame:Hide()
    return frame
end

function A.Initialize(deps)
    D = deps
    assert(D and D.Observer and D.Now
            and D.UnitAPI,
        "ThreatAwareness missing dependencies")
end

function A.GetFrame() return frame end
function A.GetRows() return rows end
function A.GetStanceAnchor() return stanceAnchor end
function A.GetCooldownAnchor() return cooldownAnchor end

function A.GetGuidanceAnchor() return guidanceAnchor end

function A.GetStanceGeometry()
    local scale = Style.GetScale()
    return { scale = scale, size = Style.iconSize,
        x = WIDTH / 2 - ROW_INSET - CONTROL_RIGHT - CONTROL_BAR_WIDTH
            - Style.iconGap - Style.iconSize / 2,
        y = FIXED_ANCHOR_Y / scale - SPELL_SECTION_HEIGHT - 1 - Style.iconSize / 2 }
end

function A.GetCooldownGeometry(index)
    return { scale = Style.GetScale(), size = Style.iconSize,
        x = WIDTH / 2 - ROW_INSET - CONTROL_RIGHT - CONTROL_BAR_WIDTH
            + (index - 1) * (Style.iconSize + Style.iconGap),
        y = FIXED_ANCHOR_Y / Style.GetScale() - 1 }
end

function A.GetSealGeometry(index)
    local geometry = A.GetCooldownGeometry(index)
    geometry.y = FIXED_ANCHOR_Y / geometry.scale - SPELL_SECTION_HEIGHT - 1
        - CONTROL_BAR_HEIGHT - 1 - STATUS_BAR_HEIGHT - Style.iconGap
    return geometry
end
