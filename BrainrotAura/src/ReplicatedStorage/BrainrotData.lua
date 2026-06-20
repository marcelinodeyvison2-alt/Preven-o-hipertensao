-- BrainrotData.lua  (v2)
local BrainrotData = {}

BrainrotData.RARITIES = {
	Common    = { name = "Comum",    color = Color3.fromRGB(200, 200, 200), chance = 45 },
	Rare      = { name = "Raro",     color = Color3.fromRGB(80,  150, 255), chance = 28 },
	Epic      = { name = "Épico",    color = Color3.fromRGB(180, 80,  255), chance = 16 },
	Legendary = { name = "Lendário", color = Color3.fromRGB(255, 200, 0),   chance = 8  },
	Mythic    = { name = "Mítico",   color = Color3.fromRGB(255, 60,  60),  chance = 3  },
}

BrainrotData.ITEMS = {
	-- COMUM (45%)
	{ id = 1,  name = "Tralalero Tralala",      rarity = "Common",    aura = 10    },
	{ id = 2,  name = "Bombardiro Crocodilo",   rarity = "Common",    aura = 15    },
	{ id = 3,  name = "Brrr Brrr Patapim",      rarity = "Common",    aura = 12    },
	{ id = 4,  name = "Tung Tung Sahur",         rarity = "Common",    aura = 18    },
	{ id = 5,  name = "Frigo Camelo",            rarity = "Common",    aura = 20    },
	{ id = 6,  name = "Gatto Panceri",           rarity = "Common",    aura = 11    },
	{ id = 7,  name = "Pinguino Atlantico",      rarity = "Common",    aura = 14    },
	-- RARO (28%)
	{ id = 8,  name = "Cappuccino Assassino",    rarity = "Rare",      aura = 75    },
	{ id = 9,  name = "Lirilì Larilà",           rarity = "Rare",      aura = 90    },
	{ id = 10, name = "Glorbo Fruttodrillo",     rarity = "Rare",      aura = 100   },
	{ id = 11, name = "Ballerina Cappuccina",    rarity = "Rare",      aura = 120   },
	{ id = 12, name = "Tortellino Marino",       rarity = "Rare",      aura = 85    },
	{ id = 13, name = "Cannoli Esplosivo",       rarity = "Rare",      aura = 95    },
	-- ÉPICO (16%)
	{ id = 14, name = "Tracotocatocatoco",       rarity = "Epic",      aura = 300   },
	{ id = 15, name = "Bombombini Gusini",       rarity = "Epic",      aura = 350   },
	{ id = 16, name = "Vaca Saturno Saturnita",  rarity = "Epic",      aura = 400   },
	{ id = 17, name = "Falco Alpino Terribile",  rarity = "Epic",      aura = 380   },
	{ id = 18, name = "Coccodrillo Cosmico",     rarity = "Epic",      aura = 420   },
	-- LENDÁRIO (8%)
	{ id = 19, name = "Trippi Troppi",           rarity = "Legendary", aura = 1200  },
	{ id = 20, name = "La Vaca Saturno",         rarity = "Legendary", aura = 1500  },
	{ id = 21, name = "Il Cacciatore",           rarity = "Legendary", aura = 2000  },
	{ id = 22, name = "Dragone Maccheroni",      rarity = "Legendary", aura = 1800  },
	-- MÍTICO (3%)
	{ id = 23, name = "ULTRA BRAINROT SIGMA",    rarity = "Mythic",    aura = 8000  },
	{ id = 24, name = "Il Goblin dei Memi",      rarity = "Mythic",    aura = 10000 },
	{ id = 25, name = "Omega Tralalero",         rarity = "Mythic",    aura = 12000 },
}

-- Ranks por Aura total acumulada
BrainrotData.RANKS = {
	{ min = 0,        name = "🥚 Noob",           color = Color3.fromRGB(180, 180, 180) },
	{ min = 500,      name = "💀 Iniciante",       color = Color3.fromRGB(120, 220, 120) },
	{ min = 5000,     name = "🧠 Brainrot Boy",    color = Color3.fromRGB(80,  160, 255) },
	{ min = 25000,    name = "⚡ Sigma",           color = Color3.fromRGB(180, 80,  255) },
	{ min = 100000,   name = "👑 Brainrot King",   color = Color3.fromRGB(255, 200, 0)   },
	{ min = 500000,   name = "🔥 Brainrot God",    color = Color3.fromRGB(255, 100, 0)   },
	{ min = 2000000,  name = "☠️ ULTRA SIGMA GOD", color = Color3.fromRGB(255, 50,  50)  },
}

-- Ordem de raridade para o roll: mais raro primeiro
local RARITY_ORDER = { "Mythic", "Legendary", "Epic", "Rare", "Common" }

function BrainrotData.GetRandom()
	local roll = math.random(1, 100)
	local cumulative = 0
	local selectedRarity = "Common"
	for _, rarity in ipairs(RARITY_ORDER) do
		cumulative = cumulative + BrainrotData.RARITIES[rarity].chance
		if roll <= cumulative then
			selectedRarity = rarity
			break
		end
	end
	local pool = {}
	for _, item in ipairs(BrainrotData.ITEMS) do
		if item.rarity == selectedRarity then
			table.insert(pool, item)
		end
	end
	if #pool == 0 then return BrainrotData.ITEMS[1] end
	return pool[math.random(1, #pool)]
end

function BrainrotData.GetById(id)
	for _, item in ipairs(BrainrotData.ITEMS) do
		if item.id == id then return item end
	end
end

function BrainrotData.GetRank(aura)
	local result = BrainrotData.RANKS[1]
	for _, rank in ipairs(BrainrotData.RANKS) do
		if aura >= rank.min then result = rank end
	end
	return result
end

return BrainrotData
