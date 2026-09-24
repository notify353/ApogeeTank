local _, addon = ...
-- Tank-local presentation only. Features retain placement and interaction policy.
local Style = {
    -- Fixed Forever HUD and picker dimensions.
    iconSize = 22, iconGap = 2, iconInset = 1,
    pickerIconSize = 24, pickerIconInset = 2,
    headerHeight = 18, headerFontSize = 9, buttonHeight = 24,
    heldThreatColor = { 0.91, 0.89, 0.84, 1 }, -- Soft ivory; warnings retain their colors.
    enemyHealthColor = { 0.91, 0.89, 0.84, 1 },
    slotColor = { 0.06, 0.075, 0.1, 0.94 },
    headerColor = { 0.09, 0.12, 0.17, 0.8 },
    panelColor = { 0.035, 0.045, 0.065, 0.98 },
    borderColor = { 0.25, 0.28, 0.34, 1 },
    mutedColor = { 0.65, 0.70, 0.78, 1 },
}
addon.Style = Style

function Style.GetScale()
    -- Keybinds uses 36px slots; Tank's 18px slots inherit this at the roots.
    return 2
end

function Style.Background(parent, color)
    local texture = parent:CreateTexture(nil, "BACKGROUND")
    texture:SetAllPoints()
    texture:SetColorTexture(unpack(color or Style.slotColor))
    return texture
end

function Style.Icon(parent, inset)
    Style.Background(parent)
    local texture = parent:CreateTexture(nil, "ARTWORK")
    inset = inset or Style.iconInset
    texture:SetPoint("TOPLEFT", parent, "TOPLEFT", inset, -inset)
    texture:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -inset, inset)
    texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    return texture
end

function Style.Text(parent, size, flags)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    local font, _, inheritedFlags = label:GetFont()
    label:SetFont(font, size or 11, flags or inheritedFlags)
    return label
end
