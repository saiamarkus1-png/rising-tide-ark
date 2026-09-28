-- Generates the island (terrain), docks, trees and lighting at server start.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local Config = require(ReplicatedStorage.Shared.Config)

local MapBuilder = {}
MapBuilder.PEAK_Y = 76
MapBuilder.BASE_Y = -28
local BASE_R, PEAK_R = 150, 8

-- Radius of the island at a given height (it's a cone-shaped mountain).
function MapBuilder.RadiusAt(y)
	local t = math.clamp((y - MapBuilder.BASE_Y) / (MapBuilder.PEAK_Y - MapBuilder.BASE_Y), 0, 1)
	return BASE_R + (PEAK_R - BASE_R) * t
end

-- Finds the ground height at an x/z position.
function MapBuilder.GroundAt(x, z)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { workspace.Terrain }
	params.IgnoreWater = true
	local hit = workspace:Raycast(Vector3.new(x, 200, z), Vector3.new(0, -300, 0), params)
	return hit and hit.Position.Y or nil
end

local function part(props, parent)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		p[k] = v
	end
	p.Parent = parent
	return p
end

local function buildIsland()
	local terrain = workspace.Terrain
	terrain:Clear()
	terrain:FillBlock(CFrame.new(0, MapBuilder.BASE_Y - 4, 0), Vector3.new(Config.MAP_SIZE, 8, Config.MAP_SIZE), Enum.Material.Sand)
	for y = MapBuilder.BASE_Y, MapBuilder.PEAK_Y, 4 do
		local mat
		if y >= 60 then
			mat = Enum.Material.Snow
		elseif y >= 44 then
			mat = Enum.Material.Rock
		elseif y <= 4 then
			mat = Enum.Material.Sand
		else
			mat = Enum.Material.Grass
		end
		terrain:FillCylinder(CFrame.new(0, y, 0), 4, MapBuilder.RadiusAt(y), mat)
	end
end

local function buildTrees(folder)
	for _ = 1, 30 do
		local a = math.random() * math.pi * 2
		local d = MapBuilder.RadiusAt(40) + math.random() * (MapBuilder.RadiusAt(10) - MapBuilder.RadiusAt(40))
		local x, z = math.cos(a) * d, math.sin(a) * d
		local g = MapBuilder.GroundAt(x, z)
		if g then
			local h = math.random(10, 16)
			part({ Name = "Trunk", Size = Vector3.new(2, h, 2), CFrame = CFrame.new(x, g + h / 2, z),
				Material = Enum.Material.Wood, Color = Color3.fromRGB(105, 70, 45) }, folder)
			part({ Name = "Leaves", Shape = Enum.PartType.Ball, Size = Vector3.new(10, 10, 10), CFrame = CFrame.new(x, g + h + 2, z),
				Material = Enum.Material.Grass, Color = Color3.fromRGB(70, 160, 70) }, folder)
		end
	end
end

local function buildPlots(mapFolder)
	local plotsFolder = Instance.new("Folder")
	plotsFolder.Name = "Plots"
	plotsFolder.Parent = mapFolder

	local bases = {}
	local size = Config.PLOT_CELLS * Config.CELL
	local centre = Vector3.new(0, Config.PLOT_Y - 0.5, 0)

	for i = 1, Config.PLOT_COUNT do
		local a = (i - 1) / Config.PLOT_COUNT * math.pi * 2
		local dir = Vector3.new(math.cos(a), 0, math.sin(a))
		local pos = dir * Config.PLOT_RADIUS + centre

		local model = Instance.new("Model")
		model.Name = "Plot" .. i
		model.Parent = plotsFolder

		-- Dock the ark is built on. Its LookVector faces the island.
		local base = part({ Name = "Base", Size = Vector3.new(size, 1, size), CFrame = CFrame.lookAt(pos, centre),
			Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(120, 85, 55) }, model)
		table.insert(bases, base)

		for _, c in { { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 } } do
			part({ Name = "Leg", Size = Vector3.new(2, 40, 2),
				CFrame = base.CFrame * CFrame.new(c[1] * (size / 2 - 1), -20.5, c[2] * (size / 2 - 1)),
				Material = Enum.Material.Wood, Color = Color3.fromRGB(80, 55, 35) }, model)
		end

		-- Walkway from island to dock
		local inner = Config.PLOT_RADIUS - size / 2
		local outer = MapBuilder.RadiusAt(Config.PLOT_Y) - 6
		local len = inner - outer
		local mid = dir * (outer + len / 2) + centre
		part({ Name = "Walkway", Size = Vector3.new(8, 1, len + 1), CFrame = CFrame.lookAt(mid, centre),
			Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(140, 100, 65) }, model)

		-- Name sign
		local board = part({ Name = "SignBoard", Size = Vector3.new(12, 4, 0.5),
			CFrame = base.CFrame * CFrame.new(size / 2 - 7, 5, -size / 2 - 0.5),
			Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(90, 60, 40), CanCollide = false }, model)
		for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
			local sg = Instance.new("SurfaceGui")
			sg.Face = face
			sg.PixelsPerStud = 40
			sg.Parent = board
			local label = Instance.new("TextLabel")
			label.Name = "Sign"
			label.Size = UDim2.fromScale(1, 1)
			label.BackgroundTransparency = 1
			label.Font = Enum.Font.FredokaOne
			label.TextScaled = true
			label.TextColor3 = Color3.new(1, 1, 1)
			label.Text = "Free Dock"
			label.Parent = sg
		end
		part({ Name = "Post", Size = Vector3.new(0.6, 5, 0.6), CFrame = board.CFrame * CFrame.new(0, -4.5, 0),
			Material = Enum.Material.Wood, Color = Color3.fromRGB(80, 55, 35), CanCollide = false }, model)
	end
	return bases
end

local function setupLighting()
	Lighting.ClockTime = 14
	Lighting.Brightness = 2.5
	local atm = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
	atm.Density = 0.3
	atm.Haze = 1
	atm.Parent = Lighting
end

function MapBuilder.Build()
	local mapFolder = Instance.new("Folder")
	mapFolder.Name = "Map"
	mapFolder.Parent = workspace

	for _, n in { "Arks", "Animals", "Effects" } do
		local f = Instance.new("Folder")
		f.Name = n
		f.Parent = workspace
	end

	buildIsland()
	local treeFolder = Instance.new("Folder")
	treeFolder.Name = "Trees"
	treeFolder.Parent = mapFolder
	buildTrees(treeFolder)
	setupLighting()

	return { Plots = buildPlots(mapFolder) }
end

return MapBuilder
