-- MainClient.client.lua
-- Entry point for all client-side logic.
-- Wires RemoteEvents to GUIManager and EffectsManager.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local character   = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Lazy-load modules (they initialise their GUI on require)
local GUIManager     = require(script.Parent.Modules.GUIManager)
local EffectsManager = require(script.Parent.Modules.EffectsManager)

local BrainrotConfig = require(ReplicatedStorage.Modules.BrainrotConfig)
local GameConfig     = require(ReplicatedStorage.Modules.GameConfig)

-- Wait for server setup
repeat task.wait(0.2) until ReplicatedStorage:GetAttribute("SetupComplete")

local remotes = ReplicatedStorage:WaitForChild("RemoteEvents")

local evCaptureSuccess  = remotes:WaitForChild("CaptureSuccess")
local evNotification    = remotes:WaitForChild("Notification")
local evSendInventory   = remotes:WaitForChild("SendInventory")
local evSendRanking     = remotes:WaitForChild("SendRanking")
local evAreaSuccess     = remotes:WaitForChild("AreaUnlockSuccess")

-- ── Current area detection (client-side, position-based) ──────────────────────

local function getAreaForPosition(pos)
    for _, areaKey in ipairs(BrainrotConfig.AreaOrder) do
        local aData = BrainrotConfig.Areas[areaKey]
        local aPos  = aData.Position
        local halfX = aData.Size.X / 2
        local halfZ = aData.Size.Z / 2
        if math.abs(pos.X - aPos.X) <= halfX and math.abs(pos.Z - aPos.Z) <= halfZ then
            return areaKey, aData.DisplayName
        end
    end
    return "CampoInicial", "Campo Inicial" -- fallback to hub / default
end

-- ── HUD area polling ──────────────────────────────────────────────────────────

local lastAura     = 0
local lastCount    = 0
local lastAreaName = ""

local function pollHUD()
    local ls = localPlayer:FindFirstChild("leaderstats")
    if ls then
        local aura  = ls:FindFirstChild("Aura")    and ls.Aura.Value    or 0
        local count = ls:FindFirstChild("Brainrots") and ls.Brainrots.Value or 0

        local pos = humanoidRootPart and humanoidRootPart.Position or Vector3.new(0,0,0)
        local _, areaName = getAreaForPosition(pos)

        if aura ~= lastAura or count ~= lastCount or areaName ~= lastAreaName then
            lastAura     = aura
            lastCount    = count
            lastAreaName = areaName
            GUIManager.updateHUD(aura, count, areaName)
        end
    end
end

RunService.Heartbeat:Connect(function()
    -- Throttle to every ~0.5s using an accumulator
end)

-- Simple timer-based poll
task.spawn(function()
    while true do
        task.wait(0.5)
        pcall(pollHUD)
    end
end)

-- Re-link root part after respawn
localPlayer.CharacterAdded:Connect(function(char)
    character = char
    humanoidRootPart = char:WaitForChild("HumanoidRootPart")
end)

-- ── Remote event handlers ─────────────────────────────────────────────────────

evCaptureSuccess.OnClientEvent:Connect(function(entry)
    GUIManager.showCapturePopup(entry)
    EffectsManager.playCaptureSound(entry.Rarity)
    EffectsManager.flashForRarity(entry.Rarity)
end)

evNotification.OnClientEvent:Connect(function(data)
    GUIManager.pushNotification(data)
    -- Play sound for error/success
    if data.type == GameConfig.NotifType.Error then
        EffectsManager.playSound("Error")
    elseif data.type == GameConfig.NotifType.Success then
        EffectsManager.playSound("Notification")
    end
end)

evSendInventory.OnClientEvent:Connect(function(inventory, unlockedAreas)
    GUIManager.updateInventory(inventory, unlockedAreas)
    -- Keep HUD count in sync (in case leaderstats lags)
    GUIManager.updateHUD(lastAura, #inventory, lastAreaName)
end)

evSendRanking.OnClientEvent:Connect(function(ranking)
    GUIManager.updateRanking(ranking)
end)

evAreaSuccess.OnClientEvent:Connect(function(areaKey, areaName)
    EffectsManager.playSound("AreaUnlock")
    EffectsManager.screenFlash(Color3.fromRGB(100, 255, 150), 0.8)
    GUIManager.pushNotification({
        type    = GameConfig.NotifType.Success,
        message = "🎉 " .. areaName .. " desbloqueada!",
    })
end)

-- ── Shop ProximityPrompt (Aura Shop in workspace) ────────────────────────────

local auraShop = workspace:WaitForChild("AuraShop", 15)
if auraShop then
    local shopPrompt = auraShop:FindFirstChildOfClass("ProximityPrompt")
    if shopPrompt then
        shopPrompt.Triggered:Connect(function()
            -- Toggle sell all via RemoteEvent
            remotes.SellBrainrots:FireServer(nil)
        end)
    end
end

print("[MainClient] Client ready.")
