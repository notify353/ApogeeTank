-- Standalone TOC execution with an instrumented WoW UI; no source addon loaded.
local now, interface, project = 10, 16001, 1
local combat, driver = false, nil
local frames, named = {}, {}
local methods = {}
local Capture = assert(loadfile("tests/ui_capture.lua"))()
local function Frame(kind, name, parent, template)
    local frame = setmetatable({ kind = kind, name = name, parent = parent, template = template,
        shown = true, points = {}, scripts = {}, events = {} }, { __index = methods })
    if template == "UIPanelCloseButton" then frame.width, frame.height = 32, 32 end
    frames[#frames + 1] = frame
    if name then assert(not named[name], "duplicate frame name"); named[name] = frame end
    return frame
end
function methods:SetPoint(...) self.points[#self.points + 1] = {...} end
function methods:ClearAllPoints() self.points = {} end
function methods:HookScript(event, hook)
    local original = self.scripts[event]
    self.scripts[event] = function(...) if original then original(...) end; hook(...) end
end
function methods:SetAllPoints(relative) self.allPoints = relative or self.parent end
function methods:SetBackdrop() end
function methods:SetBackdropColor(...) self.backdropColor = {...} end
function methods:SetBackdropBorderColor() end
function methods:SetScrollChild(child) self.scrollChild = child end
function methods:UpdateScrollChildRect() end
function methods:SetVerticalScroll(value) self.verticalScroll = value end
function methods:SetChecked(value) self.checked = value end
function methods:GetChecked() return self.checked end
function methods:SetWidth(value) self.width = value end
function methods:SetHeight(value) self.height = value end
function methods:SetSize(w, h) self.width, self.height = w, h end
function methods:SetScale(value) self.scale = value end
function methods:SetFrameLevel(value) self.frameLevel = value end
function methods:GetFrameLevel() return self.frameLevel or 0 end
function methods:GetWidth() return self.width or 1920 end
function methods:GetHeight() return self.height or 1080 end
function methods:GetEffectiveScale() return self.scale or 1 end
function methods:GetCenter() return 100, 100 end
function methods:SetEnabled(value) self.enabled = value end
function methods:SetHighlightTexture(value) self.highlight = value end
function methods:RegisterForClicks(...) self.clicks = {...} end
function methods:SetAttribute(key, value)
    assert(not InCombatLockdown(), "insecure protected attribute write in combat")
    self.attributes = self.attributes or {}
    self.attributes[key] = value
end
function methods:UnregisterEvent(event) self.events[event] = nil end
function RegisterStateDriver(frame, state, condition)
    assert(not InCombatLockdown(), "state-driver registration during combat")
    frame.stateDriver = { state, condition }
end
function UnregisterAttributeDriver(frame, key)
    assert(not InCombatLockdown())
    if frame.attributeDrivers then frame.attributeDrivers[key] = nil end
end
function RegisterAttributeDriver(frame, key, value)
    assert(not InCombatLockdown())
    frame.attributeDrivers = frame.attributeDrivers or {}
    frame.attributeDrivers[key] = value
end
function SecureHandlerWrapScript()
    error("Forever restricted compiler unavailable; addon must not register snippets")
end
function methods:SetColorTexture(...) self.color = {...} end
function methods:SetTextColor(...) self.textColor = {...} end
function methods:GetFont() return "Fonts/FRIZQT__.TTF", 12, "" end
function methods:SetFont(font, size, flags) self.font, self.fontSize, self.fontFlags = font, size, flags end
function methods:SetText(value) self.text = value end
function methods:SetDesaturated(value) self.desaturated = value end
function methods:SetTexture(value) self.texture = value end
function methods:SetTexCoord(...) self.texCoord = {...} end
function methods:SetJustifyH(value) self.justify = value end
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
function methods:IsShown() return self.shown and (not self.parent or self.parent:IsShown()) end
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
Minimap = Frame("Frame", "Minimap", UIParent)
function GetCursorPosition() return 20, 100 end
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
function GameTooltip:IsOwned(owner) return self.owner == owner end
function GameTooltip:SetText(text) self.text = text end
function GameTooltip:SetSpellByID(id) self.spellId = id end
function GameTooltip:AddLine() error("unexpected addon text on standard spell tooltip") end
function GameTooltip:Show() self.shown = true end
function GameTooltip:Hide() self.shown = false end
function GetBuildInfo() return "1.60.1", "70009", "", interface end
function GetTime() return now end
function UnitAffectingCombat() return combat end
local classToken = "WARRIOR"
function UnitClass() return classToken, classToken end
function GetNumShapeshiftForms() return 1 end
function GetShapeshiftFormInfo() return 8001, true, true, 9001 end

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
C_NamePlate = { GetNamePlates = function() return { { namePlateUnitToken = "nameplate1" } } end }

local function LoadAddon()
    local addon = {}
    for line in io.lines("ApogeeTank.toc") do
        local path = line:match("^([^#].-%.lua)%s*$")
        if path then assert(loadfile(path))("ApogeeTank", addon) end
    end
    return addon
end

local addon
local function Event(event, unit)
    local delivered = false
    for _, listener in ipairs(frames) do
        if listener.events[event] and listener.scripts.OnEvent then
            delivered = true
            listener.scripts.OnEvent(listener, event, unit)
        end
    end
    -- Model the engine-owned visibility condition, not an addon callback.
    for _, listener in ipairs(frames) do
        if listener.stateDriver then
            listener:SetShown(UnitExists("target") and UnitCanAttack("player", "target")
                and not UnitIsDeadOrGhost("target"))
        end
    end
    -- Unregistered events model engine delivery to zero listeners.
end
local function Tick(elapsed)
    now = now + elapsed
    for _, listener in ipairs(frames) do
        if listener:IsShown() and listener.scripts.OnUpdate then
            listener.scripts.OnUpdate(listener, elapsed)
        end
    end
end
local function ClickMinimap(button, shift, control, alt)
    shiftDown, controlDown, altDown = shift == true, control == true, alt == true
    local minimapButton = named.ApogeeTankMinimapButton
    minimapButton.scripts.OnClick(minimapButton, button or "LeftButton")
end
C_Spell = {
    GetSpellInfo = function(id) return { name = "Test cooldown", iconID = 4321 } end,
    GetSpellCooldown = function() return { startTime = math.floor(now), duration = 30,
        isEnabled = true, isActive = true, isOnGCD = false, modRate = 1 } end,
    GetSpellCharges = function() return nil end,
}
-- Forever TOC startup and transitions.
frames, named, driver = {}, {}, nil
interface, WOW_PROJECT_ID = 16001, 1
function GetBuildInfo() return "1.60.1", "70009", "", interface end
local secretValue = {}
function issecretvalue(value) return rawequal(value, secretValue) end
function canaccessvalue(value) return not issecretvalue(value) end
function methods:SetStatusBarTexture(texture) self.barTexture = texture end
function methods:SetStatusBarColor(...) self.barColor = {...} end
function methods:SetMinMaxValues(low, high) self.minimum, self.maximum = low, high end
function methods:SetValue(value) self.barValue = value end
local rejectMarker = false
function methods:SetSpriteSheetCell(cell, rows, columns)
    if rejectMarker then error("marker display unavailable") end
    assert(rows == 4 and columns == 4, "wrong raid marker sheet dimensions")
    self.spriteCell = cell
end
local preservedDebuffs = { version = 999, choices = { [7386] = false } }
ApogeeTankEffectsDB, ApogeeTankCooldownsDB = preservedDebuffs, nil
local betaAuraReads = 0
C_UnitAuras = {}
C_UnitAuras.GetAuraDataByIndex = function()
    betaAuraReads = betaAuraReads + 1
    error("Forever debuffs are disabled")
end
tokens.player.health = secretValue
tokens.target.health = secretValue
-- Untargeted enemies must never populate Forever rows, including login/zoning.
tokens.nameplate2 = { guid = "enemy2", hostile = true, health = 100, maximum = 100 }
C_NamePlate.GetNamePlates = function()
    return {
        { unitToken = "nameplate1", GetUnit = function(self) return self.unitToken end },
        { unitToken = "nameplate2", GetUnit = function(self) return self.unitToken end },
    }
end
addon = LoadAddon()
assert(addon.Client == "foreverBeta")
Event("PLAYER_LOGIN")
Tick(0.1)
assert(addon.ThreatObserver.Refresh().total == 1,
    "beta login included an untargeted enemy")
Event("PLAYER_LEAVING_WORLD")
Event("PLAYER_ENTERING_WORLD")
assert(addon.ThreatObserver.Refresh().total == 1,
    "beta zoning included an untargeted enemy")
Tick(0.1)
local nativeBars = {}
for _, item in ipairs(frames) do
    if item.kind == "StatusBar" then nativeBars[#nativeBars + 1] = item end
end
assert(#nativeBars == 1 and rawequal(nativeBars[1].barValue, secretValue),
    "only native enemy health should remain")
assert(nativeBars[1].mouse == false, "native fill intercepts marking clicks")
-- A selected hostile target is visible before combat even without threat.
local originalPrecombatThreat = UnitDetailedThreatSituation
function UnitDetailedThreatSituation() return nil end
Event("PLAYER_TARGET_CHANGED")
local precombatRow = addon.ThreatHud.GetRows()[1]
assert(precombatRow:IsShown() and precombatRow.controlBar:IsShown()
    and precombatRow.enemy.control == nil and precombatRow.controlFill.width == 0
    and precombatRow.enemy.severity == "unknown", "precombat target faked threat or hid click area")
local markButton = named.ApogeeTankTargetMarkerButton
assert(markButton and markButton.parent == UIParent
    and markButton.template == "SecureActionButtonTemplate",
    "marking must use an independent secure action button")
assert(markButton.attributes.harmbutton1 == "skull"
    and markButton.attributes.harmbutton2 == "cross"
    and markButton.attributes["shift-harmbutton1"] == "moon"
    and markButton.attributes["*marker-skull"] == 8
    and markButton.attributes["*marker-cross"] == 7
    and markButton.attributes["*marker-moon"] == 5
    and markButton.attributes["*action*"] == "set", "incorrect secure mark mappings")
for _, prefix in ipairs({ "ctrl-", "alt-", "ctrl-shift-", "alt-shift-", "alt-ctrl-", "alt-ctrl-shift-" }) do
    assert(markButton.attributes[prefix .. "harmbutton1"] == ""
        and markButton.attributes[prefix .. "harmbutton2"] == "", "modifier fallback enabled marking")
end
assert(markButton.attributes["shift-harmbutton2"] == "" and markButton.attributes["*type*"] == "")
assert(markButton.clicks[1] == "AnyDown" and markButton.attributes.useOnKeyDown
    and markButton.attributes.unit == "target", "marking must use current target at mouse-down")
assert(not precombatRow.controlBar.scripts.OnMouseUp
    and not addon.UnitAPI.SetCurrentTargetRaidMarker, "insecure marker call survived")
assert(markButton.stateDriver[1] == "visibility"
    and markButton.stateDriver[2] == "[@target,harm,nodead] show; hide")
assert(markButton.width == precombatRow.controlBar.width and markButton.height == precombatRow.controlBar.height
    and markButton.scale == addon.ThreatHud.GetFrame().scale
    and markButton.points[1][4] == 182.5 and markButton.points[1][5] == 2.5,
    "secure overlay does not align with the scaled target meter")
assert(precombatRow.points[1][3] == "TOPLEFT" and precombatRow.points[1][5] == -24
    and precombatRow.points[2][5] == -24 and precombatRow.height == 24,
    "Forever enemy row must start below the fixed spell strip")
assert(addon.ThreatHud.GetFrame().points[1][5] * markButton.scale == 55
    and addon.ThreatHud.GetStanceAnchor().points[1][1] == "RIGHT"
    and addon.ThreatHud.GetStanceAnchor().points[1][2] == precombatRow.controlBar
    and addon.ThreatHud.GetStanceAnchor().points[1][3] == "LEFT"
    and addon.ThreatHud.GetStanceAnchor().points[1][4] == -2
    and addon.ThreatHud.GetStanceAnchor().height == addon.Style.iconSize
    and precombatRow.marker.height == addon.Style.iconSize
    and precombatRow.marker.points[1][4] == 2
    and addon.ThreatHud.GetStanceGeometry().size == addon.Style.iconSize
    and addon.ThreatHud.GetStanceGeometry().x == 57.5
    and addon.ThreatHud.GetStanceGeometry().y == -8.5
    and addon.ThreatHud.GetStanceAnchor().points[1][5] == -3
    and precombatRow.marker.points[1][5] == -3
    and addon.Style.iconSize == precombatRow.controlBar.height + precombatRow.statusBar.height + 1
    and addon.ThreatHud.GetCooldownAnchor().points[1][2] == addon.ThreatHud.GetFrame()
    and addon.ThreatHud.GetCooldownAnchor().points[1][4] == 265
    and addon.ThreatHud.GetGuidanceAnchor().points[1][5] == -1,
    "moving enemy row moved player anchor")
assert(markButton.points[1][5] == addon.ThreatHud.GetFrame().points[1][5]
    + precombatRow.points[2][5] + precombatRow.controlBar.points[1][5],
    "secure hit area and threat meter vertical anchors diverged")

-- Optional integration input is explicit and fails closed if supplied but invalid.
-- No client code is redistributed and no restricted compiler is injected.
local function VerifyNative(exportRoot, testButton)
    if not exportRoot or exportRoot == "" then
        print("SKIP native secure integration: supply matching " .. "Forever" .. " export")
        return
    end
    local secureExport = assert(io.open(exportRoot .. "/Blizzard_FrameXML/SecureTemplates.lua", "r"))
    local source = secureExport:read("*a"); secureExport:close()
    local restrictedExport = assert(io.open(exportRoot .. "/Blizzard_RestrictedAddOnEnvironment/RestrictedExecution.lua", "r"))
    local restrictedSource = restrictedExport:read("*a"); restrictedExport:close()
    local buildSource = assert(restrictedSource:match("(local function BuildRestrictedClosure.-\nend)"))
    local buildChunk = assert(loadstring(buildSource .. "\nreturn BuildRestrictedClosure"))
    setfenv(buildChunk, { type = type, tostring = tostring }) -- compiler deliberately absent
    local build = buildChunk()
    local compiled, compileError = pcall(build, "return true", {}, "self,button,down")
    assert(not compiled and tostring(compileError):find("nil value"),
        "did not reproduce the actual export's missing-compiler failure")

    local resolverSource = assert(source:match("(local function GetConvertedButtonUnitAndActionType.-\nend)"))
    local actionSource = assert(source:match("SECURE_ACTIONS.raidtarget =%s*(function%(self, unit, button%).-\n\tend);"))
    local prefix = ""
    local function Attribute(self, name, button)
        local suffix = button == "LeftButton" and "1" or button == "RightButton" and "2" or ("-" .. button)
        local attributes = self.attributes
        local value = attributes[prefix .. name .. suffix] or attributes["*" .. name .. suffix]
            or attributes[prefix .. name .. "*"] or attributes["*" .. name .. "*"]
        if value == "" then return nil end
        return value
    end
    local calls, currentMarker = {}, nil
    local environment = {
        type = type, tonumber = tonumber, PRESS_TYPE_DOWN = 1, PRESS_TYPE_HOLD_RELEASE = 3,
        SecureButton_GetModifiedUnit = function(self) return self.attributes.unit end,
        SecureButton_GetModifiedAttribute = Attribute,
        UnitCanAttack = UnitCanAttack, UnitCanAssist = function(_, unit) return tokens[unit] and not tokens[unit].hostile end,
        UnitExists = UnitExists, GetRaidTargetIndex = function() return currentMarker end,
        SetRaidTarget = function(unit, id) assert(unit == "target"); calls[#calls + 1] = id; currentMarker = id end,
    }
    assert(environment.loadstring_untainted == nil and environment.SecureCmdOptionParse == nil)
    local compile = assert(loadstring(resolverSource .. "\nreturn GetConvertedButtonUnitAndActionType"))
    setfenv(compile, environment)
    local resolve = compile()
    compile = assert(loadstring("return " .. actionSource)); setfenv(compile, environment)
    local act = compile()
    local function Press(button, modifiers)
        prefix = modifiers or ""
        local mapped, unit, kind = resolve(testButton, button, 1)
        if kind == "raidtarget" then act(testButton, unit, mapped) end
    end
    Press("LeftButton"); Press("LeftButton") -- set must not toggle off
    Press("RightButton"); Press("LeftButton", "shift-")
    assert(#calls == 3 and calls[1] == 8 and calls[2] == 7 and calls[3] == 5,
        "real exported secure dispatch rejected mappings")
    Press("RightButton", "shift-"); Press("LeftButton", "ctrl-")
    Press("MiddleButton"); Press("LeftButton", "alt-ctrl-shift-")
    local targetBefore = tokens.target
    tokens.target = tokens.player; Press("LeftButton")
    tokens.target = nil; Press("LeftButton")
    tokens.target = targetBefore
    assert(#calls == 3, "real secure resolver admitted unsupported/friendly/empty target")
    print("Forever" .. " exported secure resolver/actions and repeated-set semantics passed")
end
VerifyNative(os.getenv("APOGEE_FOREVER_EXPORT"), markButton)
local clickedTarget = tokens.target
tokens.target = tokens.player
Event("PLAYER_TARGET_CHANGED")
assert(addon.ThreatObserver.GetSnapshot().total == 0, "friendly precombat target shown")
tokens.target = clickedTarget
tokens.target.dead = true
Event("PLAYER_TARGET_CHANGED")
assert(addon.ThreatObserver.GetSnapshot().total == 0, "dead precombat target shown")
tokens.target.dead = false
tokens.target = nil
Event("PLAYER_TARGET_CHANGED")
assert(addon.ThreatObserver.GetSnapshot().total == 0, "cleared precombat target remained visible")
tokens.target = clickedTarget
function SetRaidTarget() error("addon must never call protected marker API") end
UnitDetailedThreatSituation = originalPrecombatThreat
Event("PLAYER_TARGET_CHANGED")

-- The native visibility driver owns a visible neutral meter even when Lua
-- cannot identify a living hostile target. No fabricated GUID enters rows.
local markerBackground
for _, item in ipairs(frames) do
    if item.parent == markButton and item.layer == "BACKGROUND" then markerBackground = item end
end
assert(markerBackground and markerBackground:IsShown()
    and markButton.frameLevel < addon.ThreatHud.GetFrame().frameLevel,
    "secure marking lacks an independent visible meter beneath HUD content")
local readableGUID = UnitGUID
UnitGUID = function(unit) if unit == "target" then return secretValue end; return readableGUID(unit) end
Event("PLAYER_TARGET_CHANGED")
assert(addon.ThreatObserver.GetSnapshot().total == 0 and markerBackground:IsShown(),
    "restricted identity removed the marking affordance or invented an enemy")
UnitGUID = readableGUID
Event("PLAYER_TARGET_CHANGED")

-- Count actual observer rebuilds/API reads/text writes, not elapsed wall time.
local sampleCount, threatCount, textCount = 0, 0, 0
local originalRefresh, originalThreat, originalText = addon.ThreatObserver.Refresh,
    UnitDetailedThreatSituation, methods.SetText
addon.ThreatObserver.Refresh = function(...)
    sampleCount = sampleCount + 1; return originalRefresh(...)
end
UnitDetailedThreatSituation = function(...)
    threatCount = threatCount + 1; return originalThreat(...)
end
methods.SetText = function(self, ...)
    textCount = textCount + 1; return originalText(self, ...)
end
for _ = 1, 10 do Tick(0.1) end
assert(sampleCount == 0 and threatCount == 0 and textCount == 0,
    "unchanged precombat target rebuilt snapshots, queried threat or rewrote text")
for _ = 1, 100 do Event("UNIT_THREAT_LIST_UPDATE", "target") end
Tick(0.1)
assert(sampleCount == 1 and threatCount > 0 and textCount == 0,
    "precombat threat events lost freshness, failed coalescing or rewrote unchanged text")
print("Forever idle target: 10 ticks, zero snapshot rebuilds/threat calls/text writes; 100 events: one refresh")
addon.ThreatObserver.Refresh, UnitDetailedThreatSituation, methods.SetText =
    originalRefresh, originalThreat, originalText

combat = true
Event("PLAYER_REGEN_DISABLED")
Tick(0.1)
local readableThreat = UnitDetailedThreatSituation
assert(addon.ThreatObserver.GetSnapshot().total == 1,
    "beta combat included an untargeted enemy")
lockdown = true
Event("PLAYER_TARGET_CHANGED")
Tick(0.1)
assert(markButton == named.ApogeeTankTargetMarkerButton,
    "combat refresh recreated secure button")
lockdown = false
assert(not named.ApogeeTankPickerWindow, "enemy marking opened player picker")
local firstTarget = tokens.target
held = false -- A lost enemy must not linger after changing targets.
Event("UNIT_THREAT_LIST_UPDATE", "target")
Tick(0.1)
tokens.focus, tokens.mouseover, tokens.party1target = firstTarget, firstTarget, firstTarget
tokens.target = tokens.nameplate2
tokens.target.marker = 8
Event("PLAYER_TARGET_CHANGED")
local switched = addon.ThreatObserver.GetSnapshot()
assert(switched.total == 1 and switched.enemies[1].guid == tokens.target.guid
    and switched.enemies[1].unit == "target" and switched.enemies[1].raidMarker == 8,
    "beta target switch retained old sources or lost marker")
assert(addon.ThreatObserver.GetSnapshot().total == 1
    and addon.ThreatHud.GetRows()[1].enemy.guid == tokens.target.guid,
    "row contract did not switch immediately")
local betaEnemyRow
for _, item in ipairs(addon.ThreatHud.GetRows()) do
    if item:IsShown() then betaEnemyRow = item end
end
assert(betaEnemyRow.marker:IsShown() and betaEnemyRow.marker.spriteCell == 8,
    "readable beta marker did not render")
assert(betaEnemyRow.name == nil, "mob name presentation must not be created")

tokens.target.marker = secretValue
Event("RAID_TARGET_UPDATE")
Tick(0.1)
assert(addon.ThreatObserver.GetSnapshot().enemies[1].raidMarker == nil,
    "restricted marker leaked into snapshot")
assert(betaEnemyRow.marker:IsShown() and rawequal(betaEnemyRow.marker.spriteCell, secretValue),
    "restricted marker was discarded before native display")
tokens.target.marker = nil
Event("RAID_TARGET_UPDATE")
Tick(0.1)
assert(not betaEnemyRow.marker:IsShown(), "cleared marker retained old texture")
tokens.target.marker = 3
Event("RAID_TARGET_UPDATE")
Tick(0.1)
assert(betaEnemyRow.marker:IsShown() and betaEnemyRow.marker.spriteCell == 3,
    "marker update failed to recover")
rejectMarker = true
Event("RAID_TARGET_UPDATE")
Tick(0.1)
assert(not betaEnemyRow.marker:IsShown(), "failed marker setter retained stale icon")
rejectMarker = false
Event("RAID_TARGET_UPDATE")
Tick(0.1)
assert(betaEnemyRow.marker:IsShown(), "marker setter failed to recover")

Event("NAME_PLATE_UNIT_ADDED", "nameplate1")
Tick(0.1)
assert(addon.ThreatObserver.GetSnapshot().total == 1, "nameplate event added a beta row")
tokens.target = nil
Event("PLAYER_TARGET_CHANGED")
assert(addon.ThreatObserver.GetSnapshot().total == 0
    and addon.ThreatObserver.GetSnapshot().total == 0, "target clear retained rows")
assert(not betaEnemyRow:IsShown(), "target clear left marker row visible")
tokens.target = tokens.player
Event("PLAYER_TARGET_CHANGED")
assert(addon.ThreatObserver.GetSnapshot().total == 0, "friendly target populated threat")
tokens.target = firstTarget
tokens.target.dead = true
Event("PLAYER_TARGET_CHANGED")
assert(addon.ThreatObserver.GetSnapshot().total == 0, "dead target populated threat")
tokens.target.dead = false
Event("PLAYER_TARGET_CHANGED")
assert(addon.ThreatObserver.GetSnapshot().total == 1, "target reacquisition failed")
-- Polling must also drop a lost target without a delivered target event.
tokens.target = nil
Tick(0.1)
assert(addon.ThreatObserver.GetSnapshot().total == 0, "poll retained stale target")
tokens.target = firstTarget
Event("PLAYER_TARGET_CHANGED")
assert(betaAuraReads == 0 and ApogeeTankEffectsDB == preservedDebuffs,
    "Forever read or modified debuffs")
function UnitDetailedThreatSituation() return secretValue, secretValue, secretValue end
Event("UNIT_THREAT_LIST_UPDATE", "target")
Tick(0.1)
assert(addon.ThreatObserver.GetSnapshot().total == 1
    and addon.ThreatObserver.GetSnapshot().enemies[1].control == nil
    and addon.ThreatObserver.GetSnapshot().enemies[1].severity == "unknown",
    "restricted threat did not retain honest target presentation")
UnitDetailedThreatSituation = readableThreat
Event("UNIT_THREAT_LIST_UPDATE", "target")
Tick(0.1)
assert(addon.ThreatObserver.GetSnapshot().total > 0, "readable threat failed to recover")
combat = false
Event("PLAYER_REGEN_ENABLED")
tokens.target = nil
Event("PLAYER_TARGET_CHANGED")
assert(addon.ThreatObserver.GetSnapshot().total == 0
    and addon.ThreatObserver.GetSnapshot().total == 0, "idle target clear retained rows")
tokens.target = firstTarget
Event("PLAYER_TARGET_CHANGED")
assert(addon.ThreatObserver.GetSnapshot().total == 1, "idle hostile target did not appear")
ClickMinimap("RightButton")
Tick(0.1)
assert(not named.ApogeeTankPickerWindow, "right-click unexpectedly opened picker")
ClickMinimap("LeftButton")
Tick(0.1)
local betaPicker = named.ApogeeTankPickerWindow
assert(betaPicker and betaPicker:IsShown() and betaPicker.width == 340
    and named.ApogeeTankCooldownsClear and not named.ApogeeTankDebuffsClear,
    "Forever picker is not cooldown-only")
assert(addon.ThreatObserver.GetSnapshot().total == 1
    and addon.ThreatHud.GetRows()[1].enemy.demoMissing == nil, "Forever started a picker demo")
for _, listener in ipairs(frames) do
    if listener.events.UNIT_SPELLCAST_SUCCEEDED then
        listener.scripts.OnEvent(listener, "UNIT_SPELLCAST_SUCCEEDED", "player", "cast", 9876)
    end
end
Event("SPELL_UPDATE_COOLDOWN")
assert(#ApogeeTankCooldownsDB.watched == 1, "Forever standalone cooldown did not learn")
Tick(0.1)
local learnedWhileOpen = false
for _, item in ipairs(frames) do
    if item.kind == "CheckButton" and item.icon and item.icon.texture == 4321
        and item:GetChecked() then learnedWhileOpen = true end
end
assert(betaPicker:IsShown() and learnedWhileOpen, "open picker missed newly learned cooldown")
Capture("Forever picker", frames, true)
combat = true
Event("PLAYER_REGEN_DISABLED")
assert(not betaPicker:IsShown(), "beta combat left picker open")
ClickMinimap("LeftButton")
Tick(0.1)
assert(not betaPicker:IsShown(), "beta picker opened during combat")
local betaCooldownIcon
for _, item in ipairs(frames) do
    if item.parent == addon.ThreatHud.GetCooldownAnchor() and item.image
        and item.image.texture == 4321 then betaCooldownIcon = item end
end
assert(betaCooldownIcon and betaCooldownIcon:IsShown(), "Forever standalone cooldown is hidden")
Capture("Forever combat", frames, false)
-- Restricted numeric timers still have a native duration object. Reproduce the
-- question-mark regression without ever inspecting that object's time values.
local nativeDuration = setmetatable({}, {
    __index = function() error("opaque duration inspected") end,
    __tostring = function() error("opaque duration formatted") end,
})
local durationQueries, durationWrites = 0, 0
local rejectDuration = false
function methods:SetDrawSwipe(value) self.drawSwipe = value end
function methods:SetDrawEdge() end
function methods:SetDrawBling() end
function methods:SetCountdownFont(font) self.countdownFont = font end
function methods:SetHideCountdownNumbers(value) self.hideNumbers = value end
function methods:SetCooldownFromDurationObject(value, clearIfZero)
    if rejectDuration then error("native duration unavailable") end
    assert(value == nativeDuration and clearIfZero == true)
    durationWrites = durationWrites + 1
    self.durationObject = value
end
local readableCooldown = C_Spell.GetSpellCooldown
local readableCharges = C_Spell.GetSpellCharges
C_Spell.GetSpellCooldown = function()
    return { startTime = secretValue, duration = secretValue, modRate = secretValue,
        isEnabled = true, isActive = true, isOnGCD = false }
end
C_Spell.GetSpellCooldownDuration = function(id, ignoreGCD)
    assert(id == 9876 and ignoreGCD == true)
    durationQueries = durationQueries + 1
    return nativeDuration
end
Event("SPELL_UPDATE_COOLDOWN")
assert(betaCooldownIcon.label.text == "" and betaCooldownIcon.cooldown:IsShown()
    and betaCooldownIcon.cooldown.durationObject == nativeDuration
    and betaCooldownIcon.cooldown.drawSwipe == false,
    "restricted cooldown remained a question mark instead of native countdown")
local nativeQueries, nativeWrites = durationQueries, durationWrites
Tick(0.1)
assert(durationQueries == nativeQueries and durationWrites == nativeWrites,
    "countdown ticks queried APIs or reset the native timer")
local activeRestrictedCooldown = C_Spell.GetSpellCooldown
C_Spell.GetSpellCooldown = function()
    return { startTime = secretValue, duration = secretValue, modRate = secretValue,
        isEnabled = false, isActive = false, isOnGCD = false }
end
Event("SPELL_UPDATE_COOLDOWN")
assert(betaCooldownIcon.label.text == "?" and betaCooldownIcon.alpha == 0.4
    and not betaCooldownIcon.cooldown:IsShown(), "held native cooldown looks ready")
C_Spell.GetSpellCooldown = activeRestrictedCooldown
Event("SPELL_UPDATE_COOLDOWN")
assert(betaCooldownIcon.label.text == "" and betaCooldownIcon.cooldown:IsShown(),
    "held native cooldown failed to resume")
C_Spell.GetSpellCharges = function()
    return { maxCharges = 2, currentCharges = secretValue, isActive = true,
        cooldownStartTime = secretValue, cooldownDuration = secretValue, chargeModRate = secretValue }
end
C_Spell.GetSpellChargeDuration = function(id)
    assert(id == 9876)
    return nativeDuration
end
Event("SPELL_UPDATE_CHARGES")
assert(betaCooldownIcon.label.text == "" and not betaCooldownIcon.cooldown.hideNumbers,
    "restricted charges lost recharge countdown")
C_Spell.GetSpellCharges = function()
    return { maxCharges = 2, currentCharges = 1, isActive = true,
        cooldownStartTime = secretValue, cooldownDuration = secretValue, chargeModRate = secretValue }
end
Event("SPELL_UPDATE_CHARGES")
assert(betaCooldownIcon.label.text == "1" and betaCooldownIcon.cooldown.hideNumbers,
    "readable charge count was discarded or covered by countdown")
C_Spell.GetSpellCharges = readableCharges
nativeDuration = {} -- New timer payload; native setter rejects this update.
rejectDuration = true
Event("SPELL_UPDATE_COOLDOWN")
assert(betaCooldownIcon.label.text == "?" and not betaCooldownIcon.cooldown:IsShown(),
    "native failure retained a stale countdown or asserted readiness")
rejectDuration = false
Event("SPELL_UPDATE_COOLDOWN")
assert(betaCooldownIcon.label.text == "" and betaCooldownIcon.cooldown:IsShown(),
    "native countdown did not recover")
C_Spell.GetSpellCooldown = readableCooldown
Event("SPELL_UPDATE_COOLDOWN")
assert(not betaCooldownIcon.cooldown:IsShown() and betaCooldownIcon.label.text == "30",
    "numeric timer recovery left duplicate native countdown")


for _, betaRow in ipairs(addon.ThreatHud.GetRows()) do
    assert(betaRow.debuffIcons == nil and not betaRow.debuffOverflow,
        "Forever created applied-debuff controls")
    if betaRow:IsShown() then
        assert(betaRow.enemy.playerAuras == nil, "Forever populated aura coverage")
    end
end
combat = false
Event("PLAYER_REGEN_ENABLED")
ClickMinimap("LeftButton")
Tick(0.1)
local betaChoice
for _, item in ipairs(frames) do
    if item.kind == "CheckButton" and item.icon and item.icon.texture == 4321 then betaChoice = item end
end
assert(betaChoice and betaChoice:GetChecked(), "cooldown selection missing from picker")
betaChoice:SetChecked(false)
betaChoice.scripts.OnClick(betaChoice)
assert(#ApogeeTankCooldownsDB.watched == 0, "cooldown opt-out not saved")
betaChoice:SetChecked(true)
betaChoice.scripts.OnClick(betaChoice)
assert(#ApogeeTankCooldownsDB.watched == 1, "cooldown reselect failed")
named.ApogeeTankCooldownsClear.scripts.OnClick()
assert(named.ApogeeTankCooldownsConfirmClear:IsShown() and #ApogeeTankCooldownsDB.watched == 1,
    "clear did not require confirmation")
betaChoice.hover.scripts.OnEnter(betaChoice.hover)
assert(GameTooltip.shown, "picker spell tooltip failed to open")
betaPicker:Hide()
assert(not GameTooltip.shown, "closing picker left its spell tooltip visible")
assert(not named.ApogeeTankCooldownsConfirmClear:IsShown(), "close retained clear confirmation")
-- Combat must cancel an open that is queued but not yet rendered.
ClickMinimap("LeftButton")
combat = true
Event("PLAYER_REGEN_DISABLED")
combat = false
Event("PLAYER_REGEN_ENABLED")
Tick(0.1)
assert(not betaPicker:IsShown(), "combat retained pending picker open")
ClickMinimap("LeftButton")
Tick(0.1)
named.ApogeeTankCooldownsClear.scripts.OnClick()
named.ApogeeTankCooldownsConfirmClear.scripts.OnClick()
assert(#ApogeeTankCooldownsDB.watched == 0 and ApogeeTankEffectsDB == preservedDebuffs,
    "cooldown clear failed or touched debuffs")
Event("UNIT_AURA", secretValue)
Event("PLAYER_LEAVING_WORLD")
assert(not betaPicker:IsShown(), "zoning left picker open")
Event("PLAYER_TARGET_CHANGED")
Event("UNIT_HEALTH", "target")
Tick(0.2)
assert(not named.ApogeeTankThreatHud:IsShown(), "late zoning events restored target presentation")
assert(betaAuraReads == 0 and ApogeeTankEffectsDB == preservedDebuffs
    and preservedDebuffs.version == 999 and preservedDebuffs.choices[7386] == false,
    "beta debuff lifecycle ran or saved choices changed")
print("Full beta TOC, target-only threat, disabled debuffs, cooldown-only picker and standalone cooldown and zoning smoke passed")

-- Forever-only regression coverage for the retained spell strip and preview.
Event("PLAYER_ENTERING_WORLD")
local stableAnchor = addon.ThreatHud.GetCooldownAnchor()
local anchorPoint = stableAnchor.points[1]
local stanceIcon
for _, item in ipairs(frames) do
    if item.parent == addon.ThreatHud.GetStanceAnchor() and item.image then stanceIcon = item end
end
assert(stanceIcon, "stance slot not initialized")
local stanceReads = 0
local readStance = addon.GetActiveStanceIcon
addon.GetActiveStanceIcon = function() stanceReads = stanceReads + 1; return readStance() end
Event("PLAYER_LEAVING_WORLD")
Event("UPDATE_SHAPESHIFT_FORM")
assert(stanceReads == 0, "stance read APIs after world exit")
Event("PLAYER_ENTERING_WORLD")
assert(stanceReads == 1 and stanceIcon:IsShown(), "stance failed to recover after zoning")
addon.GetActiveStanceIcon = readStance
local activeForm = true
function GetShapeshiftFormInfo() return 8001, activeForm, true, 9001 end
for _, class in ipairs({ "WARRIOR", "DRUID", "PALADIN", "PRIEST" }) do
    classToken, activeForm = class, class ~= "PRIEST"
    Event("UPDATE_SHAPESHIFT_FORM")
    assert(stanceIcon:IsShown() == activeForm, "form/aura visibility did not follow native state")
    assert(stableAnchor.points[1] == anchorPoint, "empty stance slot shifted cooldowns")
end
activeForm = true
Event("UPDATE_SHAPESHIFT_FORM")
local cooldownEnd = now + 20
local spellReads = 0
C_Spell.GetSpellCooldown = function()
    spellReads = spellReads + 1
    return { startTime = cooldownEnd - 20, duration = 20, isEnabled = true,
        isActive = true, isOnGCD = false, modRate = 1 }
end
for id = 2001, 2008 do
    for _, listener in ipairs(frames) do
        if listener.events.UNIT_SPELLCAST_SUCCEEDED then
            listener.scripts.OnEvent(listener, "UNIT_SPELLCAST_SUCCEEDED", "player", "cast", id)
        end
    end
    Event("SPELL_UPDATE_COOLDOWN")
end
local visibleIcons, overflow = 0, nil
for _, item in ipairs(frames) do
    if item.parent == stableAnchor and item.image and item:IsShown() then visibleIcons = visibleIcons + 1 end
    if item.kind == "FontString" and item.text == "+2" and item:IsShown() then overflow = item end
end
assert(visibleIcons == 6 and overflow, "six cooldown slots or overflow failed")
assert(#addon.ThreatHud.GetRows() == 1 and not addon.ThreatHud.ReconcileQueue,
    "secondary enemy machinery survived")
assert(not driver.events.NAME_PLATE_UNIT_ADDED and not driver.events.UNIT_AURA
    and not driver.events.UNIT_POWER_FREQUENT, "obsolete observer subscriptions remain")
local savedTarget = tokens.target
tokens.target = nil
Event("PLAYER_TARGET_CHANGED")
local readsBefore = spellReads
local countdownBefore = betaCooldownIcon.label.text
Tick(1)
assert(betaCooldownIcon:IsShown() and betaCooldownIcon.label.text ~= countdownBefore,
    "targetless out-of-combat countdown froze")
assert(spellReads == readsBefore, "animation polled spell API")
Capture("Forever no target", frames, false)
ClickMinimap("LeftButton")
Tick(0.1)
assert(betaPicker:IsShown(), "picker failed without target")
local preview
for _, item in ipairs(frames) do
    if item.text == "Preview" and item.parent.parent == betaPicker then preview = item.parent end
end
assert(preview and preview:IsShown(), "isolated preview missing")
local watched = #ApogeeTankCooldownsDB.watched
local samplesBefore = sampleCount
readsBefore = spellReads
Tick(0.2)
assert(#ApogeeTankCooldownsDB.watched == watched and spellReads == readsBefore
    and sampleCount == samplesBefore, "preview observed or learned gameplay data")
for _, item in ipairs(frames) do
    local parent = item.parent
    while parent do
        if parent == preview then
            assert(item.template ~= "SecureActionButtonTemplate" and not item.scripts.OnClick,
                "preview created interactive marking surface")
        end
        parent = parent.parent
    end
end
betaPicker.scripts.OnDragStart()
assert(betaPicker.moving, "picker no longer draggable")
combat = true
Event("PLAYER_REGEN_DISABLED")
assert(not betaPicker.moving and not preview:IsShown(), "combat left preview/drag active")
combat = false
Event("PLAYER_REGEN_ENABLED")
Tick(0.1)
assert(not betaPicker:IsShown(), "combat exit reopened picker")
local paints = 0
local previewUpdate = preview.scripts.OnUpdate
preview.scripts.OnUpdate = function(...) paints = paints + 1; previewUpdate(...) end
Tick(0.2)
assert(paints == 0, "closed preview kept ticking")
tokens.target = savedTarget
Event("PLAYER_TARGET_CHANGED")
assert(stableAnchor.points[1] == anchorPoint, "target changes or overflow moved strip")
print("Forever class slots, six-icon overflow, targetless countdown and preview isolation passed")

-- Reloading under lockdown must defer all protected setup until combat ends.
frames, named, driver = {}, {}, nil
lockdown, combat = true, true
addon = LoadAddon()
Event("PLAYER_LOGIN")
Tick(0.1)
assert(not named.ApogeeTankTargetMarkerButton, "protected button created in lockdown")
lockdown, combat = false, false
Event("PLAYER_REGEN_ENABLED")
assert(named.ApogeeTankTargetMarkerButton, "deferred secure marking setup did not recover")
print("Secure marker attributes, target guard, layout and deferred setup passed")

-- Paladin picker: both lists share guards, but only cooldowns have Clear.
frames, named, driver = {}, {}, nil
classToken = "PALADIN"
ApogeeTankSealsDB, ApogeeTankCooldownsDB = nil, nil
local sealBook = {
    {spellID = 21084, name = "Seal of Righteousness", iconID = 21084},
    {spellID = 21082, name = "Seal of the Crusader", iconID = 21082},
}
Enum = {SpellBookSpellBank = {Player = 0}}
C_Spell.GetSpellInfo = function(id)
    for _, seal in ipairs(sealBook) do
        if seal.spellID == id then return {name = seal.name, iconID = seal.iconID} end
    end
    return {name = "Spell" .. id, iconID = id}
end
C_SpellBook = {
    GetNumSpellBookSkillLines = function() assert(not InCombatLockdown()); return 1 end,
    GetSpellBookSkillLineInfo = function() return {itemIndexOffset = 0, numSpellBookItems = #sealBook} end,
    GetSpellBookItemInfo = function(slot) return sealBook[slot] end,
    IsSpellKnown = function(id) return id == 21084 or id == 21082 or id == 679 or id == 853 or id == 20271 end,
}
addon = LoadAddon()
Event("PLAYER_LOGIN"); Tick(0.1)
ClickMinimap("LeftButton"); Tick(0.1)
local paladinPicker = named.ApogeeTankPickerWindow
assert(paladinPicker.width == 662 and paladinPicker:IsShown())
assert(named.ApogeeTankCooldownsClear and not named.ApogeeTankSealsClear)
local sealChoice, paladinPreview
for _, item in ipairs(frames) do
    if item.kind == "CheckButton" and item.icon.texture == 21084 then sealChoice = item end
    if item.text == "Preview" and item.parent.parent == paladinPicker then paladinPreview = item.parent end
end
assert(sealChoice and sealChoice:GetChecked())
assert(ApogeeTankSealsDB.hidden[21082] == true and not named.ApogeeTankSealAction2,
    "fresh Crusader default created a HUD action")
local crusaderChoice
for _, item in ipairs(frames) do
    if item.kind == "CheckButton" and item.icon.texture == 21082 then crusaderChoice = item end
end
assert(crusaderChoice and not crusaderChoice:GetChecked(), "Crusader opt-in checkbox is unavailable")
crusaderChoice:SetChecked(true); crusaderChoice.scripts.OnClick(crusaderChoice)
assert(ApogeeTankSealsDB.hidden[21082] == false and named.ApogeeTankSealAction2,
    "explicit Crusader opt-in did not save or show its secure action")
sealChoice:SetChecked(false); sealChoice.scripts.OnClick(sealChoice)
assert(ApogeeTankSealsDB.hidden[21084] and #ApogeeTankCooldownsDB.watched == 3)
assert(named.ApogeeTankSealAction1.attributeDrivers.spell == "21082"
    and named.ApogeeTankSealAction2.stateDriver[2] == "hide")
assert(not sealChoice:GetChecked(), "seal checklist lost unchecked row")
for _, item in ipairs(frames) do
    if item.image and item.image.texture == 21084 then
        local parent = item.parent
        while parent and parent ~= paladinPreview do parent = parent.parent end
        assert(not parent or not item:IsShown(), "preview showed an unchecked seal")
    end
end
Capture("Paladin spell picker", frames, true)
named.ApogeeTankCooldownsClear.scripts.OnClick()
named.ApogeeTankCooldownsConfirmClear.scripts.OnClick()
assert(ApogeeTankSealsDB.hidden[21084], "cooldown clear reset seal visibility")
combat = true; Event("PLAYER_REGEN_DISABLED")
assert(not paladinPicker:IsShown() and not paladinPreview:IsShown())
sealChoice:SetChecked(true); sealChoice.scripts.OnClick(sealChoice)
assert(ApogeeTankSealsDB.hidden[21084] and not sealChoice:GetChecked())
combat = false; Event("PLAYER_REGEN_ENABLED"); Tick(0.1)
ClickMinimap("LeftButton"); Tick(0.1)
Event("PLAYER_LEAVING_WORLD")
assert(not paladinPicker:IsShown())
sealChoice:SetChecked(true); sealChoice.scripts.OnClick(sealChoice)
assert(ApogeeTankSealsDB.hidden[21084])
Event("PLAYER_ENTERING_WORLD"); Tick(0.1)
ClickMinimap("LeftButton"); Tick(0.1)
sealChoice:SetChecked(true); sealChoice.scripts.OnClick(sealChoice)
assert(not ApogeeTankSealsDB.hidden[21084]
    and named.ApogeeTankSealAction1.attributeDrivers.spell == "21084")
local holyChoice, judgementChoice
for _, item in ipairs(frames) do
    if item.kind == "CheckButton" then
        if item.icon.texture == 679 then holyChoice = item end
        if item.icon.texture == 20271 then judgementChoice = item end
    end
end
assert(holyChoice and judgementChoice and holyChoice:GetChecked() and judgementChoice:GetChecked())
judgementChoice:SetChecked(true); judgementChoice.scripts.OnClick(judgementChoice)
-- Rows can move when a cooldown is selected; find Holy Strike again.
for _, item in ipairs(frames) do
    if item.kind == "CheckButton" and item.icon.texture == 679 then holyChoice = item end
end
holyChoice:SetChecked(true); holyChoice.scripts.OnClick(holyChoice)
assert(ApogeeTankCooldownsDB.watched[1].spellId == 679 and ApogeeTankCooldownsDB.watched[1].explicit
    and ApogeeTankCooldownsDB.watched[2].spellId == 20271 and ApogeeTankCooldownsDB.watched[2].explicit
    and ApogeeTankCooldownsDB.watched[3].spellId == 853, "explicit opt-ins failed to retain default order")
print("Paladin seal checklist, preview visibility, independent cooldown clear and combat/zoning guards passed")
