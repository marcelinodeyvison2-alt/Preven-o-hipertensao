-- UIManager.lua (ModuleScript em StarterPlayerScripts/Modules)
-- Gerencia toda a interface grafica do jogo

local UIManager = {}

local TweenService   = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GameConfig     = require(game:GetService("ReplicatedStorage"):WaitForChild("GameConfig"))

-- Referencia ao ScreenGui principal (definida em Setup)
local mainGui = nil

-- ============================================================
-- HELPERS: cria elementos UI padronizados
-- ============================================================
local function makeFrame(props)
    local f = Instance.new("Frame")
    f.BackgroundColor3  = props.bg or Color3.fromRGB(15, 15, 40)
    f.BorderSizePixel   = 0
    f.Size              = props.size or UDim2.new(1, 0, 1, 0)
    f.Position          = props.pos or UDim2.new(0, 0, 0, 0)
    f.ZIndex            = props.z or 1
    f.BackgroundTransparency = props.trans or 0
    if props.clip then f.ClipsDescendants = true end
    if props.parent then f.Parent = props.parent end

    if props.corner then
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, props.corner)
        c.Parent = f
    end
    return f
end

local function makeLabel(props)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Size       = props.size or UDim2.new(1, 0, 1, 0)
    l.Position   = props.pos or UDim2.new(0, 0, 0, 0)
    l.Text       = props.text or ""
    l.TextColor3 = props.color or Color3.new(1, 1, 1)
    l.Font       = props.font or Enum.Font.GothamBold
    l.TextScaled = true
    l.ZIndex     = props.z or 2
    l.TextStrokeTransparency = props.stroke ~= nil and props.stroke or 0.5
    if props.parent then l.Parent = props.parent end
    return l
end

local function makeButton(props)
    local b = Instance.new("TextButton")
    b.BackgroundColor3 = props.bg or Color3.fromRGB(50, 50, 150)
    b.BorderSizePixel  = 0
    b.Size             = props.size or UDim2.new(0.8, 0, 0, 50)
    b.Position         = props.pos or UDim2.new(0.1, 0, 0, 0)
    b.Text             = props.text or "Button"
    b.TextColor3       = props.textColor or Color3.new(1, 1, 1)
    b.Font             = Enum.Font.GothamBold
    b.TextScaled       = true
    b.ZIndex           = props.z or 2
    b.AutoButtonColor  = false
    if props.corner then
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, props.corner or 10)
        c.Parent = b
    end
    if props.parent then b.Parent = props.parent end

    -- Hover effects
    b.MouseEnter:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.1), { BackgroundColor3 = (props.bg or Color3.fromRGB(50,50,150)):Lerp(Color3.new(1,1,1), 0.15) }):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.1), { BackgroundColor3 = props.bg or Color3.fromRGB(50,50,150) }):Play()
    end)

    return b
end

local function addStroke(instance, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color     = color or Color3.fromRGB(100,100,255)
    s.Thickness = thickness or 2
    s.Parent    = instance
    return s
end

-- ============================================================
-- SETUP: cria toda a UI base
-- ============================================================
function UIManager.Setup(screenGui)
    mainGui = screenGui

    -- Background espacial (gradiente)
    local bg = makeFrame({
        bg     = Color3.fromRGB(5, 5, 20),
        parent = screenGui,
    })

    local bgGrad = Instance.new("UIGradient")
    bgGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(5, 0, 20)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(10, 5, 30)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 5, 15)),
    })
    bgGrad.Rotation = 135
    bgGrad.Parent = bg

    return bg
end

-- ============================================================
-- AREA DE SPIN: roleta central + botoes
-- ============================================================
function UIManager.CreateSpinArea(parent, callbacks)
    -- Container central
    local spinArea = makeFrame({
        bg     = Color3.fromRGB(0,0,0),
        trans  = 1,
        size   = UDim2.new(1, 0, 0.55, 0),
        pos    = UDim2.new(0, 0, 0.05, 0),
        parent = parent,
    })

    -- Titulo
    local title = makeLabel({
        size   = UDim2.new(1, 0, 0, 60),
        pos    = UDim2.new(0, 0, 0, 0),
        text   = "SOL's RNG - AURA ROLLER",
        color  = Color3.fromRGB(255, 200, 0),
        z      = 5,
        parent = spinArea,
    })
    title.TextStrokeColor3 = Color3.fromRGB(255,100,0)
    title.TextStrokeTransparency = 0

    -- Janela de animacao da roleta
    local rollWindow = makeFrame({
        bg     = Color3.fromRGB(10, 10, 30),
        size   = UDim2.new(0.9, 0, 0, 100),
        pos    = UDim2.new(0.05, 0, 0, 65),
        corner = 15,
        clip   = true,
        parent = spinArea,
    })
    addStroke(rollWindow, Color3.fromRGB(80, 80, 200), 3)

    -- Indicador central (seta)
    local indicator = makeLabel({
        size   = UDim2.new(0, 10, 1, 0),
        pos    = UDim2.new(0.5, -5, 0, 0),
        text   = "",
        z      = 10,
        parent = rollWindow,
    })
    indicator.BackgroundColor3       = Color3.fromRGB(255, 50, 50)
    indicator.BackgroundTransparency = 0

    -- Frame interno para as auras deslizando
    local rollStrip = makeFrame({
        bg     = Color3.fromRGB(0,0,0),
        trans  = 1,
        size   = UDim2.new(20, 0, 1, 0),
        pos    = UDim2.new(0, 0, 0, 0),
        z      = 5,
        parent = rollWindow,
    })
    rollStrip.Name = "RollStrip"

    -- Label do resultado atual
    local resultLabel = makeLabel({
        size   = UDim2.new(0.9, 0, 0, 50),
        pos    = UDim2.new(0.05, 0, 0, 170),
        text   = "CLIQUE PARA GIRAR!",
        color  = Color3.fromRGB(200, 200, 255),
        z      = 5,
        parent = spinArea,
    })
    resultLabel.Name = "ResultLabel"

    -- ---- BOTOES DE TIPO DE ROLETA ----
    local rollTypeFrame = makeFrame({
        bg    = Color3.fromRGB(0,0,0),
        trans = 1,
        size  = UDim2.new(0.9, 0, 0, 50),
        pos   = UDim2.new(0.05, 0, 0, 225),
        parent = spinArea,
    })

    local layout = Instance.new("UIListLayout")
    layout.FillDirection     = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.Padding           = UDim.new(0, 8)
    layout.Parent            = rollTypeFrame

    local selectedRollType = "normal"
    local rollTypeButtons   = {}

    for _, rt in ipairs(GameConfig.ROLL_TYPES) do
        local btn = makeButton({
            bg       = rt.color,
            size     = UDim2.new(0, 130, 1, 0),
            pos      = UDim2.new(0, 0, 0, 0),
            text     = rt.icon .. " " .. rt.name,
            corner   = 8,
            z        = 6,
            parent   = rollTypeFrame,
        })
        btn.Name = "RollType_" .. rt.id
        rollTypeButtons[rt.id] = btn

        btn.MouseButton1Click:Connect(function()
            selectedRollType = rt.id
            -- Visual de selecao
            for id, b in pairs(rollTypeButtons) do
                b.BackgroundTransparency = id == rt.id and 0 or 0.5
            end
            if callbacks.onRollTypeChange then callbacks.onRollTypeChange(rt) end
        end)
    end

    -- ---- BOTAO PRINCIPAL DE GIRO ----
    local spinBtn = makeButton({
        bg       = Color3.fromRGB(0, 180, 80),
        size     = UDim2.new(0, 200, 0, 65),
        pos      = UDim2.new(0.5, -100, 0, 280),
        text     = "🎰  GIRAR!",
        corner   = 32,
        z        = 6,
        parent   = spinArea,
    })
    spinBtn.Name = "SpinButton"

    -- Stroke dourado no botao de giro
    addStroke(spinBtn, Color3.fromRGB(255, 220, 0), 3)

    -- Cooldown overlay
    local cooldownOverlay = makeFrame({
        bg     = Color3.fromRGB(0, 0, 0),
        trans  = 0.5,
        size   = UDim2.new(1, 0, 1, 0),
        corner = 32,
        z      = 7,
        parent = spinBtn,
    })
    cooldownOverlay.Visible = false
    cooldownOverlay.Name    = "CooldownOverlay"

    local cooldownLabel = makeLabel({
        text   = "...",
        z      = 8,
        parent = cooldownOverlay,
    })
    cooldownLabel.Name = "CooldownLabel"

    spinBtn.MouseButton1Click:Connect(function()
        if callbacks.onSpin then callbacks.onSpin(selectedRollType) end
    end)

    return {
        spinBtn         = spinBtn,
        rollStrip       = rollStrip,
        resultLabel     = resultLabel,
        cooldownOverlay = cooldownOverlay,
        cooldownLabel   = cooldownLabel,
    }
end

-- ============================================================
-- HUD: moedas, gemas, evento ativo
-- ============================================================
function UIManager.CreateHUD(parent)
    local hudFrame = makeFrame({
        bg     = Color3.fromRGB(0,0,0),
        trans  = 1,
        size   = UDim2.new(1, 0, 0, 50),
        pos    = UDim2.new(0, 0, 0, 0),
        z      = 10,
        parent = parent,
    })

    -- Coins
    local coinsFrame = makeFrame({
        bg     = Color3.fromRGB(20, 20, 50),
        size   = UDim2.new(0, 160, 0, 40),
        pos    = UDim2.new(0, 10, 0, 5),
        corner = 8,
        z      = 10,
        parent = hudFrame,
    })

    makeLabel({
        size   = UDim2.new(1, 0, 1, 0),
        text   = "🪙 0",
        color  = Color3.fromRGB(255, 220, 0),
        z      = 11,
        parent = coinsFrame,
    }).Name = "CoinsLabel"

    -- Gems
    local gemsFrame = makeFrame({
        bg     = Color3.fromRGB(20, 20, 50),
        size   = UDim2.new(0, 130, 0, 40),
        pos    = UDim2.new(0, 180, 0, 5),
        corner = 8,
        z      = 10,
        parent = hudFrame,
    })

    makeLabel({
        size   = UDim2.new(1, 0, 1, 0),
        text   = "💎 0",
        color  = Color3.fromRGB(100, 200, 255),
        z      = 11,
        parent = gemsFrame,
    }).Name = "GemsLabel"

    -- Evento Ativo
    local eventFrame = makeFrame({
        bg     = Color3.fromRGB(60, 30, 0),
        size   = UDim2.new(0, 250, 0, 40),
        pos    = UDim2.new(1, -260, 0, 5),
        corner = 8,
        z      = 10,
        parent = hudFrame,
    })
    eventFrame.Visible = false
    eventFrame.Name    = "EventFrame"

    local eventLabel = makeLabel({
        size   = UDim2.new(1, 0, 1, 0),
        text   = "⚡ Evento!",
        color  = Color3.fromRGB(255, 220, 0),
        z      = 11,
        parent = eventFrame,
    })
    eventLabel.Name = "EventLabel"

    return {
        coinsFrame = coinsFrame,
        gemsFrame  = gemsFrame,
        eventFrame = eventFrame,
    }
end

-- ============================================================
-- PAINEL DE NAVEGACAO: botoes Inventario / Upgrades / Leaderboard
-- ============================================================
function UIManager.CreateNavPanel(parent, callbacks)
    local navFrame = makeFrame({
        bg     = Color3.fromRGB(10, 10, 30),
        size   = UDim2.new(1, 0, 0, 55),
        pos    = UDim2.new(0, 0, 1, -55),
        z      = 15,
        parent = parent,
    })
    addStroke(navFrame, Color3.fromRGB(80, 80, 200), 2)

    local btnDefs = {
        { text = "🎒 Inventario", id = "inventory",   bg = Color3.fromRGB(40, 100, 200) },
        { text = "⬆ Upgrades",   id = "upgrades",    bg = Color3.fromRGB(100, 40, 200) },
        { text = "🏆 Ranking",    id = "leaderboard", bg = Color3.fromRGB(200, 120, 0)  },
    }

    local layout = Instance.new("UIListLayout")
    layout.FillDirection       = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.Padding             = UDim.new(0, 10)
    layout.Parent              = navFrame

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft  = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)
    padding.PaddingTop   = UDim.new(0, 5)
    padding.Parent       = navFrame

    for _, def in ipairs(btnDefs) do
        local btn = makeButton({
            bg     = def.bg,
            size   = UDim2.new(0, 150, 0, 45),
            text   = def.text,
            corner = 10,
            z      = 16,
            parent = navFrame,
        })
        btn.MouseButton1Click:Connect(function()
            if callbacks.onNav then callbacks.onNav(def.id) end
        end)
    end
end

-- ============================================================
-- PAINEL DE INVENTARIO
-- ============================================================
function UIManager.CreateInventoryPanel(parent, callbacks)
    local panel = makeFrame({
        bg     = Color3.fromRGB(8, 8, 25),
        size   = UDim2.new(0.95, 0, 0.8, 0),
        pos    = UDim2.new(0.025, 0, 0.08, 0),
        corner = 15,
        z      = 20,
        parent = parent,
    })
    panel.Visible = false
    panel.Name    = "InventoryPanel"
    addStroke(panel, Color3.fromRGB(80, 80, 200), 3)

    -- Titulo
    makeLabel({
        size   = UDim2.new(1, 0, 0, 45),
        pos    = UDim2.new(0, 0, 0, 5),
        text   = "🎒 MEU INVENTARIO",
        color  = Color3.fromRGB(100, 200, 255),
        z      = 21,
        parent = panel,
    })

    -- Scroll frame para os itens
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size                  = UDim2.new(1, -20, 1, -60)
    scroll.Position              = UDim2.new(0, 10, 0, 55)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel       = 0
    scroll.ScrollBarThickness    = 6
    scroll.CanvasSize            = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize   = Enum.AutomaticSize.Y
    scroll.ScrollBarImageColor3  = Color3.fromRGB(80,80,200)
    scroll.ZIndex                = 21
    scroll.Parent                = panel
    scroll.Name                  = "InventoryScroll"

    local grid = Instance.new("UIGridLayout")
    grid.CellSize    = UDim2.new(0, 110, 0, 130)
    grid.CellPadding = UDim2.new(0, 8, 0, 8)
    grid.Parent      = scroll

    -- Botao fechar
    local closeBtn = makeButton({
        bg     = Color3.fromRGB(150, 30, 30),
        size   = UDim2.new(0, 40, 0, 40),
        pos    = UDim2.new(1, -45, 0, 5),
        text   = "✕",
        corner = 8,
        z      = 22,
        parent = panel,
    })
    closeBtn.MouseButton1Click:Connect(function()
        panel.Visible = false
    end)

    return panel
end

-- ============================================================
-- Popula inventario com dados do jogador
-- ============================================================
function UIManager.PopulateInventory(panel, inventoryData, activeAura, onEquip)
    local scroll = panel:FindFirstChild("InventoryScroll")
    if not scroll then return end

    -- Limpa itens existentes
    for _, child in ipairs(scroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    if #inventoryData == 0 then
        local emptyLabel = makeLabel({
            size   = UDim2.new(1, 0, 0, 60),
            pos    = UDim2.new(0, 0, 0, 10),
            text   = "Nenhuma aura ainda! Va girar!",
            color  = Color3.fromRGB(150, 150, 150),
            z      = 22,
            parent = scroll,
        })
        return
    end

    for _, item in ipairs(inventoryData) do
        local auraDef     = GameConfig.GetAuraByName(item.name)
        if not auraDef then continue end

        local rarityColor = GameConfig.RARITY_COLORS[item.rarity] or Color3.new(1,1,1)
        local isActive    = item.name == activeAura

        -- Card da aura
        local card = makeFrame({
            bg     = Color3.fromRGB(15, 15, 40),
            size   = UDim2.new(0, 110, 0, 130),
            corner = 10,
            z      = 22,
            parent = scroll,
        })

        -- Borda colorida
        local stroke = addStroke(card, rarityColor, isActive and 4 or 2)

        -- Nome da aura
        makeLabel({
            size   = UDim2.new(1, -4, 0, 35),
            pos    = UDim2.new(0, 2, 0, 5),
            text   = auraDef.name,
            color  = rarityColor,
            z      = 23,
            parent = card,
        })

        -- Raridade
        makeLabel({
            size   = UDim2.new(1, -4, 0, 25),
            pos    = UDim2.new(0, 2, 0, 42),
            text   = auraDef.rarity,
            color  = Color3.fromRGB(180, 180, 180),
            z      = 23,
            parent = card,
        })

        -- Count
        makeLabel({
            size   = UDim2.new(1, -4, 0, 22),
            pos    = UDim2.new(0, 2, 0, 68),
            text   = "x" .. item.count,
            color  = Color3.new(1,1,1),
            z      = 23,
            parent = card,
        })

        -- Chance
        makeLabel({
            size   = UDim2.new(1, -4, 0, 20),
            pos    = UDim2.new(0, 2, 0, 90),
            text   = "1/" .. tostring(auraDef.chance),
            color  = Color3.fromRGB(150,150,150),
            z      = 23,
            parent = card,
        })

        -- Botao equipar
        local equipBtn = makeButton({
            bg       = isActive and Color3.fromRGB(0, 180, 80) or Color3.fromRGB(40, 40, 100),
            size     = UDim2.new(1, -10, 0, 22),
            pos      = UDim2.new(0, 5, 1, -27),
            text     = isActive and "✔ ATIVA" or "EQUIPAR",
            corner   = 6,
            z        = 24,
            parent   = card,
        })

        local capturedName = item.name
        equipBtn.MouseButton1Click:Connect(function()
            if onEquip then onEquip(capturedName) end
        end)
    end
end

-- ============================================================
-- PAINEL DE UPGRADES
-- ============================================================
function UIManager.CreateUpgradesPanel(parent, callbacks)
    local panel = makeFrame({
        bg     = Color3.fromRGB(8, 8, 25),
        size   = UDim2.new(0.95, 0, 0.8, 0),
        pos    = UDim2.new(0.025, 0, 0.08, 0),
        corner = 15,
        z      = 20,
        parent = parent,
    })
    panel.Visible = false
    panel.Name    = "UpgradesPanel"
    addStroke(panel, Color3.fromRGB(130, 0, 200), 3)

    makeLabel({
        size   = UDim2.new(1, 0, 0, 45),
        pos    = UDim2.new(0, 0, 0, 5),
        text   = "⬆ UPGRADES",
        color  = Color3.fromRGB(180, 100, 255),
        z      = 21,
        parent = panel,
    })

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size                  = UDim2.new(1, -20, 1, -60)
    scroll.Position              = UDim2.new(0, 10, 0, 55)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel       = 0
    scroll.ScrollBarThickness    = 6
    scroll.CanvasSize            = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize   = Enum.AutomaticSize.Y
    scroll.ZIndex                = 21
    scroll.Parent                = panel
    scroll.Name                  = "UpgradesScroll"

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 10)
    layout.Parent  = scroll

    local closeBtn = makeButton({
        bg     = Color3.fromRGB(150, 30, 30),
        size   = UDim2.new(0, 40, 0, 40),
        pos    = UDim2.new(1, -45, 0, 5),
        text   = "✕",
        corner = 8,
        z      = 22,
        parent = panel,
    })
    closeBtn.MouseButton1Click:Connect(function() panel.Visible = false end)

    return panel
end

-- ============================================================
-- Popula upgrades
-- ============================================================
function UIManager.PopulateUpgrades(panel, playerUpgrades, playerCoins, playerGems, onBuy)
    local scroll = panel:FindFirstChild("UpgradesScroll")
    if not scroll then return end

    for _, child in ipairs(scroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    local typeColors = {
        Luck       = Color3.fromRGB(0, 200, 100),
        Speed      = Color3.fromRGB(255, 200, 0),
        Multiplier = Color3.fromRGB(255, 100, 0),
    }

    for _, upgDef in ipairs(GameConfig.UPGRADES) do
        local currentLevel = playerUpgrades[upgDef.id] or 0
        local isMax        = currentLevel >= upgDef.maxLevel
        local typeColor    = typeColors[upgDef.type] or Color3.new(1,1,1)

        local costMult = upgDef.costMultiplier ^ currentLevel
        local coinCost = math.floor(upgDef.baseCost.coins * costMult)
        local gemCost  = math.floor(upgDef.baseCost.gems  * costMult)

        local canAfford = playerCoins >= coinCost and playerGems >= gemCost

        -- Card do upgrade
        local card = makeFrame({
            bg     = Color3.fromRGB(12, 12, 35),
            size   = UDim2.new(1, -10, 0, 90),
            corner = 10,
            z      = 22,
            parent = scroll,
        })
        addStroke(card, typeColor, 2)

        -- Icone + Nome
        makeLabel({
            size   = UDim2.new(0.65, 0, 0, 35),
            pos    = UDim2.new(0, 10, 0, 5),
            text   = upgDef.icon .. " " .. upgDef.name .. " (Lv " .. currentLevel .. "/" .. upgDef.maxLevel .. ")",
            color  = typeColor,
            z      = 23,
            parent = card,
        })

        -- Descricao
        makeLabel({
            size   = UDim2.new(0.65, 0, 0, 30),
            pos    = UDim2.new(0, 10, 0, 40),
            text   = upgDef.description,
            color  = Color3.fromRGB(180, 180, 180),
            z      = 23,
            parent = card,
        })

        -- Custo
        makeLabel({
            size   = UDim2.new(0.65, 0, 0, 22),
            pos    = UDim2.new(0, 10, 0, 68),
            text   = isMax and "MAXIMO!" or ("🪙 " .. coinCost .. (gemCost > 0 and "  💎 " .. gemCost or "")),
            color  = isMax and Color3.fromRGB(255, 220, 0) or (canAfford and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100)),
            z      = 23,
            parent = card,
        })

        -- Botao comprar
        local buyBtn = makeButton({
            bg     = isMax and Color3.fromRGB(50,50,50) or (canAfford and typeColor or Color3.fromRGB(60,60,60)),
            size   = UDim2.new(0, 120, 0, 70),
            pos    = UDim2.new(1, -130, 0, 10),
            text   = isMax and "MAX" or "COMPRAR",
            corner = 8,
            z      = 24,
            parent = card,
        })
        buyBtn.Active = not isMax

        local capturedId = upgDef.id
        buyBtn.MouseButton1Click:Connect(function()
            if isMax then return end
            if onBuy then onBuy(capturedId) end
        end)
    end
end

-- ============================================================
-- PAINEL DE LEADERBOARD
-- ============================================================
function UIManager.CreateLeaderboardPanel(parent)
    local panel = makeFrame({
        bg     = Color3.fromRGB(8, 8, 25),
        size   = UDim2.new(0.95, 0, 0.8, 0),
        pos    = UDim2.new(0.025, 0, 0.08, 0),
        corner = 15,
        z      = 20,
        parent = parent,
    })
    panel.Visible = false
    panel.Name    = "LeaderboardPanel"
    addStroke(panel, Color3.fromRGB(255, 165, 0), 3)

    makeLabel({
        size   = UDim2.new(1, 0, 0, 45),
        pos    = UDim2.new(0, 0, 0, 5),
        text   = "🏆 RANKING GLOBAL",
        color  = Color3.fromRGB(255, 215, 0),
        z      = 21,
        parent = panel,
    })

    -- Duas colunas: auras e coins
    local colAuras = makeFrame({
        bg     = Color3.fromRGB(12,12,35),
        size   = UDim2.new(0.48, 0, 0.85, 0),
        pos    = UDim2.new(0.01, 0, 0.12, 0),
        corner = 10,
        z      = 21,
        parent = panel,
    })

    makeLabel({
        size   = UDim2.new(1,0,0,35),
        pos    = UDim2.new(0,0,0,5),
        text   = "🎒 Total de Auras",
        color  = Color3.fromRGB(100,200,255),
        z      = 22,
        parent = colAuras,
    })

    local scrollAuras = Instance.new("ScrollingFrame")
    scrollAuras.Size                  = UDim2.new(1, -10, 1, -45)
    scrollAuras.Position              = UDim2.new(0, 5, 0, 45)
    scrollAuras.BackgroundTransparency = 1
    scrollAuras.BorderSizePixel       = 0
    scrollAuras.ScrollBarThickness    = 4
    scrollAuras.CanvasSize            = UDim2.new(0,0,0,0)
    scrollAuras.AutomaticCanvasSize   = Enum.AutomaticSize.Y
    scrollAuras.ZIndex                = 22
    scrollAuras.Name                  = "ScrollAuras"
    scrollAuras.Parent                = colAuras
    Instance.new("UIListLayout", scrollAuras).Padding = UDim.new(0,4)

    local colCoins = makeFrame({
        bg     = Color3.fromRGB(12,12,35),
        size   = UDim2.new(0.48, 0, 0.85, 0),
        pos    = UDim2.new(0.51, 0, 0.12, 0),
        corner = 10,
        z      = 21,
        parent = panel,
    })

    makeLabel({
        size   = UDim2.new(1,0,0,35),
        pos    = UDim2.new(0,0,0,5),
        text   = "🪙 Total de Coins",
        color  = Color3.fromRGB(255,220,0),
        z      = 22,
        parent = colCoins,
    })

    local scrollCoins = Instance.new("ScrollingFrame")
    scrollCoins.Size                  = UDim2.new(1,-10,1,-45)
    scrollCoins.Position              = UDim2.new(0,5,0,45)
    scrollCoins.BackgroundTransparency = 1
    scrollCoins.BorderSizePixel       = 0
    scrollCoins.ScrollBarThickness    = 4
    scrollCoins.CanvasSize            = UDim2.new(0,0,0,0)
    scrollCoins.AutomaticCanvasSize   = Enum.AutomaticSize.Y
    scrollCoins.ZIndex                = 22
    scrollCoins.Name                  = "ScrollCoins"
    scrollCoins.Parent                = colCoins
    Instance.new("UIListLayout", scrollCoins).Padding = UDim.new(0,4)

    local closeBtn = makeButton({
        bg     = Color3.fromRGB(150, 30, 30),
        size   = UDim2.new(0, 40, 0, 40),
        pos    = UDim2.new(1, -45, 0, 5),
        text   = "✕",
        corner = 8,
        z      = 22,
        parent = panel,
    })
    closeBtn.MouseButton1Click:Connect(function() panel.Visible = false end)

    return panel
end

-- ============================================================
-- Popula leaderboard
-- ============================================================
function UIManager.PopulateLeaderboard(panel, lbData)
    local scrollAuras = panel:FindFirstChild("ScrollAuras", true)
    local scrollCoins = panel:FindFirstChild("ScrollCoins", true)

    local function fillScroll(scroll, data, valuePrefix)
        if not scroll then return end
        for _, c in ipairs(scroll:GetChildren()) do
            if c:IsA("Frame") then c:Destroy() end
        end

        local rankColors = {
            Color3.fromRGB(255,215,0),
            Color3.fromRGB(200,200,200),
            Color3.fromRGB(205,127,50),
        }

        for i, entry in ipairs(data) do
            local row = makeFrame({
                bg     = Color3.fromRGB(15,15,40),
                size   = UDim2.new(1,-6,0,32),
                corner = 6,
                z      = 23,
                parent = scroll,
            })
            makeLabel({
                size   = UDim2.new(1,-10,1,0),
                pos    = UDim2.new(0,5,0,0),
                text   = "#" .. entry.rank .. "  " .. entry.name .. "  —  " .. (valuePrefix or "") .. tostring(entry.score),
                color  = rankColors[i] or Color3.fromRGB(180,180,180),
                z      = 24,
                parent = row,
            })
        end
    end

    if lbData then
        fillScroll(scrollAuras, lbData.totalAuras or {}, "")
        fillScroll(scrollCoins, lbData.totalCoins or {}, "🪙 ")
    end
end

-- ============================================================
-- NOTIFICACAO FLUTUANTE (mensagem que sobe e desaparece)
-- ============================================================
function UIManager.ShowNotification(parent, msg, color, duration)
    color    = color or Color3.fromRGB(255, 255, 255)
    duration = duration or 3

    local notif = Instance.new("TextLabel")
    notif.BackgroundTransparency = 1
    notif.Size       = UDim2.new(0.8, 0, 0, 45)
    notif.Position   = UDim2.new(0.1, 0, 0.45, 0)
    notif.Text       = msg
    notif.TextColor3 = color
    notif.Font       = Enum.Font.GothamBold
    notif.TextScaled = true
    notif.ZIndex     = 30
    notif.TextStrokeColor3 = Color3.new(0,0,0)
    notif.TextStrokeTransparency = 0
    notif.Parent     = parent

    local tweenUp = TweenService:Create(notif,
        TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Position = UDim2.new(0.1, 0, 0.3, 0), TextTransparency = 1 }
    )
    tweenUp:Play()
    tweenUp.Completed:Connect(function() notif:Destroy() end)
end

-- ============================================================
-- ANIMACAO DA ROLETA
-- ============================================================
function UIManager.AnimateRoll(rollStrip, sequence, onComplete)
    -- Limpa strip
    for _, c in ipairs(rollStrip:GetChildren()) do c:Destroy() end

    local ITEM_WIDTH = 150
    local items = {}

    for i, auraName in ipairs(sequence) do
        local auraDef  = GameConfig.GetAuraByName(auraName)
        local rColor   = auraDef and GameConfig.RARITY_COLORS[auraDef.rarity] or Color3.new(1,1,1)

        local item = makeFrame({
            bg     = Color3.fromRGB(10, 10, 30),
            size   = UDim2.new(0, ITEM_WIDTH, 1, -10),
            pos    = UDim2.new(0, (i-1) * (ITEM_WIDTH + 5), 0, 5),
            corner = 8,
            z      = 6,
            parent = rollStrip,
        })
        addStroke(item, rColor, 2)

        makeLabel({
            size   = UDim2.new(1,0,0.6,0),
            pos    = UDim2.new(0,0,0.1,0),
            text   = auraName,
            color  = rColor,
            z      = 7,
            parent = item,
        })

        table.insert(items, item)
    end

    rollStrip.Size = UDim2.new(0, #sequence * (ITEM_WIDTH + 5), 1, 0)

    -- Animacao de scroll
    -- Posicao alvo: ultimo item no centro
    local windowWidth = rollStrip.Parent.AbsoluteSize.X
    local finalX = -(#sequence * (ITEM_WIDTH + 5) - windowWidth / 2 - ITEM_WIDTH / 2)

    rollStrip.Position = UDim2.new(0, 0, 0, 0)

    local tween = TweenService:Create(rollStrip,
        TweenInfo.new(GameConfig.SETTINGS.SPIN_ANIMATION_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Position = UDim2.new(0, finalX, 0, 0) }
    )
    tween:Play()
    tween.Completed:Connect(function()
        if onComplete then onComplete() end
    end)
end

-- ============================================================
-- UPDATE HUD (moedas/gemas)
-- ============================================================
function UIManager.UpdateHUD(hudRef, coins, gems)
    local coinsLabel = hudRef.coinsFrame:FindFirstChild("CoinsLabel")
    local gemsLabel  = hudRef.gemsFrame:FindFirstChild("GemsLabel")
    if coinsLabel then coinsLabel.Text = "🪙 " .. tostring(coins) end
    if gemsLabel  then gemsLabel.Text  = "💎 " .. tostring(gems)  end
end

-- ============================================================
-- UPDATE EVENTO HUD
-- ============================================================
function UIManager.UpdateEventHUD(hudRef, eventDef, timeRemaining)
    local eventFrame = hudRef.eventFrame
    local eventLabel = eventFrame:FindFirstChild("EventLabel")

    if eventDef then
        eventFrame.Visible = true
        if eventLabel then
            local mins = math.floor(timeRemaining / 60)
            local secs = timeRemaining % 60
            eventLabel.Text = eventDef.icon .. " " .. eventDef.name .. " [" .. string.format("%d:%02d", mins, secs) .. "]"
        end
    else
        eventFrame.Visible = false
    end
end

return UIManager
