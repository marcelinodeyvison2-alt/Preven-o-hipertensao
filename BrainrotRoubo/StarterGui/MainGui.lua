-- LocalScript: StarterGui > MainGui
-- Interface: aura, rebirth, prompt de roubo, Index e Lua de Sangue

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")

local player     = Players.LocalPlayer
local playerGui  = player.PlayerGui
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local RemoteFolder     = ReplicatedStorage:WaitForChild("Remotes")
local StealEvent       = RemoteFolder:WaitForChild("StealBrainrot")
local UpdateAuraRE     = RemoteFolder:WaitForChild("UpdateAura")
local NotifyRE         = RemoteFolder:WaitForChild("Notify")
local RebirthEvent     = RemoteFolder:WaitForChild("Rebirth")
local IndexUpdateRE    = RemoteFolder:WaitForChild("IndexUpdate")
local GlobalAnnounceRE = RemoteFolder:WaitForChild("GlobalAnnounce")

-- =====================================================
--  HELPERS
-- =====================================================
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
local function makeTB(parent, props)
    local f = Instance.new("TextButton")
    for k, v in pairs(props) do f[k] = v end
    f.Parent = parent
    return f
end
local function round(obj, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 10)
    c.Parent = obj
end
local function stroke(obj, color, thick)
    local s = Instance.new("UIStroke")
    s.Color     = color or Color3.fromRGB(255,255,255)
    s.Thickness = thick or 1.5
    s.Parent    = obj
    return s  -- necessário para capturar o objeto e animar depois
end
local function formatNum(n)
    if n >= 1e12 then return string.format("%.1fT", n/1e12) end
    if n >= 1e9  then return string.format("%.1fB", n/1e9)  end
    if n >= 1e6  then return string.format("%.1fM", n/1e6)  end
    if n >= 1000 then return string.format("%.1fK", n/1000) end
    return tostring(math.floor(n))
end

-- =====================================================
--  SCREEN GUI
-- =====================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "MainGui"
ScreenGui.ResetOnSpawn   = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent         = playerGui

-- =====================================================
--  PAINEL DE AURA (topo centro)
-- =====================================================
local AuraPanel = makeFrame(ScreenGui, {
    Size             = UDim2.new(0, 370, 0, 115),
    Position         = UDim2.new(0.5, -185, 0, 12),
    BackgroundColor3 = Color3.fromRGB(12, 12, 18),
    BackgroundTransparency = 0.15,
    BorderSizePixel  = 0,
})
round(AuraPanel, 14)
stroke(AuraPanel, Color3.fromRGB(255, 200, 50), 2)

makeTL(AuraPanel, {
    Size             = UDim2.new(1, 0, 0.26, 0),
    BackgroundTransparency = 1,
    Text             = "✦  AURA  ✦",
    TextColor3       = Color3.fromRGB(255, 210, 60),
    TextScaled       = true,
    Font             = Enum.Font.GothamBold,
})

local AuraValueLabel = makeTL(AuraPanel, {
    Size             = UDim2.new(1, 0, 0.38, 0),
    Position         = UDim2.new(0, 0, 0.26, 0),
    BackgroundTransparency = 1,
    Text             = "0 / 500",
    TextColor3       = Color3.fromRGB(255, 255, 255),
    TextScaled       = true,
    Font             = Enum.Font.GothamBold,
})

local BarBg = makeFrame(AuraPanel, {
    Size             = UDim2.new(0.88, 0, 0.14, 0),
    Position         = UDim2.new(0.06, 0, 0.72, 0),
    BackgroundColor3 = Color3.fromRGB(35, 35, 50),
    BorderSizePixel  = 0,
})
round(BarBg, 6)

local BarFill = makeFrame(BarBg, {
    Size             = UDim2.new(0, 0, 1, 0),
    BackgroundColor3 = Color3.fromRGB(80, 220, 80),
    BorderSizePixel  = 0,
})
round(BarFill, 6)

-- =====================================================
--  PAINEL DE STATS (esquerda)
-- =====================================================
local StatsPanel = makeFrame(ScreenGui, {
    Size             = UDim2.new(0, 210, 0, 145),
    Position         = UDim2.new(0, 12, 0, 12),
    BackgroundColor3 = Color3.fromRGB(12, 12, 18),
    BackgroundTransparency = 0.2,
    BorderSizePixel  = 0,
})
round(StatsPanel, 12)
stroke(StatsPanel, Color3.fromRGB(120, 80, 255), 1.5)

local function statRow(yOff, lbl, def)
    return makeTL(StatsPanel, {
        Size             = UDim2.new(1, -10, 0, 26),
        Position         = UDim2.new(0, 5, 0, yOff),
        BackgroundTransparency = 1,
        Text             = lbl .. ": " .. def,
        TextColor3       = Color3.fromRGB(220, 220, 220),
        TextScaled       = true,
        Font             = Enum.Font.Gotham,
        TextXAlignment   = Enum.TextXAlignment.Left,
    })
end
local RebirthsLabel = statRow(6,   "Rebirths",    "0")
local MultLabel     = statRow(36,  "Mult",         "x1")
local StolenLabel   = statRow(66,  "Roubados",     "0")
local CostLabel     = statRow(96,  "Custo RB",     "400")
local MutLabel      = statRow(120, "Última Mut",   "-")

-- =====================================================
--  BOTÃO REBIRTH (baixo centro)
-- =====================================================
local RebirthBtn = makeTB(ScreenGui, {
    Size             = UDim2.new(0, 240, 0, 58),
    Position         = UDim2.new(0.5, -120, 1, -74),
    BackgroundColor3 = Color3.fromRGB(80, 80, 80),
    BorderSizePixel  = 0,
    Text             = "RENASCER  (0 / 400)",
    TextColor3       = Color3.fromRGB(160, 160, 160),
    TextScaled       = true,
    Font             = Enum.Font.GothamBold,
})
round(RebirthBtn, 14)
stroke(RebirthBtn, Color3.fromRGB(255, 230, 100), 2)

RebirthBtn.MouseEnter:Connect(function()
    TweenService:Create(RebirthBtn, TweenInfo.new(0.12), {
        Size = UDim2.new(0, 256, 0, 62),
        Position = UDim2.new(0.5, -128, 1, -76),
    }):Play()
end)
RebirthBtn.MouseLeave:Connect(function()
    TweenService:Create(RebirthBtn, TweenInfo.new(0.12), {
        Size = UDim2.new(0, 240, 0, 58),
        Position = UDim2.new(0.5, -120, 1, -74),
    }):Play()
end)

-- =====================================================
--  PROMPT DE ROUBO
-- =====================================================
local StealPrompt = makeFrame(ScreenGui, {
    Size             = UDim2.new(0, 300, 0, 110),
    Position         = UDim2.new(0.5, -150, 0.72, 0),
    BackgroundColor3 = Color3.fromRGB(8, 8, 14),
    BackgroundTransparency = 0.08,
    BorderSizePixel  = 0,
    Visible          = false,
})
round(StealPrompt, 14)
local stealStroke = stroke(StealPrompt, Color3.fromRGB(255, 255, 255), 1.5)

local StealNameLabel = makeTL(StealPrompt, {
    Size             = UDim2.new(1, 0, 0.35, 0),
    BackgroundTransparency = 1,
    Text             = "Brainrot",
    TextColor3       = Color3.fromRGB(255, 255, 255),
    TextScaled       = true,
    Font             = Enum.Font.GothamBold,
})
local StealRarLabel = makeTL(StealPrompt, {
    Size             = UDim2.new(1, 0, 0.25, 0),
    Position         = UDim2.new(0, 0, 0.34, 0),
    BackgroundTransparency = 1,
    Text             = "[Comum]",
    TextColor3       = Color3.fromRGB(180, 180, 180),
    TextScaled       = true,
    Font             = Enum.Font.Gotham,
})
local StealMutLabel = makeTL(StealPrompt, {
    Size             = UDim2.new(1, 0, 0.22, 0),
    Position         = UDim2.new(0, 0, 0.58, 0),
    BackgroundTransparency = 1,
    Text             = "✦ Básico ×1",
    TextColor3       = Color3.fromRGB(180, 180, 180),
    TextScaled       = true,
    Font             = Enum.Font.GothamBold,
})
local StealKeyLabel = makeTL(StealPrompt, {
    Size             = UDim2.new(1, 0, 0.22, 0),
    Position         = UDim2.new(0, 0, 0.78, 0),
    BackgroundTransparency = 1,
    Text             = "[E] Roubar",
    TextColor3       = Color3.fromRGB(255, 210, 50),
    TextScaled       = true,
    Font             = Enum.Font.GothamBold,
})

-- Botão mobile
local MobileStealBtn = makeTB(ScreenGui, {
    Size             = UDim2.new(0, 130, 0, 130),
    Position         = UDim2.new(1, -150, 1, -160),
    BackgroundColor3 = Color3.fromRGB(200, 50, 50),
    BorderSizePixel  = 0,
    Text             = "ROUBAR",
    TextColor3       = Color3.fromRGB(255, 255, 255),
    TextScaled       = true,
    Font             = Enum.Font.GothamBold,
    Visible          = false,
})
round(MobileStealBtn, 65)
stroke(MobileStealBtn, Color3.fromRGB(255, 180, 180), 2)

-- =====================================================
--  NOTIFICAÇÕES (toast)
-- =====================================================
local NotifyStack = makeFrame(ScreenGui, {
    Size             = UDim2.new(0, 380, 1, 0),
    Position         = UDim2.new(1, -392, 0, 0),
    BackgroundTransparency = 1,
    BorderSizePixel  = 0,
})
local notifyLayout = Instance.new("UIListLayout")
notifyLayout.SortOrder        = Enum.SortOrder.LayoutOrder
notifyLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
notifyLayout.Padding          = UDim.new(0, 6)
notifyLayout.Parent           = NotifyStack

local notifyCount = 0

local function showNotification(msg, color, big)
    notifyCount = notifyCount + 1
    local h = big and 72 or 54

    local card = makeFrame(NotifyStack, {
        Size             = UDim2.new(1, 0, 0, h),
        BackgroundColor3 = Color3.fromRGB(10, 10, 16),
        BackgroundTransparency = 0.08,
        BorderSizePixel  = 0,
        LayoutOrder      = -notifyCount,
    })
    round(card, 10)
    stroke(card, color or Color3.fromRGB(255,255,255), big and 2 or 1.5)

    makeTL(card, {
        Size             = UDim2.new(1, -14, 1, 0),
        Position         = UDim2.new(0, 7, 0, 0),
        BackgroundTransparency = 1,
        Text             = msg,
        TextColor3       = color or Color3.fromRGB(255, 255, 255),
        TextScaled       = true,
        Font             = big and Enum.Font.GothamBold or Enum.Font.Gotham,
        TextXAlignment   = Enum.TextXAlignment.Left,
        TextWrapped      = true,
    })

    task.delay(big and 6 or 3.5, function()
        TweenService:Create(card, TweenInfo.new(0.4), {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
        }):Play()
        task.wait(0.42)
        if card then card:Destroy() end
    end)
end

-- Banner global de Lua de Sangue (centro da tela)
local LuaBanner = makeFrame(ScreenGui, {
    Size             = UDim2.new(0.7, 0, 0, 80),
    Position         = UDim2.new(0.15, 0, 0.12, 0),
    BackgroundColor3 = Color3.fromRGB(80, 0, 0),
    BackgroundTransparency = 0.1,
    BorderSizePixel  = 0,
    Visible          = false,
    ZIndex           = 10,
})
round(LuaBanner, 16)
stroke(LuaBanner, Color3.fromRGB(255, 0, 0), 3)

local LuaBannerLabel = makeTL(LuaBanner, {
    Size             = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    Text             = "🌑 LUA DE SANGUE!",
    TextColor3       = Color3.fromRGB(255, 80, 80),
    TextScaled       = true,
    Font             = Enum.Font.GothamBold,
    TextWrapped      = true,
    ZIndex           = 11,
})

-- =====================================================
--  PAINEL DE INDEX
-- =====================================================
local IndexOpen = false

-- Botão para abrir o Index (canto inferior esquerdo)
local IndexBtn = makeTB(ScreenGui, {
    Size             = UDim2.new(0, 120, 0, 46),
    Position         = UDim2.new(0, 12, 1, -62),
    BackgroundColor3 = Color3.fromRGB(30, 30, 50),
    BorderSizePixel  = 0,
    Text             = "📋 INDEX",
    TextColor3       = Color3.fromRGB(200, 200, 255),
    TextScaled       = true,
    Font             = Enum.Font.GothamBold,
})
round(IndexBtn, 12)
stroke(IndexBtn, Color3.fromRGB(100, 100, 200), 1.5)

-- Painel principal do Index
local IndexPanel = makeFrame(ScreenGui, {
    Size             = UDim2.new(0, 560, 0, 480),
    Position         = UDim2.new(0.5, -280, 0.5, -240),
    BackgroundColor3 = Color3.fromRGB(10, 10, 18),
    BackgroundTransparency = 0.05,
    BorderSizePixel  = 0,
    Visible          = false,
    ZIndex           = 5,
})
round(IndexPanel, 16)
stroke(IndexPanel, Color3.fromRGB(120, 80, 255), 2)

-- Título do Index
makeTL(IndexPanel, {
    Size             = UDim2.new(1, 0, 0, 44),
    BackgroundColor3 = Color3.fromRGB(18, 18, 30),
    BackgroundTransparency = 0,
    Text             = "📋  ÍNDICE DE BRAINROTS",
    TextColor3       = Color3.fromRGB(200, 180, 255),
    TextScaled       = true,
    Font             = Enum.Font.GothamBold,
    ZIndex           = 6,
})

-- Botão fechar
local CloseIndexBtn = makeTB(IndexPanel, {
    Size             = UDim2.new(0, 40, 0, 36),
    Position         = UDim2.new(1, -46, 0, 4),
    BackgroundColor3 = Color3.fromRGB(180, 40, 40),
    BorderSizePixel  = 0,
    Text             = "✕",
    TextColor3       = Color3.fromRGB(255, 255, 255),
    TextScaled       = true,
    Font             = Enum.Font.GothamBold,
    ZIndex           = 7,
})
round(CloseIndexBtn, 8)

-- Abas
local TAB_BRAINROTS = "Brainrots"
local TAB_MUTATIONS = "Mutações"
local currentTab    = TAB_BRAINROTS

local tabBar = makeFrame(IndexPanel, {
    Size             = UDim2.new(1, 0, 0, 38),
    Position         = UDim2.new(0, 0, 0, 44),
    BackgroundColor3 = Color3.fromRGB(18, 18, 30),
    BorderSizePixel  = 0,
    ZIndex           = 6,
})

local function makeTabBtn(text, xPos)
    return makeTB(tabBar, {
        Size             = UDim2.new(0.48, 0, 1, -4),
        Position         = UDim2.new(xPos, 0, 0, 2),
        BackgroundColor3 = Color3.fromRGB(30, 30, 50),
        BorderSizePixel  = 0,
        Text             = text,
        TextColor3       = Color3.fromRGB(160, 160, 200),
        TextScaled       = true,
        Font             = Enum.Font.GothamBold,
        ZIndex           = 7,
    })
end
local TabBrainrots = makeTabBtn(TAB_BRAINROTS, 0.01)
local TabMutations = makeTabBtn(TAB_MUTATIONS, 0.51)
round(TabBrainrots, 8)
round(TabMutations, 8)

-- Área de scroll do conteúdo
local IndexScroll = Instance.new("ScrollingFrame")
IndexScroll.Size             = UDim2.new(1, -12, 1, -92)
IndexScroll.Position         = UDim2.new(0, 6, 0, 88)
IndexScroll.BackgroundTransparency = 1
IndexScroll.BorderSizePixel  = 0
IndexScroll.ScrollBarThickness = 6
IndexScroll.ScrollBarImageColor3 = Color3.fromRGB(120, 80, 255)
IndexScroll.CanvasSize       = UDim2.new(0, 0, 0, 0)
IndexScroll.ZIndex           = 6
IndexScroll.Parent           = IndexPanel

local scrollLayout = Instance.new("UIListLayout")
scrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
scrollLayout.Padding   = UDim.new(0, 4)
scrollLayout.Parent    = IndexScroll

-- Estado do index local
local localIndex = { brainrots = {}, mutations = {} }

-- Ordem de raridades para exibição
local RARITY_ORDER = {
    "Comum", "Incomum", "Raro", "Epico", "Lendario", "Mitico", "God", "Secret", "OG"
}

local function buildIndexUI()
    -- Limpa scroll
    for _, c in ipairs(IndexScroll:GetChildren()) do
        if c:IsA("GuiObject") then c:Destroy() end
    end

    if currentTab == TAB_BRAINROTS then
        -- Agrupa brainrots por raridade
        local grouped = {}
        for _, rarity in ipairs(RARITY_ORDER) do grouped[rarity] = {} end

        for _, bt in ipairs(GameConfig.BRAINROT_TYPES) do
            if grouped[bt.rarity] then
                table.insert(grouped[bt.rarity], bt)
            end
        end

        local layoutOrder = 0

        for _, rarity in ipairs(RARITY_ORDER) do
            local list = grouped[rarity]
            if #list == 0 then continue end

            local rarColor = GameConfig.RARITY_COLORS[rarity] or Color3.fromRGB(200,200,200)

            -- Cabeçalho de raridade
            layoutOrder = layoutOrder + 1
            local header = makeFrame(IndexScroll, {
                Size             = UDim2.new(1, -4, 0, 28),
                BackgroundColor3 = Color3.fromRGB(20, 20, 35),
                BorderSizePixel  = 0,
                LayoutOrder      = layoutOrder,
                ZIndex           = 7,
            })
            round(header, 6)
            stroke(header, rarColor, 1)
            makeTL(header, {
                Size             = UDim2.new(1, -8, 1, 0),
                Position         = UDim2.new(0, 4, 0, 0),
                BackgroundTransparency = 1,
                Text             = "── " .. rarity:upper() .. " ──",
                TextColor3       = rarColor,
                TextScaled       = true,
                Font             = Enum.Font.GothamBold,
                TextXAlignment   = Enum.TextXAlignment.Left,
                ZIndex           = 8,
            })

            -- Entradas de brainrot
            for _, bt in ipairs(list) do
                layoutOrder = layoutOrder + 1
                local entry       = localIndex.brainrots[bt.name]
                local discovered  = entry ~= nil
                local count       = discovered and entry.count or 0
                local bestMut     = discovered and entry.bestMutation or "-"

                local row = makeFrame(IndexScroll, {
                    Size             = UDim2.new(1, -4, 0, 46),
                    BackgroundColor3 = discovered
                        and Color3.fromRGB(18, 18, 28)
                        or  Color3.fromRGB(12, 12, 18),
                    BackgroundTransparency = discovered and 0.05 or 0.3,
                    BorderSizePixel  = 0,
                    LayoutOrder      = layoutOrder,
                    ZIndex           = 7,
                })
                round(row, 7)
                if discovered then stroke(row, rarColor, 1) end

                -- Indicador de cor (barra lateral)
                local colorBar = makeFrame(row, {
                    Size             = UDim2.new(0, 5, 1, -4),
                    Position         = UDim2.new(0, 2, 0, 2),
                    BackgroundColor3 = rarColor,
                    BorderSizePixel  = 0,
                    ZIndex           = 8,
                })
                round(colorBar, 3)

                -- Nome
                local displayName = discovered and bt.name or "???"
                makeTL(row, {
                    Size             = UDim2.new(0.55, 0, 0.52, 0),
                    Position         = UDim2.new(0, 12, 0, 2),
                    BackgroundTransparency = 1,
                    Text             = displayName,
                    TextColor3       = discovered and Color3.fromRGB(240,240,240) or Color3.fromRGB(80,80,80),
                    TextScaled       = true,
                    Font             = Enum.Font.GothamBold,
                    TextXAlignment   = Enum.TextXAlignment.Left,
                    ZIndex           = 8,
                })

                -- Aura base
                makeTL(row, {
                    Size             = UDim2.new(0.4, 0, 0.42, 0),
                    Position         = UDim2.new(0.58, 0, 0.04, 0),
                    BackgroundTransparency = 1,
                    Text             = discovered and (formatNum(bt.baseAura) .. " aura base") or "???",
                    TextColor3       = Color3.fromRGB(180, 180, 180),
                    TextScaled       = true,
                    Font             = Enum.Font.Gotham,
                    TextXAlignment   = Enum.TextXAlignment.Right,
                    ZIndex           = 8,
                })

                -- Roubados e melhor mutação
                if discovered then
                    local mutColor = Color3.fromRGB(180,180,180)
                    for _, m in ipairs(GameConfig.MUTATIONS) do
                        if m.name == bestMut then mutColor = m.color break end
                    end

                    makeTL(row, {
                        Size             = UDim2.new(0.5, 0, 0.4, 0),
                        Position         = UDim2.new(0, 12, 0.54, 0),
                        BackgroundTransparency = 1,
                        Text             = "Roubados: " .. count,
                        TextColor3       = Color3.fromRGB(140, 210, 140),
                        TextScaled       = true,
                        Font             = Enum.Font.Gotham,
                        TextXAlignment   = Enum.TextXAlignment.Left,
                        ZIndex           = 8,
                    })
                    makeTL(row, {
                        Size             = UDim2.new(0.48, 0, 0.4, 0),
                        Position         = UDim2.new(0.5, 0, 0.54, 0),
                        BackgroundTransparency = 1,
                        Text             = "Melhor: " .. bestMut,
                        TextColor3       = mutColor,
                        TextScaled       = true,
                        Font             = Enum.Font.GothamBold,
                        TextXAlignment   = Enum.TextXAlignment.Right,
                        ZIndex           = 8,
                    })
                end
            end
        end

    else
        -- ABA MUTAÇÕES
        local layoutOrder = 0
        for _, mut in ipairs(GameConfig.MUTATIONS) do
            layoutOrder = layoutOrder + 1
            local count      = localIndex.mutations[mut.name] or 0
            local discovered = count > 0
            local isLua      = (mut.name == "Lua de Sangue")

            local row = makeFrame(IndexScroll, {
                Size             = UDim2.new(1, -4, 0, 58),
                BackgroundColor3 = isLua
                    and Color3.fromRGB(30, 5, 5)
                    or  (discovered and Color3.fromRGB(18, 18, 28) or Color3.fromRGB(12,12,18)),
                BackgroundTransparency = 0.05,
                BorderSizePixel  = 0,
                LayoutOrder      = layoutOrder,
                ZIndex           = 7,
            })
            round(row, 8)
            stroke(row, mut.color, isLua and 2.5 or (discovered and 1.5 or 0.5))

            -- Bolinha de cor
            local dot = makeFrame(row, {
                Size             = UDim2.new(0, 36, 0, 36),
                Position         = UDim2.new(0, 8, 0.5, -18),
                BackgroundColor3 = mut.color,
                BorderSizePixel  = 0,
                ZIndex           = 8,
            })
            round(dot, 18)

            -- Nome da mutação
            local prefix = isLua and "🌑 " or "✦ "
            makeTL(row, {
                Size             = UDim2.new(0.5, 0, 0.5, 0),
                Position         = UDim2.new(0, 52, 0, 4),
                BackgroundTransparency = 1,
                Text             = prefix .. mut.name,
                TextColor3       = mut.color,
                TextScaled       = true,
                Font             = Enum.Font.GothamBold,
                TextXAlignment   = Enum.TextXAlignment.Left,
                ZIndex           = 8,
            })

            -- Multiplicador
            makeTL(row, {
                Size             = UDim2.new(0.35, 0, 0.45, 0),
                Position         = UDim2.new(0.62, 0, 0.06, 0),
                BackgroundTransparency = 1,
                Text             = "×" .. tostring(mut.multiplier),
                TextColor3       = Color3.fromRGB(255, 255, 255),
                TextScaled       = true,
                Font             = Enum.Font.GothamBold,
                TextXAlignment   = Enum.TextXAlignment.Right,
                ZIndex           = 8,
            })

            -- Quantidade e nota especial
            makeTL(row, {
                Size             = UDim2.new(0.5, 0, 0.42, 0),
                Position         = UDim2.new(0, 52, 0.52, 0),
                BackgroundTransparency = 1,
                Text             = discovered and ("Obtida: " .. count .. "x") or "Não obtida",
                TextColor3       = discovered and Color3.fromRGB(140,210,140) or Color3.fromRGB(80,80,80),
                TextScaled       = true,
                Font             = Enum.Font.Gotham,
                TextXAlignment   = Enum.TextXAlignment.Left,
                ZIndex           = 8,
            })

            if isLua then
                makeTL(row, {
                    Size             = UDim2.new(0.38, 0, 0.4, 0),
                    Position         = UDim2.new(0.6, 0, 0.54, 0),
                    BackgroundTransparency = 1,
                    Text             = "a cada 10.000 spawns",
                    TextColor3       = Color3.fromRGB(200, 80, 80),
                    TextScaled       = true,
                    Font             = Enum.Font.Gotham,
                    TextXAlignment   = Enum.TextXAlignment.Right,
                    ZIndex           = 8,
                })
            end
        end
    end

    -- Atualiza canvas size
    IndexScroll.CanvasSize = UDim2.new(0, 0, 0, scrollLayout.AbsoluteContentSize.Y + 8)
end

local function setTab(tab)
    currentTab = tab
    local activeC   = Color3.fromRGB(80, 60, 160)
    local inactiveC = Color3.fromRGB(30, 30, 50)
    TabBrainrots.BackgroundColor3 = (tab == TAB_BRAINROTS) and activeC or inactiveC
    TabMutations.BackgroundColor3 = (tab == TAB_MUTATIONS) and activeC or inactiveC
    TabBrainrots.TextColor3 = (tab == TAB_BRAINROTS) and Color3.fromRGB(255,255,255) or Color3.fromRGB(160,160,200)
    TabMutations.TextColor3 = (tab == TAB_MUTATIONS) and Color3.fromRGB(255,255,255) or Color3.fromRGB(160,160,200)
    buildIndexUI()
end
setTab(TAB_BRAINROTS)

local function toggleIndex()
    IndexOpen = not IndexOpen
    IndexPanel.Visible = IndexOpen
    IndexBtn.BackgroundColor3 = IndexOpen
        and Color3.fromRGB(80, 60, 160)
        or  Color3.fromRGB(30, 30, 50)
    if IndexOpen then buildIndexUI() end
end

IndexBtn.Activated:Connect(toggleIndex)
CloseIndexBtn.Activated:Connect(function() IndexOpen = true; toggleIndex() end)
TabBrainrots.Activated:Connect(function() setTab(TAB_BRAINROTS) end)
TabMutations.Activated:Connect(function() setTab(TAB_MUTATIONS) end)

-- =====================================================
--  ESTADO DO CLIENTE
-- =====================================================
local currentData = {
    aura        = 0,
    auraCap     = GameConfig.BASE_AURA_CAP,
    rebirths    = 0,
    multiplier  = 1,
    rebirthCost = math.floor(GameConfig.BASE_AURA_CAP * GameConfig.REBIRTH_COST_FRACTION),
    totalStolen = 0,
}
local lastMutation = "Básico"

local function refreshUI()
    local d = currentData

    AuraValueLabel.Text = formatNum(d.aura) .. " / " .. formatNum(d.auraCap)
    local pct = math.clamp(d.aura / math.max(d.auraCap, 1), 0, 1)
    TweenService:Create(BarFill, TweenInfo.new(0.35, Enum.EasingStyle.Quad), {
        Size = UDim2.new(pct, 0, 1, 0),
    }):Play()

    local barColor = pct < 0.5 and Color3.fromRGB(80,220,80)
                  or pct < 0.85 and Color3.fromRGB(255,200,0)
                  or Color3.fromRGB(255,70,70)
    BarFill.BackgroundColor3 = barColor

    RebirthsLabel.Text = "Rebirths: "    .. tostring(d.rebirths)
    MultLabel.Text     = "Mult: x"       .. formatNum(d.multiplier)
    StolenLabel.Text   = "Roubados: "    .. tostring(d.totalStolen)
    CostLabel.Text     = "Custo RB: "    .. formatNum(d.rebirthCost)
    MutLabel.Text      = "Última Mut: "  .. lastMutation

    local canRB = d.aura >= d.rebirthCost
    RebirthBtn.Text             = string.format("RENASCER  (%s / %s)", formatNum(d.aura), formatNum(d.rebirthCost))
    RebirthBtn.BackgroundColor3 = canRB and Color3.fromRGB(255,200,0) or Color3.fromRGB(80,80,80)
    RebirthBtn.TextColor3       = canRB and Color3.fromRGB(30,20,0)   or Color3.fromRGB(160,160,160)
end

-- =====================================================
--  EVENTOS DO SERVIDOR
-- =====================================================
UpdateAuraRE.OnClientEvent:Connect(function(payload)
    for k, v in pairs(payload) do currentData[k] = v end
    refreshUI()
end)

NotifyRE.OnClientEvent:Connect(function(msg, color)
    showNotification(msg, color)
    -- Atualiza última mutação se a mensagem contiver "×"
    local mutMatch = msg:match("%[(.-)%s×")
    if mutMatch then lastMutation = mutMatch; refreshUI() end
end)

IndexUpdateRE.OnClientEvent:Connect(function(indexData)
    localIndex = indexData
    if IndexOpen then buildIndexUI() end
end)

GlobalAnnounceRE.OnClientEvent:Connect(function(msg, color)
    showNotification(msg, color, true)
    -- Exibe banner especial
    LuaBannerLabel.Text = msg
    LuaBanner.Visible   = true
    TweenService:Create(LuaBanner, TweenInfo.new(0.3), {
        BackgroundTransparency = 0.1,
    }):Play()
    task.delay(5, function()
        TweenService:Create(LuaBanner, TweenInfo.new(0.5), {
            BackgroundTransparency = 1,
        }):Play()
        task.wait(0.52)
        LuaBanner.Visible = false
        LuaBanner.BackgroundTransparency = 0.1
    end)
end)

-- =====================================================
--  DETECÇÃO DE BRAINROT PRÓXIMO
-- =====================================================
local nearestBrainrot = nil
local luaPulseT       = 0

RunService.Heartbeat:Connect(function(dt)
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
            if d < bestDist then bestDist = d; best = part end
        end
    end

    nearestBrainrot = best
    local show = best ~= nil
    StealPrompt.Visible    = show
    MobileStealBtn.Visible = show

    if best then
        local meta   = best:FindFirstChild("Meta")
        local isLua  = false
        if meta then
            local bName   = meta:FindFirstChild("BrainrotName") and meta.BrainrotName.Value or "?"
            local rarity  = meta:FindFirstChild("Rarity")       and meta.Rarity.Value       or "Comum"
            local aura    = meta:FindFirstChild("AuraValue")    and meta.AuraValue.Value    or 0
            local mutName = meta:FindFirstChild("MutationName") and meta.MutationName.Value or "Básico"
            local mutMult = meta:FindFirstChild("MutationMult") and meta.MutationMult.Value or 1
            isLua = (mutName == "Lua de Sangue")

            local gained = math.floor(aura * mutMult * currentData.multiplier)
            local rarColor = GameConfig.RARITY_COLORS[rarity] or Color3.fromRGB(255,255,255)
            local mutColor = Color3.fromRGB(180,180,180)
            for _, m in ipairs(GameConfig.MUTATIONS) do
                if m.name == mutName then mutColor = m.color break end
            end

            StealNameLabel.Text  = isLua and ("🌑 " .. bName) or bName
            StealRarLabel.Text   = "[" .. rarity .. "]  +" .. formatNum(gained) .. " aura"
            StealRarLabel.TextColor3 = rarColor

            local mutPrefix = isLua and "🌑 " or "✦ "
            StealMutLabel.Text      = mutPrefix .. mutName .. "  ×" .. tostring(mutMult)
            StealMutLabel.TextColor3 = mutColor
        end

        -- Pulso vermelho no borde quando é Lua de Sangue
        if isLua then
            luaPulseT = luaPulseT + dt * 4
            local alpha = (math.sin(luaPulseT) + 1) / 2
            stealStroke.Color     = Color3.fromRGB(
                math.floor(180 + alpha * 75), 0, 0)
            stealStroke.Thickness = 2 + alpha * 2
        else
            luaPulseT             = 0
            stealStroke.Color     = Color3.fromRGB(255, 255, 255)
            stealStroke.Thickness = 1.5
        end
    end
end)

-- =====================================================
--  INPUT
-- =====================================================
local function doSteal()
    if nearestBrainrot and nearestBrainrot.Parent then
        StealEvent:FireServer(nearestBrainrot)
    end
end

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.E then doSteal() end
end)

MobileStealBtn.Activated:Connect(doSteal)
RebirthBtn.Activated:Connect(function() RebirthEvent:FireServer() end)

refreshUI()
print("[BrainrotRoubo] Interface carregada com Index e sistema de Mutações!")
