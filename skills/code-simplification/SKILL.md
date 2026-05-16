---
name: code-simplification
description: Simplifica o código para maior clareza. Use ao refatorar para clareza sem mudar comportamento. Use quando o código funciona mas é mais difícil de ler, manter ou estender do que devia. Use ao rever código que acumulou complexidade desnecessária.
---

# Simplificação de código

## Visão Geral

Simplifique o código reduzindo complexidade e preservando o comportamento exato. O objetivo não é menos linhas — é código mais fácil de ler, entender, alterar e depurar. Toda simplificação deve passar num teste simples: “Um novo membro da equipe entenderia isto mais rápido que o original?”

## Quando Usar

- Depois de uma funcionalidade estar a funcionar e os testes passarem, mas a implementação parecer mais pesada do que precisa
- Durante revisão de código quando há alertas de legibilidade ou complexidade
- Quando encontrar lógica muito aninhada, funções longas ou nomes pouco claros
- Ao refatorar código escrito sob pressão de tempo
- Ao consolidar lógica relacionada espalhada por vários arquivos
- Depois de integrações que introduziram duplicação ou inconsistência

**Quando NÃO usar:**

- O código já está limpo e legível — não simplifique por simplificar
- Ainda não percebe o que o código faz — compreenda antes de simplificar
- O código é crítico em desempenho e a versão “mais simples” seria mensuravelmente mais lenta
- Está prestes a reescrever o módulo por completo — simplificar código descartável desperdiça esforço

## Os cinco princípios

### 1. Preservar o comportamento exatamente

Não mude o que o código faz — só como o expressa. Todas as entradas, saídas, efeitos colaterais, comportamento de erro e casos extremos devem permanecer iguais. Se não tiver certeza de que uma simplificação preserva o comportamento, não a faça.

```
PERGUNTE ANTES DE CADA ALTERAÇÃO:
→ Gera a mesma saída para todas as entradas?
→ Mantém o mesmo comportamento de erro?
→ Preserva os mesmos efeitos colaterais e a mesma ordem?
→ Todos os testes existentes passam sem modificação?
```

### 2. Seguir as convenções do projeto

Simplificar é tornar o código mais consistente com a base de código, não impor preferências externas. Antes de simplificar:

```
1. Ler CLAUDE.md / convenções do projeto
2. Estudar como o código vizinho trata padrões semelhantes
3. Alinhar ao estilo do projeto em:
   - Ordem de imports e sistema de módulos
   - Estilo de declaração de funções
   - Convenções de nomenclatura
   - Padrões de tratamento de erros
   - Profundidade de anotações de tipo
```

Simplificação que quebra a consistência do projeto não é simplificação — é ruído.

### 3. Preferir clareza a esperteza

Código explícito é melhor que código compacto quando a versão compacta obriga a uma pausa mental para decifrar.

```typescript
// POUCO CLARO: Cadeia densa de ternários
const label = isNew ? 'New' : isUpdated ? 'Updated' : isArchived ? 'Archived' : 'Active';

// CLARO: Mapeamento legível
function getStatusLabel(item: Item): string {
  if (item.isNew) return 'New';
  if (item.isUpdated) return 'Updated';
  if (item.isArchived) return 'Archived';
  return 'Active';
}
```

```typescript
// POUCO CLARO: reduces encadeados com lógica inline
const result = items.reduce((acc, item) => ({
  ...acc,
  [item.id]: { ...acc[item.id], count: (acc[item.id]?.count ?? 0) + 1 }
}), {});

// CLARO: Passo intermédio com nome
const countById = new Map<string, number>();
for (const item of items) {
  countById.set(item.id, (countById.get(item.id) ?? 0) + 1);
}
```

### 4. Manter o equilíbrio

Simplificação tem um modo de falha: simplificar em excesso. Cuidado com estas armadilhas:

- **Inline demais** — remover um helper que dava nome a um conceito torna o sítio da chamada mais difícil de ler
- **Juntar lógicas não relacionadas** — duas funções simples numa só complexa não é mais simples
- **Remover abstração “desnecessária”** — algumas abstrações existem para extensibilidade ou testabilidade, não por complexidade
- **Otimizar contagem de linhas** — menos linhas não é o objetivo; compreensão mais fácil é

### 5. Limitar ao que mudou

Por padrão, simplifique código alterado recentemente. Evite refatorações “de passagem” em código não relacionado salvo pedido explícito para ampliar o escopo. Simplificação sem escopo definido gera ruído nos diffs e risco de regressões não intencionais.

## O processo de simplificação

### Etapa 1: Entender antes de tocar (cerca de Chesterton)

Antes de alterar ou remover algo, perceba porque existe. Isto é a “cerca de Chesterton”: se vir uma cerca à estrada e não souber porque está ali, não a derrube. Primeiro entenda a razão; depois decida se a razão ainda se aplica.

```
ANTES DE SIMPLIFICAR, RESPONDA:
- Qual é a responsabilidade deste código?
- Quem o chama? Quem é que ele chama?
- Quais são os casos extremos e os caminhos de erro?
- Há testes que definem o comportamento esperado?
- Porque poderia ter sido escrito assim? (Desempenho? Restrição de plataforma? Histórico?)
- Ver git blame: qual era o contexto original deste código?
```

Se não conseguir responder, não está pronto para simplificar. Leia mais contexto primeiro.

### Etapa 2: Identificar oportunidades de simplificação

Procure estes padrões — cada um é um sinal concreto, não um “cheiro” vago:

**Complexidade estrutural:**

| Padrão | Sinal | Simplificação |
|--------|-------|----------------|
| Aninhamento profundo (3+ níveis) | Fluxo de controlo difícil de seguir | Extrair condições para guard clauses ou funções auxiliares |
| Funções longas (50+ linhas) | Várias responsabilidades | Dividir em funções focadas com nomes descritivos |
| Ternários aninhados | Exige “pilha mental” para parsear | Substituir por if/else, switch ou objetos de lookup |
| Parâmetros booleanos | `doThing(true, false, true)` | Substituir por objetos de opções ou funções separadas |
| Condicionais repetidas | O mesmo `if` em vários sítios | Extrair para uma função predicado bem nomeada |

**Nomenclatura e legibilidade:**

| Padrão | Sinal | Simplificação |
|--------|-------|----------------|
| Nomes genéricos | `data`, `result`, `temp`, `val`, `item` | Renomear para descrever o conteúdo: `userProfile`, `validationErrors` |
| Nomes abreviados | `usr`, `cfg`, `btn`, `evt` | Palavras completas salvo abreviaturas universais (`id`, `url`, `api`) |
| Nomes enganadores | Função `get` que também altera estado | Renomear para refletir o comportamento real |
| Comentários que explicam “o quê” | `// increment counter` sobre `count++` | Apagar o comentário — o código já é claro |
| Comentários que explicam “porquê” | `// Retry because the API is flaky under load` | Manter — transportam intenção que o código não exprime |

**Redundância:**

| Padrão | Sinal | Simplificação |
|--------|-------|----------------|
| Lógica duplicada | As mesmas 5+ linhas em vários sítios | Extrair para uma função partilhada |
| Código morto | Ramos inalcançáveis, variáveis não usadas, blocos comentados | Remover (depois de confirmar que está mesmo morto) |
| Abstrações desnecessárias | Wrapper que não acrescenta valor | Fazer inline do wrapper, chamar a função subjacente diretamente |
| Padrões over-engineered | Fábrica-para-fábrica, estratégia-com-uma-estratégia | Substituir pela abordagem direta simples |
| Asserções de tipo redundantes | Cast para um tipo já inferido | Remover a asserção |

### Etapa 3: Aplicar alterações de forma incremental

Faça uma simplificação de cada vez. Execute os testes após cada mudança. **Submeta refatorações separadamente de alterações de funcionalidade ou correção de bugs.** Um PR que refatora e adiciona funcionalidade são dois PRs — divida.

```
PARA CADA SIMPLIFICAÇÃO:
1. Fazer a alteração
2. Executar a suíte de testes
3. Se os testes passarem → commit (ou continuar para a próxima simplificação)
4. Se falharem → reverter e reconsiderar
```

Evite agrupar várias simplificações numa única alteração não testada. Se algo partir, precisa de saber qual simplificação causou.

**Regra dos 500:** Se uma refatoração tocar em mais de 500 linhas, invista em automação (codemods, scripts sed, transformações AST) em vez de editar à mão. Edições manuais nessa escala geram erros e revisão exaustiva.

### Etapa 4: Verificar o resultado

Depois de todas as simplificações, afaste-se e avalie o conjunto:

```
COMPARAR ANTES E DEPOIS:
- A versão simplificada é genuinamente mais fácil de entender?
- Introduziu padrões novos inconsistentes com a base de código?
- O diff é limpo e revisível?
- Um colega aprovaria esta alteração?
```

Se a versão “simplificada” for mais difícil de entender ou rever, reverta. Nem toda a tentativa de simplificação resulta.

## Orientação por linguagem

### TypeScript / JavaScript

```typescript
// SIMPLIFICAR: async wrapper desnecessário
// Antes
async function getUser(id: string): Promise<User> {
  return await userService.findById(id);
}
// Depois
function getUser(id: string): Promise<User> {
  return userService.findById(id);
}

// SIMPLIFICAR: Atribuição condicional verbosa
// Antes
let displayName: string;
if (user.nickname) {
  displayName = user.nickname;
} else {
  displayName = user.fullName;
}
// Depois
const displayName = user.nickname || user.fullName;

// SIMPLIFICAR: Construção manual de array
// Antes
const activeUsers: User[] = [];
for (const user of users) {
  if (user.isActive) {
    activeUsers.push(user);
  }
}
// Depois
const activeUsers = users.filter((user) => user.isActive);

// SIMPLIFICAR: return booleano redundante
// Antes
function isValid(input: string): boolean {
  if (input.length > 0 && input.length < 100) {
    return true;
  }
  return false;
}
// Depois
function isValid(input: string): boolean {
  return input.length > 0 && input.length < 100;
}
```

### Python

```python
# SIMPLIFICAR: Construção verbosa de dicionário
# Antes
result = {}
for item in items:
    result[item.id] = item.name
# Depois
result = {item.id: item.name for item in items}

# SIMPLIFICAR: Condicionais aninhadas com retorno antecipado
# Antes
def process(data):
    if data is not None:
        if data.is_valid():
            if data.has_permission():
                return do_work(data)
            else:
                raise PermissionError("No permission")
        else:
            raise ValueError("Invalid data")
    else:
        raise TypeError("Data is None")
# Depois
def process(data):
    if data is None:
        raise TypeError("Data is None")
    if not data.is_valid():
        raise ValueError("Invalid data")
    if not data.has_permission():
        raise PermissionError("No permission")
    return do_work(data)
```

### React / JSX

```tsx
// SIMPLIFICAR: Renderização condicional verbosa
// Antes
function UserBadge({ user }: Props) {
  if (user.isAdmin) {
    return <Badge variant="admin">Admin</Badge>;
  } else {
    return <Badge variant="default">User</Badge>;
  }
}
// Depois
function UserBadge({ user }: Props) {
  const variant = user.isAdmin ? 'admin' : 'default';
  const label = user.isAdmin ? 'Admin' : 'User';
  return <Badge variant={variant}>{label}</Badge>;
}

// SIMPLIFICAR: Prop drilling através de componentes intermédios
// Antes — avalie se contexto ou composição resolvem melhor.
// É uma decisão de juízo — assinalhe, não refatore automaticamente.
```

## Racionalizações Comuns

| Racionalização | Realidade |
|---|---|
| “Está a funcionar, não preciso mexer” | Código que funciona mas é difícil de ler será difícil de corrigir quando partir. Simplificar agora poupa tempo em cada mudança futura. |
| “Menos linhas é sempre mais simples” | Um ternário aninhado numa linha não é mais simples que um if/else de cinco linhas. Simplicidade é velocidade de compreensão, não contagem de linhas. |
| “Só simplifico rapidamente este código não relacionado também” | Simplificação sem escopo definido gera diffs ruidosos e risco de regressões em código que não queria alterar. Mantenha o foco. |
| “Os tipos documentam-se a si próprios” | Tipos documentam estrutura, não intenção. Uma função bem nomeada explica o *porquê* melhor do que uma assinatura de tipo explica o *quê*. |
| “Esta abstração pode ser útil mais tarde” | Não preserve abstrações especulativas. Se não é usada agora, é complexidade sem valor. Remova e volte a acrescentar quando for preciso. |
| “O autor original deve ter tido uma razão” | Talvez. Veja o git blame — aplique a cerca de Chesterton. Mas complexidade acumulada muitas vezes não tem razão; é só resíduo de iteração sob pressão. |
| “Refatoro enquanto acrescento esta funcionalidade” | Separe refatoração de trabalho de funcionalidade. Misturas são mais difíceis de rever, reverter e entender no histórico. |

## Sinais de Alerta

- Simplificação que obriga a alterar testes para passar (provavelmente mudou comportamento)
- Código “simplificado” mais longo e mais difícil de seguir que o original
- Renomear para corresponder às suas preferências em vez das convenções do projeto
- Remover tratamento de erros porque “deixa o código mais limpo”
- Simplificar código que não percebe totalmente
- Agrupar muitas simplificações num commit grande e difícil de rever
- Refatorar código fora do escopo da tarefa atual sem ser pedido

## Verificação

Depois de concluir uma passagem de simplificação:

- [ ] Todos os testes existentes passam sem modificação
- [ ] O build conclui sem novos avisos
- [ ] Linter/formatador passa (sem regressões de estilo)
- [ ] Cada simplificação é uma alteração incremental e revisível
- [ ] O diff é limpo — sem alterações não relacionadas misturadas
- [ ] O código simplificado segue as convenções do projeto (verificado contra CLAUDE.md ou equivalente)
- [ ] Não foi removido nem enfraquecido o tratamento de erros
- [ ] Não ficou código morto (imports não usados, ramos inalcançáveis)
- [ ] Um colega ou agente revisor aprovaria a alteração como melhoria líquida
