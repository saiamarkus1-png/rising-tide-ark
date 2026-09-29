-- Phase timer, water level, coins, notifications and the block shop.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Blocks = require(Shared:WaitForChild("Blocks"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local PHASE_INFO = {
	Intermission = { "☀️ Get Ready", Color3.fromRGB(255, 210, 90) },
	Build        = { "🔨 Build & Gather Pairs", Color3.fromRGB(120, 220, 120) },
	Flood        = { "🌧️ THE FLOOD", Color3.fromRGB(90, 170, 255) },
	Voyage       = { "⛈️ THE STORM", Color3.fromRGB(200, 120, 255) },
	Results      = { "🌈 Results", Color3.fromRGB(255, 160, 200) },
}

local gui = Instance.new("ScreenGui")
gui.Name = "HUD"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local function corner(p, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 12)
	c.Parent = p
end

local function label(parent, props)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.FredokaOne
	l.TextScaled = true
	l.TextColor3 = Color3.new(1, 1, 1)
	for k, v in props do l[k] = v end
	l.Parent = parent
	return l
end

-- Top status panel
local top = Instance.new("Frame")
top.AnchorPoint = Vector2.new(0.5, 0)
top.Position = UDim2.new(0.5, 0, 0, 8)
top.Size = UDim2.fromOffset(340, 74)
top.BackgroundColor3 = Color3.fromRGB(20, 30, 50)
top.BackgroundTransparency = 0.25
top.Parent = gui
corner(top, 14)
local phaseLabel = label(top, { Size = UDim2.new(1, -16, 0, 34), Position = UDim2.fromOffset(8, 4) })
local timerLabel = label(top, { Size = UDim2.new(0.5, -8, 0, 28), Position = UDim2.new(0, 8, 0, 40), TextXAlignment = Enum.TextXAlignment.Left })
local waterLabel = label(top, { Size = UDim2.new(0.5, -8, 0, 28), Position = UDim2.new(0.5, 0, 0, 40), TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = Color3.fromRGB(140, 200, 255) })

-- Coins
local coins = label(gui, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 60), Size = UDim2.fromOffset(170, 40),
	BackgroundTransparency = 0.25, BackgroundColor3 = Color3.fromRGB(20, 30, 50), TextColor3 = Color3.fromRGB(255, 215, 80) })
corner(coins)

-- Toast notifications
local toast = label(gui, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 92), Size = UDim2.fromOffset(460, 120),
	TextScaled = false, TextSize = 22, TextWrapped = true, TextStrokeTransparency = 0.2, TextTransparency = 1, TextStrokeColor3 = Color3.new(0, 0, 0),
	TextYAlignment = Enum.TextYAlignment.Top })
local toastId = 0
Remotes:WaitForChild("Notify").OnClientEvent:Connect(function(msg)
	toastId += 1
	local id = toastId
	toast.Text = msg
	toast.TextTransparency = 0
	toast.TextStrokeTransparency = 0.2
	task.delay(msg:find("\n") and 8 or 3.5, function()
		if id ~= toastId then return end
		TweenService:Create(toast, TweenInfo.new(0.6), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	end)
end)

-- Shop
local shopBtn = Instance.new("TextButton")
shopBtn.AnchorPoint = Vector2.new(0, 0.5)
shopBtn.Position = UDim2.new(0, 12, 0.5, 0)
shopBtn.Size = UDim2.fromOffset(90, 56)
shopBtn.BackgroundColor3 = Color3.fromRGB(230, 140, 40)
shopBtn.Font = Enum.Font.FredokaOne
shopBtn.TextScaled = true
shopBtn.TextColor3 = Color3.new(1, 1, 1)
shopBtn.Text = "🛒 Shop"
shopBtn.Parent = gui
corner(shopBtn)

local shop = Instance.new("Frame")
shop.AnchorPoint = Vector2.new(0, 0.5)
shop.Position = UDim2.new(0, 110, 0.5, 0)
shop.Size = UDim2.fromOffset(300, 60 * #Blocks.List + 16)
shop.BackgroundColor3 = Color3.fromRGB(20, 30, 50)
shop.BackgroundTransparency = 0.1
shop.Visible = false
shop.Parent = gui
corner(shop, 14)
local list = Instance.new("UIListLayout")
list.Padding = UDim.new(0, 6)
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Parent = shop
local pad = Instance.new("UIPadding")
pad.PaddingTop, pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 8), UDim.new(0, 8), UDim.new(0, 8)
pad.Parent = shop

for i, name in ipairs(Blocks.List) do
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 54)
	row.BackgroundTransparency = 1
	row.LayoutOrder = i
	row.Parent = shop
	label(row, { Size = UDim2.new(0.5, 0, 1, 0), TextXAlignment = Enum.TextXAlignment.Left,
		Text = name .. "  🪙" .. Config.BLOCK_PRICES[name] })
	for j, amount in { 1, 10 } do
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(0.23, 0, 0.8, 0)
		b.Position = UDim2.new(0.5 + (j - 1) * 0.25, 0, 0.1, 0)
		b.BackgroundColor3 = Color3.fromRGB(60, 170, 90)
		b.Font = Enum.Font.FredokaOne
		b.TextScaled = true
		b.TextColor3 = Color3.new(1, 1, 1)
		b.Text = "+" .. amount
		b.Parent = row
		corner(b, 8)
		b.Activated:Connect(function()
			Remotes.BuyBlock:FireServer(name, amount)
		end)
	end
end
shopBtn.Activated:Connect(function()
	shop.Visible = not shop.Visible
end)

local function updateCoins()
	coins.Text = "🪙 " .. (player:GetAttribute("Coins") or 0)
end
player:GetAttributeChangedSignal("Coins"):Connect(updateCoins)
updateCoins()

RunService.Heartbeat:Connect(function()
	local phase = ReplicatedStorage:GetAttribute("Phase") or "Intermission"
	local info = PHASE_INFO[phase] or { phase, Color3.new(1, 1, 1) }
	phaseLabel.Text = info[1]
	phaseLabel.TextColor3 = info[2]
	local left = math.max(0, math.floor((ReplicatedStorage:GetAttribute("PhaseEnds") or 0) - workspace:GetServerTimeNow()))
	timerLabel.Text = string.format("⏱ %d:%02d", left // 60, left % 60)
	waterLabel.Text = "🌊 " .. math.floor(ReplicatedStorage:GetAttribute("WaterLevel") or 0) .. " m"
end)
