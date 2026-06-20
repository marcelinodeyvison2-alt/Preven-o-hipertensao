-- RemoteEvents.lua
-- Cria e exporta todos os RemoteEvents/Functions do jogo

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function getOrCreate(class, name)
	local existing = ReplicatedStorage:FindFirstChild(name)
	if existing then return existing end
	local obj = Instance.new(class)
	obj.Name = name
	obj.Parent = ReplicatedStorage
	return obj
end

local RemoteEvents = {
	-- Server → Client: notifica item coletado
	ItemCollected    = getOrCreate("RemoteEvent",    "ItemCollected"),
	-- Server → Client: atualiza inventário completo
	UpdateInventory  = getOrCreate("RemoteEvent",    "UpdateInventory"),
	-- Client → Server: vender inventário
	SellInventory    = getOrCreate("RemoteEvent",    "SellInventory"),
	-- Server → Client: efeito de venda (partículas / som)
	SellEffect       = getOrCreate("RemoteEvent",    "SellEffect"),
	-- Server → Client: notificação flutuante
	ShowNotification = getOrCreate("RemoteEvent",    "ShowNotification"),
	-- Client → Server: pedir dados do jogador (aura total, rank)
	GetPlayerData    = getOrCreate("RemoteFunction", "GetPlayerData"),
}

return RemoteEvents
