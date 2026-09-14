local _, addon = ...
addon.CooldownView = {}

function addon.CooldownView.Create(getAnchor)
    local icons = {}
    local overflow
    local self = {}
    function self.Render(entries, states, now)
        local anchor = getAnchor()
        if not anchor then return end
        local count = 0
        for _, entry in ipairs(entries) do
            if entry.watched then
                count = count + 1
                if count <= 6 then
                    local icon = icons[count]
                    if not icon then
                        icon = CreateFrame("Frame", nil, anchor)
                        icon:SetSize(18, 18)
                        icon:SetPoint("LEFT", anchor, "RIGHT", 6 + (count - 1) * 20, 0)
                        icon.image = icon:CreateTexture(nil, "ARTWORK")
                        icon.image:SetAllPoints()
                        icon.image:SetTexCoord(0.07, 0.93, 0.07, 0.93)
                        icon.label = icon:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                        icon.label:SetAllPoints()
                        icons[count] = icon
                    end
                    if icon.lastTexture ~= entry.icon then
                        icon.image:SetTexture(entry.icon)
                        icon.lastTexture = entry.icon
                    end
                    local state = states[entry.spellId]
                    local remaining = state and math.max(0, state.start + state.duration - now) or nil
                    local label, alpha
                    if state and state.charges and state.charges > 0 then
                        label = tostring(state.charges)
                        alpha = 1
                    elseif remaining and remaining > 0 and state.enabled then
                        label = remaining >= 60 and (math.ceil(remaining / 60) .. "m")
                            or tostring(math.ceil(remaining))
                        alpha = 0.65
                    else
                        label = state and state.enabled and "" or "?"
                        alpha = state and state.enabled and 1 or 0.4
                    end
                    if icon.lastLabel ~= label then icon.label:SetText(label); icon.lastLabel = label end
                    if icon.lastAlpha ~= alpha then icon:SetAlpha(alpha); icon.lastAlpha = alpha end
                    if not icon:IsShown() then icon:Show() end
                end
            end
        end
        if not overflow then
            overflow = anchor:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            overflow:SetPoint("LEFT", anchor, "RIGHT", 128, 0)
        end
        local text = count > 6 and ("+" .. (count - 6)) or ""
        if self.overflowText ~= text then overflow:SetText(text); self.overflowText = text end
        overflow:SetShown(count > 6)
        for index = math.min(count, 6) + 1, #icons do icons[index]:Hide() end
    end
    function self.Hide()
        for _, icon in ipairs(icons) do icon:Hide() end
        if overflow then overflow:Hide() end
    end
    return self
end
