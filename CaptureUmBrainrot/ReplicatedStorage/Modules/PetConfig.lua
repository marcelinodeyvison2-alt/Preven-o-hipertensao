-- PetConfig.lua
-- Defines all pets, their rarities, and bonuses.

local PetConfig = {}

PetConfig.EggCost = 500  -- Aura per egg roll

PetConfig.RarityWeights = {
    Comum    = 40,
    Incomum  = 35,
    Raro     = 18,
    Epico    = 5,
    Lendario = 1.9,
    Secreto  = 0.1,
}

-- AuraMultiplier: multiplies all Aura gained while equipped
-- LuckBonus:      extra % chance to double sell value (0 to 1)
PetConfig.Pets = {
    -- Comuns (40%)
    { Name = "Gatinho Cosmico",     Rarity = "Comum",    Emoji = "🐱", AuraMultiplier = 1.15, LuckBonus = 0.05 },
    { Name = "Cachorrinho Glitch",  Rarity = "Comum",    Emoji = "🐶", AuraMultiplier = 1.12, LuckBonus = 0.06 },
    { Name = "Coelhinho Brainrot",  Rarity = "Comum",    Emoji = "🐰", AuraMultiplier = 1.10, LuckBonus = 0.08 },
    { Name = "Pinguim Gelado",      Rarity = "Comum",    Emoji = "🐧", AuraMultiplier = 1.18, LuckBonus = 0.04 },

    -- Incomuns (35%)
    { Name = "Dragaozinho RGB",     Rarity = "Incomum",  Emoji = "🐲", AuraMultiplier = 1.30, LuckBonus = 0.10 },
    { Name = "Tartaruga Turbo",     Rarity = "Incomum",  Emoji = "🐢", AuraMultiplier = 1.25, LuckBonus = 0.12 },
    { Name = "Unicornio Neon",      Rarity = "Incomum",  Emoji = "🦄", AuraMultiplier = 1.35, LuckBonus = 0.09 },
    { Name = "Hamster Quantico",    Rarity = "Incomum",  Emoji = "🐹", AuraMultiplier = 1.28, LuckBonus = 0.11 },

    -- Raros (18%)
    { Name = "Tubarao Fantasma",    Rarity = "Raro",     Emoji = "🦈", AuraMultiplier = 1.60, LuckBonus = 0.18 },
    { Name = "Lobo Galactico",      Rarity = "Raro",     Emoji = "🐺", AuraMultiplier = 1.55, LuckBonus = 0.20 },
    { Name = "Coruja Arcana",       Rarity = "Raro",     Emoji = "🦉", AuraMultiplier = 1.50, LuckBonus = 0.22 },

    -- Épicos (5%)
    { Name = "Fenix Dourada",       Rarity = "Epico",    Emoji = "🔥", AuraMultiplier = 2.00, LuckBonus = 0.35 },
    { Name = "Serpente Sombria",    Rarity = "Epico",    Emoji = "🐍", AuraMultiplier = 1.90, LuckBonus = 0.40 },

    -- Lendários (1.9%)
    { Name = "Dragao Brainrot",     Rarity = "Lendario", Emoji = "🐉", AuraMultiplier = 3.00, LuckBonus = 0.60 },

    -- Secretos (0.1%)
    { Name = "Deus dos Brainrots",  Rarity = "Secreto",  Emoji = "👁️", AuraMultiplier = 5.00, LuckBonus = 1.00 },
}

PetConfig.MaxEquipped = 3

-- Lookup pet data by name
local petIndex = {}
for _, pet in ipairs(PetConfig.Pets) do
    petIndex[pet.Name] = pet
end

function PetConfig.getPetByName(name)
    return petIndex[name]
end

-- Roll a random rarity using weights
function PetConfig.rollRarity()
    local total = 0
    for _, w in pairs(PetConfig.RarityWeights) do total = total + w end
    local roll = math.random() * total
    local cum  = 0
    for rarity, w in pairs(PetConfig.RarityWeights) do
        cum = cum + w
        if roll <= cum then return rarity end
    end
    return "Comum"
end

-- Pick a random pet of the given rarity
function PetConfig.randomPetOfRarity(rarityKey)
    local pool = {}
    for _, pet in ipairs(PetConfig.Pets) do
        if pet.Rarity == rarityKey then pool[#pool + 1] = pet end
    end
    if #pool == 0 then return PetConfig.Pets[1] end
    return pool[math.random(1, #pool)]
end

return PetConfig
