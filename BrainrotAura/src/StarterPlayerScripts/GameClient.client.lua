-- GameClient.client.lua  (v2)
-- HUD completo: rank, aura, inventário, leaderboard, shop, combo, notificações

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local player       = Players.LocalPlayer
local playerGui    = player:WaitForChild("PlayerGui")
local BrainrotData = require(ReplicatedStorage:WaitForChild("BrainrotData"))
local ShopData     = require(ReplicatedStorage:WaitForChild("ShopData"))
local RemoteEvents = require(ReplicatedStorage:WaitForChild("RemoteEvents"))

local localInventory = {}
local currentHUD     = {}
local shopOpen       = false

-- ─────────────────────────────────────────────
-- HELPERS DE UI
-- ─────────────────────────────────────────────
local function corner(parent, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 10)
	c.Parent = parent
	return c
end

local function stroke(parent, color, thick)
	local s = Instance.new("UIStroke")
	s.Color     = color or Color3.fromRGB(255, 215, 0)
	s.Thickness = thick or 2
	s.Parent    = parent
	return s
end

local function label(parent, text, color, font, size, pos, halign)
	local l = Instance.new("TextLabel")
	l.Size                 = size or UDim2.new(1, 0, 1, 0)
	l.Position             = pos  or UDim2.new(0, 0, 0, 0)
	l.BackgroundTransparency = 1
	l.Text                 = text
	l.TextColor3           = color or Color3.fromRGB(255, 255, 255)
	l.Font                 = font  or Enum.Font.Gotham
	l.TextScaled           = true
	l.TextXAlignment       = halign or Enum.TextXAlignment.Center
	l.Parent               = parent
	return l
end

local function button(parent, text, color, size, pos)
	local b = Instance.new("TextButton")
	b.Size             = size or UDim2.new(1, 0, 0, 44)
	b.Position         = pos  or UDim2.new(0, 0, 0, 0)
	b.BackgroundColor3 = color
	b.Text             = text
	b.TextColor3       = Color3.fromRGB(255, 255, 255)
	b.Font             = Enum.Font.GothamBold
	b.TextScaled       = true
	b.BorderSizePixel  = 0
	b.Parent           = parent
	corner(b, 8)
	return b
end

local function panel(parent, size, pos, bgColor, bgTrans)
	local f = Instance.new("Frame")
	f.Size                 = size
	f.Position             = pos
	f.BackgroundColor3     = bgColor or Color3.fromRGB(12, 12, 28)
	f.BackgroundTransparency = bgTrans or 0.15
	f.BorderSizePixel      = 0
	f.Parent               = parent
	corner(f, 12)
	return f
end

-- ─────────────────────────────────────────────
-- SCREEN GUI
-- ─────────────────────────────────────────────
local gui = Instance.new("ScreenGui")
gui.Name            = "BrainrotHUD"
gui.ResetOnSpawn    = false
gui.IgnoreGuiInset  = true
gui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
gui.Parent          = playerGui

-- ─────────────────────────────────────────────
-- 1) BARRA SUPERIOR (rank + aura + mult)
-- ─────────────────────────────────────────────
local topBar = panel(gui, UDim2.new(0, 420, 0, 62), UDim2.new(0.5, -210, 0, 8))
stroke(topBar, Color3.fromRGB(255, 215, 0), 2)

local rankLabel = label(topBar, "🥚 Noob",
	Color3.fromRGB(180, 180, 180), Enum.Font.GothamBold,
	UDim2.new(1, -10, 0, 28), UDim2.new(0, 5, 0, 4))

local auraLabel = label(topBar, "✨ 0 Aura",
	Color3.fromRGB(255, 215, 0), Enum.Font.GothamBold,
	UDim2.new(0.55, -5, 0, 26), UDim2.new(0, 5, 0, 32))

local multLabel = label(topBar, "x1.0",
	Color3.fromRGB(160, 255, 160), Enum.Font.Gotham,
	UDim2.new(0.25, -5, 0, 26), UDim2.new(0.55, 0, 0, 32))
multLabel.TextXAlignment = Enum.TextXAlignment.Left

local rebirthLabel = label(topBar, "",
	Color3.fromRGB(255, 100, 255), Enum.Font.GothamBold,
	UDim2.new(0.2, -5, 0, 26), UDim2.new(0.8, 0, 0, 32))

-- Botões de ação no top bar
local topBtnShop = button(topBar, "🛒 LOJA",
	Color3.fromRGB(0, 120, 220),
	UDim2.new(0, 90, 0, 30), UDim2.new(1, -195, 0.5, -15))

local topBtnSell = button(topBar, "💰 VENDER",
	Color3.fromRGB(30, 170, 60),
	UDim2.new(0, 90, 0, 30), UDim2.new(1, -100, 0.5, -15))

-- ─────────────────────────────────────────────
-- 2) LEADERBOARD (lado esquerdo)
-- ─────────────────────────────────────────────
local lbPanel = panel(gui, UDim2.new(0, 220, 0, 300), UDim2.new(0, 8, 0.5, -150))
stroke(lbPanel, Color3.fromRGB(200, 200, 255), 1.5)

label(lbPanel, "🏆 RANKING",
	Color3.fromRGB(255, 215, 0), Enum.Font.GothamBold,
	UDim2.new(1, -8, 0, 28), UDim2.new(0, 4, 0, 4))

local lbScroll = Instance.new("ScrollingFrame")
lbScroll.Size                  = UDim2.new(1, -8, 1, -38)
lbScroll.Position              = UDim2.new(0, 4, 0, 34)
lbScroll.BackgroundTransparency = 1
lbScroll.BorderSizePixel       = 0
lbScroll.ScrollBarThickness    = 3
lbScroll.AutomaticCanvasSize   = Enum.AutomaticSize.Y
lbScroll.CanvasSize            = UDim2.new(0, 0, 0, 0)
lbScroll.Parent                = lbPanel
local lbLayout = Instance.new("UIListLayout")
lbLayout.Padding    = UDim.new(0, 3)
lbLayout.SortOrder  = Enum.SortOrder.LayoutOrder
lbLayout.Parent     = lbScroll

-- ─────────────────────────────────────────────
-- 3) INVENTÁRIO (canto inferior direito)
-- ─────────────────────────────────────────────
local invPanel = panel(gui, UDim2.new(0, 300, 0, 400), UDim2.new(1, -310, 1, -415))
stroke(invPanel, Color3.fromRGB(255, 215, 0), 2)

label(invPanel, "🎒 MOCHILA",
	Color3.fromRGB(255, 215, 0), Enum.Font.GothamBold,
	UDim2.new(1, -80, 0, 32), UDim2.new(0, 5, 0, 4))

local invCountLabel = label(invPanel, "0/20 itens  ✨0",
	Color3.fromRGB(180, 180, 180), Enum.Font.Gotham,
	UDim2.new(1, -10, 0, 22), UDim2.new(0, 5, 0, 36))

-- Botão minimizar inventário
local invToggleBtn = button(invPanel, "▼",
	Color3.fromRGB(50, 50, 80),
	UDim2.new(0, 30, 0, 24), UDim2.new(1, -36, 0, 8))
stroke(invToggleBtn, Color3.fromRGB(150, 150, 200), 1)

local invScroll = Instance.new("ScrollingFrame")
invScroll.Name                 = "InvScroll"
invScroll.Size                 = UDim2.new(1, -8, 1, -120)
invScroll.Position             = UDim2.new(0, 4, 0, 62)
invScroll.BackgroundTransparency = 1
invScroll.BorderSizePixel      = 0
invScroll.ScrollBarThickness   = 4
invScroll.AutomaticCanvasSize  = Enum.AutomaticSize.Y
invScroll.CanvasSize           = UDim2.new(0, 0, 0, 0)
invScroll.Parent               = invPanel
local invLayout = Instance.new("UIListLayout")
invLayout.Padding   = UDim.new(0, 3)
invLayout.SortOrder = Enum.SortOrder.LayoutOrder
invLayout.Parent    = invScroll

local sellBtn = button(invPanel, "💰 VENDER TUDO",
	Color3.fromRGB(30, 170, 60),
	UDim2.new(1, -10, 0, 44), UDim2.new(0, 5, 1, -50))

-- Minimizar inventário
local invMinimized = false
invToggleBtn.MouseButton1Click:Connect(function()
	invMinimized = not invMinimized
	invScroll.Visible = not invMinimized
	invCountLabel.Visible = not invMinimized
	sellBtn.Visible = not invMinimized
	invPanel.Size = invMinimized
		and UDim2.new(0, 300, 0, 46)
		or  UDim2.new(0, 300, 0, 400)
	invToggleBtn.Text = invMinimized and "▲" or "▼"
end)

-- ─────────────────────────────────────────────
-- 4) PAINEL DA LOJA (centro, toggle)
-- ─────────────────────────────────────────────
local shopPanel = panel(gui, UDim2.new(0, 460, 0, 520), UDim2.new(0.5, -230, 0.5, -270))
shopPanel.ZIndex = 10
shopPanel.Visible = false
stroke(shopPanel, Color3.fromRGB(0, 160, 255), 2.5)

label(shopPanel, "🛒 LOJA BRAINROT",
	Color3.fromRGB(80, 200, 255), Enum.Font.GothamBold,
	UDim2.new(1, -50, 0, 36), UDim2.new(0, 5, 0, 6))

local closeShopBtn = button(shopPanel, "✕",
	Color3.fromRGB(200, 50, 50),
	UDim2.new(0, 34, 0, 34), UDim2.new(1, -40, 0, 6))

-- Seção Mochila
label(shopPanel, "🎒 UPGRADES DE MOCHILA",
	Color3.fromRGB(255, 215, 0), Enum.Font.GothamBold,
	UDim2.new(1, -10, 0, 24), UDim2.new(0, 5, 0, 46))

local bagUpgFrame = Instance.new("Frame")
bagUpgFrame.Name              = "BagUpgrades"
bagUpgFrame.Size              = UDim2.new(1, -10, 0, 112)
bagUpgFrame.Position          = UDim2.new(0, 5, 0, 72)
bagUpgFrame.BackgroundTransparency = 1
bagUpgFrame.Parent            = shopPanel
local bagLayout = Instance.new("UIListLayout")
bagLayout.FillDirection = Enum.FillDirection.Horizontal
bagLayout.Padding = UDim.new(0, 6)
bagLayout.Parent = bagUpgFrame

-- Seção Multiplicador
label(shopPanel, "⚡ UPGRADES DE MULTIPLICADOR",
	Color3.fromRGB(255, 215, 0), Enum.Font.GothamBold,
	UDim2.new(1, -10, 0, 24), UDim2.new(0, 5, 0, 192))

local multUpgFrame = Instance.new("Frame")
multUpgFrame.Name              = "MultUpgrades"
multUpgFrame.Size              = UDim2.new(1, -10, 0, 112)
multUpgFrame.Position          = UDim2.new(0, 5, 0, 218)
multUpgFrame.BackgroundTransparency = 1
multUpgFrame.Parent            = shopPanel
local multLayout = Instance.new("UIListLayout")
multLayout.FillDirection = Enum.FillDirection.Horizontal
multLayout.Padding = UDim.new(0, 5)
multLayout.Parent = multUpgFrame

-- Rebirth
local divider = Instance.new("Frame")
divider.Size = UDim2.new(1, -10, 0, 2)
divider.Position = UDim2.new(0, 5, 0, 338)
divider.BackgroundColor3 = Color3.fromRGB(80, 80, 140)
divider.BorderSizePixel = 0
divider.Parent = shopPanel

local rebirthInfoLabel = label(shopPanel,
	"🔁 REBIRTH — Reseta Aura para 0 mas dá +25% mult permanente por rebirth",
	Color3.fromRGB(220, 150, 255), Enum.Font.Gotham,
	UDim2.new(1, -10, 0, 38), UDim2.new(0, 5, 0, 346))
rebirthInfoLabel.TextWrapped = true

local rebirthBtn = button(shopPanel, "🔁 REBIRTH  (✨150.000 Aura)",
	Color3.fromRGB(140, 0, 200),
	UDim2.new(1, -10, 0, 50), UDim2.new(0, 5, 0, 392))
rebirthBtn.ZIndex = 11

label(shopPanel, "⚠️ Mochila e multiplicador resetam no rebirth",
	Color3.fromRGB(200, 100, 100), Enum.Font.Gotham,
	UDim2.new(1, -10, 0, 22), UDim2.new(0, 5, 0, 446))

-- ─────────────────────────────────────────────
-- 5) ÁREA DE NOTIFICAÇÕES (centro)
-- ─────────────────────────────────────────────
local notifHolder = Instance.new("Frame")
notifHolder.Name              = "Notifs"
notifHolder.Size              = UDim2.new(0, 420, 0, 280)
notifHolder.Position          = UDim2.new(0.5, -210, 0.3, 0)
notifHolder.BackgroundTransparency = 1
notifHolder.ZIndex            = 20
notifHolder.Parent            = gui
local notifLayout2 = Instance.new("UIListLayout")
notifLayout2.HorizontalAlignment = Enum.HorizontalAlignment.Center
notifLayout2.VerticalAlignment  = Enum.VerticalAlignment.Bottom
notifLayout2.Padding            = UDim.new(0, 5)
notifLayout2.SortOrder          = Enum.SortOrder.LayoutOrder
notifLayout2.Parent             = notifHolder

-- ─────────────────────────────────────────────
-- FUNÇÕES DE RENDER
-- ─────────────────────────────────────────────
local function showNotif(text, color)
	local f = Instance.new("Frame")
	f.Size             = UDim2.new(1, 0, 0, 38)
	f.BackgroundColor3 = Color3.fromRGB(15, 15, 35)
	f.BackgroundTransparency = 0.08
	f.BorderSizePixel  = 0
	f.LayoutOrder      = tick()
	f.ZIndex           = 20
	f.Parent           = notifHolder
	corner(f, 8)
	stroke(f, color or Color3.fromRGB(255, 255, 255), 1.2)

	local l2 = label(f, text, color or Color3.fromRGB(255, 255, 255), Enum.Font.GothamBold)
	l2.ZIndex = 21

	TweenService:Create(f, TweenInfo.new(0.3, Enum.EasingStyle.Back),
		{ Position = UDim2.new(0, 0, 0, 0) }):Play()

	task.delay(2.8, function()
		TweenService:Create(f, TweenInfo.new(0.4),
			{ BackgroundTransparency = 1 }):Play()
		TweenService:Create(l2, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
		task.delay(0.45, function() f:Destroy() end)
	end)
end

local function showSellEffect(amount, mult)
	local lbl = Instance.new("TextLabel")
	lbl.Size                 = UDim2.new(0, 440, 0, 80)
	lbl.Position             = UDim2.new(0.5, -220, 0.42, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text                 = "+✨" .. tostring(amount) .. " AURA!"
		.. (mult and mult > 1 and (" (x" .. string.format("%.2g", mult) .. ")") or "")
	lbl.TextColor3           = Color3.fromRGB(255, 215, 0)
	lbl.TextStrokeTransparency = 0
	lbl.Font                 = Enum.Font.GothamBold
	lbl.TextScaled           = true
	lbl.ZIndex               = 30
	lbl.Parent               = gui

	TweenService:Create(lbl, TweenInfo.new(1.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, -220, 0.22, 0),
		TextTransparency = 1,
	}):Play()
	task.delay(1.7, function() lbl:Destroy() end)
end

-- Combo floating text
local comboLabel = Instance.new("TextLabel")
comboLabel.Size                 = UDim2.new(0, 300, 0, 60)
comboLabel.Position             = UDim2.new(0.5, -150, 0.6, 0)
comboLabel.BackgroundTransparency = 1
comboLabel.Text                 = ""
comboLabel.TextColor3           = Color3.fromRGB(255, 165, 0)
comboLabel.TextStrokeTransparency = 0
comboLabel.Font                 = Enum.Font.GothamBold
comboLabel.TextScaled           = true
comboLabel.ZIndex               = 15
comboLabel.Parent               = gui

local comboClearTask
local function updateComboDisplay(count)
	if comboClearTask then task.cancel(comboClearTask) end
	if count >= 3 then
		comboLabel.Text = count >= 20 and ("🔥 INSANO x" .. count .. "! 🔥")
			or count >= 10 and ("⚡ INCRÍVEL x" .. count .. "!")
			or count >= 5  and ("🎯 COMBO x" .. count .. "!")
			or ("✨ x" .. count)
		comboLabel.TextTransparency = 0
	else
		comboLabel.Text = ""
	end
	comboClearTask = task.delay(CFG_COMBO_FADE or 5, function()
		TweenService:Create(comboLabel, TweenInfo.new(0.6), { TextTransparency = 1 }):Play()
	end)
end
local CFG_COMBO_FADE = 5  -- segundos para o combo sumir

-- ─────────────────────────────────────────────
-- INVENTÁRIO UI
-- ─────────────────────────────────────────────
local function createInvRow(itemData, qty)
	local rarity = BrainrotData.RARITIES[itemData.rarity]

	local row = Instance.new("Frame")
	row.Size             = UDim2.new(1, -6, 0, 36)
	row.BackgroundColor3 = Color3.fromRGB(22, 22, 48)
	row.BackgroundTransparency = 0.1
	row.BorderSizePixel  = 0
	row.LayoutOrder      = itemData.id
	row.Parent           = invScroll
	corner(row, 6)

	-- Ponto de raridade
	local dot = Instance.new("Frame")
	dot.Size             = Vector3.new and UDim2.new(0, 8, 0, 8) or UDim2.new(0, 8, 0, 8)
	dot.Size             = UDim2.new(0, 8, 0, 8)
	dot.Position         = UDim2.new(0, 7, 0.5, -4)
	dot.BackgroundColor3 = rarity.color
	dot.BorderSizePixel  = 0
	dot.Parent           = row
	corner(dot, 4)

	local nameL = label(row, itemData.name, rarity.color, Enum.Font.GothamBold,
		UDim2.new(0.58, -18, 1, 0), UDim2.new(0, 22, 0, 0), Enum.TextXAlignment.Left)

	label(row, "x" .. qty, Color3.fromRGB(200, 200, 200), Enum.Font.Gotham,
		UDim2.new(0.18, 0, 1, 0), UDim2.new(0.6, 0, 0, 0))

	label(row, "✨" .. (itemData.aura * qty), Color3.fromRGB(255, 215, 0), Enum.Font.GothamBold,
		UDim2.new(0.22, -6, 1, 0), UDim2.new(0.78, 0, 0, 0))

	return row
end

local function rebuildInv()
	for _, c in ipairs(invScroll:GetChildren()) do
		if c:IsA("Frame") then c:Destroy() end
	end

	local totalItems = 0
	local totalAura  = 0
	for _, entry in ipairs(localInventory) do
		local d = BrainrotData.GetById(entry.id)
		if d then
			createInvRow(d, entry.qty)
			totalItems += entry.qty
			totalAura  += d.aura * entry.qty
		end
	end

	local cap = currentHUD.bagCap or 20
	invCountLabel.Text = totalItems .. "/" .. cap .. " itens  ✨" .. tostring(totalAura)
	sellBtn.Text = totalItems > 0
		and ("💰 VENDER TUDO (+✨" .. tostring(totalAura) .. ")")
		or  "💰 VENDER TUDO (vazio)"
end

-- ─────────────────────────────────────────────
-- LEADERBOARD UI
-- ─────────────────────────────────────────────
local function rebuildLeaderboard(entries)
	for _, c in ipairs(lbScroll:GetChildren()) do
		if c:IsA("Frame") then c:Destroy() end
	end

	local medals = { "🥇", "🥈", "🥉" }

	for i, entry in ipairs(entries) do
		local row = Instance.new("Frame")
		row.Size             = UDim2.new(1, -4, 0, 30)
		row.BackgroundColor3 = i == 1
			and Color3.fromRGB(50, 40, 10)
			or  Color3.fromRGB(20, 20, 45)
		row.BackgroundTransparency = i == 1 and 0.0 or 0.2
		row.BorderSizePixel  = 0
		row.LayoutOrder      = i
		row.Parent           = lbScroll
		corner(row, 5)

		local pos = medals[i] or ("#" .. i)
		label(row, pos,
			Color3.fromRGB(255, 215, 0), Enum.Font.GothamBold,
			UDim2.new(0, 28, 1, 0), UDim2.new(0, 2, 0, 0))

		local nameColor = entry.name == player.Name
			and Color3.fromRGB(100, 255, 150)
			or  Color3.fromRGB(220, 220, 220)
		label(row, entry.name, nameColor, Enum.Font.Gotham,
			UDim2.new(0.45, -28, 1, 0), UDim2.new(0, 30, 0, 0), Enum.TextXAlignment.Left)

		label(row, "✨" .. tostring(entry.aura),
			Color3.fromRGB(255, 215, 0), Enum.Font.GothamBold,
			UDim2.new(0.52, 0, 1, 0), UDim2.new(0.48, 0, 0, 0))
	end
end

-- ─────────────────────────────────────────────
-- SHOP UI
-- ─────────────────────────────────────────────
local shopBagBtns  = {}
local shopMultBtns = {}

local function buildShopButtons()
	-- Limpa
	for _, c in ipairs(bagUpgFrame:GetChildren()) do
		if c:IsA("TextButton") then c:Destroy() end
	end
	for _, c in ipairs(multUpgFrame:GetChildren()) do
		if c:IsA("TextButton") then c:Destroy() end
	end
	shopBagBtns  = {}
	shopMultBtns = {}

	local bagCap = math.floor((bagUpgFrame.AbsoluteSize.X - (3*6)) / 4)

	for _, upg in ipairs(ShopData.BAG_UPGRADES) do
		local owned = (currentHUD.bagLevel or 1) >= upg.level
		local isNext = (currentHUD.bagLevel or 1) + 1 == upg.level

		local b = Instance.new("TextButton")
		b.Size             = UDim2.new(0.22, -4, 1, 0)
		b.BackgroundColor3 = owned   and Color3.fromRGB(30, 80, 30)
			or isNext and Color3.fromRGB(20, 80, 160)
			or            Color3.fromRGB(40, 40, 70)
		b.TextColor3       = Color3.fromRGB(255, 255, 255)
		b.Font             = Enum.Font.GothamBold
		b.TextScaled       = true
		b.BorderSizePixel  = 0
		b.Text             = (owned and "✅ " or "") .. upg.name
			.. "\n" .. upg.capacity .. " slots"
			.. (upg.cost > 0 and ("\n✨" .. upg.cost) or "\n(Grátis)")
		b.ZIndex           = 11
		b.Parent           = bagUpgFrame
		corner(b, 8)
		if isNext then stroke(b, Color3.fromRGB(80, 180, 255), 1.5) end

		b.MouseButton1Click:Connect(function()
			RemoteEvents.BuyItem:FireServer("bag")
		end)
		table.insert(shopBagBtns, b)
	end

	for _, upg in ipairs(ShopData.MULTIPLIERS) do
		local owned = (currentHUD.multLevel or 1) >= upg.level
		local isNext = (currentHUD.multLevel or 1) + 1 == upg.level

		local b = Instance.new("TextButton")
		b.Size             = UDim2.new(0.185, -4, 1, 0)
		b.BackgroundColor3 = owned   and Color3.fromRGB(30, 80, 30)
			or isNext and Color3.fromRGB(100, 20, 160)
			or            Color3.fromRGB(40, 40, 70)
		b.TextColor3       = Color3.fromRGB(255, 255, 255)
		b.Font             = Enum.Font.GothamBold
		b.TextScaled       = true
		b.BorderSizePixel  = 0
		b.Text             = (owned and "✅ " or "") .. upg.name
			.. (upg.cost > 0 and ("\n✨" .. upg.cost) or "\n(Grátis)")
		b.ZIndex           = 11
		b.Parent           = multUpgFrame
		corner(b, 8)
		if isNext then stroke(b, Color3.fromRGB(200, 80, 255), 1.5) end

		b.MouseButton1Click:Connect(function()
			RemoteEvents.BuyItem:FireServer("mult")
		end)
		table.insert(shopMultBtns, b)
	end
end

local function toggleShop(open)
	shopOpen = open
	shopPanel.Visible = open
	if open then buildShopButtons() end
end

-- ─────────────────────────────────────────────
-- HUD UPDATE
-- ─────────────────────────────────────────────
local function applyHUD(data)
	currentHUD = data
	rankLabel.Text      = data.rank and data.rank.name or ""
	rankLabel.TextColor3 = data.rank and data.rank.color or Color3.fromRGB(180,180,180)
	auraLabel.Text      = "✨ " .. tostring(data.aura or 0) .. " Aura"
	multLabel.Text      = "x" .. string.format("%.2g", data.effectiveMult or 1)
	rebirthLabel.Text   = data.rebirths and data.rebirths > 0
		and ("🔁 x" .. data.rebirths) or ""
end

-- ─────────────────────────────────────────────
-- BOTÕES
-- ─────────────────────────────────────────────
sellBtn.MouseButton1Click:Connect(function()
	RemoteEvents.SellInventory:FireServer()
end)
topBtnSell.MouseButton1Click:Connect(function()
	RemoteEvents.SellInventory:FireServer()
end)
topBtnShop.MouseButton1Click:Connect(function()
	toggleShop(not shopOpen)
end)
closeShopBtn.MouseButton1Click:Connect(function()
	toggleShop(false)
end)
rebirthBtn.MouseButton1Click:Connect(function()
	RemoteEvents.DoRebirth:FireServer()
end)

-- Hover nos botões principais
for _, btn in ipairs({ sellBtn, topBtnSell }) do
	local base = Color3.fromRGB(30, 170, 60)
	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundColor3 = Color3.fromRGB(50, 200, 90) }):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundColor3 = base }):Play()
	end)
end

-- ─────────────────────────────────────────────
-- REMOTE EVENTS → CLIENTE
-- ─────────────────────────────────────────────
RemoteEvents.UpdateInventory.OnClientEvent:Connect(function(inv)
	localInventory = inv
	rebuildInv()
end)

RemoteEvents.ItemCollected.OnClientEvent:Connect(function(item, comboCount)
	local rarity = BrainrotData.RARITIES[item.rarity]
	showNotif("+ " .. item.name .. " [" .. rarity.name .. "] ✨+" .. item.aura, rarity.color)
	updateComboDisplay(comboCount or 0)
end)

RemoteEvents.SellEffect.OnClientEvent:Connect(function(amount, mult)
	showSellEffect(amount, mult)
end)

RemoteEvents.ShowNotification.OnClientEvent:Connect(function(text, color)
	showNotif(text, color)
end)

RemoteEvents.UpdateHUD.OnClientEvent:Connect(function(data)
	applyHUD(data)
	rebuildInv()
	if data.openShop then toggleShop(true) end
end)

RemoteEvents.UpdateLeaderboard.OnClientEvent:Connect(function(entries)
	rebuildLeaderboard(entries)
end)

RemoteEvents.ComboHit.OnClientEvent:Connect(function(count)
	updateComboDisplay(count)
end)

RemoteEvents.OpenShop.OnClientEvent:Connect(function()
	toggleShop(true)
end)

-- ─────────────────────────────────────────────
-- CARREGAMENTO INICIAL
-- ─────────────────────────────────────────────
task.spawn(function()
	local ls = player:WaitForChild("leaderstats", 15)
	if ls then
		local auraVal = ls:WaitForChild("Aura", 10)
		if auraVal then
			auraVal.Changed:Connect(function(v)
				auraLabel.Text = "✨ " .. v .. " Aura"
			end)
			auraLabel.Text = "✨ " .. auraVal.Value .. " Aura"
		end
	end
end)

print("[BrainrotAura v2] Cliente carregado!")
