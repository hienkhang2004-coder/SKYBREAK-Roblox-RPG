local rs=game:GetService("ReplicatedStorage")
local remotes=rs:FindFirstChild("Remotes") or Instance.new("Folder",rs) remotes.Name="Remotes"
for _,name in ipairs({"CombatRequest","AbilityRequest","InteractRequest","EquipmentRequest","StateUpdate","CombatFX","AppearanceRequest"}) do
    if not remotes:FindFirstChild(name) then local event=Instance.new("RemoteEvent") event.Name=name event.Parent=remotes end
end
require(script.Parent.Services.SkybornMeshService).Start()
require(script.Parent.Services.GameService).Start()

require(script.Parent.Services.EnvironmentService).Apply("GoldenSky")
