local _, addon = ...
addon.CooldownView = {}
local Style = addon.Style
local STRIDE = Style.iconSize + Style.iconGap
local function HideTooltip(icon)
    if GameTooltip and GameTooltip:IsOwned(icon) then GameTooltip:Hide() end
end
local function ShowTooltip(icon)
    if not GameTooltip or not icon.spellId then return end
    GameTooltip:SetOwner(icon, "ANCHOR_RIGHT")
    GameTooltip:SetSpellByID(icon.spellId)
    GameTooltip:Show()
end

local function RenderNativeTimer(icon, state)
    if not state or not state.nativeDuration or state.enabled == false then
        if icon.cooldown then icon.cooldown:Hide() end
        icon.lastNativeDuration, icon.lastHideNumbers = nil, nil
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
    if icon.lastHideNumbers ~= (hasCharges == true) then
        icon.cooldown:SetHideCountdownNumbers(hasCharges == true)
        icon.lastHideNumbers = hasCharges == true
    end
    if icon.lastNativeDuration ~= state.nativeDuration or not icon.nativeApplied then
        icon.nativeApplied = pcall(icon.cooldown.SetCooldownFromDurationObject,
            icon.cooldown, state.nativeDuration, true)
        icon.lastNativeDuration = state.nativeDuration
    end
    icon.cooldown:SetShown(icon.nativeApplied)
    return icon.nativeApplied
end

function addon.CooldownView.Create(getAnchor, getGeometry)
    local icons = {}
    local overflow
    local self = {}
    local fixedEntries, boundEntries = {}, nil
    local updateActions = getGeometry and addon.CreateCooldownActions
        and addon.CreateCooldownActions(getGeometry, ShowTooltip, HideTooltip)
    function self.Render(entries, states, now)
        local anchor = getAnchor()
        if not anchor then return end
        if updateActions then
            if not InCombatLockdown() and boundEntries ~= entries then
                boundEntries = entries
                fixedEntries = {}
                for _, entry in ipairs(entries) do
                    if entry.watched then
                        fixedEntries[#fixedEntries + 1] = { spellId = entry.spellId,
                            icon = entry.icon, name = entry.name, watched = true }
                    end
                end
                updateActions(fixedEntries)
            end
            -- Presentation must show the exact spells on the secure buttons.
            -- Discovery continues, but slot changes wait until combat ends.
            entries = fixedEntries
        end
        local count = 0
        for _, entry in ipairs(entries) do
            if entry.watched then
                count = count + 1
                if count <= 6 then
                    local icon = icons[count]
                    if not icon then
                        icon = CreateFrame("Frame", nil, anchor)
                        icon:EnableMouse(true)
                        icon:SetScript("OnEnter", ShowTooltip)
                        icon:SetScript("OnLeave", HideTooltip)
                        icon:SetScript("OnHide", HideTooltip)
                        icon:SetSize(Style.iconSize, Style.iconSize)
                        icon:SetPoint("TOPLEFT", anchor, "TOPLEFT", (count - 1) * STRIDE, 0)
                        icon.image = Style.Icon(icon)
                        icon.label = Style.Text(icon, 11, "OUTLINE")
                        icon.label:SetAllPoints()
                        icons[count] = icon
                    end
                    if icon.spellId ~= entry.spellId then
                        HideTooltip(icon)
                        icon.spellId = entry.spellId
                    end
                    local texture = entry.icon or "Interface\\Icons\\INV_Misc_QuestionMark"
                    if icon.lastTexture ~= texture then
                        icon.image:SetTexture(texture)
                        icon.lastTexture = texture
                    end
                    local state = states[entry.spellId]
                    local native = RenderNativeTimer(icon, state)
                    if state and state.unknown and not native and state.enabled ~= false
                        and not (state.charges and state.charges > 0) then state = nil end
                    local remaining = state and math.max(0, state.start + state.duration - now) or nil
                    local label, alpha
                    if state and state.enabled == false then
                        label, alpha = "?", 0.4
                    elseif state and state.charges and state.charges > 0 then
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
                    local cooling = state and state.enabled ~= false
                        and not (state.charges and state.charges > 0)
                        and ((native and (state.coolingDown == true or state.realCooldown == true)) or (remaining and remaining > 0)) or false
                    cooling = cooling or (state and state.castable == false) or false
                    if icon.lastDesaturated ~= cooling then
                        icon.image:SetDesaturated(cooling)
                        icon.lastDesaturated = cooling
                    end
                    if cooling and alpha > 0.65 then alpha = 0.65 end
                    if icon.lastLabel ~= label then icon.label:SetText(label); icon.lastLabel = label end
                    if icon.lastAlpha ~= alpha then icon:SetAlpha(alpha); icon.lastAlpha = alpha end
                    if not icon:IsShown() then icon:Show() end
                end
            end
        end
        if not overflow then
            overflow = Style.Text(anchor, 10)
            overflow:SetPoint("LEFT", anchor, "TOPLEFT", 6 * STRIDE, -Style.iconSize / 2)
        end
        local text = count > 6 and ("+" .. (count - 6)) or ""
        if self.overflowText ~= text then overflow:SetText(text); self.overflowText = text end
        overflow:SetShown(count > 6)
        for index = math.min(count, 6) + 1, #icons do icons[index]:Hide() end
    end
    function self.Hide()
        boundEntries = nil
        if updateActions then updateActions({}) end
        for _, icon in ipairs(icons) do icon:Hide() end
        if overflow then overflow:Hide() end
    end
    return self
end
