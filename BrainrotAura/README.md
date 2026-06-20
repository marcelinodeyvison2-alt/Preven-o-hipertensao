# 🧠✨ Sell Brainrot for Aura — Roblox Game (v2)

> Colete brainrots italianos espalhados pelo mapa, venda na zona amarela e acumule **Aura** para subir de rank!
> Agora com **Shop**, **Rebirth**, **Combo**, **Leaderboard** e muito mais.

---

## 📁 Estrutura de Arquivos

```
BrainrotAura/
└── src/
    ├── ReplicatedStorage/
    │   ├── BrainrotData.lua      ← ModuleScript: itens, raridades, ranks
    │   ├── ShopData.lua          ← ModuleScript: upgrades de mochila, mult, rebirth
    │   └── RemoteEvents.lua      ← ModuleScript: todos os RemoteEvents/Functions
    ├── ServerScriptService/
    │   └── GameServer.server.lua ← Script (servidor): spawn, coleta, venda, shop...
    ├── StarterPlayerScripts/
    │   └── GameClient.client.lua ← LocalScript (cliente): HUD completo
    └── StarterGui/
        └── MobileButton.lua      ← LocalScript: botões touch para mobile
```

---

## 🚀 Instalação Passo a Passo

### Passo 1 — Configurar o Projeto

1. Abra o **Roblox Studio** e crie um novo lugar com o template **Baseplate**.
2. Vá em **Home → Game Settings → Security** e ative:
   > ✅ **Enable Studio Access to API Services**
   
   Isso é obrigatório para o **DataStore** salvar a Aura dos jogadores.

---

### Passo 2 — Criar os ModuleScripts em ReplicatedStorage

Você precisará criar **3 ModuleScripts** dentro de **ReplicatedStorage**.

#### 2.1 — BrainrotData
| Passo | Ação |
|-------|------|
| 1 | No Explorer, clique em **ReplicatedStorage** |
| 2 | Botão direito → **Insert Object** → **ModuleScript** |
| 3 | Renomeie para `BrainrotData` |
| 4 | Cole o conteúdo de `src/ReplicatedStorage/BrainrotData.lua` |

#### 2.2 — ShopData *(NOVO em v2)*
| Passo | Ação |
|-------|------|
| 1 | Repita o processo acima em **ReplicatedStorage** |
| 2 | Renomeie para `ShopData` |
| 3 | Cole o conteúdo de `src/ReplicatedStorage/ShopData.lua` |

#### 2.3 — RemoteEvents
| Passo | Ação |
|-------|------|
| 1 | Repita o processo acima em **ReplicatedStorage** |
| 2 | Renomeie para `RemoteEvents` |
| 3 | Cole o conteúdo de `src/ReplicatedStorage/RemoteEvents.lua` |

> ⚠️ **Os nomes precisam ser exatos!** O jogo usa `require()` pelo nome.

---

### Passo 3 — Script do Servidor

| Passo | Ação |
|-------|------|
| 1 | Clique em **ServerScriptService** |
| 2 | Botão direito → **Insert Object** → **Script** |
| 3 | Renomeie para `GameServer` |
| 4 | Cole o conteúdo de `src/ServerScriptService/GameServer.server.lua` |

> 💡 O nome do arquivo não importa para Roblox — só o tipo (Script vs LocalScript vs ModuleScript).

---

### Passo 4 — Script do Cliente

| Passo | Ação |
|-------|------|
| 1 | No Explorer, expanda **StarterPlayer** |
| 2 | Clique em **StarterPlayerScripts** |
| 3 | Botão direito → **Insert Object** → **LocalScript** |
| 4 | Renomeie para `GameClient` |
| 5 | Cole o conteúdo de `src/StarterPlayerScripts/GameClient.client.lua` |

---

### Passo 5 — Botões Mobile *(opcional)*

| Passo | Ação |
|-------|------|
| 1 | Clique em **StarterGui** |
| 2 | Botão direito → **Insert Object** → **LocalScript** |
| 3 | Renomeie para `MobileButton` |
| 4 | Cole o conteúdo de `src/StarterGui/MobileButton.lua` |

> Esses botões só aparecem em dispositivos com touchscreen.

---

### Passo 6 — Testar!

1. Clique em **▶ Play** (ou `F5`)
2. Você verá **bolinhas coloridas** espalhadas pelo mapa
3. **Aproxime-se** de uma bolinha e pressione **E** para coletar
4. **Entre na zona amarela** para vender tudo automaticamente
5. **Entre na zona azul** ou clique **🛒 LOJA** no HUD para abrir a loja
6. Acumule Aura e suba de **Rank**!

---

## 🎮 Como Jogar — Guia Completo

### Coleta de Brainrot

- Ande pelo mapa e procure as **bolinhas coloridas** flutuando
- Quando estiver perto, pressione **E** (ou toque no botão mobile)
- O brainrot vai para sua **mochila**
- Colete rápido para ativar o sistema de **Combo**!

### Vendendo

Você pode vender de 3 formas:
1. **Entre na zona amarela** → vende automaticamente ao encostar
2. **Botão "💰 VENDER" no HUD** (funciona se você estiver perto da zona)
3. **Botão no painel de inventário** (canto inferior direito)

### Sistema de Combo 🔥

Colete itens rápido para acumular combo e ganhar bônus de Aura!

| Combo | Bônus |
|-------|-------|
| x5 itens em 5s | +50 ✨ Aura Bônus |
| x10 itens em 5s | +200 ✨ Aura Bônus |
| x20 itens em 5s | +1.000 ✨ Aura Bônus |
| x30 itens em 5s | +5.000 ✨ Aura Bônus |

### Loja 🛒

A loja tem dois tipos de upgrade:

#### Upgrades de Mochila
| Nível | Capacidade | Custo |
|-------|------------|-------|
| 1 - Básica | 20 itens | Grátis |
| 2 - Média | 35 itens | ✨ 2.000 Aura |
| 3 - Grande | 60 itens | ✨ 10.000 Aura |
| 4 - Sigma | 100 itens | ✨ 50.000 Aura |

#### Upgrades de Multiplicador
| Nível | Multiplicador | Custo |
|-------|--------------|-------|
| 1 | x1.0 | Grátis |
| 2 | x1.5 | ✨ 5.000 Aura |
| 3 | x2.0 | ✨ 25.000 Aura |
| 4 | x3.0 | ✨ 100.000 Aura |
| 5 | x5.0 | ✨ 500.000 Aura |

> O multiplicador é aplicado na hora de **vender**, multiplicando toda a Aura do lote.

### Rebirth 🔁

- Requer **✨ 150.000 Aura**
- Reseta sua Aura para 0
- Reseta mochila e multiplicadores comprados
- Dá **+25% de multiplicador permanente** (acumula por rebirth)
- **3 rebirths** = +75% permanente de base

> **Estratégia**: faça rebirth cedo para ter mais multiplicador base, ou tarde para manter mais Aura.

---

## 🏆 Sistema de Ranks

| Aura Necessária | Rank |
|-----------------|------|
| 0 | 🥚 Noob |
| 500 | 💀 Iniciante |
| 5.000 | 🧠 Brainrot Boy |
| 25.000 | ⚡ Sigma |
| 100.000 | 👑 Brainrot King |
| 500.000 | 🔥 Brainrot God |
| 2.000.000 | ☠️ ULTRA SIGMA GOD |

O rank aparece **acima do personagem** e no **topo da tela**, com cores únicas para cada tier.

---

## 🌈 Raridades e Itens

| Raridade | Cor | Chance | Faixa de Aura |
|----------|-----|--------|--------------|
| ⚪ Comum | Cinza | 45% | 10–20 Aura |
| 🔵 Raro | Azul | 28% | 75–120 Aura |
| 🟣 Épico | Roxo | 16% | 300–420 Aura |
| 🟡 Lendário | Dourado | 8% | 1.200–2.000 Aura |
| 🔴 Mítico | Vermelho | 3% | 8.000–12.000 Aura |

### Lista de Brainrots (25 no total)

**Comum:** Tralalero Tralala, Bombardiro Crocodilo, Brrr Brrr Patapim, Tung Tung Sahur, Frigo Camelo, Gatto Panceri, Pinguino Atlantico

**Raro:** Cappuccino Assassino, Lirilì Larilà, Glorbo Fruttodrillo, Ballerina Cappuccina, Tortellino Marino, Cannoli Esplosivo

**Épico:** Tracotocatocatoco, Bombombini Gusini, Vaca Saturno Saturnita, Falco Alpino Terribile, Coccodrillo Cosmico

**Lendário:** Trippi Troppi, La Vaca Saturno, Il Cacciatore, Dragone Maccheroni

**Mítico:** ULTRA BRAINROT SIGMA, Il Goblin dei Memi, Omega Tralalero

---

## ⚙️ Personalizando o Jogo

Edite o bloco `CFG` no topo do `GameServer.server.lua`:

```lua
local CFG = {
    SPAWN_RADIUS   = 130,   -- raio de spawn dos brainrots (studs)
    MAX_ITEMS      = 35,    -- máx. de itens no mapa ao mesmo tempo
    SPAWN_INTERVAL = 3.5,   -- segundos entre cada novo spawn
    ITEM_LIFETIME  = 45,    -- segundos até o item desaparecer sozinho
    COMBO_WINDOW   = 5,     -- janela de tempo para contar combo (segundos)
}
```

Para ajustar custos da loja, edite o `ShopData.lua`.
Para adicionar brainrots, adicione entradas no array `ITEMS` do `BrainrotData.lua`.

---

## 💾 Persistência de Dados

O jogo salva automaticamente via **DataStore** (`BrainrotAura_v2`):
- Aura total acumulada
- Número de rebirths
- Nível atual de mochila
- Nível atual de multiplicador
- Estatísticas (total coletado, total vendido)

Salva em 3 momentos:
1. Quando o jogador **compra algo** na loja
2. Quando o jogador **sai do jogo**
3. A cada **2 minutos** automaticamente

---

## ❓ Problemas Comuns

**❌ "ModuleScript not found" ou "attempt to index nil"**
> Verifique se `BrainrotData`, `ShopData` e `RemoteEvents` estão em **ReplicatedStorage** com esses nomes exatos.

**❌ Os brainrots não aparecem no mapa**
> Confirme que o `GameServer` é um **Script** (não LocalScript) em **ServerScriptService**.

**❌ Aura não salva ao sair**
> Ative **"Enable Studio Access to API Services"** em Game Settings → Security.

**❌ A HUD não aparece**
> O `GameClient` deve ser um **LocalScript** em **StarterPlayerScripts** (dentro de StarterPlayer, não StarterGui).

**❌ Não consigo pressionar E para coletar**
> O ProximityPrompt requer que você esteja a **até 8 studs** do item. Chegue mais perto!

**❌ "Cannot sell" / botão de venda não funciona**
> O servidor valida que você está a **22 studs ou menos** da zona amarela. Caminhe até ela primeiro.

---

## 🗺️ Mapa

```
                  [LOJA 🔵]          [VENDA 🟡]
                   (azul)              (amarelo)
                      ↑                    ↑
               Zona azul                Zona amarela
               pressione E              entre para
               perto dela               vender tudo

         ○   ○     ○       ← brainrots espalhados
      ○       ○  ○       ○
   ○     ○         ○  ○
         [SPAWN DOS JOGADORES]
```

---

## 🔧 Dicas de Desenvolvimento

- Para testar com mais de 1 jogador no Studio, use **Home → Test → Players**
- O leaderboard atualiza a cada **12 segundos**
- O auto-save roda a cada **2 minutos** — não feche o Studio abruptamente durante testes
- Para resetar dados de teste: mude a chave do DataStore para `BrainrotAura_v3` no topo do `GameServer`
