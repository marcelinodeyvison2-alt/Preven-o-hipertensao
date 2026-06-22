-- GameConfig.lua
-- Global game settings and constants shared between client and server.

local GameConfig = {}

GameConfig.DataStoreName    = "CaptureUmBrainrot_v1"
GameConfig.BrainrotLifetime = 60     -- seconds before a brainrot auto-despawns
GameConfig.BrainrotSize     = Vector3.new(4, 4, 4)
GameConfig.SpawnHeightOffset = 5     -- studs above the area floor
GameConfig.MaxInventorySize = 200

-- How often (seconds) the ranking board surface GUI refreshes
GameConfig.RankingRefreshRate = 15

-- Free Roblox sound asset IDs
GameConfig.Sounds = {
    CaptureComum    = "rbxassetid://4590662766",
    CaptureRaro     = "rbxassetid://5982975456",
    CaptureLendario = "rbxassetid://6518811702",
    Sell            = "rbxassetid://4590662766",
    AreaUnlock      = "rbxassetid://5982975456",
    Error           = "rbxassetid://9113553526",
    Notification    = "rbxassetid://4590662766",
}

-- Which sound plays when a rarity is captured
GameConfig.RarityCaptureSound = {
    Comum    = "CaptureComum",
    Incomum  = "CaptureComum",
    Raro     = "CaptureRaro",
    Epico    = "CaptureRaro",
    Lendario = "CaptureLendario",
    Secreto  = "CaptureLendario",
}

-- UI palette
GameConfig.UIColors = {
    Background = Color3.fromRGB(15,  15,  30),
    Panel      = Color3.fromRGB(25,  25,  45),
    Accent     = Color3.fromRGB(100, 80,  255),
    Gold       = Color3.fromRGB(255, 215, 0),
    Success    = Color3.fromRGB(50,  220, 100),
    Error      = Color3.fromRGB(255, 70,  70),
    Text       = Color3.fromRGB(240, 240, 255),
    TextDim    = Color3.fromRGB(160, 160, 190),
}

-- Rarity display colors (mirrors BrainrotConfig but available client-side easily)
GameConfig.RarityColors = {
    Comum    = Color3.fromRGB(200, 200, 200),
    Incomum  = Color3.fromRGB(100, 220, 100),
    Raro     = Color3.fromRGB(80,  130, 255),
    Epico    = Color3.fromRGB(180, 50,  255),
    Lendario = Color3.fromRGB(255, 210, 0),
    Secreto  = Color3.fromRGB(255, 50,  50),
}

-- Human-readable rarity names
GameConfig.RarityNames = {
    Comum    = "Comum",
    Incomum  = "Incomum",
    Raro     = "Raro",
    Epico    = "Épico",
    Lendario = "Lendário",
    Secreto  = "Secreto",
}

-- Notification types
GameConfig.NotifType = {
    Info    = "Info",
    Success = "Success",
    Error   = "Error",
    Rare    = "Rare",
}

return GameConfig
