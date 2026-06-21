-- Script: ServerScriptService > MapSetup
-- Cria o mapa básico (chão, zona de spawn, decorações)
-- Execute apenas uma vez ao publicar o jogo; depois remova e use o mapa do Studio.

local function makePart(props)
    local p = Instance.new("Part")
    p.Anchored      = true
    p.CanCollide    = true
    for k, v in pairs(props) do p[k] = v end
    p.Parent = workspace
    return p
end

-- Chão principal
makePart({
    Name             = "Ground",
    Size             = Vector3.new(260, 2, 260),
    Position         = Vector3.new(0, -1, 0),
    BrickColor       = BrickColor.new("Sand green"),
    Material         = Enum.Material.Grass,
})

-- Bordas decorativas
local borderColor = BrickColor.new("Dark orange")
for _, pos in ipairs({
    Vector3.new(0, 1, -131),   -- Norte
    Vector3.new(0, 1,  131),   -- Sul
    Vector3.new(-131, 1, 0),   -- Oeste
    Vector3.new( 131, 1, 0),   -- Leste
}) do
    local isNS = pos.X == 0
    makePart({
        Name     = "Wall",
        Size     = isNS and Vector3.new(260, 4, 2) or Vector3.new(2, 4, 260),
        Position = pos,
        BrickColor = borderColor,
        Material = Enum.Material.SmoothPlastic,
        CanCollide = true,
    })
end

-- Plataforma central (spawn)
makePart({
    Name      = "SpawnPlatform",
    Size      = Vector3.new(20, 1, 20),
    Position  = Vector3.new(0, 0.5, 0),
    BrickColor = BrickColor.new("Bright yellow"),
    Material   = Enum.Material.SmoothPlastic,
})

-- Letreiro no centro
local sign = Instance.new("Part")
sign.Anchored = true
sign.Size     = Vector3.new(12, 4, 0.5)
sign.Position = Vector3.new(0, 6, -8)
sign.BrickColor = BrickColor.new("Dark grey")
sign.Material   = Enum.Material.SmoothPlastic
sign.Parent     = workspace

local signGui = Instance.new("SurfaceGui")
signGui.Face   = Enum.NormalId.Front
signGui.Parent = sign

local signLabel = Instance.new("TextLabel")
signLabel.Size             = UDim2.new(1, 0, 1, 0)
signLabel.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
signLabel.Text             = "BRAINROT ROUBO\nRoube brainrots e ganhe AURA!"
signLabel.TextColor3       = Color3.fromRGB(255, 215, 0)
signLabel.TextScaled       = true
signLabel.Font             = Enum.Font.GothamBold
signLabel.TextWrapped      = true
signLabel.Parent           = signGui

print("[BrainrotRoubo] Mapa configurado!")
