# Checklist de desempenho

Referência rápida para desempenho de aplicações web. Use junto com a skill `performance-optimization`.

## Índice

- [Metas Core Web Vitals](#metas-core-web-vitals)
- [Diagnóstico de TTFB](#diagnóstico-de-ttfb)
- [Checklist frontend](#checklist-frontend)
- [Checklist backend](#checklist-backend)
- [Comandos de medição](#comandos-de-medicao)
- [Antipadrões comuns](#antipadrões-comuns)

## Metas Core Web Vitals

| Métrica | Bom | Precisa melhorar | Ruim |
|---------|-----|------------------|------|
| LCP (Largest Contentful Paint) | ≤ 2,5s | ≤ 4,0s | > 4,0s |
| INP (Interaction to Next Paint) | ≤ 200ms | ≤ 500ms | > 500ms |
| CLS (Cumulative Layout Shift) | ≤ 0,1 | ≤ 0,25 | > 0,25 |

## Diagnóstico de TTFB

Quando o TTFB estiver lento (> 800ms), verifique cada parte na cascata Network do DevTools:

- [ ] **Resolução DNS** lenta → adicione `<link rel="dns-prefetch">` ou `<link rel="preconnect">` para origens conhecidas
- [ ] **Handshake TCP/TLS** lento → habilite HTTP/2, considere edge, verifique keep-alive
- [ ] **Processamento no servidor** lento → perfilar backend, checar consultas lentas, adicionar cache

## Checklist frontend

### Imagens
- [ ] Formatos modernos (WebP, AVIF)
- [ ] Tamanhos responsivos (`srcset` e `sizes`)
- [ ] Imagens e `<source>` com `width` e `height` explícitos (reduz CLS em art direction)
- [ ] Imagens abaixo da dobra com `loading="lazy"` e `decoding="async"`
- [ ] Imagens hero/LCP com `fetchpriority="high"` e sem lazy loading

### JavaScript
- [ ] Bundle inicial sob ~200KB gzip
- [ ] Code splitting com `import()` dinâmico para rotas e blocos pesados
- [ ] Tree shaking habilitado (dependência ESM e `sideEffects: false`)
- [ ] Sem JS bloqueante no `<head>` (use `defer` ou `async`)
- [ ] Cálculo pesado em Web Workers (quando aplicável)
- [ ] `React.memo()` em componentes caros que re-renderizam com as mesmas props
- [ ] `useMemo()` / `useCallback()` só onde o profiling mostrar ganho
- [ ] Tarefas longas (> 50ms) fatiadas para manter a thread principal livre — alavanca principal do INP
- [ ] Padrão `yieldToMain` em loops longos para eventos de entrada rodarem entre fatias
- [ ] APIs de agendamento modernas: `scheduler.yield()` (preferido), `scheduler.postTask()` com prioridades, `isInputPending()` para ceder só quando necessário
- [ ] `requestIdleCallback` para trabalho adiável não urgente (flush de analytics, prefetch, warmup)
- [ ] Trabalho não crítico fora dos handlers de evento (analytics, log) para não atrasar a resposta à interação
- [ ] Scripts de terceiros com `async` / `defer`, auditados em tamanho, com fachada quando pesados (chat, embeds)

### CSS
- [ ] CSS crítico inlined ou pré-carregado
- [ ] Sem CSS bloqueante para estilos não críticos
- [ ] Sem custo de CSS-in-JS em runtime na produção (use extração)

### Fontes
- [ ] Limitar a 2–3 famílias, 2–3 pesos cada (cada peso a mais é outro request)
- [ ] Só WOFF2 (menor, suporte universal — pule WOFF/TTF/EOT)
- [ ] Auto-hospedar quando possível (CDNs de fonte somam DNS + TCP + TLS)
- [ ] Fontes críticas para LCP pré-carregadas: `<link rel="preload" as="font" type="font/woff2" crossorigin>`
- [ ] `font-display: swap` (ou `optional` para não críticas) para evitar FOIT bloqueando render
- [ ] Subconjuntos com `unicode-range` para enviar só os glifos necessários
- [ ] Fontes variáveis quando vários pesos/estilos (um arquivo em vez de vários)
- [ ] Métricas de fallback com `size-adjust`, `ascent-override`, `descent-override` para reduzir CLS no swap
- [ ] Considerar stack de fontes do sistema antes de fonte customizada

### Rede
- [ ] Assets estáticos com `max-age` longo + hash no nome
- [ ] Respostas de API em cache quando apropriado (`Cache-Control`)
- [ ] HTTP/2 ou HTTP/3 habilitados
- [ ] Preconnect (`<link rel="preconnect">`) para origens conhecidas
- [ ] `fetchpriority` em recursos críticos que não são imagem (ex.: `<link rel="preload">` chave, `<script>` acima da dobra)
- [ ] Sem redirects desnecessários

### Renderização
- [ ] Sem layout thrashing (layouts síncronos forçados)
- [ ] Animações com `transform` e `opacity` (aceleradas na GPU)
- [ ] Listas longas virtualizadas (ex.: `react-window`)
- [ ] Sem re-render de página inteira desnecessário
- [ ] Seções fora da tela com `content-visibility: auto` e `contain-intrinsic-size` para pular layout/pintura
- [ ] Sem handlers de `unload` e sem `Cache-Control: no-store` no HTML — preserva elegibilidade ao bfcache

## Checklist backend

### Banco de dados
- [ ] Sem padrão N+1 (use eager loading / joins)
- [ ] Consultas com índices adequados
- [ ] Endpoints de lista paginados (nunca `SELECT * FROM tabela` sem limite)
- [ ] Pool de conexões configurado
- [ ] Log de consultas lentas habilitado

### API
- [ ] Tempos de resposta < 200ms (p95)
- [ ] Sem computação pesada síncrona nos handlers
- [ ] Operações em lote em vez de loops de chamadas individuais
- [ ] Compressão de resposta (gzip/brotli)
- [ ] Cache apropriado (memória, Redis, CDN)

### Infraestrutura
- [ ] CDN para assets estáticos
- [ ] Servidor próximo dos usuários (ou edge)
- [ ] Escalonamento horizontal configurado (se necessário)
- [ ] Endpoint de health check para o balanceador

## Comandos de medição

### Dados de campo INP e fluxo no DevTools

1. **Dados de campo primeiro** — consulte [CrUX Vis](https://developer.chrome.com/docs/crux/vis) ou sua ferramenta RUM para INP de usuários reais antes de otimizar
2. **Identificar interações lentas** — DevTools → Painel Performance → gravar enquanto interage; procure long tasks disparadas por cliques/teclas
3. **Testar em Android médio** — problemas de INP costumam aparecer só em hardware mais lento; use dispositivo real ou throttling de CPU (4×–6×)

```bash
# Lighthouse CLI
npx lighthouse https://localhost:3000 --output json --output-path ./report.json

# Análise de bundle
npx webpack-bundle-analyzer stats.json
# ou com Vite:
npx vite-bundle-visualizer

# Tamanho do bundle
npx bundlesize

# Web Vitals no código
import { onLCP, onINP, onCLS } from 'web-vitals';
onLCP(console.log);
onINP(console.log);
onCLS(console.log);

# INP com detalhe por interação (build attribution)
import { onINP } from 'web-vitals/attribution';
onINP(({ value, attribution }) => {
  const { interactionTarget, inputDelay, processingDuration, presentationDelay } = attribution;
  console.log({ value, interactionTarget, inputDelay, processingDuration, presentationDelay });
});
```

## Antipadrões comuns

| Antipadrão | Impacto | Correção |
|---|---|---|
| Consultas N+1 | Carga no DB cresce linearmente | Joins, includes ou carregamento em lote |
| Consultas sem limite | Memória, timeouts | Sempre paginar, adicionar LIMIT |
| Índices faltando | Leituras lentas conforme dados crescem | Índices para colunas filtradas/ordenadas |
| Layout thrashing | Travamentos, frames perdidos | Agrupar leituras DOM, depois escritas |
| Imagens não otimizadas | LCP lento, banda desperdiçada | WebP, tamanhos responsivos, lazy load |
| Bundles grandes | TTI lento | Code split, tree shake, auditar deps |
| Thread principal bloqueada | INP ruim, UI travada | Fatie tarefas com `scheduler.yield()` / `yieldToMain`, Web Workers |
| Vazamentos de memória | Memória crescente, crash eventual | Limpar listeners, intervals, refs |
