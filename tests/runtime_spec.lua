-- Standalone TOC execution with an instrumented WoW UI; no source addon loaded.
local now, interface, project = 10, 11509, 2
local combat, driver = false, nil
local frames, named = {}, {}
local methods = {}
local function Frame(kind, name, parent)
    local frame = setmetatable({ kind = kind, name = name, parent = parent,
        shown = true, points = {}, scripts = {}, events = {} }, { __index = methods })
    frames[#frames + 1] = frame
    if name then assert(not named[name], "duplicate frame name"); named[name] = frame end
    return frame
end
function methods:SetPoint(...) self.points[#self.points + 1] = {...} end
function methods:ClearAllPoints() self.points = {} end
function methods:SetAllPoints() end
function methods:SetBackdrop() end
function methods:SetBackdropColor() end
function methods:SetBackdropBorderColor() end
function methods:SetScrollChild(child) self.scrollChild = child end
function methods:UpdateScrollChildRect() end
function methods:SetVerticalScroll(value) self.verticalScroll = value end
function methods:SetChecked(value) self.checked = value end
function methods:GetChecked() return self.checked end
function methods:SetWidth(value) self.width = value end
function methods:SetHeight(value) self.height = value end
function methods:SetSize(w, h) self.width, self.height = w, h end
function methods:SetColorTexture(...) self.color = {...} end
function methods:SetTextColor(...) self.textColor = {...} end
function methods:GetFont() return "Fonts/FRIZQT__.TTF", 12, "" end
function methods:SetFont(font, size, flags) self.font, self.fontSize, self.fontFlags = font, size, flags end
function methods:SetText(value) self.text = value end
function methods:SetTexture(value) self.texture = value end
function methods:SetTexCoord(...) self.texCoord = {...} end
function methods:SetJustifyH() end
function methods:SetWordWrap() end
function methods:SetAlpha(value) self.alpha = value end
function methods:SetClampedToScreen(value) self.clamped = value end
function methods:RegisterForDrag(...) self.dragButtons = {...} end
function methods:StartMoving() self.moving = true end
function methods:StopMovingOrSizing() self.moving = false end
function methods:SetMovable(value) self.movable = value end
function methods:EnableMouse(value) self.mouse = value end
function methods:SetFrameStrata(value) self.strata = value end
function methods:Hide() local was = self.shown; self.shown = false; if was and self.scripts.OnHide then self.scripts.OnHide(self) end end
function methods:Show() local was = self.shown; self.shown = true; if not was and self.scripts.OnShow then self.scripts.OnShow(self) end end
function methods:SetShown(value) if value then self:Show() else self:Hide() end end
function methods:IsShown() return self.shown end
function methods:CreateTexture(name, layer)
    local texture = Frame("Texture", name, self)
    texture.layer = layer
    return texture
end
function methods:CreateFontString(name) return Frame("FontString", name, self) end
function methods:RegisterEvent(event)
    self.events[event] = true
    if event == "UNIT_THREAT_LIST_UPDATE" then driver = self end
end
function methods:SetScript(event, callback) self.scripts[event] = callback end
CreateFrame = Frame
UIParent = Frame("Frame", "UIParent")
WOW_PROJECT_CLASSIC = 2
WOW_PROJECT_ID = project
SlashCmdList = {}
local shiftDown, controlDown, altDown, lockdown = false, false, false, false
function IsShiftKeyDown() return shiftDown end
function IsControlKeyDown() return controlDown end
function IsAltKeyDown() return altDown end
function InCombatLockdown() return lockdown end
GameTooltip = { shown = false }
function GameTooltip:SetOwner(owner) self.owner = owner end
function GameTooltip:SetText(text) self.text = text end
function GameTooltip:SetSpellByID(id) self.spellId = id end
function GameTooltip:AddLine() error("unexpected addon text on standard spell tooltip") end
function GameTooltip:Show() self.shown = true end
function GameTooltip:Hide() self.shown = false end
function GetBuildInfo() return "1.15.9", "69722", "", interface end
function GetTime() return now end
function UnitAffectingCombat() return combat end
function UnitClass() return "Warrior", "WARRIOR" end

local tokens = {
    player = { guid = "player", health = 80, maximum = 100 },
    party1 = { guid = "healer" },
    target = { guid = "enemy", hostile = true, health = 75, maximum = 100 },
}
tokens.nameplate1 = tokens.target
tokens.targettarget = tokens.player
tokens.nameplate1target = tokens.player
local held, challenger, playerThreat = true, 60, 100
function UnitExists(unit) return tokens[unit] ~= nil end
function UnitGUID(unit) return tokens[unit] and tokens[unit].guid end
function UnitName(unit) return UnitGUID(unit) end
function UnitIsUnit(a, b) return UnitGUID(a) ~= nil and UnitGUID(a) == UnitGUID(b) end
function UnitCanAttack(_, unit) return tokens[unit] and tokens[unit].hostile == true end
function UnitIsDeadOrGhost(unit) return tokens[unit] and tokens[unit].dead == true end
function UnitCreatureType() return "Humanoid", 7 end
function GetRaidTargetIndex(unit) return tokens[unit] and tokens[unit].marker end
function UnitDetailedThreatSituation(unit)
    if unit == "player" then return held, held and 3 or 1, playerThreat end
    if unit == "party1" then return not held, held and 1 or 3, challenger end
end
function UnitHealth(unit) return tokens[unit].health or 100 end
function UnitHealthMax(unit) return tokens[unit].maximum or 100 end
local power, maximumPower, powerType, powerToken = 30, 100, 1, "RAGE"
function UnitPowerType() return powerType, powerToken end
function UnitPower() return power end
function UnitPowerMax() return maximumPower end
PowerBarColor = { RAGE = { r = 1, g = 0, b = 0 } }
local casting, channeling
function UnitCastingInfo(unit)
    if casting and tokens[unit].hostile then
        return "Fireball", "Fireball", 1, 10000, 14000, false, "cast", false, 133
    end
end
function UnitChannelInfo(unit)
    if channeling and tokens[unit].hostile then
        return "Drain", "Drain", 2, 10000, 14000, false, true, 689
    end
end
local auraStacks, hasSunder, aurasAvailable = 3, true, true
local sunderSource = "player"
local enemy2Auras, extraTargetAura = {}, nil
C_UnitAuras = { GetAuraDataByIndex = function(unit, index, filter)
    assert(filter == "HARMFUL")
    if not aurasAvailable then error("Aura read unavailable") end
    if unit == "nameplate2" then return enemy2Auras[index] end
    if index == 1 then return { sourceUnit = "party1", spellId = 1160, name = "Demoralizing Shout", icon = 20 } end
    if index == 2 and hasSunder then return { sourceUnit = sunderSource, spellId = 7386, name = "Sunder Armor", icon = 10,
        applications = auraStacks, expirationTime = 14, duration = 30 } end
    if index == 3 then return extraTargetAura end
end }
C_NamePlate = { GetNamePlates = function() return { { namePlateUnitToken = "nameplate1" } } end }

local function LoadAddon()
    local addon = {}
    for line in io.lines("ApogeeTank.toc") do
        local path = line:match("^([^#].-%.lua)%s*$")
        if path then assert(loadfile(path))("ApogeeTank", addon) end
    end
    return addon
end

-- A stale-addon override must not execute the feature on other clients.
interface = 20506
local before = #frames
LoadAddon()
assert(#frames == before, "unsupported interface created UI")
interface, WOW_PROJECT_ID = 11509, 1
LoadAddon()
assert(#frames == before, "non-Era project created UI")
WOW_PROJECT_ID = WOW_PROJECT_CLASSIC
local addon = LoadAddon()
assert(driver and driver.events.PLAYER_LOGIN)
local function Event(event, unit)
    local delivered = false
    for _, listener in ipairs(frames) do
        if listener.events[event] and listener.scripts.OnEvent then
            delivered = true
            listener.scripts.OnEvent(listener, event, unit)
        end
    end
    assert(delivered, "unregistered test event: " .. event)
end
local function Tick(elapsed)
    now = now + elapsed
    for _, listener in ipairs(frames) do
        if listener:IsShown() and listener.scripts.OnUpdate then
            listener.scripts.OnUpdate(listener, elapsed)
        end
    end
end
Event("PLAYER_LOGIN")
local hud = addon.ThreatHud.GetFrame()
assert(hud.name == "ApogeeTankThreatHud" and hud.width == 389)
assert(hud.points[1][1] == "TOP" and hud.points[1][3] == "CENTER"
    and hud.points[1][4] == 0 and hud.points[1][5] == 55,
    "fixed original placement changed")
assert(hud:IsShown() and not hud.mouse and not hud.movable)
assert(next(addon.ThreatHud.GetRows()) == nil, "idle enemy rows appeared")
assert(addon.ThreatHud.GetPlayerHealthBar():IsShown())

combat = true
Event("PLAYER_REGEN_DISABLED")
local row = addon.ThreatHud.GetRows()[1]
assert(row and row:IsShown() and row.enemy.guid == "enemy")
assert(addon.ThreatObserver.GetSnapshot().total == 1, "aliases created duplicate enemies")
assert(row.height == 24 and row.controlBar.width == 112 and row.controlBar.height == 16)
assert(row.enemy.control == 40 and row.controlDirection == "positive")
assert(row.debuffIcons[1]:IsShown() and row.debuffIcons[1].count.text == "3")
assert(not row.debuffIcons[2]:IsShown(), "another player's debuff was rendered")
local cap = row.targetCap
assert(cap:IsShown() and cap.parent == row.controlBar and cap.layer == "OVERLAY",
    "selected tab must belong to the threat meter")
assert(cap.points[1][1] == "TOPLEFT" and cap.points[1][2] == row.controlBar
    and cap.points[1][3] == "TOPRIGHT" and cap.points[1][4] == 0 and cap.points[1][5] == -2
    and cap.points[2][1] == "BOTTOMLEFT" and cap.points[2][2] == row.controlBar
    and cap.points[2][3] == "BOTTOMRIGHT" and cap.points[2][4] == 0 and cap.points[2][5] == 2,
    "selection tab must attach without a gap and stay inset within meter height")
assert(cap.width == 7 and row.controlBar.points[1][4] + cap.width == 0
    and row.controlBar.points[1][4] + cap.width < row.marker.points[1][4],
    "selection tab must end at the existing gutter edge before the marker lane")
assert(row.controlBar.height - 4 == 12,
    "selection tab must remain a compact 12px tall mark")

local originalTarget = tokens.target
tokens.target = nil
Event("PLAYER_TARGET_CHANGED")
Tick(0.1)
assert(not cap:IsShown(), "clearing target retained selection tab")
tokens.target = originalTarget
Event("PLAYER_TARGET_CHANGED")
Tick(0.1)
assert(cap:IsShown(), "retargeting did not restore selection tab")

auraStacks = 5
Event("UNIT_AURA", "nameplate1")
Tick(0.1)
assert(row.debuffIcons[1].count.text == "5", "alias aura invalidation failed")
held, playerThreat = false, 45
Event("UNIT_THREAT_LIST_UPDATE", "target")
Tick(0.1)
assert(row.enemy.control == -55 and row.controlDirection == "negative")
assert(row.rail.color[1] == 1 and row.rail.color[2] == 0.1)

casting = true
Event("UNIT_SPELLCAST_START", "target")
Tick(0.1)
assert(row.statusFill.color[1] == 1 and row.statusFill.color[2] == 0.68)
local castWidth = row.statusFill.width
Tick(0.05)
assert(row.statusFill.width > castWidth, "cast animation did not advance")
casting, channeling = false, true
Event("UNIT_SPELLCAST_CHANNEL_START", "target")
Tick(0.1)
local channelWidth = row.statusFill.width
assert(row.statusFill.color[1] == 0.58, "protected channel color changed")
Tick(0.05)
assert(row.statusFill.width < channelWidth, "channel did not drain")
channeling = false
Event("UNIT_SPELLCAST_CHANNEL_STOP", "target")
Tick(0.1)
assert(row.statusFill.width == 84 and row.statusFill.color[1] == 0.28,
    "health strip did not return after casting")

maximumPower = 0
Event("UNIT_MAXPOWER", "player")
Tick(0.1)
assert(not addon.ThreatHud.GetPlayerPowerBar():IsShown())
powerType, powerToken, maximumPower = 0, "MANA", 100
Event("UNIT_DISPLAYPOWER", "player")
Tick(0.1)
assert(addon.ThreatHud.GetPlayerPowerBar():IsShown())

tokens.target.dead = true
Event("UNIT_HEALTH", "target")
Tick(0.1)
assert(not row:IsShown() and addon.ThreatObserver.GetSnapshot().total == 0,
    "dead enemy retained its threat row")
tokens.target.dead = false
Tick(0.1)
assert(row:IsShown())
combat = false
Event("PLAYER_REGEN_ENABLED")
assert(not row:IsShown() and hud:IsShown(), "combat exit did not clear enemy rows")
assert(addon.ThreatObserver.GetSnapshot().total == 0)

Event("PLAYER_LEAVING_WORLD")
assert(not driver:IsShown() and not hud:IsShown())
combat = true
Event("PLAYER_ENTERING_WORLD")
assert(driver:IsShown() and hud:IsShown() and row:IsShown(), "world entry did not recover")
Event("PLAYER_LOGIN")
assert(named.ApogeeTankThreatHud == hud, "duplicate initialization rebuilt the HUD")
assert(ApogeePartyHealthBars_ThreatAwareness == nil and ApogeePartyHealthBars_S == nil,
    "standalone addon leaked source globals")

-- Actual picker callbacks and reminder icons against live target transitions.
Tick(0.1)
assert(ApogeeTankEffectsDB and #ApogeeTankEffectsDB.watched == 1,
    "own debuff was not automatically watched before opening the UI")
assert(SLASH_APOGEETANKEFFECTS1 == nil and SlashCmdList.APOGEETANKEFFECTS == nil,
    "old slash-command entry point remains")
local healthBar = addon.ThreatHud.GetPlayerHealthBar()
local function ClickHealth(button, shift, control, alt)
    shiftDown, controlDown, altDown = shift == true, control == true, alt == true
    healthBar.scripts.OnMouseUp(healthBar, button or "LeftButton")
end
ClickHealth("LeftButton", true)
Tick(0.1)
assert(not named.ApogeeTankEffectsWindow and not healthBar.mouse,
    "combat click opened settings or left the health bar interactive")
combat = false
Event("PLAYER_REGEN_ENABLED")
Tick(0.1)
assert(healthBar.mouse, "out-of-combat health-bar access was not restored")
assert(not healthBar.scripts.OnEnter and not healthBar.scripts.OnLeave, "health bar still has a hover tooltip")
for _, gesture in ipairs({ {"LeftButton", false}, {"RightButton", true},
    {"LeftButton", true, true}, {"LeftButton", true, false, true} }) do
    ClickHealth(unpack(gesture))
    Tick(0.1)
    assert(not named.ApogeeTankEffectsWindow, "an unintended gesture opened settings")
end
lockdown = true
ClickHealth("LeftButton", true)
Tick(0.1)
assert(not named.ApogeeTankEffectsWindow, "lockdown click opened settings")
lockdown = false
ClickHealth("LeftButton", true)
-- Combat can begin between the click and its coalesced UI update.
combat = true
Event("PLAYER_REGEN_DISABLED")
Tick(0.1)
assert(not named.ApogeeTankEffectsWindow, "queued opening survived combat entry")
combat = false
Event("PLAYER_REGEN_ENABLED")
Tick(0.1)
assert(not named.ApogeeTankEffectsWindow, "combat click reopened settings after combat")
ClickHealth("LeftButton", true)
Tick(0.1)
local picker = named.ApogeeTankEffectsWindow
assert(picker and picker:IsShown() and picker.width == 680 and picker.height == 312)
for _, item in ipairs(frames) do
    assert(not (item.parent == picker and item.kind == "FontString" and item.text ~= "Cooldowns" and item.text ~= "Debuffs"),
        "picker regained a title, explanation, count or footer")
end
local sunderCheck, shoutCheck
for _, item in ipairs(frames) do
    if item.kind == "CheckButton" and item.label then
        if item.label.text == "Sunder Armor" then sunderCheck = item end
        if item.label.text == "Demoralizing Shout" then shoutCheck = item end
    end
end
assert(sunderCheck and not shoutCheck, "picker did not limit discovery to the player's debuffs")
assert(sunderCheck.hover and sunderCheck.hover.mouse)
sunderCheck.hover.scripts.OnEnter(sunderCheck.hover)
assert(GameTooltip.shown and GameTooltip.spellId, "spell icon/name hover did not show a native tooltip")
sunderCheck.hover.scripts.OnLeave()
assert(not GameTooltip.shown)

assert(sunderCheck:GetChecked(), "automatically watched row was not checked")
assert(#ApogeeTankEffectsDB.watched == 1 and ApogeeTankEffectsDB.watched[1].spellId == 7386,
    "picker selected the wrong captured row")
combat = true
Event("PLAYER_REGEN_DISABLED")
Tick(0.1)
assert(not picker:IsShown() and not healthBar.mouse and not GameTooltip.shown,
    "combat entry did not close the picker and its health-bar hint")
sunderCheck:SetChecked(false)
sunderCheck.scripts.OnClick(sunderCheck)
assert(#ApogeeTankEffectsDB.watched == 1 and sunderCheck:GetChecked(),
    "a late checkbox callback changed settings in combat")
local function MissingIcons(enemyRow)
    local visible = {}
    for _, item in ipairs(frames) do
        if item.parent == (enemyRow or row)
            and item.texture and item.width == 18 and item:IsShown() then
            visible[#visible + 1] = item
        end
    end
    return visible
end
assert(#MissingIcons() == 0, "present selected aura showed a reminder")
for _, caster in ipairs({ "party1", "pet", "unknown" }) do
    sunderSource = caster
    Event("UNIT_AURA", "nameplate1")
    Tick(0.1)
    assert(#MissingIcons() == 1, "foreign or unknown application cleared the reminder")
end
sunderSource = nil
Event("UNIT_AURA", "target")
Tick(0.1)
assert(#MissingIcons() == 1, "missing caster cleared the reminder")
sunderSource = "targettarget"
Event("UNIT_AURA", "target")
Tick(0.1)
assert(#MissingIcons() == 0, "player alias was not recognized as the owner")
sunderSource = "player"
hasSunder = false
Event("UNIT_AURA", "nameplate1")
Tick(0.1)
assert(#MissingIcons() == 1 and MissingIcons()[1].texture.texture == 10,
    "selected missing effect did not show its learned icon")
assert(not MissingIcons()[1].mouse and not MissingIcons()[1].scripts.OnEnter,
    "normal HUD reminder still has a tooltip")
assert(MissingIcons()[1].points[1][1] == "RIGHT"
    and MissingIcons()[1].points[1][2] == row.controlBar
    and MissingIcons()[1].points[1][3] == "LEFT"
    and MissingIcons()[1].points[1][4] == -5 and MissingIcons()[1].points[1][5] == 0,
    "missing effect is not beside the threat meter")
assert(not row.debuffIcons[1]:IsShown(), "missing effect still showed on the applied side")
aurasAvailable = false
Event("UNIT_AURA", "target")
Tick(0.1)
assert(#MissingIcons() == 0, "unavailable auras were treated as absent")
aurasAvailable = true
Event("UNIT_AURA", "target")
Tick(0.1)
assert(#MissingIcons() == 1)
tokens.target.hostile = false
Event("UNIT_FACTION", "target")
Tick(0.1)
assert(#MissingIcons() == 0, "friendly target showed a missing-effect reminder")
tokens.target.hostile = true
tokens.target.dead = true
Event("UNIT_FLAGS", "target")
Tick(0.1)
assert(#MissingIcons() == 0, "dead target showed a missing-effect reminder")
tokens.target.dead = false
hasSunder = true
Event("PLAYER_TARGET_CHANGED")
Tick(0.1)
assert(#MissingIcons() == 0)
combat = false
Event("PLAYER_REGEN_ENABLED")
ClickHealth("LeftButton", true)
Tick(0.1)
for _, item in ipairs(frames) do
    if item.kind == "CheckButton" and item.label and item.label.text == "Sunder Armor" then
        item:SetChecked(false); item.scripts.OnClick(item); break
    end
end
Tick(0.1)
assert(#ApogeeTankEffectsDB.watched == 0, "unchecking did not remove saved choice")
assert(#ApogeeTankEffectsDB.ignored == 1, "unchecked choice was not persisted")
combat = true
Event("PLAYER_REGEN_DISABLED")
Event("UNIT_AURA", "target")
Tick(0.1)
hasSunder = false
Event("UNIT_AURA", "target")
Tick(0.1)
assert(#ApogeeTankEffectsDB.watched == 0 and #MissingIcons() == 0,
    "unchecked effect was automatically re-enabled or still reminded")
-- Re-enable through the actual checkbox, then exercise per-enemy reminder lanes.
combat = false
Event("PLAYER_REGEN_ENABLED")
ClickHealth("LeftButton", true)
Tick(0.1)
for _, item in ipairs(frames) do
    if item.kind == "CheckButton" and item.label and item.label.text == "Sunder Armor" then
        item:SetChecked(true); item.scripts.OnClick(item); break
    end
end
Tick(0.1)
combat = true
Event("PLAYER_REGEN_DISABLED")
Tick(0.1)
assert(#MissingIcons() == 1 and #ApogeeTankEffectsDB.ignored == 0)
local clear
for _, item in ipairs(frames) do
    if item.name == "ApogeeTankDebuffsClear" then clear = item end
end
assert(clear, "compact picker has no Clear All button")
clear.scripts.OnClick(clear)
assert(#ApogeeTankEffectsDB.watched == 1, "Clear All changed saved choices in combat")
combat = false
Event("PLAYER_REGEN_ENABLED")
ClickHealth("LeftButton", true)
Tick(0.1)
local savedBeforeClear = ApogeeTankEffectsDB
Event("UNIT_AURA", "target") -- Deliberately queue a refresh before clearing.
clear.scripts.OnClick(clear)
assert(#ApogeeTankEffectsDB.watched > 0, "first clear click erased selections")
named.ApogeeTankDebuffsConfirmClear.scripts.OnClick()
Tick(0.1)
assert(ApogeeTankEffectsDB == savedBeforeClear and #ApogeeTankEffectsDB.watched == 0
    and #ApogeeTankEffectsDB.ignored == 0,
    "clear failed, detached persistence, or rediscovered the unchanged target")
hasSunder = true
ClickHealth("LeftButton", true)
Tick(0.1)
ClickHealth("LeftButton", true)
Tick(0.1)
assert(#ApogeeTankEffectsDB.watched == 0, "opening the cleared list relearned unchanged auras")
Event("UNIT_AURA", "target")
Tick(0.1)
assert(#ApogeeTankEffectsDB.watched == 1, "learning did not resume after Clear All")
combat = true
Event("PLAYER_REGEN_DISABLED")
Tick(0.1)
assert(#MissingIcons() == 0 and row.debuffIcons[1]:IsShown(),
    "applying the effect did not move it from missing-left to applied-right")

tokens.nameplate2 = { guid = "enemy2", hostile = true, health = 50, maximum = 100, marker = 8 }
tokens.nameplate2target = tokens.player
Event("NAME_PLATE_UNIT_ADDED", "nameplate2")
Tick(0.1)
local secondRow
for _, enemyRow in ipairs(addon.ThreatHud.GetEnemyRows()) do
    if enemyRow.guid == "enemy2" then secondRow = enemyRow.anchor end
end
assert(secondRow and #MissingIcons(secondRow) == 1 and #MissingIcons(row) == 0,
    "two enemies did not have independent coverage")
assert(secondRow.marker:IsShown() and secondRow.marker.points[1][1] == "LEFT"
    and secondRow.marker.points[1][2] == secondRow
    and secondRow.marker.points[1][3] == "RIGHT" and secondRow.marker.points[1][4] == 2,
    "raid marker did not reserve the selection gutter")
enemy2Auras = { { sourceUnit = "player", spellId = 7386, name = "Sunder Armor", icon = 10 } }
Event("UNIT_AURA", "nameplate2")
Tick(0.1)
assert(#MissingIcons(secondRow) == 0 and secondRow.debuffIcons[1]:IsShown(),
    "off-target application did not update both sides of its own row")

extraTargetAura = { sourceUnit = "player", spellId = 99999, name = "Overflow effect", icon = 999 }
enemy2Auras = {}
for id = 100, 106 do
    enemy2Auras[#enemy2Auras + 1] = { sourceUnit = "player", spellId = id, name = "Other " .. id }
end
enemy2Auras[#enemy2Auras + 1] = extraTargetAura
Event("UNIT_AURA", "target")
Event("UNIT_AURA", "nameplate2")
Tick(0.1)
assert(#MissingIcons(secondRow) == 1 and MissingIcons(secondRow)[1].texture.texture == 10,
    "an applied effect hidden in right-side overflow was reported missing")
assert(secondRow.debuffOverflow:IsShown())
tokens.nameplate2.dead = true
Event("UNIT_HEALTH", "nameplate2")
Tick(0.1)
assert(#MissingIcons(secondRow) == 0, "removed enemy retained its missing-effect lane")
combat = false
Event("PLAYER_REGEN_ENABLED")
Tick(0.1)
assert(#MissingIcons(row) == 0 and #MissingIcons(secondRow) == 0,
    "missing-effect lanes survived combat exit after their enemy rows disappeared")

local extraModel = addon.EffectsModel.Create(nil)
local many = {}
for id = 1, 13 do many[id] = { spellId = id, name = "Extra " .. id, icon = id } end
extraModel.Observe(many)
local extraView = addon.EffectsView.Create(extraModel, function() end)
extraView.Render({ { anchor = row, guid = "test", missing = extraModel.GetMissing({}, true) } })
local overflow
for _, item in ipairs(frames) do
    if item.parent == row and item.label and item.label.text == "+9" then overflow = item end
end
assert(overflow and overflow:IsShown() and overflow.points[1][1] == "RIGHT",
    "long reminder list did not use a single-row overflow indicator")
assert(not overflow.mouse and not overflow.scripts.OnEnter, "HUD overflow still has a tooltip")
extraView.Render({ { anchor = row, guid = "replacement", missing = {} } })
assert(#MissingIcons(row) == 0 and not overflow:IsShown(),
    "recycled enemy row retained the previous enemy's reminders")
print("Standalone runtime, UI geometry, client gate, aura and lifecycle tests passed")

-- The picker owns a transient animated demo and can be moved without saving layout.
ClickHealth("LeftButton", true)
Tick(0.1)
assert(picker:IsShown() and picker.movable and picker.clamped)
picker.scripts.OnDragStart()
assert(picker.moving, "picker did not start dragging")
picker.scripts.OnDragStop()
assert(not picker.moving, "picker did not stop dragging")
local demoRow = addon.ThreatHud.GetRows()[1]
assert(demoRow.enemy.name == "Demo enemy 1" and demoRow.enemy.demoMissing,
    "picker did not open a clearly labeled demo")
assert(demoRow.enemy.cast and addon.ThreatHud.GetCastDisplay(demoRow.enemy, now),
    "demo enemy has no active cast preview")
local savedCount = #ApogeeTankEffectsDB.watched
local oldControl = demoRow.enemy.control
now = now + 4
Tick(0.1)
assert(demoRow.enemy.control ~= oldControl, "demo did not animate")
assert(#ApogeeTankEffectsDB.watched == savedCount, "demo changed learned effects")
picker:Hide() -- Includes Escape and close-button behavior in the real client.
assert(not demoRow:IsShown(), "closing picker left demo rows visible")
ClickHealth("LeftButton", true)
Tick(0.1)
combat = true
Event("PLAYER_REGEN_DISABLED")
Tick(0.1)
assert(not picker:IsShown() and addon.ThreatHud.GetRows()[1].enemy.demoMissing == nil,
    "combat retained synthetic enemies")
print("Draggable picker and isolated animated demo tests passed")

-- Cooldown learning reaches the real player-bar view and shared picker.
C_Spell = {
    GetSpellInfo = function(id) return { name = "Test cooldown", iconID = 4321 } end,
    GetSpellCooldown = function() return { startTime = now, duration = 30,
        isEnabled = true, isActive = true, isOnGCD = false, modRate = 1 } end,
    GetSpellCharges = function() return nil end,
}
for _, f in ipairs(frames) do
    if f.events.UNIT_SPELLCAST_SUCCEEDED then
        f.scripts.OnEvent(f, "UNIT_SPELLCAST_SUCCEEDED", "player", "cast", 9876)
    end
end
Event("SPELL_UPDATE_COOLDOWN")
assert(#ApogeeTankCooldownsDB.watched == 1, "cooldown was not learned in composed addon")
local cooldownIcon
for _, f in ipairs(frames) do
    if f.parent == addon.ThreatHud.GetPlayerStatusAnchor() and f.image and f.image.texture == 4321 then cooldownIcon = f end
end
assert(cooldownIcon and cooldownIcon:IsShown() and cooldownIcon.label.text == "30",
    "cooldown countdown did not appear beside the player bar")
combat = false
Event("PLAYER_REGEN_ENABLED")
ClickHealth("LeftButton", true)
Tick(0.1)
assert(named.ApogeeTankDebuffsClear and named.ApogeeTankCooldownsClear,
    "picker does not expose both columns")
local effectCount = #ApogeeTankEffectsDB.watched
named.ApogeeTankCooldownsClear.scripts.OnClick()
assert(#ApogeeTankCooldownsDB.watched == 1, "first click cleared cooldowns")
named.ApogeeTankCooldownsConfirmClear.scripts.OnClick()
assert(#ApogeeTankCooldownsDB.watched == 0 and #ApogeeTankEffectsDB.watched == effectCount,
    "cooldown clear changed debuff selections")
assert(not cooldownIcon:IsShown(), "cleared cooldown icon remained visible")
picker:Hide()
print("Cooldown HUD and independent picker clear integration passed")

ClickHealth("LeftButton", true)
Tick(0.1)
named.ApogeeTankCooldownsClear.scripts.OnClick()
assert(named.ApogeeTankCooldownsConfirmClear:IsShown())
picker:Hide()
assert(not named.ApogeeTankCooldownsConfirmClear:IsShown(),
    "closing the picker retained an armed reset")

-- Repeated identical cooldown frames should not resend texture/text/alpha writes.
local writes = 0
for _, method in ipairs({ "SetTexture", "SetText", "SetAlpha" }) do
    local original = methods[method]
    methods[method] = function(self, ...)
        writes = writes + 1
        return original(self, ...)
    end
end
local perfView = addon.CooldownView.Create(function() return healthBar end)
local perfEntries = {{ spellId = 99, icon = 123, watched = true }}
local perfStates = {[99] = {start = 100, duration = 30, enabled = true}}
perfView.Render(perfEntries, perfStates, 100)
writes = 0
for i = 1, 100 do perfView.Render(perfEntries, perfStates, 100) end
assert(writes == 0, "unchanged countdown frames rewrote texture/text/alpha")
perfView.Render(perfEntries, perfStates, 101)
assert(writes == 1, "one elapsed second should update only the countdown text")
print("Cooldown render performance: 100 unchanged frames produced zero content writes")

local activeStance = 1
function GetNumShapeshiftForms() return 2 end
function GetShapeshiftFormInfo(index) return 8000 + index, index == activeStance, true, 9000 + index end
Event("UPDATE_SHAPESHIFT_FORM")
local stanceIcon
for _, f in ipairs(frames) do
    if f.parent == addon.ThreatHud.GetPlayerStatusAnchor()
        and f.image and f.image.texture == 8001 then stanceIcon = f end
end
assert(stanceIcon and stanceIcon:IsShown() and stanceIcon.points[1][1] == "RIGHT"
    and stanceIcon.points[1][3] == "LEFT" and stanceIcon.points[1][4] == -6
    and stanceIcon.points[1][5] == 0 and stanceIcon.width == 18 and stanceIcon.height == 18
    and not stanceIcon.mouse, "stance slot must retain player-cluster alignment")
assert(stanceIcon.image.points[1][1] == "TOPLEFT"
    and stanceIcon.image.points[1][4] == 1 and stanceIcon.image.points[1][5] == -1
    and stanceIcon.image.points[2][1] == "BOTTOMRIGHT"
    and stanceIcon.image.points[2][4] == -1 and stanceIcon.image.points[2][5] == 1
    and stanceIcon.image.texCoord[1] == 0.07 and stanceIcon.image.texCoord[2] == 0.93,
    "stance artwork must use the same inset and crop as cooldown slots")
activeStance = 2
Event("UPDATE_SHAPESHIFT_FORM")
assert(stanceIcon.image.texture == 8002, "stance change did not update icon")
activeStance = 0
Event("UPDATE_SHAPESHIFT_FORM")
assert(not stanceIcon:IsShown(), "no active stance left an old icon visible")
print("Active stance icon display and switching passed")

combat = false
Event("PLAYER_REGEN_ENABLED")
Tick(0.1)
local redraws, scans = 0, 0
local originalHealth = addon.UnitAPI.GetHealth
addon.UnitAPI.GetHealth = function(unit)
    if unit == "player" then redraws = redraws + 1 end
    return originalHealth(unit)
end
local originalAuras = addon.Auras.ReadPlayerHarmful
addon.Auras.ReadPlayerHarmful = function(unit)
    scans = scans + 1
    return originalAuras(unit)
end
for i = 1, 100 do
    Event("UNIT_POWER_FREQUENT", "player")
    Event("UNIT_HEALTH", "target")
end
assert(redraws == 0 and scans == 0, "event burst performed immediate redraws or scans")
Tick(0.1)
assert(redraws == 1 and scans == 0, "health/power burst was not coalesced")
assert(not driver:IsShown(), "idle threat driver kept running")
print("100 health/power event pairs: one player redraw, zero aura scans, idle driver asleep")
