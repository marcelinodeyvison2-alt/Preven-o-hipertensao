# 🧠✨ Sell Brainrot for Aura — Roblox Game

Jogo Roblox onde você coleta itens **brainrot** espalhados pelo mapa e os vende na zona de venda para ganhar **Aura**. Quanto mais raro o brainrot, mais Aura você ganha!

---

## 📁 Estrutura de Arquivos

```
BrainrotAura/
└── src/
    ├── ReplicatedStorage/
    │   ├── BrainrotData.lua         ← ModuleScript: lista de itens e raridades
    │   └── RemoteEvents.lua         ← ModuleScript: cria RemoteEvents/Functions
    ├── ServerScriptService/
    │   └── GameServer.server.lua    ← Script do servidor (lógica principal)
    ├── StarterPlayerScripts/
    │   └── GameClient.client.lua    ← LocalScript do cliente (HUD + UI)
    └── StarterGui/
        └── MobileButton.lua         ← LocalScript (botão touch para mobile)
```

---

## 🚀 Como instalar no Roblox Studio

### Passo 1 — Preparar o projeto
1. Abra o **Roblox Studio** e crie um novo lugar em branco (Baseplate).
2. Ative o acesso ao **DataStore**: Jogo → Configurações do Jogo → Segurança → "Ativar acesso à API do Studio".

### Passo 2 — Criar os ModuleScripts em ReplicatedStorage
1. No Explorer, clique em **ReplicatedStorage** → Inserir Objeto → **ModuleScript**.
2. Renomeie para `BrainrotData` e cole o conteúdo de `src/ReplicatedStorage/BrainrotData.lua`.
3. Repita para `RemoteEvents` com o conteúdo de `src/ReplicatedStorage/RemoteEvents.lua`.

### Passo 3 — Script do servidor
1. Clique em **ServerScriptService** → Inserir Objeto → **Script**.
2. Renomeie para `GameServer` e cole o conteúdo de `src/ServerScriptService/GameServer.server.lua`.

### Passo 4 — Script do cliente
1. Clique em **StarterPlayer** → **StarterPlayerScripts** → Inserir Objeto → **LocalScript**.
2. Renomeie para `GameClient` e cole o conteúdo de `src/StarterPlayerScripts/GameClient.client.lua`.

### Passo 5 — Botão mobile (opcional)
1. Clique em **StarterGui** → Inserir Objeto → **LocalScript**.
2. Renomeie para `MobileButton` e cole o conteúdo de `src/StarterGui/MobileButton.lua`.

### Passo 6 — Testar
1. Pressione **Play** no Studio.
2. Corra até as bolinhas coloridas no mapa para coletar brainrot.
3. Vá até a **zona amarela** (SellZone) ou clique no botão da HUD para vender.

---

## 🎮 Mecânicas do Jogo

| Ação | Como fazer |
|------|-----------|
| Coletar brainrot | Toque/encoste nas bolinhas coloridas no mapa |
| Vender | Entre na zona amarela **ou** clique "VENDER TUDO" na HUD |
| Ver Aura | Canto superior central da tela + acima do personagem |
| Mochila cheia | Máx. 20 itens — venda antes de coletar mais |

---

## 🌈 Raridades e Brainrots

| Raridade | Cor | Chance | Exemplos |
|----------|-----|--------|---------|
| Comum | Cinza | 50% | Tralalero Tralala, Bombardiro Crocodilo |
| Raro | Azul | 28% | Cappuccino Assassino, Lirilì Larilà |
| Épico | Roxo | 14% | Tracotocatocatoco, Bombombini Gusini |
| Lendário | Dourado | 6% | Trippi Troppi, Il Cacciatore |
| Mítico | Vermelho | 2% | ULTRA BRAINROT SIGMA, Il Goblin dei Memi |

---

## ⚙️ Configurações (GameServer)

Edite o bloco `CONFIG` no topo do `GameServer.server.lua`:

```lua
local CONFIG = {
    SPAWN_RADIUS   = 120,  -- raio de spawn dos brainrots (studs)
    MAX_ITEMS_MAP  = 30,   -- máximo de itens no mapa ao mesmo tempo
    SPAWN_INTERVAL = 4,    -- segundos entre cada novo spawn
    ITEM_LIFETIME  = 30,   -- segundos até o item desaparecer sozinho
    BAG_CAPACITY   = 20,   -- capacidade máxima da mochila do jogador
}
```

---

## 💾 Persistência de Dados

A **Aura** do jogador é salva automaticamente no **DataStore** (`BrainrotAura_v1`) ao sair do jogo e carregada ao entrar.
