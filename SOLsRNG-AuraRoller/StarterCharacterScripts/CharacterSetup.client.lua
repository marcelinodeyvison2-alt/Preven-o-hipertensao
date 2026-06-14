-- CharacterSetup.client.lua (LocalScript em StarterCharacterScripts)
-- Configura o personagem do jogador: velocidade, efeitos iniciais

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer
local character   = script.Parent
local humanoid    = character:WaitForChild("Humanoid")
local hrp         = character:WaitForChild("HumanoidRootPart")

-- Ajusta velocidade de caminhada
humanoid.WalkSpeed = 18

-- Cria efeito de "aura de spawn" momentaneo
task.spawn(function()
    task.wait(0.1)

    local spawnLight = Instance.new("PointLight")
    spawnLight.Color      = Color3.fromRGB(100, 200, 255)
    spawnLight.Brightness = 5
    spawnLight.Range      = 25
    spawnLight.Parent     = hrp

    local tween = TweenService:Create(spawnLight,
        TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Brightness = 0 }
    )
    tween:Play()
    tween.Completed:Connect(function() spawnLight:Destroy() end)
end)

-- Billboard de nome customizado (mostra nome do jogador com estilo)
local billboard = Instance.new("BillboardGui")
billboard.Size        = UDim2.new(0, 180, 0, 25)
billboard.StudsOffset = Vector3.new(0, 2.2, 0)
billboard.AlwaysOnTop = false
billboard.Parent      = hrp

local nameLabel = Instance.new("TextLabel")
nameLabel.Size               = UDim2.new(1, 0, 1, 0)
nameLabel.BackgroundTransparency = 1
nameLabel.Text               = localPlayer.Name
nameLabel.TextColor3         = Color3.new(1, 1, 1)
nameLabel.TextStrokeColor3   = Color3.new(0, 0, 0)
nameLabel.TextStrokeTransparency = 0
nameLabel.Font               = Enum.Font.GothamBold
nameLabel.TextScaled         = true
nameLabel.Parent             = billboard
