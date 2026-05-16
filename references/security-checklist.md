# Checklist de segurança

Referência rápida para segurança de aplicações web. Use junto com a skill `security-and-hardening`.

## Índice

- [Verificações pré-commit](#verificações-pré-commit)
- [Autenticação](#autenticação)
- [Autorização](#autorização)
- [Validação de entrada](#validação-de-entrada)
- [Cabeçalhos de segurança](#cabeçalhos-de-segurança)
- [Configuração CORS](#configuração-cors)
- [Proteção de dados](#proteção-de-dados)
- [Segurança de dependências](#segurança-de-dependências)
- [Tratamento de erros](#tratamento-de-erros)
- [Referência rápida OWASP Top 10](#referência-rápida-owasp-top-10)

## Verificações pré-commit

- [ ] Sem segredos no código (`git diff --cached | grep -i "password\|secret\|api_key\|token"`)
- [ ] `.gitignore` cobre: `.env`, `.env.local`, `*.pem`, `*.key`
- [ ] `.env.example` usa valores placeholder (não segredos reais)

## Autenticação

- [ ] Senhas com hash bcrypt (≥12 rounds), scrypt ou argon2
- [ ] Cookies de sessão: `httpOnly`, `secure`, `sameSite: 'lax'`
- [ ] Expiração de sessão configurada (max-age razoável)
- [ ] Rate limiting no login (≤10 tentativas por 15 minutos)
- [ ] Tokens de redefinição de senha: tempo limitado (≤1 hora), uso único
- [ ] Bloqueio de conta após falhas repetidas (opcional, com notificação)
- [ ] MFA para operações sensíveis (opcional, recomendado)

## Autorização

- [ ] Todo endpoint protegido verifica autenticação
- [ ] Todo acesso a recurso verifica posse/papel (evita IDOR)
- [ ] Endpoints admin exigem verificação de papel admin
- [ ] Chaves de API com escopo mínimo necessário
- [ ] Tokens JWT validados (assinatura, expiração, emissor)

## Validação de entrada

- [ ] Toda entrada de usuário validada nas fronteiras (rotas API, handlers de formulário)
- [ ] Validação com listas permitidas (não listas de negação)
- [ ] Comprimentos de string limitados (mín/máx)
- [ ] Intervalos numéricos validados
- [ ] Formatos de e-mail, URL e data com bibliotecas adequadas
- [ ] Uploads: tipo restrito, tamanho limitado, conteúdo verificado
- [ ] Consultas SQL parametrizadas (sem concatenação de strings)
- [ ] Saída HTML codificada (escape automático do framework)
- [ ] URLs validadas antes do redirect (evitar redirect aberto)

## Cabeçalhos de segurança

```
Content-Security-Policy: default-src 'self'; script-src 'self'
Strict-Transport-Security: max-age=31536000; includeSubDomains
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-XSS-Protection: 0  (desativado, confiar no CSP)
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: camera=(), microphone=(), geolocation=()
```

## Configuração CORS

```typescript
// Restritivo (recomendado)
cors({
  origin: ['https://yourdomain.com', 'https://app.yourdomain.com'],
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
})

// NUNCA em produção:
cors({ origin: '*' })  // Permite qualquer origem
```

## Proteção de dados

- [ ] Campos sensíveis excluídos das respostas da API (`passwordHash`, `resetToken`, etc.)
- [ ] Dados sensíveis não vão para log (senhas, tokens, cartão completo)
- [ ] PII cifrada em repouso (se a regulamentação exigir)
- [ ] HTTPS em toda comunicação externa
- [ ] Backups de banco cifrados

## Segurança de dependências

```bash
# Auditar dependências
npm audit

# Corrigir automaticamente quando possível
npm audit fix

# Checar vulnerabilidades críticas
npm audit --audit-level=critical

# Manter dependências atualizadas
npx npm-check-updates
```

## Tratamento de erros

```typescript
// Produção: erro genérico, sem detalhes internos
res.status(500).json({
  error: { code: 'INTERNAL_ERROR', message: 'Something went wrong' }
});

// NUNCA em produção:
res.status(500).json({
  error: err.message,
  stack: err.stack,         // Expõe detalhes internos
  query: err.sql,           // Expõe detalhes do banco
});
```

## Referência rápida OWASP Top 10

| # | Vulnerabilidade | Prevenção |
|---|---|---|
| 1 | Quebra de controle de acesso | Auth em todo endpoint, verificação de posse |
| 2 | Falhas criptográficas | HTTPS, hashing forte, sem segredos no código |
| 3 | Injeção | Consultas parametrizadas, validação de entrada |
| 4 | Design inseguro | Modelagem de ameaças, desenvolvimento guiado por especificação |
| 5 | Configuração incorreta | Cabeçalhos de segurança, permissões mínimas, auditar deps |
| 6 | Componentes vulneráveis | `npm audit`, deps atualizadas, deps mínimas |
| 7 | Falhas de identificação e autenticação | Senhas fortes, rate limiting, gestão de sessão |
| 8 | Falhas de integridade de software | Verificar updates/deps, artefatos assinados |
| 9 | Falhas de registro e monitoramento | Registrar eventos de segurança, não logar segredos |
| 10 | SSRF | Validar/listar URLs permitidas, restringir saída |
