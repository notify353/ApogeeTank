function CreateFrame() end; function issecretvalue() return false end; function canaccessvalue() return true end
-- Taken from the reviewed native ProjectConstants, not the old project-1 mock.
WOW_PROJECT_CAMELOT=18; WOW_PROJECT_ID=18
local version,build,interface="1.60.1","70170",16001
GetBuildInfo=function() return version,build,"",interface end
local A={}; local function loadClient() assert(loadfile("Core/Client.lua"))("ApogeeTank",A); return A.Client end; loadClient()
assert(A.Client=="foreverBeta")
for _,case in ipairs({{"1.60.0","69894",16000},{"1.60.2","99999",16002},{"1.61.0","100001",16100}}) do
 version,build,interface=unpack(case)
 assert(loadClient(), "Native Forever revision must not disable features")
end
WOW_PROJECT_ID=1; version="1.60.2"; interface=16002
assert(loadClient(), "Legacy Forever must tolerate interface revisions")
WOW_PROJECT_ID=2; version="1.15.9"; interface=11509
assert(not (loadClient()), "Other client family must remain unsupported")
WOW_PROJECT_CAMELOT=nil; WOW_PROJECT_ID=nil; version=nil
assert(not (loadClient()), "Missing identity must not match an absent constant")
print("PASS native Forever identity, older/future revisions and legacy fallback")
