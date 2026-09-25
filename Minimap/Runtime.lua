local _, addon = ...
local DEFAULT_ANGLE = 190
local function Finite(value)
    if issecretvalue and issecretvalue(value) then return false end
    if canaccessvalue and not canaccessvalue(value) then return false end
    return type(value) == "number" and value == value and math.abs(value) < math.huge
end

function addon.StartMinimap(picker)
    local driver = CreateFrame("Frame")
    local button, angle, inWorld = nil, DEFAULT_ANGLE, true
    local pendingPosition, suppressClick = true, false
    local function CanConfigure()
        return inWorld and picker.CanConfigure()
    end
    local function Position()
        if not button or not inWorld or InCombatLockdown() or UnitAffectingCombat("player") then return end
        local width, height = Minimap:GetWidth(), Minimap:GetHeight()
        if not Finite(width) or not Finite(height) or width <= 0 or height <= 0 then return end
        local level = Minimap:GetFrameLevel()
        if not Finite(level) or level < 0 then return end
        local radians = math.rad(angle)
        local c, s = math.cos(radians), math.sin(radians)
        -- Outside expanded rectangular bounds also clears round/unknown masks.
        local rx = math.abs(c) < 0.000001 and math.huge or (width / 2 + 20) / math.abs(c)
        local ry = math.abs(s) < 0.000001 and math.huge or (height / 2 + 20) / math.abs(s)
        local radius = math.max(110, math.min(rx, ry))
        button:SetFrameLevel(level + 20)
        button:ClearAllPoints()
        button:SetPoint("CENTER", Minimap, "CENTER", radius * c, radius * s)
        pendingPosition = false
        button:Show()
        return true
    end
    local function HideTooltip()
        if button and GameTooltip:IsOwned(button) then GameTooltip:Hide() end
    end
    local function StopDrag()
        if button then button:SetScript("OnUpdate", nil) end
        HideTooltip()
    end
    local function Update()
        if not button then return end
        local enabled = CanConfigure()
        button:SetEnabled(enabled)
        button.icon:SetAlpha(enabled and 1 or 0.45)
        if not enabled then StopDrag(); HideTooltip() end
        if pendingPosition then Position() end
    end
    local function Build()
        if button or not Minimap then return end
        if type(ApogeeTankUIDB) ~= "table" then ApogeeTankUIDB = {} end
        local saved = ApogeeTankUIDB.minimapAngle
        if Finite(saved) then
            angle = saved % 360
        end
        button = CreateFrame("Button", "ApogeeTankMinimapButton", Minimap)
        button:SetSize(32, 32)
        button:EnableMouse(true)
        button:SetFrameStrata("MEDIUM")
        button:RegisterForClicks("LeftButtonUp")
        button:RegisterForDrag("RightButton")
        button.icon = button:CreateTexture(nil, "ARTWORK")
        button.icon:SetSize(20, 20)
        button.icon:SetPoint("CENTER", button, "CENTER", 0, 0)
        button.icon:SetTexture("Interface\\AddOns\\ApogeeTank\\Media\\Textures\\ApogeeLogo.png")
        local border = button:CreateTexture(nil, "OVERLAY")
        border:SetSize(54, 54)
        border:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
        border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
        button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
        button:SetScript("OnMouseDown", function() suppressClick = false end)
        button:SetScript("OnClick", function(_, mouseButton)
            if suppressClick then suppressClick = false; return end
            if mouseButton == "LeftButton" and CanConfigure()
                and not IsShiftKeyDown() and not IsControlKeyDown() and not IsAltKeyDown() then
                picker.Toggle()
            end
        end)
        button:SetScript("OnDragStart", function()
            if not CanConfigure() then return end
            suppressClick = true
            HideTooltip()
            button:SetScript("OnUpdate", function()
                if not CanConfigure() then StopDrag(); return end
                local x, y = Minimap:GetCenter()
                local scale = Minimap:GetEffectiveScale()
                if not Finite(x) or not Finite(y) or not Finite(scale) or scale <= 0 then return end
                local cursorX, cursorY = GetCursorPosition()
                if not Finite(cursorX) or not Finite(cursorY) then return end
                local dx, dy = cursorX / scale - x, cursorY / scale - y
                if not Finite(dx) or not Finite(dy) or (dx == 0 and dy == 0) then return end
                local previousAngle = angle
                angle = math.deg(math.atan2(dy, dx)) % 360
                pendingPosition = true
                if Position() then ApogeeTankUIDB.minimapAngle = angle
                else angle = previousAngle end
            end)
        end)
        button:SetScript("OnDragStop", StopDrag)
        button:SetScript("OnEnter", function()
            if not CanConfigure() then return end
            GameTooltip:SetOwner(button, "ANCHOR_LEFT")
            GameTooltip:SetText("Apogee Tank")
            GameTooltip:AddLine("Left-click: spells and preview.", 1, 1, 1)
            GameTooltip:AddLine("Right-drag: move around minimap.", 1, 1, 1)
            GameTooltip:AddLine("Target meter: left skull, right X, Shift-left moon.", 0.8, 0.8, 0.8, true)
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", HideTooltip)
        button:SetScript("OnHide", StopDrag)
        Minimap:HookScript("OnSizeChanged", function() pendingPosition = true; Position() end)
        button:Hide()
        Position()
        Update()
    end
    driver:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_LEAVING_WORLD" then inWorld = false
        elseif event == "PLAYER_ENTERING_WORLD" then inWorld = true end
        if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then Build() end
        pendingPosition = true
        Update()
    end)
    for _, event in ipairs({ "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "PLAYER_LEAVING_WORLD",
        "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "UI_SCALE_CHANGED", "DISPLAY_SIZE_CHANGED" }) do driver:RegisterEvent(event) end
end
