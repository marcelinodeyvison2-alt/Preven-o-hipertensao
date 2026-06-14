-- SoundManager.lua (ModuleScript em StarterPlayerScripts/Modules)
-- Gerencia sons do jogo (roleta, reveal, upgrades, eventos)
-- NOTA: substitua os SoundId pelos IDs reais do Roblox

local SoundManager = {}

local SoundService = game:GetService("SoundService")

-- IDs de sons (substitua pelos IDs reais do Roblox Audio)
-- Use o Roblox Audio Catalog para encontrar sons adequados
local SOUND_IDS = {
    spin_tick     = "rbxassetid://5801556929",  -- tick da roleta (clique rapido)
    spin_start    = "rbxassetid://5801556929",  -- inicio do giro
    reveal_common  = "rbxassetid://9125402735", -- reveal comum
    reveal_rare    = "rbxassetid://9125402735", -- reveal raro
    reveal_epic    = "rbxassetid://9125402735", -- reveal epico (vine boom)
    reveal_legend  = "rbxassetid://9125402735", -- reveal lendario
    reveal_divine  = "rbxassetid://9125402735", -- reveal divino (WHAT THE HELL)
    buy_upgrade    = "rbxassetid://5801556929", -- compra de upgrade
    event_start    = "rbxassetid://5801556929", -- inicio de evento
    coin_collect   = "rbxassetid://5801556929", -- coleta de moedas
    mystery_box    = "rbxassetid://5801556929", -- mystery box aparece
    button_click   = "rbxassetid://5801556929", -- clique de botao UI
}

-- Cache de sons criados
local soundInstances = {}

-- ============================================================
-- Cria ou reutiliza instancia de som
-- ============================================================
local function getSound(id, volume, pitch)
    if not soundInstances[id] then
        local sound = Instance.new("Sound")
        sound.SoundId  = id
        sound.Volume   = volume or 1
        sound.RollOffMaxDistance = 100
        sound.Parent   = SoundService
        soundInstances[id] = sound
    end
    local s = soundInstances[id]
    s.Volume    = volume or 1
    s.PlaybackSpeed = pitch or 1
    return s
end

-- ============================================================
-- Toca som de tick da roleta (chamado varias vezes durante animacao)
-- ============================================================
function SoundManager.PlaySpinTick()
    local s = getSound(SOUND_IDS.spin_tick, 0.5, 1 + math.random() * 0.3)
    s:Play()
end

-- ============================================================
-- Toca som de reveal baseado na raridade
-- ============================================================
function SoundManager.PlayReveal(rarityName)
    local soundMap = {
        Common    = SOUND_IDS.reveal_common,
        Uncommon  = SOUND_IDS.reveal_rare,
        Rare      = SOUND_IDS.reveal_rare,
        Epic      = SOUND_IDS.reveal_epic,
        Legendary = SOUND_IDS.reveal_legend,
        Divine    = SOUND_IDS.reveal_divine,
    }

    local soundId = soundMap[rarityName] or SOUND_IDS.reveal_common
    local volumes = { Common=0.5, Uncommon=0.6, Rare=0.7, Epic=0.9, Legendary=1, Divine=1 }
    local pitches = { Common=1, Uncommon=1, Rare=0.95, Epic=0.9, Legendary=0.85, Divine=0.8 }

    local s = getSound(soundId, volumes[rarityName] or 0.5, pitches[rarityName] or 1)
    s:Play()
end

-- ============================================================
-- Toca som de compra de upgrade
-- ============================================================
function SoundManager.PlayUpgradeBuy()
    local s = getSound(SOUND_IDS.buy_upgrade, 0.7, 1.2)
    s:Play()
end

-- ============================================================
-- Toca som de inicio de evento
-- ============================================================
function SoundManager.PlayEventStart()
    local s = getSound(SOUND_IDS.event_start, 0.8, 1)
    s:Play()
end

-- ============================================================
-- Toca som de botao
-- ============================================================
function SoundManager.PlayButton()
    local s = getSound(SOUND_IDS.button_click, 0.4, 1 + math.random() * 0.1)
    s:Play()
end

-- ============================================================
-- Toca som de mystery box
-- ============================================================
function SoundManager.PlayMysteryBox()
    local s = getSound(SOUND_IDS.mystery_box, 1, 1)
    s:Play()
end

return SoundManager
