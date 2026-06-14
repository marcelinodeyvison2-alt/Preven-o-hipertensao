-- DataManager.lua (ModuleScript em ServerScriptService/Modules)
-- Gerencia saves/loads de dados dos jogadores via DataStore

local DataManager = {}

local DataStoreService = game:GetService("DataStoreService")
local GameConfig       = require(game:GetService("ReplicatedStorage"):WaitForChild("GameConfig"))

local STORE = DataStoreService:GetDataStore(GameConfig.SETTINGS.DATASTORE_KEY)

-- ============================================================
-- ESTRUTURA PADRAO DE DADOS DO JOGADOR
-- ============================================================
local function defaultData()
    return {
        coins       = 0,
        gems        = 0,
        totalSpins  = 0,
        inventory   = {},       -- { { name="Fire", rarity="Uncommon", count=3 }, ... }
        activeAura  = nil,      -- nome da aura ativa
        upgrades    = {},       -- { luck1 = 2, speed1 = 1, ... }
        rarestAura  = nil,      -- nome da aura mais rara obtida
        rarestOrder = 0,        -- ordem numerica da raridade mais rara
        totalCoins  = 0,        -- total historico de coins acumulados
    }
end

-- Cache em memoria para evitar excesso de requests
local playerCache = {}

-- ============================================================
-- LOAD: carrega ou inicializa dados do jogador
-- ============================================================
function DataManager.Load(player)
    local key = "player_" .. player.UserId
    local success, data = pcall(function()
        return STORE:GetAsync(key)
    end)

    if success and data then
        -- Merge com defaults para garantir campos novos
        local defaults = defaultData()
        for k, v in pairs(defaults) do
            if data[k] == nil then
                data[k] = v
            end
        end
        playerCache[player.UserId] = data
    else
        playerCache[player.UserId] = defaultData()
    end

    return playerCache[player.UserId]
end

-- ============================================================
-- SAVE: salva dados do jogador no DataStore
-- ============================================================
function DataManager.Save(player)
    local data = playerCache[player.UserId]
    if not data then return end

    local key = "player_" .. player.UserId
    local success, err = pcall(function()
        STORE:SetAsync(key, data)
    end)

    if not success then
        warn("[DataManager] Falha ao salvar dados de " .. player.Name .. ": " .. tostring(err))
    end
end

-- ============================================================
-- GET: retorna dados em cache do jogador
-- ============================================================
function DataManager.Get(player)
    return playerCache[player.UserId]
end

-- ============================================================
-- CLEAN: remove dados do cache ao sair
-- ============================================================
function DataManager.Clean(player)
    playerCache[player.UserId] = nil
end

-- ============================================================
-- ADD AURA: adiciona aura ao inventario do jogador
-- ============================================================
function DataManager.AddAura(player, auraName)
    local data = DataManager.Get(player)
    if not data then return end

    local aura = GameConfig.GetAuraByName(auraName)
    if not aura then return end

    -- Verifica se ja tem no inventario
    local found = false
    for _, item in ipairs(data.inventory) do
        if item.name == auraName then
            item.count = item.count + 1
            found = true
            break
        end
    end

    if not found then
        table.insert(data.inventory, {
            name   = auraName,
            rarity = aura.rarity,
            count  = 1,
        })
    end

    -- Atualiza aura mais rara
    local rarityOrder = GameConfig.RARITY_ORDER[aura.rarity] or 0
    if rarityOrder > (data.rarestOrder or 0) then
        data.rarestAura  = auraName
        data.rarestOrder = rarityOrder
    end
end

-- ============================================================
-- ADD COINS / GEMS
-- ============================================================
function DataManager.AddCoins(player, amount)
    local data = DataManager.Get(player)
    if not data then return end
    data.coins      = data.coins + amount
    data.totalCoins = data.totalCoins + amount
end

function DataManager.AddGems(player, amount)
    local data = DataManager.Get(player)
    if not data then return end
    data.gems = data.gems + amount
end

function DataManager.SpendCoins(player, amount)
    local data = DataManager.Get(player)
    if not data then return false end
    if data.coins < amount then return false end
    data.coins = data.coins - amount
    return true
end

function DataManager.SpendGems(player, amount)
    local data = DataManager.Get(player)
    if not data then return false end
    if data.gems < amount then return false end
    data.gems = data.gems - amount
    return true
end

-- ============================================================
-- SET ACTIVE AURA
-- ============================================================
function DataManager.SetActiveAura(player, auraName)
    local data = DataManager.Get(player)
    if not data then return false end

    -- Verifica se o jogador tem essa aura
    if auraName ~= nil then
        local has = false
        for _, item in ipairs(data.inventory) do
            if item.name == auraName then
                has = true
                break
            end
        end
        if not has then return false end
    end

    data.activeAura = auraName
    return true
end

-- ============================================================
-- BUY UPGRADE
-- ============================================================
function DataManager.BuyUpgrade(player, upgradeId)
    local data = DataManager.Get(player)
    if not data then return false, "Dados nao encontrados" end

    -- Encontra definicao do upgrade
    local upgradeDef = nil
    for _, u in ipairs(GameConfig.UPGRADES) do
        if u.id == upgradeId then
            upgradeDef = u
            break
        end
    end
    if not upgradeDef then return false, "Upgrade nao encontrado" end

    local currentLevel = data.upgrades[upgradeId] or 0

    if currentLevel >= upgradeDef.maxLevel then
        return false, "Upgrade ja no nivel maximo!"
    end

    -- Calcula custo para o proximo nivel
    local multiplier = upgradeDef.costMultiplier ^ currentLevel
    local coinCost   = math.floor(upgradeDef.baseCost.coins * multiplier)
    local gemCost    = math.floor(upgradeDef.baseCost.gems  * multiplier)

    if data.coins < coinCost then
        return false, "Coins insuficientes! Precisa de " .. coinCost
    end
    if data.gems < gemCost then
        return false, "Gems insuficientes! Precisa de " .. gemCost
    end

    -- Debita e aplica
    data.coins = data.coins - coinCost
    data.gems  = data.gems  - gemCost
    data.upgrades[upgradeId] = currentLevel + 1

    return true, "Upgrade comprado! Nivel " .. (currentLevel + 1)
end

-- ============================================================
-- INCREMENT SPINS
-- ============================================================
function DataManager.IncrementSpins(player)
    local data = DataManager.Get(player)
    if not data then return end
    data.totalSpins = data.totalSpins + 1
end

-- ============================================================
-- LEADERBOARD: retorna dados para ranking
-- ============================================================
function DataManager.GetLeaderboardData(player)
    local data = DataManager.Get(player)
    if not data then return nil end
    return {
        totalAuras = #data.inventory,
        rarestAura = data.rarestAura or "None",
        totalCoins = data.totalCoins,
        upgrades   = (function()
            local count = 0
            for _, v in pairs(data.upgrades) do count = count + v end
            return count
        end)(),
    }
end

return DataManager
