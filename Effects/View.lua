local _, addon = ...
local View = {}
addon.EffectsView = View
local ICON_SIZE, ICON_GAP, ICON_COLUMNS = 18, 2, 4

local function ShowTooltip(frame, effect, note)
    GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
    if effect.spellId then GameTooltip:SetSpellByID(effect.spellId)
    else GameTooltip:SetText(effect.name) end
    if note then GameTooltip:AddLine(note, 1, 0.82, 0.2, true) end
    GameTooltip:Show()
end

local function Tooltip(frame, effect, note)
    frame:SetScript("OnEnter", function(self)
        ShowTooltip(self, effect, note)
    end)
    frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

function View.Create(model, onChanged, onCleared, canConfigure, onVisibility, cooldowns)
    local self, lanes, columns = {}, {}, {}
    local window
    local RefreshWindow
    local function RefreshColumn(column)
        local model, rows = column.model, column.rows
        local content, scroll, empty = column.content, column.scroll, column.empty
        if column.revision == model.GetRevision() then return end
        column.revision = model.GetRevision()
        local entries = model.GetEntries()
        empty:SetShown(#entries == 0)
        for index, effect in ipairs(entries) do
            local row = rows[index]
            if not row then
                row = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
                row:SetSize(26, 26)
                row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -(index - 1) * 32)
                row.icon = row:CreateTexture(nil, "ARTWORK")
                row.icon:SetSize(20, 20)
                row.icon:SetPoint("LEFT", row, "RIGHT", 4, 0)
                row.label = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
                row.label:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
                row.label:SetWidth(212)
                row.label:SetJustifyH("LEFT")
                row.label:SetWordWrap(false)
                row.hover = CreateFrame("Frame", nil, row)
                row.hover:SetPoint("LEFT", row, "RIGHT", 4, 0)
                row.hover:SetSize(238, 26)
                row.hover:EnableMouse(true)
                rows[index] = row
            end
            row:SetChecked(effect.watched == true)
            row.icon:SetTexture(effect.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
            row.label:SetText(effect.name)
            Tooltip(row, effect)
            Tooltip(row.hover, effect)
            row:SetScript("OnClick", function(button)
                if canConfigure and not canConfigure() then
                    button:SetChecked(model.IsWatched(effect.spellId))
                    return
                end
                local _, reason = model.SetWatched(effect.spellId, button:GetChecked())
                onChanged()
                if column.cooldown then cooldowns.Refresh() end
                RefreshWindow()
                if reason then ShowTooltip(button, effect, reason) end
            end)
            row:Show()
        end
        for index = #entries + 1, #rows do rows[index]:Hide() end
        content:SetHeight(math.max(210, #entries * 32))
        scroll:UpdateScrollChildRect()
    end
    RefreshWindow = function()
        if not window or not window:IsShown() then return end
        for _, column in ipairs(columns) do RefreshColumn(column) end
    end
    local function Disarm(column)
        column.confirm:Hide()
        column.clear:SetText("Clear")
    end
    local function BuildColumn(title, columnModel, left, isCooldown)
        local column = { model = columnModel, rows = {}, cooldown = isCooldown }
        columns[#columns + 1] = column
        local heading = window:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        heading:SetPoint("TOPLEFT", window, "TOPLEFT", left, -16)
        heading:SetText(title)
        local scroll = CreateFrame("ScrollFrame", nil, window, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", window, "TOPLEFT", left, -42)
        scroll:SetSize(286, 222)
        local content = CreateFrame("Frame", nil, scroll)
        content:SetSize(286, 222)
        scroll:SetScrollChild(content)
        column.scroll, column.content = scroll, content
        column.empty = content:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
        column.empty:SetPoint("TOPLEFT", content, "TOPLEFT", 4, -8)
        column.empty:SetText("None learned")
        local clear = CreateFrame("Button", "ApogeeTank" .. title .. "Clear", window, "UIPanelButtonTemplate")
        clear:SetSize(62, 22)
        clear:SetPoint("BOTTOMLEFT", window, "BOTTOMLEFT", left, 14)
        clear:SetText("Clear")
        local confirm = CreateFrame("Button", "ApogeeTank" .. title .. "ConfirmClear", window, "UIPanelButtonTemplate")
        confirm:SetSize(92, 22)
        confirm:SetPoint("LEFT", clear, "RIGHT", 12, 0)
        confirm:SetText("Confirm clear")
        column.clear, column.confirm = clear, confirm
        confirm:Hide()
        clear:SetScript("OnClick", function()
            if canConfigure and not canConfigure() then return end
            if confirm:IsShown() then Disarm(column)
            else clear:SetText("Cancel"); confirm:Show() end
        end)
        confirm:SetScript("OnClick", function()
            if not confirm:IsShown() or (canConfigure and not canConfigure()) then return end
            columnModel.Clear()
            Disarm(column)
            if isCooldown then cooldowns.Clear()
            else
                if onCleared then onCleared() end
                self.Render({})
            end
            scroll:SetVerticalScroll(0)
            RefreshWindow()
        end)
    end
    local function BuildWindow()
        if window then return end
        window = CreateFrame("Frame", "ApogeeTankEffectsWindow", UIParent, "BackdropTemplate")
        window:SetSize(680, 312)
        window:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        window:SetFrameStrata("DIALOG")
        window:EnableMouse(true)
        window:SetMovable(true)
        window:SetClampedToScreen(true)
        window:RegisterForDrag("LeftButton")
        window:SetScript("OnDragStart", function()
            if not canConfigure or canConfigure() then window:StartMoving() end
        end)
        window:SetScript("OnDragStop", function() window:StopMovingOrSizing() end)
        window:SetScript("OnShow", function() if onVisibility then onVisibility(true) end end)
        window:SetScript("OnHide", function()
            window:StopMovingOrSizing()
            for _, column in ipairs(columns) do Disarm(column) end
            if onVisibility then onVisibility(false) end
        end)
        window:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
        window:SetBackdropColor(0.035, 0.04, 0.05, 0.98)
        window:SetBackdropBorderColor(0.25, 0.28, 0.32, 1)
        local divider = window:CreateTexture(nil, "BACKGROUND")
        divider:SetPoint("TOP", window, "TOP", 0, -14)
        divider:SetSize(1, 280)
        divider:SetColorTexture(0.25, 0.28, 0.32, 0.5)
        local close = CreateFrame("Button", nil, window, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", window, "TOPRIGHT", -2, -2)
        close:SetScript("OnClick", function() window:Hide() end)
        if cooldowns and cooldowns.GetModel() then BuildColumn("Cooldowns", cooldowns.GetModel(), 358, true) end
        BuildColumn("Debuffs", model, 18, false)
        UISpecialFrames = UISpecialFrames or {}
        UISpecialFrames[#UISpecialFrames + 1] = "ApogeeTankEffectsWindow"
        window:Hide()
    end
    local function HideLane(lane)
        for _, icon in ipairs(lane.icons) do icon:Hide() end
        if lane.overflow then lane.overflow:Hide() end
    end
    function self.Render(presentations)
        local active = {}
        for _, presentation in ipairs(presentations) do
            local anchor, missing = presentation.anchor, presentation.missing
            active[anchor] = true
            local lane = lanes[anchor]
            if not lane then lane = { icons = {} }; lanes[anchor] = lane end
            if lane.guid ~= presentation.guid then HideLane(lane) end
            lane.guid = presentation.guid
            local visibleCount = math.min(#missing, ICON_COLUMNS)
            for index = 1, visibleCount do
                local effect = missing[index]
                local icon = lane.icons[index]
                if not icon then
                    icon = CreateFrame("Frame", nil, anchor)
                    icon:SetSize(ICON_SIZE, ICON_SIZE)
                    -- The HUD supplies the meter anchor; reminders fill its left gap.
                    icon:SetPoint("RIGHT", presentation.missingAnchor or anchor, "LEFT",
                        -5 - (index - 1) * (ICON_SIZE + ICON_GAP), 0)
                    icon:EnableMouse(false)
                    icon.texture = icon:CreateTexture(nil, "ARTWORK")
                    icon.texture:SetAllPoints()
                    icon.texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)
                    lane.icons[index] = icon
                end
                icon.texture:SetTexture(effect.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
                icon:Show()
            end
            for index = visibleCount + 1, #lane.icons do lane.icons[index]:Hide() end
            if #missing > ICON_COLUMNS then
                if not lane.overflow then
                    local overflow = CreateFrame("Frame", nil, anchor)
                    overflow:SetSize(26, ICON_SIZE)
                    overflow:SetPoint("RIGHT", lane.icons[ICON_COLUMNS], "LEFT", -3, 0)
                    overflow:EnableMouse(false)
                    overflow.label = overflow:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
                    overflow.label:SetAllPoints()
                    lane.overflow = overflow
                end
                lane.overflow.label:SetText("+" .. (#missing - ICON_COLUMNS))
                lane.overflow:Show()
            elseif lane.overflow then
                lane.overflow:Hide()
            end
        end
        for anchor, lane in pairs(lanes) do
            if not active[anchor] then HideLane(lane); lane.guid = nil end
        end
        RefreshWindow()
    end
    function self.Toggle()
        if canConfigure and not canConfigure() then return end
        BuildWindow()
        window:SetShown(not window:IsShown())
        RefreshWindow()
    end
    function self.Close()
        if window then window:Hide() end
    end
    function self.Hide()
        for _, lane in pairs(lanes) do HideLane(lane) end
        if window then window:Hide() end
    end
    return self
end
