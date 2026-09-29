-- Saves coins, block inventory, the ark layout and species collected.
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

local DataService = {}
local cache = {}
local store
local ok = pcall(function()
	store = DataStoreService:GetDataStore("RisingTideArk_v1")
end)
if not ok then
	warn("[Data] DataStore unavailable. In Studio: Game Settings > Security > Enable Studio Access to API Services.")
end

local function default()
	return { Coins = Config.START_COINS, Inventory = table.clone(Config.START_INVENTORY), Ark = {}, Species = {} }
end

function DataService.Load(player)
	local data
	if store then
		local success, result = pcall(function()
			return store:GetAsync("p_" .. player.UserId)
		end)
		if success and type(result) == "table" then
			data = result
		end
	end
	data = data or default()
	local d = default()
	for k, v in d do
		if data[k] == nil then data[k] = v end
	end
	for k, v in d.Inventory do
		if data.Inventory[k] == nil then data.Inventory[k] = v end
	end
	cache[player] = data

	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Parent = ls
	local saved = Instance.new("IntValue")
	saved.Name = "Species"
	saved.Parent = ls
	ls.Parent = player

	DataService.Sync(player)
	return data
end

function DataService.Get(player)
	return cache[player]
end

-- Pushes data to attributes the client UI reads.
function DataService.Sync(player)
	local d = cache[player]
	if not d then return end
	player:SetAttribute("Coins", d.Coins)
	for name, count in d.Inventory do
		player:SetAttribute("Inv_" .. name, count)
	end
	local n = 0
	for _ in d.Species do n += 1 end
	player:SetAttribute("SpeciesSaved", n)
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		ls.Coins.Value = d.Coins
		ls.Species.Value = n
	end
end

function DataService.Save(player)
	local d = cache[player]
	if not (d and store) then return end
	local success, err = pcall(function()
		store:SetAsync("p_" .. player.UserId, d)
	end)
	if not success then warn("[Data] Save failed: " .. tostring(err)) end
end

function DataService.Release(player)
	DataService.Save(player)
	cache[player] = nil
end

function DataService.All()
	return cache
end

return DataService
