-- ModuleScript: ReplicatedStorage > GameConfig
-- Configurações centrais do jogo de Roubar Brainrot

local GameConfig = {}

-- =====================================================
--  TIPOS DE BRAINROT
-- =====================================================
GameConfig.BRAINROT_TYPES = {
    -- COMUM
    { name = "Tralalero Tralala",     rarity = "Comum",    baseAura = 10  },
    { name = "Bombardiro Crocodilo",  rarity = "Comum",    baseAura = 15  },
    { name = "Brr Brr Patapim",       rarity = "Comum",    baseAura = 12  },
    { name = "Bananini Pepino",       rarity = "Comum",    baseAura = 8   },

    -- INCOMUM
    { name = "Tung Tung Sahur",       rarity = "Incomum",  baseAura = 60  },
    { name = "Bombombini Gusini",     rarity = "Incomum",  baseAura = 80  },
    { name = "Chimpanzini Bananini",  rarity = "Incomum",  baseAura = 75  },

    -- RARO
    { name = "Lirili Larila",         rarity = "Raro",     baseAura = 300 },
    { name = "Cappuccino Assassino",  rarity = "Raro",     baseAura = 400 },
    { name = "Pistolini Penguini",    rarity = "Raro",     baseAura = 350 },

    -- ÉPICO
    { name = "Trippi Troppi",         rarity = "Epico",    baseAura = 1500  },
    { name = "Glorbo Fruttodrillo",   rarity = "Epico",    baseAura = 2000  },
    { name = "Frigo Camello",         rarity = "Epico",    baseAura = 1800  },

    -- LENDÁRIO
    { name = "La Vacca Saturno",      rarity = "Lendario", baseAura = 8000  },
    { name = "Octopussini Tentacolo", rarity = "Lendario", baseAura = 12000 },

    -- MÍTICO
    { name = "Il Cacciatore Cosmico", rarity = "Mitico",   baseAura = 50000 },
    { name = "Banana Divina Eterna",  rarity = "Mitico",   baseAura = 75000 },

    -- GOD
    { name = "Deus Supremo Tralala",    rarity = "God",    baseAura = 500000   },
    { name = "Zeus Brainroticus",        rarity = "God",    baseAura = 750000   },
    { name = "Divino Crocodilo Eterno",  rarity = "God",    baseAura = 1000000  },

    -- SECRET
    { name = "???",                    rarity = "Secret",   baseAura = 5000000  },
    { name = "Il Segreto Proibito",    rarity = "Secret",   baseAura = 8000000  },
    { name = "Ombra Senza Nome",       rarity = "Secret",   baseAura = 12000000 },

    -- OG (a mais rara do jogo)
    { name = "O ORIGINAL",             rarity = "OG",       baseAura = 100000000 },
}

-- =====================================================
--  PESOS DE RARIDADE (escala de 1.000.000)
-- =====================================================
GameConfig.RARITY_WEIGHTS = {
    Comum    = 450000,
    Incomum  = 280000,
    Raro     = 150000,
    Epico    = 80000,
    Lendario = 33000,
    Mitico   = 6790,
    God      = 200,
    Secret   = 9,
    OG       = 1,
}

-- =====================================================
--  CORES POR RARIDADE
-- =====================================================
GameConfig.RARITY_COLORS = {
    Comum    = Color3.fromRGB(180, 180, 180),
    Incomum  = Color3.fromRGB(80,  210, 80 ),
    Raro     = Color3.fromRGB(60,  120, 255),
    Epico    = Color3.fromRGB(190, 50,  255),
    Lendario = Color3.fromRGB(255, 195, 0  ),
    Mitico   = Color3.fromRGB(255, 50,  50 ),
    God      = Color3.fromRGB(255, 255, 120),
    Secret   = Color3.fromRGB(0,   220, 200),
    OG       = Color3.fromRGB(255, 255, 255),
}

-- =====================================================
--  MUTAÇÕES
--  weight = 0  → nunca sai no sorteio normal
-- =====================================================
GameConfig.MUTATIONS = {
    { name = "Básico",        multiplier = 1,   weight = 70000, color = Color3.fromRGB(180, 180, 180) },
    { name = "Bronze",        multiplier = 2,   weight = 18000, color = Color3.fromRGB(180, 110, 40)  },
    { name = "Ouro",          multiplier = 5,   weight = 8000,  color = Color3.fromRGB(255, 210, 0)   },
    { name = "Diamante",      multiplier = 10,  weight = 3000,  color = Color3.fromRGB(120, 210, 255) },
    { name = "Esmeralda",     multiplier = 15,  weight = 1000,  color = Color3.fromRGB(0,   210, 100) },
    -- Lua de Sangue: sorteada a cada LUA_DE_SANGUE_INTERVAL spawns (weight ignorado)
    { name = "Lua de Sangue", multiplier = 20,  weight = 0,     color = Color3.fromRGB(200, 0,   0)   },
}

GameConfig.LUA_DE_SANGUE_INTERVAL = 10000  -- a cada N brainrots spawned no servidor

-- =====================================================
--  POSIÇÕES DAS BASES (12 ao total)
--  X e Z em studs; Y = topo da base (aprox. 1.5)
-- =====================================================
GameConfig.BASE_POSITIONS = {
    -- Anel externo (raio 85)
    Vector3.new( 85,  1.5,   0),
    Vector3.new( 60,  1.5,  60),
    Vector3.new(  0,  1.5,  85),
    Vector3.new(-60,  1.5,  60),
    Vector3.new(-85,  1.5,   0),
    Vector3.new(-60,  1.5, -60),
    Vector3.new(  0,  1.5, -85),
    Vector3.new( 60,  1.5, -60),
    -- Anel interno (raio 42)
    Vector3.new( 42,  1.5,   0),
    Vector3.new(  0,  1.5,  42),
    Vector3.new(-42,  1.5,   0),
    Vector3.new(  0,  1.5, -42),
}

-- Nomes temáticos de cada base (mesmo índice de BASE_POSITIONS)
GameConfig.BASE_NAMES = {
    "Base Leste",     "Base Nordeste",  "Base Norte",     "Base Noroeste",
    "Base Oeste",     "Base Sudoeste",  "Base Sul",       "Base Sudeste",
    "Área Central A", "Área Central B", "Área Central C", "Área Central D",
}

-- =====================================================
--  SISTEMA DE AURA
-- =====================================================
GameConfig.BASE_AURA_CAP         = 500
GameConfig.AURA_CAP_MULTIPLIER   = 5
GameConfig.AURA_GAIN_MULTIPLIER  = 2
GameConfig.REBIRTH_COST_FRACTION = 0.8

-- =====================================================
--  MUNDO
-- =====================================================
GameConfig.STEAL_RANGE       = 18   -- aumentado pois bases são fixas
GameConfig.MAX_BRAINROTS     = 12   -- igual ao nº de bases
GameConfig.BRAINROT_LIFETIME = 50
GameConfig.SPAWN_INTERVAL    = 2.5

-- =====================================================
--  UPGRADES (loja de aura)
-- =====================================================
GameConfig.UPGRADES = {
    {
        id="stealRange", name="Alcance", icon="🎯",
        desc="Aumenta o alcance de roubo",
        maxLevel=5,
        costs  = {500,   2500,  10000, 50000,  250000},
        values = {22,    26,    30,    36,     45},
    },
    {
        id="walkSpeed", name="Velocidade", icon="⚡",
        desc="Aumenta a velocidade de caminhada",
        maxLevel=5,
        costs  = {750,   3500,  15000, 75000,  400000},
        values = {18,    20,    23,    27,     35},
    },
    {
        id="auraBonus", name="Bônus de Aura", icon="✨",
        desc="Multiplicador extra de aura ao roubar",
        maxLevel=5,
        costs  = {1000,  5000,  20000, 100000, 600000},
        values = {1.2,   1.5,   2.0,   3.0,    5.0},
    },
}

-- =====================================================
--  MISSÕES DIÁRIAS (3 sorteadas por dia)
-- =====================================================
GameConfig.DAILY_MISSIONS = {
    { id="steal10",  name="Ladrão Iniciante",  desc="Roube 10 brainrots",           type="steal",    target=10,  reward=1000  },
    { id="steal50",  name="Ladrão Experiente", desc="Roube 50 brainrots",           type="steal",    target=50,  reward=8000  },
    { id="steal200", name="Mestre do Roubo",   desc="Roube 200 brainrots",          type="steal",    target=200, reward=40000 },
    { id="getEpico", name="Caçador Épico",     desc="Roube 1 Épico ou mais raro",   type="rarityMin",rarityMin=4,target=1,    reward=5000  },
    { id="getLend",  name="Lenda Viva",        desc="Roube 1 Lendário ou mais raro",type="rarityMin",rarityMin=5,target=1,    reward=20000 },
    { id="getLua",   name="Lua Cheia",         desc="Roube 1 Lua de Sangue",        type="mutation", mutation="Lua de Sangue",target=1,reward=50000 },
    { id="rebirth1", name="Renascimento",      desc="Faça 1 rebirth",               type="rebirth",  target=1,   reward=15000 },
}

-- Rank de raridade (para missões e bioma)
GameConfig.RARITY_ORDER = {"Comum","Incomum","Raro","Epico","Lendario","Mitico","God","Secret","OG"}
GameConfig.RARITY_RANK  = {}
for i, r in ipairs(GameConfig.RARITY_ORDER) do
    GameConfig.RARITY_RANK[r] = i
end

return GameConfig
