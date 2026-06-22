-- MissionConfig.lua
-- Defines daily mission templates and their difficulty tiers.

local MissionConfig = {}

MissionConfig.DailyCount = 3

-- Each template has a Type used by MissionManager to route progress events.
-- RarityFilter = nil means any rarity qualifies.
MissionConfig.Templates = {
    {
        Type  = "capture",
        Tiers = {
            { Desc = "Capture 10 Brainrots",  Goal = 10,  Reward = 100  },
            { Desc = "Capture 25 Brainrots",  Goal = 25,  Reward = 300  },
            { Desc = "Capture 50 Brainrots",  Goal = 50,  Reward = 800  },
            { Desc = "Capture 100 Brainrots", Goal = 100, Reward = 2000 },
        },
    },
    {
        Type         = "captureRarity",
        RarityFilter = { Raro=true, Epico=true, Lendario=true, Secreto=true },
        Tiers = {
            { Desc = "Capture 1 Brainrot Raro+",   Goal = 1, Reward = 400  },
            { Desc = "Capture 3 Brainrots Raros+",  Goal = 3, Reward = 1000 },
            { Desc = "Capture 5 Brainrots Raros+",  Goal = 5, Reward = 2500 },
        },
    },
    {
        Type         = "captureRarity",
        RarityFilter = { Epico=true, Lendario=true, Secreto=true },
        Tiers = {
            { Desc = "Capture 1 Brainrot Epico+",  Goal = 1, Reward = 1500 },
            { Desc = "Capture 2 Brainrots Epicos+", Goal = 2, Reward = 4000 },
        },
    },
    {
        Type  = "sell",
        Tiers = {
            { Desc = "Venda 10 Brainrots", Goal = 10, Reward = 80  },
            { Desc = "Venda 25 Brainrots", Goal = 25, Reward = 220 },
            { Desc = "Venda 50 Brainrots", Goal = 50, Reward = 600 },
        },
    },
    {
        Type  = "sellAura",
        Tiers = {
            { Desc = "Ganhe 500 Aura vendendo",    Goal = 500,   Reward = 100  },
            { Desc = "Ganhe 2000 Aura vendendo",   Goal = 2000,  Reward = 400  },
            { Desc = "Ganhe 10000 Aura vendendo",  Goal = 10000, Reward = 2000 },
        },
    },
    {
        Type  = "openEgg",
        Tiers = {
            { Desc = "Abra 1 Ovo de Pet",  Goal = 1, Reward = 700  },
            { Desc = "Abra 3 Ovos de Pet", Goal = 3, Reward = 1800 },
            { Desc = "Abra 5 Ovos de Pet", Goal = 5, Reward = 3500 },
        },
    },
}

-- Returns a single random mission instance (plain table, DataStore-safe)
function MissionConfig.rollMission()
    local template = MissionConfig.Templates[math.random(1, #MissionConfig.Templates)]
    local tier     = template.Tiers[math.random(1, #template.Tiers)]
    return {
        description  = tier.Desc,
        missionType  = template.Type,
        rarityFilter = template.RarityFilter,
        goal         = tier.Goal,
        reward       = tier.Reward,
        progress     = 0,
        completed    = false,
        claimed      = false,
    }
end

-- Rolls DailyCount missions, avoiding exact description duplicates
function MissionConfig.rollDailyMissions()
    local missions = {}
    local used     = {}
    local attempts = 0
    while #missions < MissionConfig.DailyCount and attempts < 60 do
        attempts = attempts + 1
        local m = MissionConfig.rollMission()
        if not used[m.description] then
            used[m.description] = true
            missions[#missions + 1] = m
        end
    end
    return missions
end

return MissionConfig
