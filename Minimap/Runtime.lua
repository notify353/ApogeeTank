local _, addon = ...
local DEFAULT_ANGLE, RADIUS = 135, 80

function addon.StartMinimap(picker)
    local driver = CreateFrame("Frame")
    local button, angle, inWorld = nil, DEFAULT_ANGLE, true
    local function CanConfigure()
        return inWorld and picker.CanConfigure()
    end
    local function Position()
        local radians = math.rad(angle)
        button:ClearAllPoints()
        button:SetPoint("CENTER", Minimap, "CENTER", RADIUS * math.cos(radians), RADIUS * math.sin(radians))
    end
    local function StopDrag()
        if button then button:SetScript("OnUpdate", nil) end
    end
    local function HideTooltip()
        if button and GameTooltip:IsOwned(button) then GameTooltip:Hide() end
    end
    local function Update()
        if not button then return end
        local enabled = CanConfigure()
        button:SetEnabled(enabled)
        button.icon:SetAlpha(enabled and 1 or 0.45)
        if not enabled then StopDrag(); HideTooltip() end
    end
    local function Build()
        if button or not Minimap then return end
        if type(ApogeeTankUIDB) ~= "table" then ApogeeTankUIDB = {} end
        local saved = ApogeeTankUIDB.minimapAngle
        if type(saved) == "number" and saved == saved and math.abs(saved) < math.huge then
            angle = saved % 360
        end
        button = CreateFrame("Button", "ApogeeTankMinimapButton", Minimap)
        button:SetSize(32, 32)
        button:EnableMouse(true)
        button:SetFrameStrata("MEDIUM")
        button:SetFrameLevel(Minimap:GetFrameLevel() + 20)
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
        button:SetScript("OnClick", function(_, mouseButton)
            if mouseButton == "LeftButton" and CanConfigure()
                and not IsShiftKeyDown() and not IsControlKeyDown() and not IsAltKeyDown() then
                picker.Toggle()
            end
        end)
        button:SetScript("OnDragStart", function()
            if not CanConfigure() then return end
            button:SetScript("OnUpdate", function()
                if not CanConfigure() then StopDrag(); return end
                local x, y = Minimap:GetCenter()
                local scale = Minimap:GetEffectiveScale()
                if not x or not y or not scale or scale <= 0 then return end
                local cursorX, cursorY = GetCursorPosition()
                angle = math.deg(math.atan2(cursorY / scale - y, cursorX / scale - x)) % 360
                ApogeeTankUIDB.minimapAngle = angle
                Position()
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
        Position()
        Update()
    end
    driver:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_LEAVING_WORLD" then inWorld = false
        elseif event == "PLAYER_ENTERING_WORLD" then inWorld = true end
        if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then Build() end
        Update()
    end)
    for _, event in ipairs({ "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "PLAYER_LEAVING_WORLD",
        "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED" }) do driver:RegisterEvent(event) end
end
