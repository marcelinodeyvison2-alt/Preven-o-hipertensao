-- MainClient.client.lua
-- Entry point: wires all RemoteEvents to GUIManager and EffectsManager.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local character   = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local hrp         = character:WaitForChild("HumanoidRootPart")

local GUIManager     = require(script.Parent.Modules.GUIManager)
local EffectsManager = require(script.Parent.Modules.EffectsManager)
local BrainrotConfig = require(ReplicatedStorage.Modules.BrainrotConfig)
local GameConfig     = require(ReplicatedStorage.Modules.GameConfig)

repeat task.wait(0.2) until ReplicatedStorage:GetAttribute("SetupComplete")

local remotes = ReplicatedStorage:WaitForChild("RemoteEvents")

-- ── HUD: area detection by position ─────────────────────────────────────────

local function getAreaName(pos)
    for _, key in ipairs(BrainrotConfig.AreaOrder) do
        local ad = BrainrotConfig.Areas[key]
        local ap = ad.Position
        if math.abs(pos.X - ap.X) <= ad.Size.X/2 and math.abs(pos.Z - ap.Z) <= ad.Size.Z/2 then
            return ad.DisplayName
        end
    end
    return "Hub Central"
end

localPlayer.CharacterAdded:Connect(function(char)
    character = char; hrp = char:WaitForChild("HumanoidRootPart")
end)

local lastAura, lastCount, lastArea = 0, 0, ""
task.spawn(function()
    while true do
        task.wait(0.5)
        pcall(function()
            local ls    = localPlayer:FindFirstChild("leaderstats")
            local aura  = ls and ls:FindFirstChild("Aura")     and ls.Aura.Value     or 0
            local count = ls and ls:FindFirstChild("Brainrots") and ls.Brainrots.Value or 0
            local area  = hrp and getAreaName(hrp.Position) or lastArea
            if aura ~= lastAura or count ~= lastCount or area ~= lastArea then
                lastAura=aura; lastCount=count; lastArea=area
                GUIManager.updateHUD(aura, count, area)
            end
        end)
    end
end)

-- ── Core game events ──────────────────────────────────────────────────────────

remotes.CaptureSuccess.OnClientEvent:Connect(function(entry)
    GUIManager.showCapturePopup(entry)
    EffectsManager.playCaptureSound(entry.Rarity)
    EffectsManager.flashForRarity(entry.Rarity)
end)

remotes.Notification.OnClientEvent:Connect(function(data)
    GUIManager.pushNotification(data)
    if data.type == GameConfig.NotifType.Error then
        EffectsManager.playSound("Error")
    elseif data.type == GameConfig.NotifType.Success then
        EffectsManager.playSound("Notification")
    end
end)

remotes.SendInventory.OnClientEvent:Connect(function(inventory, unlockedAreas)
    GUIManager.updateInventory(inventory, unlockedAreas)
    GUIManager.updateHUD(lastAura, #inventory, lastArea)
end)

remotes.SendRanking.OnClientEvent:Connect(function(ranking)
    GUIManager.updateRanking(ranking)
end)

remotes.AreaUnlockSuccess.OnClientEvent:Connect(function(_, areaName)
    EffectsManager.playSound("AreaUnlock")
    EffectsManager.screenFlash(Color3.fromRGB(100,255,150), 0.8)
    GUIManager.pushNotification({ type=GameConfig.NotifType.Success,
        message="🎉 "..areaName.." desbloqueada!" })
end)

-- ── Pet events ────────────────────────────────────────────────────────────────

remotes.PetUpdate.OnClientEvent:Connect(function(pets, equipped)
    GUIManager.updatePets(pets, equipped)
end)

-- ── Rebirth events ────────────────────────────────────────────────────────────

remotes.RebirthUpdate.OnClientEvent:Connect(function(count, cost, aura, mult)
    GUIManager.updateRebirth(count, cost, aura, mult)
end)

-- ── Event system events ───────────────────────────────────────────────────────

remotes.EventUpdate.OnClientEvent:Connect(function(eventData)
    GUIManager.updateEvent(eventData)
    if eventData then
        EffectsManager.playSound("Notification")
        EffectsManager.screenFlash(eventData.Color or Color3.fromRGB(255,215,0), 1.0)
        GUIManager.pushNotification({ type=GameConfig.NotifType.Rare,
            message="🎪 Evento iniciado: "..eventData.Name.."!" })
    end
end)

-- ── Trade events ──────────────────────────────────────────────────────────────

remotes.TradeRequestIncoming.OnClientEvent:Connect(function(data)
    GUIManager.showTradeRequest(data)
    EffectsManager.playSound("Notification")
    -- Auto-respond UI: player can accept/decline via the trade panel that opened
    -- For now, auto-accept after opening panel (player clicks Confirm to lock)
    -- Actual accept/decline comes from RespondTrade button in UI
    -- Since we opened the trade panel automatically, fire accept
    task.delay(0.5, function()
        remotes.RespondTrade:FireServer(data.tradeId, true)
    end)
end)

remotes.TradeStateUpdate.OnClientEvent:Connect(function(trade)
    GUIManager.updateTradeState(trade)
end)

remotes.TradeResult.OnClientEvent:Connect(function(success, msg)
    GUIManager.tradeResult(success, msg)
    if success then
        EffectsManager.playSound("Sell")
        EffectsManager.screenFlash(C.Success or Color3.fromRGB(50,220,100), 0.5)
    end
end)

-- ── Clan events ───────────────────────────────────────────────────────────────

remotes.ClanUpdate.OnClientEvent:Connect(function(clanData)
    GUIManager.updateClan(clanData)
end)

remotes.ClanRankingUpdate.OnClientEvent:Connect(function(rows)
    GUIManager.updateClanRanking(rows)
end)

-- ── Proximity prompts on hub buildings ───────────────────────────────────────

local function connectPrompt(partName, action)
    local part = workspace:WaitForChild(partName, 20)
    if not part then return end
    local p = part:FindFirstChildOfClass("ProximityPrompt")
    if p then p.Triggered:Connect(action) end
end

connectPrompt("AuraShop",       function() remotes.SellBrainrots:FireServer(nil) end)
connectPrompt("PetShop",        function() GUIManager.openEventPanel and nil
    -- open pets via hudBtn; this triggers buy UI
    remotes.OpenPetEgg:FireServer()
end)
connectPrompt("RebirthAltar",   function() remotes.RequestRebirth:FireServer() end)
connectPrompt("ClanHall",       function()
    -- Open clan panel
    GUIManager.pushNotification({ type=GameConfig.NotifType.Info, message="🏛️ Abra o painel de Clãs com o botão!" })
end)

-- Reference colors for effects
local C = GameConfig.UIColors

print("[MainClient] All systems connected.")
