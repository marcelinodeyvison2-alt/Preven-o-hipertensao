-- Setup.server.lua
-- Runs first. Creates RemoteEvents, BindableEvents, and builds the game map.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local BrainrotConfig = require(ReplicatedStorage.Modules.BrainrotConfig)

-- ── Remote infrastructure ─────────────────────────────────────────────────────

local function makeFolder(name, parent)
    local f = Instance.new("Folder")
    f.Name   = name
    f.Parent = parent
    return f
end

local remoteEventsFolder    = makeFolder("RemoteEvents",    ReplicatedStorage)
local remoteFunctionsFolder = makeFolder("RemoteFunctions", ReplicatedStorage)
local bindableEventsFolder  = makeFolder("BindableEvents",  ReplicatedStorage)

local REMOTE_EVENTS = {
    -- Server → Client
    "CaptureSuccess",   -- brainrot captured notification
    "Notification",     -- generic toast notification
    "SendInventory",    -- full inventory payload
    "SendRanking",      -- ranking table payload
    "AreaUnlockSuccess",-- area was unlocked
    -- Client → Server
    "SellBrainrots",    -- player wants to sell
    "UnlockArea",       -- player wants to unlock an area
    "RequestRanking",   -- player opens ranking panel
}

for _, name in ipairs(REMOTE_EVENTS) do
    local e = Instance.new("RemoteEvent")
    e.Name   = name
    e.Parent = remoteEventsFolder
end

local BINDABLE_EVENTS = {
    "BrainrotCaptured",   -- Spawner → PlayerManager
    "PlayerDataChanged",  -- PlayerManager → RankingManager
}

for _, name in ipairs(BINDABLE_EVENTS) do
    local e = Instance.new("BindableEvent")
    e.Name   = name
    e.Parent = bindableEventsFolder
end

-- ── Workspace folders ─────────────────────────────────────────────────────────

local areasFolder    = makeFolder("Areas",          workspace)
local brainrotsFolder = makeFolder("ActiveBrainrots", workspace)
local basesFolder    = makeFolder("PlayerBases",     workspace)

ReplicatedStorage:SetAttribute("SetupComplete", false)

-- ── Map builder helpers ───────────────────────────────────────────────────────

local function makePart(props)
    local p = Instance.new("Part")
    for k, v in pairs(props) do
        p[k] = v
    end
    return p
end

local function addCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(radius or 0.1, 0)
    c.Parent = parent
end

local function makeSurfaceLabel(part, face, text, textColor, bgColor, bgAlpha)
    local sg = Instance.new("SurfaceGui")
    sg.Face       = face or Enum.NormalId.Front
    sg.PixelsPerStud = 40
    sg.Parent     = part

    local lbl = Instance.new("TextLabel")
    lbl.Size               = UDim2.new(1, 0, 1, 0)
    lbl.Text               = text
    lbl.TextColor3         = textColor or Color3.new(1,1,1)
    lbl.TextScaled         = true
    lbl.BackgroundColor3   = bgColor or Color3.fromRGB(0,0,0)
    lbl.BackgroundTransparency = bgAlpha or 1
    lbl.Font               = Enum.Font.GothamBold
    lbl.TextWrapped        = true
    lbl.Parent             = sg
    return lbl
end

-- ── Central Hub ───────────────────────────────────────────────────────────────

local hub = makePart({
    Name       = "CentralHub",
    Size       = Vector3.new(70, 1, 70),
    Position   = Vector3.new(0, 0, 0),
    Anchored   = true,
    Material   = Enum.Material.SmoothPlastic,
    Color      = Color3.fromRGB(230, 210, 160),
    Parent     = workspace,
})

-- SpawnLocation
local spawnLoc = workspace:FindFirstChildOfClass("SpawnLocation")
if not spawnLoc then
    spawnLoc = Instance.new("SpawnLocation")
end
spawnLoc.Size     = Vector3.new(6, 1, 6)
spawnLoc.Position = Vector3.new(0, 1, 0)
spawnLoc.Neutral  = true
spawnLoc.Parent   = workspace

-- Aura Shop building
local shopBase = makePart({
    Name     = "AuraShop",
    Size     = Vector3.new(10, 8, 6),
    Position = Vector3.new(-20, 4, -12),
    Anchored = true,
    Material = Enum.Material.Neon,
    Color    = Color3.fromRGB(255, 215, 0),
    Parent   = workspace,
})
makeSurfaceLabel(shopBase, Enum.NormalId.Front, "💰 LOJA DE AURA\nVenda seus Brainrots!", Color3.new(1,1,1), Color3.fromRGB(0,0,0), 0.5)

local shopPrompt = Instance.new("ProximityPrompt")
shopPrompt.ActionText          = "Abrir Loja"
shopPrompt.ObjectText          = "Loja de Aura"
shopPrompt.HoldDuration        = 0
shopPrompt.MaxActivationDistance = 12
shopPrompt.KeyboardKeyCode     = Enum.KeyCode.E
shopPrompt.Parent              = shopBase

-- Ranking Board
local rankBoard = makePart({
    Name     = "RankingBoard",
    Size     = Vector3.new(14, 12, 1),
    Position = Vector3.new(20, 6, -28),
    Anchored = true,
    Material = Enum.Material.SmoothPlastic,
    Color    = Color3.fromRGB(15, 15, 40),
    Parent   = workspace,
})

local rankSg = Instance.new("SurfaceGui")
rankSg.Name        = "RankingGui"
rankSg.Face        = Enum.NormalId.Front
rankSg.PixelsPerStud = 50
rankSg.Parent      = rankBoard

local rankTitle = Instance.new("TextLabel")
rankTitle.Name               = "Title"
rankTitle.Size               = UDim2.new(1, 0, 0.15, 0)
rankTitle.Text               = "🏆 RANKING GLOBAL"
rankTitle.TextColor3         = Color3.fromRGB(255, 215, 0)
rankTitle.TextScaled         = true
rankTitle.BackgroundTransparency = 1
rankTitle.Font               = Enum.Font.GothamBold
rankTitle.Parent             = rankSg

local rankList = Instance.new("Frame")
rankList.Name               = "List"
rankList.Size               = UDim2.new(1, 0, 0.85, 0)
rankList.Position           = UDim2.new(0, 0, 0.15, 0)
rankList.BackgroundTransparency = 1
rankList.Parent             = rankSg

local rankLayout = Instance.new("UIListLayout")
rankLayout.SortOrder      = Enum.SortOrder.LayoutOrder
rankLayout.Padding        = UDim.new(0.01, 0)
rankLayout.Parent         = rankList

-- NPC Tutorial
local function buildNPC(pos, label, speech)
    local model  = Instance.new("Model")
    model.Name   = label
    model.Parent = workspace

    local torso = makePart({
        Name     = "Torso",
        Size     = Vector3.new(2, 2.5, 1),
        Position = pos + Vector3.new(0, 2.75, 0),
        Anchored = true,
        Color    = Color3.fromRGB(0, 120, 200),
        Parent   = model,
    })

    local head = makePart({
        Name      = "Head",
        Shape     = Enum.PartType.Ball,
        Size      = Vector3.new(2, 2, 2),
        Position  = pos + Vector3.new(0, 5, 0),
        Anchored  = true,
        Color     = Color3.fromRGB(255, 220, 160),
        Parent    = model,
    })

    local bb = Instance.new("BillboardGui")
    bb.Size         = UDim2.new(0, 220, 0, 100)
    bb.StudsOffset  = Vector3.new(0, 4.5, 0)
    bb.AlwaysOnTop  = false
    bb.Parent       = head

    local bubble = Instance.new("TextLabel")
    bubble.Size                = UDim2.new(1, 0, 1, 0)
    bubble.Text                = speech
    bubble.TextColor3          = Color3.new(1, 1, 1)
    bubble.TextScaled          = true
    bubble.TextWrapped         = true
    bubble.BackgroundColor3    = Color3.fromRGB(20, 20, 50)
    bubble.BackgroundTransparency = 0.2
    bubble.Font                = Enum.Font.Gotham
    bubble.Parent              = bb
    addCorner(bubble, 0.15)

    model.PrimaryPart = torso
end

buildNPC(Vector3.new(12, 1, 8),  "NPCTutorial", "🎮 Toque nos Brainrots\npara capturá-los!\nVenda por Aura! 🌟")

-- ── Area floors & spawn points ────────────────────────────────────────────────

for areaKey, areaData in pairs(BrainrotConfig.Areas) do
    local areaModel = Instance.new("Model")
    areaModel.Name   = areaKey
    areaModel.Parent = areasFolder

    -- Floor
    local floor = makePart({
        Name     = "Floor",
        Size     = areaData.Size,
        Position = areaData.Position,
        Anchored = true,
        Material = Enum.Material.SmoothPlastic,
        Color    = areaData.FloorColor,
        Parent   = areaModel,
    })

    -- Area sign arch
    local arch = makePart({
        Name     = "Sign",
        Size     = Vector3.new(areaData.Size.X * 0.6, 6, 1),
        Position = areaData.Position + Vector3.new(0, 9, areaData.Size.Z / 2 + 1),
        Anchored = true,
        Color    = areaData.FloorColor,
        Parent   = areaModel,
    })

    local lockText = areaData.UnlockCost > 0
        and ("\n🔒 " .. tostring(areaData.UnlockCost) .. " Aura para desbloquear")
        or  "\n✅ Área Inicial"

    makeSurfaceLabel(
        arch, Enum.NormalId.Back,
        areaData.DisplayName .. lockText,
        Color3.new(1, 1, 1),
        Color3.fromRGB(0, 0, 0), 0.35
    )

    -- Invisible spawn markers
    local spawnFolder = Instance.new("Folder")
    spawnFolder.Name   = "SpawnPoints"
    spawnFolder.Parent = areaModel

    local halfX = areaData.Size.X / 2 - 8
    local halfZ = areaData.Size.Z / 2 - 8
    math.randomseed(areaKey:len() * 7)  -- deterministic positions per area

    for i = 1, areaData.MaxSpawns do
        local sp = makePart({
            Name         = "SP_" .. i,
            Size         = Vector3.new(1, 1, 1),
            Position     = areaData.Position + Vector3.new(
                math.random(-halfX, halfX),
                areaData.SpawnHeightOffset,
                math.random(-halfZ, halfZ)
            ),
            Anchored     = true,
            Transparency = 1,
            CanCollide   = false,
            Parent       = spawnFolder,
        })
    end
end

-- Signal other scripts that setup is done
ReplicatedStorage:SetAttribute("SetupComplete", true)
print("[Setup] Map built. RemoteEvents and BindableEvents ready.")
