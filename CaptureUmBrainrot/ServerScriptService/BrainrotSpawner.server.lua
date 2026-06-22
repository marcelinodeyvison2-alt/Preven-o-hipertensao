-- BrainrotSpawner.server.lua
-- Spawns Brainrots in each area and handles ProximityPrompt captures.
-- Uses a single central Heartbeat loop instead of per-brainrot connections.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")

repeat task.wait(0.2) until ReplicatedStorage:GetAttribute("SetupComplete")

local BrainrotConfig  = require(ReplicatedStorage.Modules.BrainrotConfig)
local GameConfig      = require(ReplicatedStorage.Modules.GameConfig)
local SharedData      = require(script.Parent.Modules.SharedData)

local areasFolder     = workspace:WaitForChild("Areas")
local brainrotsFolder = workspace:WaitForChild("ActiveBrainrots")
local bindables       = ReplicatedStorage:WaitForChild("BindableEvents")
local captureBindable = bindables:WaitForChild("BrainrotCaptured")

local areaCount = {}
for areaKey in pairs(BrainrotConfig.Areas) do
    areaCount[areaKey] = 0
end

-- ── Central animation loop ─────────────────────────────────────────────────────
-- One Heartbeat connection for all brainrots; entries auto-clean when body is removed.

local activeBodies = {}  -- { body, basePos, startTime }

RunService.Heartbeat:Connect(function()
    local t = tick()
    for i = #activeBodies, 1, -1 do
        local e = activeBodies[i]
        if not e.body or not e.body.Parent then
            table.remove(activeBodies, i)
        else
            local age  = t - e.startTime
            local bobY = math.sin(age * 2) * 0.6
            e.body.CFrame = CFrame.new(e.basePos + Vector3.new(0, bobY, 0))
                * CFrame.Angles(0, age * 2.5, 0)
        end
    end
end)

-- ── Model factory ─────────────────────────────────────────────────────────────

local function buildBrainrotModel(bData, rData, position)
    local model = Instance.new("Model")
    model.Name  = bData.Name

    local body = Instance.new("Part")
    body.Name       = "Body"
    body.Shape      = Enum.PartType.Ball
    body.Size       = GameConfig.BrainrotSize
    body.Position   = position
    body.Anchored   = true
    body.Material   = Enum.Material.Neon
    body.Color      = rData.Color
    body.CastShadow = false
    body.Parent     = model

    local light = Instance.new("PointLight")
    light.Color      = rData.GlowColor
    light.Brightness = 3
    light.Range      = 14
    light.Parent     = body

    activeBodies[#activeBodies + 1] = { body = body, basePos = position, startTime = tick() }

    -- BillboardGui
    local bb = Instance.new("BillboardGui")
    bb.Size        = UDim2.new(0, 180, 0, 80)
    bb.StudsOffset = Vector3.new(0, 3.8, 0)
    bb.AlwaysOnTop = false
    bb.Parent      = body

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size               = UDim2.new(1, 0, 0.55, 0)
    nameLabel.Text               = bData.Emoji .. " " .. bData.Name
    nameLabel.TextColor3         = Color3.new(1, 1, 1)
    nameLabel.TextScaled         = true
    nameLabel.BackgroundColor3   = Color3.fromRGB(15, 15, 35)
    nameLabel.BackgroundTransparency = 0.15
    nameLabel.Font               = Enum.Font.GothamBold
    nameLabel.TextStrokeTransparency = 0
    nameLabel.Parent             = bb

    local uc1 = Instance.new("UICorner")
    uc1.CornerRadius = UDim.new(0.25, 0)
    uc1.Parent       = nameLabel

    local rarityLabel = Instance.new("TextLabel")
    rarityLabel.Size               = UDim2.new(1, 0, 0.42, 0)
    rarityLabel.Position           = UDim2.new(0, 0, 0.58, 0)
    rarityLabel.Text               = rData.DisplayName .. "  •  " .. rData.AuraValue .. " Aura"
    rarityLabel.TextColor3         = rData.Color
    rarityLabel.TextScaled         = true
    rarityLabel.BackgroundColor3   = Color3.fromRGB(8, 8, 22)
    rarityLabel.BackgroundTransparency = 0.25
    rarityLabel.Font               = Enum.Font.Gotham
    rarityLabel.Parent             = bb

    local uc2 = Instance.new("UICorner")
    uc2.CornerRadius = UDim.new(0.25, 0)
    uc2.Parent       = rarityLabel

    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText            = "Capturar!"
    prompt.ObjectText            = bData.Name
    prompt.HoldDuration          = 0
    prompt.MaxActivationDistance = 10
    prompt.KeyboardKeyCode       = Enum.KeyCode.E
    prompt.Parent                = body

    local function makeVal(class, name, value)
        local v = Instance.new(class)
        v.Name   = name
        v.Value  = value
        v.Parent = model
        return v
    end
    makeVal("StringValue", "BrainrotName", bData.Name)
    makeVal("StringValue", "Rarity",       bData.Rarity)
    makeVal("StringValue", "Emoji",        bData.Emoji)
    makeVal("IntValue",    "AuraValue",    rData.AuraValue)
    makeVal("StringValue", "AreaKey",      "")

    model.PrimaryPart = body
    return model, prompt
end

-- ── Spawn / remove ────────────────────────────────────────────────────────────

local function popModel(model)
    local body = model.PrimaryPart
    if body then
        local tw = TweenService:Create(body, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = Vector3.new(0.01, 0.01, 0.01),
        })
        tw:Play()
        tw.Completed:Wait()
    end
    model:Destroy()
end

local function spawnOneBrainrot(areaKey, areaData)
    local areaModel   = areasFolder:FindFirstChild(areaKey)
    if not areaModel then return end
    local spawnFolder = areaModel:FindFirstChild("SpawnPoints")
    if not spawnFolder then return end

    local points = spawnFolder:GetChildren()
    if #points == 0 then return end

    local sp       = points[math.random(1, #points)]
    local position = sp.Position + Vector3.new(0, GameConfig.SpawnHeightOffset, 0)

    local rarityKey = BrainrotConfig.rollRarity(areaData.Rarities)
    local rData     = BrainrotConfig.Rarities[rarityKey]
    local bData     = BrainrotConfig.randomBrainrot(rarityKey)

    local model, prompt = buildBrainrotModel(bData, rData, position)
    model:FindFirstChild("AreaKey").Value = areaKey
    model.Parent = brainrotsFolder
    areaCount[areaKey] = areaCount[areaKey] + 1

    local body = model.PrimaryPart
    if body then
        body.Size = Vector3.new(0.01, 0.01, 0.01)
        TweenService:Create(body, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = GameConfig.BrainrotSize,
        }):Play()
    end

    local captured = false
    prompt.Triggered:Connect(function(player)
        if captured then return end
        captured = true
        prompt.Enabled = false

        areaCount[areaKey] = math.max(0, areaCount[areaKey] - 1)
        captureBindable:Fire(player, {
            Name      = bData.Name,
            Rarity    = bData.Rarity,
            Emoji     = bData.Emoji,
            AuraValue = rData.AuraValue,
            AreaKey   = areaKey,
        })
        popModel(model)
    end)

    task.delay(GameConfig.BrainrotLifetime, function()
        if model.Parent and not captured then
            captured = true
            areaCount[areaKey] = math.max(0, areaCount[areaKey] - 1)
            popModel(model)
        end
    end)
end

-- ── Per-area spawn loops ──────────────────────────────────────────────────────

for areaKey, areaData in pairs(BrainrotConfig.Areas) do
    task.spawn(function()
        for _ = 1, areaData.MaxSpawns do
            spawnOneBrainrot(areaKey, areaData)
            task.wait(0.3)
        end

        while true do
            task.wait(areaData.SpawnInterval)
            local spawnMult = (SharedData.currentEvent and SharedData.currentEvent.SpawnMultiplier) or 1
            local cap = math.min(areaData.MaxSpawns * spawnMult, areaData.MaxSpawns * 3)
            if areaCount[areaKey] < cap then
                spawnOneBrainrot(areaKey, areaData)
            end
        end
    end)
end

print("[BrainrotSpawner] All area spawn loops started.")
