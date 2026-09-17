local _, addon = ...
local Access = addon.Access
local GetNumShapeshiftForms = Access.Global("GetNumShapeshiftForms")
local GetShapeshiftFormInfo = Access.Global("GetShapeshiftFormInfo")
function addon.GetActiveStanceIcon()
    if not GetNumShapeshiftForms or not GetShapeshiftFormInfo then return nil end
    for index = 1, (GetNumShapeshiftForms() or 0) do
        local icon, active = GetShapeshiftFormInfo(index)
        if active then return icon end
    end
end
