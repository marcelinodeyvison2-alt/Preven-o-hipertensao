-- BrainrotConfig.lua
-- Central configuration for all Brainrots, rarities, and areas.
-- Extend this module to add new content without touching other systems.

local BrainrotConfig = {}

-- ── Rarities ─────────────────────────────────────────────────────────────────

BrainrotConfig.Rarities = {
    Comum = {
        DisplayName = "Comum",
        Chance      = 60,
        AuraValue   = 10,
        Color       = Color3.fromRGB(200, 200, 200),
        GlowColor   = Color3.fromRGB(170, 170, 170),
        Order       = 1,
    },
    Incomum = {
        DisplayName = "Incomum",
        Chance      = 25,
        AuraValue   = 50,
        Color       = Color3.fromRGB(100, 220, 100),
        GlowColor   = Color3.fromRGB(60,  180,  60),
        Order       = 2,
    },
    Raro = {
        DisplayName = "Raro",
        Chance      = 10,
        AuraValue   = 250,
        Color       = Color3.fromRGB(80,  130, 255),
        GlowColor   = Color3.fromRGB(50,   90, 220),
        Order       = 3,
    },
    Epico = {
        DisplayName = "Épico",
        Chance      = 4,
        AuraValue   = 1000,
        Color       = Color3.fromRGB(180,  50, 255),
        GlowColor   = Color3.fromRGB(140,   0, 220),
        Order       = 4,
    },
    Lendario = {
        DisplayName = "Lendário",
        Chance      = 0.9,
        AuraValue   = 5000,
        Color       = Color3.fromRGB(255, 210,   0),
        GlowColor   = Color3.fromRGB(255, 170,   0),
        Order       = 5,
    },
    Secreto = {
        DisplayName = "Secreto",
        Chance      = 0.1,
        AuraValue   = 25000,
        Color       = Color3.fromRGB(255,  50,  50),
        GlowColor   = Color3.fromRGB(200,   0,   0),
        Order       = 6,
    },
}

-- Canonical order used for display and sorting
BrainrotConfig.RarityOrder = {
    "Comum", "Incomum", "Raro", "Epico", "Lendario", "Secreto",
}

-- ── Brainrot List ─────────────────────────────────────────────────────────────

BrainrotConfig.Brainrots = {
    -- Comuns (60%)
    { Name = "Tralalelo Tralala",        Rarity = "Comum",    Emoji = "🐊" },
    { Name = "Bombardiro Crocodilo",     Rarity = "Comum",    Emoji = "✈️" },
    { Name = "Capuccino Assassino",      Rarity = "Comum",    Emoji = "☕" },
    { Name = "Bananini Pinguini",        Rarity = "Comum",    Emoji = "🐧" },
    { Name = "Frigo Camelo",             Rarity = "Comum",    Emoji = "🐪" },
    { Name = "Giraffini Macchinini",     Rarity = "Comum",    Emoji = "🦒" },
    { Name = "Limonini Serpentini",      Rarity = "Comum",    Emoji = "🍋" },
    { Name = "Patotini Robotini",        Rarity = "Comum",    Emoji = "🦆" },
    { Name = "Pizzini Aquilini",         Rarity = "Comum",    Emoji = "🦅" },
    { Name = "Tornadino Gatino",         Rarity = "Comum",    Emoji = "🌪️" },

    -- Incomuns (25%)
    { Name = "Tung Tung Tung Sahur",     Rarity = "Incomum",  Emoji = "🥁" },
    { Name = "Ballerina Cappuccina",     Rarity = "Incomum",  Emoji = "💃" },
    { Name = "Glorbo Fleeb",             Rarity = "Incomum",  Emoji = "👾" },
    { Name = "La Vaca Saturno",          Rarity = "Incomum",  Emoji = "🐄" },
    { Name = "Trippi Troppi",            Rarity = "Incomum",  Emoji = "🌀" },
    { Name = "Orangutan Italiano",       Rarity = "Incomum",  Emoji = "🦧" },
    { Name = "Elefantino Submarino",     Rarity = "Incomum",  Emoji = "🐘" },
    { Name = "Cactusino Dancerino",      Rarity = "Incomum",  Emoji = "🌵" },

    -- Raros (10%)
    { Name = "Crocodilo Cementino",      Rarity = "Raro",     Emoji = "🏗️" },
    { Name = "Mediocre Tutorial",        Rarity = "Raro",     Emoji = "📖" },
    { Name = "Brrr Brrr Patapim",        Rarity = "Raro",     Emoji = "🔧" },
    { Name = "Chimpanzini Bananini",     Rarity = "Raro",     Emoji = "🍌" },
    { Name = "Quaquiri Quaquara",        Rarity = "Raro",     Emoji = "🔊" },
    { Name = "Dragao Espagueti",         Rarity = "Raro",     Emoji = "🐉" },

    -- Épicos (4%)
    { Name = "Boneca Ambalabu",          Rarity = "Epico",    Emoji = "🪆" },
    { Name = "Tralalero Supremo",        Rarity = "Epico",    Emoji = "👑" },
    { Name = "Crocodiloni Giganti",      Rarity = "Epico",    Emoji = "🦕" },
    { Name = "Sahur Maximo",             Rarity = "Epico",    Emoji = "💥" },
    { Name = "Fantasmino Fluorescente",  Rarity = "Epico",    Emoji = "👻" },

    -- Lendários (0.9%)
    { Name = "Il Bombardone",            Rarity = "Lendario", Emoji = "💣" },
    { Name = "Tralala Rei",              Rarity = "Lendario", Emoji = "🏆" },
    { Name = "Glorbo Supremus",          Rarity = "Lendario", Emoji = "✨" },
    { Name = "Dragao Cosmico",           Rarity = "Lendario", Emoji = "🌟" },

    -- Secretos (0.1%)
    { Name = "Brainrot Primordial",      Rarity = "Secreto",  Emoji = "🌑" },
    { Name = "Void Brainrot",            Rarity = "Secreto",  Emoji = "🕳️" },
    { Name = "???",                      Rarity = "Secreto",  Emoji = "❓" },
}

-- ── Areas ─────────────────────────────────────────────────────────────────────

BrainrotConfig.Areas = {
    CampoInicial = {
        DisplayName   = "Campo Inicial",
        Rarities      = { "Comum" },
        UnlockCost    = 0,
        SpawnInterval = 6,
        MaxSpawns     = 10,
        Position      = Vector3.new(0,    0, -90),
        Size          = Vector3.new(110,  1,  90),
        FloorColor    = Color3.fromRGB(106, 186, 100),
        IsDefault     = true,
    },
    FlorestaBrainrot = {
        DisplayName   = "Floresta Brainrot",
        Rarities      = { "Comum", "Incomum" },
        UnlockCost    = 500,
        SpawnInterval = 8,
        MaxSpawns     = 8,
        Position      = Vector3.new(160,  0,   0),
        Size          = Vector3.new(90,   1,  90),
        FloorColor    = Color3.fromRGB(50,  140,  50),
    },
    CidadeBrainrot = {
        DisplayName   = "Cidade Brainrot",
        Rarities      = { "Incomum", "Raro" },
        UnlockCost    = 2500,
        SpawnInterval = 12,
        MaxSpawns     = 6,
        Position      = Vector3.new(-160, 0,   0),
        Size          = Vector3.new(90,   1,  90),
        FloorColor    = Color3.fromRGB(140, 140, 170),
    },
    LaboratorioBrainrot = {
        DisplayName   = "Laboratório Brainrot",
        Rarities      = { "Raro", "Epico" },
        UnlockCost    = 10000,
        SpawnInterval = 20,
        MaxSpawns     = 5,
        Position      = Vector3.new(0,    0,  160),
        Size          = Vector3.new(90,   1,   90),
        FloorColor    = Color3.fromRGB(130, 210, 255),
    },
    DimensaoGlitch = {
        DisplayName   = "Dimensão Glitch",
        Rarities      = { "Epico", "Lendario", "Secreto" },
        UnlockCost    = 50000,
        SpawnInterval = 30,
        MaxSpawns     = 4,
        Position      = Vector3.new(0,    0,  320),
        Size          = Vector3.new(90,   1,   90),
        FloorColor    = Color3.fromRGB(80,   0, 120),
    },
}

BrainrotConfig.AreaOrder = {
    "CampoInicial",
    "FlorestaBrainrot",
    "CidadeBrainrot",
    "LaboratorioBrainrot",
    "DimensaoGlitch",
}

-- ── Helpers ──────────────────────────────────────────────────────────────────

-- Returns a weighted-random rarity key from the provided list of rarity keys.
function BrainrotConfig.rollRarity(allowedRarities)
    local total = 0
    for _, key in ipairs(allowedRarities) do
        total = total + (BrainrotConfig.Rarities[key] and BrainrotConfig.Rarities[key].Chance or 0)
    end
    local roll = math.random() * total
    local cumulative = 0
    for _, key in ipairs(allowedRarities) do
        cumulative = cumulative + BrainrotConfig.Rarities[key].Chance
        if roll <= cumulative then
            return key
        end
    end
    return allowedRarities[1]
end

-- Returns a random brainrot entry matching the given rarity key.
function BrainrotConfig.randomBrainrot(rarityKey)
    local pool = {}
    for _, b in ipairs(BrainrotConfig.Brainrots) do
        if b.Rarity == rarityKey then
            pool[#pool + 1] = b
        end
    end
    if #pool == 0 then return BrainrotConfig.Brainrots[1] end
    return pool[math.random(1, #pool)]
end

-- Returns the aura value for a rarity key.
function BrainrotConfig.auraForRarity(rarityKey)
    local r = BrainrotConfig.Rarities[rarityKey]
    return r and r.AuraValue or 0
end

return BrainrotConfig
