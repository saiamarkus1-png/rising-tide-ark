-- Rising flood using real Terrain water, so arks float with physics (like Build a Boat).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local MapBuilder = require(script.Parent.MapBuilder)

local WaterService = {}
local terrain = workspace.Terrain
local HALF = Config.MAP_SIZE / 2
local filledTo = Config.SEA_Y

-- Only swaps Air <-> Water, so the island's grass/rock is never overwritten.
local function replaceRange(y0, y1, from, to)
	local y = y0
	while y < y1 do
		local top = math.min(y + 8, y1)
		local region = Region3.new(Vector3.new(-HALF, y, -HALF), Vector3.new(HALF, top, HALF)):ExpandToGrid(4)
		local ok, err = pcall(function()
			terrain:ReplaceMaterial(region, 4, from, to)
		end)
		if not ok then
			warn("[Water] " .. tostring(err))
		end
		y = top
	end
end

function WaterService.Reset()
	replaceRange(Config.SEA_Y, Config.FLOOD_TOP_Y + 12, Enum.Material.Water, Enum.Material.Air)
	replaceRange(MapBuilder.BASE_Y, Config.SEA_Y, Enum.Material.Air, Enum.Material.Water)
	filledTo = Config.SEA_Y
	ReplicatedStorage:SetAttribute("WaterLevel", filledTo)
end

function WaterService.SetLevel(y)
	y = math.min(y, Config.FLOOD_TOP_Y)
	if y >= filledTo + 4 then
		local newTop = filledTo + math.floor((y - filledTo) / 4) * 4
		replaceRange(filledTo, newTop, Enum.Material.Air, Enum.Material.Water)
		filledTo = newTop
		ReplicatedStorage:SetAttribute("WaterLevel", filledTo)
	end
end

function WaterService.GetLevel()
	return filledTo
end

return WaterService
