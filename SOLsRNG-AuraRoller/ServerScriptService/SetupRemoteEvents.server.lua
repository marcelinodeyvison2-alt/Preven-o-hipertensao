-- SetupRemoteEvents.server.lua (Script em ServerScriptService)
-- Cria todos os RemoteEvents necessarios no ReplicatedStorage
-- DEVE rodar ANTES do MainServer

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Cria pasta de RemoteEvents
local remotesFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not remotesFolder then
    remotesFolder = Instance.new("Folder")
    remotesFolder.Name   = "RemoteEvents"
    remotesFolder.Parent = ReplicatedStorage
end

-- Lista de todos os RemoteEvents necessarios
local eventNames = {
    "Spin",             -- cliente pede giro
    "SpinResult",       -- servidor envia resultado
    "BuyUpgrade",       -- cliente compra upgrade
    "SetActiveAura",    -- cliente ativa aura
    "SyncData",         -- servidor sincroniza dados
    "EventUpdate",      -- servidor atualiza evento
    "MysteryBox",       -- servidor anuncia mystery box
    "LeaderboardUpdate",-- servidor atualiza leaderboard
}

for _, name in ipairs(eventNames) do
    if not remotesFolder:FindFirstChild(name) then
        local re = Instance.new("RemoteEvent")
        re.Name   = name
        re.Parent = remotesFolder
    end
end

print("[Setup] RemoteEvents criados com sucesso!")
