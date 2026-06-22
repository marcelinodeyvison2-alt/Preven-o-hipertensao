-- ClanManager.server.lua
-- Manages clan creation, membership, and ranking.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService  = game:GetService("DataStoreService")

repeat task.wait(0.2) until ReplicatedStorage:GetAttribute("SetupComplete")

local GameConfig = require(ReplicatedStorage.Modules.GameConfig)
local SharedData = require(script.Parent.Modules.SharedData)

local remotes    = ReplicatedStorage:WaitForChild("RemoteEvents")
local evCreate   = remotes:WaitForChild("CreateClan")
local evJoin     = remotes:WaitForChild("JoinClan")
local evLeave    = remotes:WaitForChild("LeaveClan")
local evKick     = remotes:WaitForChild("KickMember")
local evPromote  = remotes:WaitForChild("PromoteLeader")
local evClanUpd  = remotes:WaitForChild("ClanUpdate")
local evClanRank = remotes:WaitForChild("ClanRankingUpdate")
local evNotif    = remotes:WaitForChild("Notification")

local CREATE_COST   = 10000   -- Aura to create a clan
local MAX_MEMBERS   = 20
local NAME_MAX_LEN  = 20
local NAME_MIN_LEN  = 3

-- DataStore for clan persistence
local clanStore
pcall(function()
    clanStore = DataStoreService:GetDataStore("ClanData_v1")
end)

-- ── DataStore helpers ─────────────────────────────────────────────────────────

local function saveClan(name, data)
    if not clanStore then return end
    pcall(function() clanStore:SetAsync("Clan_"..name, data) end)
end

local function loadClan(name)
    if not clanStore then return nil end
    local data
    pcall(function() data = clanStore:GetAsync("Clan_"..name) end)
    return data
end

local function deleteClan(name)
    if not clanStore then return end
    pcall(function() clanStore:RemoveAsync("Clan_"..name) end)
end

-- ── Clan accessors ────────────────────────────────────────────────────────────

local function getClan(name)
    if SharedData.clans[name] then return SharedData.clans[name] end
    local data = loadClan(name)
    if data then SharedData.clans[name] = data end
    return data
end

local function computeClanAura(clanData)
    local total = 0
    for _, memberName in ipairs(clanData.Members) do
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Name == memberName then
                local session = SharedData.sessions[p.UserId]
                if session then total = total + session.aura end
                break
            end
        end
    end
    return total
end

-- ── Broadcast helpers ─────────────────────────────────────────────────────────

local function sendClanToPlayer(player)
    local session = SharedData.sessions[player.UserId]
    if not session or session.clanName == "" then
        evClanUpd:FireClient(player, nil)
        return
    end
    local clan = getClan(session.clanName)
    if clan then
        clan.TotalAura = computeClanAura(clan)
        evClanUpd:FireClient(player, clan)
    end
end

local function broadcastClanRanking()
    local rows = {}
    for name, clan in pairs(SharedData.clans) do
        rows[#rows+1] = {
            Name      = clan.Name,
            Leader    = clan.Leader,
            Members   = #clan.Members,
            TotalAura = computeClanAura(clan),
        }
    end
    table.sort(rows, function(a,b) return a.TotalAura > b.TotalAura end)
    for _, p in ipairs(Players:GetPlayers()) do
        evClanRank:FireClient(p, rows)
    end
end

-- Notify all online members of clan update
local function notifyClanMembers(clanData)
    if not clanData then return end
    for _, memberName in ipairs(clanData.Members) do
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Name == memberName then
                sendClanToPlayer(p)
                break
            end
        end
    end
end

-- ── Create clan ───────────────────────────────────────────────────────────────

evCreate.OnServerEvent:Connect(function(player, clanName, description)
    if type(clanName) ~= "string" then return end
    clanName    = clanName:sub(1, NAME_MAX_LEN):gsub("[^%w%s%-_]", "")
    description = type(description) == "string" and description:sub(1, 80) or ""

    local session = SharedData.sessions[player.UserId]
    if not session then return end

    if #clanName < NAME_MIN_LEN then
        evNotif:FireClient(player, { type=GameConfig.NotifType.Error, message="Nome muito curto (min 3 chars)." })
        return
    end
    if session.clanName ~= "" then
        evNotif:FireClient(player, { type=GameConfig.NotifType.Error, message="Voce ja esta em um cla!" })
        return
    end
    if getClan(clanName) then
        evNotif:FireClient(player, { type=GameConfig.NotifType.Error, message="Ja existe um cla com esse nome!" })
        return
    end
    if session.aura < CREATE_COST then
        evNotif:FireClient(player, { type=GameConfig.NotifType.Error,
            message="❌ Cria um cla custa "..CREATE_COST.." Aura!" })
        return
    end

    session.aura     = session.aura - CREATE_COST
    session.clanName = clanName

    local clan = { Name=clanName, Leader=player.Name, Members={ player.Name }, Description=description, TotalAura=0 }
    SharedData.clans[clanName] = clan
    saveClan(clanName, clan)

    local ls = player:FindFirstChild("leaderstats")
    if ls and ls:FindFirstChild("Aura") then ls.Aura.Value = session.aura end

    sendClanToPlayer(player)
    broadcastClanRanking()
    evNotif:FireClient(player, { type=GameConfig.NotifType.Success, message="🏛️ Cla '"..clanName.."' criado!" })
end)

-- ── Join clan ─────────────────────────────────────────────────────────────────

evJoin.OnServerEvent:Connect(function(player, clanName)
    if type(clanName) ~= "string" then return end
    local session = SharedData.sessions[player.UserId]
    if not session then return end

    if session.clanName ~= "" then
        evNotif:FireClient(player, { type=GameConfig.NotifType.Error, message="Voce ja esta em um cla!" })
        return
    end

    local clan = getClan(clanName)
    if not clan then
        evNotif:FireClient(player, { type=GameConfig.NotifType.Error, message="Cla nao encontrado: "..clanName })
        return
    end
    if #clan.Members >= MAX_MEMBERS then
        evNotif:FireClient(player, { type=GameConfig.NotifType.Error, message="Cla lotado! (max "..MAX_MEMBERS.." membros)" })
        return
    end

    table.insert(clan.Members, player.Name)
    session.clanName = clanName
    saveClan(clanName, clan)

    notifyClanMembers(clan)
    broadcastClanRanking()
    evNotif:FireClient(player, { type=GameConfig.NotifType.Success, message="🏛️ Entrou no cla '"..clanName.."'!" })
end)

-- ── Leave clan ────────────────────────────────────────────────────────────────

evLeave.OnServerEvent:Connect(function(player)
    local session = SharedData.sessions[player.UserId]
    if not session or session.clanName == "" then return end

    local clan = getClan(session.clanName)
    local clanName = session.clanName
    session.clanName = ""

    if not clan then evClanUpd:FireClient(player, nil); return end

    -- Remove from members
    for i, m in ipairs(clan.Members) do
        if m == player.Name then table.remove(clan.Members, i); break end
    end

    if #clan.Members == 0 then
        -- Disband clan
        SharedData.clans[clanName] = nil
        deleteClan(clanName)
        evNotif:FireClient(player, { type=GameConfig.NotifType.Info, message="Cla disbandido (sem membros)." })
    else
        -- Transfer leadership if needed
        if clan.Leader == player.Name then
            clan.Leader = clan.Members[1]
        end
        saveClan(clanName, clan)
        notifyClanMembers(clan)
        evNotif:FireClient(player, { type=GameConfig.NotifType.Info, message="Voce saiu do cla." })
    end

    evClanUpd:FireClient(player, nil)
    broadcastClanRanking()
end)

-- ── Kick member ───────────────────────────────────────────────────────────────

evKick.OnServerEvent:Connect(function(player, targetName)
    if type(targetName) ~= "string" then return end
    local session = SharedData.sessions[player.UserId]
    if not session or session.clanName == "" then return end

    local clan = getClan(session.clanName)
    if not clan or clan.Leader ~= player.Name then
        evNotif:FireClient(player, { type=GameConfig.NotifType.Error, message="Apenas o lider pode expulsar membros." })
        return
    end
    if targetName == player.Name then return end

    for i, m in ipairs(clan.Members) do
        if m == targetName then
            table.remove(clan.Members, i)
            saveClan(clan.Name, clan)

            -- Update kicked player's session
            local kicked = Players:FindFirstChild(targetName)
            if kicked then
                local ks = SharedData.sessions[kicked.UserId]
                if ks then ks.clanName = "" end
                evClanUpd:FireClient(kicked, nil)
                evNotif:FireClient(kicked, { type=GameConfig.NotifType.Error, message="Voce foi expulso do cla!" })
            end

            notifyClanMembers(clan)
            broadcastClanRanking()
            evNotif:FireClient(player, { type=GameConfig.NotifType.Success, message=targetName.." foi expulso." })
            return
        end
    end
    evNotif:FireClient(player, { type=GameConfig.NotifType.Error, message=targetName.." nao esta no cla." })
end)

-- ── Promote leader ────────────────────────────────────────────────────────────

evPromote.OnServerEvent:Connect(function(player, targetName)
    if type(targetName) ~= "string" then return end
    local session = SharedData.sessions[player.UserId]
    if not session or session.clanName == "" then return end

    local clan = getClan(session.clanName)
    if not clan or clan.Leader ~= player.Name then return end

    for _, m in ipairs(clan.Members) do
        if m == targetName then
            clan.Leader = targetName
            saveClan(clan.Name, clan)
            notifyClanMembers(clan)
            evNotif:FireClient(player, { type=GameConfig.NotifType.Success, message=targetName.." e o novo lider!" })
            return
        end
    end
end)

-- Periodic ranking refresh
task.spawn(function()
    while true do
        task.wait(60)
        broadcastClanRanking()
    end
end)

-- Join players get their clan info
Players.PlayerAdded:Connect(function(player)
    task.delay(5, function()
        if player.Parent then sendClanToPlayer(player) end
    end)
end)

print("[ClanManager] Ready.")
