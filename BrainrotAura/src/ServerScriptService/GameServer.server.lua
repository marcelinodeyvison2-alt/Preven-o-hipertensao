-- GameServer.server.lua  (v2)
-- Sistema completo: spawn, coleta, venda, shop, rebirth, combo, rank, leaderboard

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService  = game:GetService("DataStoreService")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local Workspace         = game:GetService("Workspace")

local BrainrotData = require(ReplicatedStorage:WaitForChild("BrainrotData"))
local ShopData     = require(ReplicatedStorage:WaitForChild("ShopData"))
local RemoteEvents = require(ReplicatedStorage:WaitForChild("RemoteEvents"))

local GameStore = DataStoreService:GetDataStore("BrainrotAura_v2")

-- ─────────────────────────────────────────────
-- CONFIGURAÇÃO
-- ─────────────────────────────────────────────
local CFG = {
	SPAWN_RADIUS         = 130,
	MAX_ITEMS            = 35,
	SPAWN_INTERVAL       = 3.5,
	ITEM_LIFETIME        = 45,
	SELL_ZONE_POS        = Vector3.new(0,   0.5, -70),
	SELL_ZONE_SIZE       = Vector3.new(18,  1,   18),
	SHOP_ZONE_POS        = Vector3.new(35,  0.5, -70),
	SHOP_ZONE_SIZE       = Vector3.new(18,  1,   18),
	COMBO_WINDOW         = 5,    -- segundos
	LEADERBOARD_INTERVAL = 12,
	SAVE_INTERVAL        = 120,
}

-- ─────────────────────────────────────────────
-- DADOS DOS JOGADORES
-- ─────────────────────────────────────────────
local playerData = {}   -- [userId] = { ... }

local function defaultData()
	return {
		aura      = 0,
		rebirths  = 0,
		multLevel = 1,
		bagLevel  = 1,
		inventory = {},
		stats     = { totalCollected = 0, totalSold = 0 },
		combos    = {},   -- timestamps dos últimos itens coletados
	}
end

local function getData(player)
	return playerData[player.UserId]
end

-- ─────────────────────────────────────────────
-- CÁLCULOS
-- ─────────────────────────────────────────────
local function getEffectiveMult(data)
	local base   = ShopData.MULTIPLIERS[data.multLevel].mult
	local rebirth = data.rebirths * ShopData.REBIRTH.multBonus
	return base + rebirth
end

local function getBagCap(data)
	return ShopData.BAG_UPGRADES[data.bagLevel].capacity
end

local function countInv(data)
	local n = 0
	for _, e in ipairs(data.inventory) do n += e.qty end
	return n
end

local function addToInv(data, itemId)
	for _, e in ipairs(data.inventory) do
		if e.id == itemId then e.qty += 1; return end
	end
	table.insert(data.inventory, { id = itemId, qty = 1 })
end

-- Registra uma coleta no sistema de combo e retorna a contagem atual
local function recordCombo(data)
	local now = tick()
	table.insert(data.combos, now)
	local fresh = {}
	for _, t in ipairs(data.combos) do
		if now - t <= CFG.COMBO_WINDOW then
			table.insert(fresh, t)
		end
	end
	data.combos = fresh
	return #fresh
end

-- ─────────────────────────────────────────────
-- LEADERSTATS & BILLBOARD
-- ─────────────────────────────────────────────
local function createLeaderstats(player)
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	ls.Parent = player

	local a = Instance.new("IntValue")
	a.Name   = "Aura"
	a.Value  = 0
	a.Parent = ls

	local r = Instance.new("IntValue")
	r.Name   = "Rebirths"
	r.Value  = 0
	r.Parent = ls
end

local billboards = {}  -- [userId] = { rankLabel, auraLabel }

local function setupBillboard(player, character)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if not root then return end

	local bb = Instance.new("BillboardGui")
	bb.Name         = "AuraBillboard"
	bb.Size         = UDim2.new(0, 240, 0, 65)
	bb.StudsOffset  = Vector3.new(0, 3.8, 0)
	bb.AlwaysOnTop  = false
	bb.Adornee      = root
	bb.Parent       = character

	local rankLbl = Instance.new("TextLabel")
	rankLbl.Name                 = "RankLabel"
	rankLbl.Size                 = UDim2.new(1, 0, 0.45, 0)
	rankLbl.BackgroundTransparency = 1
	rankLbl.Font                 = Enum.Font.GothamBold
	rankLbl.TextScaled           = true
	rankLbl.TextStrokeTransparency = 0
	rankLbl.Parent               = bb

	local auraLbl = Instance.new("TextLabel")
	auraLbl.Name                 = "AuraLabel"
	auraLbl.Size                 = UDim2.new(1, 0, 0.55, 0)
	auraLbl.Position             = UDim2.new(0, 0, 0.45, 0)
	auraLbl.BackgroundTransparency = 1
	auraLbl.Font                 = Enum.Font.Gotham
	auraLbl.TextColor3           = Color3.fromRGB(255, 215, 0)
	auraLbl.TextStrokeTransparency = 0
	auraLbl.TextScaled           = true
	auraLbl.Parent               = bb

	billboards[player.UserId] = { rank = rankLbl, aura = auraLbl }
end

local function refreshBillboard(player)
	local data   = getData(player)
	local labels = billboards[player.UserId]
	if not data or not labels then return end

	local rank = BrainrotData.GetRank(data.aura)
	labels.rank.Text       = rank.name
	labels.rank.TextColor3 = rank.color

	local suffix = data.rebirths > 0 and (" 🔁" .. data.rebirths) or ""
	labels.aura.Text = "✨ " .. tostring(data.aura) .. " Aura" .. suffix
end

-- ─────────────────────────────────────────────
-- HUD UPDATE
-- ─────────────────────────────────────────────
local function fireHUD(player, extra)
	local data = getData(player)
	if not data then return end
	local rank = BrainrotData.GetRank(data.aura)
	local payload = {
		aura          = data.aura,
		rebirths      = data.rebirths,
		multLevel     = data.multLevel,
		bagLevel      = data.bagLevel,
		effectiveMult = getEffectiveMult(data),
		rank          = { name = rank.name, color = rank.color },
		stats         = data.stats,
		invCount      = countInv(data),
		bagCap        = getBagCap(data),
	}
	if extra then
		for k, v in pairs(extra) do payload[k] = v end
	end
	RemoteEvents.UpdateHUD:FireClient(player, payload)
end

-- ─────────────────────────────────────────────
-- SAVE / LOAD
-- ─────────────────────────────────────────────
local function saveData(player)
	local data = getData(player)
	if not data then return end
	pcall(function()
		GameStore:SetAsync(tostring(player.UserId), {
			aura      = data.aura,
			rebirths  = data.rebirths,
			multLevel = data.multLevel,
			bagLevel  = data.bagLevel,
			stats     = data.stats,
		})
	end)
end

local function loadData(player)
	local saved
	pcall(function()
		saved = GameStore:GetAsync(tostring(player.UserId))
	end)

	local data = defaultData()
	if saved then
		data.aura      = saved.aura      or 0
		data.rebirths  = saved.rebirths  or 0
		data.multLevel = math.clamp(saved.multLevel or 1, 1, #ShopData.MULTIPLIERS)
		data.bagLevel  = math.clamp(saved.bagLevel  or 1, 1, #ShopData.BAG_UPGRADES)
		if saved.stats then data.stats = saved.stats end
	end
	playerData[player.UserId] = data

	local ls = player:FindFirstChild("leaderstats")
	if ls then
		ls.Aura.Value     = data.aura
		ls.Rebirths.Value = data.rebirths
	end
	fireHUD(player)
end

-- ─────────────────────────────────────────────
-- VENDA
-- ─────────────────────────────────────────────
local sellDebounce = {}

local function sellInventory(player)
	if sellDebounce[player.UserId] then return end
	sellDebounce[player.UserId] = true
	task.delay(1.5, function() sellDebounce[player.UserId] = nil end)

	local data = getData(player)
	if not data or #data.inventory == 0 then
		RemoteEvents.ShowNotification:FireClient(player, "Mochila vazia!", Color3.fromRGB(255, 150, 0))
		return
	end

	local rawAura = 0
	for _, entry in ipairs(data.inventory) do
		local item = BrainrotData.GetById(entry.id)
		if item then rawAura += item.aura * entry.qty end
	end

	local mult       = getEffectiveMult(data)
	local totalAura  = math.floor(rawAura * mult)

	data.inventory = {}
	data.aura     += totalAura
	data.stats.totalSold += 1
	player.leaderstats.Aura.Value = data.aura

	RemoteEvents.UpdateInventory:FireClient(player, data.inventory)
	RemoteEvents.SellEffect:FireClient(player, totalAura, mult)
	RemoteEvents.ShowNotification:FireClient(player,
		"💰 +" .. totalAura .. " ✨ Aura" .. (mult > 1 and (" (mult x" .. string.format("%.2g", mult) .. ")") or ""),
		Color3.fromRGB(80, 255, 120)
	)

	refreshBillboard(player)
	fireHUD(player)
	task.spawn(saveData, player)
end

-- ─────────────────────────────────────────────
-- SHOP
-- ─────────────────────────────────────────────
local function buyBag(player)
	local data = getData(player)
	if not data then return end
	local next = ShopData.BAG_UPGRADES[data.bagLevel + 1]
	if not next then
		RemoteEvents.ShowNotification:FireClient(player, "🎒 Mochila já está no máximo!", Color3.fromRGB(255, 150, 0))
		return
	end
	if data.aura < next.cost then
		RemoteEvents.ShowNotification:FireClient(player,
			"Precisa de ✨" .. next.cost .. " Aura!  (falta " .. (next.cost - data.aura) .. ")",
			Color3.fromRGB(255, 80, 80))
		return
	end
	data.aura     -= next.cost
	data.bagLevel += 1
	player.leaderstats.Aura.Value = data.aura
	fireHUD(player)
	RemoteEvents.ShowNotification:FireClient(player, "✅ " .. next.name .. " comprada! (" .. next.capacity .. " slots)", Color3.fromRGB(80, 255, 120))
	task.spawn(saveData, player)
end

local function buyMult(player)
	local data = getData(player)
	if not data then return end
	local next = ShopData.MULTIPLIERS[data.multLevel + 1]
	if not next then
		RemoteEvents.ShowNotification:FireClient(player, "⚡ Multiplicador já está no máximo!", Color3.fromRGB(255, 150, 0))
		return
	end
	if data.aura < next.cost then
		RemoteEvents.ShowNotification:FireClient(player,
			"Precisa de ✨" .. next.cost .. " Aura!  (falta " .. (next.cost - data.aura) .. ")",
			Color3.fromRGB(255, 80, 80))
		return
	end
	data.aura      -= next.cost
	data.multLevel += 1
	player.leaderstats.Aura.Value = data.aura
	fireHUD(player)
	RemoteEvents.ShowNotification:FireClient(player, "✅ " .. next.name .. " ativado!", Color3.fromRGB(80, 255, 120))
	task.spawn(saveData, player)
end

local function doRebirth(player)
	local data = getData(player)
	if not data then return end
	if data.aura < ShopData.REBIRTH.cost then
		RemoteEvents.ShowNotification:FireClient(player,
			"Precisa de ✨" .. ShopData.REBIRTH.cost .. " para renascer! (falta " .. (ShopData.REBIRTH.cost - data.aura) .. ")",
			Color3.fromRGB(255, 80, 80))
		return
	end
	data.aura      = 0
	data.rebirths += 1
	data.multLevel = 1
	data.bagLevel  = 1
	data.inventory = {}

	local ls = player:FindFirstChild("leaderstats")
	if ls then
		ls.Aura.Value     = 0
		ls.Rebirths.Value = data.rebirths
	end
	RemoteEvents.UpdateInventory:FireClient(player, data.inventory)
	fireHUD(player)
	RemoteEvents.ShowNotification:FireClient(player,
		"🔁 REBIRTH #" .. data.rebirths .. "! +" .. (ShopData.REBIRTH.multBonus * 100) .. "% Aura Permanente!",
		Color3.fromRGB(255, 80, 255))
	refreshBillboard(player)
	task.spawn(saveData, player)
end

-- ─────────────────────────────────────────────
-- SPAWN DE ITENS NO MAPA
-- ─────────────────────────────────────────────
local spawnedItems  = {}
local itemStartData = {}   -- [part] = { baseCF, startTime }

-- Loop único de animação para todos os itens (mais eficiente)
RunService.Heartbeat:Connect(function()
	local now = tick()
	for _, part in ipairs(spawnedItems) do
		if part.Parent then
			local d = itemStartData[part]
			if d then
				local t = now - d.startTime
				part.CFrame = d.baseCF
					* CFrame.new(0, math.sin(t * 2.2) * 0.45, 0)
					* CFrame.Angles(0, t * 1.2, 0)
			end
		end
	end
end)

local function spawnItem()
	if #spawnedItems >= CFG.MAX_ITEMS then return end

	local item   = BrainrotData.GetRandom()
	local rarity = BrainrotData.RARITIES[item.rarity]

	local angle = math.random() * 2 * math.pi
	local dist  = math.random(12, CFG.SPAWN_RADIUS)
	local pos   = Vector3.new(math.cos(angle) * dist, 1.6, math.sin(angle) * dist)

	local part = Instance.new("Part")
	part.Name         = "Brainrot_" .. item.id
	part.Shape        = Enum.PartType.Ball
	part.Size         = Vector3.new(2.2, 2.2, 2.2)
	part.Material     = Enum.Material.Neon
	part.Color        = rarity.color
	part.Anchored     = true
	part.CanCollide   = false
	part.CastShadow   = false
	part.CFrame       = CFrame.new(pos)

	-- Dados do item
	local idVal = Instance.new("IntValue")
	idVal.Name   = "ItemId"
	idVal.Value  = item.id
	idVal.Parent = part

	-- Billboard
	local bb = Instance.new("BillboardGui")
	bb.Size        = UDim2.new(0, 190, 0, 62)
	bb.StudsOffset = Vector3.new(0, 2.8, 0)
	bb.Parent      = part

	local n = Instance.new("TextLabel")
	n.Size                 = UDim2.new(1, 0, 0.52, 0)
	n.BackgroundTransparency = 1
	n.Text                 = item.name
	n.TextColor3           = rarity.color
	n.TextStrokeTransparency = 0
	n.Font                 = Enum.Font.GothamBold
	n.TextScaled           = true
	n.Parent               = bb

	local v = Instance.new("TextLabel")
	v.Size                 = UDim2.new(1, 0, 0.48, 0)
	v.Position             = UDim2.new(0, 0, 0.52, 0)
	v.BackgroundTransparency = 1
	v.Text                 = "✨ +" .. item.aura .. "  [" .. rarity.name .. "]"
	v.TextColor3           = Color3.fromRGB(255, 255, 255)
	v.TextStrokeTransparency = 0
	v.Font                 = Enum.Font.Gotham
	v.TextScaled           = true
	v.Parent               = bb

	-- ProximityPrompt (pressionar E para coletar)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText     = "Coletar"
	prompt.ObjectText     = item.name
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = 8
	prompt.HoldDuration   = 0
	prompt.Parent         = part

	part.Parent = Workspace
	table.insert(spawnedItems, part)
	itemStartData[part] = { baseCF = part.CFrame, startTime = tick() }

	local collected = false

	prompt.Triggered:Connect(function(player)
		if collected then return end
		local data = getData(player)
		if not data then return end

		if countInv(data) >= getBagCap(data) then
			RemoteEvents.ShowNotification:FireClient(player,
				"🎒 Mochila cheia! (" .. getBagCap(data) .. "/" .. getBagCap(data) .. ") — Venda primeiro!",
				Color3.fromRGB(255, 80, 80))
			return
		end

		collected = true

		-- Remove do mapa
		for i, v2 in ipairs(spawnedItems) do
			if v2 == part then table.remove(spawnedItems, i); break end
		end
		itemStartData[part] = nil
		part:Destroy()

		addToInv(data, item.id)
		data.stats.totalCollected += 1

		-- Combo
		local comboCount = recordCombo(data)
		local bonus = ShopData.COMBO_BONUSES[comboCount]
		if bonus then
			data.aura += bonus
			player.leaderstats.Aura.Value = data.aura
			RemoteEvents.ShowNotification:FireClient(player,
				"🔥 COMBO x" .. comboCount .. "! +" .. bonus .. " ✨ Aura Bônus!",
				Color3.fromRGB(255, 165, 0))
			refreshBillboard(player)
		end
		RemoteEvents.ComboHit:FireClient(player, comboCount)

		RemoteEvents.UpdateInventory:FireClient(player, data.inventory)
		RemoteEvents.ItemCollected:FireClient(player, item, comboCount)
		fireHUD(player)
	end)

	-- Auto-destruir após lifetime
	task.delay(CFG.ITEM_LIFETIME, function()
		if not collected and part.Parent then
			collected = true
			for i, v2 in ipairs(spawnedItems) do
				if v2 == part then table.remove(spawnedItems, i); break end
			end
			itemStartData[part] = nil
			part:Destroy()
		end
	end)
end

-- ─────────────────────────────────────────────
-- ZONAS (VENDA E LOJA)
-- ─────────────────────────────────────────────
local function buildZone(name, pos, size, color, title, sub)
	local zone = Instance.new("Part")
	zone.Name         = name
	zone.Size         = size
	zone.CFrame       = CFrame.new(pos)
	zone.Anchored     = true
	zone.CanCollide   = true   -- Touched funciona
	zone.Transparency = 0.55
	zone.Material     = Enum.Material.Neon
	zone.Color        = color
	zone.Parent       = Workspace

	-- Bordas decorativas nos 4 cantos
	local corners = {
		Vector3.new( size.X/2,  2, -size.Z/2),
		Vector3.new(-size.X/2,  2, -size.Z/2),
		Vector3.new( size.X/2,  2,  size.Z/2),
		Vector3.new(-size.X/2,  2,  size.Z/2),
	}
	for _, offset in ipairs(corners) do
		local pillar = Instance.new("Part")
		pillar.Size      = Vector3.new(0.5, 4, 0.5)
		pillar.CFrame    = CFrame.new(pos + offset)
		pillar.Anchored  = true
		pillar.CanCollide= false
		pillar.Material  = Enum.Material.Neon
		pillar.Color     = color
		pillar.Parent    = Workspace
	end

	local bb = Instance.new("BillboardGui")
	bb.Size        = UDim2.new(0, 320, 0, 110)
	bb.StudsOffset = Vector3.new(0, 6, 0)
	bb.Adornee     = zone
	bb.Parent      = zone

	local t1 = Instance.new("TextLabel")
	t1.Size = UDim2.new(1, 0, 0.52, 0)
	t1.BackgroundTransparency = 1
	t1.Text = title
	t1.TextColor3 = Color3.fromRGB(255, 255, 255)
	t1.TextStrokeTransparency = 0
	t1.Font = Enum.Font.GothamBold
	t1.TextScaled = true
	t1.Parent = bb

	local t2 = Instance.new("TextLabel")
	t2.Size = UDim2.new(1, 0, 0.48, 0)
	t2.Position = UDim2.new(0, 0, 0.52, 0)
	t2.BackgroundTransparency = 1
	t2.Text = sub
	t2.TextColor3 = Color3.fromRGB(210, 210, 210)
	t2.TextStrokeTransparency = 0
	t2.Font = Enum.Font.Gotham
	t2.TextScaled = true
	t2.Parent = bb

	TweenService:Create(zone, TweenInfo.new(1.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ Transparency = 0.8 }):Play()

	return zone
end

-- ─────────────────────────────────────────────
-- LEADERBOARD
-- ─────────────────────────────────────────────
local function broadcastLeaderboard()
	local entries = {}
	for _, plr in ipairs(Players:GetPlayers()) do
		local d = getData(plr)
		if d then
			local rank = BrainrotData.GetRank(d.aura)
			table.insert(entries, { name = plr.Name, aura = d.aura, rankName = rank.name, rebirths = d.rebirths })
		end
	end
	table.sort(entries, function(a, b) return a.aura > b.aura end)
	-- Máximo 8 entradas
	while #entries > 8 do table.remove(entries) end
	for _, plr in ipairs(Players:GetPlayers()) do
		RemoteEvents.UpdateLeaderboard:FireClient(plr, entries)
	end
end

-- ─────────────────────────────────────────────
-- LIFECYCLE DOS JOGADORES
-- ─────────────────────────────────────────────
local function onPlayerAdded(player)
	createLeaderstats(player)
	task.spawn(loadData, player)

	player.CharacterAdded:Connect(function(character)
		task.delay(0.6, function()
			setupBillboard(player, character)
			task.wait(0.1)
			refreshBillboard(player)
		end)
	end)
end

local function onPlayerRemoving(player)
	saveData(player)
	billboards[player.UserId] = nil
	playerData[player.UserId] = nil
end

-- ─────────────────────────────────────────────
-- REMOTE EVENTS
-- ─────────────────────────────────────────────
RemoteEvents.SellInventory.OnServerEvent:Connect(function(player)
	local char = player.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local sz = Workspace:FindFirstChild("SellZone")
	if sz and (root.Position - sz.Position).Magnitude > 22 then
		RemoteEvents.ShowNotification:FireClient(player, "Chegue perto da zona amarela para vender!", Color3.fromRGB(255, 80, 80))
		return
	end
	sellInventory(player)
end)

RemoteEvents.BuyItem.OnServerEvent:Connect(function(player, itemType)
	if itemType == "bag"  then buyBag(player)
	elseif itemType == "mult" then buyMult(player)
	end
end)

RemoteEvents.DoRebirth.OnServerEvent:Connect(function(player)
	doRebirth(player)
end)

RemoteEvents.GetPlayerData.OnServerInvoke = function(player)
	local d = getData(player)
	if not d then return {} end
	return {
		aura      = d.aura,
		rebirths  = d.rebirths,
		multLevel = d.multLevel,
		bagLevel  = d.bagLevel,
		stats     = d.stats,
	}
end

-- ─────────────────────────────────────────────
-- INICIALIZAÇÃO
-- ─────────────────────────────────────────────
local sellZone = buildZone("SellZone", CFG.SELL_ZONE_POS, CFG.SELL_ZONE_SIZE,
	Color3.fromRGB(255, 200, 0), "💰 VENDER BRAINROT", "Entre aqui para vender tudo!")

local shopZone = buildZone("ShopZone", CFG.SHOP_ZONE_POS, CFG.SHOP_ZONE_SIZE,
	Color3.fromRGB(0, 140, 255), "🛒 LOJA", "Entre para abrir a loja!")

-- Sell zone: auto-vende ao entrar
local autoSellDebounce = {}
sellZone.Touched:Connect(function(hit)
	if hit.Name ~= "HumanoidRootPart" then return end
	local plr = Players:GetPlayerFromCharacter(hit.Parent)
	if not plr or autoSellDebounce[plr.UserId] then return end
	autoSellDebounce[plr.UserId] = true
	task.delay(2, function() autoSellDebounce[plr.UserId] = nil end)
	sellInventory(plr)
end)

-- Shop zone: abre loja ao entrar
local shopDebounce = {}
shopZone.Touched:Connect(function(hit)
	if hit.Name ~= "HumanoidRootPart" then return end
	local plr = Players:GetPlayerFromCharacter(hit.Parent)
	if not plr or shopDebounce[plr.UserId] then return end
	shopDebounce[plr.UserId] = true
	task.delay(3, function() shopDebounce[plr.UserId] = nil end)
	RemoteEvents.OpenShop:FireClient(plr)
end)

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Spawn inicial
for _ = 1, 20 do spawnItem() end

-- Loop de spawn
task.spawn(function()
	while true do
		task.wait(CFG.SPAWN_INTERVAL)
		spawnItem()
	end
end)

-- Leaderboard periódico
task.spawn(function()
	while true do
		task.wait(CFG.LEADERBOARD_INTERVAL)
		broadcastLeaderboard()
	end
end)

-- Auto-save periódico
task.spawn(function()
	while true do
		task.wait(CFG.SAVE_INTERVAL)
		for _, plr in ipairs(Players:GetPlayers()) do
			task.spawn(saveData, plr)
		end
	end
end)

print("[BrainrotAura v2] Servidor iniciado!")
