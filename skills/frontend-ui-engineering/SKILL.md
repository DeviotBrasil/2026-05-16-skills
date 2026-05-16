---
name: frontend-ui-engineering
description: Constrói UIs de qualidade de produção. Use ao criar ou modificar interfaces voltadas ao usuário. Use ao criar componentes, implementar layouts, gerenciar estado ou quando a saída precisa parecer produção, não genérica de IA.
---

# Engenharia de UI frontend

## Visão geral

Construa interfaces de usuário de qualidade de produção: acessíveis, performáticas e visualmente polidas. O objetivo é UI que pareça feita por um engenheiro consciente de design em empresa de referência — não por IA. Isso significa aderência real ao design system, acessibilidade correta, padrões de interação cuidadosos e sem "estética genérica de IA".

## Quando usar

- Construindo novos componentes ou páginas de UI
- Modificando interfaces existentes voltadas ao usuário
- Implementando layouts responsivos
- Adicionando interatividade ou gerenciamento de estado
- Corrigindo problemas visuais ou de UX

## Arquitetura de componentes

### Estrutura de arquivos

Coloque tudo relacionado a um componente junto:

```
src/components/
  TaskList/
    TaskList.tsx          # Component implementation
    TaskList.test.tsx     # Tests
    TaskList.stories.tsx  # Storybook stories (if using)
    use-task-list.ts      # Custom hook (if complex state)
    types.ts              # Component-specific types (if needed)
```

### Padrões de componentes

**Prefira composição a configuração:**

```tsx
// Good: Composable
<Card>
  <CardHeader>
    <CardTitle>Tasks</CardTitle>
  </CardHeader>
  <CardBody>
    <TaskList tasks={tasks} />
  </CardBody>
</Card>

// Avoid: Over-configured
<Card
  title="Tasks"
  headerVariant="large"
  bodyPadding="md"
  content={<TaskList tasks={tasks} />}
/>
```

**Mantenha componentes focados:**

```tsx
// Good: Faz uma coisa só
export function TaskItem({ task, onToggle, onDelete }: TaskItemProps) {
  return (
    <li className="flex items-center gap-3 p-3">
      <Checkbox checked={task.done} onChange={() => onToggle(task.id)} />
      <span className={task.done ? 'line-through text-muted' : ''}>{task.title}</span>
      <Button variant="ghost" size="sm" onClick={() => onDelete(task.id)}>
        <TrashIcon />
      </Button>
    </li>
  );
}
```

**Separe busca de dados da apresentação:**

```tsx
// Container: lida com dados
export function TaskListContainer() {
  const { tasks, isLoading, error } = useTasks();

  if (isLoading) return <TaskListSkeleton />;
  if (error) return <ErrorState message="Falha ao carregar tarefas" retry={refetch} />;
  if (tasks.length === 0) return <EmptyState message="Nenhuma tarefa ainda" />;

  return <TaskList tasks={tasks} />;
}

// Presentation: lida com renderização
export function TaskList({ tasks }: { tasks: Task[] }) {
  return (
    <ul role="list" className="divide-y">
      {tasks.map(task => <TaskItem key={task.id} task={task} />)}
    </ul>
  );
}
```

## Gerenciamento de estado

**Escolha a abordagem mais simples que funcione:**

```
Estado local (useState)           → Estado de UI específico do componente
Estado elevado                     → Compartilhado entre 2–3 irmãos
Contexto                           → Tema, auth, locale (muita leitura, pouca escrita)
Estado na URL (searchParams)       → Filtros, paginação, estado compartilhável
Estado do servidor (React Query, SWR)  → Dados remotos com cache
Store global (Zustand, Redux)     → Estado cliente complexo em todo o app
```

**Evite prop drilling além de 3 níveis.** Se estiver passando props por componentes que não as usam, introduza contexto ou reestruture a árvore.

## Aderência ao design system

### Evite a estética de IA

UIs geradas por IA têm padrões reconhecidos. Evite todos:

| Padrão default de IA | Por que é problema | Qualidade de produção |
|---|---|---|
| Tudo roxo/anil | Modelos defaultam em paletas "seguras", deixando todo app igual | Use a paleta real do projeto |
| Gradientes em excesso | Ruído visual e conflito com a maioria dos design systems | Gradientes planos ou sutis alinhados ao DS |
| Tudo muito arredondado (rounded-2xl) | Arredondamento máximo ignora hierarquia de raios em designs reais | Border-radius consistente do design system |
| Heróis genéricos | Layout de template sem conexão com conteúdo ou necessidade do usuário | Layouts centrados no conteúdo |
| Copy estilo lorem ipsum | Texto placeholder esconde problemas que conteúdo real revela (comprimento, quebra, overflow) | Placeholder realista |
| Padding enorme em tudo | Padding generoso igual destrói hierarquia e desperdiça espaço | Escala de espaçamento consistente |
| Grids de cards genéricos | Grids uniformes ignoram prioridade informacional e padrões de escaneamento | Layouts com propósito |
| Design carregado de sombra | Sombras em camadas competem com conteúdo e prejudicam renderização em aparelhos fracos | Sombras sutis ou ausentes salvo o DS |

### Espaçamento e layout

Use escala de espaçamento consistente. Não invente valores:

```css
/* Use the scale: 0.25rem increments (or whatever the project uses) */
/* Good */  padding: 1rem;      /* 16px */
/* Good */  gap: 0.75rem;       /* 12px */
/* Bad */   padding: 13px;      /* Not on any scale */
/* Bad */   margin-top: 2.3rem; /* Not on any scale */
```

### Tipografia

Respeite a hierarquia tipográfica:

```
h1 → Título da página (um por página)
h2 → Título de seção
h3 → Título de subseção
body → Texto padrão
small → Texto secundário/ajuda
```

Não pule níveis de heading. Não use estilo de heading para conteúdo que não é título.

### Cor

- Use tokens semânticos: `text-primary`, `bg-surface`, `border-default` — não hex cru
- Garanta contraste suficiente (4,5:1 texto normal, 3:1 texto grande)
- Não dependa só de cor para informação (use ícones, texto ou padrões também)

## Acessibilidade (WCAG 2.1 AA)

Todo componente deve atender estes padrões:

### Navegação por teclado

```tsx
// Every interactive element must be keyboard accessible
<button onClick={handleClick}>Click me</button>        // ✓ Focusable by default
<div onClick={handleClick}>Click me</div>               // ✗ Not focusable
<div role="button" tabIndex={0} onClick={handleClick}    // ✓ But prefer <button>
     onKeyDown={e => {
       if (e.key === 'Enter') handleClick();
       if (e.key === ' ') e.preventDefault();
     }}
     onKeyUp={e => {
      if (e.key === ' ') handleClick();
     }}>
  Click me
</div>
```

### Rótulos ARIA

```tsx
// Label interactive elements that lack visible text
<button aria-label="Close dialog"><XIcon /></button>

// Label form inputs
<label htmlFor="email">Email</label>
<input id="email" type="email" />

// Or use aria-label when no visible label exists
<input aria-label="Search tasks" type="search" />
```

### Gerenciamento de foco

```tsx
// Move focus when content changes
function Dialog({ isOpen, onClose }: DialogProps) {
  const closeRef = useRef<HTMLButtonElement>(null);

  useEffect(() => {
    if (isOpen) closeRef.current?.focus();
  }, [isOpen]);

  // Trap focus inside dialog when open
  return (
    <dialog open={isOpen}>
      <button ref={closeRef} onClick={onClose}>Close</button>
      {/* dialog content */}
    </dialog>
  );
}
```

### Estados vazios e de erro significativos

```tsx
// Don't show blank screens
function TaskList({ tasks }: { tasks: Task[] }) {
  if (tasks.length === 0) {
    return (
      <div role="status" className="text-center py-12">
        <TasksEmptyIcon className="mx-auto h-12 w-12 text-muted" />
        <h3 className="mt-2 text-sm font-medium">Nenhuma tarefa</h3>
        <p className="mt-1 text-sm text-muted">Comece criando uma nova tarefa.</p>
        <Button className="mt-4" onClick={onCreateTask}>Criar tarefa</Button>
      </div>
    );
  }

  return <ul role="list">...</ul>;
}
```

## Design responsivo

Projete mobile-first, depois expanda:

```tsx
// Tailwind: mobile-first responsive
<div className="
  grid grid-cols-1      /* Mobile: single column */
  sm:grid-cols-2        /* Small: 2 columns */
  lg:grid-cols-3        /* Large: 3 columns */
  gap-4
">
```

Teste nestes breakpoints: 320px, 768px, 1024px, 1440px.

## Carregamento e transições

```tsx
// Skeleton loading (not spinners for content)
function TaskListSkeleton() {
  return (
    <div className="space-y-3" aria-busy="true" aria-label="Loading tasks">
      {Array.from({ length: 3 }).map((_, i) => (
        <div key={i} className="h-12 bg-muted animate-pulse rounded" />
      ))}
    </div>
  );
}

// Optimistic updates for perceived speed
function useToggleTask() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: toggleTask,
    onMutate: async (taskId) => {
      await queryClient.cancelQueries({ queryKey: ['tasks'] });
      const previous = queryClient.getQueryData(['tasks']);

      queryClient.setQueryData(['tasks'], (old: Task[]) =>
        old.map(t => t.id === taskId ? { ...t, done: !t.done } : t)
      );

      return { previous };
    },
    onError: (_err, _taskId, context) => {
      queryClient.setQueryData(['tasks'], context?.previous);
    },
  });
}
```

## Ver também

Para requisitos detalhados de acessibilidade e ferramentas de teste, veja `references/accessibility-checklist.md`.

## Racionalizações comuns

| Racionalização | Realidade |
|---|---|
| "Acessibilidade é opcional" | É requisito legal em muitas jurisdições e padrão de qualidade de engenharia. |
| "Deixamos responsivo para depois" | Refatorar responsivo é 3× mais difícil que construir desde o início. |
| "O design não está final, então pulo estilo" | Use os defaults do design system. UI sem estilo cria primeira impressão ruim para revisores. |
| "É só um protótipo" | Protótipos viram código de produção. Construa a fundação certa. |
| "Estética de IA serve por enquanto" | Sinaliza baixa qualidade. Use o design system real do projeto desde o início. |

## Sinais de alerta

- Componentes com mais de 200 linhas (divida-os)
- Estilos inline ou pixels arbitrários
- Sem estados de erro, carregamento ou vazio
- Sem teste de navegação por teclado
- Cor como único indicador de estado (vermelho/verde sem texto ou ícones)
- Visual genérico de "IA" (gradientes roxos, cards enormes, layouts prontos)

## Verificação

Após construir UI:

- [ ] Componente renderiza sem erros no console
- [ ] Todos os elementos interativos são acessíveis por teclado (Tab pela página)
- [ ] Leitor de tela transmite conteúdo e estrutura da página
- [ ] Responsivo: funciona em 320px, 768px, 1024px, 1440px
- [ ] Estados de carregamento, erro e vazio tratados
- [ ] Segue o design system do projeto (espaçamento, cores, tipografia)
- [ ] Sem avisos de acessibilidade nas dev tools ou no axe-core
