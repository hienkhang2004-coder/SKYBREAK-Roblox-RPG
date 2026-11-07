-- SKYBREAK: Fragments of the Core — Server Remote Rate Limiter & Payload Validator (P0-05)
-- Location: ServerScriptService/Services/RemoteGuard.lua

local Players = game:GetService("Players")

local RemoteGuard = {}

RemoteGuard.Channels = {
	Combat = { Rate = 20, Burst = 25 },
	Ability = { Rate = 15, Burst = 20 },
	UI = { Rate = 8, Burst = 12 },
	Equipment = { Rate = 6, Burst = 10 },
	Interact = { Rate = 8, Burst = 12 },
	Appearance = { Rate = 4, Burst = 6 },
	Native = { Rate = 1, Burst = 2, MaxSessionCalls = 40 },
}

local playerBuckets = {}

local function getPlayerKey(player)
	if type(player) == "table" or typeof(player) == "Instance" then
		local uid = tonumber(player.UserId)
		if uid and uid ~= 0 then
			return uid
		end
		return player
	end
	return player
end

function RemoteGuard.ResetPlayer(player)
	local key = getPlayerKey(player)
	if key ~= nil then
		playerBuckets[key] = nil
	end
end

function RemoteGuard.Allow(player, channelName)
	if player == nil then
		return false
	end
	local cfg = RemoteGuard.Channels[channelName or "UI"] or RemoteGuard.Channels.UI
	local key = getPlayerKey(player)
	local pState = playerBuckets[key]
	if not pState then
		pState = {}
		playerBuckets[key] = pState
	end

	local now = os.clock()
	local b = pState[channelName]
	if not b then
		b = {
			Tokens = cfg.Burst,
			LastRefill = now,
			SessionCalls = 0,
		}
		pState[channelName] = b
	else
		local elapsed = math.max(0, now - b.LastRefill)
		b.LastRefill = now
		b.Tokens = math.min(cfg.Burst, b.Tokens + elapsed * cfg.Rate)
	end

	if cfg.MaxSessionCalls and b.SessionCalls >= cfg.MaxSessionCalls then
		return false
	end

	if b.Tokens < 1 then
		return false
	end

	b.Tokens -= 1
	b.SessionCalls += 1
	return true
end

function RemoteGuard.SanitizeString(val, maxLen)
	if type(val) ~= "string" then
		return nil
	end
	local limit = tonumber(maxLen) or 64
	if #val > limit then
		return string.sub(val, 1, limit)
	end
	return val
end

function RemoteGuard.SanitizeNumber(val, minVal, maxVal, defaultVal)
	local n = tonumber(val)
	if not n or n ~= n or n == math.huge or n == -math.huge then
		return defaultVal or minVal or 0
	end
	if minVal ~= nil and n < minVal then
		n = minVal
	end
	if maxVal ~= nil and n > maxVal then
		n = maxVal
	end
	return n
end

function RemoteGuard.ValidatePayload(payload, maxDepth)
	local depthLimit = tonumber(maxDepth) or 4
	local function check(v, depth)
		if depth > depthLimit then
			return false
		end
		local t = type(v)
		if t == "nil" or t == "boolean" then
			return true
		elseif t == "number" then
			return v == v and v ~= math.huge and v ~= -math.huge
		elseif t == "string" then
			return #v <= 512
		elseif t == "table" then
			local count = 0
			for k, sub in pairs(v) do
				count += 1
				if count > 64 then
					return false
				end
				if type(k) == "string" and #k > 64 then
					return false
				end
				if not check(sub, depth + 1) then
					return false
				end
			end
			return true
		elseif t == "vector" or typeof(v) == "Vector3" or typeof(v) == "CFrame" or typeof(v) == "Color3" then
			return true
		end
		return false
	end
	return check(payload, 0)
end

function RemoteGuard.WrapEvent(channelName, fn)
	return function(player, ...)
		if not RemoteGuard.Allow(player, channelName) then
			return
		end
		return fn(player, ...)
	end
end

function RemoteGuard.WrapInvoke(channelName, fn, fallbackReturn)
	return function(player, ...)
		if not RemoteGuard.Allow(player, channelName) then
			return fallbackReturn
		end
		return fn(player, ...)
	end
end

pcall(function()
	Players.PlayerRemoving:Connect(function(player)
		RemoteGuard.ResetPlayer(player)
	end)
end)

return RemoteGuard
