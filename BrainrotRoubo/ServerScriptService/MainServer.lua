-- Script: ServerScriptService > MainServer
-- Sistema completo: inventário, pets, prestígio, conquistas, battlepass, trocas, anti-cheat, admin, VIP

local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local RunService         = game:GetService("RunService")
local DataStoreService   = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local DataStore    = DataStoreService:GetDataStore("BrainrotAuraV5")
local LB_Rebirths  = DataStoreService:GetOrderedDataStore("LB_Rebirths_v1")
local LB_Stolen    = DataStoreService:GetOrderedDataStore("LB_Stolen_v1")

-- =====================================================
--  REMOTES
-- =====================================================
local RemoteFolder = Instance.new("Folder")
RemoteFolder.Name = "Remotes"; RemoteFolder.Parent = ReplicatedStorage

local function makeRE(name)
    local re = Instance.new("RemoteEvent"); re.Name = name; re.Parent = RemoteFolder; return re
end
local function makeRF(name)
    local rf = Instance.new("RemoteFunction"); rf.Name = name; rf.Parent = RemoteFolder; return rf
end

local StealEvent        = makeRE("StealBrainrot")
local UpdateAuraRE      = makeRE("UpdateAura")
local NotifyRE          = makeRE("Notify")
local RebirthEvent      = makeRE("Rebirth")
local IndexUpdateRE     = makeRE("IndexUpdate")
local GlobalAnnounceRE  = makeRE("GlobalAnnounce")
local BuyUpgradeEvent   = makeRE("BuyUpgrade")
local ClaimMissionEvent = makeRE("ClaimMission")
local MissionUpdateRE   = makeRE("MissionUpdate")
-- Novos
local CollectEvent      = makeRE("CollectBrainrot")
local InventoryUpdateRE = makeRE("InventoryUpdate")
local CombineEvent      = makeRE("CombineItems")
local TradeProposeEvent = makeRE("TradePropose")
local TradeRespondEvent = makeRE("TradeRespond")
local TradeOfferRE      = makeRE("TradeOffer")
local TradeResultRE     = makeRE("TradeResult")
local BuyPetEvent       = makeRE("BuyPet")
local EquipPetEvent     = makeRE("EquipPet")
local PetUpdateRE       = makeRE("PetUpdate")
local PrestigeEvent     = makeRE("Prestige")
local AchievementRE     = makeRE("AchievementUnlock")
local TitleChangeEvent  = makeRE("TitleChange")
local BiomeUpdateRE     = makeRE("BiomeUpdate")
local AdminEvent        = makeRE("AdminCommand")
local BattlepassRE      = makeRE("BattlepassUpdate")
local ClaimBPEvent      = makeRE("ClaimBattlepass")
local LeaderboardRE     = makeRE("LeaderboardUpdate")
local LeaderboardRF     = makeRF("GetLeaderboard")
local EventUpdateRE     = makeRE("EventUpdate")

-- =====================================================
--  MUNDO
-- =====================================================
local BrainrotsFolder = Instance.new("Folder")
BrainrotsFolder.Name = "Brainrots"; BrainrotsFolder.Parent = workspace

local BaseOccupied      = {}
local globalSpawnCount  = 0
local currentInnerBases = {9, 10, 11, 12}
local tradeIdCounter    = 0
local PendingTrades     = {}

-- =====================================================
--  DADOS DOS JOGADORES
-- =====================================================
local PlayerData    = {}
local StealCooldown = {}  -- anti-cheat

local function defaultData()
    return {
        aura          = 0,
        rebirths      = 0,
        totalStolen   = 0,
        prestige      = 0,
        index         = { brainrots={}, mutations={} },
        upgrades      = { stealRange=0, walkSpeed=0, auraBonus=0 },
        missionData   = nil,
        inventory     = {},
        nextItemId    = 0,
        pets          = {},
        activePet     = nil,
        achievements  = {},
        unlockedTitles= {},
        equippedTitle = nil,
        battlepass    = { xp=0, level=0, claimed={} },
        isVIP         = false,
        hasSeenTutorial = false,
    }
end

-- =====================================================
--  HELPERS AURA / REBIRTH
-- =====================================================
local function getAuraCap(rb, prestige)
    local base = GameConfig.BASE_AURA_CAP * (GameConfig.AURA_CAP_MULTIPLIER ^ rb)
    local pvip  = prestige or 0
    return math.floor(base * (GameConfig.PRESTIGE_MULTIPLIER ^ pvip))
end
local function getRebirthCost(rb) return math.floor(getAuraCap(rb,0) * GameConfig.REBIRTH_COST_FRACTION) end
local function getAuraMultiplier(rb) return GameConfig.AURA_GAIN_MULTIPLIER ^ rb end
local function getPrestigeMult(p) return GameConfig.PRESTIGE_MULTIPLIER ^ (p or 0) end

local function formatBig(n)
    if n >= 1e12 then return string.format("%.1fT",n/1e12) end
    if n >= 1e9  then return string.format("%.1fB",n/1e9)  end
    if n >= 1e6  then return string.format("%.1fM",n/1e6)  end
    if n >= 1000 then return string.format("%.1fK",n/1000) end
    return tostring(math.floor(n))
end

-- =====================================================
--  HELPERS UPGRADES
-- =====================================================
local function getUpgLevel(data, id) return (data.upgrades and data.upgrades[id]) or 0 end

local function getStealRange(data)
    local lv = getUpgLevel(data,"stealRange")
    if lv == 0 then return GameConfig.STEAL_RANGE end
    for _, u in ipairs(GameConfig.UPGRADES) do
        if u.id=="stealRange" then return u.values[math.min(lv,u.maxLevel)] end
    end
    return GameConfig.STEAL_RANGE
end
local function getAuraBonusMult(data)
    local lv = getUpgLevel(data,"auraBonus")
    if lv == 0 then return 1.0 end
    for _, u in ipairs(GameConfig.UPGRADES) do
        if u.id=="auraBonus" then return u.values[math.min(lv,u.maxLevel)] end
    end
    return 1.0
end
local function getWalkSpeed(data)
    local lv = getUpgLevel(data,"walkSpeed")
    if lv == 0 then return 16 end
    for _, u in ipairs(GameConfig.UPGRADES) do
        if u.id=="walkSpeed" then return u.values[math.min(lv,u.maxLevel)] end
    end
    return 16
end
local function applyUpgradesToPlayer(player, data)
    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = getWalkSpeed(data) end
end

-- =====================================================
--  HELPERS PETS
-- =====================================================
local function getPetAuraBonus(data)
    if not data.activePet then return 1.0 end
    for _, p in ipairs(GameConfig.PETS) do
        if p.id == data.activePet then return 1.0 + p.auraBonus end
    end
    return 1.0
end
local function getPetRarityBonus(data)
    if not data.activePet then return 0 end
    for _, p in ipairs(GameConfig.PETS) do
        if p.id == data.activePet then return p.rarityBonus end
    end
    return 0
end

-- =====================================================
--  HELPERS MISSÕES
-- =====================================================
local function getMissionDay() return math.floor(os.time()/86400) end
local function pickDailyMissions()
    local pool = {}
    for i=1,#GameConfig.DAILY_MISSIONS do table.insert(pool,GameConfig.DAILY_MISSIONS[i].id) end
    for i=#pool,2,-1 do local j=math.random(1,i); pool[i],pool[j]=pool[j],pool[i] end
    return {pool[1],pool[2],pool[3]}
end
local function refreshMissions(data)
    local today = getMissionDay()
    if not data.missionData or data.missionData.day ~= today then
        data.missionData = { day=today, active=pickDailyMissions(), progress={}, claimed={} }
    end
end
local function advanceMission(data, mType, extra)
    local md = data.missionData; if not md then return false end
    local changed = false
    for _, mId in ipairs(md.active) do
        if not md.claimed[mId] then
            for _, mission in ipairs(GameConfig.DAILY_MISSIONS) do
                if mission.id == mId then
                    local prog = md.progress[mId] or 0
                    if prog < mission.target then
                        local adv = false
                        if mission.type=="steal" and mType=="steal" then adv=true
                        elseif mission.type=="rarityMin" and mType=="steal" then
                            local rank = GameConfig.RARITY_RANK[extra.rarity] or 0
                            if rank >= mission.rarityMin then adv=true end
                        elseif mission.type=="mutation" and mType=="steal" then
                            if extra.mutation==mission.mutation then adv=true end
                        elseif mission.type=="rebirth" and mType=="rebirth" then adv=true
                        end
                        if adv then md.progress[mId]=prog+1; changed=true end
                    end
                end
            end
        end
    end
    return changed
end

-- =====================================================
--  CONQUISTAS
-- =====================================================
local function checkAchievements(player, data, context)
    local unlocked = {}
    for _, ach in ipairs(GameConfig.ACHIEVEMENTS) do
        if not data.achievements[ach.id] then
            local ok = false
            if     ach.type=="totalStolen" and data.totalStolen >= ach.threshold then ok=true
            elseif ach.type=="rebirths"    and data.rebirths    >= ach.threshold then ok=true
            elseif ach.type=="prestige"    and (data.prestige or 0) >= ach.threshold then ok=true
            elseif ach.type=="rarity"   and context and context.rarity   == ach.rarity   then ok=true
            elseif ach.type=="mutation" and context and context.mutation  == ach.mutation then ok=true
            end
            if ok then
                data.achievements[ach.id] = true
                table.insert(unlocked, ach)
                for _, title in ipairs(GameConfig.TITLES) do
                    if title.unlock == ach.id then
                        if not data.unlockedTitles then data.unlockedTitles={} end
                        data.unlockedTitles[title.id] = true
                    end
                end
            end
        end
    end
    if #unlocked > 0 then AchievementRE:FireClient(player, unlocked) end
end

-- =====================================================
--  BATTLEPASS
-- =====================================================
local function addBPXP(player, data, xp)
    local bp = data.battlepass
    if not bp then bp = {xp=0,level=0,claimed={}}; data.battlepass=bp end
    if bp.level >= GameConfig.BATTLEPASS_LEVELS then return end
    bp.xp = bp.xp + xp
    local leveled = false
    while bp.xp >= GameConfig.BATTLEPASS_XP_PER_LEVEL and bp.level < GameConfig.BATTLEPASS_LEVELS do
        bp.xp    = bp.xp - GameConfig.BATTLEPASS_XP_PER_LEVEL
        bp.level = bp.level + 1
        leveled  = true
    end
    BattlepassRE:FireClient(player, bp)
    if leveled then
        NotifyRE:FireClient(player,
            string.format("✦ Battlepass Nível %d!", bp.level),
            Color3.fromRGB(255, 200, 0))
    end
end

-- =====================================================
--  LEADERBOARD
-- =====================================================
local function updateLeaderboard(player, data)
    pcall(function()
        LB_Rebirths:SetAsync("P_"..player.UserId, data.rebirths)
        LB_Stolen:SetAsync("P_"..player.UserId,   data.totalStolen)
    end)
end

local function getTopLeaderboard(dsName, count)
    local ds = dsName=="rebirths" and LB_Rebirths or LB_Stolen
    local ok, pages = pcall(function()
        return ds:GetSortedAsync(false, count)
    end)
    if not ok then return {} end
    local top = {}
    local ok2, data = pcall(function() return pages:GetCurrentPage() end)
    if not ok2 then return {} end
    for _, entry in ipairs(data) do
        local name = "Jogador"
        local ok3, p = pcall(function()
            return Players:GetNameFromUserIdAsync(tonumber(entry.key:sub(3)))
        end)
        if ok3 then name = p end
        table.insert(top, {name=name, value=entry.value})
    end
    return top
end

LeaderboardRF.OnServerInvoke = function(player, lbType)
    return getTopLeaderboard(lbType, 10)
end

-- =====================================================
--  VIP / ADMIN
-- =====================================================
local function checkVIP(player)
    local ok, has = pcall(function()
        return MarketplaceService:UserOwnsGamePassAsync(player.UserId, GameConfig.VIP_GAMEPASS_ID)
    end)
    return ok and has
end
local function isAdmin(player)
    for _, id in ipairs(GameConfig.ADMIN_IDS) do
        if id == player.UserId then return true end
    end
    return false
end

-- =====================================================
--  BUILD UPDATE PAYLOAD
-- =====================================================
local function buildUpdatePayload(data)
    local rb = data.rebirths
    local pr = data.prestige or 0
    return {
        aura            = data.aura,
        auraCap         = getAuraCap(rb, pr),
        rebirths        = rb,
        prestige        = pr,
        multiplier      = getAuraMultiplier(rb),
        prestigeMult    = getPrestigeMult(pr),
        rebirthCost     = getRebirthCost(rb),
        totalStolen     = data.totalStolen or 0,
        upgrades        = data.upgrades or {},
        activePet       = data.activePet,
        isVIP           = data.isVIP or false,
        equippedTitle   = data.equippedTitle,
        hasSeenTutorial = data.hasSeenTutorial or false,
    }
end

-- =====================================================
--  DATASTORE
-- =====================================================
local function loadData(player)
    local ok, saved = pcall(function() return DataStore:GetAsync("P_"..player.UserId) end)
    local data = (ok and saved) and saved or defaultData()
    if not data.index       then data.index       = {brainrots={},mutations={}} end
    if not data.upgrades    then data.upgrades    = {stealRange=0,walkSpeed=0,auraBonus=0} end
    if not data.inventory   then data.inventory   = {} end
    if not data.pets        then data.pets        = {} end
    if not data.achievements then data.achievements = {} end
    if not data.unlockedTitles then data.unlockedTitles = {} end
    if not data.battlepass  then data.battlepass  = {xp=0,level=0,claimed={}} end
    if not data.prestige    then data.prestige    = 0 end
    if not data.nextItemId  then data.nextItemId  = 0 end
    refreshMissions(data)
    -- Verifica VIP
    data.isVIP = checkVIP(player)
    PlayerData[player.UserId] = data
    UpdateAuraRE:FireClient(player, buildUpdatePayload(data))
    IndexUpdateRE:FireClient(player, data.index)
    MissionUpdateRE:FireClient(player, data.missionData)
    InventoryUpdateRE:FireClient(player, data.inventory)
    PetUpdateRE:FireClient(player, { owned=data.pets, active=data.activePet })
    BattlepassRE:FireClient(player, data.battlepass)
    AchievementRE:FireClient(player, {})  -- envia achievements atuais
    EventUpdateRE:FireClient(player, GameConfig.CURRENT_EVENT)
    BiomeUpdateRE:FireClient(player, currentInnerBases)
end

local function saveData(player)
    local data = PlayerData[player.UserId]
    if not data then return end
    pcall(function() DataStore:SetAsync("P_"..player.UserId, data) end)
end

local function setupLeaderstats(player)
    local ls = Instance.new("Folder"); ls.Name="leaderstats"; ls.Parent=player
    local av = Instance.new("NumberValue"); av.Name="Aura";     av.Value=0; av.Parent=ls
    local rv = Instance.new("NumberValue"); rv.Name="Rebirths"; rv.Value=0; rv.Parent=ls
    local pv = Instance.new("NumberValue"); pv.Name="Prestígio";pv.Value=0; pv.Parent=ls
end
local function updateLeaderstats(player)
    local data=PlayerData[player.UserId]; if not data then return end
    local ls=player:FindFirstChild("leaderstats"); if not ls then return end
    ls.Aura.Value      = data.aura
    ls.Rebirths.Value  = data.rebirths
    ls["Prestígio"].Value = data.prestige or 0
end

-- =====================================================
--  MUTAÇÃO / BRAINROT
-- =====================================================
local MUTATION_TOTAL_WEIGHT = 0
for _, m in ipairs(GameConfig.MUTATIONS) do MUTATION_TOTAL_WEIGHT = MUTATION_TOTAL_WEIGHT + m.weight end

local function pickMutation(forceLua)
    if forceLua then
        for _, m in ipairs(GameConfig.MUTATIONS) do if m.name=="Lua de Sangue" then return m end end
    end
    local roll = math.random(1, MUTATION_TOTAL_WEIGHT); local acc=0
    for _, m in ipairs(GameConfig.MUTATIONS) do
        if m.weight>0 then acc=acc+m.weight; if roll<=acc then return m end end
    end
    return GameConfig.MUTATIONS[1]
end

local function isInnerBase(baseIdx)
    for _, i in ipairs(currentInnerBases) do if i==baseIdx then return true end end
    return false
end

local function pickBrainrotType(baseIdx, petRarityBonus)
    local weights = {}; local total = 0
    local inner   = isInnerBase(baseIdx)
    local evBonus = GameConfig.CURRENT_EVENT and GameConfig.CURRENT_EVENT.rarBonus or 1
    for rarity, w in pairs(GameConfig.RARITY_WEIGHTS) do
        local rank = GameConfig.RARITY_RANK[rarity] or 1
        local adj  = w
        if inner    and rank >= 4 then adj = adj * 2           end
        if evBonus  and rank >= 4 then adj = math.floor(adj * evBonus) end
        if petRarityBonus and rank >= 4 then adj = math.floor(adj * (1 + petRarityBonus)) end
        weights[rarity] = adj; total = total + adj
    end
    local roll = math.random(1, total); local acc = 0; local chosen = "Comum"
    for rarity, w in pairs(weights) do
        acc = acc + w; if roll <= acc then chosen = rarity; break end
    end
    local pool = {}
    for _, bt in ipairs(GameConfig.BRAINROT_TYPES) do
        if bt.rarity == chosen then table.insert(pool, bt) end
    end
    if #pool == 0 then return GameConfig.BRAINROT_TYPES[1] end
    return pool[math.random(1,#pool)]
end

-- =====================================================
--  SPAWN DE BRAINROT
-- =====================================================
local RARE_RANK   = 4   -- Épico
local DRAMA_RANK  = 7   -- God ou melhor dispara câmera shake

local function getFreeBases()
    local free = {}
    for i=1,#GameConfig.BASE_POSITIONS do if not BaseOccupied[i] then table.insert(free,i) end end
    return free
end

local function spawnBrainrot()
    local freeBases = getFreeBases(); if #freeBases == 0 then return end
    globalSpawnCount = globalSpawnCount + 1
    local isLua = (globalSpawnCount % GameConfig.LUA_DE_SANGUE_INTERVAL == 0)

    local baseIdx = freeBases[math.random(1,#freeBases)]
    local basePos = GameConfig.BASE_POSITIONS[baseIdx]
    local bt      = pickBrainrotType(baseIdx, 0)
    local mut     = pickMutation(isLua)

    local rarColor = GameConfig.RARITY_COLORS[bt.rarity]
    local spawnY   = basePos.Y + 4

    local part = Instance.new("Part")
    part.Name       = "BrainrotPart"; part.Shape = Enum.PartType.Ball
    part.Size       = Vector3.new(3.5,3.5,3.5)
    part.Position   = Vector3.new(basePos.X, spawnY, basePos.Z)
    part.Anchored   = true; part.CanCollide = false
    part.Color      = isLua and Color3.fromRGB(200,0,0) or rarColor
    part.Material   = Enum.Material.Neon; part.CastShadow = false
    part.Parent     = BrainrotsFolder

    local light = Instance.new("PointLight")
    light.Color      = isLua and Color3.fromRGB(255,0,0) or rarColor
    light.Brightness = isLua and 10 or 4; light.Range = isLua and 35 or 18
    light.Parent     = part

    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0,240,0,isLua and 100 or 80); bb.StudsOffset=Vector3.new(0,4,0); bb.Parent=part

    local function addLabel(yPos,h,text,color,bold)
        local l=Instance.new("TextLabel"); l.Size=UDim2.new(1,0,h,0); l.Position=UDim2.new(0,0,yPos,0)
        l.BackgroundTransparency=1; l.Text=text; l.TextColor3=color
        l.TextStrokeTransparency=0; l.TextStrokeColor3=Color3.fromRGB(0,0,0)
        l.TextScaled=true; l.Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham; l.Parent=bb
    end
    addLabel(0,0.38,isLua and("🌑 "..bt.name.." 🌑")or bt.name,Color3.fromRGB(255,255,255),true)
    addLabel(0.38,0.30,"[ "..bt.rarity.." ]",rarColor,false)
    addLabel(0.68,0.32,isLua and"✦ LUA DE SANGUE ×20 ✦"or("✦ "..mut.name.."  ×"..mut.multiplier),mut.color,true)

    local meta=Instance.new("Folder"); meta.Name="Meta"; meta.Parent=part
    local function addVal(cls,name,val)
        local v=Instance.new(cls); v.Name=name; v.Value=val; v.Parent=meta
    end
    addVal("StringValue","BrainrotName",bt.name); addVal("StringValue","Rarity",bt.rarity)
    addVal("IntValue","AuraValue",bt.baseAura);   addVal("StringValue","MutationName",mut.name)
    addVal("IntValue","MutationMult",mut.multiplier); addVal("IntValue","BaseIndex",baseIdx)

    BaseOccupied[baseIdx] = part
    local bp2 = workspace:FindFirstChild("Base_"..baseIdx)
    if bp2 then local ind=bp2:FindFirstChild("Indicator"); if ind then ind.Color=isLua and Color3.fromRGB(255,0,0) or rarColor end end

    local baseY=spawnY; local t=0; local conn
    conn = RunService.Heartbeat:Connect(function(dt)
        t=t+dt
        if not part or not part.Parent then conn:Disconnect(); return end
        part.CFrame = CFrame.new(basePos.X, baseY+math.sin(t*1.8)*0.7, basePos.Z)*CFrame.Angles(0,t*0.9,0)
    end)

    -- Anúncios
    if isLua then
        GlobalAnnounceRE:FireAllClients(
            string.format("🌑 LUA DE SANGUE em %s!  [%s]  ×20 Aura!", GameConfig.BASE_NAMES[baseIdx] or "Base "..baseIdx, bt.rarity),
            Color3.fromRGB(220,0,0))
    else
        local rank = GameConfig.RARITY_RANK[bt.rarity] or 0
        if rank >= RARE_RANK then
            local dramatic = rank >= DRAMA_RANK
            GlobalAnnounceRE:FireAllClients(
                string.format("%s %s [%s] em %s!", dramatic and"⚡ ÉPICO EXTREMO!"or"✦", bt.name, bt.rarity, GameConfig.BASE_NAMES[baseIdx] or"Base "..baseIdx),
                rarColor, dramatic)
        end
    end

    task.delay(GameConfig.BRAINROT_LIFETIME, function()
        if part and part.Parent then
            conn:Disconnect(); BaseOccupied[baseIdx]=nil
            local bp3=workspace:FindFirstChild("Base_"..baseIdx)
            if bp3 then local ind=bp3:FindFirstChild("Indicator"); if ind then ind.Color=Color3.fromRGB(60,60,80) end end
            part:Destroy()
        end
    end)
end

-- =====================================================
--  EVENTO: ROUBAR BRAINROT (aura)
-- =====================================================
StealEvent.OnServerEvent:Connect(function(player, brainrotPart)
    -- Anti-cheat: cooldown de 0.5s
    local uid = player.UserId
    local now = tick()
    if StealCooldown[uid] and now - StealCooldown[uid] < 0.5 then return end
    StealCooldown[uid] = now

    local data = PlayerData[uid]; if not data then return end
    if not brainrotPart or not brainrotPart.Parent or brainrotPart.Parent~=BrainrotsFolder then return end

    local char = player.Character; if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart"); if not root then return end
    if (root.Position-brainrotPart.Position).Magnitude > getStealRange(data)+4 then
        NotifyRE:FireClient(player,"Muito longe!",Color3.fromRGB(255,80,80)); return
    end

    local meta=brainrotPart:FindFirstChild("Meta"); if not meta then return end
    local bName   = meta:FindFirstChild("BrainrotName") and meta.BrainrotName.Value or "?"
    local rarity  = meta:FindFirstChild("Rarity")       and meta.Rarity.Value       or "Comum"
    local baseAura= meta:FindFirstChild("AuraValue")    and meta.AuraValue.Value    or 10
    local mutName = meta:FindFirstChild("MutationName") and meta.MutationName.Value or "Básico"
    local mutMult = meta:FindFirstChild("MutationMult") and meta.MutationMult.Value or 1
    local baseIdx = meta:FindFirstChild("BaseIndex")    and meta.BaseIndex.Value    or 0

    local rebirthMult = getAuraMultiplier(data.rebirths)
    local bonusMult   = getAuraBonusMult(data)
    local petMult     = getPetAuraBonus(data)
    local prestige    = getPrestigeMult(data.prestige)
    local eventBonus  = GameConfig.CURRENT_EVENT and GameConfig.CURRENT_EVENT.auraBonus or 1
    local vipBonus    = data.isVIP and GameConfig.VIP_AURA_BONUS or 1

    local totalGain = math.floor(baseAura * mutMult * rebirthMult * bonusMult * petMult * prestige * eventBonus * vipBonus)
    local cap       = getAuraCap(data.rebirths, data.prestige)
    local newAura   = math.min(data.aura + totalGain, cap)
    local actual    = newAura - data.aura
    if actual <= 0 then
        NotifyRE:FireClient(player,"Aura no limite! Faca rebirth.",Color3.fromRGB(255,200,0)); return
    end

    data.aura = newAura; data.totalStolen = (data.totalStolen or 0)+1

    -- Index
    local idx=data.index
    if not idx.brainrots[bName] then idx.brainrots[bName]={count=0,bestMutation="Básico"} end
    idx.brainrots[bName].count = idx.brainrots[bName].count+1
    local prev=1
    for _,m in ipairs(GameConfig.MUTATIONS) do if m.name==idx.brainrots[bName].bestMutation then prev=m.multiplier;break end end
    if mutMult>prev then idx.brainrots[bName].bestMutation=mutName end
    idx.mutations[mutName] = (idx.mutations[mutName] or 0)+1

    -- Inventário (se tiver espaço)
    if #(data.inventory or {}) < GameConfig.INVENTORY_MAX_SLOTS then
        data.nextItemId = (data.nextItemId or 0)+1
        table.insert(data.inventory, {id=data.nextItemId, name=bName, rarity=rarity, mutation=mutName})
        InventoryUpdateRE:FireClient(player, data.inventory)
    end

    -- Missões
    local missionChanged = advanceMission(data,"steal",{rarity=rarity,mutation=mutName})

    -- Conquistas
    checkAchievements(player,data,{rarity=rarity,mutation=mutName})

    -- Battlepass XP
    addBPXP(player, data, GameConfig.BATTLEPASS_XP_STEAL)

    -- Remove brainrot
    if baseIdx>0 then
        BaseOccupied[baseIdx]=nil
        local bp2=workspace:FindFirstChild("Base_"..baseIdx)
        if bp2 then local ind=bp2:FindFirstChild("Indicator"); if ind then ind.Color=Color3.fromRGB(60,60,80) end end
    end
    brainrotPart:Destroy()

    local rarColor = GameConfig.RARITY_COLORS[rarity] or Color3.fromRGB(255,255,255)
    local mutColor = Color3.fromRGB(255,255,255)
    for _,m in ipairs(GameConfig.MUTATIONS) do if m.name==mutName then mutColor=m.color;break end end
    local mutLine = (mutName~="Básico") and ("  ["..mutName.." ×"..mutMult.."]") or ""

    NotifyRE:FireClient(player,
        string.format("+%s Aura  •  %s  [%s]%s", formatBig(actual), bName, rarity, mutLine),
        mutName=="Lua de Sangue" and Color3.fromRGB(220,0,0) or rarColor)

    UpdateAuraRE:FireClient(player, buildUpdatePayload(data))
    IndexUpdateRE:FireClient(player, data.index)
    if missionChanged then MissionUpdateRE:FireClient(player,data.missionData) end
    updateLeaderstats(player)
    updateLeaderboard(player, data)
end)

-- =====================================================
--  EVENTO: REBIRTH
-- =====================================================
RebirthEvent.OnServerEvent:Connect(function(player)
    local data=PlayerData[player.UserId]; if not data then return end
    local cost=getRebirthCost(data.rebirths)
    if data.aura < cost then
        NotifyRE:FireClient(player,string.format("Precisa de %s aura!",formatBig(cost)),Color3.fromRGB(255,80,80)); return
    end
    data.rebirths=data.rebirths+1; data.aura=0
    advanceMission(data,"rebirth",{})
    checkAchievements(player,data,{})
    addBPXP(player,data,GameConfig.BATTLEPASS_XP_REBIRTH)
    NotifyRE:FireClient(player,
        string.format("RENASCIMENTO #%d!  Cap: %s  Mult: x%s",data.rebirths,formatBig(getAuraCap(data.rebirths,data.prestige)),formatBig(getAuraMultiplier(data.rebirths))),
        Color3.fromRGB(255,215,0))
    UpdateAuraRE:FireClient(player,buildUpdatePayload(data))
    MissionUpdateRE:FireClient(player,data.missionData)
    updateLeaderstats(player); updateLeaderboard(player,data)
    applyUpgradesToPlayer(player,data); saveData(player)
end)

-- =====================================================
--  EVENTO: PRESTÍGIO
-- =====================================================
PrestigeEvent.OnServerEvent:Connect(function(player)
    local data=PlayerData[player.UserId]; if not data then return end
    if data.rebirths < GameConfig.MAX_REBIRTHS_FOR_PRESTIGE then
        NotifyRE:FireClient(player,string.format("Precisa de %d rebirths para prestigiar! (você tem %d)",GameConfig.MAX_REBIRTHS_FOR_PRESTIGE,data.rebirths),Color3.fromRGB(255,80,80)); return
    end
    if (data.prestige or 0) >= GameConfig.MAX_PRESTIGE then
        NotifyRE:FireClient(player,"Prestígio máximo atingido!",Color3.fromRGB(255,200,0)); return
    end
    data.prestige  = (data.prestige or 0)+1
    data.rebirths  = 0; data.aura = 0
    data.upgrades  = {stealRange=0,walkSpeed=0,auraBonus=0}
    -- Mantém: index, achievements, inventory, pets, battlepass, titles
    checkAchievements(player,data,{})
    addBPXP(player,data,GameConfig.BATTLEPASS_XP_PRESTIGE)
    NotifyRE:FireClient(player,
        string.format("✦ PRESTÍGIO %d! Mult permanente: ×%.1f",data.prestige,getPrestigeMult(data.prestige)),
        Color3.fromRGB(255,150,0))
    UpdateAuraRE:FireClient(player,buildUpdatePayload(data))
    updateLeaderstats(player); applyUpgradesToPlayer(player,data); saveData(player)
end)

-- =====================================================
--  EVENTO: COMPRAR UPGRADE
-- =====================================================
BuyUpgradeEvent.OnServerEvent:Connect(function(player, upgradeId)
    local data=PlayerData[player.UserId]; if not data then return end
    local upg=nil
    for _,u in ipairs(GameConfig.UPGRADES) do if u.id==upgradeId then upg=u;break end end
    if not upg then return end
    local lv=(data.upgrades and data.upgrades[upgradeId]) or 0
    if lv >= upg.maxLevel then NotifyRE:FireClient(player,upg.name.." já está no máximo!",Color3.fromRGB(255,200,0));return end
    local cost=upg.costs[lv+1]
    if data.aura<cost then NotifyRE:FireClient(player,"Aura insuficiente! Precisa de "..formatBig(cost),Color3.fromRGB(255,80,80));return end
    data.aura=data.aura-cost; data.upgrades[upgradeId]=lv+1
    NotifyRE:FireClient(player,string.format("%s %s → Nível %d!  (-%s aura)",upg.icon,upg.name,lv+1,formatBig(cost)),Color3.fromRGB(100,255,100))
    UpdateAuraRE:FireClient(player,buildUpdatePayload(data))
    updateLeaderstats(player); applyUpgradesToPlayer(player,data)
end)

-- =====================================================
--  EVENTO: CLAIM MISSÃO
-- =====================================================
ClaimMissionEvent.OnServerEvent:Connect(function(player, missionId)
    local data=PlayerData[player.UserId]; if not data or not data.missionData then return end
    local md=data.missionData
    local isActive=false
    for _,id in ipairs(md.active) do if id==missionId then isActive=true;break end end
    if not isActive or md.claimed[missionId] then return end
    local mission=nil
    for _,m in ipairs(GameConfig.DAILY_MISSIONS) do if m.id==missionId then mission=m;break end end
    if not mission then return end
    if (md.progress[missionId] or 0)<mission.target then NotifyRE:FireClient(player,"Missão incompleta!",Color3.fromRGB(255,80,80));return end
    md.claimed[missionId]=true
    data.aura=math.min(data.aura+mission.reward, getAuraCap(data.rebirths,data.prestige))
    NotifyRE:FireClient(player,string.format("✦ MISSÃO: %s! +%s aura!",mission.name,formatBig(mission.reward)),Color3.fromRGB(255,215,0))
    UpdateAuraRE:FireClient(player,buildUpdatePayload(data)); MissionUpdateRE:FireClient(player,md); updateLeaderstats(player)
end)

-- =====================================================
--  EVENTO: PETS
-- =====================================================
BuyPetEvent.OnServerEvent:Connect(function(player, petId)
    local data=PlayerData[player.UserId]; if not data then return end
    local petCfg=nil
    for _,p in ipairs(GameConfig.PETS) do if p.id==petId then petCfg=p;break end end
    if not petCfg then return end
    for _,id in ipairs(data.pets) do if id==petId then NotifyRE:FireClient(player,"Você já tem esse pet!",Color3.fromRGB(255,200,0));return end end
    if data.aura<petCfg.cost then NotifyRE:FireClient(player,"Aura insuficiente! Precisa de "..formatBig(petCfg.cost),Color3.fromRGB(255,80,80));return end
    data.aura=data.aura-petCfg.cost; table.insert(data.pets,petId)
    NotifyRE:FireClient(player,petCfg.icon.." Pet "..petCfg.name.." adquirido! Equipe-o para usar.",Color3.fromRGB(150,255,150))
    UpdateAuraRE:FireClient(player,buildUpdatePayload(data)); PetUpdateRE:FireClient(player,{owned=data.pets,active=data.activePet}); updateLeaderstats(player)
end)

EquipPetEvent.OnServerEvent:Connect(function(player, petId)
    local data=PlayerData[player.UserId]; if not data then return end
    if petId == nil then data.activePet=nil
    else
        local owns=false
        for _,id in ipairs(data.pets) do if id==petId then owns=true;break end end
        if not owns then return end
        data.activePet = (data.activePet==petId) and nil or petId
    end
    PetUpdateRE:FireClient(player,{owned=data.pets,active=data.activePet})
    UpdateAuraRE:FireClient(player,buildUpdatePayload(data))
    local name = data.activePet and data.activePet or "nenhum"
    NotifyRE:FireClient(player,"Pet ativo: "..name,Color3.fromRGB(200,255,200))
end)

-- =====================================================
--  EVENTO: COMBINAÇÃO DE BRAINROTS
-- =====================================================
CombineEvent.OnServerEvent:Connect(function(player, itemId1, itemId2)
    local data=PlayerData[player.UserId]; if not data then return end
    if itemId1==itemId2 then return end
    local item1,idx1,item2,idx2=nil,nil,nil,nil
    for i,item in ipairs(data.inventory or {}) do
        if item.id==itemId1 then item1=item;idx1=i
        elseif item.id==itemId2 then item2=item;idx2=i
        end
    end
    if not item1 or not item2 then return end
    if item1.name~=item2.name then NotifyRE:FireClient(player,"Combine apenas 2 brainrots IGUAIS!",Color3.fromRGB(255,80,80));return end
    local chance = GameConfig.COMBINE_CHANCE[item1.rarity] or 0
    if chance <= 0 then NotifyRE:FireClient(player,"Este brainrot não pode ser combinado!",Color3.fromRGB(255,80,80));return end
    -- Encontra próxima raridade
    local nextRarity=nil
    for i,r in ipairs(GameConfig.RARITY_ORDER) do
        if r==item1.rarity and GameConfig.RARITY_ORDER[i+1] then nextRarity=GameConfig.RARITY_ORDER[i+1];break end
    end
    -- Remove ambos
    local hi,lo=math.max(idx1,idx2),math.min(idx1,idx2)
    table.remove(data.inventory,hi); table.remove(data.inventory,lo)
    if math.random()<chance and nextRarity then
        local pool={}
        for _,bt in ipairs(GameConfig.BRAINROT_TYPES) do if bt.rarity==nextRarity then table.insert(pool,bt) end end
        if #pool>0 then
            local bt=pool[math.random(1,#pool)]
            data.nextItemId=(data.nextItemId or 0)+1
            table.insert(data.inventory,{id=data.nextItemId,name=bt.name,rarity=bt.rarity,mutation="Básico"})
            local rarColor=GameConfig.RARITY_COLORS[nextRarity] or Color3.fromRGB(255,255,255)
            NotifyRE:FireClient(player,string.format("✦ COMBINAÇÃO! → %s [%s]!",bt.name,nextRarity),rarColor)
            checkAchievements(player,data,{rarity=nextRarity})
        end
    else
        NotifyRE:FireClient(player,"❌ Combinação falhou! Os brainrots foram perdidos.",Color3.fromRGB(255,80,80))
    end
    InventoryUpdateRE:FireClient(player,data.inventory)
end)

-- =====================================================
--  EVENTO: TROCAS
-- =====================================================
TradeProposeEvent.OnServerEvent:Connect(function(fromPlayer, targetName, myItemId)
    local fromData=PlayerData[fromPlayer.UserId]; if not fromData then return end
    local toPlayer=nil
    for _,p in ipairs(Players:GetPlayers()) do
        if p.Name==targetName or p.DisplayName==targetName then toPlayer=p;break end
    end
    if not toPlayer or toPlayer==fromPlayer then NotifyRE:FireClient(fromPlayer,"Jogador não encontrado!",Color3.fromRGB(255,80,80));return end
    local myItem=nil
    for _,item in ipairs(fromData.inventory or {}) do if item.id==myItemId then myItem=item;break end end
    if not myItem then return end
    tradeIdCounter=tradeIdCounter+1
    local tid=tradeIdCounter
    PendingTrades[tid]={fromId=fromPlayer.UserId,toId=toPlayer.UserId,fromItemId=myItemId,fromItem=myItem,status="pending"}
    TradeOfferRE:FireClient(toPlayer,fromPlayer.DisplayName,myItem,tid)
    NotifyRE:FireClient(fromPlayer,"Proposta enviada para "..toPlayer.DisplayName.."!",Color3.fromRGB(100,200,100))
    task.delay(30,function()
        if PendingTrades[tid] and PendingTrades[tid].status=="pending" then
            PendingTrades[tid]=nil
            NotifyRE:FireClient(fromPlayer,"Proposta expirou.",Color3.fromRGB(180,180,180))
        end
    end)
end)

TradeRespondEvent.OnServerEvent:Connect(function(toPlayer, tid, accepted, theirItemId)
    local trade=PendingTrades[tid]; if not trade or trade.status~="pending" then return end
    if trade.toId~=toPlayer.UserId then return end
    local fromPlayer=Players:GetPlayerByUserId(trade.fromId)
    if not accepted then
        PendingTrades[tid]=nil
        if fromPlayer then NotifyRE:FireClient(fromPlayer,toPlayer.DisplayName.." recusou a troca.",Color3.fromRGB(255,80,80)) end
        TradeResultRE:FireClient(toPlayer,false,"Troca cancelada.")
        return
    end
    local fromData=PlayerData[trade.fromId]; local toData=PlayerData[toPlayer.UserId]
    if not fromData or not toData then return end
    local fromItem,fromIdx,toItem,toIdx=nil,nil,nil,nil
    for i,item in ipairs(fromData.inventory or {}) do if item.id==trade.fromItemId then fromItem=item;fromIdx=i;break end end
    for i,item in ipairs(toData.inventory or {}) do if item.id==theirItemId then toItem=item;toIdx=i;break end end
    if not fromItem or not toItem then TradeResultRE:FireClient(toPlayer,false,"Item não encontrado.");return end
    table.remove(fromData.inventory,fromIdx); table.insert(fromData.inventory,toItem)
    table.remove(toData.inventory,toIdx);   table.insert(toData.inventory,fromItem)
    PendingTrades[tid]=nil
    if fromPlayer then
        InventoryUpdateRE:FireClient(fromPlayer,fromData.inventory)
        NotifyRE:FireClient(fromPlayer,string.format("Troca! Você recebeu: %s [%s]",toItem.name,toItem.rarity),Color3.fromRGB(100,255,100))
    end
    InventoryUpdateRE:FireClient(toPlayer,toData.inventory)
    TradeResultRE:FireClient(toPlayer,true,string.format("Troca! Você recebeu: %s [%s]",fromItem.name,fromItem.rarity))
end)

-- =====================================================
--  EVENTO: BATTLEPASS CLAIM
-- =====================================================
ClaimBPEvent.OnServerEvent:Connect(function(player, level)
    local data=PlayerData[player.UserId]; if not data then return end
    local bp=data.battlepass; if not bp or bp.level<level then return end
    if bp.claimed[tostring(level)] then NotifyRE:FireClient(player,"Recompensa já resgatada!",Color3.fromRGB(255,200,0));return end
    local reward=GameConfig.BATTLEPASS_REWARDS[level]; if not reward then return end
    bp.claimed[tostring(level)]=true
    if reward.type=="aura" then
        data.aura=math.min(data.aura+reward.amount, getAuraCap(data.rebirths,data.prestige))
        UpdateAuraRE:FireClient(player,buildUpdatePayload(data))
    elseif reward.type=="pet" then
        local owns=false
        for _,id in ipairs(data.pets) do if id==reward.id then owns=true;break end end
        if not owns then table.insert(data.pets,reward.id) end
        PetUpdateRE:FireClient(player,{owned=data.pets,active=data.activePet})
    elseif reward.type=="title" then
        if not data.unlockedTitles then data.unlockedTitles={} end
        data.unlockedTitles[reward.id]=true
    end
    NotifyRE:FireClient(player,"🎁 Battlepass Nível "..level..": "..reward.name.."!",Color3.fromRGB(255,215,0))
    BattlepassRE:FireClient(player,bp); updateLeaderstats(player)
end)

-- =====================================================
--  EVENTO: TROCAR TÍTULO
-- =====================================================
TitleChangeEvent.OnServerEvent:Connect(function(player, titleId)
    local data=PlayerData[player.UserId]; if not data then return end
    if titleId and not data.unlockedTitles[titleId] then return end
    data.equippedTitle = titleId
    UpdateAuraRE:FireClient(player, buildUpdatePayload(data))
end)

-- =====================================================
--  EVENTO: ADMIN COMMAND
-- =====================================================
AdminEvent.OnServerEvent:Connect(function(player, cmd, arg1, arg2)
    if not isAdmin(player) then return end
    if cmd == "give" then
        local target=Players:FindFirstChild(arg1 or "")
        local amount=tonumber(arg2) or 0
        if target and PlayerData[target.UserId] then
            local d=PlayerData[target.UserId]
            d.aura=math.min(d.aura+amount, getAuraCap(d.rebirths,d.prestige))
            UpdateAuraRE:FireClient(target,buildUpdatePayload(d)); updateLeaderstats(target)
            NotifyRE:FireClient(player,"Dado "..formatBig(amount).." aura para "..target.Name,Color3.fromRGB(100,255,100))
        end
    elseif cmd == "kick" then
        local target=Players:FindFirstChild(arg1 or "")
        if target then target:Kick("Você foi kickado por um administrador.") end
    elseif cmd == "event" then
        -- /admin event on|off
        if arg1 == "on" then
            GameConfig.CURRENT_EVENT = { name="Evento Admin", icon="⭐", auraBonus=2, rarBonus=2, color=Color3.fromRGB(255,215,0) }
        else
            GameConfig.CURRENT_EVENT = nil
        end
        EventUpdateRE:FireAllClients(GameConfig.CURRENT_EVENT)
        NotifyRE:FireClient(player,"Evento "..(arg1=="on" and "ativado" or "desativado").."!",Color3.fromRGB(255,200,0))
    end
end)

-- =====================================================
--  TUTORIAL COMPLETO
-- =====================================================
local TutorialDoneEvent = makeRE("TutorialDone")
TutorialDoneEvent.OnServerEvent:Connect(function(player)
    local data=PlayerData[player.UserId]; if not data then return end
    data.hasSeenTutorial = true
end)

-- =====================================================
--  JOGADORES
-- =====================================================
Players.PlayerAdded:Connect(function(player)
    setupLeaderstats(player)
    loadData(player)
    updateLeaderstats(player)
    player.CharacterAdded:Connect(function()
        task.wait(1)
        local data=PlayerData[player.UserId]
        if data then applyUpgradesToPlayer(player,data) end
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    saveData(player); PlayerData[player.UserId]=nil; StealCooldown[player.UserId]=nil
end)

-- Auto-save
task.spawn(function()
    while true do
        task.wait(60)
        for _,p in ipairs(Players:GetPlayers()) do saveData(p) end
    end
end)

-- Leaderboard periódico
task.spawn(function()
    while true do
        task.wait(120)
        local rb10 = getTopLeaderboard("rebirths", 10)
        local st10 = getTopLeaderboard("stolen",   10)
        LeaderboardRE:FireAllClients({ rebirths=rb10, stolen=st10 })
    end
end)

-- Rotação de bioma
task.spawn(function()
    while true do
        task.wait(GameConfig.BIOME_ROTATION_INTERVAL)
        local pool = {}
        for i=1,#GameConfig.BASE_POSITIONS do table.insert(pool,i) end
        for i=#pool,2,-1 do local j=math.random(1,i); pool[i],pool[j]=pool[j],pool[i] end
        currentInnerBases = {pool[1],pool[2],pool[3],pool[4]}
        local names={}
        for _,idx in ipairs(currentInnerBases) do table.insert(names, GameConfig.BASE_NAMES[idx] or "Base "..idx) end
        GlobalAnnounceRE:FireAllClients("🗺 ZONA ÉPICA mudou! Novas bases: "..table.concat(names,", "), Color3.fromRGB(0,200,180))
        BiomeUpdateRE:FireAllClients(currentInnerBases)
    end
end)

-- Loop de spawn
task.spawn(function()
    for _=1,#GameConfig.BASE_POSITIONS do spawnBrainrot(); task.wait(0.15) end
    while true do task.wait(GameConfig.SPAWN_INTERVAL); spawnBrainrot() end
end)

print("[BrainrotRoubo] Servidor COMPLETO iniciado! Todos os sistemas ativos.")
