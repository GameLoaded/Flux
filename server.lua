--[[
	
	┏━━━┓ ┏┓︱︱︱ ┏┓︱┏┓ ┏━┓┏━┓   ┏━━━┓
	┃┏━━┛ ┃┃︱︱︱ ┃┃︱┃┃ ┗┓┗┛┏┛   ┃┏━┓┃
	┃┗━━┓ ┃┃︱︱︱ ┃┃︱┃┃ ︱┗┓┏┛︱   ┗┛┏┛┃
	┃┏━━┛ ┃┃︱┏┓ ┃┃︱┃┃ ︱┏┛┗┓︱   ┏┓┗┓┃
	┃┃︱︱︱ ┃┗━┛┃ ┃┗━┛┃ ┏┛┏┓┗┓   ┃┗━┛┃
	┗┛︱︱︱ ┗━━━┛ ┗━━━┛ ┗━┛┗━┛   ┗━━━
	
	█▀▀ █▀▀ █▀▀█ ▀█ █▀ █▀▀ █▀▀█
	▀▀█ █▀▀ █▄▄▀  █▄█  █▀▀ █▄▄▀
	▀▀▀ ▀▀▀ ▀ ▀▀   ▀   ▀▀▀ ▀ ▀▀
	
	Author(s): AdministratorGnar, ThunderGemios10
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--]]

-- SERVICES
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- VARIABLES
local random = math.random
local userRemoteCodes = {}

-- FUNCTIONS
local function newInstance(class, properties)
	local instance = Instance.new(class)
	for property, value in pairs(properties) do
		instance[property] = value
	end
	return instance
end

-- EVENTS
local remoteEventBin = newInstance("Folder", {Name = "Events", Parent = ReplicatedStorage})
local remoteEvent = newInstance("RemoteEvent", {Parent = remoteEventBin})
local remoteFunction = newInstance("RemoteFunction", {Parent = remoteEventBin})
local verifyFunction = newInstance("RemoteFunction", {Parent = remoteEventBin, Name = "VerifyFunction"})


-- NETWORK
local function net_new_link()
	local link = {}
	function link:InvokeClient(...)
		return remoteFunction:InvokeClient(...)
	end
	function link:FireClient(...)
		remoteEvent:FireClient(...)
	end
	function link:FireAllClients(...)
		remoteEvent:FireAllClients(...)
	end
	function link:FireAllClientsWithException(exception, ...)
		for _, player in pairs(Players:GetPlayers()) do
			if player ~= exception then
				remoteEvent:FireClient(player, ...)
			end
		end
	end
	
	function link:OnEvent(events)
		remoteEvent.OnServerEvent:Connect(function(player, code, event, ...)
			-- Connect any remote events to the ones passed in the function.
			if userRemoteCodes[player] and userRemoteCodes[player] == code and events[event] then
				events[event](player, ...)
			else
				player:Kick("Network handler failed to connect your client, please rejoin. [Invalid Event]")
				warn("Failed to pass event through FLUX NetworkHandler: "..event)
			end
		end)
	end
	function link:OnFunction(functions)
		function remoteFunction.OnServerInvoke(player, code, event, ...)
				-- Connect any remote functions to the ones passed in the function.
				if userRemoteCodes[player] and userRemoteCodes[player] == code and functions[event] then
					return functions[event](player, ...)
				else
					player:Kick("Network handler failed to connect your client, please rejoin. [Invalid Function]")
					warn("Failed to pass function through FLUX NetworkHandler: "..event)
				end
			end
		end
	return link
end

local function playerRemoving(player)
	if userRemoteCodes[player] then
		userRemoteCodes[player] = nil
	end
end	

-- REMOTE
function verifyFunction.OnServerInvoke(player)
	-- Return the code first.
	if userRemoteCodes[player] then
		-- If they have already generated a code then kick them.
		player:Kick("Network handler failed to connect your client, please rejoin. [Duplicate Token]")
	else
		-- If the server has no code on record then generate one.
		local randomGeneratedCode = math.random(10000, 99999)
		userRemoteCodes[player] = randomGeneratedCode
		
		warn("Returning "..player.Name.."'s one-time access code to remote functions and events.")
		return randomGeneratedCode
	end
end

-- PACKAGES
local packages = {}
for _, package in pairs(ReplicatedStorage:WaitForChild("Packages"):GetChildren()) do
	if not package:FindFirstChild("index") then
		error(package.Name.." does not include an index file. This package is maybe corrupted or broken.")
	end
	if packages[package.Name] then
		error("Attempted to load two or more packages by the same name ("..package..")")
	end
	packages[package.Name] = package.index
end

-- IMPORT
shared.import = function(...)
	local imports = {}
	for place, import in pairs({...}) do
		if import == "network" then
			table.insert(imports, place, net_new_link())
		elseif packages[import] then
			table.insert(imports, place, require(packages[import]))
		else
			error("Attempted to import an unknown package ("..import.."), "..debug.traceback())
		end
	end
	return unpack(imports)
end

-- CONNECTIONS
Players.PlayerRemoving:Connect(playerRemoving)
		
-- EXEC
shared.import("require")("CoreHandler")