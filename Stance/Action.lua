local _, addon = ...
-- Native non-toggling aura macro, independent of the ordinary HUD's parent/anchor graph.
-- Configure outside combat; the native action remains usable during combat.
function addon.CreateAuraAction(getGeometry, enter, leave)
    local button, configuredID, configuredName
    return function(spellID, spellName)
        if InCombatLockdown() then return end
        if type(spellName) ~= "string" or spellName:find("[\r\n]") then spellID = nil end
        if not button and spellID then
            local geometry = getGeometry()
            button = CreateFrame("Button", "ApogeeTankAuraAction", UIParent, "SecureActionButtonTemplate")
            button:SetScale(geometry.scale)
            button:SetSize(geometry.size, geometry.size)
            button:SetPoint("CENTER", UIParent, "CENTER", geometry.x, geometry.y)
            button:SetFrameStrata("MEDIUM")
            button:SetFrameLevel(30)
            button:RegisterForClicks("LeftButtonDown")
            button:SetAttribute("useOnKeyDown", true)
            button:SetAttribute("unit", "player")
            button:SetAttribute("*type*", "")
            for _, prefix in ipairs({ "shift-", "ctrl-", "alt-", "ctrl-shift-",
                "alt-shift-", "alt-ctrl-", "alt-ctrl-shift-" }) do
                button:SetAttribute(prefix .. "type1", "")
            end
            button:SetScript("OnEnter", enter)
            button:SetScript("OnLeave", leave)
            button:SetScript("OnHide", leave)
        end
        if not button then return end
        if configuredID == spellID and configuredName == spellName then return end
        configuredID, configuredName = spellID, spellName
        button:SetAttribute("type1", spellID and "macro" or "")
        -- Native ! syntax activates a toggle without toggling it back off.
        button:SetAttribute("macrotext1", spellID and ("/cast !" .. spellName) or nil)
        -- Native state visibility handles combat without addon protected writes.
        RegisterStateDriver(button, "visibility", spellID and "[dead] hide; show" or "hide")
    end
end
