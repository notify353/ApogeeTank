local _, addon = ...
addon.CooldownView = {}
local Style = addon.Style
local STRIDE = Style.iconSize + Style.iconGap
local CLUSTER_GAP = 1

local function RenderNativeTimer(icon, state)
    if not state or not state.nativeDuration or state.enabled == false then
        if icon.cooldown then icon.cooldown:Hide() end
        icon.lastNativeState = nil
        return false
    end
    if not icon.cooldown then
        local cooldown = CreateFrame("Cooldown", nil, icon)
        cooldown:SetAllPoints()
        cooldown:EnableMouse(false)
        cooldown:SetDrawSwipe(false)
        cooldown:SetDrawEdge(false)
        cooldown:SetDrawBling(false)
        cooldown:SetCountdownFont("GameFontHighlightSmall")
        icon.cooldown = cooldown
    end
    local hasCharges = state.charges and state.charges > 0
    if icon.lastNativeState ~= state then
        icon.cooldown:SetHideCountdownNumbers(hasCharges == true)
        icon.nativeApplied = pcall(icon.cooldown.SetCooldownFromDurationObject,
            icon.cooldown, state.nativeDuration, true)
        icon.lastNativeState = state
    end
    icon.cooldown:SetShown(icon.nativeApplied)
    return icon.nativeApplied
end

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
                        icon:SetSize(Style.iconSize, Style.iconSize)
                        icon:SetPoint("LEFT", anchor, "RIGHT", CLUSTER_GAP + (count - 1) * STRIDE, 0)
                        icon.image = Style.Icon(icon)
                        icon.label = Style.Text(icon, 11, "OUTLINE")
                        icon.label:SetAllPoints()
                        icons[count] = icon
                    end
                    if icon.lastTexture ~= entry.icon then
                        icon.image:SetTexture(entry.icon)
                        icon.lastTexture = entry.icon
                    end
                    local state = states[entry.spellId]
                    local native = RenderNativeTimer(icon, state)
                    if state and state.unknown and not native and state.enabled ~= false then state = nil end
                    local remaining = state and math.max(0, state.start + state.duration - now) or nil
                    local label, alpha
                    if state and state.charges and state.charges > 0 then
                        label = tostring(state.charges)
                        alpha = 1
                    elseif native then
                        -- The native child owns the countdown; no Lua timer
                        -- arithmetic or readiness guess is made from secrets.
                        label, alpha = "", 1
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
            overflow = Style.Text(anchor, 10)
            overflow:SetPoint("LEFT", anchor, "RIGHT", CLUSTER_GAP + 6 * STRIDE + Style.iconGap, 0)
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
