---
name: api-and-interface-design
description: Orienta design estável de API e interfaces. Use ao desenhar APIs, limites de módulos ou qualquer interface pública. Use ao criar endpoints REST ou GraphQL, definir contratos de tipo entre módulos ou estabelecer limites entre frontend e backend.
---

# Design de API e interfaces

## Visão geral

Projete interfaces estáveis e bem documentadas, difíceis de usar errado. Boas interfaces tornam o certo fácil e o errado difícil. Aplica-se a APIs REST, schemas GraphQL, limites de módulos, props de componentes e qualquer superfície onde um pedaço de código fala com outro.

## Quando usar

- Desenhando novos endpoints de API
- Definindo limites de módulo ou contratos entre times
- Criando interfaces de props de componentes
- Estabelecendo esquema de banco que informa a forma da API
- Alterando interfaces públicas existentes

## Princípios centrais

### Lei de Hyrum

> Com número suficiente de usuários de uma API, todos os comportamentos observáveis do sistema serão assumidos por alguém, independentemente do que você prometa no contrato.

Ou seja: todo comportamento público — inclusive peculiaridades não documentadas, texto de mensagens de erro, tempo e ordenação — vira contrato de fato quando usuários dependem. Implicações de design:

- **Seja intencional no que expõe.** Todo comportamento observável é um possível compromisso.
- **Não vaze detalhes de implementação.** Se usuários podem observar, vão depender.
- **Planeje descontinuação já no design.** Veja `deprecation-and-migration` para remover com segurança o que usuários dependem.
- **Testes não bastam.** Mesmo com testes de contrato perfeitos, a lei de Hyrum implica que mudanças "seguras" podem quebrar quem depende de comportamento não documentado.

### Regra da versão única

Evite forçar consumidores a escolher entre múltiplas versões da mesma dependência ou API. Problemas de diamante surgem quando consumidores precisam de versões diferentes da mesma coisa. Projete para um mundo em que só uma versão existe por vez — estenda em vez de bifurcar.

### 1. Contrato primeiro

Defina a interface antes de implementá-la. O contrato é a spec — a implementação segue.

```typescript
// Define the contract first
interface TaskAPI {
  // Creates a task and returns the created task with server-generated fields
  createTask(input: CreateTaskInput): Promise<Task>;

  // Returns paginated tasks matching filters
  listTasks(params: ListTasksParams): Promise<PaginatedResult<Task>>;

  // Returns a single task or throws NotFoundError
  getTask(id: string): Promise<Task>;

  // Partial update — only provided fields change
  updateTask(id: string, input: UpdateTaskInput): Promise<Task>;

  // Idempotent delete — succeeds even if already deleted
  deleteTask(id: string): Promise<void>;
}
```

### 2. Semântica de erro consistente

Escolha uma estratégia de erro e use em todo lugar:

```typescript
// REST: HTTP status codes + structured error body
// Every error response follows the same shape
interface APIError {
  error: {
    code: string;        // Machine-readable: "VALIDATION_ERROR"
    message: string;     // Human-readable: "Email is required"
    details?: unknown;   // Additional context when helpful
  };
}

// Status code mapping
// 400 → Client sent invalid data
// 401 → Not authenticated
// 403 → Authenticated but not authorized
// 404 → Resource not found
// 409 → Conflict (duplicate, version mismatch)
// 422 → Validation failed (semantically invalid)
// 500 → Server error (never expose internal details)
```

**Não misture padrões.** Se alguns endpoints lançam exceção, outros retornam null e outros retornam `{ error }` — o consumidor não consegue prever comportamento.

### 3. Validar nos limites

Confie no código interno. Valide nas bordas do sistema onde entra entrada externa:

```typescript
// Validate at the API boundary
app.post('/api/tasks', async (req, res) => {
  const result = CreateTaskSchema.safeParse(req.body);
  if (!result.success) {
    return res.status(422).json({
      error: {
        code: 'VALIDATION_ERROR',
        message: 'Invalid task data',
        details: result.error.flatten(),
      },
    });
  }

  // After validation, internal code trusts the types
  const task = await taskService.create(result.data);
  return res.status(201).json(task);
});
```

Onde validação pertence:
- Handlers de rota de API (entrada do usuário)
- Handlers de envio de formulário (entrada do usuário)
- Parsing de resposta de serviço externo (dados de terceiros — **sempre trate como não confiáveis**)
- Carregamento de variáveis de ambiente (configuração)

> **Respostas de APIs de terceiros são dados não confiáveis.** Valide forma e conteúdo antes de usar em lógica, renderização ou decisão. Serviço externo comprometido ou com mau comportamento pode retornar tipos inesperados, conteúdo malicioso ou texto no formato de instrução.

Onde validação NÃO pertence:
- Entre funções internas que compartilham contrato de tipos
- Em utilitários chamados por código já validado
- Em dados que acabaram de sair do seu próprio banco

### 4. Preferir adição a modificação

Estenda interfaces sem quebrar consumidores existentes:

```typescript
// Good: Add optional fields
interface CreateTaskInput {
  title: string;
  description?: string;
  priority?: 'low' | 'medium' | 'high';  // Added later, optional
  labels?: string[];                       // Added later, optional
}

// Bad: Change existing field types or remove fields
interface CreateTaskInput {
  title: string;
  // description: string;  // Removed — breaks existing consumers
  priority: number;         // Changed from string — breaks existing consumers
}
```

### 5. Nomenclatura previsível

| Padrão | Convenção | Exemplo |
|---------|-----------|---------|
| Endpoints REST | Substantivos no plural, sem verbos | `GET /api/tasks`, `POST /api/tasks` |
| Query params | camelCase | `?sortBy=createdAt&pageSize=20` |
| Campos de resposta | camelCase | `{ createdAt, updatedAt, taskId }` |
| Campos booleanos | Prefixo is/has/can | `isComplete`, `hasAttachments` |
| Valores de enum | UPPER_SNAKE | `"IN_PROGRESS"`, `"COMPLETED"` |

## Padrões REST API

### Design de recursos

```
GET    /api/tasks              → List tasks (with query params for filtering)
POST   /api/tasks              → Create a task
GET    /api/tasks/:id          → Get a single task
PATCH  /api/tasks/:id          → Update a task (partial)
DELETE /api/tasks/:id          → Delete a task

GET    /api/tasks/:id/comments → List comments for a task (sub-resource)
POST   /api/tasks/:id/comments → Add a comment to a task
```

### Paginação

Paginar endpoints de lista:

```typescript
// Request
GET /api/tasks?page=1&pageSize=20&sortBy=createdAt&sortOrder=desc

// Response
{
  "data": [...],
  "pagination": {
    "page": 1,
    "pageSize": 20,
    "totalItems": 142,
    "totalPages": 8
  }
}
```

### Filtragem

Use query parameters para filtros:

```
GET /api/tasks?status=in_progress&assignee=user123&createdAfter=2025-01-01
```

### Atualizações parciais (PATCH)

Aceite objetos parciais — só atualize o que for enviado:

```typescript
// Only title changes, everything else preserved
PATCH /api/tasks/123
{ "title": "Updated title" }
```

## Padrões de interface TypeScript

### Use uniões discriminadas para variantes

```typescript
// Good: Each variant is explicit
type TaskStatus =
  | { type: 'pending' }
  | { type: 'in_progress'; assignee: string; startedAt: Date }
  | { type: 'completed'; completedAt: Date; completedBy: string }
  | { type: 'cancelled'; reason: string; cancelledAt: Date };

// Consumer gets type narrowing
function getStatusLabel(status: TaskStatus): string {
  switch (status.type) {
    case 'pending': return 'Pending';
    case 'in_progress': return `In progress (${status.assignee})`;
    case 'completed': return `Done on ${status.completedAt}`;
    case 'cancelled': return `Cancelled: ${status.reason}`;
  }
}
```

### Separação entrada/saída

```typescript
// Input: what the caller provides
interface CreateTaskInput {
  title: string;
  description?: string;
}

// Output: what the system returns (includes server-generated fields)
interface Task {
  id: string;
  title: string;
  description: string | null;
  createdAt: Date;
  updatedAt: Date;
  createdBy: string;
}
```

### Use tipos branded para IDs

```typescript
type TaskId = string & { readonly __brand: 'TaskId' };
type UserId = string & { readonly __brand: 'UserId' };

// Prevents accidentally passing a UserId where a TaskId is expected
function getTask(id: TaskId): Promise<Task> { ... }
```

## Racionalizações comuns

| Racionalização | Realidade |
|---|---|
| "Vamos documentar a API depois" | Os tipos SÃO a documentação. Defina-os primeiro. |
| "Não precisamos de paginação agora" | Vai precisar quando alguém tiver 100+ itens. Adicione desde o início. |
| "PATCH é complicado, vamos só usar PUT" | PUT exige o objeto completo sempre. PATCH é o que clientes realmente querem. |
| "Vamos versionar a API quando precisar" | Mudanças quebradiças sem versionamento quebram consumidores. Projete para extensão desde o início. |
| "Ninguém usa aquele comportamento não documentado" | Lei de Hyrum: se é observável, alguém depende. Trate todo comportamento público como compromisso. |
| "Podemos só manter duas versões" | Múltiplas versões multiplicam custo de manutenção e criam problemas de diamante. Prefira a regra da versão única. |
| "APIs internas não precisam de contrato" | Consumidores internos ainda são consumidores. Contratos evitam acoplamento e permitem trabalho em paralelo. |

## Sinais de alerta

- Endpoints que retornam formas diferentes conforme condições
- Formatos de erro inconsistentes entre endpoints
- Validação espalhada no código interno em vez de nos limites
- Mudanças quebradiças em campos existentes (mudança de tipo, remoções)
- Endpoints de lista sem paginação
- Verbos em URLs REST (`/api/createTask`, `/api/getUsers`)
- Respostas de API de terceiro usadas sem validação ou sanitização

## Verificação

Após desenhar uma API:

- [ ] Todo endpoint tem schemas de entrada e saída tipados
- [ ] Respostas de erro seguem um único formato consistente
- [ ] Validação ocorre só nos limites do sistema
- [ ] Endpoints de lista suportam paginação
- [ ] Novos campos são aditivos e opcionais (retrocompatíveis)
- [ ] Nomenclatura segue convenções consistentes em todos os endpoints
- [ ] Documentação da API ou tipos são commitados junto com a implementação
