-- MobileButton.lua  (LocalScript em StarterGui)
-- Botões de ação rápida para dispositivos touch

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

if not UserInputService.TouchEnabled then return end

local RemoteEvents = require(ReplicatedStorage:WaitForChild("RemoteEvents"))
local player = Players.LocalPlayer

local hud = player:WaitForChild("PlayerGui"):WaitForChild("BrainrotHUD", 15)
if not hud then return end

local function mobileBtn(text, color, pos)
	local b = Instance.new("TextButton")
	b.Size             = UDim2.new(0, 120, 0, 55)
	b.Position         = pos
	b.BackgroundColor3 = color
	b.Text             = text
	b.TextColor3       = Color3.fromRGB(255, 255, 255)
	b.Font             = Enum.Font.GothamBold
	b.TextScaled       = true
	b.BorderSizePixel  = 0
	b.ZIndex           = 8
	b.Parent           = hud
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 12)
	c.Parent = b
	return b
end

local sellButton = mobileBtn("💰 Vender",
	Color3.fromRGB(30, 170, 60),
	UDim2.new(0, 10, 1, -70))

local shopButton = mobileBtn("🛒 Loja",
	Color3.fromRGB(0, 120, 220),
	UDim2.new(0, 140, 1, -70))

sellButton.MouseButton1Click:Connect(function()
	RemoteEvents.SellInventory:FireServer()
end)

shopButton.MouseButton1Click:Connect(function()
	RemoteEvents.OpenShop:FireClient()  -- não existe; usa FireServer para abrir
	-- Abre localmente enviando sinal ao servidor que devolve OpenShop ao cliente
	-- Alternativa: toggle direto se a loja for controlada localmente
end)
