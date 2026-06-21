# TUTORIAL COMPLETO — BRAINROT ROUBO
### Jogo para Roblox Studio | Versão Final Atualizada

---

## O QUE É ESSE JOGO?

**Brainrot Roubo** é um jogo de idle/clicker no Roblox onde você percorre um mapa com 12 bases e **rouba brainrots** que aparecem em cima delas. Cada brainrot tem uma **raridade** e uma **mutação** que juntas determinam quanta **Aura** você ganha ao roubar.

Quando sua Aura chega perto do limite, você faz **Rebirth** (renascimento) — isso zera sua Aura mas aumenta permanentemente o seu cap e o multiplicador de ganho, deixando você mais forte para sempre.

---

## ESTRUTURA DE ARQUIVOS

Seu projeto tem 4 scripts principais. Cada um vai em um lugar específico dentro do Roblox Studio:

```
BrainrotRoubo/
│
├── ReplicatedStorage/
│   └── GameConfig.lua         ← ModuleScript (configurações do jogo)
│
├── ServerScriptService/
│   ├── MainServer.lua          ← Script do servidor (lógica principal)
│   └── MapSetup.lua            ← Script do servidor (cria o mapa)
│
├── StarterGui/
│   └── MainGui.lua             ← LocalScript (interface do jogador)
│
└── StarterCharacterScripts/
    └── AuraEffect.lua          ← LocalScript (efeitos visuais no personagem)
```

---

## PARTE 1 — INSTALAÇÃO NO ROBLOX STUDIO

### Passo 1: Abra o Roblox Studio

1. Abra o **Roblox Studio**
2. Clique em **New** → escolha o template **Baseplate** (plataforma limpa)
3. Você vai ver a tela com um chão verde e o painel **Explorer** à direita

> **Dica:** Se o Explorer não aparecer, vá em `View` → `Explorer` na barra superior.

---

### Passo 2: Criar o GameConfig (ModuleScript)

O GameConfig é o **cérebro de configuração** do jogo. Todos os outros scripts leem ele para saber as raridades, mutações, posições das bases, etc.

1. No Explorer, clique com o botão direito em **ReplicatedStorage**
2. Clique em **Insert Object**
3. Escolha **ModuleScript**
4. Renomeie para **GameConfig** (clique no nome e edite)
5. Clique duas vezes para abrir o editor de código
6. **Apague todo o conteúdo** que veio por padrão
7. Cole o conteúdo completo do arquivo `ReplicatedStorage/GameConfig.lua`

> **Por que ReplicatedStorage?** Porque tanto o servidor quanto o cliente precisam ler essas configurações. O ReplicatedStorage é o único lugar acessível dos dois lados.

---

### Passo 3: Criar o MainServer (Script do servidor)

O MainServer controla **tudo que acontece no servidor**: spawnar brainrots nas bases, receber pedidos de roubo, calcular aura, salvar dados e gerenciar rebirths.

1. No Explorer, clique com o botão direito em **ServerScriptService**
2. Clique em **Insert Object**
3. Escolha **Script** (não LocalScript!)
4. Renomeie para **MainServer**
5. Apague o conteúdo padrão
6. Cole o conteúdo do arquivo `ServerScriptService/MainServer.lua`

> **Por que ServerScriptService?** Scripts aqui rodam APENAS no servidor, que é confiável. O cliente nunca pode mexer na lógica de aura diretamente — só o servidor faz isso, evitando trapaça.

---

### Passo 4: Criar o MapSetup (Script do servidor)

O MapSetup cria automaticamente o mapa: chão, paredes, as 12 bases com plataforma e indicador luminoso, e os caminhos decorativos.

1. No Explorer, clique com o botão direito em **ServerScriptService**
2. Clique em **Insert Object** → **Script**
3. Renomeie para **MapSetup**
4. Apague o conteúdo padrão
5. Cole o conteúdo do arquivo `ServerScriptService/MapSetup.lua`

> **Dica importante:** O MapSetup cria o mapa **toda vez que o servidor inicia**. Isso significa que se você quiser personalizar o mapa no Studio depois (adicionar árvores, construções, etc.), você pode ou editar o MapSetup ou excluí-lo e construir manualmente — mas aí precisa manter as 12 bases com os nomes `Base_1` até `Base_12`.

---

### Passo 5: Criar o MainGui (LocalScript da interface)

O MainGui cria toda a interface visual do jogador: painel de aura, botão de rebirth, prompt de roubo, sistema de notificações, o painel de Index e o banner da Lua de Sangue.

1. No Explorer, clique com o botão direito em **StarterGui**
2. Clique em **Insert Object**
3. Escolha **LocalScript**
4. Renomeie para **MainGui**
5. Apague o conteúdo padrão
6. Cole o conteúdo do arquivo `StarterGui/MainGui.lua`

> **Por que LocalScript?** A interface roda no computador de cada jogador individualmente. Um LocalScript em StarterGui executa uma vez quando o jogador entra no jogo e persiste mesmo quando o personagem morre.

---

### Passo 6: Criar o AuraEffect (LocalScript de efeitos)

O AuraEffect adiciona efeitos visuais no personagem do jogador: partículas de aura saindo do corpo, trilha colorida nos pés e flashes dourados no rebirth. A cor do efeito muda conforme o número de rebirths.

1. No Explorer, clique com o botão direito em **StarterCharacterScripts**
2. Clique em **Insert Object**
3. Escolha **LocalScript**
4. Renomeie para **AuraEffect**
5. Apague o conteúdo padrão
6. Cole o conteúdo do arquivo `StarterCharacterScripts/AuraEffect.lua`

> **Por que StarterCharacterScripts?** Scripts aqui são executados toda vez que o personagem aparece (spawn/respawn). É necessário para recriar os efeitos de partícula quando o personagem morre e renasce.

---

### Passo 7: Ativar o API de DataStore

Para o jogo salvar o progresso dos jogadores, você precisa ativar a permissão de DataStore:

1. No Studio, clique em **File** → **Game Settings** (ou **Home** → **Game Settings**)
2. Vá na aba **Security**
3. Ative a opção **Enable Studio Access to API Services**
4. Clique em **Save**

> **Importante:** Sem isso, o jogo não salva e você verá erros no Output. Quando publicar o jogo no Roblox, o DataStore funciona automaticamente em produção — essa opção é só para testar no Studio.

---

### Passo 8: Testar o jogo

1. Clique no botão **Play** (▶) no topo do Studio
2. Seu personagem vai aparecer na plataforma central amarela
3. Brainrots começarão a aparecer nas 12 bases ao redor do mapa
4. Caminhe até uma base e aperte **E** para roubar

---

## PARTE 2 — COMO JOGAR

### A Tela de Jogo

Quando você entrar no jogo, vai ver a seguinte interface:

```
┌─────────────────────────────────────────────────────────────┐
│  [Rebirths: 0]          ✦ AURA ✦                           │
│  [Mult: x1]          0 / 500                                │
│  [Roubados: 0]    ████████░░░░░░░░░░░░░░░░  (barra)        │
│  [Custo RB: 400]                                            │
│  [Última Mut: -]                         [📋 INDEX]         │
│                                                             │
│                     (mundo 3D aqui)                         │
│                                                             │
│           ┌─────────────────────────┐                       │
│           │ Nome do Brainrot        │  ← aparece quando    │
│           │ [Raridade] +X aura      │    você chega perto  │
│           │ ✦ Mutação ×N            │    de uma base       │
│           │ [E] Roubar              │                       │
│           └─────────────────────────┘                       │
│                                                             │
│              [RENASCER (0 / 400)]                           │
└─────────────────────────────────────────────────────────────┘
```

**Painel superior central** → mostra sua Aura atual, o limite (cap) e a barra de progresso.

**Painel esquerdo** → mostra seus stats: quantos rebirths tem, o multiplicador atual, total de brainrots roubados, o custo do próximo rebirth e a última mutação que pegou.

**Prompt de roubo** → aparece automaticamente quando você está a menos de 18 studs de uma base com brainrot. Mostra o nome, raridade, aura que vai ganhar e a mutação.

**Botão RENASCER** → fica cinza quando você não tem aura suficiente. Fica dourado e clicável quando você atingiu o custo do rebirth.

**Botão INDEX** → abre o painel de coleção no canto inferior esquerdo.

---

### As 12 Bases do Mapa

O mapa tem 12 bases distribuídas em dois anéis:

**Anel Externo** (8 bases, mais longe do centro):
- Base Leste, Base Nordeste, Base Norte, Base Noroeste
- Base Oeste, Base Sudoeste, Base Sul, Base Sudeste

**Anel Interno** (4 bases, mais perto do centro):
- Área Central A, B, C e D

Cada base tem:
- Uma **plataforma cilíndrica** onde você fica em pé para roubar
- Um **anel branco brilhante** na borda como decoração
- Um **indicador luminoso** (bolinha) que fica **cinza escuro quando vazia** e muda de cor para a cor da raridade quando tem um brainrot
- Um **número** gravado no chão e o **nome** em cima

**Como funciona o spawn:** A cada 2,5 segundos, o servidor escolhe uma base vazia aleatória e spawna um brainrot nela. No início do servidor, todas as 12 bases são preenchidas rapidamente. Máximo de 12 brainrots no mundo ao mesmo tempo (um por base).

Quando você rouba ou um brainrot desaparece (depois de 50 segundos sem ser roubado), o indicador da base volta a cinza e a base fica disponível para um novo spawn.

---

### Como Roubar um Brainrot

1. **Caminhe até uma base** que tenha o indicador aceso (colorido)
2. O **prompt de roubo** aparecerá na parte inferior da tela mostrando:
   - Nome do brainrot
   - Raridade e aura base
   - Mutação e multiplicador dela
3. Aperte **E** (PC) ou o **botão vermelho ROUBAR** (mobile/tablet)
4. Uma notificação aparece no canto direito mostrando quanto você ganhou

**Distância:** Você precisa estar a menos de **18 studs** da base. Se tentar de longe, vai aparecer a mensagem "Muito longe! Chegue mais perto da base."

---

## PARTE 3 — SISTEMAS DO JOGO

### Sistema de Raridades

Cada brainrot que spawna tem uma raridade sorteada aleatoriamente. Quanto mais rara, mais aura base ela dá:

| Raridade    | Cor           | Chance         | Aura Base          |
|-------------|---------------|----------------|--------------------|
| **Comum**   | Cinza         | ~45%           | 8 – 15             |
| **Incomum** | Verde         | ~28%           | 60 – 80            |
| **Raro**    | Azul          | ~15%           | 300 – 400          |
| **Épico**   | Roxo          | ~8%            | 1.500 – 2.000      |
| **Lendário**| Dourado       | ~3,3%          | 8.000 – 12.000     |
| **Mítico**  | Vermelho      | ~0,68%         | 50.000 – 75.000    |
| **God**     | Amarelo div.  | 1 em 5.000     | 500.000 – 1.000.000|
| **Secret**  | Ciano         | 1 em 111.000   | 5M – 12.000.000    |
| **OG**      | Branco puro   | 1 em 1.000.000 | 100.000.000        |

> A raridade **OG** tem apenas 1 brainrot: **"O ORIGINAL"** — dá 100 milhões de aura de uma vez.
> A raridade **Secret** tem nomes misteriosos: `???`, `Il Segreto Proibito`, `Ombra Senza Nome`.
> A raridade **God** tem: `Deus Supremo Tralala`, `Zeus Brainroticus`, `Divino Crocodilo Eterno`.

O indicador da base muda para a **cor da raridade** quando tem um brainrot, então você consegue ver de longe se vale a pena correr para aquela base.

---

### Sistema de Mutações

Além da raridade, **cada brainrot recebe uma mutação aleatória** no momento em que spawna. A mutação funciona como um **multiplicador de bônus** em cima da aura base:

| Mutação          | Cor           | Multiplicador | Chance    |
|------------------|---------------|---------------|-----------|
| **Básico**       | Cinza         | ×1            | 70%       |
| **Bronze**       | Marrom        | ×2            | 18%       |
| **Ouro**         | Dourado       | ×5            | 8%        |
| **Diamante**     | Azul claro    | ×10           | 3%        |
| **Esmeralda**    | Verde         | ×15           | 1%        |
| **Lua de Sangue**| Vermelho      | ×20           | especial* |

> *A **Lua de Sangue** não entra no sorteio normal. Ela aparece **a cada 10.000 brainrots spawned no servidor** e pode cair em qualquer raridade — até numa Comum!

**Como calcular a aura que você vai ganhar:**

```
Aura Final = Aura Base × Multiplicador da Mutação × Multiplicador do Rebirth
```

**Exemplo prático:**
- Você tem 3 rebirths (multiplicador ×8)
- Roubou um `Lirili Larila` (Raro, 300 aura base)
- Com mutação **Ouro** (×5)
- Aura ganha = 300 × 5 × 8 = **12.000 aura**

**Como identificar a mutação antes de roubar:**
- Olhe o prompt de roubo — ele mostra `✦ Nome da Mutação ×N`
- Cada mutação tem uma cor diferente no texto
- O billboard em cima do brainrot no mundo também mostra

**Quando a Lua de Sangue aparece:**
- Um **banner vermelho** pisca na tela de TODOS os jogadores: `🌑 LUA DE SANGUE apareceu em Base X! [Raridade] ×20 Aura!`
- Uma notificação especial grande aparece à direita
- O brainrot fica **vermelho** com brilho muito mais forte
- O indicador da base fica vermelho brilhante
- O **prompt de roubo pulsa em vermelho** quando você está perto dela
- É uma corrida: o primeiro que chegar rouba!

---

### Sistema de Aura

A **Aura** é a moeda principal do jogo. Ela representa seu poder acumulado.

**Cap de Aura (Limite):** Você tem um limite máximo de aura que pode guardar. No início é **500**. Quando você tenta roubar um brainrot mas já está no limite, aparece a mensagem `"Aura no limite! Faça rebirth para aumentar o cap."` — o brainrot não é roubado e você não perde nada.

**Barra de Progresso:** A barra muda de cor conforme enche:
- **Verde** (0% a 50%) → ainda tem bastante espaço
- **Amarelo** (50% a 85%) → chegando perto
- **Vermelho** (85% a 100%) → quase no limite, pense em fazer rebirth

**Leaderstats:** Sua Aura e número de Rebirths aparecem no leaderboard padrão do Roblox (canto superior direito da tela com a lista de jogadores).

---

### Sistema de Rebirth

O **Rebirth** (renascimento) é a mecânica central de progressão. Você troca sua Aura acumulada por poder permanente.

**Custo:** Para fazer rebirth, você precisa ter **80% do seu cap atual** em aura.

**O que acontece:**
- Sua Aura zera para 0
- Seu número de Rebirths sobe em +1
- O **cap de Aura** multiplica por 5
- O **multiplicador de ganho** multiplica por 2

**Progressão de Rebirths:**

| Rebirth | Cap de Aura   | Multiplicador | Custo do Rebirth |
|---------|---------------|---------------|------------------|
| 0       | 500           | ×1            | 400              |
| 1       | 2.500         | ×2            | 2.000            |
| 2       | 12.500        | ×4            | 10.000           |
| 3       | 62.500        | ×8            | 50.000           |
| 4       | 312.500       | ×16           | 250.000          |
| 5       | 1.562.500     | ×32           | 1.250.000        |
| 6       | 7.812.500     | ×64           | 6.250.000        |
| 7       | 39.062.500    | ×128          | 31.250.000       |
| 8       | 195.312.500   | ×256          | 156.250.000      |

> Com 8 rebirths você já consegue segurar **195 milhões** de aura e cada brainrot ganha 256 vezes mais!

**Como fazer Rebirth:**
1. Encha sua aura até 80% do cap (o botão RENASCER vai ficar **dourado**)
2. Clique no botão **RENASCER** na parte inferior da tela
3. Uma notificação dourada confirma o rebirth com seu novo cap e multiplicador
4. Seus efeitos visuais de aura mudam de cor (veja abaixo)

**Efeitos visuais por Rebirth:**

| Rebirths | Cor do Efeito   | Equivalência     |
|----------|-----------------|------------------|
| 0        | Cinza           | (sem efeito)     |
| 1        | Verde           | Incomum          |
| 2        | Azul            | Raro             |
| 3        | Roxo            | Épico            |
| 4        | Dourado         | Lendário         |
| 5        | Vermelho        | Mítico           |
| 6        | Amarelo divino  | God              |
| 7        | Ciano           | Secret           |
| 8+       | Branco puro     | OG               |

No rebirth ocorre um **flash dourado** ao redor do personagem.

---

### Sistema de Index (📋)

O Index é sua **coleção pessoal** de brainrots e mutações. Funciona como um Pokédex do jogo.

**Como abrir:** Clique no botão **📋 INDEX** no canto inferior esquerdo da tela.

**Aba Brainrots:**
- Todos os brainrots do jogo aparecem agrupados por raridade
- Cada raridade tem um cabeçalho colorido com o nome em caixa alta
- Cada entrada mostra:
  - **Barra lateral colorida** com a cor da raridade
  - **Nome** do brainrot (ou `???` se você nunca roubou um)
  - **Aura base** no canto direito
  - **Quantas vezes roubou** (Roubados: X)
  - **Melhor mutação** que já pegou nele (Melhor: Nome)
- Entradas não descobertas ficam escuras e sem informações
- À medida que você rouba, as entradas vão se iluminando

**Aba Mutações:**
- Todas as 6 mutações são listadas
- Cada uma mostra:
  - **Bolinha colorida** com a cor da mutação
  - **Nome** com prefixo ✦ (ou 🌑 para Lua de Sangue)
  - **Multiplicador** (×1, ×2, ×5, ×10, ×15, ×20)
  - **Quantas vezes obtida** (ou "Não obtida" se nunca pegou)
  - Lua de Sangue tem nota especial: `"a cada 10.000 spawns"`

**O Index salva:** Suas descobertas ficam salvas no DataStore junto com seus outros dados. Ao entrar no jogo novamente, seu Index carrega automaticamente.

---

### Salvamento de Dados

O progresso é salvo **automaticamente a cada 60 segundos** e também **quando você sai do jogo**. O que é salvo:

- Quantidade de Aura atual
- Número de Rebirths
- Total de brainrots roubados
- Index completo (quais brainrots descobriu, quantas vezes, melhor mutação de cada)

Os dados ficam no **DataStore "BrainrotAuraV3"** do Roblox.

---

## PARTE 4 — CONTROLES

| Ação            | Teclado / PC    | Mobile / Tablet          |
|-----------------|-----------------|--------------------------|
| Roubar brainrot | Tecla **E**     | Botão vermelho **ROUBAR** (canto inferior direito, aparece quando perto) |
| Abrir Index     | Clique **📋 INDEX** | Toque **📋 INDEX** |
| Fazer Rebirth   | Clique **RENASCER** | Toque **RENASCER** |
| Fechar Index    | Clique **✕**    | Toque **✕**             |
| Mudar aba Index | Clique na aba   | Toque na aba             |

---

## PARTE 5 — CUSTOMIZAÇÃO

Você pode editar o arquivo `GameConfig.lua` para ajustar qualquer coisa sem precisar mexer nos outros scripts.

### Adicionar um novo brainrot

No bloco `BRAINROT_TYPES`, adicione uma linha na raridade desejada:

```lua
{ name = "Seu Brainrot Aqui", rarity = "Raro", baseAura = 500 },
```

Os campos:
- `name` → nome que aparece no jogo e no Index
- `rarity` → deve ser exatamente: `"Comum"`, `"Incomum"`, `"Raro"`, `"Epico"`, `"Lendario"`, `"Mitico"`, `"God"`, `"Secret"` ou `"OG"`
- `baseAura` → aura antes dos multiplicadores

### Mudar as chances de raridade

No bloco `RARITY_WEIGHTS`, aumente o número para ficar mais comum ou diminua para ficar mais raro. Os valores são relativos entre si:

```lua
GameConfig.RARITY_WEIGHTS = {
    Comum    = 450000, -- ← aumente para spawnar mais Comum
    Raro     = 150000, -- ← diminua para Raro ficar menos frequente
    -- etc.
}
```

### Mudar o cap inicial de Aura

```lua
GameConfig.BASE_AURA_CAP = 500  -- ← mude aqui (padrão: 500)
```

### Mudar o multiplicador do cap por Rebirth

```lua
GameConfig.AURA_CAP_MULTIPLIER = 5  -- ← padrão: 5 (cap ×5 a cada rebirth)
```

### Mudar o multiplicador de ganho por Rebirth

```lua
GameConfig.AURA_GAIN_MULTIPLIER = 2  -- ← padrão: 2 (ganho ×2 a cada rebirth)
```

### Mudar o intervalo da Lua de Sangue

```lua
GameConfig.LUA_DE_SANGUE_INTERVAL = 10000  -- ← padrão: 10.000 spawns
```
Coloque `100` para testar, depois volte para `10000` na produção.

### Mudar os multiplicadores das mutações

No bloco `MUTATIONS`:
```lua
{ name = "Ouro", multiplier = 5, ... },  -- ← troque o 5 pelo valor desejado
```

### Adicionar mais bases

No bloco `BASE_POSITIONS`, adicione novas posições `Vector3.new(X, 1.5, Z)` e no bloco `BASE_NAMES` adicione o nome correspondente na mesma posição. Também atualize `MAX_BRAINROTS` para o novo total de bases.

### Mudar o tamanho do mapa

No `MapSetup.lua`, os valores `280` e `142` nos paredes e chão controlam o tamanho. Coordene com as posições das bases no GameConfig.

---

## PARTE 6 — SOLUÇÃO DE PROBLEMAS

### O jogo não salva

**Causa:** A API de DataStore não está ativada.

**Solução:**
1. `File` → `Game Settings` → aba `Security`
2. Ative **Enable Studio Access to API Services**
3. Reinicie o teste (clique Stop e Play novamente)

---

### Os brainrots não aparecem

**Causa mais comum:** O `MainServer.lua` não está no `ServerScriptService` ou está com erro.

**Como verificar:**
1. Abra o painel **Output** (`View` → `Output`)
2. Procure por `[BrainrotRoubo] Servidor iniciado! Bases: 12` — se não aparecer, há um erro
3. Erros em vermelho no Output indicam o problema

**Outras causas:**
- O `GameConfig` não está em `ReplicatedStorage` ou não se chama exatamente `GameConfig`
- Tem outro script no jogo com conflito

---

### A interface não aparece

**Causa:** O `MainGui.lua` não está no `StarterGui` ou é um `Script` em vez de `LocalScript`.

**Solução:**
1. No Explorer, verifique que dentro de `StarterGui` tem um **LocalScript** chamado `MainGui`
2. O ícone de LocalScript tem uma seta azul (→), Script normal tem um papel branco

---

### Não consigo apertar E para roubar

**Causas possíveis:**
1. Você está longe demais da base (precisa de menos de 18 studs)
2. Sua Aura está no limite (cap) — faça rebirth
3. O brainrot que estava na base foi roubado por outro jogador ou desapareceu enquanto você andava até lá

---

### Os efeitos de aura não aparecem

**Causa:** O `AuraEffect.lua` não está no `StarterCharacterScripts` ou é um `Script` em vez de `LocalScript`.

**Solução:** Verifique que dentro de `StarterCharacterScripts` tem um **LocalScript** chamado `AuraEffect`.

Os efeitos só aparecem quando você tem aura > 10% do cap ou fez pelo menos 1 rebirth.

---

### "Muito longe!" aparece mesmo estando perto

**Causa:** Lag de rede entre o cliente e o servidor. O servidor recalcula a distância e pode discordar do cliente por alguns studs.

**Solução:** A tolerância já é de +4 studs além do `STEAL_RANGE`. Se persistir, aumente o valor em `GameConfig.lua`:
```lua
GameConfig.STEAL_RANGE = 22  -- ← aumente (padrão: 18)
```

---

### O Index não mostra nada

**Causa:** Você ainda não roubou nenhum brainrot. Entradas não descobertas ficam como `???`.

**Isso é normal.** Quanto mais você roubar, mais entradas aparecem coloridas no Index.

---

### A Lua de Sangue nunca aparece

**Isso é intencional.** Ela aparece somente a cada **10.000 brainrots spawned** no servidor desde que ele iniciou. Num servidor normal de Roblox isso pode levar horas.

**Para testar no Studio:**
1. Abra `GameConfig.lua`
2. Mude `LUA_DE_SANGUE_INTERVAL = 10000` para `LUA_DE_SANGUE_INTERVAL = 10`
3. Teste, depois volte para 10.000 antes de publicar

---

## RESUMO RÁPIDO (Cheat Sheet)

```
FÓRMULA DE AURA:
Aura Ganha = Aura Base × Mutação × Rebirth Mult

REBIRTH:
Custo = 80% do Cap atual
Cap × 5 a cada rebirth
Mult × 2 a cada rebirth

LUA DE SANGUE:
Aparece a cada 10.000 spawns no servidor
Multiplicador ×20 — melhor mutação do jogo
Anúncio global para todos os jogadores

INDEX:
Botão 📋 INDEX (canto inferior esquerdo)
Aba Brainrots: todos os 25 brainrots por raridade
Aba Mutações: as 6 mutações com stats

CONTROLES:
E → roubar (PC)
Botão ROUBAR → roubar (mobile)
Botão RENASCER → fazer rebirth
```

---

*Tutorial gerado para a versão final do Brainrot Roubo — todos os sistemas: raridades, mutações, Lua de Sangue, bases, Index e Rebirth.*
