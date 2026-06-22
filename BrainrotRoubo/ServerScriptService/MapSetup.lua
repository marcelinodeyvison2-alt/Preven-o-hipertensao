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
local BLT_CLR = BrickColor.new("Dark stone grey")
local BLT_MAT = Enum.Material.Metal

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

-- Setas + faixas de aviso industriais na face superior
local arrowData = {
    { part=beltSouth, text="▶  ▶  ▶  ▶  ▶  ▶  ▶  ▶  ▶  ▶" },
    { part=beltNorth, text="◀  ◀  ◀  ◀  ◀  ◀  ◀  ◀  ◀  ◀" },
    { part=beltEast,  text="▲   ▲   ▲   ▲   ▲" },
    { part=beltWest,  text="▼   ▼   ▼   ▼   ▼" },
}
for _, ad in ipairs(arrowData) do
    local sg  = Instance.new("SurfaceGui"); sg.Face=Enum.NormalId.Top; sg.Parent=ad.part
    local bg  = Instance.new("Frame"); bg.Size=UDim2.new(1,0,1,0)
    bg.BackgroundColor3=Color3.fromRGB(18,18,18); bg.BorderSizePixel=0; bg.Parent=sg
    local lbl = Instance.new("TextLabel"); lbl.Size=UDim2.new(1,0,1,0)
    lbl.BackgroundTransparency=1
    lbl.Text=ad.text; lbl.TextColor3=Color3.fromRGB(255,220,0); lbl.TextScaled=true
    lbl.Font=Enum.Font.GothamBold
    lbl.TextStrokeTransparency=0.2; lbl.TextStrokeColor3=Color3.fromRGB(0,0,0)
    lbl.Parent=bg
end

-- Caps de canto (cobrem as junções nos 4 waypoints)
local capColors = {
    Color3.fromRGB(255, 60,  60 ),  -- WP1 vermelho
    Color3.fromRGB(255, 200, 0  ),  -- WP2 amarelo
    Color3.fromRGB(60,  160, 255),  -- WP3 azul
    Color3.fromRGB(60,  255, 120),  -- WP4 verde
}
for i, wp in ipairs(WPS) do
    makePart({ Name="ConveyorCorner_"..i,
        Size=Vector3.new(BLT_W+0.5, BLT_H+0.25, BLT_W+0.5),
        Position=Vector3.new(wp.X, BLT_Y, wp.Z),
        BrickColor=BrickColor.new("Dark stone grey"),
        Material=Enum.Material.Metal, CanCollide=true })
    local capRing = Instance.new("Part")
    capRing.Name="CornerRing_"..i; capRing.Shape=Enum.PartType.Cylinder
    capRing.Size=Vector3.new(0.3, BLT_W+2.2, BLT_W+2.2)
    capRing.Anchored=true; capRing.CanCollide=false; capRing.CastShadow=false
    capRing.Material=Enum.Material.Neon; capRing.Transparency=0.3
    capRing.Color=capColors[i]
    capRing.CFrame=CFrame.new(wp.X, BLT_H+0.35, wp.Z)*CFrame.Angles(0,0,math.rad(90))
    capRing.Parent=workspace
    local cl=Instance.new("PointLight"); cl.Color=capColors[i]
    cl.Brightness=5; cl.Range=24; cl.Parent=capRing
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

-- Linhas neon de zona dos jogadores (N/S/L/O)
local zoneMarkers = {
    { px=midX,   pz=minZ-7, sx=lenX-4, sz=0.3, color=Color3.fromRGB(255,80,80),  label="⬇ ZONA SUL ⬇"   },
    { px=midX,   pz=maxZ+7, sx=lenX-4, sz=0.3, color=Color3.fromRGB(80,160,255), label="⬆ ZONA NORTE ⬆" },
    { px=maxX+7, pz=midZ,   sx=0.3, sz=lenZ-4, color=Color3.fromRGB(255,200,50), label="ZONA LESTE"       },
    { px=minX-7, pz=midZ,   sx=0.3, sz=lenZ-4, color=Color3.fromRGB(80,255,150), label="ZONA OESTE"       },
}
for i, zm in ipairs(zoneMarkers) do
    local ml = makePart({ Name="ZoneMarker_"..i,
        Size=Vector3.new(zm.sx, 0.15, zm.sz),
        Position=Vector3.new(zm.px, 0.58, zm.pz),
        BrickColor=BrickColor.new("Institutional white"),
        Material=Enum.Material.Neon, CanCollide=false, Transparency=0.15 })
    ml.Color=zm.color
    local mpl=Instance.new("PointLight"); mpl.Color=zm.color; mpl.Brightness=1; mpl.Range=9; mpl.Parent=ml
end

-- =====================================================
--  HOLOFOTES DE ESTÁDIO (iluminação profissional)
-- =====================================================
for i, pos in ipairs({
    Vector3.new( maxX+11, 0,  maxZ+11),  -- NE
    Vector3.new(-maxX-11, 0,  maxZ+11),  -- NW
    Vector3.new( maxX+11, 0, -(maxZ+11)),-- SE
    Vector3.new(-maxX-11, 0, -(maxZ+11)),-- SW
}) do
    makePart({ Name="StadiumPole_"..i, Size=Vector3.new(1.2,28,1.2),
        Position=Vector3.new(pos.X,14,pos.Z),
        BrickColor=BrickColor.new("Medium stone grey"),
        Material=Enum.Material.SmoothPlastic, CanCollide=true })
    local armZ = pos.Z > 0 and (pos.Z-3) or (pos.Z+3)
    makePart({ Name="StadiumArm_"..i, Size=Vector3.new(0.6,0.6,6),
        Position=Vector3.new(pos.X,29,armZ),
        BrickColor=BrickColor.new("Dark stone grey"),
        Material=Enum.Material.SmoothPlastic, CanCollide=false })
    local fixZ = pos.Z > 0 and (pos.Z-6) or (pos.Z+6)
    local fix = makePart({ Name="StadiumFixture_"..i, Size=Vector3.new(4,1.4,2.2),
        Position=Vector3.new(pos.X,28.8,fixZ),
        BrickColor=BrickColor.new("Really black"),
        Material=Enum.Material.SmoothPlastic, CanCollide=false })
    local bulb = makePart({ Name="StadiumBulb_"..i, Size=Vector3.new(3.5,0.55,2),
        Position=Vector3.new(pos.X,28.0,fixZ),
        BrickColor=BrickColor.new("Institutional white"),
        Material=Enum.Material.Neon, CanCollide=false, Transparency=0.05 })
    bulb.Color=Color3.fromRGB(255,250,220)
    local spot=Instance.new("SpotLight")
    spot.Angle=60; spot.Brightness=7; spot.Range=110
    spot.Color=Color3.fromRGB(255,245,210); spot.Face=Enum.NormalId.Bottom
    spot.Parent=fix
    local bl=Instance.new("PointLight"); bl.Color=Color3.fromRGB(255,250,200)
    bl.Brightness=3; bl.Range=18; bl.Parent=bulb
end

-- =====================================================
--  PLACAR CENTRAL (SCOREBOARD acima da entrada sul)
-- =====================================================
makePart({ Name="ScoreboardPost1", Size=Vector3.new(1.2,18,1.2),
    Position=Vector3.new(-8,9,-13),
    BrickColor=BrickColor.new("Dark stone grey"), Material=Enum.Material.SmoothPlastic })
makePart({ Name="ScoreboardPost2", Size=Vector3.new(1.2,18,1.2),
    Position=Vector3.new( 8,9,-13),
    BrickColor=BrickColor.new("Dark stone grey"), Material=Enum.Material.SmoothPlastic })
makePart({ Name="ScoreboardCrossbar", Size=Vector3.new(17.6,0.8,0.8),
    Position=Vector3.new(0,18.4,-13),
    BrickColor=BrickColor.new("Dark stone grey"), Material=Enum.Material.SmoothPlastic, CanCollide=false })
local sbPanel = makePart({ Name="ScoreboardPanel", Size=Vector3.new(20,7.5,0.65),
    Position=Vector3.new(0,22.25,-13),
    BrickColor=BrickColor.new("Really black"), Material=Enum.Material.SmoothPlastic, CanCollide=false })
local sbGui=Instance.new("SurfaceGui"); sbGui.Face=Enum.NormalId.Front; sbGui.Parent=sbPanel
local sbBg=Instance.new("Frame"); sbBg.Size=UDim2.new(1,0,1,0)
sbBg.BackgroundColor3=Color3.fromRGB(4,4,18); sbBg.BorderSizePixel=0; sbBg.Parent=sbGui
local sbT=Instance.new("TextLabel"); sbT.Size=UDim2.new(1,0,0.48,0)
sbT.BackgroundTransparency=1; sbT.Text="🏆  BRAINROT ROUBO  🏆"
sbT.TextColor3=Color3.fromRGB(255,215,0); sbT.TextScaled=true; sbT.Font=Enum.Font.GothamBold
sbT.TextStrokeTransparency=0.4; sbT.Parent=sbBg
local sbS=Instance.new("TextLabel"); sbS.Size=UDim2.new(1,0,0.30,0)
sbS.Position=UDim2.new(0,0,0.50,0); sbS.BackgroundTransparency=1
sbS.Text="Roube brainrots  •  Ganhe aura  •  Torne-se lendário"
sbS.TextColor3=Color3.fromRGB(170,195,255); sbS.TextScaled=true; sbS.Font=Enum.Font.Gotham; sbS.Parent=sbBg
local sbF=Instance.new("TextLabel"); sbF.Size=UDim2.new(1,0,0.22,0)
sbF.Position=UDim2.new(0,0,0.80,0)
sbF.BackgroundColor3=Color3.fromRGB(200,30,30); sbF.BackgroundTransparency=0.35
sbF.Text="🌑  LUA DE SANGUE A CADA 25 SPAWNS  🌑"
sbF.TextColor3=Color3.fromRGB(255,200,200); sbF.TextScaled=true; sbF.Font=Enum.Font.GothamBold; sbF.Parent=sbBg
-- Moldura neon do placar
for _, bd in ipairs({
    {x=0,     y=26.3,  sx=21,  sz=0.3},
    {x=0,     y=18.2,  sx=21,  sz=0.3},
    {x=-10.5, y=22.25, sx=0.3, sz=8.5},
    {x= 10.5, y=22.25, sx=0.3, sz=8.5},
}) do
    makePart({ Name="SbFrame", Size=Vector3.new(bd.sx,0.35,bd.sz),
        Position=Vector3.new(bd.x, bd.y, -12.65),
        BrickColor=BrickColor.new("Bright yellow"),
        Material=Enum.Material.Neon, CanCollide=false, Transparency=0.2 })
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
--  BARRACA DO VENDEDOR
-- =====================================================
-- Balcão de madeira
makePart({ Name="ShopCounter", Size=Vector3.new(5.5,1.5,1.5),
    Position=Vector3.new(0,0.75,-29.5),
    BrickColor=BrickColor.new("Dark orange"), Material=Enum.Material.Wood })
makePart({ Name="ShopCounterTop", Size=Vector3.new(5.7,0.22,1.7),
    Position=Vector3.new(0,1.61,-29.5),
    BrickColor=BrickColor.new("Forest green"), Material=Enum.Material.SmoothPlastic, CanCollide=false })
-- Pernas do balcão
for _, cx in ipairs({-2.3, 2.3}) do
    makePart({ Name="CounterLeg", Size=Vector3.new(0.4,1.5,0.4),
        Position=Vector3.new(cx,0.75,-29.2),
        BrickColor=BrickColor.new("Brown"), Material=Enum.Material.Wood, CanCollide=false })
    makePart({ Name="CounterLeg", Size=Vector3.new(0.4,1.5,0.4),
        Position=Vector3.new(cx,0.75,-30.3),
        BrickColor=BrickColor.new("Brown"), Material=Enum.Material.Wood, CanCollide=false })
end
-- Toldo listrado vermelho/branco
makePart({ Name="ShopAwning", Size=Vector3.new(8,0.3,5.5),
    Position=Vector3.new(0,8.3,-32),
    BrickColor=BrickColor.new("Bright red"), Material=Enum.Material.SmoothPlastic, CanCollide=false })
for ix = -3.5, 3.5, 1.4 do
    makePart({ Name="ShopAwningStripe", Size=Vector3.new(0.65,0.38,5.6),
        Position=Vector3.new(ix,8.45,-32),
        BrickColor=BrickColor.new("Institutional white"),
        Material=Enum.Material.SmoothPlastic, CanCollide=false })
end
-- Franja decorativa
for ix = -3.8, 3.8, 0.65 do
    makePart({ Name="ShopFringe", Size=Vector3.new(0.4,0.65,0.4),
        Position=Vector3.new(ix,7.8,-29.5),
        BrickColor=BrickColor.new("Bright red"),
        Material=Enum.Material.SmoothPlastic, CanCollide=false })
end
-- Placa da loja
local shopSign = makePart({ Name="ShopSignBoard", Size=Vector3.new(7,1.7,0.3),
    Position=Vector3.new(0,9.85,-29.7),
    BrickColor=BrickColor.new("Really black"), Material=Enum.Material.SmoothPlastic, CanCollide=false })
makeSurfaceLabel(shopSign, "  ✦  UPGRADES & ITENS  ✦  ", Color3.fromRGB(255,215,0))
local sLit=Instance.new("PointLight"); sLit.Color=Color3.fromRGB(255,215,0)
sLit.Brightness=2; sLit.Range=12; sLit.Parent=shopSign
-- Prateleira atrás do NPC
makePart({ Name="ShopShelf", Size=Vector3.new(4.5,0.25,1.2),
    Position=Vector3.new(0,3.8,-37.2),
    BrickColor=BrickColor.new("Dark orange"), Material=Enum.Material.Wood, CanCollide=false })
makePart({ Name="ShopShelfBack", Size=Vector3.new(4.5,3,0.2),
    Position=Vector3.new(0,2.5,-37.7),
    BrickColor=BrickColor.new("Brown"), Material=Enum.Material.Wood, CanCollide=false })
-- Itens na prateleira (esferas coloridas neon)
local shelfItems = {
    Color3.fromRGB(255,60,60), Color3.fromRGB(80,200,255),
    Color3.fromRGB(80,255,120), Color3.fromRGB(255,200,50), Color3.fromRGB(160,80,255),
}
for j, clr in ipairs(shelfItems) do
    local item = makePart({ Name="ShelfItem_"..j, Shape=Enum.PartType.Ball,
        Size=Vector3.new(0.65,0.65,0.65),
        Position=Vector3.new(-2+(j-1)*1, 4.22, -37.2),
        BrickColor=BrickColor.new("Institutional white"),
        Material=Enum.Material.Neon, CanCollide=false, CastShadow=false, Transparency=0.1 })
    item.Color=clr
    local il=Instance.new("PointLight"); il.Color=clr; il.Brightness=1.5; il.Range=5; il.Parent=item
end
-- Dois postes que sustentam o toldo
for _, cx in ipairs({-3.7, 3.7}) do
    makePart({ Name="AwningPost", Size=Vector3.new(0.5,8.3,0.5),
        Position=Vector3.new(cx,4.15,-29.5),
        BrickColor=BrickColor.new("Dark stone grey"), Material=Enum.Material.SmoothPlastic })
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
local hatL=Instance.new("PointLight"); hatL.Color=Color3.fromRGB(255,220,60); hatL.Brightness=2; hatL.Range=10; hatL.Parent=hatStar

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
    Position=Vector3.new(-3.2,1.05,-33.2), BrickColor=BrickColor.new("Medium stone grey"),
    Material=Enum.Material.SmoothPlastic, CanCollide=false })
makePart({ Name="PetRatinho_EarL", Shape=Enum.PartType.Ball, Size=Vector3.new(0.35,0.35,0.1),
    Position=Vector3.new(-2.95,1.6,-33.1), BrickColor=BrickColor.new("Light reddish violet"),
    Material=Enum.Material.SmoothPlastic, CanCollide=false })
makePart({ Name="PetRatinho_EarR", Shape=Enum.PartType.Ball, Size=Vector3.new(0.35,0.35,0.1),
    Position=Vector3.new(-3.45,1.6,-33.1), BrickColor=BrickColor.new("Light reddish violet"),
    Material=Enum.Material.SmoothPlastic, CanCollide=false })
-- Brilho nos olhos do ratinho
local ratEye = makePart({ Name="PetRatinho_Eye", Shape=Enum.PartType.Ball, Size=Vector3.new(0.2,0.2,0.2),
    Position=Vector3.new(-3.1,1.1,-32.8), BrickColor=BrickColor.new("Institutional white"),
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
    Position=Vector3.new(3.2,1.3,-33.2), BrickColor=BrickColor.new("Institutional white"),
    Material=Enum.Material.SmoothPlastic, CanCollide=false }).Color = Color3.fromRGB(160,100,255)
makePart({ Name="PetGato_EarL", Size=Vector3.new(0.4,0.5,0.15), Position=Vector3.new(2.9,2.0,-33.15),
    BrickColor=BrickColor.new("Institutional white"), Material=Enum.Material.SmoothPlastic,
    CanCollide=false }).Color = Color3.fromRGB(160,100,255)
makePart({ Name="PetGato_EarR", Size=Vector3.new(0.4,0.5,0.15), Position=Vector3.new(3.5,2.0,-33.15),
    BrickColor=BrickColor.new("Institutional white"), Material=Enum.Material.SmoothPlastic,
    CanCollide=false }).Color = Color3.fromRGB(160,100,255)
-- Aura mística ao redor do gato
local gatoAtt = Instance.new("Attachment"); gatoAtt.Parent = gatoBody
local gatoPE  = Instance.new("ParticleEmitter"); gatoPE.Parent = gatoAtt
gatoPE.Color  = ColorSequence.new({ ColorSequenceKeypoint.new(0,Color3.fromRGB(160,100,255)), ColorSequenceKeypoint.new(1,Color3.fromRGB(255,200,255)) })
gatoPE.Size   = NumberSequence.new({ NumberSequenceKeypoint.new(0,0.2), NumberSequenceKeypoint.new(1,0) })
gatoPE.Lifetime=NumberRange.new(0.8,1.6); gatoPE.Rate=12; gatoPE.Speed=NumberRange.new(1,3); gatoPE.SpreadAngle=Vector2.new(180,180)
local gatoEye = makePart({ Name="PetGato_Eye", Shape=Enum.PartType.Ball, Size=Vector3.new(0.25,0.25,0.25),
    Position=Vector3.new(3.1,1.35,-32.7), BrickColor=BrickColor.new("Institutional white"),
    Material=Enum.Material.Neon, CanCollide=false, CastShadow=false })
gatoEye.Color = Color3.fromRGB(80,200,255)
local catLight = Instance.new("PointLight"); catLight.Color=Color3.fromRGB(160,80,255); catLight.Brightness=2; catLight.Range=10; catLight.Parent=gatoBody
local catoBB = Instance.new("BillboardGui"); catoBB.Size=UDim2.new(0,160,0,28); catoBB.StudsOffset=Vector3.new(0,1.8,0); catoBB.Parent=gatoBody
local catoLbl = Instance.new("TextLabel"); catoLbl.Size=UDim2.new(1,0,1,0); catoLbl.BackgroundTransparency=1
catoLbl.Text="🐱 Gato Místico"; catoLbl.TextColor3=Color3.fromRGB(220,160,255); catoLbl.TextScaled=true
catoLbl.Font=Enum.Font.GothamBold; catoLbl.TextStrokeTransparency=0; catoLbl.TextStrokeColor3=Color3.fromRGB(0,0,0); catoLbl.Parent=catoBB

-- =====================================================
--  LEADERBOARD 3D NO MAPA (Feature 1)
-- =====================================================
local function makeWorldLeaderboard(boardName, posX, faceDir)
    -- Support poles
    makePart({ Name="LBPole1", Size=Vector3.new(1.2,18,1.2),
        Position=Vector3.new(posX, 9, -8),
        BrickColor=BrickColor.new("Dark stone grey"), Material=Enum.Material.SmoothPlastic })
    makePart({ Name="LBPole2", Size=Vector3.new(1.2,18,1.2),
        Position=Vector3.new(posX, 9, 8),
        BrickColor=BrickColor.new("Dark stone grey"), Material=Enum.Material.SmoothPlastic })
    -- Crossbar
    makePart({ Name="LBCrossbar", Size=Vector3.new(17.6,0.8,0.8),
        Position=Vector3.new(posX, 18.4, 0),
        BrickColor=BrickColor.new("Dark stone grey"), Material=Enum.Material.SmoothPlastic, CanCollide=false })
    -- Panel
    local panel = makePart({ Name=boardName, Size=Vector3.new(0.65,8.5,18.5),
        Position=Vector3.new(posX, 15, 0),
        BrickColor=BrickColor.new("Really black"), Material=Enum.Material.SmoothPlastic, CanCollide=false })

    -- SurfaceGui
    local sg = Instance.new("SurfaceGui")
    sg.Face   = faceDir
    sg.Parent = panel

    -- Background frame
    local bg = Instance.new("Frame")
    bg.Name             = "LBBg"
    bg.Size             = UDim2.new(1,0,1,0)
    bg.BackgroundColor3 = Color3.fromRGB(4,4,20)
    bg.BorderSizePixel  = 0
    bg.Parent           = sg

    -- Title label
    local titleLbl = Instance.new("TextLabel")
    titleLbl.Name                   = "LBTitle"
    titleLbl.Size                   = UDim2.new(1,0,0.14,0)
    titleLbl.BackgroundColor3       = Color3.fromRGB(12,10,3)
    titleLbl.Text                   = "🏆 TOP AURA AO VIVO"
    titleLbl.TextColor3             = Color3.fromRGB(255,215,0)
    titleLbl.TextScaled             = true
    titleLbl.Font                   = Enum.Font.GothamBold
    titleLbl.BorderSizePixel        = 0
    titleLbl.Parent                 = bg

    -- Rank colors
    local rankColors = {
        Color3.fromRGB(255,215,0),   -- 1st gold
        Color3.fromRGB(192,192,192), -- 2nd silver
        Color3.fromRGB(205,127,50),  -- 3rd bronze
        Color3.fromRGB(200,200,200), -- 4th
        Color3.fromRGB(200,200,200), -- 5th
    }
    local rankLabels = {"1°","2°","3°","4°","5°"}

    -- 5 row frames
    for k = 1, 5 do
        local row = Instance.new("Frame")
        row.Name             = "LBRow_"..k
        row.Size             = UDim2.new(1,0,0.16,0)
        row.Position         = UDim2.new(0,0,0.14+(k-1)*0.16,0)
        row.BackgroundColor3 = (k%2==0) and Color3.fromRGB(8,8,28) or Color3.fromRGB(5,5,18)
        row.BorderSizePixel  = 0
        row.Parent           = bg

        -- Rank number
        local rankNum = Instance.new("TextLabel")
        rankNum.Name                   = "RankNum"
        rankNum.Size                   = UDim2.new(0.12,0,1,0)
        rankNum.BackgroundTransparency = 1
        rankNum.Text                   = rankLabels[k]
        rankNum.TextColor3             = rankColors[k]
        rankNum.TextScaled             = true
        rankNum.Font                   = Enum.Font.GothamBold
        rankNum.Parent                 = row

        -- Player name
        local playerName = Instance.new("TextLabel")
        playerName.Name                   = "PlayerName"
        playerName.Size                   = UDim2.new(0.55,0,1,0)
        playerName.Position               = UDim2.new(0.13,0,0,0)
        playerName.BackgroundTransparency = 1
        playerName.Text                   = "---"
        playerName.TextColor3             = Color3.fromRGB(220,220,220)
        playerName.TextScaled             = true
        playerName.Font                   = Enum.Font.Gotham
        playerName.TextXAlignment         = Enum.TextXAlignment.Left
        playerName.Parent                 = row

        -- Aura amount
        local auraAmt = Instance.new("TextLabel")
        auraAmt.Name                   = "AuraAmt"
        auraAmt.Size                   = UDim2.new(0.32,0,1,0)
        auraAmt.Position               = UDim2.new(0.67,0,0,0)
        auraAmt.BackgroundTransparency = 1
        auraAmt.Text                   = "0"
        auraAmt.TextColor3             = Color3.fromRGB(255,160,50)
        auraAmt.TextScaled             = true
        auraAmt.Font                   = Enum.Font.GothamBold
        auraAmt.TextXAlignment         = Enum.TextXAlignment.Right
        auraAmt.Parent                 = row
    end

    -- Neon borders (top and bottom)
    makePart({ Name="LBBorderTop", Size=Vector3.new(0.1,0.35,19.2),
        Position=Vector3.new(posX, 19.6, 0),
        BrickColor=BrickColor.new("Bright yellow"), Material=Enum.Material.Neon,
        CanCollide=false, CastShadow=false, Transparency=0.2 })
    makePart({ Name="LBBorderBot", Size=Vector3.new(0.1,0.35,19.2),
        Position=Vector3.new(posX, 10.5, 0),
        BrickColor=BrickColor.new("Bright yellow"), Material=Enum.Material.Neon,
        CanCollide=false, CastShadow=false, Transparency=0.2 })
end

makeWorldLeaderboard("WorldLeaderboard",     minX-13.5, Enum.NormalId.Right)
makeWorldLeaderboard("WorldLeaderboardEast",  maxX+13.5, Enum.NormalId.Left)

-- =====================================================
--  PÓDIO 3D (Ouro / Prata / Bronze) — lado leste
-- =====================================================
local podiumData = {
    { rank=1, x=maxX+28, h=3.5, color=Color3.fromRGB(255,215,0),   label="🥇 1°" },
    { rank=2, x=maxX+24, h=2.5, color=Color3.fromRGB(192,192,192), label="🥈 2°" },
    { rank=3, x=maxX+32, h=1.8, color=Color3.fromRGB(205,127,50),  label="🥉 3°" },
}
for _, pd in ipairs(podiumData) do
    -- Base do pódio
    local base = makePart({ Name="Podium_"..pd.rank,
        Size=Vector3.new(4.5, pd.h, 4.5),
        Position=Vector3.new(pd.x, pd.h/2, 0),
        BrickColor=BrickColor.new("Dark stone grey"),
        Material=Enum.Material.SmoothPlastic, CanCollide=true })
    -- Topo colorido
    local top = makePart({ Name="PodiumTop_"..pd.rank,
        Size=Vector3.new(4.7, 0.4, 4.7),
        Position=Vector3.new(pd.x, pd.h+0.2, 0),
        BrickColor=BrickColor.new("Institutional white"),
        Material=Enum.Material.Neon, CanCollide=false })
    top.Color = pd.color
    local tl = Instance.new("PointLight"); tl.Color=pd.color; tl.Brightness=3; tl.Range=14; tl.Parent=top
    -- Placa com ranking
    local sg = Instance.new("SurfaceGui"); sg.Face=Enum.NormalId.Front; sg.Parent=base
    local lbl = Instance.new("TextLabel"); lbl.Size=UDim2.new(1,0,1,0)
    lbl.BackgroundTransparency=1; lbl.Text=pd.label
    lbl.TextColor3=pd.color; lbl.TextScaled=true; lbl.Font=Enum.Font.GothamBold
    lbl.TextStrokeTransparency=0; lbl.Parent=sg
    -- Troféu no topo
    local trophy = makePart({ Name="PodiumTrophy_"..pd.rank,
        Shape=Enum.PartType.Ball, Size=Vector3.new(1.5,1.5,1.5),
        Position=Vector3.new(pd.x, pd.h+1.15, 0),
        BrickColor=BrickColor.new("Institutional white"),
        Material=Enum.Material.Neon, CanCollide=false, CastShadow=false, Transparency=0.15 })
    trophy.Color = pd.color
end
-- Painel acima dos pódios
local podSign = makePart({ Name="PodiumSign", Size=Vector3.new(16,3,0.5),
    Position=Vector3.new(maxX+28, 7, 0),
    BrickColor=BrickColor.new("Really black"), Material=Enum.Material.SmoothPlastic, CanCollide=false })
local podSg = Instance.new("SurfaceGui"); podSg.Face=Enum.NormalId.Front; podSg.Parent=podSign
local podLbl = Instance.new("TextLabel"); podLbl.Size=UDim2.new(1,0,1,0)
podLbl.BackgroundColor3=Color3.fromRGB(4,4,20); podLbl.BorderSizePixel=0
podLbl.Text="🏆  HALL DA FAMA  🏆"; podLbl.TextColor3=Color3.fromRGB(255,215,0)
podLbl.TextScaled=true; podLbl.Font=Enum.Font.GothamBold; podLbl.Parent=podSg
local podLight=Instance.new("PointLight"); podLight.Color=Color3.fromRGB(255,215,0); podLight.Brightness=2; podLight.Range=16; podLight.Parent=podSign

-- =====================================================
--  ARCO DE ENTRADA (Norte e Sul da arena)
-- =====================================================
for _, arc in ipairs({
    { z=minZ-14.5, label="⚡  BRAINROT ROUBO  ⚡", flip=false },
    { z=maxZ+14.5, label="🏆  BOA SORTE!  🏆",     flip=true  },
}) do
    -- Dois pilares
    for _, sx in ipairs({-9.5, 9.5}) do
        makePart({ Name="ArchPillar", Size=Vector3.new(1.8, 14, 1.8),
            Position=Vector3.new(sx, 7, arc.z),
            BrickColor=BrickColor.new("Dark stone grey"), Material=Enum.Material.SmoothPlastic })
        local capBall = makePart({ Name="ArchPillarCap", Shape=Enum.PartType.Ball,
            Size=Vector3.new(2.4,2.4,2.4), Position=Vector3.new(sx, 15, arc.z),
            BrickColor=BrickColor.new("Institutional white"), Material=Enum.Material.Neon,
            CanCollide=false, CastShadow=false, Transparency=0.1 })
        capBall.Color = Color3.fromRGB(255,215,0)
        local cl=Instance.new("PointLight"); cl.Color=Color3.fromRGB(255,215,0); cl.Brightness=5; cl.Range=20; cl.Parent=capBall
    end
    -- Viga horizontal
    local beam = makePart({ Name="ArchBeam", Size=Vector3.new(21, 1.4, 1.8),
        Position=Vector3.new(0, 14, arc.z),
        BrickColor=BrickColor.new("Dark stone grey"), Material=Enum.Material.SmoothPlastic, CanCollide=false })
    -- Painel do arco com texto
    local arcPanel = makePart({ Name="ArchPanel", Size=Vector3.new(20, 3, 0.5),
        Position=Vector3.new(0, 16.5, arc.z),
        BrickColor=BrickColor.new("Really black"), Material=Enum.Material.SmoothPlastic, CanCollide=false })
    local arcSg = Instance.new("SurfaceGui"); arcSg.Face=arc.flip and Enum.NormalId.Back or Enum.NormalId.Front; arcSg.Parent=arcPanel
    local arcLbl = Instance.new("TextLabel"); arcLbl.Size=UDim2.new(1,0,1,0)
    arcLbl.BackgroundColor3=Color3.fromRGB(6,4,20); arcLbl.BorderSizePixel=0
    arcLbl.Text=arc.label; arcLbl.TextColor3=Color3.fromRGB(255,220,80)
    arcLbl.TextScaled=true; arcLbl.Font=Enum.Font.GothamBold
    arcLbl.TextStrokeTransparency=0.3; arcLbl.Parent=arcSg
    -- Neon no topo do painel
    local arcNeon = makePart({ Name="ArchNeon", Size=Vector3.new(20.5, 0.3, 0.4),
        Position=Vector3.new(0, 18.1, arc.z),
        BrickColor=BrickColor.new("Institutional white"), Material=Enum.Material.Neon,
        CanCollide=false, CastShadow=false, Transparency=0.15 })
    arcNeon.Color = Color3.fromRGB(255,215,0)
end

-- =====================================================
--  VIGAS INDUSTRIAIS SUSPENSAS + LÂMPADAS PENDURADAS
-- =====================================================
-- Treliça superior leste-oeste (2 vigas cruzando o mapa)
for _, girderZ in ipairs({ -8, 8 }) do
    makePart({ Name="Girder_H", Size=Vector3.new(lenX + 30, 1.2, 1.2),
        Position=Vector3.new(0, 26, girderZ),
        BrickColor=BrickColor.new("Dark stone grey"), Material=Enum.Material.DiamondPlate,
        CanCollide=false, CastShadow=false })
    -- 5 lâmpadas penduradas em cada viga
    for lx = -36, 36, 18 do
        makePart({ Name="LampPole", Size=Vector3.new(0.3, 5, 0.3),
            Position=Vector3.new(lx, 23.5, girderZ),
            BrickColor=BrickColor.new("Dark stone grey"), Material=Enum.Material.SmoothPlastic,
            CanCollide=false, CastShadow=false })
        local bulb = makePart({ Name="HangingBulb", Shape=Enum.PartType.Ball,
            Size=Vector3.new(1.2,1.2,1.2), Position=Vector3.new(lx, 21, girderZ),
            BrickColor=BrickColor.new("Institutional white"), Material=Enum.Material.Neon,
            CanCollide=false, CastShadow=false, Transparency=0.05 })
        bulb.Color = Color3.fromRGB(255,245,200)
        local bl=Instance.new("PointLight"); bl.Color=Color3.fromRGB(255,240,180); bl.Brightness=4; bl.Range=28; bl.Parent=bulb
    end
end
-- Viga norte-sul central
makePart({ Name="Girder_V", Size=Vector3.new(1.2, 1.2, lenZ + 30),
    Position=Vector3.new(0, 26, 0),
    BrickColor=BrickColor.new("Dark stone grey"), Material=Enum.Material.DiamondPlate,
    CanCollide=false, CastShadow=false })
-- Suportes verticais da treliça (4 pilares)
for _, sp in ipairs({ Vector3.new(-36,0,-8), Vector3.new(36,0,-8), Vector3.new(-36,0,8), Vector3.new(36,0,8) }) do
    makePart({ Name="GirderSupport", Size=Vector3.new(0.8, 26, 0.8),
        Position=Vector3.new(sp.X, 13, sp.Z),
        BrickColor=BrickColor.new("Dark stone grey"), Material=Enum.Material.SmoothPlastic,
        CanCollide=false, CastShadow=false })
end

-- =====================================================
--  ZONA VIP / PRESTÍGIO (canto NW fora da esteira)
-- =====================================================
local vipX = minX - 26
local vipZ = maxZ + 26
-- Plataforma dourada elevada
local vipFloor = makePart({ Name="VIPZone",
    Size=Vector3.new(18, 0.6, 18), Position=Vector3.new(vipX, 0.3, vipZ),
    BrickColor=BrickColor.new("Institutional white"), Material=Enum.Material.SmoothPlastic })
vipFloor.Color = Color3.fromRGB(255,215,0)
-- Borda neon da zona VIP
for _, vb in ipairs({
    {dx=0,    dz=-9.5, sx=18.5, sz=0.3},
    {dx=0,    dz= 9.5, sx=18.5, sz=0.3},
    {dx=-9.5, dz=0,    sx=0.3,  sz=18.5},
    {dx= 9.5, dz=0,    sx=0.3,  sz=18.5},
}) do
    local vbn = makePart({ Name="VIPBorder", Size=Vector3.new(vb.sx,0.3,vb.sz),
        Position=Vector3.new(vipX+vb.dx, 0.75, vipZ+vb.dz),
        BrickColor=BrickColor.new("Institutional white"), Material=Enum.Material.Neon,
        CanCollide=false, CastShadow=false, Transparency=0.1 })
    vbn.Color = Color3.fromRGB(255,215,0)
    local vbl=Instance.new("PointLight"); vbl.Color=Color3.fromRGB(255,215,0); vbl.Brightness=2; vbl.Range=12; vbl.Parent=vbn
end
-- Placa VIP
local vipSign = makePart({ Name="VIPSign", Size=Vector3.new(12, 3, 0.5),
    Position=Vector3.new(vipX, 5, vipZ - 9.5),
    BrickColor=BrickColor.new("Really black"), Material=Enum.Material.SmoothPlastic, CanCollide=false })
local vipSg = Instance.new("SurfaceGui"); vipSg.Face=Enum.NormalId.Front; vipSg.Parent=vipSign
local vipLbl = Instance.new("TextLabel"); vipLbl.Size=UDim2.new(1,0,0.6,0)
vipLbl.BackgroundColor3=Color3.fromRGB(8,6,2); vipLbl.BorderSizePixel=0
vipLbl.Text="👑  ZONA VIP  👑"; vipLbl.TextColor3=Color3.fromRGB(255,215,0)
vipLbl.TextScaled=true; vipLbl.Font=Enum.Font.GothamBold; vipLbl.Parent=vipSg
local vipSub = Instance.new("TextLabel"); vipSub.Size=UDim2.new(1,0,0.35,0)
vipSub.Position=UDim2.new(0,0,0.63,0); vipSub.BackgroundTransparency=1
vipSub.Text="Prestígio 1+ para acessar"; vipSub.TextColor3=Color3.fromRGB(200,180,100)
vipSub.TextScaled=true; vipSub.Font=Enum.Font.Gotham; vipSub.Parent=vipSg
-- 4 pilares VIP com esferas douradas
for _, vc in ipairs({ {-8,-8},{8,-8},{-8,8},{8,8} }) do
    makePart({ Name="VIPPillar", Size=Vector3.new(1,10,1),
        Position=Vector3.new(vipX+vc[1], 5, vipZ+vc[2]),
        BrickColor=BrickColor.new("Dark stone grey"), Material=Enum.Material.SmoothPlastic, CanCollide=false })
    local vcap = makePart({ Name="VIPPillarCap", Shape=Enum.PartType.Ball, Size=Vector3.new(1.8,1.8,1.8),
        Position=Vector3.new(vipX+vc[1], 10.9, vipZ+vc[2]),
        BrickColor=BrickColor.new("Institutional white"), Material=Enum.Material.Neon,
        CanCollide=false, CastShadow=false, Transparency=0.1 })
    vcap.Color = Color3.fromRGB(255,215,0)
    local vcl=Instance.new("PointLight"); vcl.Color=Color3.fromRGB(255,215,0); vcl.Brightness=4; vcl.Range=16; vcl.Parent=vcap
end

-- =====================================================
--  CAIXAS / CONTAINERS INDUSTRIAIS DECORATIVOS
-- =====================================================
local boxData = {
    { x= 52, z= 30, w=3.5, h=2.5, d=3,   clr=BrickColor.new("Dark stone grey"), mat=Enum.Material.DiamondPlate },
    { x= 52, z= 35, w=3.5, h=1.5, d=3,   clr=BrickColor.new("Sand red"),        mat=Enum.Material.DiamondPlate },
    { x= 55, z= 32, w=2.5, h=4,   d=2.5, clr=BrickColor.new("Dark stone grey"), mat=Enum.Material.DiamondPlate },
    { x=-52, z= 30, w=3.5, h=2.5, d=3,   clr=BrickColor.new("Dark stone grey"), mat=Enum.Material.DiamondPlate },
    { x=-52, z=-30, w=3,   h=3,   d=3,   clr=BrickColor.new("Sand red"),        mat=Enum.Material.DiamondPlate },
    { x= 52, z=-30, w=4,   h=2,   d=3,   clr=BrickColor.new("Dark stone grey"), mat=Enum.Material.Metal        },
    { x= 48, z=-33, w=2,   h=4.5, d=2,   clr=BrickColor.new("Sand red"),        mat=Enum.Material.DiamondPlate },
    { x=-55, z=-32, w=3.5, h=3.5, d=3.5, clr=BrickColor.new("Dark stone grey"), mat=Enum.Material.Metal        },
}
for i, bd in ipairs(boxData) do
    makePart({ Name="IndustrialBox_"..i, Size=Vector3.new(bd.w, bd.h, bd.d),
        Position=Vector3.new(bd.x, bd.h/2, bd.z),
        BrickColor=bd.clr, Material=bd.mat, CanCollide=true })
end
-- Barris de metal nas entradas
for _, bp in ipairs({ {x=-18,z=minZ-14.5},{x=18,z=minZ-14.5},{x=-18,z=maxZ+14.5},{x=18,z=maxZ+14.5} }) do
    local bar = makePart({ Name="Barrel", Shape=Enum.PartType.Cylinder,
        Size=Vector3.new(2.8,1.4,1.4), Position=Vector3.new(bp.x, 0.7, bp.z),
        BrickColor=BrickColor.new("Dark stone grey"), Material=Enum.Material.DiamondPlate, CanCollide=true })
    bar.CFrame = CFrame.new(bp.x, 0.7, bp.z) * CFrame.Angles(0, 0, math.rad(90))
    local bStripe = makePart({ Name="BarrelStripe", Size=Vector3.new(2.9,0.25,1.45),
        Position=Vector3.new(bp.x, 0.9, bp.z),
        BrickColor=BrickColor.new("Bright yellow"), Material=Enum.Material.Neon,
        CanCollide=false, CastShadow=false, Transparency=0.2 })
    bStripe.CFrame = CFrame.new(bp.x, 0.9, bp.z) * CFrame.Angles(0, 0, math.rad(90))
end

-- =====================================================
--  PAREDES DE FUNDO (evita "vazio" no horizonte)
-- =====================================================
local wallHeight = 35
local wallDist   = 143
for _, wd in ipairs({
    { px=0,        pz=-wallDist, sx=300, sz=2,  rot=0          },
    { px=0,        pz= wallDist, sx=300, sz=2,  rot=0          },
    { px=-wallDist, pz=0,        sx=2,   sz=300, rot=0         },
    { px= wallDist, pz=0,        sx=2,   sz=300, rot=0         },
}) do
    makePart({ Name="BackWall", Size=Vector3.new(wd.sx, wallHeight, wd.sz),
        Position=Vector3.new(wd.px, wallHeight/2, wd.pz),
        BrickColor=BrickColor.new("Dark stone grey"), Material=Enum.Material.SmoothPlastic,
        Transparency=0, CanCollide=true })
end
-- Faixas neon nas paredes de fundo (cada parede)
for _, wn in ipairs({
    { px=0,         pz=-(wallDist-1), sx=300, sz=0.4 },
    { px=0,         pz= (wallDist-1), sx=300, sz=0.4 },
    { px=-(wallDist-1), pz=0,         sx=0.4, sz=300 },
    { px= (wallDist-1), pz=0,         sx=0.4, sz=300 },
}) do
    local wnn = makePart({ Name="WallNeon", Size=Vector3.new(wn.sx, 0.4, wn.sz),
        Position=Vector3.new(wn.px, 3, wn.pz),
        BrickColor=BrickColor.new("Institutional white"), Material=Enum.Material.Neon,
        CanCollide=false, CastShadow=false, Transparency=0.3 })
    wnn.Color = Color3.fromRGB(80, 160, 255)
end

-- =====================================================
--  MARCAÇÕES NO CHÃO DA ARENA (faixas de zona)
-- =====================================================
-- Linhas centrais cruzadas no piso
makePart({ Name="FloorLine_H", Size=Vector3.new(lenX+28, 0.06, 0.5),
    Position=Vector3.new(0, 0.0, 0),
    BrickColor=BrickColor.new("Institutional white"), Material=Enum.Material.Neon,
    CanCollide=false, CastShadow=false, Transparency=0.4 }).Color = Color3.fromRGB(255,215,0)
makePart({ Name="FloorLine_V", Size=Vector3.new(0.5, 0.06, lenZ+24),
    Position=Vector3.new(0, 0.0, 0),
    BrickColor=BrickColor.new("Institutional white"), Material=Enum.Material.Neon,
    CanCollide=false, CastShadow=false, Transparency=0.4 }).Color = Color3.fromRGB(255,215,0)
-- Círculo central (aproximado com 8 segmentos)
for seg = 0, 7 do
    local ang  = math.rad(seg * 45)
    local r    = 10
    local clp  = makePart({ Name="FloorCircle_"..seg, Size=Vector3.new(0.4, 0.06, 8),
        Position=Vector3.new(math.cos(ang)*r, 0.0, math.sin(ang)*r),
        BrickColor=BrickColor.new("Institutional white"), Material=Enum.Material.Neon,
        CanCollide=false, CastShadow=false, Transparency=0.45 })
    clp.CFrame = CFrame.new(math.cos(ang)*r, 0.0, math.sin(ang)*r) * CFrame.Angles(0, ang+math.rad(90), 0)
    clp.Color  = Color3.fromRGB(80, 200, 255)
end

-- =====================================================
--  PAINÉIS INFORMATIVOS (dicas espalhadas no mapa)
-- =====================================================
local infoBoards = {
    { x= 0,   z=maxZ+26,  face=Enum.NormalId.Front, title="💡 DICA",        body="Raros+ aparecem\npor 50s na esteira!" },
    { x= 0,   z=minZ-26,  face=Enum.NormalId.Back,  title="⚡ REBIRTH",     body="Renasça para ganhar\nmais AURA por roubo!" },
    { x=maxX+26, z=0,     face=Enum.NormalId.Left,  title="🎲 LUCKY SPIN",  body="A cada 35 roubos\nvocê ganha uma roleta!" },
    { x=minX-26, z=0,     face=Enum.NormalId.Right, title="🌙 OFFLINE",     body="Sua aura cresce\nmesmo fora do jogo!" },
}
for i, ib in ipairs(infoBoards) do
    local ibPost1 = makePart({ Name="InfoPost1_"..i, Size=Vector3.new(0.8,8,0.8),
        Position=Vector3.new(ib.x-4, 4, ib.z),
        BrickColor=BrickColor.new("Dark stone grey"), Material=Enum.Material.SmoothPlastic, CanCollide=false })
    local ibPost2 = makePart({ Name="InfoPost2_"..i, Size=Vector3.new(0.8,8,0.8),
        Position=Vector3.new(ib.x+4, 4, ib.z),
        BrickColor=BrickColor.new("Dark stone grey"), Material=Enum.Material.SmoothPlastic, CanCollide=false })
    local ibPanel = makePart({ Name="InfoPanel_"..i, Size=Vector3.new(9, 5, 0.4),
        Position=Vector3.new(ib.x, 6, ib.z),
        BrickColor=BrickColor.new("Really black"), Material=Enum.Material.SmoothPlastic, CanCollide=false })
    local ibSg = Instance.new("SurfaceGui"); ibSg.Face=ib.face; ibSg.Parent=ibPanel
    local ibBg = Instance.new("Frame"); ibBg.Size=UDim2.new(1,0,1,0)
    ibBg.BackgroundColor3=Color3.fromRGB(4,4,20); ibBg.BorderSizePixel=0; ibBg.Parent=ibSg
    local ibTitle = Instance.new("TextLabel"); ibTitle.Size=UDim2.new(1,0,0.38,0)
    ibTitle.BackgroundColor3=Color3.fromRGB(20,10,50); ibTitle.BorderSizePixel=0
    ibTitle.Text=ib.title; ibTitle.TextColor3=Color3.fromRGB(255,215,0)
    ibTitle.TextScaled=true; ibTitle.Font=Enum.Font.GothamBold; ibTitle.Parent=ibBg
    local ibBody = Instance.new("TextLabel"); ibBody.Size=UDim2.new(1,0,0.55,0)
    ibBody.Position=UDim2.new(0,0,0.40,0); ibBody.BackgroundTransparency=1
    ibBody.Text=ib.body; ibBody.TextColor3=Color3.fromRGB(200,200,200)
    ibBody.TextScaled=true; ibBody.Font=Enum.Font.Gotham
    ibBody.TextWrapped=true; ibBody.Parent=ibBg
    -- Neon border
    local ibNeon = makePart({ Name="InfoNeon_"..i, Size=Vector3.new(9.3, 0.25, 0.3),
        Position=Vector3.new(ib.x, 8.8, ib.z),
        BrickColor=BrickColor.new("Institutional white"), Material=Enum.Material.Neon,
        CanCollide=false, CastShadow=false, Transparency=0.2 })
    ibNeon.Color = Color3.fromRGB(80,180,255)
end

print("[BrainrotRoubo] Mapa COMPLETO gerado: esteira central com " .. #GameConfig.CONVEYOR_WAYPOINTS .. " waypoints, NPC Zé das Upgrades, pets, pódio 3D, arcos de entrada, vigas industriais, zona VIP e painéis informativos!")
