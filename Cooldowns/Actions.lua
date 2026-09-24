local _, addon = ...
-- Protected click surfaces never inherit the changing live HUD frame tree.
function addon.CreateCooldownActions(getGeometry, enter, leave)
    local buttons = {}
    return function(entries)
        if InCombatLockdown() then return end
        for index = 1, 6 do
            local entry, button = entries[index], buttons[index]
            if entry and not button then
                local geometry = getGeometry(index)
                button = CreateFrame("Button", "ApogeeTankCooldownAction" .. index,
                    UIParent, "SecureActionButtonTemplate")
                button:SetScale(geometry.scale)
                button:SetSize(geometry.size, geometry.size)
                button:SetPoint("TOPLEFT", UIParent, "CENTER", geometry.x, geometry.y)
                button:SetFrameStrata("MEDIUM")
                button:SetFrameLevel(30)
                button:RegisterForClicks("LeftButtonUp")
                button:SetAttribute("useOnKeyDown", false)
                button:SetAttribute("type", "")
                for _, prefix in ipairs({ "shift-", "ctrl-", "alt-", "ctrl-shift-",
                    "alt-shift-", "alt-ctrl-", "alt-ctrl-shift-" }) do
                    button:SetAttribute(prefix .. "type1", "")
                end
                button:SetScript("OnEnter", enter)
                button:SetScript("OnLeave", leave)
                button:SetScript("OnHide", leave)
                buttons[index] = button
            end
            if button and button.spellId ~= (entry and entry.spellId) then
                leave(button)
                button.spellId = entry and entry.spellId
                local macro = entry and addon.CooldownAPI.TargetMacro(button.spellId)
                -- A target-bound secure button is rejected before its macro runs
                -- when no target exists. Let acquisition macros resolve their own unit.
                button:SetAttribute("unit", entry and not macro and "target" or nil)
                -- Match the working Keybinds HUD native-driver setup. Native
                -- code supplies the action type as well as its payload.
                for _, field in ipairs({ "type1", "spell", "macrotext" }) do
                    UnregisterAttributeDriver(button, field)
                end
                RegisterAttributeDriver(button, "type1", entry and (macro and "macro" or "spell") or "nil")
                RegisterAttributeDriver(button, "spell", entry and tostring(button.spellId) or "nil")
                RegisterAttributeDriver(button, "macrotext", macro or "nil")
                RegisterStateDriver(button, "visibility", entry and "[dead] hide; show" or "hide")
            end
        end
    end
end
