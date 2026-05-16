---
name: source-driven-development
description: Ancora cada decisão de implementação na documentação oficial. Use quando quiser código com fontes oficiais citadas, livre de padrões desatualizados. Use quando estiver desenvolvendo com qualquer framework ou biblioteca em que a correção importe.
---

# Desenvolvimento orientado à fonte

## Visão geral

Toda decisão de código específica de framework deve estar apoiada na documentação oficial. Não implemente de memória — verifique, cite e deixe o usuário ver suas fontes. Dados de treinamento envelhecem, APIs são descontinuadas e as melhores práticas evoluem. Esta skill garante que o usuário receba código confiável porque cada padrão remonta a uma fonte autoritativa que ele pode conferir.

## Quando usar

- O usuário quer código que siga as melhores práticas atuais de um determinado framework
- Construindo boilerplate, código inicial ou padrões que serão copiados no projeto
- O usuário pede explicitamente implementação documentada, verificada ou "correta"
- Implementando recursos em que a abordagem recomendada pelo framework importa (formulários, roteamento, busca de dados, gerenciamento de estado, autenticação)
- Revisando ou melhorando código que usa padrões específicos de framework
- Sempre que estiver prestes a escrever código específico de framework de memória

**Quando NÃO usar:**

- A correção não depende de uma versão específica (renomear variáveis, corrigir typos, mover arquivos)
- Lógica pura que funciona igual em todas as versões (laços, condicionais, estruturas de dados)
- O usuário quer explicitamente velocidade em vez de verificação ("só faz logo")

## O processo

```
DETECTAR ──→ BUSCAR ──→ IMPLEMENTAR ──→ CITAR
   │          │            │              │
   ▼          ▼            ▼              ▼
 Qual      Obter os      Seguir os     Mostrar suas
 stack?    docs          padrões       fontes
           relevantes    documentados
```

### Passo 1: Detectar stack e versões

Leia o arquivo de dependências do projeto para identificar versões exatas:

```
package.json    → Node/React/Vue/Angular/Svelte
composer.json   → PHP/Symfony/Laravel
requirements.txt / pyproject.toml → Python/Django/Flask
go.mod          → Go
Cargo.toml      → Rust
Gemfile         → Ruby/Rails
```

Declare explicitamente o que encontrou:

```
STACK DETECTADA:
- React 19.1.0 (de package.json)
- Vite 6.2.0
- Tailwind CSS 4.0.3
→ Buscando documentação oficial para os padrões relevantes.
```

Se as versões estiverem ausentes ou ambíguas, **pergunte ao usuário**. Não adivinhe — a versão determina quais padrões são corretos.

### Passo 2: Buscar documentação oficial

Busque a página específica da documentação para o recurso que está implementando. Não a página inicial, não a documentação inteira — a página relevante.

**Hierarquia de fontes (por autoridade):**

| Prioridade | Fonte | Exemplo |
|------------|-------|---------|
| 1 | Documentação oficial | react.dev, docs.djangoproject.com, symfony.com/doc |
| 2 | Blog oficial / changelog | react.dev/blog, nextjs.org/blog |
| 3 | Referências de padrões web | MDN, web.dev, html.spec.whatwg.org |
| 4 | Compatibilidade navegador/runtime | caniuse.com, node.green |

**Não autoritativo — nunca cite como fonte principal:**

- Respostas do Stack Overflow
- Posts de blog ou tutoriais (mesmo populares)
- Documentação ou resumos gerados por IA
- Seus próprios dados de treinamento (esse é o ponto — verifique)

**Seja preciso no que busca:**

```
RUIM:  Buscar a página inicial do React
BOM: Buscar react.dev/reference/react/useActionState

RUIM:  Pesquisar "django authentication best practices"
BOM: Buscar docs.djangoproject.com/en/6.0/topics/auth/
```

Depois de buscar, extraia os padrões-chave e anote avisos de descontinuação ou orientação de migração.

Quando fontes oficiais divergirem (por exemplo, um guia de migração contradiz a referência da API), exponha a discrepância ao usuário e verifique qual padrão realmente funciona na versão detectada.

### Passo 3: Implementar seguindo padrões documentados

Escreva código que corresponda ao que a documentação mostra:

- Use as assinaturas de API dos docs, não da memória
- Se os docs mostrarem uma forma nova de fazer algo, use a forma nova
- Se os docs descontinuarem um padrão, não use a versão descontinuada
- Se os docs não cobrirem algo, sinalize como não verificado

**Quando os docs divergem do código existente do projeto:**

```
CONFLITO DETECTADO:
A base existente usa useState para estado de carregamento do formulário,
mas os docs do React 19 recomendam useActionState para esse padrão.
(Fonte: react.dev/reference/react/useActionState)

Opções:
A) Usar o padrão moderno (useActionState) — alinhado à documentação atual
B) Manter o código existente (useState) — alinhado à base de código
→ Qual abordagem você prefere?
```

Exponha o conflito. Não escolha uma opção em silêncio.

### Passo 4: Citar suas fontes

Todo padrão específico de framework recebe uma citação. O usuário deve poder verificar cada decisão.

**Em comentários no código:**

```typescript
// React 19 form handling with useActionState
// Source: https://react.dev/reference/react/useActionState#usage
const [state, formAction, isPending] = useActionState(submitOrder, initialState);
```

**Na conversa:**

```
Estou usando useActionState em vez de useState manual para o
estado de envio do formulário. O React 19 substituiu o padrão manual
isPending/setIsPending por esse hook.

Source: https://react.dev/blog/2024/12/05/react-19#actions
"useTransition now supports async functions [...] to handle
pending states automatically"
```

**Regras de citação:**

- URLs completas, não encurtadas
- Prefira links profundos com âncoras quando possível (ex.: `/useActionState#usage` em vez de só `/useActionState`) — âncoras sobrevivem melhor a reorganizações da doc do que páginas de topo
- Cite o trecho relevante quando sustenta uma decisão não óbvia
- Inclua dados de suporte navegador/runtime ao recomendar recursos de plataforma
- Se não encontrar documentação para um padrão, diga explicitamente:

```
NÃO VERIFICADO: Não encontrei documentação oficial para esse
padrão. Isto se baseia em dados de treinamento e pode estar desatualizado.
Verifique antes de usar em produção.
```

Honestidade sobre o que não foi verificado vale mais que falsa confiança.

## Racionalizações comuns

| Racionalização | Realidade |
|---|---|
| "Tenho certeza dessa API" | Certeza não é evidência. Dados de treinamento contêm padrões desatualizados que parecem corretos mas quebram em versões atuais. Verifique. |
| "Buscar docs gasta tokens" | Alucinar uma API gasta mais. O usuário depura por uma hora e descobre que a assinatura da função mudou. Uma busca evita horas de retrabalho. |
| "A documentação não terá o que preciso" | Se a documentação não cobre, isso é informação valiosa — o padrão pode não ser oficialmente recomendado. |
| "Só vou mencionar que pode estar desatualizado" | Um aviso não ajuda. Ou verifique e cite, ou sinalize claramente como não verificado. O meio-termo é a pior opção. |
| "É tarefa simples, não preciso conferir" | Tarefas simples com padrões errados viram modelos. O usuário copia seu handler de formulário descontinuado em dez componentes antes de descobrir que existe abordagem moderna. |

## Sinais de alerta

- Escrever código específico de framework sem conferir a documentação dessa versão
- Usar "acho" ou "creio" sobre uma API em vez de citar a fonte
- Implementar um padrão sem saber a qual versão se aplica
- Citar Stack Overflow ou blogs em vez da documentação oficial
- Usar APIs descontinuadas porque aparecem em dados de treinamento
- Não ler `package.json` / arquivos de dependência antes de implementar
- Entregar código sem citações de fonte para decisões específicas de framework
- Buscar um site de documentação inteiro quando só uma página é relevante

## Verificação

Depois de implementar com desenvolvimento orientado à fonte:

- [ ] Versões de framework e biblioteca foram identificadas no arquivo de dependências
- [ ] Documentação oficial foi buscada para padrões específicos de framework
- [ ] Todas as fontes são documentação oficial, não blogs nem dados de treinamento
- [ ] O código segue os padrões mostrados na documentação da versão atual
- [ ] Decisões não triviais incluem citações com URLs completas
- [ ] Nenhuma API descontinuada é usada (conferido com guias de migração)
- [ ] Conflitos entre documentação e código existente foram comunicados ao usuário
- [ ] Tudo que não pôde ser verificado está explicitamente marcado como não verificado
