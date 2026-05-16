---
name: performance-optimization
description: Otimiza o desempenho da aplicação. Use quando houver requisitos de desempenho, quando suspeitar de regressões ou quando Core Web Vitals ou tempos de carregamento precisarem melhorar. Use quando o profiling apontar gargalos a corrigir.
---

# Otimização de desempenho

## Visão Geral

Meça antes de otimizar. Trabalho de desempenho sem medição é chute — e chute leva a otimização prematura que adiciona complexidade sem melhorar o que importa. Profile primeiro, identifique o gargalo real, corrija, meça de novo. Otimize só o que as medições provam que importa.

**Escopo:** Grande parte do conteúdo abaixo foca **aplicações web** (Core Web Vitals, bundles, Lighthouse). Para **Python / desktop / visão computacional** (PySide6, OpenCV, workers, inferência YOLO), use o mesmo fluxo (medir → identificar → corrigir → verificar) com ferramentas adequadas: `cProfile` ou `py-spy`, `time.perf_counter`, medição de inferência e I/O de câmera, sempre conforme o PRD do projeto.

## Quando Usar

- A especificação define requisitos de desempenho (orçamentos de tempo de carregamento, SLAs de tempo de resposta)
- Usuários ou monitoramento reportam lentidão
- Os scores de Core Web Vitals estão abaixo dos limiares
- Suspeita de que uma alteração introduziu regressão
- A construir funcionalidades com grandes volumes de dados ou tráfego elevado

**Quando NÃO usar:** Não otimize antes de ter evidência de um problema. Otimização prematura adiciona complexidade que custa mais do que o desempenho que ganha.

## Metas de Core Web Vitals

| Métrica | Bom | Precisa melhorar | Fraco |
|---------|-----|------------------|--------|
| **LCP** (Largest Contentful Paint) | ≤ 2,5s | ≤ 4,0s | > 4,0s |
| **INP** (Interaction to Next Paint) | ≤ 200ms | ≤ 500ms | > 500ms |
| **CLS** (Cumulative Layout Shift) | ≤ 0,1 | ≤ 0,25 | > 0,25 |

## Fluxo de otimização

```
1. MEDIR     → Estabelecer linha de base com dados reais
2. IDENTIFICAR → Encontrar o gargalo real (não o assumido)
3. CORRIGIR  → Tratar o gargalo específico
4. VERIFICAR → Medir de novo, confirmar melhoria
5. PROTEGER  → Adicionar monitoramento ou testes para evitar regressão
```

### Etapa 1: Medir

Dois enfoques complementares — use ambos:

- **Sintético (Lighthouse, separador Performance do DevTools):** Condições controladas, reprodutíveis. Melhor para detecção de regressão em CI e isolar problemas específicos.
- **RUM (biblioteca web-vitals, CrUX):** Dados reais de usuários em condições reais. Necessário para validar se a correção melhorou de fato a experiência do usuário.

**Frontend:**
```bash
# Sintético: Lighthouse no Chrome DevTools (ou CI)
# Chrome DevTools → separador Performance → Gravar
# Chrome DevTools MCP → rastreio de desempenho (performance trace)

# RUM: biblioteca Web Vitals no código
import { onLCP, onINP, onCLS } from 'web-vitals';

onLCP(console.log);
onINP(console.log);
onCLS(console.log);
```

**Backend:**
```bash
# Registo de tempos de resposta
# Application Performance Monitoring (APM)
# Registo de consultas à base de dados com tempos

# Temporização simples
console.time('db-query');
const result = await db.query(...);
console.timeEnd('db-query');
```

### Por onde começar a medir

Use o sintoma para decidir o que medir primeiro:

```
O que está lento?
├── Primeiro carregamento da página
│   ├── Bundle grande? --> Medir tamanho do bundle, verificar code splitting
│   ├── Resposta do servidor lenta? --> Medir TTFB na cascata Network do DevTools
│   │   ├── DNS longo? --> dns-prefetch / preconnect para origens conhecidas
│   │   ├── TCP/TLS longo? --> Ativar HTTP/2, verificar edge, keep-alive
│   │   └── Waiting (servidor) longo? --> Profile do backend, consultas e cache
│   └── Recursos que bloqueiam render? --> Cascata de rede para CSS/JS bloqueantes
├── Interação “pesada”
│   ├── UI trava ao clicar? --> Profile da main thread, tarefas longas (>50ms)
│   ├── Atraso no input de formulário? --> Re-renderizações, overhead de controlados
│   └── “Jank” em animações? --> Layout thrashing, reflows forçados
├── Página após navegação
│   ├── Carregamento de dados? --> Tempos de resposta da API, waterfalls
│   └── Render no cliente? --> Tempo de render dos componentes, fetches N+1
└── Backend / API
    ├── Um endpoint lento? --> Profile de consultas à BD, índices
    ├── Todos os endpoints lentos? --> Connection pool, memória, CPU
    └── Lentidão intermitente? --> Contenção de locks, pausas de GC, dependências externas
```

### Etapa 2: Identificar o gargalo

Gargalos comuns por categoria:

**Frontend:**

| Sintoma | Causa provável | Investigação |
|---------|----------------|---------------|
| LCP lento | Imagens grandes, recursos bloqueantes, servidor lento | Cascata de rede, tamanhos de imagem |
| CLS alto | Imagens sem dimensões, conteúdo tardio, mudanças de fonte | Atribuição de layout shift |
| INP fraco | JavaScript pesado na main thread, atualizações grandes no DOM | Long tasks no rastreio Performance |
| Carregamento inicial lento | Bundle grande, muitos pedidos de rede | Tamanho do bundle, code splitting |

**Backend:**

| Sintoma | Causa provável | Investigação |
|---------|----------------|---------------|
| APIs lentas | Consultas N+1, índices em falta, queries não otimizadas | Log de consultas à BD |
| Crescimento de memória | Referências em fuga, caches sem limite, payloads grandes | Análise de heap snapshot |
| Picos de CPU | Cálculo pesado síncrono, backtracking de regex | Profiling de CPU |
| Latência alta | Cache em falta, computação redundante, saltos de rede | Rastrear pedidos na stack |

### Etapa 3: Corrigir anti-padrões comuns

#### Consultas N+1 (Backend)

```typescript
// MAU: N+1 — uma query por tarefa para o dono
const tasks = await db.tasks.findMany();
for (const task of tasks) {
  task.owner = await db.users.findUnique({ where: { id: task.ownerId } });
}

// BOM: Uma query com join/include
const tasks = await db.tasks.findMany({
  include: { owner: true },
});
```

#### Obtenção de dados sem limite

```typescript
// MAU: Trazer todos os registos
const allTasks = await db.tasks.findMany();

// BOM: Paginado com limites
const tasks = await db.tasks.findMany({
  take: 20,
  skip: (page - 1) * 20,
  orderBy: { createdAt: 'desc' },
});
```

#### Otimização de imagens em falta (Frontend)

```html
<!-- MAU: Sem dimensões, sem otimização de formato -->
<img src="/hero.jpg" />

<!-- BOM: Imagem hero / LCP — art direction + troca de resolução, prioridade alta -->
<!--
  Duas técnicas combinadas:
  - Art direction (media): recorte/composição diferentes por breakpoint
  - Troca de resolução (srcset + sizes): arquivo certo por densidade de tela
-->
<picture>
  <!-- Mobile: recorte portrait (8:10) -->
  <source
    media="(max-width: 767px)"
    srcset="/hero-mobile-400.avif 400w, /hero-mobile-800.avif 800w"
    sizes="100vw"
    width="800"
    height="1000"
    type="image/avif"
  />
  <source
    media="(max-width: 767px)"
    srcset="/hero-mobile-400.webp 400w, /hero-mobile-800.webp 800w"
    sizes="100vw"
    width="800"
    height="1000"
    type="image/webp"
  />
  <!-- Desktop: recorte landscape (2:1) -->
  <source
    srcset="/hero-800.avif 800w, /hero-1200.avif 1200w, /hero-1600.avif 1600w"
    sizes="(max-width: 1200px) 100vw, 1200px"
    width="1200"
    height="600"
    type="image/avif"
  />
  <source
    srcset="/hero-800.webp 800w, /hero-1200.webp 1200w, /hero-1600.webp 1600w"
    sizes="(max-width: 1200px) 100vw, 1200px"
    width="1200"
    height="600"
    type="image/webp"
  />
  <img
    src="/hero-desktop.jpg"
    width="1200"
    height="600"
    fetchpriority="high"
    alt="Descrição da imagem hero"
  />
</picture>

<!-- BOM: Imagem abaixo da dobra — lazy + decoding assíncrono -->
<img
  src="/content.webp"
  width="800"
  height="400"
  loading="lazy"
  decoding="async"
  alt="Descrição da imagem de conteúdo"
/>
```

#### Re-renderizações desnecessárias (React)

```tsx
// MAU: Cria novo objeto a cada render, filhos re-renderizam
function TaskList() {
  return <TaskFilters options={{ sortBy: 'date', order: 'desc' }} />;
}

// BOM: Referência estável
const DEFAULT_OPTIONS = { sortBy: 'date', order: 'desc' } as const;
function TaskList() {
  return <TaskFilters options={DEFAULT_OPTIONS} />;
}

// React.memo em componentes pesados
const TaskItem = React.memo(function TaskItem({ task }: Props) {
  return <div>{/* render dispendioso */}</div>;
});

// useMemo para cálculos pesados
function TaskStats({ tasks }: Props) {
  const stats = useMemo(() => calculateStats(tasks), [tasks]);
  return <div>{stats.completed} / {stats.total}</div>;
}
```

#### Bundle grande

```typescript
// Bundlers modernos (Vite, webpack 5+) tratam imports nomeados com tree-shaking,
// desde que a dependência seja ESM e tenha `sideEffects: false` no package.json.
// Profile antes de mudar estilos de import — o ganho real vem de splitting e lazy loading.

// BOM: import dinâmico para funcionalidades pesadas e raras
const ChartLibrary = lazy(() => import('./ChartLibrary'));

// BOM: code splitting a nível de rota com Suspense
const SettingsPage = lazy(() => import('./pages/Settings'));

function App() {
  return (
    <Suspense fallback={<Spinner />}>
      <SettingsPage />
    </Suspense>
  );
}
```

#### Cache em falta (Backend)

```typescript
// Cache de dados muito lidos, raramente alterados
const CACHE_TTL = 5 * 60 * 1000; // 5 minutos
let cachedConfig: AppConfig | null = null;
let cacheExpiry = 0;

async function getAppConfig(): Promise<AppConfig> {
  if (cachedConfig && Date.now() < cacheExpiry) {
    return cachedConfig;
  }
  cachedConfig = await db.config.findFirst();
  cacheExpiry = Date.now() + CACHE_TTL;
  return cachedConfig;
}

// Cabeçalhos HTTP de cache para estáticos
app.use('/static', express.static('public', {
  maxAge: '1y',           // Cache 1 ano
  immutable: true,        // Sem revalidar (use hash de conteúdo nos nomes)
}));

// Cache-Control para respostas de API
res.set('Cache-Control', 'public, max-age=300'); // 5 minutos
```

## Orçamento de desempenho (performance budget)

Defina orçamentos e faça-os cumprir:

```
Bundle JavaScript: < 200KB gzip (carga inicial)
CSS: < 50KB gzip
Imagens: < 200KB por imagem (acima da dobra)
Fontes: < 100KB no total
Tempo de resposta da API: < 200ms (p95)
Time to Interactive: < 3,5s em 4G
Score Lighthouse Performance: ≥ 90
```

**Aplicar em CI:**
```bash
# Verificação de tamanho do bundle
npx bundlesize --config bundlesize.config.json

# Lighthouse CI
npx lhci autorun
```

## Ver também

Para listas de verificação detalhadas, comandos de otimização e referência de anti-padrões, veja `references/performance-checklist.md`.


## Racionalizações Comuns

| Racionalização | Realidade |
|---|---|
| “Otimizamos depois” | Dívida de desempenho compõe. Corrija anti-padrões óbvios agora, adie micro-otimizações. |
| “No meu PC é rápido” | A sua máquina não é a do usuário. Use profiling em hardware e redes representativos. |
| “Esta otimização é óbvia” | Se não mediste, não sabes. Profile primeiro. |
| “Os usuários não notam 100ms” | Estudos mostram que atrasos de 100ms afetam conversão. Notam-se mais do que imaginas. |
| “O framework trata do desempenho” | Frameworks evitam alguns problemas, mas não corrigem N+1 nem bundles excessivos. |

## Sinais de Alerta

- Otimização sem dados de profiling que a justifiquem
- Padrões N+1 na obtenção de dados
- Endpoints de listagem sem paginação
- Imagens sem dimensões, lazy loading ou tamanhos responsivos
- Tamanho do bundle a crescer sem revisão
- Sem monitoramento de desempenho em produção
- `React.memo` e `useMemo` em todo o lado (excesso é tão mau como falta)

## Verificação

Após qualquer alteração relacionada com desempenho:

- [ ] Existem medições antes e depois (números concretos)
- [ ] O gargalo específico foi identificado e tratado
- [ ] Core Web Vitals estão na gama “Bom”
- [ ] O tamanho do bundle não aumentou de forma significativa
- [ ] Não há consultas N+1 no novo código de obtenção de dados
- [ ] O orçamento de desempenho passa no CI (se configurado)
- [ ] Os testes existentes ainda passam (a otimização não quebrou comportamento)
