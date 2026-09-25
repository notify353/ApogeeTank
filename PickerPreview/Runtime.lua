local _, addon = ...
local Style = addon.Style
local PLACEHOLDER = "Interface\\Icons\\INV_Misc_QuestionMark"

-- Display-only sample, parented to the picker. Never observes a unit or spell,
-- creates a secure button, or passes synthetic data to a selection model.
function addon.CreatePickerPreview(parent, models)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", 18, -8)
    frame:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -32, -8)
    frame:SetHeight(110)
    frame:EnableMouse(false)
    local title = Style.Text(frame, Style.headerFontSize)
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    title:SetText("Preview")
    title:SetTextColor(unpack(Style.mutedColor))
    local function Slot(anchor, point, relative, x, y)
        local slot = CreateFrame("Frame", nil, frame)
        slot:SetSize(Style.iconSize, Style.iconSize)
        slot:SetPoint(point, anchor, relative, x, y)
        slot:EnableMouse(false)
        slot.image = Style.Icon(slot)
        slot.label = Style.Text(slot, 11, "OUTLINE")
        slot.label:SetAllPoints()
        return slot
    end
    local strip = CreateFrame("Frame", nil, frame)
    strip:SetSize(Style.iconSize + 6 + 6 * (Style.iconSize + Style.iconGap) + 20, Style.iconSize)
    strip:SetPoint("TOP", frame, "TOP", 0, -18)
    local icons = {}
    for index = 1, 6 do
        icons[index] = Slot(strip, "TOPLEFT", "TOPLEFT",
            (Style.iconSize + 6 + 6 * (Style.iconSize + Style.iconGap) + 20) / 2 - 56
                + (index - 1) * (Style.iconSize + Style.iconGap), 0)
    end
    local overflow = Style.Text(strip, 10)
    overflow:SetPoint("LEFT", icons[6], "RIGHT", Style.iconGap, 0)
    local meter = CreateFrame("Frame", nil, frame)
    meter:SetSize(112, 16)
    meter:SetPoint("TOP", strip, "BOTTOM", 0, -5)
    meter:EnableMouse(false)
    local stance = Slot(meter, "RIGHT", "LEFT", -Style.iconGap, -(Style.iconSize - 16) / 2)
    stance:SetSize(Style.iconSize, Style.iconSize)
    stance.image:SetTexture("Interface\\Icons\\Ability_Defend")
    Style.Background(meter, Style.headerColor)
    local fill = meter:CreateTexture(nil, "ARTWORK")
    fill:SetPoint("LEFT", meter, "CENTER", 1, 0)
    fill:SetHeight(14)
    fill:SetColorTexture(unpack(Style.heldThreatColor))
    local health = meter:CreateTexture(nil, "ARTWORK")
    health:SetPoint("TOPLEFT", meter, "BOTTOMLEFT", 0, -1)
    health:SetSize(86, 5)
    health:SetColorTexture(unpack(Style.enemyHealthColor))
    local marker = meter:CreateTexture(nil, "ARTWORK")
    marker:SetSize(Style.iconSize, Style.iconSize)
    marker:SetPoint("LEFT", meter, "RIGHT", Style.iconGap, -(Style.iconSize - 16) / 2)
    marker:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
    marker:SetSpriteSheetCell(8, 4, 4)
    local seals = {}
    for index = 1, 7 do
        seals[index] = Slot(meter, "TOPLEFT", "BOTTOMLEFT",
            (index - 1) * (Style.iconSize + Style.iconGap), -6 - Style.iconGap)
        seals[index]:Hide()
    end
    local spells, elapsed, sincePaint = {}, 0, 0
    local function Selected(model)
        local entries = {}
        for _, entry in ipairs(model and model.GetEntries() or {}) do
            if entry.watched then entries[#entries + 1] = entry end
        end
        return entries
    end
    local function Paint()
        fill:SetWidth(15 + 35 * (0.5 + 0.5 * math.sin(elapsed)))
        for index, icon in ipairs(icons) do
            local entry = spells[index]
            icon.image:SetTexture(entry and entry.icon or PLACEHOLDER)
            icon.label:SetText(index == 1 and "" or tostring(math.ceil(12 - elapsed % 12)))
            icon:SetAlpha(index == 1 and 1 or 0.65)
            icon:SetShown(entry ~= nil or (#spells == 0 and index <= 3))
        end
        overflow:SetText(#spells > 6 and ("+" .. (#spells - 6)) or "")
    end
    local function Refresh()
        spells = Selected(models.Cooldowns)
        local selectedSeals = Selected(models.Seals)
        for index, icon in ipairs(seals) do
            local entry = selectedSeals[index]
            icon.image:SetTexture(entry and entry.icon)
            icon:SetShown(entry ~= nil)
        end
        Paint()
    end
    frame:SetScript("OnUpdate", function(_, delta)
        elapsed, sincePaint = elapsed + delta, sincePaint + delta
        if sincePaint >= 0.1 then sincePaint = 0; Paint() end
    end)
    frame:Hide()
    return {
        Refresh = Refresh,
        SetShown = function(shown)
            if shown and (InCombatLockdown() or UnitAffectingCombat("player")) then shown = false end
            if shown then elapsed, sincePaint = 0, 0; Refresh() end
            frame:SetShown(shown)
        end,
    }
end
