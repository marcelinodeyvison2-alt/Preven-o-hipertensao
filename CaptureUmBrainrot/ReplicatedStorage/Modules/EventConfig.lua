-- EventConfig.lua
-- Defines timed global events that affect the entire server.

local EventConfig = {}

-- Time between random event triggers (seconds)
EventConfig.MinInterval = 1800  -- 30 min
EventConfig.MaxInterval = 3600  -- 60 min

-- Event definitions
-- AuraMultiplier : multiplied into all Aura gained
-- LuckMultiplier : multiplied into all LuckBonus values
-- SpawnMultiplier: how many extra brainrots to spawn (1 = normal)
EventConfig.Events = {
    DoubleAura = {
        Key             = "DoubleAura",
        Name            = "Aura em Dobro!",
        Description     = "Todo Aura ganho e dobrado durante o evento!",
        Emoji           = "⭐",
        Duration        = 600,
        AuraMultiplier  = 2.0,
        LuckMultiplier  = 1.0,
        SpawnMultiplier = 1,
        Color           = Color3.fromRGB(255, 215, 0),
    },
    TripleLuck = {
        Key             = "TripleLuck",
        Name            = "Sorte Suprema!",
        Description     = "Toda sorte esta triplicada. Mais chance de dobrar a venda!",
        Emoji           = "🍀",
        Duration        = 600,
        AuraMultiplier  = 1.0,
        LuckMultiplier  = 3.0,
        SpawnMultiplier = 1,
        Color           = Color3.fromRGB(50, 220, 100),
    },
    MegaSpawn = {
        Key             = "MegaSpawn",
        Name            = "Mega Invasao!",
        Description     = "Os Brainrots estao invadindo em massa!",
        Emoji           = "🧠",
        Duration        = 480,
        AuraMultiplier  = 1.0,
        LuckMultiplier  = 1.0,
        SpawnMultiplier = 3,
        Color           = Color3.fromRGB(180, 50, 255),
    },
    BrainrotFestival = {
        Key             = "BrainrotFestival",
        Name            = "Festival de Brainrots!",
        Description     = "Aura 1.5x e sorte 2x. A festa comecou!",
        Emoji           = "🎉",
        Duration        = 900,
        AuraMultiplier  = 1.5,
        LuckMultiplier  = 2.0,
        SpawnMultiplier = 2,
        Color           = Color3.fromRGB(255, 120, 20),
    },
    SecretHour = {
        Key             = "SecretHour",
        Name            = "Hora Secreta!",
        Description     = "Brainrots Secretos aparecem com muito mais frequencia!",
        Emoji           = "🕳️",
        Duration        = 300,
        AuraMultiplier  = 1.0,
        LuckMultiplier  = 10.0,
        SpawnMultiplier = 1,
        Color           = Color3.fromRGB(255, 50, 50),
    },
}

EventConfig.EventList = {
    "DoubleAura", "TripleLuck", "MegaSpawn", "BrainrotFestival", "SecretHour",
}

return EventConfig
