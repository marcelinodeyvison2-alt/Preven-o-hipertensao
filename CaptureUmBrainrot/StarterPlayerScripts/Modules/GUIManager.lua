-- GUIManager.lua (client ModuleScript)
-- Builds and manages ALL ScreenGui elements.

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local GameConfig     = require(game.ReplicatedStorage.Modules.GameConfig)
local BrainrotConfig = require(game.ReplicatedStorage.Modules.BrainrotConfig)
local PetConfig      = require(game.ReplicatedStorage.Modules.PetConfig)
local EventConfig    = require(game.ReplicatedStorage.Modules.EventConfig)

local GUIManager  = {}
local localPlayer = Players.LocalPlayer
local playerGui   = localPlayer:WaitForChild("PlayerGui")

local C  = GameConfig.UIColors
local RC = GameConfig.RarityColors
local RN = GameConfig.RarityNames

-- ── Shared UI helpers ─────────────────────────────────────────────────────────

local function newSG(name, zOrder)
    local sg = Instance.new("ScreenGui")
    sg.Name = name; sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder   = zOrder or 1
    sg.Parent         = playerGui
    return sg
end

local function corner(parent, r)
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(r or 0.12, 0); c.Parent = parent
end

local function stroke(parent, color, thick)
    local s = Instance.new("UIStroke"); s.Color = color or C.Accent; s.Thickness = thick or 2; s.Parent = parent
end

local function lbl(parent, props)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1; l.Font = Enum.Font.GothamBold
    l.TextColor3 = C.Text; l.TextScaled = true; l.TextWrapped = true
    for k, v in pairs(props) do l[k] = v end
    l.Parent = parent; return l
end

local function frm(parent, props)
    local f = Instance.new("Frame"); f.BackgroundColor3 = C.Panel
    for k, v in pairs(props) do f[k] = v end
    f.Parent = parent; return f
end

local function btn(parent, props, cb)
    local b = Instance.new("TextButton"); b.AutoButtonColor = false
    b.Font = Enum.Font.GothamBold; b.TextScaled = true
    b.TextColor3 = C.Text; b.BackgroundColor3 = C.Accent
    for k, v in pairs(props) do b[k] = v end
    b.Parent = parent; corner(b, 0.15)
    if cb then
        b.MouseButton1Click:Connect(cb)
        b.MouseEnter:Connect(function()
            TweenService:Create(b, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(130, 110, 255)}):Play()
        end)
        b.MouseLeave:Connect(function()
            TweenService:Create(b, TweenInfo.new(0.1), {BackgroundColor3 = b:GetAttribute("BaseColor") or C.Accent}):Play()
        end)
    end
    return b
end

local function colorBtn(b, color)
    b.BackgroundColor3 = color; b:SetAttribute("BaseColor", color)
    b.MouseLeave:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.1), {BackgroundColor3 = color}):Play()
    end)
end

local function scroll(parent, props)
    local s = Instance.new("ScrollingFrame"); s.BackgroundTransparency = 0.5
    s.BackgroundColor3 = C.Panel; s.ScrollBarThickness = 6
    s.ScrollBarImageColor3 = C.Accent; s.CanvasSize = UDim2.new(0,0,0,0)
    s.AutomaticCanvasSize = Enum.AutomaticSize.Y
    for k, v in pairs(props) do s[k] = v end
    s.Parent = parent; return s
end

local function listLayout(parent)
    local l = Instance.new("UIListLayout"); l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Padding = UDim.new(0,5); l.Parent = parent; return l
end

local function gridLayout(parent, cellSize)
    local g = Instance.new("UIGridLayout"); g.CellSize = cellSize or UDim2.new(0,160,0,90)
    g.CellPadding = UDim2.new(0,8,0,8); g.SortOrder = Enum.SortOrder.LayoutOrder; g.Parent = parent
end

local function pad(parent, all)
    local p = Instance.new("UIPadding"); p.PaddingAll = UDim.new(0, all or 8); p.Parent = parent
end

local function closeBtn(parent, sg)
    return btn(parent, { Size=UDim2.new(0,44,0,44), Position=UDim2.new(1,-50,0,4),
        Text="✕", BackgroundColor3=C.Error }, function() sg.Enabled = false end)
end

local function panelTitle(parent, text, color)
    lbl(parent, { Size=UDim2.new(1,-60,0,50), Position=UDim2.new(0,8,0,4),
        Text=text, TextColor3=color or C.Gold, Font=Enum.Font.GothamBold,
        TextXAlignment=Enum.TextXAlignment.Left })
end

-- ── HUD (Row 1 + Row 2) ───────────────────────────────────────────────────────

local hudSG = newSG("HUD_GUI", 1)

local hudRow1 = frm(hudSG, {
    Size=UDim2.new(1,0,0,58), Position=UDim2.new(0,0,0,0),
    BackgroundColor3=Color3.fromRGB(10,10,25), BackgroundTransparency=0.1
})

local auraLabel  = lbl(hudRow1, { Size=UDim2.new(0.26,0,1,0), Position=UDim2.new(0.04,0,0,0),
    Text="⭐ 0 Aura", TextColor3=C.Gold, TextXAlignment=Enum.TextXAlignment.Left })
local countLabel = lbl(hudRow1, { Size=UDim2.new(0.22,0,1,0), Position=UDim2.new(0.3,0,0,0),
    Text="🧠 0", TextXAlignment=Enum.TextXAlignment.Left })
local areaLabel  = lbl(hudRow1, { Size=UDim2.new(0.22,0,1,0), Position=UDim2.new(0.52,0,0,0),
    Text="📍 Campo", TextXAlignment=Enum.TextXAlignment.Left })

local invBtn  = btn(hudRow1, { Size=UDim2.new(0,120,0,44), Position=UDim2.new(1,-254,0.5,-22),
    Text="🎒 Inventário", BackgroundColor3=Color3.fromRGB(60,50,160) })
local rankBtn = btn(hudRow1, { Size=UDim2.new(0,120,0,44), Position=UDim2.new(1,-128,0.5,-22),
    Text="🏆 Ranking", BackgroundColor3=Color3.fromRGB(160,120,0) })

local hudRow2 = frm(hudSG, {
    Size=UDim2.new(1,0,0,44), Position=UDim2.new(0,0,0,58),
    BackgroundColor3=Color3.fromRGB(8,8,20), BackgroundTransparency=0.15
})

local function hudBtn2(text, xPos, col)
    local b = btn(hudRow2, { Size=UDim2.new(0,110,0,36), Position=UDim2.new(0,xPos,0.5,-18),
        Text=text, BackgroundColor3=col })
    colorBtn(b, col); return b
end

local petsBtn    = hudBtn2("🐾 Pets",      10,  Color3.fromRGB(0,120,200))
local rebirthBtn = hudBtn2("♻️ Rebirth",   128, Color3.fromRGB(180,50,50))
local eventBadge = lbl(hudRow2, { Size=UDim2.new(0,200,0,36), Position=UDim2.new(0.5,-100,0.5,-18),
    Text="", TextColor3=C.Gold, Font=Enum.Font.GothamBold })
local tradeBtn   = hudBtn2("🔄 Troca",     0,   Color3.fromRGB(40,140,60))
local clanBtn    = hudBtn2("🏛️ Clã",       0,   Color3.fromRGB(80,40,140))

-- Adjust right-aligned buttons
tradeBtn.Position = UDim2.new(1,-238,0.5,-18)
clanBtn.Position  = UDim2.new(1,-120,0.5,-18)

-- ── Capture Popup ─────────────────────────────────────────────────────────────

local popSG = newSG("CapturePopup_GUI", 5)
local capPop = frm(popSG, { Size=UDim2.new(0,320,0,110), Position=UDim2.new(0.5,-160,0,-130),
    BackgroundColor3=Color3.fromRGB(15,15,35), BackgroundTransparency=0.1 })
corner(capPop); stroke(capPop)
lbl(capPop, { Name="Title", Size=UDim2.new(1,-10,0.4,0), Position=UDim2.new(0,5,0.04,0),
    Text="✨ Brainrot Capturado!", TextColor3=C.Gold })
local popName   = lbl(capPop, { Size=UDim2.new(1,-10,0.32,0), Position=UDim2.new(0,5,0.42,0), Text="" })
local popRarity = lbl(capPop, { Size=UDim2.new(1,-10,0.25,0), Position=UDim2.new(0,5,0.73,0), Text="" })
local popBusy   = false

local function showCapturePopup(entry)
    if popBusy then return end; popBusy = true
    local col = RC[entry.Rarity] or C.Text
    popName.Text = (entry.Emoji or "").. " " ..entry.Name
    popRarity.Text = (RN[entry.Rarity] or entry.Rarity).."  •  +"..entry.AuraValue.." Aura"
    popRarity.TextColor3 = col
    stroke(capPop, col, 2)
    TweenService:Create(capPop, TweenInfo.new(0.35,Enum.EasingStyle.Back,Enum.EasingDirection.Out),
        {Position=UDim2.new(0.5,-160,0,10)}):Play()
    task.delay(2.5, function()
        TweenService:Create(capPop, TweenInfo.new(0.25,Enum.EasingStyle.Quad,Enum.EasingDirection.In),
            {Position=UDim2.new(0.5,-160,0,-130)}):Play()
        task.wait(0.3); popBusy = false
    end)
end

-- ── Notification Toast ────────────────────────────────────────────────────────

local notifSG     = newSG("Notif_GUI", 4)
local notifQueue  = {}
local notifActive = false
local notifFrame  = frm(notifSG, { Size=UDim2.new(0,340,0,60),
    Position=UDim2.new(0.5,-170,1,20), BackgroundColor3=Color3.fromRGB(20,20,45),
    BackgroundTransparency=0.1 })
corner(notifFrame,0.15)
local notifLbl = lbl(notifFrame, { Size=UDim2.new(1,-12,1,0), Position=UDim2.new(0,6,0,0),
    Text="", TextXAlignment=Enum.TextXAlignment.Left })

local typeColors = {
    [GameConfig.NotifType.Success] = C.Success, [GameConfig.NotifType.Error] = C.Error,
    [GameConfig.NotifType.Info]    = C.Accent,  [GameConfig.NotifType.Rare]  = C.Gold,
}

local function processNotif()
    if notifActive or #notifQueue == 0 then return end; notifActive = true
    local n = table.remove(notifQueue,1)
    local col = typeColors[n.type] or C.Text
    stroke(notifFrame, col, 2); notifLbl.Text = n.message; notifLbl.TextColor3 = col
    TweenService:Create(notifFrame,TweenInfo.new(0.3,Enum.EasingStyle.Back,Enum.EasingDirection.Out),
        {Position=UDim2.new(0.5,-170,1,-78)}):Play()
    task.delay(2.8, function()
        TweenService:Create(notifFrame,TweenInfo.new(0.25,Enum.EasingStyle.Quad,Enum.EasingDirection.In),
            {Position=UDim2.new(0.5,-170,1,20)}):Play()
        task.wait(0.3); notifActive = false; processNotif()
    end)
end

local function pushNotif(data) notifQueue[#notifQueue+1] = data; processNotif() end

-- ── Inventory Panel ───────────────────────────────────────────────────────────

local invSG = newSG("Inventory_GUI", 3); invSG.Enabled = false
local invPanel = frm(invSG, { Size=UDim2.new(0.85,0,0.85,0), Position=UDim2.new(0.075,0,0.075,0),
    BackgroundColor3=C.Background })
corner(invPanel,0.04); stroke(invPanel,C.Accent)
panelTitle(invPanel,"🎒 Inventário")
closeBtn(invPanel, invSG)

local invStats = frm(invPanel, { Size=UDim2.new(1,-16,0,40), Position=UDim2.new(0,8,0,60),
    BackgroundColor3=C.Panel }); corner(invStats,0.12)
local invStatsLbl = lbl(invStats, { Size=UDim2.new(0.68,0,1,0), Position=UDim2.new(0,6,0,0),
    Text="0 itens", TextXAlignment=Enum.TextXAlignment.Left, Font=Enum.Font.Gotham })
local sellAllBtn = btn(invStats, { Size=UDim2.new(0,140,0,32), Position=UDim2.new(1,-146,0.5,-16),
    Text="💰 Vender Tudo", BackgroundColor3=Color3.fromRGB(180,140,0) })

local invScroll = scroll(invPanel, { Size=UDim2.new(1,-16,1,-112), Position=UDim2.new(0,8,0,108) })
corner(invScroll,0.05); gridLayout(invScroll); pad(invScroll)

local currentInventory     = {}
local currentUnlockedAreas = {}

local function refreshInventoryUI()
    for _, c in ipairs(invScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    local total = 0
    for _, item in ipairs(currentInventory) do
        total = total + (item.AuraValue or 0)
        local card = frm(invScroll, { Size=UDim2.new(0,160,0,90), BackgroundColor3=Color3.fromRGB(22,22,48) })
        corner(card,0.12); stroke(card, RC[item.Rarity] or C.Text, 2)
        lbl(card,{Size=UDim2.new(1,-6,0.5,0),Position=UDim2.new(0,3,0,2),Text=(item.Emoji or"🧠").." "..item.Name,Font=Enum.Font.Gotham})
        lbl(card,{Size=UDim2.new(1,-6,0.28,0),Position=UDim2.new(0,3,0.5,0),Text=RN[item.Rarity] or item.Rarity,TextColor3=RC[item.Rarity] or C.Text,Font=Enum.Font.Gotham})
        lbl(card,{Size=UDim2.new(1,-6,0.25,0),Position=UDim2.new(0,3,0.75,0),Text=item.AuraValue.." Aura",TextColor3=C.Gold,Font=Enum.Font.Gotham})
    end
    invStatsLbl.Text = #currentInventory.." itens  •  Valor: "..total.." Aura"
end

sellAllBtn.MouseButton1Click:Connect(function()
    game.ReplicatedStorage.RemoteEvents.SellBrainrots:FireServer(nil)
end)
invSG:GetPropertyChangedSignal("Enabled"):Connect(function() if invSG.Enabled then refreshInventoryUI() end end)
invBtn.MouseButton1Click:Connect(function() invSG.Enabled = not invSG.Enabled end)

-- ── Ranking Panel ─────────────────────────────────────────────────────────────

local rankSG = newSG("Ranking_GUI",3); rankSG.Enabled = false
local rankPanel = frm(rankSG, { Size=UDim2.new(0.6,0,0.8,0), Position=UDim2.new(0.2,0,0.1,0),
    BackgroundColor3=C.Background }); corner(rankPanel,0.04); stroke(rankPanel,C.Gold)
panelTitle(rankPanel,"🏆 Ranking Global", C.Gold); closeBtn(rankPanel,rankSG)
local rankScroll = scroll(rankPanel,{Size=UDim2.new(1,-16,1,-68),Position=UDim2.new(0,8,0,62)})
corner(rankScroll,0.05); listLayout(rankScroll); pad(rankScroll,4)
local MEDALS = {"🥇","🥈","🥉"}

local function refreshRanking(ranking)
    for _, c in ipairs(rankScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    for i, e in ipairs(ranking) do
        local row = frm(rankScroll,{Size=UDim2.new(1,-8,0,46),
            BackgroundColor3=(i%2==0)and Color3.fromRGB(18,18,40) or Color3.fromRGB(25,25,52),LayoutOrder=i})
        corner(row,0.1)
        local medal = MEDALS[i] or("#"..i)
        lbl(row,{Size=UDim2.new(0.06,0,1,0),Text=medal})
        lbl(row,{Size=UDim2.new(0.25,0,1,0),Position=UDim2.new(0.06,0,0,0),Text=e.Name,TextXAlignment=Enum.TextXAlignment.Left})
        lbl(row,{Size=UDim2.new(0.22,0,1,0),Position=UDim2.new(0.31,0,0,0),Text=tostring(e.Aura).." ⭐",TextColor3=C.Gold})
        lbl(row,{Size=UDim2.new(0.18,0,1,0),Position=UDim2.new(0.53,0,0,0),Text=tostring(e.TotalBrainrots).." 🧠"})
        lbl(row,{Size=UDim2.new(0.12,0,1,0),Position=UDim2.new(0.71,0,0,0),Text="♻️"..tostring(e.RebirthCount or 0)})
        lbl(row,{Size=UDim2.new(0.17,0,1,0),Position=UDim2.new(0.83,0,0,0),Text=e.ClanName or"",TextColor3=Color3.fromRGB(180,140,255)})
    end
end

rankBtn.MouseButton1Click:Connect(function()
    rankSG.Enabled = not rankSG.Enabled
    if rankSG.Enabled then game.ReplicatedStorage.RemoteEvents.RequestRanking:FireServer() end
end)

-- ── Area Unlock Panel ─────────────────────────────────────────────────────────

local areaSG = newSG("Area_GUI",2); areaSG.Enabled = false
local areaPanel = frm(areaSG,{Size=UDim2.new(0.65,0,0.78,0),Position=UDim2.new(0.175,0,0.11,0),
    BackgroundColor3=C.Background}); corner(areaPanel,0.04); stroke(areaPanel,C.Accent)
panelTitle(areaPanel,"🗺️ Áreas do Mapa", C.Accent); closeBtn(areaPanel,areaSG)
local areaScroll = scroll(areaPanel,{Size=UDim2.new(1,-16,1,-68),Position=UDim2.new(0,8,0,62),BackgroundTransparency=1})
listLayout(areaScroll); pad(areaScroll,6)

local function buildAreaCards(ua)
    for _, c in ipairs(areaScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    for idx, key in ipairs(BrainrotConfig.AreaOrder) do
        local ad = BrainrotConfig.Areas[key]
        local unlocked = ua[key] == true
        local card = frm(areaScroll,{Size=UDim2.new(1,-12,0,78),LayoutOrder=idx,
            BackgroundColor3=unlocked and Color3.fromRGB(18,45,22) or Color3.fromRGB(35,15,15)})
        corner(card,0.1); stroke(card,unlocked and C.Success or C.Error,2)
        lbl(card,{Size=UDim2.new(0.55,0,0.5,0),Position=UDim2.new(0.01,0,0,0),
            Text=(unlocked and"✅ "or"🔒 ")..ad.DisplayName,
            TextXAlignment=Enum.TextXAlignment.Left,TextColor3=unlocked and C.Success or C.Error})
        lbl(card,{Size=UDim2.new(0.55,0,0.45,0),Position=UDim2.new(0.01,0,0.5,0),
            Text="Raridades: "..table.concat(ad.Rarities,", "),
            TextXAlignment=Enum.TextXAlignment.Left,TextColor3=C.TextDim,Font=Enum.Font.Gotham})
        if not unlocked then
            lbl(card,{Size=UDim2.new(0.26,0,0.9,0),Position=UDim2.new(0.55,0,0.05,0),
                Text=tostring(ad.UnlockCost).." Aura",TextColor3=C.Gold})
            btn(card,{Size=UDim2.new(0.16,0,0.7,0),Position=UDim2.new(0.82,0,0.15,0),
                Text="Abrir",BackgroundColor3=C.Gold,TextColor3=Color3.fromRGB(0,0,0)},
                function() game.ReplicatedStorage.RemoteEvents.UnlockArea:FireServer(key) end)
        else
            lbl(card,{Size=UDim2.new(0.4,0,0.9,0),Position=UDim2.new(0.58,0,0.05,0),Text="Desbloqueada!",TextColor3=C.Success})
        end
    end
end

local areaMapBtn = btn(hudRow1,{Size=UDim2.new(0,36,0,44),Position=UDim2.new(0,0,0.5,-22),Text="🗺️",BackgroundColor3=Color3.fromRGB(40,30,110)},
    function() areaSG.Enabled = not areaSG.Enabled; if areaSG.Enabled then buildAreaCards(currentUnlockedAreas) end end)

-- ── Pets Panel ────────────────────────────────────────────────────────────────

local petSG = newSG("Pets_GUI",3); petSG.Enabled = false
local petPanel = frm(petSG,{Size=UDim2.new(0.85,0,0.85,0),Position=UDim2.new(0.075,0,0.075,0),
    BackgroundColor3=C.Background}); corner(petPanel,0.04); stroke(petPanel,Color3.fromRGB(0,150,255))
panelTitle(petPanel,"🐾 Meus Pets",Color3.fromRGB(100,200,255)); closeBtn(petPanel,petSG)

-- Egg buy bar
local eggBar = frm(petPanel,{Size=UDim2.new(1,-16,0,48),Position=UDim2.new(0,8,0,58),BackgroundColor3=C.Panel})
corner(eggBar,0.12)
lbl(eggBar,{Size=UDim2.new(0.55,0,1,0),Position=UDim2.new(0,6,0,0),
    Text="🥚 Abrir Ovo  =  500 Aura",TextColor3=Color3.fromRGB(200,240,255),TextXAlignment=Enum.TextXAlignment.Left,Font=Enum.Font.Gotham})
local eggBtn = btn(eggBar,{Size=UDim2.new(0,130,0,36),Position=UDim2.new(1,-136,0.5,-18),
    Text="🥚 Abrir Ovo",BackgroundColor3=Color3.fromRGB(0,120,200)},
    function() game.ReplicatedStorage.RemoteEvents.OpenPetEgg:FireServer() end)

-- Equipped slots
local slotsBar = frm(petPanel,{Size=UDim2.new(1,-16,0,70),Position=UDim2.new(0,8,0,114),BackgroundColor3=C.Panel})
corner(slotsBar,0.12)
lbl(slotsBar,{Size=UDim2.new(1,0,0.35,0),Text="Pets Equipados (max 3)",TextColor3=C.TextDim,Font=Enum.Font.Gotham})
local slotLabels = {}
for i = 1, 3 do
    local slot = frm(slotsBar,{Size=UDim2.new(0.3,0,0.6,0),Position=UDim2.new((i-1)*0.33,0,0.37,0),
        BackgroundColor3=Color3.fromRGB(30,30,60)})
    corner(slot,0.12); stroke(slot,Color3.fromRGB(0,120,200),1)
    slotLabels[i] = lbl(slot,{Size=UDim2.new(1,0,1,0),Text="[vazio]",TextColor3=C.TextDim,Font=Enum.Font.Gotham})
end

-- Pet inventory scroll
local petScroll = scroll(petPanel,{Size=UDim2.new(1,-16,1,-200),Position=UDim2.new(0,8,0,192)})
corner(petScroll,0.05); gridLayout(petScroll,UDim2.new(0,150,0,90)); pad(petScroll)

local currentPets = {}; local currentEquipped = {}

local function refreshPetsUI()
    for _, c in ipairs(petScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end

    for i = 1, 3 do
        local name = currentEquipped[i]
        if name then
            local petData = PetConfig.getPetByName(name)
            slotLabels[i].Text = petData and (petData.Emoji.." "..name) or name
            slotLabels[i].TextColor3 = petData and (RC[petData.Rarity] or C.Text) or C.Text
        else
            slotLabels[i].Text = "[vazio]"; slotLabels[i].TextColor3 = C.TextDim
        end
    end

    local equippedSet = {}
    for _, n in ipairs(currentEquipped) do equippedSet[n] = true end

    for _, petName in ipairs(currentPets) do
        local petData = PetConfig.getPetByName(petName)
        if not petData then continue end
        local card = frm(petScroll,{Size=UDim2.new(0,150,0,90),BackgroundColor3=Color3.fromRGB(20,20,48)})
        corner(card,0.12); stroke(card,RC[petData.Rarity] or C.Text,2)
        lbl(card,{Size=UDim2.new(1,-4,0.38,0),Position=UDim2.new(0,2,0,2),
            Text=petData.Emoji.." "..petName,Font=Enum.Font.Gotham,TextColor3=RC[petData.Rarity] or C.Text})
        lbl(card,{Size=UDim2.new(1,-4,0.25,0),Position=UDim2.new(0,2,0.38,0),
            Text="x"..petData.AuraMultiplier.." Aura",TextColor3=C.Gold,Font=Enum.Font.Gotham})
        lbl(card,{Size=UDim2.new(1,-4,0.22,0),Position=UDim2.new(0,2,0.62,0),
            Text="Sorte "..math.floor(petData.LuckBonus*100).."%",TextColor3=C.Success,Font=Enum.Font.Gotham})

        local equipped = equippedSet[petName]
        local eb = btn(card,{Size=UDim2.new(1,-6,0.25,0),Position=UDim2.new(0,3,0.75,0),
            Text=equipped and "Desequipar" or "Equipar",
            BackgroundColor3=equipped and C.Error or Color3.fromRGB(0,120,200)})
        if equipped then
            eb.MouseButton1Click:Connect(function()
                game.ReplicatedStorage.RemoteEvents.UnequipPet:FireServer(petName)
            end)
        else
            eb.MouseButton1Click:Connect(function()
                game.ReplicatedStorage.RemoteEvents.EquipPet:FireServer(petName)
            end)
        end
    end
end

petsBtn.MouseButton1Click:Connect(function() petSG.Enabled = not petSG.Enabled; if petSG.Enabled then refreshPetsUI() end end)
petSG:GetPropertyChangedSignal("Enabled"):Connect(function() if petSG.Enabled then refreshPetsUI() end end)

-- ── Rebirth Panel ─────────────────────────────────────────────────────────────

local rebSG = newSG("Rebirth_GUI",3); rebSG.Enabled = false
local rebPanel = frm(rebSG,{Size=UDim2.new(0.5,0,0.6,0),Position=UDim2.new(0.25,0,0.2,0),
    BackgroundColor3=C.Background}); corner(rebPanel,0.04); stroke(rebPanel,C.Error)
panelTitle(rebPanel,"♻️ Rebirth",C.Error); closeBtn(rebPanel,rebSG)

local rebInfo = lbl(rebPanel,{Size=UDim2.new(1,-16,0.55,0),Position=UDim2.new(0,8,0,60),
    Text="Carregando...",TextColor3=C.Text,Font=Enum.Font.Gotham})
local rebBtn = btn(rebPanel,{Size=UDim2.new(0.7,0,0.16,0),Position=UDim2.new(0.15,0,0.75,0),
    Text="♻️ RENASCER",BackgroundColor3=C.Error},
    function() game.ReplicatedStorage.RemoteEvents.RequestRebirth:FireServer() end)
stroke(rebBtn,C.Error,3)

local rebirthData = { count=0, cost=100000, aura=0, mult=1 }

local function refreshRebirthUI()
    local nextMult = string.format("%.1f", 1 + 0.5*(rebirthData.count+1))
    rebInfo.Text =
        "Renascimento atual: #"..rebirthData.count.."\n"..
        "Multiplicador atual de Aura: x"..string.format("%.1f",rebirthData.mult).."\n"..
        "Proximo multiplicador: x"..nextMult.."\n\n"..
        "Aura necessaria: "..rebirthData.cost.."\n"..
        "Sua Aura atual: "..rebirthData.aura.."\n\n"..
        "⚠️ Resetara: Aura, Inventario e Areas\n✅ Mantera: Pets, Cla, Rebirths"
    rebBtn.BackgroundColor3 = (rebirthData.aura >= rebirthData.cost) and C.Error or Color3.fromRGB(80,20,20)
end

rebirthBtn.MouseButton1Click:Connect(function() rebSG.Enabled = not rebSG.Enabled; if rebSG.Enabled then refreshRebirthUI() end end)
rebSG:GetPropertyChangedSignal("Enabled"):Connect(function() if rebSG.Enabled then refreshRebirthUI() end end)

-- ── Events Panel ──────────────────────────────────────────────────────────────

local evtSG = newSG("Event_GUI",3); evtSG.Enabled = false
local evtPanel = frm(evtSG,{Size=UDim2.new(0.5,0,0.55,0),Position=UDim2.new(0.25,0,0.22,0),
    BackgroundColor3=C.Background}); corner(evtPanel,0.04); stroke(evtPanel,C.Gold)
panelTitle(evtPanel,"🎪 Evento Ativo",C.Gold); closeBtn(evtPanel,evtSG)
local evtBody = lbl(evtPanel,{Size=UDim2.new(1,-16,0.8,0),Position=UDim2.new(0,8,0,60),
    Text="Nenhum evento ativo no momento.\nFique ligado!",TextColor3=C.Text,Font=Enum.Font.Gotham})

local currentEventData = nil

local function refreshEventUI()
    if not currentEventData then
        evtBody.Text = "Nenhum evento ativo no momento.\nFique ligado! 👀"
        evtBody.TextColor3 = C.TextDim
    else
        local e = currentEventData
        local remaining = math.max(0, math.floor((e.endsAt or 0) - os.clock()))
        local mins = math.floor(remaining/60)
        local secs = remaining%60
        evtBody.Text =
            e.Emoji.." "..e.Name.."\n\n"..
            e.Description.."\n\n"..
            "• Aura: x"..e.AuraMultiplier.."    • Sorte: x"..e.LuckMultiplier.."    • Spawn: x"..e.SpawnMultiplier.."\n\n"..
            "⏱️ Termina em: "..mins.."m "..secs.."s"
        evtBody.TextColor3 = C.Gold
    end
end

-- Event badge in HUD row 2
local function updateEventBadge(e)
    if e then
        eventBadge.Text = "🎪 "..e.Name
        eventBadge.TextColor3 = e.Color or C.Gold
    else
        eventBadge.Text = ""
    end
end

-- ── Trade Panel ───────────────────────────────────────────────────────────────

local tradeSG = newSG("Trade_GUI",3); tradeSG.Enabled = false
local tradePanel = frm(tradeSG,{Size=UDim2.new(0.88,0,0.88,0),Position=UDim2.new(0.06,0,0.06,0),
    BackgroundColor3=C.Background}); corner(tradePanel,0.04); stroke(tradePanel,Color3.fromRGB(40,180,80))
panelTitle(tradePanel,"🔄 Troca entre Jogadores",Color3.fromRGB(80,220,120)); closeBtn(tradePanel,tradeSG)

-- Search bar
local srchBar = frm(tradePanel,{Size=UDim2.new(1,-16,0,48),Position=UDim2.new(0,8,0,58),BackgroundColor3=C.Panel})
corner(srchBar,0.12)
local srchBox = Instance.new("TextBox"); srchBox.Size=UDim2.new(0.65,0,0.8,0); srchBox.Position=UDim2.new(0,6,0.1,0)
srchBox.PlaceholderText="Digite o nome do jogador..."; srchBox.Font=Enum.Font.Gotham
srchBox.TextScaled=true; srchBox.BackgroundColor3=Color3.fromRGB(30,30,55)
srchBox.TextColor3=C.Text; srchBox.ClearTextOnFocus=false; srchBox.Parent=srchBar; corner(srchBox,0.1)
btn(srchBar,{Size=UDim2.new(0.3,0,0.8,0),Position=UDim2.new(0.69,0,0.1,0),Text="Solicitar Troca",
    BackgroundColor3=Color3.fromRGB(40,180,80)},
    function() game.ReplicatedStorage.RemoteEvents.SendTradeRequest:FireServer(srchBox.Text) end)

-- Trade state display
local tradeStatus = lbl(tradePanel,{Size=UDim2.new(1,-16,0.12,0),Position=UDim2.new(0,8,0,114),
    Text="Sem troca ativa. Solicite uma troca acima.",TextColor3=C.TextDim,Font=Enum.Font.Gotham})

-- Your offer area (left)
local myOfferFrame = frm(tradePanel,{Size=UDim2.new(0.48,0,0.6,0),Position=UDim2.new(0,8,0.22,0),
    BackgroundColor3=Color3.fromRGB(18,30,18)}); corner(myOfferFrame); stroke(myOfferFrame,Color3.fromRGB(40,180,80))
lbl(myOfferFrame,{Size=UDim2.new(1,0,0.1,0),Text="Sua Oferta",TextColor3=Color3.fromRGB(80,220,120)})
local myOfferScroll = scroll(myOfferFrame,{Size=UDim2.new(1,-8,0.88,0),Position=UDim2.new(0,4,0.12,0)})
corner(myOfferScroll); gridLayout(myOfferScroll,UDim2.new(0,140,0,80)); pad(myOfferScroll,4)

-- Their offer area (right)
local theirOfferFrame = frm(tradePanel,{Size=UDim2.new(0.48,0,0.6,0),Position=UDim2.new(0.52,0,0.22,0),
    BackgroundColor3=Color3.fromRGB(30,18,18)}); corner(theirOfferFrame); stroke(theirOfferFrame,Color3.fromRGB(180,80,80))
lbl(theirOfferFrame,{Size=UDim2.new(1,0,0.1,0),Text="Oferta Deles",TextColor3=Color3.fromRGB(255,120,120)})
local theirOfferLbl = lbl(theirOfferFrame,{Size=UDim2.new(1,-8,0.88,0),Position=UDim2.new(0,4,0.12,0),
    Text="Aguardando...",TextColor3=C.TextDim,Font=Enum.Font.Gotham})

-- Trade action buttons
local confirmTradeBtn = btn(tradePanel,{Size=UDim2.new(0.22,0,0.07,0),Position=UDim2.new(0.56,0,0.85,0),
    Text="✅ Confirmar",BackgroundColor3=Color3.fromRGB(40,160,60)},
    function() end)
local cancelTradeBtn = btn(tradePanel,{Size=UDim2.new(0.22,0,0.07,0),Position=UDim2.new(0.78,0,0.85,0),
    Text="❌ Cancelar",BackgroundColor3=C.Error},
    function() end)

local activeTrade = nil

local function refreshTradeUI()
    if not activeTrade then
        tradeStatus.Text = "Sem troca ativa. Solicite uma troca acima."
        for _, c in ipairs(myOfferScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
        theirOfferLbl.Text = "Aguardando..."
        confirmTradeBtn.Visible = false; cancelTradeBtn.Visible = false
        return
    end

    tradeStatus.Text = "Troca ativa com: "..( activeTrade.partnerName or "?")
        ..(activeTrade.lockedSelf and "  |  ✅ Você confirmou" or "  |  ⌛ Aguardando sua confirmação")
    confirmTradeBtn.Visible = true; cancelTradeBtn.Visible = true

    -- Show my offer items
    for _, c in ipairs(myOfferScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    for _, idx in ipairs(activeTrade.myOffer or {}) do
        local item = currentInventory[idx]
        if item then
            local card = frm(myOfferScroll,{Size=UDim2.new(0,140,0,80),BackgroundColor3=Color3.fromRGB(22,40,22)})
            corner(card,0.1); stroke(card,RC[item.Rarity] or C.Text,1)
            lbl(card,{Size=UDim2.new(1,-4,0.5,0),Position=UDim2.new(0,2,0,2),Text=(item.Emoji or"")..item.Name,Font=Enum.Font.Gotham,TextColor3=RC[item.Rarity] or C.Text})
            lbl(card,{Size=UDim2.new(1,-4,0.3,0),Position=UDim2.new(0,2,0.5,0),Text=item.AuraValue.." Aura",TextColor3=C.Gold,Font=Enum.Font.Gotham})
            btn(card,{Size=UDim2.new(1,-4,0.22,0),Position=UDim2.new(0,2,0.78,0),Text="Remover",BackgroundColor3=C.Error},
                function()
                    game.ReplicatedStorage.RemoteEvents.UpdateTradeOffer:FireServer(activeTrade.id,"remove",idx)
                end)
        end
    end

    -- Their offer
    if activeTrade.theirItems and #activeTrade.theirItems > 0 then
        local names = {}
        for _, it in ipairs(activeTrade.theirItems) do names[#names+1] = (it.Emoji or"")..it.Name end
        theirOfferLbl.Text = table.concat(names,"\n")
    else
        theirOfferLbl.Text = "(nenhum item adicionado)"
    end
end

-- Inventory items in trade context: click to add to offer
local function buildTradeInventory()
    for _, c in ipairs(myOfferScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    for idx, item in ipairs(currentInventory) do
        local card = frm(myOfferScroll,{Size=UDim2.new(0,140,0,80),BackgroundColor3=Color3.fromRGB(22,22,40)})
        corner(card,0.1); stroke(card,RC[item.Rarity] or C.Text,1)
        lbl(card,{Size=UDim2.new(1,-4,0.5,0),Position=UDim2.new(0,2,0,2),Text=(item.Emoji or"")..item.Name,Font=Enum.Font.Gotham,TextColor3=RC[item.Rarity] or C.Text})
        lbl(card,{Size=UDim2.new(1,-4,0.3,0),Position=UDim2.new(0,2,0.5,0),Text=item.AuraValue.." Aura",TextColor3=C.Gold,Font=Enum.Font.Gotham})
        btn(card,{Size=UDim2.new(1,-4,0.22,0),Position=UDim2.new(0,2,0.78,0),Text="Oferecer",BackgroundColor3=Color3.fromRGB(40,160,60)},
            function()
                if activeTrade then
                    game.ReplicatedStorage.RemoteEvents.UpdateTradeOffer:FireServer(activeTrade.id,"add",idx)
                end
            end)
    end
end

confirmTradeBtn.MouseButton1Click:Connect(function()
    if activeTrade then game.ReplicatedStorage.RemoteEvents.ConfirmTrade:FireServer(activeTrade.id) end
end)
cancelTradeBtn.MouseButton1Click:Connect(function()
    if activeTrade then game.ReplicatedStorage.RemoteEvents.CancelTrade:FireServer(activeTrade.id) end
end)

tradeBtn.MouseButton1Click:Connect(function()
    tradeSG.Enabled = not tradeSG.Enabled
    if tradeSG.Enabled then refreshTradeUI() end
end)

-- ── Clan Panel ────────────────────────────────────────────────────────────────

local clanSG = newSG("Clan_GUI",3); clanSG.Enabled = false
local clanPanel = frm(clanSG,{Size=UDim2.new(0.8,0,0.85,0),Position=UDim2.new(0.1,0,0.075,0),
    BackgroundColor3=C.Background}); corner(clanPanel,0.04); stroke(clanPanel,Color3.fromRGB(120,80,255))
panelTitle(clanPanel,"🏛️ Clãs",Color3.fromRGB(160,120,255)); closeBtn(clanPanel,clanSG)

-- Left: current clan info
local clanInfoFrame = frm(clanPanel,{Size=UDim2.new(0.48,0,0.85,0),Position=UDim2.new(0,8,0,58),
    BackgroundColor3=Color3.fromRGB(18,15,32)}); corner(clanInfoFrame); stroke(clanInfoFrame,Color3.fromRGB(120,80,255))
local clanInfoLbl = lbl(clanInfoFrame,{Size=UDim2.new(1,-12,0.5,0),Position=UDim2.new(0,6,0,6),
    Text="Você não está em nenhum clã.",TextColor3=C.TextDim,Font=Enum.Font.Gotham})
local clanMembersLbl = lbl(clanInfoFrame,{Size=UDim2.new(1,-12,0.45,0),Position=UDim2.new(0,6,0.5,0),
    Text="",TextColor3=C.Text,Font=Enum.Font.Gotham})

local clanCreateBox = Instance.new("TextBox"); clanCreateBox.Size=UDim2.new(0.55,0,0.08,0)
clanCreateBox.Position=UDim2.new(0,8,0.88,0); clanCreateBox.PlaceholderText="Nome do clã (3-20 chars)"
clanCreateBox.Font=Enum.Font.Gotham; clanCreateBox.TextScaled=true
clanCreateBox.BackgroundColor3=Color3.fromRGB(30,25,55); clanCreateBox.TextColor3=C.Text
clanCreateBox.ClearTextOnFocus=false; clanCreateBox.Parent=clanPanel; corner(clanCreateBox,0.1)

btn(clanPanel,{Size=UDim2.new(0.18,0,0.07,0),Position=UDim2.new(0.57,0,0.88,0),Text="Criar (10k)",
    BackgroundColor3=Color3.fromRGB(80,40,180)},
    function() game.ReplicatedStorage.RemoteEvents.CreateClan:FireServer(clanCreateBox.Text,"") end)

btn(clanPanel,{Size=UDim2.new(0.2,0,0.07,0),Position=UDim2.new(0.76,0,0.88,0),Text="Entrar",
    BackgroundColor3=Color3.fromRGB(40,130,60)},
    function() game.ReplicatedStorage.RemoteEvents.JoinClan:FireServer(clanCreateBox.Text) end)

btn(clanPanel,{Size=UDim2.new(0.2,0,0.07,0),Position=UDim2.new(0.79,0,0.79,0),Text="Sair do Clã",
    BackgroundColor3=C.Error},
    function() game.ReplicatedStorage.RemoteEvents.LeaveClan:FireServer() end)

-- Right: clan ranking
local clanRankFrame = frm(clanPanel,{Size=UDim2.new(0.48,0,0.85,0),Position=UDim2.new(0.52,0,0,58),
    BackgroundColor3=Color3.fromRGB(15,12,28)}); clanRankFrame.Position=UDim2.new(0.52,0,0,58)
corner(clanRankFrame); stroke(clanRankFrame,Color3.fromRGB(100,60,200))
lbl(clanRankFrame,{Size=UDim2.new(1,0,0.1,0),Text="🏆 Top Clãs",TextColor3=Color3.fromRGB(160,120,255)})
local clanRankScroll = scroll(clanRankFrame,{Size=UDim2.new(1,-8,0.88,0),Position=UDim2.new(0,4,0.12,0)})
corner(clanRankScroll,0.05); listLayout(clanRankScroll); pad(clanRankScroll,3)

local currentClanData = nil

local function refreshClanInfo()
    if not currentClanData then
        clanInfoLbl.Text = "Você não está em nenhum clã.\nCrie ou entre em um!"
        clanMembersLbl.Text = ""
    else
        local d = currentClanData
        clanInfoLbl.Text = "🏛️ "..d.Name.."\n👑 Líder: "..d.Leader
            .."\n💰 Aura total: "..(d.TotalAura or 0).." ⭐"
            .."\n📝 "..(d.Description or "")
        local mems = d.Members or {}
        clanMembersLbl.Text = "👥 Membros ("..#mems.."): "..table.concat(mems,", ")
    end
end

local function refreshClanRanking(rows)
    for _, c in ipairs(clanRankScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    local shown = math.min(#rows, 10)
    for i = 1, shown do
        local r = rows[i]
        local row = frm(clanRankScroll,{Size=UDim2.new(1,-6,0,44),LayoutOrder=i,
            BackgroundColor3=(i%2==0)and Color3.fromRGB(18,14,35) or Color3.fromRGB(24,18,45)})
        corner(row,0.1)
        lbl(row,{Size=UDim2.new(0.1,0,1,0),Text=(MEDALS[i] or"#"..i)})
        lbl(row,{Size=UDim2.new(0.45,0,1,0),Position=UDim2.new(0.1,0,0,0),Text=r.Name,TextXAlignment=Enum.TextXAlignment.Left,Font=Enum.Font.Gotham})
        lbl(row,{Size=UDim2.new(0.28,0,1,0),Position=UDim2.new(0.55,0,0,0),Text=tostring(r.TotalAura).."⭐",TextColor3=C.Gold,Font=Enum.Font.Gotham})
        lbl(row,{Size=UDim2.new(0.17,0,1,0),Position=UDim2.new(0.83,0,0,0),Text=tostring(r.Members).."👥",TextColor3=C.TextDim,Font=Enum.Font.Gotham})
    end
end

clanBtn.MouseButton1Click:Connect(function() clanSG.Enabled = not clanSG.Enabled; if clanSG.Enabled then refreshClanInfo() end end)

-- ── Public API ────────────────────────────────────────────────────────────────

function GUIManager.updateHUD(aura, count, area)
    auraLabel.Text  = "⭐ "..tostring(aura).." Aura"
    countLabel.Text = "🧠 "..tostring(count)
    areaLabel.Text  = "📍 "..( area or "?")
end

function GUIManager.showCapturePopup(entry) showCapturePopup(entry) end
function GUIManager.pushNotification(data)  pushNotif(data) end

function GUIManager.updateInventory(inventory, unlockedAreas)
    currentInventory     = inventory or {}
    currentUnlockedAreas = unlockedAreas or {}
    if invSG.Enabled  then refreshInventoryUI() end
    if areaSG.Enabled then buildAreaCards(unlockedAreas) end
    if tradeSG.Enabled and activeTrade then buildTradeInventory() end
end

function GUIManager.updateRanking(ranking)
    if rankSG.Enabled then refreshRanking(ranking) end
end

function GUIManager.updatePets(pets, equipped)
    currentPets     = pets or {}
    currentEquipped = equipped or {}
    if petSG.Enabled then refreshPetsUI() end
end

function GUIManager.updateRebirth(count, cost, aura, mult)
    rebirthData = { count=count, cost=cost, aura=aura, mult=mult }
    if rebSG.Enabled then refreshRebirthUI() end
end

function GUIManager.updateEvent(eventData)
    currentEventData = eventData
    updateEventBadge(eventData)
    if evtSG.Enabled then refreshEventUI() end
end

function GUIManager.showTradeRequest(data)
    pushNotif({ type=GameConfig.NotifType.Info,
        message="🔄 "..data.from.." quer trocar com você!" })
    tradeSG.Enabled = true
    activeTrade = { id=data.tradeId, partnerName=data.from, myOffer={}, theirItems={} }
    refreshTradeUI()
end

function GUIManager.updateTradeState(trade)
    if not trade then
        activeTrade = nil
    else
        activeTrade = activeTrade or {}
        activeTrade.id         = trade.id
        activeTrade.myOffer    = trade.offerA or trade.offerB or {}
        activeTrade.theirItems = {}
        activeTrade.lockedSelf = trade.lockedA or trade.lockedB
    end
    if tradeSG.Enabled then refreshTradeUI() end
end

function GUIManager.tradeResult(success, msg)
    activeTrade = nil
    pushNotif({ type=success and GameConfig.NotifType.Success or GameConfig.NotifType.Error, message=msg })
    if tradeSG.Enabled then refreshTradeUI() end
end

function GUIManager.updateClan(clanData)
    currentClanData = clanData
    if clanSG.Enabled then refreshClanInfo() end
end

function GUIManager.updateClanRanking(rows)
    if clanSG.Enabled then refreshClanRanking(rows) end
end

-- Attach event panel toggle to a placeholder button (client wires it below via evtSG)
GUIManager.openEventPanel = function()
    evtSG.Enabled = not evtSG.Enabled
    if evtSG.Enabled then refreshEventUI() end
end

eventBadge.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
        GUIManager.openEventPanel()
    end
end)

return GUIManager
