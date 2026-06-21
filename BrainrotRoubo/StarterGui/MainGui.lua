-- LocalScript: StarterGui > MainGui
-- Interface completa v2 — todos os 22 sistemas

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local SoundService      = game:GetService("SoundService")
local Camera            = workspace.CurrentCamera

local player     = Players.LocalPlayer
local playerGui  = player.PlayerGui
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local RemoteFolder       = ReplicatedStorage:WaitForChild("Remotes")
local StealEvent         = RemoteFolder:WaitForChild("StealBrainrot")
local UpdateAuraRE       = RemoteFolder:WaitForChild("UpdateAura")
local NotifyRE           = RemoteFolder:WaitForChild("Notify")
local RebirthEvent       = RemoteFolder:WaitForChild("Rebirth")
local IndexUpdateRE      = RemoteFolder:WaitForChild("IndexUpdate")
local GlobalAnnounceRE   = RemoteFolder:WaitForChild("GlobalAnnounce")
local BuyUpgradeEvent    = RemoteFolder:WaitForChild("BuyUpgrade")
local ClaimMissionEvent  = RemoteFolder:WaitForChild("ClaimMission")
local MissionUpdateRE    = RemoteFolder:WaitForChild("MissionUpdate")
local InventoryUpdateRE  = RemoteFolder:WaitForChild("InventoryUpdate")
local CombineItemsEvent  = RemoteFolder:WaitForChild("CombineItems")
local TradeProposeEvent  = RemoteFolder:WaitForChild("TradePropose")
local TradeRespondEvent  = RemoteFolder:WaitForChild("TradeRespond")
local TradeOfferRE       = RemoteFolder:WaitForChild("TradeOffer")
local TradeResultRE      = RemoteFolder:WaitForChild("TradeResult")
local BuyPetEvent        = RemoteFolder:WaitForChild("BuyPet")
local EquipPetEvent      = RemoteFolder:WaitForChild("EquipPet")
local PetUpdateRE        = RemoteFolder:WaitForChild("PetUpdate")
local PrestigeEvent      = RemoteFolder:WaitForChild("Prestige")
local AchievementRE      = RemoteFolder:WaitForChild("AchievementUnlock")
local TitleChangeEvent   = RemoteFolder:WaitForChild("TitleChange")
local BiomeUpdateRE      = RemoteFolder:WaitForChild("BiomeUpdate")
local EventUpdateRE      = RemoteFolder:WaitForChild("EventUpdate")
local BattlepassUpdateRE = RemoteFolder:WaitForChild("BattlepassUpdate")
local ClaimBattlepassEv  = RemoteFolder:WaitForChild("ClaimBattlepass")
local LeaderboardRE      = RemoteFolder:WaitForChild("LeaderboardUpdate")
local GetLeaderboardRF   = RemoteFolder:WaitForChild("GetLeaderboard")
local TutorialDoneEvent  = RemoteFolder:WaitForChild("TutorialDone")
local AdminCommandEvent  = RemoteFolder:WaitForChild("AdminCommand")
local CollectBrainrotEv  = RemoteFolder:WaitForChild("CollectBrainrot")

-- =====================================================
--  HELPERS
-- =====================================================
local function makeTL(parent, props)
    local f = Instance.new("TextLabel")
    for k, v in pairs(props) do f[k] = v end
    f.Parent = parent; return f
end
local function makeFrame(parent, props)
    local f = Instance.new("Frame")
    for k, v in pairs(props) do f[k] = v end
    f.Parent = parent; return f
end
local function makeTB(parent, props)
    local f = Instance.new("TextButton")
    for k, v in pairs(props) do f[k] = v end
    f.Parent = parent; return f
end
local function makeScroll(parent, props)
    local f = Instance.new("ScrollingFrame")
    for k, v in pairs(props) do f[k] = v end
    f.Parent = parent; return f
end
local function round(obj, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 10); c.Parent = obj
end
local function stroke(obj, color, thick)
    local s = Instance.new("UIStroke")
    s.Color = color or Color3.fromRGB(255,255,255)
    s.Thickness = thick or 1.5; s.Parent = obj; return s
end
local function listLayout(parent, pad)
    local l = Instance.new("UIListLayout")
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Padding   = UDim.new(0, pad or 4)
    l.Parent    = parent; return l
end
local function formatNum(n)
    if n >= 1e12 then return string.format("%.1fT", n/1e12) end
    if n >= 1e9  then return string.format("%.1fB", n/1e9)  end
    if n >= 1e6  then return string.format("%.1fM", n/1e6)  end
    if n >= 1000 then return string.format("%.1fK", n/1000) end
    return tostring(math.floor(n))
end

local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- =====================================================
--  SOUNDS
-- =====================================================
local musicVol = 0.12
local sfxVol   = 0.5

local function makeSound(id, vol, looped)
    local s = Instance.new("Sound")
    s.SoundId = "rbxassetid://" .. tostring(id)
    s.Volume  = vol or 0.5
    s.Looped  = looped or false
    s.Parent  = SoundService
    return s
end

local sfxSteal   = makeSound(142070081,  sfxVol * 0.7)
local sfxRebirth = makeSound(507109592,  sfxVol * 1.1)
local sfxLua     = makeSound(4874877895, sfxVol * 1.4)
local sfxMission = makeSound(419010678,  sfxVol)
local sfxAchiev  = makeSound(3360735306, sfxVol)
local sfxPrestige= makeSound(507109592,  sfxVol * 1.5)
local sfxAmbient = makeSound(1843402343, musicVol, true)
pcall(function() sfxAmbient:Play() end)

local function setMusicVol(v) musicVol = v; sfxAmbient.Volume = v end
local function setSfxVol(v)
    sfxVol = v
    sfxSteal.Volume   = v * 0.7
    sfxRebirth.Volume = v * 1.1
    sfxLua.Volume     = v * 1.4
    sfxMission.Volume = v
    sfxAchiev.Volume  = v
    sfxPrestige.Volume= v * 1.5
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
--  LOADING SCREEN
-- =====================================================
local LoadScreen = makeFrame(ScreenGui, {
    Size = UDim2.new(1,0,1,0), BackgroundColor3 = Color3.fromRGB(5,5,12),
    BorderSizePixel = 0, ZIndex = 50,
})
local loadTitle = makeTL(LoadScreen, {
    Size = UDim2.new(0.7,0,0,80), Position = UDim2.new(0.15,0,0.35,0),
    BackgroundTransparency = 1, Text = "BRAINROT ROUBO",
    TextColor3 = Color3.fromRGB(255,215,0), TextScaled = true,
    Font = Enum.Font.GothamBold, TextStrokeTransparency = 0, ZIndex = 51,
})
local loadSub = makeTL(LoadScreen, {
    Size = UDim2.new(0.6,0,0,36), Position = UDim2.new(0.2,0,0.52,0),
    BackgroundTransparency = 1, Text = "Carregando...",
    TextColor3 = Color3.fromRGB(180,180,180), TextScaled = true, Font = Enum.Font.Gotham, ZIndex = 51,
})
local loadBarBg = makeFrame(LoadScreen, {
    Size = UDim2.new(0.5,0,0,8), Position = UDim2.new(0.25,0,0.60,0),
    BackgroundColor3 = Color3.fromRGB(30,30,50), BorderSizePixel = 0, ZIndex = 51,
})
round(loadBarBg, 4)
local loadBarFill = makeFrame(loadBarBg, {
    Size = UDim2.new(0,0,1,0), BackgroundColor3 = Color3.fromRGB(255,215,0),
    BorderSizePixel = 0, ZIndex = 52,
})
round(loadBarFill, 4)

task.spawn(function()
    TweenService:Create(loadBarFill, TweenInfo.new(2.5, Enum.EasingStyle.Quad), {Size = UDim2.new(1,0,1,0)}):Play()
    task.wait(2.5)
    loadSub.Text = "Pronto! Vai roubar!"
    task.wait(0.6)
    TweenService:Create(LoadScreen, TweenInfo.new(0.6), {BackgroundTransparency=1}):Play()
    TweenService:Create(loadTitle, TweenInfo.new(0.6), {TextTransparency=1}):Play()
    TweenService:Create(loadSub, TweenInfo.new(0.6), {TextTransparency=1}):Play()
    task.wait(0.7)
    LoadScreen.Visible = false
end)

-- =====================================================
--  AURA PANEL (top center)
-- =====================================================
local AuraPanel = makeFrame(ScreenGui, {
    Size = UDim2.new(0,370,0,115), Position = UDim2.new(0.5,-185,0,12),
    BackgroundColor3 = Color3.fromRGB(12,12,18), BackgroundTransparency = 0.15, BorderSizePixel = 0,
})
round(AuraPanel, 14); stroke(AuraPanel, Color3.fromRGB(255,200,50), 2)

makeTL(AuraPanel, {
    Size = UDim2.new(1,0,0.26,0), BackgroundTransparency = 1,
    Text = "✦  AURA  ✦", TextColor3 = Color3.fromRGB(255,210,60),
    TextScaled = true, Font = Enum.Font.GothamBold,
})
local AuraValueLabel = makeTL(AuraPanel, {
    Size = UDim2.new(1,0,0.38,0), Position = UDim2.new(0,0,0.26,0),
    BackgroundTransparency = 1, Text = "0 / 500",
    TextColor3 = Color3.fromRGB(255,255,255), TextScaled = true, Font = Enum.Font.GothamBold,
})
local BarBg = makeFrame(AuraPanel, {
    Size = UDim2.new(0.88,0,0.14,0), Position = UDim2.new(0.06,0,0.72,0),
    BackgroundColor3 = Color3.fromRGB(35,35,50), BorderSizePixel = 0,
})
round(BarBg, 6)
local BarFill = makeFrame(BarBg, {
    Size = UDim2.new(0,0,1,0), BackgroundColor3 = Color3.fromRGB(80,220,80), BorderSizePixel = 0,
})
round(BarFill, 6)

-- Event banner (above aura panel)
local EventBanner = makeFrame(ScreenGui, {
    Size = UDim2.new(0,370,0,28), Position = UDim2.new(0.5,-185,0,130),
    BackgroundColor3 = Color3.fromRGB(180,100,0), BackgroundTransparency = 0.1,
    BorderSizePixel = 0, Visible = false,
})
round(EventBanner, 8); stroke(EventBanner, Color3.fromRGB(255,200,0), 1.5)
local EventBannerLabel = makeTL(EventBanner, {
    Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
    Text = "🎉 EVENTO ATIVO", TextColor3 = Color3.fromRGB(255,240,180),
    TextScaled = true, Font = Enum.Font.GothamBold,
})

-- =====================================================
--  STATS PANEL (left)
-- =====================================================
local StatsPanel = makeFrame(ScreenGui, {
    Size = UDim2.new(0,210,0,165), Position = UDim2.new(0,12,0,12),
    BackgroundColor3 = Color3.fromRGB(12,12,18), BackgroundTransparency = 0.2, BorderSizePixel = 0,
})
round(StatsPanel, 12); stroke(StatsPanel, Color3.fromRGB(120,80,255), 1.5)

local function statRow(yOff, lbl, def)
    return makeTL(StatsPanel, {
        Size = UDim2.new(1,-10,0,26), Position = UDim2.new(0,5,0,yOff),
        BackgroundTransparency = 1, Text = lbl..": "..def,
        TextColor3 = Color3.fromRGB(220,220,220), TextScaled = true, Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
end
local RebirthsLabel  = statRow(4,   "Rebirths",   "0")
local MultLabel      = statRow(30,  "Mult",        "x1")
local StolenLabel    = statRow(56,  "Roubados",    "0")
local CostLabel      = statRow(82,  "Custo RB",    "400")
local MutLabel       = statRow(108, "Última Mut",  "-")
local PrestigeLabel  = statRow(134, "Prestígio",   "0")

-- =====================================================
--  REBIRTH BUTTON
-- =====================================================
local btnW = isMobile and 200 or 240
local RebirthBtn = makeTB(ScreenGui, {
    Size = UDim2.new(0,btnW,0,58), Position = UDim2.new(0.5,-btnW/2,1,-74),
    BackgroundColor3 = Color3.fromRGB(80,80,80), BorderSizePixel = 0,
    Text = "RENASCER  (0 / 400)", TextColor3 = Color3.fromRGB(160,160,160),
    TextScaled = true, Font = Enum.Font.GothamBold,
})
round(RebirthBtn, 14); stroke(RebirthBtn, Color3.fromRGB(255,230,100), 2)

-- Prestige button (hidden until rebirths >= MAX)
local PrestigeBtn = makeTB(ScreenGui, {
    Size = UDim2.new(0,200,0,46), Position = UDim2.new(0.5,-100,1,-134),
    BackgroundColor3 = Color3.fromRGB(80,0,120), BorderSizePixel = 0,
    Text = "⭐ PRESTÍGIO", TextColor3 = Color3.fromRGB(255,200,255),
    TextScaled = true, Font = Enum.Font.GothamBold, Visible = false,
})
round(PrestigeBtn, 12); stroke(PrestigeBtn, Color3.fromRGB(200,100,255), 2)

-- =====================================================
--  STEAL PROMPT
-- =====================================================
local promptW = isMobile and 340 or 300
local StealPrompt = makeFrame(ScreenGui, {
    Size = UDim2.new(0,promptW,0,100), Position = UDim2.new(0.5,-promptW/2,0.70,0),
    BackgroundColor3 = Color3.fromRGB(8,8,14), BackgroundTransparency = 0.08,
    BorderSizePixel = 0, Visible = false,
})
round(StealPrompt, 14)
local stealStroke = stroke(StealPrompt, Color3.fromRGB(255,255,255), 1.5)
local StealNameLabel = makeTL(StealPrompt, {
    Size=UDim2.new(1,0,0.34,0), BackgroundTransparency=1, Text="Brainrot",
    TextColor3=Color3.fromRGB(255,255,255), TextScaled=true, Font=Enum.Font.GothamBold,
})
local StealRarLabel = makeTL(StealPrompt, {
    Size=UDim2.new(1,0,0.26,0), Position=UDim2.new(0,0,0.34,0), BackgroundTransparency=1,
    Text="[Comum]", TextColor3=Color3.fromRGB(180,180,180), TextScaled=true, Font=Enum.Font.Gotham,
})
local StealMutLabel = makeTL(StealPrompt, {
    Size=UDim2.new(1,0,0.22,0), Position=UDim2.new(0,0,0.60,0), BackgroundTransparency=1,
    Text="✦ Básico ×1", TextColor3=Color3.fromRGB(180,180,180), TextScaled=true, Font=Enum.Font.GothamBold,
})
local StealKeyLabel = makeTL(StealPrompt, {
    Size=UDim2.new(1,0,0.18,0), Position=UDim2.new(0,0,0.82,0), BackgroundTransparency=1,
    Text=isMobile and "Botão ROUBAR →" or "[E] para Roubar",
    TextColor3=Color3.fromRGB(255,210,50), TextScaled=true, Font=Enum.Font.GothamBold,
})

local mobileStealSize = isMobile and 150 or 130
local MobileStealBtn = makeTB(ScreenGui, {
    Size = UDim2.new(0,mobileStealSize,0,mobileStealSize),
    Position = UDim2.new(1,-mobileStealSize-20,1,-mobileStealSize-20),
    BackgroundColor3 = Color3.fromRGB(200,50,50), BorderSizePixel=0,
    Text="ROUBAR", TextColor3=Color3.fromRGB(255,255,255), TextScaled=true, Font=Enum.Font.GothamBold, Visible=false,
})
round(MobileStealBtn, mobileStealSize/2); stroke(MobileStealBtn, Color3.fromRGB(255,180,180), 2)

-- =====================================================
--  NOTIFICATIONS
-- =====================================================
local NotifyStack = makeFrame(ScreenGui, {
    Size=UDim2.new(0,380,1,0), Position=UDim2.new(1,-392,0,0),
    BackgroundTransparency=1, BorderSizePixel=0,
})
local notifyLayout = Instance.new("UIListLayout")
notifyLayout.SortOrder=Enum.SortOrder.LayoutOrder
notifyLayout.VerticalAlignment=Enum.VerticalAlignment.Bottom
notifyLayout.Padding=UDim.new(0,6)
notifyLayout.Parent=NotifyStack

local notifyCount = 0
local function showNotification(msg, color, big)
    notifyCount = notifyCount + 1
    local h = big and 72 or 54
    local card = makeFrame(NotifyStack, {
        Size=UDim2.new(1,0,0,h), BackgroundColor3=Color3.fromRGB(10,10,16),
        BackgroundTransparency=0.08, BorderSizePixel=0, LayoutOrder=-notifyCount,
    })
    round(card, 10); stroke(card, color or Color3.fromRGB(255,255,255), big and 2 or 1.5)
    makeTL(card, {
        Size=UDim2.new(1,-14,1,0), Position=UDim2.new(0,7,0,0),
        BackgroundTransparency=1, Text=msg, TextColor3=color or Color3.fromRGB(255,255,255),
        TextScaled=true, Font=big and Enum.Font.GothamBold or Enum.Font.Gotham,
        TextXAlignment=Enum.TextXAlignment.Left, TextWrapped=true,
    })
    task.delay(big and 6 or 3.5, function()
        TweenService:Create(card, TweenInfo.new(0.4), {BackgroundTransparency=1, Size=UDim2.new(1,0,0,0)}):Play()
        task.wait(0.42); if card then card:Destroy() end
    end)
end

-- Lua Banner
local LuaBanner = makeFrame(ScreenGui, {
    Size=UDim2.new(0.7,0,0,80), Position=UDim2.new(0.15,0,0.12,0),
    BackgroundColor3=Color3.fromRGB(80,0,0), BackgroundTransparency=0.1,
    BorderSizePixel=0, Visible=false, ZIndex=10,
})
round(LuaBanner, 16); stroke(LuaBanner, Color3.fromRGB(255,0,0), 3)
local LuaBannerLabel = makeTL(LuaBanner, {
    Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="🌑 LUA DE SANGUE!",
    TextColor3=Color3.fromRGB(255,80,80), TextScaled=true, Font=Enum.Font.GothamBold,
    TextWrapped=true, ZIndex=11,
})

-- =====================================================
--  RECENT STEALS (right sidebar)
-- =====================================================
local recentSteals = {}
local RecentPanel = makeFrame(ScreenGui, {
    Size=UDim2.new(0,220,0,240), Position=UDim2.new(1,-234,0,200),
    BackgroundColor3=Color3.fromRGB(8,8,14), BackgroundTransparency=0.2, BorderSizePixel=0,
})
round(RecentPanel, 10); stroke(RecentPanel, Color3.fromRGB(80,80,120), 1)
makeTL(RecentPanel, {
    Size=UDim2.new(1,0,0,22), BackgroundTransparency=1, Text="📜 Últimos Roubos",
    TextColor3=Color3.fromRGB(160,160,200), TextScaled=true, Font=Enum.Font.GothamBold,
})
local RecentScroll = makeScroll(RecentPanel, {
    Size=UDim2.new(1,-4,1,-24), Position=UDim2.new(0,2,0,24),
    BackgroundTransparency=1, BorderSizePixel=0, ScrollBarThickness=3,
    ScrollBarImageColor3=Color3.fromRGB(100,100,160), CanvasSize=UDim2.new(0,0,0,0),
})
local recentLayout = listLayout(RecentScroll, 2)

local function addRecentSteal(name, rarity, mutName)
    table.insert(recentSteals, 1, {name=name, rarity=rarity, mutName=mutName})
    if #recentSteals > 10 then table.remove(recentSteals) end
    -- Rebuild
    for _, c in ipairs(RecentScroll:GetChildren()) do
        if c:IsA("GuiObject") then c:Destroy() end
    end
    local rarColors = GameConfig.RARITY_COLORS
    for idx, s in ipairs(recentSteals) do
        local c = rarColors[s.rarity] or Color3.fromRGB(200,200,200)
        local row = makeFrame(RecentScroll, {
            Size=UDim2.new(1,0,0,20), BackgroundColor3=Color3.fromRGB(15,15,22),
            BackgroundTransparency=0.1, BorderSizePixel=0, LayoutOrder=idx,
        })
        round(row, 4)
        makeTL(row, {
            Size=UDim2.new(0.6,0,1,0), BackgroundTransparency=1,
            Text=s.name, TextColor3=c, TextScaled=true, Font=Enum.Font.GothamBold,
            TextXAlignment=Enum.TextXAlignment.Left,
        })
        makeTL(row, {
            Size=UDim2.new(0.38,0,1,0), Position=UDim2.new(0.6,0,0,0),
            BackgroundTransparency=1, Text="["..s.rarity.."]",
            TextColor3=c, TextScaled=true, Font=Enum.Font.Gotham,
            TextXAlignment=Enum.TextXAlignment.Right,
        })
    end
    RecentScroll.CanvasSize = UDim2.new(0,0,0,recentLayout.AbsoluteContentSize.Y)
end

-- =====================================================
--  MINI-MAP
-- =====================================================
local MAP_SIZE   = 163
local MAP_MARGIN = 10
local MAP_RANGE  = 170
local MAP_SCALE  = (MAP_SIZE - MAP_MARGIN*2) / MAP_RANGE

local function worldToMap(worldX, worldZ)
    return MAP_MARGIN+(worldX+85)*MAP_SCALE, MAP_MARGIN+(worldZ+85)*MAP_SCALE
end

local MiniMapPanel = makeFrame(ScreenGui, {
    Size=UDim2.new(0,MAP_SIZE,0,MAP_SIZE), Position=UDim2.new(1,-(MAP_SIZE+12),0,12),
    BackgroundColor3=Color3.fromRGB(8,12,20), BackgroundTransparency=0.15, BorderSizePixel=0,
})
round(MiniMapPanel, 10); stroke(MiniMapPanel, Color3.fromRGB(80,80,140), 1.5)
makeTL(MiniMapPanel, {
    Size=UDim2.new(1,0,0,18), BackgroundTransparency=1, Text="MINI-MAPA",
    TextColor3=Color3.fromRGB(160,160,220), TextScaled=true, Font=Enum.Font.GothamBold,
})
local innerRingUI = makeFrame(MiniMapPanel, {
    Size=UDim2.new(0,52,0,52), Position=UDim2.new(0.5,-26,0.5,-26),
    BackgroundTransparency=1, BorderSizePixel=0,
})
stroke(innerRingUI, Color3.fromRGB(0,180,160), 1); round(innerRingUI, 26)

local miniDots = {}
for i, pos in ipairs(GameConfig.BASE_POSITIONS) do
    local px, pz = worldToMap(pos.X, pos.Z)
    local dot = makeFrame(MiniMapPanel, {
        Size=UDim2.new(0,9,0,9), Position=UDim2.new(0,px-4,0,pz-4),
        BackgroundColor3=Color3.fromRGB(60,60,80), BorderSizePixel=0,
    })
    round(dot, 5); miniDots[i] = dot
end
local playerDot = makeFrame(MiniMapPanel, {
    Size=UDim2.new(0,10,0,10), Position=UDim2.new(0.5,-5,0.5,-5),
    BackgroundColor3=Color3.fromRGB(255,255,255), BorderSizePixel=0, ZIndex=3,
})
round(playerDot, 5)

-- =====================================================
--  BOTTOM BUTTON BAR
-- =====================================================
local function makeBarBtn(xPos, icon, color, strkColor)
    local w = isMobile and 80 or 68
    local b = makeTB(ScreenGui, {
        Size=UDim2.new(0,w,0,isMobile and 56 or 46),
        Position=UDim2.new(0,xPos,1,-(isMobile and 66 or 62)),
        BackgroundColor3=Color3.fromRGB(15,15,25), BorderSizePixel=0,
        Text=icon, TextColor3=color, TextScaled=true, Font=Enum.Font.GothamBold,
    })
    round(b, 10); stroke(b, strkColor or color, 1.5); return b
end

local IndexBtn    = makeBarBtn(12,    "📖 INDEX",    Color3.fromRGB(200,200,255), Color3.fromRGB(100,100,200))
local UpgradeBtn  = makeBarBtn(88,    "⚒ UPG",      Color3.fromRGB(160,255,160), Color3.fromRGB(80,200,80))
local MissionsBtn = makeBarBtn(164,   "📋 MISS",     Color3.fromRGB(180,180,255), Color3.fromRGB(100,100,220))
local InventoryBtn= makeBarBtn(240,   "🎒 INV",      Color3.fromRGB(255,210,100), Color3.fromRGB(200,150,50))
local PetBtn      = makeBarBtn(316,   "🐾 PETS",     Color3.fromRGB(255,180,180), Color3.fromRGB(200,100,100))
local AchievBtn   = makeBarBtn(392,   "🏆 CONQ",     Color3.fromRGB(255,220,80),  Color3.fromRGB(200,170,0))
local BPBtn       = makeBarBtn(468,   "🎖 PASSE",    Color3.fromRGB(180,255,220), Color3.fromRGB(80,200,140))
local LBBtn       = makeBarBtn(544,   "🌍 RANK",     Color3.fromRGB(255,180,120), Color3.fromRGB(200,120,60))
local SettingsBtn = makeBarBtn(620,   "⚙ VOL",      Color3.fromRGB(180,180,180), Color3.fromRGB(120,120,120))

-- =====================================================
--  PANEL BUILDER HELPERS
-- =====================================================
local function makePanel(title, strokeColor, bkColor)
    local p = makeFrame(ScreenGui, {
        Size=UDim2.new(0,560,0,500), Position=UDim2.new(0.5,-280,0.5,-250),
        BackgroundColor3=bkColor or Color3.fromRGB(10,10,18), BackgroundTransparency=0.04,
        BorderSizePixel=0, Visible=false, ZIndex=8,
    })
    round(p, 16); stroke(p, strokeColor, 2)
    makeTL(p, {
        Size=UDim2.new(1,0,0,44), BackgroundColor3=Color3.fromRGB(8,8,16),
        BackgroundTransparency=0, Text=title, TextColor3=strokeColor,
        TextScaled=true, Font=Enum.Font.GothamBold, ZIndex=9,
    })
    local closeBtn = makeTB(p, {
        Size=UDim2.new(0,40,0,36), Position=UDim2.new(1,-46,0,4),
        BackgroundColor3=Color3.fromRGB(180,40,40), BorderSizePixel=0,
        Text="✕", TextColor3=Color3.fromRGB(255,255,255), TextScaled=true, Font=Enum.Font.GothamBold, ZIndex=10,
    })
    round(closeBtn, 8)
    return p, closeBtn
end

local function panelToggle(panel, btn, openColor, closeColor)
    local open = false
    local function toggle()
        open = not open
        panel.Visible = open
        btn.BackgroundColor3 = open and openColor or Color3.fromRGB(15,15,25)
    end
    btn.Activated:Connect(toggle)
    return toggle
end

-- =====================================================
--  UPGRADE PANEL
-- =====================================================
local UpgradePanel, CloseUpgradeBtn = makePanel("⚒  LOJA DE UPGRADES", Color3.fromRGB(80,200,80))
UpgradePanel.Size = UDim2.new(0,500,0,380)
UpgradePanel.Position = UDim2.new(0.5,-250,0.5,-190)
local upgradeRows = {}

local function buildUpgradeUI(upgradesData)
    for _, r in pairs(upgradeRows) do r:Destroy() end
    upgradeRows = {}
    local startY = 54
    for _, upg in ipairs(GameConfig.UPGRADES) do
        local level = (upgradesData and upgradesData[upg.id]) or 0
        local isMax = level >= upg.maxLevel
        local nextCost = isMax and 0 or upg.costs[level+1]
        local curValue = (level==0) and (upg.id=="stealRange" and GameConfig.STEAL_RANGE or upg.id=="walkSpeed" and 16 or 1.0) or upg.values[level]
        local nextValue = isMax and upg.values[upg.maxLevel] or upg.values[level+1]

        local row = makeFrame(UpgradePanel, {
            Size=UDim2.new(1,-20,0,78), Position=UDim2.new(0,10,0,startY),
            BackgroundColor3=Color3.fromRGB(15,28,15), BackgroundTransparency=0.1, BorderSizePixel=0, ZIndex=9,
        })
        round(row, 10); stroke(row, isMax and Color3.fromRGB(255,200,0) or Color3.fromRGB(60,120,60), isMax and 2 or 1)
        makeTL(row, {Size=UDim2.new(0.45,0,0.5,0), Position=UDim2.new(0,10,0,4), BackgroundTransparency=1,
            Text=upg.icon.." "..upg.name, TextColor3=Color3.fromRGB(200,255,200), TextScaled=true, Font=Enum.Font.GothamBold,
            TextXAlignment=Enum.TextXAlignment.Left, ZIndex=10,})
        makeTL(row, {Size=UDim2.new(0.55,0,0.36,0), Position=UDim2.new(0,10,0.52,0), BackgroundTransparency=1,
            Text=upg.desc, TextColor3=Color3.fromRGB(140,180,140), TextScaled=true, Font=Enum.Font.Gotham,
            TextXAlignment=Enum.TextXAlignment.Left, ZIndex=10,})
        local valText = isMax and ("MAX: "..tostring(curValue)) or string.format("Atual: %s → %s", tostring(curValue), tostring(nextValue))
        makeTL(row, {Size=UDim2.new(0.38,0,0.44,0), Position=UDim2.new(0.58,0,0.04,0), BackgroundTransparency=1,
            Text=valText, TextColor3=Color3.fromRGB(200,200,200), TextScaled=true, Font=Enum.Font.Gotham,
            TextXAlignment=Enum.TextXAlignment.Right, ZIndex=10,})
        local lvlBg = makeFrame(row, {Size=UDim2.new(0.4,0,0.22,0), Position=UDim2.new(0.58,0,0.52,0),
            BackgroundColor3=Color3.fromRGB(25,40,25), BorderSizePixel=0, ZIndex=10,})
        round(lvlBg, 4)
        local lvlFill = makeFrame(lvlBg, {Size=UDim2.new(level/upg.maxLevel,0,1,0),
            BackgroundColor3=isMax and Color3.fromRGB(255,200,0) or Color3.fromRGB(80,200,80), BorderSizePixel=0, ZIndex=11,})
        round(lvlFill, 4)
        makeTL(lvlBg, {Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
            Text="Nível "..level.."/"..upg.maxLevel, TextColor3=Color3.fromRGB(255,255,255),
            TextScaled=true, Font=Enum.Font.GothamBold, ZIndex=12,})
        local buyBtn = makeTB(row, {
            Size=UDim2.new(0.52,0,0.78,0), Position=UDim2.new(0,10,0.11,0),
            BackgroundColor3=isMax and Color3.fromRGB(100,80,0) or Color3.fromRGB(40,120,40), BorderSizePixel=0,
            Text=isMax and "MÁXIMO" or ("⬆ "..formatNum(nextCost).." aura"),
            TextColor3=isMax and Color3.fromRGB(200,180,0) or Color3.fromRGB(200,255,200),
            TextScaled=true, Font=Enum.Font.GothamBold, ZIndex=10,
        })
        round(buyBtn, 8)
        if not isMax then buyBtn.Activated:Connect(function() BuyUpgradeEvent:FireServer(upg.id) end) end
        table.insert(upgradeRows, row)
        startY = startY + 84
    end
end

CloseUpgradeBtn.Activated:Connect(function() UpgradePanel.Visible = false end)
UpgradeBtn.Activated:Connect(function() UpgradePanel.Visible = not UpgradePanel.Visible end)

-- =====================================================
--  MISSIONS PANEL
-- =====================================================
local MissionsPanel, CloseMissionsBtn = makePanel("📋  MISSÕES DIÁRIAS", Color3.fromRGB(100,100,220))
MissionsPanel.Size = UDim2.new(0,500,0,360)
MissionsPanel.Position = UDim2.new(0.5,-250,0.5,-180)
local missionRows = {}
local localMissions = nil

local function buildMissionsUI(md)
    for _, r in pairs(missionRows) do r:Destroy() end; missionRows = {}
    if not md then return end
    local startY = 52
    for _, mId in ipairs(md.active) do
        local mission = nil
        for _, m in ipairs(GameConfig.DAILY_MISSIONS) do if m.id==mId then mission=m; break end end
        if not mission then continue end
        local progress = md.progress[mId] or 0
        local claimed  = md.claimed[mId] or false
        local complete = progress >= mission.target
        local pct = math.clamp(progress/mission.target, 0, 1)

        local row = makeFrame(MissionsPanel, {
            Size=UDim2.new(1,-20,0,80), Position=UDim2.new(0,10,0,startY),
            BackgroundColor3=claimed and Color3.fromRGB(10,10,10) or (complete and Color3.fromRGB(20,30,10) or Color3.fromRGB(12,12,24)),
            BackgroundTransparency=0.1, BorderSizePixel=0, ZIndex=9,
        })
        round(row, 10)
        stroke(row, claimed and Color3.fromRGB(80,80,80) or complete and Color3.fromRGB(255,215,0) or Color3.fromRGB(80,80,160), claimed and 0.8 or (complete and 2 or 1))
        makeTL(row, {Size=UDim2.new(0.6,0,0.42,0), Position=UDim2.new(0,10,0,4), BackgroundTransparency=1,
            Text=mission.name, TextColor3=claimed and Color3.fromRGB(100,100,100) or complete and Color3.fromRGB(255,215,0) or Color3.fromRGB(200,200,255),
            TextScaled=true, Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=10,})
        makeTL(row, {Size=UDim2.new(0.6,0,0.34,0), Position=UDim2.new(0,10,0.44,0), BackgroundTransparency=1,
            Text=mission.desc, TextColor3=Color3.fromRGB(140,140,180), TextScaled=true, Font=Enum.Font.Gotham,
            TextXAlignment=Enum.TextXAlignment.Left, ZIndex=10,})
        local progBg = makeFrame(row, {Size=UDim2.new(0.6,0,0.18,0), Position=UDim2.new(0,10,0.80,0),
            BackgroundColor3=Color3.fromRGB(25,25,40), BorderSizePixel=0, ZIndex=10,})
        round(progBg, 3)
        local progFill = makeFrame(progBg, {Size=UDim2.new(pct,0,1,0),
            BackgroundColor3=claimed and Color3.fromRGB(60,60,60) or (complete and Color3.fromRGB(255,215,0) or Color3.fromRGB(80,80,200)),
            BorderSizePixel=0, ZIndex=11,})
        round(progFill, 3)
        makeTL(progBg, {Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
            Text=progress.." / "..mission.target, TextColor3=Color3.fromRGB(255,255,255),
            TextScaled=true, Font=Enum.Font.GothamBold, ZIndex=12,})
        local claimBtn = makeTB(row, {
            Size=UDim2.new(0.34,0,0.80,0), Position=UDim2.new(0.64,0,0.10,0),
            BackgroundColor3=claimed and Color3.fromRGB(40,40,40) or (complete and Color3.fromRGB(180,140,0) or Color3.fromRGB(30,30,60)),
            BorderSizePixel=0, Text=claimed and "✓ Resgatado" or (complete and ("🎁 +"..formatNum(mission.reward)) or ("+"..formatNum(mission.reward).." aura")),
            TextColor3=claimed and Color3.fromRGB(80,80,80) or (complete and Color3.fromRGB(255,255,200) or Color3.fromRGB(120,120,180)),
            TextScaled=true, Font=Enum.Font.GothamBold, ZIndex=10,
        })
        round(claimBtn, 8)
        if complete and not claimed then
            claimBtn.Activated:Connect(function() ClaimMissionEvent:FireServer(mId); pcall(function() sfxMission:Play() end) end)
        end
        table.insert(missionRows, row); startY = startY + 86
    end
end

CloseMissionsBtn.Activated:Connect(function() MissionsPanel.Visible = false end)
MissionsBtn.Activated:Connect(function()
    MissionsPanel.Visible = not MissionsPanel.Visible
    if MissionsPanel.Visible then buildMissionsUI(localMissions) end
end)

-- =====================================================
--  INDEX PANEL
-- =====================================================
local IndexPanel, CloseIndexBtn = makePanel("📖  ÍNDICE DE BRAINROTS", Color3.fromRGB(120,80,255))
IndexPanel.Size = UDim2.new(0,560,0,480); IndexPanel.Position = UDim2.new(0.5,-280,0.5,-240)

local tabBar = makeFrame(IndexPanel, {
    Size=UDim2.new(1,0,0,38), Position=UDim2.new(0,0,0,44),
    BackgroundColor3=Color3.fromRGB(12,12,22), BorderSizePixel=0, ZIndex=9,
})
local function makeTabBtn(text, xPos)
    local b = makeTB(tabBar, {
        Size=UDim2.new(0.48,0,1,-4), Position=UDim2.new(xPos,0,0,2),
        BackgroundColor3=Color3.fromRGB(30,30,50), BorderSizePixel=0,
        Text=text, TextColor3=Color3.fromRGB(160,160,200), TextScaled=true, Font=Enum.Font.GothamBold, ZIndex=10,
    })
    round(b, 8); return b
end
local TabBrainrots = makeTabBtn("Brainrots", 0.01)
local TabMutations = makeTabBtn("Mutações",  0.51)

local IndexScroll = makeScroll(IndexPanel, {
    Size=UDim2.new(1,-12,1,-92), Position=UDim2.new(0,6,0,88),
    BackgroundTransparency=1, BorderSizePixel=0, ScrollBarThickness=6,
    ScrollBarImageColor3=Color3.fromRGB(120,80,255), CanvasSize=UDim2.new(0,0,0,0), ZIndex=9,
})
local scrollLayout = listLayout(IndexScroll, 4)
local localIndex = {brainrots={}, mutations={}}
local RARITY_ORDER = {"Comum","Incomum","Raro","Epico","Lendario","Mitico","God","Secret","OG"}
local currentTab = "Brainrots"

local function buildIndexUI()
    for _, c in ipairs(IndexScroll:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
    if currentTab == "Brainrots" then
        local grouped = {}
        for _, r in ipairs(RARITY_ORDER) do grouped[r] = {} end
        for _, bt in ipairs(GameConfig.BRAINROT_TYPES) do
            if grouped[bt.rarity] then table.insert(grouped[bt.rarity], bt) end
        end
        local lo = 0
        for _, rarity in ipairs(RARITY_ORDER) do
            local list = grouped[rarity]; if #list==0 then continue end
            local rarColor = GameConfig.RARITY_COLORS[rarity] or Color3.fromRGB(200,200,200)
            lo = lo+1
            local hdr = makeFrame(IndexScroll, {
                Size=UDim2.new(1,-4,0,26), BackgroundColor3=Color3.fromRGB(20,20,35),
                BorderSizePixel=0, LayoutOrder=lo, ZIndex=10,
            })
            round(hdr, 6); stroke(hdr, rarColor, 1)
            makeTL(hdr, {Size=UDim2.new(1,-8,1,0), Position=UDim2.new(0,4,0,0), BackgroundTransparency=1,
                Text="── "..rarity:upper().." ──", TextColor3=rarColor, TextScaled=true, Font=Enum.Font.GothamBold,
                TextXAlignment=Enum.TextXAlignment.Left, ZIndex=11,})
            for _, bt in ipairs(list) do
                lo = lo+1
                local entry = localIndex.brainrots[bt.name]
                local disc = entry ~= nil
                local count = disc and entry.count or 0
                local bestMut = disc and entry.bestMutation or "-"
                local row = makeFrame(IndexScroll, {
                    Size=UDim2.new(1,-4,0,44), BackgroundColor3=disc and Color3.fromRGB(18,18,28) or Color3.fromRGB(12,12,18),
                    BackgroundTransparency=disc and 0.05 or 0.3, BorderSizePixel=0, LayoutOrder=lo, ZIndex=10,
                })
                round(row, 7); if disc then stroke(row, rarColor, 1) end
                local colorBar = makeFrame(row, {Size=UDim2.new(0,5,1,-4), Position=UDim2.new(0,2,0,2),
                    BackgroundColor3=rarColor, BorderSizePixel=0, ZIndex=11,})
                round(colorBar, 3)
                makeTL(row, {Size=UDim2.new(0.55,0,0.5,0), Position=UDim2.new(0,12,0,2), BackgroundTransparency=1,
                    Text=disc and bt.name or "???", TextColor3=disc and Color3.fromRGB(240,240,240) or Color3.fromRGB(80,80,80),
                    TextScaled=true, Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=11,})
                makeTL(row, {Size=UDim2.new(0.4,0,0.42,0), Position=UDim2.new(0.58,0,0.04,0), BackgroundTransparency=1,
                    Text=disc and (formatNum(bt.baseAura).." aura") or "???",
                    TextColor3=Color3.fromRGB(180,180,180), TextScaled=true, Font=Enum.Font.Gotham,
                    TextXAlignment=Enum.TextXAlignment.Right, ZIndex=11,})
                if disc then
                    local mutColor = Color3.fromRGB(180,180,180)
                    for _, m in ipairs(GameConfig.MUTATIONS) do if m.name==bestMut then mutColor=m.color; break end end
                    makeTL(row, {Size=UDim2.new(0.5,0,0.4,0), Position=UDim2.new(0,12,0.54,0), BackgroundTransparency=1,
                        Text="Roubados: "..count, TextColor3=Color3.fromRGB(140,210,140),
                        TextScaled=true, Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=11,})
                    makeTL(row, {Size=UDim2.new(0.48,0,0.4,0), Position=UDim2.new(0.5,0,0.54,0), BackgroundTransparency=1,
                        Text="Melhor: "..bestMut, TextColor3=mutColor, TextScaled=true, Font=Enum.Font.GothamBold,
                        TextXAlignment=Enum.TextXAlignment.Right, ZIndex=11,})
                end
            end
        end
    else
        local lo = 0
        for _, mut in ipairs(GameConfig.MUTATIONS) do
            lo = lo+1
            local count = localIndex.mutations[mut.name] or 0
            local disc = count>0; local isLua = (mut.name=="Lua de Sangue")
            local row = makeFrame(IndexScroll, {
                Size=UDim2.new(1,-4,0,58),
                BackgroundColor3=isLua and Color3.fromRGB(30,5,5) or (disc and Color3.fromRGB(18,18,28) or Color3.fromRGB(12,12,18)),
                BackgroundTransparency=0.05, BorderSizePixel=0, LayoutOrder=lo, ZIndex=10,
            })
            round(row, 8); stroke(row, mut.color, isLua and 2.5 or (disc and 1.5 or 0.5))
            local dot = makeFrame(row, {Size=UDim2.new(0,34,0,34), Position=UDim2.new(0,8,0.5,-17),
                BackgroundColor3=mut.color, BorderSizePixel=0, ZIndex=11,})
            round(dot, 17)
            makeTL(row, {Size=UDim2.new(0.5,0,0.5,0), Position=UDim2.new(0,50,0,4), BackgroundTransparency=1,
                Text=(isLua and "🌑 " or "✦ ")..mut.name, TextColor3=mut.color,
                TextScaled=true, Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=11,})
            makeTL(row, {Size=UDim2.new(0.35,0,0.45,0), Position=UDim2.new(0.62,0,0.06,0), BackgroundTransparency=1,
                Text="×"..tostring(mut.multiplier), TextColor3=Color3.fromRGB(255,255,255),
                TextScaled=true, Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Right, ZIndex=11,})
            makeTL(row, {Size=UDim2.new(0.5,0,0.42,0), Position=UDim2.new(0,50,0.52,0), BackgroundTransparency=1,
                Text=disc and ("Obtida: "..count.."x") or "Não obtida",
                TextColor3=disc and Color3.fromRGB(140,210,140) or Color3.fromRGB(80,80,80),
                TextScaled=true, Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=11,})
        end
    end
    IndexScroll.CanvasSize = UDim2.new(0,0,0,scrollLayout.AbsoluteContentSize.Y+8)
end

local function setTab(tab)
    currentTab = tab
    TabBrainrots.BackgroundColor3 = (tab=="Brainrots") and Color3.fromRGB(80,60,160) or Color3.fromRGB(30,30,50)
    TabMutations.BackgroundColor3 = (tab=="Mutações")  and Color3.fromRGB(80,60,160) or Color3.fromRGB(30,30,50)
    buildIndexUI()
end
setTab("Brainrots")

CloseIndexBtn.Activated:Connect(function() IndexPanel.Visible = false end)
IndexBtn.Activated:Connect(function()
    IndexPanel.Visible = not IndexPanel.Visible
    if IndexPanel.Visible then buildIndexUI() end
end)
TabBrainrots.Activated:Connect(function() setTab("Brainrots") end)
TabMutations.Activated:Connect(function()  setTab("Mutações")  end)

-- =====================================================
--  INVENTORY PANEL
-- =====================================================
local InvPanel, CloseInvBtn = makePanel("🎒  INVENTÁRIO", Color3.fromRGB(255,200,80))
local localInventory = {}
local selectedItems  = {}  -- up to 2 for combine, 1 for trade
local tradeTargetPlayer = nil

makeTL(InvPanel, {
    Size=UDim2.new(1,0,0,22), Position=UDim2.new(0,0,0,44), BackgroundColor3=Color3.fromRGB(10,10,18),
    BackgroundTransparency=0, Text="Selecione itens: [Combinar] 2 iguais → 1 mais raro  |  [Trocar] 1 item",
    TextColor3=Color3.fromRGB(180,160,100), TextScaled=true, Font=Enum.Font.Gotham, ZIndex=9,
})

local InvScroll = makeScroll(InvPanel, {
    Size=UDim2.new(1,-12,1,-130), Position=UDim2.new(0,6,0,70),
    BackgroundTransparency=1, BorderSizePixel=0, ScrollBarThickness=5,
    ScrollBarImageColor3=Color3.fromRGB(200,150,50), CanvasSize=UDim2.new(0,0,0,0), ZIndex=9,
})
local invLayout = listLayout(InvScroll, 3)

local CombineBtn = makeTB(InvPanel, {
    Size=UDim2.new(0.32,0,0,38), Position=UDim2.new(0.02,0,1,-48),
    BackgroundColor3=Color3.fromRGB(40,80,40), BorderSizePixel=0,
    Text="🔀 Combinar (0/2)", TextColor3=Color3.fromRGB(160,255,160),
    TextScaled=true, Font=Enum.Font.GothamBold, ZIndex=9,
})
round(CombineBtn, 10); stroke(CombineBtn, Color3.fromRGB(80,200,80), 1.5)

local TradeInputFrame = makeFrame(InvPanel, {
    Size=UDim2.new(0.35,0,0,38), Position=UDim2.new(0.36,0,1,-48),
    BackgroundColor3=Color3.fromRGB(10,10,22), BorderSizePixel=0, ZIndex=9,
})
round(TradeInputFrame, 8)
local TradeTargetBox = Instance.new("TextBox")
TradeTargetBox.Size = UDim2.new(1,0,1,0)
TradeTargetBox.BackgroundTransparency = 1
TradeTargetBox.Text = "Nome do jogador..."
TradeTargetBox.TextColor3 = Color3.fromRGB(200,200,200)
TradeTargetBox.PlaceholderColor3 = Color3.fromRGB(100,100,100)
TradeTargetBox.TextScaled = true
TradeTargetBox.Font = Enum.Font.Gotham
TradeTargetBox.ZIndex = 10
TradeTargetBox.ClearTextOnFocus = true
TradeTargetBox.Parent = TradeInputFrame
stroke(TradeInputFrame, Color3.fromRGB(80,80,160), 1.5)

local TradeBtn = makeTB(InvPanel, {
    Size=UDim2.new(0.28,0,0,38), Position=UDim2.new(0.71,0,1,-48),
    BackgroundColor3=Color3.fromRGB(30,30,80), BorderSizePixel=0,
    Text="🔄 Propor Troca", TextColor3=Color3.fromRGB(180,180,255),
    TextScaled=true, Font=Enum.Font.GothamBold, ZIndex=9,
})
round(TradeBtn, 10); stroke(TradeBtn, Color3.fromRGB(100,100,220), 1.5)

local invSlotButtons = {}
local function buildInventoryUI()
    for _, c in ipairs(InvScroll:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
    invSlotButtons = {}
    local lo = 0
    for _, item in ipairs(localInventory) do
        lo = lo+1
        local isSelected = false
        for _, s in ipairs(selectedItems) do if s.id == item.id then isSelected=true; break end end
        local rarColor = GameConfig.RARITY_COLORS[item.rarity] or Color3.fromRGB(200,200,200)
        local row = makeFrame(InvScroll, {
            Size=UDim2.new(1,0,0,36), BackgroundColor3=isSelected and Color3.fromRGB(40,40,10) or Color3.fromRGB(15,15,22),
            BackgroundTransparency=0.1, BorderSizePixel=0, LayoutOrder=lo, ZIndex=10,
        })
        round(row, 7)
        stroke(row, isSelected and Color3.fromRGB(255,215,0) or rarColor, isSelected and 2.5 or 1)
        makeTL(row, {Size=UDim2.new(0.4,0,1,0), Position=UDim2.new(0,8,0,0), BackgroundTransparency=1,
            Text=item.name, TextColor3=rarColor, TextScaled=true, Font=Enum.Font.GothamBold,
            TextXAlignment=Enum.TextXAlignment.Left, ZIndex=11,})
        makeTL(row, {Size=UDim2.new(0.25,0,1,0), Position=UDim2.new(0.4,0,0,0), BackgroundTransparency=1,
            Text="["..item.rarity.."]", TextColor3=rarColor, TextScaled=true, Font=Enum.Font.Gotham,
            TextXAlignment=Enum.TextXAlignment.Center, ZIndex=11,})
        makeTL(row, {Size=UDim2.new(0.28,0,1,0), Position=UDim2.new(0.68,0,0,0), BackgroundTransparency=1,
            Text=item.mutationName~="Básico" and ("✦"..item.mutationName) or "",
            TextColor3=Color3.fromRGB(200,200,100), TextScaled=true, Font=Enum.Font.Gotham,
            TextXAlignment=Enum.TextXAlignment.Right, ZIndex=11,})
        local capturedItem = item
        local btn = makeTB(row, {
            Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="",
            BorderSizePixel=0, ZIndex=12,
        })
        btn.Activated:Connect(function()
            local alreadyIdx = nil
            for i, s in ipairs(selectedItems) do if s.id==capturedItem.id then alreadyIdx=i; break end end
            if alreadyIdx then
                table.remove(selectedItems, alreadyIdx)
            else
                if #selectedItems < 2 then table.insert(selectedItems, capturedItem) end
            end
            CombineBtn.Text = "🔀 Combinar ("..#selectedItems.."/2)"
            buildInventoryUI()
        end)
        table.insert(invSlotButtons, btn)
    end
    InvScroll.CanvasSize = UDim2.new(0,0,0,invLayout.AbsoluteContentSize.Y+8)
end

CombineBtn.Activated:Connect(function()
    if #selectedItems ~= 2 then showNotification("Selecione 2 itens iguais para combinar!", Color3.fromRGB(255,100,100)); return end
    local a, b = selectedItems[1], selectedItems[2]
    if a.rarity ~= b.rarity then showNotification("Os 2 itens devem ter a mesma raridade!", Color3.fromRGB(255,100,100)); return end
    CombineItemsEvent:FireServer(a.id, b.id)
    selectedItems = {}
    CombineBtn.Text = "🔀 Combinar (0/2)"
end)

TradeBtn.Activated:Connect(function()
    if #selectedItems ~= 1 then showNotification("Selecione 1 item para trocar!", Color3.fromRGB(255,100,100)); return end
    local targetName = TradeTargetBox.Text
    if targetName == "" or targetName == "Nome do jogador..." then
        showNotification("Digite o nome do jogador alvo!", Color3.fromRGB(255,100,100)); return
    end
    TradeProposeEvent:FireServer(selectedItems[1].id, targetName)
    showNotification("Proposta de troca enviada para "..targetName.."!", Color3.fromRGB(100,180,255))
    selectedItems = {}
    CombineBtn.Text = "🔀 Combinar (0/2)"
    buildInventoryUI()
end)

CloseInvBtn.Activated:Connect(function() InvPanel.Visible = false end)
InventoryBtn.Activated:Connect(function()
    InvPanel.Visible = not InvPanel.Visible
    if InvPanel.Visible then buildInventoryUI() end
end)

-- =====================================================
--  TRADE OFFER POPUP
-- =====================================================
local TradePopup = makeFrame(ScreenGui, {
    Size=UDim2.new(0,400,0,220), Position=UDim2.new(0.5,-200,0.5,-110),
    BackgroundColor3=Color3.fromRGB(10,10,20), BackgroundTransparency=0.05,
    BorderSizePixel=0, Visible=false, ZIndex=20,
})
round(TradePopup, 16); stroke(TradePopup, Color3.fromRGB(100,100,220), 2.5)
local TradePopupTitle = makeTL(TradePopup, {
    Size=UDim2.new(1,0,0,44), BackgroundColor3=Color3.fromRGB(10,10,30), BackgroundTransparency=0,
    Text="🔄 PROPOSTA DE TROCA", TextColor3=Color3.fromRGB(180,180,255),
    TextScaled=true, Font=Enum.Font.GothamBold, ZIndex=21,
})
local TradePopupInfo = makeTL(TradePopup, {
    Size=UDim2.new(1,-20,0,80), Position=UDim2.new(0,10,0,50),
    BackgroundTransparency=1, Text="...", TextColor3=Color3.fromRGB(220,220,220),
    TextScaled=true, Font=Enum.Font.Gotham, TextWrapped=true, ZIndex=21,
})
local TradeAcceptBtn = makeTB(TradePopup, {
    Size=UDim2.new(0.44,0,0,44), Position=UDim2.new(0.03,0,1,-54),
    BackgroundColor3=Color3.fromRGB(30,120,30), BorderSizePixel=0,
    Text="✔ Aceitar", TextColor3=Color3.fromRGB(180,255,180), TextScaled=true, Font=Enum.Font.GothamBold, ZIndex=21,
})
round(TradeAcceptBtn, 10)
local TradeRejectBtn = makeTB(TradePopup, {
    Size=UDim2.new(0.44,0,0,44), Position=UDim2.new(0.53,0,1,-54),
    BackgroundColor3=Color3.fromRGB(120,30,30), BorderSizePixel=0,
    Text="✕ Recusar", TextColor3=Color3.fromRGB(255,180,180), TextScaled=true, Font=Enum.Font.GothamBold, ZIndex=21,
})
round(TradeRejectBtn, 10)

local pendingTradeId = nil
TradeAcceptBtn.Activated:Connect(function()
    if pendingTradeId then TradeRespondEvent:FireServer(pendingTradeId, true) end
    TradePopup.Visible = false; pendingTradeId = nil
end)
TradeRejectBtn.Activated:Connect(function()
    if pendingTradeId then TradeRespondEvent:FireServer(pendingTradeId, false) end
    TradePopup.Visible = false; pendingTradeId = nil
end)

-- =====================================================
--  PETS PANEL
-- =====================================================
local PetPanel, ClosePetBtn = makePanel("🐾  PETS", Color3.fromRGB(255,150,150))
local localPets     = {}
local localActivePet= nil

local PetScroll = makeScroll(PetPanel, {
    Size=UDim2.new(1,-12,1,-54), Position=UDim2.new(0,6,0,54),
    BackgroundTransparency=1, BorderSizePixel=0, ScrollBarThickness=5,
    ScrollBarImageColor3=Color3.fromRGB(255,150,150), CanvasSize=UDim2.new(0,0,0,0), ZIndex=9,
})
local petLayout = listLayout(PetScroll, 4)
local petRows = {}

local function buildPetUI()
    for _, r in pairs(petRows) do r:Destroy() end; petRows = {}
    local lo = 0
    for _, pet in ipairs(GameConfig.PETS) do
        lo = lo+1
        local owned   = false
        for _, id in ipairs(localPets) do if id==pet.id then owned=true; break end end
        local isActive = (localActivePet == pet.id)
        local row = makeFrame(PetScroll, {
            Size=UDim2.new(1,0,0,60), BackgroundColor3=isActive and Color3.fromRGB(30,20,40) or Color3.fromRGB(15,15,22),
            BackgroundTransparency=0.1, BorderSizePixel=0, LayoutOrder=lo, ZIndex=10,
        })
        round(row, 10)
        stroke(row, isActive and Color3.fromRGB(220,100,255) or (owned and Color3.fromRGB(180,100,180) or Color3.fromRGB(60,60,80)), isActive and 2.5 or 1.5)
        makeTL(row, {Size=UDim2.new(0,44,1,0), BackgroundTransparency=1,
            Text=pet.icon, TextColor3=Color3.fromRGB(255,255,255), TextScaled=true, Font=Enum.Font.GothamBold, ZIndex=11,})
        makeTL(row, {Size=UDim2.new(0.35,0,0.52,0), Position=UDim2.new(0,48,0,4), BackgroundTransparency=1,
            Text=pet.name, TextColor3=Color3.fromRGB(255,200,200), TextScaled=true, Font=Enum.Font.GothamBold,
            TextXAlignment=Enum.TextXAlignment.Left, ZIndex=11,})
        local bonusTxt = ""
        if pet.auraBonus > 0 then bonusTxt = bonusTxt.."Aura +"..math.floor(pet.auraBonus*100).."%" end
        if pet.rarityBonus > 0 then bonusTxt = bonusTxt..(bonusTxt~="" and " | " or "").."Raridade +"..math.floor(pet.rarityBonus*100).."%" end
        makeTL(row, {Size=UDim2.new(0.42,0,0.4,0), Position=UDim2.new(0,48,0.52,0), BackgroundTransparency=1,
            Text=bonusTxt, TextColor3=Color3.fromRGB(200,200,150), TextScaled=true, Font=Enum.Font.Gotham,
            TextXAlignment=Enum.TextXAlignment.Left, ZIndex=11,})
        local actionBtn = makeTB(row, {
            Size=UDim2.new(0.28,0,0.7,0), Position=UDim2.new(0.70,0,0.15,0),
            BackgroundColor3=isActive and Color3.fromRGB(80,30,100)
                or owned and Color3.fromRGB(50,30,70)
                or Color3.fromRGB(30,50,30),
            BorderSizePixel=0,
            Text=isActive and "✓ Ativo" or owned and "Equipar" or ("🪙 "..formatNum(pet.cost)),
            TextColor3=isActive and Color3.fromRGB(220,150,255) or owned and Color3.fromRGB(200,180,220) or Color3.fromRGB(160,255,160),
            TextScaled=true, Font=Enum.Font.GothamBold, ZIndex=11,
        })
        round(actionBtn, 8)
        local capturedPet = pet
        actionBtn.Activated:Connect(function()
            if owned then
                EquipPetEvent:FireServer(isActive and "" or capturedPet.id)
            else
                BuyPetEvent:FireServer(capturedPet.id)
            end
        end)
        table.insert(petRows, row)
    end
    PetScroll.CanvasSize = UDim2.new(0,0,0,petLayout.AbsoluteContentSize.Y+8)
end

ClosePetBtn.Activated:Connect(function() PetPanel.Visible = false end)
PetBtn.Activated:Connect(function()
    PetPanel.Visible = not PetPanel.Visible
    if PetPanel.Visible then buildPetUI() end
end)

-- =====================================================
--  ACHIEVEMENTS PANEL
-- =====================================================
local AchievPanel, CloseAchievBtn = makePanel("🏆  CONQUISTAS", Color3.fromRGB(255,200,50))
local localAchievements = {}

local AchievScroll = makeScroll(AchievPanel, {
    Size=UDim2.new(1,-12,1,-54), Position=UDim2.new(0,6,0,54),
    BackgroundTransparency=1, BorderSizePixel=0, ScrollBarThickness=5,
    ScrollBarImageColor3=Color3.fromRGB(255,200,50), CanvasSize=UDim2.new(0,0,0,0), ZIndex=9,
})
local achievLayout = listLayout(AchievScroll, 4)
local achievRows = {}

local function buildAchievUI()
    for _, r in pairs(achievRows) do r:Destroy() end; achievRows = {}
    local lo = 0
    for _, ach in ipairs(GameConfig.ACHIEVEMENTS) do
        lo = lo+1
        local earned = localAchievements[ach.id] or false
        local row = makeFrame(AchievScroll, {
            Size=UDim2.new(1,0,0,52), BackgroundColor3=earned and Color3.fromRGB(25,22,10) or Color3.fromRGB(14,14,20),
            BackgroundTransparency=0.1, BorderSizePixel=0, LayoutOrder=lo, ZIndex=10,
        })
        round(row, 9)
        stroke(row, earned and Color3.fromRGB(255,200,50) or Color3.fromRGB(60,60,80), earned and 2 or 0.8)
        makeTL(row, {Size=UDim2.new(0,44,1,0), BackgroundTransparency=1,
            Text=earned and "🏆" or "🔒", TextColor3=Color3.fromRGB(255,200,50), TextScaled=true, Font=Enum.Font.GothamBold, ZIndex=11,})
        makeTL(row, {Size=UDim2.new(0.65,0,0.52,0), Position=UDim2.new(0,48,0,4), BackgroundTransparency=1,
            Text=ach.name, TextColor3=earned and Color3.fromRGB(255,230,100) or Color3.fromRGB(120,120,120),
            TextScaled=true, Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=11,})
        local desc = ""
        if ach.type=="totalStolen" then desc="Roubar "..ach.threshold.." brainrots"
        elseif ach.type=="rebirths" then desc="Fazer "..ach.threshold.." rebirths"
        elseif ach.type=="rarity" then desc="Obter raridade "..ach.rarity
        elseif ach.type=="mutation" then desc="Obter mutação "..ach.mutation
        elseif ach.type=="prestige" then desc="Fazer "..ach.threshold.." prestígio(s)"
        end
        makeTL(row, {Size=UDim2.new(0.65,0,0.42,0), Position=UDim2.new(0,48,0.54,0), BackgroundTransparency=1,
            Text=desc, TextColor3=Color3.fromRGB(140,140,140), TextScaled=true, Font=Enum.Font.Gotham,
            TextXAlignment=Enum.TextXAlignment.Left, ZIndex=11,})
        makeTL(row, {Size=UDim2.new(0.25,0,1,0), Position=UDim2.new(0.73,0,0,0), BackgroundTransparency=1,
            Text=earned and "OBTIDA" or "Pendente", TextColor3=earned and Color3.fromRGB(255,215,0) or Color3.fromRGB(80,80,80),
            TextScaled=true, Font=Enum.Font.GothamBold, ZIndex=11,})
        table.insert(achievRows, row)
    end
    AchievScroll.CanvasSize = UDim2.new(0,0,0,achievLayout.AbsoluteContentSize.Y+8)
end

CloseAchievBtn.Activated:Connect(function() AchievPanel.Visible = false end)
AchievBtn.Activated:Connect(function()
    AchievPanel.Visible = not AchievPanel.Visible
    if AchievPanel.Visible then buildAchievUI() end
end)

-- =====================================================
--  BATTLEPASS PANEL
-- =====================================================
local BPPanel, CloseBPBtn = makePanel("🎖  PASSE DE BATALHA", Color3.fromRGB(80,200,140))
local localBP = {xp=0, level=0, claimed={}}

local BPScroll = makeScroll(BPPanel, {
    Size=UDim2.new(1,-12,1,-80), Position=UDim2.new(0,6,0,80),
    BackgroundTransparency=1, BorderSizePixel=0, ScrollBarThickness=5,
    ScrollBarImageColor3=Color3.fromRGB(80,200,140), CanvasSize=UDim2.new(0,0,0,0), ZIndex=9,
})
local bpLayout = listLayout(BPScroll, 4)
local bpRows = {}

-- XP bar
local bpXpBg = makeFrame(BPPanel, {
    Size=UDim2.new(0.9,0,0,14), Position=UDim2.new(0.05,0,0,54),
    BackgroundColor3=Color3.fromRGB(20,40,30), BorderSizePixel=0, ZIndex=9,
})
round(bpXpBg, 6)
local bpXpFill = makeFrame(bpXpBg, {
    Size=UDim2.new(0,0,1,0), BackgroundColor3=Color3.fromRGB(60,200,120), BorderSizePixel=0, ZIndex=10,
})
round(bpXpFill, 6)
local bpXpLabel = makeTL(bpXpBg, {
    Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="Nível 0 — 0 XP",
    TextColor3=Color3.fromRGB(255,255,255), TextScaled=true, Font=Enum.Font.GothamBold, ZIndex=11,
})

local function buildBPUI()
    for _, r in pairs(bpRows) do r:Destroy() end; bpRows = {}
    local lvlXp = GameConfig.BATTLEPASS_XP_PER_LEVEL
    local xpPct = math.clamp((localBP.xp % lvlXp) / lvlXp, 0, 1)
    bpXpFill.Size = UDim2.new(xpPct, 0, 1, 0)
    bpXpLabel.Text = "Nível "..localBP.level.." — "..(localBP.xp % lvlXp).." / "..lvlXp.." XP"

    local lo = 0
    for lvl = 1, GameConfig.BATTLEPASS_LEVELS do
        lo = lo+1
        local reward   = GameConfig.BATTLEPASS_REWARDS[lvl]
        local unlocked = localBP.level >= lvl
        local claimed  = localBP.claimed[tostring(lvl)] or false

        local row = makeFrame(BPScroll, {
            Size=UDim2.new(1,0,0,46), BackgroundColor3=unlocked and Color3.fromRGB(15,28,20) or Color3.fromRGB(12,12,18),
            BackgroundTransparency=0.1, BorderSizePixel=0, LayoutOrder=lo, ZIndex=10,
        })
        round(row, 8)
        stroke(row, claimed and Color3.fromRGB(255,200,50) or (unlocked and Color3.fromRGB(80,200,140) or Color3.fromRGB(40,40,60)), claimed and 2 or 1)
        makeTL(row, {Size=UDim2.new(0,44,1,0), BackgroundTransparency=1,
            Text=claimed and "✓" or (unlocked and "⬡" or "🔒"),
            TextColor3=claimed and Color3.fromRGB(255,215,0) or (unlocked and Color3.fromRGB(80,200,140) or Color3.fromRGB(80,80,80)),
            TextScaled=true, Font=Enum.Font.GothamBold, ZIndex=11,})
        makeTL(row, {Size=UDim2.new(0.22,0,1,0), Position=UDim2.new(0,44,0,0), BackgroundTransparency=1,
            Text="Nível "..lvl, TextColor3=Color3.fromRGB(180,180,180), TextScaled=true, Font=Enum.Font.GothamBold,
            TextXAlignment=Enum.TextXAlignment.Left, ZIndex=11,})
        local rewardText = "—"
        if reward then
            if reward.type=="aura" then rewardText = "💰 "..formatNum(reward.amount).." Aura"
            elseif reward.type=="pet" then rewardText = "🐾 Pet: "..reward.id
            elseif reward.type=="title" then rewardText = "🏅 Título: "..reward.id
            end
        end
        makeTL(row, {Size=UDim2.new(0.44,0,1,0), Position=UDim2.new(0.30,0,0,0), BackgroundTransparency=1,
            Text=rewardText, TextColor3=Color3.fromRGB(220,220,100), TextScaled=true, Font=Enum.Font.Gotham,
            TextXAlignment=Enum.TextXAlignment.Left, ZIndex=11,})
        if reward and unlocked and not claimed then
            local clBtn = makeTB(row, {
                Size=UDim2.new(0.22,0,0.75,0), Position=UDim2.new(0.76,0,0.125,0),
                BackgroundColor3=Color3.fromRGB(40,120,60), BorderSizePixel=0,
                Text="Resgatar", TextColor3=Color3.fromRGB(180,255,200), TextScaled=true, Font=Enum.Font.GothamBold, ZIndex=11,
            })
            round(clBtn, 7)
            local capturedLvl = lvl
            clBtn.Activated:Connect(function() ClaimBattlepassEv:FireServer(capturedLvl) end)
        end
        table.insert(bpRows, row)
    end
    BPScroll.CanvasSize = UDim2.new(0,0,0,bpLayout.AbsoluteContentSize.Y+8)
end

CloseBPBtn.Activated:Connect(function() BPPanel.Visible = false end)
BPBtn.Activated:Connect(function()
    BPPanel.Visible = not BPPanel.Visible
    if BPPanel.Visible then buildBPUI() end
end)

-- =====================================================
--  LEADERBOARD PANEL
-- =====================================================
local LBPanel, CloseLBBtn = makePanel("🌍  RANKING GLOBAL", Color3.fromRGB(255,160,80))
local lbTabBar = makeFrame(LBPanel, {
    Size=UDim2.new(1,0,0,36), Position=UDim2.new(0,0,0,44),
    BackgroundColor3=Color3.fromRGB(12,12,22), BorderSizePixel=0, ZIndex=9,
})
local function makeLBTab(text, xPos)
    local b = makeTB(lbTabBar, {
        Size=UDim2.new(0.48,0,1,-4), Position=UDim2.new(xPos,0,0,2),
        BackgroundColor3=Color3.fromRGB(30,30,50), BorderSizePixel=0,
        Text=text, TextColor3=Color3.fromRGB(160,160,200), TextScaled=true, Font=Enum.Font.GothamBold, ZIndex=10,
    })
    round(b, 8); return b
end
local LBTabRB  = makeLBTab("Rebirths",  0.01)
local LBTabST  = makeLBTab("Roubados",  0.51)

local LBScroll = makeScroll(LBPanel, {
    Size=UDim2.new(1,-12,1,-90), Position=UDim2.new(0,6,0,86),
    BackgroundTransparency=1, BorderSizePixel=0, ScrollBarThickness=5,
    ScrollBarImageColor3=Color3.fromRGB(255,160,80), CanvasSize=UDim2.new(0,0,0,0), ZIndex=9,
})
local lbLayout = listLayout(LBScroll, 3)
local lbRows = {}
local currentLBTab = "rebirths"
local lbData = {rebirths={}, stolen={}}

local function buildLBUI()
    for _, r in pairs(lbRows) do r:Destroy() end; lbRows = {}
    local list = lbData[currentLBTab] or {}
    local MEDALS = {"🥇","🥈","🥉"}
    for i, entry in ipairs(list) do
        local lo = i
        local row = makeFrame(LBScroll, {
            Size=UDim2.new(1,0,0,44), BackgroundColor3=Color3.fromRGB(14,14,22),
            BackgroundTransparency=0.1, BorderSizePixel=0, LayoutOrder=lo, ZIndex=10,
        })
        round(row, 8)
        stroke(row, i<=3 and Color3.fromRGB(255,200,0) or Color3.fromRGB(50,50,70), i<=3 and 2 or 0.8)
        makeTL(row, {Size=UDim2.new(0,44,1,0), BackgroundTransparency=1,
            Text=MEDALS[i] or tostring(i), TextColor3=Color3.fromRGB(255,200,80), TextScaled=true, Font=Enum.Font.GothamBold, ZIndex=11,})
        makeTL(row, {Size=UDim2.new(0.5,0,1,0), Position=UDim2.new(0,48,0,0), BackgroundTransparency=1,
            Text=tostring(entry.name or "???"), TextColor3=Color3.fromRGB(220,220,220), TextScaled=true, Font=Enum.Font.GothamBold,
            TextXAlignment=Enum.TextXAlignment.Left, ZIndex=11,})
        makeTL(row, {Size=UDim2.new(0.35,0,1,0), Position=UDim2.new(0.63,0,0,0), BackgroundTransparency=1,
            Text=formatNum(entry.value or 0), TextColor3=Color3.fromRGB(255,180,80), TextScaled=true, Font=Enum.Font.GothamBold,
            TextXAlignment=Enum.TextXAlignment.Right, ZIndex=11,})
        table.insert(lbRows, row)
    end
    LBScroll.CanvasSize = UDim2.new(0,0,0,lbLayout.AbsoluteContentSize.Y+8)
end

local function switchLBTab(tab)
    currentLBTab = tab
    LBTabRB.BackgroundColor3 = (tab=="rebirths") and Color3.fromRGB(80,50,20) or Color3.fromRGB(30,30,50)
    LBTabST.BackgroundColor3 = (tab=="stolen")   and Color3.fromRGB(80,50,20) or Color3.fromRGB(30,30,50)
    buildLBUI()
end

LBTabRB.Activated:Connect(function() switchLBTab("rebirths") end)
LBTabST.Activated:Connect(function() switchLBTab("stolen") end)
CloseLBBtn.Activated:Connect(function() LBPanel.Visible = false end)
LBBtn.Activated:Connect(function()
    LBPanel.Visible = not LBPanel.Visible
    if LBPanel.Visible then
        -- Try to fetch fresh
        task.spawn(function()
            local ok, res = pcall(function() return GetLeaderboardRF:InvokeServer() end)
            if ok and res then lbData = res; buildLBUI() end
        end)
    end
end)

-- =====================================================
--  SETTINGS PANEL (volume)
-- =====================================================
local SettingsPanel, CloseSettBtn = makePanel("⚙  CONFIGURAÇÕES", Color3.fromRGB(160,160,160))
SettingsPanel.Size = UDim2.new(0,400,0,220)
SettingsPanel.Position = UDim2.new(0.5,-200,0.5,-110)

local function makeSlider(parent, label, yOff, initVal, callback)
    makeTL(parent, {Size=UDim2.new(0.9,0,0,24), Position=UDim2.new(0.05,0,0,yOff), BackgroundTransparency=1,
        Text=label, TextColor3=Color3.fromRGB(200,200,200), TextScaled=true, Font=Enum.Font.GothamBold,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=9,})
    local trackBg = makeFrame(parent, {
        Size=UDim2.new(0.85,0,0,10), Position=UDim2.new(0.075,0,0,yOff+28),
        BackgroundColor3=Color3.fromRGB(40,40,60), BorderSizePixel=0, ZIndex=9,
    })
    round(trackBg, 5)
    local fill = makeFrame(trackBg, {
        Size=UDim2.new(initVal,0,1,0), BackgroundColor3=Color3.fromRGB(100,180,255), BorderSizePixel=0, ZIndex=10,
    })
    round(fill, 5)
    local thumb = makeFrame(trackBg, {
        Size=UDim2.new(0,20,0,20), Position=UDim2.new(initVal,0,0.5,-10),
        BackgroundColor3=Color3.fromRGB(255,255,255), BorderSizePixel=0, ZIndex=11,
    })
    round(thumb, 10)

    local dragging = false
    thumb.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = true
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    RunService.Heartbeat:Connect(function()
        if not dragging then return end
        local absPos = trackBg.AbsolutePosition
        local absSize = trackBg.AbsoluteSize
        local mouseX = UserInputService:GetMouseLocation().X
        local pct = math.clamp((mouseX - absPos.X) / absSize.X, 0, 1)
        fill.Size = UDim2.new(pct,0,1,0)
        thumb.Position = UDim2.new(pct,0,0.5,-10)
        callback(pct)
    end)
end

makeSlider(SettingsPanel, "🎵 Volume Música",  56,  musicVol/0.5, function(v) setMusicVol(v*0.5) end)
makeSlider(SettingsPanel, "🔊 Volume Efeitos", 116, sfxVol/1.0,  function(v) setSfxVol(v) end)

CloseSettBtn.Activated:Connect(function() SettingsPanel.Visible = false end)
SettingsBtn.Activated:Connect(function() SettingsPanel.Visible = not SettingsPanel.Visible end)

-- =====================================================
--  TUTORIAL POPUP
-- =====================================================
local tutorialSteps = {
    {title="👋 Bem-vindo!", text="Bem-vindo ao Brainrot Roubo!\nRoube brainrots nas bases para ganhar AURA."},
    {title="🎯 Como roubar", text="Aproxime-se de uma base colorida.\nPressione [E] ou aguarde o auto-roubo."},
    {title="💫 Rebirths", text="Quando a barra de Aura encher, pressione\nRENASCER para multiplicar seus ganhos!"},
    {title="⭐ Prestígio", text="Após 8 rebirths, faça Prestígio para\nganhar multiplicador permanente."},
    {title="🎒 Inventário", text="Colecione brainrots no inventário.\nCombine 2 iguais para um mais raro!"},
    {title="🐾 Pets", text="Compre Pets para bônus de Aura\ne raridade. Equipe um ativo."},
    {title="✅ Bom jogo!", text="Explore as bases, complete missões\ne suba no ranking global. Boa sorte!"},
}
local tutStep = 1
local tutShown = false

local TutorialFrame = makeFrame(ScreenGui, {
    Size=UDim2.new(0,420,0,200), Position=UDim2.new(0.5,-210,0.5,-100),
    BackgroundColor3=Color3.fromRGB(8,8,16), BackgroundTransparency=0.05,
    BorderSizePixel=0, Visible=false, ZIndex=30,
})
round(TutorialFrame, 18); stroke(TutorialFrame, Color3.fromRGB(80,180,255), 2.5)
local TutTitle = makeTL(TutorialFrame, {
    Size=UDim2.new(1,0,0,44), BackgroundColor3=Color3.fromRGB(8,12,24), BackgroundTransparency=0,
    Text="Tutorial", TextColor3=Color3.fromRGB(80,180,255), TextScaled=true, Font=Enum.Font.GothamBold, ZIndex=31,
})
local TutText = makeTL(TutorialFrame, {
    Size=UDim2.new(1,-20,0,80), Position=UDim2.new(0,10,0,50), BackgroundTransparency=1,
    Text="...", TextColor3=Color3.fromRGB(220,220,220), TextScaled=true, Font=Enum.Font.Gotham,
    TextWrapped=true, ZIndex=31,
})
local TutProgress = makeTL(TutorialFrame, {
    Size=UDim2.new(0.5,0,0,22), Position=UDim2.new(0,10,1,-34), BackgroundTransparency=1,
    Text="1 / "..#tutorialSteps, TextColor3=Color3.fromRGB(120,120,160), TextScaled=true, Font=Enum.Font.Gotham, ZIndex=31,
})
local TutNextBtn = makeTB(TutorialFrame, {
    Size=UDim2.new(0,130,0,32), Position=UDim2.new(1,-140,1,-40),
    BackgroundColor3=Color3.fromRGB(30,80,160), BorderSizePixel=0,
    Text="Próximo →", TextColor3=Color3.fromRGB(180,220,255), TextScaled=true, Font=Enum.Font.GothamBold, ZIndex=31,
})
round(TutNextBtn, 10)
local TutSkipBtn = makeTB(TutorialFrame, {
    Size=UDim2.new(0,80,0,26), Position=UDim2.new(0,10,1,-36),
    BackgroundColor3=Color3.fromRGB(30,30,50), BorderSizePixel=0,
    Text="Pular", TextColor3=Color3.fromRGB(120,120,160), TextScaled=true, Font=Enum.Font.Gotham, ZIndex=31,
})
round(TutSkipBtn, 8)

local function showTutStep(step)
    local s = tutorialSteps[step]
    if not s then TutorialFrame.Visible = false; return end
    TutTitle.Text    = s.title
    TutText.Text     = s.text
    TutProgress.Text = step.." / "..#tutorialSteps
    TutNextBtn.Text  = step==#tutorialSteps and "Começar! ✓" or "Próximo →"
end

TutNextBtn.Activated:Connect(function()
    if tutStep >= #tutorialSteps then
        TutorialFrame.Visible = false
        TutorialDoneEvent:FireServer()
    else
        tutStep = tutStep + 1
        showTutStep(tutStep)
    end
end)
TutSkipBtn.Activated:Connect(function()
    TutorialFrame.Visible = false
    TutorialDoneEvent:FireServer()
end)

-- =====================================================
--  CAMERA SHAKE
-- =====================================================
local function cameraShake(duration, magnitude)
    local startTime = tick()
    local conn
    conn = RunService.RenderStepped:Connect(function()
        local elapsed = tick() - startTime
        if elapsed >= duration then conn:Disconnect(); return end
        local decay = 1 - (elapsed/duration)
        Camera.CFrame = Camera.CFrame * CFrame.new(
            (math.random()-0.5)*magnitude*decay,
            (math.random()-0.5)*magnitude*decay, 0
        )
    end)
end

-- =====================================================
--  CLIENT STATE
-- =====================================================
local currentData = {
    aura=0, auraCap=GameConfig.BASE_AURA_CAP, rebirths=0, multiplier=1,
    rebirthCost=math.floor(GameConfig.BASE_AURA_CAP*GameConfig.REBIRTH_COST_FRACTION),
    totalStolen=0, upgrades={stealRange=0,walkSpeed=0,auraBonus=0},
    prestige=0, isVIP=false,
}
local lastMutation = "Básico"
local lastRebirths = 0
local lastPrestige = 0

local function refreshUI()
    local d = currentData
    AuraValueLabel.Text = formatNum(d.aura).." / "..formatNum(d.auraCap)
    local pct = math.clamp(d.aura/math.max(d.auraCap,1),0,1)
    TweenService:Create(BarFill, TweenInfo.new(0.35,Enum.EasingStyle.Quad), {Size=UDim2.new(pct,0,1,0)}):Play()
    local barColor = pct<0.5 and Color3.fromRGB(80,220,80) or pct<0.85 and Color3.fromRGB(255,200,0) or Color3.fromRGB(255,70,70)
    BarFill.BackgroundColor3 = barColor

    RebirthsLabel.Text = "Rebirths: "..tostring(d.rebirths)
    MultLabel.Text     = "Mult: x"..formatNum(d.multiplier)
    StolenLabel.Text   = "Roubados: "..tostring(d.totalStolen)
    CostLabel.Text     = "Custo RB: "..formatNum(d.rebirthCost)
    MutLabel.Text      = "Última Mut: "..lastMutation
    PrestigeLabel.Text = "Prestígio: "..tostring(d.prestige or 0)..(d.isVIP and " [VIP]" or "")

    local canRB = d.aura >= d.rebirthCost
    RebirthBtn.Text = string.format("RENASCER  (%s / %s)", formatNum(d.aura), formatNum(d.rebirthCost))
    RebirthBtn.BackgroundColor3 = canRB and Color3.fromRGB(255,200,0) or Color3.fromRGB(80,80,80)
    RebirthBtn.TextColor3       = canRB and Color3.fromRGB(30,20,0)   or Color3.fromRGB(160,160,160)

    local canPrestige = (d.rebirths or 0) >= GameConfig.MAX_REBIRTHS_FOR_PRESTIGE
    PrestigeBtn.Visible = canPrestige
end

RebirthBtn.MouseEnter:Connect(function()
    TweenService:Create(RebirthBtn,TweenInfo.new(0.12),{Size=UDim2.new(0,256,0,62),Position=UDim2.new(0.5,-128,1,-76)}):Play()
end)
RebirthBtn.MouseLeave:Connect(function()
    local w = btnW
    TweenService:Create(RebirthBtn,TweenInfo.new(0.12),{Size=UDim2.new(0,w,0,58),Position=UDim2.new(0.5,-w/2,1,-74)}):Play()
end)

-- =====================================================
--  REMOTE EVENT HANDLERS
-- =====================================================
UpdateAuraRE.OnClientEvent:Connect(function(payload)
    for k, v in pairs(payload) do currentData[k] = v end
    if currentData.rebirths > lastRebirths then
        pcall(function() sfxRebirth:Play() end)
        showNotification("✨ REBIRTH! x"..tostring(currentData.multiplier).." multiplicador!", Color3.fromRGB(255,215,0))
        lastRebirths = currentData.rebirths
    end
    if (currentData.prestige or 0) > lastPrestige then
        pcall(function() sfxPrestige:Play() end)
        cameraShake(1.5, 0.6)
        showNotification("⭐ PRESTÍGIO "..currentData.prestige.."! Multiplicador permanente!", Color3.fromRGB(220,100,255), true)
        lastPrestige = currentData.prestige or 0
    end
    refreshUI()
    if UpgradePanel.Visible then buildUpgradeUI(currentData.upgrades) end
end)

NotifyRE.OnClientEvent:Connect(function(msg, color)
    showNotification(msg, color)
    if msg:find("Aura") and msg:sub(1,1)=="+" then
        pcall(function() sfxSteal:Play() end)
    end
    local mutMatch = msg:match("%[(.-)%s×")
    if mutMatch then lastMutation=mutMatch; refreshUI() end
end)

IndexUpdateRE.OnClientEvent:Connect(function(indexData)
    localIndex = indexData
    if IndexPanel.Visible then buildIndexUI() end
end)

MissionUpdateRE.OnClientEvent:Connect(function(md)
    localMissions = md
    if MissionsPanel.Visible then buildMissionsUI(md) end
    local hasClaim = false
    if md then
        for _, mId in ipairs(md.active) do
            local prog = md.progress[mId] or 0
            for _, m in ipairs(GameConfig.DAILY_MISSIONS) do
                if m.id==mId and prog>=m.target and not md.claimed[mId] then hasClaim=true; break end
            end
        end
    end
    MissionsBtn.BackgroundColor3 = hasClaim and Color3.fromRGB(60,60,20) or Color3.fromRGB(15,15,25)
    MissionsBtn.TextColor3 = hasClaim and Color3.fromRGB(255,215,0) or Color3.fromRGB(180,180,255)
end)

GlobalAnnounceRE.OnClientEvent:Connect(function(msg, color)
    showNotification(msg, color, true)
    LuaBannerLabel.Text = msg; LuaBanner.Visible = true
    TweenService:Create(LuaBanner,TweenInfo.new(0.3),{BackgroundTransparency=0.1}):Play()
    if msg:find("LUA DE SANGUE") then pcall(function() sfxLua:Play() end) end
    task.delay(5, function()
        TweenService:Create(LuaBanner,TweenInfo.new(0.5),{BackgroundTransparency=1}):Play()
        task.wait(0.52); LuaBanner.Visible=false; LuaBanner.BackgroundTransparency=0.1
    end)
end)

InventoryUpdateRE.OnClientEvent:Connect(function(inv)
    localInventory = inv or {}
    if InvPanel.Visible then buildInventoryUI() end
end)

TradeOfferRE.OnClientEvent:Connect(function(tradeId, proposerName, itemName, itemRarity)
    pendingTradeId = tradeId
    TradePopupInfo.Text = proposerName.." quer trocar um item com você!\n\n"
        ..proposerName.." oferece: "..itemName.." ["..itemRarity.."]"
    TradePopup.Visible = true
end)

TradeResultRE.OnClientEvent:Connect(function(success, msg)
    showNotification(msg, success and Color3.fromRGB(100,255,100) or Color3.fromRGB(255,100,100))
end)

PetUpdateRE.OnClientEvent:Connect(function(pets, activePet)
    localPets = pets or {}
    localActivePet = activePet
    if PetPanel.Visible then buildPetUI() end
end)

AchievementRE.OnClientEvent:Connect(function(achId, achName)
    localAchievements[achId] = true
    pcall(function() sfxAchiev:Play() end)
    showNotification("🏆 CONQUISTA: "..achName, Color3.fromRGB(255,200,50), true)
    if AchievPanel.Visible then buildAchievUI() end
end)

BattlepassUpdateRE.OnClientEvent:Connect(function(bp)
    localBP = bp or {xp=0,level=0,claimed={}}
    if BPPanel.Visible then buildBPUI() end
end)

LeaderboardRE.OnClientEvent:Connect(function(data)
    lbData = data or {rebirths={}, stolen={}}
    if LBPanel.Visible then buildLBUI() end
end)

BiomeUpdateRE.OnClientEvent:Connect(function(innerBases)
    showNotification("🌀 Zona Épica rotacionou! Novas bases: "..table.concat(innerBases,", "), Color3.fromRGB(0,200,180))
    -- Update minimap highlight
    for i, dot in pairs(miniDots) do
        local isInner = false
        for _, idx in ipairs(innerBases) do if idx==i then isInner=true; break end end
        dot.BackgroundColor3 = isInner and Color3.fromRGB(0,200,180) or Color3.fromRGB(60,60,80)
    end
end)

EventUpdateRE.OnClientEvent:Connect(function(eventData)
    if eventData and eventData.name then
        EventBanner.Visible = true
        EventBannerLabel.Text = "🎉 "..eventData.name.." — "..tostring(math.floor((eventData.auraBonus or 1)*100)).."% aura"
    else
        EventBanner.Visible = false
    end
end)

-- Tutorial trigger (server sends UpdateAura with hasSeenTutorial=false on first join)
UpdateAuraRE.OnClientEvent:Connect(function(payload)
    if payload.hasSeenTutorial == false and not tutShown then
        tutShown = true
        task.delay(3.5, function()
            showTutStep(1)
            TutorialFrame.Visible = true
        end)
    end
end)

-- Prestige + Title change
PrestigeBtn.Activated:Connect(function() PrestigeEvent:FireServer() end)

-- =====================================================
--  PROXIMITY / HEARTBEAT
-- =====================================================
local nearestBrainrot = nil
local luaPulseT       = 0

RunService.Heartbeat:Connect(function(dt)
    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    -- Mini-map player dot
    local px, pz = worldToMap(root.Position.X, root.Position.Z)
    playerDot.Position = UDim2.new(0,math.clamp(px-5,0,MAP_SIZE-10), 0,math.clamp(pz-5,0,MAP_SIZE-10))

    for i, dot in pairs(miniDots) do
        local basePart = workspace:FindFirstChild("Base_"..i)
        if basePart then
            local ind = basePart:FindFirstChild("Indicator")
            if ind then dot.BackgroundColor3 = ind.Color end
        end
    end

    -- Brainrot detection
    local folder = workspace:FindFirstChild("Brainrots")
    if not folder then return end

    local stealRange = GameConfig.STEAL_RANGE
    if currentData.upgrades then
        local lvl = currentData.upgrades.stealRange or 0
        if lvl > 0 then
            for _, upg in ipairs(GameConfig.UPGRADES) do
                if upg.id=="stealRange" then stealRange=upg.values[math.min(lvl,upg.maxLevel)]; break end
            end
        end
    end

    local best, bestDist = nil, stealRange
    for _, part in ipairs(folder:GetChildren()) do
        if part:IsA("BasePart") then
            local d = (root.Position-part.Position).Magnitude
            if d < bestDist then bestDist=d; best=part end
        end
    end

    nearestBrainrot = best
    StealPrompt.Visible    = best ~= nil
    MobileStealBtn.Visible = best ~= nil

    if best then
        local meta = best:FindFirstChild("Meta")
        local isLua = false
        if meta then
            local bName   = meta:FindFirstChild("BrainrotName") and meta.BrainrotName.Value or "?"
            local rarity  = meta:FindFirstChild("Rarity")       and meta.Rarity.Value       or "Comum"
            local aura    = meta:FindFirstChild("AuraValue")    and meta.AuraValue.Value    or 0
            local mutName = meta:FindFirstChild("MutationName") and meta.MutationName.Value or "Básico"
            local mutMult = meta:FindFirstChild("MutationMult") and meta.MutationMult.Value or 1
            isLua = (mutName=="Lua de Sangue")
            local gained  = math.floor(aura*mutMult*currentData.multiplier)
            local rarColor = GameConfig.RARITY_COLORS[rarity] or Color3.fromRGB(255,255,255)
            local mutColor = Color3.fromRGB(180,180,180)
            for _, m in ipairs(GameConfig.MUTATIONS) do if m.name==mutName then mutColor=m.color; break end end
            StealNameLabel.Text      = (isLua and "🌑 " or "")..bName
            StealRarLabel.Text       = "["..rarity.."]  +"..formatNum(gained).." aura"
            StealRarLabel.TextColor3 = rarColor
            StealMutLabel.Text       = (isLua and "🌑 " or "✦ ")..mutName.."  ×"..tostring(mutMult)
            StealMutLabel.TextColor3 = mutColor
        end

        if isLua then
            luaPulseT = luaPulseT+dt*4
            local alpha = (math.sin(luaPulseT)+1)/2
            stealStroke.Color     = Color3.fromRGB(math.floor(180+alpha*75),0,0)
            stealStroke.Thickness = 2+alpha*2
        else
            luaPulseT=0; stealStroke.Color=Color3.fromRGB(255,255,255); stealStroke.Thickness=1.5
        end
    end
end)

-- NPC Vendedor ProximityPrompt listener
workspace.ChildAdded:Connect(function(child)
    if child.Name=="VendedorNPC" then
        local pp = child:FindFirstChildWhichIsA("ProximityPrompt")
        if pp then
            pp.Triggered:Connect(function()
                UpgradePanel.Visible = true
                buildUpgradeUI(currentData.upgrades)
            end)
        end
    end
end)
local npc = workspace:FindFirstChild("VendedorNPC")
if npc then
    local pp = npc:FindFirstChildWhichIsA("ProximityPrompt")
    if pp then
        pp.Triggered:Connect(function()
            UpgradePanel.Visible = true
            buildUpgradeUI(currentData.upgrades)
        end)
    end
end

-- =====================================================
--  INPUT
-- =====================================================
local function doSteal()
    if nearestBrainrot and nearestBrainrot.Parent then
        autoStealTimer = 0
        StealEvent:FireServer(nearestBrainrot)
    end
end

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.E then doSteal() end
    if input.KeyCode == Enum.KeyCode.Slash then
        -- Admin command via chat-like shortcut (type in chat instead)
    end
end)

MobileStealBtn.Activated:Connect(doSteal)
RebirthBtn.Activated:Connect(function() RebirthEvent:FireServer() end)

refreshUI()
print("[BrainrotRoubo] Interface v2 carregada — "..player.DisplayName)
