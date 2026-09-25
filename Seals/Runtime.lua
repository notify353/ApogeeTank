local _, addon = ...
function addon.StartSeals(getGeometry)
    local driver, buttons = CreateFrame("Frame"), {}
    local function HideTooltip(button)
        if GameTooltip and GameTooltip:IsOwned(button) then GameTooltip:Hide() end
    end
    local inWorld = true
    local model, initialized, changedHandler, notifiedRevision
    local function CanConfigure()
        return inWorld and not InCombatLockdown()
            and (not UnitAffectingCombat or not UnitAffectingCombat("player"))
    end
    local function Initialize()
        if initialized then return end
        local _, class = addon.Access.Call(UnitClass, "player")
        if not class then return end
        initialized = true
        if class ~= "PALADIN" then return end
        local reason
        model, reason = addon.SealSelection.Create(ApogeeTankSealsDB, CanConfigure)
        if model then ApogeeTankSealsDB = model.GetSaved()
        else print("Apogee Tank: Seal selection disabled. " .. reason) end
    end
    local function Paint()
        local state = inWorld and addon.Access.Call(UnitIsDeadOrGhost, "player") == false
            and addon.SealAPI.Active(addon.SealEntries or {}) or nil
        for _, button in ipairs(buttons) do
            local active = state and state.spellId == button.spellId
            local dimmed = state and state.spellId ~= nil and not active or false
            if button.lastDimmed ~= dimmed then
                button.image:SetDesaturated(dimmed)
                button.image:SetAlpha(dimmed and 0.5 or 1)
                button.lastDimmed = dimmed
            end
            local durationObject = active and state.durationObject or nil
            local start = active and state.start or nil
            local duration = active and state.duration or nil
            if button.timerObject ~= durationObject or button.timerStart ~= start
                or button.timerDuration ~= duration
                or ((durationObject or start) and not button.timerApplied) then
                button.timerObject, button.timerStart, button.timerDuration = durationObject, start, duration
                button.timerApplied = false
                if durationObject then
                    button.timerApplied = pcall(button.timer.SetCooldownFromDurationObject, button.timer, durationObject, true)
                elseif start then
                    button.timerApplied = pcall(button.timer.SetCooldown, button.timer, start, duration)
                end
            end
            button.timer:SetShown(button.timerApplied == true)
        end
    end
    local function Refresh()
        Initialize()
        if not model then return end
        if InCombatLockdown() then return end
        local learned = addon.SealAPI.Learn()
        if not learned then return end
        model.Reconcile(learned)
        -- Hidden seals still identify the active aura, but never get HUD actions.
        addon.SealEntries = learned
        local entries = {}
        for _, entry in ipairs(model.GetEntries()) do
            if entry.watched then entries[#entries + 1] = entry end
        end
        for index = 1, math.max(#entries, #buttons) do
            local entry, button = entries[index], buttons[index]
            if entry and not button then
                local geometry = getGeometry(index)
                button = CreateFrame("Button", "ApogeeTankSealAction" .. index, UIParent, "SecureActionButtonTemplate")
                button:SetScale(geometry.scale)
                button:SetSize(geometry.size, geometry.size)
                button:SetPoint("TOPLEFT", UIParent, "CENTER", geometry.x, geometry.y)
                button:SetFrameStrata("MEDIUM"); button:SetFrameLevel(30)
                button:RegisterForClicks("LeftButtonUp")
                button:SetAttribute("useOnKeyDown", false)
                button:SetAttribute("unit", "player")
                button:SetAttribute("type", "")
                for _, prefix in ipairs({ "shift-", "ctrl-", "alt-", "ctrl-shift-", "alt-shift-", "alt-ctrl-", "alt-ctrl-shift-" }) do
                    button:SetAttribute(prefix .. "type1", "")
                end
                button.image = addon.Style.Icon(button)
                -- Independent ordinary overlay: aura updates never mutate the
                -- secure button or any protected child during combat.
                local overlay = CreateFrame("Frame", nil, UIParent)
                overlay:SetScale(geometry.scale); overlay:SetSize(geometry.size, geometry.size)
                overlay:SetPoint("TOPLEFT", UIParent, "CENTER", geometry.x, geometry.y)
                overlay:SetFrameStrata("MEDIUM"); overlay:SetFrameLevel(31); overlay:EnableMouse(false)
                button.timer = CreateFrame("Cooldown", nil, overlay)
                button.timer:SetAllPoints(); button.timer:EnableMouse(false)
                button.timer:SetDrawSwipe(false); button.timer:SetDrawEdge(false); button.timer:SetDrawBling(false)
                button.timer:SetCountdownFont("GameFontHighlightSmall"); button.timer:Hide()
                button:SetScript("OnEnter", function(self)
                    if self.spellId and GameTooltip then
                        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                        GameTooltip:SetSpellByID(self.spellId); GameTooltip:Show()
                    end
                end)
                button:SetScript("OnLeave", HideTooltip)
                button:SetScript("OnHide", function(self) HideTooltip(self); self.timer:Hide() end)
                buttons[index] = button
            end
            if button and button.spellId ~= (entry and entry.spellId) then
                HideTooltip(button)
                button.spellId = entry and entry.spellId
                button.image:SetTexture(entry and entry.icon)
                button.lastDimmed = nil
                button.timer:Hide()
                button.timerObject, button.timerStart, button.timerDuration, button.timerApplied = nil, nil, nil, false
                UnregisterAttributeDriver(button, "type1"); UnregisterAttributeDriver(button, "spell")
                RegisterAttributeDriver(button, "type1", entry and "spell" or "nil")
                RegisterAttributeDriver(button, "spell", entry and tostring(entry.spellId) or "nil")
                RegisterStateDriver(button, "visibility", entry and "[dead] hide; show" or "hide")
            end
        end
        if notifiedRevision ~= model.GetRevision() then
            notifiedRevision = model.GetRevision()
            if changedHandler then changedHandler() end
        end
    end
    driver:SetScript("OnEvent", function(_, event, unit)
        if event == "PLAYER_LEAVING_WORLD" then inWorld = false; Paint(); return end
        if event == "PLAYER_ENTERING_WORLD" then inWorld = true end
        if not inWorld then return end
        if event == "UNIT_AURA" then
            if not addon.Access.CanRead(unit) or unit ~= "player" then return end
        elseif event ~= "PLAYER_REGEN_DISABLED" then
            Refresh()
        end
        Paint()
    end)
    for _, event in ipairs({ "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "SPELLS_CHANGED", "PLAYER_REGEN_ENABLED",
        "PLAYER_REGEN_DISABLED", "UNIT_AURA", "PLAYER_LEAVING_WORLD", "PLAYER_DEAD", "PLAYER_ALIVE", "PLAYER_UNGHOST" }) do
        driver:RegisterEvent(event)
    end
    return {
        GetModel = function() return model end,
        SetChangedHandler = function(handler) changedHandler = handler end,
        Refresh = function() if CanConfigure() then Refresh(); Paint() end end,
    }
end
