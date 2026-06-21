-- Script: ServerScriptService > MainServer
-- Lógica principal: spawn em bases, mutações, Lua de Sangue, índice

local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local RunService         = game:GetService("RunService")
local DataStoreService   = game:GetService("DataStoreService")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local DataStore  = DataStoreService:GetDataStore("BrainrotAuraV3")

-- =====================================================
--  REMOTES
-- =====================================================
local RemoteFolder = Instance.new("Folder")
RemoteFolder.Name = "Remotes"
RemoteFolder.Parent = ReplicatedStorage

local function makeRE(name)
    local re = Instance.new("RemoteEvent")
    re.Name = name
    re.Parent = RemoteFolder
    return re
end

local StealEvent       = makeRE("StealBrainrot")
local UpdateAuraRE     = makeRE("UpdateAura")
local NotifyRE         = makeRE("Notify")
local RebirthEvent     = makeRE("Rebirth")
local IndexUpdateRE    = makeRE("IndexUpdate")
local GlobalAnnounceRE = makeRE("GlobalAnnounce")

-- =====================================================
--  FOLDER DE BRAINROTS NO MUNDO
-- =====================================================
local BrainrotsFolder = Instance.new("Folder")
BrainrotsFolder.Name = "Brainrots"
BrainrotsFolder.Parent = workspace

-- Controle de bases ocupadas  [baseIndex] = brainrotPart | nil
local BaseOccupied = {}

-- Contador global de spawns (para Lua de Sangue)
local globalSpawnCount = 0

-- =====================================================
--  DADOS DOS JOGADORES
-- =====================================================
local PlayerData = {}

local function defaultData()
    return {
        aura        = 0,
        rebirths    = 0,
        totalStolen = 0,
        index       = { brainrots = {}, mutations = {} },
    }
end

local function getAuraCap(rb)
    return math.floor(GameConfig.BASE_AURA_CAP * (GameConfig.AURA_CAP_MULTIPLIER ^ rb))
end

local function getRebirthCost(rb)
    return math.floor(getAuraCap(rb) * GameConfig.REBIRTH_COST_FRACTION)
end

local function getAuraMultiplier(rb)
    return GameConfig.AURA_GAIN_MULTIPLIER ^ rb
end

local function buildUpdatePayload(data)
    local rb = data.rebirths
    return {
        aura        = data.aura,
        auraCap     = getAuraCap(rb),
        rebirths    = rb,
        multiplier  = getAuraMultiplier(rb),
        rebirthCost = getRebirthCost(rb),
        totalStolen = data.totalStolen or 0,
    }
end

local function loadData(player)
    local ok, saved = pcall(function()
        return DataStore:GetAsync("P_" .. player.UserId)
    end)
    local data = (ok and saved) and saved or defaultData()
    -- Garante que index existe em saves antigos
    if not data.index then data.index = { brainrots = {}, mutations = {} } end
    PlayerData[player.UserId] = data
    UpdateAuraRE:FireClient(player, buildUpdatePayload(data))
    IndexUpdateRE:FireClient(player, data.index)
end

local function saveData(player)
    local data = PlayerData[player.UserId]
    if not data then return end
    pcall(function()
        DataStore:SetAsync("P_" .. player.UserId, data)
    end)
end

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
end

local function updateLeaderstats(player)
    local data = PlayerData[player.UserId]
    if not data then return end
    local ls = player:FindFirstChild("leaderstats")
    if not ls then return end
    ls.Aura.Value     = data.aura
    ls.Rebirths.Value = data.rebirths
end

-- =====================================================
--  SISTEMA DE MUTAÇÃO
-- =====================================================
local MUTATION_TOTAL_WEIGHT = 0
for _, m in ipairs(GameConfig.MUTATIONS) do
    MUTATION_TOTAL_WEIGHT = MUTATION_TOTAL_WEIGHT + m.weight
end

local function pickMutation(forceLuaDeSangue)
    if forceLuaDeSangue then
        -- Acha a entrada Lua de Sangue
        for _, m in ipairs(GameConfig.MUTATIONS) do
            if m.name == "Lua de Sangue" then return m end
        end
    end

    local roll = math.random(1, MUTATION_TOTAL_WEIGHT)
    local acc  = 0
    for _, m in ipairs(GameConfig.MUTATIONS) do
        if m.weight > 0 then
            acc = acc + m.weight
            if roll <= acc then return m end
        end
    end
    return GameConfig.MUTATIONS[1]
end

-- =====================================================
--  SORTEIO DE BRAINROT
-- =====================================================
local RARITY_TOTAL = 0
for _, w in pairs(GameConfig.RARITY_WEIGHTS) do RARITY_TOTAL = RARITY_TOTAL + w end

local function pickBrainrotType()
    local roll = math.random(1, RARITY_TOTAL)
    local acc  = 0
    local chosen = "Comum"
    for rarity, w in pairs(GameConfig.RARITY_WEIGHTS) do
        acc = acc + w
        if roll <= acc then chosen = rarity break end
    end

    local pool = {}
    for _, bt in ipairs(GameConfig.BRAINROT_TYPES) do
        if bt.rarity == chosen then table.insert(pool, bt) end
    end
    if #pool == 0 then return GameConfig.BRAINROT_TYPES[1] end
    return pool[math.random(1, #pool)]
end

-- =====================================================
--  SPAWN DE BRAINROT EM BASE
-- =====================================================
local function getFreeBases()
    local free = {}
    for i = 1, #GameConfig.BASE_POSITIONS do
        if not BaseOccupied[i] then
            table.insert(free, i)
        end
    end
    return free
end

local function spawnBrainrot()
    local freeBases = getFreeBases()
    if #freeBases == 0 then return end

    globalSpawnCount = globalSpawnCount + 1
    local isLuaDeSangue = (globalSpawnCount % GameConfig.LUA_DE_SANGUE_INTERVAL == 0)

    local baseIdx  = freeBases[math.random(1, #freeBases)]
    local basePos  = GameConfig.BASE_POSITIONS[baseIdx]
    local bt       = pickBrainrotType()
    local mutation = pickMutation(isLuaDeSangue)

    local rarColor = GameConfig.RARITY_COLORS[bt.rarity]
    local mutColor = mutation.color
    local spawnY   = basePos.Y + 4

    -- Parte principal
    local part = Instance.new("Part")
    part.Name       = "BrainrotPart"
    part.Shape      = Enum.PartType.Ball
    part.Size       = Vector3.new(3.5, 3.5, 3.5)
    part.Position   = Vector3.new(basePos.X, spawnY, basePos.Z)
    part.Anchored   = true
    part.CanCollide = false
    part.Color      = isLuaDeSangue and Color3.fromRGB(200, 0, 0) or rarColor
    part.Material   = Enum.Material.Neon
    part.CastShadow = false
    part.Parent     = BrainrotsFolder

    local light = Instance.new("PointLight")
    light.Color      = isLuaDeSangue and Color3.fromRGB(255, 0, 0) or rarColor
    light.Brightness = isLuaDeSangue and 10 or 4
    light.Range      = isLuaDeSangue and 35 or 18
    light.Parent     = part

    -- Billboard
    local bb = Instance.new("BillboardGui")
    bb.Size        = UDim2.new(0, 240, 0, isLuaDeSangue and 100 or 80)
    bb.StudsOffset = Vector3.new(0, 4, 0)
    bb.AlwaysOnTop = false
    bb.Parent      = part

    local function addLabel(yPos, height, text, color, font, bold)
        local lbl = Instance.new("TextLabel")
        lbl.Size                   = UDim2.new(1, 0, height, 0)
        lbl.Position               = UDim2.new(0, 0, yPos, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text                   = text
        lbl.TextColor3             = color
        lbl.TextStrokeTransparency = 0
        lbl.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
        lbl.TextScaled             = true
        lbl.Font                   = bold and Enum.Font.GothamBold or Enum.Font.Gotham
        lbl.Parent                 = bb
        return lbl
    end

    -- Nome do brainrot
    local nameText = isLuaDeSangue and ("🌑 " .. bt.name .. " 🌑") or bt.name
    addLabel(0,    0.38, nameText, Color3.fromRGB(255,255,255), nil, true)
    -- Raridade
    addLabel(0.38, 0.30, "[ " .. bt.rarity .. " ]", rarColor, nil, false)
    -- Mutação
    local mutText = isLuaDeSangue and "✦ LUA DE SANGUE ×20 ✦" or ("✦ " .. mutation.name .. "  ×" .. tostring(mutation.multiplier))
    addLabel(0.68, 0.32, mutText, mutColor, nil, true)

    -- Metadata
    local meta = Instance.new("Folder")
    meta.Name = "Meta"
    meta.Parent = part

    local function addVal(cls, name, val)
        local v = Instance.new(cls)
        v.Name   = name
        v.Value  = val
        v.Parent = meta
    end
    addVal("StringValue", "BrainrotName",    bt.name)
    addVal("StringValue", "Rarity",          bt.rarity)
    addVal("IntValue",    "AuraValue",       bt.baseAura)
    addVal("StringValue", "MutationName",    mutation.name)
    addVal("IntValue",    "MutationMult",    mutation.multiplier)
    addVal("IntValue",    "BaseIndex",       baseIdx)

    BaseOccupied[baseIdx] = part

    -- Atualiza luz indicadora na base
    local basePart = workspace:FindFirstChild("Base_" .. baseIdx)
    if basePart then
        local ind = basePart:FindFirstChild("Indicator")
        if ind then
            ind.Color = isLuaDeSangue and Color3.fromRGB(255, 0, 0) or rarColor
        end
    end

    -- Animação de flutuação
    local baseY = spawnY
    local t     = 0
    local conn
    conn = RunService.Heartbeat:Connect(function(dt)
        t = t + dt
        if not part or not part.Parent then
            conn:Disconnect()
            return
        end
        part.CFrame = CFrame.new(basePos.X, baseY + math.sin(t * 1.8) * 0.7, basePos.Z)
                    * CFrame.Angles(0, t * 0.9, 0)
    end)

    -- Anúncio global de Lua de Sangue
    if isLuaDeSangue then
        local baseName = GameConfig.BASE_NAMES[baseIdx] or ("Base " .. baseIdx)
        GlobalAnnounceRE:FireAllClients(
            string.format("🌑 LUA DE SANGUE apareceu em %s!  [%s]  ×20 Aura!", baseName, bt.rarity),
            Color3.fromRGB(220, 0, 0)
        )
    end

    -- Auto-despawn
    task.delay(GameConfig.BRAINROT_LIFETIME, function()
        if part and part.Parent then
            conn:Disconnect()
            BaseOccupied[baseIdx] = nil
            -- Reseta indicador da base
            local bp = workspace:FindFirstChild("Base_" .. baseIdx)
            if bp then
                local ind = bp:FindFirstChild("Indicator")
                if ind then ind.Color = Color3.fromRGB(60, 60, 80) end
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

    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local dist = (root.Position - brainrotPart.Position).Magnitude
    if dist > GameConfig.STEAL_RANGE + 4 then
        NotifyRE:FireClient(player, "Muito longe! Chegue mais perto da base.", Color3.fromRGB(255, 80, 80))
        return
    end

    local meta = brainrotPart:FindFirstChild("Meta")
    if not meta then return end

    local brainrotName = meta:FindFirstChild("BrainrotName") and meta.BrainrotName.Value or "?"
    local rarity       = meta:FindFirstChild("Rarity")       and meta.Rarity.Value       or "Comum"
    local baseAura     = meta:FindFirstChild("AuraValue")    and meta.AuraValue.Value     or 10
    local mutName      = meta:FindFirstChild("MutationName") and meta.MutationName.Value  or "Básico"
    local mutMult      = meta:FindFirstChild("MutationMult") and meta.MutationMult.Value  or 1
    local baseIdx      = meta:FindFirstChild("BaseIndex")    and meta.BaseIndex.Value     or 0

    local rebirthMult = getAuraMultiplier(data.rebirths)
    local totalGain   = math.floor(baseAura * mutMult * rebirthMult)
    local cap         = getAuraCap(data.rebirths)
    local newAura     = math.min(data.aura + totalGain, cap)
    local actual      = newAura - data.aura

    if actual <= 0 then
        NotifyRE:FireClient(player,
            "Aura no limite! Faca rebirth para aumentar o cap.",
            Color3.fromRGB(255, 200, 0))
        return
    end

    data.aura        = newAura
    data.totalStolen = (data.totalStolen or 0) + 1

    -- Atualiza index do jogador
    local idx = data.index
    if not idx.brainrots[brainrotName] then
        idx.brainrots[brainrotName] = { count = 0, bestMutation = "Básico" }
    end
    idx.brainrots[brainrotName].count = idx.brainrots[brainrotName].count + 1

    -- Guarda melhor mutação (por multiplicador)
    local prevBestMult = 1
    for _, m in ipairs(GameConfig.MUTATIONS) do
        if m.name == idx.brainrots[brainrotName].bestMutation then
            prevBestMult = m.multiplier
            break
        end
    end
    if mutMult > prevBestMult then
        idx.brainrots[brainrotName].bestMutation = mutName
    end

    idx.mutations[mutName] = (idx.mutations[mutName] or 0) + 1

    -- Remove brainrot do mundo
    if baseIdx > 0 then
        BaseOccupied[baseIdx] = nil
        local bp = workspace:FindFirstChild("Base_" .. baseIdx)
        if bp then
            local ind = bp:FindFirstChild("Indicator")
            if ind then ind.Color = Color3.fromRGB(60, 60, 80) end
        end
    end
    brainrotPart:Destroy()

    -- Notificações
    local rarColor = GameConfig.RARITY_COLORS[rarity] or Color3.fromRGB(255,255,255)
    local mutColor = Color3.fromRGB(255,255,255)
    for _, m in ipairs(GameConfig.MUTATIONS) do
        if m.name == mutName then mutColor = m.color break end
    end

    local mutLine = (mutName ~= "Básico") and ("  [" .. mutName .. " ×" .. mutMult .. "]") or ""
    NotifyRE:FireClient(player,
        string.format("+%s Aura  •  %s  [%s]%s", formatBig(actual), brainrotName, rarity, mutLine),
        mutName == "Lua de Sangue" and Color3.fromRGB(220,0,0) or rarColor)

    UpdateAuraRE:FireClient(player, buildUpdatePayload(data))
    IndexUpdateRE:FireClient(player, data.index)
    updateLeaderstats(player)
end)

-- Helper de formatação (precisa estar antes do evento de roubo)
function formatBig(n)
    if n >= 1e12 then return string.format("%.1fT", n/1e12) end
    if n >= 1e9  then return string.format("%.1fB", n/1e9)  end
    if n >= 1e6  then return string.format("%.1fM", n/1e6)  end
    if n >= 1000 then return string.format("%.1fK", n/1000) end
    return tostring(math.floor(n))
end

-- =====================================================
--  EVENTO: REBIRTH
-- =====================================================
RebirthEvent.OnServerEvent:Connect(function(player)
    local data = PlayerData[player.UserId]
    if not data then return end

    local cost = getRebirthCost(data.rebirths)
    if data.aura < cost then
        NotifyRE:FireClient(player,
            string.format("Precisa de %s aura! (voce tem %s)", formatBig(cost), formatBig(data.aura)),
            Color3.fromRGB(255, 80, 80))
        return
    end

    data.rebirths = data.rebirths + 1
    data.aura     = 0

    local newCap  = getAuraCap(data.rebirths)
    local newMult = getAuraMultiplier(data.rebirths)

    NotifyRE:FireClient(player,
        string.format("RENASCIMENTO #%d!  Cap: %s  |  Mult: x%s",
            data.rebirths, formatBig(newCap), formatBig(newMult)),
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

task.spawn(function()
    while true do
        task.wait(60)
        for _, p in ipairs(Players:GetPlayers()) do saveData(p) end
    end
end)

-- =====================================================
--  LOOP DE SPAWN
-- =====================================================
task.spawn(function()
    -- Preenche todas as bases no início
    for _ = 1, #GameConfig.BASE_POSITIONS do
        spawnBrainrot()
        task.wait(0.15)
    end
    while true do
        task.wait(GameConfig.SPAWN_INTERVAL)
        spawnBrainrot()
    end
end)

print("[BrainrotRoubo] Servidor iniciado! Bases: " .. #GameConfig.BASE_POSITIONS)
