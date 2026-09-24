local _, addon = ...
local Style = addon.Style
function addon.StartStance(getAnchor, getGeometry)
    local driver = CreateFrame("Frame")
    local icon, suggestion
    local inWorld = true
    local updateAction
    local function StopPulse()
        if not icon then return end
        icon.pulsing = false
        icon:SetScript("OnUpdate", nil)
        if icon.warningEdges then
            for _, edge in ipairs(icon.warningEdges) do edge:Hide() end
        end
    end
    local function Pulse(self, elapsed)
        -- Animate cached presentation only; never query spell or aura APIs here.
        self.pulseTime = (self.pulseTime + elapsed) % 1.8
        local wave = (1 - math.cos(self.pulseTime * 2 * math.pi / 1.8)) / 2
        self.image:SetAlpha(0.55 + 0.3 * wave)
        for _, edge in ipairs(self.warningEdges) do edge:SetAlpha(0.4 + 0.6 * wave) end
    end
    local function HideTooltip()
        if icon and GameTooltip and GameTooltip:IsOwned(icon) then GameTooltip:Hide() end
    end
    local function Refresh()
        if not inWorld then return end
        local anchor = getAnchor()
        if not anchor then return end
        local active = addon.GetActiveStanceIcon()
        local missing = not active and suggestion and suggestion.missing
        local texture = active or (suggestion and suggestion.spell.icon)
        local _, class = addon.Access.Call(UnitClass, "player")
        if texture and class == "PALADIN" then texture = "Interface\\Icons\\Ability_Defend" end
        if not icon and texture then
            icon = CreateFrame("Frame", nil, anchor)
            icon:SetSize(Style.iconSize, Style.iconSize)
            icon:SetPoint("TOPLEFT", anchor, "TOPLEFT", 0, 0)
            icon:EnableMouse(true)
            icon.image = Style.Icon(icon)
            icon.warningEdges = {}
            for _, side in ipairs({ "TOP", "BOTTOM", "LEFT", "RIGHT" }) do
                local edge = icon:CreateTexture(nil, "OVERLAY")
                edge:SetColorTexture(1, 0.72, 0.12, 1)
                edge:SetPoint(side, icon, side, 0, 0)
                if side == "TOP" or side == "BOTTOM" then
                    edge:SetSize(Style.iconSize, 2)
                else
                    edge:SetSize(2, Style.iconSize)
                end
                edge:Hide()
                icon.warningEdges[#icon.warningEdges + 1] = edge
            end
            icon:SetScript("OnLeave", HideTooltip)
            icon:SetScript("OnHide", function() StopPulse(); HideTooltip() end)
            icon:SetScript("OnEnter", function()
                if not suggestion or not GameTooltip then return end
                GameTooltip:SetOwner(icon, "ANCHOR_LEFT")
                GameTooltip:SetSpellByID(suggestion.spell.id)
                local labels = { devotion = "TANK", concentration = "HEALER", retribution = "DPS" }
                local label = labels[suggestion.family]
                if label then
                    GameTooltip:AddLine(" ")
                    GameTooltip:AddLine(label, 1, 0.82, 0.35)
                end
                GameTooltip:Show()
            end)
        end
        if icon then
            HideTooltip()
            icon.missing = missing and true or false
            icon.image:SetTexture(texture)
            icon.image:SetDesaturated(icon.missing or (not active and suggestion and suggestion.unknown) or false)
            if icon.missing and class == "PALADIN" then
                if not icon.pulsing then
                    icon.pulsing, icon.pulseTime = true, 0
                    icon:SetAlpha(1)
                    icon.image:SetAlpha(0.55)
                    for _, edge in ipairs(icon.warningEdges) do edge:SetAlpha(0.4); edge:Show() end
                    icon:SetScript("OnUpdate", Pulse)
                end
            else
                StopPulse()
                icon:SetAlpha(1)
                icon.image:SetAlpha(not active and suggestion and suggestion.unknown and 0.55 or 1)
            end
            icon:SetShown(texture ~= nil and texture ~= false)
        end
        if not updateAction and addon.CreateAuraAction and getGeometry then
            updateAction = addon.CreateAuraAction(getGeometry,
                function() if icon then icon:GetScript("OnEnter")() end end, HideTooltip)
        end
        if updateAction then
            updateAction(class == "PALADIN" and suggestion and suggestion.spell.id or nil, suggestion and suggestion.spell.name)
        end
    end
    driver:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_LEAVING_WORLD" then
            inWorld, suggestion = false, nil
            if updateAction then updateAction(nil) end
            StopPulse()
            if icon then icon:Hide() end
            return
        end
        if event == "PLAYER_ENTERING_WORLD" then inWorld = true end
        Refresh()
    end)
    for _, event in ipairs({ "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "PLAYER_LEAVING_WORLD",
        "UPDATE_SHAPESHIFT_FORM", "UPDATE_SHAPESHIFT_FORMS", "PLAYER_REGEN_ENABLED" }) do driver:RegisterEvent(event) end
    return { SetUnavailable = function()
        if suggestion and not suggestion.unknown then
            suggestion = { spell = suggestion.spell, family = suggestion.family,
                role = suggestion.role, missing = false, unknown = true }
            Refresh()
        end
    end, SetSuggestion = function(value)
        if value == suggestion then return end
        if value and suggestion and value.spell.id == suggestion.spell.id
            and value.role == suggestion.role and value.family == suggestion.family
            and value.missing == suggestion.missing and value.unknown == suggestion.unknown then return end
        suggestion = value; Refresh()
    end }
end
