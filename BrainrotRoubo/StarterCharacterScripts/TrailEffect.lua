-- LocalScript: StarterCharacterScripts > TrailEffect
-- Trilha de partículas colorida — desbloqueada ao atingir Rebirth 5 ou Prestígio 1

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")

local player   = Players.LocalPlayer
local char     = player.Character or player.CharacterAdded:Wait()
local humanoid = char:WaitForChild("Humanoid")
local rootPart = char:WaitForChild("HumanoidRootPart")

-- Verifica se tem trilha desbloqueada via leaderstats
local function hasTrailUnlocked()
    local ls = player:FindFirstChild("leaderstats")
    if not ls then return false end
    local rb = ls:FindFirstChild("Rebirths")
    local pr = ls:FindFirstChild("Prestígio")
    return (rb and rb.Value >= 5) or (pr and pr.Value >= 1)
end

if not hasTrailUnlocked() then
    -- Verifica de novo após um tempo (pode ainda estar carregando)
    task.wait(5)
    if not hasTrailUnlocked() then return end
end

-- Cria a trilha de partículas
local att = Instance.new("Attachment")
att.Position = Vector3.new(0, -2, 0)
att.Parent = rootPart

local pe = Instance.new("ParticleEmitter")
pe.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(80,  200, 255)),
    ColorSequenceKeypoint.new(0.4, Color3.fromRGB(160, 80,  255)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(255, 80,  160)),
})
pe.Size = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.28),
    NumberSequenceKeypoint.new(0.5, 0.18),
    NumberSequenceKeypoint.new(1, 0),
})
pe.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.2),
    NumberSequenceKeypoint.new(1, 1),
})
pe.Lifetime       = NumberRange.new(0.35, 0.7)
pe.Rate           = 0     -- controlado pelo loop
pe.Speed          = NumberRange.new(0, 2)
pe.SpreadAngle    = Vector2.new(180, 180)
pe.RotSpeed       = NumberRange.new(-180, 180)
pe.Rotation       = NumberRange.new(0, 360)
pe.LightEmission  = 1
pe.LightInfluence = 0
pe.Parent = att

-- Ativa partículas apenas ao se mover
RunService.RenderStepped:Connect(function()
    if not char.Parent then return end
    pe.Rate = humanoid.MoveDirection.Magnitude > 0.1 and 30 or 0
end)
