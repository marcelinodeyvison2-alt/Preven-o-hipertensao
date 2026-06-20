-- GameClient.client.lua
-- HUD, inventário, notificações e efeitos visuais no cliente

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")

local player       = Players.LocalPlayer
local playerGui    = player:WaitForChild("PlayerGui")
local BrainrotData = require(ReplicatedStorage:WaitForChild("BrainrotData"))
local RemoteEvents = require(ReplicatedStorage:WaitForChild("RemoteEvents"))

-- Inventário local (espelho do servidor)
local localInventory = {}

-- ─────────────────────────────────────────────
-- CRIAÇÃO DA UI PRINCIPAL
-- ─────────────────────────────────────────────
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BrainrotHUD"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

-- ── PAINEL DO INVENTÁRIO (canto inferior direito) ──
local invFrame = Instance.new("Frame")
invFrame.Name = "InventoryPanel"
invFrame.Size = UDim2.new(0, 320, 0, 420)
invFrame.Position = UDim2.new(1, -330, 1, -430)
invFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 30)
invFrame.BackgroundTransparency = 0.2
invFrame.BorderSizePixel = 0
invFrame.Parent = screenGui

local invCorner = Instance.new("UICorner")
invCorner.CornerRadius = UDim.new(0, 12)
invCorner.Parent = invFrame

local invStroke = Instance.new("UIStroke")
invStroke.Color = Color3.fromRGB(255, 215, 0)
invStroke.Thickness = 2
invStroke.Parent = invFrame

-- Título do inventário
local invTitle = Instance.new("TextLabel")
invTitle.Size = UDim2.new(1, -10, 0, 40)
invTitle.Position = UDim2.new(0, 5, 0, 5)
invTitle.BackgroundTransparency = 1
invTitle.Text = "🎒 MOCHILA BRAINROT"
invTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
invTitle.Font = Enum.Font.GothamBold
invTitle.TextScaled = true
invTitle.Parent = invFrame

-- Contador de itens
local invCount = Instance.new("TextLabel")
invCount.Name = "InvCount"
invCount.Size = UDim2.new(1, -10, 0, 24)
invCount.Position = UDim2.new(0, 5, 0, 45)
invCount.BackgroundTransparency = 1
invCount.Text = "0 / 20 itens"
invCount.TextColor3 = Color3.fromRGB(200, 200, 200)
invCount.Font = Enum.Font.Gotham
invCount.TextScaled = true
invCount.Parent = invFrame

-- Lista scrollável
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "ItemList"
scrollFrame.Size = UDim2.new(1, -10, 1, -130)
scrollFrame.Position = UDim2.new(0, 5, 0, 74)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 5
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollFrame.Parent = invFrame

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 4)
listLayout.Parent = scrollFrame

-- Botão vender
local sellBtn = Instance.new("TextButton")
sellBtn.Name = "SellButton"
sellBtn.Size = UDim2.new(1, -10, 0, 44)
sellBtn.Position = UDim2.new(0, 5, 1, -50)
sellBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 80)
sellBtn.Text = "💰 VENDER TUDO (aproxime-se da zona)"
sellBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
sellBtn.Font = Enum.Font.GothamBold
sellBtn.TextScaled = true
sellBtn.BorderSizePixel = 0
sellBtn.Parent = invFrame

local sellCorner = Instance.new("UICorner")
sellCorner.CornerRadius = UDim.new(0, 8)
sellCorner.Parent = sellBtn

sellBtn.MouseButton1Click:Connect(function()
	RemoteEvents.SellInventory:FireServer()
end)

-- Efeito hover no botão
sellBtn.MouseEnter:Connect(function()
	TweenService:Create(sellBtn, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(80, 230, 100) }):Play()
end)
sellBtn.MouseLeave:Connect(function()
	TweenService:Create(sellBtn, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(50, 200, 80) }):Play()
end)

-- ── BARRA DE AURA (topo central) ──
local auraBar = Instance.new("Frame")
auraBar.Name = "AuraBar"
auraBar.Size = UDim2.new(0, 300, 0, 56)
auraBar.Position = UDim2.new(0.5, -150, 0, 10)
auraBar.BackgroundColor3 = Color3.fromRGB(15, 15, 30)
auraBar.BackgroundTransparency = 0.2
auraBar.BorderSizePixel = 0
auraBar.Parent = screenGui

local auraBarCorner = Instance.new("UICorner")
auraBarCorner.CornerRadius = UDim.new(0, 12)
auraBarCorner.Parent = auraBar

local auraBarStroke = Instance.new("UIStroke")
auraBarStroke.Color = Color3.fromRGB(255, 215, 0)
auraBarStroke.Thickness = 2
auraBarStroke.Parent = auraBar

local auraLabel = Instance.new("TextLabel")
auraLabel.Name = "AuraLabel"
auraLabel.Size = UDim2.new(1, 0, 1, 0)
auraLabel.BackgroundTransparency = 1
auraLabel.Text = "✨ 0 Aura"
auraLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
auraLabel.Font = Enum.Font.GothamBold
auraLabel.TextScaled = true
auraLabel.Parent = auraBar

-- ── ÁREA DE NOTIFICAÇÕES (centro da tela) ──
local notifHolder = Instance.new("Frame")
notifHolder.Name = "NotifHolder"
notifHolder.Size = UDim2.new(0, 400, 0, 300)
notifHolder.Position = UDim2.new(0.5, -200, 0.35, 0)
notifHolder.BackgroundTransparency = 1
notifHolder.BorderSizePixel = 0
notifHolder.Parent = screenGui

local notifLayout = Instance.new("UIListLayout")
notifLayout.SortOrder = Enum.SortOrder.LayoutOrder
notifLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
notifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
notifLayout.Padding = UDim.new(0, 6)
notifLayout.Parent = notifHolder

-- ─────────────────────────────────────────────
-- FUNÇÕES DE UI
-- ─────────────────────────────────────────────
local function updateAuraDisplay()
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		local auraVal = ls:FindFirstChild("Aura")
		if auraVal then
			auraLabel.Text = "✨ " .. tostring(auraVal.Value) .. " Aura"
		end
	end
end

local function showNotification(text, color)
	local notif = Instance.new("TextLabel")
	notif.Size = UDim2.new(1, 0, 0, 36)
	notif.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
	notif.BackgroundTransparency = 0.1
	notif.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	notif.Text = text
	notif.Font = Enum.Font.GothamBold
	notif.TextScaled = true
	notif.BorderSizePixel = 0
	notif.LayoutOrder = tick()
	notif.Parent = notifHolder

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = notif

	notif.Position = UDim2.new(0, 0, 0, 30)
	TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Position = UDim2.new(0, 0, 0, 0) }):Play()

	task.delay(2.5, function()
		TweenService:Create(notif, TweenInfo.new(0.4), { BackgroundTransparency = 1, TextTransparency = 1 }):Play()
		task.delay(0.45, function()
			notif:Destroy()
		end)
	end)
end

-- Cria uma linha de item no inventário
local function createItemRow(itemData, qty)
	local rarityInfo = BrainrotData.RARITIES[itemData.rarity]

	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -8, 0, 38)
	row.BackgroundColor3 = Color3.fromRGB(25, 25, 50)
	row.BackgroundTransparency = 0.1
	row.BorderSizePixel = 0
	row.LayoutOrder = itemData.id
	row.Parent = scrollFrame

	local rc = Instance.new("UICorner")
	rc.CornerRadius = UDim.new(0, 6)
	rc.Parent = row

	-- Dot colorido de raridade
	local dot = Instance.new("Frame")
	dot.Size = UDim2.new(0, 8, 0, 8)
	dot.Position = UDim2.new(0, 8, 0.5, -4)
	dot.BackgroundColor3 = rarityInfo.color
	dot.BorderSizePixel = 0
	dot.Parent = row
	local dc = Instance.new("UICorner")
	dc.CornerRadius = UDim.new(1, 0)
	dc.Parent = dot

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.65, -20, 1, 0)
	nameLabel.Position = UDim2.new(0, 24, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = itemData.name
	nameLabel.TextColor3 = rarityInfo.color
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextScaled = true
	nameLabel.Parent = row

	local qtyLabel = Instance.new("TextLabel")
	qtyLabel.Size = UDim2.new(0.18, 0, 1, 0)
	qtyLabel.Position = UDim2.new(0.67, 0, 0, 0)
	qtyLabel.BackgroundTransparency = 1
	qtyLabel.Text = "x" .. qty
	qtyLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	qtyLabel.Font = Enum.Font.Gotham
	qtyLabel.TextScaled = true
	qtyLabel.Parent = row

	local auraText = Instance.new("TextLabel")
	auraText.Size = UDim2.new(0.18, -4, 1, 0)
	auraText.Position = UDim2.new(0.84, 0, 0, 0)
	auraText.BackgroundTransparency = 1
	auraText.Text = "✨" .. tostring(itemData.aura * qty)
	auraText.TextColor3 = Color3.fromRGB(255, 215, 0)
	auraText.Font = Enum.Font.GothamBold
	auraText.TextScaled = true
	auraText.Parent = row

	return row
end

local function rebuildInventoryUI()
	for _, child in ipairs(scrollFrame:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	local totalItems = 0
	local totalAura  = 0
	for _, entry in ipairs(localInventory) do
		local data = BrainrotData.GetById(entry.id)
		if data then
			createItemRow(data, entry.qty)
			totalItems = totalItems + entry.qty
			totalAura  = totalAura + data.aura * entry.qty
		end
	end

	invCount.Text = totalItems .. " / 20 itens  |  Valor total: ✨" .. tostring(totalAura)
	sellBtn.Text = totalItems > 0
		and ("💰 VENDER TUDO (+✨" .. tostring(totalAura) .. " Aura)")
		or  "💰 VENDER TUDO (mochila vazia)"
end

-- ─────────────────────────────────────────────
-- EFEITO DE VENDA ("+500 Aura!" flutuando)
-- ─────────────────────────────────────────────
local function playSellEffect(amount)
	local bigLabel = Instance.new("TextLabel")
	bigLabel.Size = UDim2.new(0, 400, 0, 80)
	bigLabel.Position = UDim2.new(0.5, -200, 0.45, 0)
	bigLabel.BackgroundTransparency = 1
	bigLabel.Text = "+✨" .. tostring(amount) .. " AURA!"
	bigLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	bigLabel.TextStrokeTransparency = 0
	bigLabel.Font = Enum.Font.GothamBold
	bigLabel.TextScaled = true
	bigLabel.ZIndex = 10
	bigLabel.Parent = screenGui

	TweenService:Create(bigLabel, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, -200, 0.25, 0),
		TextTransparency = 1,
	}):Play()

	task.delay(1.6, function() bigLabel:Destroy() end)
end

-- ─────────────────────────────────────────────
-- REMOTE EVENTS → CLIENTE
-- ─────────────────────────────────────────────
RemoteEvents.UpdateInventory.OnClientEvent:Connect(function(inventory)
	localInventory = inventory
	rebuildInventoryUI()
end)

RemoteEvents.ItemCollected.OnClientEvent:Connect(function(item)
	local rarityInfo = BrainrotData.RARITIES[item.rarity]
	showNotification("+ " .. item.name .. " [" .. rarityInfo.name .. "] ✨+" .. item.aura, rarityInfo.color)
end)

RemoteEvents.SellEffect.OnClientEvent:Connect(function(amount)
	playSellEffect(amount)
	updateAuraDisplay()
end)

RemoteEvents.ShowNotification.OnClientEvent:Connect(function(text, color)
	showNotification(text, color)
end)

-- ─────────────────────────────────────────────
-- ATUALIZAR AURA DISPLAY EM TEMPO REAL
-- ─────────────────────────────────────────────
player:WaitForChild("leaderstats", 10)
local ls = player:FindFirstChild("leaderstats")
if ls then
	local auraVal = ls:WaitForChild("Aura", 10)
	if auraVal then
		auraVal.Changed:Connect(updateAuraDisplay)
		updateAuraDisplay()
	end
end

print("[BrainrotAura] Cliente carregado!")
