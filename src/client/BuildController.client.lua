-- Build a Boat style building: ghost preview, place, rotate, delete. Works with mouse and touch.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Blocks = require(Shared:WaitForChild("Blocks"))
local Grid = require(Shared:WaitForChild("Grid"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local buildOn = false
local selected = Blocks.List[1]
local rot = 0
local deleteMode = false
local target = nil

local ghost = Instance.new("Part")
ghost.Name = "BuildGhost"
ghost.Anchored = true
ghost.CanCollide = false
ghost.CanQuery = false
ghost.CanTouch = false
ghost.Material = Enum.Material.SmoothPlastic
ghost.Transparency = 1
ghost.Parent = workspace

local selBox = Instance.new("SelectionBox")
selBox.Color3 = Color3.fromRGB(255, 70, 70)
selBox.LineThickness = 0.08
selBox.Parent = ghost

local function canBuild()
	local phase = ReplicatedStorage:GetAttribute("Phase")
	return phase == "Build" or phase == "Intermission"
end

local function myBase()
	local idx = player:GetAttribute("Plot")
	local map = workspace:FindFirstChild("Map")
	local plots = map and map:FindFirstChild("Plots")
	local plot = idx and plots and plots:FindFirstChild("Plot" .. idx)
	return plot and plot:FindFirstChild("Base")
end

local function myArk()
	local idx = player:GetAttribute("Plot")
	local arks = workspace:FindFirstChild("Arks")
	return idx and arks and arks:FindFirstChild("Ark" .. idx)
end

local function cast(ray)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignore = { ghost }
	if player.Character then table.insert(ignore, player.Character) end
	local animals = workspace:FindFirstChild("Animals")
	if animals then table.insert(ignore, animals) end
	params.FilterDescendantsInstances = ignore
	params.IgnoreWater = true
	return workspace:Raycast(ray.Origin, ray.Direction * 400, params)
end

-- Works out which cell the pointer is aiming at.
local function computeTarget(ray)
	target = nil
	ghost.Transparency = 1
	selBox.Adornee = nil
	if not (buildOn and canBuild()) then return end
	local base, ark = myBase(), myArk()
	if not base then return end
	local hit = cast(ray)
	if not hit then return end
	local part = hit.Instance
	local isMine = ark and part:IsDescendantOf(ark) and part:GetAttribute("GX") ~= nil

	if deleteMode then
		if isMine then
			selBox.Adornee = part
			target = { Delete = true, x = part:GetAttribute("GX"), y = part:GetAttribute("GY"), z = part:GetAttribute("GZ") }
		end
		return
	end

	local x, y, z
	if isMine then
		local n = base.CFrame:VectorToObjectSpace(hit.Normal)
		x = part:GetAttribute("GX") + math.round(n.X)
		y = part:GetAttribute("GY") + math.round(n.Y)
		z = part:GetAttribute("GZ") + math.round(n.Z)
	elseif part == base then
		x, y, z = Grid.WorldToCell(base, hit.Position + hit.Normal * 0.05)
	else
		return
	end
	if not Grid.InBounds(x, y, z) then return end

	local def = Blocks.Defs[selected]
	ghost.Size = def.Size
	ghost.CFrame = Grid.CellCFrame(base, x, y, z, rot) * CFrame.new(def.Offset or Vector3.zero)
	local has = (player:GetAttribute("Inv_" .. selected) or 0) > 0
	ghost.Color = has and Color3.fromRGB(90, 255, 120) or Color3.fromRGB(255, 80, 80)
	ghost.Transparency = 0.45
	target = { x = x, y = y, z = z }
end

local function act()
	if not target then return end
	if target.Delete then
		Remotes.RemoveBlock:FireServer(target.x, target.y, target.z)
	else
		Remotes.PlaceBlock:FireServer(selected, target.x, target.y, target.z, rot)
	end
end

------------------------------------------------------------------ UI
local gui = Instance.new("ScreenGui")
gui.Name = "BuildGui"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local NORMAL = Color3.fromRGB(40, 60, 90)

local function button(text, order)
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(74, 60)
	b.BackgroundColor3 = NORMAL
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Font = Enum.Font.FredokaOne
	b.TextScaled = true
	b.Text = text
	b.LayoutOrder = order
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 12)
	c.Parent = b
	local s = Instance.new("UIStroke")
	s.Thickness = 2
	s.Color = Color3.new(1, 1, 1)
	s.Transparency = 0.6
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = b
	local pad = Instance.new("UIPadding")
	pad.PaddingTop, pad.PaddingBottom = UDim.new(0, 4), UDim.new(0, 4)
	pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 4), UDim.new(0, 4)
	pad.Parent = b
	return b
end

local bar = Instance.new("Frame")
bar.AnchorPoint = Vector2.new(0.5, 1)
bar.Position = UDim2.new(0.5, 0, 1, -12)
bar.Size = UDim2.fromOffset(0, 60)
bar.AutomaticSize = Enum.AutomaticSize.X
bar.BackgroundTransparency = 1
bar.Parent = gui
local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 8)
layout.Parent = bar

-- Shrink the bar on narrow screens so it fits phones
local barScale = Instance.new("UIScale")
barScale.Parent = bar
local function updateScale()
	barScale.Scale = math.clamp(camera.ViewportSize.X / 900, 0.55, 1)
end
camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
updateScale()

local toggleBtn = button("🔨 Build", 0)
toggleBtn.BackgroundColor3 = Color3.fromRGB(230, 140, 40)
toggleBtn.Parent = bar

local blockButtons = {}
local rotBtn = button("↻ Turn", 100)
local delBtn = button("🗑 Delete", 101)

local refresh
refresh = function()
	local ok = canBuild()
	toggleBtn.Visible = ok
	toggleBtn.Text = buildOn and "✔ Done" or "🔨 Build"
	for name, b in blockButtons do
		b.Visible = ok and buildOn
		b.Text = name .. "\n×" .. (player:GetAttribute("Inv_" .. name) or 0)
		b.BackgroundColor3 = (name == selected and not deleteMode) and Color3.fromRGB(60, 170, 90) or NORMAL
	end
	rotBtn.Visible = ok and buildOn
	delBtn.Visible = ok and buildOn
	delBtn.BackgroundColor3 = deleteMode and Color3.fromRGB(200, 60, 60) or NORMAL
end

for i, name in ipairs(Blocks.List) do
	local b = button(name, i)
	b.Parent = bar
	blockButtons[name] = b
	b.Activated:Connect(function()
		selected = name
		deleteMode = false
		refresh()
	end)
end
rotBtn.Parent = bar
delBtn.Parent = bar

toggleBtn.Activated:Connect(function()
	buildOn = not buildOn
	refresh()
end)
rotBtn.Activated:Connect(function()
	rot = (rot + 1) % 4
end)
delBtn.Activated:Connect(function()
	deleteMode = not deleteMode
	refresh()
end)

player.AttributeChanged:Connect(refresh)
ReplicatedStorage:GetAttributeChangedSignal("Phase"):Connect(function()
	if not canBuild() then buildOn = false end
	refresh()
end)
refresh()

------------------------------------------------------------------ Input
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.B and canBuild() then
		buildOn = not buildOn
		refresh()
	elseif input.KeyCode == Enum.KeyCode.R then
		rot = (rot + 1) % 4
	elseif input.KeyCode == Enum.KeyCode.X then
		deleteMode = not deleteMode
		refresh()
	elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
		act()
	else
		local numbers = { Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four, Enum.KeyCode.Five }
		for i, kc in ipairs(numbers) do
			if input.KeyCode == kc and Blocks.List[i] then
				selected = Blocks.List[i]
				deleteMode = false
				refresh()
			end
		end
	end
end)

-- Mobile: tap the dock/ark to place or delete
UserInputService.TouchTapInWorld:Connect(function(position, processed)
	if processed then return end
	computeTarget(camera:ScreenPointToRay(position.X, position.Y))
	act()
end)

RunService.RenderStepped:Connect(function()
	if UserInputService.MouseEnabled then
		local m = UserInputService:GetMouseLocation()
		computeTarget(camera:ViewportPointToRay(m.X, m.Y))
	elseif not (buildOn and canBuild()) then
		ghost.Transparency = 1
		selBox.Adornee = nil
	end
end)
