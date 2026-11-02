-- Delegated V5 handles all 3D character skeletal animations; keep GuardianAnimator as a safe compatibility shim.
local A = {}
function A.Init()
	script:SetAttribute("PlaybackInitialized", true)
end
function A.Action(ch, action, combo) end
function A.Reset(ch) end
return A
