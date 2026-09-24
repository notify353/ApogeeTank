local _, addon = ...
function addon.StartGuidance(getAnchor, stance)
    local A, API, M = addon.Access, addon.GuidanceAPI, addon.Guidance
    local driver = CreateFrame("Frame")
    local panel, label, known, names
    local inWorld = true
    local function Refresh(_, event, unit)
        if event == "UNIT_AURA" and (not A.CanRead(unit) or unit ~= "player") then return end
        if event == "PLAYER_LEAVING_WORLD" then
            inWorld = false
            known, names = nil, nil
            if stance then stance.SetSuggestion(nil) end
            if panel then panel:Hide() end
            return
        end
        if event == "PLAYER_ENTERING_WORLD" then inWorld = true end
        if not inWorld then return end
        local _, class = A.Call(UnitClass, "player")
        if class ~= "PALADIN" and class ~= "WARRIOR" and class ~= "DRUID" then return end
        local anchor = getAnchor()
        if not anchor then return end
        if not panel then
            panel = CreateFrame("Frame", nil, anchor)
            panel:SetSize(190, 60)
            panel:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", 0, 6)
            panel:EnableMouse(false)
            label = addon.Style.Text(panel, 9)
            label:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 0, 0)
            label:SetWidth(190)
            label:SetJustifyH("LEFT")
            label:SetTextColor(1, 0.82, 0.35, 1)
        end
        if A.Call(UnitIsDeadOrGhost, "player") ~= false then
            if stance then stance.SetSuggestion(nil) end
            panel:Hide(); return
        end
        if not InCombatLockdown() and (not known or event == "SPELLS_CHANGED"
            or event == "PLAYER_ENTERING_WORLD") then known, names = API.Learn() end
        local role = API.Role()
        local active = names and API.Active(names)
        if not role or not known or not active then
            if stance then
                if class == "PALADIN" and InCombatLockdown() then stance.SetUnavailable()
                else stance.SetSuggestion(nil) end
            end
            if class == "PALADIN" then panel:Hide(); return end
            label:SetText("Preparation status unavailable")
            panel:Show()
            return
        end
        local rows = M.Evaluate(class, role, known, active)
        if class == "PALADIN" and stance then
            local suggestion = rows[1]
            if not suggestion then
                for key, spell in pairs(known) do
                    if active[key] then suggestion = { spell = spell }; break end
                end
            end
            local family
            if suggestion then
                for key, spell in pairs(known) do
                    if spell == suggestion.spell then family = key; break end
                end
            end
            stance.SetSuggestion(suggestion and { spell = suggestion.spell, role = role,
                family = family, missing = #rows > 0 })
            panel:Hide()
            return
        end
        if stance then stance.SetSuggestion(nil) end
        local lines = {}
        for _, row in ipairs(rows) do lines[#lines + 1] = row.text .. ": " .. row.spell.name end
        label:SetText(table.concat(lines, "\n"))
        panel:SetShown(#lines > 0)
    end
    driver:SetScript("OnEvent", Refresh)
    for _, event in ipairs({ "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "PLAYER_LEAVING_WORLD",
        "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "PLAYER_ROLES_ASSIGNED",
        "ROLE_CHANGED_INFORM", "GROUP_ROSTER_UPDATE", "SPELLS_CHANGED", "UNIT_AURA",
        "UPDATE_SHAPESHIFT_FORM", "PLAYER_DEAD", "PLAYER_ALIVE", "PLAYER_UNGHOST" }) do driver:RegisterEvent(event) end
end
