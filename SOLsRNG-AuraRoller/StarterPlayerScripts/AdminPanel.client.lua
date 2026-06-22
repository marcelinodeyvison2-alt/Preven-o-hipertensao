-- AdminPanel.client.lua (LocalScript em StarterPlayerScripts)
-- Painel de execucao de scripts para admins
-- Atalho: F9 para abrir / fechar | Ctrl+Enter para executar

local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

-- Aguarda confirmacao do servidor de que o jogador e admin
local adminRemotes = ReplicatedStorage:WaitForChild("AdminRemotes", 10)
if not adminRemotes then return end

local RE_IsAdmin = adminRemotes:WaitForChild("IsAdmin", 10)
local RF_Execute = adminRemotes:WaitForChild("Execute", 10)
local RE_Output  = adminRemotes:WaitForChild("Output",  10)
if not RE_IsAdmin or not RF_Execute or not RE_Output then return end

-- Aguarda o sinal do servidor (admin confirmado)
local adminConfirmed = false
RE_IsAdmin.OnClientEvent:Connect(function()
    adminConfirmed = true
end)

-- Tambem permite em Studio sem esperar o servidor
if game:GetService("RunService"):IsStudio() then
    adminConfirmed = true
end

-- Aguarda ate 5 segundos pela confirmacao
local waited = 0
while not adminConfirmed and waited < 5 do
    task.wait(0.2)
    waited = waited + 0.2
end

if not adminConfirmed then return end -- nao e admin, encerra o script

-- ============================================================
-- CONSTRUCAO DA UI
-- ============================================================
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name            = "AdminExecutor"
gui.ResetOnSpawn    = false
gui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder    = 999
gui.Parent          = PlayerGui

-- Painel principal
local panel = Instance.new("Frame")
panel.Name                = "Panel"
panel.Size                = UDim2.new(0, 640, 0, 440)
panel.Position            = UDim2.new(0.5, -320, 0.5, -220)
panel.BackgroundColor3    = Color3.fromRGB(12, 12, 18)
panel.BorderSizePixel     = 0
panel.Visible             = false
panel.ClipsDescendants    = true
panel.Parent              = gui

Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 10)

local panelStroke = Instance.new("UIStroke", panel)
panelStroke.Color     = Color3.fromRGB(110, 0, 255)
panelStroke.Thickness = 2

-- Barra de titulo (arrastavel)
local titleBar = Instance.new("Frame")
titleBar.Name             = "TitleBar"
titleBar.Size             = UDim2.new(1, 0, 0, 38)
titleBar.BackgroundColor3 = Color3.fromRGB(22, 0, 55)
titleBar.BorderSizePixel  = 0
titleBar.Parent           = panel
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 10)

-- Titulo
local titleLbl = Instance.new("TextLabel")
titleLbl.Size                = UDim2.new(1, -90, 1, 0)
titleLbl.Position            = UDim2.new(0, 14, 0, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text                = "  Script Executor — Admin Panel"
titleLbl.TextColor3          = Color3.fromRGB(190, 130, 255)
titleLbl.TextSize            = 14
titleLbl.Font                = Enum.Font.GothamBold
titleLbl.TextXAlignment      = Enum.TextXAlignment.Left
titleLbl.Parent              = titleBar

-- Badge F9
local f9Badge = Instance.new("TextLabel")
f9Badge.Size             = UDim2.new(0, 60, 0, 22)
f9Badge.Position         = UDim2.new(1, -94, 0.5, -11)
f9Badge.BackgroundColor3 = Color3.fromRGB(50, 0, 100)
f9Badge.Text             = "F9"
f9Badge.TextColor3       = Color3.fromRGB(200, 150, 255)
f9Badge.TextSize         = 12
f9Badge.Font             = Enum.Font.GothamBold
f9Badge.BorderSizePixel  = 0
f9Badge.Parent           = titleBar
Instance.new("UICorner", f9Badge).CornerRadius = UDim.new(0, 5)

-- Botao fechar
local closeBtn = Instance.new("TextButton")
closeBtn.Size             = UDim2.new(0, 26, 0, 26)
closeBtn.Position         = UDim2.new(1, -32, 0.5, -13)
closeBtn.BackgroundColor3 = Color3.fromRGB(160, 0, 0)
closeBtn.Text             = "✕"
closeBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize         = 13
closeBtn.Font             = Enum.Font.GothamBold
closeBtn.BorderSizePixel  = 0
closeBtn.Parent           = titleBar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

-- ---- Console de saida ----
local outputBg = Instance.new("Frame")
outputBg.Size             = UDim2.new(1, -16, 0, 216)
outputBg.Position         = UDim2.new(0, 8, 0, 46)
outputBg.BackgroundColor3 = Color3.fromRGB(6, 6, 10)
outputBg.BorderSizePixel  = 0
outputBg.Parent           = panel
Instance.new("UICorner", outputBg).CornerRadius = UDim.new(0, 6)
local outStroke = Instance.new("UIStroke", outputBg)
outStroke.Color     = Color3.fromRGB(45, 0, 110)
outStroke.Thickness = 1

local outputScroll = Instance.new("ScrollingFrame")
outputScroll.Size                 = UDim2.new(1, -4, 1, -4)
outputScroll.Position             = UDim2.new(0, 2, 0, 2)
outputScroll.BackgroundTransparency = 1
outputScroll.BorderSizePixel      = 0
outputScroll.ScrollBarThickness   = 5
outputScroll.ScrollBarImageColor3 = Color3.fromRGB(100, 0, 255)
outputScroll.CanvasSize           = UDim2.new(0, 0, 0, 0)
outputScroll.AutomaticCanvasSize  = Enum.AutomaticSize.Y
outputScroll.Parent               = outputBg

local outList    = Instance.new("UIListLayout", outputScroll)
outList.Padding  = UDim.new(0, 1)
local outPad     = Instance.new("UIPadding", outputScroll)
outPad.PaddingLeft   = UDim.new(0, 7)
outPad.PaddingRight  = UDim.new(0, 7)
outPad.PaddingTop    = UDim.new(0, 5)
outPad.PaddingBottom = UDim.new(0, 5)

-- ---- Area de entrada ----
local inputBg = Instance.new("Frame")
inputBg.Size             = UDim2.new(1, -16, 0, 96)
inputBg.Position         = UDim2.new(0, 8, 0, 270)
inputBg.BackgroundColor3 = Color3.fromRGB(6, 6, 10)
inputBg.BorderSizePixel  = 0
inputBg.Parent           = panel
Instance.new("UICorner", inputBg).CornerRadius = UDim.new(0, 6)
local inStroke = Instance.new("UIStroke", inputBg)
inStroke.Color     = Color3.fromRGB(70, 0, 180)
inStroke.Thickness = 1

local inputBox = Instance.new("TextBox")
inputBox.Size                 = UDim2.new(1, -12, 1, -8)
inputBox.Position             = UDim2.new(0, 6, 0, 4)
inputBox.BackgroundTransparency = 1
inputBox.Text                 = ""
inputBox.PlaceholderText      = "-- Digite um comando ou script Lua aqui...\n-- Ex: give_coins SeuNome 5000\n-- Ex: print(workspace:GetChildren())"
inputBox.TextColor3           = Color3.fromRGB(180, 255, 180)
inputBox.PlaceholderColor3    = Color3.fromRGB(70, 70, 95)
inputBox.TextSize             = 13
inputBox.Font                 = Enum.Font.Code
inputBox.TextXAlignment       = Enum.TextXAlignment.Left
inputBox.TextYAlignment       = Enum.TextYAlignment.Top
inputBox.MultiLine            = true
inputBox.ClearTextOnFocus     = false
inputBox.Parent               = inputBg

-- ---- Barra de botoes ----
local btnRow = Instance.new("Frame")
btnRow.Size                = UDim2.new(1, -16, 0, 40)
btnRow.Position            = UDim2.new(0, 8, 0, 376)
btnRow.BackgroundTransparency = 1
btnRow.Parent              = panel

local btnLayout = Instance.new("UIListLayout", btnRow)
btnLayout.FillDirection     = Enum.FillDirection.Horizontal
btnLayout.VerticalAlignment = Enum.VerticalAlignment.Center
btnLayout.Padding           = UDim.new(0, 8)

local function makeBtn(label, bg)
    local b = Instance.new("TextButton")
    b.Size             = UDim2.new(0, 118, 0, 32)
    b.BackgroundColor3 = bg
    b.Text             = label
    b.TextColor3       = Color3.fromRGB(255, 255, 255)
    b.TextSize         = 13
    b.Font             = Enum.Font.GothamBold
    b.BorderSizePixel  = 0
    b.Parent           = btnRow
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    return b
end

local execBtn  = makeBtn("▶  Executar",  Color3.fromRGB(0, 130, 0))
local clearBtn = makeBtn("⬜ Limpar",    Color3.fromRGB(60, 60, 80))
local helpBtn  = makeBtn("?  Ajuda",     Color3.fromRGB(0, 70, 155))

local hintLbl = Instance.new("TextLabel")
hintLbl.Size             = UDim2.new(1, -374, 1, 0)
hintLbl.BackgroundTransparency = 1
hintLbl.Text             = "Ctrl+Enter para executar"
hintLbl.TextColor3       = Color3.fromRGB(100, 100, 130)
hintLbl.TextSize         = 11
hintLbl.Font             = Enum.Font.Gotham
hintLbl.TextXAlignment   = Enum.TextXAlignment.Right
hintLbl.Parent           = btnRow

-- ============================================================
-- LOGICA DE ARRASTAR
-- ============================================================
local dragging, dragStart, panelStart = false, nil, nil

titleBar.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging    = true
        dragStart   = inp.Position
        panelStart  = panel.Position
    end
end)

UserInputService.InputChanged:Connect(function(inp)
    if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
        local d = inp.Position - dragStart
        panel.Position = UDim2.new(
            panelStart.X.Scale, panelStart.X.Offset + d.X,
            panelStart.Y.Scale, panelStart.Y.Offset + d.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- ============================================================
-- LOGICA DO CONSOLE
-- ============================================================
local lineCount = 0
local MAX_LINES = 300

-- Paleta de cores para cada tipo de saida
local COLORS = {
    input   = Color3.fromRGB(140, 140, 255), -- comando digitado
    ok      = Color3.fromRGB(90,  220,  90), -- sucesso
    err     = Color3.fromRGB(255,  70,  70), -- erro
    print   = Color3.fromRGB(255, 210,  90), -- print() do script
    system  = Color3.fromRGB(160, 100, 255), -- mensagens do sistema
    divider = Color3.fromRGB( 60,  60,  80), -- separadores
}

local function addLine(text, color)
    lineCount = lineCount + 1
    if lineCount > MAX_LINES then
        local oldest = outputScroll:FindFirstChildOfClass("TextLabel")
        if oldest then oldest:Destroy() end
    end

    local lbl = Instance.new("TextLabel")
    lbl.Size                = UDim2.new(1, 0, 0, 0)
    lbl.AutomaticSize       = Enum.AutomaticSize.Y
    lbl.BackgroundTransparency = 1
    lbl.Text                = tostring(text)
    lbl.TextColor3          = color or COLORS.ok
    lbl.TextSize            = 12
    lbl.Font                = Enum.Font.Code
    lbl.TextXAlignment      = Enum.TextXAlignment.Left
    lbl.TextWrapped         = true
    lbl.RichText            = false
    lbl.Parent              = outputScroll

    task.defer(function()
        outputScroll.CanvasPosition = Vector2.new(0, math.huge)
    end)
end

local function divider()
    addLine(string.rep("─", 72), COLORS.divider)
end

-- ============================================================
-- HISTORICO DE COMANDOS
-- ============================================================
local history    = {}
local histIdx    = 0

local function pushHistory(cmd)
    if history[#history] == cmd then return end
    table.insert(history, cmd)
    if #history > 100 then table.remove(history, 1) end
    histIdx = #history + 1
end

-- ============================================================
-- EXECUCAO
-- ============================================================
local executing = false

local function runInput()
    if executing then return end
    local text = inputBox.Text:match("^%s*(.-)%s*$")
    if text == "" then return end

    executing = true

    -- Mostra o que foi digitado
    divider()
    for line in (text .. "\n"):gmatch("([^\n]*)\n") do
        addLine("  " .. line, COLORS.input)
    end

    pushHistory(text)
    inputBox.Text = ""

    local ok, result = RF_Execute:InvokeServer(text)

    if ok then
        addLine(tostring(result), COLORS.ok)
    else
        addLine("ERRO: " .. tostring(result), COLORS.err)
    end

    executing = false
end

-- Saida em tempo real do servidor (via print() nos scripts Lua)
RE_Output.OnClientEvent:Connect(function(msg)
    addLine("[print] " .. tostring(msg), COLORS.print)
end)

-- ============================================================
-- EVENTOS DOS BOTOES
-- ============================================================
execBtn.MouseButton1Click:Connect(runInput)

clearBtn.MouseButton1Click:Connect(function()
    for _, c in ipairs(outputScroll:GetChildren()) do
        if c:IsA("TextLabel") then c:Destroy() end
    end
    lineCount = 0
    addLine("-- Console limpo --", COLORS.system)
end)

helpBtn.MouseButton1Click:Connect(function()
    inputBox.Text = "help"
    runInput()
end)

closeBtn.MouseButton1Click:Connect(function()
    panel.Visible = false
end)

-- ============================================================
-- ATALHOS DE TECLADO
-- ============================================================
UserInputService.InputBegan:Connect(function(inp, processed)
    -- F9: abre/fecha o painel
    if inp.KeyCode == Enum.KeyCode.F9 then
        panel.Visible = not panel.Visible
        if panel.Visible then
            task.defer(function() inputBox:CaptureFocus() end)
        end
        return
    end

    if processed or not panel.Visible then return end

    -- Ctrl+Enter: executa
    if inp.KeyCode == Enum.KeyCode.Return
        and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        runInput()
        return
    end

    -- Seta cima: comando anterior
    if inp.KeyCode == Enum.KeyCode.Up then
        if histIdx > 1 then
            histIdx = histIdx - 1
            inputBox.Text = history[histIdx] or ""
        end
        return
    end

    -- Seta baixo: proximo comando
    if inp.KeyCode == Enum.KeyCode.Down then
        if histIdx < #history then
            histIdx = histIdx + 1
            inputBox.Text = history[histIdx] or ""
        else
            histIdx = #history + 1
            inputBox.Text = ""
        end
    end
end)

-- ============================================================
-- MENSAGEM DE BOAS-VINDAS
-- ============================================================
addLine("  Script Executor — Admin Panel  ", COLORS.system)
addLine("  Bem-vindo, " .. LocalPlayer.Name .. "!", COLORS.system)
divider()
addLine("  F9       — abrir / fechar painel",  COLORS.system)
addLine("  Ctrl+Enter — executar script",      COLORS.system)
addLine("  Setas ↑↓  — historico de comandos", COLORS.system)
addLine("  Digite 'help' para ver os comandos.", COLORS.system)
divider()

print("[AdminPanel] Painel de admin carregado para " .. LocalPlayer.Name)
