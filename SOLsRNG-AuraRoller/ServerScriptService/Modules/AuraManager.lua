-- AuraManager.lua (ModuleScript em ServerScriptService/Modules)
-- Gerencia efeitos de aura nos personagens dos jogadores (servidor)

local AuraManager = {}

local GameConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("GameConfig"))

-- Cache dos efeitos ativos: { [player] = { attachment, light, ... } }
local activeEffects = {}

-- ============================================================
-- Remove efeito de aura do personagem
-- ============================================================
local function removeAuraEffects(character)
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local existing = hrp:FindFirstChild("AuraAttachment")
    if existing then existing:Destroy() end

    local existingLight = hrp:FindFirstChild("AuraLight")
    if existingLight then existingLight:Destroy() end
end

-- ============================================================
-- Aplica efeito de aura no personagem
-- ============================================================
local function applyAuraEffect(character, auraDef)
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    removeAuraEffects(character)

    if not auraDef then return end

    -- Attachment base
    local attachment = Instance.new("Attachment")
    attachment.Name = "AuraAttachment"
    attachment.Position = Vector3.new(0, 0, 0)
    attachment.Parent = hrp

    -- Emissor de particulas principal
    local emitter = Instance.new("ParticleEmitter")
    emitter.Color         = ColorSequence.new({
        ColorSequenceKeypoint.new(0, auraDef.color),
        ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
        ColorSequenceKeypoint.new(1, auraDef.color),
    })
    emitter.LightEmission = 1
    emitter.LightInfluence = 0
    emitter.Size          = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.3),
        NumberSequenceKeypoint.new(0.5, 0.8),
        NumberSequenceKeypoint.new(1, 0),
    })
    emitter.Transparency  = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.7, 0.3),
        NumberSequenceKeypoint.new(1, 1),
    })
    emitter.Speed         = NumberRange.new(3, 8)
    emitter.SpreadAngle   = Vector2.new(180, 180)
    emitter.Rate          = auraDef.particles
    emitter.Lifetime      = NumberRange.new(1.5, 3)
    emitter.RotSpeed      = NumberRange.new(-45, 45)
    emitter.Rotation      = NumberRange.new(0, 360)

    -- Auras Raras/Epic+ tem particulas maiores
    local rarityOrder = GameConfig.RARITY_ORDER[auraDef.rarity] or 1
    if rarityOrder >= 4 then -- Epic+
        emitter.Rate = auraDef.particles * 1.5
        emitter.Speed = NumberRange.new(5, 15)
    end

    emitter.Parent = attachment

    -- Emissor secundario (rastro orbital) para Epic+
    if rarityOrder >= 4 then
        local orbitalAttach = Instance.new("Attachment")
        orbitalAttach.Name = "OrbitalAttachment"
        orbitalAttach.Parent = hrp

        local orbEmitter = Instance.new("ParticleEmitter")
        orbEmitter.Color        = ColorSequence.new(auraDef.color)
        orbEmitter.LightEmission = 1
        orbEmitter.Size         = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.5),
            NumberSequenceKeypoint.new(1, 0),
        })
        orbEmitter.Speed        = NumberRange.new(2, 5)
        orbEmitter.SpreadAngle  = Vector2.new(360, 360)
        orbEmitter.Rate         = auraDef.particles * 0.5
        orbEmitter.Lifetime     = NumberRange.new(2, 4)
        orbEmitter.Parent       = orbitalAttach
    end

    -- Luz ambiente (para auras que tem lightIntensity > 0)
    if auraDef.lightIntensity > 0 then
        local light = Instance.new("PointLight")
        light.Name        = "AuraLight"
        light.Color       = auraDef.color
        light.Brightness  = auraDef.lightIntensity
        light.Range       = 20 + (rarityOrder * 5)
        light.Parent      = hrp
    end

    -- Billboard de nome da aura (para raridades altas)
    if rarityOrder >= 5 then
        local billboard = Instance.new("BillboardGui")
        billboard.Name         = "AuraBillboard"
        billboard.Size         = UDim2.new(0, 200, 0, 30)
        billboard.StudsOffset  = Vector3.new(0, 3.5, 0)
        billboard.AlwaysOnTop  = false
        billboard.Parent       = hrp

        local label = Instance.new("TextLabel")
        label.Size              = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text              = "✨ " .. auraDef.name:upper() .. " ✨"
        label.TextColor3        = auraDef.color
        label.TextStrokeColor3  = Color3.new(0, 0, 0)
        label.TextStrokeTransparency = 0
        label.Font              = Enum.Font.GothamBold
        label.TextScaled        = true
        label.Parent            = billboard
    end
end

-- ============================================================
-- API PUBLICA
-- ============================================================

-- Aplica aura ativa do jogador ao seu personagem
function AuraManager.ApplyPlayerAura(player, auraName)
    local character = player.Character
    if not character then return end

    if auraName then
        local auraDef = GameConfig.GetAuraByName(auraName)
        if auraDef then
            applyAuraEffect(character, auraDef)
        end
    else
        removeAuraEffects(character)
    end
end

-- Remove aura do personagem
function AuraManager.RemovePlayerAura(player)
    local character = player.Character
    if not character then return end
    removeAuraEffects(character)
end

-- Conecta com respawn do jogador para reaplicar aura
function AuraManager.ConnectRespawn(player, dataGetter)
    player.CharacterAdded:Connect(function(character)
        -- Aguarda personagem carregar
        character:WaitForChild("HumanoidRootPart")
        task.wait(0.5)

        local data = dataGetter(player)
        if data and data.activeAura then
            AuraManager.ApplyPlayerAura(player, data.activeAura)
        end
    end)
end

-- Toca efeito de reveal de aura (explosao de particulas momentanea)
function AuraManager.PlayRevealEffect(player, auraDef)
    local character = player.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- Burst de particulas de reveal
    local burst = Instance.new("Attachment")
    burst.Parent = hrp

    local burstEmitter = Instance.new("ParticleEmitter")
    burstEmitter.Color        = ColorSequence.new(auraDef.color)
    burstEmitter.LightEmission = 1
    burstEmitter.Size         = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 2),
        NumberSequenceKeypoint.new(1, 0),
    })
    burstEmitter.Speed        = NumberRange.new(15, 30)
    burstEmitter.SpreadAngle  = Vector2.new(180, 180)
    burstEmitter.Rate         = 0
    burstEmitter.Lifetime     = NumberRange.new(1, 2)
    burstEmitter.Parent       = burst

    -- Emite burst
    local rarityOrder = GameConfig.RARITY_ORDER[auraDef.rarity] or 1
    burstEmitter:Emit(50 * rarityOrder)

    -- Luz intensa momentanea
    local flashLight = Instance.new("PointLight")
    flashLight.Color      = auraDef.color
    flashLight.Brightness = 20
    flashLight.Range      = 60
    flashLight.Parent     = hrp

    -- Fade da luz
    task.spawn(function()
        for i = 1, 20 do
            flashLight.Brightness = 20 * (1 - i / 20)
            task.wait(0.05)
        end
        flashLight:Destroy()
        burst:Destroy()
    end)
end

return AuraManager
