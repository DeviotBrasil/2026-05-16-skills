# Checklist de acessibilidade

Referência rápida para conformidade com WCAG 2.1 nível AA. Use junto com a skill `frontend-ui-engineering`.

## Índice

- [Verificações essenciais](#verificações-essenciais)
- [Padrões HTML comuns](#padrões-html-comuns)
- [Ferramentas de teste](#ferramentas-de-teste)
- [Referência rápida: regiões ARIA live](#referência-rápida-regiões-aria-live)
- [Antipadrões comuns](#antipadrões-comuns)

## Verificações essenciais

### Navegação por teclado
- [ ] Todos os elementos interativos focáveis com Tab
- [ ] Ordem de foco segue ordem visual/lógica
- [ ] Foco visível (contorno/anel nos elementos focados)
- [ ] Widgets customizados com suporte a teclado (Enter ativa, Escape fecha)
- [ ] Sem armadilhas de teclado (sempre dá para sair com Tab)
- [ ] Link “pular para o conteúdo” no topo — visível (pelo menos) ao focar com teclado
- [ ] Modais prendem o foco enquanto abertos e devolvem o foco ao fechar

### Leitores de tela
- [ ] Todas as imagens têm texto `alt` (ou `alt=""` para decorativas)
- [ ] Todos os inputs de formulário têm rótulo associado (`<label>` ou `aria-label`)
- [ ] Botões e links com texto descritivo (não “Clique aqui”)
- [ ] Botões só com ícone têm `aria-label`
- [ ] Página tem um `<h1>` e cabeçalhos não pulam níveis
- [ ] Mudanças de conteúdo dinâmico anunciadas (regiões `aria-live`)
- [ ] Tabelas têm `<th>` com escopo

### Visual
- [ ] Contraste do texto ≥ 4,5:1 (texto normal) ou ≥ 3:1 (texto grande, 18px+)
- [ ] Contraste de componentes de UI ≥ 3:1 com o fundo
- [ ] Cor não é o único meio de transmitir informação
- [ ] Texto redimensionável até 200% sem quebrar o layout
- [ ] Nada pisca mais de 3 vezes por segundo

### Formulários
- [ ] Cada campo tem rótulo visível
- [ ] Campos obrigatórios indicados (não só por cor)
- [ ] Mensagens de erro específicas e associadas ao campo
- [ ] Estado de erro visível por mais que cor (ícone, texto, borda)
- [ ] Erros de envio resumidos e focáveis
- [ ] Campos conhecidos com autocomplete (ex.: `type="email" autocomplete="email"`)

### Conteúdo
- [ ] Idioma declarado (`<html lang="en">` ou `lang="pt-BR"` conforme o caso)
- [ ] Página tem `<title>` descritivo
- [ ] Links distinguíveis do texto ao redor (não só por cor)
- [ ] Alvos de toque ≥ 44×44px no mobile
- [ ] Estados vazios com significado (não telas em branco)

## Padrões HTML comuns

### Botões vs. links

```html
<!-- Use <button> para ações -->
<button onClick={handleDelete}>Delete Task</button>

<!-- Use <a> para navegação -->
<a href="/tasks/123">View Task</a>

<!-- NUNCA use div/span como botão -->
<div onClick={handleDelete}>Delete</div>  <!-- RUIM -->
```

### Rótulos de formulário

```html
<!-- Associação explícita -->
<label htmlFor="email">Email address</label>
<input id="email" type="email" required />

<!-- Envoltório implícito -->
<label>
  Email address
  <input type="email" required />
</label>

<!-- Rótulo oculto (prefira rótulo visível) -->
<input type="search" aria-label="Search tasks" />
```

### Papéis ARIA

```html
<!-- Navegação -->
<nav aria-label="Main navigation">...</nav>
<nav aria-label="Footer links">...</nav>

<!-- Mensagens de status -->
<div role="status" aria-live="polite">Task saved</div>

<!-- Alertas -->
<div role="alert">Error: Title is required</div>

<!-- Diálogos modais -->
<dialog aria-modal="true" aria-labelledby="dialog-title">
  <h2 id="dialog-title">Confirm Delete</h2>
  ...
</dialog>

<!-- Carregamento -->
<div aria-busy="true" aria-label="Loading tasks">
  <Spinner />
</div>
```

### Listas acessíveis

```html
<ul role="list" aria-label="Tasks">
  <li>
    <input type="checkbox" id="task-1" aria-label="Complete: Buy groceries" />
    <label htmlFor="task-1">Buy groceries</label>
  </li>
</ul>
```

## Ferramentas de teste

```bash
# Auditoria automatizada
npx axe-core          # Testes programáticos de acessibilidade
npx pa11y             # Verificador de acessibilidade na CLI

# No navegador
# Chrome DevTools → Lighthouse → Accessibility
# Chrome DevTools → Elements → Accessibility tree

# Teste com leitor de tela
# macOS: VoiceOver (Cmd + F5)
# Windows: NVDA (grátis) ou JAWS
# Linux: Orca
```

## Referência rápida: regiões ARIA live

| Valor | Comportamento | Uso típico |
|-------|-----------------|------------|
| `aria-live="polite"` | Anunciado na próxima pausa | Atualizações de status, confirmações de salvamento |
| `aria-live="assertive"` | Anunciado imediatamente | Erros, alertas urgentes |
| `role="status"` | Igual a `polite` | Mensagens de status |
| `role="alert"` | Igual a `assertive` | Mensagens de erro |

## Antipadrões comuns

| Antipadrão | Problema | Correção |
|---|---|---|
| `div` como botão | Não focável, sem teclado | Use `<button>` |
| Falta de `alt` | Imagens invisíveis ao leitor de tela | Adicione `alt` descritivo |
| Estados só por cor | Invisível para daltônicos | Ícones, texto ou padrões |
| Mídia com autoplay | Desorienta, difícil parar | Controles, evitar autoplay |
| Dropdown custom sem ARIA | Inútil no teclado/leitor | `<select>` nativo ou listbox ARIA correto |
| Remover contorno de foco | Usuário não vê onde está | Estilize o contorno, não remova |
| Links/botões vazios | “Link” sem descrição | Texto ou `aria-label` |
| `tabindex > 0` | Quebra ordem natural de Tab | Use `tabindex="0"` ou `-1` apenas |
