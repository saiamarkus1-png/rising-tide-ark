-- Round loop: Intermission -> Build -> Flood -> Voyage -> Results.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local Config = require(ReplicatedStorage.Shared.Config)
local BuildService = require(script.Parent.BuildService)
local AnimalService = require(script.Parent.AnimalService)
local WaterService = require(script.Parent.WaterService)
local DataService = require(script.Parent.DataService)
local Net = require(script.Parent.Net)

local RoundService = {}
local nextStorm = 0

local function mood(stormy)
	local info = TweenInfo.new(6)
	TweenService:Create(Lighting, info, {
		ClockTime = stormy and 17.6 or 14,
		Brightness = stormy and 0.8 or 2.5,
	}):Play()
	local atm = Lighting:FindFirstChildOfClass("Atmosphere")
	if atm then
		TweenService:Create(atm, info, {
			Density = stormy and 0.55 or 0.3,
			Color = stormy and Color3.fromRGB(120, 130, 150) or Color3.fromRGB(200, 215, 230),
		}):Play()
	end
end

local function teleportAll()
	for _, player in Players:GetPlayers() do
		local char = player.Character
		local cf = BuildService.SpawnCFrame(player)
		if char and cf then char:PivotTo(cf) end
	end
end

local Handlers = {}

function Handlers.IntermissionEnter()
	mood(false)
	WaterService.Reset()
	BuildService.RebuildAll()
	AnimalService.Reset()
	teleportAll()
	Net.Broadcast("☀️ New round! Build your ark and bring animals aboard in PAIRS.")
end

function Handlers.BuildEnter()
	Net.Broadcast("🌥️ Dark clouds are gathering... build fast and find pairs!")
end

function Handlers.FloodEnter()
	mood(true)
	BuildService.LaunchAll()
	Net.Broadcast("🌧️ THE FLOOD HAS BEGUN! Get to your ark!")
end

function Handlers.FloodTick(elapsed, total)
	local f = math.clamp(elapsed / total, 0, 1) ^ 1.3
	WaterService.SetLevel(Config.SEA_Y + (Config.FLOOD_TOP_Y - Config.SEA_Y) * f)
end

function Handlers.VoyageEnter()
	WaterService.SetLevel(Config.FLOOD_TOP_Y)
	nextStorm = 0
	Net.Broadcast("⛈️ The storm hits! Hold your ark together!")
end

function Handlers.VoyageTick()
	if os.clock() < nextStorm then return end
	nextStorm = os.clock() + Config.STORM_INTERVAL
	for _, plot in ipairs(BuildService.Plots) do
		if plot.Owner and plot.Ark and plot.BlockCount > 0 then
			if math.random() < 0.6 then BuildService.Strike(plot) end
			if math.random() < 0.5 then BuildService.Wave(plot) end
		end
	end
end

function Handlers.ResultsEnter()
	mood(false)
	for _, plot in ipairs(BuildService.Plots) do
		local player = plot.Owner
		local data = player and DataService.Get(player)
		if data then
			local results = AnimalService.CountFor(plot)
			local coins, pairs, lines, newSpecies = 0, 0, {}, 0
			for _, r in results do
				pairs += r.Pairs
				coins += r.Pairs * (Config.COINS_PER_PAIR + r.Spec.Bonus)
				if not data.Species[r.Spec.Name] then
					data.Species[r.Spec.Name] = true
					newSpecies += 1
				end
				table.insert(lines, r.Pairs .. "x " .. r.Spec.Name)
			end
			local survived = plot.BlockCount > 0 and not plot.Shattered
			if survived then coins += Config.SURVIVAL_BONUS end
			data.Coins += coins

			local msg = "🌈 The flood is over!\n"
			if pairs > 0 then
				msg ..= "Pairs saved: " .. table.concat(lines, ", ") .. "\n"
			else
				msg ..= "No pairs saved this time.\n"
			end
			if newSpecies > 0 then msg ..= "✨ " .. newSpecies .. " new species for your Sanctuary!\n" end
			msg ..= "+" .. coins .. " coins"
			Net.Notify(player, msg, true)
			DataService.Sync(player)
			task.spawn(DataService.Save, player)
		end
	end
end

function RoundService.Run()
	while true do
		for _, phase in ipairs(Config.PHASES) do
			ReplicatedStorage:SetAttribute("Phase", phase.Name)
			ReplicatedStorage:SetAttribute("PhaseEnds", workspace:GetServerTimeNow() + phase.Time)
			local enter = Handlers[phase.Name .. "Enter"]
			if enter then
				local ok, err = pcall(enter)
				if not ok then warn("[Round] " .. phase.Name .. ": " .. tostring(err)) end
			end
			local tickFn = Handlers[phase.Name .. "Tick"]
			local start = os.clock()
			while os.clock() - start < phase.Time do
				if tickFn then
					local ok, err = pcall(tickFn, os.clock() - start, phase.Time)
					if not ok then warn("[Round] tick: " .. tostring(err)) end
				end
				task.wait(0.25)
			end
		end
	end
end

return RoundService
