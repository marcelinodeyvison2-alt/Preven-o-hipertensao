# SOL's RNG - Aura Roller 🎰✨

Jogo de RNG para Roblox inspirado em SOL's RNG, com auras colecionáveis, upgrades e eventos aleatórios.

---

## 📁 Estrutura de Arquivos

```
SOLsRNG-AuraRoller/
├── ServerScriptService/
│   ├── SetupRemoteEvents.server.lua   ← Cria RemoteEvents (rodar PRIMEIRO)
│   ├── WorldSetup.server.lua          ← Configura mapa e Lighting
│   ├── MainServer.server.lua          ← Lógica principal do servidor
│   └── Modules/
│       ├── DataManager.lua            ← DataStore (salvar/carregar dados)
│       ├── RNGSystem.lua              ← Sistema de probabilidade
│       ├── AuraManager.lua            ← Efeitos de aura nos personagens
│       └── EventManager.lua           ← Eventos aleatórios
├── ReplicatedStorage/
│   └── GameConfig.lua                 ← Configuração central (auras, upgrades, etc.)
├── StarterPlayerScripts/
│   ├── MainClient.client.lua          ← Script principal do cliente
│   └── Modules/
│       ├── UIManager.lua              ← Interface gráfica completa
│       ├── AuraEffects.lua            ← Efeitos visuais no cliente
│       └── SoundManager.lua           ← Gerenciador de sons
└── StarterCharacterScripts/
    └── CharacterSetup.client.lua      ← Configuração do personagem
```

---

## 🛠️ GUIA DE INSTALAÇÃO NO ROBLOX STUDIO

### Pré-requisitos
- Roblox Studio instalado
- Conta Roblox
- Plugin opcional: **Rojo** (para sincronizar arquivos, recomendado)

---

### MÉTODO 1: Manual (copiar/colar)

#### Passo 1: Criar o projeto
1. Abra o **Roblox Studio**
2. Crie um novo jogo (**Baseplate** ou **Empty**)
3. Vá em `File → Game Settings → Security` e ative **Allow HTTP Requests**

#### Passo 2: Configurar ReplicatedStorage
1. Na aba **Explorer**, clique com botão direito em **ReplicatedStorage**
2. Insira um **ModuleScript**
3. Renomeie para `GameConfig`
4. Cole o conteúdo de `ReplicatedStorage/GameConfig.lua`

#### Passo 3: Configurar ServerScriptService
1. Clique com botão direito em **ServerScriptService**
2. Insira um **Script**, renomeie para `SetupRemoteEvents` e cole o conteúdo
3. Insira outro **Script**, renomeie para `WorldSetup` e cole o conteúdo
4. Insira outro **Script**, renomeie para `MainServer` e cole o conteúdo
5. Dentro do **ServerScriptService**, crie uma **Folder** chamada `Modules`
6. Dentro de `Modules`, insira 4 **ModuleScripts**:
   - `DataManager` → cole conteúdo de `ServerScriptService/Modules/DataManager.lua`
   - `RNGSystem` → cole conteúdo de `ServerScriptService/Modules/RNGSystem.lua`
   - `AuraManager` → cole conteúdo de `ServerScriptService/Modules/AuraManager.lua`
   - `EventManager` → cole conteúdo de `ServerScriptService/Modules/EventManager.lua`

#### Passo 4: Configurar StarterPlayerScripts
1. Expanda **StarterPlayer** → clique com botão direito em **StarterPlayerScripts**
2. Insira um **LocalScript**, renomeie para `MainClient` e cole o conteúdo
3. Crie uma **Folder** chamada `Modules` dentro de StarterPlayerScripts
4. Dentro de `Modules`, insira 3 **ModuleScripts**:
   - `UIManager` → cole conteúdo de `StarterPlayerScripts/Modules/UIManager.lua`
   - `AuraEffects` → cole conteúdo de `StarterPlayerScripts/Modules/AuraEffects.lua`
   - `SoundManager` → cole conteúdo de `StarterPlayerScripts/Modules/SoundManager.lua`

#### Passo 5: Configurar StarterCharacterScripts
1. Expanda **StarterPlayer** → clique com botão direito em **StarterCharacterScripts**
2. Insira um **LocalScript**, renomeie para `CharacterSetup` e cole o conteúdo

#### Passo 6: Testar
1. Clique em **Play** (F5) no Roblox Studio
2. A UI deve aparecer com botão de giro, HUD de moedas e navegação

---

### MÉTODO 2: Via Rojo (recomendado para desenvolvimento)

1. Instale o [Rojo](https://rojo.space/) (plugin + CLI)
2. Crie um arquivo `default.project.json` na raiz do projeto:

```json
{
    "name": "SOLsRNG-AuraRoller",
    "tree": {
        "$className": "DataModel",
        "ReplicatedStorage": {
            "GameConfig": {
                "$path": "SOLsRNG-AuraRoller/ReplicatedStorage/GameConfig.lua"
            }
        },
        "ServerScriptService": {
            "SetupRemoteEvents": {
                "$path": "SOLsRNG-AuraRoller/ServerScriptService/SetupRemoteEvents.server.lua"
            },
            "WorldSetup": {
                "$path": "SOLsRNG-AuraRoller/ServerScriptService/WorldSetup.server.lua"
            },
            "MainServer": {
                "$path": "SOLsRNG-AuraRoller/ServerScriptService/MainServer.server.lua"
            },
            "Modules": {
                "$className": "Folder",
                "DataManager": {
                    "$path": "SOLsRNG-AuraRoller/ServerScriptService/Modules/DataManager.lua"
                },
                "RNGSystem": {
                    "$path": "SOLsRNG-AuraRoller/ServerScriptService/Modules/RNGSystem.lua"
                },
                "AuraManager": {
                    "$path": "SOLsRNG-AuraRoller/ServerScriptService/Modules/AuraManager.lua"
                },
                "EventManager": {
                    "$path": "SOLsRNG-AuraRoller/ServerScriptService/Modules/EventManager.lua"
                }
            }
        },
        "StarterPlayer": {
            "StarterPlayerScripts": {
                "MainClient": {
                    "$path": "SOLsRNG-AuraRoller/StarterPlayerScripts/MainClient.client.lua"
                },
                "Modules": {
                    "$className": "Folder",
                    "UIManager": {
                        "$path": "SOLsRNG-AuraRoller/StarterPlayerScripts/Modules/UIManager.lua"
                    },
                    "AuraEffects": {
                        "$path": "SOLsRNG-AuraRoller/StarterPlayerScripts/Modules/AuraEffects.lua"
                    },
                    "SoundManager": {
                        "$path": "SOLsRNG-AuraRoller/StarterPlayerScripts/Modules/SoundManager.lua"
                    }
                }
            },
            "StarterCharacterScripts": {
                "CharacterSetup": {
                    "$path": "SOLsRNG-AuraRoller/StarterCharacterScripts/CharacterSetup.client.lua"
                }
            }
        }
    }
}
```

3. Execute `rojo serve` e conecte pelo plugin no Studio

---

## 🎵 Configurando Sons

No arquivo `SoundManager.lua`, substitua os IDs de som:

1. Vá ao **Roblox Audio Catalog** (https://www.roblox.com/develop/library?CatID=0&SortType=0&SortAggregation=5&genreTypeId=1&PageNumber=1&targetNotForSale=false)
2. Procure sons como:
   - `spin_tick`: som de clique/tick rápido
   - `reveal_epic`: vine boom / som dramático
   - `reveal_divine`: "WHAT THE HELL" / som épico
   - `event_start`: fanfara / fanfare
3. Copie os IDs e substitua no `SoundManager.lua`

---

## 🎮 Como Jogar

| Ação | Como fazer |
|------|-----------|
| Girar | Clique no botão "GIRAR!" |
| Ver inventário | Botão "🎒 Inventario" |
| Equipar aura | Inventário → clique na aura → "EQUIPAR" |
| Comprar upgrade | Botão "⬆ Upgrades" → "COMPRAR" |
| Ver ranking | Botão "🏆 Ranking" |
| Mystery Box | Corra até a caixa que aparece no mapa |

---

## ⚙️ Personalizando Auras

Para adicionar novas auras, edite `GameConfig.lua` na tabela `AURAS`:

```lua
{ 
    name = "MinhaAura",     -- Nome único
    rarity = "Epic",        -- Common/Uncommon/Rare/Epic/Legendary/Divine
    chance = 15000,         -- 1 em 15.000
    color = Color3.fromRGB(255, 0, 150),  -- Cor das partículas
    particles = 80,         -- Quantidade de partículas
    lightIntensity = 2.2,   -- Brilho da luz (0 = sem luz)
    coins = 300,            -- Coins ganhos ao coletar
    gems = 5,               -- Gems ganhos (0 para comuns)
},
```

---

## 🏆 Raridades e Chances

| Raridade  | Cor        | Exemplo de Chance |
|-----------|------------|-------------------|
| Common    | ⬜ Cinza   | 1/10 a 1/100      |
| Uncommon  | 🟩 Verde   | 1/100 a 1/300     |
| Rare      | 🟦 Azul    | 1/1.000 a 1/3.000 |
| Epic      | 🟪 Roxo    | 1/10.000 a 1/30.000 |
| Legendary | 🟧 Laranja | 1/100.000 a 1/500.000 |
| Divine    | 🟥 Vermelho| 1/1.000.000+      |

---

## 🔧 Configurações Avançadas

Em `GameConfig.lua` → `SETTINGS`:

```lua
GameConfig.SETTINGS = {
    BASE_SPIN_COOLDOWN  = 3,    -- Cooldown base entre giros (segundos)
    SPIN_ANIMATION_TIME = 2,    -- Duração da animação de spin
    EVENT_MIN_INTERVAL  = 300,  -- Mínimo entre eventos (5 min)
    EVENT_MAX_INTERVAL  = 900,  -- Máximo entre eventos (15 min)
    MAX_INVENTORY_SIZE  = 500,  -- Máximo de auras no inventário
    COIN_PER_SPIN       = 2,    -- Coins base por giro
}
```

---

## 📊 Sistemas Implementados

- ✅ **RNG com pesos** — auras raras têm peso menor, mas aparecem
- ✅ **27 auras** em 6 raridades (Common a Divine)  
- ✅ **DataStore** — inventário, moedas e upgrades salvos permanentemente
- ✅ **6 upgrades** (Luck, Speed, Multiplier)
- ✅ **3 tipos de roleta** (Normal, Mystic, Godly)
- ✅ **3 eventos aleatórios** (Double RNG, Luxury Hour, Mystery Box)
- ✅ **Leaderboard global** (auras e coins)
- ✅ **Efeitos de partículas** por raridade
- ✅ **Auto-spin** (desbloqueável via upgrade)
- ✅ **Cooldown visual** com countdown
- ✅ **Mensagens virais** por raridade ("NO CAP BRO!", "RIZZ UP!")
- ✅ **Camera shake** e **screen flash** para auras épicas+
- ✅ **Card de reveal** animado para auras raras+
- ✅ **Billboard de aura** nos personagens (Legendary+)
- ✅ **Ambiente espacial** com bloom, atmosfera e partículas de estrelas

---

## 🚀 Dicas para Viralizar no TikTok

1. **Grave o momento** de conseguir uma aura Divine — o efeito visual épico é compartilhável
2. **Crie desafios**: "1000 giros buscando SOL aura"
3. **Shows de aura**: ative auras Legendary/Divine e grave seus efeitos
4. **Leaderboard flex**: mostre sua posição no ranking
5. **Mystery Box**: grave o momento em que a caixa aparece e alguém pega

---

Criado com Lua para Roblox Studio.
