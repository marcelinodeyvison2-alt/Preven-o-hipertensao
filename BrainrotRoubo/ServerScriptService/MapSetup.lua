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
-- Chão externo (grama ao redor da arena)
makePart({
    Name="Ground",
    Size=Vector3.new(280, 2, 280),
    Position=Vector3.new(0, -1, 0),
    BrickColor=BrickColor.new("Bright green"),
    Material=Enum.Material.Grass,
    CanCollide=true,
})

-- Piso da arena (escuro, contraste estilo Roubei um Brainrot)
makePart({
    Name="ArenaFloor",
    Size=Vector3.new(120, 0.5, 90),
    Position=Vector3.new(0, -0.26, 0),
    BrickColor=BrickColor.new("Dark stone grey"),
    Material=Enum.Material.SmoothPlastic,
    CanCollide=true,
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

-- Plataforma de spawn (centro do corredor interno da esteira)
local center = makePart({
    Name      = "SpawnPlatform",
    Size      = Vector3.new(18, 0.5, 12),
    Position  = Vector3.new(0, 0.25, 0),
    BrickColor = BrickColor.new("Bright yellow"),
    Material   = Enum.Material.SmoothPlastic,
})
makeSurfaceLabel(center, "✦ SPAWN ✦", Color3.fromRGB(10, 10, 10))

-- 4 pilares do spawn (marcadores visuais nos cantos)
for _, cp in ipairs({
    Vector3.new(-9,  0, -6), Vector3.new( 9,  0, -6),
    Vector3.new(-9,  0,  6), Vector3.new( 9,  0,  6),
}) do
    local pole = makePart({
        Name="SpawnPole", Size=Vector3.new(0.5, 4, 0.5),
        Position=Vector3.new(cp.X, 2, cp.Z),
        BrickColor=BrickColor.new("Bright yellow"), Material=Enum.Material.Neon,
        CanCollide=false, CastShadow=false, Transparency=0.3,
    })
    local pl=Instance.new("PointLight"); pl.Color=Color3.fromRGB(255,230,0)
    pl.Brightness=2; pl.Range=10; pl.Parent=pole
end

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
--  ESTEIRA CENTRAL (CONVEYOR BELT — estilo Roubei um Brainrot)
-- =====================================================
local WPS    = GameConfig.CONVEYOR_WAYPOINTS   -- 4 waypoints em loop retangular
local BLT_H  = 1.5    -- altura do piso da esteira
local BLT_W  = 4.5    -- largura de cada faixa
local BLT_Y  = BLT_H / 2
local BLT_CLR = BrickColor.new("Deep orange")
local BLT_MAT = Enum.Material.SmoothPlastic

-- Limites do retângulo (extraídos dos waypoints)
local minX = WPS[4].X   -- -40
local maxX = WPS[2].X   --  40
local minZ = WPS[1].Z   -- -22
local maxZ = WPS[3].Z   --  22
local midX = (minX + maxX) / 2   --  0
local midZ = (minZ + maxZ) / 2   --  0
local lenX  = maxX - minX        --  80
local lenZ  = maxZ - minZ        --  44

-- Seções horizontais: inclui margem lateral para cobrir os cantos
local beltSouth = makePart({ Name="ConveyorBelt_S",
    Size=Vector3.new(lenX + BLT_W, BLT_H, BLT_W),
    Position=Vector3.new(midX, BLT_Y, minZ),
    BrickColor=BLT_CLR, Material=BLT_MAT, CanCollide=true })

local beltNorth = makePart({ Name="ConveyorBelt_N",
    Size=Vector3.new(lenX + BLT_W, BLT_H, BLT_W),
    Position=Vector3.new(midX, BLT_Y, maxZ),
    BrickColor=BLT_CLR, Material=BLT_MAT, CanCollide=true })

-- Seções verticais: comprimento sem sobrepor os cantos das seções horizontais
local beltEast = makePart({ Name="ConveyorBelt_E",
    Size=Vector3.new(BLT_W, BLT_H, lenZ - BLT_W),
    Position=Vector3.new(maxX, BLT_Y, midZ),
    BrickColor=BLT_CLR, Material=BLT_MAT, CanCollide=true })

local beltWest = makePart({ Name="ConveyorBelt_W",
    Size=Vector3.new(BLT_W, BLT_H, lenZ - BLT_W),
    Position=Vector3.new(minX, BLT_Y, midZ),
    BrickColor=BLT_CLR, Material=BLT_MAT, CanCollide=true })

-- Setas de direção na face superior de cada seção
local arrowData = {
    { part=beltSouth, text="►   ►   ►   ►   ►   ►   ►   ►" },
    { part=beltNorth, text="◄   ◄   ◄   ◄   ◄   ◄   ◄   ◄" },
    { part=beltEast,  text="▲     ▲     ▲     ▲" },
    { part=beltWest,  text="▼     ▼     ▼     ▼" },
}
for _, ad in ipairs(arrowData) do
    local sg  = Instance.new("SurfaceGui"); sg.Face=Enum.NormalId.Top; sg.Parent=ad.part
    local lbl = Instance.new("TextLabel"); lbl.Size=UDim2.new(1,0,1,0)
    lbl.BackgroundColor3=Color3.fromRGB(40,20,0); lbl.BackgroundTransparency=0.35
    lbl.Text=ad.text; lbl.TextColor3=Color3.fromRGB(255,220,0); lbl.TextScaled=true
    lbl.Font=Enum.Font.GothamBold; lbl.Parent=sg
end

-- Trilhos neon nas bordas da esteira
local RAIL_CLR = BrickColor.new("Bright yellow")
local RAIL_MAT = Enum.Material.Neon
local RAIL_T   = 0.3
local RAIL_H_2 = 0.6
local railY    = BLT_H + RAIL_H_2 / 2

local function makeRail(px, pz, sx, sz)
    local r = makePart({ Name="ConveyorRail",
        Size=Vector3.new(sx, RAIL_H_2, sz),
        Position=Vector3.new(px, railY, pz),
        BrickColor=RAIL_CLR, Material=RAIL_MAT,
        CanCollide=false, CastShadow=false, Transparency=0.2 })
    local rl = Instance.new("PointLight"); rl.Color=Color3.fromRGB(255,210,0)
    rl.Brightness=1.5; rl.Range=9; rl.Parent=r
end

-- Trilhos seção Sul (bordas externa e interna)
makeRail(midX, minZ - BLT_W/2, lenX + BLT_W, RAIL_T)
makeRail(midX, minZ + BLT_W/2, lenX + BLT_W, RAIL_T)
-- Trilhos seção Norte
makeRail(midX, maxZ + BLT_W/2, lenX + BLT_W, RAIL_T)
makeRail(midX, maxZ - BLT_W/2, lenX + BLT_W, RAIL_T)
-- Trilhos seção Leste
makeRail(maxX + BLT_W/2, midZ, RAIL_T, lenZ - BLT_W)
makeRail(maxX - BLT_W/2, midZ, RAIL_T, lenZ - BLT_W)
-- Trilhos seção Oeste
makeRail(minX - BLT_W/2, midZ, RAIL_T, lenZ - BLT_W)
makeRail(minX + BLT_W/2, midZ, RAIL_T, lenZ - BLT_W)

-- Marcador de zona de spawn (WP1 — canto SW, onde brainrots aparecem)
local spawnMark = makePart({ Name="SpawnZoneMark",
    Size=Vector3.new(BLT_W + 1, 0.15, BLT_W + 1),
    Position=Vector3.new(WPS[1].X, BLT_H + 0.08, WPS[1].Z),
    BrickColor=BrickColor.new("Lime green"), Material=Enum.Material.Neon,
    CanCollide=false, CastShadow=false, Transparency=0.25 })
local spawnPL = Instance.new("PointLight")
spawnPL.Color=Color3.fromRGB(0,255,100); spawnPL.Brightness=3; spawnPL.Range=12
spawnPL.Parent=spawnMark

local spawnBB = Instance.new("BillboardGui")
spawnBB.Size=UDim2.new(0,220,0,42); spawnBB.StudsOffset=Vector3.new(0,5,0)
spawnBB.AlwaysOnTop=false; spawnBB.Parent=spawnMark
local spawnLbl = Instance.new("TextLabel")
spawnLbl.Size=UDim2.new(1,0,1,0); spawnLbl.BackgroundColor3=Color3.fromRGB(0,50,15)
spawnLbl.BackgroundTransparency=0.3; spawnLbl.Text="🟢 SPAWN DE BRAINROTS"
spawnLbl.TextColor3=Color3.fromRGB(80,255,130); spawnLbl.TextScaled=true
spawnLbl.Font=Enum.Font.GothamBold; spawnLbl.TextStrokeTransparency=0
spawnLbl.TextStrokeColor3=Color3.fromRGB(0,0,0); spawnLbl.Parent=spawnBB
local spawnCorner=Instance.new("UICorner"); spawnCorner.CornerRadius=UDim.new(0,8)
spawnCorner.Parent=spawnLbl

-- Plataformas de observação (norte e sul da esteira — fora do retângulo)
for _, cfg in ipairs({
    { z=-(maxZ+10), label="[ Aproxime-se da esteira para roubar brainrots! ]" },
    { z=  maxZ+10,  label="[ Aproxime-se da esteira para roubar brainrots! ]" },
}) do
    local vp = makePart({ Name="ViewPlatform",
        Size=Vector3.new(55, 1.0, 7),
        Position=Vector3.new(0, 0.5, cfg.z),
        BrickColor=BrickColor.new("Medium stone grey"),
        Material=Enum.Material.SmoothPlastic, CanCollide=true })
    makeSurfaceLabel(vp, cfg.label, Color3.fromRGB(220,220,220))
end

-- Luz ambiente central sobre a esteira
local cAmbPart = Instance.new("Part")
cAmbPart.Size=Vector3.new(0.1,0.1,0.1); cAmbPart.Position=Vector3.new(0,28,0)
cAmbPart.Anchored=true; cAmbPart.CanCollide=false; cAmbPart.Transparency=1
cAmbPart.Parent=workspace
local cAmbL=Instance.new("PointLight"); cAmbL.Color=Color3.fromRGB(255,180,60)
cAmbL.Brightness=2; cAmbL.Range=90; cAmbL.Parent=cAmbPart

-- =====================================================
--  TORRES DE CANTO + BORDA DA ARENA
-- =====================================================
-- 4 torres iluminadas nos cantos da esteira (cada WP tem uma torre de cor diferente)
local towerColors = {
    Color3.fromRGB(255, 60, 60),    -- WP1 vermelho (spawn)
    Color3.fromRGB(255, 200, 0),    -- WP2 amarelo
    Color3.fromRGB(60, 160, 255),   -- WP3 azul
    Color3.fromRGB(60, 255, 120),   -- WP4 verde
}
for i, wp in ipairs(WPS) do
    -- Pilar central da torre
    makePart({ Name="CornerTower_"..i,
        Size=Vector3.new(1.6, 22, 1.6),
        Position=Vector3.new(wp.X, 11, wp.Z),
        BrickColor=BrickColor.new("Really black"),
        Material=Enum.Material.SmoothPlastic, CanCollide=true })
    -- Cápsula neon no topo
    local topBall = makePart({ Name="TowerTop_"..i,
        Shape=Enum.PartType.Ball, Size=Vector3.new(3, 3, 3),
        Position=Vector3.new(wp.X, 23, wp.Z),
        BrickColor=BrickColor.new("Institutional white"),
        Material=Enum.Material.Neon, CanCollide=false, CastShadow=false, Transparency=0.05 })
    topBall.Color = towerColors[i]
    local tl = Instance.new("PointLight")
    tl.Color=towerColors[i]; tl.Brightness=7; tl.Range=40; tl.Parent=topBall
    -- Anel decorativo ao redor do topo
    local topRing = makePart({ Name="TowerRing_"..i,
        Shape=Enum.PartType.Cylinder, Size=Vector3.new(0.25, 6, 6),
        Position=Vector3.new(wp.X, 23, wp.Z),
        BrickColor=BrickColor.new("Institutional white"),
        Material=Enum.Material.Neon, CanCollide=false, CastShadow=false, Transparency=0.35 })
    topRing.CFrame = CFrame.new(wp.X, 23, wp.Z) * CFrame.Angles(0, 0, math.rad(90))
    topRing.Color = towerColors[i]
    -- Faixas na torre
    for j = 1, 3 do
        local stripe = makePart({ Name="TowerStripe_"..i.."_"..j,
            Size=Vector3.new(1.7, 0.5, 1.7),
            Position=Vector3.new(wp.X, 4*j, wp.Z),
            BrickColor=BrickColor.new("Institutional white"),
            Material=Enum.Material.Neon, CanCollide=false, CastShadow=false, Transparency=0.5 })
        stripe.Color = towerColors[i]
    end
end

-- Bordas neon da arena (contorno brilhante ao redor da área de jogo)
local arenaW = lenX + 28   -- 108
local arenaD = lenZ + 26   -- 70
local borderY = 0.2
local borderGlow = Color3.fromRGB(255, 200, 0)
for _, bd in ipairs({
    {px=midX,       pz=minZ - 13.5, sx=arenaW, sz=0.4},   -- sul
    {px=midX,       pz=maxZ + 13.5, sx=arenaW, sz=0.4},   -- norte
    {px=minX - 13.5, pz=midZ,       sx=0.4,    sz=arenaD}, -- oeste
    {px=maxX + 13.5, pz=midZ,       sx=0.4,    sz=arenaD}, -- leste
}) do
    local br = makePart({ Name="ArenaBorder",
        Size=Vector3.new(bd.sx, 0.35, bd.sz),
        Position=Vector3.new(bd.px, borderY, bd.pz),
        BrickColor=BrickColor.new("Bright yellow"),
        Material=Enum.Material.Neon, CanCollide=false, CastShadow=false, Transparency=0.25 })
    local bl = Instance.new("PointLight"); bl.Color=borderGlow; bl.Brightness=1; bl.Range=12; bl.Parent=br
end

-- Cercado: paredes baixas de metal ao redor da arena
for _, fd in ipairs({
    {px=midX,       pz=minZ - 14, sx=arenaW+1, sz=0.5, h=2.5},
    {px=midX,       pz=maxZ + 14, sx=arenaW+1, sz=0.5, h=2.5},
    {px=minX - 14,  pz=midZ,      sx=0.5, sz=arenaD-1, h=2.5},
    {px=maxX + 14,  pz=midZ,      sx=0.5, sz=arenaD-1, h=2.5},
}) do
    makePart({ Name="ArenaFence",
        Size=Vector3.new(fd.sx, fd.h, fd.sz),
        Position=Vector3.new(fd.px, fd.h/2, fd.pz),
        BrickColor=BrickColor.new("Dark stone grey"),
        Material=Enum.Material.DiamondPlate,
        CanCollide=true, Transparency=0.15 })
end

-- Platôs para jogadores ao redor da esteira (onde ficam perto dos brainrots)
for _, pl2 in ipairs({
    {px=midX,  pz=minZ-7,  sx=lenX-4,  sz=6},   -- sul da esteira
    {px=midX,  pz=maxZ+7,  sx=lenX-4,  sz=6},   -- norte da esteira
    {px=maxX+7, pz=midZ,   sx=6, sz=lenZ-4},    -- leste da esteira
    {px=minX-7, pz=midZ,   sx=6, sz=lenZ-4},    -- oeste da esteira
}) do
    makePart({ Name="PlayerZone",
        Size=Vector3.new(pl2.sx, 0.5, pl2.sz),
        Position=Vector3.new(pl2.px, 0.25, pl2.pz),
        BrickColor=BrickColor.new("Medium stone grey"),
        Material=Enum.Material.SmoothPlastic, CanCollide=true })
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
-- Cristais posicionados FORA do retângulo da esteira (|X|<40, |Z|<22)
local crystalPositions = {
    -- Leste (fora da esteira)
    Vector3.new(56, 0, -14), Vector3.new(56, 0, 0), Vector3.new(56, 0, 14),
    -- Oeste (fora da esteira)
    Vector3.new(-56, 0, -14), Vector3.new(-56, 0, 0), Vector3.new(-56, 0, 14),
    -- Norte (fora da esteira)
    Vector3.new(-18, 0, 36), Vector3.new(0, 0, 38), Vector3.new(18, 0, 36),
    -- Sul (fora da esteira)
    Vector3.new(-18, 0, -36), Vector3.new(0, 0, -38), Vector3.new(18, 0, -36),
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
vendedor.Position   = Vector3.new(0, 2.25, -33)
vendedor.Anchored   = true
vendedor.CanCollide = true
vendedor.BrickColor = BrickColor.new("Reddish brown")
vendedor.Material   = Enum.Material.SmoothPlastic
vendedor.Parent     = workspace

-- Barriga/roupa (manto)
local vendRobe = makePart({
    Name="VendedorRobe", Size=Vector3.new(2.4,4.2,1.4), Position=Vector3.new(0,2.1,-33),
    BrickColor=BrickColor.new("Really black"), Material=Enum.Material.SmoothPlastic, CanCollide=false,
})

-- Braço esquerdo
makePart({ Name="VendedorArmL", Size=Vector3.new(0.7,3.2,0.7), Position=Vector3.new(-1.5,2.2,-33),
    BrickColor=BrickColor.new("Reddish brown"), Material=Enum.Material.SmoothPlastic, CanCollide=false })

-- Braço direito (segurando cajado)
makePart({ Name="VendedorArmR", Size=Vector3.new(0.7,3.2,0.7), Position=Vector3.new(1.5,2.2,-33),
    BrickColor=BrickColor.new("Reddish brown"), Material=Enum.Material.SmoothPlastic, CanCollide=false })

-- Cajado
local staffPole = makePart({ Name="VendedorStaff", Size=Vector3.new(0.3,6,0.3),
    Position=Vector3.new(2.5,3,-33), BrickColor=BrickColor.new("Dark orange"),
    Material=Enum.Material.Wood, CanCollide=false })
local staffGem  = makePart({ Name="VendedorStaffGem", Shape=Enum.PartType.Ball,
    Size=Vector3.new(1.2,1.2,1.2), Position=Vector3.new(2.5,6.3,-33),
    BrickColor=BrickColor.new("Institutional white"), Material=Enum.Material.Neon,
    CanCollide=false, CastShadow=false, Transparency=0.1 })
staffGem.Color = Color3.fromRGB(130,80,255)
local gemLight = Instance.new("PointLight"); gemLight.Color=Color3.fromRGB(130,80,255); gemLight.Brightness=3; gemLight.Range=16; gemLight.Parent=staffGem

-- Chapéu de mago (cone + aba)
local hatBrim = makePart({ Name="VendedorHatBrim", Size=Vector3.new(3,0.3,3), Position=Vector3.new(0,7.2,-33),
    BrickColor=BrickColor.new("Really black"), Material=Enum.Material.SmoothPlastic, CanCollide=false })
local hatCone = makePart({ Name="VendedorHatCone", Size=Vector3.new(1.6,3,1.6), Position=Vector3.new(0,8.7,-33),
    BrickColor=BrickColor.new("Really black"), Material=Enum.Material.SmoothPlastic, CanCollide=false })
local hatStar = makePart({ Name="VendedorHatStar", Shape=Enum.PartType.Ball, Size=Vector3.new(0.5,0.5,0.5),
    Position=Vector3.new(0,10.4,-33), BrickColor=BrickColor.new("Institutional white"),
    Material=Enum.Material.Neon, CanCollide=false, CastShadow=false })
hatStar.Color = Color3.fromRGB(255,220,60)
Instance.new("PointLight").Color=Color3.fromRGB(255,220,60); local hatL=Instance.new("PointLight"); hatL.Color=Color3.fromRGB(255,220,60); hatL.Brightness=2; hatL.Range=10; hatL.Parent=hatStar

-- Cabeça
local vendHead = makePart({
    Name       = "VendedorHead",
    Shape      = Enum.PartType.Ball,
    Size       = Vector3.new(2.2, 2.2, 2.2),
    Position   = Vector3.new(0, 6.1, -33),
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
    Size=Vector3.new(1.2,0.9,1.5), Position=Vector3.new(-3,0.45,-33),
    BrickColor=BrickColor.new("Medium stone grey"), Material=Enum.Material.SmoothPlastic, CanCollide=false })
makePart({ Name="PetRatinho_Head", Shape=Enum.PartType.Ball, Size=Vector3.new(0.9,0.9,0.9),
    Position=Vector3.new(-3.2,1.05,-41.2), BrickColor=BrickColor.new("Medium stone grey"),
    Material=Enum.Material.SmoothPlastic, CanCollide=false })
makePart({ Name="PetRatinho_EarL", Shape=Enum.PartType.Ball, Size=Vector3.new(0.35,0.35,0.1),
    Position=Vector3.new(-2.95,1.6,-41.1), BrickColor=BrickColor.new("Light reddish violet"),
    Material=Enum.Material.SmoothPlastic, CanCollide=false })
makePart({ Name="PetRatinho_EarR", Shape=Enum.PartType.Ball, Size=Vector3.new(0.35,0.35,0.1),
    Position=Vector3.new(-3.45,1.6,-41.1), BrickColor=BrickColor.new("Light reddish violet"),
    Material=Enum.Material.SmoothPlastic, CanCollide=false })
-- Brilho nos olhos do ratinho
local ratEye = makePart({ Name="PetRatinho_Eye", Shape=Enum.PartType.Ball, Size=Vector3.new(0.2,0.2,0.2),
    Position=Vector3.new(-3.1,1.1,-40.8), BrickColor=BrickColor.new("Institutional white"),
    Material=Enum.Material.Neon, CanCollide=false, CastShadow=false })
ratEye.Color = Color3.fromRGB(255,50,50)
-- Billboard com nome do pet
local ratBB = Instance.new("BillboardGui"); ratBB.Size=UDim2.new(0,130,0,28); ratBB.StudsOffset=Vector3.new(0,1.5,0); ratBB.Parent=ratBody
local ratLbl = Instance.new("TextLabel"); ratLbl.Size=UDim2.new(1,0,1,0); ratLbl.BackgroundTransparency=1
ratLbl.Text="🐭 Pet Ratinho"; ratLbl.TextColor3=Color3.fromRGB(255,255,255); ratLbl.TextScaled=true
ratLbl.Font=Enum.Font.GothamBold; ratLbl.TextStrokeTransparency=0; ratLbl.TextStrokeColor3=Color3.fromRGB(0,0,0); ratLbl.Parent=ratBB

-- Pet Gato Místico — gato azul/místico do outro lado
local gatoBody = makePart({ Name="PetGato_Body", Shape=Enum.PartType.Ball,
    Size=Vector3.new(1.4,1.1,1.6), Position=Vector3.new(3,0.55,-33),
    BrickColor=BrickColor.new("Institutional white"), Material=Enum.Material.SmoothPlastic, CanCollide=false })
gatoBody.Color = Color3.fromRGB(160,100,255)
makePart({ Name="PetGato_Head", Shape=Enum.PartType.Ball, Size=Vector3.new(1.1,1.1,1.1),
    Position=Vector3.new(3.2,1.3,-41.2), BrickColor=BrickColor.new("Institutional white"),
    Material=Enum.Material.SmoothPlastic, CanCollide=false }).Color = Color3.fromRGB(160,100,255)
makePart({ Name="PetGato_EarL", Size=Vector3.new(0.4,0.5,0.15), Position=Vector3.new(2.9,2.0,-41.15),
    BrickColor=BrickColor.new("Institutional white"), Material=Enum.Material.SmoothPlastic,
    CanCollide=false }).Color = Color3.fromRGB(160,100,255)
makePart({ Name="PetGato_EarR", Size=Vector3.new(0.4,0.5,0.15), Position=Vector3.new(3.5,2.0,-41.15),
    BrickColor=BrickColor.new("Institutional white"), Material=Enum.Material.SmoothPlastic,
    CanCollide=false }).Color = Color3.fromRGB(160,100,255)
-- Aura mística ao redor do gato
local gatoAtt = Instance.new("Attachment"); gatoAtt.Parent = gatoBody
local gatoPE  = Instance.new("ParticleEmitter"); gatoPE.Parent = gatoAtt
gatoPE.Color  = ColorSequence.new({ ColorSequenceKeypoint.new(0,Color3.fromRGB(160,100,255)), ColorSequenceKeypoint.new(1,Color3.fromRGB(255,200,255)) })
gatoPE.Size   = NumberSequence.new({ NumberSequenceKeypoint.new(0,0.2), NumberSequenceKeypoint.new(1,0) })
gatoPE.Lifetime=NumberRange.new(0.8,1.6); gatoPE.Rate=12; gatoPE.Speed=NumberRange.new(1,3); gatoPE.SpreadAngle=Vector2.new(180,180)
local gatoEye = makePart({ Name="PetGato_Eye", Shape=Enum.PartType.Ball, Size=Vector3.new(0.25,0.25,0.25),
    Position=Vector3.new(3.1,1.35,-40.7), BrickColor=BrickColor.new("Institutional white"),
    Material=Enum.Material.Neon, CanCollide=false, CastShadow=false })
gatoEye.Color = Color3.fromRGB(80,200,255)
local catLight = Instance.new("PointLight"); catLight.Color=Color3.fromRGB(160,80,255); catLight.Brightness=2; catLight.Range=10; catLight.Parent=gatoBody
local catoBB = Instance.new("BillboardGui"); catoBB.Size=UDim2.new(0,160,0,28); catoBB.StudsOffset=Vector3.new(0,1.8,0); catoBB.Parent=gatoBody
local catoLbl = Instance.new("TextLabel"); catoLbl.Size=UDim2.new(1,0,1,0); catoLbl.BackgroundTransparency=1
catoLbl.Text="🐱 Gato Místico"; catoLbl.TextColor3=Color3.fromRGB(220,160,255); catoLbl.TextScaled=true
catoLbl.Font=Enum.Font.GothamBold; catoLbl.TextStrokeTransparency=0; catoLbl.TextStrokeColor3=Color3.fromRGB(0,0,0); catoLbl.Parent=catoBB

print("[BrainrotRoubo] Mapa COMPLETO gerado: esteira central com " .. #GameConfig.CONVEYOR_WAYPOINTS .. " waypoints, NPC Zé das Upgrades, pets e decorações!")
