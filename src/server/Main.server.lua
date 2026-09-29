-- Entry point: creates remotes, builds the map, wires players, starts the round loop.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
for _, name in { "PlaceBlock", "RemoveBlock", "BuyBlock", "Notify" } do
	local r = Instance.new("RemoteEvent")
	r.Name = name
	r.Parent = remotes
end
remotes.Parent = ReplicatedStorage
ReplicatedStorage:SetAttribute("Phase", "Intermission")
ReplicatedStorage:SetAttribute("PhaseEnds", 0)
ReplicatedStorage:SetAttribute("WaterLevel", Config.SEA_Y)

local Server = script.Parent
local MapBuilder = require(Server.MapBuilder)
local DataService = require(Server.DataService)
local BuildService = require(Server.BuildService)
local AnimalService = require(Server.AnimalService)
local RoundService = require(Server.RoundService)
local Net = require(Server.Net)

local map = MapBuilder.Build()
BuildService.Init(map.Plots)

-- Simple per-player rate limit
local last = {}
local function allow(player, gap)
	local now = os.clock()
	if last[player] and now - last[player] < gap then return false end
	last[player] = now
	return true
end

local function onPlayerAdded(player)
	DataService.Load(player)
	if not player.Parent then
		DataService.Release(player)
		return
	end
	local plot = BuildService.AssignPlot(player)
	if not plot then
		Net.Notify(player, "All docks are taken. You can still help others save animals!", true)
	end
	player.CharacterAdded:Connect(function(char)
		task.wait(0.2)
		local cf = BuildService.SpawnCFrame(player)
		if cf then char:PivotTo(cf) end
	end)
	if player.Character then
		local cf = BuildService.SpawnCFrame(player)
		if cf then player.Character:PivotTo(cf) end
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, p in Players:GetPlayers() do
	task.spawn(onPlayerAdded, p)
end

Players.PlayerRemoving:Connect(function(player)
	AnimalService.OnPlayerLeft(player)
	BuildService.ReleasePlot(player)
	DataService.Release(player)
	last[player] = nil
end)

game:BindToClose(function()
	for _, p in Players:GetPlayers() do
		DataService.Save(p)
	end
end)

task.spawn(function()
	while true do
		task.wait(120)
		for _, p in Players:GetPlayers() do
			task.spawn(DataService.Save, p)
		end
	end
end)

remotes.PlaceBlock.OnServerEvent:Connect(function(player, t, x, y, z, r)
	if not allow(player, 0.06) then return end
	local ok, msg = BuildService.Place(player, t, x, y, z, r)
	if not ok and msg then Net.Notify(player, msg) end
end)

remotes.RemoveBlock.OnServerEvent:Connect(function(player, x, y, z)
	if not allow(player, 0.06) then return end
	BuildService.Remove(player, x, y, z)
end)

remotes.BuyBlock.OnServerEvent:Connect(function(player, t, amount)
	if type(t) ~= "string" or not Config.BLOCK_PRICES[t] then return end
	if amount ~= 1 and amount ~= 10 then return end
	local data = DataService.Get(player)
	if not data then return end
	local cost = Config.BLOCK_PRICES[t] * amount
	if data.Coins < cost then
		Net.Notify(player, "Not enough coins! Save animal pairs to earn more.", true)
		return
	end
	data.Coins -= cost
	data.Inventory[t] = (data.Inventory[t] or 0) + amount
	DataService.Sync(player)
end)

AnimalService.Start()
task.spawn(RoundService.Run)
print("[" .. Config.GAME_NAME .. "] Server started")
