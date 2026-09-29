-- Block types players can build their ark with.
-- Density below water (1.0) means it floats. Hull is sturdy but heavier.
local Defs = {
	Wood   = { Order = 1, Size = Vector3.new(4, 4, 4),   Color = Color3.fromRGB(163, 112, 70),  Material = Enum.Material.WoodPlanks, HP = 3, Density = 0.35 },
	Plank  = { Order = 2, Size = Vector3.new(4, 1, 4),   Offset = Vector3.new(0, -1.5, 0), Color = Color3.fromRGB(200, 155, 105), Material = Enum.Material.WoodPlanks, HP = 2, Density = 0.3 },
	Hull   = { Order = 3, Size = Vector3.new(4, 4, 4),   Color = Color3.fromRGB(88, 60, 40),    Material = Enum.Material.Wood,       HP = 8, Density = 0.5 },
	Stable = { Order = 4, Size = Vector3.new(4, 4, 4),   Color = Color3.fromRGB(225, 190, 95),  Material = Enum.Material.Fabric,     HP = 4, Density = 0.3, Capacity = 2 },
	Sail   = { Order = 5, Size = Vector3.new(0.6, 4, 4), Color = Color3.fromRGB(245, 245, 240), Material = Enum.Material.Fabric,     HP = 2, Density = 0.2 },
}

local List = {}
for name, def in Defs do
	def.Name = name
	table.insert(List, name)
end
table.sort(List, function(a, b) return Defs[a].Order < Defs[b].Order end)

return { Defs = Defs, List = List }
