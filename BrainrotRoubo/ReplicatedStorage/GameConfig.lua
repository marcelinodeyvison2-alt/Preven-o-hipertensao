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

-- =====================================================
--  PETS
-- =====================================================
GameConfig.PETS = {
    { id="ratinho",  name="Ratinho Brainrot",  icon="🐭", cost=5000,    auraBonus=0.05, rarityBonus=0    },
    { id="gato",     name="Gato Místico",      icon="🐱", cost=25000,   auraBonus=0.10, rarityBonus=0    },
    { id="corvo",    name="Corvo das Sombras", icon="🐦", cost=80000,   auraBonus=0,    rarityBonus=0.05 },
    { id="dragao",   name="Dragão Épico",      icon="🐉", cost=300000,  auraBonus=0.20, rarityBonus=0.10 },
    { id="fantasma", name="Fantasma OG",       icon="👻", cost=2000000, auraBonus=0.50, rarityBonus=0.20 },
}

-- =====================================================
--  PRESTÍGIO
-- =====================================================
GameConfig.MAX_REBIRTHS_FOR_PRESTIGE = 8
GameConfig.MAX_PRESTIGE              = 5
GameConfig.PRESTIGE_MULTIPLIER       = 1.5   -- por nível (multiplicativo)

-- =====================================================
--  CONQUISTAS
-- =====================================================
GameConfig.ACHIEVEMENTS = {
    { id="first_steal",  name="Primeiro Roubo",      desc="Roube 1 brainrot",          icon="🎯", type="totalStolen", threshold=1     },
    { id="steal_50",     name="Mão Leve",            desc="Roube 50 brainrots",         icon="💪", type="totalStolen", threshold=50    },
    { id="steal_500",    name="Ladrão Pro",          desc="Roube 500 brainrots",        icon="⚡", type="totalStolen", threshold=500   },
    { id="steal_5000",   name="Rei do Roubo",        desc="Roube 5.000 brainrots",      icon="👑", type="totalStolen", threshold=5000  },
    { id="rebirth_1",    name="Renascido",           desc="Faça 1 rebirth",             icon="✨", type="rebirths",    threshold=1     },
    { id="rebirth_5",    name="Cinco Vidas",         desc="Faça 5 rebirths",            icon="🌟", type="rebirths",    threshold=5     },
    { id="rebirth_max",  name="Rebirth Máximo",      desc="Chegue ao rebirth 8",        icon="🔱", type="rebirths",    threshold=8     },
    { id="got_raro",     name="Raridade Descoberta", desc="Roube 1 Raro",               icon="💎", type="rarity",      rarity="Raro"    },
    { id="got_lendario", name="Lendário Capturado",  desc="Roube 1 Lendário",           icon="⭐", type="rarity",      rarity="Lendario"},
    { id="got_mitico",   name="Poder Mítico",        desc="Roube 1 Mítico",             icon="🔥", type="rarity",      rarity="Mitico"  },
    { id="got_god",      name="Toque Divino",        desc="Roube 1 God",                icon="💫", type="rarity",      rarity="God"     },
    { id="got_secret",   name="O Segredo",           desc="Roube 1 Secret",             icon="🌑", type="rarity",      rarity="Secret"  },
    { id="got_og",       name="O ORIGINAL",          desc="Roube o OG — 1 em 1.000.000",icon="🏆",type="rarity",      rarity="OG"      },
    { id="got_lua",      name="Lua de Sangue",       desc="Roube 1 Lua de Sangue",      icon="🌑", type="mutation",    mutation="Lua de Sangue" },
    { id="prestige_1",   name="Prestigiado",         desc="Faça 1 prestígio",           icon="💎", type="prestige",    threshold=1     },
}

-- =====================================================
--  TÍTULOS DESBLOQUEÁVEIS
-- =====================================================
GameConfig.TITLES = {
    { id="iniciante",  name="Iniciante",    unlock="first_steal"  },
    { id="ladrao",     name="Ladrão",       unlock="steal_50"     },
    { id="pro",        name="Pro",          unlock="steal_500"    },
    { id="rei",        name="Rei do Roubo", unlock="steal_5000"   },
    { id="renascido",  name="Renascido",    unlock="rebirth_1"    },
    { id="mitico",     name="Mítico",       unlock="got_mitico"   },
    { id="divino",     name="Divino",       unlock="got_god"      },
    { id="secreto",    name="???",          unlock="got_secret"   },
    { id="original",   name="O ORIGINAL",   unlock="got_og"       },
    { id="lenda",      name="Lenda",        unlock="rebirth_max"  },
    { id="prestigiado",name="Prestigiado",  unlock="prestige_1"   },
}

-- =====================================================
--  VIP / ADMIN
-- =====================================================
GameConfig.VIP_GAMEPASS_ID = 987654321   -- substitua pelo ID real
GameConfig.VIP_AURA_BONUS  = 2.0         -- 2× aura para VIP
GameConfig.VIP_CAP_BONUS   = 2           -- +2 no rebirthsCap base
GameConfig.ADMIN_IDS       = {}          -- ex: { 123456789, 987654321 }

-- =====================================================
--  EVENTO ATUAL (nil = sem evento ativo)
-- =====================================================
GameConfig.CURRENT_EVENT = nil
-- Exemplo:
-- GameConfig.CURRENT_EVENT = {
--     name      = "Fim de Semana de Ouro",
--     icon      = "⭐",
--     auraBonus = 2.0,
--     rarBonus  = 1.5,    -- peso extra para raros
--     color     = Color3.fromRGB(255, 215, 0),
-- }

-- =====================================================
--  BATTLEPASS
-- =====================================================
GameConfig.BATTLEPASS_SEASON        = 1
GameConfig.BATTLEPASS_LEVELS        = 30
GameConfig.BATTLEPASS_XP_PER_LEVEL  = 1000
GameConfig.BATTLEPASS_XP_STEAL      = 10
GameConfig.BATTLEPASS_XP_REBIRTH    = 200
GameConfig.BATTLEPASS_XP_PRESTIGE   = 1000
GameConfig.BATTLEPASS_REWARDS = {
    [1]  = { type="aura",  amount=5000,   name="5k Aura"         },
    [5]  = { type="pet",   id="ratinho",  name="Pet Ratinho"     },
    [10] = { type="aura",  amount=50000,  name="50k Aura"        },
    [15] = { type="pet",   id="gato",     name="Pet Gato Místico"},
    [20] = { type="title", id="lenda",    name="Título: Lenda"   },
    [25] = { type="aura",  amount=500000, name="500k Aura"       },
    [30] = { type="pet",   id="dragao",   name="Pet Dragão Épico"},
}

-- =====================================================
--  COMBINAÇÃO DE BRAINROTS
-- =====================================================
GameConfig.COMBINE_CHANCE = {
    Comum    = 1.0,
    Incomum  = 0.9,
    Raro     = 0.8,
    Epico    = 0.7,
    Lendario = 0.6,
    Mitico   = 0.5,
    God      = 0.4,
    Secret   = 0.3,
    OG       = 0,    -- não pode combinar OG
}

-- =====================================================
--  INVENTÁRIO
-- =====================================================
GameConfig.INVENTORY_MAX_SLOTS = 50

-- =====================================================
--  ROTAÇÃO DE BIOMA
-- =====================================================
GameConfig.BIOME_ROTATION_INTERVAL = 300   -- segundos (5 min)

-- =====================================================
--  NOVOS SISTEMAS (v3)
-- =====================================================
-- Visual 3D por raridade: quantos anéis decorativos
GameConfig.RARITY_MESH = {
    Comum    = { rings=0, particles=false },
    Incomum  = { rings=0, particles=false },
    Raro     = { rings=0, particles=true  },
    Epico    = { rings=1, particles=true  },
    Lendario = { rings=1, particles=true  },
    Mitico   = { rings=1, particles=true  },
    God      = { rings=2, particles=true  },
    Secret   = { rings=2, particles=true  },
    OG       = { rings=3, particles=true  },
}

-- SFX por raridade (asset IDs do Roblox)
GameConfig.RARITY_SFX = {
    Comum    = 142070081,
    Incomum  = 255670561,
    Raro     = 616576400,
    Epico    = 190840006,
    Lendario = 743521451,
    Mitico   = 145556083,
    God      = 507771019,
    Secret   = 278062209,
    OG       = 1369158552,
}

-- Prestígio escala o CAP de aura de forma mais agressiva
GameConfig.PRESTIGE_CAP_MULT             = 3.0

-- Rebirth aumenta chance de upgrade de raridade ao roubar
GameConfig.REBIRTH_RARITY_UPGRADE_CHANCE = 0.05   -- 5% por threshold
GameConfig.REBIRTH_RARITY_UPGRADE_EVERY  = 3      -- a cada 3 rebirths

-- Sistema de times
GameConfig.TEAM_AURA_SHARE     = 0.15  -- 15% da aura vai pro companheiro de time
GameConfig.TEAM_INVITE_TIMEOUT = 30    -- segundos antes do convite expirar

-- Missões semanais (todas ativas ao mesmo tempo)
GameConfig.WEEKLY_MISSIONS = {
    { id="wsteal500", name="Ladrão Semanal",    desc="Roube 500 brainrots esta semana",   type="steal",    target=500,  reward=500000  },
    { id="wget_god",  name="Caçador de Deuses", desc="Roube 1 God ou melhor esta semana", type="rarityMin",rarityMin=7, target=1,     reward=2000000 },
    { id="wrebirth3", name="Triplicidade",       desc="Faça 3 rebirths esta semana",       type="rebirth",  target=3,    reward=300000  },
    { id="wgetlua",   name="Lua da Semana",      desc="Roube 1 Lua de Sangue esta semana", type="mutation", mutation="Lua de Sangue", target=1, reward=1000000 },
}

-- Streak de login
GameConfig.LOGIN_STREAK_REWARDS = {
    [1]  = { type="aura",  amount=1000,   name="1.000 Aura"       },
    [3]  = { type="aura",  amount=10000,  name="10.000 Aura"      },
    [7]  = { type="pet",   id="ratinho",  name="Pet Ratinho"      },
    [14] = { type="pet",   id="gato",     name="Pet Gato Místico" },
    [30] = { type="title", id="lenda",    name="Título: Lenda"    },
}
GameConfig.LOGIN_STREAK_MAX_GAP = 2  -- dias sem logar antes de resetar streak

-- =====================================================
--  VISUAL 3D AVANÇADO POR RARIDADE
-- =====================================================
-- mesh: tipo do SpecialMesh | orbCount: orbs satélite ao redor
GameConfig.RARITY_VISUAL = {
    Comum    = { mesh="Sphere",  orbCount=0 },
    Incomum  = { mesh="Brick",   orbCount=0 },
    Raro     = { mesh="Sphere",  orbCount=1 },
    Epico    = { mesh="Torso",   orbCount=2 },
    Lendario = { mesh="Sphere",  orbCount=3 },
    Mitico   = { mesh="Wedge",   orbCount=3 },
    God      = { mesh="Sphere",  orbCount=4 },
    Secret   = { mesh="Head",    orbCount=3 },
    OG       = { mesh="Sphere",  orbCount=5 },
}

-- Escala do mesh principal por raridade
GameConfig.RARITY_MESH_SCALE = {
    Comum    = Vector3.new(1.0, 1.0, 1.0),
    Incomum  = Vector3.new(1.0, 1.0, 1.0),
    Raro     = Vector3.new(1.1, 1.1, 1.1),
    Epico    = Vector3.new(1.0, 1.0, 1.0),
    Lendario = Vector3.new(1.2, 1.2, 1.2),
    Mitico   = Vector3.new(1.1, 1.1, 1.1),
    God      = Vector3.new(1.3, 1.3, 1.3),
    Secret   = Vector3.new(1.2, 1.2, 1.2),
    OG       = Vector3.new(1.5, 1.5, 1.5),
}

-- Ícones de raridade para a UI
GameConfig.RARITY_ICONS = {
    Comum    = "⬜",
    Incomum  = "🟩",
    Raro     = "🟦",
    Epico    = "🟪",
    Lendario = "🌟",
    Mitico   = "🔥",
    God      = "👑",
    Secret   = "❓",
    OG       = "🏆",
}

return GameConfig
