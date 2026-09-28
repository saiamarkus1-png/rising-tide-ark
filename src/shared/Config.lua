-- Rising Tide Ark: all tunable numbers live here.
local Config = {}

Config.GAME_NAME = "Rising Tide Ark"

-- Building grid (Build a Boat style)
Config.CELL = 4            -- studs per grid cell
Config.PLOT_CELLS = 10     -- dock footprint is 10 x 10 cells
Config.MAX_HEIGHT = 8      -- max layers tall
Config.MAX_BLOCKS = 250

-- Map
Config.PLOT_COUNT = 8
Config.PLOT_RADIUS = 160   -- distance of docks from island centre
Config.PLOT_Y = 6          -- top surface height of the docks
Config.SEA_Y = 0           -- normal sea level
Config.FLOOD_TOP_Y = 92    -- water level at the end of the flood (island peak is 76). Multiple of 4.
Config.MAP_SIZE = 960

-- Round flow
Config.PHASES = {
	{ Name = "Intermission", Time = 15 },
	{ Name = "Build",        Time = 150 },
	{ Name = "Flood",        Time = 180 },
	{ Name = "Voyage",       Time = 75 },
	{ Name = "Results",      Time = 12 },
}

-- Economy
Config.START_COINS = 0
Config.START_INVENTORY = { Wood = 60, Plank = 40, Hull = 0, Stable = 2, Sail = 1 }
Config.BLOCK_PRICES = { Wood = 4, Plank = 2, Hull = 20, Stable = 60, Sail = 35 }
Config.COINS_PER_PAIR = 40
Config.SURVIVAL_BONUS = 25

-- Animals
Config.BASE_CAPACITY = 4   -- animal slots every ark has; each Stable adds more
Config.MAX_LEAD = 2        -- animals a player can lead at once (a pair!)

-- Storm
Config.STORM_INTERVAL = 2.5
Config.SHATTER_FRACTION = 0.35  -- ark breaks apart if it drops below 35% of its blocks

Config.RARITY_COLORS = {
	Common    = Color3.fromRGB(235, 235, 235),
	Uncommon  = Color3.fromRGB(110, 230, 120),
	Rare      = Color3.fromRGB(90, 170, 255),
	Legendary = Color3.fromRGB(255, 200, 60),
}

-- MinH/MaxH = where on the island they live (0 = beach, 1 = peak).
-- Slots = how much ark space one animal takes.
Config.SPECIES = {
	{ Name = "Sheep",        Rarity = "Common",    Color = Color3.fromRGB(240, 238, 230), Size = Vector3.new(3, 2.6, 4),     Speed = 10, MinH = 0.05, MaxH = 0.3,  Pairs = 2, Bonus = 0,   Slots = 1 },
	{ Name = "Pig",          Rarity = "Common",    Color = Color3.fromRGB(242, 170, 180), Size = Vector3.new(3, 2.4, 4),     Speed = 10, MinH = 0.05, MaxH = 0.3,  Pairs = 2, Bonus = 0,   Slots = 1 },
	{ Name = "Cow",          Rarity = "Common",    Color = Color3.fromRGB(95, 72, 60),    Size = Vector3.new(3.6, 3.4, 5.5), Speed = 9,  MinH = 0.1,  MaxH = 0.35, Pairs = 2, Bonus = 0,   Slots = 1 },
	{ Name = "Zebra",        Rarity = "Uncommon",  Color = Color3.fromRGB(210, 210, 210), Size = Vector3.new(3.2, 3.6, 5.5), Speed = 14, MinH = 0.2,  MaxH = 0.5,  Pairs = 1, Bonus = 20,  Slots = 1 },
	{ Name = "Lion",         Rarity = "Uncommon",  Color = Color3.fromRGB(215, 160, 70),  Size = Vector3.new(3.4, 3.4, 5.5), Speed = 14, MinH = 0.25, MaxH = 0.55, Pairs = 1, Bonus = 30,  Slots = 1 },
	{ Name = "Giraffe",      Rarity = "Rare",      Color = Color3.fromRGB(230, 180, 80),  Size = Vector3.new(3.2, 6, 5),     Speed = 12, MinH = 0.3,  MaxH = 0.6,  Pairs = 1, Bonus = 60,  Slots = 2 },
	{ Name = "Elephant",     Rarity = "Rare",      Color = Color3.fromRGB(140, 140, 150), Size = Vector3.new(6, 6, 8),       Speed = 8,  MinH = 0.35, MaxH = 0.6,  Pairs = 1, Bonus = 80,  Slots = 2 },
	{ Name = "Penguin",      Rarity = "Uncommon",  Color = Color3.fromRGB(40, 40, 50),    Size = Vector3.new(1.8, 2.6, 1.8), Speed = 10, MinH = 0.62, MaxH = 0.8,  Pairs = 1, Bonus = 40,  Slots = 1 },
	{ Name = "Snow Leopard", Rarity = "Rare",      Color = Color3.fromRGB(225, 225, 235), Size = Vector3.new(3, 2.8, 5),     Speed = 16, MinH = 0.72, MaxH = 0.9,  Pairs = 1, Bonus = 100, Slots = 1 },
	{ Name = "Golden Deer",  Rarity = "Legendary", Color = Color3.fromRGB(255, 205, 60),  Size = Vector3.new(2.8, 3.4, 4.5), Speed = 18, MinH = 0.9,  MaxH = 1.0,  Pairs = 1, Bonus = 300, Slots = 1 },
}

return Config
