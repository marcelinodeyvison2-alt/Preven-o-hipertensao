-- ScriptExecutor.client.lua  (LocalScript em StarterPlayerScripts)
-- UI estilo Solara / Xeno / Potassium
-- Toggle: Insert   |   Executar: Execute ou F6

local Players          = game:GetService("Players")
local UIS              = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local HttpService      = game:GetService("HttpService")

local lp    = Players.LocalPlayer
local pgui  = lp:WaitForChild("PlayerGui")

-- ─────────────────────────────────────────────────────────────
-- TEMA  (inspirado em Solara / Xeno)
-- ─────────────────────────────────────────────────────────────
local T = {
    bg          = Color3.fromRGB(15,  15,  20 ),
    sidebar     = Color3.fromRGB(20,  20,  28 ),
    panel       = Color3.fromRGB(22,  22,  30 ),
    panelHov    = Color3.fromRGB(30,  30,  42 ),
    editor      = Color3.fromRGB(12,  12,  17 ),
    console     = Color3.fromRGB(10,  10,  15 ),
    border      = Color3.fromRGB(45,  45,  65 ),
    accent      = Color3.fromRGB(90,  60, 210 ),
    accentLight = Color3.fromRGB(120,  90, 240 ),
    accentDim   = Color3.fromRGB(60,  40, 150 ),
    green       = Color3.fromRGB(65,  210,  100),
    red         = Color3.fromRGB(210,  60,   60),
    yellow      = Color3.fromRGB(210, 185,   55),
    blue        = Color3.fromRGB(80,  150,  255),
    text        = Color3.fromRGB(215, 215, 235 ),
    textDim     = Color3.fromRGB(110, 110, 140 ),
    textCode    = Color3.fromRGB(185, 215, 255 ),
    lineNum     = Color3.fromRGB( 70,  70, 100 ),
    tabActive   = Color3.fromRGB( 90,  60, 210 ),
    tabIdle     = Color3.fromRGB( 22,  22,  30 ),
    btnExec     = Color3.fromRGB( 90,  60, 210 ),
    btnClear    = Color3.fromRGB( 35,  35,  50 ),
    btnDanger   = Color3.fromRGB(160,  35,  35 ),
}

-- ─────────────────────────────────────────────────────────────
-- UTILIDADES
-- ─────────────────────────────────────────────────────────────
local function uicorner(r, p)
    local c = Instance.new("UICorner", p)
    c.CornerRadius = UDim.new(0, r)
    return c
end
local function uistroke(col, th, p)
    local s = Instance.new("UIStroke", p)
    s.Color = col; s.Thickness = th
    return s
end
local function uipad(l, r, t, b, p)
    local o = Instance.new("UIPadding", p)
    o.PaddingLeft   = UDim.new(0, l)
    o.PaddingRight  = UDim.new(0, r)
    o.PaddingTop    = UDim.new(0, t)
    o.PaddingBottom = UDim.new(0, b)
end
local function newFrame(props, parent)
    local f = Instance.new("Frame")
    f.BorderSizePixel = 0
    for k,v in pairs(props) do f[k] = v end
    f.Parent = parent
    return f
end
local function newLabel(props, parent)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.BorderSizePixel = 0
    for k,v in pairs(props) do l[k] = v end
    l.Parent = parent
    return l
end
local function newBtn(props, parent)
    local b = Instance.new("TextButton")
    b.BorderSizePixel = 0
    b.AutoButtonColor = false
    for k,v in pairs(props) do b[k] = v end
    b.Parent = parent
    return b
end
local function tween(obj, props, t)
    TweenService:Create(obj, TweenInfo.new(t or 0.13, Enum.EasingStyle.Quad), props):Play()
end
local function onHover(btn, n, h)
    btn.MouseEnter:Connect(function() tween(btn, {BackgroundColor3 = h}) end)
    btn.MouseLeave:Connect(function() tween(btn, {BackgroundColor3 = n}) end)
end

-- ─────────────────────────────────────────────────────────────
-- RAIZ
-- ─────────────────────────────────────────────────────────────
local gui = Instance.new("ScreenGui")
gui.Name          = "ScriptExecutor"
gui.ResetOnSpawn  = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder  = 9999
gui.Parent        = pgui

-- Janela principal
local win = newFrame({
    Name             = "Win",
    Size             = UDim2.new(0, 760, 0, 510),
    Position         = UDim2.new(0.5, -380, 0.5, -255),
    BackgroundColor3 = T.bg,
    Visible          = false,
    ClipsDescendants = true,
}, gui)
uicorner(10, win)
uistroke(T.border, 1, win)

-- ─────────────────────────────────────────────────────────────
-- SIDEBAR  (esquerda — navegação estilo Solara)
-- ─────────────────────────────────────────────────────────────
local sidebar = newFrame({
    Size             = UDim2.new(0, 52, 1, 0),
    BackgroundColor3 = T.sidebar,
}, win)
uicorner(10, sidebar)

local sideList = Instance.new("UIListLayout", sidebar)
sideList.FillDirection     = Enum.FillDirection.Vertical
sideList.HorizontalAlignment = Enum.HorizontalAlignment.Center
sideList.Padding           = UDim.new(0, 4)
uipad(0, 0, 10, 10, sidebar)

local PAGES = {
    { icon = "✏", label = "Editor",    id = "editor"  },
    { icon = "📜", label = "Scripts",   id = "scripts" },
    { icon = "⚙",  label = "Settings",  id = "settings"},
}

local sideButtons = {}
local currentPage = "editor"

local function makeSideBtn(icon, id)
    local btn = newBtn({
        Size             = UDim2.new(0, 38, 0, 38),
        BackgroundColor3 = (id == currentPage) and T.accentDim or T.sidebar,
        Text             = icon,
        TextSize         = 18,
        Font             = Enum.Font.GothamBold,
        TextColor3       = (id == currentPage) and T.text or T.textDim,
    }, sidebar)
    uicorner(8, btn)
    return btn
end

for _, p in ipairs(PAGES) do
    local b = makeSideBtn(p.icon, p.id)
    sideButtons[p.id] = b
    onHover(b, (p.id == currentPage) and T.accentDim or T.sidebar, T.panelHov)
end

-- ─────────────────────────────────────────────────────────────
-- ÁREA PRINCIPAL  (direita da sidebar)
-- ─────────────────────────────────────────────────────────────
local main = newFrame({
    Size             = UDim2.new(1, -52, 1, 0),
    Position         = UDim2.new(0, 52, 0, 0),
    BackgroundColor3 = T.bg,
}, win)

-- ── Barra de título ──────────────────────────────────────────
local titleBar = newFrame({
    Size             = UDim2.new(1, 0, 0, 38),
    BackgroundColor3 = T.panel,
}, main)
uicorner(10, titleBar)

newLabel({
    Size             = UDim2.new(0, 26, 0, 26),
    Position         = UDim2.new(0, 10, 0.5, -13),
    Text             = "⚡",
    TextSize         = 16,
    TextColor3       = T.accent,
    Font             = Enum.Font.GothamBold,
}, titleBar)

newLabel({
    Size             = UDim2.new(0, 160, 1, 0),
    Position         = UDim2.new(0, 36, 0, 0),
    Text             = "Script Executor",
    TextSize         = 14,
    Font             = Enum.Font.GothamBold,
    TextColor3       = T.text,
    TextXAlignment   = Enum.TextXAlignment.Left,
}, titleBar)

newLabel({
    Size             = UDim2.new(0, 160, 1, 0),
    Position         = UDim2.new(0, 175, 0, 0),
    Text             = "v2.0",
    TextSize         = 11,
    Font             = Enum.Font.Gotham,
    TextColor3       = T.textDim,
    TextXAlignment   = Enum.TextXAlignment.Left,
}, titleBar)

-- Botão minimizar
local minBtn = newBtn({
    Size             = UDim2.new(0, 26, 0, 26),
    Position         = UDim2.new(1, -60, 0.5, -13),
    BackgroundColor3 = T.panel,
    Text             = "─",
    TextSize         = 13,
    Font             = Enum.Font.GothamBold,
    TextColor3       = T.textDim,
}, titleBar)
uicorner(6, minBtn)
onHover(minBtn, T.panel, T.panelHov)

-- Botão fechar
local closeBtn = newBtn({
    Size             = UDim2.new(0, 26, 0, 26),
    Position         = UDim2.new(1, -30, 0.5, -13),
    BackgroundColor3 = T.btnDanger,
    Text             = "✕",
    TextSize         = 12,
    Font             = Enum.Font.GothamBold,
    TextColor3       = Color3.new(1,1,1),
}, titleBar)
uicorner(6, closeBtn)
onHover(closeBtn, T.btnDanger, T.red)

-- ─────────────────────────────────────────────────────────────
-- PÁGINA: EDITOR
-- ─────────────────────────────────────────────────────────────
local editorPage = newFrame({
    Size             = UDim2.new(1, 0, 1, -38),
    Position         = UDim2.new(0, 0, 0, 38),
    BackgroundTransparency = 1,
    Visible          = true,
}, main)

-- ── Abas de scripts ──────────────────────────────────────────
local tabStrip = newFrame({
    Size             = UDim2.new(1, 0, 0, 30),
    BackgroundColor3 = T.panel,
}, editorPage)

local tabRowList = Instance.new("UIListLayout", tabStrip)
tabRowList.FillDirection     = Enum.FillDirection.Horizontal
tabRowList.VerticalAlignment = Enum.VerticalAlignment.Center
tabRowList.Padding           = UDim.new(0, 2)
uipad(8, 8, 4, 0, tabStrip)

local NUM_TABS     = 6
local tabBtns      = {}
local tabContents  = {}
local activeTabIdx = 1

local function setActiveTab(idx)
    tabContents[activeTabIdx] = editorInput.Text
    activeTabIdx = idx
    editorInput.Text = tabContents[activeTabIdx] or ""
    for i, b in ipairs(tabBtns) do
        tween(b, {
            BackgroundColor3 = (i == idx) and T.tabActive or T.tabIdle,
            TextColor3       = (i == idx) and Color3.new(1,1,1) or T.textDim,
        })
    end
    updateLineNums()
end

-- (declaração antecipada — funções usam editorInput que vem depois)
local updateLineNums  -- forward declaration

for i = 1, NUM_TABS do
    tabContents[i] = ""
    local b = newBtn({
        Size             = UDim2.new(0, 82, 0, 24),
        BackgroundColor3 = (i == 1) and T.tabActive or T.tabIdle,
        Text             = "Script " .. i,
        TextSize         = 11,
        Font             = Enum.Font.GothamBold,
        TextColor3       = (i == 1) and Color3.new(1,1,1) or T.textDim,
    }, tabStrip)
    uicorner(5, b)
    tabBtns[i] = b
end

-- ── Editor de código ─────────────────────────────────────────
local editorWrap = newFrame({
    Size             = UDim2.new(1, -16, 0, 248),
    Position         = UDim2.new(0, 8, 0, 36),
    BackgroundColor3 = T.editor,
}, editorPage)
uicorner(6, editorWrap)
uistroke(T.border, 1, editorWrap)

-- Coluna de números de linha
local lineNumCol = newFrame({
    Size             = UDim2.new(0, 36, 1, 0),
    BackgroundColor3 = Color3.fromRGB(9, 9, 13),
}, editorWrap)
uicorner(6, lineNumCol)

local lineScroll = Instance.new("ScrollingFrame")
lineScroll.Size                 = UDim2.new(1, 0, 1, 0)
lineScroll.BackgroundTransparency = 1
lineScroll.BorderSizePixel      = 0
lineScroll.ScrollBarThickness   = 0
lineScroll.ScrollingEnabled     = false
lineScroll.CanvasSize           = UDim2.new(0, 0, 0, 0)
lineScroll.AutomaticCanvasSize  = Enum.AutomaticSize.Y
lineScroll.Parent               = lineNumCol
local lineLayout = Instance.new("UIListLayout", lineScroll)
uipad(0, 0, 7, 7, lineScroll)

-- Scroll do editor
local editorScroll = Instance.new("ScrollingFrame")
editorScroll.Size                = UDim2.new(1, -40, 1, 0)
editorScroll.Position            = UDim2.new(0, 40, 0, 0)
editorScroll.BackgroundTransparency = 1
editorScroll.BorderSizePixel     = 0
editorScroll.ScrollBarThickness  = 5
editorScroll.ScrollBarImageColor3 = T.border
editorScroll.CanvasSize          = UDim2.new(0, 0, 0, 0)
editorScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
editorScroll.Parent              = editorWrap

local editorInput = Instance.new("TextBox")
editorInput.Size               = UDim2.new(1, 0, 1, 0)
editorInput.BackgroundTransparency = 1
editorInput.Text               = ""
editorInput.PlaceholderText    = "-- Cole ou escreva seu script aqui...\n\nprint(\"Olá, Executor!\")"
editorInput.TextColor3         = T.textCode
editorInput.PlaceholderColor3  = Color3.fromRGB(60, 60, 85)
editorInput.TextSize           = 13
editorInput.Font               = Enum.Font.Code
editorInput.TextXAlignment     = Enum.TextXAlignment.Left
editorInput.TextYAlignment     = Enum.TextYAlignment.Top
editorInput.MultiLine          = true
editorInput.ClearTextOnFocus   = false
editorInput.Parent             = editorScroll
uipad(8, 8, 7, 7, editorInput)

-- Definição de updateLineNums (agora que editorInput existe)
updateLineNums = function()
    for _, c in ipairs(lineScroll:GetChildren()) do
        if c:IsA("TextLabel") then c:Destroy() end
    end
    local count = 1
    for _ in (editorInput.Text .. "\n"):gmatch("[^\n]*\n") do count = count + 1 end
    count = math.max(count, 14)
    for i = 1, count do
        newLabel({
            Size           = UDim2.new(1, 0, 0, 18),
            Text           = tostring(i),
            TextSize       = 11,
            Font           = Enum.Font.Code,
            TextColor3     = T.lineNum,
            TextXAlignment = Enum.TextXAlignment.Center,
        }, lineScroll)
    end
    local h = count * 18 + 14
    lineScroll.CanvasSize   = UDim2.new(0, 0, 0, h)
    editorScroll.CanvasSize = UDim2.new(0, 0, 0, h)
end

editorInput:GetPropertyChangedSignal("Text"):Connect(updateLineNums)
updateLineNums()

-- Conecta abas agora que editorInput existe
for i, b in ipairs(tabBtns) do
    b.MouseButton1Click:Connect(function() setActiveTab(i) end)
end

-- ── Barra de ações ───────────────────────────────────────────
local actionBar = newFrame({
    Size             = UDim2.new(1, -16, 0, 36),
    Position         = UDim2.new(0, 8, 0, 292),
    BackgroundTransparency = 1,
}, editorPage)

local actionList = Instance.new("UIListLayout", actionBar)
actionList.FillDirection     = Enum.FillDirection.Horizontal
actionList.VerticalAlignment = Enum.VerticalAlignment.Center
actionList.Padding           = UDim.new(0, 8)

local function actionBtn(txt, bg, w)
    local b = newBtn({
        Size             = UDim2.new(0, w or 110, 0, 32),
        BackgroundColor3 = bg,
        Text             = txt,
        TextSize         = 13,
        Font             = Enum.Font.GothamBold,
        TextColor3       = Color3.new(1,1,1),
    }, actionBar)
    uicorner(7, b)
    return b
end

local execBtn    = actionBtn("▶  Execute",      T.btnExec,  118)
local clearBtn   = actionBtn("⬜  Clear",        T.btnClear,  90)
local clearConBtn= actionBtn("⬜  Clear Console",T.btnClear, 138)
local copyBtn    = actionBtn("📋  Copy",         T.btnClear,  90)

onHover(execBtn,     T.btnExec,  T.accentLight)
onHover(clearBtn,    T.btnClear, T.panelHov)
onHover(clearConBtn, T.btnClear, T.panelHov)
onHover(copyBtn,     T.btnClear, T.panelHov)

-- Tecla rápida
local kbLabel = newLabel({
    Size             = UDim2.new(1, -460, 1, 0),
    Text             = "F6  —  Execute",
    TextSize         = 11,
    Font             = Enum.Font.Gotham,
    TextColor3       = T.textDim,
    TextXAlignment   = Enum.TextXAlignment.Right,
}, actionBar)

-- ── Console / Output ─────────────────────────────────────────
local consoleSep = newFrame({
    Size             = UDim2.new(1, -16, 0, 1),
    Position         = UDim2.new(0, 8, 0, 336),
    BackgroundColor3 = T.border,
}, editorPage)

newLabel({
    Size             = UDim2.new(0, 70, 0, 18),
    Position         = UDim2.new(0, 16, 0, 338),
    Text             = "Console",
    TextSize         = 11,
    Font             = Enum.Font.GothamBold,
    TextColor3       = T.textDim,
    TextXAlignment   = Enum.TextXAlignment.Left,
}, editorPage)

local consoleBg = newFrame({
    Size             = UDim2.new(1, -16, 0, 108),
    Position         = UDim2.new(0, 8, 0, 358),
    BackgroundColor3 = T.console,
}, editorPage)
uicorner(6, consoleBg)
uistroke(T.border, 1, consoleBg)

local consScroll = Instance.new("ScrollingFrame")
consScroll.Size                 = UDim2.new(1, 0, 1, 0)
consScroll.BackgroundTransparency = 1
consScroll.BorderSizePixel      = 0
consScroll.ScrollBarThickness   = 4
consScroll.ScrollBarImageColor3 = T.border
consScroll.CanvasSize           = UDim2.new(0, 0, 0, 0)
consScroll.AutomaticCanvasSize  = Enum.AutomaticSize.Y
consScroll.Parent               = consoleBg
local consList = Instance.new("UIListLayout", consScroll)
consList.Padding = UDim.new(0, 1)
uipad(8, 8, 5, 5, consScroll)

-- ─────────────────────────────────────────────────────────────
-- PÁGINA: SCRIPT HUB
-- ─────────────────────────────────────────────────────────────
local scriptsPage = newFrame({
    Size             = UDim2.new(1, 0, 1, -38),
    Position         = UDim2.new(0, 0, 0, 38),
    BackgroundTransparency = 1,
    Visible          = false,
}, main)

newLabel({
    Size             = UDim2.new(1, -20, 0, 28),
    Position         = UDim2.new(0, 10, 0, 8),
    Text             = "Script Hub",
    TextSize         = 16,
    Font             = Enum.Font.GothamBold,
    TextColor3       = T.text,
    TextXAlignment   = Enum.TextXAlignment.Left,
}, scriptsPage)

local hubScroll = Instance.new("ScrollingFrame")
hubScroll.Size                 = UDim2.new(1, -16, 1, -50),
hubScroll.Position             = UDim2.new(0, 8, 0, 44)
hubScroll.BackgroundTransparency = 1
hubScroll.BorderSizePixel      = 0
hubScroll.ScrollBarThickness   = 5
hubScroll.ScrollBarImageColor3 = T.border
hubScroll.CanvasSize           = UDim2.new(0, 0, 0, 0)
hubScroll.AutomaticCanvasSize  = Enum.AutomaticSize.Y
hubScroll.Parent               = scriptsPage
local hubList = Instance.new("UIListLayout", hubScroll)
hubList.Padding = UDim.new(0, 8)
uipad(0, 0, 4, 4, hubScroll)

-- Scripts prontos no hub
local HUB_SCRIPTS = {
    {
        name   = "Infinite Jump",
        desc   = "Ativa salto infinito para o personagem local.",
        tag    = "Util",
        code   = [[
local UIS = game:GetService("UserInputService")
local lp  = game.Players.LocalPlayer
UIS.JumpRequest:Connect(function()
    if lp.Character and lp.Character:FindFirstChild("Humanoid") then
        lp.Character.Humanoid:ChangeState("Jumping")
    end
end)
print("[InfiniteJump] Ativado!")
]],
    },
    {
        name   = "Speed Hack",
        desc   = "Aumenta WalkSpeed do personagem para 100.",
        tag    = "Movimento",
        code   = [[
local lp  = game.Players.LocalPlayer
local chr = lp.Character or lp.CharacterAdded:Wait()
local hum = chr:WaitForChild("Humanoid")
hum.WalkSpeed = 100
print("[SpeedHack] WalkSpeed = 100")
]],
    },
    {
        name   = "Print Players",
        desc   = "Exibe no console todos os jogadores online.",
        tag    = "Info",
        code   = [[
for _, p in ipairs(game.Players:GetPlayers()) do
    print(string.format("[%d] %s", p.UserId, p.Name))
end
]],
    },
    {
        name   = "Noclip",
        desc   = "Ativa noclip (atravessar paredes) com loop no RunService.",
        tag    = "Movimento",
        code   = [[
local lp  = game.Players.LocalPlayer
local RS  = game:GetService("RunService")
local on  = true
RS.Stepped:Connect(function()
    if not on then return end
    if lp.Character then
        for _, p in ipairs(lp.Character:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end
end)
print("[Noclip] Ativado!")
]],
    },
    {
        name   = "Highlight All Parts",
        desc   = "Adiciona Highlight em todas as partes do workspace.",
        tag    = "Visual",
        code   = [[
for _, v in ipairs(workspace:GetDescendants()) do
    if v:IsA("BasePart") and not v:FindFirstChildOfClass("SelectionBox") then
        local s = Instance.new("SelectionBox")
        s.Adornee = v
        s.Color3  = Color3.fromRGB(255,50,50)
        s.LineThickness = 0.04
        s.Parent = workspace
    end
end
print("[Highlight] Feito!")
]],
    },
    {
        name   = "Remove Fog",
        desc   = "Remove neblina do ambiente.",
        tag    = "Visual",
        code   = [[
game:GetService("Lighting").FogEnd   = 100000
game:GetService("Lighting").FogStart = 100000
print("[RemoveFog] Neblina removida!")
]],
    },
}

local TAG_COLORS = {
    Util      = Color3.fromRGB(60, 180, 100),
    Movimento = Color3.fromRGB(80, 140, 220),
    Info      = Color3.fromRGB(180, 140, 50),
    Visual    = Color3.fromRGB(150, 80, 220),
}

for _, sc in ipairs(HUB_SCRIPTS) do
    local card = newFrame({
        Size             = UDim2.new(1, 0, 0, 70),
        BackgroundColor3 = T.panel,
    }, hubScroll)
    uicorner(8, card)
    uistroke(T.border, 1, card)

    -- Tag de categoria
    local tagBg = newFrame({
        Size             = UDim2.new(0, 80, 0, 18),
        Position         = UDim2.new(1, -88, 0, 8),
        BackgroundColor3 = TAG_COLORS[sc.tag] or T.accent,
    }, card)
    uicorner(4, tagBg)
    newLabel({
        Size        = UDim2.new(1, 0, 1, 0),
        Text        = sc.tag,
        TextSize    = 10,
        Font        = Enum.Font.GothamBold,
        TextColor3  = Color3.new(1,1,1),
    }, tagBg)

    newLabel({
        Size             = UDim2.new(1, -100, 0, 22),
        Position         = UDim2.new(0, 10, 0, 8),
        Text             = sc.name,
        TextSize         = 14,
        Font             = Enum.Font.GothamBold,
        TextColor3       = T.text,
        TextXAlignment   = Enum.TextXAlignment.Left,
    }, card)

    newLabel({
        Size             = UDim2.new(1, -20, 0, 28),
        Position         = UDim2.new(0, 10, 0, 30),
        Text             = sc.desc,
        TextSize         = 11,
        Font             = Enum.Font.Gotham,
        TextColor3       = T.textDim,
        TextXAlignment   = Enum.TextXAlignment.Left,
        TextWrapped      = true,
    }, card)

    -- Botões Execute / Load
    local execHubBtn = newBtn({
        Size             = UDim2.new(0, 80, 0, 22),
        Position         = UDim2.new(1, -88, 1, -28),
        BackgroundColor3 = T.btnExec,
        Text             = "Execute",
        TextSize         = 11,
        Font             = Enum.Font.GothamBold,
        TextColor3       = Color3.new(1,1,1),
    }, card)
    uicorner(5, execHubBtn)
    onHover(execHubBtn, T.btnExec, T.accentLight)

    local loadHubBtn = newBtn({
        Size             = UDim2.new(0, 60, 0, 22),
        Position         = UDim2.new(1, -156, 1, -28),
        BackgroundColor3 = T.btnClear,
        Text             = "Carregar",
        TextSize         = 11,
        Font             = Enum.Font.GothamBold,
        TextColor3       = T.text,
    }, card)
    uicorner(5, loadHubBtn)
    onHover(loadHubBtn, T.btnClear, T.panelHov)

    local scCode = sc.code
    execHubBtn.MouseButton1Click:Connect(function() runScript(scCode) end)
    loadHubBtn.MouseButton1Click:Connect(function()
        editorInput.Text = scCode:match("^%s*(.-)%s*$")
        tabContents[activeTabIdx] = editorInput.Text
        switchToPage("editor")
        updateLineNums()
    end)
end

-- ─────────────────────────────────────────────────────────────
-- PÁGINA: SETTINGS
-- ─────────────────────────────────────────────────────────────
local settingsPage = newFrame({
    Size             = UDim2.new(1, 0, 1, -38),
    Position         = UDim2.new(0, 0, 0, 38),
    BackgroundTransparency = 1,
    Visible          = false,
}, main)

newLabel({
    Size             = UDim2.new(1, -20, 0, 28),
    Position         = UDim2.new(0, 10, 0, 8),
    Text             = "Configurações",
    TextSize         = 16,
    Font             = Enum.Font.GothamBold,
    TextColor3       = T.text,
    TextXAlignment   = Enum.TextXAlignment.Left,
}, settingsPage)

local settingsList = {
    { key = "Toggle",    val = "INSERT" },
    { key = "Execute",   val = "F6" },
    { key = "Versão",    val = "2.0" },
    { key = "Ambiente",  val = RunService:IsStudio() and "Studio" or "Game" },
    { key = "Jogador",   val = lp.Name .. " (#"..lp.UserId..")" },
}

local settingsScroll = Instance.new("ScrollingFrame")
settingsScroll.Size                 = UDim2.new(1, -16, 1, -50)
settingsScroll.Position             = UDim2.new(0, 8, 0, 44)
settingsScroll.BackgroundTransparency = 1
settingsScroll.BorderSizePixel      = 0
settingsScroll.ScrollBarThickness   = 5
settingsScroll.ScrollBarImageColor3 = T.border
settingsScroll.CanvasSize           = UDim2.new(0, 0, 0, 0)
settingsScroll.AutomaticCanvasSize  = Enum.AutomaticSize.Y
settingsScroll.Parent               = settingsPage
local sl = Instance.new("UIListLayout", settingsScroll)
sl.Padding = UDim.new(0, 6)
uipad(0, 0, 4, 4, settingsScroll)

for _, row in ipairs(settingsList) do
    local r = newFrame({
        Size             = UDim2.new(1, 0, 0, 42),
        BackgroundColor3 = T.panel,
    }, settingsScroll)
    uicorner(6, r)
    newLabel({
        Size             = UDim2.new(0.4, 0, 1, 0),
        Position         = UDim2.new(0, 12, 0, 0),
        Text             = row.key,
        TextSize         = 13,
        Font             = Enum.Font.GothamBold,
        TextColor3       = T.textDim,
        TextXAlignment   = Enum.TextXAlignment.Left,
    }, r)
    newLabel({
        Size             = UDim2.new(0.6, -12, 1, 0),
        Position         = UDim2.new(0.4, 0, 0, 0),
        Text             = row.val,
        TextSize         = 13,
        Font             = Enum.Font.GothamBold,
        TextColor3       = T.text,
        TextXAlignment   = Enum.TextXAlignment.Left,
    }, r)
end

-- ─────────────────────────────────────────────────────────────
-- NAVEGAÇÃO ENTRE PÁGINAS
-- ─────────────────────────────────────────────────────────────
local pageFrames = {
    editor   = editorPage,
    scripts  = scriptsPage,
    settings = settingsPage,
}

switchToPage = function(id)
    currentPage = id
    for pid, pf in pairs(pageFrames) do
        pf.Visible = (pid == id)
    end
    for _, p in ipairs(PAGES) do
        local b = sideButtons[p.id]
        tween(b, {
            BackgroundColor3 = (p.id == id) and T.accentDim or T.sidebar,
            TextColor3       = (p.id == id) and T.text or T.textDim,
        })
    end
end

for _, p in ipairs(PAGES) do
    sideButtons[p.id].MouseButton1Click:Connect(function()
        switchToPage(p.id)
    end)
end

-- ─────────────────────────────────────────────────────────────
-- CONSOLE — log helper
-- ─────────────────────────────────────────────────────────────
local consLineCount = 0
local MAX_CONS = 300

local function log(txt, col)
    consLineCount = consLineCount + 1
    if consLineCount > MAX_CONS then
        local old = consScroll:FindFirstChildOfClass("TextLabel")
        if old then old:Destroy() end
    end
    newLabel({
        Size          = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Text          = txt,
        TextSize      = 12,
        Font          = Enum.Font.Code,
        TextColor3    = col or T.green,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped   = true,
    }, consScroll)
    task.defer(function()
        consScroll.CanvasPosition = Vector2.new(0, math.huge)
    end)
end

-- ─────────────────────────────────────────────────────────────
-- EXECUÇÃO DE SCRIPT
-- ─────────────────────────────────────────────────────────────
local running = false

runScript = function(code)
    if not code then
        tabContents[activeTabIdx] = editorInput.Text
        code = editorInput.Text:match("^%s*(.-)%s*$")
    end
    if code == "" then
        log("[!] Nenhum codigo para executar.", T.yellow)
        return
    end
    if running then
        log("[!] Ja existe um script rodando.", T.yellow)
        return
    end

    log(">>> Executando...", T.blue)

    local fn, syntaxErr = loadstring(code)
    if not fn then
        log("[Sintaxe] " .. tostring(syntaxErr), T.red)
        return
    end

    local env = setmetatable({
        print = function(...)
            local parts = {}
            for _,v in ipairs({...}) do parts[#parts+1] = tostring(v) end
            log(table.concat(parts, "  "), T.green)
        end,
        warn = function(...)
            local parts = {}
            for _,v in ipairs({...}) do parts[#parts+1] = tostring(v) end
            log("[warn] "..table.concat(parts,"  "), T.yellow)
        end,
        error = function(msg, lv) error(msg, lv) end,
        game            = game,
        workspace       = workspace,
        script          = script,
        Players         = Players,
        UserInputService= UIS,
        RunService      = RunService,
        TweenService    = TweenService,
        HttpService     = HttpService,
        tostring = tostring, tonumber = tonumber,
        pairs = pairs, ipairs = ipairs, next = next,
        type = type, select = select, unpack = table.unpack or unpack,
        pcall = pcall, xpcall = xpcall,
        math = math, string = string, table = table,
        os = os, tick = tick, task = task, wait = task.wait,
        Instance = Instance, Color3 = Color3,
        Vector3 = Vector3, Vector2 = Vector2,
        CFrame = CFrame, BrickColor = BrickColor,
        UDim2 = UDim2, UDim = UDim, Enum = Enum,
        TweenInfo = TweenInfo, Ray = Ray,
    }, { __index = _G })

    setfenv(fn, env)
    running = true

    task.spawn(function()
        local ok, err = pcall(fn)
        running = false
        if ok then
            log("[OK] Script finalizado.", Color3.fromRGB(100,100,130))
        else
            log("[Erro] "..tostring(err), T.red)
        end
    end)
end

-- ─────────────────────────────────────────────────────────────
-- BOTÕES
-- ─────────────────────────────────────────────────────────────
execBtn.MouseButton1Click:Connect(function() runScript() end)

clearBtn.MouseButton1Click:Connect(function()
    editorInput.Text = ""
    tabContents[activeTabIdx] = ""
    updateLineNums()
end)

clearConBtn.MouseButton1Click:Connect(function()
    for _, c in ipairs(consScroll:GetChildren()) do
        if c:IsA("TextLabel") then c:Destroy() end
    end
    consLineCount = 0
    log("-- Console limpo --", Color3.fromRGB(70,70,90))
end)

copyBtn.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard(editorInput.Text)
        log("[Copiado] Codigo copiado!", T.blue)
    else
        log("[Copy] setclipboard nao disponivel.", T.yellow)
    end
end)

closeBtn.MouseButton1Click:Connect(function() win.Visible = false end)

local minimized = false
minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    editorPage.Visible  = (not minimized) and (currentPage == "editor")
    scriptsPage.Visible = (not minimized) and (currentPage == "scripts")
    settingsPage.Visible= (not minimized) and (currentPage == "settings")
    tween(win, { Size = minimized
        and UDim2.new(0, 760, 0, 42)
        or  UDim2.new(0, 760, 0, 510)
    }, 0.18)
end)

-- ─────────────────────────────────────────────────────────────
-- ARRASTAR
-- ─────────────────────────────────────────────────────────────
local drag, dragS, winS = false, nil, nil
titleBar.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        drag=true; dragS=i.Position; winS=win.Position
    end
end)
UIS.InputChanged:Connect(function(i)
    if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
        local d = i.Position - dragS
        win.Position = UDim2.new(winS.X.Scale, winS.X.Offset+d.X,
                                 winS.Y.Scale, winS.Y.Offset+d.Y)
    end
end)
UIS.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then drag=false end
end)

-- ─────────────────────────────────────────────────────────────
-- ATALHOS
-- ─────────────────────────────────────────────────────────────
UIS.InputBegan:Connect(function(inp, proc)
    if inp.KeyCode == Enum.KeyCode.Insert then
        win.Visible = not win.Visible
        if win.Visible then
            task.defer(function() editorInput:CaptureFocus() end)
        end
        return
    end
    if proc or not win.Visible then return end
    if inp.KeyCode == Enum.KeyCode.F6 then
        runScript()
    end
end)

-- ─────────────────────────────────────────────────────────────
-- BOOT
-- ─────────────────────────────────────────────────────────────
log("Script Executor pronto!  INSERT = abrir  |  F6 = executar",
    Color3.fromRGB(130, 100, 220))
log(string.rep("─", 55), Color3.fromRGB(40,40,60))
print("[ScriptExecutor] Carregado! Pressione INSERT para abrir.")
