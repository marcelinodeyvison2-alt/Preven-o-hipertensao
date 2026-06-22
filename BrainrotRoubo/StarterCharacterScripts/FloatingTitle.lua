-- LocalScript: StarterCharacterScripts > FloatingTitle
-- Título flutuante acima da cabeça mostrando rank e rebirths

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local player    = Players.LocalPlayer
local character = script.Parent
local head      = character:WaitForChild("Head")

local RemoteFolder = ReplicatedStorage:WaitForChild("Remotes")
local UpdateAuraRE = RemoteFolder:WaitForChild("UpdateAura")

-- Cores por rebirth (máximo 12)
local REBIRTH_COLORS = {
    [0]  = Color3.fromRGB(180, 180, 180),
    [1]  = Color3.fromRGB(80,  210, 80 ),
    [2]  = Color3.fromRGB(60,  120, 255),
    [3]  = Color3.fromRGB(190, 50,  255),
    [4]  = Color3.fromRGB(255, 195, 0  ),
    [5]  = Color3.fromRGB(255, 50,  50 ),
    [6]  = Color3.fromRGB(255, 255, 120),
    [7]  = Color3.fromRGB(0,   220, 200),
    [8]  = Color3.fromRGB(255, 255, 255),
    [9]  = Color3.fromRGB(255, 100, 220),
    [10] = Color3.fromRGB(180, 80,  255),
    [11] = Color3.fromRGB(255, 160, 40 ),
    [12] = Color3.fromRGB(255, 215, 0  ),
}

-- Títulos automáticos por rebirth (quando sem título equipado)
local REBIRTH_TITLES = {
    [0]  = "Novato",
    [1]  = "Ladrão",
    [2]  = "Furtivo",
    [3]  = "Épico",
    [4]  = "Lendário",
    [5]  = "Mítico",
    [6]  = "Deus",
    [7]  = "Secreto",
    [8]  = "O ORIGINAL",
    [9]  = "⚡ Transcendente",
    [10] = "🌌 Além do Limite",
    [11] = "🔱 Imortal",
    [12] = "👑 Divino Supremo",
}

local bb = Instance.new("BillboardGui")
bb.Size            = UDim2.new(0, 220, 0, 52)
bb.StudsOffset     = Vector3.new(0, 3.5, 0)
bb.AlwaysOnTop     = false
bb.LightInfluence  = 0
bb.Parent          = head

-- Fundo levemente escuro
local bg = Instance.new("Frame")
bg.Size                   = UDim2.new(1, 0, 1, 0)
bg.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
bg.BackgroundTransparency = 0.55
bg.BorderSizePixel        = 0
bg.Parent                 = bb

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent       = bg

-- Linha superior: título de rank
local rankLabel = Instance.new("TextLabel")
rankLabel.Size                   = UDim2.new(1, -8, 0.52, 0)
rankLabel.Position               = UDim2.new(0, 4, 0, 2)
rankLabel.BackgroundTransparency = 1
rankLabel.Text                   = "✦ Novato"
rankLabel.TextColor3             = Color3.fromRGB(180, 180, 180)
rankLabel.TextStrokeTransparency = 0
rankLabel.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
rankLabel.TextScaled             = true
rankLabel.Font                   = Enum.Font.GothamBold
rankLabel.Parent                 = bb

-- Linha inferior: nome do jogador e rebirths
local infoLabel = Instance.new("TextLabel")
infoLabel.Size                   = UDim2.new(1, -8, 0.40, 0)
infoLabel.Position               = UDim2.new(0, 4, 0.55, 0)
infoLabel.BackgroundTransparency = 1
infoLabel.Text                   = player.DisplayName .. "  [RB 0]"
infoLabel.TextColor3             = Color3.fromRGB(200, 200, 200)
infoLabel.TextStrokeTransparency = 0.3
infoLabel.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
infoLabel.TextScaled             = true
infoLabel.Font                   = Enum.Font.Gotham
infoLabel.Parent                 = bb

local function getColor(rebirths)
    local clamped = math.clamp(rebirths, 0, 12)
    return REBIRTH_COLORS[clamped] or Color3.fromRGB(255, 215, 0)
end

local function getTitle(rebirths)
    local clamped = math.clamp(rebirths, 0, 12)
    return REBIRTH_TITLES[clamped] or "👑 Divino Supremo"
end

local lastRB = 0

UpdateAuraRE.OnClientEvent:Connect(function(payload)
    local rb     = payload.rebirths or 0
    local prest  = payload.prestige  or 0
    local color  = getColor(rb)
    local title  = payload.equippedTitle or getTitle(rb)

    rankLabel.TextColor3 = color
    rankLabel.Text       = "✦ " .. title

    local rbStr  = "[RB " .. rb .. "]"
    local prStr  = prest > 0 and (" ⭐" .. prest) or ""
    infoLabel.Text = player.DisplayName .. "  " .. rbStr .. prStr

    -- Flash no título ao ganhar rebirth ou prestígio
    if rb > lastRB then
        lastRB = rb
        TweenService:Create(rankLabel, TweenInfo.new(0.2), {
            TextColor3 = Color3.fromRGB(255, 255, 255),
        }):Play()
        task.delay(0.3, function()
            TweenService:Create(rankLabel, TweenInfo.new(0.5), {
                TextColor3 = color,
            }):Play()
        end)
    end
end)

print("[BrainrotRoubo] Título flutuante carregado para " .. player.DisplayName)
