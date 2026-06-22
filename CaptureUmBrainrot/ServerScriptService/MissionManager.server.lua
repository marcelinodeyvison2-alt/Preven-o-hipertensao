-- MissionManager.server.lua
-- Tracks daily mission progress per player and handles reward claims.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

repeat task.wait(0.2) until ReplicatedStorage:GetAttribute("SetupComplete")

local MissionConfig = require(ReplicatedStorage.Modules.MissionConfig)
local GameConfig    = require(ReplicatedStorage.Modules.GameConfig)
local SharedData    = require(script.Parent.Modules.SharedData)

local remotes   = ReplicatedStorage:WaitForChild("RemoteEvents")
local bindables = ReplicatedStorage:WaitForChild("BindableEvents")

local evMissionUpdate = remotes:WaitForChild("MissionUpdate")
local evClaimMission  = remotes:WaitForChild("ClaimMissionReward")
local evNotif         = remotes:WaitForChild("Notification")

local bindCapture = bindables:WaitForChild("BrainrotCaptured")
local bindSold    = bindables:WaitForChild("BrainrotsSold")
local bindEgg     = bindables:WaitForChild("PetEggOpened")

local function today()
    return os.date("%Y-%m-%d")
end

local function ensureMissions(session)
    local d = today()
    if session.missions.day ~= d then
        session.missions.day  = d
        session.missions.list = MissionConfig.rollDailyMissions()
    end
end

local function sendMissions(player)
    local session = SharedData.sessions[player.UserId]
    if not session then return end
    ensureMissions(session)
    evMissionUpdate:FireClient(player, session.missions.list)
end

local function addProgress(player, missionType, amount, rarityKey)
    local session = SharedData.sessions[player.UserId]
    if not session then return end
    ensureMissions(session)

    local changed = false
    for _, m in ipairs(session.missions.list) do
        if m.completed then continue end
        if m.missionType ~= missionType then continue end

        local ok = true
        if m.rarityFilter then
            ok = rarityKey ~= nil and m.rarityFilter[rarityKey] == true
        end
        if not ok then continue end

        m.progress = math.min(m.goal, m.progress + amount)
        if m.progress >= m.goal then
            m.completed = true
        end
        changed = true
    end

    if changed then
        evMissionUpdate:FireClient(player, session.missions.list)
    end
end

-- ── BindableEvent listeners ────────────────────────────────────────────────────

bindCapture.Event:Connect(function(player, brainrotData)
    addProgress(player, "capture", 1, nil)
    addProgress(player, "captureRarity", 1, brainrotData.Rarity)
end)

bindSold.Event:Connect(function(player, soldCount, gainedAura)
    addProgress(player, "sell", soldCount, nil)
    addProgress(player, "sellAura", gainedAura, nil)
end)

bindEgg.Event:Connect(function(player)
    addProgress(player, "openEgg", 1, nil)
end)

-- ── Claim reward ───────────────────────────────────────────────────────────────

evClaimMission.OnServerEvent:Connect(function(player, index)
    if type(index) ~= "number" then return end
    local session = SharedData.sessions[player.UserId]
    if not session then return end
    ensureMissions(session)

    local m = session.missions.list[index]
    if not m then return end
    if not m.completed then
        evNotif:FireClient(player, { type=GameConfig.NotifType.Error, message="❌ Missão ainda não concluída!" })
        return
    end
    if m.claimed then
        evNotif:FireClient(player, { type=GameConfig.NotifType.Info, message="✅ Recompensa já coletada!" })
        return
    end

    m.claimed    = true
    session.aura = session.aura + m.reward

    local ls = player:FindFirstChild("leaderstats")
    if ls then
        local auraVal = ls:FindFirstChild("Aura")
        if auraVal then auraVal.Value = session.aura end
    end

    evNotif:FireClient(player, { type=GameConfig.NotifType.Rare,
        message="🏆 Missão concluída! +"..m.reward.." Aura!" })
    evMissionUpdate:FireClient(player, session.missions.list)
end)

-- ── Send missions on join ──────────────────────────────────────────────────────

Players.PlayerAdded:Connect(function(player)
    task.delay(4, function()
        if player.Parent then sendMissions(player) end
    end)
end)
for _, p in ipairs(Players:GetPlayers()) do
    task.spawn(function()
        task.delay(4, function() if p.Parent then sendMissions(p) end end)
    end)
end

print("[MissionManager] Ready.")
