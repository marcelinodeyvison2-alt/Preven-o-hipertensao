-- Script: ServerScriptService > MapSetup
-- Cria o mapa: chão, paredes, bases temáticas

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig        = require(ReplicatedStorage:WaitForChild("GameConfig"))

-- =====================================================
--  UTILIDADES
-- =====================================================
local function makePart(props)
    local p = Instance.new("Part")
    p.Anchored      = true
    p.CanCollide    = true
    p.CastShadow    = true
    for k, v in pairs(props) do p[k] = v end
    p.Parent = workspace
    return p
end

local function makeSurfaceLabel(part, text, color)
    local sg = Instance.new("SurfaceGui")
    sg.Face   = Enum.NormalId.Top
    sg.Parent = part

    local lbl = Instance.new("TextLabel")
    lbl.Size                   = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text                   = text
    lbl.TextColor3             = color or Color3.fromRGB(255, 255, 255)
    lbl.TextScaled             = true
    lbl.Font                   = Enum.Font.GothamBold
    lbl.TextStrokeTransparency = 0
    lbl.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
    lbl.Parent                 = sg
end

-- =====================================================
--  CHÃO E AMBIENTE
-- =====================================================
-- Chão principal
makePart({
    Name             = "Ground",
    Size             = Vector3.new(280, 2, 280),
    Position         = Vector3.new(0, -1, 0),
    BrickColor       = BrickColor.new("Bright green"),
    Material         = Enum.Material.Grass,
    CanCollide       = true,
})

-- Bordas invisíveis (colisão)
for _, data in ipairs({
    { pos = Vector3.new(0,  5, -142), sz = Vector3.new(284, 12, 2) },
    { pos = Vector3.new(0,  5,  142), sz = Vector3.new(284, 12, 2) },
    { pos = Vector3.new(-142, 5, 0),  sz = Vector3.new(2, 12, 284) },
    { pos = Vector3.new( 142, 5, 0),  sz = Vector3.new(2, 12, 284) },
}) do
    local wall = Instance.new("Part")
    wall.Anchored               = true
    wall.CanCollide             = true
    wall.Size                   = data.sz
    wall.Position               = data.pos
    wall.Transparency           = 1
    wall.Parent                 = workspace
end

-- Plataforma central (spawn dos jogadores)
local center = makePart({
    Name      = "SpawnPlatform",
    Size      = Vector3.new(22, 1, 22),
    Position  = Vector3.new(0, 0.5, 0),
    BrickColor = BrickColor.new("Bright yellow"),
    Material   = Enum.Material.SmoothPlastic,
})
makeSurfaceLabel(center, "SPAWN", Color3.fromRGB(20, 20, 20))

-- Letreiro central
local sign = makePart({
    Name      = "MainSign",
    Size      = Vector3.new(14, 4.5, 0.5),
    Position  = Vector3.new(0, 7.5, -10),
    BrickColor = BrickColor.new("Really black"),
    Material   = Enum.Material.SmoothPlastic,
    CanCollide = false,
})
local signGui = Instance.new("SurfaceGui")
signGui.Face   = Enum.NormalId.Front
signGui.Parent = sign

local function addSignLabel(yPos, h, text, color, font)
    local lbl = Instance.new("TextLabel")
    lbl.Size             = UDim2.new(1, 0, h, 0)
    lbl.Position         = UDim2.new(0, 0, yPos, 0)
    lbl.BackgroundColor3 = Color3.fromRGB(8, 8, 15)
    lbl.Text             = text
    lbl.TextColor3       = color
    lbl.TextScaled       = true
    lbl.Font             = font or Enum.Font.GothamBold
    lbl.TextStrokeTransparency = 0.5
    lbl.TextStrokeColor3 = Color3.fromRGB(0,0,0)
    lbl.Parent           = signGui
end
addSignLabel(0,    0.5, "BRAINROT ROUBO",            Color3.fromRGB(255, 215, 0))
addSignLabel(0.5,  0.3, "Roube brainrots → ganhe AURA", Color3.fromRGB(200, 200, 200))
addSignLabel(0.8,  0.2, "Rebirth para ficar mais forte!", Color3.fromRGB(120, 220, 120))

-- =====================================================
--  BASES
-- =====================================================
-- Cores de anel por zona
local outerRingColor = BrickColor.new("Dark stone grey")
local innerRingColor = BrickColor.new("Medium stone grey")

for i, pos in ipairs(GameConfig.BASE_POSITIONS) do
    local isInner = (i > 8)
    local baseName = GameConfig.BASE_NAMES[i] or ("Base " .. i)

    -- Plataforma da base (cilindro achatado)
    local platform = makePart({
        Name      = "Base_" .. i,
        Shape     = Enum.PartType.Cylinder,
        Size      = Vector3.new(1.2, isInner and 10 or 12, isInner and 10 or 12),
        -- CFrame rotacionado para o cilindro ficar deitado (chão)
        BrickColor = isInner and innerRingColor or outerRingColor,
        Material   = Enum.Material.SmoothPlastic,
        CastShadow = true,
        CanCollide = true,
    })
    platform.CFrame = CFrame.new(pos.X, pos.Y - 0.6, pos.Z)
                    * CFrame.Angles(0, 0, math.rad(90))

    -- Anel decorativo por cima
    local ring = makePart({
        Name      = "Ring_" .. i,
        Shape     = Enum.PartType.Cylinder,
        Size      = Vector3.new(0.3, isInner and 11 or 13, isInner and 11 or 13),
        BrickColor = BrickColor.new("Institutional white"),
        Material   = Enum.Material.Neon,
        CanCollide = false,
        CastShadow = false,
    })
    ring.CFrame = CFrame.new(pos.X, pos.Y + 0.16, pos.Z)
               * CFrame.Angles(0, 0, math.rad(90))

    -- Indicador luminoso (começa cinza, muda com o brainrot)
    local indicator = Instance.new("Part")
    indicator.Name       = "Indicator"
    indicator.Shape      = Enum.PartType.Ball
    indicator.Size       = Vector3.new(1.5, 1.5, 1.5)
    indicator.Position   = Vector3.new(pos.X, pos.Y + 1.2, pos.Z)
    indicator.Anchored   = true
    indicator.CanCollide = false
    indicator.Color      = Color3.fromRGB(60, 60, 80)
    indicator.Material   = Enum.Material.Neon
    indicator.CastShadow = false
    indicator.Parent     = platform   -- filho da plataforma para o server achar

    local indLight = Instance.new("PointLight")
    indLight.Color      = Color3.fromRGB(60, 60, 80)
    indLight.Brightness = 2
    indLight.Range      = 10
    indLight.Parent     = indicator

    -- Billboard com nome da base
    local bb = Instance.new("BillboardGui")
    bb.Size        = UDim2.new(0, 180, 0, 35)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop = false
    bb.Parent      = platform

    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size                   = UDim2.new(1, 0, 1, 0)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text                   = baseName
    nameLbl.TextColor3             = Color3.fromRGB(200, 200, 200)
    nameLbl.TextStrokeTransparency = 0
    nameLbl.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
    nameLbl.TextScaled             = true
    nameLbl.Font                   = Enum.Font.Gotham
    nameLbl.Parent                 = bb

    -- Número da base no chão da plataforma
    local numberGui = Instance.new("SurfaceGui")
    numberGui.Face   = Enum.NormalId.Top
    numberGui.Parent = platform
    local numLbl = Instance.new("TextLabel")
    numLbl.Size                   = UDim2.new(1, 0, 1, 0)
    numLbl.BackgroundTransparency = 1
    numLbl.Text                   = tostring(i)
    numLbl.TextColor3             = Color3.fromRGB(255, 255, 255)
    numLbl.TextScaled             = true
    numLbl.Font                   = Enum.Font.GothamBold
    numLbl.Parent                 = numberGui
end

-- =====================================================
--  CAMINHOS ENTRE AS BASES (decoração)
-- =====================================================
-- Conecta centro às bases internas
local innerPositions = { 9, 10, 11, 12 }
for _, idx in ipairs(innerPositions) do
    local pos = GameConfig.BASE_POSITIONS[idx]
    local midX = pos.X / 2
    local midZ = pos.Z / 2
    local length = math.sqrt(pos.X^2 + pos.Z^2)
    local angle  = math.atan2(pos.Z, pos.X)

    local path = makePart({
        Name      = "Path_inner_" .. idx,
        Size      = Vector3.new(length - 8, 0.3, 2.5),
        BrickColor = BrickColor.new("Medium stone grey"),
        Material   = Enum.Material.SmoothPlastic,
        CanCollide = false,
        CastShadow = false,
    })
    path.CFrame = CFrame.new(midX, 0.15, midZ) * CFrame.Angles(0, -angle, 0)
end

-- =====================================================
--  BIOMAS VISUAIS
-- =====================================================
-- Zona Épica: área interna (raio ~55) com chão teal brilhante
local innerZone = makePart({
    Name         = "InnerZoneFloor",
    Shape        = Enum.PartType.Cylinder,
    Size         = Vector3.new(0.35, 108, 108),
    BrickColor   = BrickColor.new("Teal"),
    Material     = Enum.Material.Neon,
    CanCollide   = false,
    CastShadow   = false,
    Transparency = 0.82,
})
innerZone.CFrame = CFrame.new(0, -0.82, 0) * CFrame.Angles(0, 0, math.rad(90))

-- Anel divisório entre zona interna e externa
local divRing = makePart({
    Name         = "DivisionRing",
    Shape        = Enum.PartType.Cylinder,
    Size         = Vector3.new(0.5, 116, 116),
    BrickColor   = BrickColor.new("Cyan"),
    Material     = Enum.Material.Neon,
    CanCollide   = false,
    CastShadow   = false,
    Transparency = 0.55,
})
divRing.CFrame = CFrame.new(0, -0.55, 0) * CFrame.Angles(0, 0, math.rad(90))

-- Legenda flutuante "ZONA ÉPICA" no centro
local zoneMarker = Instance.new("Part")
zoneMarker.Size        = Vector3.new(0.1, 0.1, 0.1)
zoneMarker.Position    = Vector3.new(0, 10, 0)
zoneMarker.Anchored    = true
zoneMarker.CanCollide  = false
zoneMarker.Transparency = 1
zoneMarker.Parent      = workspace

local zoneBB = Instance.new("BillboardGui")
zoneBB.Size        = UDim2.new(0, 220, 0, 44)
zoneBB.StudsOffset = Vector3.new(0, 0, 0)
zoneBB.AlwaysOnTop = false
zoneBB.Parent      = zoneMarker

local zoneLabel = Instance.new("TextLabel")
zoneLabel.Size                   = UDim2.new(1, 0, 1, 0)
zoneLabel.BackgroundColor3       = Color3.fromRGB(0, 50, 50)
zoneLabel.BackgroundTransparency = 0.35
zoneLabel.BorderSizePixel        = 0
zoneLabel.Text                   = "✦ ZONA ÉPICA — drops raros dobrados ✦"
zoneLabel.TextColor3             = Color3.fromRGB(0, 230, 210)
zoneLabel.TextScaled             = true
zoneLabel.Font                   = Enum.Font.GothamBold
zoneLabel.TextStrokeTransparency = 0
zoneLabel.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
zoneLabel.Parent                 = zoneBB

local zoneCorner = Instance.new("UICorner")
zoneCorner.CornerRadius = UDim.new(0, 8)
zoneCorner.Parent       = zoneLabel

-- 4 pilares de luz nos cantos da zona épica (bases internas)
for _, idx in ipairs({9, 10, 11, 12}) do
    local pos = GameConfig.BASE_POSITIONS[idx]
    local pillar = makePart({
        Name         = "EpicPillar_" .. idx,
        Size         = Vector3.new(0.6, 12, 0.6),
        Position     = Vector3.new(pos.X, 6, pos.Z),
        BrickColor   = BrickColor.new("Teal"),
        Material     = Enum.Material.Neon,
        CanCollide   = false,
        CastShadow   = false,
        Transparency = 0.4,
    })
    local pillarLight = Instance.new("PointLight")
    pillarLight.Color      = Color3.fromRGB(0, 200, 180)
    pillarLight.Brightness = 3
    pillarLight.Range      = 20
    pillarLight.Parent     = pillar
end

-- =====================================================
--  NPC VENDEDOR
-- =====================================================
local vendedor = Instance.new("Part")
vendedor.Name       = "VendedorNPC"
vendedor.Size       = Vector3.new(2.5, 5, 2.5)
vendedor.Position   = Vector3.new(0, 2.5, -16)
vendedor.Anchored   = true
vendedor.CanCollide = true
vendedor.BrickColor = BrickColor.new("Reddish brown")
vendedor.Material   = Enum.Material.SmoothPlastic
vendedor.Parent     = workspace

local vendHead = makePart({
    Name       = "VendedorHead",
    Shape      = Enum.PartType.Ball,
    Size       = Vector3.new(2, 2, 2),
    Position   = Vector3.new(0, 6.3, -16),
    BrickColor = BrickColor.new("Brick yellow"),
    Material   = Enum.Material.SmoothPlastic,
    CanCollide = false,
})

local vendBB = Instance.new("BillboardGui")
vendBB.Size        = UDim2.new(0, 200, 0, 52)
vendBB.StudsOffset = Vector3.new(0, 2.5, 0)
vendBB.AlwaysOnTop = false
vendBB.Parent      = vendHead

local vendEmoji = Instance.new("TextLabel")
vendEmoji.Size                   = UDim2.new(1, 0, 0.52, 0)
vendEmoji.BackgroundTransparency = 1
vendEmoji.Text                   = "🧙 Zé das Upgrades"
vendEmoji.TextColor3             = Color3.fromRGB(255, 220, 120)
vendEmoji.TextStrokeTransparency = 0
vendEmoji.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
vendEmoji.TextScaled             = true
vendEmoji.Font                   = Enum.Font.GothamBold
vendEmoji.Parent                 = vendBB

local vendSub = Instance.new("TextLabel")
vendSub.Size                   = UDim2.new(1, 0, 0.38, 0)
vendSub.Position               = UDim2.new(0, 0, 0.55, 0)
vendSub.BackgroundTransparency = 1
vendSub.Text                   = "[F] Comprar upgrades"
vendSub.TextColor3             = Color3.fromRGB(200, 200, 200)
vendSub.TextStrokeTransparency = 0.3
vendSub.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
vendSub.TextScaled             = true
vendSub.Font                   = Enum.Font.Gotham
vendSub.Parent                 = vendBB

local pp = Instance.new("ProximityPrompt")
pp.ActionText            = "Comprar Upgrades"
pp.ObjectText            = "Zé das Upgrades"
pp.KeyboardKeyCode       = Enum.KeyCode.F
pp.HoldDuration          = 0
pp.MaxActivationDistance = 10
pp.Parent                = vendedor

print("[BrainrotRoubo] Mapa gerado com " .. #GameConfig.BASE_POSITIONS .. " bases, biomas e NPC Vendedor!")
