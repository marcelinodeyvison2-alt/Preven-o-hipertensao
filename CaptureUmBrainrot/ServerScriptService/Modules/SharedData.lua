-- SharedData.lua (ServerScriptService ModuleScript)
-- Single source of truth for all server-side runtime state.
-- All server scripts require this module; Roblox guarantees one instance per server.

local SharedData = {}

-- Player sessions keyed by userId (number)
-- { aura, totalCaptured, inventory, unlockedAreas, rarestRarity,
--   rebirthCount, pets, equippedPets, clanName }
SharedData.sessions = {}

-- Active global event or nil
-- { Key, Name, AuraMultiplier, LuckMultiplier, SpawnMultiplier, endsAt }
SharedData.currentEvent = nil

-- Active trades keyed by tradeId (string)
-- { id, playerAId, playerBId, offerA, offerB, lockedA, lockedB }
SharedData.trades = {}

-- Clan data cache keyed by clanName (loaded from DataStore on demand)
-- { Name, Leader, Members={}, Description, Aura }
SharedData.clans = {}

-- Compute the total Aura multiplier for a session
function SharedData.totalAuraMultiplier(session)
    if not session then return 1 end

    local PetConfig = require(game.ReplicatedStorage.Modules.PetConfig)
    local mult = 1

    -- Rebirth bonus
    mult = mult * (1 + 0.5 * (session.rebirthCount or 0))

    -- Equipped pet bonuses (multiplicative)
    for _, petName in ipairs(session.equippedPets or {}) do
        local pet = PetConfig.getPetByName(petName)
        if pet then mult = mult * (pet.AuraMultiplier or 1) end
    end

    -- Active event
    if SharedData.currentEvent then
        mult = mult * (SharedData.currentEvent.AuraMultiplier or 1)
    end

    return mult
end

-- Compute total luck bonus for a session (0..N)
function SharedData.totalLuckBonus(session)
    if not session then return 0 end

    local PetConfig = require(game.ReplicatedStorage.Modules.PetConfig)
    local luck = 0

    for _, petName in ipairs(session.equippedPets or {}) do
        local pet = PetConfig.getPetByName(petName)
        if pet then luck = luck + (pet.LuckBonus or 0) end
    end

    if SharedData.currentEvent then
        luck = luck * (SharedData.currentEvent.LuckMultiplier or 1)
    end

    return luck
end

return SharedData
