---
name: incremental-implementation
description: Entrega mudanças de forma incremental. Use ao implementar qualquer funcionalidade ou alteração que afete mais de um arquivo. Use quando estiver prestes a escrever uma grande quantidade de código de uma só vez ou quando uma tarefa parecer grande demais para ser finalizada em um único passo.
---

# Implementação Incremental

## Visão Geral

Construa em "fatias verticais" finas — implemente uma parte, teste, verifique e então expanda. Evite implementar uma funcionalidade inteira de uma só vez. Cada incremento deve deixar o sistema em um estado funcional e testável. Esta é a disciplina de execução que torna grandes funcionalidades gerenciáveis.

## Quando Usar

- Ao implementar qualquer mudança em múltiplos arquivos.
- Ao construir uma nova funcionalidade a partir de um detalhamento de tarefas.
- Ao refatorar código existente.
- Sempre que você sentir a tentação de escrever mais de ~100 linhas antes de testar.

**Quando NÃO usar:** Mudanças em um único arquivo ou função onde o escopo já é mínimo.

## O Ciclo de Incremento

```
┌──────────────────────────────────────┐
│                                      │
│   Implement ──→ Test ──→ Verify ──┐  │
│       ▲                           │  │
│       └───── Commit ◄─────────────┘  │
│              │                       │
│              ▼                       │
│          Next slice                  │
│                                      │
└──────────────────────────────────────┘
```

Para cada fatia:

1. **Implemente** a menor peça completa de funcionalidade.
2. **Teste** — execute a suíte de testes (ou escreva um teste se não existir).
3. **Verifique** — confirme que a fatia funciona como esperado (testes passam, build com sucesso, verificação manual).
4. **Commit** — salve seu progresso com uma mensagem descritiva (consulte `git-workflow-and-versioning` para orientações sobre commits atômicos).
5. **Mova para a próxima fatia** — siga em frente, não recomece.

## Estratégias de Fatiamento

### Fatias Verticais (Preferido)

Construa um caminho completo através da stack:

```
Fatia 1: Criar uma tarefa (DB + API + UI básica)
    → Testes passam, usuário pode criar uma tarefa via UI

Fatia 2: Listar tarefas (Query + API + UI)
    → Testes passam, usuário pode ver suas tarefas

Fatia 3: Editar uma tarefa (Update + API + UI)
    → Testes passam, usuário pode modificar tarefas

Fatia 4: Excluir uma tarefa (Delete + API + UI + confirmação)
    → Testes passam, CRUD completo finalizado
```

Cada fatia entrega uma funcionalidade ponta-a-ponta funcional.

### Fatiamento "Contract-First" (Contrato Primeiro)

Quando o backend e o frontend precisam se desenvolver em paralelo:

```
Fatia 1: Provar que a conexão WebSocket funciona (maior risco)
Fatia 2: Construir atualizações de tarefas em tempo real na conexão provada
Fatia 3: Adicionar suporte offline e reconexão
```

### Risk-First Slicing

Tackle the riskiest or most uncertain piece first:

```
Slice 1: Prove the WebSocket connection works (highest risk)
Slice 2: Build real-time task updates on the proven connection
Slice 3: Add offline support and reconnection
```

Se a Fatia 1 falhar, você descobre antes de investir nas Fatias 2 e 3.

## Regras de Implementação

### Regra 0: Simplicidade Primeiro

Antes de escrever qualquer código, pergunte-se: "Qual é a coisa mais simples que poderia funcionar?"

Após escrever o código, revise-o contra estes pontos:
- Isso pode ser feito em menos linhas?
- Essas abstrações justificam sua complexidade?
- Um engenheiro sênior olharia para isso e diria "por que você simplesmente não fez..."?
- Estou construindo para requisitos futuros hipotéticos ou para a tarefa atual?

```
CHECK DE SIMPLICIDADE:
✗ EventBus genérico com pipeline de middleware para uma única notificação
✓ Chamada de função simples

✗ Padrão Abstract Factory para dois componentes similares
✓ Dois componentes diretos com utilitários compartilhados

✗ Construtor de formulários baseado em config para apenas três formulários
✓ Três componentes de formulário individuais
```

Três linhas de código similares são melhores do que uma abstração prematura. Implemente a versão ingênua e obviamente correta primeiro. Otimize apenas após a correção ser provada com testes.

### Regra 0.5: Disciplina de Escopo

Toque apenas no que a tarefa exige.

NÃO faça:
- "Limpeza" de código adjacente à sua mudança.
- Refatoração de imports em arquivos que você não está modificando.
- Remoção de comentários que você não entende completamente.
- Adição de funcionalidades fora da especificação porque "parecem úteis".
- Modernização de sintaxe em arquivos que você está apenas lendo.

Se notar algo que vale a pena melhorar fora do escopo da tarefa, anote — não conserte:

```
NOTADO, MAS NÃO ALTERADO:
- src/utils/format.ts tem um import não utilizado (irrelevante para esta tarefa)
- O middleware de autenticação poderia usar mensagens de erro melhores (tarefa separada)
→ Quer que eu crie tarefas para isso?

```
### Regra 1: Uma Coisa de Cada Vez

Cada incremento altera uma coisa lógica. Não misture preocupações:

**Ruim:** Um único commit que adiciona um novo componente, refatora um existente e atualiza a configuração de build.

**Bom:** Três commits separados — um para cada mudança.

### Regra 2: Mantenha o Código Compilável

Após cada incremento, o projeto deve buildar e os testes existentes devem passar. Não deixe a base de código em um estado quebrado entre as fatias.

### Regra 3: Feature Flags para Funcionalidades Incompletas

Se uma funcionalidade não está pronta para os usuários, mas você precisa mesclar (merge) os incrementos:

```typescript
// Feature flag para trabalho em progresso
const ENABLE_TASK_SHARING = process.env.FEATURE_TASK_SHARING === 'true';

if (ENABLE_TASK_SHARING) {
  // Nova UI de compartilhamento
}
```

Isso permite que você envie pequenos incrementos para a branch principal sem expor trabalho incompleto.

### Regra 4: Padrões Seguros

O novo código deve ter como padrão um comportamento seguro e conservador:

```typescript
// Safe: disabled by default, opt-in
export function createTask(data: TaskInput, options?: { notify?: boolean }) {
  const shouldNotify = options?.notify ?? false;
  // ...
}
```

### Regra 5: Amigável a Reversões (Rollback-Friendly)

Cada incremento deve ser independentemente reversível:

- Mudanças aditivas (novos arquivos, novas funções) são fáceis de reverter.
- Modificações em código existente devem ser mínimas e focadas.
- Migrações de banco de dados devem ter migrações de rollback correspondentes.
- Evite deletar algo em um commit e substituí-lo no mesmo commit — separe-os.

## Trabalhando com IAs (Agents)

Ao direcionar um agente para implementar incrementalmente:

```
"Vamos implementar a Tarefa 3 do plano.

Comece apenas com a mudança no esquema do banco de dados e o endpoint da API.
Não toque na UI ainda — faremos isso no próximo incremento.

Após implementar, execute `npm test` e `npm run build` para verificar se nada foi quebrado."
```

Seja explícito sobre o que está no escopo e o que NÃO está no escopo para cada incremento.

## Checklist de Incremento

Após cada incremento, verifique:

- [ ] A mudança faz apenas uma coisa e a faz completamente.
- [ ] Todos os testes existentes ainda passam (npm test).
- [ ] O build tem sucesso (npm run build).
- [ ] A checagem de tipos passa (npx tsc --noEmit).
- [ ] O linting passa (npm run lint).
- [ ] A nova funcionalidade funciona como esperado.
- [ ] A mudança foi commitada com uma mensagem descritiva.

## Racionalizações Comuns

| Racionalização | Realidade |
| :--- | :--- |
| **"Vou testar tudo no final"** | Bugs se acumulam. Um bug na Fatia 1 torna as Fatias 2-5 erradas. Teste cada fatia. |
| **"É mais rápido fazer tudo de uma vez"** | Parece mais rápido até que algo quebra e você não consegue encontrar qual das 500 linhas alteradas causou o erro. |
| **"Essas mudanças são pequenas demais para commits separados"** | Commits pequenos são gratuitos. Commits grandes escondem bugs e tornam reversões dolorosas. |
| **"Eu adiciono a feature flag depois"** | Se a funcionalidade não está completa, não deve estar visível ao usuário. Adicione a flag agora. |
| **"Esta refatoração é pequena o suficiente para incluir"** | Refatorações misturadas com funcionalidades tornam ambas difíceis de revisar e debugar. Separe-as. |

## Sinais de Alerta (Red Flags)

* Mais de 100 linhas de código escritas sem executar testes.
* Múltiplas mudanças não relacionadas em um único incremento.
* Expansão de escopo do tipo "deixa eu adicionar isso aqui rapidinho também".
* Pular a etapa de teste/verificação para ir mais rápido.
* Build ou testes quebrados entre incrementos.
* Grandes mudanças não commitadas se acumulando.
* Construção de abstrações antes que o terceiro caso de uso exija.
* Alterar arquivos fora do escopo da tarefa "já que estou aqui".
* Criar novos arquivos de utilitários para operações de uso único.

## Verificação

Após completar todos os incrementos de uma tarefa:

- [ ] Cada incremento foi testado individualmente e commitado.
- [ ] A suíte completa de testes passa.
- [ ] O build está limpo.
- [ ] A funcionalidade funciona de ponta a ponta conforme especificado.
- [ ] Não restam mudanças não commitadas.