-- Grid math shared by server (validation) and client (ghost preview).
local Config = require(script.Parent.Config)

local Grid = {}
local CELL = Config.CELL
local HALF = Config.PLOT_CELLS / 2

function Grid.CellCFrame(base, x, y, z, r)
	local offset = Vector3.new((x - HALF + 0.5) * CELL, base.Size.Y / 2 + (y + 0.5) * CELL, (z - HALF + 0.5) * CELL)
	return base.CFrame * CFrame.new(offset) * CFrame.Angles(0, math.rad(90 * (r or 0)), 0)
end

function Grid.WorldToCell(base, pos)
	local l = base.CFrame:PointToObjectSpace(pos)
	return math.floor(l.X / CELL + HALF), math.floor((l.Y - base.Size.Y / 2) / CELL), math.floor(l.Z / CELL + HALF)
end

function Grid.InBounds(x, y, z)
	return x >= 0 and x < Config.PLOT_CELLS and z >= 0 and z < Config.PLOT_CELLS and y >= 0 and y < Config.MAX_HEIGHT
end

function Grid.IsInt(v)
	return type(v) == "number" and v == v and v == math.floor(v) and math.abs(v) < 1000
end

return Grid
