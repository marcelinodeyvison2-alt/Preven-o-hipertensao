-- Setup.server.lua
-- Runs first. Creates RemoteEvents, BindableEvents, and builds the game map.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotConfig = require(ReplicatedStorage.Modules.BrainrotConfig)

-- ── Remote infrastructure ─────────────────────────────────────────────────────

local function makeFolder(name, parent)
    local f = Instance.new("Folder")
    f.Name   = name
    f.Parent = parent
    return f
end

local remoteEventsFolder    = makeFolder("RemoteEvents",    ReplicatedStorage)
local bindableEventsFolder  = makeFolder("BindableEvents",  ReplicatedStorage)

local REMOTE_EVENTS = {
    -- Core game (Server → Client)
    "CaptureSuccess", "Notification", "SendInventory", "SendRanking", "AreaUnlockSuccess",
    -- Core game (Client → Server)
    "SellBrainrots", "UnlockArea", "RequestRanking",
    -- Pets (S→C)
    "PetUpdate",
    -- Pets (C→S)
    "OpenPetEgg", "EquipPet", "UnequipPet",
    -- Rebirth (S→C)
    "RebirthUpdate",
    -- Rebirth (C→S)
    "RequestRebirth",
    -- Events (S→C)
    "EventUpdate",
    -- Trade (S→C)
    "TradeRequestIncoming", "TradeStateUpdate", "TradeResult",
    -- Trade (C→S)
    "SendTradeRequest", "RespondTrade", "UpdateTradeOffer", "ConfirmTrade", "CancelTrade",
    -- Clans (S→C)
    "ClanUpdate", "ClanRankingUpdate",
    -- Clans (C→S)
    "CreateClan", "JoinClan", "LeaveClan", "KickMember", "PromoteLeader",
    -- Missions (S→C)
    "MissionUpdate",
    -- Missions (C→S)
    "ClaimMissionReward",
}

for _, name in ipairs(REMOTE_EVENTS) do
    local e = Instance.new("RemoteEvent")
    e.Name   = name
    e.Parent = remoteEventsFolder
end

local BINDABLE_EVENTS = {
    "BrainrotCaptured",   -- Spawner → PlayerManager + MissionManager
    "PlayerDataChanged",  -- PlayerManager → RankingManager
    "EventChanged",       -- EventManager → BrainrotSpawner
    "BrainrotsSold",      -- PlayerManager → MissionManager
    "PetEggOpened",       -- PlayerManager → MissionManager
}

for _, name in ipairs(BINDABLE_EVENTS) do
    local e = Instance.new("BindableEvent")
    e.Name   = name
    e.Parent = bindableEventsFolder
end

-- ── Workspace folders ─────────────────────────────────────────────────────────

local function makeWsFolder(name)
    local f = Instance.new("Folder")
    f.Name   = name
    f.Parent = workspace
    return f
end

makeWsFolder("Areas")
makeWsFolder("ActiveBrainrots")
makeWsFolder("PlayerBases")

-- ── Map builder helpers ───────────────────────────────────────────────────────

local function makePart(props)
    local p = Instance.new("Part")
    for k, v in pairs(props) do p[k] = v end
    return p
end

local function corner(parent, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(r or 0.1, 0)
    c.Parent = parent
end

local function makeSurfaceLabel(part, face, text, textColor, bgAlpha)
    local sg = Instance.new("SurfaceGui")
    sg.Face          = face or Enum.NormalId.Front
    sg.PixelsPerStud = 40
    sg.Parent        = part

    local lbl = Instance.new("TextLabel")
    lbl.Size               = UDim2.new(1, 0, 1, 0)
    lbl.Text               = text
    lbl.TextColor3         = textColor or Color3.new(1,1,1)
    lbl.TextScaled         = true
    lbl.BackgroundTransparency = bgAlpha or 1
    lbl.Font               = Enum.Font.GothamBold
    lbl.TextWrapped        = true
    lbl.Parent             = sg
    return lbl
end

-- ── Central Hub ───────────────────────────────────────────────────────────────

makePart({
    Name     = "CentralHub",
    Size     = Vector3.new(70, 1, 70),
    Position = Vector3.new(0, 0, 0),
    Anchored = true,
    Material = Enum.Material.SmoothPlastic,
    Color    = Color3.fromRGB(230, 210, 160),
    Parent   = workspace,
})

local spawnLoc = workspace:FindFirstChildOfClass("SpawnLocation")
if not spawnLoc then spawnLoc = Instance.new("SpawnLocation") end
spawnLoc.Size     = Vector3.new(6, 1, 6)
spawnLoc.Position = Vector3.new(0, 1, 0)
spawnLoc.Neutral  = true
spawnLoc.Parent   = workspace

-- Aura Shop
local shopBase = makePart({
    Name     = "AuraShop",
    Size     = Vector3.new(10, 8, 6),
    Position = Vector3.new(-20, 4, -12),
    Anchored = true,
    Material = Enum.Material.Neon,
    Color    = Color3.fromRGB(255, 215, 0),
    Parent   = workspace,
})
makeSurfaceLabel(shopBase, Enum.NormalId.Front, "💰 LOJA DE AURA\nVenda seus Brainrots!", Color3.new(1,1,1), 0.5)
local shopPrompt = Instance.new("ProximityPrompt")
shopPrompt.ActionText = "Abrir Loja"; shopPrompt.ObjectText = "Loja de Aura"
shopPrompt.HoldDuration = 0; shopPrompt.MaxActivationDistance = 12
shopPrompt.Parent = shopBase

-- Pet Shop
local petShop = makePart({
    Name     = "PetShop",
    Size     = Vector3.new(10, 8, 6),
    Position = Vector3.new(20, 4, -12),
    Anchored = true,
    Material = Enum.Material.Neon,
    Color    = Color3.fromRGB(100, 200, 255),
    Parent   = workspace,
})
makeSurfaceLabel(petShop, Enum.NormalId.Front, "🐾 LOJA DE PETS\nAbra Ovos por 500 Aura!", Color3.new(1,1,1), 0.5)
local petPrompt = Instance.new("ProximityPrompt")
petPrompt.ActionText = "Ver Pets"; petPrompt.ObjectText = "Loja de Pets"
petPrompt.HoldDuration = 0; petPrompt.MaxActivationDistance = 12
petPrompt.Parent = petShop

-- Rebirth Altar
local altar = makePart({
    Name     = "RebirthAltar",
    Size     = Vector3.new(8, 8, 8),
    Position = Vector3.new(0, 4, -28),
    Anchored = true,
    Material = Enum.Material.Neon,
    Color    = Color3.fromRGB(255, 80, 80),
    Parent   = workspace,
})
makeSurfaceLabel(altar, Enum.NormalId.Front, "♻️ ALTAR DO REBIRTH\nRecomece mais forte!", Color3.new(1,1,1), 0.5)
local altarPrompt = Instance.new("ProximityPrompt")
altarPrompt.ActionText = "Ver Rebirth"; altarPrompt.ObjectText = "Altar do Rebirth"
altarPrompt.HoldDuration = 0; altarPrompt.MaxActivationDistance = 12
altarPrompt.Parent = altar

-- Ranking Board
local rankBoard = makePart({
    Name     = "RankingBoard",
    Size     = Vector3.new(14, 12, 1),
    Position = Vector3.new(30, 6, -28),
    Anchored = true,
    Material = Enum.Material.SmoothPlastic,
    Color    = Color3.fromRGB(15, 15, 40),
    Parent   = workspace,
})
local rankSg = Instance.new("SurfaceGui")
rankSg.Name = "RankingGui"; rankSg.Face = Enum.NormalId.Front
rankSg.PixelsPerStud = 50; rankSg.Parent = rankBoard
local rankTitle = Instance.new("TextLabel")
rankTitle.Name = "Title"; rankTitle.Size = UDim2.new(1,0,0.15,0)
rankTitle.Text = "🏆 RANKING GLOBAL"; rankTitle.TextColor3 = Color3.fromRGB(255,215,0)
rankTitle.TextScaled = true; rankTitle.BackgroundTransparency = 1
rankTitle.Font = Enum.Font.GothamBold; rankTitle.Parent = rankSg
local rankList = Instance.new("Frame")
rankList.Name = "List"; rankList.Size = UDim2.new(1,0,0.85,0)
rankList.Position = UDim2.new(0,0,0.15,0); rankList.BackgroundTransparency = 1
rankList.Parent = rankSg
local rl = Instance.new("UIListLayout"); rl.SortOrder = Enum.SortOrder.LayoutOrder
rl.Padding = UDim.new(0.01,0); rl.Parent = rankList

-- Clan Hall
local clanHall = makePart({
    Name     = "ClanHall",
    Size     = Vector3.new(12, 8, 6),
    Position = Vector3.new(-30, 4, 15),
    Anchored = true,
    Material = Enum.Material.SmoothPlastic,
    Color    = Color3.fromRGB(60, 40, 120),
    Parent   = workspace,
})
makeSurfaceLabel(clanHall, Enum.NormalId.Front, "🏛️ SALAO DOS CLAS\nCrie ou entre em um cla!", Color3.new(1,1,1), 0.5)
local clanPrompt = Instance.new("ProximityPrompt")
clanPrompt.ActionText = "Ver Clas"; clanPrompt.ObjectText = "Salao dos Clas"
clanPrompt.HoldDuration = 0; clanPrompt.MaxActivationDistance = 14
clanPrompt.Parent = clanHall

-- NPC Tutorial
local function buildNPC(pos, speech)
    local model = Instance.new("Model"); model.Name = "NPC"; model.Parent = workspace
    local torso = makePart({ Name="Torso", Size=Vector3.new(2,2.5,1), Position=pos+Vector3.new(0,2.75,0),
        Anchored=true, Color=Color3.fromRGB(0,120,200), Parent=model })
    local head = makePart({ Name="Head", Shape=Enum.PartType.Ball, Size=Vector3.new(2,2,2),
        Position=pos+Vector3.new(0,5,0), Anchored=true, Color=Color3.fromRGB(255,220,160), Parent=model })
    local bb = Instance.new("BillboardGui"); bb.Size=UDim2.new(0,240,0,100)
    bb.StudsOffset=Vector3.new(0,4.5,0); bb.Parent=head
    local bub = Instance.new("TextLabel"); bub.Size=UDim2.new(1,0,1,0)
    bub.Text=speech; bub.TextColor3=Color3.new(1,1,1); bub.TextScaled=true
    bub.TextWrapped=true; bub.BackgroundColor3=Color3.fromRGB(20,20,50)
    bub.BackgroundTransparency=0.2; bub.Font=Enum.Font.Gotham; bub.Parent=bb
    corner(bub, 0.15); model.PrimaryPart=torso
end
buildNPC(Vector3.new(12,1,8), "🎮 Capture Brainrots!\n🐾 Compre Pets!\n🏛️ Entre num Cla!")

-- ── Area floors & spawn points ────────────────────────────────────────────────

local areasFolder = workspace:WaitForChild("Areas")

for areaKey, areaData in pairs(BrainrotConfig.Areas) do
    local areaModel = Instance.new("Model"); areaModel.Name = areaKey; areaModel.Parent = areasFolder

    makePart({ Name="Floor", Size=areaData.Size, Position=areaData.Position,
        Anchored=true, Material=Enum.Material.SmoothPlastic,
        Color=areaData.FloorColor, Parent=areaModel })

    local arch = makePart({ Name="Sign",
        Size=Vector3.new(areaData.Size.X*0.6, 6, 1),
        Position=areaData.Position+Vector3.new(0,9,areaData.Size.Z/2+1),
        Anchored=true, Color=areaData.FloorColor, Parent=areaModel })

    local lockText = areaData.UnlockCost > 0
        and ("\n🔒 "..tostring(areaData.UnlockCost).." Aura")
        or  "\n✅ Inicial"
    makeSurfaceLabel(arch, Enum.NormalId.Back, areaData.DisplayName..lockText, Color3.new(1,1,1), 0.35)

    local spawnFolder = Instance.new("Folder"); spawnFolder.Name="SpawnPoints"; spawnFolder.Parent=areaModel
    local halfX = areaData.Size.X/2 - 8
    local halfZ = areaData.Size.Z/2 - 8
    math.randomseed(areaKey:len() * 7)
    for i = 1, areaData.MaxSpawns do
        makePart({ Name="SP_"..i,
            Size=Vector3.new(1,1,1),
            Position=areaData.Position+Vector3.new(math.random(-halfX,halfX),areaData.SpawnHeightOffset,math.random(-halfZ,halfZ)),
            Anchored=true, Transparency=1, CanCollide=false, Parent=spawnFolder })
    end
end

ReplicatedStorage:SetAttribute("SetupComplete", true)
print("[Setup] Map built. All remotes ready.")
