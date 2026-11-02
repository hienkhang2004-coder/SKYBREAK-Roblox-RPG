-- Auto-generated Clean3D Gameplay3x Physics Collider Module for FrozenCyber
-- All Part.Size components strictly <= 1700 studs (< 2048 Roblox limit).
local M = {}

local CYL_ROT = CFrame.Angles(0, 0, math.pi * 0.5)

local CYL = {
	{531.3,42.25,-65,8,100.36},
	{-324.3,40.9,224.2,12,216.93},
	{-379.5,40.9,534.8,12,232},
	{0,40.9,-462,12,438.84},
	{0,40.9,0,12,390.51},
	{905,40.9,-195,12,160.3},
	{-605,40.9,145,12,156},
	{515,40.9,-802,12,168.32},
	{-445,40.9,-472,12,168.36},
	{295,40.9,-962,12,144},
	{610,40.9,-475,12,293.36},
	{-108,40.9,622,12,136},
	{-342,40.9,-208,12,184},
}

local BLK = {
	{-226.84,44.94,156.82,35.82,6,27.2,0.6049,0.0579},
	{-199.09,45.96,137.64,33.11,6,27.2,0.6049},
	{-171.34,44.94,118.45,35.82,6,27.2,0.6049,-0.0579},
	{-517.02,44.72,169.82,42.4,6,22.2,-0.275,0.035},
	{-478.19,45.45,180.78,39.72,6,22.2,-0.275},
	{-439.37,44.72,191.73,42.4,6,22.2,-0.275,-0.035},
	{-357.57,44.71,411.39,36.46,6,22.2,1.3949,0.0413},
	{-351.55,45.45,377.51,33.78,6,22.2,1.3949},
	{-345.53,44.71,343.64,36.46,6,22.2,1.3949,-0.0413},
	{-257.6,44.71,573.95,40.72,6,22.2,-0.3108,0.0366},
	{-220.78,45.45,585.78,38.04,6,22.2,-0.3108},
	{-183.97,44.71,597.6,40.72,6,22.2,-0.3108,-0.0366},
	{0,44.88,-238.11,21.47,6,31.2,-1.5708,0.104},
	{0,45.96,-218.78,31.2,6,18.7},
	{0,44.88,-199.46,21.47,6,31.2,-1.5708,-0.104},
	{206.72,44.97,-25.29,52.38,6,27.2,0.1217,0.0383},
	{256.66,45.96,-31.4,49.69,6,27.2,0.1217},
	{306.6,44.97,-37.51,52.38,6,27.2,0.1217,-0.0383},
	{-252.61,44.72,-153.63,44.63,6,22.2,-0.5464,0.0331},
	{-216.23,45.45,-131.51,41.95,6,22.2,-0.5464},
	{-179.86,44.72,-109.39,44.63,6,22.2,-0.5464,-0.0331},
	{736.08,44.72,-136.24,44.66,6,22.2,0.3348,0.0331},
	{776.33,45.45,-150.24,41.99,6,22.2,0.3348},
	{816.57,44.72,-164.24,44.66,6,22.2,0.3348,-0.0331},
	{570.82,44.7,-270.86,30.24,6,22.2,1.3812,0.0508},
	{576.13,45.45,-298.54,27.55,6,22.2,1.3812},
	{581.44,44.7,-326.21,30.24,6,22.2,1.3812,-0.0508},
	{364.51,44.72,-911.45,45.6,6,22.2,-0.6288,0.0323},
	{399.73,45.45,-885.83,42.93,6,22.2,-0.6288},
	{434.95,44.72,-860.22,45.6,6,22.2,-0.6288,-0.0323},
	{542.62,44.72,-706.93,41.71,6,22.2,-1.288,0.0356},
	{553.69,45.45,-668.84,39.04,6,22.2,-1.288},
	{564.75,44.72,-630.75,41.71,6,22.2,-1.288,-0.0356},
	{-410.22,44.72,-382.86,42.41,6,22.2,-1.1988,0.035},
	{-395.55,45.45,-345.26,39.73,6,22.2,-1.1988},
	{-380.89,44.72,-307.67,42.41,6,22.2,-1.1988,-0.035},
	{655.21,40.9,-40.35,160.32,12,86.55,-0.1963},
	{636.35,40.9,5.19,160.32,12,86.55,-0.589},
	{601.49,40.9,40.05,160.32,12,86.55,-0.9818},
	{555.95,40.9,58.91,160.32,12,86.55,-1.3744},
	{506.65,40.9,58.91,160.32,12,86.55,1.3744},
	{461.11,40.9,40.05,160.32,12,86.55,0.9818},
	{426.25,40.9,5.19,160.32,12,86.55,0.589},
	{407.39,40.9,-40.35,160.32,12,86.55,0.1963},
	{407.39,40.9,-89.65,160.32,12,86.55,-0.1963},
	{426.25,40.9,-135.19,160.32,12,86.55,-0.589},
	{461.11,40.9,-170.05,160.32,12,86.55,-0.9818},
	{506.65,40.9,-188.91,160.32,12,86.55,-1.3744},
	{555.95,40.9,-188.91,160.32,12,86.55,1.3744},
	{601.49,40.9,-170.05,160.32,12,86.55,0.9818},
	{636.35,40.9,-135.19,160.32,12,86.55,0.589},
	{655.21,40.9,-89.65,160.32,12,86.55,0.1963},
	{-441.99,44.12,566.14,40.06,6,12.5,0.4133},
}

function M.Build(parent, origin)
	parent = parent or workspace:FindFirstChild("FrozenCyber") or workspace
	local folder = parent:FindFirstChild("FrozenCyber_Collision")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "FrozenCyber_Collision"
		folder.Parent = parent
	else
		folder:ClearAllChildren()
	end

	local hasOrigin = (typeof(origin) == "Vector3")
	local baseCF = hasOrigin and CFrame.new(origin) or nil
	local idx = 0

	for _, c in ipairs(CYL) do
		idx += 1
		local p = Instance.new("Part")
		p.Name = "FrozenCyber_Floor_" .. idx
		p.Shape = Enum.PartType.Cylinder
		p.Anchored = true
		p.CanCollide = true
		p.CanQuery = true
		p.CanTouch = true
		p.CastShadow = false
		p.Transparency = 1
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Size = Vector3.new(c[4], c[5], c[5])
		local lcf = CFrame.new(c[1], c[2], c[3]) * CYL_ROT
		p.CFrame = hasOrigin and (baseCF * lcf) or lcf
		p.Parent = folder
	end

	for _, b in ipairs(BLK) do
		idx += 1
		local p = Instance.new("Part")
		p.Name = "FrozenCyber_Floor_" .. idx
		p.Shape = Enum.PartType.Block
		p.Anchored = true
		p.CanCollide = true
		p.CanQuery = true
		p.CanTouch = true
		p.CastShadow = false
		p.Transparency = 1
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Size = Vector3.new(b[4], b[5], b[6])
		local lcf = CFrame.new(b[1], b[2], b[3])
		local yaw = b[7]
		local slp = b[8]
		if yaw and yaw ~= 0 then
			lcf = lcf * CFrame.Angles(0, yaw, 0)
		end
		if slp and slp ~= 0 then
			lcf = lcf * CFrame.Angles(0, 0, slp)
		end
		p.CFrame = hasOrigin and (baseCF * lcf) or lcf
		p.Parent = folder
	end

	folder:SetAttribute("ColliderCount", idx)
	return folder
end

M.CYL = CYL
M.BLK = BLK

setmetatable(M, {
	__call = function(_, parent, origin)
		return M.Build(parent, origin)
	end,
})

return M
