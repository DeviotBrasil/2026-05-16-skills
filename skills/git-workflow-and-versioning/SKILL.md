---
name: git-workflow-and-versioning
description: Estrutura práticas de fluxo com Git. Use ao fazer qualquer alteração de código. Use ao fazer commits, branches, resolver conflitos ou organizar trabalho em vários fluxos paralelos.
---

# Fluxo Git e versionamento

## Visão Geral

Git é a sua rede de segurança. Trate commits como pontos de gravação, branches como caixas de areia e o histórico como documentação. Com agentes de IA gerando código em alta velocidade, o controle de versões disciplinado é o mecanismo que mantém as alterações gerenciáveis, revisáveis e reversíveis.

## Quando Usar

Sempre. Toda alteração de código passa por Git.

## Princípios centrais

### Trunk-based development (recomendado)

Mantenha `main` sempre implementável. Trabalhe em branches de funcionalidade de curta duração que voltam a integrar em 1–3 dias. Branches de desenvolvimento longas têm custo oculto — divergem, geram conflitos e atrasam a integração. Pesquisa DORA mostra que trunk-based development se correlaciona com equipes de engenharia de alto desempenho.

```
main ──●──●──●──●──●──●──●──●──●──  (sempre implementável)
        ╲      ╱  ╲    ╱
         ●──●─╱    ●──╱    ← branches de funcionalidade curtas (1–3 dias)
```

Este é o padrão recomendado. Equipes com gitflow ou branches longas podem adaptar os princípios (commits atómicos, alterações pequenas, mensagens descritivas) ao modelo de branches — a disciplina de commit importa mais do que a estratégia de branches em si.

- **Branches de dev são custo.** Cada dia de vida de uma branch acumula risco de merge.
- **Branches de release são aceitáveis.** Quando precisa estabilizar um release enquanto `main` avança.
- **Feature flags > branches longas.** Prefira entregar trabalho incompleto atrás de flags em vez de manter semanas num branch.

### 1. Commit cedo, commit frequente

Cada incremento bem-sucedido ganha o seu próprio commit. Não acumule grandes mudanças não commitadas.

```
Padrão de trabalho:
  Implementar fatia → Testar → Verificar → Commit → Próxima fatia

Evite:
  Implementar tudo → Esperar que funcione → Commit gigante
```

Commits são pontos de restauração. Se a próxima alteração quebrar algo, você volta ao último estado bom instantaneamente.

### 2. Commits atómicos

Cada commit faz uma coisa lógica:

```
# Bom: cada commit é autocontido
git log --oneline
a1b2c3d Add task creation endpoint with validation
d4e5f6g Add task creation form component
h7i8j9k Connect form to API and add loading state
m1n2o3p Add task creation tests (unit + integration)

# Ruim: tudo misturado
git log --oneline
x1y2z3a Add task feature, fix sidebar, update deps, refactor utils
```

### 3. Mensagens descritivas

Mensagens de commit explicam o **porquê**, não só o **quê**:

```
# Bom: explica intenção
feat: add email validation to registration endpoint

Evita formatos inválidos antes de chegar ao banco.
Validação com schema Zod no handler, alinhada aos padrões em auth.ts.

# Ruim: descreve o óbvio do diff
update auth.ts
```

**Formato:**
```
<tipo>: <descrição curta>

<corpo opcional explicando o porquê, não o quê>
```

**Tipos:**
- `feat` — Nova funcionalidade
- `fix` — Correção de bug
- `refactor` — Mudança que não corrige bug nem adiciona feature
- `test` — Adiciona ou atualiza testes
- `docs` — Só documentação
- `chore` — Ferramentas, dependências, config

### 4. Manter preocupações separadas

Não misture formatação com mudança de comportamento. Não misture refatoração com feature. Cada tipo de mudança deve ser um commit — e de preferência um PR:

```
# Bom: preocupações separadas
git commit -m "refactor: extract validation logic to shared utility"
git commit -m "feat: add phone number validation to registration"

# Ruim: misturado
git commit -m "refactor validation and add phone number field"
```

**Separe refatoração de funcionalidade.** São duas mudanças diferentes — envie separadamente. Limpezas pequenas (renomear variável) podem ir no commit da feature a critério do revisor.

### 5. Tamanho das alterações

Aponte para ~100 linhas por commit/PR. Acima de ~1000 linhas, divida. Veja em `code-review-and-quality` estratégias para fatiar mudanças grandes.

```
~100 linhas  → Fácil de revisar e reverter
~300 linhas  → Aceitável para uma mudança lógica única
~1000 linhas → Dividir em partes menores
```

## Estratégia de branches

### Branches de funcionalidade

```
main (sempre implementável)
  │
  ├── feature/task-creation    ← Uma funcionalidade por branch
  ├── feature/user-settings    ← Trabalho em paralelo
  └── fix/duplicate-tasks      ← Correções de bug
```

- Derive de `main` (ou branch padrão da equipe)
- Mantenha branches curtas (merge em 1–3 dias)
- Apague branches após merge
- Prefira feature flags a branches longas para trabalho incompleto

### Nomeação de branches

```
feature/<descrição-curta>   → feature/task-creation
fix/<descrição-curta>       → fix/duplicate-tasks
chore/<descrição-curta>     → chore/update-deps
refactor/<descrição-curta>  → refactor/auth-module
```

## Trabalhar com worktrees

Para agentes em paralelo, use git worktrees para várias branches ao mesmo tempo:

```bash
# Criar worktree para um branch de funcionalidade
git worktree add ../project-feature-a feature/task-creation
git worktree add ../project-feature-b feature/user-settings

# Cada worktree é um diretório com o seu branch
# Agentes podem trabalhar em paralelo sem interferir
ls ../
  project/              ← branch main
  project-feature-a/    ← branch task-creation
  project-feature-b/    ← branch user-settings

# Ao terminar, merge e limpeza
git worktree remove ../project-feature-a
```

Benefícios:
- Vários agentes em funcionalidades diferentes
- Sem troca de branch no mesmo diretório
- Se um experimento falhar, remova o worktree — nada se perde
- Alterações isoladas até merge explícito

## Padrão “ponto de gravação”

```
Agente inicia
    │
    ├── Faz uma alteração
    │   ├── Teste passa? → Commit → Continua
    │   └── Teste falha? → Volta ao último commit → Investiga
    │
    ├── Outra alteração
    │   ├── Teste passa? → Commit → Continua
    │   └── Teste falha? → Volta ao último commit → Investiga
    │
    └── Funcionalidade pronta → Histórico de commits limpo
```

Assim você não perde mais do que um incremento de trabalho. Se o agente sair do trilho, `git reset --hard HEAD` volta ao último estado bom.

## Resumos de alteração

Depois de modificar código, forneça um resumo estruturado. Facilita revisão, documenta escopo e expõe mudanças não intencionais:

```
ALTERAÇÕES FEITAS:
- src/routes/tasks.ts: middleware de validação no POST
- src/lib/validation.ts: TaskCreateSchema com Zod

NÃO ALTEREI (de propósito):
- src/routes/auth.ts: lacuna semelhante de validação, fora do escopo
- src/middleware/error.ts: formato de erro poderia melhorar (outra tarefa)

PONTOS DE ATENÇÃO:
- Schema Zod é estrito — rejeita campos extra. Confirmar se é desejado.
- Dependência zod (72KB gzipped) — já está no package.json
```

A seção “NÃO ALTEREI” mostra disciplina de escopo e evita “renovações” não pedidas.

## Higiene antes do commit

Antes de cada commit:

```bash
# 1. Ver o que vai entrar
git diff --staged

# 2. Garantir que não há segredos
git diff --staged | grep -i "password\|secret\|api_key\|token"

# 3. Rodar testes (ajuste ao projeto: npm, pytest, etc.)
npm test

# 4. Lint
npm run lint

# 5. Checagem de tipos (se aplicável)
npx tsc --noEmit
```

Automatize com hooks Git (ex.: lint-staged + husky) quando o projeto usar esse fluxo.

## Arquivos gerados

- **Versionar gerados** só se o projeto esperar (`package-lock.json`, migrações Prisma, etc.).
- **Não versionar** saída de build (`dist/`, `.next/`), `.env`, config local de IDE (salvo política partilhada).
- Tenha **`.gitignore`** cobrindo: `node_modules/`, `dist/`, `.env`, `.env.local`, `*.pem`.

## Git para depuração

```bash
# Qual commit introduziu o bug
git bisect start
git bisect bad HEAD
git bisect good <commit-bom-conhecido>
# Git faz checkout de pontos intermediários; rode o teste em cada um

# O que mudou recentemente
git log --oneline -20
git diff HEAD~5..HEAD -- src/

# Quem alterou uma linha por último
git blame src/services/task.ts

# Buscar em mensagens de commit
git log --grep="validation" --oneline
```

## Racionalizações Comuns

| Racionalização | Realidade |
|---|---|
| "Faço commit quando a feature estiver pronta" | Um commit enorme é impossível de revisar, depurar ou reverter. Commit cada fatia. |
| "A mensagem não importa" | Mensagens são documentação. O você futuro (e outros agentes) precisam entender o quê e o porquê. |
| "Depois faço squash" | Squash destrói a narrativa do desenvolvimento. Prefira commits incrementais limpos desde o início. |
| "Branches dão overhead" | Branches de vida curta são baratas e evitam colisão. O problema são branches longas — integre em 1–3 dias. |
| "Depois divido essa mudança" | Mudanças grandes são mais arriscadas. Divida antes de submeter, não depois. |
| "Não preciso de .gitignore" | Até commit acidental de `.env` com segredos. Configure desde já. |

## Sinais de Alerta

- Grandes mudanças não commitadas se acumulando
- Mensagens como "fix", "update", "misc"
- Formatação misturada com mudança de comportamento
- Projeto sem `.gitignore`
- Versionar `node_modules/`, `.env` ou artefatos de build
- Branches longas muito divergentes de `main`
- Force push em branches partilhadas

## Verificação

Para cada commit:

- [ ] O commit faz uma coisa lógica
- [ ] A mensagem explica o porquê e segue os tipos combinados
- [ ] Testes passam antes do commit
- [ ] Nenhum segredo no diff
- [ ] Não mistura só formatação com mudança de comportamento
- [ ] `.gitignore` cobre exclusões habituais
