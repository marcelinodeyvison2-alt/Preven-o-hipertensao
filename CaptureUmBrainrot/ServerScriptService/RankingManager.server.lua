-- RankingManager.server.lua
-- Updates the in-world ranking board SurfaceGui.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

repeat task.wait(0.2) until ReplicatedStorage:GetAttribute("SetupComplete")

local GameConfig     = require(ReplicatedStorage.Modules.GameConfig)
local BrainrotConfig = require(ReplicatedStorage.Modules.BrainrotConfig)

local bindables      = ReplicatedStorage:WaitForChild("BindableEvents")
local bindDataChg    = bindables:WaitForChild("PlayerDataChanged")
local remotes        = ReplicatedStorage:WaitForChild("RemoteEvents")
local evSendRank     = remotes:WaitForChild("SendRanking")

-- ── Locate the SurfaceGui on the ranking board ────────────────────────────────

local rankBoard = workspace:WaitForChild("RankingBoard", 30)
local rankGui   = rankBoard and rankBoard:FindFirstChild("RankingGui")
local rankList  = rankGui  and rankGui:FindFirstChild("List")

local MEDAL = { "🥇", "🥈", "🥉" }

local rarityDisplayNames = {}
for key, data in pairs(BrainrotConfig.Rarities) do
    rarityDisplayNames[key] = data.DisplayName
end

local function buildRow(index, entry)
    local frame = Instance.new("Frame")
    frame.Name               = "Row_" .. index
    frame.Size               = UDim2.new(1, 0, 0.085, 0)
    frame.BackgroundColor3   = (index % 2 == 0)
        and Color3.fromRGB(20, 20, 45)
        or  Color3.fromRGB(28, 28, 55)
    frame.BackgroundTransparency = 0.1
    frame.LayoutOrder        = index

    local label = Instance.new("TextLabel")
    label.Size               = UDim2.new(1, -6, 1, -4)
    label.Position           = UDim2.new(0, 3, 0, 2)
    local medal = MEDAL[index] or ("#" .. index)
    local rarestStr = entry.RarestRarity ~= "" and rarityDisplayNames[entry.RarestRarity] or "—"
    label.Text               = medal .. " " .. entry.Name
        .. "   |   " .. tostring(entry.Aura) .. " Aura"
        .. "   |   " .. tostring(entry.TotalBrainrots) .. " Brainrots"
        .. "   |   " .. rarestStr
    label.TextColor3         = Color3.fromRGB(240, 240, 255)
    label.TextScaled         = true
    label.BackgroundTransparency = 1
    label.Font               = Enum.Font.Gotham
    label.Parent             = frame

    return frame
end

local function refreshBoard(ranking)
    if not rankList then return end

    -- Clear old rows
    for _, child in ipairs(rankList:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    local shown = math.min(#ranking, 10)
    for i = 1, shown do
        local row = buildRow(i, ranking[i])
        row.Parent = rankList
    end
end

-- ── Listen for ranking updates sent by PlayerManager ─────────────────────────

evSendRank.OnServerEvent:Connect(function(_, ranking)
    -- This event direction is server→client; we shouldn't receive it here.
    -- RankingManager builds its own board based on bindable events.
end)

-- Rebuild board whenever player data changes
bindDataChg.Event:Connect(function()
    -- Build ranking from leaderstats (available on all players)
    local rows = {}
    for _, player in ipairs(Players:GetPlayers()) do
        local ls = player:FindFirstChild("leaderstats")
        if ls then
            rows[#rows + 1] = {
                Name           = player.Name,
                Aura           = ls:FindFirstChild("Aura") and ls.Aura.Value or 0,
                TotalBrainrots = ls:FindFirstChild("Brainrots") and ls.Brainrots.Value or 0,
                RarestRarity   = "",
            }
        end
    end
    table.sort(rows, function(a, b) return a.Aura > b.Aura end)
    refreshBoard(rows)
end)

-- Periodic refresh
task.spawn(function()
    while true do
        task.wait(GameConfig.RankingRefreshRate)
        local rows = {}
        for _, player in ipairs(Players:GetPlayers()) do
            local ls = player:FindFirstChild("leaderstats")
            if ls then
                rows[#rows + 1] = {
                    Name           = player.Name,
                    Aura           = ls:FindFirstChild("Aura") and ls.Aura.Value or 0,
                    TotalBrainrots = ls:FindFirstChild("Brainrots") and ls.Brainrots.Value or 0,
                    RarestRarity   = "",
                }
            end
        end
        table.sort(rows, function(a, b) return a.Aura > b.Aura end)
        refreshBoard(rows)
    end
end)

print("[RankingManager] Board ready.")
