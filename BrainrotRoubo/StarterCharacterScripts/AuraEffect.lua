-- LocalScript: StarterCharacterScripts > AuraEffect
-- Efeito visual de aura no personagem do jogador

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local player    = Players.LocalPlayer
local character = script.Parent
local humanoid  = character:WaitForChild("Humanoid")
local root      = character:WaitForChild("HumanoidRootPart")

local UpdateAuraRE = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("UpdateAura")

-- Cria partícula de aura no HumanoidRootPart
local attachment = Instance.new("Attachment")
attachment.Parent = root

local particles = Instance.new("ParticleEmitter")
particles.Parent        = attachment
particles.Enabled       = false
particles.Rate          = 12
particles.Lifetime      = NumberRange.new(0.6, 1.2)
particles.Speed         = NumberRange.new(2, 5)
particles.Size          = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.3),
    NumberSequenceKeypoint.new(0.5, 0.6),
    NumberSequenceKeypoint.new(1, 0),
})
particles.Transparency  = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.2),
    NumberSequenceKeypoint.new(1, 1),
})
particles.LightEmission = 1
particles.LightInfluence = 0
particles.Color         = ColorSequence.new(Color3.fromRGB(255, 215, 0))
particles.EmissionDirection = Enum.NormalId.Top
particles.SpreadAngle   = Vector2.new(60, 60)
particles.RotSpeed      = NumberRange.new(-180, 180)
particles.Rotation      = NumberRange.new(0, 360)

-- Brilho que aumenta com rebirths
local bodyLight = Instance.new("PointLight")
bodyLight.Brightness = 0
bodyLight.Range      = 0
bodyLight.Color      = Color3.fromRGB(255, 210, 50)
bodyLight.Parent     = root

-- Trilha no personagem para parecer aura fluindo
local trail = Instance.new("Trail")
trail.Lifetime         = 0.4
trail.MinLength        = 0.05
trail.FaceCamera       = true
trail.LightEmission    = 1
trail.Transparency     = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.3),
    NumberSequenceKeypoint.new(1, 1),
})
trail.Color = ColorSequence.new(Color3.fromRGB(255, 210, 0))

local att0 = Instance.new("Attachment")
att0.Position = Vector3.new(0, 1, 0)
att0.Parent   = root

local att1 = Instance.new("Attachment")
att1.Position = Vector3.new(0, -1, 0)
att1.Parent   = root

trail.Attachment0 = att0
trail.Attachment1 = att1
trail.Enabled     = false
trail.Parent      = root

-- Cores de aura por nível de rebirth (máximo 12 → prestígio)
local REBIRTH_COLORS = {
    [0]  = Color3.fromRGB(200, 200, 200), -- Comum
    [1]  = Color3.fromRGB(80,  210, 80 ), -- Incomum
    [2]  = Color3.fromRGB(60,  120, 255), -- Raro
    [3]  = Color3.fromRGB(190, 50,  255), -- Épico
    [4]  = Color3.fromRGB(255, 195, 0  ), -- Lendário
    [5]  = Color3.fromRGB(255, 50,  50 ), -- Mítico
    [6]  = Color3.fromRGB(255, 255, 120), -- God
    [7]  = Color3.fromRGB(0,   220, 200), -- Secret
    [8]  = Color3.fromRGB(255, 255, 255), -- OG
    [9]  = Color3.fromRGB(255, 100, 220), -- Além do OG I
    [10] = Color3.fromRGB(180, 80,  255), -- Além do OG II
    [11] = Color3.fromRGB(255, 160, 40 ), -- Além do OG III
    [12] = Color3.fromRGB(255, 215, 0  ), -- Máximo — Ouro Divino
}

local function getAuraColor(rebirths)
    local clamped = math.clamp(rebirths, 0, 12)
    return REBIRTH_COLORS[clamped] or Color3.fromRGB(255, 215, 0)
end

local lastRebirths = 0

UpdateAuraRE.OnClientEvent:Connect(function(payload)
    local rebirths   = payload.rebirths or 0
    local aura       = payload.aura or 0
    local auraCap    = payload.auraCap or 500
    local pct        = math.clamp(aura / math.max(auraCap, 1), 0, 1)

    local auraColor = getAuraColor(rebirths)

    -- Atualiza cor das partículas e trilha
    particles.Color = ColorSequence.new(auraColor)
    trail.Color     = ColorSequence.new(auraColor)
    bodyLight.Color = auraColor

    -- Intensidade proporcional à % de aura
    local intensity = pct * rebirths * 0.5
    particles.Rate  = math.floor(8 + intensity * 30)
    particles.Enabled = pct > 0.1

    trail.Enabled     = rebirths > 0
    bodyLight.Brightness = rebirths * 1.5
    bodyLight.Range      = rebirths * 6

    -- Flash dourado no rebirth
    if rebirths > lastRebirths then
        lastRebirths = rebirths
        local flash = Instance.new("PointLight")
        flash.Color      = Color3.fromRGB(255, 230, 100)
        flash.Brightness = 25
        flash.Range      = 60
        flash.Parent     = root

        TweenService:Create(flash, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Brightness = 0,
            Range      = 0,
        }):Play()

        task.delay(1.3, function()
            if flash then flash:Destroy() end
        end)

        -- Burst de partículas
        particles.Enabled = true
        particles.Rate    = 100
        task.delay(0.8, function()
            particles.Rate = math.floor(8 + rebirths * 5)
        end)
    end
end)

print("[BrainrotRoubo] Efeito de aura carregado!")
