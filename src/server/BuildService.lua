-- Docks, grid building, saving layouts, launching and storm damage.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Blocks = require(Shared.Blocks)
local Grid = require(Shared.Grid)
local DataService = require(script.Parent.DataService)

local BuildService = {}
BuildService.Plots = {}
local plotOf = {}

local function key(x, y, z)
	return x .. "," .. y .. "," .. z
end

local function canEdit()
	local phase = ReplicatedStorage:GetAttribute("Phase")
	return phase == "Build" or phase == "Intermission"
end

local function setSign(plot, text)
	for _, d in plot.Base.Parent:GetDescendants() do
		if d:IsA("TextLabel") and d.Name == "Sign" then d.Text = text end
	end
end

function BuildService.Init(bases)
	for i, base in ipairs(bases) do
		BuildService.Plots[i] = { Index = i, Base = base, Cells = {}, BlockCount = 0 }
	end
end

local function newArk(plot)
	if plot.Ark then plot.Ark:Destroy() end
	local ark = Instance.new("Model")
	ark.Name = "Ark" .. plot.Index
	ark:SetAttribute("Plot", plot.Index)

	-- Invisible root every block welds to. Anchoring it anchors the whole ark.
	local root = Instance.new("Part")
	root.Name = "ArkRoot"
	root.Size = Vector3.new(1, 1, 1)
	root.Transparency = 1
	root.CanCollide = false
	root.CanQuery = false
	root.CanTouch = false
	root.Massless = true
	root.Anchored = true
	root.CFrame = plot.Base.CFrame * CFrame.new(0, plot.Base.Size.Y / 2 + 2, 0)
	root.Parent = ark
	ark.PrimaryPart = root
	ark.Parent = workspace.Arks

	plot.Ark, plot.Root, plot.Cells, plot.BlockCount = ark, root, {}, 0
	plot.Shattered, plot.StartBlocks = false, 0
end

local function makeBlock(plot, t, x, y, z, r)
	local def = Blocks.Defs[t]
	local p = Instance.new("Part")
	p.Name = t
	p.Size = def.Size
	p.Color = def.Color
	p.Material = def.Material
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CustomPhysicalProperties = PhysicalProperties.new(def.Density, 0.6, 0.2)
	p.CFrame = Grid.CellCFrame(plot.Base, x, y, z, r) * CFrame.new(def.Offset or Vector3.zero)
	p.Anchored = false
	p:SetAttribute("GX", x)
	p:SetAttribute("GY", y)
	p:SetAttribute("GZ", z)
	p:SetAttribute("HP", def.HP)
	local w = Instance.new("WeldConstraint")
	w.Part0 = plot.Root
	w.Part1 = p
	w.Parent = p
	p.Parent = plot.Ark
	plot.Cells[key(x, y, z)] = p
	plot.BlockCount += 1
	return p
end

function BuildService.Rebuild(plot)
	newArk(plot)
	if not plot.Owner then return end
	local data = DataService.Get(plot.Owner)
	if not data then return end
	for _, e in ipairs(data.Ark) do
		if Blocks.Defs[e.t] and Grid.InBounds(e.x, e.y, e.z) and not plot.Cells[key(e.x, e.y, e.z)] then
			makeBlock(plot, e.t, e.x, e.y, e.z, e.r or 0)
		end
	end
end

function BuildService.RebuildAll()
	for _, plot in ipairs(BuildService.Plots) do
		BuildService.Rebuild(plot)
	end
end

function BuildService.AssignPlot(player)
	for _, plot in ipairs(BuildService.Plots) do
		if not plot.Owner then
			plot.Owner = player
			plotOf[player] = plot
			player:SetAttribute("Plot", plot.Index)
			setSign(plot, player.DisplayName .. "'s Ark")
			-- Mid-flood joiners get their ark next round.
			if canEdit() then
				BuildService.Rebuild(plot)
			end
			return plot
		end
	end
	return nil
end

function BuildService.ReleasePlot(player)
	local plot = plotOf[player]
	if not plot then return end
	plotOf[player] = nil
	plot.Owner = nil
	if plot.Ark then plot.Ark:Destroy() end
	plot.Ark, plot.Root, plot.Cells, plot.BlockCount = nil, nil, {}, 0
	setSign(plot, "Free Dock")
end

function BuildService.GetPlot(player)
	return plotOf[player]
end

function BuildService.Place(player, t, x, y, z, r)
	if not canEdit() then return false, "The flood has started, no more building!" end
	local plot = plotOf[player]
	if not (plot and plot.Ark) then return false end
	if type(t) ~= "string" or not Blocks.Defs[t] then return false end
	if not (Grid.IsInt(x) and Grid.IsInt(y) and Grid.IsInt(z) and Grid.IsInt(r)) then return false end
	r = r % 4
	if not Grid.InBounds(x, y, z) then return false end
	if plot.Cells[key(x, y, z)] then return false end
	if plot.BlockCount >= Config.MAX_BLOCKS then return false, "Your ark is at max size!" end
	local data = DataService.Get(player)
	if not data then return false end
	if (data.Inventory[t] or 0) <= 0 then return false, "Out of " .. t .. "! Buy more in the Shop." end

	data.Inventory[t] -= 1
	table.insert(data.Ark, { t = t, x = x, y = y, z = z, r = r })
	makeBlock(plot, t, x, y, z, r)
	DataService.Sync(player)
	return true
end

function BuildService.Remove(player, x, y, z)
	if not canEdit() then return false end
	local plot = plotOf[player]
	if not (plot and plot.Ark) then return false end
	if not (Grid.IsInt(x) and Grid.IsInt(y) and Grid.IsInt(z)) then return false end
	local k = key(x, y, z)
	local p = plot.Cells[k]
	if not p then return false end
	local t = p.Name
	p:Destroy()
	plot.Cells[k] = nil
	plot.BlockCount -= 1

	local data = DataService.Get(player)
	if data then
		for i, e in ipairs(data.Ark) do
			if e.x == x and e.y == y and e.z == z then
				table.remove(data.Ark, i)
				break
			end
		end
		data.Inventory[t] = (data.Inventory[t] or 0) + 1
		DataService.Sync(player)
	end
	return true
end

function BuildService.Capacity(plot)
	local cap = Config.BASE_CAPACITY
	for _, p in plot.Cells do
		local def = Blocks.Defs[p.Name]
		if def and def.Capacity then cap += def.Capacity end
	end
	return cap
end

-- Top of the ark (for respawning onto it during the flood).
function BuildService.SpawnCFrame(player)
	local plot = plotOf[player]
	if not plot then return nil end
	if plot.Ark and plot.Root and not plot.Root.Anchored and plot.BlockCount > 0 then
		local cf, size = plot.Ark:GetBoundingBox()
		return CFrame.new(cf.Position + Vector3.new(0, size.Y / 2 + 4, 0))
	end
	return plot.Base.CFrame * CFrame.new(0, 6, 8)
end

local function addLadder(plot)
	local cf, size = plot.Ark:GetBoundingBox()
	local h = size.Y + 2
	local truss = Instance.new("TrussPart")
	truss.Name = "BoardingLadder"
	truss.Size = Vector3.new(2, h, 2)
	truss.CFrame = cf * CFrame.new(0, -size.Y / 2 + h / 2, -size.Z / 2 - 1.2)
	truss.Massless = true
	truss.CustomPhysicalProperties = PhysicalProperties.new(0.1, 0.3, 0)
	truss.Color = Color3.fromRGB(120, 85, 55)
	local w = Instance.new("WeldConstraint")
	w.Part0 = plot.Root
	w.Part1 = truss
	w.Parent = truss
	truss.Parent = plot.Ark
end

-- Flood starts: unanchor every ark so the rising water carries it.
function BuildService.LaunchAll()
	for _, plot in ipairs(BuildService.Plots) do
		if plot.Ark and plot.BlockCount > 0 then
			addLadder(plot)
			plot.StartBlocks = plot.BlockCount
			plot.Root.Anchored = false
			pcall(function()
				plot.Root:SetNetworkOwner(nil)
			end)
		end
	end
end

local function lightningAt(pos)
	local bolt = Instance.new("Part")
	bolt.Anchored = true
	bolt.CanCollide = false
	bolt.CanQuery = false
	bolt.Material = Enum.Material.Neon
	bolt.Color = Color3.fromRGB(200, 220, 255)
	bolt.Size = Vector3.new(0.6, 120, 0.6)
	bolt.CFrame = CFrame.new(pos + Vector3.new(0, 60, 0))
	bolt.Parent = workspace.Effects
	Debris:AddItem(bolt, 0.2)
	local ex = Instance.new("Explosion")
	ex.Position = pos
	ex.BlastPressure = 0
	ex.BlastRadius = 4
	ex.DestroyJointRadiusPercent = 0
	ex.ExplosionType = Enum.ExplosionType.NoCraters
	ex.Parent = workspace.Effects
end

function BuildService.Strike(plot)
	local list = {}
	for k, p in plot.Cells do
		table.insert(list, { k = k, p = p })
	end
	if #list == 0 then return end
	local pick = list[math.random(#list)]
	local p = pick.p
	lightningAt(p.Position)
	local hp = (p:GetAttribute("HP") or 1) - 1
	if hp <= 0 then
		p:Destroy()
		plot.Cells[pick.k] = nil
		plot.BlockCount -= 1
	else
		p:SetAttribute("HP", hp)
		p.Color = p.Color:Lerp(Color3.new(0, 0, 0), 0.25)
	end
	if not plot.Shattered and plot.StartBlocks > 0 and plot.BlockCount < plot.StartBlocks * Config.SHATTER_FRACTION then
		plot.Shattered = true
		for _, part in plot.Cells do
			local w = part:FindFirstChildOfClass("WeldConstraint")
			if w then w:Destroy() end
		end
		if plot.Owner then
			require(script.Parent.Net).Notify(plot.Owner, "💥 Your ark broke apart!", true)
		end
	end
end

function BuildService.Wave(plot)
	if plot.Root and not plot.Root.Anchored and not plot.Shattered then
		local mass = plot.Root.AssemblyMass
		local dir = Vector3.new(math.random() - 0.5, 0, math.random() - 0.5)
		if dir.Magnitude > 0 then
			plot.Root:ApplyImpulse(dir.Unit * mass * 8)
		end
		plot.Root:ApplyAngularImpulse(Vector3.new(math.random() - 0.5, 0, math.random() - 0.5) * mass * 6)
	end
end

return BuildService
