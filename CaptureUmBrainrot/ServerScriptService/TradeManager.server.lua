-- TradeManager.server.lua
-- Manages item trades between players.
-- Flow: A requests → B accepts → both select items → both confirm → swap executes.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

repeat task.wait(0.2) until ReplicatedStorage:GetAttribute("SetupComplete")

local GameConfig = require(ReplicatedStorage.Modules.GameConfig)
local SharedData = require(script.Parent.Modules.SharedData)

local remotes = ReplicatedStorage:WaitForChild("RemoteEvents")
local evReq   = remotes:WaitForChild("SendTradeRequest")
local evResp  = remotes:WaitForChild("RespondTrade")
local evUpd   = remotes:WaitForChild("UpdateTradeOffer")
local evConf  = remotes:WaitForChild("ConfirmTrade")
local evCanc  = remotes:WaitForChild("CancelTrade")
local evInc   = remotes:WaitForChild("TradeRequestIncoming")
local evState = remotes:WaitForChild("TradeStateUpdate")
local evRes   = remotes:WaitForChild("TradeResult")
local evNotif   = remotes:WaitForChild("Notification")
local evSendInv = remotes:WaitForChild("SendInventory")

-- ── Trade state helpers ───────────────────────────────────────────────────────

local function getTrade(tradeId)
    return SharedData.trades[tradeId]
end

local function findTradeByPlayer(userId)
    for id, trade in pairs(SharedData.trades) do
        if trade.playerAId == userId or trade.playerBId == userId then
            return id, trade
        end
    end
    return nil, nil
end

local function broadcast(trade)
    local pA = Players:GetPlayerByUserId(trade.playerAId)
    local pB = Players:GetPlayerByUserId(trade.playerBId)
    if pA then evState:FireClient(pA, trade) end
    if pB then evState:FireClient(pB, trade) end
end

local function cancelTrade(tradeId, reason)
    local trade = SharedData.trades[tradeId]
    if not trade then return end
    SharedData.trades[tradeId] = nil

    local pA = Players:GetPlayerByUserId(trade.playerAId)
    local pB = Players:GetPlayerByUserId(trade.playerBId)
    local msg = reason or "Troca cancelada."
    if pA then evRes:FireClient(pA, false, msg) end
    if pB then evRes:FireClient(pB, false, msg) end
end

-- Auto-expire trades after 3 minutes
local function scheduleExpiry(tradeId)
    task.delay(180, function()
        if SharedData.trades[tradeId] then
            cancelTrade(tradeId, "⏱️ Troca expirou por inatividade.")
        end
    end)
end

-- ── Request trade ─────────────────────────────────────────────────────────────

evReq.OnServerEvent:Connect(function(playerA, targetName)
    if type(targetName) ~= "string" then return end

    -- Check playerA not already in a trade
    local _, existing = findTradeByPlayer(playerA.UserId)
    if existing then
        evNotif:FireClient(playerA, { type=GameConfig.NotifType.Error, message="Voce ja esta em uma troca!" })
        return
    end

    local playerB = Players:FindFirstChild(targetName)
    if not playerB or playerB == playerA then
        evNotif:FireClient(playerA, { type=GameConfig.NotifType.Error, message="Jogador nao encontrado: "..targetName })
        return
    end

    local _, existingB = findTradeByPlayer(playerB.UserId)
    if existingB then
        evNotif:FireClient(playerA, { type=GameConfig.NotifType.Error, message=targetName.." ja esta em uma troca." })
        return
    end

    local tradeId = tostring(playerA.UserId).."_"..tostring(os.clock())
    SharedData.trades[tradeId] = {
        id        = tradeId,
        playerAId = playerA.UserId,
        playerBId = playerB.UserId,
        offerA    = {},
        offerB    = {},
        lockedA   = false,
        lockedB   = false,
        status    = "pending",
    }

    evInc:FireClient(playerB, { tradeId = tradeId, from = playerA.Name })
    evNotif:FireClient(playerA, { type=GameConfig.NotifType.Info, message="🔄 Solicitacao enviada para "..targetName.."!" })
    scheduleExpiry(tradeId)
end)

-- ── Respond to trade request ──────────────────────────────────────────────────

evResp.OnServerEvent:Connect(function(player, tradeId, accepted)
    if type(tradeId) ~= "string" then return end
    local trade = getTrade(tradeId)
    if not trade or trade.playerBId ~= player.UserId then return end
    if trade.status ~= "pending" then return end

    if not accepted then
        cancelTrade(tradeId, "❌ Troca recusada.")
        return
    end

    trade.status = "active"
    local pA = Players:GetPlayerByUserId(trade.playerAId)
    evNotif:FireClient(player, { type=GameConfig.NotifType.Success, message="Troca aceita! Selecione seus itens." })
    if pA then evNotif:FireClient(pA, { type=GameConfig.NotifType.Success, message=player.Name.." aceitou a troca!" }) end
    broadcast(trade)
end)

-- ── Update trade offer (add/remove item by inventory index) ──────────────────

evUpd.OnServerEvent:Connect(function(player, tradeId, action, itemIndex)
    if type(tradeId) ~= "string" or type(itemIndex) ~= "number" then return end
    local trade = getTrade(tradeId)
    if not trade or trade.status ~= "active" then return end

    local isA = trade.playerAId == player.UserId
    local offer = isA and trade.offerA or trade.offerB

    -- Reset lock when offer changes
    if isA then trade.lockedA = false else trade.lockedB = false end

    local session = SharedData.sessions[player.UserId]
    if not session then return end

    if action == "add" then
        local item = session.inventory[itemIndex]
        if not item then return end
        -- Prevent duplicate
        for _, v in ipairs(offer) do
            if v == itemIndex then return end
        end
        if #offer >= 10 then
            evNotif:FireClient(player, { type=GameConfig.NotifType.Error, message="Maximo de 10 itens por oferta." })
            return
        end
        table.insert(offer, itemIndex)
    elseif action == "remove" then
        for i, v in ipairs(offer) do
            if v == itemIndex then table.remove(offer, i); break end
        end
    end

    if isA then trade.offerA = offer else trade.offerB = offer end
    broadcast(trade)
end)

-- ── Confirm trade ─────────────────────────────────────────────────────────────

evConf.OnServerEvent:Connect(function(player, tradeId)
    if type(tradeId) ~= "string" then return end
    local trade = getTrade(tradeId)
    if not trade or trade.status ~= "active" then return end

    local isA = trade.playerAId == player.UserId
    if isA then trade.lockedA = true else trade.lockedB = true end
    broadcast(trade)

    -- Execute when both confirmed
    if not (trade.lockedA and trade.lockedB) then return end

    local sessionA = SharedData.sessions[trade.playerAId]
    local sessionB = SharedData.sessions[trade.playerBId]
    if not sessionA or not sessionB then
        cancelTrade(tradeId, "Dados de jogador indisponiveis.")
        return
    end

    -- Validate indices still exist
    for _, idx in ipairs(trade.offerA) do
        if not sessionA.inventory[idx] then cancelTrade(tradeId, "Item invalido na oferta."); return end
    end
    for _, idx in ipairs(trade.offerB) do
        if not sessionB.inventory[idx] then cancelTrade(tradeId, "Item invalido na oferta."); return end
    end

    -- Collect items (in reverse index order to avoid shifting)
    local function extractItems(session, indices)
        table.sort(indices, function(a,b) return a>b end)
        local extracted = {}
        for _, idx in ipairs(indices) do
            extracted[#extracted+1] = table.remove(session.inventory, idx)
        end
        return extracted
    end

    local itemsFromA = extractItems(sessionA, table.clone and table.clone(trade.offerA) or {table.unpack(trade.offerA)})
    local itemsFromB = extractItems(sessionB, table.clone and table.clone(trade.offerB) or {table.unpack(trade.offerB)})

    for _, item in ipairs(itemsFromB) do table.insert(sessionA.inventory, item) end
    for _, item in ipairs(itemsFromA) do table.insert(sessionB.inventory, item) end

    SharedData.trades[tradeId] = nil

    local pA = Players:GetPlayerByUserId(trade.playerAId)
    local pB = Players:GetPlayerByUserId(trade.playerBId)

    if pA then
        evRes:FireClient(pA, true, "✅ Troca concluida!")
        evSendInv:FireClient(pA, sessionA.inventory, sessionA.unlockedAreas)
    end
    if pB then
        evRes:FireClient(pB, true, "✅ Troca concluida!")
        evSendInv:FireClient(pB, sessionB.inventory, sessionB.unlockedAreas)
    end
end)

-- ── Cancel trade ──────────────────────────────────────────────────────────────

evCanc.OnServerEvent:Connect(function(player, tradeId)
    if type(tradeId) ~= "string" then return end
    local trade = getTrade(tradeId)
    if not trade then return end
    if trade.playerAId ~= player.UserId and trade.playerBId ~= player.UserId then return end
    cancelTrade(tradeId, "❌ "..player.Name.." cancelou a troca.")
end)

-- Clean up trades when players leave
Players.PlayerRemoving:Connect(function(player)
    local tradeId, _ = findTradeByPlayer(player.UserId)
    if tradeId then
        cancelTrade(tradeId, player.Name.." saiu do jogo.")
    end
end)

print("[TradeManager] Ready.")
