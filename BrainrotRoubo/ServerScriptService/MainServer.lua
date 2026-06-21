-- Script: ServerScriptService > MainServer
-- Lógica principal: spawn, mutações, bioma, upgrades, missões, índice

local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local RunService         = game:GetService("RunService")
local DataStoreService   = game:GetService("DataStoreService")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local DataStore  = DataStoreService:GetDataStore("BrainrotAuraV4")

-- =====================================================
--  REMOTES
-- =====================================================
local RemoteFolder = Instance.new("Folder")
RemoteFolder.Name = "Remotes"
RemoteFolder.Parent = ReplicatedStorage

local function makeRE(name)
    local re = Instance.new("RemoteEvent")
    re.Name = name; re.Parent = RemoteFolder
    return re
end

local StealEvent        = makeRE("StealBrainrot")
local UpdateAuraRE      = makeRE("UpdateAura")
local NotifyRE          = makeRE("Notify")
local RebirthEvent      = makeRE("Rebirth")
local IndexUpdateRE     = makeRE("IndexUpdate")
local GlobalAnnounceRE  = makeRE("GlobalAnnounce")
local BuyUpgradeEvent   = makeRE("BuyUpgrade")
local ClaimMissionEvent = makeRE("ClaimMission")
local MissionUpdateRE   = makeRE("MissionUpdate")

-- =====================================================
--  FOLDER DE BRAINROTS
-- =====================================================
local BrainrotsFolder = Instance.new("Folder")
BrainrotsFolder.Name = "Brainrots"
BrainrotsFolder.Parent = workspace

local BaseOccupied     = {}
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
        upgrades    = { stealRange=0, walkSpeed=0, auraBonus=0 },
        missionData = nil,
    }
end

-- =====================================================
--  HELPERS DE AURA / REBIRTH
-- =====================================================
local function getAuraCap(rb)
    return math.floor(GameConfig.BASE_AURA_CAP * (GameConfig.AURA_CAP_MULTIPLIER ^ rb))
end

local function getRebirthCost(rb)
    return math.floor(getAuraCap(rb) * GameConfig.REBIRTH_COST_FRACTION)
end

local function getAuraMultiplier(rb)
    return GameConfig.AURA_GAIN_MULTIPLIER ^ rb
end

local function formatBig(n)
    if n >= 1e12 then return string.format("%.1fT", n/1e12) end
    if n >= 1e9  then return string.format("%.1fB", n/1e9)  end
    if n >= 1e6  then return string.format("%.1fM", n/1e6)  end
    if n >= 1000 then return string.format("%.1fK", n/1000) end
    return tostring(math.floor(n))
end

-- =====================================================
--  HELPERS DE UPGRADES
-- =====================================================
local function getUpgLevel(data, id)
    return (data.upgrades and data.upgrades[id]) or 0
end

local function getStealRange(data)
    local level = getUpgLevel(data, "stealRange")
    if level == 0 then return GameConfig.STEAL_RANGE end
    for _, upg in ipairs(GameConfig.UPGRADES) do
        if upg.id == "stealRange" then
            return upg.values[math.min(level, upg.maxLevel)]
        end
    end
    return GameConfig.STEAL_RANGE
end

local function getAuraBonusMult(data)
    local level = getUpgLevel(data, "auraBonus")
    if level == 0 then return 1.0 end
    for _, upg in ipairs(GameConfig.UPGRADES) do
        if upg.id == "auraBonus" then
            return upg.values[math.min(level, upg.maxLevel)]
        end
    end
    return 1.0
end

local function getWalkSpeed(data)
    local level = getUpgLevel(data, "walkSpeed")
    if level == 0 then return 16 end
    for _, upg in ipairs(GameConfig.UPGRADES) do
        if upg.id == "walkSpeed" then
            return upg.values[math.min(level, upg.maxLevel)]
        end
    end
    return 16
end

local function applyUpgradesToPlayer(player, data)
    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = getWalkSpeed(data) end
end

-- =====================================================
--  HELPERS DE MISSÕES
-- =====================================================
local function getMissionDay()
    return math.floor(os.time() / 86400)
end

local function pickDailyMissions()
    local pool = {}
    for i = 1, #GameConfig.DAILY_MISSIONS do
        table.insert(pool, GameConfig.DAILY_MISSIONS[i].id)
    end
    for i = #pool, 2, -1 do
        local j = math.random(1, i)
        pool[i], pool[j] = pool[j], pool[i]
    end
    return { pool[1], pool[2], pool[3] }
end

local function refreshMissions(data)
    local today = getMissionDay()
    if not data.missionData or data.missionData.day ~= today then
        data.missionData = {
            day      = today,
            active   = pickDailyMissions(),
            progress = {},
            claimed  = {},
        }
    end
end

local function advanceMission(data, mType, extra)
    local md = data.missionData
    if not md then return false end
    local changed = false
    for _, mId in ipairs(md.active) do
        if not md.claimed[mId] then
            for _, mission in ipairs(GameConfig.DAILY_MISSIONS) do
                if mission.id == mId then
                    local prog = md.progress[mId] or 0
                    if prog < mission.target then
                        local advance = false
                        if mission.type == "steal" and mType == "steal" then
                            advance = true
                        elseif mission.type == "rarityMin" and mType == "steal" then
                            local rank = GameConfig.RARITY_RANK[extra.rarity] or 0
                            if rank >= mission.rarityMin then advance = true end
                        elseif mission.type == "mutation" and mType == "steal" then
                            if extra.mutation == mission.mutation then advance = true end
                        elseif mission.type == "rebirth" and mType == "rebirth" then
                            advance = true
                        end
                        if advance then
                            md.progress[mId] = prog + 1
                            changed = true
                        end
                    end
                end
            end
        end
    end
    return changed
end

-- =====================================================
--  BUILD UPDATE PAYLOAD
-- =====================================================
local function buildUpdatePayload(data)
    local rb = data.rebirths
    return {
        aura        = data.aura,
        auraCap     = getAuraCap(rb),
        rebirths    = rb,
        multiplier  = getAuraMultiplier(rb),
        rebirthCost = getRebirthCost(rb),
        totalStolen = data.totalStolen or 0,
        upgrades    = data.upgrades or {},
    }
end

-- =====================================================
--  DATASTORE
-- =====================================================
local function loadData(player)
    local ok, saved = pcall(function()
        return DataStore:GetAsync("P_" .. player.UserId)
    end)
    local data = (ok and saved) and saved or defaultData()
    if not data.index    then data.index    = { brainrots={}, mutations={} } end
    if not data.upgrades then data.upgrades = { stealRange=0, walkSpeed=0, auraBonus=0 } end
    refreshMissions(data)
    PlayerData[player.UserId] = data
    UpdateAuraRE:FireClient(player, buildUpdatePayload(data))
    IndexUpdateRE:FireClient(player, data.index)
    MissionUpdateRE:FireClient(player, data.missionData)
end

local function saveData(player)
    local data = PlayerData[player.UserId]
    if not data then return end
    pcall(function() DataStore:SetAsync("P_" .. player.UserId, data) end)
end

local function setupLeaderstats(player)
    local ls = Instance.new("Folder")
    ls.Name = "leaderstats"; ls.Parent = player

    local auraVal = Instance.new("NumberValue")
    auraVal.Name = "Aura"; auraVal.Value = 0; auraVal.Parent = ls

    local rbVal = Instance.new("NumberValue")
    rbVal.Name = "Rebirths"; rbVal.Value = 0; rbVal.Parent = ls
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
--  SORTEIO DE BRAINROT (com bioma)
-- =====================================================
-- Bases internas (9-12) são "Zona Épica": Épico+ tem peso dobrado
local function pickBrainrotType(isInnerBase)
    local weights = {}
    local total   = 0
    for rarity, w in pairs(GameConfig.RARITY_WEIGHTS) do
        local rank     = GameConfig.RARITY_RANK[rarity] or 1
        local adjusted = (isInnerBase and rank >= 4) and (w * 2) or w
        weights[rarity] = adjusted
        total = total + adjusted
    end

    local roll   = math.random(1, total)
    local acc    = 0
    local chosen = "Comum"
    for rarity, w in pairs(weights) do
        acc = acc + w
        if roll <= acc then chosen = rarity; break end
    end

    local pool = {}
    for _, bt in ipairs(GameConfig.BRAINROT_TYPES) do
        if bt.rarity == chosen then table.insert(pool, bt) end
    end
    if #pool == 0 then return GameConfig.BRAINROT_TYPES[1] end
    return pool[math.random(1, #pool)]
end

-- =====================================================
--  SPAWN DE BRAINROT
-- =====================================================
local RARE_ANNOUNCE_RANK = 4  -- Épico ou melhor

local function getFreeBases()
    local free = {}
    for i = 1, #GameConfig.BASE_POSITIONS do
        if not BaseOccupied[i] then table.insert(free, i) end
    end
    return free
end

local function spawnBrainrot()
    local freeBases = getFreeBases()
    if #freeBases == 0 then return end

    globalSpawnCount = globalSpawnCount + 1
    local isLuaDeSangue = (globalSpawnCount % GameConfig.LUA_DE_SANGUE_INTERVAL == 0)

    local baseIdx  = freeBases[math.random(1, #freeBases)]
    local isInner  = (baseIdx > 8)
    local basePos  = GameConfig.BASE_POSITIONS[baseIdx]
    local bt       = pickBrainrotType(isInner)
    local mutation = pickMutation(isLuaDeSangue)

    local rarColor = GameConfig.RARITY_COLORS[bt.rarity]
    local spawnY   = basePos.Y + 4

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

    local bb = Instance.new("BillboardGui")
    bb.Size        = UDim2.new(0, 240, 0, isLuaDeSangue and 100 or 80)
    bb.StudsOffset = Vector3.new(0, 4, 0)
    bb.AlwaysOnTop = false
    bb.Parent      = part

    local function addLabel(yPos, height, text, color, bold)
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
    end

    local nameText = isLuaDeSangue and ("🌑 " .. bt.name .. " 🌑") or bt.name
    addLabel(0,    0.38, nameText, Color3.fromRGB(255,255,255), true)
    addLabel(0.38, 0.30, "[ " .. bt.rarity .. " ]", rarColor, false)
    local mutText = isLuaDeSangue
        and "✦ LUA DE SANGUE ×20 ✦"
        or  ("✦ " .. mutation.name .. "  ×" .. tostring(mutation.multiplier))
    addLabel(0.68, 0.32, mutText, mutation.color, true)

    local meta = Instance.new("Folder")
    meta.Name = "Meta"; meta.Parent = part

    local function addVal(cls, name, val)
        local v = Instance.new(cls); v.Name = name; v.Value = val; v.Parent = meta
    end
    addVal("StringValue", "BrainrotName",  bt.name)
    addVal("StringValue", "Rarity",        bt.rarity)
    addVal("IntValue",    "AuraValue",     bt.baseAura)
    addVal("StringValue", "MutationName",  mutation.name)
    addVal("IntValue",    "MutationMult",  mutation.multiplier)
    addVal("IntValue",    "BaseIndex",     baseIdx)

    BaseOccupied[baseIdx] = part

    local basePart = workspace:FindFirstChild("Base_" .. baseIdx)
    if basePart then
        local ind = basePart:FindFirstChild("Indicator")
        if ind then ind.Color = isLuaDeSangue and Color3.fromRGB(255, 0, 0) or rarColor end
    end

    -- Animação de flutuação
    local baseY = spawnY
    local t     = 0
    local conn
    conn = RunService.Heartbeat:Connect(function(dt)
        t = t + dt
        if not part or not part.Parent then conn:Disconnect(); return end
        part.CFrame = CFrame.new(basePos.X, baseY + math.sin(t * 1.8) * 0.7, basePos.Z)
                    * CFrame.Angles(0, t * 0.9, 0)
    end)

    -- Anúncios globais
    if isLuaDeSangue then
        local baseName = GameConfig.BASE_NAMES[baseIdx] or ("Base " .. baseIdx)
        GlobalAnnounceRE:FireAllClients(
            string.format("🌑 LUA DE SANGUE em %s!  [%s]  ×20 Aura!", baseName, bt.rarity),
            Color3.fromRGB(220, 0, 0)
        )
    else
        local rank = GameConfig.RARITY_RANK[bt.rarity] or 0
        if rank >= RARE_ANNOUNCE_RANK then
            local baseName = GameConfig.BASE_NAMES[baseIdx] or ("Base " .. baseIdx)
            GlobalAnnounceRE:FireAllClients(
                string.format("✦ %s [%s] em %s!", bt.name, bt.rarity, baseName),
                rarColor
            )
        end
    end

    -- Auto-despawn
    task.delay(GameConfig.BRAINROT_LIFETIME, function()
        if part and part.Parent then
            conn:Disconnect()
            BaseOccupied[baseIdx] = nil
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
    if dist > getStealRange(data) + 4 then
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
    local bonusMult   = getAuraBonusMult(data)
    local totalGain   = math.floor(baseAura * mutMult * rebirthMult * bonusMult)
    local cap         = getAuraCap(data.rebirths)
    local newAura     = math.min(data.aura + totalGain, cap)
    local actual      = newAura - data.aura

    if actual <= 0 then
        NotifyRE:FireClient(player, "Aura no limite! Faca rebirth para aumentar o cap.", Color3.fromRGB(255, 200, 0))
        return
    end

    data.aura        = newAura
    data.totalStolen = (data.totalStolen or 0) + 1

    -- Atualiza index
    local idx = data.index
    if not idx.brainrots[brainrotName] then
        idx.brainrots[brainrotName] = { count = 0, bestMutation = "Básico" }
    end
    idx.brainrots[brainrotName].count = idx.brainrots[brainrotName].count + 1
    local prevBestMult = 1
    for _, m in ipairs(GameConfig.MUTATIONS) do
        if m.name == idx.brainrots[brainrotName].bestMutation then prevBestMult = m.multiplier; break end
    end
    if mutMult > prevBestMult then idx.brainrots[brainrotName].bestMutation = mutName end
    idx.mutations[mutName] = (idx.mutations[mutName] or 0) + 1

    -- Avança missões
    local missionChanged = advanceMission(data, "steal", { rarity=rarity, mutation=mutName })

    -- Remove brainrot
    if baseIdx > 0 then
        BaseOccupied[baseIdx] = nil
        local bp = workspace:FindFirstChild("Base_" .. baseIdx)
        if bp then
            local ind = bp:FindFirstChild("Indicator")
            if ind then ind.Color = Color3.fromRGB(60, 60, 80) end
        end
    end
    brainrotPart:Destroy()

    local rarColor = GameConfig.RARITY_COLORS[rarity] or Color3.fromRGB(255,255,255)
    local mutColor = Color3.fromRGB(255,255,255)
    for _, m in ipairs(GameConfig.MUTATIONS) do
        if m.name == mutName then mutColor = m.color; break end
    end

    local mutLine = (mutName ~= "Básico") and ("  [" .. mutName .. " ×" .. mutMult .. "]") or ""
    NotifyRE:FireClient(player,
        string.format("+%s Aura  •  %s  [%s]%s", formatBig(actual), brainrotName, rarity, mutLine),
        mutName == "Lua de Sangue" and Color3.fromRGB(220,0,0) or rarColor)

    UpdateAuraRE:FireClient(player, buildUpdatePayload(data))
    IndexUpdateRE:FireClient(player, data.index)
    if missionChanged then MissionUpdateRE:FireClient(player, data.missionData) end
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
            string.format("Precisa de %s aura! (voce tem %s)", formatBig(cost), formatBig(data.aura)),
            Color3.fromRGB(255, 80, 80))
        return
    end

    data.rebirths = data.rebirths + 1
    data.aura     = 0

    local missionChanged = advanceMission(data, "rebirth", {})
    local newCap  = getAuraCap(data.rebirths)
    local newMult = getAuraMultiplier(data.rebirths)

    NotifyRE:FireClient(player,
        string.format("RENASCIMENTO #%d!  Cap: %s  |  Mult: x%s",
            data.rebirths, formatBig(newCap), formatBig(newMult)),
        Color3.fromRGB(255, 215, 0))

    UpdateAuraRE:FireClient(player, buildUpdatePayload(data))
    if missionChanged then MissionUpdateRE:FireClient(player, data.missionData) end
    updateLeaderstats(player)
    applyUpgradesToPlayer(player, data)
    saveData(player)
end)

-- =====================================================
--  EVENTO: COMPRAR UPGRADE
-- =====================================================
BuyUpgradeEvent.OnServerEvent:Connect(function(player, upgradeId)
    local data = PlayerData[player.UserId]
    if not data then return end

    local upg = nil
    for _, u in ipairs(GameConfig.UPGRADES) do
        if u.id == upgradeId then upg = u; break end
    end
    if not upg then return end

    if not data.upgrades then data.upgrades = {} end
    local currentLevel = data.upgrades[upgradeId] or 0
    if currentLevel >= upg.maxLevel then
        NotifyRE:FireClient(player, upg.name .. " já está no nível máximo!", Color3.fromRGB(255, 200, 0))
        return
    end

    local cost = upg.costs[currentLevel + 1]
    if data.aura < cost then
        NotifyRE:FireClient(player,
            string.format("Aura insuficiente! Precisa de %s", formatBig(cost)),
            Color3.fromRGB(255, 80, 80))
        return
    end

    data.aura = data.aura - cost
    data.upgrades[upgradeId] = currentLevel + 1

    NotifyRE:FireClient(player,
        string.format("%s %s → Nível %d!  (-%s aura)", upg.icon, upg.name, currentLevel + 1, formatBig(cost)),
        Color3.fromRGB(100, 255, 100))

    UpdateAuraRE:FireClient(player, buildUpdatePayload(data))
    updateLeaderstats(player)
    applyUpgradesToPlayer(player, data)
end)

-- =====================================================
--  EVENTO: CLAIM MISSÃO
-- =====================================================
ClaimMissionEvent.OnServerEvent:Connect(function(player, missionId)
    local data = PlayerData[player.UserId]
    if not data or not data.missionData then return end
    local md = data.missionData

    local isActive = false
    for _, id in ipairs(md.active) do
        if id == missionId then isActive = true; break end
    end
    if not isActive or md.claimed[missionId] then return end

    local mission = nil
    for _, m in ipairs(GameConfig.DAILY_MISSIONS) do
        if m.id == missionId then mission = m; break end
    end
    if not mission then return end

    local progress = md.progress[missionId] or 0
    if progress < mission.target then
        NotifyRE:FireClient(player, "Missão ainda não completa!", Color3.fromRGB(255, 80, 80))
        return
    end

    md.claimed[missionId] = true
    local cap = getAuraCap(data.rebirths)
    data.aura = math.min(data.aura + mission.reward, cap)

    NotifyRE:FireClient(player,
        string.format("✦ MISSÃO: %s! +%s aura!", mission.name, formatBig(mission.reward)),
        Color3.fromRGB(255, 215, 0))

    UpdateAuraRE:FireClient(player, buildUpdatePayload(data))
    MissionUpdateRE:FireClient(player, md)
    updateLeaderstats(player)
end)

-- =====================================================
--  JOGADORES
-- =====================================================
Players.PlayerAdded:Connect(function(player)
    setupLeaderstats(player)
    loadData(player)
    updateLeaderstats(player)
    player.CharacterAdded:Connect(function()
        task.wait(1)
        local data = PlayerData[player.UserId]
        if data then applyUpgradesToPlayer(player, data) end
    end)
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
    for _ = 1, #GameConfig.BASE_POSITIONS do
        spawnBrainrot()
        task.wait(0.15)
    end
    while true do
        task.wait(GameConfig.SPAWN_INTERVAL)
        spawnBrainrot()
    end
end)

print("[BrainrotRoubo] Servidor iniciado! Upgrades, Missões e Bioma ativos.")
