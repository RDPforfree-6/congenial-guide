--=============================================================================
--   █████╗ ██╗  ██╗███████╗██████╗
--  ██╔══██╗╚██╗██╔╝██╔════╝██╔══██╗
--  ███████║ ╚███╔╝ █████╗  ██████╔╝
--  ██╔══██║ ██╔██╗ ██╔══╝  ██╔══██╗
--  ██║  ██║██╔╝ ██╗███████╗██║  ██║
--  ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝
--
--  AXER SPAMMER V2  •  Premium Edition
--  Author: Axer (Ashar)
--=============================================================================

--// ==========================================================================
--// 1. SERVICES
--// ==========================================================================
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local SoundService      = game:GetService("SoundService")
local UserInputService  = game:GetService("UserInputService")
local TextChatService   = game:GetService("TextChatService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

--// ==========================================================================
--// 2. CONFIGURATION  (everything tunable lives here)
--// ==========================================================================
local CONFIG = {
	ADMIN_USER_ID      = 5258579647,   -- change to your own UserId if needed

	DEFAULT_DELAY      = 1.5,
	MIN_DELAY          = 1.0,
	MAX_DELAY          = 15.0,
	DEFAULT_MODE       = "NORMAL",
	MAX_MESSAGE_LENGTH = 197,          -- hard cap, keeps chat send safe

	RP_NAME            = "AxEʀ Sᴘᴀᴍᴍᴇʀ Usᴇʀ",
	RP_BIO             = "Welcome",
	RP_UPDATE_RATE     = 0.1,

	WINDOW_W           = 360,
	WINDOW_H           = 486,
	UI_SCALE_MIN       = 0.70,
	UI_SCALE_MAX       = 1.40,

	SOUNDS = {
		CLICK = "rbxasset://sounds/electronicpingshort.wav",
		START = "rbxasset://sounds/switch.wav",
		STOP  = "rbxasset://sounds/switch.wav",
		ERROR = "rbxasset://sounds/uuhhh.mp3",
	},
}

--// ==========================================================================
--// 3. PALETTE
--// ==========================================================================
local PALETTE = {
	BG        = Color3.fromRGB(10, 10, 14),
	PANEL     = Color3.fromRGB(18, 18, 25),
	PANEL_ALT = Color3.fromRGB(24, 24, 33),
	ELEMENT   = Color3.fromRGB(32, 32, 44),
	STROKE    = Color3.fromRGB(46, 46, 62),
	TEXT      = Color3.fromRGB(238, 238, 245),
	SUBTEXT   = Color3.fromRGB(146, 146, 168),
	GOOD      = Color3.fromRGB(70, 210, 130),
	BAD       = Color3.fromRGB(235, 75, 95),
	WARN      = Color3.fromRGB(240, 180, 70),
}

local DEFAULT_ACCENT = Color3.fromRGB(104, 92, 255)

--// ==========================================================================
--// 4. STATE
--// ==========================================================================
local State = {
	spamming    = false,
	paused      = false,
	messagesSent = 0,
	runtime     = 0,

	mode        = CONFIG.DEFAULT_MODE,
	delay       = CONFIG.DEFAULT_DELAY,
	message     = "",
	randomWords = false,

	uiRGB       = true,
	uiAccent    = DEFAULT_ACCENT,
	themeName   = "RGB Rainbow",

	rpNameEnabled = true,
	rpBioEnabled  = true,

	animations  = true,
	sound       = true,
	uiScale     = 1,

	patternIndex = 1,
}

--// ==========================================================================
--// 5. UTILITIES
--// ==========================================================================
local function new(class, props, parent)
	local inst = Instance.new(class)
	if props then
		for k, v in pairs(props) do
			inst[k] = v
		end
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

local function corner(parent, radius)
	return new("UICorner", { CornerRadius = UDim.new(0, radius or 8) }, parent)
end

local function stroke(parent, color, thickness, transparency)
	return new("UIStroke", {
		Color = color or PALETTE.STROKE,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, parent)
end

local function animate(obj, time, props)
	if State.animations then
		TweenService:Create(
			obj,
			TweenInfo.new(time or 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			props
		):Play()
	else
		for k, v in pairs(props) do
			obj[k] = v
		end
	end
end

local function colorToHex(c)
	return string.format(
		"%02X%02X%02X",
		math.clamp(math.floor(c.R * 255 + 0.5), 0, 255),
		math.clamp(math.floor(c.G * 255 + 0.5), 0, 255),
		math.clamp(math.floor(c.B * 255 + 0.5), 0, 255)
	)
end

local function hexToColor(hex)
	hex = tostring(hex):gsub("#", ""):gsub("%s", "")
	if #hex == 3 then
		hex = hex:sub(1, 1):rep(2) .. hex:sub(2, 2):rep(2) .. hex:sub(3, 3):rep(2)
	end
	if #hex ~= 6 or hex:match("%X") == nil and not hex:match("^%x%x%x%x%x%x$") then
		return nil
	end
	local r = tonumber(hex:sub(1, 2), 16)
	local g = tonumber(hex:sub(3, 4), 16)
	local b = tonumber(hex:sub(5, 6), 16)
	if not r or not g or not b then
		return nil
	end
	return Color3.fromRGB(r, g, b)
end

local function accentFill(color)
	return color:Lerp(Color3.new(0, 0, 0), 0.45)
end

local function formatTime(sec)
	sec = math.floor(sec)
	local h = math.floor(sec / 3600)
	local m = math.floor((sec % 3600) / 60)
	local s = sec % 60
	if h > 0 then
		return string.format("%02d:%02d:%02d", h, m, s)
	end
	return string.format("%02d:%02d", m, s)
end

-- Safely truncate a string without breaking a multi-byte UTF-8 character.
local function safeTruncate(str, max)
	if #str <= max then
		return str
	end
	local cut = str:sub(1, max)
	local i = #cut
	while i > 0 do
		local b = cut:byte(i)
		if b < 0x80 then
			break
		elseif b >= 0xC0 then
			local need = 2
			if b >= 0xF0 then
				need = 4
			elseif b >= 0xE0 then
				need = 3
			end
			if i + need - 1 > #cut then
				cut = cut:sub(1, i - 1)
			end
			break
		else
			i = i - 1
		end
	end
	return cut
end

--// ---------- Sound feedback ----------
local sfxFolder = new("Folder", { Name = "AXER_SFX" }, SoundService)
local SFX = {}
for name, id in pairs(CONFIG.SOUNDS) do
	SFX[name] = new("Sound", { SoundId = id, Volume = 0.35 }, sfxFolder)
end

local function playSound(name)
	if not State.sound then
		return
	end
	local s = SFX[name]
	if not s then
		return
	end
	pcall(function()
		s.TimePosition = 0
		s:Play()
	end)
end

--// ==========================================================================
--// 6. ACCENT SYSTEM (single source of truth for UI colour)
--// ==========================================================================
local AccentStrokes   = {}
local AccentTexts     = {}
local AccentFills     = {}
local AccentToggles   = {}
local AccentSelectors = {}

local function registerStroke(s) table.insert(AccentStrokes, s) return s end
local function registerText(t) table.insert(AccentTexts, t) return t end
local function registerFill(f) table.insert(AccentFills, f) return f end

local function refreshSelector(sel)
	for name, btn in pairs(sel.buttons) do
		local active = (sel.getCurrent() == name)
		btn.BackgroundColor3 = active and State.uiAccent or PALETTE.ELEMENT
		btn.BackgroundTransparency = active and 0 or 0.35
		btn.TextColor3 = active and Color3.new(1, 1, 1) or PALETTE.SUBTEXT
	end
end

local titleLabel -- forward declaration (assigned in UI section)

local function applyAccent(color, instant)
	State.uiAccent = color
	local hex = colorToHex(color)
	if titleLabel then
		titleLabel.Text = string.format(
			'<font color="#%s">AXER</font> SPAMMER <font color="#%s">V2</font>',
			hex, hex
		)
	end

	local info = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local soft = (instant or not State.animations)

	for _, o in ipairs(AccentStrokes) do
		if o.Parent then
			if soft then o.Color = color else TweenService:Create(o, info, { Color = color }):Play() end
		end
	end
	for _, o in ipairs(AccentTexts) do
		if o.Parent then
			if soft then o.TextColor3 = color else TweenService:Create(o, info, { TextColor3 = color }):Play() end
		end
	end
	for _, o in ipairs(AccentFills) do
		if o.Parent then
			local target = accentFill(color)
			if soft then o.BackgroundColor3 = target else TweenService:Create(o, info, { BackgroundColor3 = target }):Play() end
		end
	end
	for _, entry in ipairs(AccentToggles) do
		if entry.track.Parent and entry.getValue() then
			entry.track.BackgroundColor3 = color
		end
	end
	for _, sel in ipairs(AccentSelectors) do
		refreshSelector(sel)
	end
end

--// ==========================================================================
--// 7. UI — ROOT WINDOW
--// ==========================================================================
local screenGui = new("ScreenGui", {
	Name = "AXER_V2_MASTER",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 100,
}, PlayerGui)

local WINDOW_W, WINDOW_H = CONFIG.WINDOW_W, CONFIG.WINDOW_H

local window = new("Frame", {
	Name = "Window",
	Size = UDim2.fromOffset(WINDOW_W, WINDOW_H),
	Position = UDim2.new(0.5, 0, 0.5, 0),
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundColor3 = PALETTE.BG,
	BorderSizePixel = 0,
	Active = true,
	ClipsDescendants = true,
}, screenGui)
corner(window, 14)
registerStroke(stroke(window, State.uiAccent, 1.5))

local uiScale = new("UIScale", { Scale = 1 }, window)

local function updateScale()
	local cam = workspace.CurrentCamera
	local vp = (cam and cam.ViewportSize) or Vector2.new(1280, 720)
	local fit = math.min(vp.X / (WINDOW_W + 30), vp.Y / (WINDOW_H + 30))
	uiScale.Scale = math.clamp(math.min(1, fit) * State.uiScale, 0.45, 1.5)
end

--// ---------- Floating restore button ----------
local floatBtn = new("TextButton", {
	Name = "FloatButton",
	Size = UDim2.fromOffset(52, 52),
	Position = UDim2.new(0, 24, 0.4, 0),
	BackgroundColor3 = PALETTE.PANEL,
	Text = "AXER",
	Font = Enum.Font.GothamBlack,
	TextSize = 12,
	TextColor3 = PALETTE.TEXT,
	AutoButtonColor = false,
	BorderSizePixel = 0,
	Visible = false,
	Draggable = true,
}, screenGui)
corner(floatBtn, 26)
local floatStroke = registerStroke(stroke(floatBtn, State.uiAccent, 1.5))

floatBtn.MouseButton1Click:Connect(function()
	playSound("CLICK")
	floatBtn.Visible = false
	window.Visible = true
	window.Size = UDim2.fromOffset(WINDOW_W, 10)
	animate(window, 0.22, { Size = UDim2.fromOffset(WINDOW_W, WINDOW_H) })
end)

--// ---------- Header ----------
local HEADER_H = 54
local header = new("Frame", {
	Name = "Header",
	Size = UDim2.new(1, 0, 0, HEADER_H),
	BackgroundColor3 = PALETTE.PANEL,
	BorderSizePixel = 0,
}, window)
corner(header, 14)
new("Frame", { -- hides the bottom corner rounding
	Size = UDim2.new(1, 0, 0, 22),
	Position = UDim2.new(0, 0, 1, -22),
	BackgroundColor3 = PALETTE.PANEL,
	BorderSizePixel = 0,
}, header)

titleLabel = new("TextLabel", {
	Size = UDim2.new(0, 220, 0, 20),
	Position = UDim2.new(0, 16, 0, 9),
	BackgroundTransparency = 1,
	RichText = true,
	Text = "",
	Font = Enum.Font.GothamBlack,
	TextSize = 16,
	TextColor3 = PALETTE.TEXT,
	TextXAlignment = Enum.TextXAlignment.Left,
}, header)

new("TextLabel", {
	Size = UDim2.new(0, 220, 0, 14),
	Position = UDim2.new(0, 16, 0, 30),
	BackgroundTransparency = 1,
	Text = string.format("@%s  •  ID %d", LocalPlayer.Name, LocalPlayer.UserId),
	Font = Enum.Font.Gotham,
	TextSize = 10,
	TextColor3 = PALETTE.SUBTEXT,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextTruncate = Enum.TextTruncate.AtEnd,
}, header)

local headerLine = registerFill(new("Frame", {
	Size = UDim2.new(1, -28, 0, 2),
	Position = UDim2.new(0, 14, 1, -3),
	BackgroundColor3 = State.uiAccent,
	BorderSizePixel = 0,
}, header))
corner(headerLine, 1)

local function headerButton(text, xOffset)
	local b = new("TextButton", {
		Size = UDim2.fromOffset(26, 26),
		Position = UDim2.new(1, xOffset, 0, 14),
		BackgroundColor3 = PALETTE.ELEMENT,
		Text = text,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = PALETTE.TEXT,
		AutoButtonColor = false,
		BorderSizePixel = 0,
	}, header)
	corner(b, 8)
	stroke(b, PALETTE.STROKE, 1)
	b.MouseEnter:Connect(function()
		animate(b, 0.12, { BackgroundColor3 = PALETTE.ELEMENT:Lerp(Color3.new(1, 1, 1), 0.12) })
	end)
	b.MouseLeave:Connect(function()
		animate(b, 0.12, { BackgroundColor3 = PALETTE.ELEMENT })
	end)
	return b
end

local minBtn   = headerButton("–", -72)
local closeBtn = headerButton("✕", -40)

--// ---------- Window drag ----------
do
	local dragging, dragStart, startPos = false, nil, nil

	header.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		if input.Target and input.Target:IsA("GuiButton") then
			return
		end
		dragging = true
		dragStart = input.Position
		startPos = window.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		local delta = input.Position - dragStart
		local s = uiScale.Scale > 0 and uiScale.Scale or 1
		window.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X / s,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y / s
		)
	end)
end

--// ---------- Toast ----------
local toast = new("Frame", {
	Size = UDim2.new(1, -24, 0, 34),
	Position = UDim2.new(0, 12, 1, -50),
	BackgroundColor3 = PALETTE.PANEL_ALT,
	BorderSizePixel = 0,
	Visible = false,
	ZIndex = 20,
}, window)
corner(toast, 9)
local toastStroke = stroke(toast, PALETTE.STROKE, 1)

local toastLabel = new("TextLabel", {
	Size = UDim2.new(1, -20, 1, 0),
	Position = UDim2.new(0, 10, 0, 0),
	BackgroundTransparency = 1,
	Text = "",
	Font = Enum.Font.GothamBold,
	TextSize = 11,
	TextColor3 = PALETTE.TEXT,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextTruncate = Enum.TextTruncate.AtEnd,
	ZIndex = 21,
}, toast)

local toastToken = 0
local function showToast(text, color)
	toastToken += 1
	local myToken = toastToken
	toastLabel.Text = text
	toastLabel.TextColor3 = color or PALETTE.TEXT
	toastStroke.Color = color or PALETTE.STROKE
	toast.Visible = true
	toast.Position = UDim2.new(0, 12, 1, -28)
	animate(toast, 0.2, { Position = UDim2.new(0, 12, 1, -50) })

	task.delay(2.2, function()
		if toastToken ~= myToken then return end
		animate(toast, 0.22, { Position = UDim2.new(0, 12, 1, -28) })
		task.wait(0.25)
		if toastToken == myToken then
			toast.Visible = false
		end
	end)
end

--// ---------- Tab bar ----------
local TABBAR_H = 34
local tabBar = new("Frame", {
	Size = UDim2.new(1, -20, 0, TABBAR_H),
	Position = UDim2.new(0, 10, 0, HEADER_H + 4),
	BackgroundColor3 = PALETTE.PANEL,
	BorderSizePixel = 0,
}, window)
corner(tabBar, 10)
stroke(tabBar, PALETTE.STROKE, 1)

local TAB_NAMES = { "Home", "Spam", "Builder", "Themes", "Settings", "Info" }
local tabButtons = {}

for _, name in ipairs(TAB_NAMES) do
	local b = new("TextButton", {
		Size = UDim2.new(0.15, 0, 1, -8),
		BackgroundColor3 = PALETTE.ELEMENT,
		BackgroundTransparency = 0.45,
		Text = name,
		Font = Enum.Font.GothamBold,
		TextSize = 9,
		TextColor3 = PALETTE.SUBTEXT,
		AutoButtonColor = false,
		BorderSizePixel = 0,
	}, tabBar)
	corner(b, 7)
	tabButtons[name] = b
end

new("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	Padding = UDim.new(0, 4),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, tabBar)

--// ---------- Content ----------
local CONTENT_Y = HEADER_H + 4 + TABBAR_H + 8
local content = new("Frame", {
	Size = UDim2.new(1, -20, 1, -(CONTENT_Y + 12)),
	Position = UDim2.new(0, 10, 0, CONTENT_Y),
	BackgroundTransparency = 1,
}, window)

local function createPage()
	local page = new("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = PALETTE.STROKE,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Visible = false,
		ClipsDescendants = true,
	}, content)
	new("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, page)
	new("UIPadding", {
		PaddingRight = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 16),
	}, page)
	return page
end

--// ==========================================================================
--// 8. UI WIDGETS
--// ==========================================================================
local function sectionTitle(parent, text)
	return new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 16),
		BackgroundTransparency = 1,
		Text = text,
		Font = Enum.Font.GothamBold,
		TextSize = 10,
		TextColor3 = PALETTE.SUBTEXT,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, parent)
end

local function card(parent, height)
	local f = new("Frame", {
		Size = UDim2.new(1, 0, 0, height),
		BackgroundColor3 = PALETTE.PANEL,
		BorderSizePixel = 0,
	}, parent)
	corner(f, 10)
	stroke(f, PALETTE.STROKE, 1)
	return f
end

local function makeButton(parent, text, opts)
	opts = opts or {}
	local baseColor = opts.color or PALETTE.ELEMENT
	local b = new("TextButton", {
		Size = UDim2.new(1, 0, 0, opts.height or 34),
		BackgroundColor3 = baseColor,
		Text = text,
		Font = Enum.Font.GothamBold,
		TextSize = opts.textSize or 12,
		TextColor3 = opts.textColor or PALETTE.TEXT,
		AutoButtonColor = false,
		BorderSizePixel = 0,
	}, parent)
	corner(b, 8)
	stroke(b, opts.strokeColor or PALETTE.STROKE, 1)

	if not opts.noHover then
		b.MouseEnter:Connect(function()
			animate(b, 0.12, { BackgroundColor3 = baseColor:Lerp(Color3.new(1, 1, 1), 0.12) })
		end)
		b.MouseLeave:Connect(function()
			animate(b, 0.12, { BackgroundColor3 = baseColor })
		end)
		b.MouseButton1Down:Connect(function()
			animate(b, 0.06, { BackgroundColor3 = baseColor:Lerp(Color3.new(0, 0, 0), 0.15) })
		end)
	end
	b.MouseButton1Click:Connect(function()
		playSound("CLICK")
	end)
	return b
end

local function makeTextBox(parent, placeholder, default, height)
	local box = new("TextBox", {
		Size = UDim2.new(1, 0, 0, height or 34),
		BackgroundColor3 = PALETTE.ELEMENT,
		Text = default or "",
		PlaceholderText = placeholder or "",
		PlaceholderColor3 = PALETTE.SUBTEXT,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextColor3 = PALETTE.TEXT,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		BorderSizePixel = 0,
	}, parent)
	corner(box, 8)
	local s = stroke(box, PALETTE.STROKE, 1)
	new("UIPadding", {
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
	}, box)

	box.Focused:Connect(function()
		animate(s, 0.15, { Color = State.uiAccent })
	end)
	box.FocusLost:Connect(function()
		animate(s, 0.15, { Color = PALETTE.STROKE })
	end)
	return box
end

local function makeToggle(parent, label, default, callback)
	local row = new("Frame", {
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundColor3 = PALETTE.PANEL,
		BorderSizePixel = 0,
	}, parent)
	corner(row, 8)
	stroke(row, PALETTE.STROKE, 1)

	new("TextLabel", {
		Size = UDim2.new(1, -80, 1, 0),
		Position = UDim2.new(0, 12, 0, 0),
		BackgroundTransparency = 1,
		Text = label,
		Font = Enum.Font.GothamMedium,
		TextSize = 11,
		TextColor3 = PALETTE.TEXT,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, row)

	local track = new("Frame", {
		Size = UDim2.fromOffset(38, 20),
		Position = UDim2.new(1, -50, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = PALETTE.ELEMENT,
		BorderSizePixel = 0,
	}, row)
	corner(track, 10)

	local knob = new("Frame", {
		Size = UDim2.fromOffset(14, 14),
		Position = UDim2.new(0, 3, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = PALETTE.TEXT,
		BorderSizePixel = 0,
	}, track)
	corner(knob, 7)

	local value = default and true or false

	local function render(instant)
		local bg = value and State.uiAccent or PALETTE.ELEMENT
		local pos = value and UDim2.new(1, -17, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
		if instant or not State.animations then
			track.BackgroundColor3 = bg
			knob.Position = pos
		else
			animate(track, 0.18, { BackgroundColor3 = bg })
			animate(knob, 0.18, { Position = pos })
		end
	end

	local api = {}
	function api.set(v, fire)
		value = v and true or false
		render(false)
		if fire and callback then
			callback(value)
		end
	end
	function api.get()
		return value
	end

	render(true)
	table.insert(AccentToggles, { track = track, getValue = function() return value end })

	local click = new("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
	}, row)
	click.MouseButton1Click:Connect(function()
		api.set(not value, true)
	end)

	return api
end

local function makeSelector(parent, options, getCurrent, setCurrent)
	local cols = 3
	local rows = math.ceil(#options / cols)
	local cellH = 30
	local gap = 6

	local holder = new("Frame", {
		Size = UDim2.new(1, 0, 0, rows * cellH + (rows - 1) * gap),
		BackgroundTransparency = 1,
	}, parent)

	new("UIGridLayout", {
		CellSize = UDim2.new(1 / cols, -(gap * (cols - 1)) / cols, 0, cellH),
		CellPadding = UDim2.new(0, gap, 0, gap),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, holder)

	local sel = { buttons = {}, getCurrent = getCurrent }

	for _, name in ipairs(options) do
		local b = new("TextButton", {
			BackgroundColor3 = PALETTE.ELEMENT,
			BackgroundTransparency = 0.35,
			Text = name,
			Font = Enum.Font.GothamBold,
			TextSize = 10,
			TextColor3 = PALETTE.SUBTEXT,
			AutoButtonColor = false,
			BorderSizePixel = 0,
		}, holder)
		corner(b, 8)
		stroke(b, PALETTE.STROKE, 1)
		b.MouseButton1Click:Connect(function()
			setCurrent(name)
			refreshSelector(sel)
		end)
		sel.buttons[name] = b
	end

	table.insert(AccentSelectors, sel)
	refreshSelector(sel)
	return sel
end

local function makeSlider(parent, label, min, max, default, decimals, callback)
	local holder = new("Frame", {
		Size = UDim2.new(1, 0, 0, 48),
		BackgroundColor3 = PALETTE.PANEL,
		BorderSizePixel = 0,
	}, parent)
	corner(holder, 8)
	stroke(holder, PALETTE.STROKE, 1)

	new("TextLabel", {
		Size = UDim2.new(0.6, 0, 0, 16),
		Position = UDim2.new(0, 12, 0, 8),
		BackgroundTransparency = 1,
		Text = label,
		Font = Enum.Font.GothamMedium,
		TextSize = 11,
		TextColor3 = PALETTE.TEXT,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, holder)

	local valueLabel = new("TextLabel", {
		Size = UDim2.new(0.4, -24, 0, 16),
		Position = UDim2.new(0.6, 12, 0, 8),
		BackgroundTransparency = 1,
		Text = "",
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		TextColor3 = State.uiAccent,
		TextXAlignment = Enum.TextXAlignment.Right,
	}, holder)
	registerText(valueLabel)

	local hit = new("Frame", {
		Size = UDim2.new(1, -24, 0, 18),
		Position = UDim2.new(0, 12, 1, -23),
		BackgroundTransparency = 1,
	}, holder)

	local track = new("Frame", {
		Size = UDim2.new(1, 0, 0, 5),
		Position = UDim2.new(0, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = PALETTE.ELEMENT,
		BorderSizePixel = 0,
	}, hit)
	corner(track, 3)

	local fill = new("Frame", {
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = State.uiAccent,
		BorderSizePixel = 0,
	}, track)
	corner(fill, 3)
	registerFill(fill)

	local knob = new("Frame", {
		Size = UDim2.fromOffset(12, 12),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
	}, hit)
	corner(knob, 6)

	local dragging = false

	local function setFromAlpha(alpha)
		alpha = math.clamp(alpha, 0, 1)
		local value = min + (max - min) * alpha
		local rounded = math.floor(value * (10 ^ decimals) + 0.5) / (10 ^ decimals)
		fill.Size = UDim2.new(alpha, 0, 1, 0)
		knob.Position = UDim2.new(alpha, 0, 0.5, 0)
		valueLabel.Text = string.format("%." .. decimals .. "f", rounded)
		if callback then
			callback(rounded)
		end
	end

	local function handleInput(input)
		local rel = (input.Position.X - hit.AbsolutePosition.X) / math.max(hit.AbsoluteSize.X, 1)
		setFromAlpha(rel)
	end

	hit.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			handleInput(input)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			handleInput(input)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	local api = {}
	function api.set(v)
		local alpha = (v - min) / (max - min)
		setFromAlpha(alpha)
	end
	api.set(default)

	return api
end

--// ==========================================================================
--// 9. MESSAGE SYSTEM
--// ==========================================================================
local PATTERN_CYCLE = { "`", "'", "Z_", "Q_", "@", "#", "*", "%", "@_", "/-", "_", "P_" }
local RANDOM_WORDS = {
	"BURGER", "PIZZA", "QATAR", "JUICE", "ORANGE", "BALL", "BLACK HOLE", "APPLE",
	"GMD", "LUN", "BUS", "CAR", "PLANE", "VORTEX", "REBEL", "JOKER", "GHOST",
	"LEGEND", "SNIPER", "OMEGA", "ALPHA", "VENOM", "SHADOW", "COBRA", "TIGOR",
	"PHANTOM", "HYDRA", "TITAN", "BEAST", "KRATOS", "VOID", "STORM", "VOLT",
	"CARBON", "NITRO", "CHIP", "BLADE", "REAPER", "GLITCH", "STATIC", "NEON",
	"ZENITH", "KILLER", "DOOM", "GALAXY",
}

local function nextPattern()
	local p = PATTERN_CYCLE[State.patternIndex] or "`"
	State.patternIndex = (State.patternIndex % #PATTERN_CYCLE) + 1
	return p
end

-- Build a filler prefix that does not exceed the maximum message length.
local function makeFiller(chunk, coreLength)
	local budget = CONFIG.MAX_MESSAGE_LENGTH - coreLength - 1
	if budget < #chunk then
		return ""
	end
	local out = {}
	local total = 0
	while total + #chunk <= budget do
		table.insert(out, chunk)
		total = total + #chunk
	end
	return table.concat(out)
end

local function buildMessage()
	local base = State.message or ""
	local body

	if State.mode == "CUSTOM" then
		body = base
	else
		body = base
		if State.randomWords then
			local w = RANDOM_WORDS[math.random(1, #RANDOM_WORDS)]
			body = (body ~= "" and (body .. " ") or "") .. w
		end
	end

	local result

	if State.mode == "NORMAL" then
		local core = (body ~= "" and (body .. " ") or "") .. "TMKX MAI"
		core = (body ~= "" and body or "TMKX MAI")
		local full = body ~= "" and body or ""
		local coreText = (full ~= "" and full or "TMKX MAI")
		local filler = makeFiller(nextPattern(), #coreText)
		result = (filler ~= "" and (filler .. " ") or "") .. coreText

	elseif State.mode == "CLEAN" then
		local filler = makeFiller(nextPattern(), #body)
		result = (filler ~= "" and (filler .. " ") or "") .. body

	elseif State.mode == "LOADED" then
		local filler = makeFiller("•=•", #body)
		result = (filler ~= "" and (filler .. " ") or "") .. body

	elseif State.mode == "RANDOM" then
		local word = RANDOM_WORDS[math.random(1, #RANDOM_WORDS)]
		local filler = makeFiller(nextPattern(), #word)
		result = (filler ~= "" and (filler .. " ") or "") .. word

	else -- CUSTOM
		result = body
	end

	if result == nil then
		result = body
	end

	return safeTruncate(result, CONFIG.MAX_MESSAGE_LENGTH)
end

local function sendMessage(msg)
	local delivered = false

	pcall(function()
		local channels = TextChatService:FindFirstChild("TextChannels")
		if channels then
			local target = channels:FindFirstChild("RBXGeneral")
			if not target then
				for _, c in ipairs(channels:GetChildren()) do
					if c:IsA("TextChannel") then
						target = c
						break
					end
				end
			end
			if target then
				target:SendAsync(msg)
				delivered = true
			end
		end
	end)

	pcall(function()
		local events = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
		if events then
			local req = events:FindFirstChild("SayMessageRequest")
			if req then
				req:FireServer(msg, "All")
				delivered = true
			end
		end
	end)

	return delivered
end

--// ==========================================================================
--// 10. PAGES
--// ==========================================================================
local homePage    = createPage()
local spamPage    = createPage()
local builderPage = createPage()
local themePage   = createPage()
local settPage    = createPage()
local infoPage    = createPage()

local PAGES = {
	Home = homePage,
	Spam = spamPage,
	Builder = builderPage,
	Themes = themePage,
	Settings = settPage,
	Info = infoPage,
}

local activeTab = "Home"
local function showPage(name)
	for key, page in pairs(PAGES) do
		page.Visible = (key == name)
	end
	for key, btn in pairs(tabButtons) do
		local active = (key == name)
		btn.BackgroundColor3 = active and accentFill(State.uiAccent) or PALETTE.ELEMENT
		btn.BackgroundTransparency = active and 0 or 0.45
		btn.TextColor3 = active and Color3.new(1, 1, 1) or PALETTE.SUBTEXT
	end
	activeTab = name
end

--// ==========================================================================
--// 11. DASHBOARD PAGE
--// ==========================================================================
local UI = {}

do
	-- Status card
	local statusCard = card(homePage, 78)

	UI.statusDot = new("Frame", {
		Size = UDim2.fromOffset(10, 10),
		Position = UDim2.new(0, 16, 0, 20),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = PALETTE.BAD,
		BorderSizePixel = 0,
	}, statusCard)
	corner(UI.statusDot, 5)

	UI.statusLabel = new("TextLabel", {
		Size = UDim2.new(1, -40, 0, 24),
		Position = UDim2.new(0, 34, 0, 10),
		BackgroundTransparency = 1,
		Text = "STOPPED",
		Font = Enum.Font.GothamBlack,
		TextSize = 20,
		TextColor3 = PALETTE.BAD,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, statusCard)

	UI.statusSub = new("TextLabel", {
		Size = UDim2.new(1, -32, 0, 16),
		Position = UDim2.new(0, 16, 0, 40),
		BackgroundTransparency = 1,
		Text = "Mode: NORMAL  •  Delay: 1.5s",
		Font = Enum.Font.Gotham,
		TextSize = 10,
		TextColor3 = PALETTE.SUBTEXT,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, statusCard)

	-- Stats card
	local statsCard = card(homePage, 168)
	new("UIListLayout", {
		Padding = UDim.new(0, 2),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, statsCard)
	new("UIPadding", {
		PaddingTop = UDim.new(0, 12),
		PaddingBottom = UDim.new(0, 12),
		PaddingLeft = UDim.new(0, 14),
		PaddingRight = UDim.new(0, 14),
	}, statsCard)

	local function statRow(labelText)
		local row = new("Frame", {
			Size = UDim2.new(1, 0, 0, 22),
			BackgroundTransparency = 1,
		}, statsCard)
		new("TextLabel", {
			Size = UDim2.new(0.5, 0, 1, 0),
			BackgroundTransparency = 1,
			Text = labelText,
			Font = Enum.Font.Gotham,
			TextSize = 11,
			TextColor3 = PALETTE.SUBTEXT,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, row)
		return new("TextLabel", {
			Size = UDim2.new(0.5, 0, 1, 0),
			Position = UDim2.new(0.5, 0, 0, 0),
			BackgroundTransparency = 1,
			Text = "—",
			Font = Enum.Font.GothamBold,
			TextSize = 11,
			TextColor3 = PALETTE.TEXT,
			TextXAlignment = Enum.TextXAlignment.Right,
			TextTruncate = Enum.TextTruncate.AtEnd,
		}, row)
	end

	UI.statPlayer   = statRow("Player")
	UI.statUserId   = statRow("User ID")
	UI.statMessages = statRow("Messages Sent")
	UI.statRuntime  = statRow("Session Runtime")
	UI.statMode     = statRow("Mode")
	UI.statTheme    = statRow("Theme")

	-- Controls
	sectionTitle(homePage, "CONTROLS")

	UI.startBtn = makeButton(homePage, "START", {
		height = 38,
		color = Color3.fromRGB(28, 90, 55),
	})
	UI.pauseBtn = makeButton(homePage, "PAUSE", { height = 34 })
	UI.stopBtn  = makeButton(homePage, "STOP", {
		height = 34,
		color = Color3.fromRGB(120, 35, 45),
	})
end

--// ==========================================================================
--// 12. SPAM PAGE
--// ==========================================================================
do
	sectionTitle(spamPage, "MESSAGE MODE")

	makeSelector(
		spamPage,
		{ "NORMAL", "CLEAN", "LOADED", "CUSTOM", "RANDOM" },
		function() return State.mode end,
		function(v)
			State.mode = v
			UI.statusSub.Text = string.format("Mode: %s  •  Delay: %.1fs", State.mode, State.delay)
			updateDashboard()
		end
	)

	sectionTitle(spamPage, "SEND DELAY")

	makeSlider(spamPage, "Delay (seconds)", CONFIG.MIN_DELAY, CONFIG.MAX_DELAY, State.delay, 1, function(v)
		State.delay = v
		UI.statusSub.Text = string.format("Mode: %s  •  Delay: %.1fs", State.mode, State.delay)
		updateDashboard()
	end)

	sectionTitle(spamPage, "QUICK ACTIONS")

	local previewCard = card(spamPage, 74)
	new("TextLabel", {
		Size = UDim2.new(1, -24, 0, 14),
		Position = UDim2.new(0, 12, 0, 8),
		BackgroundTransparency = 1,
		Text = "PREVIEW",
		Font = Enum.Font.GothamBold,
		TextSize = 9,
		TextColor3 = PALETTE.SUBTEXT,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, previewCard)

	UI.previewLabel = new("TextLabel", {
		Size = UDim2.new(1, -24, 0, 42),
		Position = UDim2.new(0, 12, 0, 24),
		BackgroundTransparency = 1,
		Text = "—",
		Font = Enum.Font.Code,
		TextSize = 10,
		TextColor3 = PALETTE.TEXT,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
	}, previewCard)

	UI.previewBtn = makeButton(spamPage, "GENERATE PREVIEW", { height = 34 })
	UI.previewBtn.MouseButton1Click:Connect(function()
		local msg = buildMessage()
		UI.previewLabel.Text = (msg ~= "" and msg) or "—"
		showToast(string.format("Preview: %d characters", #msg), PALETTE.TEXT)
	end)

	local row = new("Frame", {
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundTransparency = 1,
	}, spamPage)
	local rowLayout = new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, row)

	local halfA = makeButton(row, "START", { height = 34, color = Color3.fromRGB(28, 90, 55) })
	halfA.Size = UDim2.new(0.5, -4, 1, 0)
	local halfB = makeButton(row, "STOP", { height = 34, color = Color3.fromRGB(120, 35, 45) })
	halfB.Size = UDim2.new(0.5, -4, 1, 0)

	halfA.MouseButton1Click:Connect(function() startSpam() end)
	halfB.MouseButton1Click:Connect(function() stopSpam() end)
end

--// ==========================================================================
--// 13. BUILDER PAGE
--// ==========================================================================
do
	sectionTitle(builderPage, "CUSTOM MESSAGE")

	local messageBox = makeTextBox(builderPage, "Type your message here...", State.message, 38)
	messageBox.Text = State.message
	messageBox:GetPropertyChangedSignal("Text"):Connect(function()
		State.message = messageBox.Text
	end)
	UI.messageBox = messageBox

	makeToggle(builderPage, "Append Random Words", State.randomWords, function(v)
		State.randomWords = v
	end)

	sectionTitle(builderPage, "ACTIONS")

	local previewCard = card(builderPage, 88)
	new("TextLabel", {
		Size = UDim2.new(1, -24, 0, 14),
		Position = UDim2.new(0, 12, 0, 8),
		BackgroundTransparency = 1,
		Text = "BUILT MESSAGE",
		Font = Enum.Font.GothamBold,
		TextSize = 9,
		TextColor3 = PALETTE.SUBTEXT,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, previewCard)

	local builtLabel = new("TextLabel", {
		Size = UDim2.new(1, -24, 0, 56),
		Position = UDim2.new(0, 12, 0, 24),
		BackgroundTransparency = 1,
		Text = "—",
		Font = Enum.Font.Code,
		TextSize = 10,
		TextColor3 = PALETTE.TEXT,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
	}, previewCard)

	local buildBtn = makeButton(builderPage, "BUILD PREVIEW", { height = 34 })
	buildBtn.MouseButton1Click:Connect(function()
		local msg = buildMessage()
		builtLabel.Text = (msg ~= "" and msg) or "—"
		showToast(string.format("Built %d characters", #msg), PALETTE.GOOD)
	end)

	local actionRow = new("Frame", {
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundTransparency = 1,
	}, builderPage)
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, actionRow)

	local clearBtn = makeButton(actionRow, "CLEAR", { height = 34 })
	clearBtn.Size = UDim2.new(0.5, -4, 1, 0)
	clearBtn.MouseButton1Click:Connect(function()
		messageBox.Text = ""
		State.message = ""
		builtLabel.Text = "—"
		UI.previewLabel.Text = "—"
		showToast("Message cleared.", PALETTE.WARN)
	end)

	local saveBtn = makeButton(actionRow, "SAVE SESSION", { height = 34 })
	saveBtn.Size = UDim2.new(0.5, -4, 1, 0)
	saveBtn.MouseButton1Click:Connect(function()
		State.message = messageBox.Text
		showToast("Configuration saved for this session.", PALETTE.GOOD)
	end)

	local useBtn = makeButton(builderPage, "USE AS ACTIVE MESSAGE", { height = 34 })
	useBtn.MouseButton1Click:Connect(function()
		State.message = messageBox.Text
		if State.mode == "CUSTOM" then
			showToast("Active message updated.", PALETTE.GOOD)
		else
			State.mode = "CUSTOM"
			showToast("Mode switched to CUSTOM.", PALETTE.TEXT)
			updateDashboard()
		end
	end)
end

--// ==========================================================================
--// 14. THEMES PAGE
--// ==========================================================================
do
	sectionTitle(themePage, "THEME PRESETS")

	local THEMES = {
		{ name = "RGB Rainbow",     color = nil },
		{ name = "Crimson",         color = Color3.fromRGB(220, 50, 70) },
		{ name = "Cyber Blue",      color = Color3.fromRGB(0, 140, 255) },
		{ name = "Electric Purple", color = Color3.fromRGB(160, 60, 255) },
		{ name = "Emerald",         color = Color3.fromRGB(40, 200, 130) },
		{ name = "Gold",            color = Color3.fromRGB(255, 195, 60) },
		{ name = "Silver",          color = Color3.fromRGB(190, 195, 205) },
		{ name = "Midnight",        color = Color3.fromRGB(70, 90, 200) },
	}

	local rows = math.ceil(#THEMES / 2)
	local grid = new("Frame", {
		Size = UDim2.new(1, 0, 0, rows * 36 + (rows - 1) * 8),
		BackgroundTransparency = 1,
	}, themePage)
	new("UIGridLayout", {
		CellSize = UDim2.new(0.5, -4, 0, 36),
		CellPadding = UDim2.new(0, 8, 0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, grid)

	for _, theme in ipairs(THEMES) do
		local b = new("TextButton", {
			BackgroundColor3 = PALETTE.ELEMENT,
			Text = theme.name,
			Font = Enum.Font.GothamBold,
			TextSize = 10,
			TextColor3 = PALETTE.TEXT,
			AutoButtonColor = false,
			BorderSizePixel = 0,
		}, grid)
		corner(b, 8)
		stroke(b, PALETTE.STROKE, 1)
		new("UIPadding", { PaddingLeft = UDim.new(0, 26) }, b)

		local swatch = new("Frame", {
			Size = UDim2.fromOffset(12, 12),
			Position = UDim2.new(0, 10, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = theme.color or Color3.fromRGB(120, 120, 255),
			BorderSizePixel = 0,
		}, b)
		corner(swatch, 6)

		b.MouseEnter:Connect(function()
			animate(b, 0.12, { BackgroundColor3 = PALETTE.ELEMENT:Lerp(Color3.new(1, 1, 1), 0.12) })
		end)
		b.MouseLeave:Connect(function()
			animate(b, 0.12, { BackgroundColor3 = PALETTE.ELEMENT })
		end)
		b.MouseButton1Click:Connect(function()
			State.themeName = theme.name
			if theme.color then
				State.uiRGB = false
				applyAccent(theme.color, false)
			else
				State.uiRGB = true
			end
			updateDashboard()
			showToast("Theme: " .. theme.name, PALETTE.GOOD)
		end)
	end

	sectionTitle(themePage, "CUSTOM COLOR")

	local customBox = makeTextBox(themePage, "Hex code e.g. FF3366", "", 34)
	local applyBtn = makeButton(themePage, "APPLY CUSTOM COLOR", { height = 34 })
	applyBtn.MouseButton1Click:Connect(function()
		local c = hexToColor(customBox.Text)
		if not c then
			playSound("ERROR")
			showToast("Invalid hex color.", PALETTE.BAD)
			return
		end
		State.uiRGB = false
		State.themeName = "Custom"
		applyAccent(c, false)
		updateDashboard()
		showToast("Custom color applied.", PALETTE.GOOD)
	end)
end

--// ==========================================================================
--// 15. SETTINGS PAGE
--// ==========================================================================
do
	sectionTitle(settPage, "INTERFACE")

	makeSlider(settPage, "UI Scale", CONFIG.UI_SCALE_MIN, CONFIG.UI_SCALE_MAX, State.uiScale, 2, function(v)
		State.uiScale = v
		updateScale()
	end)

	makeToggle(settPage, "Animations", State.animations, function(v)
		State.animations = v
	end)

	makeToggle(settPage, "Sound Effects", State.sound, function(v)
		State.sound = v
		if v then
			playSound("CLICK")
		end
	end)

	makeToggle(settPage, "RGB UI Accent", State.uiRGB, function(v)
		State.uiRGB = v
		if v then
			State.themeName = "RGB Rainbow"
		else
			applyAccent(State.uiAccent, false)
		end
	end)

	sectionTitle(settPage, "ROLEPLAY NAME / BIO")

	makeToggle(settPage, "Rainbow Name", State.rpNameEnabled, function(v)
		State.rpNameEnabled = v
	end)

	makeToggle(settPage, "Rainbow Bio", State.rpBioEnabled, function(v)
		State.rpBioEnabled = v
	end)

	local rpNameBox = makeTextBox(settPage, "Roleplay name text", CONFIG.RP_NAME, 34)
	rpNameBox.FocusLost:Connect(function()
		CONFIG.RP_NAME = rpNameBox.Text
	end)

	local rpBioBox = makeTextBox(settPage, "Roleplay bio text", CONFIG.RP_BIO, 34)
	rpBioBox.FocusLost:Connect(function()
		CONFIG.RP_BIO = rpBioBox.Text
	end)

	sectionTitle(settPage, "DEFAULTS")

	local resetBtn = makeButton(settPage, "RESTORE DEFAULT SETTINGS", {
		height = 36,
		color = Color3.fromRGB(90, 60, 30),
	})
	resetBtn.MouseButton1Click:Connect(function()
		State.delay = CONFIG.DEFAULT_DELAY
		State.mode = CONFIG.DEFAULT_MODE
		State.randomWords = false
		State.animations = true
		State.sound = true
		State.uiScale = 1
		State.uiRGB = true
		State.themeName = "RGB Rainbow"
		State.rpNameEnabled = true
		State.rpBioEnabled = true
		State.patternIndex = 1
		updateScale()
		updateDashboard()
		showToast("Settings restored to defaults.", PALETTE.WARN)
	end)
end

--// ==========================================================================
--// 16. INFO PAGE
--// ==========================================================================
do
	local infoCard = card(infoPage, 190)
	new("UIListLayout", {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, infoCard)
	new("UIPadding", {
		PaddingTop = UDim.new(0, 14),
		PaddingBottom = UDim.new(0, 14),
		PaddingLeft = UDim.new(0, 14),
		PaddingRight = UDim.new(0, 14),
	}, infoCard)

	local function infoLine(text, bold)
		return new("TextLabel", {
			Size = UDim2.new(1, 0, 0, 16),
			BackgroundTransparency = 1,
			Text = text,
			Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham,
			TextSize = 11,
			TextColor3 = bold and PALETTE.TEXT or PALETTE.SUBTEXT,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, infoCard)
	end

	infoLine("AXER SPAMMER V2", true)
	infoLine("Creator: Axer (Ashar)")
	infoLine("Script: V2 Premium Edition")
	infoLine("Support: Brookhaven / All Games")
	infoLine("Themes: 8 presets + custom hex")
	infoLine("Modes: Normal / Clean / Loaded / Custom / Random")

	sectionTitle(infoPage, "NOTES")

	local noteCard = card(infoPage, 96)
	local note = new("TextLabel", {
		Size = UDim2.new(1, -24, 1, -20),
		Position = UDim2.new(0, 12, 0, 10),
		BackgroundTransparency = 1,
		Text = "Use a reasonable delay so the game's chat system stays stable. "
			.. "Changing theme stops the old RGB loop automatically. "
			.. "Admin commands work only for the configured UserId.",
		Font = Enum.Font.Gotham,
		TextSize = 10,
		TextColor3 = PALETTE.SUBTEXT,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
	}, noteCard)
end

--// ==========================================================================
--// 17. DASHBOARD REFRESH
--// ==========================================================================
function updateDashboard()
	if not UI.statusLabel then return end

	local running = State.spamming and not State.paused
	local paused = State.spamming and State.paused

	UI.statusLabel.Text = running and "RUNNING" or (paused and "PAUSED" or "STOPPED")
	UI.statusLabel.TextColor3 = running and PALETTE.GOOD or (paused and PALETTE.WARN or PALETTE.BAD)
	UI.statusDot.BackgroundColor3 = UI.statusLabel.TextColor3
	UI.statusSub.Text = string.format("Mode: %s  •  Delay: %.1fs", State.mode, State.delay)

	UI.statPlayer.Text = LocalPlayer.DisplayName
	UI.statUserId.Text = tostring(LocalPlayer.UserId)
	UI.statMessages.Text = tostring(State.messagesSent)
	UI.statRuntime.Text = formatTime(State.runtime)
	UI.statMode.Text = State.mode
	UI.statTheme.Text = State.themeName

	if UI.startBtn then
		UI.startBtn.Text = State.spamming and "● ACTIVE" or "START"
		UI.startBtn.BackgroundColor3 = State.spamming and PALETTE.ELEMENT or Color3.fromRGB(28, 90, 55)
		UI.pauseBtn.Text = State.paused and "RESUME" or "PAUSE"
		UI.pauseBtn.BackgroundColor3 = State.paused and Color3.fromRGB(120, 90, 30) or PALETTE.ELEMENT
		UI.stopBtn.BackgroundColor3 = State.spamming and Color3.fromRGB(120, 35, 45) or PALETTE.ELEMENT
	end
end

--// ==========================================================================
--// 18. CONTROL FUNCTIONS
--// ==========================================================================
function startSpam()
	if State.spamming then
		showToast("Spammer is already running.", PALETTE.WARN)
		return
	end

	local hasContent = (State.message ~= nil and #State.message > 0) or State.randomWords
	if not hasContent then
		playSound("ERROR")
		showToast("Enter a message or enable Random Words.", PALETTE.BAD)
		return
	end

	State.spamming = true
	State.paused = false
	playSound("START")
	showToast("Spammer started.", PALETTE.GOOD)
	updateDashboard()
end

function stopSpam()
	if not State.spamming then
		showToast("Spammer is already stopped.", PALETTE.WARN)
		return
	end
	State.spamming = false
	State.paused = false
	playSound("STOP")
	showToast("Spammer stopped.", PALETTE.BAD)
	updateDashboard()
end

function togglePause()
	if not State.spamming then
		showToast("Nothing to pause.", PALETTE.WARN)
		return
	end
	State.paused = not State.paused
	playSound("CLICK")
	showToast(State.paused and "Paused." or "Resumed.", PALETTE.WARN)
	updateDashboard()
end

UI.startBtn.MouseButton1Click:Connect(startSpam)
UI.stopBtn.MouseButton1Click:Connect(stopSpam)
UI.pauseBtn.MouseButton1Click:Connect(togglePause)

--// ==========================================================================
--// 19. TAB NAVIGATION
--// ==========================================================================
for name, btn in pairs(tabButtons) do
	btn.MouseButton1Click:Connect(function()
		showPage(name)
	end)
end

--// ==========================================================================
--// 20. MINIMIZE / CLOSE
--// ==========================================================================
minBtn.MouseButton1Click:Connect(function()
	playSound("CLICK")
	window.Visible = false
	floatBtn.Visible = true
	showToast("Minimized. Spammer keeps running.", PALETTE.TEXT)
end)

closeBtn.MouseButton1Click:Connect(function()
	playSound("STOP")
	State.spamming = false
	State.paused = false
	updateDashboard()
	window.Visible = false
	floatBtn.Visible = true
	showToast("Closed. Spammer stopped.", PALETTE.BAD)
end)

--// ==========================================================================
--// 21. ROLEPLAY NAME / BIO REMOTE LOOP
--// ==========================================================================
local RP = { name = nil, color = nil }

task.spawn(function()
	local ok, re = pcall(function()
		return ReplicatedStorage:WaitForChild("RE", 20)
	end)
	if not ok or not re then
		return
	end
	local okName, nameRemote = pcall(function()
		return re:WaitForChild("1RPNam1eTex1t", 10)
	end)
	local okColor, colorRemote = pcall(function()
		return re:WaitForChild("1RPNam1eColo1r", 10)
	end)
	if okName then RP.name = nameRemote end
	if okColor then RP.color = colorRemote end
end)

task.spawn(function()
	while true do
		if RP.name or RP.color then
			local rainbow = Color3.fromHSV((tick() % 6) / 6, 1, 1)
			local nameColor = State.rpNameEnabled and rainbow or State.uiAccent
			local bioColor = State.rpBioEnabled and rainbow or State.uiAccent

			pcall(function()
				if RP.name then
					RP.name:FireServer("RolePlayName", CONFIG.RP_NAME, nameColor)
					RP.name:FireServer("RolePlayBio", CONFIG.RP_BIO, bioColor)
				end
				if RP.color then
					RP.color:FireServer("PickingRPNameColor", nameColor)
					RP.color:FireServer("PickingRPBioColor", bioColor)
				end
			end)
		end
		task.wait(CONFIG.RP_UPDATE_RATE)
	end
end)

--// ==========================================================================
--// 22. UI ACCENT (RGB) LOOP — single loop, never duplicated
--// ==========================================================================
task.spawn(function()
	while true do
		if State.uiRGB then
			applyAccent(Color3.fromHSV((tick() % 6) / 6, 0.85, 1), true)
		end
		task.wait(0.06)
	end
end)

--// ==========================================================================
--// 23. MAIN SPAM LOOP — single loop, interruptible
--// ==========================================================================
local function waitInterruptible(seconds)
	local elapsed = 0
	while elapsed < seconds do
		if not State.spamming or State.paused then
			return false
		end
		local step = math.min(0.1, seconds - elapsed)
		task.wait(step)
		elapsed = elapsed + step
	end
	return State.spamming and not State.paused
end

task.spawn(function()
	while true do
		if State.spamming and not State.paused then
			local msg = buildMessage()
			if msg and #msg > 0 then
				local ok = sendMessage(msg)
				if ok then
					State.messagesSent = State.messagesSent + 1
					updateDashboard()
				end
			end
			waitInterruptible(State.delay)
		else
			task.wait(0.1)
		end
	end
end)

--// ==========================================================================
--// 24. RUNTIME TICKER
--// ==========================================================================
task.spawn(function()
	while true do
		task.wait(1)
		if State.spamming and not State.paused then
			State.runtime = State.runtime + 1
		end
		updateDashboard()
	end
end)

--// ==========================================================================
--// 25. ADMIN COMMANDS
--// ==========================================================================
local function statusText()
	return string.format(
		"Status: %s | Mode: %s | Delay: %.1fs | Sent: %d",
		State.spamming and (State.paused and "PAUSED" or "RUNNING") or "STOPPED",
		State.mode,
		State.delay,
		State.messagesSent
	)
end

local function handleAdminCommand(speaker, message)
	if not speaker or speaker.UserId ~= CONFIG.ADMIN_USER_ID then
		return
	end
	if type(message) ~= "string" or #message == 0 then
		return
	end

	local args = string.split(message, " ")
	local cmd = (args[1] or ""):lower()

	if cmd == "!target" then
		local target = message:sub(#args[1] + 1):match("^%s*(.-)%s*$")
		if not target or target == "" then
			showToast("Admin: !target requires a name.", PALETTE.WARN)
			return
		end
		State.message = target
		if UI.messageBox then
			UI.messageBox.Text = target
		end
		showToast("Admin set target: " .. target, PALETTE.GOOD)

	elseif cmd == "!start" then
		startSpam()

	elseif cmd == "!stop" then
		stopSpam()

	elseif cmd == "!pause" then
		togglePause()

	elseif cmd == "!status" then
		showToast(statusText(), PALETTE.TEXT)
	end
end

local function bindPlayer(plr)
	if plr == LocalPlayer then
		return
	end
	plr.Chatted:Connect(function(msg)
		handleAdminCommand(plr, msg)
	end)
end

for _, plr in ipairs(Players:GetPlayers()) do
	bindPlayer(plr)
end
Players.PlayerAdded:Connect(bindPlayer)

--// ==========================================================================
--// 26. BOOT
--// ==========================================================================
applyAccent(State.uiAccent, true)
updateScale()
showPage("Home")
updateDashboard()

local camera = workspace.CurrentCamera
if camera then
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	local cam = workspace.CurrentCamera
	if cam then
		cam:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
	end
	updateScale()
end)

showToast("AXER SPAMMER V2 loaded.", PALETTE.GOOD)