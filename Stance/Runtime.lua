local _, addon = ...

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
            icon = anchor:CreateTexture(nil, "ARTWORK")
            icon:SetSize(18, 18)
            icon:SetPoint("RIGHT", anchor, "LEFT", -6, 0)
            icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        end
        if icon then
            icon:SetTexture(texture)
            icon:SetShown(texture ~= nil)
        end
    end)
    for _, event in ipairs({ "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "PLAYER_LEAVING_WORLD",
        "UPDATE_SHAPESHIFT_FORM", "UPDATE_SHAPESHIFT_FORMS" }) do
        driver:RegisterEvent(event)
    end
end
