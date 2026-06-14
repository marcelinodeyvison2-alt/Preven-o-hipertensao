-- RNGSystem.lua (ModuleScript em ServerScriptService/Modules)
-- Sistema de RNG: calcula qual aura o jogador recebe ao girar

local RNGSystem = {}

local GameConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("GameConfig"))

-- ============================================================
-- Calcula o peso total de uma lista de auras
-- quanto MENOR o chance, MAIOR o peso (mais raro = menos peso)
-- ============================================================
local function buildWeightTable(auraList, luckMultiplier)
    luckMultiplier = luckMultiplier or 1
    local weightTable = {}
    local totalWeight = 0

    for _, aura in ipairs(auraList) do
        -- Divisor reduzido pelo multiplicador de sorte
        local adjustedChance = math.max(1, aura.chance / luckMultiplier)
        -- Peso = 1000000 / chance (invertido para raros terem peso menor mas ainda aparecerem)
        local weight = math.floor(1000000 / adjustedChance)
        weight = math.max(1, weight)
        totalWeight = totalWeight + weight
        table.insert(weightTable, {
            aura   = aura,
            weight = weight,
            cumulative = totalWeight,
        })
    end

    return weightTable, totalWeight
end

-- ============================================================
-- Seleciona uma aura da tabela de pesos
-- ============================================================
local function selectFromWeightTable(weightTable, totalWeight)
    local roll = math.random(1, totalWeight)
    for _, entry in ipairs(weightTable) do
        if roll <= entry.cumulative then
            return entry.aura
        end
    end
    return weightTable[#weightTable].aura
end

-- ============================================================
-- FUNCAO PRINCIPAL: executa um giro
-- playerData: dados do jogador (upgrades, etc)
-- rollTypeId: "normal", "mystic", "godly"
-- activeEventMultiplier: multiplicador de sorte do evento ativo
-- ============================================================
function RNGSystem.Spin(playerData, rollTypeId, activeEventMultiplier)
    rollTypeId = rollTypeId or "normal"
    activeEventMultiplier = activeEventMultiplier or 1

    -- Encontra o tipo de roleta
    local rollType = nil
    for _, rt in ipairs(GameConfig.ROLL_TYPES) do
        if rt.id == rollTypeId then
            rollType = rt
            break
        end
    end
    if not rollType then rollType = GameConfig.ROLL_TYPES[1] end

    -- Calcula multiplicador de sorte total
    local luckMult = activeEventMultiplier * (rollType.luckMultiplier or 1)

    -- Aplica upgrades de sorte do jogador
    if playerData and playerData.upgrades then
        for upgradeId, upgradeLevel in pairs(playerData.upgrades) do
            for _, upgradeDef in ipairs(GameConfig.UPGRADES) do
                if upgradeDef.id == upgradeId and upgradeDef.type == "Luck" then
                    luckMult = luckMult * (1 + upgradeDef.effect * upgradeLevel)
                end
            end
        end
    end

    -- Filtra auras pelo tipo de roleta
    local auraPool
    if rollType.minRarity then
        auraPool = GameConfig.GetAurasByMinRarity(rollType.minRarity)
    else
        auraPool = GameConfig.AURAS
    end

    if #auraPool == 0 then
        auraPool = GameConfig.AURAS
    end

    -- Constroi tabela de pesos e seleciona aura
    local weightTable, totalWeight = buildWeightTable(auraPool, luckMult)
    local selectedAura = selectFromWeightTable(weightTable, totalWeight)

    return selectedAura
end

-- ============================================================
-- Gera sequencia de auras para animacao da roleta
-- Retorna lista de auras para mostrar passando na tela
-- ============================================================
function RNGSystem.GenerateRollSequence(finalAura, count)
    count = count or 20
    local sequence = {}

    -- 80% das auras da sequencia sao comuns/incomuns (para dar sensacao de roleta)
    local commonPool = GameConfig.GetAurasByMinRarity("Common")
    local uncommonAndBelow = {}
    for _, aura in ipairs(commonPool) do
        if GameConfig.RARITY_ORDER[aura.rarity] <= 2 then
            table.insert(uncommonAndBelow, aura)
        end
    end
    if #uncommonAndBelow == 0 then uncommonAndBelow = commonPool end

    for i = 1, count - 1 do
        local randomAura = uncommonAndBelow[math.random(1, #uncommonAndBelow)]
        table.insert(sequence, randomAura.name)
    end

    -- Ultima posicao e a aura final
    table.insert(sequence, finalAura.name)

    return sequence
end

-- ============================================================
-- Calcula recompensas de moedas/gemas por aura
-- ============================================================
function RNGSystem.CalculateRewards(aura, playerData, activeEventMultiplier)
    activeEventMultiplier = activeEventMultiplier or 1

    local coinMultiplier = 1
    local gemBonus = 0

    -- Aplica upgrades de multiplicador
    if playerData and playerData.upgrades then
        for upgradeId, upgradeLevel in pairs(playerData.upgrades) do
            for _, upgradeDef in ipairs(GameConfig.UPGRADES) do
                if upgradeDef.id == upgradeId then
                    if upgradeDef.type == "Multiplier" and upgradeDef.id == "multi1" then
                        coinMultiplier = coinMultiplier * (upgradeDef.effect ^ upgradeLevel)
                    elseif upgradeDef.type == "Multiplier" and upgradeDef.id == "multi2" then
                        -- Chance de gem extra
                        local chance = upgradeDef.effect * upgradeLevel
                        if math.random() < chance then
                            gemBonus = gemBonus + 1
                        end
                    end
                end
            end
        end
    end

    local coins = math.floor((aura.coins + GameConfig.SETTINGS.COIN_PER_SPIN) * coinMultiplier * activeEventMultiplier)
    local gems  = aura.gems + gemBonus

    return coins, gems
end

-- ============================================================
-- Calcula cooldown atual do jogador
-- ============================================================
function RNGSystem.GetSpinCooldown(playerData)
    local baseCooldown = GameConfig.SETTINGS.BASE_SPIN_COOLDOWN
    local reduction = 0

    if playerData and playerData.upgrades then
        for upgradeId, upgradeLevel in pairs(playerData.upgrades) do
            for _, upgradeDef in ipairs(GameConfig.UPGRADES) do
                if upgradeDef.id == upgradeId and upgradeDef.type == "Speed" and upgradeDef.id == "speed1" then
                    reduction = reduction + upgradeDef.effect * upgradeLevel
                end
            end
        end
    end

    return math.max(0.5, baseCooldown - reduction)
end

return RNGSystem
