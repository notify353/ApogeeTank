local addon, combat, buttons = {}, true, {}
addon.CooldownAPI = { TargetMacro = function(id)
    if id == 679 then return "[harm,nodead] /cast Holy Strike; /targetenemy\n/cast Holy Strike" end
end }
local hostile = false
local drivers = {}
function RegisterAttributeDriver(button, key, text)
    assert(not combat)
    if key == "macrotext" then drivers[button] = { key = key, text = text } end
    local keep, acquire = text:match("^%[harm,nodead%] (.-); (.+)$")
    local value = keep and (hostile and keep or acquire) or text
    if value == "nil" then value = nil else value = tonumber(value) or value end
    button:SetAttribute(key, value)
end
function UnregisterAttributeDriver(button, key) assert(not combat); if key == "macrotext" then drivers[button] = nil end end
UIParent = {}
InCombatLockdown = function() return combat end
function CreateFrame(kind, name, parent, template)
    assert(not combat and parent == UIParent and template == "SecureActionButtonTemplate")
    local button = { attributes = {} }
    function button:SetScale(value) self.scale = value end
    function button:SetSize(w, h) self.width, self.height = w, h end
    function button:SetPoint(...) self.point = {...} end
    function button:SetFrameStrata() end
    function button:SetFrameLevel() end
    function button:RegisterForClicks(value) self.clicks = value end
    function button:SetScript() end
    function button:SetAttribute(key, value) assert(not combat); self.attributes[key] = value end
    buttons[#buttons + 1] = button
    return button
end
function RegisterStateDriver(button, _, value) assert(not combat); button.visibility = value end
assert(loadfile("Cooldowns/Actions.lua"))("test", addon)
local update = addon.CreateCooldownActions(function(index)
    return { size = 22, scale = 2, x = 70.5 + (index - 1) * 24, y = 26.5 }
end, function() end, function() end)
update({ { spellId = 679 } })
assert(#buttons == 0, "combat reload created protected cooldown")
combat = false
update({ { spellId = 679 }, { spellId = 853 } })
assert(#buttons == 2 and buttons[1].attributes.type1 == "macro"
    and buttons[1].attributes.unit == nil and buttons[2].attributes.unit == "target" and buttons[2].attributes.spell == 853)
assert(buttons[2].point[4] == 94.5 and buttons[1].width == 22)
hostile = true
RegisterAttributeDriver(buttons[1], "macrotext", drivers[buttons[1]].text)
assert(buttons[1].attributes.macrotext == "/cast Holy Strike", "living hostile target was cycled")
hostile = false
RegisterAttributeDriver(buttons[1], "macrotext", drivers[buttons[1]].text)
combat = true
update({ { spellId = 20271 } })
assert(buttons[1].attributes.spell == 679 and buttons[2].attributes.spell == 853)
local export = os.getenv("APOGEE_FOREVER_EXPORT")
if export and export ~= "" then
    local file = assert(io.open(export .. "/Blizzard_FrameXML/SecureTemplates.lua", "r"))
    local source = file:read("*a"); file:close()
    local convertSource = assert(source:match("local function GetConvertedButtonUnitAndActionType(.-)\nend"))
    local convertChunk = assert(loadstring("return function" .. convertSource .. "\nend"))
    local exists = false
    setfenv(convertChunk, {
        type = type, PRESS_TYPE_DOWN = 1, PRESS_TYPE_UP = 2, PRESS_TYPE_HOLD_RELEASE = 3,
        SecureButton_GetModifiedUnit = function(frame) return frame.attributes.unit end,
        SecureButton_GetModifiedAttribute = function(frame, key) return frame.attributes[key .. "1"] or frame.attributes[key] end,
        UnitExists = function() return exists end,
        UnitCanAttack = function() return exists end,
        UnitCanAssist = function() return false end,
    })
    local convert = convertChunk()
    -- Reproduce the actual native early return from the previous build.
    buttons[1].attributes.unit = "target"
    assert(convert(buttons[1], "LeftButton", 2) == nil, "native no-target guard not exercised")
    buttons[1].attributes.unit = nil
    local mouse, unit, kind = convert(buttons[1], "LeftButton", 2)
    assert(mouse == "LeftButton" and unit == nil and kind == "macro", "acquisition macro blocked by missing target")
    exists = true
    assert(convert(buttons[1], "LeftButton", 2) == "LeftButton", "existing target blocked macro")
    local driverFile = assert(io.open(export .. "/Blizzard_RestrictedAddOnEnvironment/SecureStateDriver.lua", "r"))
    local driverSource = driverFile:read("*a"); driverFile:close()
    local resolveSource = assert(driverSource:match("local function resolveDriver(.-)\nend"))
    local resolver = assert(loadstring("return function" .. resolveSource .. "\nend"))
    local selected
    setfenv(resolver, { tonumber = tonumber, SecureCmdOptionParse = function() return selected end })
    buttons[1].GetAttribute = function(self, key) return self.attributes[key] end
    -- Native resolver applies both complete payloads; conditional parsing remains simulated.
    combat = false
    selected = "/cast Holy Strike"
    resolver()(buttons[1], "macrotext", drivers[buttons[1]].text)
    assert(buttons[1].attributes.macrotext == selected)
    selected = "/targetenemy\n/cast Holy Strike"
    resolver()(buttons[1], "macrotext", drivers[buttons[1]].text)
    assert(buttons[1].attributes.macrotext == selected)
    combat = true
    local clickSource = assert(source:match("function SecureActionButton_OnClick(.-)\nend"))
    local clickChunk = assert(loadstring("return function" .. clickSource .. "\nend"))
    local clicked = 0
    setfenv(clickChunk, {
        SecureButton_GetAttribute = function(frame, key) return frame.attributes[key] end,
        SecureActionButton_ShouldUseOnKeyDown = function(frame) return frame.attributes.useOnKeyDown end,
        GetCVarBool = function() return false end,
        OnActionButtonClick = function() clicked = clicked + 1 end,
    })
    local click = clickChunk()
    for _, secureMouse in ipairs({ false, true }) do
        local before = clicked
        click(buttons[1], "LeftButton", true, false, secureMouse)
        assert(clicked == before, "mouse down fired a mouse-up action")
        click(buttons[1], "LeftButton", false, false, secureMouse)
        assert(clicked == before + 1, "native mouse release did not dispatch")
    end
    local action = assert(source:match("SECURE_ACTIONS.macro =%s*(function%s*%(self, unit, button%).-\n%s*end);"))
    local chunk = assert(loadstring("return " .. action))
    local cast
    setfenv(chunk, { tonumber = tonumber,
        SecureButton_GetModifiedAttribute = function(self, key) return self.attributes[key] end,
        C_Macro = { RunMacroText = function(text, mouse) cast = { text, mouse } end } })
    chunk()(buttons[1], "target", "LeftButton")
    assert(cast[1] == "/targetenemy\n/cast Holy Strike" and cast[2] == "LeftButton")
end
combat = false
update({ { spellId = 20271 } })
assert(buttons[1].attributes.spell == 20271 and buttons[2].visibility == "hide"
    and buttons[2].attributes.spell == nil)
assert(buttons[1].attributes["shift-type1"] == ""
    and buttons[1].clicks == "LeftButtonUp" and buttons[1].attributes.useOnKeyDown == false)
assert(buttons[1].attributes.type1 == "spell" and buttons[1].attributes.macrotext == nil, "stale targeting macro")
print("Native cooldown spell casting, fixed combat assignments and deferred creation passed")
