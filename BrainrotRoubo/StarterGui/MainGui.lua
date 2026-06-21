-- LocalScript: StarterGui > MainGui
-- Cria toda a interface do jogo e detecta brainrots próximos

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")

local player    = Players.LocalPlayer
local playerGui = player.PlayerGui
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local RemoteFolder  = ReplicatedStorage:WaitForChild("Remotes")
local StealEvent    = RemoteFolder:WaitForChild("StealBrainrot")
local UpdateAuraRE  = RemoteFolder:WaitForChild("UpdateAura")
local NotifyRE      = RemoteFolder:WaitForChild("Notify")
local RebirthEvent  = RemoteFolder:WaitForChild("Rebirth")

-- =====================================================
--  CONSTRUÇÃO DA INTERFACE
-- =====================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "MainGui"
ScreenGui.ResetOnSpawn   = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent         = playerGui

-- ---- Utilidades ----
local function makeTL(parent, props)
    local f = Instance.new("TextLabel")
    for k, v in pairs(props) do f[k] = v end
    f.Parent = parent
    return f
end

local function makeFrame(parent, props)
    local f = Instance.new("Frame")
    for k, v in pairs(props) do f[k] = v end
    f.Parent = parent
    return f
end

local function roundCorners(obj, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 10)
    corner.Parent = obj
end

local function addStroke(obj, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color     = color or Color3.fromRGB(255,255,255)
    s.Thickness = thickness or 1.5
    s.Parent    = obj
end

-- ============================================================
--  PAINEL SUPERIOR: AURA
-- ============================================================
local AuraPanel = makeFrame(ScreenGui, {
    Size              = UDim2.new(0, 360, 0, 110),
    Position          = UDim2.new(0.5, -180, 0, 12),
    BackgroundColor3  = Color3.fromRGB(15, 15, 20),
    BackgroundTransparency = 0.2,
    BorderSizePixel   = 0,
})
roundCorners(AuraPanel, 14)
addStroke(AuraPanel, Color3.fromRGB(255, 200, 50), 2)

local AuraTitle = makeTL(AuraPanel, {
    Size             = UDim2.new(1, 0, 0.28, 0),
    BackgroundTransparency = 1,
    Text             = "AURA",
    TextColor3       = Color3.fromRGB(255, 210, 60),
    TextScaled       = true,
    Font             = Enum.Font.GothamBold,
    TextXAlignment   = Enum.TextXAlignment.Center,
})

local AuraValueLabel = makeTL(AuraPanel, {
    Size             = UDim2.new(1, 0, 0.38, 0),
    Position         = UDim2.new(0, 0, 0.27, 0),
    BackgroundTransparency = 1,
    Text             = "0 / 500",
    TextColor3       = Color3.fromRGB(255, 255, 255),
    TextScaled       = true,
    Font             = Enum.Font.GothamBold,
})

-- Barra de progresso da aura
local BarBg = makeFrame(AuraPanel, {
    Size             = UDim2.new(0.88, 0, 0.15, 0),
    Position         = UDim2.new(0.06, 0, 0.70, 0),
    BackgroundColor3 = Color3.fromRGB(40, 40, 50),
    BorderSizePixel  = 0,
})
roundCorners(BarBg, 6)

local BarFill = makeFrame(BarBg, {
    Size             = UDim2.new(0, 0, 1, 0),
    BackgroundColor3 = Color3.fromRGB(255, 210, 0),
    BorderSizePixel  = 0,
})
roundCorners(BarFill, 6)

-- ============================================================
--  PAINEL ESQUERDO: STATS
-- ============================================================
local StatsPanel = makeFrame(ScreenGui, {
    Size             = UDim2.new(0, 200, 0, 130),
    Position         = UDim2.new(0, 12, 0, 12),
    BackgroundColor3 = Color3.fromRGB(15, 15, 20),
    BackgroundTransparency = 0.25,
    BorderSizePixel  = 0,
})
roundCorners(StatsPanel, 12)
addStroke(StatsPanel, Color3.fromRGB(120, 80, 255), 1.5)

local function makeStatRow(yOff, label, defaultVal)
    local lbl = makeTL(StatsPanel, {
        Size             = UDim2.new(1, -10, 0, 28),
        Position         = UDim2.new(0, 5, 0, yOff),
        BackgroundTransparency = 1,
        Text             = label .. ": " .. defaultVal,
        TextColor3       = Color3.fromRGB(220, 220, 220),
        TextScaled       = true,
        Font             = Enum.Font.Gotham,
        TextXAlignment   = Enum.TextXAlignment.Left,
    })
    return lbl
end

local RebirthsLabel  = makeStatRow(8,  "Rebirths",    "0")
local MultLabel      = makeStatRow(42, "Multiplicador","x1")
local StolenLabel    = makeStatRow(76, "Roubados",    "0")
local CostLabel      = makeStatRow(105, "Custo RB",   "400")

-- ============================================================
--  BOTÃO DE REBIRTH
-- ============================================================
local RebirthBtn = Instance.new("TextButton")
RebirthBtn.Size             = UDim2.new(0, 230, 0, 56)
RebirthBtn.Position         = UDim2.new(0.5, -115, 1, -72)
RebirthBtn.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
RebirthBtn.BorderSizePixel  = 0
RebirthBtn.Text             = "RENASCER  (0 / 400)"
RebirthBtn.TextColor3       = Color3.fromRGB(30, 20, 0)
RebirthBtn.TextScaled       = true
RebirthBtn.Font             = Enum.Font.GothamBold
RebirthBtn.Parent           = ScreenGui
roundCorners(RebirthBtn, 14)
addStroke(RebirthBtn, Color3.fromRGB(255, 230, 100), 2)

-- ============================================================
--  PROMPT DE ROUBO (aparece quando perto de brainrot)
-- ============================================================
local StealPrompt = makeFrame(ScreenGui, {
    Size             = UDim2.new(0, 280, 0, 90),
    Position         = UDim2.new(0.5, -140, 0.75, 0),
    BackgroundColor3 = Color3.fromRGB(10, 10, 15),
    BackgroundTransparency = 0.1,
    BorderSizePixel  = 0,
    Visible          = false,
})
roundCorners(StealPrompt, 14)
addStroke(StealPrompt, Color3.fromRGB(255, 255, 255), 1.5)

local StealNameLabel = makeTL(StealPrompt, {
    Size             = UDim2.new(1, 0, 0.45, 0),
    BackgroundTransparency = 1,
    Text             = "Brainrot",
    TextColor3       = Color3.fromRGB(255, 255, 255),
    TextScaled       = true,
    Font             = Enum.Font.GothamBold,
})
local StealRarLabel = makeTL(StealPrompt, {
    Size             = UDim2.new(1, 0, 0.3, 0),
    Position         = UDim2.new(0, 0, 0.44, 0),
    BackgroundTransparency = 1,
    Text             = "[Comum] +10 aura",
    TextColor3       = Color3.fromRGB(180, 180, 180),
    TextScaled       = true,
    Font             = Enum.Font.Gotham,
})
local StealKeyLabel = makeTL(StealPrompt, {
    Size             = UDim2.new(1, 0, 0.26, 0),
    Position         = UDim2.new(0, 0, 0.74, 0),
    BackgroundTransparency = 1,
    Text             = "[E] Roubar",
    TextColor3       = Color3.fromRGB(255, 210, 50),
    TextScaled       = true,
    Font             = Enum.Font.GothamBold,
})

-- ============================================================
--  BOTÃO MÓVEL DE ROUBAR (toque / mobile)
-- ============================================================
local MobileStealBtn = Instance.new("TextButton")
MobileStealBtn.Size             = UDim2.new(0, 130, 0, 130)
MobileStealBtn.Position         = UDim2.new(1, -150, 1, -160)
MobileStealBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
MobileStealBtn.Text             = "ROUBAR"
MobileStealBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
MobileStealBtn.TextScaled       = true
MobileStealBtn.Font             = Enum.Font.GothamBold
MobileStealBtn.Visible          = false
MobileStealBtn.Parent           = ScreenGui
roundCorners(MobileStealBtn, 65)
addStroke(MobileStealBtn, Color3.fromRGB(255, 180, 180), 2)

-- ============================================================
--  SISTEMA DE NOTIFICAÇÕES (toast)
-- ============================================================
local NotifyStack = makeFrame(ScreenGui, {
    Size             = UDim2.new(0, 360, 1, 0),
    Position         = UDim2.new(1, -370, 0, 0),
    BackgroundTransparency = 1,
    BorderSizePixel  = 0,
})

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.SortOrder     = Enum.SortOrder.LayoutOrder
UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
UIListLayout.Padding       = UDim.new(0, 8)
UIListLayout.Parent        = NotifyStack

local notifyCount = 0

local function showNotification(msg, color)
    notifyCount = notifyCount + 1

    local card = makeFrame(NotifyStack, {
        Size             = UDim2.new(1, 0, 0, 56),
        BackgroundColor3 = Color3.fromRGB(15, 15, 20),
        BackgroundTransparency = 0.1,
        BorderSizePixel  = 0,
        LayoutOrder      = -notifyCount,
    })
    roundCorners(card, 10)
    addStroke(card, color or Color3.fromRGB(255, 255, 255), 1.5)

    makeTL(card, {
        Size             = UDim2.new(1, -12, 1, 0),
        Position         = UDim2.new(0, 6, 0, 0),
        BackgroundTransparency = 1,
        Text             = msg,
        TextColor3       = color or Color3.fromRGB(255, 255, 255),
        TextScaled       = true,
        Font             = Enum.Font.GothamBold,
        TextXAlignment   = Enum.TextXAlignment.Left,
        TextWrapped      = true,
    })

    -- Animação de saída após 4 segundos
    task.delay(3.5, function()
        TweenService:Create(card, TweenInfo.new(0.4), {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
        }):Play()
        task.wait(0.4)
        if card then card:Destroy() end
    end)
end

-- ============================================================
--  ESTADO DO CLIENTE
-- ============================================================
local currentData = {
    aura        = 0,
    auraCap     = GameConfig.BASE_AURA_CAP,
    rebirths    = 0,
    multiplier  = 1,
    rebirthCost = math.floor(GameConfig.BASE_AURA_CAP * GameConfig.REBIRTH_COST_FRACTION),
    totalStolen = 0,
}

local function formatNum(n)
    if n >= 1e9  then return string.format("%.2fB", n / 1e9) end
    if n >= 1e6  then return string.format("%.2fM", n / 1e6) end
    if n >= 1000 then return string.format("%.1fK", n / 1000) end
    return tostring(math.floor(n))
end

local function refreshUI()
    local d = currentData

    -- Aura panel
    AuraValueLabel.Text = formatNum(d.aura) .. " / " .. formatNum(d.auraCap)
    local pct = (d.auraCap > 0) and math.clamp(d.aura / d.auraCap, 0, 1) or 0
    TweenService:Create(BarFill, TweenInfo.new(0.35, Enum.EasingStyle.Quad), {
        Size = UDim2.new(pct, 0, 1, 0),
    }):Play()

    -- Cor da barra: verde → amarelo → vermelho conforme enchimento
    local barColor
    if pct < 0.5 then
        barColor = Color3.fromRGB(80, 220, 80)
    elseif pct < 0.85 then
        barColor = Color3.fromRGB(255, 200, 0)
    else
        barColor = Color3.fromRGB(255, 70, 70)
    end
    BarFill.BackgroundColor3 = barColor

    -- Stats
    RebirthsLabel.Text = "Rebirths: " .. tostring(d.rebirths)
    MultLabel.Text     = "Multiplicador: x" .. formatNum(d.multiplier)
    StolenLabel.Text   = "Roubados: " .. tostring(d.totalStolen)
    CostLabel.Text     = "Custo RB: " .. formatNum(d.rebirthCost)

    -- Botão rebirth
    local canRebirth = d.aura >= d.rebirthCost
    RebirthBtn.Text = string.format("RENASCER  (%s / %s)", formatNum(d.aura), formatNum(d.rebirthCost))
    RebirthBtn.BackgroundColor3 = canRebirth and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(80, 80, 80)
    RebirthBtn.TextColor3       = canRebirth and Color3.fromRGB(30, 20, 0)   or Color3.fromRGB(160, 160, 160)
end

-- ============================================================
--  EVENTOS DO SERVIDOR
-- ============================================================
UpdateAuraRE.OnClientEvent:Connect(function(payload)
    for k, v in pairs(payload) do
        currentData[k] = v
    end
    refreshUI()
end)

NotifyRE.OnClientEvent:Connect(function(msg, color)
    showNotification(msg, color)
end)

-- ============================================================
--  DETECÇÃO DE BRAINROT PRÓXIMO
-- ============================================================
local nearestBrainrot = nil

RunService.Heartbeat:Connect(function()
    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local folder = workspace:FindFirstChild("Brainrots")
    if not folder then return end

    local best     = nil
    local bestDist = GameConfig.STEAL_RANGE

    for _, part in ipairs(folder:GetChildren()) do
        if part:IsA("BasePart") then
            local d = (root.Position - part.Position).Magnitude
            if d < bestDist then
                bestDist = d
                best     = part
            end
        end
    end

    nearestBrainrot = best
    local show      = best ~= nil
    StealPrompt.Visible    = show
    MobileStealBtn.Visible = show

    if best then
        local meta = best:FindFirstChild("Meta")
        if meta then
            local bName  = meta:FindFirstChild("BrainrotName") and meta.BrainrotName.Value or "?"
            local rarity = meta:FindFirstChild("Rarity")       and meta.Rarity.Value       or "Comum"
            local aura   = meta:FindFirstChild("AuraValue")    and meta.AuraValue.Value    or 0
            local gained = math.floor(aura * currentData.multiplier)

            StealNameLabel.Text  = bName
            StealRarLabel.Text   = "[" .. rarity .. "]  +" .. formatNum(gained) .. " aura"
            StealRarLabel.TextColor3 = GameConfig.RARITY_COLORS[rarity] or Color3.fromRGB(255,255,255)
        end
    end
end)

-- ============================================================
--  INPUT
-- ============================================================
local function doSteal()
    if nearestBrainrot and nearestBrainrot.Parent then
        StealEvent:FireServer(nearestBrainrot)
    end
end

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.E then
        doSteal()
    end
end)

MobileStealBtn.Activated:Connect(doSteal)

RebirthBtn.Activated:Connect(function()
    RebirthEvent:FireServer()
end)

-- Efeito hover no botão de rebirth
RebirthBtn.MouseEnter:Connect(function()
    TweenService:Create(RebirthBtn, TweenInfo.new(0.15), {
        Size = UDim2.new(0, 246, 0, 60),
        Position = UDim2.new(0.5, -123, 1, -74),
    }):Play()
end)
RebirthBtn.MouseLeave:Connect(function()
    TweenService:Create(RebirthBtn, TweenInfo.new(0.15), {
        Size = UDim2.new(0, 230, 0, 56),
        Position = UDim2.new(0.5, -115, 1, -72),
    }):Play()
end)

-- Inicializa UI
refreshUI()
print("[BrainrotRoubo] Interface carregada!")
