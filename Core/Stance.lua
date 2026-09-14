local _, addon = ...
function addon.GetActiveStanceIcon()
    if not GetNumShapeshiftForms or not GetShapeshiftFormInfo then return nil end
    for index = 1, GetNumShapeshiftForms() do
        local icon, active = GetShapeshiftFormInfo(index)
        if active then return icon end
    end
end
