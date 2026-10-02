-- ====================================================================
-- 👑 AXER CHAT : THE APEX TITAN EDITION (FINAL MASTER-CORE V30.3)
-- DEV : VENUS_EDIT
-- 🔥 100% FIREBASE — NO PROXY
-- 🆕 V30.3 : Search bar only in DM Inbox tab (not in main server tab)
-- ====================================================================

if getgenv().AxerChat_Loaded then
	getgenv().AxerChat_Unloading = true
	task.wait(0.3)
	pcall(function()
		local cgui = pcall(function() return game:GetService("CoreGui") end) and game:GetService("CoreGui") or game.Players.LocalPlayer:WaitForChild("PlayerGui")
		for _, v in pairs(cgui:GetChildren()) do if v.Name:match("^AxerUI_") then v:Destroy() end end
	end)
end
getgenv().AxerChat_Loaded = true; getgenv().AxerChat_Unloading = false

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserService = pcall(function() return game:GetService("UserService") end) and game:GetService("UserService") or nil
local LocalPlayer = Players.LocalPlayer

local CoreGui = pcall(function() return game:GetService("CoreGui") end) and game:GetService("CoreGui") or nil

local httprequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or (getgenv().request) or request
if not httprequest then warn("AXER CHAT: HTTP Request pipeline missing!") return end

-- ====================================================================
--  🔥 FIREBASE
-- ====================================================================
local FIREBASE_URL = "https://axer-chat-v2-default-rtdb.asia-southeast1.firebasedatabase.app/"
local FIREBASE_SERVER_PATH = "servers/" .. game.JobId .. "/chat.json"

local function makeHttpRequest(options)
    local req = (syn and syn.request) or http_request or request or (http and http.request)
    if req then
        local success, response = pcall(req, options)
        if success then return response end
    end
    return nil
end

local function FB_GET(path)
    local buster = tostring(os.clock()):gsub("%.","") .. "_" .. math.random(1000,9999)
    local res = makeHttpRequest({ Url = FIREBASE_URL .. path .. ".json?bust=" .. buster, Method = "GET", Headers = { ["Cache-Control"] = "no-cache" } })
    if res and (res.StatusCode == 200 or res.StatusCode == 304) and res.Body and res.Body ~= "null" then
        local ok, dec = pcall(function() return HttpService:JSONDecode(res.Body) end)
        return (ok and typeof(dec) == "table") and dec or nil
    end
    return nil
end

local function FB_PUT(path, body, isRaw)
    local payload = isRaw and body or HttpService:JSONEncode(body)
    task.spawn(function()
        makeHttpRequest({ Url = FIREBASE_URL .. path .. ".json", Method = "PUT", Headers = { ["Content-Type"] = "application/json" }, Body = payload })
    end)
end

local function FB_PUT_SYNC(path, body, isRaw)
    local payload = isRaw and body or HttpService:JSONEncode(body)
    return makeHttpRequest({ Url = FIREBASE_URL .. path .. ".json", Method = "PUT", Headers = { ["Content-Type"] = "application/json" }, Body = payload })
end

local function FB_POST(path, body, isRaw)
    local payload = isRaw and body or HttpService:JSONEncode(body)
    task.spawn(function()
        makeHttpRequest({ Url = FIREBASE_URL .. path .. ".json", Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = payload })
    end)
end

local function FB_DELETE(path)
    task.spawn(function()
        makeHttpRequest({ Url = FIREBASE_URL .. path .. ".json", Method = "DELETE" })
    end)
end

local function FB_GET_RAW(path)
    local buster = tostring(os.clock()):gsub("%.","") .. "_" .. math.random(1000,9999)
    local res = makeHttpRequest({ Url = FIREBASE_URL .. path .. ".json?bust=" .. buster, Method = "GET", Headers = { ["Cache-Control"] = "no-cache" } })
    if res and res.StatusCode == 200 then return res.Body end
    return nil
end

local function BroadcastToFirebase(sender, text, isImg, imgUrl, isJoin, isAdminJoin)
    task.spawn(function()
        local data = {
            sender = sender, displayName = LocalPlayer.DisplayName, text = text,
            isImg = isImg or false, imgUrl = imgUrl or "",
            isJoin = isJoin or false, isAdminJoin = isAdminJoin or false,
            isSystem = isAdminJoin or false, timestamp = os.time()
        }
        local success, json = pcall(function() return HttpService:JSONEncode(data) end)
        if success then
            makeHttpRequest({ Url = FIREBASE_URL .. FIREBASE_SERVER_PATH, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = json })
        end
    end)
end

local function BroadcastAdminJoin()
    local flagFile = "AxerAdminJoin_" .. game.JobId .. ".txt"
    if isfile and isfile(flagFile) then return end
    task.spawn(function()
        local joinMessage = "👑 Axer Chat's Creator has entered the server!\nSIR AXER HAS ENTERED!"
        local data = { sender = "ARIA", displayName = "ARIA", text = joinMessage, isImg = false, isSystem = true, isAdminJoin = true, isJoin = false, imgUrl = "", timestamp = os.time() }
        local success, json = pcall(function() return HttpService:JSONEncode(data) end)
        if success then
            makeHttpRequest({ Url = FIREBASE_URL .. FIREBASE_SERVER_PATH, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = json })
            if writefile then pcall(function() writefile(flagFile, "1") end) end
        end
    end)
end

local function BroadcastNormalJoin()
    if IsStrictAdmin() then return end
    task.spawn(function()
        local joinMessage = LocalPlayer.DisplayName .. " has joined the server."
        BroadcastToFirebase(LocalPlayer.Name, joinMessage, false, nil, true, false)
    end)
end

-- ====================================================================

local function GenerateRandomUIName() local s="AxerUI_"; for _=1,12 do s=s..string.char(math.random(65,90)) end return s end
local c_wrap = (typeof(newcclosure) == "function" and newcclosure) or function(f) return f end

local function GetBulletproofHWID()
	local h = ""
	pcall(function() h = gethwid() end)
	if not h or h == "" then pcall(function() h = getgenv().gethwid() end) end
	if not h or h == "" then pcall(function() h = game:GetService("RbxAnalyticsService"):GetClientId() end) end
	if not h or h == "" then h = "FALLBACK_ID_" .. tostring(LocalPlayer.UserId) end
	return tostring(h):gsub("[^%w_]", "")
end
local MY_HWID = GetBulletproofHWID()
local EXECUTOR_NAME = (identifyexecutor and identifyexecutor()) or "Unknown_Universal_Exec"

local getSalt = c_wrap(function() return "5A40796E5F4D40737465725F4B33795F39393831325F47686F73745F50726F746F636F6C5F585F53757072656D655F56313831" end)
local getSrvPfx = c_wrap(function() return "AxerSrvSec_Key_" end)
local rawJob = (game.JobId ~= "") and game.JobId or "OFFLINE_STUDIO_TEST_99"
local REAL_JOB_ID = rawJob:gsub("[^%w_]", "")

local function PunishBannedUser()
	task.spawn(function()
		pcall(function()
			local cg = pcall(function() return game:GetService("CoreGui") end) and game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")
			for _,v in pairs(cg:GetChildren()) do if v.Name:find("Axer") then v:Destroy() end end
		end)
	end)
	LocalPlayer:Kick("\n⛔ APEX TITAN BAN ENGINE ⛔\nAccount or Device Fingerprint permanently blacklisted by VENUS_EDIT.")
	task.wait(0.5)
	task.spawn(function() while true do end end)
	while true do task.wait(9e9) end
end

local function ExecuteAbsoluteBanCheck()
	local usrLower = LocalPlayer.Name:lower()
	local isLocallyBanned = false
	if pcall(isfile, "AxerTitan_Ban_Signature.sys") and isfile("AxerTitan_Ban_Signature.sys") then isLocallyBanned = true end
	local b1 = FB_GET_RAW("Blacklist/Accounts/" .. usrLower)
	local b2 = FB_GET_RAW("Blacklist/HWIDs/" .. MY_HWID)
	local isCloudBanned = false
	if (b1 and string.find(b1, "true")) or (b2 and string.find(b2, "true")) then isCloudBanned = true end
	if isCloudBanned then
		task.spawn(function()
			pcall(function() if writefile then writefile("AxerTitan_Ban_Signature.sys", "PERMA_BANNED_BY_VENUS_EDIT") end end)
			FB_PUT_SYNC("Blacklist/HWIDs/" .. MY_HWID, "true", true)
			FB_PUT_SYNC("Blacklist/Accounts/" .. usrLower, MY_HWID, true)
		end)
		PunishBannedUser()
	elseif isLocallyBanned and not isCloudBanned then
		pcall(function() if delfile then delfile("AxerTitan_Ban_Signature.sys") end end)
	end
end
ExecuteAbsoluteBanCheck()

local function PerformStrictIdentityCheck()
	local realName = LocalPlayer.Name
	local realDisplayName = LocalPlayer.DisplayName
	pcall(function()
		local success, nameResult = pcall(function() return Players:GetNameFromUserIdAsync(LocalPlayer.UserId) end)
		if success and nameResult then realName = nameResult end
		if UserService then
			local s2, info = pcall(function() return UserService:GetUserInfosByUserIdsAsync({LocalPlayer.UserId})[1] end)
			if s2 and info then
				if info.Username then realName = info.Username end
				if info.DisplayName then realDisplayName = info.DisplayName end
			end
		end
	end)
	local function checkForbidden(str)
		if not str then return false end
		local normalized = str:lower():gsub("0", "o"):gsub("1", "i")
		return string.find(normalized, "forbid") ~= nil
	end
	if checkForbidden(realName) or checkForbidden(realDisplayName) then
		task.spawn(function()
			pcall(function() if writefile then writefile("AxerTitan_Ban_Signature.sys", "PERMA_BANNED_FORBID_CLAN") end end)
			FB_PUT_SYNC("Blacklist/HWIDs/" .. MY_HWID, "true", true)
			FB_PUT_SYNC("Blacklist/Accounts/" .. realName:lower(), MY_HWID, true)
		end)
		PunishBannedUser()
	end
end
PerformStrictIdentityCheck()

local AXER_HARDCODED_BANLIST = { UserIds = { ["baduser123"] = true }, HWIDs = { ["ADD_HWID_HERE"] = true } }
if AXER_HARDCODED_BANLIST.UserIds[LocalPlayer.Name:lower()] or AXER_HARDCODED_BANLIST.HWIDs[MY_HWID] then LocalPlayer:Kick("\n⛔ PERMANENT BAN ⛔\nMachine strictly blacklisted."); task.spawn(function() while true do end end); while true do task.wait(9e9) end end

local function TitanGuardKick(code, reason)
	if getgenv().AxerChat_Unloading then return end
	local severe_codes = { ["SPY-01"]=true, ["TRP-M01"]=true, ["TRP-W02"]=true, ["META-HOOK"]=true, ["VIP-SPOOF"]=true, ["GOD-BREACH"]=true }
	if severe_codes[code] then
		task.spawn(function()
			FB_PUT_SYNC("Blacklist/HWIDs/" .. MY_HWID, "true", true)
			FB_PUT_SYNC("Blacklist/Accounts/" .. LocalPlayer.Name:lower(), MY_HWID, true)
			pcall(function() if writefile then writefile("AxerTitan_Ban_Signature.sys", "PERMA_BANNED_BY_TITANGUARD") end end)
		end)
	end
	task.spawn(function()
		pcall(function()
			local logData = { PlayerName = LocalPlayer.Name, PlayerID = LocalPlayer.UserId, HWID = MY_HWID, Executor = EXECUTOR_NAME, ViolationCode = code, Reason = reason, ServerJobId = REAL_JOB_ID, Timestamp = os.time() }
			FB_PUT("AdminLogs/" .. LocalPlayer.Name:lower() .. "_" .. os.time(), logData)
		end)
	end)
	task.wait(0.5); LocalPlayer:Kick("\n🛡️ AXER TITANGUARD 🛡️\nIntercepted Violation: [" .. code .. "]\nSession securely closed."); task.spawn(function() while true do end end); while true do task.wait(9e9) end
end

local ADMIN_IDS = { 7169032620 }
local function IsStrictAdmin()
    local rp = LocalPlayer
    if rp.UserId == 7169032620 and string.lower(rp.Name) == "venus_edit" then return true end
    for _, id in ipairs(ADMIN_IDS) do if rp.UserId == id then return true end end
    return false
end
if LocalPlayer.UserId == 7169032620 and not IsStrictAdmin() then TitanGuardKick("VIP-SPOOF", "Identity Theft Intercepted") end

task.spawn(function() while task.wait(1.0) do if getthreadidentity and pcall(getthreadidentity) and getthreadidentity() < 7 and not getgenv().AxerChat_Unloading then TitanGuardKick("THREAD-HIJACK", "Privilege Downgrade Exploit") end end end)

local function PlayAdminJoinAudio()
    task.spawn(function()
        local audioUrl = "https://files.catbox.moe/v324qy.mp3"
        local fileName = "AxerAdminJoinAudio.mp3"
        if not isfile(fileName) then
            local succ, rawAudio = pcall(function() return httprequest({Url = audioUrl, Method = "GET"}).Body end)
            if succ and rawAudio and rawAudio ~= "" then pcall(function() writefile(fileName, rawAudio) end) end
        end
        pcall(function()
            local customAsset = getcustomasset(fileName)
            if customAsset then
                local sound = Instance.new("Sound")
                sound.SoundId = customAsset
                sound.Parent = CoreGui or game:GetService("CoreGui")
                sound.Volume = 3
                sound:Play()
                sound.Ended:Connect(function() sound:Destroy() end)
            end
        end)
    end)
end

task.spawn(function()
	if game.PlaceId ~= 4924922222 then return end
	local rs = game:GetService("ReplicatedStorage"); local RE = rs:FindFirstChild("RE") or rs
	task.spawn(function() while task.wait(0.06) do if getgenv().AxerChat_Unloading then break end local smoothHue = (os.clock() * 0.12) % 1; local premCol = Color3.fromHSV(smoothHue, 0.55, 1); pcall(function() local cr = RE:FindFirstChild("1RPNam1eColo1r"); if cr then cr:FireServer("PickingRPNameColor", premCol); cr:FireServer("PickingRPBioColor", premCol) end end) end end)
	local function FulfillRP() local ntr = RE:FindFirstChild("1RPNam1eTex1t"); if ntr then pcall(function() ntr:FireServer("RolePlayName", "ᴀxᴇʀ ♥ ᴄʜᴀᴛ"); ntr:FireServer("RolePlayBio", 'Welcome Dear "' .. LocalPlayer.DisplayName .. '"') end) end end
	FulfillRP(); LocalPlayer.CharacterAdded:Connect(function() task.wait(1.5); FulfillRP() end)
end)

local function AttachUniversalOverhead(char)
	if game.PlaceId == 4924922222 then return end
	local head = char:WaitForChild("Head", 5); if not head or head:FindFirstChild("AxerUniversalOverhead") then return end
	local b = Instance.new("BillboardGui", head); b.Name = "AxerUniversalOverhead"; b.Size = UDim2.new(0,220,0,45); b.StudsOffset = Vector3.new(0,3.2,0); b.AlwaysOnTop = true
	local title = Instance.new("TextLabel", b); title.Size = UDim2.new(1,0,0.55,0); title.BackgroundTransparency = 1; title.Text = "ᴀxᴇʀ ♥ ᴄʜᴀᴛ"; title.Font = Enum.Font.GothamBold; title.TextSize = 14; title.TextStrokeTransparency = 0
	local bio = Instance.new("TextLabel", b); bio.Size = UDim2.new(1,0,0.45,0); bio.Position = UDim2.new(0,0,0.55,0); bio.BackgroundTransparency = 1; bio.Text = 'Welcome dear "' .. LocalPlayer.DisplayName .. '"!'; bio.Font = Enum.Font.GothamMedium; bio.TextSize = 11; bio.TextColor3 = Color3.fromRGB(230,230,235)
	task.spawn(function() while b and b.Parent do if getgenv().AxerChat_Unloading then break end title.TextColor3 = Color3.fromHSV((os.clock() * 0.25) % 1, 0.85, 1); task.wait() end end)
end
if LocalPlayer.Character then AttachUniversalOverhead(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(AttachUniversalOverhead)

if not getgenv().Axer_Honeypots_Active then
	local fakeMetatable = { __index = function() return "AXER_TITANGUARD_SECURE_NODE" end, __newindex = function() if checkcaller and checkcaller() and not getgenv().AxerChat_Unloading then TitanGuardKick("TRP-W02", "Honeypot Write") end end }
	local FakeDB = setmetatable({}, fakeMetatable)
	pcall(function() _G.FIREBASE_ROOT = FakeDB; shared.FirebasePipeline = FakeDB end)
	local SecureRegistryProxy = setmetatable({}, { __index = function() return "DENIED" end, __newindex = function() if not getgenv().AxerChat_Unloading then TitanGuardKick("TRP-M01", "Memory Injection") end end, __metatable = "LOCKED" })
	pcall(function() shared.AxerTitanVault = SecureRegistryProxy end)
	getgenv().Axer_Honeypots_Active = true
end

local function VerifyMetatableIntegrity()
	if getgenv().AxerChat_Unloading then return end
	local getrm = getrawmetatable or function() return nil end
	local isro = isreadonly or function() return true end
	for _, service in ipairs({HttpService, Players, ReplicatedStorage}) do
		local mt = getrm(service); if mt and (typeof(mt) ~= "table" or not isro(mt)) then TitanGuardKick("META-HOOK", "Service Compromised") end
	end
	if ishooked and ishooked(httprequest) then TitanGuardKick("SPY-01", "HTTP Spy") end
end

local function GetUniverseTimestamp() local s, t = pcall(function() return workspace:GetServerTimeNow() end); return s and math.floor(t) or os.time() end
local SESSION_START_TIME = GetUniverseTimestamp(); local SERVER_RETENTION_SECONDS = 86400; local ONE_WEEK_SECONDS = 604800

local STICKER_LIST = {
    "77649364", "4575171289", "2939688117", "377662481", "8602843662",
    "84406977929953", "99638752080138", "11648237431", "5883531940",
    "9597834616", "12573542769", "13297237968", "135055229700449",
    "14164452624", "118477781128724", "83990024276263", "15404150022",
    "168290988", "15149485377", "14742201370", "13329191544",
    "12753246648", "15314865297", "13276722238", "13249175283",
    "7037371946", "13967189767", "443560505", "13116796587",
    "14493140295", "2888515085", "13231918877", "9086717675",
    "14833591986", "16360873499",
    "129040222524985", "112758420253845", "95770046851932",
    "71442089462191", "98946997706325", "87239554144904",
    "75030286063678", "136413255954959", "83671542566237",
    "124047412639555", "130819442854007", "135700976643537",
    "107679067587993", "100722574482118",
    "102243712812624", "124145396344946", "77449075537615", "86278563388796",
    "113540856419753", "115062400395026", "91965007204396", "74143981281416",
    "128965568153551", "105612301516352", "81437059666138", "96930545429149",
    "90357041968118", "106503865025496", "107949395268622", "95112780943766",
    "90286953844894", "108550928457595", "111616336841381", "72793460663497",
    "97531898393056", "86402817297314", "108283809544243", "76757365751988",
    "134676873059671", "108796531608917", "87693756574279", "107991336904158",
    "102923210652647", "85407192167743", "127600871692693", "116671713835756",
    "91554946838716", "129299999390074", "112947637609310", "9535816766",
    "113433225859507", "129716842531162", "120533300214549", "121648840999566",
    "18260819726", "16199278981", "17597703320", "13166065031",
    "120578004452417", "12729122625", "9897741285", "130121292590990",
    "14036814111", "128535076379472", "12410868506", "88936593668553",
    "100088928101922", "16450680734", "12028496352", "12028382065",
    "18974318836", "86247165299072", "16172341273", "81322691393605",
    "14107602842", "124905421403275", "104386409157529", "96811408303163",
    "94625331166483", "92064377599037", "103845863474380", "90727287236387",
    "7530801913", "14412069881", "88780855152800", "71992024065641",
    "16022747924", "139094555259200", "17894229494", "96463708021010",
    "17883713384", "18355912002", "10180536602", "11818627075",
    "9142678957", "11623459250", "2245118763", "2094272667",
    "12053823662", "5292514021", "2790989672", "3072000000",
    "11648246819", "10149736922", "1049903144", "5663084305",
    "14790980059", "10982686736", "6754961478", "6892957751",
    "14334644220", "7118722842"
}

local function hexToStr(hex) return (hex:gsub('..', function(cc) return string.char(tonumber(cc, 16) or 0) end)) end
math.randomseed(os.time() + tick())
local bxor = bit32 and bit32.bxor or function(a,b) local p,c=1,0 while a>0 or b>0 do if (a%2) ~= (b%2) then c=c+p end a,b,p=math.floor(a/2),math.floor(b/2),p*2 end return c end

local function SignData(data)
	local str = string.upper(tostring(data)) .. "||" .. hexToStr(getSalt()); local hash = 2166136261
	for i = 1, #str do hash = bxor(hash, string.byte(str, i)); hash = (hash * 16777619) % 4294967296 end
	return string.format("%08X", hash)
end

local function RC4(key, data)
	local S = {}; for i = 0, 255 do S[i] = i end; local j = 0
	for i = 0, 255 do j = (j + S[i] + string.byte(key, (i % #key) + 1)) % 256; S[i], S[j] = S[j], S[i] end
	local i, res = 0, {}; j = 0
	for k = 1, #data do i = (i + 1) % 256; j = (j + S[i]) % 256; S[i], S[j] = S[j], S[i]; table.insert(res, string.char(bxor(string.byte(data, k), S[(S[i] + S[j]) % 256]))) end
	return table.concat(res)
end
local function strToHex(str) return string.upper(str:gsub('.', function(c) return string.format('%02X', string.byte(c)) end)) end
local function GenNonce() local c = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"; local n = "" for _ = 1, 8 do local r = math.random(1, #c); n = n .. c:sub(r, r) end return n end
local function SecureEncrypt(key, text) local roomKey = key .. "_TITAN_SECURE_VAULT_V14"; local p = GenNonce() .. text; local h = strToHex(RC4(roomKey, p)); return h, SignData(h) end
local function SecureDecrypt(key, hexText, sig)
	if not hexText or not sig or SignData(hexText) ~= string.upper(tostring(sig)) then return nil end
	local s, r = pcall(hexToStr, hexText); if not s or not r then return nil end
	local d = RC4(key .. "_TITAN_SECURE_VAULT_V14", r); return (#d > 8) and d:sub(9) or nil
end
local function getDMKey(uA, uB) local s = {string.lower(uA), string.lower(uB)}; table.sort(s); return "DM_CIPHER_" .. s[1] .. "_X_" .. s[2] end

local AxerChat = {
	Mode = "Server", ActiveDM = nil, MessagesCount = 0, MaxMessages = 100,
	CurrentTheme = "Black", ReplyingTo = nil, EditingMsgID = nil, ActiveSwipeBubble = nil,
	SeenIDs = {}, Cache = { Server = {}, DMs = {} }, ActiveBubbleNodes = {},
	AccountRegistry = {}, MuteServerToasts = false, UI = {}, LastSendTime = 0,
	PendingCommitGrace = {}, VIPList = {},
	TitleRegistry = { ["venus_edit"] = "CREATOR" },
	ThrottlingFlags = { BurstCount = 0, LastWindow = os.clock() },
	IsLocked = false, ShadowMuted = {}, MutedKeywords = {},
	LastSentMessage = "", MessageTimestamps = {},
	AdminJoinAlreadyDone = false, FavoritesMode = false,
}

local adminJoinFlagFile = "AxerAdminJoin_" .. game.JobId .. ".txt"
if isfile and isfile(adminJoinFlagFile) then AxerChat.AdminJoinAlreadyDone = true end

local function ExecuteWebPush(url, payload)
	local nowWindow = os.clock()
	if nowWindow - AxerChat.ThrottlingFlags.LastWindow < 1.0 then
		AxerChat.ThrottlingFlags.BurstCount = AxerChat.ThrottlingFlags.BurstCount + 1
		if AxerChat.ThrottlingFlags.BurstCount > 10 then return end
	else AxerChat.ThrottlingFlags.BurstCount = 1; AxerChat.ThrottlingFlags.LastWindow = nowWindow end
	task.spawn(function()
		local s, _ = pcall(function() return httprequest({ Url = url, Method = "PUT", Headers = { ["Content-Type"] = "application/json" }, Body = payload }) end)
		if not s then task.wait(1.0); pcall(function() httprequest({ Url = url, Method = "PUT", Headers = { ["Content-Type"] = "application/json" }, Body = payload }) end) end
	end)
end

local Themes = {
	Black = {
		MainBg=Color3.fromRGB(8,8,8), HeaderBg=Color3.fromRGB(16,16,16), InputBg=Color3.fromRGB(24,24,26),
		TextColor=Color3.fromRGB(255,255,255), NameColor=Color3.fromRGB(165,165,170), SubText=Color3.fromRGB(115,115,120),
		MyBubble=Color3.fromRGB(0,122,255), OtherBubble=Color3.fromRGB(32,32,34), Accent=Color3.fromRGB(0,122,255),
		BgTrans=0, HeadTrans=0, InpTrans=0, BubOtherTrans=0, BubMeTrans=0, StrokeColor=Color3.fromRGB(48,48,52)
	},
	White = {
		MainBg=Color3.fromRGB(248,248,252), HeaderBg=Color3.fromRGB(255,255,255), InputBg=Color3.fromRGB(240,240,245),
		TextColor=Color3.fromRGB(20,20,25), NameColor=Color3.fromRGB(90,90,100), SubText=Color3.fromRGB(140,140,150),
		MyBubble=Color3.fromRGB(0,122,255), OtherBubble=Color3.fromRGB(232,232,240), Accent=Color3.fromRGB(0,122,255),
		BgTrans=0, HeadTrans=0, InpTrans=0, BubOtherTrans=0, BubMeTrans=0, StrokeColor=Color3.fromRGB(212,212,222)
	},
	Pink = {
		MainBg=Color3.fromRGB(30,15,26), HeaderBg=Color3.fromRGB(48,25,42), InputBg=Color3.fromRGB(58,32,52),
		TextColor=Color3.fromRGB(255,242,250), NameColor=Color3.fromRGB(255,185,222), SubText=Color3.fromRGB(225,165,205),
		MyBubble=Color3.fromRGB(255,80,160), OtherBubble=Color3.fromRGB(72,38,62), Accent=Color3.fromRGB(255,105,180),
		BgTrans=0, HeadTrans=0, InpTrans=0, BubOtherTrans=0, BubMeTrans=0, StrokeColor=Color3.fromRGB(255,105,180)
	}
}
local ThemeSequence = {"Black", "White", "Pink"}
local ThemeIcons = {Black="⚫", White="⚪", Pink="🌸"}
local currentThemeIndex = 1

local function ApplyVIPStyleToBubble(bub, themeKey)
	local t = Themes[themeKey]
	local isMe = (bub.AnchorPoint.X == 1)
	bub.BackgroundColor3 = isMe and t.MyBubble or t.OtherBubble
	bub.BackgroundTransparency = isMe and t.BubMeTrans or t.BubOtherTrans
	local nLbl = bub:FindFirstChild("SenderName"); if nLbl and nLbl.Text ~= "ARIA" then nLbl.TextColor3 = t.NameColor end
	local mLbl = bub:FindFirstChild("MainMessageText"); if mLbl then mLbl.TextColor3 = t.TextColor end
end

local targetParent = CoreGui or LocalPlayer:WaitForChild("PlayerGui")
local Screen = Instance.new("ScreenGui", targetParent)
Screen.Name = GenerateRandomUIName(); Screen.ResetOnSpawn = false
Screen.IgnoreGuiInset = true; Screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

Screen.AncestryChanged:Connect(function(_, newParent)
	if newParent == nil and Screen.Name:find("AxerUI_") and not getgenv().AxerChat_Unloading then TitanGuardKick("UI-HIJACK", "UI Container Destroyed") end
end)
Screen.Destroying:Connect(function() if Lighting:FindFirstChild("AxerCinematicBlur") then Lighting.AxerCinematicBlur:Destroy() end end)

local ToastFrame = Instance.new("Frame", Screen); ToastFrame.Name = "AxerSmartToastContainer"; ToastFrame.Size = UDim2.new(0, 280, 0.65, 0); ToastFrame.AnchorPoint = Vector2.new(1, 1); ToastFrame.Position = UDim2.new(1, -15, 1, -15); ToastFrame.BackgroundTransparency = 1; ToastFrame.ClipsDescendants = false
local ToastLayout = Instance.new("UIListLayout", ToastFrame); ToastLayout.Padding = UDim.new(0, 10); ToastLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom; ToastLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right; ToastLayout.SortOrder = Enum.SortOrder.LayoutOrder

local function GetHumanReadablePreview(raw)
	if not raw then return "" end
	local _, _, clean = raw:match("^%[RPL::(.-)::(.-)::RPL%]%s*(.*)"); local target = clean or raw
	if target:sub(1,5) == "[EDT]" then target = target:sub(6) end
	if target:match("^%[MEDIA::") then return "🖼️ [Image Vault]" end
	if target:match("^%[STICKER://") then return "🏵️ [Sticker]" end
	return target:gsub("<[^>]+>", "")
end

function AxerChat.SyncNativeRobloxBubbleSettings()
	local isPink = (AxerChat.CurrentTheme == "Pink"); local isWhite = (AxerChat.CurrentTheme == "White")
	local bgCol = isWhite and Color3.fromRGB(255, 255, 255) or (isPink and Color3.fromRGB(30, 15, 26) or Color3.fromRGB(15, 15, 15))
	local txtCol = isWhite and Color3.fromRGB(15, 15, 15) or Color3.fromRGB(255, 255, 255)
	pcall(function() local tcs = game:GetService("TextChatService"); if tcs and tcs:FindFirstChild("BubbleChatConfiguration") then tcs.BubbleChatConfiguration.BackgroundColor3 = bgCol; tcs.BubbleChatConfiguration.TextColor3 = txtCol end end)
	pcall(function() game:GetService("Chat"):SetBubbleChatSettings({BackgroundColor3 = bgCol, TextColor3 = txtCol}) end)
end

local VAULT_FILE = "AxerImageVault_" .. LocalPlayer.UserId .. ".json"
local function GetDiskVault() if not readfile then return {} end local s, r = pcall(function() return HttpService:JSONDecode(readfile(VAULT_FILE)) end); return (s and typeof(r)=="table") and r or {} end
local function SaveDiskVault(t) if writefile then pcall(function() writefile(VAULT_FILE, HttpService:JSONEncode(t)) end) end end

local FAV_FILE = "AxerImageFavs_" .. LocalPlayer.UserId .. ".json"
local function GetDiskFavs() if not readfile then return {} end local s, r = pcall(function() return HttpService:JSONDecode(readfile(FAV_FILE)) end); return (s and typeof(r)=="table") and r or {} end
local function SaveDiskFavs(t) if writefile then pcall(function() writefile(FAV_FILE, HttpService:JSONEncode(t)) end) end end

local READ_FILE = "AxerReadState_" .. LocalPlayer.UserId .. ".json"
function AxerChat.GetLastRead(partnerLower) if not readfile then return 0 end local s, r = pcall(function() return HttpService:JSONDecode(readfile(READ_FILE)) end); return (s and typeof(r)=="table" and r[partnerLower]) and tonumber(r[partnerLower]) or 0 end
function AxerChat.SetLastRead(partnerLower, timestamp) if not writefile then return end local s, r = pcall(function() return HttpService:JSONDecode(readfile(READ_FILE)) end); local st = (s and typeof(r)=="table") and r or {}; st[partnerLower] = timestamp; pcall(function() writefile(READ_FILE, HttpService:JSONEncode(st)) end) end
function AxerChat.GetUnreadCount(partnerLower) local cnt = 0; local lr = AxerChat.GetLastRead(partnerLower); for _, m in ipairs(AxerChat.Cache.DMs[partnerLower] or {}) do if m.Time > lr and m.UserID ~= LocalPlayer.UserId then cnt = cnt + 1 end end return cnt end

function AxerChat.RegisterAccount(rawUsername, rawDisplayName, rawUserId)
	if not rawUsername or typeof(rawUsername) ~= "string" or rawUsername == "" then return end
	AxerChat.AccountRegistry[rawUsername:lower()] = { Username = rawUsername, DisplayName = rawDisplayName or rawUsername, UserId = rawUserId or 1 }
end
function AxerChat.GetAccount(usernameLower)
	if not usernameLower or typeof(usernameLower) ~= "string" then return { Username = "Unknown", DisplayName = "Unknown", UserId = 1 } end
	local tk = usernameLower:lower(); if AxerChat.AccountRegistry[tk] then return AxerChat.AccountRegistry[tk] end
	for _, p in ipairs(Players:GetPlayers()) do if p.Name:lower() == tk then AxerChat.RegisterAccount(p.Name, p.DisplayName, p.UserId); return AxerChat.AccountRegistry[tk] end end
	return { Username = usernameLower, DisplayName = usernameLower, UserId = 1 }
end

local function ApplyWebImage(imgObj, url)
	if not url then return end
	if url:sub(1,10):lower() == "rbxassetid" or url:sub(1,9):lower() == "rbxthumb:" then imgObj.Image = url; return end
	if not getcustomasset or not writefile or not isfile then return end
	local safeHash = SignData(url); local fileName = "AxerMediaCache_" .. safeHash .. ".png"
	if pcall(isfile, fileName) and isfile(fileName) then pcall(function() imgObj.Image = getcustomasset(fileName) end); return end
	task.spawn(function() local succ, res = pcall(function() return httprequest({Url = url, Method = "GET"}) end); if succ and res and res.StatusCode == 200 and res.Body then pcall(function() writefile(fileName, res.Body); imgObj.Image = getcustomasset(fileName) end) end end)
end

local function loadDP(img, user)
	if user == "ARIA" then img.Image = "rbxassetid://92917449577250"; return end
	task.spawn(function() local p = Players:FindFirstChild(user); local succ, fId = pcall(function() return Players:GetUserIdFromNameAsync(user) end); local id = p and p.UserId or (succ and fId or 1); img.Image = Players:GetUserThumbnailAsync(id, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48) end)
end

function AxerChat.DispatchGodCommand(cmdStr)
	if not IsStrictAdmin() then TitanGuardKick("GOD-SPOOF", "Illegal God Execution") return end
	if cmdStr:sub(1, 9) == "BAN_USER:" then
		FB_PUT_SYNC("Blacklist/Accounts/" .. cmdStr:sub(10):lower(), "true", true)
	elseif cmdStr:sub(1, 11) == "UNBAN_USER:" then
		local u = cmdStr:sub(12):lower()
		task.spawn(function()
			local mapRes = FB_GET_RAW("Blacklist/Accounts/" .. u)
			if mapRes and type(mapRes) == "string" and mapRes ~= "null" and mapRes ~= "true" then
				FB_DELETE("Blacklist/HWIDs/" .. mapRes:gsub('"', ''))
			end
			FB_DELETE("Blacklist/Accounts/" .. u)
		end)
	elseif cmdStr:sub(1, 10) == "LOCK_CHAT:" then FB_PUT("Locks/" .. cmdStr:sub(11):lower(), "true", true)
	elseif cmdStr:sub(1, 12) == "UNLOCK_CHAT:" then FB_DELETE("Locks/" .. cmdStr:sub(13):lower())
	elseif cmdStr:sub(1, 13) == "MUTE_KEYWORD:" then FB_PUT("Mutes/Keywords/" .. cmdStr:sub(14):lower(), "true", true)
	elseif cmdStr:sub(1, 15) == "UNMUTE_KEYWORD:" then FB_DELETE("Mutes/Keywords/" .. cmdStr:sub(16):lower())
	elseif cmdStr:sub(1,10) == "GRANT_VIP:" then
		local u = cmdStr:sub(11):lower()
		AxerChat.VIPList[u] = true; FB_PUT("VIP/" .. u, "true", true)
		AxerChat.RefreshAllVisibleVIPBadges()
		AxerChat.TriggerToast("👑 VIP Granted", "@" .. u .. " is now a VIP!", false)
	elseif cmdStr:sub(1,12) == "REVOKE_VIP:" then
		local u = cmdStr:sub(13):lower()
		AxerChat.VIPList[u] = nil; FB_DELETE("VIP/" .. u)
		AxerChat.RefreshAllVisibleVIPBadges()
		AxerChat.TriggerToast("👑 VIP Revoked", "@" .. u .. " is no longer VIP.", false)
	elseif cmdStr:sub(1,12) == "GRANT_TITLE:" then
		local rest = cmdStr:sub(13); local u, ttl = rest:match("^([^:]+):(.+)$")
		if u and ttl then u = u:lower(); AxerChat.TitleRegistry[u] = ttl; FB_PUT("Titles/" .. u, ttl, true); AxerChat.LiveSyncAllVisibleBubblesTitle() end
	elseif cmdStr:sub(1,13) == "REVOKE_TITLE:" then
		local u = cmdStr:sub(14):lower(); AxerChat.TitleRegistry[u] = nil; FB_DELETE("Titles/" .. u); AxerChat.LiveSyncAllVisibleBubblesTitle()
	end
end

function AxerChat.SetLockState(isLocked)
	AxerChat.IsLocked = isLocked
	if not AxerChat.UI.TextBox then return end
	if isLocked then
		AxerChat.UI.TextBox.TextEditable = false; AxerChat.UI.TextBox.ClearTextOnFocus = false
		AxerChat.UI.TextBox.Text = ""; AxerChat.UI.TextBox.PlaceholderText = "🔒 CHAT LOCKED BY ADMIN"
		AxerChat.UI.TextBox.TextColor3 = Color3.fromRGB(255, 80, 80)
		AxerChat.UI.SendBtn.BackgroundColor3 = Color3.fromRGB(80, 20, 20)
	else
		AxerChat.UI.TextBox.TextEditable = true; AxerChat.UI.TextBox.PlaceholderText = "Type message..."
		AxerChat.UI.TextBox.TextColor3 = Themes[AxerChat.CurrentTheme].TextColor
		AxerChat.UI.SendBtn.BackgroundColor3 = Themes[AxerChat.CurrentTheme].Accent
	end
end

function AxerChat.TriggerAriaLocal(msgText)
	local zID = "SYS_LOCAL_WARN_" .. tostring(os.clock()) .. "_" .. math.random(1000,9999)
	local targetCache = (AxerChat.Mode == "DM" and AxerChat.ActiveDM) and AxerChat.Cache.DMs[AxerChat.ActiveDM] or AxerChat.Cache.Server
	table.insert(targetCache, {Sender="ARIA", UserID=0, Msg=msgText, Time=os.time(), ID=zID, Edited=false})
	AxerChat.RenderBubble("ARIA", 0, msgText, os.time(), zID, false)
	AxerChat.HandleScroll(true)
end

task.spawn(function()
	local lock = FB_GET_RAW("Locks/" .. LocalPlayer.Name:lower())
	if lock and lock == "true" then AxerChat.SetLockState(true) end
	local kw = FB_GET("Mutes/Keywords"); if type(kw) == "table" then AxerChat.MutedKeywords = kw end
	local vips = FB_GET("VIP"); if type(vips) == "table" then for k,_ in pairs(vips) do AxerChat.VIPList[k] = true end end
	local titles = FB_GET("Titles"); if type(titles) == "table" then for k,v in pairs(titles) do AxerChat.TitleRegistry[k] = v end end
end)

local lastAnnounceKey = ""
local function SendAnnouncement(text)
    if not IsStrictAdmin() then return end
    if not text or text == "" then return end
    local key = tostring(os.time()) .. "_" .. tostring(LocalPlayer.UserId) .. "_" .. tostring(math.random(1000,9999))
    FB_PUT_SYNC("Announcements/" .. key, { sender = LocalPlayer.Name, displayName = LocalPlayer.DisplayName, text = text, timestamp = os.time() })
    task.spawn(function()
        AxerChat.TriggerAriaLocal("📢 <b>ANNOUNCEMENT SENT</b>\n<font color='#B43CFF'>📡 Broadcasting to all servers...</font>\n\n" .. text)
        task.wait(0.4); AxerChat.TriggerToast("📢 Announcement Sent", text:sub(1, 50), false)
    end)
end

local function StartAnnouncementPolling()
    task.spawn(function()
        local initial = FB_GET("Announcements")
        if type(initial) == "table" then
            local keys = {}; for k, _ in pairs(initial) do table.insert(keys, k) end; table.sort(keys)
            if #keys > 0 then lastAnnounceKey = keys[#keys] end
        end
        while task.wait(4) do
            if getgenv().AxerChat_Unloading then break end
            local data = FB_GET("Announcements")
            if type(data) == "table" then
                local keys = {}; for k, _ in pairs(data) do table.insert(keys, k) end; table.sort(keys)
                for _, k in ipairs(keys) do
                    if k > lastAnnounceKey then
                        lastAnnounceKey = k
                        local ann = data[k]
                        if ann and ann.text and ann.sender ~= LocalPlayer.Name then
                            task.spawn(function()
                                AxerChat.TriggerAriaLocal("📢 <b>CROSS-SERVER ANNOUNCEMENT</b>\n<font color='#B43CFF'>From: @" .. tostring(ann.sender) .. "</font>\n<font color='#888888'>─────────────────</font>\n\n" .. tostring(ann.text) .. "\n\n<font color='#888888'>─────────────────</font>")
                                task.wait(0.8); AxerChat.TriggerToast("📢 Announcement", tostring(ann.text):sub(1, 60), false)
                            end)
                        end
                    end
                end
            end
        end
    end)
end

local function PlayMinimizerSound()
    task.spawn(function()
        local sound = Instance.new("Sound")
        sound.SoundId = "rbxassetid://135244211779631"; sound.Volume = 1.5
        sound.Parent = CoreGui or game:GetService("CoreGui")
        sound:Play(); sound.Ended:Connect(function() sound:Destroy() end)
    end)
end

local function SmoothShowTray(tray, slideFromY)
	if not tray then return end
	if tray.Visible then return end
	local basePos = tray:GetAttribute("AxerBaseY") or tray.Position.Y.Offset
	tray:SetAttribute("AxerBaseY", basePos)
	local startY = slideFromY or (basePos + 30)
	tray.Position = UDim2.new(tray.Position.X.Scale, tray.Position.X.Offset, tray.Position.Y.Scale, startY)
	tray.BackgroundTransparency = 1
	if tray:FindFirstChild("UIStroke") then tray.UIStroke.Transparency = 1 end
	tray.Visible = true
	TweenService:Create(tray, TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Position = UDim2.new(tray.Position.X.Scale, tray.Position.X.Offset, tray.Position.Y.Scale, basePos),
		BackgroundTransparency = Themes[AxerChat.CurrentTheme].HeadTrans
	}):Play()
	if tray:FindFirstChild("UIStroke") then TweenService:Create(tray.UIStroke, TweenInfo.new(0.32), {Transparency = 0}):Play() end
end

local function SmoothHideTray(tray)
	if not tray or not tray.Visible then return end
	local basePos = tray:GetAttribute("AxerBaseY") or tray.Position.Y.Offset
	tray:SetAttribute("AxerBaseY", basePos)
	local tw = TweenService:Create(tray, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = UDim2.new(tray.Position.X.Scale, tray.Position.X.Offset, tray.Position.Y.Scale, basePos + 25),
		BackgroundTransparency = 1
	})
	if tray:FindFirstChild("UIStroke") then TweenService:Create(tray.UIStroke, TweenInfo.new(0.22), {Transparency = 1}):Play() end
	tw:Play()
	tw.Completed:Connect(function()
		if tray then
			tray.Visible = false
			tray.Position = UDim2.new(tray.Position.X.Scale, tray.Position.X.Offset, tray.Position.Y.Scale, basePos)
		end
	end)
end

local function ToggleMainGUI()
    PlayMinimizerSound()
    local main = AxerChat.UI.MainBg
    if not main then return end
    if main.Visible then
        if AxerChat.UI.StickerTray then SmoothHideTray(AxerChat.UI.StickerTray) end
        if AxerChat.UI.ImageTray then SmoothHideTray(AxerChat.UI.ImageTray) end
        if AxerChat.UI.AdminTray then SmoothHideTray(AxerChat.UI.AdminTray) end
        AxerChat.CancelActionBar()
        main.Visible = false
    else
        main.Visible = true
    end
end

local function ApplyVIPCurvedTitle(dpImage)
    if not dpImage or not dpImage.Parent then return end
    local pf = dpImage.Parent
    local Arc = pf:FindFirstChild("AxerCurvedTitleArc"); if Arc then Arc:Destroy() end
    Arc = Instance.new("Frame", pf); Arc.Name = "AxerCurvedTitleArc"
    Arc.Size = dpImage.Size; Arc.Position = dpImage.Position; Arc.AnchorPoint = dpImage.AnchorPoint
    Arc.BackgroundTransparency = 1; Arc.ZIndex = dpImage.ZIndex + 5
    local textString = "VIP"; local cc = #textString
    local br = (dpImage.Size.X.Offset / 2) + 3.5
    local sa = math.rad(-90 - (math.min((cc-1)*18, 160)/2))
    local ea = math.rad(-90 + (math.min((cc-1)*18, 160)/2))
    local cx, cy = dpImage.Size.X.Offset/2, dpImage.Size.Y.Offset/2
    local lTrack = {}
    for i = 1, cc do
        local curA = (cc > 1) and (sa + ((i-1)*(ea-sa)/(cc-1))) or sa
        local L = Instance.new("TextLabel", Arc)
        L.Size = UDim2.new(0, 14, 0, 14); L.AnchorPoint = Vector2.new(0.5, 0.5)
        L.Position = UDim2.new(0, cx + (math.cos(curA)*br), 0, cy + (math.sin(curA)*br))
        L.BackgroundTransparency = 1; L.Text = textString:sub(i,i)
        L.Font = Enum.Font.GothamBold; L.TextSize = 8.5
        L.TextColor3 = Color3.fromRGB(255, 215, 0)
        L.TextXAlignment = Enum.TextXAlignment.Center
        L.Rotation = math.deg(curA) + 90
        local ug = Instance.new("UIGradient", L); ug.Rotation = 45
        ug.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 215, 0)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 165, 0)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 215, 0))})
        table.insert(lTrack, {l = L, idx = i})
    end
    local tc = 10.0; local con
    con = RunService.Heartbeat:Connect(function()
        if not Arc or not Arc.Parent or getgenv().AxerChat_Unloading then con:Disconnect() return end
        local t = os.clock()
        for _, d in ipairs(lTrack) do
            local lt = (t - (d.idx * 0.22)) % tc
            d.l.TextTransparency = (lt < 5.0) and 0 or ((lt < 6.0) and ((1-math.cos((lt-5.0)*math.pi))/2) or ((lt < 9.0) and 1 or ((1+math.cos((lt-9.0)*math.pi))/2)))
        end
    end)
end

function AxerChat.RefreshAllVisibleVIPBadges()
    for _, child in pairs(AxerChat.UI.Scroll:GetChildren()) do
        if child:IsA("Frame") and child:FindFirstChild("MessageBubble") then
            local bub = child.MessageBubble
            local dp = child:FindFirstChildWhichIsA("ImageLabel")
            if dp then
                local sn = ""; local nl = bub:FindFirstChild("SenderName")
                if nl then sn = nl.Text elseif bub.AnchorPoint.X == 1 then sn = LocalPlayer.Name end
                local sl = sn:lower()
                if dp.Parent:FindFirstChild("AxerCurvedTitleArc") then dp.Parent.AxerCurvedTitleArc:Destroy() end
                if AxerChat.VIPList[sl] then ApplyVIPCurvedTitle(dp) end
            end
        end
    end
end

function AxerChat.BuildMasterUI()
	local t = Themes[AxerChat.CurrentTheme]
	local ToggleBtn = Instance.new("ImageButton", Screen); ToggleBtn.Name = "AxerMovableToggle"; ToggleBtn.Size = UDim2.new(0,42,0,42); ToggleBtn.Position = UDim2.new(0,15,0.5,-21)
	ToggleBtn.Image = "rbxassetid://106542899596174"
	ToggleBtn.BackgroundColor3 = Color3.fromRGB(15,15,15); Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(1,0); Instance.new("UIStroke", ToggleBtn).Color = Color3.fromRGB(255,255,255)
	local MainFrame = Instance.new("Frame", Screen); MainFrame.Name = "AxerMainFrame"; MainFrame.Size = UDim2.new(0,440,0,350); MainFrame.Position = UDim2.new(0.5,-220,0.5,-175); MainFrame.BackgroundColor3 = t.MainBg; MainFrame.Visible = false; MainFrame.Active = true; MainFrame.Draggable = true; Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0,16); local MainStroke = Instance.new("UIStroke", MainFrame); MainStroke.Color = t.StrokeColor

	local dragTog, startP, togStart, hasDragged = false, nil, nil, false
	ToggleBtn.InputBegan:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then dragTog=true; startP=inp.Position; togStart=ToggleBtn.Position; hasDragged=false end end)
	UserInputService.InputChanged:Connect(function(inp) if dragTog and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then local delta=inp.Position-startP; if delta.Magnitude>5 then hasDragged=true; ToggleBtn.Position=UDim2.new(togStart.X.Scale, togStart.X.Offset+delta.X, togStart.Y.Scale, togStart.Y.Offset+delta.Y) end end end)
	ToggleBtn.InputEnded:Connect(function(inp)
		if dragTog and (inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch) then
			dragTog=false
			if not hasDragged then ToggleMainGUI(); if MainFrame.Visible then AxerChat.SwitchMode(AxerChat.Mode, AxerChat.ActiveDM); AxerChat.HandleScroll(true) end end
		end
	end)

	local Header = Instance.new("Frame", MainFrame); Header.Size = UDim2.new(1,0,0,34); Header.BackgroundColor3 = t.HeaderBg; Header.BorderSizePixel = 0; Instance.new("UICorner", Header).CornerRadius = UDim.new(0,14)
	local BackBtn = Instance.new("TextButton", Header); BackBtn.Size = UDim2.new(0,30,1,0); BackBtn.Position = UDim2.new(0,5,0,0); BackBtn.BackgroundTransparency = 1; BackBtn.Font = Enum.Font.GothamBold; BackBtn.Text = "◀"; BackBtn.TextSize = 15; BackBtn.TextColor3 = t.MyBubble; BackBtn.Visible = false
	local HeaderDP = Instance.new("ImageLabel", Header); HeaderDP.Name = "ActiveDMProfilePic"; HeaderDP.Size = UDim2.new(0, 24, 0, 24); HeaderDP.Position = UDim2.new(0, 38, 0.5, -12); HeaderDP.BackgroundTransparency = 1; HeaderDP.Visible = false; Instance.new("UICorner", HeaderDP).CornerRadius = UDim.new(1, 0)
	local Title = Instance.new("TextLabel", Header); Title.Name = "MainTitle"; Title.Size = UDim2.new(0,210,1,0); Title.Position = UDim2.new(0,15,0,0); Title.BackgroundTransparency = 1; Title.Text = "AXER CHAT"; Title.Font = Enum.Font.GothamBold; Title.TextSize = 14; Title.TextColor3 = t.TextColor; Title.TextXAlignment = Enum.TextXAlignment.Left; Title.RichText = true

	local ThemeBtn = Instance.new("TextButton", Header); ThemeBtn.Size = UDim2.new(0,26,0,26); ThemeBtn.Position = UDim2.new(1,-32,0.5,-13); ThemeBtn.BackgroundColor3 = t.InputBg; ThemeBtn.Text = ThemeIcons[ThemeSequence[currentThemeIndex]]; ThemeBtn.Font = Enum.Font.GothamBold; ThemeBtn.TextSize = 13; Instance.new("UICorner", ThemeBtn).CornerRadius = UDim.new(0,8)
	local InboxBtn = Instance.new("TextButton", Header); InboxBtn.Size = UDim2.new(0,26,0,26); InboxBtn.Position = UDim2.new(1,-64,0.5,-13); InboxBtn.BackgroundColor3 = t.InputBg; InboxBtn.Text = "📩"; InboxBtn.Font = Enum.Font.GothamBold; InboxBtn.TextSize = 13; Instance.new("UICorner", InboxBtn).CornerRadius = UDim.new(0,8)
	local MuteBtn = Instance.new("TextButton", Header); MuteBtn.Size = UDim2.new(0,26,0,26); MuteBtn.Position = UDim2.new(1,-96,0.5,-13); MuteBtn.BackgroundColor3 = t.InputBg; MuteBtn.Text = "🔊"; MuteBtn.Font = Enum.Font.GothamBold; MuteBtn.TextSize = 13; Instance.new("UICorner", MuteBtn).CornerRadius = UDim.new(0,8)

	local SearchWrapper = Instance.new("Frame", MainFrame); SearchWrapper.Name = "AxerGlobalSearch"; SearchWrapper.Size = UDim2.new(1,-20,0,36); SearchWrapper.Position = UDim2.new(0,10,0,40); SearchWrapper.BackgroundColor3 = t.InputBg; SearchWrapper.Visible = false; Instance.new("UICorner", SearchWrapper).CornerRadius = UDim.new(0,18)
	local SearchInput = Instance.new("TextBox", SearchWrapper); SearchInput.Size = UDim2.new(1,-20,1,0); SearchInput.Position = UDim2.new(0,15,0,0); SearchInput.BackgroundTransparency = 1; SearchInput.Font = Enum.Font.GothamMedium; SearchInput.TextSize = 12; SearchInput.TextColor3 = t.TextColor; SearchInput.PlaceholderText = "🔍 Search user by name..."; SearchInput.PlaceholderColor3 = t.SubText; SearchInput.TextXAlignment = Enum.TextXAlignment.Left; SearchInput.ClearTextOnFocus = false; SearchInput.Text = ""

	local Scroll = Instance.new("ScrollingFrame", MainFrame); Scroll.Size = UDim2.new(1,0,1,-80); Scroll.Position = UDim2.new(0,0,0,34); Scroll.BackgroundTransparency = 1; Scroll.ScrollBarThickness = 2; Scroll.AutomaticCanvasSize = Enum.AutomaticSize.None
	local ScrollLayout = Instance.new("UIListLayout", Scroll); ScrollLayout.Padding = UDim.new(0,8)
	local SPad = Instance.new("UIPadding", Scroll); SPad.PaddingLeft = UDim.new(0,15); SPad.PaddingRight = UDim.new(0,15); SPad.PaddingTop = UDim.new(0,10); SPad.PaddingBottom = UDim.new(0,10)
	ScrollLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() local pTotal=SPad.PaddingTop.Offset+SPad.PaddingBottom.Offset; Scroll.CanvasSize=UDim2.new(0,0,0,ScrollLayout.AbsoluteContentSize.Y+pTotal+25) end)

	local JumpBtn = Instance.new("TextButton", MainFrame); JumpBtn.Name = "AxerJumpBtn"; JumpBtn.Size = UDim2.new(0,34,0,34); JumpBtn.Position = UDim2.new(1,-45,1,-90); JumpBtn.BackgroundColor3 = t.Accent; JumpBtn.Text = "⬇️"; JumpBtn.Font = Enum.Font.GothamBold; JumpBtn.TextSize = 14; JumpBtn.TextColor3 = Color3.fromRGB(255,255,255); Instance.new("UICorner", JumpBtn).CornerRadius = UDim.new(1,0); JumpBtn.Visible = false
	JumpBtn.MouseButton1Click:Connect(function() AxerChat.HandleScroll(true) end)

	local ReplyPreview = Instance.new("Frame", MainFrame); ReplyPreview.Name = "AxerReplyPocketBar"; ReplyPreview.Size = UDim2.new(1,-20,0,36); ReplyPreview.Position = UDim2.new(0,10,1,-46); ReplyPreview.BackgroundColor3 = t.InputBg; ReplyPreview.Visible = false; ReplyPreview.ZIndex = 2; Instance.new("UICorner", ReplyPreview).CornerRadius = UDim.new(0,8)
	local ReplyIcon = Instance.new("TextLabel", ReplyPreview); ReplyIcon.Name = "RepIcon"; ReplyIcon.Size = UDim2.new(0,25,1,0); ReplyIcon.Position = UDim2.new(0,5,0,0); ReplyIcon.BackgroundTransparency = 1; ReplyIcon.Text = "↩"; ReplyIcon.Font = Enum.Font.GothamBold; ReplyIcon.TextSize = 15; ReplyIcon.TextColor3 = t.MyBubble; ReplyIcon.ZIndex = 2
	local ReplyText = Instance.new("TextLabel", ReplyPreview); ReplyText.Name = "RepText"; ReplyText.Size = UDim2.new(1,-60,1,0); ReplyText.Position = UDim2.new(0,30,0,0); ReplyText.BackgroundTransparency = 1; ReplyText.Font = Enum.Font.GothamMedium; ReplyText.TextSize = 11; ReplyText.TextColor3 = t.SubText; ReplyText.TextXAlignment = Enum.TextXAlignment.Left; ReplyText.RichText = true; ReplyText.ZIndex = 2
	local CancelRep = Instance.new("TextButton", ReplyPreview); CancelRep.Size = UDim2.new(0,22,0,22); CancelRep.Position = UDim2.new(1,-28,0.5,-11); CancelRep.BackgroundColor3 = t.MainBg; CancelRep.Text = "X"; CancelRep.TextColor3 = t.SubText; CancelRep.Font = Enum.Font.GothamBold; CancelRep.ZIndex = 2; Instance.new("UICorner", CancelRep).CornerRadius = UDim.new(1,0)

	local InputWrapper = Instance.new("Frame", MainFrame); InputWrapper.Size = UDim2.new(1,-20,0,38); InputWrapper.Position = UDim2.new(0,10,1,-46); InputWrapper.BackgroundColor3 = t.InputBg; InputWrapper.ZIndex = 3; Instance.new("UICorner", InputWrapper).CornerRadius = UDim.new(0,19)
	local TextBox = Instance.new("TextBox", InputWrapper); TextBox.Size = UDim2.new(1,-120,1,0); TextBox.Position = UDim2.new(0,15,0,0); TextBox.BackgroundTransparency = 1; TextBox.Font = Enum.Font.GothamMedium; TextBox.TextSize = 12; TextBox.TextColor3 = t.TextColor; TextBox.PlaceholderText = "Type message..."; TextBox.PlaceholderColor3 = t.SubText; TextBox.TextXAlignment = Enum.TextXAlignment.Left; TextBox.ClearTextOnFocus = false; TextBox.Text = ""; TextBox.ZIndex = 3

	local SendBtn = Instance.new("TextButton", InputWrapper); SendBtn.Size = UDim2.new(0,34,0,28); SendBtn.Position = UDim2.new(1,-38,0.5,-14); SendBtn.BackgroundColor3 = t.Accent; SendBtn.Text = "▶︎"; SendBtn.Font = Enum.Font.GothamBold; SendBtn.TextSize = 14; SendBtn.TextColor3 = Color3.fromRGB(255,255,255); SendBtn.ZIndex = 3; Instance.new("UICorner", SendBtn).CornerRadius = UDim.new(0,8)
	local StickerBtn = Instance.new("TextButton", InputWrapper); StickerBtn.Size = UDim2.new(0,32,0,28); StickerBtn.Position = UDim2.new(1,-74,0.5,-14); StickerBtn.BackgroundColor3 = t.HeaderBg; StickerBtn.Text = "🏵️"; StickerBtn.Font = Enum.Font.GothamBold; StickerBtn.TextSize = 13; StickerBtn.ZIndex = 3; Instance.new("UICorner", StickerBtn).CornerRadius = UDim.new(0,8)
	local ImageBtn = Instance.new("TextButton", InputWrapper); ImageBtn.Size = UDim2.new(0,32,0,28); ImageBtn.Position = UDim2.new(1,-110,0.5,-14); ImageBtn.BackgroundColor3 = t.HeaderBg; ImageBtn.Text = "🖼️"; ImageBtn.Font = Enum.Font.GothamBold; ImageBtn.TextSize = 13; ImageBtn.ZIndex = 3; Instance.new("UICorner", ImageBtn).CornerRadius = UDim.new(0,8)

	local StickerTray = Instance.new("Frame", MainFrame)
	StickerTray.Name = "AxerStickerTray"; StickerTray.Size = UDim2.new(1, -20, 0, 245); StickerTray.Position = UDim2.new(0, 10, 1, -296)
	StickerTray.BackgroundColor3 = t.HeaderBg; StickerTray.BackgroundTransparency = t.HeadTrans
	StickerTray.Visible = false; StickerTray.ZIndex = 50; StickerTray:SetAttribute("AxerBaseY", -296)
	Instance.new("UICorner", StickerTray).CornerRadius = UDim.new(0, 14); Instance.new("UIStroke", StickerTray).Color = t.Accent

	local StkSearch = Instance.new("TextBox", StickerTray)
	StkSearch.Size = UDim2.new(1, -16, 0, 28); StkSearch.Position = UDim2.new(0, 8, 0, 6)
	StkSearch.BackgroundColor3 = t.InputBg; StkSearch.TextColor3 = t.TextColor; StkSearch.Font = Enum.Font.GothamMedium; StkSearch.TextSize = 11
	StkSearch.PlaceholderText = "🔍 Search sticker ID..."; StkSearch.PlaceholderColor3 = t.SubText
	StkSearch.TextXAlignment = Enum.TextXAlignment.Left; StkSearch.ClearTextOnFocus = false; StkSearch.Text = ""; StkSearch.ZIndex = 52
	Instance.new("UICorner", StkSearch).CornerRadius = UDim.new(0, 8); Instance.new("UIPadding", StkSearch).PaddingLeft = UDim.new(0, 8)

	local StkScroll = Instance.new("ScrollingFrame", StickerTray)
	StkScroll.Size = UDim2.new(1, -8, 1, -44); StkScroll.Position = UDim2.new(0, 4, 0, 38)
	StkScroll.BackgroundTransparency = 1; StkScroll.ScrollBarThickness = 3; StkScroll.ZIndex = 51
	StkScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y; StkScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	local Grid = Instance.new("UIGridLayout", StkScroll)
	Grid.CellSize = UDim2.new(0, 50, 0, 50); Grid.CellPadding = UDim2.new(0, 6, 0, 6)
	Grid.HorizontalAlignment = Enum.HorizontalAlignment.Center; Grid.SortOrder = Enum.SortOrder.LayoutOrder
	Grid.FillDirectionMaxCells = 7
	Instance.new("UIPadding", StkScroll).PaddingTop = UDim.new(0, 8); StkScroll.UIPadding.PaddingBottom = UDim.new(0, 8)

	local function RenderStickerGrid(filter)
	    for _, c in pairs(StkScroll:GetChildren()) do if c:IsA("ImageButton") or c:IsA("TextLabel") then c:Destroy() end end
	    local fl = (filter and filter:lower():match("^%s*(.-)%s*$")) or ""
	    local shown = 0
	    for idx, stkid in ipairs(STICKER_LIST) do
	        if fl == "" or stkid:find(fl, 1, true) then
	            shown = shown + 1
	            local box = Instance.new("ImageButton", StkScroll)
	            box.Name = "Stk_" .. stkid; box.BackgroundColor3 = t.InputBg; box.BackgroundTransparency = 1
	            box.ZIndex = 52; box.LayoutOrder = idx
	            box.Image = "rbxthumb://type=Asset&id=" .. stkid .. "&w=150&h=150"
	            box.ScaleType = Enum.ScaleType.Fit
	            box.MouseButton1Click:Connect(function()
	                AxerChat.Send("[STICKER://" .. stkid .. "]")
	                SmoothHideTray(StickerTray); StkSearch.Text = ""
	            end)
	        end
	    end
	    if shown == 0 then
	        local empty = Instance.new("TextLabel", StkScroll); empty.Size = UDim2.new(1, 0, 0, 45); empty.BackgroundTransparency = 1
	        empty.Font = Enum.Font.GothamMedium; empty.TextSize = 11; empty.TextColor3 = t.SubText
	        empty.Text = "😶 No stickers match '" .. (filter or "") .. "'"; empty.ZIndex = 52
	    end
	end
	RenderStickerGrid("")
	StkSearch:GetPropertyChangedSignal("Text"):Connect(function() RenderStickerGrid(StkSearch.Text) end)

	local ImageTray = Instance.new("Frame", MainFrame)
	ImageTray.Name = "AxerImageVaultTray"; ImageTray.Size = UDim2.new(1, -20, 0, 245); ImageTray.Position = UDim2.new(0, 10, 1, -296)
	ImageTray.BackgroundColor3 = t.HeaderBg; ImageTray.BackgroundTransparency = t.HeadTrans
	ImageTray.Visible = false; ImageTray.ZIndex = 70; ImageTray:SetAttribute("AxerBaseY", -296)
	Instance.new("UICorner", ImageTray).CornerRadius = UDim.new(0, 14); Instance.new("UIStroke", ImageTray).Color = t.Accent

	local AriaBanner = Instance.new("Frame", ImageTray); AriaBanner.Size = UDim2.new(1, -16, 0, 32); AriaBanner.Position = UDim2.new(0, 8, 0, 6); AriaBanner.BackgroundColor3 = Color3.fromRGB(26, 15, 38); AriaBanner.ZIndex = 71
	Instance.new("UICorner", AriaBanner).CornerRadius = UDim.new(0, 8); Instance.new("UIStroke", AriaBanner).Color = Color3.fromRGB(180, 60, 255)
	local AriaDP = Instance.new("ImageLabel", AriaBanner); AriaDP.Size = UDim2.new(0, 22, 0, 22); AriaDP.Position = UDim2.new(0, 5, 0.5, -11); AriaDP.BackgroundTransparency = 1; AriaDP.Image = "rbxassetid://92917449577250"; AriaDP.ZIndex = 72
	Instance.new("UICorner", AriaDP).CornerRadius = UDim.new(1, 0)
	local AriaMsg = Instance.new("TextLabel", AriaBanner); AriaMsg.Size = UDim2.new(1, -34, 1, 0); AriaMsg.Position = UDim2.new(0, 30, 0, 0); AriaMsg.BackgroundTransparency = 1
	AriaMsg.Font = Enum.Font.GothamMedium; AriaMsg.TextSize = 10; AriaMsg.TextColor3 = Color3.fromRGB(255, 255, 255)
	AriaMsg.RichText = true; AriaMsg.TextXAlignment = Enum.TextXAlignment.Left; AriaMsg.ZIndex = 72
	AriaMsg.Text = "<font color='#B43CFF'><b>ARIA :</b></font> Save, favorite ⭐ & share!"

	local TabBar = Instance.new("Frame", ImageTray); TabBar.Size = UDim2.new(1, -16, 0, 26); TabBar.Position = UDim2.new(0, 8, 0, 42); TabBar.BackgroundColor3 = t.InputBg; TabBar.ZIndex = 71
	Instance.new("UICorner", TabBar).CornerRadius = UDim.new(0, 8)
	local AllTab = Instance.new("TextButton", TabBar); AllTab.Size = UDim2.new(0.5, -2, 1, -4); AllTab.Position = UDim2.new(0, 2, 0, 2); AllTab.BackgroundColor3 = t.Accent; AllTab.Text = "📂 All"
	AllTab.Font = Enum.Font.GothamBold; AllTab.TextSize = 11; AllTab.TextColor3 = Color3.fromRGB(255, 255, 255); AllTab.ZIndex = 72; AllTab.AutoButtonColor = false
	Instance.new("UICorner", AllTab).CornerRadius = UDim.new(0, 6)
	local FavTab = Instance.new("TextButton", TabBar); FavTab.Size = UDim2.new(0.5, -2, 1, -4); FavTab.Position = UDim2.new(0.5, 0, 0, 2); FavTab.BackgroundColor3 = t.InputBg; FavTab.Text = "⭐ Favorites"
	FavTab.Font = Enum.Font.GothamBold; FavTab.TextSize = 11; FavTab.TextColor3 = t.TextColor; FavTab.ZIndex = 72; FavTab.AutoButtonColor = false
	Instance.new("UICorner", FavTab).CornerRadius = UDim.new(0, 6)

	local VaultTopBar = Instance.new("Frame", ImageTray); VaultTopBar.Size = UDim2.new(1, -16, 0, 30); VaultTopBar.Position = UDim2.new(0, 8, 0, 72); VaultTopBar.BackgroundTransparency = 1; VaultTopBar.ZIndex = 71
	local UrlBox = Instance.new("TextBox", VaultTopBar); UrlBox.Size = UDim2.new(1, -70, 1, 0); UrlBox.BackgroundColor3 = t.InputBg; UrlBox.TextColor3 = t.TextColor; UrlBox.Font = Enum.Font.GothamMedium; UrlBox.TextSize = 11
	UrlBox.PlaceholderText = "🔗 Paste image URL here..."; UrlBox.PlaceholderColor3 = t.SubText; UrlBox.TextXAlignment = Enum.TextXAlignment.Left; UrlBox.ClearTextOnFocus = false; UrlBox.ZIndex = 72
	Instance.new("UICorner", UrlBox).CornerRadius = UDim.new(0, 6); Instance.new("UIPadding", UrlBox).PaddingLeft = UDim.new(0, 8)
	local SaveImgBtn = Instance.new("TextButton", VaultTopBar); SaveImgBtn.Size = UDim2.new(0, 62, 1, 0); SaveImgBtn.Position = UDim2.new(1, -62, 0, 0); SaveImgBtn.BackgroundColor3 = t.Accent
	SaveImgBtn.Font = Enum.Font.GothamBold; SaveImgBtn.TextSize = 11; SaveImgBtn.TextColor3 = Color3.fromRGB(255, 255, 255); SaveImgBtn.Text = "📥 Save"; SaveImgBtn.ZIndex = 72
	Instance.new("UICorner", SaveImgBtn).CornerRadius = UDim.new(0, 6)

	local VaultScroll = Instance.new("ScrollingFrame", ImageTray); VaultScroll.Name = "VaultScroll"; VaultScroll.Size = UDim2.new(1, -16, 1, -108); VaultScroll.Position = UDim2.new(0, 8, 0, 108)
	VaultScroll.BackgroundTransparency = 1; VaultScroll.ScrollBarThickness = 2; VaultScroll.AutomaticCanvasSize = Enum.AutomaticSize.None; VaultScroll.ZIndex = 71
	local VGrid = Instance.new("UIGridLayout", VaultScroll); VGrid.CellSize = UDim2.new(0, 62, 0, 62); VGrid.CellPadding = UDim2.new(0, 8, 0, 8); VGrid.HorizontalAlignment = Enum.HorizontalAlignment.Left

	local function SwitchVaultTab(isFavs)
		AxerChat.FavoritesMode = isFavs
		local twInfo = TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
		if isFavs then
			TweenService:Create(FavTab, twInfo, {BackgroundColor3 = t.Accent}):Play(); TweenService:Create(FavTab, twInfo, {TextColor3 = Color3.fromRGB(255,255,255)}):Play()
			TweenService:Create(AllTab, twInfo, {BackgroundColor3 = t.InputBg}):Play(); TweenService:Create(AllTab, twInfo, {TextColor3 = t.TextColor}):Play()
		else
			TweenService:Create(AllTab, twInfo, {BackgroundColor3 = t.Accent}):Play(); TweenService:Create(AllTab, twInfo, {TextColor3 = Color3.fromRGB(255,255,255)}):Play()
			TweenService:Create(FavTab, twInfo, {BackgroundColor3 = t.InputBg}):Play(); TweenService:Create(FavTab, twInfo, {TextColor3 = t.TextColor}):Play()
		end
		AxerChat.RefreshVaultUI()
	end
	AllTab.MouseButton1Click:Connect(function() SwitchVaultTab(false) end)
	FavTab.MouseButton1Click:Connect(function() SwitchVaultTab(true) end)

	if IsStrictAdmin() then
		local AdminBtn = Instance.new("TextButton", Header); AdminBtn.Size = UDim2.new(0,26,0,26); AdminBtn.Position = UDim2.new(1,-128,0.5,-13); AdminBtn.BackgroundColor3 = t.InputBg; AdminBtn.Text = "⚙️"
		AdminBtn.Font = Enum.Font.GothamBold; AdminBtn.TextSize = 13; Instance.new("UICorner", AdminBtn).CornerRadius = UDim.new(0,8)
		local AdminTray = Instance.new("Frame", MainFrame); AdminTray.Size = UDim2.new(1,-20,0,290); AdminTray.Position = UDim2.new(0,10,1,-340); AdminTray.BackgroundColor3 = t.HeaderBg
		AdminTray.Visible = false; AdminTray.ZIndex = 90; AdminTray:SetAttribute("AxerBaseY", -340)
		Instance.new("UICorner", AdminTray).CornerRadius = UDim.new(0,14); Instance.new("UIStroke", AdminTray).Color = t.Accent
		local SearchBar = Instance.new("TextBox", AdminTray); SearchBar.Size = UDim2.new(1,-50,0,32); SearchBar.Position = UDim2.new(0,8,0,8); SearchBar.BackgroundColor3 = t.InputBg; SearchBar.TextColor3 = t.TextColor
		SearchBar.Font = Enum.Font.GothamMedium; SearchBar.TextSize = 11; SearchBar.PlaceholderText = "Search User OR Keyword..."; SearchBar.PlaceholderColor3 = t.SubText
		SearchBar.TextXAlignment = Enum.TextXAlignment.Left; SearchBar.ClearTextOnFocus = false; SearchBar.ZIndex = 91
		Instance.new("UICorner", SearchBar).CornerRadius = UDim.new(0,6); Instance.new("UIPadding", SearchBar).PaddingLeft = UDim.new(0,8)

		local AdminCloseBtn = Instance.new("TextButton", AdminTray); AdminCloseBtn.Size = UDim2.new(0,32,0,32); AdminCloseBtn.Position = UDim2.new(1,-40,0,8); AdminCloseBtn.BackgroundColor3 = Color3.fromRGB(45,35,40); AdminCloseBtn.Text = "❌"
		AdminCloseBtn.Font = Enum.Font.GothamBold; AdminCloseBtn.TextSize = 12; AdminCloseBtn.ZIndex = 92; Instance.new("UICorner", AdminCloseBtn).CornerRadius = UDim.new(0,6)
		AdminCloseBtn.MouseButton1Click:Connect(function() SmoothHideTray(AdminTray) end)

		local kwBar = Instance.new("Frame", AdminTray); kwBar.Size = UDim2.new(1,-16,0,30); kwBar.Position = UDim2.new(0,8,0,46); kwBar.BackgroundTransparency = 1; kwBar.ZIndex = 91
		local mBtn = Instance.new("TextButton", kwBar); mBtn.Size = UDim2.new(0.48,0,1,0); mBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40); mBtn.Text = "🔇 MUTE KEYWORD"
		mBtn.Font = Enum.Font.GothamBold; mBtn.TextSize = 10; mBtn.TextColor3 = Color3.fromRGB(255,255,255); mBtn.ZIndex = 92; Instance.new("UICorner", mBtn).CornerRadius = UDim.new(0,6)
		local umBtn = Instance.new("TextButton", kwBar); umBtn.Size = UDim2.new(0.48,0,1,0); umBtn.Position = UDim2.new(0.52,0,0,0); umBtn.BackgroundColor3 = Color3.fromRGB(40, 150, 80); umBtn.Text = "🔊 UNMUTE KEYWORD"
		umBtn.Font = Enum.Font.GothamBold; umBtn.TextSize = 10; umBtn.TextColor3 = Color3.fromRGB(255,255,255); umBtn.ZIndex = 92; Instance.new("UICorner", umBtn).CornerRadius = UDim.new(0,6)
		mBtn.MouseButton1Click:Connect(function() local t2 = SearchBar.Text:lower():match("^%s*(.-)%s*$"); if t2 and t2~="" then AxerChat.DispatchGodCommand("MUTE_KEYWORD:"..t2); SearchBar.Text="" end end)
		umBtn.MouseButton1Click:Connect(function() local t2 = SearchBar.Text:lower():match("^%s*(.-)%s*$"); if t2 and t2~="" then AxerChat.DispatchGodCommand("UNMUTE_KEYWORD:"..t2); SearchBar.Text="" end end)

		local UsrScroll = Instance.new("ScrollingFrame", AdminTray); UsrScroll.Size = UDim2.new(1,-16,1,-86); UsrScroll.Position = UDim2.new(0,8,0,80); UsrScroll.BackgroundTransparency = 1; UsrScroll.ScrollBarThickness = 2
		UsrScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y; UsrScroll.ZIndex = 91
		local UsrLayout = Instance.new("UIListLayout", UsrScroll); UsrLayout.Padding = UDim.new(0,6); UsrLayout.SortOrder = Enum.SortOrder.LayoutOrder

		local function OpenAdminActionModal(uName, dName)
			if MainFrame:FindFirstChild("AxerAdminModal") then MainFrame.AxerAdminModal:Destroy() end
			local Overlay = Instance.new("Frame", MainFrame); Overlay.Size = UDim2.new(1,0,1,0); Overlay.BackgroundColor3 = Color3.fromRGB(0,0,0); Overlay.BackgroundTransparency = 0.5; Overlay.Active = true; Overlay.ZIndex = 95
			local Box = Instance.new("Frame", Overlay); Box.Size = UDim2.new(0,240,0,225); Box.Position = UDim2.new(0.5,0,0.5,0); Box.AnchorPoint = Vector2.new(0.5,0.5); Box.BackgroundColor3 = t.HeaderBg; Box.ZIndex = 96
			Instance.new("UICorner", Box).CornerRadius = UDim.new(0,12); Instance.new("UIStroke", Box).Color = t.Accent
			local Lyt = Instance.new("UIListLayout", Box); Lyt.Padding = UDim.new(0,6); Lyt.HorizontalAlignment = Enum.HorizontalAlignment.Center; Instance.new("UIPadding", Box).PaddingTop = UDim.new(0,10)
			local Tl = Instance.new("TextLabel", Box); Tl.Size = UDim2.new(1,-20,0,24); Tl.BackgroundTransparency = 1; Tl.Font = Enum.Font.GothamBold; Tl.TextSize = 12; Tl.TextColor3 = t.TextColor; Tl.Text = "Manage: " .. dName; Tl.ZIndex = 97
			local function mkBtn(n, col, act)
				local b = Instance.new("TextButton", Box); b.Size = UDim2.new(1,-30,0,30); b.BackgroundColor3 = col; b.Text = n; b.Font = Enum.Font.GothamBold; b.TextSize = 11; b.TextColor3 = Color3.fromRGB(255,255,255); b.ZIndex = 97
				Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
				b.MouseButton1Click:Connect(function() act(uName:lower()); Overlay:Destroy() end)
			end
			mkBtn("🔨 HWID BAN", Color3.fromRGB(200,45,45), function(u) AxerChat.DispatchGodCommand("BAN_USER:"..u) end)
			mkBtn("✅ UNBAN", Color3.fromRGB(45,150,200), function(u) AxerChat.DispatchGodCommand("UNBAN_USER:"..u) end)
			mkBtn("🔒 LOCK CHAT", Color3.fromRGB(210,110,20), function(u) AxerChat.DispatchGodCommand("LOCK_CHAT:"..u) end)
			mkBtn("🔓 UNLOCK CHAT", Color3.fromRGB(30,160,80), function(u) AxerChat.DispatchGodCommand("UNLOCK_CHAT:"..u) end)
			mkBtn("❌ CANCEL", Color3.fromRGB(80,80,80), function() end)
		end

		local function RenderAdminCards(filter)
			for _, c in pairs(UsrScroll:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
			local seen = {}; local q = filter and filter:lower() or ""
			local function addCard(un, dn, uid)
				if seen[un:lower()] or (q ~= "" and not un:lower():find(q) and not dn:lower():find(q)) then return end
				seen[un:lower()] = true
				local c = Instance.new("TextButton", UsrScroll); c.Size = UDim2.new(1,0,0,42); c.BackgroundColor3 = t.InputBg; c.Text = ""; c.ZIndex = 92; Instance.new("UICorner", c).CornerRadius = UDim.new(0,8)
				local p = Instance.new("ImageLabel", c); p.Size = UDim2.new(0,30,0,30); p.Position = UDim2.new(0,6,0,6); p.BackgroundTransparency = 1; p.ZIndex = 93; Instance.new("UICorner", p).CornerRadius = UDim.new(1,0); loadDP(p, un)
				local nl = Instance.new("TextLabel", c); nl.Size = UDim2.new(1,-50,0,16); nl.Position = UDim2.new(0,44,0,5); nl.BackgroundTransparency = 1; nl.Font = Enum.Font.GothamBold; nl.TextSize = 12; nl.TextColor3 = t.TextColor; nl.TextXAlignment = Enum.TextXAlignment.Left; nl.Text = dn; nl.ZIndex = 93
				local sl = Instance.new("TextLabel", c); sl.Size = UDim2.new(1,-50,0,14); sl.Position = UDim2.new(0,44,0,23); sl.BackgroundTransparency = 1; sl.Font = Enum.Font.GothamMedium; sl.TextSize = 10; sl.TextColor3 = t.SubText; sl.TextXAlignment = Enum.TextXAlignment.Left; sl.Text = "@" .. un; sl.ZIndex = 93
				c.MouseButton1Click:Connect(function() OpenAdminActionModal(un, dn) end)
			end
			for _, p in ipairs(Players:GetPlayers()) do addCard(p.Name, p.DisplayName, p.UserId) end
			for uName, acc in pairs(AxerChat.AccountRegistry) do addCard(acc.Username, acc.DisplayName, acc.UserId) end
		end
		SearchBar:GetPropertyChangedSignal("Text"):Connect(function() RenderAdminCards(SearchBar.Text) end)

		AdminBtn.MouseButton1Click:Connect(function()
			if StickerTray.Visible then SmoothHideTray(StickerTray) end
			if ImageTray.Visible then SmoothHideTray(ImageTray) end
			if AdminTray.Visible then SmoothHideTray(AdminTray) else SmoothShowTray(AdminTray); SearchBar.Text = ""; RenderAdminCards() end
		end)
		AxerChat.UI.AdminBtn = AdminBtn; AxerChat.UI.AdminTray = AdminTray; AxerChat.UI.AdminSearch = SearchBar
	end

	ImageBtn.MouseButton1Click:Connect(function()
		if StickerTray.Visible then SmoothHideTray(StickerTray) end
		if AxerChat.UI.AdminTray and AxerChat.UI.AdminTray.Visible then SmoothHideTray(AxerChat.UI.AdminTray) end
		if ImageTray.Visible then SmoothHideTray(ImageTray)
		else SmoothShowTray(ImageTray); task.wait(0.05); AxerChat.RefreshVaultUI() end
	end)

	StickerBtn.MouseButton1Click:Connect(function()
		if ImageTray.Visible then SmoothHideTray(ImageTray) end
		if AxerChat.UI.AdminTray and AxerChat.UI.AdminTray.Visible then SmoothHideTray(AxerChat.UI.AdminTray) end
		if StickerTray.Visible then SmoothHideTray(StickerTray)
		else SmoothShowTray(StickerTray); StkSearch.Text = ""; RenderStickerGrid("") end
	end)

	SaveImgBtn.MouseButton1Click:Connect(function()
		local ru = UrlBox.Text:match("^%s*(.-)%s*$"); if not ru or ru=="" then return end
		UrlBox.Text = ""; local cl = GetDiskVault(); local idp=false
		for _, u in ipairs(cl) do if u == ru then idp=true break end end
		if not idp then table.insert(cl, ru); SaveDiskVault(cl); AxerChat.TriggerToast("✅ Secure Vault", "Image saved forever!", false); AxerChat.RefreshVaultUI()
		else AxerChat.TriggerToast("⚠️ Notice", "Image already saved.", false) end
	end)

	AxerChat.UI.MainBg = MainFrame; AxerChat.UI.MainStroke = MainStroke; AxerChat.UI.HeaderBg = Header; AxerChat.UI.Scroll = Scroll; AxerChat.UI.JumpBtn = JumpBtn; AxerChat.UI.InputWrapper = InputWrapper; AxerChat.UI.TextBox = TextBox; AxerChat.UI.SendBtn = SendBtn; AxerChat.UI.StickerBtn = StickerBtn; AxerChat.UI.ImageBtn = ImageBtn; AxerChat.UI.StickerTray = StickerTray; AxerChat.UI.ImageTray = ImageTray; AxerChat.UI.InboxBtn = InboxBtn; AxerChat.UI.ThemeBtn = ThemeBtn; AxerChat.UI.MuteBtn = MuteBtn; AxerChat.UI.SearchWrapper = SearchWrapper; AxerChat.UI.SearchInput = SearchInput; AxerChat.UI.Title = Title; AxerChat.UI.Back = BackBtn; AxerChat.UI.HeaderDP = HeaderDP; AxerChat.UI.ReplyPreview = ReplyPreview; AxerChat.UI.ReplyIcon = ReplyIcon; AxerChat.UI.ReplyText = ReplyText; AxerChat.UI.CancelRep = CancelRep
	AxerChat.SyncNativeRobloxBubbleSettings()
	if AxerChat.IsLocked then AxerChat.SetLockState(true) end
end

function AxerChat.RefreshVaultUI()
	local sc = AxerChat.UI.ImageTray:FindFirstChild("VaultScroll"); if not sc then return end
	for _, c in pairs(sc:GetChildren()) do if c:IsA("ImageButton") or c:IsA("TextLabel") then c:Destroy() end end

	local vl = GetDiskVault(); local favs = GetDiskFavs(); local isFavMode = AxerChat.FavoritesMode; local t = Themes[AxerChat.CurrentTheme]
	local displayList = {}
	for idx, url in ipairs(vl) do
		if isFavMode then
			if favs[url] then table.insert(displayList, {url = url, origIdx = idx}) end
		else table.insert(displayList, {url = url, origIdx = idx}) end
	end
	local cnt = #displayList

	if cnt == 0 then
		local emp = Instance.new("TextLabel", sc)
		emp.Size = UDim2.new(1, -16, 1, -8); emp.Position = UDim2.new(0, 8, 0, 4); emp.BackgroundTransparency = 1
		emp.Font = Enum.Font.GothamMedium; emp.TextSize = 11; emp.TextColor3 = t.SubText; emp.ZIndex = 72; emp.RichText = true
		if isFavMode then emp.Text = "⭐ No favorites yet!\n\nTap the ⭐ star on any image\nto add it here for quick access.\n\n<font color='#B43CFF'>👉 Type <b>/helpphoto</b> for guide</font>"
		else emp.Text = "📂 Vault is empty!\n\nPaste an image URL above\nand click <b>Save</b> to store it.\n\n<font color='#B43CFF'>👉 Type <b>/helpphoto</b> for guide</font>" end
		sc.CanvasSize = UDim2.new(0, 0, 0, 130); return
	end

	sc.CanvasSize = UDim2.new(0, 0, 0, math.max(140, (math.ceil(cnt / 5) * 70) + 20))

	for _, item in ipairs(displayList) do
		local imgUrl = item.url
		local tile = Instance.new("ImageButton", sc)
		tile.Size = UDim2.new(0, 62, 0, 62); tile.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
		tile.ScaleType = Enum.ScaleType.Crop; tile.LayoutOrder = item.origIdx; tile.ZIndex = 72; tile.ClipsDescendants = false
		Instance.new("UICorner", tile).CornerRadius = UDim.new(0, 8)
		Instance.new("UIStroke", tile).Color = favs[imgUrl] and Color3.fromRGB(255, 200, 0) or t.StrokeColor
		ApplyWebImage(tile, imgUrl)

		local isFav = favs[imgUrl] and true or false
		local star = Instance.new("TextButton", tile)
		star.Size = UDim2.new(0, 20, 0, 20); star.Position = UDim2.new(0, -4, 0, -4)
		star.BackgroundColor3 = isFav and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(0, 0, 0)
		star.BackgroundTransparency = isFav and 0.1 or 0.4
		star.Text = isFav and "⭐" or "☆"; star.Font = Enum.Font.GothamBold; star.TextSize = 12
		star.TextColor3 = Color3.fromRGB(255, 255, 255); star.ZIndex = 74; star.AutoButtonColor = false
		Instance.new("UICorner", star).CornerRadius = UDim.new(1, 0)

		star.MouseButton1Click:Connect(function()
			local cf = GetDiskFavs()
			if cf[imgUrl] then cf[imgUrl] = nil; AxerChat.TriggerToast("⭐ Removed", "Removed from favorites", false)
			else cf[imgUrl] = true; AxerChat.TriggerToast("⭐ Favorited!", "Added to your favorites", false) end
			SaveDiskFavs(cf); AxerChat.RefreshVaultUI()
		end)

		local del = Instance.new("TextButton", tile)
		del.Size = UDim2.new(0, 18, 0, 18); del.Position = UDim2.new(1, -14, 0, -3)
		del.BackgroundColor3 = Color3.fromRGB(220, 45, 45); del.Text = "X"; del.Font = Enum.Font.GothamBold
		del.TextSize = 10; del.TextColor3 = Color3.fromRGB(255, 255, 255); del.ZIndex = 74
		Instance.new("UICorner", del).CornerRadius = UDim.new(1, 0)

		del.MouseButton1Click:Connect(function()
			local cv = GetDiskVault(); local cf = GetDiskFavs()
			for i = #cv, 1, -1 do if cv[i] == imgUrl then table.remove(cv, i) break end end
			cf[imgUrl] = nil; SaveDiskVault(cv); SaveDiskFavs(cf); AxerChat.RefreshVaultUI()
			AxerChat.TriggerToast("🗑️ Deleted", "Image removed from vault", false)
		end)

		tile.MouseButton1Click:Connect(function()
			AxerChat.Send("[MEDIA::" .. imgUrl .. "::MEDIA]")
			SmoothHideTray(AxerChat.UI.ImageTray)
		end)
	end
end

function AxerChat.DressInboxCard(card, itemKey, snippetText, unreadCount)
	local t = Themes[AxerChat.CurrentTheme]; local sl = card:FindFirstChild("Sub")
	if sl then local cl = GetHumanReadablePreview(snippetText); sl.Text = cl:sub(1,35) .. (#cl>35 and "..." or "") end
	local bd = card:FindFirstChild("AxerUnreadBadge")
	if unreadCount > 0 then
		if not bd then
			bd = Instance.new("Frame", card); bd.Size = UDim2.new(0, 64, 0, 22); bd.Position = UDim2.new(1, -74, 0.5, -11); bd.BackgroundColor3 = t.Accent; Instance.new("UICorner", bd).CornerRadius = UDim.new(0, 6)
			local bt = Instance.new("TextLabel", bd); bt.Size = UDim2.new(1,0,1,0); bt.BackgroundTransparency = 1; bt.Font = Enum.Font.GothamBold; bt.TextSize = 10; bt.TextColor3 = Color3.fromRGB(255,255,255)
		end
		bd.Txt.Text = (unreadCount >= 4) and "4+ New Msgs" or tostring(unreadCount) .. " New Msg"; card.BackgroundColor3 = t.Accent; card.BackgroundTransparency = 0.85
	else if bd then bd:Destroy() end card.BackgroundColor3 = t.OtherBubble; card.BackgroundTransparency = t.BubOtherTrans end
end

function AxerChat.RenderInboxCard(displayName, realUsername, partnerDbKey, lastMsgSnippet)
	local t = Themes[ThemeSequence[currentThemeIndex]]
	local Card = Instance.new("TextButton", AxerChat.UI.Scroll); Card.Name = "DM_Card_" .. partnerDbKey; Card.Size = UDim2.new(1,0,0,48); Card.BackgroundColor3 = t.OtherBubble; Card.BackgroundTransparency = t.BubOtherTrans; Card.Text = ""; Instance.new("UICorner", Card).CornerRadius = UDim.new(0,12)
	local DP = Instance.new("ImageLabel", Card); DP.Size = UDim2.new(0,34,0,34); DP.Position = UDim2.new(0,7,0,7); DP.BackgroundTransparency = 1; loadDP(DP, realUsername); Instance.new("UICorner", DP).CornerRadius = UDim.new(1,0)
	local NameL = Instance.new("TextLabel", Card); NameL.Name = "CardName"; NameL.Size = UDim2.new(1,-60,0,18); NameL.Position = UDim2.new(0,50,0,5); NameL.BackgroundTransparency = 1; NameL.Font = Enum.Font.GothamBold; NameL.TextSize = 13; NameL.TextColor3 = t.TextColor; NameL.TextXAlignment = Enum.TextXAlignment.Left; NameL.Text = displayName .. " (@" .. realUsername .. ")"
	local SnipL = Instance.new("TextLabel", Card); SnipL.Name = "Sub"; SnipL.Size = UDim2.new(1,-60,0,16); SnipL.Position = UDim2.new(0,50,0,25); SnipL.BackgroundTransparency = 1; SnipL.Font = Enum.Font.GothamMedium; SnipL.TextSize = 11; SnipL.TextColor3 = t.SubText; SnipL.TextXAlignment = Enum.TextXAlignment.Left
	Card.MouseButton1Click:Connect(function() AxerChat.SwitchMode("DM", partnerDbKey) end)
	AxerChat.DressInboxCard(Card, partnerDbKey, lastMsgSnippet, AxerChat.GetUnreadCount(partnerDbKey))
end

function AxerChat.RenderUserSearchCard(displayName, realUserName, userId)
	local t = Themes[ThemeSequence[currentThemeIndex]]
	local Card = Instance.new("Frame", AxerChat.UI.Scroll); Card.Name = "SearchCard_" .. realUserName; Card.Size = UDim2.new(1,0,0,52); Card.BackgroundColor3 = t.OtherBubble; Card.BackgroundTransparency = t.BubOtherTrans; Instance.new("UICorner", Card).CornerRadius = UDim.new(0,12); Instance.new("UIStroke", Card).Color = t.StrokeColor
	local DP = Instance.new("ImageLabel", Card); DP.Size = UDim2.new(0,36,0,36); DP.Position = UDim2.new(0,8,0,8); DP.BackgroundTransparency = 1; Instance.new("UICorner", DP).CornerRadius = UDim.new(1,0); DP.Image = "rbxthumb://type=AvatarHeadShot&id=" .. userId .. "&w=48&h=48"
	local DispL = Instance.new("TextLabel", Card); DispL.Name = "Disp"; DispL.Size = UDim2.new(1,-150,0,18); DispL.Position = UDim2.new(0,54,0,7); DispL.BackgroundTransparency = 1; DispL.Font = Enum.Font.GothamBold; DispL.TextSize = 13; DispL.TextColor3 = t.TextColor; DispL.TextXAlignment = Enum.TextXAlignment.Left; DispL.Text = displayName
	local UserL = Instance.new("TextLabel", Card); UserL.Name = "User"; UserL.Size = UDim2.new(1,-150,0,16); UserL.Position = UDim2.new(0,54,0,27); UserL.BackgroundTransparency = 1; UserL.Font = Enum.Font.GothamMedium; UserL.TextSize = 11; UserL.TextColor3 = t.SubText; UserL.TextXAlignment = Enum.TextXAlignment.Left; UserL.Text = "@" .. realUserName
	local DMBtn = Instance.new("TextButton", Card); DMBtn.Size = UDim2.new(0,68,0,30); DMBtn.Position = UDim2.new(1,-76,0.5,-15); DMBtn.BackgroundColor3 = t.Accent; DMBtn.Font = Enum.Font.GothamBold; DMBtn.TextSize = 12; DMBtn.TextColor3 = Color3.fromRGB(255,255,255); DMBtn.Text = "DM 💬"; Instance.new("UICorner", DMBtn).CornerRadius = UDim.new(0,8)
	DMBtn.MouseButton1Click:Connect(function() local tl = realUserName:lower(); AxerChat.RegisterAccount(realUserName, displayName, userId); AxerChat.Cache.DMs[tl] = AxerChat.Cache.DMs[tl] or {}; AxerChat.SwitchMode("DM", tl); AxerChat.UI.SearchInput.Text = "" end)
end

function AxerChat.TriggerToast(head, snip, isDM, dmTargetDbKey, senderUsername)
	local t = Themes[AxerChat.CurrentTheme]
	local Card = Instance.new("Frame"); Card.Size = UDim2.new(1, 0, 0, 54); Card.BackgroundColor3 = t.HeaderBg; Card.BackgroundTransparency = 1; Card.Position = UDim2.new(1, 60, 0, 0); Card.ZIndex = 200
	Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 12)
	local Stroke = Instance.new("UIStroke", Card); Stroke.Color = isDM and Color3.fromRGB(0, 220, 115) or t.Accent; Stroke.Transparency = 1; Stroke.Thickness = 1.2
	local Txt = Instance.new("TextLabel", Card); Txt.Size = UDim2.new(1, -20, 1, 0); Txt.Position = UDim2.new(0, 10, 0, 0); Txt.BackgroundTransparency = 1; Txt.Font = Enum.Font.GothamMedium; Txt.TextSize = 12
	Txt.TextColor3 = t.TextColor; Txt.TextTransparency = 1; Txt.TextXAlignment = Enum.TextXAlignment.Left; Txt.RichText = true
	Txt.Text = string.format("<b>%s</b>\n<font color='#888888'>%s</font>", head, GetHumanReadablePreview(snip):sub(1,30))
	local dpImg = nil
	if senderUsername then
		Txt.Size = UDim2.new(1, -56, 1, 0); Txt.Position = UDim2.new(0, 50, 0, 0)
		dpImg = Instance.new("ImageLabel", Card); dpImg.Size = UDim2.new(0, 34, 0, 34); dpImg.Position = UDim2.new(0, 8, 0.5, -17)
		dpImg.BackgroundTransparency = 1; dpImg.ImageTransparency = 1; Instance.new("UICorner", dpImg).CornerRadius = UDim.new(1, 0); loadDP(dpImg, senderUsername)
	end
	Card.Parent = ToastFrame
	TweenService:Create(Card, TweenInfo.new(0.42, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = t.HeadTrans}):Play()
	TweenService:Create(Stroke, TweenInfo.new(0.42, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Transparency = 0.15}):Play()
	TweenService:Create(Txt, TweenInfo.new(0.42, Enum.EasingStyle.Sine), {TextTransparency = 0}):Play()
	if dpImg then TweenService:Create(dpImg, TweenInfo.new(0.42, Enum.EasingStyle.Sine), {ImageTransparency = 0}):Play() end
	if isDM and dmTargetDbKey then
		local Btn = Instance.new("TextButton", Card); Btn.Size = UDim2.new(1, 0, 1, 0); Btn.BackgroundTransparency = 1; Btn.Text = ""
		Btn.MouseButton1Click:Connect(function() AxerChat.SwitchMode("DM", dmTargetDbKey); if not AxerChat.UI.MainBg.Visible then AxerChat.UI.MainBg.Visible = true end; Card:Destroy() end)
	end
	task.spawn(function()
		task.wait(4)
		if Card.Parent then
			local fadeOut = TweenService:Create(Card, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Position = UDim2.new(1, 60, 0, 0), BackgroundTransparency = 1})
			TweenService:Create(Stroke, TweenInfo.new(0.4), {Transparency = 1}):Play()
			TweenService:Create(Txt, TweenInfo.new(0.35), {TextTransparency = 1}):Play()
			if dpImg then TweenService:Create(dpImg, TweenInfo.new(0.35), {ImageTransparency = 1}):Play() end
			fadeOut:Play(); fadeOut.Completed:Wait(); Card:Destroy()
		end
	end)
end

function AxerChat.TriggerArrivalToast(arrName)
	local Card = Instance.new("Frame"); Card.Size = UDim2.new(1, 0, 0, 58); Card.BackgroundColor3 = Color3.fromRGB(28, 10, 45); Card.Position = UDim2.new(1, 60, 0, 0); Card.ZIndex = 200
	Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 12)
	local Stroke = Instance.new("UIStroke", Card); Stroke.Color = Color3.fromRGB(180, 60, 255); Stroke.Thickness = 1.5; Stroke.Transparency = 1
	local dpImg = Instance.new("ImageLabel", Card); dpImg.Size = UDim2.new(0, 34, 0, 34); dpImg.Position = UDim2.new(0, 10, 0.5, -17); dpImg.BackgroundTransparency = 1; dpImg.ImageTransparency = 1; dpImg.Image = "rbxassetid://92917449577250"
	Instance.new("UICorner", dpImg).CornerRadius = UDim.new(1, 0)
	local Txt = Instance.new("TextLabel", Card); Txt.Size = UDim2.new(1, -58, 1, 0); Txt.Position = UDim2.new(0, 54, 0, 0); Txt.BackgroundTransparency = 1; Txt.Font = Enum.Font.GothamMedium; Txt.TextSize = 11
	Txt.TextColor3 = Color3.fromRGB(255, 255, 255); Txt.TextXAlignment = Enum.TextXAlignment.Left; Txt.RichText = true; Txt.TextTransparency = 1
	Txt.Text = "<font color='#B43CFF'><b>ARIA</b></font>\nWelcome dear <b>" .. arrName .. "</b>!"
	Card.Parent = ToastFrame
	TweenService:Create(Card, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 0.1}):Play()
	TweenService:Create(Stroke, TweenInfo.new(0.4, Enum.EasingStyle.Sine), {Transparency = 0}):Play()
	TweenService:Create(Txt, TweenInfo.new(0.4, Enum.EasingStyle.Sine), {TextTransparency = 0}):Play()
	TweenService:Create(dpImg, TweenInfo.new(0.4, Enum.EasingStyle.Sine), {ImageTransparency = 0}):Play()
	task.spawn(function()
		task.wait(5.0)
		if Card.Parent then
			local fadeOut = TweenService:Create(Card, TweenInfo.new(0.48, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Position = UDim2.new(1, 60, 0, 0), BackgroundTransparency = 1})
			TweenService:Create(Stroke, TweenInfo.new(0.4), {Transparency = 1}):Play()
			TweenService:Create(Txt, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
			TweenService:Create(dpImg, TweenInfo.new(0.4), {ImageTransparency = 1}):Play()
			fadeOut:Play(); fadeOut.Completed:Wait(); Card:Destroy()
		end
	end)
end

local function ApplyPreciseTimelineCurvedTitle(dpImage, textString)
	if not dpImage or not dpImage.Parent then return end
	local pf = dpImage.Parent; local Arc = pf:FindFirstChild("AxerCurvedTitleArc"); if Arc then Arc:Destroy() end
	Arc = Instance.new("Frame"); Arc.Name = "AxerCurvedTitleArc"; Arc.Size = dpImage.Size; Arc.Position = dpImage.Position; Arc.AnchorPoint = dpImage.AnchorPoint; Arc.BackgroundTransparency = 1; Arc.ZIndex = dpImage.ZIndex + 5; Arc.Parent = pf
	local cc = #textString; local br = (dpImage.Size.X.Offset / 2) + 3.5; local sa = math.rad(-90 - (math.min((cc-1)*18, 160)/2)); local ea = math.rad(-90 + (math.min((cc-1)*18, 160)/2)); local cx, cy = dpImage.Size.X.Offset/2, dpImage.Size.Y.Offset/2
	local lTrack = {}
	for i = 1, cc do
		local curA = (cc > 1) and (sa + ((i-1)*(ea-sa)/(cc-1))) or sa
		local L = Instance.new("TextLabel", Arc); L.Size = UDim2.new(0, 14, 0, 14); L.AnchorPoint = Vector2.new(0.5, 0.5); L.Position = UDim2.new(0, cx + (math.cos(curA)*br), 0, cy + (math.sin(curA)*br)); L.BackgroundTransparency = 1; L.Text = textString:sub(i,i); L.Font = Enum.Font.GothamBold; L.TextSize = 8.5; L.TextColor3 = Color3.fromRGB(255, 255, 255); L.TextXAlignment = Enum.TextXAlignment.Center; L.Rotation = math.deg(curA) + 90
		local ug = Instance.new("UIGradient", L); ug.Rotation = 45; ug.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 195, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 60, 255))})
		table.insert(lTrack, {l = L, idx = i})
	end
	local tc = 10.0; local con
	con = RunService.Heartbeat:Connect(function()
		if not Arc or not Arc.Parent or getgenv().AxerChat_Unloading then con:Disconnect() return end
		local t = os.clock()
		for _, d in ipairs(lTrack) do
			local lt = (t - (d.idx * 0.22)) % tc
			d.l.TextTransparency = (lt < 5.0) and 0 or ((lt < 6.0) and ((1-math.cos((lt-5.0)*math.pi))/2) or ((lt < 9.0) and 1 or ((1+math.cos((lt-9.0)*math.pi))/2)))
		end
	end)
end

function AxerChat.LiveSyncAllVisibleBubblesTitle()
	for _, child in pairs(AxerChat.UI.Scroll:GetChildren()) do
		if child:IsA("Frame") and child:FindFirstChild("MessageBubble") then
			local dp = child:FindFirstChildWhichIsA("ImageLabel"); local bub = child.MessageBubble
			if dp and bub then
				local sn = ""; local nl = bub:FindFirstChild("SenderName")
				if nl then sn = nl.Text elseif bub.AnchorPoint.X == 1 then sn = LocalPlayer.Name end
				local ast = AxerChat.TitleRegistry[sn:lower()] or ((bub.AnchorPoint.X == 1 and LocalPlayer.UserId == 7169032620) and "CREATOR" or nil)
				if ast then ApplyPreciseTimelineCurvedTitle(dp, ast) else if dp.Parent:FindFirstChild("AxerCurvedTitleArc") then dp.Parent.AxerCurvedTitleArc:Destroy() end end
			end
		end
	end
end

function AxerChat.RenderBubble(senderUsername, rawUserId, rawText, timestamp, msg_id, isEditedFlag)
	local t = Themes[ThemeSequence[currentThemeIndex]]; local isMe = (string.lower(senderUsername) == string.lower(LocalPlayer.Name)); local isAria = (senderUsername == "ARIA")
	local repUser, repSnippet, cleanText = rawText:match("^%[RPL::(.-)::(.-)::RPL%]%s*(.*)"); if not repUser then cleanText = rawText end
	local isEdt = isEditedFlag or false; if cleanText:sub(1,5) == "[EDT]" then isEdt = true; cleanText = cleanText:sub(6) end

	local Wrap = Instance.new("Frame", AxerChat.UI.Scroll); Wrap.Size = UDim2.new(1,0,0,0); Wrap.AutomaticSize = Enum.AutomaticSize.Y; Wrap.BackgroundTransparency = 1
	if msg_id then AxerChat.ActiveBubbleNodes[msg_id] = Wrap end

	local DP = Instance.new("ImageLabel", Wrap); DP.Size = isAria and UDim2.new(0,32,0,32) or UDim2.new(0,26,0,26); DP.BackgroundTransparency = 1; loadDP(DP, senderUsername); Instance.new("UICorner", DP).CornerRadius = UDim.new(1,0); DP.AnchorPoint = isMe and Vector2.new(1,0) or Vector2.new(0,0); DP.Position = isMe and UDim2.new(1,0,0,0) or UDim2.new(0,0,0,0)

	local sl = senderUsername:lower()
	local isV = (tonumber(rawUserId) == 7169032620) or (sl == "venus_edit") or (AxerChat.VIPList and AxerChat.VIPList[sl])
	if not isAria then
		if AxerChat.VIPList[sl] then ApplyVIPCurvedTitle(DP)
		else
			local at = AxerChat.TitleRegistry[sl] or ((tonumber(rawUserId) == 7169032620) or (sl == "venus_edit") and "CREATOR" or nil)
			if at then ApplyPreciseTimelineCurvedTitle(DP, at) end
		end
	end

	local basePos = isMe and UDim2.new(1,-34,0,0) or (isAria and UDim2.new(0,42,0,0) or UDim2.new(0,34,0,0))
	local SwipeIcon = Instance.new("TextLabel", Wrap); SwipeIcon.Size=UDim2.new(0,30,0,30); SwipeIcon.BackgroundTransparency=1; SwipeIcon.Position=isMe and UDim2.new(0,-15,0.5,-15) or UDim2.new(1,-15,0.5,-15); SwipeIcon.Text="↩"; SwipeIcon.Font=Enum.Font.GothamBold; SwipeIcon.TextSize=16; SwipeIcon.TextColor3=t.SubText; SwipeIcon.TextTransparency=1

	local Bub = Instance.new("Frame", Wrap); Bub.Name = "MessageBubble"; Bub.AutomaticSize=Enum.AutomaticSize.XY; Bub.AnchorPoint=isMe and Vector2.new(1,0) or Vector2.new(0,0); Bub.Position=basePos; Bub.Active=true; Instance.new("UICorner", Bub).CornerRadius=UDim.new(0,14); Instance.new("UISizeConstraint", Bub).MaxSize=Vector2.new(330,9999)
	local BLayout = Instance.new("UIListLayout", Bub); BLayout.Padding=UDim.new(0,3); BLayout.SortOrder=Enum.SortOrder.LayoutOrder
	local Pad = Instance.new("UIPadding", Bub); Pad.PaddingTop=UDim.new(0,6); Pad.PaddingBottom=UDim.new(0,6); Pad.PaddingLeft=UDim.new(0,14); Pad.PaddingRight=UDim.new(0,14)
	Bub:SetAttribute("LiveText", cleanText)

	if not isMe then
		local acc = AxerChat.GetAccount(senderUsername)
		local N = Instance.new("TextLabel", Bub); N.Name="SenderName"; N.AutomaticSize=Enum.AutomaticSize.XY; N.BackgroundTransparency=1; N.Font=Enum.Font.GothamBold; N.TextSize=isAria and 12 or 10; N.TextColor3=isAria and Color3.fromRGB(180,60,255) or t.NameColor; N.Text=isAria and "ARIA" or acc.DisplayName; N.LayoutOrder=1
	end

	if repUser then
		local gAcc = AxerChat.GetAccount(repUser); local Ghost = Instance.new("Frame", Bub); Ghost.AutomaticSize=Enum.AutomaticSize.XY; Ghost.BackgroundColor3=t.TextColor; Ghost.BackgroundTransparency=0.88; Ghost.LayoutOrder=2; Instance.new("UICorner", Ghost).CornerRadius=UDim.new(0,6); local GPad=Instance.new("UIPadding", Ghost); GPad.PaddingLeft=UDim.new(0,12); GPad.PaddingRight=UDim.new(0,8); GPad.PaddingTop=UDim.new(0,4); GPad.PaddingBottom=UDim.new(0,4); local Line=Instance.new("Frame", Ghost); Line.Size=UDim2.new(0,3,1,0); Line.Position=UDim2.new(0,-8,0,0); Line.BackgroundColor3=t.Accent; Line.BackgroundTransparency=0.1; Line.BorderSizePixel=0; Instance.new("UICorner", Line).CornerRadius=UDim.new(0,2); local GTxt=Instance.new("TextLabel", Ghost); GTxt.AutomaticSize=Enum.AutomaticSize.XY; GTxt.BackgroundTransparency=1; GTxt.Font=Enum.Font.GothamMedium; GTxt.TextSize=10; GTxt.TextColor3=t.TextColor; GTxt.TextTransparency=0.1; GTxt.RichText=true; GTxt.Text=string.format("<b>%s</b>\n%s", gAcc.DisplayName, repSnippet)
	end

	local stkId = cleanText:match("%[STICKER://(%d+)%]"); local mediaUrl = cleanText:match("%[MEDIA::(.-)::MEDIA%]")
	local isMediaOnly = false
	if stkId then
		local StkBox = Instance.new("ImageLabel", Bub); StkBox.Size=UDim2.new(0,115,0,115); StkBox.BackgroundTransparency=1; StkBox.Image="rbxthumb://type=Asset&id="..stkId.."&w=150&h=150"; StkBox.ScaleType=Enum.ScaleType.Fit; StkBox.LayoutOrder=3
		if cleanText:match("^%s*%[STICKER://%d+%]%s*$") then isMediaOnly = true end
	elseif mediaUrl then
		local ImgWrapper = Instance.new("Frame", Bub); ImgWrapper.Size = UDim2.new(0, 220, 0, 170); ImgWrapper.BackgroundTransparency = 1; ImgWrapper.LayoutOrder = 3; ImgWrapper.ClipsDescendants = false
		local ImgBox = Instance.new("ImageButton", ImgWrapper); ImgBox.Size = UDim2.new(1, 0, 1, 0); ImgBox.BackgroundColor3 = Color3.fromRGB(20, 20, 22); ImgBox.BackgroundTransparency = 0.35; ImgBox.ScaleType = Enum.ScaleType.Crop; ImgBox.AutoButtonColor = false; ImgBox.ClipsDescendants = true
		Instance.new("UICorner", ImgBox).CornerRadius = UDim.new(0, 14)
		local imgStroke = Instance.new("UIStroke", ImgBox); imgStroke.Color = t.StrokeColor; imgStroke.Thickness = 1; imgStroke.Transparency = 0.3
		ApplyWebImage(ImgBox, mediaUrl)
		if cleanText:match("^%s*%[MEDIA::.-::MEDIA%]%s*$") then isMediaOnly = true end
		ImgBox.MouseButton1Click:Connect(function()
			if Screen:FindFirstChild("AxerFullscreenViewerModal") then return end
			local blur = Instance.new("BlurEffect", Lighting); blur.Name = "AxerCinematicBlur"; blur.Size = 22
			local Modal = Instance.new("Frame", Screen); Modal.Size = UDim2.new(1,0,1,0); Modal.BackgroundColor3 = Color3.fromRGB(0,0,0); Modal.BackgroundTransparency = 0.35; Modal.Active = true; Modal.ZIndex = 1000
			local BigWrap = Instance.new("Frame", Modal); BigWrap.Size = UDim2.new(0.85, 0, 0.85, 0); BigWrap.Position = UDim2.new(0.5, 0, 0.5, 0); BigWrap.AnchorPoint = Vector2.new(0.5, 0.5); BigWrap.BackgroundTransparency = 1; BigWrap.ClipsDescendants = false
			local BigImg = Instance.new("ImageLabel", BigWrap); BigImg.Size = UDim2.new(1, 0, 1, 0); BigImg.BackgroundTransparency = 1; BigImg.ScaleType = Enum.ScaleType.Fit; BigImg.ZIndex = 1001
			Instance.new("UICorner", BigImg).CornerRadius = UDim.new(0, 16)
			ApplyWebImage(BigImg, mediaUrl)
			local CloseBtn = Instance.new("TextButton", Modal); CloseBtn.Size = UDim2.new(0,44,0,44); CloseBtn.Position = UDim2.new(1,-58,0,35); CloseBtn.BackgroundColor3 = Color3.fromRGB(20,20,25); CloseBtn.Text = "X"; CloseBtn.Font = Enum.Font.GothamBold; CloseBtn.TextSize = 22; CloseBtn.TextColor3 = Color3.fromRGB(255,255,255); CloseBtn.ZIndex = 1002
			Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(1,0)
			CloseBtn.MouseButton1Click:Connect(function() if Lighting:FindFirstChild("AxerCinematicBlur") then Lighting.AxerCinematicBlur:Destroy() end; Modal:Destroy() end)
		end)
	else
		local MsgTxt = Instance.new("TextLabel", Bub); MsgTxt.Name="MainMessageText"; MsgTxt.AutomaticSize=Enum.AutomaticSize.XY; MsgTxt.BackgroundTransparency=1; MsgTxt.Font=Enum.Font.GothamMedium; MsgTxt.TextSize=13; MsgTxt.TextColor3=t.TextColor; MsgTxt.TextWrapped=true; MsgTxt.RichText=true; MsgTxt.TextXAlignment=Enum.TextXAlignment.Left; MsgTxt.Text=isEdt and (cleanText.."\n<font color='#888888' size='10'><i>(edited)</i></font>") or cleanText; MsgTxt.LayoutOrder=3
	end

	local bgCol = isMe and t.MyBubble or t.OtherBubble
	local bgTrans = isMe and t.BubMeTrans or t.BubOtherTrans
	Bub.BackgroundColor3 = bgCol; Bub.BackgroundTransparency = bgTrans
	Bub:SetAttribute("IsMediaOnly", isMediaOnly)
	if isV then Bub:SetAttribute("IsVIPBubble", true); ApplyVIPStyleToBubble(Bub, AxerChat.CurrentTheme)
	else
		local msgLbl = Bub:FindFirstChild("MainMessageText"); if msgLbl then msgLbl.TextColor3 = t.TextColor end
		local nameLbl = Bub:FindFirstChild("SenderName"); if nameLbl and nameLbl.Text ~= "ARIA" then nameLbl.TextColor3 = t.NameColor end
	end
	if isMediaOnly then Bub.BackgroundTransparency = 1 end

	local isHolding = false
	Bub.InputBegan:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then if isAria then return end; isHolding=true; task.delay(1.0, function() if isHolding and Bub.Parent then isHolding=false; AxerChat.OpenActionMenu(senderUsername, rawUserId, Bub:GetAttribute("LiveText") or cleanText, msg_id, isMe) end end) end end)
	Bub.InputEnded:Connect(function() isHolding=false end)

	local dragBub, sX = false, 0
	Bub.InputBegan:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then if not isAria and not AxerChat.ActiveSwipeBubble then AxerChat.ActiveSwipeBubble=Bub; dragBub=true; sX=inp.Position.X end end end)
	UserInputService.InputChanged:Connect(function(inp) if dragBub and AxerChat.ActiveSwipeBubble==Bub then if inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch then isHolding=false; local d=inp.Position.X-sX; if isMe and d<0 then local mX=math.max(d,-60); Bub.Position=basePos+UDim2.new(0,mX,0,0); SwipeIcon.TextTransparency=1-(math.abs(mX)/45) elseif not isMe and d>0 then local mX=math.min(d,60); Bub.Position=basePos+UDim2.new(0,mX,0,0); SwipeIcon.TextTransparency=1-(mX/45) end end end end)
	UserInputService.InputEnded:Connect(function(inp) if dragBub and AxerChat.ActiveSwipeBubble==Bub then if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then dragBub=false; AxerChat.ActiveSwipeBubble=nil; local d=inp.Position.X-sX; if (isMe and d<=-40) or (not isMe and d>=40) then AxerChat.SetReply(senderUsername, Bub:GetAttribute("LiveText") or cleanText, AxerChat.GetAccount(senderUsername).DisplayName) end; TweenService:Create(Bub, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position=basePos}):Play(); TweenService:Create(SwipeIcon, TweenInfo.new(0.2), {TextTransparency=1}):Play() end end end)

	DP.InputBegan:Connect(function(inp) if (inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch) and not isMe and not isAria then AxerChat.SwitchMode("DM", senderUsername:lower()) end end)
	AxerChat.HandleScroll(isMe)
end

function AxerChat.OpenActionMenu(senderUsername, rawUserId, cleanText, msg_id, isMe)
	if senderUsername == "ARIA" or AxerChat.UI.MainBg:FindFirstChild("AxerHoldActionMenu") then return end
	local acc = AxerChat.GetAccount(senderUsername); local trueDispName = acc.DisplayName; local rawMenuText = (cleanText:sub(1,5) == "[EDT]") and cleanText:sub(6) or cleanText; local t = Themes[ThemeSequence[currentThemeIndex]]
	local Overlay = Instance.new("Frame", AxerChat.UI.MainBg); Overlay.Name = "AxerHoldActionMenu"; Overlay.Size = UDim2.new(1,0,1,0); Overlay.BackgroundColor3 = Color3.fromRGB(0,0,0); Overlay.BackgroundTransparency = 1; Overlay.Active = true; Overlay.ZIndex = 85
	local isMedia = rawMenuText:match("^%[STICKER://") or rawMenuText:match("^%[MEDIA::"); local btnCount = 3; if isMe and msg_id then btnCount = btnCount + (isMedia and 1 or 2) end
	local Box = Instance.new("Frame", Overlay); Box.Size = UDim2.new(0, 260, 0, 75 + (btnCount * 34)); Box.Position = UDim2.new(0.5, 0, 0.5, 0); Box.AnchorPoint = Vector2.new(0.5, 0.5); Box.BackgroundColor3 = t.HeaderBg; Box.BackgroundTransparency = t.HeadTrans; Box.ZIndex = 86; Box.ClipsDescendants = true
	Instance.new("UICorner", Box).CornerRadius = UDim.new(0, 14); Instance.new("UIStroke", Box).Color = t.Accent
	local Layout = Instance.new("UIListLayout", Box); Layout.Padding = UDim.new(0, 4); Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center; Layout.SortOrder = Enum.SortOrder.LayoutOrder; Instance.new("UIPadding", Box).PaddingTop = UDim.new(0, 10)
	local Title = Instance.new("TextLabel", Box); Title.Size = UDim2.new(1, -20, 0, 22); Title.BackgroundTransparency = 1; Title.Font = Enum.Font.GothamBold; Title.TextSize = 12; Title.TextColor3 = t.SubText; Title.LayoutOrder = 1; Title.ZIndex = 87; Title.Text = "Options (" .. trueDispName .. ")"
	local desc = GetHumanReadablePreview(rawMenuText); local Snip = Instance.new("TextLabel", Box); Snip.Size = UDim2.new(1, -20, 0, 32); Snip.BackgroundTransparency = 1; Snip.Font = Enum.Font.GothamMedium; Snip.TextSize = 11; Snip.TextColor3 = t.TextColor; Snip.TextWrapped = true; Snip.LayoutOrder = 2; Snip.ZIndex = 87; Snip.Text = (desc == rawMenuText) and ('"' .. rawMenuText:sub(1,36) .. '..."') or desc

	local curOrder = 3
	local function makeBtn(name, icon, bgCol, action)
		local b = Instance.new("TextButton", Box); b.Size = UDim2.new(1, -30, 0, 30); b.BackgroundColor3 = bgCol; b.BackgroundTransparency = 0.15; b.Font = Enum.Font.GothamBold; b.TextSize = 12; b.TextColor3 = Color3.fromRGB(255,255,255); b.LayoutOrder = curOrder; b.ZIndex = 87; b.Text = icon .. " " .. name
		Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
		b.MouseButton1Click:Connect(function() action(); Overlay:Destroy() end); curOrder = curOrder + 1
	end
	makeBtn("Copy Text", "📋", Color3.fromRGB(35,110,200), function() local cp = setclipboard or toclipboard; if cp then cp(rawMenuText); AxerChat.TriggerToast("📋 Copied", "Text saved", false) end end)
	if isMe and msg_id and not isMedia then makeBtn("Edit Message", "✏️", Color3.fromRGB(210,130,30), function() AxerChat.StartEditing(msg_id, rawMenuText) end) end
	makeBtn("Reply", "↩️", t.Accent, function() AxerChat.SetReply(senderUsername, rawMenuText, trueDispName) end)
	if isMe and msg_id then makeBtn("Unsend", "🗑️", Color3.fromRGB(210,45,45), function() AxerChat.UnsendMsg(msg_id) end) end
	makeBtn("Cancel", "X", Color3.fromRGB(70,70,70), function() end)
	TweenService:Create(Overlay, TweenInfo.new(0.18), {BackgroundTransparency=0.5}):Play()
end

function AxerChat.UnsendMsg(msg_id)
	local myLower = LocalPlayer.Name:lower(); local hisLower = AxerChat.ActiveDM and AxerChat.ActiveDM:lower() or ""
	task.spawn(function()
		if AxerChat.Mode == "DM" and hisLower ~= "" then
			FB_DELETE("DMs/" .. myLower .. "/" .. hisLower .. "/" .. msg_id)
			FB_DELETE("DMs/" .. hisLower .. "/" .. myLower .. "/" .. msg_id)
		else FB_DELETE("servers/" .. REAL_JOB_ID .. "/chat/" .. msg_id) end
	end)
	AxerChat.TriggerToast("🗑️ Unsent", "Message recalled globally", false)
	if AxerChat.ActiveBubbleNodes[msg_id] then AxerChat.ActiveBubbleNodes[msg_id]:Destroy(); AxerChat.ActiveBubbleNodes[msg_id] = nil end
end

function AxerChat.StartEditing(msg_id, old_text)
	AxerChat.EditingMsgID = msg_id; AxerChat.UI.TextBox.Text = old_text; AxerChat.UI.ReplyIcon.Text = "✏️"; AxerChat.UI.ReplyText.Text = "Editing your message...\n" .. old_text:sub(1,28)
	AxerChat.UI.ReplyPreview.Visible = true; TweenService:Create(AxerChat.UI.ReplyPreview, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position=UDim2.new(0,10,1,-84)}):Play(); AxerChat.UI.TextBox:CaptureFocus()
end

function AxerChat.SetReply(senderUsername, text, senderTrueDisplayName)
	local snip = GetHumanReadablePreview(text); if #snip > 28 and not snip:match("^%[") then snip=snip:sub(1,28).."..." end
	AxerChat.ReplyingTo = {Username = senderUsername, DispName = senderTrueDisplayName, Text = snip}; AxerChat.UI.ReplyText.Text = "Replying to <b>" .. senderTrueDisplayName .. "</b>\n" .. snip; AxerChat.UI.ReplyIcon.Text = "↩"
	AxerChat.UI.ReplyPreview.Visible = true; TweenService:Create(AxerChat.UI.ReplyPreview, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position=UDim2.new(0,10,1,-84)}):Play(); AxerChat.UI.TextBox:CaptureFocus()
end

function AxerChat.CancelActionBar()
	AxerChat.ReplyingTo = nil; AxerChat.EditingMsgID = nil; local tw = TweenService:Create(AxerChat.UI.ReplyPreview, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position=UDim2.new(0,10,1,-46)})
	tw:Play(); task.spawn(function() tw.Completed:Wait(); AxerChat.UI.ReplyPreview.Visible=false end)
end

function AxerChat.HandleScroll(forceBottom)
	task.spawn(function()
		RunService.RenderStepped:Wait(); RunService.RenderStepped:Wait()
		local maxS = AxerChat.UI.Scroll.CanvasSize.Y.Offset - AxerChat.UI.Scroll.AbsoluteWindowSize.Y
		if maxS <= 0 then return end
		local hyperGlide = TweenInfo.new(0.38, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
		if forceBottom then TweenService:Create(AxerChat.UI.Scroll, hyperGlide, {CanvasPosition = Vector2.new(0, maxS)}):Play(); AxerChat.UI.JumpBtn.Visible = false
		elseif AxerChat.UI.Scroll.CanvasPosition.Y < (maxS - 50) then AxerChat.UI.JumpBtn.Visible = true
		else TweenService:Create(AxerChat.UI.Scroll, hyperGlide, {CanvasPosition = Vector2.new(0, maxS)}):Play() end
	end)
end

function AxerChat.LiveUpdateInboxSort()
	if AxerChat.Mode ~= "DM_Inbox" then return end
	local sList = {}
	for pl, msgs in pairs(AxerChat.Cache.DMs) do table.insert(sList, {k = pl, t = msgs[#msgs] and msgs[#msgs].Time or 0, s = msgs[#msgs] and msgs[#msgs].Msg or "Start secure chat...", u = AxerChat.GetUnreadCount(pl)}) end
	table.sort(sList, function(a, b) return a.t > b.t end)
	for idx, item in ipairs(sList) do
		local c = AxerChat.UI.Scroll:FindFirstChild("DM_Card_" .. item.k)
		if c then c.LayoutOrder = idx; AxerChat.DressInboxCard(c, item.k, item.s, item.u) else local acc = AxerChat.GetAccount(item.k); AxerChat.RenderInboxCard(acc.DisplayName, acc.Username, item.k, item.s) end
	end
end

function AxerChat.SwitchMode(mode, targetUsernameLower)
	AxerChat.Mode = mode; AxerChat.ActiveDM = targetUsernameLower and targetUsernameLower:lower() or nil
	for _, c in pairs(AxerChat.UI.Scroll:GetChildren()) do if c:IsA("Frame") or c:IsA("TextButton") then c:Destroy() end end
	AxerChat.ActiveBubbleNodes = {}; AxerChat.MessagesCount = 0

	if mode == "Server" then
		AxerChat.UI.HeaderDP.Visible = false; AxerChat.UI.Title.Text = "AXER CHAT"; AxerChat.UI.Title.Position = UDim2.new(0,15,0,0)
		AxerChat.UI.Back.Visible=false; AxerChat.UI.InboxBtn.Visible=true; AxerChat.UI.MuteBtn.Visible=true
		AxerChat.UI.SearchWrapper.Visible = false
		AxerChat.UI.SearchInput.Text = ""
		AxerChat.UI.InputWrapper.Visible=true; AxerChat.UI.StickerBtn.Visible=true; AxerChat.UI.ImageBtn.Visible=true
		AxerChat.UI.Scroll.Position=UDim2.new(0,0,0,34); AxerChat.UI.Scroll.Size=UDim2.new(1,0,1,-80)
		AxerChat.UI.TextBox.PlaceholderText = AxerChat.IsLocked and "🔒 CHAT LOCKED BY ADMIN" or "Type message..."
		for _, m in pairs(AxerChat.Cache.Server) do AxerChat.RenderBubble(m.Sender, m.UserID, m.Msg, m.Time, m.ID, m.Edited) end
	elseif mode == "DM_Inbox" then
		AxerChat.UI.HeaderDP.Visible = false; AxerChat.UI.Title.Text = "DM Inbox"; AxerChat.UI.Title.Position = UDim2.new(0,35,0,0)
		AxerChat.UI.Back.Visible=true; AxerChat.UI.InboxBtn.Visible=false; AxerChat.UI.MuteBtn.Visible=false
		AxerChat.UI.InputWrapper.Visible=false; AxerChat.UI.ReplyPreview.Visible=false; AxerChat.UI.StickerTray.Visible=false; AxerChat.UI.ImageTray.Visible=false
		AxerChat.UI.SearchWrapper.Visible = true
		AxerChat.UI.SearchWrapper.Position = UDim2.new(0,10,0,40)
		AxerChat.UI.Scroll.Position=UDim2.new(0,0,0,82); AxerChat.UI.Scroll.Size=UDim2.new(1,0,1,-88)
		local sList = {}
		for pl, msgs in pairs(AxerChat.Cache.DMs) do local acc = AxerChat.GetAccount(pl); table.insert(sList, {k = pl, d = acc.DisplayName, u = acc.Username, s = msgs[#msgs] and msgs[#msgs].Msg or "Tap to chat...", t = msgs[#msgs] and msgs[#msgs].Time or 0}) end
		table.sort(sList, function(a, b) return a.t > b.t end)
		for idx, item in ipairs(sList) do AxerChat.RenderInboxCard(item.d, item.u, item.k, item.s); local c = AxerChat.UI.Scroll:FindFirstChild("DM_Card_" .. item.k); if c then c.LayoutOrder = idx end end
	elseif mode == "DM" then
		AxerChat.SetLastRead(targetUsernameLower, GetUniverseTimestamp()); local acc = AxerChat.GetAccount(targetUsernameLower)
		AxerChat.UI.HeaderDP.Visible = true; loadDP(AxerChat.UI.HeaderDP, acc.Username)
		AxerChat.UI.Title.Text = acc.DisplayName .. " (@" .. acc.Username .. ")"; AxerChat.UI.Title.Position = UDim2.new(0, 68, 0, 0)
		AxerChat.UI.Back.Visible=true; AxerChat.UI.InboxBtn.Visible=true; AxerChat.UI.MuteBtn.Visible=false
		AxerChat.UI.SearchWrapper.Visible = false
		AxerChat.UI.InputWrapper.Visible=true; AxerChat.UI.StickerBtn.Visible=true; AxerChat.UI.ImageBtn.Visible=true
		AxerChat.UI.Scroll.Position=UDim2.new(0,0,0,34); AxerChat.UI.Scroll.Size=UDim2.new(1,0,1,-80)
		AxerChat.UI.TextBox.PlaceholderText = AxerChat.IsLocked and "🔒 CHAT LOCKED BY ADMIN" or ("DM to " .. acc.DisplayName .. "...")
		if AxerChat.Cache.DMs[targetUsernameLower] then for _, m in pairs(AxerChat.Cache.DMs[targetUsernameLower]) do AxerChat.RenderBubble(m.Sender, m.UserID, m.Msg, m.Time, m.ID, m.Edited) end end
	end
	AxerChat.HandleScroll(true)
end

function AxerChat.Send(txt)
	if AxerChat.IsLocked then return end
	local myLower = LocalPlayer.Name:lower()
	if AxerChat.ReplyingTo then txt = string.format("[RPL::%s::%s::RPL] %s", AxerChat.ReplyingTo.Username, AxerChat.ReplyingTo.Text, txt) end
	local function isImgUrl(s) local l=s:lower() return l:match("^https?://.+") and (l:find("%.png") or l:find("%.jpg") or l:find("%.jpeg") or l:find("%.webp") or l:find("%.gif")) end
	if isImgUrl(txt) and not txt:match("^%[MEDIA::") then txt = "[MEDIA::" .. txt .. "::MEDIA]" end
	local isDM, hisLower = (AxerChat.Mode == "DM"), AxerChat.ActiveDM or ""
	local packetID = "M_" .. LocalPlayer.UserId .. "_" .. os.time() .. "_" .. math.random(1000, 9999)
	local key = isDM and getDMKey(myLower, hisLower) or getSrvPfx() .. REAL_JOB_ID
	local ciph, sign = SecureEncrypt(key, txt); local newTime = GetUniverseTimestamp()
	AxerChat.PendingCommitGrace[packetID] = os.clock()
	local payload = HttpService:JSONEncode({ u = LocalPlayer.UserId, s = LocalPlayer.Name, m = ciph, sign = sign, t = newTime })
	if isDM then
		FB_PUT_SYNC("DMs/" .. myLower .. "/" .. hisLower .. "/" .. packetID, payload, true)
		FB_PUT_SYNC("DMs/" .. hisLower .. "/" .. myLower .. "/" .. packetID, payload, true)
		AxerChat.SetLastRead(hisLower, newTime)
	else BroadcastToFirebase(LocalPlayer.Name, txt, false, nil, false, false) end
	AxerChat.SeenIDs[packetID] = sign; local targetCache = isDM and AxerChat.Cache.DMs[hisLower] or AxerChat.Cache.Server
	if targetCache then table.insert(targetCache, {Sender = LocalPlayer.Name, UserID = LocalPlayer.UserId, Msg = txt, Time = newTime, ID = packetID, Edited = false}) end
	if not isDM and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head") then pcall(function() game:GetService("Chat"):Chat(LocalPlayer.Character.Head, GetHumanReadablePreview(txt), Enum.ChatColor.White) end) end
	AxerChat.RenderBubble(LocalPlayer.Name, LocalPlayer.UserId, txt, newTime, packetID, false)
end

function AxerChat.SubmitEdit(msg_id, new_text)
	local isDM, hisLower = (AxerChat.Mode == "DM"), AxerChat.ActiveDM or ""; local myLower = LocalPlayer.Name:lower()
	local key = isDM and getDMKey(myLower, hisLower) or getSrvPfx() .. REAL_JOB_ID; local ciph, sign = SecureEncrypt(key, "[EDT]" .. new_text); local newTime = GetUniverseTimestamp()
	for _, itm in ipairs((isDM and AxerChat.Cache.DMs[hisLower] or AxerChat.Cache.Server) or {}) do if itm.ID == msg_id then itm.Msg=new_text; itm.Edited=true break end end
	AxerChat.SeenIDs[msg_id] = sign; local payload = HttpService:JSONEncode({ u = LocalPlayer.UserId, s = LocalPlayer.Name, m = ciph, sign = sign, t = newTime })
	if isDM then
		FB_PUT_SYNC("DMs/" .. myLower .. "/" .. hisLower .. "/" .. msg_id, payload, true)
		FB_PUT_SYNC("DMs/" .. hisLower .. "/" .. myLower .. "/" .. msg_id, payload, true)
	end
	local node = AxerChat.ActiveBubbleNodes[msg_id]; if node and node:FindFirstChild("MessageBubble") then node.MessageBubble:SetAttribute("LiveText", new_text); if node.MessageBubble:FindFirstChild("MainMessageText") then node.MessageBubble.MainMessageText.Text=new_text.."\n<font color='#888888' size='10'><i>(edited)</i></font>" end end
end

local lastFirebaseKey = ""
local firebaseInitialFetch = false

task.spawn(function()
    while task.wait(1.5) do
        if getgenv().AxerChat_Unloading then break end
        local response = makeHttpRequest({ Url = FIREBASE_URL .. FIREBASE_SERVER_PATH .. "?orderBy=\"$key\"&limitToLast=15", Method = "GET" })
        if response and response.StatusCode == 200 then
            local ok, data = pcall(function() return HttpService:JSONDecode(response.Body) end)
            if ok and type(data) == "table" then
                local sortedPackets = {}
                for key, packet in pairs(data) do table.insert(sortedPackets, {key = key, val = packet}) end
                table.sort(sortedPackets, function(a, b) return a.key < b.key end)
                for _, entry in ipairs(sortedPackets) do
                    if entry.key > lastFirebaseKey then
                        lastFirebaseKey = entry.key
                        if firebaseInitialFetch and entry.val.sender ~= LocalPlayer.Name then
                            local sender = entry.val.sender; local text = entry.val.text
                            local isJoin = entry.val.isJoin or false; local isAdminJoin = entry.val.isAdminJoin or false
                            local timestamp = entry.val.timestamp or os.time(); local msgID = "FIREBASE_" .. entry.key
                            if isAdminJoin and entry.val.isSystem then
                                if not AxerChat.AdminJoinAlreadyDone then
                                    table.insert(AxerChat.Cache.Server, {Sender = "ARIA", UserID = 0, Msg = text, Time = timestamp, ID = msgID, Edited = false})
                                    if #AxerChat.Cache.Server > 100 then table.remove(AxerChat.Cache.Server, 1) end
                                    if AxerChat.Mode == "Server" and AxerChat.UI.MainBg and AxerChat.UI.MainBg.Visible then AxerChat.RenderBubble("ARIA", 0, text, timestamp, msgID, false) end
                                end
                            elseif isJoin then
                                local userId = 0; local p = Players:FindFirstChild(sender); if p then userId = p.UserId end
                                table.insert(AxerChat.Cache.Server, {Sender = sender, UserID = userId, Msg = text, Time = timestamp, ID = msgID, Edited = false})
                                if #AxerChat.Cache.Server > 100 then table.remove(AxerChat.Cache.Server, 1) end
                                if AxerChat.Mode == "Server" and AxerChat.UI.MainBg and AxerChat.UI.MainBg.Visible then AxerChat.RenderBubble(sender, userId, text, timestamp, msgID, false)
                                else AxerChat.TriggerToast("👤 Player Joined", text, false, nil, sender) end
                            elseif not entry.val.isSystem then
                                local userId = 0; local p = Players:FindFirstChild(sender); if p then userId = p.UserId end
                                table.insert(AxerChat.Cache.Server, {Sender = sender, UserID = userId, Msg = text, Time = timestamp, ID = msgID, Edited = false})
                                if #AxerChat.Cache.Server > 100 then table.remove(AxerChat.Cache.Server, 1) end
                                if AxerChat.Mode == "Server" and AxerChat.UI.MainBg and AxerChat.UI.MainBg.Visible then AxerChat.RenderBubble(sender, userId, text, timestamp, msgID, false)
                                else AxerChat.TriggerToast("🌐 Server Chat", sender .. ": " .. text, false, nil, sender) end
                            end
                        end
                    end
                end
                firebaseInitialFetch = true
            end
        end
    end
end)

function AxerChat.StartPolling()
	task.spawn(function()
		local myLower = LocalPlayer.Name:lower()
		local snapDM = FB_GET("DMs/" .. myLower)
		if typeof(snapDM) == "table" then
			for pl, msgs in pairs(snapDM) do
				if typeof(msgs) == "table" then
					AxerChat.Cache.DMs[pl] = AxerChat.Cache.DMs[pl] or {}; local dmKey = getDMKey(myLower, pl); local preDM = {}
					for m_id, p in pairs(msgs) do
						if m_id ~= "_typ" and typeof(p) == "table" and tonumber(p.t) then
							if (GetUniverseTimestamp() - tonumber(p.t)) > ONE_WEEK_SECONDS then task.spawn(function() FB_DELETE("DMs/" .. myLower .. "/" .. pl .. "/" .. m_id) end)
							else
								AxerChat.SeenIDs[m_id] = p.sign; if p.s and p.u then AxerChat.RegisterAccount(p.s, nil, p.u) end
								local dec = SecureDecrypt(dmKey, p.m, p.sign); if dec then table.insert(preDM, {Sender = p.s, UserID = p.u, Msg = (dec:sub(1,5) == "[EDT]") and dec:sub(6) or dec, Time = tonumber(p.t), ID = m_id, Edited = (dec:sub(1,5) == "[EDT]")}) end
							end
						end
					end
					table.sort(preDM, function(a, b) return a.Time < b.Time end)
					for _, itm in ipairs(preDM) do table.insert(AxerChat.Cache.DMs[pl], itm) end
				end
			end
		end

		while task.wait(1.5) do
			if getgenv().AxerChat_Unloading then break end
			if not Screen or not Screen.Parent then break end
			local now = GetUniverseTimestamp(); local isGuiVisible = (AxerChat.UI.MainBg and AxerChat.UI.MainBg.Visible)
			local dData = FB_GET("DMs/" .. myLower)
			if dData then
				for pl, msgs in pairs(dData) do
					AxerChat.Cache.DMs[pl] = AxerChat.Cache.DMs[pl] or {}; local dmKey = getDMKey(myLower, pl); local admk = {}
					if not AxerChat.AccountRegistry[pl] then task.spawn(function() local uid = Players:GetUserIdFromNameAsync(pl); local d = pl; if UserService and uid then pcall(function() d = UserService:GetUserInfosByUserIdsAsync({tonumber(uid)})[1].DisplayName end) end; AxerChat.RegisterAccount(pl, d, uid) end) end

					for m_id, pkt in pairs(msgs) do
						admk[m_id] = true; if m_id == "_typ" then continue end
						local pkt_t = tonumber(typeof(pkt)=="table" and pkt.t or 0)
						if now - pkt_t > ONE_WEEK_SECONDS then
							task.spawn(function() FB_DELETE("DMs/" .. myLower .. "/" .. pl .. "/" .. m_id); FB_DELETE("DMs/" .. pl .. "/" .. myLower .. "/" .. m_id) end)
							if AxerChat.ActiveBubbleNodes[m_id] then AxerChat.ActiveBubbleNodes[m_id]:Destroy(); AxerChat.ActiveBubbleNodes[m_id]=nil end
							continue
						end
						if typeof(pkt)=="table" and AxerChat.SeenIDs[m_id] ~= pkt.sign and pkt.m and pkt.sign then
							local isK = (AxerChat.SeenIDs[m_id] ~= nil); AxerChat.SeenIDs[m_id] = pkt.sign; if pkt.s and pkt.u then AxerChat.RegisterAccount(pkt.s, nil, pkt.u) end
							local plain = SecureDecrypt(dmKey, pkt.m, pkt.sign)
							if plain then
								local isEdt = (plain:sub(1,5) == "[EDT]"); local trueText = isEdt and plain:sub(6) or plain
								local isKeywordMuted = false
								for kw, _ in pairs(AxerChat.MutedKeywords) do if string.find(string.lower(trueText), kw) then isKeywordMuted = true; break end end
								if isKeywordMuted and pkt.s:lower() ~= LocalPlayer.Name:lower() then continue end
								if isK then
									for _, itm in ipairs(AxerChat.Cache.DMs[pl]) do if itm.ID == m_id then itm.Msg=trueText; itm.Edited=true break end end
									if AxerChat.ActiveBubbleNodes[m_id] and AxerChat.ActiveBubbleNodes[m_id]:FindFirstChild("MessageBubble") then AxerChat.ActiveBubbleNodes[m_id].MessageBubble:SetAttribute("LiveText", trueText); if AxerChat.ActiveBubbleNodes[m_id].MessageBubble:FindFirstChild("MainMessageText") then AxerChat.ActiveBubbleNodes[m_id].MessageBubble.MainMessageText.Text=trueText.."\n<font color='#888888' size='10'><i>(edited)</i></font>" end end
								else
									table.insert(AxerChat.Cache.DMs[pl], {Sender=pkt.s, UserID=pkt.u, Msg=trueText, Time=pkt_t, ID=m_id, Edited=isEdt})
									if isGuiVisible and AxerChat.Mode=="DM" and AxerChat.ActiveDM==pl then AxerChat.RenderBubble(pkt.s, pkt.u, trueText, pkt_t, m_id, isEdt); AxerChat.SetLastRead(pl, GetUniverseTimestamp())
									else AxerChat.TriggerToast("💬 DM : "..AxerChat.GetAccount(pl).DisplayName, trueText, true, pl, pkt.s) end
								end
							end
						end
					end
					if AxerChat.Mode == "DM" and AxerChat.ActiveDM == pl then
						for aid, n in pairs(AxerChat.ActiveBubbleNodes) do
							if not admk[aid] and aid~="_typ" then
								if not (AxerChat.PendingCommitGrace[aid] and os.clock()-AxerChat.PendingCommitGrace[aid]<45) then n:Destroy(); AxerChat.ActiveBubbleNodes[aid]=nil end
							elseif admk[aid] then AxerChat.PendingCommitGrace[aid]=nil end
						end
					end
				end
			end
			AxerChat.LiveUpdateInboxSort(); VerifyMetatableIntegrity()
		end
	end)
end

function AxerChat.UpdateThemeAnimated()
	local t = Themes[ThemeSequence[currentThemeIndex]]; local twInfo = TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	TweenService:Create(AxerChat.UI.MainBg, twInfo, {BackgroundColor3=t.MainBg, BackgroundTransparency=t.BgTrans}):Play(); TweenService:Create(AxerChat.UI.MainStroke, twInfo, {Color=t.StrokeColor}):Play()
	TweenService:Create(AxerChat.UI.HeaderBg, twInfo, {BackgroundColor3=t.HeaderBg, BackgroundTransparency=t.HeadTrans}):Play()
	TweenService:Create(AxerChat.UI.InputWrapper, twInfo, {BackgroundColor3=t.InputBg, BackgroundTransparency=t.InpTrans}):Play()
	TweenService:Create(AxerChat.UI.SearchWrapper, twInfo, {BackgroundColor3=t.InputBg, BackgroundTransparency=t.InpTrans}):Play()
	TweenService:Create(AxerChat.UI.ReplyPreview, twInfo, {BackgroundColor3=t.InputBg, BackgroundTransparency=t.InpTrans}):Play()
	if AxerChat.UI.StickerTray then TweenService:Create(AxerChat.UI.StickerTray, twInfo, {BackgroundColor3=t.HeaderBg}):Play(); if AxerChat.UI.StickerTray:FindFirstChild("UIStroke") then TweenService:Create(AxerChat.UI.StickerTray.UIStroke, twInfo, {Color=t.Accent}):Play() end end
	if AxerChat.UI.ImageTray then TweenService:Create(AxerChat.UI.ImageTray, twInfo, {BackgroundColor3=t.HeaderBg}):Play(); if AxerChat.UI.ImageTray:FindFirstChild("UIStroke") then TweenService:Create(AxerChat.UI.ImageTray.UIStroke, twInfo, {Color=t.Accent}):Play() end end
	AxerChat.UI.Title.TextColor3=t.TextColor; AxerChat.UI.TextBox.TextColor3=AxerChat.IsLocked and Color3.fromRGB(255,80,80) or t.TextColor; AxerChat.UI.TextBox.PlaceholderColor3=t.SubText; AxerChat.UI.SearchInput.TextColor3=t.TextColor; AxerChat.UI.SearchInput.PlaceholderColor3=t.SubText; AxerChat.UI.ReplyText.TextColor3=t.SubText; AxerChat.UI.CancelRep.TextColor3=t.SubText
	AxerChat.UI.ThemeBtn.BackgroundColor3=t.InputBg; AxerChat.UI.InboxBtn.BackgroundColor3=t.InputBg; AxerChat.UI.MuteBtn.BackgroundColor3=t.InputBg; AxerChat.UI.StickerBtn.BackgroundColor3=t.HeaderBg; AxerChat.UI.ImageBtn.BackgroundColor3=t.HeaderBg
	AxerChat.UI.SendBtn.BackgroundColor3=AxerChat.IsLocked and Color3.fromRGB(80,20,20) or t.Accent
	if AxerChat.UI.AdminBtn then TweenService:Create(AxerChat.UI.AdminBtn, twInfo, {BackgroundColor3=t.InputBg}):Play() end
	if AxerChat.UI.AdminTray then TweenService:Create(AxerChat.UI.AdminTray, twInfo, {BackgroundColor3=t.HeaderBg}):Play(); TweenService:Create(AxerChat.UI.AdminSearch, twInfo, {BackgroundColor3=t.InputBg, TextColor3=t.TextColor, PlaceholderColor3=t.SubText}):Play() end
	for _, child in pairs(AxerChat.UI.Scroll:GetChildren()) do
		if child:IsA("Frame") and child:FindFirstChild("MessageBubble") then
			local bub = child.MessageBubble
			local isMe = (bub.AnchorPoint.X == 1)
			local bgCol = isMe and t.MyBubble or t.OtherBubble
			local bgTrans = isMe and t.BubMeTrans or t.BubOtherTrans
			if bub:GetAttribute("IsVIPBubble") then ApplyVIPStyleToBubble(bub, AxerChat.CurrentTheme)
			else
				TweenService:Create(bub, twInfo, {BackgroundColor3=bgCol, BackgroundTransparency=bgTrans}):Play()
				if bub:FindFirstChild("MainMessageText") then bub.MainMessageText.TextColor3 = t.TextColor end
				if bub:FindFirstChild("SenderName") and bub.SenderName.Text~="ARIA" then bub.SenderName.TextColor3 = t.NameColor end
			end
			if bub:GetAttribute("IsMediaOnly") then bub.BackgroundTransparency = 1 end
		elseif child.Name:match("^DM_Card_") or child.Name:match("^SearchCard_") then
			if child:FindFirstChild("AxerUnreadBadge") then TweenService:Create(child, twInfo, {BackgroundColor3=t.Accent}):Play() else TweenService:Create(child, twInfo, {BackgroundColor3=t.OtherBubble, BackgroundTransparency=t.BubOtherTrans}):Play() end
			if child:FindFirstChild("CardName") then child.CardName.TextColor3=t.TextColor end; if child:FindFirstChild("Sub") then child.Sub.TextColor3=t.SubText end
		end
	end
	AxerChat.SyncNativeRobloxBubbleSettings(); AxerChat.LiveSyncAllVisibleBubblesTitle()
end

AxerChat.BuildMasterUI()
AxerChat.StartPolling()
StartAnnouncementPolling()

task.spawn(function()
    local isAdmin = IsStrictAdmin()
    local customWelcome = "👑 Axer Chat's Creator has entered the server!\nSIR AXER HAS ENTERED!"
    local normalWelcome = "Welcome dear " .. LocalPlayer.DisplayName .. "!"
    local wTxt = isAdmin and customWelcome or normalWelcome
    local ariaLocalID = "SYS_LOCAL_ARIA_" .. LocalPlayer.UserId
    table.insert(AxerChat.Cache.Server, {Sender="ARIA", UserID=0, Msg=wTxt, Time=os.time(), ID=ariaLocalID, Edited=false})
    if AxerChat.Mode == "Server" and AxerChat.UI.MainBg.Visible then AxerChat.RenderBubble("ARIA", 0, wTxt, os.time(), ariaLocalID, false) end
    AxerChat.TriggerArrivalToast(LocalPlayer.DisplayName)
    if isAdmin and not AxerChat.AdminJoinAlreadyDone then BroadcastAdminJoin(); task.wait(1); PlayAdminJoinAudio()
    else BroadcastNormalJoin() end
    task.wait(0.5)
    FB_PUT("Srv/" .. REAL_JOB_ID .. "/SYS_NET_ARRIVAL_" .. LocalPlayer.UserId .. "_" .. os.time(), { u = LocalPlayer.UserId, s = "SYS_ARIA_ARRIVAL", m = LocalPlayer.DisplayName, sign = "ARR_SECURE_" .. os.time(), t = os.time() })
end)

local flyEnabled = false
local flyConnection = nil
local flyBodyVelocity = nil
local lastPosition = nil
local viewTarget = nil

local function findPlayerByName(name)
    if not name or name == "" then return nil end
    local lower = name:lower()
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name:lower() == lower or p.DisplayName:lower() == lower then return p end
    end
    return nil
end

local function getCharRoot(char)
    if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart")
    if root then return root end
    local head = char:FindFirstChild("Head")
    if head then return head end
    return nil
end

local function getHumanoid(char) if not char then return nil end return char:FindFirstChildOfClass("Humanoid") end

local function CommitMessage()
	if AxerChat.IsLocked then return end
	local txt = AxerChat.UI.TextBox.Text
	if txt ~= "" then
		if string.len(txt) > 200 then AxerChat.TriggerAriaLocal("⚠️ <b>Limit Exceeded!</b>\nYour message contains over 200 alphabets/characters. Keep it short!"); return end
		if string.lower(txt) == string.lower(AxerChat.LastSentMessage) then AxerChat.TriggerAriaLocal("⚠️ <b>Spam Alert!</b>\nYou cannot send the exact same message repeatedly."); return end
		local nowTime = os.clock()
		local recent = {}
		for _, t in ipairs(AxerChat.MessageTimestamps) do if nowTime - t <= 3.0 then table.insert(recent, t) end end
		AxerChat.MessageTimestamps = recent
		if #AxerChat.MessageTimestamps >= 5 then AxerChat.TriggerAriaLocal("⚠️ <b>Spam Blocked!</b>\nYou are typing too fast! (Limit: 5 messages per 3 seconds)"); return end

		AxerChat.UI.TextBox.Text = ""; AxerChat.LastSentMessage = txt
		table.insert(AxerChat.MessageTimestamps, os.clock())

		if txt:lower():match("^/time$") or txt:lower():match("^/time ") then
			AxerChat.CancelActionBar()
			AxerChat.TriggerAriaLocal("🕐 **Your Current Time:**\n" .. os.date("%A, %B %d, %Y") .. "\n" .. os.date("%I:%M:%S %p"))
			return
		end

		local cmdLower = txt:lower()
		if cmdLower:match("^/help$") or cmdLower:match("^/help ") then
			AxerChat.CancelActionBar()
			local isAdmin = IsStrictAdmin()
			local helpMsg = "📚 <b>Available Commands:</b>\n\n<b>📌 Utility:</b>\n/help, /time, /helpphoto, /respawn\n\n<b>✈️ Movement:</b>\n/fly, /to &lt;player&gt;, /back\n\n<b>👁️ Camera:</b>\n/view &lt;player&gt;, /unview\n"
			if isAdmin then helpMsg = helpMsg .. "\n<b>👑 Admin:</b>\n/announce, /vip, /unvip, /title, /untitle"
			else helpMsg = helpMsg .. "\n<font color='#B43CFF'>Admin commands hidden.</font>" end
			AxerChat.TriggerAriaLocal(helpMsg)
			return
		end

		local announceText = txt:match("^/announce%s+(.+)$")
		if announceText then
			AxerChat.CancelActionBar()
			if IsStrictAdmin() then SendAnnouncement(announceText)
			else AxerChat.TriggerAriaLocal("❌ <b>Access Denied</b>\nOnly admins can send cross-server announcements.") end
			return
		end

		if cmdLower:match("^/respawn$") then
			AxerChat.CancelActionBar()
			local char = LocalPlayer.Character
			if char then local hum = getHumanoid(char); if hum then hum.Health = 0; AxerChat.TriggerAriaLocal("💀 You have been respawned.") else AxerChat.TriggerAriaLocal("❌ No humanoid found.") end
			else AxerChat.TriggerAriaLocal("❌ You have no character.") end
			return
		end

		if cmdLower:match("^/fly$") then
			AxerChat.CancelActionBar()
			if flyEnabled then
				flyEnabled = false
				if flyConnection then flyConnection:Disconnect(); flyConnection = nil end
				if flyBodyVelocity then flyBodyVelocity:Destroy(); flyBodyVelocity = nil end
				AxerChat.TriggerAriaLocal("🛑 Flight disabled.")
			else
				flyEnabled = true; AxerChat.TriggerAriaLocal("✈️ Flight enabled! Type /fly again to disable.")
				if flyConnection then flyConnection:Disconnect() end
				flyConnection = RunService.Heartbeat:Connect(function()
					local char = LocalPlayer.Character
					if not char or not flyEnabled then flyEnabled = false; if flyConnection then flyConnection:Disconnect(); flyConnection = nil end; return end
					local root = getCharRoot(char); if not root then return end
					local hum = getHumanoid(char); if not hum then return end
					hum.PlatformStand = true
					if not flyBodyVelocity or not flyBodyVelocity.Parent then
						flyBodyVelocity = Instance.new("BodyVelocity"); flyBodyVelocity.MaxForce = Vector3.new(0, 4000, 0); flyBodyVelocity.Velocity = Vector3.new(0, 30, 0); flyBodyVelocity.Parent = root
					end
					flyBodyVelocity.Velocity = Vector3.new(0, 30, 0)
				end)
			end
			return
		end

		local viewMatch = cmdLower:match("^/view%s+(.+)$")
		if viewMatch then
			AxerChat.CancelActionBar()
			local target = findPlayerByName(viewMatch)
			if not target or target == LocalPlayer then AxerChat.TriggerAriaLocal("❌ Player not found."); return end
			local char = target.Character; if not char then AxerChat.TriggerAriaLocal("❌ That player has no character."); return end
			local root = getCharRoot(char); if not root then AxerChat.TriggerAriaLocal("❌ Cannot find part."); return end
			viewTarget = target; workspace.CurrentCamera.CameraSubject = root
			AxerChat.TriggerAriaLocal("👀 Now viewing " .. target.DisplayName .. " (@" .. target.Name .. ").")
			return
		end

		if cmdLower:match("^/unview$") then
			AxerChat.CancelActionBar()
			local char = LocalPlayer.Character
			if char then
				local root = getCharRoot(char)
				if root then workspace.CurrentCamera.CameraSubject = root; AxerChat.TriggerAriaLocal("👁️ Camera returned.") else AxerChat.TriggerAriaLocal("❌ Cannot find your root.") end
			else AxerChat.TriggerAriaLocal("❌ You have no character.") end
			viewTarget = nil; return
		end

		local toMatch = cmdLower:match("^/to%s+(.+)$")
		if toMatch then
			AxerChat.CancelActionBar()
			local target = findPlayerByName(toMatch)
			if not target or target == LocalPlayer then AxerChat.TriggerAriaLocal("❌ Player not found."); return end
			local char = LocalPlayer.Character; if not char then AxerChat.TriggerAriaLocal("❌ You have no character."); return end
			local myRoot = getCharRoot(char); if not myRoot then AxerChat.TriggerAriaLocal("❌ Cannot find your root."); return end
			local targetChar = target.Character; if not targetChar then AxerChat.TriggerAriaLocal("❌ No target char."); return end
			local targetRoot = getCharRoot(targetChar); if not targetRoot then AxerChat.TriggerAriaLocal("❌ Cannot find their root."); return end
			lastPosition = myRoot.Position; myRoot.CFrame = targetRoot.CFrame
			AxerChat.TriggerAriaLocal("🚀 Teleported to " .. target.DisplayName .. ".")
			return
		end

		if cmdLower:match("^/back$") then
			AxerChat.CancelActionBar()
			if not lastPosition then AxerChat.TriggerAriaLocal("❌ No previous location stored."); return end
			local char = LocalPlayer.Character; if not char then AxerChat.TriggerAriaLocal("❌ You have no character."); return end
			local myRoot = getCharRoot(char); if not myRoot then AxerChat.TriggerAriaLocal("❌ Cannot find your root."); return end
			myRoot.Position = lastPosition; AxerChat.TriggerAriaLocal("🔙 Returned to previous location.")
			lastPosition = nil; return
		end

		if txt:lower():match("^/helpphoto") then
			AxerChat.CancelActionBar()
			AxerChat.TriggerAriaLocal("📸 <b>ARIA Media Guide:</b>\n\n1. Copy any image link.\n2. Click the <b>🖼️ Image Button</b>.\n3. Paste link and click <b>Save</b>.\n4. Tap saved tile to broadcast!\n5. ⭐ Star to favorite!\n6. Use tabs All/Favorites")
			return
		end

		local vipTarget = txt:match("^/vip%s+(.+)$")
		local unvipTarget = txt:match("^/unvip%s+(.+)$")
		local titleUser, titleText = txt:match("^/title%s+(@?%S+)%s+(.+)$")
		local untitleUser = txt:match("^/untitle%s+(@?%S+)$")
		if vipTarget or unvipTarget or titleUser or untitleUser then
			AxerChat.CancelActionBar()
			if IsStrictAdmin() then
				local cmdStr = titleUser and ("GRANT_TITLE:"..titleUser:gsub("^@",""):lower()..":"..titleText) or (untitleUser and ("REVOKE_TITLE:"..untitleUser:gsub("^@",""):lower()) or (vipTarget and ("GRANT_VIP:"..vipTarget) or ("REVOKE_VIP:"..unvipTarget)))
				AxerChat.DispatchGodCommand(cmdStr)
			else TitanGuardKick("ADM-SPOOF", "Admin Protocol Breach") end
			return
		end

		if AxerChat.EditingMsgID then
			local tid = AxerChat.EditingMsgID; AxerChat.CancelActionBar(); AxerChat.SubmitEdit(tid, txt)
		else AxerChat.Send(txt); AxerChat.CancelActionBar() end
	end
end

AxerChat.UI.SendBtn.MouseButton1Click:Connect(CommitMessage)
AxerChat.UI.TextBox.FocusLost:Connect(function(enter) if enter then CommitMessage() end end)
AxerChat.UI.CancelRep.MouseButton1Click:Connect(AxerChat.CancelActionBar)

local searchThread = nil
AxerChat.UI.SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
	if AxerChat.Mode ~= "DM_Inbox" then return end
	local q = AxerChat.UI.SearchInput.Text:match("^%s*(.-)%s*$")
	for _, c in pairs(AxerChat.UI.Scroll:GetChildren()) do if c:IsA("Frame") or c:IsA("TextButton") then c:Destroy() end end
	if not q or #q < 1 then AxerChat.LiveUpdateInboxSort() return end
	local st = Instance.new("TextLabel", AxerChat.UI.Scroll); st.Size=UDim2.new(1,0,0,35); st.BackgroundTransparency=1; st.Font=Enum.Font.GothamMedium; st.TextSize=11; st.TextColor3=Themes[AxerChat.CurrentTheme].SubText; st.Text="🔍 Searching '"..q.."'..."
	if searchThread then task.cancel(searchThread) end
	searchThread = task.spawn(function()
		task.wait(0.25); local cnt = 0; local seen = {}
		for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer and (p.Name:lower():find(q:lower()) or p.DisplayName:lower():find(q:lower())) then seen[p.Name:lower()]=true; cnt=cnt+1; AxerChat.RegisterAccount(p.Name, p.DisplayName, p.UserId); AxerChat.RenderUserSearchCard(p.DisplayName, p.Name, p.UserId) end end
		if #q >= 3 then
			local s, fId = pcall(function() return Players:GetUserIdFromNameAsync(q) end)
			if s and fId then
				local u, dn = q, q
				if UserService then pcall(function() local inf=UserService:GetUserInfosByUserIdsAsync({fId}); u=inf[1].Username or q; dn=inf[1].DisplayName or u end) else pcall(function() u=Players:GetNameFromUserIdAsync(fId); dn=u end) end
				if u ~= LocalPlayer.Name and not seen[u:lower()] then cnt=cnt+1; AxerChat.RegisterAccount(u, dn, fId); AxerChat.RenderUserSearchCard(dn, u, fId) end
			end
		end
		if st and st.Parent then st:Destroy() end
		if cnt == 0 then local n=Instance.new("TextLabel", AxerChat.UI.Scroll); n.Size=UDim2.new(1,0,0,40); n.BackgroundTransparency=1; n.Font=Enum.Font.GothamMedium; n.TextSize=12; n.TextColor3=Color3.fromRGB(210,70,70); n.Text="No users found matching '"..q.."'" end
	end)
end)

AxerChat.UI.Back.MouseButton1Click:Connect(function() if AxerChat.Mode=="DM" then AxerChat.SwitchMode("DM_Inbox") elseif AxerChat.Mode=="DM_Inbox" then AxerChat.SwitchMode("Server") end end)
AxerChat.UI.InboxBtn.MouseButton1Click:Connect(function() AxerChat.SwitchMode("DM_Inbox") end)
AxerChat.UI.MuteBtn.MouseButton1Click:Connect(function() AxerChat.MuteServerToasts = not AxerChat.MuteServerToasts; AxerChat.UI.MuteBtn.Text = AxerChat.MuteServerToasts and "🔕" or "🔊"; AxerChat.TriggerToast("🔕 Alerts", AxerChat.MuteServerToasts and "Popups Muted" or "Popups Active", false) end)
AxerChat.UI.ThemeBtn.MouseButton1Click:Connect(function() currentThemeIndex = (currentThemeIndex % 3) + 1; AxerChat.CurrentTheme = ThemeSequence[currentThemeIndex]; AxerChat.UI.ThemeBtn.Text = ThemeIcons[AxerChat.CurrentTheme]; AxerChat.UpdateThemeAnimated() end)