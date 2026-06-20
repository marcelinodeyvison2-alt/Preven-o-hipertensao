-- MobileButton.lua  (LocalScript em StarterGui)
-- Botão de venda visível apenas em dispositivos touch

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

if not UserInputService.TouchEnabled then return end

local RemoteEvents = require(ReplicatedStorage:WaitForChild("RemoteEvents"))
local player = Players.LocalPlayer
local gui    = player:WaitForChild("PlayerGui")

-- Espera a HUD principal carregar
local hud = gui:WaitForChild("BrainrotHUD", 10)
if not hud then return end

-- Botão grande para mobile (canto inferior esquerdo)
local btn = Instance.new("TextButton")
btn.Name = "MobileSell"
btn.Size = UDim2.new(0, 130, 0, 60)
btn.Position = UDim2.new(0, 10, 1, -80)
btn.BackgroundColor3 = Color3.fromRGB(50, 200, 80)
btn.Text = "💰 VENDER"
btn.TextColor3 = Color3.fromRGB(255, 255, 255)
btn.Font = Enum.Font.GothamBold
btn.TextScaled = true
btn.BorderSizePixel = 0
btn.ZIndex = 5
btn.Parent = hud

local c = Instance.new("UICorner")
c.CornerRadius = UDim.new(0, 12)
c.Parent = btn

btn.MouseButton1Click:Connect(function()
	RemoteEvents.SellInventory:FireServer()
end)
