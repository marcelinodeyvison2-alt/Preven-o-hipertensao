-- WorldSetup.server.lua (Script em ServerScriptService)
-- Configura o ambiente visual do jogo (Lighting, mapa, plataforma)

local Lighting   = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

-- ============================================================
-- LIGHTING: ambiente espacial/mistico
-- ============================================================
Lighting.Brightness        = 0
Lighting.GlobalShadows     = true
Lighting.Ambient           = Color3.fromRGB(10, 5, 30)
Lighting.OutdoorAmbient    = Color3.fromRGB(10, 5, 30)
Lighting.ShadowSoftness    = 0.2
Lighting.FogColor          = Color3.fromRGB(10, 5, 40)
Lighting.FogEnd            = 500
Lighting.FogStart          = 100
Lighting.ClockTime         = 0  -- noite

-- Efeito de atmosfera nebulosa
local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
if not atmosphere then
    atmosphere = Instance.new("Atmosphere")
    atmosphere.Parent = Lighting
end
atmosphere.Density     = 0.3
atmosphere.Offset      = 0.2
atmosphere.Color       = Color3.fromRGB(20, 10, 50)
atmosphere.Decay       = Color3.fromRGB(10, 5, 30)
atmosphere.Glare       = 0.2
atmosphere.Haze        = 0.5

-- Bloom effect
local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
if not bloom then
    bloom = Instance.new("BloomEffect")
    bloom.Parent = Lighting
end
bloom.Intensity   = 0.8
bloom.Size        = 28
bloom.Threshold   = 0.7

-- Color correction para tom roxo/azul
local colorCorrection = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
if not colorCorrection then
    colorCorrection = Instance.new("ColorCorrectionEffect")
    colorCorrection.Parent = Lighting
end
colorCorrection.Brightness = -0.02
colorCorrection.Contrast   = 0.1
colorCorrection.Saturation = 0.3
colorCorrection.TintColor  = Color3.fromRGB(180, 170, 220)

-- ============================================================
-- MAPA BASE: plataforma circular espacial
-- ============================================================

-- Plataforma principal
local platform = workspace:FindFirstChild("SpacePlatform")
if not platform then
    platform = Instance.new("Part")
    platform.Name      = "SpacePlatform"
    platform.Shape     = Enum.PartType.Cylinder
    platform.Size      = Vector3.new(2, 120, 120)
    platform.Position  = Vector3.new(0, -1, 0)
    platform.CFrame    = CFrame.new(0, -1, 0) * CFrame.Angles(0, 0, math.rad(90))
    platform.Anchored  = true
    platform.CanCollide = true
    platform.Material  = Enum.Material.SmoothPlastic
    platform.BrickColor = BrickColor.new("Dark indigo")
    platform.Parent    = workspace
end

-- Grade de luz no chao (linhas neon)
local function createGridLine(size, position, rotation)
    local line = Instance.new("Part")
    line.Size      = size
    line.Position  = position
    line.Anchored  = true
    line.CanCollide = false
    line.Material  = Enum.Material.Neon
    line.BrickColor = BrickColor.new("Alder")
    line.Transparency = 0.6
    if rotation then
        line.CFrame = CFrame.new(position) * rotation
    end
    line.Parent = workspace
    return line
end

-- Grade de linhas (5x5)
for x = -50, 50, 20 do
    createGridLine(Vector3.new(0.2, 0.3, 100), Vector3.new(x, 0.2, 0))
end
for z = -50, 50, 20 do
    createGridLine(Vector3.new(100, 0.3, 0.2), Vector3.new(0, 0.2, z))
end

-- ============================================================
-- PLATAFORMA DE GIRO (onde fica a roleta no mapa)
-- ============================================================
local spinPlatform = Instance.new("Part")
spinPlatform.Name      = "SpinPlatform"
spinPlatform.Shape     = Enum.PartType.Cylinder
spinPlatform.Size      = Vector3.new(1, 15, 15)
spinPlatform.CFrame    = CFrame.new(0, 0.5, 0) * CFrame.Angles(0, 0, math.rad(90))
spinPlatform.Anchored  = true
spinPlatform.CanCollide = true
spinPlatform.Material  = Enum.Material.Neon
spinPlatform.BrickColor = BrickColor.new("Electric blue")
spinPlatform.Transparency = 0.4
spinPlatform.Parent    = workspace

-- Luz na plataforma de giro
local spinLight = Instance.new("PointLight")
spinLight.Color      = Color3.fromRGB(0, 150, 255)
spinLight.Brightness = 3
spinLight.Range      = 30
spinLight.Parent     = spinPlatform

-- Animacao pulsante da plataforma
task.spawn(function()
    while true do
        local t1 = TweenService:Create(spinLight,
            TweenInfo.new(1.5, Enum.EasingStyle.Sine),
            { Brightness = 6 }
        )
        t1:Play()
        task.wait(1.5)
        local t2 = TweenService:Create(spinLight,
            TweenInfo.new(1.5, Enum.EasingStyle.Sine),
            { Brightness = 3 }
        )
        t2:Play()
        task.wait(1.5)
    end
end)

-- ============================================================
-- ESTRELAS NO CEU (particulas no ar)
-- ============================================================
local skyParticles = Instance.new("Part")
skyParticles.Anchored   = true
skyParticles.CanCollide = false
skyParticles.Size       = Vector3.new(1, 1, 1)
skyParticles.Position   = Vector3.new(0, 30, 0)
skyParticles.Transparency = 1
skyParticles.Parent     = workspace

local starEmitter = Instance.new("ParticleEmitter")
starEmitter.Color      = ColorSequence.new(Color3.new(1,1,1))
starEmitter.LightEmission = 1
starEmitter.Size       = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.2),
    NumberSequenceKeypoint.new(1, 0),
})
starEmitter.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.3),
    NumberSequenceKeypoint.new(0.8, 0.5),
    NumberSequenceKeypoint.new(1, 1),
})
starEmitter.Speed      = NumberRange.new(0.5, 2)
starEmitter.SpreadAngle = Vector2.new(180, 180)
starEmitter.Rate       = 5
starEmitter.Lifetime   = NumberRange.new(10, 20)
starEmitter.Parent     = skyParticles

-- ============================================================
-- SPAWN LOCATION
-- ============================================================
local spawnLocation = workspace:FindFirstChildOfClass("SpawnLocation")
if not spawnLocation then
    spawnLocation = Instance.new("SpawnLocation")
    spawnLocation.Position = Vector3.new(0, 2, 15)
    spawnLocation.Anchored = true
    spawnLocation.Size     = Vector3.new(6, 1, 6)
    spawnLocation.BrickColor = BrickColor.new("Dark indigo")
    spawnLocation.Parent   = workspace
end
spawnLocation.Position  = Vector3.new(0, 2, 15)

print("[WorldSetup] Ambiente configurado!")
