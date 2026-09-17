local _, addon = ...
local Style = addon.Style

function addon.StartStance(getAnchor)
    local driver = CreateFrame("Frame")
    local icon
    driver:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_LEAVING_WORLD" then
            if icon then icon:Hide() end
            return
        end
        local anchor = getAnchor()
        if not anchor then return end
        local texture = addon.GetActiveStanceIcon()
        if not icon and texture then
            icon = CreateFrame("Frame", nil, anchor)
            icon:SetSize(Style.iconSize, Style.iconSize)
            icon:SetPoint("RIGHT", anchor, "LEFT", -1, 0)
            icon:EnableMouse(false)
            icon.image = Style.Icon(icon)
        end
        if icon then
            icon.image:SetTexture(texture)
            icon:SetShown(texture ~= nil)
        end
    end)
    for _, event in ipairs({ "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "PLAYER_LEAVING_WORLD",
        "UPDATE_SHAPESHIFT_FORM", "UPDATE_SHAPESHIFT_FORMS" }) do
        driver:RegisterEvent(event)
    end
end
