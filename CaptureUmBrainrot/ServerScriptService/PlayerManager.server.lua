-- PlayerManager.server.lua
-- Manages all player state: inventory, Aura, unlocked areas.
-- Listens to BrainrotCaptured BindableEvent from BrainrotSpawner.
-- Handles SellBrainrots and UnlockArea RemoteEvents from clients.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService  = game:GetService("DataStoreService")

repeat task.wait(0.2) until ReplicatedStorage:GetAttribute("SetupComplete")

local BrainrotConfig = require(ReplicatedStorage.Modules.BrainrotConfig)
local GameConfig     = require(ReplicatedStorage.Modules.GameConfig)

local remotes        = ReplicatedStorage:WaitForChild("RemoteEvents")
local bindables      = ReplicatedStorage:WaitForChild("BindableEvents")

local evCapSuccess   = remotes:WaitForChild("CaptureSuccess")
local evNotif        = remotes:WaitForChild("Notification")
local evSendInv      = remotes:WaitForChild("SendInventory")
local evSendRank     = remotes:WaitForChild("SendRanking")
local evAreaSuccess  = remotes:WaitForChild("AreaUnlockSuccess")
local evSellReq      = remotes:WaitForChild("SellBrainrots")
local evUnlockReq    = remotes:WaitForChild("UnlockArea")
local evRankReq      = remotes:WaitForChild("RequestRanking")

local bindCapture     = bindables:WaitForChild("BrainrotCaptured")
local bindDataChanged = bindables:WaitForChild("PlayerDataChanged")

-- DataStore (wrapped in pcall to handle Studio limitations gracefully)
local dataStore
local ok, err = pcall(function()
    dataStore = DataStoreService:GetDataStore(GameConfig.DataStoreName)
end)
if not ok then warn("[PlayerManager] DataStore unavailable:", err) end

-- ── In-memory session data ────────────────────────────────────────────────────

local sessions = {}
-- sessions[userId] = {
--   aura          : number,
--   totalCaptured : number,
--   inventory     : { {Name, Rarity, Emoji, AuraValue} ... },
--   unlockedAreas : { areaKey = true },
--   rarestRarity  : string,
-- }

local function defaultSession()
    local unlocked = {}
    for key, data in pairs(BrainrotConfig.Areas) do
        if data.IsDefault then unlocked[key] = true end
    end
    return {
        aura          = 0,
        totalCaptured = 0,
        inventory     = {},
        unlockedAreas = unlocked,
        rarestRarity  = "",
    }
end

-- ── DataStore helpers ─────────────────────────────────────────────────────────

local function loadData(userId)
    if not dataStore then return defaultSession() end
    local saved
    local ok2, err2 = pcall(function()
        saved = dataStore:GetAsync(tostring(userId))
    end)
    if not ok2 then
        warn("[PlayerManager] Load failed for", userId, err2)
        return defaultSession()
    end
    if not saved then return defaultSession() end

    -- Merge saved into defaults so new fields appear automatically
    local session = defaultSession()
    session.aura          = saved.aura          or 0
    session.totalCaptured = saved.totalCaptured  or 0
    session.inventory     = saved.inventory      or {}
    session.rarestRarity  = saved.rarestRarity   or ""
    if saved.unlockedAreas then
        for k, v in pairs(saved.unlockedAreas) do
            session.unlockedAreas[k] = v
        end
    end
    return session
end

local function saveData(userId, session)
    if not dataStore then return end
    local ok2, err2 = pcall(function()
        dataStore:SetAsync(tostring(userId), {
            aura          = session.aura,
            totalCaptured = session.totalCaptured,
            inventory     = session.inventory,
            unlockedAreas = session.unlockedAreas,
            rarestRarity  = session.rarestRarity,
        })
    end)
    if not ok2 then warn("[PlayerManager] Save failed for", userId, err2) end
end

-- ── Leaderstats ───────────────────────────────────────────────────────────────

local function createLeaderstats(player, session)
    local ls = Instance.new("Folder")
    ls.Name   = "leaderstats"
    ls.Parent = player

    local auraVal = Instance.new("IntValue")
    auraVal.Name   = "Aura"
    auraVal.Value  = session.aura
    auraVal.Parent = ls

    local countVal = Instance.new("IntValue")
    countVal.Name   = "Brainrots"
    countVal.Value  = session.totalCaptured
    countVal.Parent = ls

    return ls
end

local function updateLeaderstats(player, session)
    local ls = player:FindFirstChild("leaderstats")
    if not ls then return end
    local av = ls:FindFirstChild("Aura")
    local cv = ls:FindFirstChild("Brainrots")
    if av then av.Value = session.aura end
    if cv then cv.Value = session.totalCaptured end
end

-- ── Rarity ordering ───────────────────────────────────────────────────────────

local rarityRank = {}
for i, key in ipairs(BrainrotConfig.RarityOrder) do
    rarityRank[key] = i
end

local function isRarer(a, b)
    return (rarityRank[a] or 0) > (rarityRank[b] or 0)
end

-- ── Player join / leave ───────────────────────────────────────────────────────

local function onPlayerAdded(player)
    local session = loadData(player.UserId)
    sessions[player.UserId] = session

    createLeaderstats(player, session)

    -- Push initial inventory to client (may arrive before GUI is ready; client buffers it)
    task.delay(3, function()
        if player.Parent then
            evSendInv:FireClient(player, session.inventory, session.unlockedAreas)
        end
    end)

    bindDataChanged:Fire()
end

local function onPlayerRemoving(player)
    local session = sessions[player.UserId]
    if session then
        saveData(player.UserId, session)
        sessions[player.UserId] = nil
    end
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Handle players already in game (Studio Play Solo)
for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(onPlayerAdded, player)
end

-- ── Capture handler ───────────────────────────────────────────────────────────

bindCapture.Event:Connect(function(player, brainrotData)
    local session = sessions[player.UserId]
    if not session then return end

    -- Validate area access
    if not session.unlockedAreas[brainrotData.AreaKey] then
        evNotif:FireClient(player, {
            type    = GameConfig.NotifType.Error,
            message = "🔒 Desbloqueie esta área primeiro!",
        })
        return
    end

    -- Inventory cap
    if #session.inventory >= GameConfig.MaxInventorySize then
        evNotif:FireClient(player, {
            type    = GameConfig.NotifType.Error,
            message = "📦 Inventário cheio! Venda alguns Brainrots.",
        })
        return
    end

    -- Add to inventory
    local entry = {
        Name     = brainrotData.Name,
        Rarity   = brainrotData.Rarity,
        Emoji    = brainrotData.Emoji,
        AuraValue = brainrotData.AuraValue,
    }
    table.insert(session.inventory, entry)
    session.totalCaptured = session.totalCaptured + 1

    -- Track rarest
    if isRarer(brainrotData.Rarity, session.rarestRarity) then
        session.rarestRarity = brainrotData.Rarity
    end

    updateLeaderstats(player, session)

    -- Notify client for animation / sound
    evCapSuccess:FireClient(player, entry)

    -- Sync inventory
    evSendInv:FireClient(player, session.inventory, session.unlockedAreas)

    bindDataChanged:Fire()
end)

-- ── Sell handler ──────────────────────────────────────────────────────────────

evSellReq.OnServerEvent:Connect(function(player, rarityFilter)
    -- rarityFilter = nil means sell ALL, or a rarity string to sell that rarity only
    local session = sessions[player.UserId]
    if not session then return end

    local totalGained = 0
    local soldCount   = 0
    local newInventory = {}

    for _, item in ipairs(session.inventory) do
        local shouldSell = (rarityFilter == nil) or (item.Rarity == rarityFilter)
        if shouldSell then
            totalGained = totalGained + item.AuraValue
            soldCount   = soldCount + 1
        else
            newInventory[#newInventory + 1] = item
        end
    end

    if soldCount == 0 then
        evNotif:FireClient(player, {
            type    = GameConfig.NotifType.Error,
            message = "Você não tem Brainrots para vender!",
        })
        return
    end

    session.inventory = newInventory
    session.aura      = session.aura + totalGained

    updateLeaderstats(player, session)
    evSendInv:FireClient(player, session.inventory, session.unlockedAreas)
    evNotif:FireClient(player, {
        type    = GameConfig.NotifType.Success,
        message = "💰 Vendeu " .. soldCount .. " Brainrot(s) por " .. totalGained .. " Aura!",
    })

    bindDataChanged:Fire()
end)

-- ── Area unlock handler ───────────────────────────────────────────────────────

evUnlockReq.OnServerEvent:Connect(function(player, areaKey)
    -- Sanitize input
    if type(areaKey) ~= "string" then return end

    local areaData = BrainrotConfig.Areas[areaKey]
    if not areaData then return end

    local session = sessions[player.UserId]
    if not session then return end

    if session.unlockedAreas[areaKey] then
        evNotif:FireClient(player, {
            type    = GameConfig.NotifType.Info,
            message = "✅ Esta área já está desbloqueada!",
        })
        return
    end

    if session.aura < areaData.UnlockCost then
        evNotif:FireClient(player, {
            type    = GameConfig.NotifType.Error,
            message = "❌ Aura insuficiente! Você precisa de " .. areaData.UnlockCost .. " Aura.",
        })
        return
    end

    session.aura = session.aura - areaData.UnlockCost
    session.unlockedAreas[areaKey] = true

    updateLeaderstats(player, session)
    evSendInv:FireClient(player, session.inventory, session.unlockedAreas)
    evAreaSuccess:FireClient(player, areaKey, areaData.DisplayName)
    evNotif:FireClient(player, {
        type    = GameConfig.NotifType.Success,
        message = "🎉 Área desbloqueada: " .. areaData.DisplayName .. "!",
    })

    bindDataChanged:Fire()
end)

-- ── Ranking request ───────────────────────────────────────────────────────────

evRankReq.OnServerEvent:Connect(function(player)
    local ranking = {}
    for userId, session in pairs(sessions) do
        local p = Players:GetPlayerByUserId(userId)
        if p then
            ranking[#ranking + 1] = {
                Name          = p.Name,
                Aura          = session.aura,
                TotalBrainrots = session.totalCaptured,
                RarestRarity  = session.rarestRarity,
            }
        end
    end
    table.sort(ranking, function(a, b) return a.Aura > b.Aura end)
    evSendRank:FireClient(player, ranking)
end)

-- Broadcast ranking to all on data changes (throttled)
local rankingTimer = 0
local RANK_INTERVAL = GameConfig.RankingRefreshRate

task.spawn(function()
    while true do
        task.wait(RANK_INTERVAL)
        local ranking = {}
        for userId, session in pairs(sessions) do
            local p = Players:GetPlayerByUserId(userId)
            if p then
                ranking[#ranking + 1] = {
                    Name           = p.Name,
                    Aura           = session.aura,
                    TotalBrainrots = session.totalCaptured,
                    RarestRarity   = session.rarestRarity,
                }
            end
        end
        table.sort(ranking, function(a, b) return a.Aura > b.Aura end)
        for _, p in ipairs(Players:GetPlayers()) do
            evSendRank:FireClient(p, ranking)
        end
    end
end)

print("[PlayerManager] Ready.")
