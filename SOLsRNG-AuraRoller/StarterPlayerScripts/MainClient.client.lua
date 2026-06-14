-- MainClient.client.lua (LocalScript em StarterPlayerScripts)
-- Script principal do cliente - orquestra UI, efeitos e comunicacao com servidor

local Players          = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local playerGui   = localPlayer:WaitForChild("PlayerGui")

-- Modulos
local Modules      = script.Parent:WaitForChild("Modules")
local UIManager    = require(Modules:WaitForChild("UIManager"))
local AuraEffects  = require(Modules:WaitForChild("AuraEffects"))
local SoundManager = require(Modules:WaitForChild("SoundManager"))
local GameConfig   = require(ReplicatedStorage:WaitForChild("GameConfig"))

-- Remote Events
local remotes          = ReplicatedStorage:WaitForChild("RemoteEvents")
local RE_Spin          = remotes:WaitForChild("Spin")
local RE_SpinResult    = remotes:WaitForChild("SpinResult")
local RE_BuyUpgrade    = remotes:WaitForChild("BuyUpgrade")
local RE_SetActiveAura = remotes:WaitForChild("SetActiveAura")
local RE_SyncData      = remotes:WaitForChild("SyncData")
local RE_EventUpdate   = remotes:WaitForChild("EventUpdate")
local RE_MysteryBox    = remotes:WaitForChild("MysteryBox")
local RE_LeaderboardUpdate = remotes:WaitForChild("LeaderboardUpdate")

-- ============================================================
-- ESTADO DO CLIENTE
-- ============================================================
local playerData     = nil    -- dados do jogador (sincronizados do servidor)
local isSpinning     = false  -- animacao de giro em progresso
local spinCooldown   = 0      -- tempo do proximo giro permitido
local activeEventDef = nil    -- evento ativo atual
local eventEndTime   = 0      -- quando o evento acaba

-- Referencias UI
local mainGui       = nil
local spinUI        = nil
local hudRef        = nil
local inventoryPanel = nil
local upgradesPanel  = nil
local lbPanel        = nil

-- ============================================================
-- SETUP DA INTERFACE
-- ============================================================
local function setupUI()
    -- Cria ScreenGui principal
    mainGui = Instance.new("ScreenGui")
    mainGui.Name           = "SOLsRNG_GUI"
    mainGui.ResetOnSpawn   = false
    mainGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    mainGui.Parent         = playerGui

    -- Background
    local bg = UIManager.Setup(mainGui)

    -- Particulas de fundo (estrelas)
    task.spawn(function()
        while mainGui and mainGui.Parent do
            local star = Instance.new("Frame")
            star.BackgroundColor3      = Color3.new(1, 1, 1)
            star.BackgroundTransparency = 0.7
            star.BorderSizePixel        = 0
            star.Size                   = UDim2.new(0, math.random(1,3), 0, math.random(1,3))
            star.Position               = UDim2.new(math.random(), 0, math.random(), 0)
            star.ZIndex                 = 1
            star.Parent                 = mainGui

            local tween = TweenService:Create(star,
                TweenInfo.new(math.random(5,15), Enum.EasingStyle.Linear),
                { BackgroundTransparency = 1 }
            )
            tween:Play()
            tween.Completed:Connect(function() star:Destroy() end)

            task.wait(0.3)
        end
    end)

    -- HUD (moedas, gemas, evento)
    hudRef = UIManager.CreateHUD(mainGui)

    -- Area de Spin
    spinUI = UIManager.CreateSpinArea(mainGui, {
        onSpin = function(rollTypeId)
            handleSpin(rollTypeId)
        end,
        onRollTypeChange = function(rollType)
            -- Mostra custo da roleta selecionada
            local msg = rollType.icon .. " " .. rollType.name
            if rollType.cost.coins > 0 then msg = msg .. " — 🪙 " .. rollType.cost.coins end
            if rollType.cost.gems  > 0 then msg = msg .. " — 💎 " .. rollType.cost.gems  end
        end,
    })

    -- Paineis (inventario, upgrades, leaderboard)
    inventoryPanel = UIManager.CreateInventoryPanel(mainGui, {
        onEquip = function(auraName)
            RE_SetActiveAura:FireServer(auraName)
            SoundManager.PlayButton()
        end,
    })

    upgradesPanel = UIManager.CreateUpgradesPanel(mainGui, {
        onBuy = function(upgradeId)
            RE_BuyUpgrade:FireServer(upgradeId)
            SoundManager.PlayButton()
        end,
    })

    lbPanel = UIManager.CreateLeaderboardPanel(mainGui)

    -- Navegacao
    UIManager.CreateNavPanel(mainGui, {
        onNav = function(panelId)
            SoundManager.PlayButton()
            inventoryPanel.Visible = false
            upgradesPanel.Visible  = false
            lbPanel.Visible        = false

            if panelId == "inventory" then
                inventoryPanel.Visible = true
                if playerData then
                    UIManager.PopulateInventory(
                        inventoryPanel,
                        playerData.inventory,
                        playerData.activeAura,
                        function(auraName)
                            RE_SetActiveAura:FireServer(auraName)
                        end
                    )
                end
            elseif panelId == "upgrades" then
                upgradesPanel.Visible = true
                if playerData then
                    UIManager.PopulateUpgrades(
                        upgradesPanel,
                        playerData.upgrades,
                        playerData.coins,
                        playerData.gems,
                        function(upgradeId)
                            RE_BuyUpgrade:FireServer(upgradeId)
                        end
                    )
                end
            elseif panelId == "leaderboard" then
                lbPanel.Visible = true
            end
        end,
    })
end

-- ============================================================
-- FUNCAO: GIRAR
-- ============================================================
function handleSpin(rollTypeId)
    if isSpinning then return end

    local now = tick()
    if now < spinCooldown then
        local remaining = math.ceil(spinCooldown - now)
        UIManager.ShowNotification(mainGui, "⏳ Aguarde " .. remaining .. "s...", Color3.fromRGB(255,150,0))
        return
    end

    -- Inicia animacao de spinner de espera
    isSpinning = true
    if spinUI.spinBtn then
        spinUI.spinBtn.Text = "🎰  GIRANDO..."
        spinUI.spinBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    end

    -- Anima a roleta com itens aleatorios temporarios enquanto espera servidor
    local dummySeq = {}
    local allAuras = GameConfig.AURAS
    for i = 1, 20 do
        table.insert(dummySeq, allAuras[math.random(1, #allAuras)].name)
    end

    UIManager.AnimateRoll(spinUI.rollStrip, dummySeq, function() end)

    -- Toca sons de tick da roleta
    task.spawn(function()
        for i = 1, 15 do
            SoundManager.PlaySpinTick()
            task.wait(0.05 + i * 0.008)
        end
    end)

    -- Envia pedido de giro ao servidor
    RE_Spin:FireServer(rollTypeId)
end

-- ============================================================
-- REMOTE: RESULTADO DO GIRO
-- ============================================================
RE_SpinResult.OnClientEvent:Connect(function(result, errorMsg, upgradeResult)
    -- Resultado de upgrade
    if upgradeResult then
        local color = upgradeResult.upgradeSuccess and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 80, 80)
        UIManager.ShowNotification(mainGui, upgradeResult.msg, color)
        SoundManager.PlayUpgradeBuy()

        -- Recarrega painel de upgrades se estiver aberto
        if upgradesPanel.Visible and playerData then
            UIManager.PopulateUpgrades(
                upgradesPanel,
                playerData.upgrades,
                playerData.coins,
                playerData.gems,
                function(upgradeId) RE_BuyUpgrade:FireServer(upgradeId) end
            )
        end
        return
    end

    -- Erro no giro
    if errorMsg then
        UIManager.ShowNotification(mainGui, "❌ " .. errorMsg, Color3.fromRGB(255, 80, 80))
        isSpinning = false
        if spinUI.spinBtn then
            spinUI.spinBtn.Text = "🎰  GIRAR!"
            spinUI.spinBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
        end
        return
    end

    if not result then return end

    local auraDef   = result.aura
    local rarityOrder = GameConfig.RARITY_ORDER[auraDef.rarity] or 1

    -- Anima roleta com sequencia real do servidor
    UIManager.AnimateRoll(spinUI.rollStrip, result.rollSequence, function()
        -- Reveal da aura
        SoundManager.PlayReveal(auraDef.rarity)

        -- Efeito de flash na tela para raras
        if rarityOrder >= 3 then
            AuraEffects.ScreenFlash(auraDef.color, 0.5)
        end

        -- Shake de camera para epicas+
        if rarityOrder >= 4 then
            AuraEffects.CameraShake(rarityOrder * 0.3, 0.8)
        end

        -- Estrelas na tela para legendarias+
        if rarityOrder >= 5 then
            AuraEffects.SpawnRevealStars(mainGui, auraDef.color, 50)
        end

        -- Atualiza label de resultado
        if spinUI.resultLabel then
            local rarityColor = GameConfig.RARITY_COLORS[auraDef.rarity]
            spinUI.resultLabel.Text = auraDef.name:upper() .. " (" .. auraDef.rarity .. ")"
            spinUI.resultLabel.TextColor3 = rarityColor
        end

        -- Mensagem aleatoria por raridade
        local messages = GameConfig.MESSAGES[auraDef.rarity]
        if messages then
            local msg = messages[math.random(1, #messages)]
            UIManager.ShowNotification(mainGui, msg, GameConfig.RARITY_COLORS[auraDef.rarity], 3)
        end

        -- Recompensas
        local rewardText = "+" .. result.coins .. " 🪙"
        if result.gems > 0 then rewardText = rewardText .. "  +" .. result.gems .. " 💎" end
        UIManager.ShowNotification(mainGui, rewardText, Color3.fromRGB(255, 220, 0), 2.5)

        -- Card de reveal para raras+
        if rarityOrder >= 3 then
            AuraEffects.PlayRevealAnimation(mainGui, auraDef, function(clickedAura)
                if clickedAura then
                    RE_SetActiveAura:FireServer(clickedAura.name)
                end
            end)
        end

        -- Libera spin
        isSpinning = false
        local cooldownTime = 3
        if playerData then
            -- Calcula cooldown baseado nos upgrades
            local reduction = 0
            if playerData.upgrades then
                for upgradeId, level in pairs(playerData.upgrades) do
                    if upgradeId == "speed1" then
                        reduction = reduction + 0.5 * level
                    end
                end
            end
            cooldownTime = math.max(0.5, 3 - reduction)
        end

        spinCooldown = tick() + cooldownTime

        if spinUI.spinBtn then
            spinUI.spinBtn.Text = "🎰  GIRAR!"
            spinUI.spinBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
        end

        -- Mostra overlay de cooldown
        task.spawn(function()
            if spinUI.cooldownOverlay then
                spinUI.cooldownOverlay.Visible = true
                local remaining = cooldownTime
                while remaining > 0 do
                    spinUI.cooldownLabel.Text = string.format("%.1fs", remaining)
                    task.wait(0.1)
                    remaining = remaining - 0.1
                end
                spinUI.cooldownOverlay.Visible = false
            end
        end)
    end)
end)

-- ============================================================
-- REMOTE: SYNC DE DADOS
-- ============================================================
RE_SyncData.OnClientEvent:Connect(function(data)
    playerData = data

    -- Atualiza HUD
    if hudRef then
        UIManager.UpdateHUD(hudRef, data.coins, data.gems)
    end

    -- Recarrega paineis se abertos
    if inventoryPanel and inventoryPanel.Visible then
        UIManager.PopulateInventory(
            inventoryPanel,
            data.inventory,
            data.activeAura,
            function(auraName) RE_SetActiveAura:FireServer(auraName) end
        )
    end
    if upgradesPanel and upgradesPanel.Visible then
        UIManager.PopulateUpgrades(
            upgradesPanel,
            data.upgrades,
            data.coins,
            data.gems,
            function(upgradeId) RE_BuyUpgrade:FireServer(upgradeId) end
        )
    end
end)

-- ============================================================
-- REMOTE: EVENTOS
-- ============================================================
RE_EventUpdate.OnClientEvent:Connect(function(eventType, eventDef, timeRemaining)
    if eventType == "started" then
        activeEventDef = eventDef
        eventEndTime   = tick() + (timeRemaining or 0)

        SoundManager.PlayEventStart()

        -- Notificacao de evento
        UIManager.ShowNotification(
            mainGui,
            eventDef.icon .. " " .. eventDef.name .. "! " .. eventDef.description,
            Color3.fromRGB(255, 220, 0),
            5
        )

        -- Flash especial de evento
        AuraEffects.ScreenFlash(eventDef.color or Color3.fromRGB(255,200,0), 0.8)

    elseif eventType == "ended" then
        activeEventDef = nil
        UIManager.ShowNotification(mainGui, "Evento encerrado.", Color3.fromRGB(150,150,150), 2)
        if hudRef then UIManager.UpdateEventHUD(hudRef, nil, 0) end
    end
end)

-- ============================================================
-- REMOTE: MYSTERY BOX
-- ============================================================
RE_MysteryBox.OnClientEvent:Connect(function(eventType, ...)
    if eventType == "spawned" then
        SoundManager.PlayMysteryBox()
        UIManager.ShowNotification(
            mainGui,
            "📦 Uma Mystery Box apareceu! Corra para pegar!",
            Color3.fromRGB(0, 255, 200),
            5
        )
        AuraEffects.ScreenFlash(Color3.fromRGB(0, 255, 200), 0.4)
    elseif eventType == "collected" then
        local playerName, auraName = ...
        UIManager.ShowNotification(
            mainGui,
            "📦 " .. playerName .. " coletou a Mystery Box e ganhou: " .. auraName .. "!",
            Color3.fromRGB(0, 255, 200),
            4
        )
    elseif eventType == "expired" then
        UIManager.ShowNotification(mainGui, "📦 A Mystery Box desapareceu...", Color3.fromRGB(150,150,150), 2)
    end
end)

-- ============================================================
-- REMOTE: LEADERBOARD UPDATE
-- ============================================================
RE_LeaderboardUpdate.OnClientEvent:Connect(function(lbData)
    if lbPanel then
        UIManager.PopulateLeaderboard(lbPanel, lbData)
    end
end)

-- ============================================================
-- LOOP DE ATUALIZACAO DE EVENTO HUD
-- ============================================================
task.spawn(function()
    while true do
        task.wait(1)
        if hudRef and activeEventDef then
            local remaining = math.max(0, math.floor(eventEndTime - tick()))
            UIManager.UpdateEventHUD(hudRef, activeEventDef, remaining)
        end
    end
end)

-- ============================================================
-- INICIALIZACAO
-- ============================================================
setupUI()
print("[Client] SOL's RNG - Aura Roller carregado para " .. localPlayer.Name)
