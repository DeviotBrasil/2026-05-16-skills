---
name: security-and-hardening
description: Endurece o código contra vulnerabilidades. Use ao tratar entrada do usuário, autenticação, armazenamento de dados ou integrações externas. Use ao construir qualquer recurso que aceite dados não confiáveis, gerencie sessões de usuário ou interaja com serviços de terceiros.
---

# Segurança e endurecimento

## Visão geral

Práticas de desenvolvimento com segurança em primeiro lugar para aplicações web. Trate toda entrada externa como hostil, todo segredo como sagrado e toda verificação de autorização como obrigatória. Segurança não é uma fase — é uma restrição em cada linha que toca dados de usuários, autenticação ou sistemas externos.

## Quando usar

- Construindo qualquer coisa que aceite entrada do usuário
- Implementando autenticação ou autorização
- Armazenando ou transmitindo dados sensíveis
- Integrando com APIs ou serviços externos
- Adicionando uploads de arquivo, webhooks ou callbacks
- Tratando pagamentos ou dados pessoais (PII)

## Sistema de limites em três níveis

### Sempre fazer (sem exceções)

- **Validar toda entrada externa** no limite do sistema (rotas de API, handlers de formulário)
- **Parametrizar todas as consultas ao banco** — nunca concatenar entrada do usuário em SQL
- **Codificar saída** para prevenir XSS (usar escape automático do framework, não contornar)
- **Usar HTTPS** em toda comunicação externa
- **Hash de senhas** com bcrypt/scrypt/argon2 (nunca em texto plano)
- **Definir cabeçalhos de segurança** (CSP, HSTS, X-Frame-Options, X-Content-Type-Options)
- **Usar cookies httpOnly, secure, sameSite** para sessões
- **Executar `npm audit`** (ou equivalente) antes de cada release

### Perguntar primeiro (requer aprovação humana)

- Adicionar novos fluxos de autenticação ou alterar lógica de auth
- Armazenar novas categorias de dados sensíveis (PII, pagamento)
- Adicionar novas integrações com serviços externos
- Alterar configuração de CORS
- Adicionar handlers de upload de arquivo
- Modificar rate limiting ou throttling
- Conceder permissões ou papéis elevados

### Nunca fazer

- **Nunca commitar segredos** no controle de versão (chaves de API, senhas, tokens)
- **Nunca logar dados sensíveis** (senhas, tokens, número completo de cartão)
- **Nunca confiar na validação só no cliente** como limite de segurança
- **Nunca desabilitar cabeçalhos de segurança** por conveniência
- **Nunca usar `eval()` ou `innerHTML`** com dados fornecidos pelo usuário
- **Nunca armazenar sessões em storage acessível ao cliente** (localStorage para tokens de auth)
- **Nunca expor stack traces** ou detalhes internos de erro a usuários

## Prevenção OWASP Top 10

### 1. Injeção (SQL, NoSQL, comando de SO)

```typescript
// BAD: SQL injection via string concatenation
const query = `SELECT * FROM users WHERE id = '${userId}'`;

// GOOD: Parameterized query
const user = await db.query('SELECT * FROM users WHERE id = $1', [userId]);

// GOOD: ORM with parameterized input
const user = await prisma.user.findUnique({ where: { id: userId } });
```

### 2. Autenticação quebrada

```typescript
// Password hashing
import { hash, compare } from 'bcrypt';

const SALT_ROUNDS = 12;
const hashedPassword = await hash(plaintext, SALT_ROUNDS);
const isValid = await compare(plaintext, hashedPassword);

// Session management
app.use(session({
  secret: process.env.SESSION_SECRET,  // From environment, not code
  resave: false,
  saveUninitialized: false,
  cookie: {
    httpOnly: true,     // Not accessible via JavaScript
    secure: true,       // HTTPS only
    sameSite: 'lax',    // CSRF protection
    maxAge: 24 * 60 * 60 * 1000,  // 24 hours
  },
}));
```

### 3. Cross-Site Scripting (XSS)

```typescript
// BAD: Rendering user input as HTML
element.innerHTML = userInput;

// GOOD: Use framework auto-escaping (React does this by default)
return <div>{userInput}</div>;

// If you MUST render HTML, sanitize first
import DOMPurify from 'dompurify';
const clean = DOMPurify.sanitize(userInput);
```

### 4. Controle de acesso quebrado

```typescript
// Always check authorization, not just authentication
app.patch('/api/tasks/:id', authenticate, async (req, res) => {
  const task = await taskService.findById(req.params.id);

  // Check that the authenticated user owns this resource
  if (task.ownerId !== req.user.id) {
    return res.status(403).json({
      error: { code: 'FORBIDDEN', message: 'Sem autorização para modificar esta tarefa' }
    });
  }

  // Proceed with update
  const updated = await taskService.update(req.params.id, req.body);
  return res.json(updated);
});
```

### 5. Configuração incorreta de segurança

```typescript
// Security headers (use helmet for Express)
import helmet from 'helmet';
app.use(helmet());

// Content Security Policy
app.use(helmet.contentSecurityPolicy({
  directives: {
    defaultSrc: ["'self'"],
    scriptSrc: ["'self'"],
    styleSrc: ["'self'", "'unsafe-inline'"],  // Tighten if possible
    imgSrc: ["'self'", 'data:', 'https:'],
    connectSrc: ["'self'"],
  },
}));

// CORS — restrict to known origins
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') || 'http://localhost:3000',
  credentials: true,
}));
```

### 6. Exposição de dados sensíveis

```typescript
// Never return sensitive fields in API responses
function sanitizeUser(user: UserRecord): PublicUser {
  const { passwordHash, resetToken, ...publicFields } = user;
  return publicFields;
}

// Use environment variables for secrets
const API_KEY = process.env.STRIPE_API_KEY;
if (!API_KEY) throw new Error('STRIPE_API_KEY not configured');
```

## Padrões de validação de entrada

### Validação de esquema nos limites

```typescript
import { z } from 'zod';

const CreateTaskSchema = z.object({
  title: z.string().min(1).max(200).trim(),
  description: z.string().max(2000).optional(),
  priority: z.enum(['low', 'medium', 'high']).default('medium'),
  dueDate: z.string().datetime().optional(),
});

// Validate at the route handler
app.post('/api/tasks', async (req, res) => {
  const result = CreateTaskSchema.safeParse(req.body);
  if (!result.success) {
    return res.status(422).json({
      error: {
        code: 'VALIDATION_ERROR',
        message: 'Entrada inválida',
        details: result.error.flatten(),
      },
    });
  }
  // result.data is now typed and validated
  const task = await taskService.create(result.data);
  return res.status(201).json(task);
});
```

### Segurança em upload de arquivo

```typescript
// Restrict file types and sizes
const ALLOWED_TYPES = ['image/jpeg', 'image/png', 'image/webp'];
const MAX_SIZE = 5 * 1024 * 1024; // 5MB

function validateUpload(file: UploadedFile) {
  if (!ALLOWED_TYPES.includes(file.mimetype)) {
    throw new ValidationError('Tipo de arquivo não permitido');
  }
  if (file.size > MAX_SIZE) {
    throw new ValidationError('Arquivo muito grande (máx. 5MB)');
  }
  // Don't trust the file extension — check magic bytes if critical
}
```

## Triagem de resultados do npm audit

Nem todos os achados exigem ação imediata. Use esta árvore de decisão:

```
npm audit reports a vulnerability
├── Severity: critical or high
│   ├── Is the vulnerable code reachable in your app?
│   │   ├── YES --> Fix immediately (update, patch, or replace the dependency)
│   │   └── NO (dev-only dep, unused code path) --> Fix soon, but not a blocker
│   └── Is a fix available?
│       ├── YES --> Update to the patched version
│       └── NO --> Check for workarounds, consider replacing the dependency, or add to allowlist with a review date
├── Severity: moderate
│   ├── Reachable in production? --> Fix in the next release cycle
│   └── Dev-only? --> Fix when convenient, track in backlog
└── Severity: low
    └── Track and fix during regular dependency updates
```

**Perguntas-chave:**
- A função vulnerável é de fato chamada no seu caminho de código?
- A dependência é de runtime ou só de desenvolvimento?
- A vulnerabilidade é explorável no seu contexto de implantação (ex.: vulnerabilidade server-side em app só cliente)?

Ao adiar correção, documente o motivo e defina data de revisão.

## Rate limiting

```typescript
import rateLimit from 'express-rate-limit';

// General API rate limit
app.use('/api/', rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100,                   // 100 requests per window
  standardHeaders: true,
  legacyHeaders: false,
}));

// Stricter limit for auth endpoints
app.use('/api/auth/', rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,  // 10 attempts per 15 minutes
}));
```

## Gestão de segredos

```
.env files:
  ├── .env.example  → Committed (template with placeholder values)
  ├── .env          → NOT committed (contains real secrets)
  └── .env.local    → NOT committed (local overrides)

.gitignore must include:
  .env
  .env.local
  .env.*.local
  *.pem
  *.key
```

**Sempre verificar antes de commitar:**
```bash
# Verificar segredos adicionados ao stage por engano
git diff --cached | grep -i "password\|secret\|api_key\|token"
```

## Checklist de revisão de segurança

```markdown
### Autenticação
- [ ] Senhas com hash bcrypt/scrypt/argon2 (salt rounds ≥ 12)
- [ ] Tokens de sessão são httpOnly, secure, sameSite
- [ ] Login tem rate limiting
- [ ] Tokens de redefinição de senha expiram

### Autorização
- [ ] Todo endpoint verifica permissões do usuário
- [ ] Usuários só acessam seus próprios recursos
- [ ] Ações de admin exigem verificação de papel admin

### Entrada
- [ ] Toda entrada do usuário validada no limite
- [ ] Consultas SQL são parametrizadas
- [ ] Saída HTML é codificada/escapada

### Dados
- [ ] Sem segredos em código ou controle de versão
- [ ] Campos sensíveis excluídos das respostas da API
- [ ] PII criptografada em repouso (se aplicável)

### Infraestrutura
- [ ] Cabeçalhos de segurança configurados (CSP, HSTS etc.)
- [ ] CORS restrito a origens conhecidas
- [ ] Dependências auditadas quanto a vulnerabilidades
- [ ] Mensagens de erro não expõem detalhes internos
```
## Ver também

Para checklists detalhados de segurança e passos de verificação pré-commit, veja `references/security-checklist.md`.

## Racionalizações comuns

| Racionalização | Realidade |
|---|---|
| "É ferramenta interna, segurança não importa" | Ferramentas internas são comprometidas. Atacantes miram o elo mais fraco. |
| "Vamos adicionar segurança depois" | Refatorar segurança depois é 10× mais difícil que embutir agora. |
| "Ninguém tentaria explorar isso" | Scanners automatizados acham. Segurança por obscuridade não é segurança. |
| "O framework cuida da segurança" | Frameworks fornecem ferramentas, não garantias. Ainda é preciso usá-las corretamente. |
| "É só um protótipo" | Protótipos viram produção. Hábitos de segurança desde o dia um. |

## Sinais de alerta

- Entrada do usuário passada direto para consultas ao banco, comandos shell ou renderização HTML
- Segredos no código-fonte ou histórico de commits
- Endpoints de API sem autenticação ou autorização
- CORS ausente ou origem curinga (`*`)
- Sem rate limiting em endpoints de autenticação
- Stack traces ou erros internos expostos a usuários
- Dependências com vulnerabilidades críticas conhecidas

## Verificação

Depois de implementar código relevante para segurança:

- [ ] `npm audit` sem vulnerabilidades críticas ou altas
- [ ] Sem segredos no código-fonte ou histórico git
- [ ] Toda entrada do usuário validada nos limites do sistema
- [ ] Autenticação e autorização verificadas em todo endpoint protegido
- [ ] Cabeçalhos de segurança presentes na resposta (conferir com DevTools do navegador)
- [ ] Respostas de erro não expõem detalhes internos
- [ ] Rate limiting ativo em endpoints de auth
