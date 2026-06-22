-- AdminExecutor.server.lua (Script em ServerScriptService)
-- Executor de scripts e comandos para admins/desenvolvedores
-- Seguranca: apenas user IDs na lista ADMIN_IDS podem usar

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

-- ============================================================
-- CONFIGURACAO DE ADMINS
-- Adicione os Roblox User IDs dos admins aqui.
-- Para encontrar seu ID: roblox.com/users/<SEU_ID>/profile
-- ============================================================
local ADMIN_IDS = {
    -- Exemplo: 12345678,
}

-- ============================================================
-- DEPENDENCIAS
-- ============================================================
local Modules       = script.Parent:WaitForChild("Modules")
local DataManager   = require(Modules:WaitForChild("DataManager"))
local EventManager  = require(Modules:WaitForChild("EventManager"))
local GameConfig    = require(ReplicatedStorage:WaitForChild("GameConfig"))

local remotes    = ReplicatedStorage:WaitForChild("RemoteEvents")
local RE_SyncData = remotes:WaitForChild("SyncData")

-- ============================================================
-- CRIA PASTA DE REMOTES DO ADMIN
-- ============================================================
local adminRemotes = ReplicatedStorage:FindFirstChild("AdminRemotes")
if not adminRemotes then
    adminRemotes = Instance.new("Folder")
    adminRemotes.Name   = "AdminRemotes"
    adminRemotes.Parent = ReplicatedStorage
end

local function getOrCreate(class, name, parent)
    local obj = parent:FindFirstChild(name)
    if not obj then
        obj        = Instance.new(class)
        obj.Name   = name
        obj.Parent = parent
    end
    return obj
end

local RF_Execute = getOrCreate("RemoteFunction", "Execute",   adminRemotes)
local RE_Output  = getOrCreate("RemoteEvent",    "Output",    adminRemotes)
local RE_IsAdmin = getOrCreate("RemoteEvent",    "IsAdmin",   adminRemotes)

-- ============================================================
-- VERIFICACAO DE PERMISSAO
-- Em Studio qualquer desenvolvedor tem acesso automatico.
-- No jogo publicado so os IDs em ADMIN_IDS tem acesso.
-- ============================================================
local function isAdmin(player)
    -- Criador do jogo sempre e admin
    if game.CreatorId ~= 0 and player.UserId == game.CreatorId then
        return true
    end
    -- Modo Studio: todos sao admins para facilitar testes
    if RunService:IsStudio() then
        return true
    end
    for _, id in ipairs(ADMIN_IDS) do
        if player.UserId == id then
            return true
        end
    end
    return false
end

-- Notifica clientes que sao admin quando entram
Players.PlayerAdded:Connect(function(player)
    task.wait(2)
    if isAdmin(player) then
        RE_IsAdmin:FireClient(player)
    end
end)

-- ============================================================
-- COMANDOS EMBUTIDOS
-- ============================================================
local commands = {}

commands["help"] = function(player, args)
    return [[
╔══════════════════════════════════════════════════════════╗
║              SCRIPT EXECUTOR — COMANDOS                  ║
╠══════════════════════════════════════════════════════════╣
║ help                         - lista de comandos         ║
║ players                      - jogadores online          ║
║ give_aura   <user> <aura>    - da uma aura               ║
║ give_coins  <user> <qtd>     - da moedas                 ║
║ give_gems   <user> <qtd>     - da gemas                  ║
║ kick        <user> [motivo]  - expulsa jogador           ║
║ trigger_event <id>           - aciona evento             ║
║ get_data    <user>           - exibe dados do jogador    ║
║ list_auras                   - lista todas as auras      ║
║ print_inv   <user>           - mostra inventario         ║
╠══════════════════════════════════════════════════════════╣
║ Tambem aceita codigo Lua diretamente.                    ║
║ Ex: print(#Players:GetPlayers())                         ║
║ Ex: workspace.Baseplate.BrickColor = BrickColor.Blue()   ║
╚══════════════════════════════════════════════════════════╝]]
end

commands["players"] = function(player, args)
    local list = Players:GetPlayers()
    if #list == 0 then return "Nenhum jogador online." end
    local lines = { string.format("JOGADORES ONLINE (%d):", #list) }
    for _, p in ipairs(list) do
        local data = DataManager.Get(p)
        local coins = data and data.coins or 0
        local gems  = data and data.gems  or 0
        local aura  = (data and data.activeAura) or "—"
        table.insert(lines, string.format(
            "  [%d] %-20s  Coins:%-8d  Gems:%-6d  Aura: %s",
            p.UserId, p.Name, coins, gems, aura
        ))
    end
    return table.concat(lines, "\n")
end

commands["give_aura"] = function(player, args)
    local targetName, auraName = args[1], args[2]
    if not targetName or not auraName then
        return "Uso: give_aura <jogador> <aura>"
    end
    local target = Players:FindFirstChild(targetName)
    if not target then return "Jogador '" .. targetName .. "' nao encontrado." end
    local aura = GameConfig.GetAuraByName(auraName)
    if not aura then return "Aura '" .. auraName .. "' nao existe. Use 'list_auras'." end
    DataManager.AddAura(target, auraName)
    RE_SyncData:FireClient(target, DataManager.Get(target))
    return string.format("Aura '%s' (%s) adicionada ao inventario de %s!", auraName, aura.rarity, target.Name)
end

commands["give_coins"] = function(player, args)
    local targetName, amount = args[1], tonumber(args[2])
    if not targetName or not amount then
        return "Uso: give_coins <jogador> <quantidade>"
    end
    local target = Players:FindFirstChild(targetName)
    if not target then return "Jogador '" .. targetName .. "' nao encontrado." end
    DataManager.AddCoins(target, amount)
    RE_SyncData:FireClient(target, DataManager.Get(target))
    return string.format("%d coins adicionados para %s!", amount, target.Name)
end

commands["give_gems"] = function(player, args)
    local targetName, amount = args[1], tonumber(args[2])
    if not targetName or not amount then
        return "Uso: give_gems <jogador> <quantidade>"
    end
    local target = Players:FindFirstChild(targetName)
    if not target then return "Jogador '" .. targetName .. "' nao encontrado." end
    DataManager.AddGems(target, amount)
    RE_SyncData:FireClient(target, DataManager.Get(target))
    return string.format("%d gems adicionados para %s!", amount, target.Name)
end

commands["kick"] = function(player, args)
    local targetName = args[1]
    if not targetName then return "Uso: kick <jogador> [motivo]" end
    if targetName == player.Name then return "Voce nao pode se expulsar!" end
    local target = Players:FindFirstChild(targetName)
    if not target then return "Jogador '" .. targetName .. "' nao encontrado." end
    local reason = #args > 1 and table.concat(args, " ", 2) or "Expulso por um administrador."
    DataManager.Save(target)
    target:Kick("[Admin] " .. reason)
    return string.format("%s foi expulso. Motivo: %s", target.Name, reason)
end

commands["trigger_event"] = function(player, args)
    local eventId = args[1]
    if not eventId then
        return "Uso: trigger_event <id>\nIDs: double_rng, luxury_hour, mystery_box"
    end
    local valid = false
    for _, ev in ipairs(GameConfig.EVENTS) do
        if ev.id == eventId then valid = true break end
    end
    if not valid then
        return "Evento '" .. eventId .. "' desconhecido.\nIDs validos: double_rng, luxury_hour, mystery_box"
    end
    EventManager.TriggerManual(eventId)
    return "Evento '" .. eventId .. "' acionado com sucesso!"
end

commands["get_data"] = function(player, args)
    local targetName = args[1] or player.Name
    local target = Players:FindFirstChild(targetName)
    if not target then return "Jogador '" .. targetName .. "' nao encontrado." end
    local data = DataManager.Get(target)
    if not data then return "Dados nao carregados ainda." end
    local inv = data.inventory or {}
    return string.format(
        "DADOS DE %s (ID %d):\n  Coins     : %d\n  Gems      : %d\n  Spins     : %d\n  Inventario: %d auras\n  Aura Ativa: %s\n  Upgrades  : %s",
        target.Name, target.UserId,
        data.coins, data.gems, data.totalSpins, #inv,
        data.activeAura or "nenhuma",
        next(data.upgrades or {}) and "sim" or "nenhum"
    )
end

commands["list_auras"] = function(player, args)
    local rarityFilter = args[1]
    local lines = { "AURAS DISPONIVEIS:" }
    for _, aura in ipairs(GameConfig.AURAS) do
        if not rarityFilter or aura.rarity:lower() == rarityFilter:lower() then
            table.insert(lines, string.format(
                "  %-12s  %-10s  1/%s coins",
                aura.name, aura.rarity, tostring(aura.chance)
            ))
        end
    end
    return table.concat(lines, "\n")
end

commands["print_inv"] = function(player, args)
    local targetName = args[1] or player.Name
    local target = Players:FindFirstChild(targetName)
    if not target then return "Jogador '" .. targetName .. "' nao encontrado." end
    local data = DataManager.Get(target)
    if not data then return "Dados nao carregados." end
    local inv = data.inventory or {}
    if #inv == 0 then return target.Name .. " nao tem auras no inventario." end
    local lines = { string.format("INVENTARIO DE %s (%d auras):", target.Name, #inv) }
    local counts = {}
    for _, name in ipairs(inv) do
        counts[name] = (counts[name] or 0) + 1
    end
    for name, count in pairs(counts) do
        local aura = GameConfig.GetAuraByName(name)
        local rarity = aura and aura.rarity or "?"
        table.insert(lines, string.format("  %-12s  %-10s  x%d", name, rarity, count))
    end
    table.sort(lines, function(a, b) return a < b end)
    return table.concat(lines, "\n")
end

-- ============================================================
-- PROCESSADOR DE ENTRADA
-- Tenta como comando embutido; se nao reconhecer, roda como Lua
-- ============================================================
local function processInput(player, input)
    input = input:match("^%s*(.-)%s*$") -- trim whitespace
    if input == "" then return false, "Entrada vazia." end

    -- Tenta como comando embutido (primeira palavra)
    local parts = {}
    for word in input:gmatch("%S+") do
        table.insert(parts, word)
    end
    local cmdName = parts[1] and parts[1]:lower()
    if cmdName and commands[cmdName] then
        table.remove(parts, 1)
        local ok, result = pcall(commands[cmdName], player, parts)
        if ok then
            return true, tostring(result)
        else
            return false, "Erro no comando: " .. tostring(result)
        end
    end

    -- Executa como codigo Lua via loadstring
    local fn, compileErr = loadstring(input)
    if not fn then
        return false, "Erro de sintaxe: " .. tostring(compileErr)
    end

    -- Funcao print customizada que envia output em tempo real para o cliente
    local function customPrint(...)
        local strs = {}
        for _, v in ipairs({ ... }) do
            table.insert(strs, tostring(v))
        end
        local msg = table.concat(strs, "\t")
        RE_Output:FireClient(player, msg)
    end

    -- Ambiente de execucao com acesso seguro as APIs relevantes
    local env = setmetatable({
        -- Servicos e APIs do jogo
        game        = game,
        workspace   = workspace,
        Players     = Players,
        player      = player,      -- o admin que executou
        -- Modulos do jogo
        DataManager  = DataManager,
        EventManager = EventManager,
        GameConfig   = GameConfig,
        -- Funcoes substituidas
        print  = customPrint,
        warn   = function(...) customPrint("[warn]", ...) end,
        -- Lua padrao
        task        = task,
        tostring    = tostring,
        tonumber    = tonumber,
        pairs       = pairs,
        ipairs      = ipairs,
        next        = next,
        type        = type,
        select      = select,
        error       = error,
        pcall       = pcall,
        xpcall      = xpcall,
        unpack      = table.unpack or unpack,
        math        = math,
        string      = string,
        table       = table,
        tick        = tick,
        os          = os,
        Instance    = Instance,
        Color3      = Color3,
        Vector3     = Vector3,
        CFrame      = CFrame,
        BrickColor  = BrickColor,
        UDim2       = UDim2,
        UDim        = UDim,
        Enum        = Enum,
        TweenInfo   = TweenInfo,
        Ray         = Ray,
    }, { __index = _G })

    setfenv(fn, env)

    local ok, err = pcall(fn)
    if ok then
        return true, "[Script executado com sucesso]"
    else
        return false, "Erro de execucao: " .. tostring(err)
    end
end

-- ============================================================
-- HANDLER DO REMOTE FUNCTION
-- ============================================================
RF_Execute.OnServerInvoke = function(player, input)
    if not isAdmin(player) then
        return false, "Acesso negado. Voce nao esta na lista de admins."
    end
    if type(input) ~= "string" then
        return false, "Entrada invalida."
    end

    local ok, result = processInput(player, input)

    local tag = ok and "[OK]" or "[ERRO]"
    print(string.format("[AdminExecutor] %s %s >>> %s", tag, player.Name, input:sub(1, 100)))

    return ok, result
end

print("[AdminExecutor] Sistema de execucao para admins iniciado!")
