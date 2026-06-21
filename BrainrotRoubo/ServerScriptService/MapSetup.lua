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
--  DECORAÇÃO: BIOMA EXTERNO (árvores, pedras, arbustos)
-- =====================================================
local treePositions = {
    Vector3.new( 110,0, 30), Vector3.new( 110,0,-30), Vector3.new(-110,0, 30), Vector3.new(-110,0,-30),
    Vector3.new(  30,0, 110), Vector3.new( -30,0, 110), Vector3.new( 30,0,-110), Vector3.new( -30,0,-110),
    Vector3.new( 100,0, 70), Vector3.new(-100,0, 70), Vector3.new( 100,0,-70), Vector3.new(-100,0,-70),
    Vector3.new(  70,0, 100), Vector3.new( -70,0, 100), Vector3.new( 70,0,-100), Vector3.new( -70,0,-100),
    Vector3.new( 125,0,  0), Vector3.new(-125,0,  0), Vector3.new(   0,0, 125), Vector3.new(   0,0,-125),
}
local treeTrunkColors = { BrickColor.new("Reddish brown"), BrickColor.new("Dark orange"), BrickColor.new("Brown") }
local treeLeafColors  = { BrickColor.new("Bright green"),  BrickColor.new("Dark green"),  BrickColor.new("Medium green") }
for i, pos in ipairs(treePositions) do
    local tc = treeTrunkColors[(i-1)%#treeTrunkColors+1]
    local lc = treeLeafColors[(i-1)%#treeLeafColors+1]
    local h  = 6 + (i%4)*1.5
    makePart({ Name="TreeTrunk_"..i, Size=Vector3.new(1.2,h,1.2), Position=Vector3.new(pos.X,h/2,pos.Z),
        BrickColor=tc, Material=Enum.Material.Wood, CanCollide=true })
    makePart({ Name="TreeLeaves_"..i, Shape=Enum.PartType.Ball, Size=Vector3.new(5+(i%3),5+(i%3),5+(i%3)),
        Position=Vector3.new(pos.X,h+2.5,pos.Z), BrickColor=lc, Material=Enum.Material.Grass, CanCollide=false })
end

-- Pedras decorativas (anel externo)
local rockPositions = {
    Vector3.new( 95,0, 10), Vector3.new(-95,0,-10), Vector3.new( 10,0, 95), Vector3.new(-10,0,-95),
    Vector3.new( 80,0, 90), Vector3.new(-80,0,-90), Vector3.new( 90,0,-80), Vector3.new(-90,0, 80),
    Vector3.new(115,0, 50), Vector3.new(-115,0,-50), Vector3.new( 50,0,115), Vector3.new(-50,0,-115),
}
for i, pos in ipairs(rockPositions) do
    local sz = 2 + (i%3)*1.2
    makePart({ Name="Rock_"..i, Size=Vector3.new(sz,sz*0.6,sz*0.8), Position=Vector3.new(pos.X,sz*0.3,pos.Z),
        BrickColor=BrickColor.new("Dark stone grey"), Material=Enum.Material.Rock, CanCollide=true })
end

-- Arbustos (esferas menores verdes)
local bushPositions = {
    Vector3.new( 70,0, 20), Vector3.new(-70,0, 20), Vector3.new( 20,0, 70), Vector3.new(-20,0, 70),
    Vector3.new( 70,0,-20), Vector3.new(-70,0,-20), Vector3.new( 20,0,-70), Vector3.new(-20,0,-70),
    Vector3.new( 55,0, 55), Vector3.new(-55,0, 55), Vector3.new( 55,0,-55), Vector3.new(-55,0,-55),
}
for i, pos in ipairs(bushPositions) do
    local sz = 2.5 + (i%2)
    makePart({ Name="Bush_"..i, Shape=Enum.PartType.Ball, Size=Vector3.new(sz,sz*0.7,sz),
        Position=Vector3.new(pos.X,sz*0.35,pos.Z), BrickColor=BrickColor.new("Medium green"),
        Material=Enum.Material.Grass, CanCollide=false })
end

-- =====================================================
--  DECORAÇÃO: ZONA ÉPICA (cristais + ruínas)
-- =====================================================
local crystalPositions = {
    Vector3.new( 30,0, 15), Vector3.new(-30,0, 15), Vector3.new( 15,0, 30), Vector3.new(-15,0, 30),
    Vector3.new( 30,0,-15), Vector3.new(-30,0,-15), Vector3.new( 15,0,-30), Vector3.new(-15,0,-30),
    Vector3.new( 38,0,  5), Vector3.new(-38,0,  5), Vector3.new(  5,0, 38), Vector3.new( -5,0, 38),
}
local crystalColors = {
    Color3.fromRGB(0,220,200), Color3.fromRGB(80,200,255), Color3.fromRGB(150,80,255), Color3.fromRGB(0,255,180),
}
for i, pos in ipairs(crystalPositions) do
    local h   = 3 + (i%4)*1.5
    local clr = crystalColors[(i-1)%#crystalColors+1]
    local c1  = makePart({ Name="Crystal_"..i, Size=Vector3.new(0.8,h,0.8),
        BrickColor=BrickColor.new("Institutional white"), Material=Enum.Material.Neon,
        CanCollide=false, CastShadow=false, Transparency=0.25 })
    c1.CFrame = CFrame.new(pos.X,h/2,pos.Z) * CFrame.Angles(math.rad((i%5)*8-20),0,math.rad((i%3)*12-18))
    c1.Color  = clr
    local cL  = Instance.new("PointLight"); cL.Color=clr; cL.Brightness=1.5; cL.Range=12; cL.Parent=c1
    local c2  = makePart({ Name="Crystal2_"..i, Size=Vector3.new(0.5,h*0.6,0.5),
        BrickColor=BrickColor.new("Institutional white"), Material=Enum.Material.Neon,
        CanCollide=false, CastShadow=false, Transparency=0.35 })
    c2.CFrame = CFrame.new(pos.X+1,(h*0.6)/2,pos.Z+0.8) * CFrame.Angles(math.rad(15),0,math.rad(-12))
    c2.Color  = clr
end

-- Pilares de ruína na zona épica
for i, pos in ipairs({ Vector3.new(35,0,-35), Vector3.new(-35,0,35), Vector3.new(38,0,35), Vector3.new(-38,0,-35) }) do
    local h = 3 + i*0.8
    makePart({ Name="Ruin_"..i, Size=Vector3.new(2,h,2), Position=Vector3.new(pos.X,h/2,pos.Z),
        BrickColor=BrickColor.new("Dark stone grey"), Material=Enum.Material.SmoothPlastic, CanCollide=true })
    local top = makePart({ Name="RuinTop_"..i, Size=Vector3.new(2.4,0.5,2.4),
        Position=Vector3.new(pos.X,h+0.25,pos.Z), BrickColor=BrickColor.new("Teal"),
        Material=Enum.Material.Neon, CanCollide=false, CastShadow=false, Transparency=0.4 })
    local rl = Instance.new("PointLight"); rl.Color=Color3.fromRGB(0,200,180); rl.Brightness=2; rl.Range=14; rl.Parent=top
end

-- =====================================================
--  DECORAÇÃO: POSTES DE BORDA
-- =====================================================
for i, pos in ipairs({
    Vector3.new( 140,0,  0), Vector3.new(-140,0,  0), Vector3.new(   0,0,140), Vector3.new(   0,0,-140),
    Vector3.new( 100,0,100), Vector3.new(-100,0,100), Vector3.new( 100,0,-100), Vector3.new(-100,0,-100),
}) do
    makePart({ Name="BorderPost_"..i, Size=Vector3.new(1.5,8,1.5), Position=Vector3.new(pos.X,4,pos.Z),
        BrickColor=BrickColor.new("Medium stone grey"), Material=Enum.Material.SmoothPlastic, CanCollide=true })
    local lamp = makePart({ Name="BorderLamp_"..i, Shape=Enum.PartType.Ball, Size=Vector3.new(2,2,2),
        Position=Vector3.new(pos.X,9,pos.Z), BrickColor=BrickColor.new("Institutional white"),
        Material=Enum.Material.Neon, CanCollide=false, CastShadow=false, Transparency=0.1 })
    local ll = Instance.new("PointLight"); ll.Color=Color3.fromRGB(255,240,200); ll.Brightness=3; ll.Range=24; ll.Parent=lamp
end

-- =====================================================
--  NPC VENDEDOR — Zé das Upgrades (modelo completo)
-- =====================================================
-- Corpo
local vendedor = Instance.new("Part")
vendedor.Name       = "VendedorNPC"
vendedor.Size       = Vector3.new(2, 4.5, 1.2)
vendedor.Position   = Vector3.new(0, 2.25, -16)
vendedor.Anchored   = true
vendedor.CanCollide = true
vendedor.BrickColor = BrickColor.new("Reddish brown")
vendedor.Material   = Enum.Material.SmoothPlastic
vendedor.Parent     = workspace

-- Barriga/roupa (manto)
local vendRobe = makePart({
    Name="VendedorRobe", Size=Vector3.new(2.4,4.2,1.4), Position=Vector3.new(0,2.1,-16),
    BrickColor=BrickColor.new("Really black"), Material=Enum.Material.SmoothPlastic, CanCollide=false,
})

-- Braço esquerdo
makePart({ Name="VendedorArmL", Size=Vector3.new(0.7,3.2,0.7), Position=Vector3.new(-1.5,2.2,-16),
    BrickColor=BrickColor.new("Reddish brown"), Material=Enum.Material.SmoothPlastic, CanCollide=false })

-- Braço direito (segurando cajado)
makePart({ Name="VendedorArmR", Size=Vector3.new(0.7,3.2,0.7), Position=Vector3.new(1.5,2.2,-16),
    BrickColor=BrickColor.new("Reddish brown"), Material=Enum.Material.SmoothPlastic, CanCollide=false })

-- Cajado
local staffPole = makePart({ Name="VendedorStaff", Size=Vector3.new(0.3,6,0.3),
    Position=Vector3.new(2.5,3,-16), BrickColor=BrickColor.new("Dark orange"),
    Material=Enum.Material.Wood, CanCollide=false })
local staffGem  = makePart({ Name="VendedorStaffGem", Shape=Enum.PartType.Ball,
    Size=Vector3.new(1.2,1.2,1.2), Position=Vector3.new(2.5,6.3,-16),
    BrickColor=BrickColor.new("Institutional white"), Material=Enum.Material.Neon,
    CanCollide=false, CastShadow=false, Transparency=0.1 })
staffGem.Color = Color3.fromRGB(130,80,255)
local gemLight = Instance.new("PointLight"); gemLight.Color=Color3.fromRGB(130,80,255); gemLight.Brightness=3; gemLight.Range=16; gemLight.Parent=staffGem

-- Chapéu de mago (cone + aba)
local hatBrim = makePart({ Name="VendedorHatBrim", Size=Vector3.new(3,0.3,3), Position=Vector3.new(0,7.2,-16),
    BrickColor=BrickColor.new("Really black"), Material=Enum.Material.SmoothPlastic, CanCollide=false })
local hatCone = makePart({ Name="VendedorHatCone", Size=Vector3.new(1.6,3,1.6), Position=Vector3.new(0,8.7,-16),
    BrickColor=BrickColor.new("Really black"), Material=Enum.Material.SmoothPlastic, CanCollide=false })
local hatStar = makePart({ Name="VendedorHatStar", Shape=Enum.PartType.Ball, Size=Vector3.new(0.5,0.5,0.5),
    Position=Vector3.new(0,10.4,-16), BrickColor=BrickColor.new("Institutional white"),
    Material=Enum.Material.Neon, CanCollide=false, CastShadow=false })
hatStar.Color = Color3.fromRGB(255,220,60)
Instance.new("PointLight").Color=Color3.fromRGB(255,220,60); local hatL=Instance.new("PointLight"); hatL.Color=Color3.fromRGB(255,220,60); hatL.Brightness=2; hatL.Range=10; hatL.Parent=hatStar

-- Cabeça
local vendHead = makePart({
    Name       = "VendedorHead",
    Shape      = Enum.PartType.Ball,
    Size       = Vector3.new(2.2, 2.2, 2.2),
    Position   = Vector3.new(0, 6.1, -16),
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

-- =====================================================
--  PETS DE EXIBIÇÃO (estáticos perto do vendedor)
-- =====================================================
-- Pet Ratinho — pequeno rato cinza ao lado do NPC
local ratBody = makePart({ Name="PetRatinho_Body", Shape=Enum.PartType.Ball,
    Size=Vector3.new(1.2,0.9,1.5), Position=Vector3.new(-3,0.45,-16),
    BrickColor=BrickColor.new("Medium stone grey"), Material=Enum.Material.SmoothPlastic, CanCollide=false })
makePart({ Name="PetRatinho_Head", Shape=Enum.PartType.Ball, Size=Vector3.new(0.9,0.9,0.9),
    Position=Vector3.new(-3.2,1.05,-15.2), BrickColor=BrickColor.new("Medium stone grey"),
    Material=Enum.Material.SmoothPlastic, CanCollide=false })
makePart({ Name="PetRatinho_EarL", Shape=Enum.PartType.Ball, Size=Vector3.new(0.35,0.35,0.1),
    Position=Vector3.new(-2.95,1.6,-15.1), BrickColor=BrickColor.new("Light reddish violet"),
    Material=Enum.Material.SmoothPlastic, CanCollide=false })
makePart({ Name="PetRatinho_EarR", Shape=Enum.PartType.Ball, Size=Vector3.new(0.35,0.35,0.1),
    Position=Vector3.new(-3.45,1.6,-15.1), BrickColor=BrickColor.new("Light reddish violet"),
    Material=Enum.Material.SmoothPlastic, CanCollide=false })
-- Brilho nos olhos do ratinho
local ratEye = makePart({ Name="PetRatinho_Eye", Shape=Enum.PartType.Ball, Size=Vector3.new(0.2,0.2,0.2),
    Position=Vector3.new(-3.1,1.1,-14.8), BrickColor=BrickColor.new("Institutional white"),
    Material=Enum.Material.Neon, CanCollide=false, CastShadow=false })
ratEye.Color = Color3.fromRGB(255,50,50)
-- Billboard com nome do pet
local ratBB = Instance.new("BillboardGui"); ratBB.Size=UDim2.new(0,130,0,28); ratBB.StudsOffset=Vector3.new(0,1.5,0); ratBB.Parent=ratBody
local ratLbl = Instance.new("TextLabel"); ratLbl.Size=UDim2.new(1,0,1,0); ratLbl.BackgroundTransparency=1
ratLbl.Text="🐭 Pet Ratinho"; ratLbl.TextColor3=Color3.fromRGB(255,255,255); ratLbl.TextScaled=true
ratLbl.Font=Enum.Font.GothamBold; ratLbl.TextStrokeTransparency=0; ratLbl.TextStrokeColor3=Color3.fromRGB(0,0,0); ratLbl.Parent=ratBB

-- Pet Gato Místico — gato azul/místico do outro lado
local gatoBody = makePart({ Name="PetGato_Body", Shape=Enum.PartType.Ball,
    Size=Vector3.new(1.4,1.1,1.6), Position=Vector3.new(3,0.55,-16),
    BrickColor=BrickColor.new("Institutional white"), Material=Enum.Material.SmoothPlastic, CanCollide=false })
gatoBody.Color = Color3.fromRGB(160,100,255)
makePart({ Name="PetGato_Head", Shape=Enum.PartType.Ball, Size=Vector3.new(1.1,1.1,1.1),
    Position=Vector3.new(3.2,1.3,-15.2), BrickColor=BrickColor.new("Institutional white"),
    Material=Enum.Material.SmoothPlastic, CanCollide=false }).Color = Color3.fromRGB(160,100,255)
makePart({ Name="PetGato_EarL", Size=Vector3.new(0.4,0.5,0.15), Position=Vector3.new(2.9,2.0,-15.15),
    BrickColor=BrickColor.new("Institutional white"), Material=Enum.Material.SmoothPlastic,
    CanCollide=false }).Color = Color3.fromRGB(160,100,255)
makePart({ Name="PetGato_EarR", Size=Vector3.new(0.4,0.5,0.15), Position=Vector3.new(3.5,2.0,-15.15),
    BrickColor=BrickColor.new("Institutional white"), Material=Enum.Material.SmoothPlastic,
    CanCollide=false }).Color = Color3.fromRGB(160,100,255)
-- Aura mística ao redor do gato
local gatoAtt = Instance.new("Attachment"); gatoAtt.Parent = gatoBody
local gatoPE  = Instance.new("ParticleEmitter"); gatoPE.Parent = gatoAtt
gatoPE.Color  = ColorSequence.new({ ColorSequenceKeypoint.new(0,Color3.fromRGB(160,100,255)), ColorSequenceKeypoint.new(1,Color3.fromRGB(255,200,255)) })
gatoPE.Size   = NumberSequence.new({ NumberSequenceKeypoint.new(0,0.2), NumberSequenceKeypoint.new(1,0) })
gatoPE.Lifetime=NumberRange.new(0.8,1.6); gatoPE.Rate=12; gatoPE.Speed=NumberRange.new(1,3); gatoPE.SpreadAngle=Vector2.new(180,180)
local gatoEye = makePart({ Name="PetGato_Eye", Shape=Enum.PartType.Ball, Size=Vector3.new(0.25,0.25,0.25),
    Position=Vector3.new(3.1,1.35,-14.7), BrickColor=BrickColor.new("Institutional white"),
    Material=Enum.Material.Neon, CanCollide=false, CastShadow=false })
gatoEye.Color = Color3.fromRGB(80,200,255)
local catLight = Instance.new("PointLight"); catLight.Color=Color3.fromRGB(160,80,255); catLight.Brightness=2; catLight.Range=10; catLight.Parent=gatoBody
local catoBB = Instance.new("BillboardGui"); catoBB.Size=UDim2.new(0,160,0,28); catoBB.StudsOffset=Vector3.new(0,1.8,0); catoBB.Parent=gatoBody
local catoLbl = Instance.new("TextLabel"); catoLbl.Size=UDim2.new(1,0,1,0); catoLbl.BackgroundTransparency=1
catoLbl.Text="🐱 Gato Místico"; catoLbl.TextColor3=Color3.fromRGB(220,160,255); catoLbl.TextScaled=true
catoLbl.Font=Enum.Font.GothamBold; catoLbl.TextStrokeTransparency=0; catoLbl.TextStrokeColor3=Color3.fromRGB(0,0,0); catoLbl.Parent=catoBB

print("[BrainrotRoubo] Mapa COMPLETO gerado: " .. #GameConfig.BASE_POSITIONS .. " bases, biomas, NPC Zé das Upgrades, pets e decorações!")
