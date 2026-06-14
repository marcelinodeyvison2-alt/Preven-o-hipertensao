-- EventManager.lua (ModuleScript em ServerScriptService/Modules)
-- Gerencia eventos aleatorios do jogo (Double RNG, Luxury Hour, Mystery Box)

local EventManager = {}

local RunService   = game:GetService("RunService")
local GameConfig   = require(game:GetService("ReplicatedStorage"):WaitForChild("GameConfig"))

-- Estado do evento ativo
local activeEvent = nil       -- { eventDef, endTime }
local eventCallbacks = {}     -- funcoes chamadas quando evento muda

-- Tempo do proximo evento
local nextEventTime = 0

-- ============================================================
-- Inicia um evento pelo ID
-- ============================================================
function EventManager.StartEvent(eventId)
    local eventDef = nil
    for _, e in ipairs(GameConfig.EVENTS) do
        if e.id == eventId then
            eventDef = e
            break
        end
    end
    if not eventDef then return end

    activeEvent = {
        def     = eventDef,
        endTime = os.time() + eventDef.duration,
    }

    -- Notifica callbacks (MainServer vai repassar para clientes)
    for _, cb in ipairs(eventCallbacks) do
        pcall(cb, "started", activeEvent)
    end

    -- Agenda fim do evento
    task.delay(eventDef.duration, function()
        if activeEvent and activeEvent.def.id == eventId then
            EventManager.EndEvent()
        end
    end)
end

-- ============================================================
-- Encerra evento ativo
-- ============================================================
function EventManager.EndEvent()
    if activeEvent then
        for _, cb in ipairs(eventCallbacks) do
            pcall(cb, "ended", activeEvent)
        end
        activeEvent = nil
    end

    -- Agenda proximo evento aleatorio
    local minInterval = GameConfig.SETTINGS.EVENT_MIN_INTERVAL
    local maxInterval = GameConfig.SETTINGS.EVENT_MAX_INTERVAL
    nextEventTime = os.time() + math.random(minInterval, maxInterval)
end

-- ============================================================
-- Verifica e dispara eventos aleatorios
-- Deve ser chamado no loop principal
-- ============================================================
function EventManager.Update()
    if activeEvent then
        -- Verifica se evento expirou
        if os.time() >= activeEvent.endTime then
            EventManager.EndEvent()
        end
        return
    end

    -- Verifica se e hora de um novo evento
    if os.time() >= nextEventTime and nextEventTime > 0 then
        -- Seleciona evento aleatorio (excluindo mystery box que e especial)
        local regularEvents = {}
        for _, e in ipairs(GameConfig.EVENTS) do
            if not e.isBox then
                table.insert(regularEvents, e)
            end
        end

        if #regularEvents > 0 then
            local chosen = regularEvents[math.random(1, #regularEvents)]
            EventManager.StartEvent(chosen.id)
        end
    end
end

-- ============================================================
-- Inicializa o sistema (chama uma vez ao iniciar o servidor)
-- ============================================================
function EventManager.Initialize()
    -- Primeiro evento apos 5-10 minutos de jogo
    nextEventTime = os.time() + math.random(300, 600)
end

-- ============================================================
-- Getters
-- ============================================================
function EventManager.GetActiveEvent()
    return activeEvent
end

function EventManager.GetLuckMultiplier()
    if activeEvent then
        return activeEvent.def.luckMultiplier or 1
    end
    return 1
end

function EventManager.GetCoinMultiplier()
    if activeEvent then
        return activeEvent.def.coinMultiplier or 1
    end
    return 1
end

function EventManager.GetTimeRemaining()
    if not activeEvent then return 0 end
    return math.max(0, activeEvent.endTime - os.time())
end

-- ============================================================
-- Registra callback para mudancas de evento
-- ============================================================
function EventManager.OnEventChange(callback)
    table.insert(eventCallbacks, callback)
end

-- ============================================================
-- Trigger manual (admin command)
-- ============================================================
function EventManager.TriggerManual(eventId)
    if activeEvent then
        EventManager.EndEvent()
    end
    EventManager.StartEvent(eventId)
end

return EventManager
