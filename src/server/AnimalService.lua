-- Spawns animal pairs, wandering/fleeing AI, leading, and boarding arks.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local MapBuilder = require(script.Parent.MapBuilder)
local BuildService = require(script.Parent.BuildService)
local Net = require(script.Parent.Net)

local AnimalService = {}
local animals = {}
local leadCount = {}

local function weld(a, b)
	local w = Instance.new("WeldConstraint")
	w.Part0 = a
	w.Part1 = b
	w.Parent = a
	return w
end

local function makeAnimal(spec, gender, pos)
	local m = Instance.new("Model")
	m.Name = spec.Name

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = spec.Size
	root.Color = spec.Color
	root.Material = Enum.Material.SmoothPlastic
	root.CustomPhysicalProperties = PhysicalProperties.new(0.25, 0.5, 0.1)
	root.CFrame = CFrame.new(pos)
	root.Parent = m

	local hs = math.min(spec.Size.X, spec.Size.Y) * 0.75
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(hs, hs, hs)
	head.Color = spec.Color
	head.Material = Enum.Material.SmoothPlastic
	head.Massless = true
	head.CanCollide = false
	head.CFrame = root.CFrame * CFrame.new(0, spec.Size.Y * 0.35, -spec.Size.Z / 2 - hs * 0.3)
	weld(root, head)
	head.Parent = m

	for _, o in { { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 } } do
		local leg = Instance.new("Part")
		leg.Name = "Leg"
		leg.Size = Vector3.new(0.6, 1.2, 0.6)
		leg.Color = spec.Color:Lerp(Color3.new(0, 0, 0), 0.3)
		leg.Massless = true
		leg.CanCollide = false
		leg.CFrame = root.CFrame * CFrame.new(o[1] * (spec.Size.X / 2 - 0.4), -spec.Size.Y / 2 - 0.6, o[2] * (spec.Size.Z / 2 - 0.5))
		weld(root, leg)
		leg.Parent = m
	end

	local hum = Instance.new("Humanoid")
	hum.RigType = Enum.HumanoidRigType.R15
	hum.HipHeight = 1.2
	hum.WalkSpeed = spec.Speed
	hum.RequiresNeck = false
	hum.BreakJointsOnDeath = false
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.Parent = m
	m.PrimaryPart = root

	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(170, 36)
	bb.StudsOffset = Vector3.new(0, spec.Size.Y / 2 + 2.5, 0)
	bb.MaxDistance = 120
	bb.Parent = root
	local tl = Instance.new("TextLabel")
	tl.Size = UDim2.fromScale(1, 1)
	tl.BackgroundTransparency = 1
	tl.Font = Enum.Font.FredokaOne
	tl.TextScaled = true
	tl.TextStrokeTransparency = 0.3
	tl.TextColor3 = Config.RARITY_COLORS[spec.Rarity]
	tl.Text = spec.Name .. (gender == "M" and " ♂" or " ♀")
	tl.Parent = bb

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Lead"
	prompt.ObjectText = spec.Name .. " (" .. spec.Rarity .. ")"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = root

	m.Parent = workspace.Animals
	pcall(function()
		root:SetNetworkOwner(nil)
	end)
	return m, root, hum, prompt
end

local function spawnPos(spec)
	for _ = 1, 10 do
		local h = spec.MinH + math.random() * (spec.MaxH - spec.MinH)
		local y = math.max(Config.PLOT_Y + 6, h * MapBuilder.PEAK_Y)
		local d = MapBuilder.RadiusAt(y) * (0.85 + math.random() * 0.15)
		local a = math.random() * math.pi * 2
		local x, z = math.cos(a) * d, math.sin(a) * d
		local g = MapBuilder.GroundAt(x, z)
		if g then
			return Vector3.new(x, g + spec.Size.Y / 2 + 3, z)
		end
	end
	return Vector3.new(0, MapBuilder.PEAK_Y + 5, 0)
end

local function setLeader(a, player)
	if a.Leader then
		leadCount[a.Leader] = math.max(0, (leadCount[a.Leader] or 1) - 1)
	end
	a.Leader = player
	if player then
		leadCount[player] = (leadCount[player] or 0) + 1
	end
end

local function usedSlots(plot)
	local used = 0
	for _, a in animals do
		if a.State == "Aboard" and a.Plot == plot then used += a.Spec.Slots or 1 end
	end
	return used
end

local function tryBoard(a, plot)
	if os.clock() < (a.NoBoardUntil or 0) then return false end
	local best, bd
	for _, p in plot.Cells do
		local d = (p.Position - a.Root.Position).Magnitude
		if not bd or d < bd then best, bd = p, d end
	end
	if not best or bd > 12 then return false end
	if usedSlots(plot) + (a.Spec.Slots or 1) > BuildService.Capacity(plot) then
		if plot.Owner then Net.Notify(plot.Owner, "Your ark is full! Add Stables for more room.") end
		return false
	end
	-- Stand on the highest block in that column
	local top = best
	for _, p in plot.Cells do
		local flat = (p.Position - best.Position) * Vector3.new(1, 0, 1)
		if flat.Magnitude < 1 and p.Position.Y > top.Position.Y then top = p end
	end
	local jitter = Vector3.new(math.random() - 0.5, 0, math.random() - 0.5)
	local pos = top.Position + Vector3.new(0, top.Size.Y / 2 + a.Spec.Size.Y / 2 + 1.2, 0) + jitter
	a.Model:PivotTo(CFrame.new(pos) * top.CFrame.Rotation)
	a.Hum.PlatformStand = true
	a.Weld = weld(a.Root, top)
	a.State = "Aboard"
	a.Plot = plot
	setLeader(a, nil)
	a.Prompt.ActionText = "Unload"
	if plot.Owner then Net.Notify(plot.Owner, "🐾 " .. a.Spec.Name .. " is aboard!", true) end
	return true
end

local function makeWild(a)
	if a.Weld then a.Weld:Destroy() end
	a.Weld = nil
	a.Plot = nil
	a.Hum.PlatformStand = false
	a.State = "Wild"
	setLeader(a, nil)
	a.Prompt.ActionText = "Lead"
end

local function onPrompt(a, player)
	if a.State == "Wild" then
		if (leadCount[player] or 0) >= Config.MAX_LEAD then
			Net.Notify(player, "You can lead 2 animals at once. Bring them to your ark!", true)
			return
		end
		a.State = "Led"
		setLeader(a, player)
		a.Prompt.ActionText = "Let go"
	elseif a.State == "Led" and a.Leader == player then
		makeWild(a)
	elseif a.State == "Aboard" and a.Plot and a.Plot.Owner == player then
		if (leadCount[player] or 0) >= Config.MAX_LEAD then
			Net.Notify(player, "You can lead 2 animals at once. Bring them to your ark!", true)
			return
		end
		makeWild(a)
		a.NoBoardUntil = os.clock() + 6
		a.State = "Led"
		setLeader(a, player)
		a.Prompt.ActionText = "Let go"
	end
end

function AnimalService.Reset()
	for _, a in animals do
		if a.Model then a.Model:Destroy() end
	end
	table.clear(animals)
	table.clear(leadCount)
	local extra = math.floor(#Players:GetPlayers() / 4)
	for _, spec in ipairs(Config.SPECIES) do
		local n = spec.Pairs + (spec.Rarity == "Common" and extra or 0)
		for _ = 1, n do
			for _, g in { "M", "F" } do
				local m, root, hum, prompt = makeAnimal(spec, g, spawnPos(spec))
				local a = { Model = m, Root = root, Hum = hum, Prompt = prompt, Spec = spec, Gender = g, State = "Wild", WanderAt = 0 }
				prompt.Triggered:Connect(function(player)
					onPrompt(a, player)
				end)
				table.insert(animals, a)
			end
		end
	end
end

local function tick()
	local water = ReplicatedStorage:GetAttribute("WaterLevel") or Config.SEA_Y
	for _, a in animals do
		if not a.Model.Parent then continue end
		local pos = a.Root.Position

		if a.State == "Aboard" then
			if not (a.Weld and a.Weld.Parent and a.Weld.Part1 and a.Weld.Part1.Parent) then
				makeWild(a) -- its block was destroyed
			end
		elseif a.State == "Led" then
			local char = a.Leader and a.Leader.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if not hrp or (hrp.Position - pos).Magnitude > 80 then
				makeWild(a)
			else
				local plot = BuildService.GetPlot(a.Leader)
				if not (plot and plot.Ark and tryBoard(a, plot)) then
					local away = pos - hrp.Position
					local offset = away.Magnitude > 0.1 and away.Unit * 5 or Vector3.zero
					a.Hum:MoveTo(hrp.Position + offset)
				end
			end
		else
			if water > pos.Y - a.Spec.Size.Y - 6 then
				-- Water's coming: run uphill toward the centre
				a.Hum:MoveTo(Vector3.new(pos.X * 0.6, pos.Y + 10, pos.Z * 0.6))
			elseif os.clock() > a.WanderAt then
				a.WanderAt = os.clock() + math.random(3, 7)
				local t = pos + Vector3.new(math.random(-18, 18), 0, math.random(-18, 18))
				local flat = Vector3.new(t.X, 0, t.Z)
				local maxD = MapBuilder.RadiusAt(math.max(a.Spec.MinH * MapBuilder.PEAK_Y, water + 8))
				if flat.Magnitude > maxD then
					flat = flat.Unit * maxD
					t = Vector3.new(flat.X, t.Y, flat.Z)
				end
				a.Hum:MoveTo(t)
			end
		end
	end
end

-- Pairs = min(males, females) per species still safely aboard and attached.
function AnimalService.CountFor(plot)
	local water = ReplicatedStorage:GetAttribute("WaterLevel") or Config.SEA_Y
	local by = {}
	for _, a in animals do
		if a.State == "Aboard" and a.Plot == plot and plot.Root
			and a.Weld and a.Weld.Part1 and a.Weld.Part1.Parent
			and a.Root.AssemblyRootPart == plot.Root.AssemblyRootPart
			and a.Root.Position.Y > water - 6 then
			local s = by[a.Spec.Name] or { M = 0, F = 0, Spec = a.Spec }
			s[a.Gender] += 1
			by[a.Spec.Name] = s
		end
	end
	local result = {}
	for _, s in by do
		local n = math.min(s.M, s.F)
		if n > 0 then table.insert(result, { Spec = s.Spec, Pairs = n }) end
	end
	return result
end

function AnimalService.OnPlayerLeft(player)
	for _, a in animals do
		if a.Leader == player then makeWild(a) end
	end
	leadCount[player] = nil
end

function AnimalService.Start()
	task.spawn(function()
		while true do
			local ok, err = pcall(tick)
			if not ok then warn("[Animals] " .. tostring(err)) end
			task.wait(0.4)
		end
	end)
end

return AnimalService
