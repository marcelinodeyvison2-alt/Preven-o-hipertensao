-- GameServer.server.lua
-- Script principal do servidor: spawna brainrots, gerencia vendas e persiste Aura

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService  = game:GetService("DataStoreService")
local RunService        = game:GetService("RunService")
local Workspace         = game:GetService("Workspace")
local TweenService      = game:GetService("TweenService")

local BrainrotData = require(ReplicatedStorage:WaitForChild("BrainrotData"))
local RemoteEvents = require(ReplicatedStorage:WaitForChild("RemoteEvents"))

local AuraStore = DataStoreService:GetDataStore("BrainrotAura_v1")

-- ─────────────────────────────────────────────
-- CONFIGURAÇÕES
-- ─────────────────────────────────────────────
local CONFIG = {
	SPAWN_RADIUS      = 120,   -- raio de spawn dos brainrots
	MAX_ITEMS_MAP     = 30,    -- máximo de itens no mapa
	SPAWN_INTERVAL    = 4,     -- segundos entre spawns
	ITEM_LIFETIME     = 30,    -- segundos até o item desaparecer
	SELL_ZONE_SIZE    = Vector3.new(14, 4, 14),
	BAG_CAPACITY      = 20,    -- max itens no inventário
	SELL_ZONE_POS     = Vector3.new(0, 1, -60),
}

-- Inventários e auras em memória
local playerInventories = {}  -- [userId] = { {itemId, quantity}, ... }
local playerAuras       = {}  -- [userId] = number

local spawnedItems = {}  -- partes no mapa

-- ─────────────────────────────────────────────
-- FUNÇÕES UTILITÁRIAS
-- ─────────────────────────────────────────────
local function getAura(player)
	return playerAuras[player.UserId] or 0
end

local function setAura(player, value)
	playerAuras[player.UserId] = value
	player.leaderstats.Aura.Value = value
end

local function getInventory(player)
	return playerInventories[player.UserId] or {}
end

local function countInventory(player)
	local inv = getInventory(player)
	local total = 0
	for _, entry in ipairs(inv) do
		total = total + entry.qty
	end
	return total
end

local function addToInventory(player, itemId)
	local inv = playerInventories[player.UserId]
	for _, entry in ipairs(inv) do
		if entry.id == itemId then
			entry.qty = entry.qty + 1
			return
		end
	end
	table.insert(inv, { id = itemId, qty = 1 })
end

local function syncInventory(player)
	RemoteEvents.UpdateInventory:FireClient(player, getInventory(player))
end

-- ─────────────────────────────────────────────
-- LEADERSTATS
-- ─────────────────────────────────────────────
local function createLeaderstats(player)
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	ls.Parent = player

	local aura = Instance.new("IntValue")
	aura.Name = "Aura"
	aura.Value = 0
	aura.Parent = ls
end

-- ─────────────────────────────────────────────
-- BILLBOARD AURA ACIMA DO PERSONAGEM
-- ─────────────────────────────────────────────
local function createAuraBillboard(character, auraValue)
	local humanoidRoot = character:WaitForChild("HumanoidRootPart", 10)
	if not humanoidRoot then return end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "AuraBillboard"
	billboard.Size = UDim2.new(0, 200, 0, 50)
	billboard.StudsOffset = Vector3.new(0, 3.5, 0)
	billboard.AlwaysOnTop = false
	billboard.Adornee = humanoidRoot
	billboard.Parent = character

	local label = Instance.new("TextLabel")
	label.Name = "AuraLabel"
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(255, 215, 0)
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Text = "✨ " .. tostring(auraValue) .. " Aura"
	label.Parent = billboard

	return label
end

-- ─────────────────────────────────────────────
-- ZONA DE VENDA
-- ─────────────────────────────────────────────
local function createSellZone()
	local zone = Instance.new("Part")
	zone.Name = "SellZone"
	zone.Size = CONFIG.SELL_ZONE_SIZE
	zone.Position = CONFIG.SELL_ZONE_POS
	zone.Anchored = true
	zone.CanCollide = false
	zone.Material = Enum.Material.Neon
	zone.BrickColor = BrickColor.new("Bright yellow")
	zone.Transparency = 0.4
	zone.Parent = Workspace

	-- Letreiro
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 300, 0, 100)
	billboard.StudsOffset = Vector3.new(0, 5, 0)
	billboard.Adornee = zone
	billboard.Parent = zone

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0.55, 0)
	title.BackgroundTransparency = 1
	title.Text = "💰 VENDER BRAINROT"
	title.TextColor3 = Color3.fromRGB(255, 230, 0)
	title.TextStrokeTransparency = 0
	title.Font = Enum.Font.GothamBold
	title.TextScaled = true
	title.Parent = billboard

	local sub = Instance.new("TextLabel")
	sub.Size = UDim2.new(1, 0, 0.45, 0)
	sub.Position = UDim2.new(0, 0, 0.55, 0)
	sub.BackgroundTransparency = 1
	sub.Text = "Entre na zona para vender!"
	sub.TextColor3 = Color3.fromRGB(255, 255, 255)
	sub.TextStrokeTransparency = 0
	sub.Font = Enum.Font.Gotham
	sub.TextScaled = true
	sub.Parent = billboard

	-- Animação de hover na zona
	local tween = TweenService:Create(zone,
		TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ Transparency = 0.7 }
	)
	tween:Play()

	return zone
end

-- ─────────────────────────────────────────────
-- SPAWN DE BRAINROT NO MAPA
-- ─────────────────────────────────────────────
local function spawnBrainrotItem()
	if #spawnedItems >= CONFIG.MAX_ITEMS_MAP then return end

	local item = BrainrotData.GetRandom()
	local rarityInfo = BrainrotData.RARITIES[item.rarity]

	local angle = math.random() * 2 * math.pi
	local dist  = math.random(10, CONFIG.SPAWN_RADIUS)
	local px    = math.cos(angle) * dist
	local pz    = math.sin(angle) * dist

	local part = Instance.new("Part")
	part.Name = "Brainrot_" .. item.id
	part.Size = Vector3.new(2, 2, 2)
	part.Position = Vector3.new(px, 1.5, pz)
	part.Anchored = false
	part.CanCollide = true
	part.Shape = Enum.PartType.Ball
	part.Material = Enum.Material.Neon
	part.Color = rarityInfo.color
	part.CastShadow = true

	-- Tag com dados
	local idVal = Instance.new("IntValue")
	idVal.Name = "ItemId"
	idVal.Value = item.id
	idVal.Parent = part

	-- Letreiro flutuante
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 160, 0, 55)
	bb.StudsOffset = Vector3.new(0, 2.5, 0)
	bb.AlwaysOnTop = false
	bb.Parent = part

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0.6, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = item.name
	nameLabel.TextColor3 = rarityInfo.color
	nameLabel.TextStrokeTransparency = 0
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextScaled = true
	nameLabel.Parent = bb

	local auraLabel = Instance.new("TextLabel")
	auraLabel.Size = UDim2.new(1, 0, 0.4, 0)
	auraLabel.Position = UDim2.new(0, 0, 0.6, 0)
	auraLabel.BackgroundTransparency = 1
	auraLabel.Text = "✨ +" .. tostring(item.aura) .. " Aura  [" .. rarityInfo.name .. "]"
	auraLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	auraLabel.TextStrokeTransparency = 0
	auraLabel.Font = Enum.Font.Gotham
	auraLabel.TextScaled = true
	auraLabel.Parent = bb

	-- Rotação constante via BodyAngularVelocity
	local bav = Instance.new("BodyAngularVelocity")
	bav.AngularVelocity = Vector3.new(0, 2, 0)
	bav.MaxTorque = Vector3.new(0, 400000, 0)
	bav.Parent = part

	part.Parent = Workspace
	table.insert(spawnedItems, part)

	-- Coleta por toque
	part.Touched:Connect(function(hit)
		local character = hit.Parent
		local player = Players:GetPlayerFromCharacter(character)
		if not player then return end
		if not part.Parent then return end  -- já coletado

		if countInventory(player) >= CONFIG.BAG_CAPACITY then
			RemoteEvents.ShowNotification:FireClient(player, "Mochila cheia! Venda seu brainrot primeiro.", Color3.fromRGB(255, 80, 80))
			return
		end

		-- Remove do mapa
		for i, v in ipairs(spawnedItems) do
			if v == part then table.remove(spawnedItems, i) break end
		end
		part:Destroy()

		addToInventory(player, item.id)
		syncInventory(player)
		RemoteEvents.ItemCollected:FireClient(player, item)
	end)

	-- Auto-destroy após lifetime
	task.delay(CONFIG.ITEM_LIFETIME, function()
		if part and part.Parent then
			for i, v in ipairs(spawnedItems) do
				if v == part then table.remove(spawnedItems, i) break end
			end
			part:Destroy()
		end
	end)
end

-- ─────────────────────────────────────────────
-- VENDA DE INVENTÁRIO
-- ─────────────────────────────────────────────
local function sellInventory(player)
	local inv = getInventory(player)
	if #inv == 0 then
		RemoteEvents.ShowNotification:FireClient(player, "Mochila vazia!", Color3.fromRGB(255, 150, 0))
		return
	end

	local totalAura = 0
	for _, entry in ipairs(inv) do
		local itemData = BrainrotData.GetById(entry.id)
		if itemData then
			totalAura = totalAura + itemData.aura * entry.qty
		end
	end

	playerInventories[player.UserId] = {}
	setAura(player, getAura(player) + totalAura)
	syncInventory(player)

	RemoteEvents.SellEffect:FireClient(player, totalAura)
	RemoteEvents.ShowNotification:FireClient(
		player,
		"Vendido! +" .. tostring(totalAura) .. " ✨ Aura!",
		Color3.fromRGB(80, 255, 120)
	)

	-- Atualiza billboard
	local character = player.Character
	if character then
		local bb = character:FindFirstChild("AuraBillboard")
		if bb then
			local lbl = bb:FindFirstChild("AuraLabel")
			if lbl then
				lbl.Text = "✨ " .. tostring(getAura(player)) .. " Aura"
			end
		end
	end

	-- Salva no DataStore
	task.spawn(function()
		pcall(function()
			AuraStore:SetAsync(tostring(player.UserId), getAura(player))
		end)
	end)
end

-- ─────────────────────────────────────────────
-- ZONA DE VENDA: detecta quem está dentro
-- ─────────────────────────────────────────────
local function setupSellZoneTouched(sellZone)
	local debounce = {}
	sellZone.Touched:Connect(function(hit)
		local character = hit.Parent
		local player = Players:GetPlayerFromCharacter(character)
		if not player then return end
		if debounce[player.UserId] then return end

		debounce[player.UserId] = true
		sellInventory(player)
		task.delay(2, function() debounce[player.UserId] = nil end)
	end)
end

-- ─────────────────────────────────────────────
-- ENTRADA DO JOGADOR
-- ─────────────────────────────────────────────
local function onPlayerAdded(player)
	playerInventories[player.UserId] = {}
	playerAuras[player.UserId] = 0

	createLeaderstats(player)

	-- Carrega aura salva
	task.spawn(function()
		local success, savedAura = pcall(function()
			return AuraStore:GetAsync(tostring(player.UserId))
		end)
		if success and savedAura then
			setAura(player, savedAura)
		end
	end)

	-- Billboard quando personagem aparecer
	player.CharacterAdded:Connect(function(character)
		task.delay(1, function()
			local lbl = createAuraBillboard(character, getAura(player))
			-- Atualiza rótulo em tempo real ao ganhar aura
			if player.leaderstats then
				player.leaderstats.Aura.Changed:Connect(function(v)
					if lbl and lbl.Parent then
						lbl.Text = "✨ " .. tostring(v) .. " Aura"
					end
				end)
			end
		end)
	end)
end

local function onPlayerRemoving(player)
	-- Salva ao sair
	task.spawn(function()
		pcall(function()
			AuraStore:SetAsync(tostring(player.UserId), getAura(player))
		end)
	end)
	playerInventories[player.UserId] = nil
	playerAuras[player.UserId]       = nil
end

-- ─────────────────────────────────────────────
-- REMOTE FUNCTION: dados do jogador
-- ─────────────────────────────────────────────
RemoteEvents.GetPlayerData.OnServerInvoke = function(player)
	return {
		aura      = getAura(player),
		inventory = getInventory(player),
	}
end

-- ─────────────────────────────────────────────
-- REMOTE EVENT: vender
-- ─────────────────────────────────────────────
RemoteEvents.SellInventory.OnServerEvent:Connect(function(player)
	-- Valida que o jogador está perto da sell zone
	local character = player.Character
	if not character then return end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local sellZone = Workspace:FindFirstChild("SellZone")
	if not sellZone then return end

	local dist = (root.Position - sellZone.Position).Magnitude
	if dist > 18 then
		RemoteEvents.ShowNotification:FireClient(player, "Chegue mais perto da zona de venda!", Color3.fromRGB(255, 80, 80))
		return
	end
	sellInventory(player)
end)

-- ─────────────────────────────────────────────
-- INICIALIZAÇÃO
-- ─────────────────────────────────────────────
local sellZone = createSellZone()
setupSellZoneTouched(sellZone)

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Spawna itens iniciais
for _ = 1, 15 do
	spawnBrainrotItem()
end

-- Loop de spawn
task.spawn(function()
	while true do
		task.wait(CONFIG.SPAWN_INTERVAL)
		spawnBrainrotItem()
	end
end)

print("[BrainrotAura] Servidor iniciado com sucesso!")
