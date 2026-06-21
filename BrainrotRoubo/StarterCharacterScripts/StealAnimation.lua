-- LocalScript: StarterCharacterScripts > StealAnimation
-- Toca uma animação ao apertar [E] para roubar (feature 2)

local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local character = script.Parent
local hum       = character:WaitForChild("Humanoid")
local animator  = hum:WaitForChild("Animator")

-- Animação de "acenar/alcançar" (Wave stock do Roblox)
local anim = Instance.new("Animation")
anim.AnimationId = "rbxassetid://507770239"

local track = nil
local playing = false

task.defer(function()
    local ok, t = pcall(function() return animator:LoadAnimation(anim) end)
    if ok and t then
        track = t
        track.Priority = Enum.AnimationPriority.Action
        track.Looped   = false
    end
end)

local function playSteal()
    if not track then return end
    if playing then return end
    playing = true
    track:Play()
    track.Stopped:Wait()
    playing = false
end

-- Detecta tecla E (ou toque no botão mobile via BindableEvent futuro)
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.E then
        playSteal()
    end
end)
