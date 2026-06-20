-- BrainrotData.lua
-- Todos os itens brainrot disponíveis no jogo

local BrainrotData = {}

BrainrotData.RARITIES = {
	Common    = { name = "Comum",    color = Color3.fromRGB(200, 200, 200), chance = 50  },
	Rare      = { name = "Raro",     color = Color3.fromRGB(80,  150, 255), chance = 28  },
	Epic      = { name = "Épico",    color = Color3.fromRGB(180, 80,  255), chance = 14  },
	Legendary = { name = "Lendário", color = Color3.fromRGB(255, 200, 0),   chance = 6   },
	Mythic    = { name = "Mítico",   color = Color3.fromRGB(255, 60,  60),  chance = 2   },
}

-- Lista de brainrots com nome, rarity e valor em Aura
BrainrotData.ITEMS = {
	-- COMUM
	{ id = 1,  name = "Tralalero Tralala",    rarity = "Common",    aura = 10   },
	{ id = 2,  name = "Bombardiro Crocodilo", rarity = "Common",    aura = 15   },
	{ id = 3,  name = "Brrr Brrr Patapim",   rarity = "Common",    aura = 12   },
	{ id = 4,  name = "Tung Tung Sahur",      rarity = "Common",    aura = 18   },
	{ id = 5,  name = "Frigo Camelo",         rarity = "Common",    aura = 20   },

	-- RARO
	{ id = 6,  name = "Cappuccino Assassino", rarity = "Rare",      aura = 75   },
	{ id = 7,  name = "Lirilì Larilà",        rarity = "Rare",      aura = 90   },
	{ id = 8,  name = "Glorbo Fruttodrillo",  rarity = "Rare",      aura = 100  },
	{ id = 9,  name = "Ballerina Cappuccina", rarity = "Rare",      aura = 120  },

	-- ÉPICO
	{ id = 10, name = "Tracotocatocatoco",    rarity = "Epic",      aura = 300  },
	{ id = 11, name = "Bombombini Gusini",    rarity = "Epic",      aura = 350  },
	{ id = 12, name = "Vaca Saturno Saturnita",rarity = "Epic",     aura = 400  },

	-- LENDÁRIO
	{ id = 13, name = "Trippi Troppi",        rarity = "Legendary", aura = 1200 },
	{ id = 14, name = "La Vaca Saturno",      rarity = "Legendary", aura = 1500 },
	{ id = 15, name = "Il Cacciatore",        rarity = "Legendary", aura = 2000 },

	-- MÍTICO
	{ id = 16, name = "ULTRA BRAINROT SIGMA", rarity = "Mythic",   aura = 8000 },
	{ id = 17, name = "Il Goblin dei Memi",   rarity = "Mythic",   aura = 10000 },
}

-- Retorna item aleatório baseado nas chances de raridade
function BrainrotData.GetRandom()
	local roll = math.random(1, 100)
	local cumulative = 0
	local selectedRarity = "Common"

	-- Ordem: Mythic > Legendary > Epic > Rare > Common
	local order = { "Mythic", "Legendary", "Epic", "Rare", "Common" }
	local remaining = 100
	for _, rarity in ipairs(order) do
		local chance = BrainrotData.RARITIES[rarity].chance
		cumulative = cumulative + chance
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

	if #pool == 0 then
		return BrainrotData.ITEMS[1]
	end
	return pool[math.random(1, #pool)]
end

function BrainrotData.GetById(id)
	for _, item in ipairs(BrainrotData.ITEMS) do
		if item.id == id then
			return item
		end
	end
	return nil
end

return BrainrotData
