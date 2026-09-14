local _, addon = ...

-- Artwork only: no spell identities or tracking defaults are supplied here.
local SAMPLE_EFFECTS = {
    { name = "Demo: Sunder Armor", icon = "Interface\\Icons\\Ability_Warrior_Sunder" },
    { name = "Demo: Thunder Clap", icon = "Interface\\Icons\\Spell_Nature_ThunderClap" },
    { name = "Demo: Demoralizing Shout", icon = "Interface\\Icons\\Ability_Warrior_WarCry" },
}

-- Synthetic presentation only: never enters the observer or saved effect model.
function addon.CreateThreatDemo()
    local driver = CreateFrame("Frame")
    local active, getEntries, elapsed = false, nil, 0
    local function Render()
        local effects = {}
        for _, effect in ipairs(getEntries and getEntries() or {}) do
            if effect.watched then effects[#effects + 1] = effect end
        end
        if #effects == 0 then
            effects = SAMPLE_EFFECTS
        end
        local now, enemies = GetTime(), {}
        for index = 1, 3 do
            local control = math.sin(now / 3 + index) * 70
            local applied, missing = {}, {}
            for effectIndex, effect in ipairs(effects) do
                local list = (math.floor(now / 3) + index + effectIndex) % 2 == 0
                    and applied or missing
                list[#list + 1] = effect
            end
            enemies[index] = { guid = "apogee-demo-" .. index,
                name = "Demo enemy " .. index, live = true, raidMarker = 9 - index,
                control = control, isTanking = control >= 0,
                severity = control < 0 and "lost" or (control < 30 and "slipping" or "safe"),
                healthValid = true, health = 75 + 20 * math.sin(now / 5 + index),
                healthMaximum = 100, playerDebuffSlots = applied,
                playerDebuffOverflow = math.max(0, #applied - 6),
                demoMissing = missing,
            }
        end
        addon.ThreatHud.SetDemoSnapshot({ enemies = enemies, total = #enemies })
        addon.ThreatHud.Tick(0.1)
    end
    local function SetShown(shown, entries)
        if shown and (InCombatLockdown() or UnitAffectingCombat("player")) then shown = false end
        if shown then
            active, getEntries = true, entries
            driver:Show()
            Render()
        elseif active then
            active = false
            driver:Hide()
            addon.ThreatHud.SetDemoSnapshot(nil)
        end
    end
    driver:SetScript("OnUpdate", function(_, delta)
        elapsed = elapsed + delta
        if elapsed >= 0.1 then elapsed = 0; Render() end
    end)
    driver:RegisterEvent("PLAYER_REGEN_DISABLED")
    driver:RegisterEvent("PLAYER_LEAVING_WORLD")
    driver:SetScript("OnEvent", function() SetShown(false) end)
    driver:Hide()
    return { SetShown = SetShown }
end
