# Padrões de orquestração

Catálogo de referência de padrões de orquestração de agentes que este repositório adota, mais antipadrões a evitar. Leia antes de adicionar um novo comando slash que coordene várias personas, ou antes de introduzir uma nova persona que “empacota” as existentes.

A regra mestra: **o usuário (ou um comando slash) é o orquestrador. Personas não invocam outras personas.** Skills são passos obrigatórios dentro do fluxo de uma persona.

---

## Padrões recomendados

### 1. Invocação direta (sem orquestração)

Uma persona, um ponto de vista, um artefato. O padrão padrão e o mais barato.

```
usuário → code-reviewer → relatório → usuário
```

**Use quando:** o trabalho for um ponto de vista sobre um artefato e puder ser descrito em uma frase.

**Exemplos:**
- “Revisar este PR” → `code-reviewer`
- “Achar problemas de segurança em `auth.ts`” → `security-auditor`
- “Quais testes faltam no fluxo de checkout?” → `test-engineer`

**Custo:** uma ida e volta. A linha de base com a qual os padrões orquestrados devem ser comparados.

---

### 2. Comando slash de uma persona

Um comando slash que envolve uma persona com as skills do projeto. Poupa o usuário de reexplicar o fluxo toda vez.

```
/review → code-reviewer (com skill code-review-and-quality) → relatório
```

**Use quando:** a mesma invocação de uma única persona se repetir com a mesma configuração.

**Exemplos neste repositório:** `/review`, `/test`, `/code-simplify`.

**Custo:** igual à invocação direta. O comando slash é só um prompt salvo.

**Sinal de alerta:** se o corpo do comando for sobretudo “decida qual persona chamar”, apague e deixe o usuário chamar a persona diretamente.

---

### 3. Fan-out paralelo com consolidação

Várias personas operam na mesma entrada em paralelo, cada uma produzindo um relatório independente. Um passo de consolidação (no contexto do agente principal) sintetiza tudo numa única decisão.

```
                    ┌─→ code-reviewer    ─┐
/ship → fan-out  ───┼─→ security-auditor ─┤→ merge → go/no-go + rollback
                    └─→ test-engineer    ─┘
```

**Use quando:**
- As subtarefas são genuinamente independentes (sem estado mutável compartilhado, sem dependência de ordem)
- Cada subagente se beneficia de sua própria janela de contexto
- O passo de consolidação é pequeno o suficiente para caber no contexto principal
- O tempo de parede importa

**Exemplos neste repositório:** `/ship`.

**Custo:** N contextos de subagente paralelos + um turno de consolidação. Maior que invocação direta, porém em geral mais rápido em tempo de parede e produz relatórios melhores porque cada subagente fica focado.

**Checklist de validação antes de adotar o padrão:**
- [ ] Dá para rodar todos os subagentes ao mesmo tempo sem problema de ordem?
- [ ] Cada persona produz um *tipo* diferente de achado, não o mesmo achado de outro ângulo?
- [ ] O passo de consolidação cabe no contexto restante do agente principal?
- [ ] O tempo de espera do usuário é longo o bastante para o paralelismo valer a pena?

Se alguma resposta for “não,” volte à invocação direta ou a um comando de uma única persona.

---

### 4. Pipeline sequencial com comandos slash conduzidos pelo usuário

O usuário executa comandos slash em ordem definida, carregando contexto (ou histórico de commits) entre eles. Não há agente orquestrador — o **usuário** é o orquestrador.

```
usuário executa:  /spec  →  /plan  →  /build  →  /test  →  /review  →  /ship
```

**Use quando:** o fluxo tiver dependências (cada passo precisa da saída do anterior) e julgamento humano entre passos agregar valor.

**Exemplos neste repositório:** o ciclo DEFINE → PLAN → BUILD → VERIFY → REVIEW → SHIP inteiro.

**Custo:** um contexto de subagente por passo. “Grátis” na camada de orquestração porque não há agente orquestrador.

**Por que não automatizar:** um LLM “orquestrador de ciclo de vida” (a) perde nuance entre passos ao resumir para hand-off, (b) pula checkpoints humanos que pegam trabalho na direção errada cedo, e (c) dobra o custo em tokens com reformulações.

---

### 5. Isolamento de pesquisa (preservação de contexto)

Quando a tarefa exige ler muito material que não deve poluir o contexto principal, dispare um subagente de pesquisa que devolve só um resumo.

```
agente principal → subagente de pesquisa (lê 50 arquivos) → resumo → agente principal continua
```

**Use quando:**
- A sessão principal precisa ficar focada numa tarefa à frente
- O resultado da investigação é muito menor que a entrada que consome
- A qualidade da decisão melhora com espaço no contexto principal depois da leitura

**Exemplos:** “Achar todos os call sites desta API deprecada no monorepo”, “Resumir o que estes 30 ADRs dizem sobre cache”.

**Custo:** um contexto isolado de subagente. Vale sempre que a alternativa seja carregar centenas de arquivos no contexto principal.

**No Claude Code, use o subagente `Explore` embutido** em vez de definir uma persona de pesquisa customizada. `Explore` roda em Haiku, não tem ferramentas de escrita/edição e foi feito para esse padrão. Defina pesquisa custom só quando `Explore` não servir (ex.: você precisa de um system prompt de domínio que o modelo não inferiria).

---

## Compatibilidade com Claude Code

Este catálogo é independente do harness, mas a maioria dos leitores usará Claude Code. Segue como cada padrão se mapeia nos primitivos da plataforma — e onde ela impõe nossas regras.

### Onde ficam as personas

Subagentes de plugin ficam em `agents/` na raiz do plugin. Este repositório é um plugin (`.claude-plugin/plugin.json`), então `agents/code-reviewer.md`, `agents/security-auditor.md` e `agents/test-engineer.md` são descobertos automaticamente quando o plugin está habilitado. Sem configuração de caminho.

### Subagentes vs. Agent Teams

O Claude Code tem dois primitivos de paralelismo. O padrão 3 (fan-out paralelo com merge) mapeia para **subagentes**. Se precisar de colegas que conversam entre si, use **Agent Teams**.

| | Subagentes | Agent Teams |
|--|------------|---------------|
| Coordenação | Agente principal faz fan-out; subagentes só reportam de volta | Colegas trocam mensagens, compartilham lista de tarefas |
| Contexto | Janela própria por subagente | Janela própria por colega |
| Quando usar | Tarefas independentes que geram relatórios | Trabalho colaborativo que precisa discussão |
| Status | Estável | Experimental — exige `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` |
| Custo | Menor | Maior — cada colega é uma instância Claude separada |

**As personas deste repositório funcionam nos dois modos.** Quando disparadas como subagentes (ex.: por `/ship`), reportam achados à sessão principal. Quando disparadas como colegas (`Spawn a teammate using the security-auditor agent type…`), podem contestar achados umas das outras diretamente. A definição da persona é a mesma; só muda o contexto de spawn.

Um detalhe: os campos `skills` e `mcpServers` no frontmatter da persona são respeitados quando roda como subagente, mas **ignorados como teammate** — colegas carregam skills e MCP das configurações de projeto e usuário, como uma sessão normal. Se uma persona depende de uma skill ou MCP específico, configure no nível da sessão para ficar disponível nos dois modos.

### Regras impostas pela plataforma

Duas regras deste catálogo não são só convenção — o Claude Code as impõe:

- **“Subagentes não podem criar outros subagentes”** (literal dos docs). O antipadrão B (persona chama persona) e o D (árvores profundas de personas) não existem na prática no Claude Code.
- **“Sem times aninhados”** — colegas não criam seus próprios times. Os mesmos antipadrões ficam bloqueados no nível de time.

Isso significa que você pode adotar os padrões deste catálogo sem medo de contribuidores montarem acidentalmente os antipadrões — eles simplesmente não carregam.

### Subagentes embutidos a conhecer

Antes de definir um subagente customizado, veja se um destes cobre o papel:

| Embutido | Finalidade |
|----------|------------|
| `Explore` | Busca e análise read-only no código. Use para o padrão 5 (isolamento de pesquisa). |
| `Plan` | Pesquisa read-only durante o modo plano. |
| `general-purpose` | Tarefas multi-etapa que precisam explorar e modificar. |

Não redefina esses papéis. Empilhe suas personas especialistas (`code-reviewer`, `security-auditor`, `test-engineer`) sobre eles.

### Restrições de frontmatter em agentes de plugin

Subagentes de plugin **não** suportam os campos `hooks`, `mcpServers` ou `permissionMode` no frontmatter — são ignorados silenciosamente. Se uma persona futura precisar de algum deles, o usuário deve copiar o arquivo para `.claude/agents/` ou `~/.claude/agents/`.

Os campos que **funcionam** em agentes de plugin são: `name`, `description`, `tools`, `disallowedTools`, `model`, `maxTurns`, `skills`, `memory`, `background`, `effort`, `isolation`, `color`, `initialPrompt`. Use `model` por persona para otimizar custo (ex.: Haiku para varreduras do `test-engineer`, Sonnet para `code-reviewer`, Opus para `security-auditor`).

### Disparar vários subagentes em paralelo

No Claude Code, fan-out paralelo (padrão 3) exige emitir **várias chamadas à ferramenta Agent num único turno do assistente**. Turnos sequenciais serializam a execução. `/ship` deixa isso explícito. Qualquer novo comando orquestrador deve fazer o mesmo.

---

## Exemplo trabalhado: Agent Teams para depuração com hipóteses concorrentes

Este exemplo mostra quando usar **Agent Teams** em vez do fan-out de subagentes do `/ship`. Os dois padrões parecem parecidos — os mesmos três tipos de persona — mas o valor vem de outro lugar.

### O cenário

> *O checkout às vezes trava ~30 segundos antes de concluir. Ocorre cerca de uma vez a cada 50 sessões. Sem erros nos logs. Começou após o release da semana passada.*

Causas plausíveis (mutuamente exclusivas, todas cabem nos sintomas):

1. Condição de corrida no novo fluxo de confirmação de pagamento
2. Verificação de auth que ocasionalmente cai numa chamada de rede síncrona lenta
3. Índice faltando numa query que escala com o tamanho do carrinho
4. API de terceiros instável onde o SDK refaz tentativas em silêncio antes do timeout

Um único agente escolhe a primeira teoria plausível e para de investigar. Um fan-out estilo `/ship` faria cada persona reportar de forma independente — mas os relatórios nunca se encontram, então nada elimina as teorias erradas.

É exatamente o caso que os docs de Agent Teams descrevem: *“Com vários investigadores independentes tentando refutar uns aos outros, a teoria que sobrevive tem muito mais chance de ser a causa raiz real.”*

### Por que isso **não** é trabalho para `/ship`

| | `/ship` (subagentes) | Agent Teams |
|--|----------------------|-------------|
| Subagentes veem | O mesmo diff, lentes diferentes | Lista de tarefas compartilhada, mensagens uns dos outros |
| Saída | Três relatórios independentes → um merge | Debate adversarial → consenso na causa raiz |
| Certo quando | Você quer veredito sobre um artefato conhecido | Você quer *achar* o artefato entre hipóteses |

`/ship` é um veredito; Agent Teams é uma investigação.

### Configuração (uma vez, por ambiente)

Agent Teams é experimental. Em `~/.claude/settings.json`:

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

Exige Claude Code v2.1.32 ou superior. As personas deste repositório são carregadas automaticamente — sem arquivos de configuração de time à mão.

### O prompt de disparo

Digite na sessão principal, em linguagem natural:

```
Users report checkout hangs for ~30 seconds intermittently after last
week's release. No errors in logs.

Create an agent team to debug this with competing hypotheses. Spawn
three teammates using the existing agent types:

  - code-reviewer  — investigate race conditions and blocking calls
                     in the checkout code path
  - security-auditor — investigate auth checks, session handling,
                       and any synchronous network calls added recently
  - test-engineer  — propose tests that would distinguish between the
                     hypotheses and check coverage gaps in checkout

Have them message each other directly to challenge each other's
theories. Update findings as consensus emerges. Only converge when
two teammates agree they can disprove the others'.
```

O líder cria três colegas referenciando os nomes das personas existentes. O corpo da persona é **anexado** ao system prompt de cada colega como instruções extras (além das instruções de coordenação de time que o líder instala); o prompt acima vira a tarefa deles.

### O que acontece

1. Cada colega roda em sua própria janela de contexto, explorando o código pela sua lente.
2. Colegas usam `message` para enviar achados uns aos outros diretamente. O líder não precisa retransmitir.
3. A lista de tarefas compartilhada mostra quem investiga o quê — visível a qualquer momento com `Ctrl+T` (modo in-process) ou num painel tmux (modo split).
4. Quando `code-reviewer` acha um `Promise.all` que deveria ser sequencial, manda mensagem a `security-auditor` para confirmar se a chamada de auth não faz parte da corrida. `security-auditor` verifica e responde — confirmando a corrida como causa real ou trazendo contraevidência.
5. `test-engineer` propõe um teste de integração focado na teoria que está ganhando, que o time usa para verificar antes de declarar consenso.
6. O líder sintetiza o achado convergente e apresenta a você.

Você pode interromper qualquer colega com `Shift+Down` e digitando — útil para redirecionar um investigador que foi por um caminho errado.

### Quando encerrar

Quando a investigação chegar numa causa raiz, diga ao líder:

```
Clean up the team
```

Sempre encerre pelo líder, não por um colega (segundo os docs: colegas não têm contexto completo do time para cleanup).

### Expectativa de custo

Três colegas Sonnet rodando ~10–15 minutos de investigação custam bem mais que as mesmas três personas como subagentes do `/ship`. A justificativa é *qualidade da conclusão* — em depuração de produção onde o conserto errado é caro, os tokens extras compensam. Para revisão de PR rotineira, fique no `/ship`.

### Antipadrão neste cenário

**Não** reconstrua isso como comando `/debug` que faz fan-out de subagentes. Subagentes não podem mandar mensagens entre si — você perderia o debate adversarial que faz o padrão funcionar. Se um fluxo voltar a aparecer, documente o prompt de disparo acima como snippet em vez de embrulhar num comando slash que usa subagentes de forma errada.

### Quando **não** usar Agent Teams

- Veredito em produção sobre um diff conhecido → use `/ship` (subagentes).
- Um especialista num artefato → invocação direta da persona.
- Ciclo sequencial (spec → plan → build) → comandos slash conduzidos pelo usuário (padrão 4).
- Pesquisa pesada de leitura com resumo pequeno → subagente `Explore` embutido.

Use Agent Teams só quando os colegas **precisem** se contestar para chegar à resposta certa.

---

## Antipadrões

### A. Persona roteadora (“meta-orquestrador”)

Persona cuja função é decidir qual outra persona chamar.

```
/work → router-persona → "this needs a review" → code-reviewer → router (paraphrases) → user
```

**Por que falha:**
- Camada pura de roteamento sem valor de domínio
- Duas etapas de paráfrase → perda de informação + ~2× custo em tokens
- O usuário já sabia que queria revisão; poderia ter chamado `/review` direto
- Replica o que comandos slash e o mapeamento de intenção em `AGENTS.md` já fazem

**O que fazer:** adicionar ou refinar comandos slash. Documentar intenção → comando em `AGENTS.md`.

---

### B. Persona que chama outra persona

Um `code-reviewer` que internamente invoca `security-auditor` quando vê código de auth.

**Por que falha:**
- Personas foram feitas para um único ponto de vista; encadear derrota isso
- O resumo que a persona chamadora passa perde contexto que a chamada precisa
- Modos de falha se multiplicam (qual formato de saída ganha? de quem são as regras?)
- Esconde custo do usuário

**O que fazer:** a persona chamadora *recomenda* auditoria complementar no relatório. O usuário ou um comando slash executa a segunda passagem.

---

### C. Orquestrador sequencial que paráfraseia

Agente que chama `/spec`, depois `/plan`, depois `/build`, etc. em nome do usuário.

**Por que falha:**
- Perde checkpoints humanos que pegam trabalho na direção errada
- Cada hand-off resume contexto — deriva acumulada num pipeline longo
- Dobra custo em tokens: turno do orquestrador + turno do subagente a cada passo
- Retira agência do usuário exatamente onde o julgamento mais importa

**O que fazer:** manter o usuário como orquestrador. Documentar a sequência recomendada no `README.md` e deixar o usuário invocar.

---

### D. Árvores profundas de personas

`/ship` chama `pre-ship-coordinator` que chama `quality-coordinator` que chama `code-reviewer`.

**Por que falha:**
- Cada camada soma latência e tokens sem valor de decisão
- Depuração vira investigação multínivel
- Personas folha perdem contexto por várias etapas de sumarização

**O que fazer:** manter profundidade de orquestração no máximo 1 (comando slash → personas). A consolidação fica no agente principal.

---

## Fluxo de decisão

Ao considerar um novo fluxo orquestrado, percorra:

```
O trabalho é um ponto de vista sobre um artefato?
├── Sim → Invocação direta. Pare.
└── Não → A mesma composição vai se repetir?
         ├── Não → Invocação direta, ad hoc. Pare.
         └── Sim → As subtarefas são independentes?
                  ├── Não → Comandos slash sequenciais pelo usuário (padrão 4).
                  └── Sim → Fan-out paralelo com merge (padrão 3).
                           Validar com o checklist acima.
                           Se alguma verificação falhar → voltar ao comando de uma persona (padrão 2).
```

---

## Quando adicionar um novo padrão a este catálogo

Só acrescente entrada nova depois de:

1. Ter usado o padrão pelo menos duas vezes em trabalho real
2. Poder nomear um artefato concreto neste repositório que o demonstre
3. Explicar por que um padrão existente não teria funcionado
4. Descrever o “antipadrão sombra” (o que as pessoas vão construir por engano)

Entradas prematuras viram documentação aspiracional que ninguém segue.
