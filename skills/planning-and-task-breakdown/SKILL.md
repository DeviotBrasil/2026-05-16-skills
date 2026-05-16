---
name: planning-and-task-breakdown
description: Decompõe o trabalho em tarefas ordenadas. Use quando tiver uma especificação ou requisitos claros e precisar dividir o trabalho em tarefas implementáveis. Use quando uma tarefa parecer grande demais para começar, quando precisar de estimar escopo ou quando for possível trabalho em paralelo.
---

# Planejamento e decomposição de tarefas

## Visão Geral

Decompõe o trabalho em tarefas pequenas e verificáveis, com critérios de aceitação explícitos. Uma boa decomposição é a diferença entre um agente que conclui o trabalho de forma confiável e um que gera um emaranhado de dependências. Cada tarefa deve ser suficientemente pequena para implementar, testar e verificar numa única sessão focada.

## Quando Usar

- Você tem uma especificação e precisa dividi-la em unidades implementáveis
- Uma tarefa parece grande ou vaga demais para começar
- O trabalho precisa ser paralelizado entre vários agentes ou sessões
- Precisa comunicar o escopo a uma pessoa
- A ordem de implementação não é óbvia

**Quando NÃO usar:** Alterações em um único arquivo com escopo óbvio, ou quando a especificação já contém tarefas bem definidas.

## O processo de planejamento

### Passo 1: Entrar em modo de plano

Antes de escrever código, opere em modo só de leitura:

- Leia a especificação e as seções relevantes da base de código
- Identifique padrões e convenções existentes
- Mapeie dependências entre componentes
- Registre riscos e incertezas

**NÃO escreva código durante o planejamento.** O resultado é um documento de plano, não implementação.

### Passo 2: Identificar o grafo de dependências

Mapeie o que depende do quê:

```
Esquema do banco de dados
    │
    ├── Modelos/tipos da API
    │       │
    │       ├── Endpoints da API
    │       │       │
    │       │       └── Cliente API no frontend
    │       │               │
    │       │               └── Componentes de UI
    │       │
    │       └── Lógica de validação
    │
    └── Dados seed / migrações
```

A ordem de implementação segue o grafo de dependências de baixo para cima: fundações primeiro.

### Passo 3: Fatiar verticalmente

Em vez de construir todo o banco de dados, depois toda a API, depois toda a UI — construa um caminho completo de funcionalidade de cada vez:

**Mau (fatia horizontal):**
```
Tarefa 1: Construir o esquema completo do banco de dados
Tarefa 2: Construir todos os endpoints da API
Tarefa 3: Construir todos os componentes de UI
Tarefa 4: Ligar tudo
```

**Bom (fatia vertical):**
```
Tarefa 1: O usuário pode criar conta (esquema + API + UI de cadastro)
Tarefa 2: O usuário pode fazer login (esquema de auth + API + UI de login)
Tarefa 3: O usuário pode criar uma tarefa (esquema + API + UI de criação)
Tarefa 4: O usuário pode ver a lista de tarefas (consulta + API + UI da lista)
```

Cada fatia vertical entrega funcionalidade que funciona e é testável.

### Passo 4: Escrever tarefas

Cada tarefa segue esta estrutura:

```markdown
## Tarefa [N]: [Título curto e descritivo]

**Descrição:** Um parágrafo que explica o que esta tarefa realiza.

**Critérios de aceitação:**
- [ ] [Condição específica e testável]
- [ ] [Condição específica e testável]

**Verificação:**
- [ ] Testes passam: `npm test -- --grep "feature-name"`
- [ ] Build com sucesso: `npm run build`
- [ ] Verificação manual: [descrição do que confirmar]

**Dependências:** [Números das tarefas das quais esta depende, ou "Nenhuma"]

**Arquivos provavelmente afetados:**
- `src/path/to/file.ts`
- `tests/path/to/test.ts`

**Âmbito estimado:** [Pequeno: 1-2 arquivos | Médio: 3-5 arquivos | Grande: 5+ arquivos]
```

### Passo 5: Ordenar e definir pontos de verificação

Organize as tarefas de forma que:

1. As dependências fiquem satisfeitas (fundamentos primeiro)
2. Cada tarefa deixe o sistema num estado funcional
3. Existem pontos de verificação a cada 2-3 tarefas
4. Tarefas de maior risco vêm cedo (falhar cedo)

Adicione pontos de verificação explícitos:

```markdown
## Ponto de verificação: Após as tarefas 1-3
- [ ] Todos os testes passam
- [ ] A aplicação compila sem erros
- [ ] O fluxo principal do usuário funciona de ponta a ponta
- [ ] Revisão com um humano antes de continuar
```

## Diretrizes de tamanho de tarefa

| Tamanho | Arquivos | Escopo | Exemplo |
|---------|-----------|--------|---------|
| **XS** | 1 | Uma função ou alteração de config | Acrescentar uma regra de validação |
| **S** | 1-2 | Um componente ou endpoint | Acrescentar um novo endpoint de API |
| **M** | 3-5 | Uma fatia de funcionalidade | Fluxo de cadastro de usuário |
| **L** | 5-8 | Funcionalidade multi-componente | Pesquisa com filtros e paginação |
| **XL** | 8+ | **Grande demais — dividir mais** | — |

Se uma tarefa é L ou maior, deve ser dividida em tarefas mais pequenas. Um agente rende melhor em tarefas S e M.

**Quando dividir mais uma tarefa:**
- Levaria mais do que uma sessão focada (cerca de 2+ horas de trabalho do agente)
- Não consegue descrever os critérios de aceitação em 3 ou menos tópicos
- Toca em dois ou mais subsistemas independentes (p.ex. autenticação e faturamento)
- Vê-se a escrever “e” no título da tarefa (sinal de que são duas tarefas)

## Modelo de documento de plano

```markdown
# Plano de implementação: [Nome da funcionalidade/projeto]

## Visão Geral
[Um parágrafo com resumo do que vamos construir]

## Decisões de arquitetura
- [Decisão chave 1 e raciocínio]
- [Decisão chave 2 e raciocínio]

## Lista de tarefas

### Fase 1: Fundações
- [ ] Tarefa 1: ...
- [ ] Tarefa 2: ...

### Ponto de verificação: Fundações
- [ ] Testes passam, build limpo

### Fase 2: Funcionalidades core
- [ ] Tarefa 3: ...
- [ ] Tarefa 4: ...

### Ponto de verificação: Funcionalidades core
- [ ] Fluxo de ponta a ponta funciona

### Fase 3: Acabamentos
- [ ] Tarefa 5: ...
- [ ] Tarefa 6: ...

### Ponto de verificação: Conclusão
- [ ] Todos os critérios de aceitação cumpridos
- [ ] Pronto para revisão

## Riscos e mitigações
| Risco | Impacto | Mitigação |
|------|---------|-----------|
| [Risco] | [Alto/Médio/Baixo] | [Estratégia] |

## Questões em aberto
- [Questão que precisa de input humano]
```

## Oportunidades de paralelização

Quando há vários agentes ou sessões disponíveis:

- **Seguro paralelizar:** Fatias de funcionalidade independentes, testes para funcionalidades já implementadas, documentação
- **Tem de ser sequencial:** Migrações de banco de dados, alterações de estado compartilhado, cadeias de dependências
- **Precisa coordenação:** Funcionalidades que compartilham um contrato de API (definir o contrato primeiro, depois paralelizar)

## Racionalizações Comuns

| Racionalização | Realidade |
|---|---|
| “Vou descobrindo à medida que avanço” | É assim que se chega a retrabalho e a um emaranhado de dependências. 10 minutos de planejamento economizam horas. |
| “As tarefas são óbvias” | Escreva-as na mesma. Tarefas explícitas revelam dependências ocultas e casos extremos esquecidos. |
| “Planejamento é overhead” | O planejamento é a tarefa. Implementação sem plano é só digitar sem direção. |
| “Consigo manter tudo na cabeça” | As janelas de contexto são finitas. Planos escritos sobrevivem a limites de sessão e compactação. |

## Sinais de Alerta

- Começar a implementação sem uma lista de tarefas escrita
- Tarefas que dizem “implementar a funcionalidade” sem critérios de aceitação
- Nenhum passo de verificação no plano
- Todas as tarefas com tamanho XL
- Sem pontos de verificação entre tarefas
- Ordem de dependências não considerada

## Verificação

Antes de começar a implementação, confirme:

- [ ] Cada tarefa tem critérios de aceitação
- [ ] Cada tarefa tem um passo de verificação
- [ ] As dependências entre tarefas estão identificadas e ordenadas corretamente
- [ ] Nenhuma tarefa toca em mais de ~5 arquivos
- [ ] Existem pontos de verificação entre fases principais
- [ ] O humano rever e aprova o plano
