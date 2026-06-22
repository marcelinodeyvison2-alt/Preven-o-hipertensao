-- PlayerManager.server.lua
-- Central server authority: owns all player session data.
-- Uses SharedData as the shared session store.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService  = game:GetService("DataStoreService")

repeat task.wait(0.2) until ReplicatedStorage:GetAttribute("SetupComplete")

local BrainrotConfig = require(ReplicatedStorage.Modules.BrainrotConfig)
local GameConfig     = require(ReplicatedStorage.Modules.GameConfig)
local PetConfig      = require(ReplicatedStorage.Modules.PetConfig)
local SharedData     = require(script.Parent.Modules.SharedData)

local remotes        = ReplicatedStorage:WaitForChild("RemoteEvents")
local bindables      = ReplicatedStorage:WaitForChild("BindableEvents")

local evCapSuccess   = remotes:WaitForChild("CaptureSuccess")
local evNotif        = remotes:WaitForChild("Notification")
local evSendInv      = remotes:WaitForChild("SendInventory")
local evAreaSuccess  = remotes:WaitForChild("AreaUnlockSuccess")
local evSellReq      = remotes:WaitForChild("SellBrainrots")
local evUnlockReq    = remotes:WaitForChild("UnlockArea")
local evRankReq      = remotes:WaitForChild("RequestRanking")
local evSendRank     = remotes:WaitForChild("SendRanking")
local evPetUpdate    = remotes:WaitForChild("PetUpdate")
local evOpenEgg      = remotes:WaitForChild("OpenPetEgg")
local evEquipPet     = remotes:WaitForChild("EquipPet")
local evUnequipPet   = remotes:WaitForChild("UnequipPet")
local evRebirthUpd   = remotes:WaitForChild("RebirthUpdate")
local evRebirthReq   = remotes:WaitForChild("RequestRebirth")
local evClanUpd      = remotes:WaitForChild("ClanUpdate")

local bindCapture     = bindables:WaitForChild("BrainrotCaptured")
local bindDataChanged = bindables:WaitForChild("PlayerDataChanged")

-- DataStore
local dataStore
pcall(function()
    dataStore = DataStoreService:GetDataStore(GameConfig.DataStoreName)
end)

-- ── Session schema ────────────────────────────────────────────────────────────

local function defaultUnlocked()
    local t = {}
    for k, d in pairs(BrainrotConfig.Areas) do
        if d.IsDefault then t[k] = true end
    end
    return t
end

local function defaultSession()
    return {
        aura          = 0,
        totalCaptured = 0,
        inventory     = {},
        unlockedAreas = defaultUnlocked(),
        rarestRarity  = "",
        rebirthCount  = 0,
        pets          = {},    -- list of pet names owned
        equippedPets  = {},    -- list of pet names equipped (max 3)
        clanName      = "",
    }
end

-- ── DataStore helpers ─────────────────────────────────────────────────────────

local function loadData(userId)
    if not dataStore then return defaultSession() end
    local saved
    pcall(function() saved = dataStore:GetAsync(tostring(userId)) end)
    if not saved then return defaultSession() end
    local s = defaultSession()
    s.aura          = saved.aura          or 0
    s.totalCaptured = saved.totalCaptured  or 0
    s.inventory     = saved.inventory      or {}
    s.rarestRarity  = saved.rarestRarity   or ""
    s.rebirthCount  = saved.rebirthCount   or 0
    s.pets          = saved.pets           or {}
    s.equippedPets  = saved.equippedPets   or {}
    s.clanName      = saved.clanName       or ""
    if saved.unlockedAreas then
        for k, v in pairs(saved.unlockedAreas) do s.unlockedAreas[k] = v end
    end
    return s
end

local function saveData(userId, session)
    if not dataStore then return end
    pcall(function()
        dataStore:SetAsync(tostring(userId), {
            aura          = session.aura,
            totalCaptured = session.totalCaptured,
            inventory     = session.inventory,
            unlockedAreas = session.unlockedAreas,
            rarestRarity  = session.rarestRarity,
            rebirthCount  = session.rebirthCount,
            pets          = session.pets,
            equippedPets  = session.equippedPets,
            clanName      = session.clanName,
        })
    end)
end

-- ── Leaderstats ───────────────────────────────────────────────────────────────

local function createLeaderstats(player, session)
    local ls = Instance.new("Folder"); ls.Name = "leaderstats"; ls.Parent = player
    local function iv(n, v) local x = Instance.new("IntValue"); x.Name=n; x.Value=v; x.Parent=ls; return x end
    iv("Aura",     session.aura)
    iv("Brainrots",session.totalCaptured)
    iv("Rebirth",  session.rebirthCount)
end

local function updateLeaderstats(player, session)
    local ls = player:FindFirstChild("leaderstats"); if not ls then return end
    local function sv(n,v) local x=ls:FindFirstChild(n); if x then x.Value=v end end
    sv("Aura",     session.aura)
    sv("Brainrots",session.totalCaptured)
    sv("Rebirth",  session.rebirthCount)
end

-- ── Rarity order helper ───────────────────────────────────────────────────────

local rarityRank = {}
for i, k in ipairs(BrainrotConfig.RarityOrder) do rarityRank[k] = i end
local function isRarer(a, b) return (rarityRank[a] or 0) > (rarityRank[b] or 0) end

-- ── Payload helpers ───────────────────────────────────────────────────────────

local function sendInventory(player, session)
    evSendInv:FireClient(player, session.inventory, session.unlockedAreas)
end

local function sendPetUpdate(player, session)
    evPetUpdate:FireClient(player, session.pets, session.equippedPets)
end

local function sendRebirthUpdate(player, session)
    local cost = math.floor(100000 * (5 ^ session.rebirthCount))
    local mult = SharedData.totalAuraMultiplier(session)
    evRebirthUpd:FireClient(player, session.rebirthCount, cost, session.aura, mult)
end

-- ── Player join / leave ───────────────────────────────────────────────────────

local function onPlayerAdded(player)
    local session = loadData(player.UserId)
    SharedData.sessions[player.UserId] = session
    createLeaderstats(player, session)

    task.delay(3, function()
        if not player.Parent then return end
        sendInventory(player, session)
        sendPetUpdate(player, session)
        sendRebirthUpdate(player, session)
        if session.clanName ~= "" then
            evClanUpd:FireClient(player, SharedData.clans[session.clanName])
        end
    end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(function(player)
    local session = SharedData.sessions[player.UserId]
    if session then
        saveData(player.UserId, session)
        SharedData.sessions[player.UserId] = nil
    end
end)
for _, p in ipairs(Players:GetPlayers()) do task.spawn(onPlayerAdded, p) end

-- ── Capture handler ───────────────────────────────────────────────────────────

bindCapture.Event:Connect(function(player, brainrotData)
    local session = SharedData.sessions[player.UserId]
    if not session then return end

    if not session.unlockedAreas[brainrotData.AreaKey] then
        evNotif:FireClient(player, { type=GameConfig.NotifType.Error, message="🔒 Desbloqueie esta area primeiro!" })
        return
    end
    if #session.inventory >= GameConfig.MaxInventorySize then
        evNotif:FireClient(player, { type=GameConfig.NotifType.Error, message="📦 Inventario cheio! Venda alguns Brainrots." })
        return
    end

    -- Apply Aura multiplier to capture value
    local baseAura  = brainrotData.AuraValue
    local mult      = SharedData.totalAuraMultiplier(session)
    local finalAura = math.floor(baseAura * mult)

    local entry = {
        Name      = brainrotData.Name,
        Rarity    = brainrotData.Rarity,
        Emoji     = brainrotData.Emoji,
        AuraValue = finalAura,
    }
    table.insert(session.inventory, entry)
    session.totalCaptured = session.totalCaptured + 1
    if isRarer(brainrotData.Rarity, session.rarestRarity) then
        session.rarestRarity = brainrotData.Rarity
    end

    updateLeaderstats(player, session)
    evCapSuccess:FireClient(player, entry)
    sendInventory(player, session)
    bindDataChanged:Fire()
end)

-- ── Sell handler ──────────────────────────────────────────────────────────────

evSellReq.OnServerEvent:Connect(function(player, rarityFilter)
    local session = SharedData.sessions[player.UserId]
    if not session then return end

    local gained, count = 0, 0
    local newInv = {}
    local luck   = SharedData.totalLuckBonus(session)

    for _, item in ipairs(session.inventory) do
        local sell = (rarityFilter == nil) or (item.Rarity == rarityFilter)
        if sell then
            local value = item.AuraValue
            -- Luck: chance to double sell value
            if math.random() < luck then value = value * 2 end
            gained = gained + value
            count  = count  + 1
        else
            newInv[#newInv+1] = item
        end
    end

    if count == 0 then
        evNotif:FireClient(player, { type=GameConfig.NotifType.Error, message="Voce nao tem Brainrots para vender!" })
        return
    end

    session.inventory = newInv
    session.aura      = session.aura + gained
    updateLeaderstats(player, session)
    sendInventory(player, session)
    evNotif:FireClient(player, { type=GameConfig.NotifType.Success,
        message = "💰 Vendeu "..count.." item(s) por "..gained.." Aura!" })
    bindDataChanged:Fire()
end)

-- ── Area unlock handler ───────────────────────────────────────────────────────

evUnlockReq.OnServerEvent:Connect(function(player, areaKey)
    if type(areaKey) ~= "string" then return end
    local areaData = BrainrotConfig.Areas[areaKey]
    if not areaData then return end

    local session = SharedData.sessions[player.UserId]
    if not session then return end

    if session.unlockedAreas[areaKey] then
        evNotif:FireClient(player, { type=GameConfig.NotifType.Info, message="✅ Area ja desbloqueada!" })
        return
    end
    if session.aura < areaData.UnlockCost then
        evNotif:FireClient(player, { type=GameConfig.NotifType.Error,
            message="❌ Aura insuficiente! Precisa de "..areaData.UnlockCost.." Aura." })
        return
    end

    session.aura = session.aura - areaData.UnlockCost
    session.unlockedAreas[areaKey] = true
    updateLeaderstats(player, session)
    sendInventory(player, session)
    evAreaSuccess:FireClient(player, areaKey, areaData.DisplayName)
    evNotif:FireClient(player, { type=GameConfig.NotifType.Success,
        message="🎉 Area desbloqueada: "..areaData.DisplayName.."!" })
    bindDataChanged:Fire()
end)

-- ── Pet egg handler ───────────────────────────────────────────────────────────

evOpenEgg.OnServerEvent:Connect(function(player)
    local session = SharedData.sessions[player.UserId]
    if not session then return end

    if session.aura < PetConfig.EggCost then
        evNotif:FireClient(player, { type=GameConfig.NotifType.Error,
            message="❌ Precisa de "..PetConfig.EggCost.." Aura para abrir um ovo!" })
        return
    end

    session.aura = session.aura - PetConfig.EggCost
    local rarity = PetConfig.rollRarity()
    local pet    = PetConfig.randomPetOfRarity(rarity)

    table.insert(session.pets, pet.Name)
    updateLeaderstats(player, session)
    sendPetUpdate(player, session)
    evNotif:FireClient(player, { type=GameConfig.NotifType.Rare,
        message="🥚 Voce ganhou: "..pet.Emoji.." "..pet.Name.." ("..rarity..")!" })
    bindDataChanged:Fire()
end)

-- ── Equip / Unequip pet ───────────────────────────────────────────────────────

evEquipPet.OnServerEvent:Connect(function(player, petName)
    if type(petName) ~= "string" then return end
    local session = SharedData.sessions[player.UserId]
    if not session then return end

    -- Check ownership
    local owns = false
    for _, p in ipairs(session.pets) do if p == petName then owns=true; break end end
    if not owns then return end

    -- Already equipped?
    for _, p in ipairs(session.equippedPets) do
        if p == petName then
            evNotif:FireClient(player, { type=GameConfig.NotifType.Info, message="Pet ja equipado!" })
            return
        end
    end

    if #session.equippedPets >= PetConfig.MaxEquipped then
        evNotif:FireClient(player, { type=GameConfig.NotifType.Error,
            message="❌ Slots cheios! Desequipe um pet primeiro." })
        return
    end

    table.insert(session.equippedPets, petName)
    sendPetUpdate(player, session)
    local pet = PetConfig.getPetByName(petName)
    evNotif:FireClient(player, { type=GameConfig.NotifType.Success,
        message="🐾 "..( pet and pet.Emoji or "")..petName.." equipado!" })
end)

evUnequipPet.OnServerEvent:Connect(function(player, petName)
    if type(petName) ~= "string" then return end
    local session = SharedData.sessions[player.UserId]
    if not session then return end

    for i, p in ipairs(session.equippedPets) do
        if p == petName then
            table.remove(session.equippedPets, i)
            sendPetUpdate(player, session)
            evNotif:FireClient(player, { type=GameConfig.NotifType.Info, message="Pet desequipado." })
            return
        end
    end
end)

-- ── Rebirth handler ───────────────────────────────────────────────────────────

evRebirthReq.OnServerEvent:Connect(function(player)
    local session = SharedData.sessions[player.UserId]
    if not session then return end

    local cost = math.floor(100000 * (5 ^ session.rebirthCount))
    if session.aura < cost then
        evNotif:FireClient(player, { type=GameConfig.NotifType.Error,
            message="❌ Precisa de "..cost.." Aura para renascer!" })
        return
    end

    -- Reset but keep pets, clans, and rebirth count
    session.rebirthCount  = session.rebirthCount + 1
    session.aura          = 0
    session.inventory     = {}
    session.unlockedAreas = defaultUnlocked()
    session.totalCaptured = 0
    session.rarestRarity  = ""

    updateLeaderstats(player, session)
    sendInventory(player, session)
    sendPetUpdate(player, session)
    sendRebirthUpdate(player, session)
    evNotif:FireClient(player, { type=GameConfig.NotifType.Rare,
        message="♻️ Renascimento "..session.rebirthCount.."! Multiplicador: x"
            ..string.format("%.1f", 1 + 0.5*session.rebirthCount) })
    bindDataChanged:Fire()
end)

-- ── Ranking broadcast ─────────────────────────────────────────────────────────

local function buildRanking()
    local rows = {}
    for userId, session in pairs(SharedData.sessions) do
        local p = Players:GetPlayerByUserId(userId)
        if p then
            rows[#rows+1] = {
                Name           = p.Name,
                Aura           = session.aura,
                TotalBrainrots = session.totalCaptured,
                RarestRarity   = session.rarestRarity,
                RebirthCount   = session.rebirthCount,
                ClanName       = session.clanName,
            }
        end
    end
    table.sort(rows, function(a,b) return a.Aura > b.Aura end)
    return rows
end

evRankReq.OnServerEvent:Connect(function(player)
    evSendRank:FireClient(player, buildRanking())
end)

task.spawn(function()
    while true do
        task.wait(GameConfig.RankingRefreshRate)
        local ranking = buildRanking()
        for _, p in ipairs(Players:GetPlayers()) do
            evSendRank:FireClient(p, ranking)
        end
    end
end)

print("[PlayerManager] Ready.")
