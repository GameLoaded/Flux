--[[
	
	┏━━━┓ ┏┓︱︱︱ ┏┓︱┏┓ ┏━┓┏━┓   ┏━━━┓
	┃┏━━┛ ┃┃︱︱︱ ┃┃︱┃┃ ┗┓┗┛┏┛   ┃┏━┓┃
	┃┗━━┓ ┃┃︱︱︱ ┃┃︱┃┃ ︱┗┓┏┛︱   ┗┛┏┛┃
	┃┏━━┛ ┃┃︱┏┓ ┃┃︱┃┃ ︱┏┛┗┓︱   ┏┓┗┓┃
	┃┃︱︱︱ ┃┗━┛┃ ┃┗━┛┃ ┏┛┏┓┗┓   ┃┗━┛┃
	┗┛︱︱︱ ┗━━━┛ ┗━━━┛ ┗━┛┗━┛   ┗━━━┛
	
	█▀▀ █    ▀  █▀▀ █▀▀▄ ▀▀█▀▀
	█   █   ▀█▀ █▀▀ █  █   █  
	▀▀▀ ▀▀▀ ▀▀▀ ▀▀▀ ▀  ▀   ▀  
	
	Author(s): AdministratorGnar, ThunderGemios10
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--]]

-- SERVICES
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ScriptContext = game:GetService("ScriptContext")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- VARIABLES
local privateKey = ""
local securityCode = ""
local localPlayer = Players.LocalPlayer

-- EVENTS
local events = ReplicatedStorage:WaitForChild("Events")
local remoteEvent = events:WaitForChild("RemoteEvent")
local remoteFunction = events:WaitForChild("RemoteFunction")
local verifyFunction = events:WaitForChild("VerifyFunction")

-- NETWORK
local function net_new_link()
	local link = {}
	function link:FireServer(...)
		remoteEvent:FireServer(securityCode, ...)
	end
	function link:InvokeServer(...)
		return remoteFunction:InvokeServer(securityCode, ...)
	end
	
	function link:OnEvent(events)
		remoteEvent.OnClientEvent:Connect(function(event, ...)
			if events[event] then
				events[event](...)
			end
		end)
	end
	function link:OnFunction(functions)
		function remoteFunction.OnClientInvoke(invoke, ...)
			if functions[invoke] then
				return functions[invoke](...)
			end
		end
	end
	return link
end

-- ENCODE KEY
securityCode = verifyFunction:InvokeServer()
verifyFunction:Destroy()

-- PACKAGES
local packages = {}
for _, package in pairs(ReplicatedStorage:WaitForChild("Packages"):GetChildren()) do
	if not package:FindFirstChild("index") then
		error(package.Name.." does not include an index file. This package maybe corrupted or broken.")
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

ScriptContext.Error:Connect(function(message, trace, script)
	warn(script:GetFullName().." errored!")
	warn("Reason: "..message)
	warn("Trace: "..trace)
end)

-- EXEC
shared.import("require")("CoreHandler")
shared.import = nil
script.Parent:Destroy()