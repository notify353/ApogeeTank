local _, addon = ...
local View = {}
addon.PickerView = View
local Style = addon.Style

local function ShowTooltip(frame, effect, note)
    GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
    if effect.spellId then GameTooltip:SetSpellByID(effect.spellId)
    else GameTooltip:SetText(effect.name) end
    if note then GameTooltip:AddLine(note, 1, 0.82, 0.2, true) end
    GameTooltip:Show()
end

local function HideTooltip(frame)
    if GameTooltip:IsOwned(frame) then GameTooltip:Hide() end
end

local function Tooltip(frame, effect, note)
    frame:SetScript("OnEnter", function(self)
        ShowTooltip(self, effect, note)
    end)
    frame:SetScript("OnLeave", function() HideTooltip(frame) end)
    frame:SetScript("OnHide", function() HideTooltip(frame) end)
end

-- The picker consumes cooldown selection operations, not private HUD frames.
function View.Create(options)
    local cooldowns = options.Cooldowns
    local onChanged = options.OnChanged
    local canConfigure = options.CanConfigure
    local self, column = {}, nil
    local window, preview
    local PREVIEW_HEIGHT = 120
    local RefreshWindow
    local function RefreshColumn(column)
        local model, rows = column.model, column.rows
        local content, scroll, empty = column.content, column.scroll, column.empty
        if column.revision == model.GetRevision() then return end
        -- Existing rows can be rebound to different spells after a selection.
        -- Do not leave the previous spell tooltip attached to the recycled row.
        for _, row in ipairs(rows) do HideTooltip(row); HideTooltip(row.hover) end
        column.revision = model.GetRevision()
        local entries = model.GetEntries()
        empty:SetShown(#entries == 0)
        for index, effect in ipairs(entries) do
            local row = rows[index]
            if not row then
                row = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
                row:SetSize(26, 26)
                row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -(index - 1) * 32)
                row.slot = CreateFrame("Frame", nil, row)
                row.slot:SetSize(Style.pickerIconSize, Style.pickerIconSize)
                row.slot:SetPoint("LEFT", row, "RIGHT", 4, 0)
                row.icon = Style.Icon(row.slot, Style.pickerIconInset)
                row.label = Style.Text(row)
                row.label:SetPoint("LEFT", row.slot, "RIGHT", 6, 0)
                row.label:SetWidth(208)
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
                cooldowns.Refresh()
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
        if column then RefreshColumn(column) end
        if preview then preview.Refresh() end
    end
    local function Disarm(column)
        column.confirm:Hide()
        column.clear:SetText("Clear")
    end
    local function BuildColumn(title, columnModel, left)
        column = { model = columnModel, rows = {} }
        local header = CreateFrame("Frame", nil, window)
        header:SetPoint("TOPLEFT", window, "TOPLEFT", left, -14 - PREVIEW_HEIGHT)
        header:SetSize(286, Style.headerHeight)
        Style.Background(header, Style.headerColor)
        local heading = Style.Text(header, Style.headerFontSize)
        heading:SetPoint("LEFT", header, "LEFT", 6, 0)
        heading:SetText(title)
        local scroll = CreateFrame("ScrollFrame", nil, window, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", window, "TOPLEFT", left, -42 - PREVIEW_HEIGHT)
        scroll:SetSize(286, 222)
        local content = CreateFrame("Frame", nil, scroll)
        content:SetSize(286, 222)
        scroll:SetScrollChild(content)
        column.scroll, column.content = scroll, content
        column.empty = Style.Text(content)
        column.empty:SetPoint("TOPLEFT", content, "TOPLEFT", 4, -8)
        column.empty:SetText("None learned")
        column.empty:SetTextColor(unpack(Style.mutedColor))
        local clear = CreateFrame("Button", "ApogeeTank" .. title .. "Clear", window, "UIPanelButtonTemplate")
        clear:SetSize(72, Style.buttonHeight)
        clear:SetPoint("BOTTOMLEFT", window, "BOTTOMLEFT", left, 14)
        clear:SetText("Clear")
        local confirm = CreateFrame("Button", "ApogeeTank" .. title .. "ConfirmClear", window, "UIPanelButtonTemplate")
        confirm:SetSize(112, Style.buttonHeight)
        confirm:SetPoint("LEFT", clear, "RIGHT", 4, 0)
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
            cooldowns.Clear()
            scroll:SetVerticalScroll(0)
            RefreshWindow()
        end)
    end
    local function BuildWindow()
        if window then return end
        window = CreateFrame("Frame", "ApogeeTankPickerWindow", UIParent, "BackdropTemplate")
        local width, height = 340, 312 + PREVIEW_HEIGHT
        local scale = math.min(Style.GetScale(), (UIParent:GetWidth() - 24) / width,
            (UIParent:GetHeight() - 24) / height)
        window:SetScale(scale)
        window:SetSize(width, height)
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
        window:SetScript("OnShow", function() if preview then preview.SetShown(true) end end)
        window:SetScript("OnHide", function()
            window:StopMovingOrSizing()
            if column then
                Disarm(column)
                for _, row in ipairs(column.rows) do HideTooltip(row); HideTooltip(row.hover) end
            end
            if preview then preview.SetShown(false) end
        end)
        window:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
        window:SetBackdropColor(unpack(Style.panelColor))
        window:SetBackdropBorderColor(unpack(Style.borderColor))
        preview = addon.CreatePickerPreview(window, {
            Cooldowns = cooldowns.GetModel(),
        })
        local close = CreateFrame("Button", nil, window, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", window, "TOPRIGHT", -2, -2)
        close:SetScript("OnClick", function() window:Hide() end)
        if cooldowns and cooldowns.GetModel() then
            BuildColumn("Cooldowns", cooldowns.GetModel(), 18)
        end
        UISpecialFrames = UISpecialFrames or {}
        UISpecialFrames[#UISpecialFrames + 1] = "ApogeeTankPickerWindow"
        window:Hide()
    end
    self.Refresh = RefreshWindow
    function self.Toggle()
        if canConfigure and not canConfigure() then return end
        BuildWindow()
        window:SetShown(not window:IsShown())
        RefreshWindow()
    end
    function self.Close()
        if window then window:Hide() end
    end
    return self
end
