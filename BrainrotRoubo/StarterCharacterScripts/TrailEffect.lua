-- LocalScript: StarterCharacterScripts > TrailEffect
-- Trilha de partículas com suporte a skins via TrailSkinUpdate remote

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local player   = Players.LocalPlayer
local char     = player.Character or player.CharacterAdded:Wait()
local humanoid = char:WaitForChild("Humanoid")
local rootPart = char:WaitForChild("HumanoidRootPart")

local GameConfig      = require(ReplicatedStorage:WaitForChild("GameConfig"))
local RemoteFolder    = ReplicatedStorage:WaitForChild("Remotes")
local TrailSkinUpdateRE = RemoteFolder:WaitForChild("TrailSkinUpdate")

-- Current skin state
local currentSkin = "default"

-- Attachment that persists; only the ParticleEmitter is rebuilt on skin change
local att = Instance.new("Attachment")
att.Position = Vector3.new(0, -2, 0)
att.Parent   = rootPart

local currentPE = nil

-- Build (or rebuild) the ParticleEmitter from three Color3 values
local function buildTrail(skinColors)
    if currentPE then
        currentPE:Destroy()
        currentPE = nil
    end

    local c1 = skinColors[1] or Color3.fromRGB(80,  200, 255)
    local c2 = skinColors[2] or Color3.fromRGB(160, 80,  255)
    local c3 = skinColors[3] or Color3.fromRGB(255, 80,  160)

    local pe = Instance.new("ParticleEmitter")
    pe.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   c1),
        ColorSequenceKeypoint.new(0.4, c2),
        ColorSequenceKeypoint.new(1,   c3),
    })
    pe.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0,   0.28),
        NumberSequenceKeypoint.new(0.5, 0.18),
        NumberSequenceKeypoint.new(1,   0),
    })
    pe.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.2),
        NumberSequenceKeypoint.new(1, 1),
    })
    pe.Lifetime       = NumberRange.new(0.35, 0.7)
    pe.Rate           = 0     -- controlled by loop
    pe.Speed          = NumberRange.new(0, 2)
    pe.SpreadAngle    = Vector2.new(180, 180)
    pe.RotSpeed       = NumberRange.new(-180, 180)
    pe.Rotation       = NumberRange.new(0, 360)
    pe.LightEmission  = 1
    pe.LightInfluence = 0
    pe.Parent         = att

    currentPE = pe
end

-- Resolve skin colors from GameConfig.TRAIL_SKINS by skin id
local function getSkinColors(skinId)
    if GameConfig.TRAIL_SKINS then
        for _, skin in ipairs(GameConfig.TRAIL_SKINS) do
            if skin.id == skinId then
                return skin.colors or {}
            end
        end
    end
    -- Fallback default colors
    return {
        Color3.fromRGB(80,  200, 255),
        Color3.fromRGB(160, 80,  255),
        Color3.fromRGB(255, 80,  160),
    }
end

-- Check if the player has trail unlocked (Rebirth >= 5 or Prestige >= 1)
local function hasTrailUnlocked()
    local ls = player:FindFirstChild("leaderstats")
    if not ls then return false end
    local rb = ls:FindFirstChild("Rebirths")
    local pr = ls:FindFirstChild("Prestígio")
    return (rb and rb.Value >= 5) or (pr and pr.Value >= 1)
end

-- Wait for unlock if not yet available
if not hasTrailUnlocked() then
    task.wait(5)
    if not hasTrailUnlocked() then
        -- Still not unlocked — keep listening but don't emit yet
        -- buildTrail will still be constructed so the remote works once unlocked
    end
end

-- Build initial trail with the default skin
buildTrail(getSkinColors(currentSkin))

-- Listen for skin changes from server
TrailSkinUpdateRE.OnClientEvent:Connect(function(skinId)
    currentSkin = skinId or "default"
    buildTrail(getSkinColors(currentSkin))
end)

-- Activate particles only while moving
RunService.RenderStepped:Connect(function()
    if not char.Parent then return end
    if not currentPE then return end
    currentPE.Rate = humanoid.MoveDirection.Magnitude > 0.1 and 30 or 0
end)
