-- RemoteEvents.lua  (v2)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function getOrCreate(class, name)
	local existing = ReplicatedStorage:FindFirstChild(name)
	if existing then return existing end
	local obj = Instance.new(class)
	obj.Name   = name
	obj.Parent = ReplicatedStorage
	return obj
end

return {
	-- Coleta e inventário
	ItemCollected     = getOrCreate("RemoteEvent",    "ItemCollected"),
	UpdateInventory   = getOrCreate("RemoteEvent",    "UpdateInventory"),
	-- Venda
	SellInventory     = getOrCreate("RemoteEvent",    "SellInventory"),
	SellEffect        = getOrCreate("RemoteEvent",    "SellEffect"),
	-- HUD e notificações
	UpdateHUD         = getOrCreate("RemoteEvent",    "UpdateHUD"),
	ShowNotification  = getOrCreate("RemoteEvent",    "ShowNotification"),
	-- Leaderboard
	UpdateLeaderboard = getOrCreate("RemoteEvent",    "UpdateLeaderboard"),
	-- Shop e rebirth
	BuyItem           = getOrCreate("RemoteEvent",    "BuyItem"),
	DoRebirth         = getOrCreate("RemoteEvent",    "DoRebirth"),
	OpenShop          = getOrCreate("RemoteEvent",    "OpenShop"),
	-- Combo
	ComboHit          = getOrCreate("RemoteEvent",    "ComboHit"),
	-- RemoteFunction para dados iniciais
	GetPlayerData     = getOrCreate("RemoteFunction", "GetPlayerData"),
}
