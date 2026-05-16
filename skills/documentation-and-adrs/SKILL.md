---
name: documentation-and-adrs
description: Registra decisões e documentação. Use ao tomar decisões arquiteturais, alterar APIs públicas, entregar recursos ou quando precisar registrar contexto que engenheiros e agentes futuros precisarão para entender a base.
---

# Documentação e ADRs

## Visão geral

Documente decisões, não só código. A documentação mais valiosa captura o *por quê* — o contexto, restrições e trade-offs que levaram à decisão. O código mostra *o que* foi construído; a documentação explica *por que foi assim* e *quais alternativas foram consideradas*. Esse contexto é essencial para humanos e agentes futuros na base.

## Quando usar

- Tomando decisão arquitetural significativa
- Escolhendo entre abordagens concorrentes
- Adicionando ou alterando API pública
- Entregando recurso que muda comportamento voltado ao usuário
- Integrando novos membros (ou agentes) ao projeto
- Quando você se pega explicando a mesma coisa repetidamente

**Quando NÃO usar:** Não documente código óbvio. Não adicione comentários que repetem o que o código já diz. Não escreva docs para protótipos descartáveis.

## Architecture Decision Records (ADRs)

ADRs capturam o raciocínio por trás de decisões técnicas importantes. São a documentação de maior valor que você pode escrever.

### Quando escrever um ADR

- Escolher framework, biblioteca ou dependência maior
- Projetar modelo de dados ou esquema de banco
- Selecionar estratégia de autenticação
- Decidir arquitetura de API (REST vs. GraphQL vs. tRPC)
- Escolher entre ferramentas de build, plataformas de hospedagem ou infraestrutura
- Qualquer decisão cara de reverter

### Modelo de ADR

Guarde ADRs em `docs/decisions/` com numeração sequencial:

```markdown
# ADR-001: Use PostgreSQL for primary database

## Status
Accepted | Superseded by ADR-XXX | Deprecated

## Date
2025-01-15

## Context
We need a primary database for the task management application. Key requirements:
- Relational data model (users, tasks, teams with relationships)
- ACID transactions for task state changes
- Support for full-text search on task content
- Managed hosting available (for small team, limited ops capacity)

## Decision
Use PostgreSQL with Prisma ORM.

## Alternatives Considered

### MongoDB
- Pros: Flexible schema, easy to start with
- Cons: Our data is inherently relational; would need to manage relationships manually
- Rejected: Relational data in a document store leads to complex joins or data duplication

### SQLite
- Pros: Zero configuration, embedded, fast for reads
- Cons: Limited concurrent write support, no managed hosting for production
- Rejected: Not suitable for multi-user web application in production

### MySQL
- Pros: Mature, widely supported
- Cons: PostgreSQL has better JSON support, full-text search, and ecosystem tooling
- Rejected: PostgreSQL is the better fit for our feature requirements

## Consequences
- Prisma provides type-safe database access and migration management
- We can use PostgreSQL's full-text search instead of adding Elasticsearch
- Team needs PostgreSQL knowledge (standard skill, low risk)
- Hosting on managed service (Supabase, Neon, or RDS)
```

### Ciclo de vida do ADR

```
PROPOSED → ACCEPTED → (SUPERSEDED or DEPRECATED)
```

- **Não apague ADRs antigos.** Eles guardam contexto histórico.
- Quando a decisão mudar, escreva um ADR novo que referencie e substitua o antigo.

## Documentação inline

### Quando comentar

Comente o *por quê*, não o *o quê*:

```typescript
// BAD: Restates the code
// Increment counter by 1
counter += 1;

// GOOD: Explains non-obvious intent
// Rate limit uses a sliding window — reset counter at window boundary,
// not on a fixed schedule, to prevent burst attacks at window edges
if (now - windowStart > WINDOW_SIZE_MS) {
  counter = 0;
  windowStart = now;
}
```

### Quando NÃO comentar

```typescript
// Don't comment self-explanatory code
function calculateTotal(items: CartItem[]): number {
  return items.reduce((sum, item) => sum + item.price * item.quantity, 0);
}

// Don't leave TODO comments for things you should just do now
// TODO: add error handling  ← Just add it

// Don't leave commented-out code
// const oldImplementation = () => { ... }  ← Delete it, git has history
```

### Documente pegadinhas conhecidas

```typescript
/**
 * IMPORTANT: This function must be called before the first render.
 * If called after hydration, it causes a flash of unstyled content
 * because the theme context isn't available during SSR.
 *
 * See ADR-003 for the full design rationale.
 */
export function initializeTheme(theme: Theme): void {
  // ...
}
```

## Documentação de API

Para APIs públicas (REST, GraphQL, interfaces de biblioteca):

### Inline com tipos (preferido em TypeScript)

```typescript
/**
 * Creates a new task.
 *
 * @param input - Task creation data (title required, description optional)
 * @returns The created task with server-generated ID and timestamps
 * @throws {ValidationError} If title is empty or exceeds 200 characters
 * @throws {AuthenticationError} If the user is not authenticated
 *
 * @example
 * const task = await createTask({ title: 'Buy groceries' });
 * console.log(task.id); // "task_abc123"
 */
export async function createTask(input: CreateTaskInput): Promise<Task> {
  // ...
}
```

### OpenAPI / Swagger para APIs REST

```yaml
paths:
  /api/tasks:
    post:
      summary: Create a task
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/CreateTaskInput'
      responses:
        '201':
          description: Task created
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Task'
        '422':
          description: Validation error
```

## Estrutura do README

Todo projeto deve ter README cobrindo:

```markdown
# Project Name

One-paragraph description of what this project does.

## Quick Start
1. Clone the repo
2. Install dependencies: `npm install`
3. Set up environment: `cp .env.example .env`
4. Run the dev server: `npm run dev`

## Commands
| Command | Description |
|---------|-------------|
| `npm run dev` | Start development server |
| `npm test` | Run tests |
| `npm run build` | Production build |
| `npm run lint` | Run linter |

## Architecture
Brief overview of the project structure and key design decisions.
Link to ADRs for details.

## Contributing
How to contribute, coding standards, PR process.
```

## Manutenção do changelog

Para recursos entregues:

```markdown
# Changelog

## [1.2.0] - 2025-01-20
### Added
- Task sharing: users can share tasks with team members (#123)
- Email notifications for task assignments (#124)

### Fixed
- Duplicate tasks appearing when rapidly clicking create button (#125)

### Changed
- Task list now loads 50 items per page (was 20) for better UX (#126)
```

## Documentação para agentes

Considerações especiais para contexto de agentes de IA:

- **CLAUDE.md / arquivos de regras** — Convenções do projeto para agentes seguirem
- **Arquivos de spec** — Mantenha specs atualizados para agentes construírem certo
- **ADRs** — Ajudam agentes a entender decisões passadas (evita redecidir)
- **Pegadinhas inline** — Evitam que agentes caiam em armadilhas conhecidas

## Racionalizações comuns

| Racionalização | Realidade |
|---|---|
| "O código é autoexplicativo" | Código mostra o quê. Não mostra por quê, alternativas rejeitadas ou restrições. |
| "Vamos documentar quando a API estabilizar" | APIs estabilizam mais rápido quando documentadas. A doc é o primeiro teste do design. |
| "Ninguém lê docs" | Agentes leem. Engenheiros futuros leem. Você daqui a 3 meses lê. |
| "ADRs são overhead" | Um ADR de 10 minutos evita 2 h de debate sobre a mesma decisão seis meses depois. |
| "Comentários ficam desatualizados" | Comentários sobre *por quê* são estáveis. Comentários sobre *o quê* envelhecem — por isso só escreva o primeiro. |

## Sinais de alerta

- Decisões arquiteturais sem justificativa escrita
- APIs públicas sem documentação ou tipos
- README que não explica como rodar o projeto
- Código comentado em vez de exclusão
- Comentários TODO há semanas
- Sem ADRs em projeto com escolhas arquiteturais significativas
- Documentação que repete o código em vez de explicar intenção

## Verificação

Após documentar:

- [ ] ADRs existem para todas as decisões arquiteturais significativas
- [ ] README cobre quick start, comandos e visão da arquitetura
- [ ] Funções de API têm documentação de parâmetros e tipo de retorno
- [ ] Pegadinhas conhecidas documentadas inline onde importam
- [ ] Não resta código comentado
- [ ] Arquivos de regras (CLAUDE.md etc.) estão atuais e corretos
