-- GUIManager.lua (client ModuleScript)
-- Builds and manages all ScreenGui elements:
--   HUD, CapturePopup, Inventory panel, Ranking panel, Notification toasts.

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local GameConfig     = require(game.ReplicatedStorage.Modules.GameConfig)
local BrainrotConfig = require(game.ReplicatedStorage.Modules.BrainrotConfig)

local GUIManager = {}
local localPlayer = Players.LocalPlayer
local playerGui   = localPlayer:WaitForChild("PlayerGui")

-- ── Shared builders ───────────────────────────────────────────────────────────

local C = GameConfig.UIColors

local function newSG(name, zIndex)
    local sg = Instance.new("ScreenGui")
    sg.Name           = name
    sg.ResetOnSpawn   = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder   = zIndex or 1
    sg.Parent         = playerGui
    return sg
end

local function corner(parent, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(r or 0.1, 0)
    c.Parent = parent
end

local function stroke(parent, color, thick)
    local s = Instance.new("UIStroke")
    s.Color     = color or Color3.fromRGB(80, 60, 200)
    s.Thickness = thick or 2
    s.Parent    = parent
end

local function label(parent, props)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Font                   = Enum.Font.GothamBold
    l.TextColor3             = C.Text
    l.TextScaled             = true
    l.TextWrapped            = true
    for k, v in pairs(props) do l[k] = v end
    l.Parent = parent
    return l
end

local function button(parent, props, callback)
    local b = Instance.new("TextButton")
    b.AutoButtonColor    = false
    b.Font               = Enum.Font.GothamBold
    b.TextScaled         = true
    b.TextColor3         = C.Text
    b.BackgroundColor3   = C.Accent
    for k, v in pairs(props) do b[k] = v end
    b.Parent = parent
    corner(b, 0.15)
    if callback then
        b.MouseButton1Click:Connect(callback)
        b.MouseEnter:Connect(function()
            TweenService:Create(b, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(130, 110, 255)}):Play()
        end)
        b.MouseLeave:Connect(function()
            TweenService:Create(b, TweenInfo.new(0.1), {BackgroundColor3 = C.Accent}):Play()
        end)
    end
    return b
end

local function frame(parent, props)
    local f = Instance.new("Frame")
    f.BackgroundColor3 = C.Panel
    for k, v in pairs(props) do f[k] = v end
    f.Parent = parent
    return f
end

-- ── HUD ───────────────────────────────────────────────────────────────────────

local hudSG = newSG("HUD_GUI", 1)

local hudBar = frame(hudSG, {
    Size               = UDim2.new(1, 0, 0, 60),
    Position           = UDim2.new(0, 0, 0, 0),
    BackgroundColor3   = Color3.fromRGB(12, 12, 28),
    BackgroundTransparency = 0.1,
})

-- Aura display
local auraLabel = label(hudBar, {
    Name     = "AuraLabel",
    Size     = UDim2.new(0.28, 0, 1, 0),
    Position = UDim2.new(0.01, 0, 0, 0),
    Text     = "⭐ 0 Aura",
    TextColor3 = C.Gold,
    TextXAlignment = Enum.TextXAlignment.Left,
})

-- Brainrot count
local countLabel = label(hudBar, {
    Name     = "CountLabel",
    Size     = UDim2.new(0.25, 0, 1, 0),
    Position = UDim2.new(0.29, 0, 0, 0),
    Text     = "🧠 0 Brainrots",
    TextXAlignment = Enum.TextXAlignment.Left,
})

-- Current area
local areaLabel = label(hudBar, {
    Name     = "AreaLabel",
    Size     = UDim2.new(0.25, 0, 1, 0),
    Position = UDim2.new(0.54, 0, 0, 0),
    Text     = "📍 Campo Inicial",
    TextXAlignment = Enum.TextXAlignment.Left,
})

-- Open Inventory button (top-right)
local invBtn = button(hudBar, {
    Size     = UDim2.new(0, 130, 0, 44),
    Position = UDim2.new(1, -274, 0.5, -22),
    Text     = "🎒 Inventário",
    BackgroundColor3 = Color3.fromRGB(60, 50, 160),
})

-- Open Ranking button
local rankBtn = button(hudBar, {
    Size     = UDim2.new(0, 130, 0, 44),
    Position = UDim2.new(1, -136, 0.5, -22),
    Text     = "🏆 Ranking",
    BackgroundColor3 = Color3.fromRGB(160, 120, 0),
})

-- ── Capture Popup ─────────────────────────────────────────────────────────────

local popupSG = newSG("CapturePopup_GUI", 5)

local capturePopup = frame(popupSG, {
    Name               = "CapturePopup",
    Size               = UDim2.new(0, 320, 0, 110),
    Position           = UDim2.new(0.5, -160, 0, -130),
    BackgroundColor3   = Color3.fromRGB(15, 15, 35),
    BackgroundTransparency = 0.1,
})
corner(capturePopup, 0.12)
stroke(capturePopup)

local popupTitle = label(capturePopup, {
    Size     = UDim2.new(1, -10, 0.4, 0),
    Position = UDim2.new(0, 5, 0.05, 0),
    Text     = "✨ Brainrot Capturado!",
    TextColor3 = C.Gold,
    Font     = Enum.Font.GothamBold,
})

local popupName = label(capturePopup, {
    Size     = UDim2.new(1, -10, 0.32, 0),
    Position = UDim2.new(0, 5, 0.42, 0),
    Text     = "",
    Font     = Enum.Font.Gotham,
})

local popupRarity = label(capturePopup, {
    Size     = UDim2.new(1, -10, 0.25, 0),
    Position = UDim2.new(0, 5, 0.73, 0),
    Text     = "",
    Font     = Enum.Font.Gotham,
})

local popupVisible = false

local function showCapturePopup(entry)
    if popupVisible then return end
    popupVisible = true

    local rarityColor = GameConfig.RarityColors[entry.Rarity] or C.Text
    local rarityName  = GameConfig.RarityNames[entry.Rarity]  or entry.Rarity

    popupName.Text       = (entry.Emoji or "") .. " " .. entry.Name
    popupRarity.Text     = rarityName .. "  •  +" .. entry.AuraValue .. " Aura"
    popupRarity.TextColor3 = rarityColor
    stroke(capturePopup, rarityColor, 2)

    TweenService:Create(capturePopup, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -160, 0, 10),
    }):Play()

    task.delay(2.5, function()
        TweenService:Create(capturePopup, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Position = UDim2.new(0.5, -160, 0, -130),
        }):Play()
        task.wait(0.3)
        popupVisible = false
    end)
end

-- ── Notification Toast ────────────────────────────────────────────────────────

local notifSG = newSG("Notif_GUI", 4)

local notifQueue = {}
local notifActive = false

local notifFrame = frame(notifSG, {
    Size             = UDim2.new(0, 340, 0, 60),
    Position         = UDim2.new(0.5, -170, 1, 20),
    BackgroundColor3 = Color3.fromRGB(20, 20, 45),
    BackgroundTransparency = 0.1,
})
corner(notifFrame, 0.15)

local notifLabel = label(notifFrame, {
    Size     = UDim2.new(1, -12, 1, 0),
    Position = UDim2.new(0, 6, 0, 0),
    Text     = "",
    TextXAlignment = Enum.TextXAlignment.Left,
})

local function processNotifQueue()
    if notifActive or #notifQueue == 0 then return end
    notifActive = true

    local notif = table.remove(notifQueue, 1)
    local typeColors = {
        [GameConfig.NotifType.Success] = C.Success,
        [GameConfig.NotifType.Error]   = C.Error,
        [GameConfig.NotifType.Info]    = C.Accent,
        [GameConfig.NotifType.Rare]    = C.Gold,
    }
    local col = typeColors[notif.type] or C.Text
    stroke(notifFrame, col, 2)
    notifLabel.Text      = notif.message
    notifLabel.TextColor3 = col

    TweenService:Create(notifFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -170, 1, -78),
    }):Play()

    task.delay(2.8, function()
        TweenService:Create(notifFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Position = UDim2.new(0.5, -170, 1, 20),
        }):Play()
        task.wait(0.3)
        notifActive = false
        processNotifQueue()
    end)
end

local function pushNotification(data)
    notifQueue[#notifQueue + 1] = data
    processNotifQueue()
end

-- ── Inventory Panel ───────────────────────────────────────────────────────────

local invSG = newSG("Inventory_GUI", 3)
invSG.Enabled = false

local invPanel = frame(invSG, {
    Size             = UDim2.new(0.85, 0, 0.85, 0),
    Position         = UDim2.new(0.075, 0, 0.075, 0),
    BackgroundColor3 = C.Background,
})
corner(invPanel, 0.04)
stroke(invPanel, C.Accent, 2)

-- Title bar
local invTitle = label(invPanel, {
    Size     = UDim2.new(1, -60, 0, 50),
    Position = UDim2.new(0, 8, 0, 4),
    Text     = "🎒 Inventário",
    TextXAlignment = Enum.TextXAlignment.Left,
    Font     = Enum.Font.GothamBold,
    TextColor3 = C.Gold,
})

local invClose = button(invPanel, {
    Size     = UDim2.new(0, 44, 0, 44),
    Position = UDim2.new(1, -50, 0, 4),
    Text     = "✕",
    BackgroundColor3 = C.Error,
}, function() invSG.Enabled = false end)

-- Stats bar
local invStatsBar = frame(invPanel, {
    Size             = UDim2.new(1, -16, 0, 42),
    Position         = UDim2.new(0, 8, 0, 58),
    BackgroundColor3 = C.Panel,
})
corner(invStatsBar, 0.12)

local invStatsLabel = label(invStatsBar, {
    Size     = UDim2.new(0.7, 0, 1, 0),
    Position = UDim2.new(0, 6, 0, 0),
    Text     = "0 itens  •  Valor total: 0 Aura",
    TextXAlignment = Enum.TextXAlignment.Left,
    Font     = Enum.Font.Gotham,
})

-- Sell all button
local invSellAll = button(invStatsBar, {
    Size     = UDim2.new(0, 140, 0, 32),
    Position = UDim2.new(1, -146, 0.5, -16),
    Text     = "💰 Vender Tudo",
    BackgroundColor3 = Color3.fromRGB(180, 140, 0),
})

-- Scroll frame for items
local invScroll = Instance.new("ScrollingFrame")
invScroll.Size               = UDim2.new(1, -16, 1, -120)
invScroll.Position           = UDim2.new(0, 8, 0, 108)
invScroll.BackgroundColor3   = C.Panel
invScroll.BackgroundTransparency = 0.5
invScroll.ScrollBarThickness = 6
invScroll.ScrollBarImageColor3 = C.Accent
invScroll.CanvasSize         = UDim2.new(0, 0, 0, 0)
invScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
invScroll.Parent             = invPanel
corner(invScroll, 0.05)

local invGrid = Instance.new("UIGridLayout")
invGrid.CellSize    = UDim2.new(0, 160, 0, 90)
invGrid.CellPadding = UDim2.new(0, 8, 0, 8)
invGrid.SortOrder   = Enum.SortOrder.LayoutOrder
invGrid.Parent      = invScroll

local invPadding = Instance.new("UIPadding")
invPadding.PaddingAll = UDim.new(0, 8)
invPadding.Parent     = invScroll

local currentInventory     = {}
local currentUnlockedAreas = {}

local function refreshInventoryUI()
    -- Clear existing cards
    for _, child in ipairs(invScroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    local totalValue = 0
    local rarityGroups = {}

    for _, item in ipairs(currentInventory) do
        totalValue = totalValue + (item.AuraValue or 0)
        rarityGroups[item.Rarity] = (rarityGroups[item.Rarity] or 0) + 1

        -- Item card
        local card = frame(invScroll, {
            Size             = UDim2.new(0, 160, 0, 90),
            BackgroundColor3 = Color3.fromRGB(22, 22, 48),
        })
        corner(card, 0.12)

        local rarityColor = GameConfig.RarityColors[item.Rarity] or C.Text
        stroke(card, rarityColor, 2)

        label(card, {
            Size     = UDim2.new(1, -6, 0.5, 0),
            Position = UDim2.new(0, 3, 0, 2),
            Text     = (item.Emoji or "🧠") .. " " .. item.Name,
            Font     = Enum.Font.Gotham,
        })
        label(card, {
            Size     = UDim2.new(1, -6, 0.28, 0),
            Position = UDim2.new(0, 3, 0.5, 0),
            Text     = GameConfig.RarityNames[item.Rarity] or item.Rarity,
            TextColor3 = rarityColor,
            Font     = Enum.Font.Gotham,
        })
        label(card, {
            Size     = UDim2.new(1, -6, 0.25, 0),
            Position = UDim2.new(0, 3, 0.75, 0),
            Text     = item.AuraValue .. " Aura",
            TextColor3 = C.Gold,
            Font     = Enum.Font.Gotham,
        })
    end

    invStatsLabel.Text = #currentInventory .. " itens  •  Valor total: " .. totalValue .. " Aura"
end

local function refreshAreasUI()
    -- Areas panel is embedded in inventory for simplicity
    -- Handled in the area-unlock section below
end

invSellAll.MouseButton1Click:Connect(function()
    local remotes = game.ReplicatedStorage:WaitForChild("RemoteEvents")
    remotes.SellBrainrots:FireServer(nil) -- nil = sell all
end)

-- ── Ranking Panel ─────────────────────────────────────────────────────────────

local rankSG = newSG("Ranking_GUI", 3)
rankSG.Enabled = false

local rankPanel = frame(rankSG, {
    Size             = UDim2.new(0.6, 0, 0.8, 0),
    Position         = UDim2.new(0.2, 0, 0.1, 0),
    BackgroundColor3 = C.Background,
})
corner(rankPanel, 0.04)
stroke(rankPanel, Color3.fromRGB(200, 160, 0), 2)

label(rankPanel, {
    Size     = UDim2.new(1, -60, 0, 52),
    Position = UDim2.new(0, 8, 0, 4),
    Text     = "🏆 Ranking Global",
    TextColor3 = C.Gold,
    Font     = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
})

local rankClose = button(rankPanel, {
    Size     = UDim2.new(0, 44, 0, 44),
    Position = UDim2.new(1, -50, 0, 4),
    Text     = "✕",
    BackgroundColor3 = C.Error,
}, function() rankSG.Enabled = false end)

local rankScroll = Instance.new("ScrollingFrame")
rankScroll.Size               = UDim2.new(1, -16, 1, -70)
rankScroll.Position           = UDim2.new(0, 8, 0, 62)
rankScroll.BackgroundColor3   = C.Panel
rankScroll.BackgroundTransparency = 0.5
rankScroll.ScrollBarThickness = 6
rankScroll.ScrollBarImageColor3 = Color3.fromRGB(200, 160, 0)
rankScroll.CanvasSize         = UDim2.new(0, 0, 0, 0)
rankScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
rankScroll.Parent             = rankPanel
corner(rankScroll, 0.05)

local rankLayout2 = Instance.new("UIListLayout")
rankLayout2.SortOrder = Enum.SortOrder.LayoutOrder
rankLayout2.Padding   = UDim.new(0, 4)
rankLayout2.Parent    = rankScroll

local MEDALS = { "🥇", "🥈", "🥉" }

local function refreshRankingPanel(ranking)
    for _, child in ipairs(rankScroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    for i, entry in ipairs(ranking) do
        local row = frame(rankScroll, {
            Size             = UDim2.new(1, -8, 0, 48),
            BackgroundColor3 = (i % 2 == 0) and Color3.fromRGB(18,18,40) or Color3.fromRGB(25,25,52),
            LayoutOrder      = i,
        })
        corner(row, 0.1)

        local medal  = MEDALS[i] or ("#" .. i)
        local rarest = entry.RarestRarity ~= "" and (GameConfig.RarityNames[entry.RarestRarity] or entry.RarestRarity) or "—"

        label(row, {
            Size     = UDim2.new(0.06, 0, 1, 0),
            Text     = medal,
        })
        label(row, {
            Size     = UDim2.new(0.28, 0, 1, 0),
            Position = UDim2.new(0.06, 0, 0, 0),
            Text     = entry.Name,
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        label(row, {
            Size     = UDim2.new(0.28, 0, 1, 0),
            Position = UDim2.new(0.34, 0, 0, 0),
            Text     = tostring(entry.Aura) .. " ⭐",
            TextColor3 = C.Gold,
        })
        label(row, {
            Size     = UDim2.new(0.2, 0, 1, 0),
            Position = UDim2.new(0.62, 0, 0, 0),
            Text     = tostring(entry.TotalBrainrots) .. " 🧠",
        })
        label(row, {
            Size     = UDim2.new(0.18, 0, 1, 0),
            Position = UDim2.new(0.82, 0, 0, 0),
            Text     = rarest,
            TextColor3 = (i == 1) and C.Gold or C.TextDim,
        })
    end
end

-- ── Area Unlock Panel ─────────────────────────────────────────────────────────

local areaSG = newSG("Area_GUI", 2)
areaSG.Enabled = false

local areaPanel = frame(areaSG, {
    Size             = UDim2.new(0.65, 0, 0.78, 0),
    Position         = UDim2.new(0.175, 0, 0.11, 0),
    BackgroundColor3 = C.Background,
})
corner(areaPanel, 0.04)
stroke(areaPanel, C.Accent, 2)

label(areaPanel, {
    Size     = UDim2.new(1, -60, 0, 52),
    Position = UDim2.new(0, 8, 0, 4),
    Text     = "🗺️ Áreas do Mapa",
    TextColor3 = C.Accent,
    Font     = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
})

local areaClose = button(areaPanel, {
    Size     = UDim2.new(0, 44, 0, 44),
    Position = UDim2.new(1, -50, 0, 4),
    Text     = "✕",
    BackgroundColor3 = C.Error,
}, function() areaSG.Enabled = false end)

local areaScroll = Instance.new("ScrollingFrame")
areaScroll.Size               = UDim2.new(1, -16, 1, -68)
areaScroll.Position           = UDim2.new(0, 8, 0, 62)
areaScroll.BackgroundTransparency = 1
areaScroll.ScrollBarThickness = 6
areaScroll.ScrollBarImageColor3 = C.Accent
areaScroll.CanvasSize         = UDim2.new(0, 0, 0, 0)
areaScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
areaScroll.Parent             = areaPanel

local areaListLayout = Instance.new("UIListLayout")
areaListLayout.SortOrder = Enum.SortOrder.LayoutOrder
areaListLayout.Padding   = UDim.new(0, 8)
areaListLayout.Parent    = areaScroll

local aPad = Instance.new("UIPadding")
aPad.PaddingAll = UDim.new(0, 6)
aPad.Parent     = areaScroll

local function buildAreaCards(unlockedAreas)
    for _, child in ipairs(areaScroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    for idx, areaKey in ipairs(BrainrotConfig.AreaOrder) do
        local areaData = BrainrotConfig.Areas[areaKey]
        local isUnlocked = unlockedAreas[areaKey] == true

        local card = frame(areaScroll, {
            Size             = UDim2.new(1, -12, 0, 80),
            BackgroundColor3 = isUnlocked and Color3.fromRGB(18, 45, 22) or Color3.fromRGB(35, 15, 15),
            LayoutOrder      = idx,
        })
        corner(card, 0.1)
        stroke(card, isUnlocked and C.Success or C.Error, 2)

        label(card, {
            Size     = UDim2.new(0.55, 0, 0.5, 0),
            Position = UDim2.new(0.01, 0, 0, 0),
            Text     = (isUnlocked and "✅ " or "🔒 ") .. areaData.DisplayName,
            TextXAlignment = Enum.TextXAlignment.Left,
            Font     = Enum.Font.GothamBold,
            TextColor3 = isUnlocked and C.Success or C.Error,
        })

        local rarityStr = table.concat(areaData.Rarities, ", ")
        label(card, {
            Size     = UDim2.new(0.55, 0, 0.45, 0),
            Position = UDim2.new(0.01, 0, 0.5, 0),
            Text     = "Raridades: " .. rarityStr,
            TextXAlignment = Enum.TextXAlignment.Left,
            Font     = Enum.Font.Gotham,
            TextColor3 = C.TextDim,
        })

        if not isUnlocked then
            local costLabel = label(card, {
                Size     = UDim2.new(0.28, 0, 0.9, 0),
                Position = UDim2.new(0.55, 0, 0.05, 0),
                Text     = tostring(areaData.UnlockCost) .. " Aura",
                TextColor3 = C.Gold,
                Font     = Enum.Font.GothamBold,
            })

            local unlockBtn = button(card, {
                Size     = UDim2.new(0.14, 0, 0.7, 0),
                Position = UDim2.new(0.84, 0, 0.15, 0),
                Text     = "Abrir",
                BackgroundColor3 = C.Gold,
                TextColor3 = Color3.fromRGB(0, 0, 0),
            }, function()
                game.ReplicatedStorage.RemoteEvents.UnlockArea:FireServer(areaKey)
            end)
        else
            label(card, {
                Size     = UDim2.new(0.4, 0, 0.9, 0),
                Position = UDim2.new(0.58, 0, 0.05, 0),
                Text     = "Desbloqueada!",
                TextColor3 = C.Success,
                Font     = Enum.Font.GothamBold,
            })
        end
    end
end

-- Area button in HUD
local areaMapBtn = button(hudBar, {
    Size     = UDim2.new(0, 40, 0, 44),
    Position = UDim2.new(0, 0, 0.5, -22),
    Text     = "🗺️",
    BackgroundColor3 = Color3.fromRGB(40, 30, 110),
}, function()
    areaSG.Enabled = not areaSG.Enabled
    if areaSG.Enabled then
        buildAreaCards(currentUnlockedAreas)
    end
end)

-- ── Public interface ──────────────────────────────────────────────────────────

invBtn.MouseButton1Click:Connect(function()
    invSG.Enabled = not invSG.Enabled
end)

rankBtn.MouseButton1Click:Connect(function()
    rankSG.Enabled = not rankSG.Enabled
    if rankSG.Enabled then
        game.ReplicatedStorage.RemoteEvents.RequestRanking:FireServer()
    end
end)

function GUIManager.updateHUD(aura, count, area)
    auraLabel.Text  = "⭐ " .. tostring(aura)  .. " Aura"
    countLabel.Text = "🧠 " .. tostring(count) .. " Brainrots"
    areaLabel.Text  = "📍 " .. (area or "?")
end

function GUIManager.showCapturePopup(entry)
    showCapturePopup(entry)
end

function GUIManager.pushNotification(data)
    pushNotification(data)
end

function GUIManager.updateInventory(inventory, unlockedAreas)
    currentInventory     = inventory or {}
    currentUnlockedAreas = unlockedAreas or {}
    if invSG.Enabled then refreshInventoryUI() end
    if areaSG.Enabled then buildAreaCards(currentUnlockedAreas) end
end

function GUIManager.updateRanking(ranking)
    if rankSG.Enabled then
        refreshRankingPanel(ranking)
    end
end

-- Reopen inventory refreshes content
invSG:GetPropertyChangedSignal("Enabled"):Connect(function()
    if invSG.Enabled then refreshInventoryUI() end
end)

return GUIManager
