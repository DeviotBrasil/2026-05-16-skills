---
name: ci-cd-and-automation
description: Automatiza configuração de pipeline CI/CD. Use ao configurar ou modificar pipelines de build e deploy. Use quando precisar automatizar portões de qualidade, configurar test runners em CI ou estabelecer estratégias de implantação.
---

# CI/CD e automação

## Visão geral

Automatize portões de qualidade para que nenhuma mudança chegue à produção sem passar por testes, lint, verificação de tipos e build. CI/CD é o mecanismo de fiscalização das outras skills — pega o que humanos e agentes perdem e faz isso de forma consistente em toda mudança.

**Shift Left:** Capture problemas o mais cedo possível no pipeline. Um bug pego no lint custa minutos; o mesmo bug em produção custa horas. Mova checagens para cima — análise estática antes de testes, testes antes de staging, staging antes de produção.

**Mais rápido é mais seguro:** Lotes menores e releases mais frequentes reduzem risco, não aumentam. Deploy com 3 mudanças é mais fácil de depurar que um com 30. Releases frequentes geram confiança no próprio processo de release.

## Quando usar

- Configurando CI novo no projeto
- Adicionando ou modificando checagens automatizadas
- Configurando pipelines de deploy
- Quando uma mudança deve disparar verificação automatizada
- Depurando falhas de CI

## Pipeline de portões de qualidade

Toda mudança passa por estes portões antes do merge:

```
Pull Request Opened
    │
    ▼
┌─────────────────┐
│   LINT CHECK     │  eslint, prettier
│   ↓ pass         │
│   TYPE CHECK     │  tsc --noEmit
│   ↓ pass         │
│   UNIT TESTS     │  jest/vitest
│   ↓ pass         │
│   BUILD          │  npm run build
│   ↓ pass         │
│   INTEGRATION    │  API/DB tests
│   ↓ pass         │
│   E2E (optional) │  Playwright/Cypress
│   ↓ pass         │
│   SECURITY AUDIT │  npm audit
│   ↓ pass         │
│   BUNDLE SIZE    │  bundlesize check
└─────────────────┘
    │
    ▼
  Ready for review
```

**Nenhum portão pode ser pulado.** Se o lint falha, corrija o lint — não desabilite a regra. Se um teste falha, corrija o código — não pule o teste.

## Configuração do GitHub Actions

### CI básico

```yaml
# .github/workflows/ci.yml
name: CI

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: '22'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Lint
        run: npm run lint

      - name: Type check
        run: npx tsc --noEmit

      - name: Test
        run: npm test -- --coverage

      - name: Build
        run: npm run build

      - name: Security audit
        run: npm audit --audit-level=high
```

### Com testes de integração e banco

```yaml
  integration:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_DB: testdb
          POSTGRES_USER: ci_user
          POSTGRES_PASSWORD: ${{ secrets.CI_DB_PASSWORD }}
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '22'
          cache: 'npm'
      - run: npm ci
      - name: Run migrations
        run: npx prisma migrate deploy
        env:
          DATABASE_URL: postgresql://ci_user:${{ secrets.CI_DB_PASSWORD }}@localhost:5432/testdb
      - name: Integration tests
        run: npm run test:integration
        env:
          DATABASE_URL: postgresql://ci_user:${{ secrets.CI_DB_PASSWORD }}@localhost:5432/testdb
```

> **Nota:** Mesmo para bancos só de teste no CI, use GitHub Secrets para credenciais em vez de valores fixos no YAML. Isso cria bons hábitos e evita reuso acidental de credenciais de teste em outros contextos.

### Testes E2E

```yaml
  e2e:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '22'
          cache: 'npm'
      - run: npm ci
      - name: Install Playwright
        run: npx playwright install --with-deps chromium
      - name: Build
        run: npm run build
      - name: Run E2E tests
        run: npx playwright test
      - uses: actions/upload-artifact@v4
        if: failure()
        with:
          name: playwright-report
          path: playwright-report/
```

## Feedback de falhas de CI para agentes

O poder do CI com agentes de IA é o loop de feedback. Quando o CI falha:

```
CI fails
    │
    ▼
Copy the failure output
    │
    ▼
Feed it to the agent:
"The CI pipeline failed with this error:
[paste specific error]
Fix the issue and verify locally before pushing again."
    │
    ▼
Agent fixes → pushes → CI runs again
```

**Padrões-chave:**

```
Falha de lint → Agente roda `npm run lint --fix` e commita
Erro de tipo  → Agente lê o local do erro e corrige o tipo
Falha de teste → Agente segue a skill debugging-and-error-recovery
Erro de build → Agente verifica config e dependências
```

## Estratégias de deploy

### Deploys de preview

Todo PR recebe deploy de preview para teste manual:

```yaml
# Preview de deploy no PR (Vercel/Netlify/etc.)
deploy-preview:
  runs-on: ubuntu-latest
  if: github.event_name == 'pull_request'
  steps:
    - uses: actions/checkout@v4
    - name: Publicar preview
      run: npx vercel --token=${{ secrets.VERCEL_TOKEN }}
```

### Feature flags

Feature flags desacoplam deploy de release. Implante recursos incompletos ou arriscados atrás de flags para:

- **Entregar código sem habilitar.** Faça merge na main cedo, habilite quando estiver pronto.
- **Reverter sem reimplantar.** Desligue a flag em vez de reverter código.
- **Canário de recursos novos.** Habilite para 1% dos usuários, depois 10%, depois 100%.
- **Rodar testes A/B.** Compare comportamento com e sem o recurso.

```typescript
// Simple feature flag pattern
if (featureFlags.isEnabled('new-checkout-flow', { userId })) {
  return renderNewCheckout();
}
return renderLegacyCheckout();
```

**Ciclo de vida da flag:** Criar → Habilitar para testes → Canário → Rollout completo → Remover flag e código morto. Flags que vivem para sempre viram dívida técnica — defina data de limpeza ao criar.

### Rollouts em estágios

```
PR merged na main
    │
    ▼
  Deploy em staging (automático)
    │ Verificação manual
    ▼
  Deploy em produção (gatilho manual ou auto após staging)
    │
    ▼
  Monitorar erros (janela de 15 minutos)
    │
    ├── Erros detectados → Rollback
    └── Limpo → Concluído
```

### Plano de reversão

Todo deploy deve ser reversível:

```yaml
# Fluxo de rollback manual
name: Rollback
on:
  workflow_dispatch:
    inputs:
      version:
        description: 'Version to rollback to'
        required: true

jobs:
  rollback:
    runs-on: ubuntu-latest
    steps:
      - name: Rollback deployment
        run: |
          # Deploy the specified previous version
          npx vercel rollback ${{ inputs.version }}
```

## Gestão de ambiente

```
.env.example       → Committed (template for developers)
.env                → NOT committed (local development)
.env.test           → Committed (test environment, no real secrets)
CI secrets          → Stored in GitHub Secrets / vault
Production secrets  → Stored in deployment platform / vault
```

O CI nunca deve ter segredos de produção. Use segredos separados para testes no CI.

## Automação além do CI

### Dependabot / Renovate

```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: npm
    directory: /
    schedule:
      interval: weekly
    open-pull-requests-limit: 5
```

### Papel de Build Cop

Designe alguém responsável por manter o CI verde. Quando o build quebra, o trabalho do Build Cop é corrigir ou reverter — não necessariamente quem causou a quebra. Isso evita builds quebrados acumulando enquanto todos acham que outro vai corrigir.

### Checagens de PR

- **Revisões obrigatórias:** Pelo menos 1 aprovação antes do merge
- **Status checks obrigatórios:** CI deve passar antes do merge
- **Pro branch:** Sem force-push na main
- **Auto-merge:** Se todas as checas passarem e estiver aprovado, merge automático

## Otimização de CI

Quando o pipeline passar de 10 minutos, aplique estas estratégias por ordem de impacto:

```
CI lento?
├── Cache dependencies
│   └── Use actions/cache or setup-node cache option for node_modules
├── Run jobs in parallel
│   └── Split lint, typecheck, test, build into separate parallel jobs
├── Only run what changed
│   └── Use path filters to skip unrelated jobs (e.g., skip e2e for docs-only PRs)
├── Use matrix builds
│   └── Shard test suites across multiple runners
├── Optimize the test suite
│   └── Remove slow tests from the critical path, run them on a schedule instead
└── Use larger runners
    └── GitHub-hosted larger runners or self-hosted for CPU-heavy builds
```

**Exemplo: cache e paralelismo**
```yaml
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '22', cache: 'npm' }
      - run: npm ci
      - run: npm run lint

  typecheck:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '22', cache: 'npm' }
      - run: npm ci
      - run: npx tsc --noEmit

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '22', cache: 'npm' }
      - run: npm ci
      - run: npm test -- --coverage
```

## Racionalizações comuns

| Racionalização | Realidade |
|---|---|
| "CI é lento demais" | Otimize o pipeline (veja Otimização de CI abaixo), não pule. Pipeline de 5 min evita horas de depuração. |
| "Mudança trivial, pula CI" | Mudanças triviais quebram builds. CI é rápido para mudanças triviais de qualquer forma. |
| "Teste floco, só roda de novo" | Testes flaky mascaram bugs reais e desperdiçam tempo de todos. Corrija a flakiness. |
| "Vamos adicionar CI depois" | Projetos sem CI acumulam estados quebrados. Configure no dia um. |
| "Teste manual basta" | Teste manual não escala nem se repete. Automatize o que puder. |

## Sinais de alerta

- Sem pipeline CI no projeto
- Falhas de CI ignoradas ou silenciadas
- Testes desabilitados no CI para o pipeline passar
- Deploy em produção sem verificação em staging
- Sem mecanismo de reversão
- Segredos em código ou arquivos de config de CI (não em secrets manager)
- CI longo sem esforço de otimização

## Verificação

Após configurar ou modificar CI:

- [ ] Todos os portões de qualidade presentes (lint, tipos, testes, build, audit)
- [ ] Pipeline roda em todo PR e push à main
- [ ] Falhas bloqueiam merge (branch protection configurada)
- [ ] Resultados de CI alimentam o loop de desenvolvimento
- [ ] Segredos no gerenciador de secrets, não no código
- [ ] Deploy tem mecanismo de reversão
- [ ] Pipeline roda em menos de 10 minutos para a suíte de testes principal
