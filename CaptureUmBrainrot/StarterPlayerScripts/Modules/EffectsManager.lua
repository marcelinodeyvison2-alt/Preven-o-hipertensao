-- EffectsManager.lua (client ModuleScript)
-- Plays sounds and visual effects for capture, sell, and notifications.

local TweenService = game:GetService("TweenService")
local GameConfig   = require(game.ReplicatedStorage.Modules.GameConfig)

local EffectsManager = {}

-- ── Sound playback ────────────────────────────────────────────────────────────

local soundCache = {}

local function getSound(assetId)
    if soundCache[assetId] then return soundCache[assetId] end
    local s = Instance.new("Sound")
    s.SoundId   = assetId
    s.RollOffMaxDistance = 0
    s.Parent    = game.SoundService or workspace
    soundCache[assetId] = s
    return s
end

function EffectsManager.playSound(soundKey)
    local id = GameConfig.Sounds[soundKey]
    if not id then return end
    local s = getSound(id)
    s:Play()
end

function EffectsManager.playCaptureSound(rarityKey)
    local soundKey = GameConfig.RarityCaptureSound[rarityKey] or "CaptureComum"
    EffectsManager.playSound(soundKey)
end

-- ── Screen flash ──────────────────────────────────────────────────────────────

local flashFrame
local function getFlash()
    if flashFrame and flashFrame.Parent then return flashFrame end
    local sg = Instance.new("ScreenGui")
    sg.Name            = "FlashGui"
    sg.ResetOnSpawn    = false
    sg.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
    sg.Parent          = game.Players.LocalPlayer:WaitForChild("PlayerGui")

    local f = Instance.new("Frame")
    f.Size               = UDim2.new(1, 0, 1, 0)
    f.BackgroundColor3   = Color3.new(1, 1, 1)
    f.BackgroundTransparency = 1
    f.ZIndex             = 50
    f.Parent             = sg
    flashFrame = f
    return f
end

function EffectsManager.screenFlash(color, duration)
    local f = getFlash()
    f.BackgroundColor3   = color or Color3.new(1, 1, 1)
    f.BackgroundTransparency = 0.2
    TweenService:Create(f, TweenInfo.new(duration or 0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = 1
    }):Play()
end

function EffectsManager.flashForRarity(rarityKey)
    local rarityData = GameConfig.RarityColors[rarityKey]
    if rarityData then
        EffectsManager.screenFlash(rarityData, 0.5)
    end
end

return EffectsManager
