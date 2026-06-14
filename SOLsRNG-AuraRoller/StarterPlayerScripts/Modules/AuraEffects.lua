-- AuraEffects.lua (ModuleScript em StarterPlayerScripts/Modules)
-- Efeitos visuais de aura no lado do cliente

local AuraEffects = {}

local TweenService = game:GetService("TweenService")
local GameConfig   = require(game:GetService("ReplicatedStorage"):WaitForChild("GameConfig"))

-- ============================================================
-- Cria flash de tela (ColorCorrection no Lighting)
-- ============================================================
function AuraEffects.ScreenFlash(color, duration)
    duration = duration or 0.3
    local lighting = game:GetService("Lighting")

    local cc = lighting:FindFirstChildOfClass("ColorCorrectionEffect")
    if not cc then
        cc = Instance.new("ColorCorrectionEffect")
        cc.Parent = lighting
    end

    local originalTint = cc.TintColor
    cc.TintColor = color

    local tween = TweenService:Create(cc,
        TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { TintColor = originalTint }
    )
    tween:Play()
end

-- ============================================================
-- Cria shake de camera
-- ============================================================
function AuraEffects.CameraShake(intensity, duration)
    local camera = workspace.CurrentCamera
    if not camera then return end

    local startTime = tick()
    local connection
    connection = game:GetService("RunService").RenderStepped:Connect(function()
        local elapsed = tick() - startTime
        if elapsed >= duration then
            connection:Disconnect()
            return
        end

        local remaining = 1 - (elapsed / duration)
        local offsetX = (math.random() - 0.5) * intensity * remaining
        local offsetY = (math.random() - 0.5) * intensity * remaining

        camera.CFrame = camera.CFrame * CFrame.new(offsetX, offsetY, 0)
    end)
end

-- ============================================================
-- Cria estrelas de revelacao (particulas 2D na tela)
-- Estas sao GUI elements no ScreenGui
-- ============================================================
function AuraEffects.SpawnRevealStars(screenGui, auraColor, count)
    count = count or 30
    local screenSize = screenGui.AbsoluteSize

    for i = 1, count do
        task.delay(math.random() * 0.5, function()
            local star = Instance.new("TextLabel")
            star.BackgroundTransparency = 1
            star.Size     = UDim2.new(0, 30, 0, 30)
            star.Position = UDim2.new(math.random(), 0, math.random(), 0)
            star.Text     = "✦"
            star.TextColor3    = auraColor
            star.TextScaled    = true
            star.ZIndex        = 100
            star.Font          = Enum.Font.GothamBold
            star.BackgroundTransparency = 1
            star.Parent = screenGui

            -- Anima e destroi
            local tween = TweenService:Create(star,
                TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {
                    Position = UDim2.new(star.Position.X.Scale, 0, star.Position.Y.Scale - 0.3, 0),
                    TextTransparency = 1,
                    Size = UDim2.new(0, 60, 0, 60),
                }
            )
            tween:Play()
            tween.Completed:Connect(function()
                star:Destroy()
            end)
        end)
    end
end

-- ============================================================
-- Animacao de reveal da aura (card vira/aparece)
-- Retorna o frame que foi criado
-- ============================================================
function AuraEffects.PlayRevealAnimation(parent, auraDef, onComplete)
    local rarityOrder = GameConfig.RARITY_ORDER[auraDef.rarity] or 1
    local rarityColor = GameConfig.RARITY_COLORS[auraDef.rarity] or Color3.new(1,1,1)

    -- Container da animacao
    local revealFrame = Instance.new("Frame")
    revealFrame.Size              = UDim2.new(0, 250, 0, 350)
    revealFrame.Position          = UDim2.new(0.5, -125, 0.5, -175)
    revealFrame.BackgroundColor3  = Color3.fromRGB(10, 10, 30)
    revealFrame.BorderSizePixel   = 0
    revealFrame.ZIndex            = 50
    revealFrame.ClipsDescendants  = true
    revealFrame.Parent            = parent

    -- Borda colorida
    local border = Instance.new("UIStroke")
    border.Color     = rarityColor
    border.Thickness = 4
    border.Parent    = revealFrame

    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, 12)
    uiCorner.Parent = revealFrame

    -- Gradiente de fundo
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 20, 50)),
        ColorSequenceKeypoint.new(1, rarityColor:Lerp(Color3.fromRGB(10,10,30), 0.7)),
    })
    gradient.Rotation = 45
    gradient.Parent = revealFrame

    -- Icone de raridade
    local rarityLabel = Instance.new("TextLabel")
    rarityLabel.Size                = UDim2.new(1, 0, 0, 40)
    rarityLabel.Position            = UDim2.new(0, 0, 0, 10)
    rarityLabel.BackgroundTransparency = 1
    rarityLabel.Text                = GameConfig.RARITY_LABELS[auraDef.rarity] or auraDef.rarity
    rarityLabel.TextColor3          = rarityColor
    rarityLabel.Font                = Enum.Font.GothamBold
    rarityLabel.TextScaled          = true
    rarityLabel.ZIndex              = 51
    rarityLabel.Parent              = revealFrame

    -- Nome da aura
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size                  = UDim2.new(1, -20, 0, 60)
    nameLabel.Position              = UDim2.new(0, 10, 0.35, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text                  = auraDef.name:upper()
    nameLabel.TextColor3            = Color3.new(1, 1, 1)
    nameLabel.Font                  = Enum.Font.GothamBold
    nameLabel.TextScaled            = true
    nameLabel.ZIndex                = 51
    nameLabel.Parent                = revealFrame

    -- Chance
    local chanceLabel = Instance.new("TextLabel")
    chanceLabel.Size                = UDim2.new(1, -20, 0, 30)
    chanceLabel.Position            = UDim2.new(0, 10, 0.6, 0)
    chanceLabel.BackgroundTransparency = 1
    chanceLabel.Text                = "1 em " .. string.format("%s", tostring(auraDef.chance))
    chanceLabel.TextColor3          = Color3.fromRGB(180, 180, 180)
    chanceLabel.Font                = Enum.Font.Gotham
    chanceLabel.TextScaled          = true
    chanceLabel.ZIndex              = 51
    chanceLabel.Parent              = revealFrame

    -- Recompensas
    local rewardLabel = Instance.new("TextLabel")
    rewardLabel.Size                = UDim2.new(1, -20, 0, 30)
    rewardLabel.Position            = UDim2.new(0, 10, 0.75, 0)
    rewardLabel.BackgroundTransparency = 1
    rewardLabel.Text                = "🪙 +" .. auraDef.coins .. (auraDef.gems > 0 and "  💎 +" .. auraDef.gems or "")
    rewardLabel.TextColor3          = Color3.fromRGB(255, 220, 0)
    rewardLabel.Font                = Enum.Font.GothamBold
    rewardLabel.TextScaled          = true
    rewardLabel.ZIndex              = 51
    rewardLabel.Parent              = revealFrame

    -- Botao de fechar
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size                   = UDim2.new(0.8, 0, 0, 40)
    closeBtn.Position               = UDim2.new(0.1, 0, 0.88, 0)
    closeBtn.BackgroundColor3       = rarityColor
    closeBtn.Text                   = "✔  EQUIPAR AURA"
    closeBtn.TextColor3             = Color3.new(1, 1, 1)
    closeBtn.Font                   = Enum.Font.GothamBold
    closeBtn.TextScaled             = true
    closeBtn.ZIndex                 = 52
    closeBtn.BorderSizePixel        = 0
    closeBtn.Parent                 = revealFrame

    local closeBtnCorner = Instance.new("UICorner")
    closeBtnCorner.CornerRadius = UDim.new(0, 8)
    closeBtnCorner.Parent = closeBtn

    -- Animacao de entrada (scale up)
    revealFrame.Size = UDim2.new(0, 0, 0, 0)
    revealFrame.Position = UDim2.new(0.5, 0, 0.5, 0)

    local tweenIn = TweenService:Create(revealFrame,
        TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {
            Size     = UDim2.new(0, 250, 0, 350),
            Position = UDim2.new(0.5, -125, 0.5, -175),
        }
    )
    tweenIn:Play()

    -- Pulsa a borda para raridades altas
    if rarityOrder >= 4 then
        task.spawn(function()
            for i = 1, 5 do
                local t1 = TweenService:Create(border,
                    TweenInfo.new(0.3, Enum.EasingStyle.Sine),
                    { Thickness = 8 }
                )
                t1:Play()
                task.wait(0.3)
                local t2 = TweenService:Create(border,
                    TweenInfo.new(0.3, Enum.EasingStyle.Sine),
                    { Thickness = 4 }
                )
                t2:Play()
                task.wait(0.3)
            end
        end)
    end

    -- Fechar ao clicar
    closeBtn.MouseButton1Click:Connect(function()
        if onComplete then onComplete(auraDef) end
        local tweenOut = TweenService:Create(revealFrame,
            TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            { Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0) }
        )
        tweenOut:Play()
        tweenOut.Completed:Connect(function() revealFrame:Destroy() end)
    end)

    -- Auto-fechar apos 8 segundos
    task.delay(8, function()
        if revealFrame and revealFrame.Parent then
            if onComplete then onComplete(nil) end
            local tweenOut = TweenService:Create(revealFrame,
                TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                { Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0) }
            )
            tweenOut:Play()
            tweenOut.Completed:Connect(function() revealFrame:Destroy() end)
        end
    end)

    return revealFrame
end

return AuraEffects
