local _, addon = ...
local version, build, _, interface = GetBuildInfo()
addon.Client = nil
if type(CreateFrame) ~= "function" then return end
if WOW_PROJECT_ID == 2 and type(version)=="string" and version:match("^1%.15%.")
    and tonumber(interface) == 11509 then
    addon.Client = "classicEra"
elseif WOW_PROJECT_ID == 1 and type(version)=="string" and version:match("^1%.60%.")
    and tonumber(interface) == 16001 and type(issecretvalue) == "function"
    and type(canaccessvalue) == "function" then
    addon.Client = "foreverBeta"
end
local reviewed = addon.Client == "classicEra" and "69722" or "69913"
if addon.Client and tostring(build) ~= reviewed and not addon.compatibilityWarned then
    addon.compatibilityWarned = true
    print("Apogee Tank: this client build is unverified; continuing with capability checks. Report errors after updates.")
end
