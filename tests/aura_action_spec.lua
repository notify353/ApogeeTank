local addon, combat, button = {}, true, nil
UIParent = {}
InCombatLockdown = function() return combat end
function CreateFrame(kind, name, parent, template)
    assert(not combat and kind == "Button" and parent == UIParent and template == "SecureActionButtonTemplate")
    button = { attributes = {} }
    function button:SetScale() end
    function button:SetSize() end
    function button:SetPoint(...) self.point = {...} end
    function button:SetFrameStrata() end
    function button:SetFrameLevel() end
    function button:RegisterForClicks(value) self.clicks = value end
    function button:SetScript() end
    function button:SetAttribute(key, value) assert(not combat); self.attributes[key] = value end
    return button
end
function RegisterStateDriver(frame, _, condition) assert(not combat); frame.condition = condition end
assert(loadfile("Stance/Action.lua"))("test", addon)
local update = addon.CreateAuraAction(function() return { scale = 2, size = 22, x = 57.5, y = -8.5 } end)
update(465, "Devotion Aura")
assert(not button, "combat reload created protected action")
combat = false
update(465, "Devotion Aura")
assert(button.attributes.type1 == "macro" and button.attributes.macrotext1 == "/cast !Devotion Aura" and button.attributes.unit == "player")
assert(button.condition == "[dead] hide; show" and button.clicks == "LeftButtonDown")
assert(button.attributes["shift-type1"] == "" and button.attributes["alt-ctrl-shift-type1"] == "")
combat = true
update(nil)
assert(button.attributes.macrotext1 == "/cast !Devotion Aura" and button.condition == "[dead] hide; show", "combat disabled configured spell action")
combat = false
update(nil)
assert(button.condition == "hide" and button.attributes.type1 == "" and not button.attributes.macrotext1)
local export = os.getenv("APOGEE_FOREVER_EXPORT")
if export and export ~= "" then
    local file = assert(io.open(export .. "/Blizzard_FrameXML/SecureTemplates.lua", "r"))
    local source = file:read("*a"); file:close()
    local action = assert(source:match("SECURE_ACTIONS.macro =%s*(function%s*%(self, unit, button%).-\n%s*end);"))
    local chunk = assert(loadstring("return " .. action))
    local cast
    setfenv(chunk, { tonumber = tonumber,
        SecureButton_GetModifiedAttribute = function(self, key) return self.attributes[key .. "1"] end,
        C_Macro = { RunMacroText = function(text, mouse) cast = {text, mouse} end } })
    update(465, "Devotion Aura")
    chunk()(button, "player", "LeftButton")
    assert(cast[1] == "/cast !Devotion Aura" and cast[2] == "LeftButton")
end
print("Native Forever aura spell action, combat deferral and inactive-action clearing passed")
