-- EventManager.server.lua
-- Manages timed global events that affect the entire server.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

repeat task.wait(0.2) until ReplicatedStorage:GetAttribute("SetupComplete")

local EventConfig = require(ReplicatedStorage.Modules.EventConfig)
local SharedData  = require(script.Parent.Modules.SharedData)

local remotes    = ReplicatedStorage:WaitForChild("RemoteEvents")
local bindables  = ReplicatedStorage:WaitForChild("BindableEvents")
local evEvent    = remotes:WaitForChild("EventUpdate")
local bindEvent  = bindables:WaitForChild("EventChanged")

-- ── Broadcast current event state to all players ──────────────────────────────

local function broadcastEvent()
    local payload = SharedData.currentEvent
    for _, player in ipairs(Players:GetPlayers()) do
        evEvent:FireClient(player, payload)
    end
    bindEvent:Fire(payload)
end

-- ── Start an event ────────────────────────────────────────────────────────────

local function startEvent(eventKey)
    local def = EventConfig.Events[eventKey]
    if not def then return end

    SharedData.currentEvent = {
        Key             = def.Key,
        Name            = def.Name,
        Description     = def.Description,
        Emoji           = def.Emoji,
        Duration        = def.Duration,
        AuraMultiplier  = def.AuraMultiplier,
        LuckMultiplier  = def.LuckMultiplier,
        SpawnMultiplier = def.SpawnMultiplier,
        Color           = def.Color,
        endsAt          = os.clock() + def.Duration,
    }

    broadcastEvent()
    print("[EventManager] Started event:", def.Name)

    task.delay(def.Duration, function()
        if SharedData.currentEvent and SharedData.currentEvent.Key == eventKey then
            SharedData.currentEvent = nil
            broadcastEvent()
            print("[EventManager] Event ended:", def.Name)
        end
    end)
end

-- ── Auto-start countdown loop ─────────────────────────────────────────────────

task.spawn(function()
    -- Initial delay before first event
    task.wait(math.random(EventConfig.MinInterval, EventConfig.MaxInterval))

    while true do
        if not SharedData.currentEvent then
            local list   = EventConfig.EventList
            local chosen = list[math.random(1, #list)]
            startEvent(chosen)
        end
        task.wait(math.random(EventConfig.MinInterval, EventConfig.MaxInterval))
    end
end)

-- ── Time-remaining countdown broadcaster (every 30s) ─────────────────────────

task.spawn(function()
    while true do
        task.wait(30)
        if SharedData.currentEvent then
            broadcastEvent()
        end
    end
end)

-- Give joining players the current event state
Players.PlayerAdded:Connect(function(player)
    task.delay(4, function()
        if player.Parent then
            evEvent:FireClient(player, SharedData.currentEvent)
        end
    end)
end)

print("[EventManager] Ready. Events will begin randomly.")
