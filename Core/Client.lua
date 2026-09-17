local _, addon = ...
local version, build, _, interface = GetBuildInfo()
if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC and tonumber(interface) == 11509 then
    addon.Client = "classicEra"
elseif WOW_PROJECT_ID == 1 and version == "1.60.1" and tostring(build) == "69893"
    and tonumber(interface) == 16001 and type(issecretvalue) == "function"
    and type(canaccessvalue) == "function" then
    addon.Client = "foreverBeta"
end
