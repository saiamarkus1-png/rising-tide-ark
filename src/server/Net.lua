-- Remote access + throttled notifications.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local Net = { Remotes = Remotes }
local lastNotify = {}

function Net.Notify(player, msg, force)
	local now = os.clock()
	local key = player.UserId .. msg
	if not force and lastNotify[key] and now - lastNotify[key] < 3 then return end
	lastNotify[key] = now
	Remotes.Notify:FireClient(player, msg)
end

function Net.Broadcast(msg)
	Remotes.Notify:FireAllClients(msg)
end

return Net
