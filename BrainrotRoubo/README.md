# Brainrot Roubo — Roblox Studio

Jogo no estilo idle/clicker em que você **rouba brainrots** espalhados pelo mapa para acumular **Aura**. Quanto mais raro o brainrot, mais aura você ganha. O sistema de **Rebirth** reseta sua aura, mas aumenta o cap e o multiplicador de ganho permanentemente.

---

## Sistemas

### Raridades de Brainrot

| Raridade   | Chance   | Aura Base         |
|------------|----------|-------------------|
| Comum      | ~45%     | 8–15              |
| Incomum    | ~28%     | 60–80             |
| Raro       | ~15%     | 300–400           |
| Épico      | ~8%      | 1 500–2 000       |
| Lendário   | ~3.3%    | 8 000–12 000      |
| Mítico     | ~0.7%    | 50 000–75 000     |

### Sistema de Aura
- Cap inicial: **500**
- Cada Rebirth multiplica o cap por **5**
- Cada Rebirth multiplica o ganho de aura por **2**

### Rebirth
- Custo: **80% do cap atual**
- Reseta a aura para 0
- Aumenta cap e multiplicador permanentemente

### Exemplo de progressão

| Rebirth | Cap      | Multiplicador | Custo Rebirth |
|---------|----------|---------------|---------------|
| 0       | 500      | x1            | 400           |
| 1       | 2 500    | x2            | 2 000         |
| 2       | 12 500   | x4            | 10 000        |
| 3       | 62 500   | x8            | 50 000        |
| 4       | 312 500  | x16           | 250 000       |

---

## Estrutura de Arquivos

```
BrainrotRoubo/
├── ReplicatedStorage/
│   └── GameConfig.lua          ← ModuleScript com todas as configurações
├── ServerScriptService/
│   ├── MainServer.lua          ← Script principal do servidor
│   └── MapSetup.lua            ← Script de criação do mapa básico
├── StarterGui/
│   └── MainGui.lua             ← LocalScript com toda a interface
└── StarterCharacterScripts/
    └── AuraEffect.lua          ← LocalScript de efeitos visuais de aura
```

---

## Instalação no Roblox Studio

### Método 1 — Manual (recomendado)

1. Abra o **Roblox Studio** e crie um novo projeto em branco.

2. **ReplicatedStorage > GameConfig** (ModuleScript)
   - Crie um `ModuleScript` dentro de `ReplicatedStorage`
   - Renomeie para `GameConfig`
   - Cole o conteúdo de `ReplicatedStorage/GameConfig.lua`

3. **ServerScriptService > MainServer** (Script)
   - Crie um `Script` dentro de `ServerScriptService`
   - Cole o conteúdo de `ServerScriptService/MainServer.lua`

4. **ServerScriptService > MapSetup** (Script)
   - Crie outro `Script` dentro de `ServerScriptService`
   - Cole o conteúdo de `ServerScriptService/MapSetup.lua`
   - *(Pode remover depois de configurar o mapa no Studio)*

5. **StarterGui > MainGui** (LocalScript)
   - Crie um `LocalScript` dentro de `StarterGui`
   - Renomeie para `MainGui`
   - Cole o conteúdo de `StarterGui/MainGui.lua`

6. **StarterCharacterScripts > AuraEffect** (LocalScript)
   - Crie um `LocalScript` dentro de `StarterCharacterScripts`
   - Renomeie para `AuraEffect`
   - Cole o conteúdo de `StarterCharacterScripts/AuraEffect.lua`

7. Pressione **Play** para testar!

### Método 2 — Plugin rbxmx
Use o plugin **Rojo** para sincronizar a pasta diretamente com o Studio.

---

## Controles

| Ação         | PC         | Mobile          |
|--------------|------------|-----------------|
| Roubar       | `E`        | Botão vermelho  |
| Renascer     | Botão UI   | Botão UI        |

---

## Dicas de Customização

- **Tamanho do mapa**: altere `SPAWN_AREA_HALF` em `GameConfig.lua`
- **Velocidade de spawn**: altere `SPAWN_INTERVAL`
- **Adicionar brainrots**: insira entradas na tabela `BRAINROT_TYPES`
- **Balanceamento**: ajuste `RARITY_WEIGHTS` (soma não precisa ser 10 000)
- **Cap inicial**: altere `BASE_AURA_CAP`
