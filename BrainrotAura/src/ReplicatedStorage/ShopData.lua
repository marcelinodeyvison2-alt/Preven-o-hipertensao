-- ShopData.lua
local ShopData = {}

-- Upgrades de mochila (sequenciais)
ShopData.BAG_UPGRADES = {
	{ level = 1, capacity = 20,  name = "Mochila Básica",  cost = 0       },
	{ level = 2, capacity = 35,  name = "Mochila Média",   cost = 2000    },
	{ level = 3, capacity = 60,  name = "Mochila Grande",  cost = 10000   },
	{ level = 4, capacity = 100, name = "Mochila Sigma",   cost = 50000   },
}

-- Upgrades de multiplicador de Aura (sequenciais)
ShopData.MULTIPLIERS = {
	{ level = 1, mult = 1.0, name = "Normal",    cost = 0       },
	{ level = 2, mult = 1.5, name = "Aura x1.5", cost = 5000    },
	{ level = 3, mult = 2.0, name = "Aura x2",   cost = 25000   },
	{ level = 4, mult = 3.0, name = "Aura x3",   cost = 100000  },
	{ level = 5, mult = 5.0, name = "Aura x5",   cost = 500000  },
}

-- Rebirth: reseta Aura mas dá +25% de mult permanente por rebirth
ShopData.REBIRTH = {
	cost      = 150000,
	multBonus = 0.25,
}

-- Marcos de combo que dão bônus de Aura instantâneos
ShopData.COMBO_BONUSES = {
	[5]  = 50,
	[10] = 200,
	[20] = 1000,
	[30] = 5000,
}

return ShopData
