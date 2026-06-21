-- ModuleScript: ReplicatedStorage > GameConfig
-- Configurações centrais do jogo de Roubar Brainrot

local GameConfig = {}

-- =====================================================
--  TIPOS DE BRAINROT (nome, raridade, aura base)
-- =====================================================
GameConfig.BRAINROT_TYPES = {
    -- COMUM (frequente, pouca aura)
    { name = "Tralalero Tralala",     rarity = "Comum",     baseAura = 10  },
    { name = "Bombardiro Crocodilo",  rarity = "Comum",     baseAura = 15  },
    { name = "Brr Brr Patapim",       rarity = "Comum",     baseAura = 12  },
    { name = "Bananini Pepino",       rarity = "Comum",     baseAura = 8   },

    -- INCOMUM
    { name = "Tung Tung Sahur",       rarity = "Incomum",   baseAura = 60  },
    { name = "Bombombini Gusini",     rarity = "Incomum",   baseAura = 80  },
    { name = "Chimpanzini Bananini",  rarity = "Incomum",   baseAura = 75  },

    -- RARO
    { name = "Lirili Larila",         rarity = "Raro",      baseAura = 300 },
    { name = "Cappuccino Assassino",  rarity = "Raro",      baseAura = 400 },
    { name = "Pistolini Penguini",    rarity = "Raro",      baseAura = 350 },

    -- ÉPICO
    { name = "Trippi Troppi",         rarity = "Epico",     baseAura = 1500  },
    { name = "Glorbo Fruttodrillo",   rarity = "Epico",     baseAura = 2000  },
    { name = "Frigo Camello",         rarity = "Epico",     baseAura = 1800  },

    -- LENDÁRIO
    { name = "La Vacca Saturno",      rarity = "Lendario",  baseAura = 8000  },
    { name = "Octopussini Tentacolo", rarity = "Lendario",  baseAura = 12000 },

    -- MÍTICO (rarissimo)
    { name = "Il Cacciatore Cosmico", rarity = "Mitico",    baseAura = 50000 },
    { name = "Banana Divina Eterna",  rarity = "Mitico",    baseAura = 75000 },
}

-- =====================================================
--  PESOS DE RARIDADE (soma total = 10000)
--  Quanto maior o número, mais comum
-- =====================================================
GameConfig.RARITY_WEIGHTS = {
    Comum    = 4500,
    Incomum  = 2800,
    Raro     = 1500,
    Epico    = 800,
    Lendario = 330,
    Mitico   = 70,
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
}

-- =====================================================
--  SISTEMA DE AURA
-- =====================================================
GameConfig.BASE_AURA_CAP         = 500    -- Cap inicial de aura
GameConfig.AURA_CAP_MULTIPLIER   = 5      -- Cada rebirth: cap * 5
GameConfig.AURA_GAIN_MULTIPLIER  = 2      -- Cada rebirth: ganho * 2
GameConfig.REBIRTH_COST_FRACTION = 0.8   -- Custo do rebirth = 80% do cap atual

-- =====================================================
--  MUNDO / SPAWN
-- =====================================================
GameConfig.STEAL_RANGE      = 14    -- Distância máxima para roubar (studs)
GameConfig.SPAWN_INTERVAL   = 2.5   -- Segundos entre spawns
GameConfig.MAX_BRAINROTS    = 30    -- Máximo simultâneo no mundo
GameConfig.BRAINROT_LIFETIME = 45   -- Segundos até desaparecer

-- Área de spawn (mapa quadrado simétrico em torno da origem)
GameConfig.SPAWN_AREA_HALF  = 120   -- brainrots surgem de -120 a +120 em X e Z

return GameConfig
