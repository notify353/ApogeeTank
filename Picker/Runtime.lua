local _, addon = ...

function addon.StartPicker(cooldowns, seals)
    local driver = CreateFrame("Frame")
    local initialized, inWorld, inCombat = false, true, false
    local view, pendingToggle
    local dirty, elapsed = false, 0
    local function CanConfigure()
        return initialized and cooldowns.GetModel() ~= nil and inWorld and not inCombat
            and not InCombatLockdown() and not UnitAffectingCombat("player")
    end
    local function RequestRefresh()
        if not inWorld then return end
        dirty = true
        driver:Show()
    end
    local function Close()
        pendingToggle = false
        if view then view.Close() end
    end
    local function Refresh()
        if not CanConfigure() then Close()
        else
            if not view then
                view = addon.PickerView.Create({ Cooldowns = cooldowns, Seals = seals,
                    OnChanged = RequestRefresh, CanConfigure = CanConfigure })
            end
            view.Refresh()
            if pendingToggle then pendingToggle = false; view.Toggle() end
        end
        dirty = false
        driver:Hide()
    end
    driver:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_LOGIN" then initialized = true
        elseif event == "PLAYER_ENTERING_WORLD" then
            inWorld = true
            inCombat = UnitAffectingCombat("player") == true
        elseif event == "PLAYER_LEAVING_WORLD" then
            inWorld, dirty = false, false
            Close()
            driver:Hide()
            return
        elseif event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
            inCombat = event == "PLAYER_REGEN_DISABLED"
        end
        if not CanConfigure() then Close() end
        RequestRefresh()
    end)
    for _, event in ipairs({ "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "PLAYER_LEAVING_WORLD",
        "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED" }) do driver:RegisterEvent(event) end
    driver:SetScript("OnUpdate", function(_, delta)
        if not dirty then driver:Hide(); return end
        elapsed = elapsed + delta
        if elapsed >= 0.05 then elapsed = 0; Refresh() end
    end)
    cooldowns.SetChangedHandler(RequestRefresh)
    if seals then seals.SetChangedHandler(RequestRefresh) end
    driver:Hide()
    return { CanConfigure = CanConfigure, Toggle = function()
        if not CanConfigure() then return end
        pendingToggle = not pendingToggle
        RequestRefresh()
    end }
end
