-- Script: ServerScriptService > MainServer
-- Lógica principal do servidor: spawn, roubo, rebirth e dados

local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local RunService         = game:GetService("RunService")
local DataStoreService   = game:GetService("DataStoreService")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local DataStore  = DataStoreService:GetDataStore("BrainrotAuraV2")

-- =====================================================
--  REMOTES
-- =====================================================
local RemoteFolder = Instance.new("Folder")
RemoteFolder.Name = "Remotes"
RemoteFolder.Parent = ReplicatedStorage

local function makeRemoteEvent(name)
    local re = Instance.new("RemoteEvent")
    re.Name = name
    re.Parent = RemoteFolder
    return re
end

local StealEvent    = makeRemoteEvent("StealBrainrot")
local UpdateAuraRE  = makeRemoteEvent("UpdateAura")
local NotifyRE      = makeRemoteEvent("Notify")
local RebirthEvent  = makeRemoteEvent("Rebirth")

-- =====================================================
--  FOLDER DE BRAINROTS NO MUNDO
-- =====================================================
local BrainrotsFolder = Instance.new("Folder")
BrainrotsFolder.Name = "Brainrots"
BrainrotsFolder.Parent = workspace

local ActiveBrainrots = {}   -- lista de Parts ativas

-- =====================================================
--  DADOS DOS JOGADORES
-- =====================================================
local PlayerData = {}

local function defaultData()
    return { aura = 0, rebirths = 0, totalStolen = 0 }
end

local function getAuraCap(rebirths)
    return math.floor(GameConfig.BASE_AURA_CAP * (GameConfig.AURA_CAP_MULTIPLIER ^ rebirths))
end

local function getRebirthCost(rebirths)
    return math.floor(getAuraCap(rebirths) * GameConfig.REBIRTH_COST_FRACTION)
end

local function getAuraMultiplier(rebirths)
    return GameConfig.AURA_GAIN_MULTIPLIER ^ rebirths
end

local function buildUpdatePayload(data)
    local rb = data.rebirths
    return {
        aura         = data.aura,
        auraCap      = getAuraCap(rb),
        rebirths     = rb,
        multiplier   = getAuraMultiplier(rb),
        rebirthCost  = getRebirthCost(rb),
        totalStolen  = data.totalStolen or 0,
    }
end

local function loadData(player)
    local ok, saved = pcall(function()
        return DataStore:GetAsync("P_" .. player.UserId)
    end)
    PlayerData[player.UserId] = (ok and saved) and saved or defaultData()
    UpdateAuraRE:FireClient(player, buildUpdatePayload(PlayerData[player.UserId]))
end

local function saveData(player)
    local data = PlayerData[player.UserId]
    if not data then return end
    pcall(function()
        DataStore:SetAsync("P_" .. player.UserId, data)
    end)
end

-- Leaderstats (aparece no leaderboard do Roblox)
local function setupLeaderstats(player)
    local ls = Instance.new("Folder")
    ls.Name = "leaderstats"
    ls.Parent = player

    local auraVal = Instance.new("NumberValue")
    auraVal.Name = "Aura"
    auraVal.Value = 0
    auraVal.Parent = ls

    local rbVal = Instance.new("NumberValue")
    rbVal.Name = "Rebirths"
    rbVal.Value = 0
    rbVal.Parent = ls

    return ls
end

local function updateLeaderstats(player)
    local data = PlayerData[player.UserId]
    if not data then return end
    local ls = player:FindFirstChild("leaderstats")
    if not ls then return end
    ls.Aura.Value    = data.aura
    ls.Rebirths.Value = data.rebirths
end

-- =====================================================
--  SPAWN DE BRAINROTS
-- =====================================================
local function pickRandomBrainrot()
    -- Soma pesos
    local total = 0
    for _, w in pairs(GameConfig.RARITY_WEIGHTS) do total = total + w end

    local roll = math.random(1, total)
    local acc = 0
    local chosenRarity = "Comum"
    for rarity, w in pairs(GameConfig.RARITY_WEIGHTS) do
        acc = acc + w
        if roll <= acc then
            chosenRarity = rarity
            break
        end
    end

    -- Pega todos do rarity sorteado
    local pool = {}
    for _, bt in ipairs(GameConfig.BRAINROT_TYPES) do
        if bt.rarity == chosenRarity then
            table.insert(pool, bt)
        end
    end

    if #pool == 0 then return GameConfig.BRAINROT_TYPES[1] end
    return pool[math.random(1, #pool)]
end

local function spawnBrainrot()
    if #ActiveBrainrots >= GameConfig.MAX_BRAINROTS then return end

    local bt    = pickRandomBrainrot()
    local color = GameConfig.RARITY_COLORS[bt.rarity]
    local half  = GameConfig.SPAWN_AREA_HALF

    local x = math.random(-half, half)
    local z = math.random(-half, half)
    local spawnY = 4

    -- Corpo principal
    local part = Instance.new("Part")
    part.Name      = "BrainrotPart"
    part.Shape     = Enum.PartType.Ball
    part.Size      = Vector3.new(3.5, 3.5, 3.5)
    part.Position  = Vector3.new(x, spawnY, z)
    part.Anchored  = true
    part.CanCollide = false
    part.Color     = color
    part.Material  = Enum.Material.Neon
    part.CastShadow = false
    part.Parent    = BrainrotsFolder

    -- Brilho
    local light = Instance.new("PointLight")
    light.Color      = color
    light.Brightness = 4
    light.Range      = 18
    light.Parent     = part

    -- Billboard com nome e raridade
    local bb = Instance.new("BillboardGui")
    bb.Size          = UDim2.new(0, 220, 0, 65)
    bb.StudsOffset   = Vector3.new(0, 3.5, 0)
    bb.AlwaysOnTop   = false
    bb.Parent        = part

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size                  = UDim2.new(1, 0, 0.55, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text                  = bt.name
    nameLabel.TextColor3            = Color3.fromRGB(255, 255, 255)
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextStrokeColor3      = Color3.fromRGB(0, 0, 0)
    nameLabel.TextScaled            = true
    nameLabel.Font                  = Enum.Font.GothamBold
    nameLabel.Parent                = bb

    local rarLabel = Instance.new("TextLabel")
    rarLabel.Size                   = UDim2.new(1, 0, 0.45, 0)
    rarLabel.Position               = UDim2.new(0, 0, 0.55, 0)
    rarLabel.BackgroundTransparency = 1
    rarLabel.Text                   = "[ " .. bt.rarity .. " ] +" .. tostring(bt.baseAura) .. " aura"
    rarLabel.TextColor3             = color
    rarLabel.TextStrokeTransparency = 0
    rarLabel.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
    rarLabel.TextScaled             = true
    rarLabel.Font                   = Enum.Font.Gotham
    rarLabel.Parent                 = bb

    -- Metadata para o servidor verificar
    local meta = Instance.new("Folder")
    meta.Name   = "Meta"
    meta.Parent = part

    local function addVal(cls, name, val)
        local v = Instance.new(cls)
        v.Name   = name
        v.Value  = val
        v.Parent = meta
    end
    addVal("StringValue", "BrainrotName", bt.name)
    addVal("StringValue", "Rarity",       bt.rarity)
    addVal("IntValue",    "AuraValue",    bt.baseAura)

    table.insert(ActiveBrainrots, part)

    -- Animação de flutuação no servidor (Heartbeat)
    local baseY = spawnY
    local t     = 0
    local conn
    conn = RunService.Heartbeat:Connect(function(dt)
        t = t + dt
        if not part or not part.Parent then
            conn:Disconnect()
            return
        end
        part.CFrame = CFrame.new(x, baseY + math.sin(t * 1.8) * 0.6, z)
                    * CFrame.Angles(0, t * 0.8, 0)
    end)

    -- Auto-despawn
    task.delay(GameConfig.BRAINROT_LIFETIME, function()
        if part and part.Parent then
            conn:Disconnect()
            for i, b in ipairs(ActiveBrainrots) do
                if b == part then table.remove(ActiveBrainrots, i) break end
            end
            part:Destroy()
        end
    end)
end

-- =====================================================
--  EVENTO: ROUBAR BRAINROT
-- =====================================================
StealEvent.OnServerEvent:Connect(function(player, brainrotPart)
    local data = PlayerData[player.UserId]
    if not data then return end
    if not brainrotPart or not brainrotPart.Parent then return end
    if brainrotPart.Parent ~= BrainrotsFolder then return end

    -- Verifica distância
    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local dist = (root.Position - brainrotPart.Position).Magnitude
    if dist > GameConfig.STEAL_RANGE + 3 then  -- +3 de tolerância de rede
        NotifyRE:FireClient(player, "Muito longe! Chegue mais perto.", Color3.fromRGB(255, 80, 80))
        return
    end

    local meta = brainrotPart:FindFirstChild("Meta")
    if not meta then return end

    local brainrotName = meta:FindFirstChildOfClass("StringValue") and meta.BrainrotName.Value or "?"
    local rarity       = meta:FindFirstChild("Rarity")    and meta.Rarity.Value    or "Comum"
    local baseAura     = meta:FindFirstChild("AuraValue") and meta.AuraValue.Value or 10

    local multiplier   = getAuraMultiplier(data.rebirths)
    local gained       = math.floor(baseAura * multiplier)
    local cap          = getAuraCap(data.rebirths)
    local newAura      = math.min(data.aura + gained, cap)
    local actual       = newAura - data.aura

    if actual <= 0 then
        NotifyRE:FireClient(player,
            "Aura no limite! Faca rebirth para aumentar o cap.",
            Color3.fromRGB(255, 200, 0))
        return
    end

    data.aura        = newAura
    data.totalStolen = (data.totalStolen or 0) + 1

    -- Remove brainrot do mundo
    for i, b in ipairs(ActiveBrainrots) do
        if b == brainrotPart then table.remove(ActiveBrainrots, i) break end
    end
    brainrotPart:Destroy()

    local rarColor = GameConfig.RARITY_COLORS[rarity] or Color3.fromRGB(255, 255, 255)
    NotifyRE:FireClient(player,
        string.format("+%d Aura  |  %s  [%s]", actual, brainrotName, rarity),
        rarColor)

    UpdateAuraRE:FireClient(player, buildUpdatePayload(data))
    updateLeaderstats(player)
end)

-- =====================================================
--  EVENTO: REBIRTH
-- =====================================================
RebirthEvent.OnServerEvent:Connect(function(player)
    local data = PlayerData[player.UserId]
    if not data then return end

    local cost = getRebirthCost(data.rebirths)
    if data.aura < cost then
        NotifyRE:FireClient(player,
            string.format("Precisa de %d aura para renascer! (voce tem %d)", cost, data.aura),
            Color3.fromRGB(255, 80, 80))
        return
    end

    data.rebirths = data.rebirths + 1
    data.aura     = 0

    local newCap  = getAuraCap(data.rebirths)
    local newMult = getAuraMultiplier(data.rebirths)

    NotifyRE:FireClient(player,
        string.format("RENASCIMENTO #%d!  Novo Cap: %d  |  Multiplicador: x%d",
            data.rebirths, newCap, newMult),
        Color3.fromRGB(255, 215, 0))

    UpdateAuraRE:FireClient(player, buildUpdatePayload(data))
    updateLeaderstats(player)
    saveData(player)
end)

-- =====================================================
--  JOGADORES
-- =====================================================
Players.PlayerAdded:Connect(function(player)
    setupLeaderstats(player)
    loadData(player)
    updateLeaderstats(player)
end)

Players.PlayerRemoving:Connect(function(player)
    saveData(player)
    PlayerData[player.UserId] = nil
end)

-- Auto-save a cada 60 segundos
task.spawn(function()
    while true do
        task.wait(60)
        for _, p in ipairs(Players:GetPlayers()) do
            saveData(p)
        end
    end
end)

-- Loop de spawn de brainrots
task.spawn(function()
    -- Spawn inicial para preencher o mapa
    for _ = 1, 15 do
        spawnBrainrot()
        task.wait(0.1)
    end
    -- Loop contínuo
    while true do
        task.wait(GameConfig.SPAWN_INTERVAL)
        spawnBrainrot()
    end
end)

print("[BrainrotRoubo] Servidor iniciado com sucesso!")
