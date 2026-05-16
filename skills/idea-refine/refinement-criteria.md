# Critérios de refinamento e avaliação

Use esta rubrica na Fase 2 (Avaliar e convergir) para stress-testar direções de ideia. Nem todo critério se aplica a toda ideia — use julgamento sobre quais dimensões mais importam no contexto.

## Dimensões centrais de avaliação

### 1. Valor ao usuário

A dimensão mais importante. Se o valor não é claro, mais nada importa.

**Analgésico vs. vitamina:**
- **Analgésico:** Resolve problema agudo e frequente. Usuários buscam ativamente. Trocam da solução atual. Sinais: descrevem o problema com emoção, criaram gambiarras, pagariam por solução.
- **Vitamina:** Bom ter. Melhora algo marginalmente. Usuários não se esforçam. Sinais: acenam com educação, dizem "legal", não mudam comportamento.

**Perguntas:**
- Você consegue nomear 3 pessoas específicas com este problema agora?
- O que fazem hoje no lugar? (O concorrente real é sempre o contorno atual.)
- Trocariam da abordagem atual? O que faria trocarem?
- Com que frequência encontram este problema? (Diário > mensal)
- É problema de "puxar" (usuários pedem) ou de "empurrar" (você acha que deveriam querer)?

**Sinais de alerta:**
- "Todo mundo poderia usar" — sem usuário específico, valor não está claro
- "É como X só melhor" — melhorias marginais raramente geram adoção
- Problema real mas raro — alta intensidade mas baixa frequência raramente justifica produto

### 2. Viabilidade

Dá para construir de fato? Não só tecnicamente, mas na prática.

**Viabilidade técnica:**
- A tecnologia central existe e funciona de forma confiável?
- Qual o problema técnico mais difícil? É problema conhecido-difícil ou novo?
- Há dependência de terceiros, APIs ou fontes de dados que você não controla?
- Qual a stack técnica mínima? (Se a resposta é "muita coisa", é um sinal.)

**Viabilidade de recursos:**
- Qual o esforço mínimo de time para um MVP?
- Exige expertise especializada que você não tem?
- Há requisitos regulatórios, legais ou de compliance?

**Tempo até valor:**
- Quão rápido algo pode chegar à frente de usuários?
- Existe versão que entrega valor em dias/semanas, não meses?
- Qual o caminho crítico? O que precisa acontecer primeiro?

**Sinais de alerta:**
- "Só precisamos resolver [problema de pesquisa muito difícil] primeiro"
- Múltiplas dependências que precisam funcionar ao mesmo tempo
- MVP ainda exige meses de trabalho — provavelmente não é mínimo o bastante

### 3. Diferenciação

O que torna isto genuinamente diferente? Não melhor — *diferente*.

**Perguntas:**
- Se um usuário descrevesse isto a um amigo, o que diria? Essa descrição é convincente?
- Qual a única coisa que isto faz que mais nada faz? (Se não nomear uma, há problema.)
- Essa diferenciação é durável? Um concorrente copia em uma semana?
- A diferença é algo que usuários de fato se importam, ou só interessa a quem constrói?

**Tipos de diferenciação (do mais forte ao mais fraco):**
1. **Nova capacidade:** Faz algo antes impossível
2. **Melhoria 10×:** Tanto melhor numa dimensão-chave que muda comportamento
3. **Novo público:** Traz capacidade existente para quem estava excluído
4. **Novo contexto:** Funciona onde soluções atuais falham
5. **Melhor UX:** Mesma capacidade, experiência dramaticamente mais simples
6. **Mais barato:** Mesma coisa, menor custo (mais fraco — facilmente contestado)

**Sinais de alerta:**
- Diferenciação só em tecnologia, não em experiência do usuário
- "Somos mais rápidos/baratos/mais bonitos" sem razão estrutural
- O recurso que diferencia não é o que mais importa aos usuários

## Auditoria de premissas

Para cada direção de ideia, liste premissas em três categorias:

### Precisa ser verdade (bloqueadores)

Premissas que, se falsas, matam a ideia. Precisam validação antes de construir.

Ex.: "Usuários compartilharão dados conosco" — se não compartilharem, o produto inteiro não funciona.

### Deveria ser verdade (importante)

Premissas que impactam muito o sucesso mas não matam a ideia. Você pode ajustar a abordagem se estiverem erradas.

Ex.: "Usuários preferem self-serve a falar com pessoa" — se errado, precisa de go-to-market diferente, mas o núcleo do produto ainda pode funcionar.

### Pode ser verdade (bom ter)

Premissas sobre recursos secundários ou otimizações. Não valide até o núcleo estar provado.

Ex.: "Usuários vão querer compartilhar resultados com colegas" — recurso de crescimento, não proposta de valor central.

## Framework de decisão

Ao escolher entre direções, ordene nesta matriz:

|                    | Alta viabilidade | Baixa viabilidade |
|--------------------|------------------|-------------------|
| **Alto valor**     | Fazer isto primeiro | Vale o risco |
| **Baixo valor**    | Só se trivial     | Não fazer |

Depois use diferenciação como critério de desempate entre opções no mesmo quadrante.

## Princípios de escopo de MVP

Ao definir escopo do MVP para a direção escolhida:

1. **Um job, bem feito.** O MVP deve acertar exatamente um job do usuário. Não três jobs meio feitos.
2. **A premissa mais arriscada primeiro.** O propósito principal do MVP é testar a premissa mais provável de estar errada.
3. **Time-box, não lista de features.** "O que podemos construir e testar em [prazo]?" é melhor que "de quais features precisamos?"
4. **Lista 'Não fazer' é obrigatória.** Nomeie explicitamente o que está cortando e por quê. Isso evita creep de escopo e força priorização honesta.
5. **Se não é embaraçoso, esperou demais.** A primeira versão deve parecer incompleta para quem constrói. Se não parece, construiu demais.
