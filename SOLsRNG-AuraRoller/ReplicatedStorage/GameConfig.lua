-- GameConfig.lua (ModuleScript em ReplicatedStorage)
-- Configuracao central do jogo SOL's RNG - Aura Roller

local GameConfig = {}

-- ============================================================
-- AURAS E RARIDADES
-- ============================================================
-- chance: 1 em X probabilidade (ex: 100 = 1/100)
-- color: cor principal da aura
-- particles: numero de particulas
-- light: intensidade da luz ambiente
-- coins: moedas ganhas ao coletar
-- gems: gemas ganhas (0 para auras comuns)

GameConfig.AURAS = {
    -- ===================== COMMON (1/10 a 1/100) =====================
    { name = "Stone",      rarity = "Common",    chance = 10,       color = Color3.fromRGB(128,128,128), particles = 10,  lightIntensity = 0,   coins = 5,    gems = 0  },
    { name = "Leaf",       rarity = "Common",    chance = 15,       color = Color3.fromRGB(76,153,0),    particles = 12,  lightIntensity = 0,   coins = 5,    gems = 0  },
    { name = "Water",      rarity = "Common",    chance = 20,       color = Color3.fromRGB(0,162,255),   particles = 14,  lightIntensity = 0,   coins = 6,    gems = 0  },
    { name = "Sand",       rarity = "Common",    chance = 25,       color = Color3.fromRGB(194,178,128), particles = 10,  lightIntensity = 0,   coins = 5,    gems = 0  },
    { name = "Wind",       rarity = "Common",    chance = 30,       color = Color3.fromRGB(200,230,255), particles = 15,  lightIntensity = 0,   coins = 6,    gems = 0  },

    -- ===================== UNCOMMON (1/100 a 1/1000) =====================
    { name = "Fire",       rarity = "Uncommon",  chance = 100,      color = Color3.fromRGB(255,80,0),    particles = 20,  lightIntensity = 0.5, coins = 15,   gems = 0  },
    { name = "Ice",        rarity = "Uncommon",  chance = 150,      color = Color3.fromRGB(150,220,255), particles = 22,  lightIntensity = 0.5, coins = 15,   gems = 0  },
    { name = "Thunder",    rarity = "Uncommon",  chance = 200,      color = Color3.fromRGB(255,255,0),   particles = 25,  lightIntensity = 0.6, coins = 18,   gems = 0  },
    { name = "Shadow",     rarity = "Uncommon",  chance = 250,      color = Color3.fromRGB(60,0,80),     particles = 20,  lightIntensity = 0.4, coins = 16,   gems = 0  },
    { name = "Nature",     rarity = "Uncommon",  chance = 300,      color = Color3.fromRGB(0,200,100),   particles = 18,  lightIntensity = 0.5, coins = 15,   gems = 0  },

    -- ===================== RARE (1/1000 a 1/10000) =====================
    { name = "Crystal",    rarity = "Rare",      chance = 1000,     color = Color3.fromRGB(0,255,200),   particles = 35,  lightIntensity = 1,   coins = 50,   gems = 1  },
    { name = "Magma",      rarity = "Rare",      chance = 1500,     color = Color3.fromRGB(255,50,0),    particles = 40,  lightIntensity = 1.2, coins = 60,   gems = 1  },
    { name = "Storm",      rarity = "Rare",      chance = 2000,     color = Color3.fromRGB(150,0,255),   particles = 45,  lightIntensity = 1.3, coins = 70,   gems = 1  },
    { name = "Aurora",     rarity = "Rare",      chance = 2500,     color = Color3.fromRGB(0,255,150),   particles = 50,  lightIntensity = 1.5, coins = 80,   gems = 2  },
    { name = "Void",       rarity = "Rare",      chance = 3000,     color = Color3.fromRGB(30,0,60),     particles = 55,  lightIntensity = 1.4, coins = 90,   gems = 2  },

    -- ===================== EPIC (1/10000 a 1/100000) =====================
    { name = "Galaxy",     rarity = "Epic",      chance = 10000,    color = Color3.fromRGB(100,0,200),   particles = 70,  lightIntensity = 2,   coins = 200,  gems = 5  },
    { name = "Plasma",     rarity = "Epic",      chance = 15000,    color = Color3.fromRGB(255,0,200),   particles = 80,  lightIntensity = 2.2, coins = 250,  gems = 5  },
    { name = "Inferno",    rarity = "Epic",      chance = 20000,    color = Color3.fromRGB(255,100,0),   particles = 90,  lightIntensity = 2.5, coins = 300,  gems = 8  },
    { name = "Cosmos",     rarity = "Epic",      chance = 25000,    color = Color3.fromRGB(50,100,255),  particles = 100, lightIntensity = 2.8, coins = 350,  gems = 8  },
    { name = "Nether",     rarity = "Epic",      chance = 30000,    color = Color3.fromRGB(200,0,0),     particles = 95,  lightIntensity = 2.6, coins = 320,  gems = 7  },

    -- ===================== LEGENDARY (1/100000 a 1/1000000) =====================
    { name = "Solar",      rarity = "Legendary", chance = 100000,   color = Color3.fromRGB(255,200,0),   particles = 150, lightIntensity = 4,   coins = 1000, gems = 25 },
    { name = "Celestial",  rarity = "Legendary", chance = 200000,   color = Color3.fromRGB(200,200,255), particles = 180, lightIntensity = 5,   coins = 1500, gems = 30 },
    { name = "Abyss",      rarity = "Legendary", chance = 300000,   color = Color3.fromRGB(0,0,60),      particles = 200, lightIntensity = 4.5, coins = 1800, gems = 35 },
    { name = "Titan",      rarity = "Legendary", chance = 500000,   color = Color3.fromRGB(255,150,0),   particles = 220, lightIntensity = 5.5, coins = 2500, gems = 50 },

    -- ===================== DIVINE (1/1000000+) =====================
    { name = "Godly",      rarity = "Divine",    chance = 1000000,  color = Color3.fromRGB(255,255,255), particles = 300, lightIntensity = 8,   coins = 5000, gems = 100 },
    { name = "Omnipotent", rarity = "Divine",    chance = 5000000,  color = Color3.fromRGB(255,215,0),   particles = 400, lightIntensity = 10,  coins = 10000,gems = 250 },
    { name = "SOL",        rarity = "Divine",    chance = 10000000, color = Color3.fromRGB(255,100,100), particles = 500, lightIntensity = 15,  coins = 25000,gems = 500 },
}

-- ============================================================
-- CORES DAS RARIDADES
-- ============================================================
GameConfig.RARITY_COLORS = {
    Common    = Color3.fromRGB(200, 200, 200),
    Uncommon  = Color3.fromRGB(0, 255, 0),
    Rare      = Color3.fromRGB(0, 100, 255),
    Epic      = Color3.fromRGB(150, 0, 255),
    Legendary = Color3.fromRGB(255, 165, 0),
    Divine    = Color3.fromRGB(255, 50, 50),
}

-- ============================================================
-- EMOJIS E LABELS DE RARIDADE
-- ============================================================
GameConfig.RARITY_LABELS = {
    Common    = "⬜ COMMON",
    Uncommon  = "🟩 UNCOMMON",
    Rare      = "🟦 RARE",
    Epic      = "🟪 EPIC",
    Legendary = "🟧 LEGENDARY",
    Divine    = "🟥 DIVINE",
}

-- ============================================================
-- UPGRADES
-- ============================================================
GameConfig.UPGRADES = {
    -- Luck Upgrades: aumentam chance de raros
    {
        id = "luck1",
        name = "Lucky Charm",
        description = "Aumenta chance de auras raras em 10%",
        type = "Luck",
        level = 1,
        maxLevel = 5,
        baseCost = { coins = 500, gems = 0 },
        costMultiplier = 2.5,
        effect = 0.10,  -- 10% por nivel
        icon = "🍀",
    },
    {
        id = "luck2",
        name = "Fortune Crystal",
        description = "Reduz o divisor de chance em 20% por nivel",
        type = "Luck",
        level = 1,
        maxLevel = 3,
        baseCost = { coins = 5000, gems = 10 },
        costMultiplier = 3,
        effect = 0.20,
        icon = "💎",
    },

    -- Speed Upgrades: reduzem cooldown de giro
    {
        id = "speed1",
        name = "Quick Hands",
        description = "Reduz cooldown de giro em 0.5s por nivel",
        type = "Speed",
        level = 1,
        maxLevel = 6,
        baseCost = { coins = 300, gems = 0 },
        costMultiplier = 2,
        effect = 0.5,   -- segundos removidos por nivel
        icon = "⚡",
    },
    {
        id = "speed2",
        name = "Auto Spinner",
        description = "Ativa auto-spin a cada N segundos",
        type = "Speed",
        level = 1,
        maxLevel = 1,
        baseCost = { coins = 10000, gems = 50 },
        costMultiplier = 1,
        effect = 1,     -- unlocks auto-spin
        icon = "🔄",
    },

    -- Multiplier Upgrades: multiplicam coins ganhos
    {
        id = "multi1",
        name = "Coin Magnet",
        description = "Multiplica coins ganhos por 1.5x por nivel",
        type = "Multiplier",
        level = 1,
        maxLevel = 5,
        baseCost = { coins = 1000, gems = 0 },
        costMultiplier = 3,
        effect = 1.5,   -- multiplicador por nivel (acumula)
        icon = "🪙",
    },
    {
        id = "multi2",
        name = "Gem Hunter",
        description = "Chance de ganhar gemas extras ao girar",
        type = "Multiplier",
        level = 1,
        maxLevel = 3,
        baseCost = { coins = 2000, gems = 20 },
        costMultiplier = 4,
        effect = 0.05,  -- +5% chance de gem por nivel
        icon = "💍",
    },
}

-- ============================================================
-- ROLETAS ESPECIAIS
-- ============================================================
GameConfig.ROLL_TYPES = {
    {
        id = "normal",
        name = "Normal Roll",
        description = "Todas as auras disponiveis",
        cost = { coins = 0, gems = 0 },
        minRarity = nil,   -- sem filtro
        icon = "🎰",
        color = Color3.fromRGB(100, 200, 255),
    },
    {
        id = "mystic",
        name = "Mystic Roll",
        description = "Apenas Epic ou superior (3x mais chance!)",
        cost = { coins = 500, gems = 0 },
        minRarity = "Epic",
        icon = "🔮",
        color = Color3.fromRGB(180, 0, 255),
        luckMultiplier = 3,
    },
    {
        id = "godly",
        name = "Godly Roll",
        description = "Apenas Legendary ou superior (10x mais chance!)",
        cost = { coins = 0, gems = 50 },
        minRarity = "Legendary",
        icon = "⚡",
        color = Color3.fromRGB(255, 165, 0),
        luckMultiplier = 10,
    },
}

-- ============================================================
-- EVENTOS ALEATORIOS
-- ============================================================
GameConfig.EVENTS = {
    {
        id = "double_rng",
        name = "Double RNG!",
        description = "Chances de auras raras DUPLICADAS por 5 minutos!",
        duration = 300,  -- segundos
        color = Color3.fromRGB(255, 200, 0),
        icon = "⚡⚡",
        luckMultiplier = 2,
        coinMultiplier = 1,
    },
    {
        id = "luxury_hour",
        name = "Luxury Hour!",
        description = "Todas as auras dao 2x moedas por 5 minutos!",
        duration = 300,
        color = Color3.fromRGB(255, 215, 0),
        icon = "🪙🪙",
        luckMultiplier = 1,
        coinMultiplier = 2,
    },
    {
        id = "mystery_box",
        name = "Mystery Box!",
        description = "Uma caixa misteriosa apareceu! Clique para abrir!",
        duration = 60,
        color = Color3.fromRGB(0, 255, 200),
        icon = "📦",
        luckMultiplier = 1,
        coinMultiplier = 1,
        isBox = true,
    },
}

-- ============================================================
-- CONFIGURACOES GERAIS
-- ============================================================
GameConfig.SETTINGS = {
    BASE_SPIN_COOLDOWN  = 3,      -- segundos entre giros
    SPIN_ANIMATION_TIME = 2,      -- duracao da animacao de spin
    EVENT_MIN_INTERVAL  = 300,    -- minimo 5min entre eventos
    EVENT_MAX_INTERVAL  = 900,    -- maximo 15min entre eventos
    MAX_INVENTORY_SIZE  = 500,    -- max auras no inventario
    LEADERBOARD_SIZE    = 10,     -- top 10 no leaderboard
    COIN_PER_SPIN       = 2,      -- coins base por giro
    DATASTORE_KEY       = "SOLsRNG_v1",
}

-- ============================================================
-- RARIDADE -> ORDEM NUMERICA (para comparacoes)
-- ============================================================
GameConfig.RARITY_ORDER = {
    Common    = 1,
    Uncommon  = 2,
    Rare      = 3,
    Epic      = 4,
    Legendary = 5,
    Divine    = 6,
}

-- ============================================================
-- MENSAGENS ALEATORIAS POR RARIDADE
-- ============================================================
GameConfig.MESSAGES = {
    Common    = { "Hm... keep trying!", "That one's pretty mid ngl.", "It is what it is." },
    Uncommon  = { "Decent pull!", "Not bad!", "A little rare, nice!" },
    Rare      = { "RARE PULL! Let's go!", "Ooh, that's fire!", "We're cooking!" },
    Epic      = { "NO WAY! EPIC?!", "SHEESH bro! EPIC aura!", "We're SO BACK!" },
    Legendary = { "OMG LEGENDARY?! Are you kidding?!", "CHAT IS FREAKING OUT!", "SLAY QUEEN SLAY!" },
    Divine    = {
        "OMG YOU GOT GODLY! NO CAP BRO!",
        "RIZZ UP! YOU ARE THE CHOSEN ONE!",
        "WHAT THE HELL! DIVINE AURA?!",
        "CHAT CANNOT PROCESS THIS!",
        "BIGGEST W IN HISTORY!",
    },
}

-- ============================================================
-- FUNCAO AUXILIAR: busca aura por nome
-- ============================================================
function GameConfig.GetAuraByName(name)
    for _, aura in ipairs(GameConfig.AURAS) do
        if aura.name == name then
            return aura
        end
    end
    return nil
end

-- ============================================================
-- FUNCAO AUXILIAR: filtra auras por raridade minima
-- ============================================================
function GameConfig.GetAurasByMinRarity(minRarity)
    local filtered = {}
    local minOrder = GameConfig.RARITY_ORDER[minRarity] or 1
    for _, aura in ipairs(GameConfig.AURAS) do
        if GameConfig.RARITY_ORDER[aura.rarity] >= minOrder then
            table.insert(filtered, aura)
        end
    end
    return filtered
end

return GameConfig
