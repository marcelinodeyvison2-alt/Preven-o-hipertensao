-- MainServer.server.lua (Script em ServerScriptService)
-- Script principal do servidor - orquestra todos os sistemas

local Players          = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local RunService       = game:GetService("RunService")

-- Aguarda modulos
local Modules = script.Parent:WaitForChild("Modules")
local DataManager  = require(Modules:WaitForChild("DataManager"))
local RNGSystem    = require(Modules:WaitForChild("RNGSystem"))
local AuraManager  = require(Modules:WaitForChild("AuraManager"))
local EventManager = require(Modules:WaitForChild("EventManager"))
local GameConfig   = require(ReplicatedStorage:WaitForChild("GameConfig"))

-- ============================================================
-- REMOTE EVENTS SETUP
-- ============================================================
local remotes = ReplicatedStorage:WaitForChild("RemoteEvents")

local RE_Spin           = remotes:WaitForChild("Spin")           -- client -> server: giro
local RE_SpinResult     = remotes:WaitForChild("SpinResult")     -- server -> client: resultado
local RE_BuyUpgrade     = remotes:WaitForChild("BuyUpgrade")     -- client -> server: comprar upgrade
local RE_SetActiveAura  = remotes:WaitForChild("SetActiveAura")  -- client -> server: ativar aura
local RE_SyncData       = remotes:WaitForChild("SyncData")       -- server -> client: sincronizar dados
local RE_EventUpdate    = remotes:WaitForChild("EventUpdate")    -- server -> client: atualizar evento
local RE_MysteryBox     = remotes:WaitForChild("MysteryBox")     -- server -> client: mystery box spawnou
local RE_LeaderboardUpdate = remotes:WaitForChild("LeaderboardUpdate")

-- Cooldowns de giro por jogador
local spinCooldowns = {}

-- ============================================================
-- LEADERBOARD: Ordered DataStore para ranking global
-- ============================================================
local leaderboardStores = {
    totalAuras = DataStoreService:GetOrderedDataStore("LB_TotalAuras"),
    totalCoins = DataStoreService:GetOrderedDataStore("LB_TotalCoins"),
}

local function updateLeaderboard(player)
    local data = DataManager.GetLeaderboardData(player)
    if not data then return end

    pcall(function()
        leaderboardStores.totalAuras:SetAsync(tostring(player.UserId), data.totalAuras)
        leaderboardStores.totalCoins:SetAsync(tostring(player.UserId), data.totalCoins)
    end)
end

local function broadcastLeaderboard()
    local function getTop(store)
        local pages
        local success = pcall(function()
            pages = store:GetSortedAsync(false, GameConfig.SETTINGS.LEADERBOARD_SIZE)
        end)
        if not success then return {} end

        local topData = {}
        local ok, page = pcall(function() return pages:GetCurrentPage() end)
        if not ok then return {} end

        for rank, entry in ipairs(page) do
            local playerName = "Unknown"
            local ok2, playerInfo = pcall(function()
                return Players:GetNameFromUserIdAsync(tonumber(entry.key))
            end)
            if ok2 then playerName = playerInfo end

            table.insert(topData, {
                rank  = rank,
                name  = playerName,
                score = entry.value,
            })
        end
        return topData
    end

    local lbData = {
        totalAuras = getTop(leaderboardStores.totalAuras),
        totalCoins = getTop(leaderboardStores.totalCoins),
    }

    RE_LeaderboardUpdate:FireAllClients(lbData)
end

-- ============================================================
-- SYNC: envia dados atuais do jogador para o client
-- ============================================================
local function syncPlayer(player)
    local data = DataManager.Get(player)
    if not data then return end
    RE_SyncData:FireClient(player, data)
end

-- ============================================================
-- JOGADOR ENTROU
-- ============================================================
Players.PlayerAdded:Connect(function(player)
    -- Carrega dados
    local data = DataManager.Load(player)

    -- Conecta respawn da aura
    AuraManager.ConnectRespawn(player, DataManager.Get)

    -- Aguarda personagem e aplica aura ativa
    if player.Character then
        task.wait(0.5)
        if data.activeAura then
            AuraManager.ApplyPlayerAura(player, data.activeAura)
        end
    end

    -- Inicializa cooldown
    spinCooldowns[player.UserId] = 0

    -- Envia dados iniciais ao cliente
    task.wait(1)
    syncPlayer(player)

    -- Envia estado do evento ativo (se houver)
    local ev = EventManager.GetActiveEvent()
    if ev then
        RE_EventUpdate:FireClient(player, "started", ev.def, EventManager.GetTimeRemaining())
    end

    print("[Server] " .. player.Name .. " entrou. Moedas: " .. data.coins)
end)

-- ============================================================
-- JOGADOR SAIU
-- ============================================================
Players.PlayerRemoving:Connect(function(player)
    updateLeaderboard(player)
    DataManager.Save(player)
    DataManager.Clean(player)
    spinCooldowns[player.UserId] = nil
    print("[Server] Dados de " .. player.Name .. " salvos.")
end)

-- ============================================================
-- REMOTE: SPIN (cliente pede um giro)
-- ============================================================
RE_Spin.OnServerEvent:Connect(function(player, rollTypeId)
    local userId = player.UserId
    local now    = tick()

    -- Verifica cooldown
    local data = DataManager.Get(player)
    if not data then return end

    local cooldown = RNGSystem.GetSpinCooldown(data)
    if spinCooldowns[userId] and now - spinCooldowns[userId] < cooldown then
        RE_SpinResult:FireClient(player, nil, "Cooldown! Aguarde.")
        return
    end

    -- Verifica custo da roleta
    local rollType = nil
    for _, rt in ipairs(GameConfig.ROLL_TYPES) do
        if rt.id == rollTypeId then
            rollType = rt
            break
        end
    end
    rollType = rollType or GameConfig.ROLL_TYPES[1]

    if rollType.cost.coins > 0 and data.coins < rollType.cost.coins then
        RE_SpinResult:FireClient(player, nil, "Coins insuficientes!")
        return
    end
    if rollType.cost.gems > 0 and data.gems < rollType.cost.gems then
        RE_SpinResult:FireClient(player, nil, "Gems insuficientes!")
        return
    end

    -- Debita custo
    if rollType.cost.coins > 0 then DataManager.SpendCoins(player, rollType.cost.coins) end
    if rollType.cost.gems  > 0 then DataManager.SpendGems(player, rollType.cost.gems)   end

    -- Atualiza cooldown
    spinCooldowns[userId] = now

    -- Incrementa spins
    DataManager.IncrementSpins(player)

    -- Calcula multiplicadores de evento
    local luckMult = EventManager.GetLuckMultiplier()
    local coinMult = EventManager.GetCoinMultiplier()

    -- Executa RNG
    local selectedAura = RNGSystem.Spin(data, rollTypeId, luckMult)

    -- Calcula recompensas
    local coins, gems = RNGSystem.CalculateRewards(selectedAura, data, coinMult)

    -- Aplica recompensas
    DataManager.AddAura(player, selectedAura.name)
    DataManager.AddCoins(player, coins)
    if gems > 0 then DataManager.AddGems(player, gems) end

    -- Efeito visual de reveal no personagem
    task.spawn(function()
        task.wait(GameConfig.SETTINGS.SPIN_ANIMATION_TIME)
        AuraManager.PlayRevealEffect(player, selectedAura)
    end)

    -- Monta sequencia de animacao de roleta
    local rollSequence = RNGSystem.GenerateRollSequence(selectedAura, 20)

    -- Envia resultado ao cliente
    RE_SpinResult:FireClient(player, {
        aura        = selectedAura,
        coins       = coins,
        gems        = gems,
        rollSequence = rollSequence,
    })

    -- Sincroniza dados atualizados
    syncPlayer(player)

    -- Atualiza leaderboard
    task.spawn(function()
        task.wait(1)
        updateLeaderboard(player)
    end)
end)

-- ============================================================
-- REMOTE: BUY UPGRADE
-- ============================================================
RE_BuyUpgrade.OnServerEvent:Connect(function(player, upgradeId)
    local success, msg = DataManager.BuyUpgrade(player, upgradeId)
    if success then
        syncPlayer(player)
        -- Notifica o cliente sobre o sucesso
        RE_SpinResult:FireClient(player, nil, nil, { upgradeSuccess = true, msg = msg })
    else
        RE_SpinResult:FireClient(player, nil, nil, { upgradeSuccess = false, msg = msg })
    end
end)

-- ============================================================
-- REMOTE: SET ACTIVE AURA
-- ============================================================
RE_SetActiveAura.OnServerEvent:Connect(function(player, auraName)
    local ok = DataManager.SetActiveAura(player, auraName)
    if ok then
        AuraManager.ApplyPlayerAura(player, auraName)
        syncPlayer(player)
    end
end)

-- ============================================================
-- EVENTS: callbacks quando evento muda
-- ============================================================
EventManager.OnEventChange(function(eventType, eventData)
    if eventType == "started" then
        local remaining = EventManager.GetTimeRemaining()
        RE_EventUpdate:FireAllClients("started", eventData.def, remaining)
        print("[Server] Evento iniciado: " .. eventData.def.name)
    elseif eventType == "ended" then
        RE_EventUpdate:FireAllClients("ended", nil, 0)
        print("[Server] Evento encerrado.")
    end
end)

-- ============================================================
-- LOOP PRINCIPAL (a cada segundo)
-- ============================================================
local lastLeaderboardBroadcast = 0
local lastSave = 0

RunService.Heartbeat:Connect(function()
    local now = tick()

    -- Atualiza sistema de eventos
    EventManager.Update()

    -- Salva dados a cada 60 segundos
    if now - lastSave >= 60 then
        lastSave = now
        for _, player in ipairs(Players:GetPlayers()) do
            task.spawn(DataManager.Save, player)
        end
    end

    -- Broadcast do leaderboard a cada 30 segundos
    if now - lastLeaderboardBroadcast >= 30 then
        lastLeaderboardBroadcast = now
        task.spawn(broadcastLeaderboard)
    end
end)

-- ============================================================
-- INICIALIZACAO
-- ============================================================
EventManager.Initialize()

-- Setup do Mystery Box (aparece no workspace a cada X minutos)
local function spawnMysteryBox()
    while true do
        task.wait(math.random(300, 900))

        -- Escolhe posicao aleatoria no mapa
        local x = math.random(-50, 50)
        local z = math.random(-50, 50)
        local pos = Vector3.new(x, 3, z)

        -- Cria a caixa no workspace
        local box = Instance.new("Part")
        box.Name         = "MysteryBox"
        box.Size         = Vector3.new(3, 3, 3)
        box.Position     = pos
        box.Anchored     = true
        box.CanCollide   = true
        box.BrickColor   = BrickColor.new("Cyan")
        box.Material     = Enum.Material.Neon
        box.Shape        = Enum.PartType.Block
        box.Parent       = workspace

        -- Brilho na caixa
        local light = Instance.new("PointLight")
        light.Color      = Color3.fromRGB(0, 255, 200)
        light.Brightness = 5
        light.Range      = 20
        light.Parent     = box

        -- Faz a caixa girar
        local angle = 0
        local connection
        connection = RunService.Heartbeat:Connect(function(dt)
            angle = angle + dt * 90
            box.CFrame = CFrame.new(pos) * CFrame.Angles(0, math.rad(angle), 0)
        end)

        -- Notifica clientes
        RE_MysteryBox:FireAllClients("spawned", pos)
        EventManager.TriggerManual("mystery_box")

        -- Detecta toque do jogador
        local touched = false
        box.Touched:Connect(function(part)
            if touched then return end
            local player = Players:GetPlayerFromCharacter(part.Parent)
            if not player then return end
            touched = true

            -- Da recompensa: aura rara aleatorio
            local epicPool = GameConfig.GetAurasByMinRarity("Rare")
            local randomAura = epicPool[math.random(1, #epicPool)]

            DataManager.AddAura(player, randomAura.name)
            DataManager.AddCoins(player, randomAura.coins * 2)
            if randomAura.gems > 0 then DataManager.AddGems(player, randomAura.gems) end

            AuraManager.PlayRevealEffect(player, randomAura)

            RE_SpinResult:FireClient(player, {
                aura   = randomAura,
                coins  = randomAura.coins * 2,
                gems   = randomAura.gems,
                isMysteryBox = true,
            })

            syncPlayer(player)

            -- Destroi caixa
            connection:Disconnect()
            RE_MysteryBox:FireAllClients("collected", player.Name, randomAura.name)
            box:Destroy()
        end)

        -- Auto-destroi apos 60 segundos se ninguem pegar
        task.delay(60, function()
            if box and box.Parent then
                connection:Disconnect()
                box:Destroy()
                RE_MysteryBox:FireAllClients("expired")
            end
        end)
    end
end

task.spawn(spawnMysteryBox)

-- Auto-save ao fechar servidor
game:BindToClose(function()
    for _, player in ipairs(Players:GetPlayers()) do
        DataManager.Save(player)
    end
    task.wait(2)
end)

print("[Server] SOL's RNG - Aura Roller INICIADO!")
