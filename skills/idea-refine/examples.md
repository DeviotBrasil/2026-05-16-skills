# Exemplos de sessão de ideação

Estes exemplos mostram como boas sessões de ideação se parecem em tipos diferentes de ideia. Estude o ritmo, o tom e a estrutura — não só o conteúdo. A skill deve funcionar igualmente bem com conceito vago de startup, recurso para produto existente ou melhoria de processo.

---

## Exemplo 1: Conceito inicial vago (sessão completa em 3 fases)

**Usuário invoca:** `/ideate I want to help small local restaurants compete with the big delivery platforms`

### Fase 1: Entender e expandir

**Resposta da skill:**

> **Como poderíamos** dar a restaurantes independentes o alcance e a conveniência que clientes esperam das plataformas de entrega, sem forçá-los a um modelo que corroe margens e marca?

É um espaço grande. Deixa eu afiar:

1. **Qual parte de "competir"?** Aquisição de clientes? Logística de entrega? UX de pedido online? Fidelidade/retenção? Pressão de margem por taxas de plataforma?
2. **Para quem você está construindo?** Dono de restaurante? Cliente final? Os dois?
3. **Qual a restrição?** Pensando em software? Modelo cooperativo? Algo físico?

**Usuário responde:** "Donos de restaurante. A dor central é pagarem 25–30% de comissão para apps de entrega mas sentirem que não podem sair porque é onde estão os clientes. Estou pensando em software mas estou aberto."

**A skill continua:**

Então o problema não é logística de entrega — é **dependência do cliente**. As plataformas donas do relacionamento com o cliente, e restaurantes alugam acesso aos próprios clientes a 30% da receita. Esse é o ponto de alavanca para quebrar.

Aqui vão 6 variações:

1. **Kit de canal direto:** Dar aos restaurantes pedido com marca própria — web, SMS, talvez app leve — para mover clientes existentes para fora da plataforma. Aposta central: clientes que *já conhecem* um restaurante pedem direto se for fácil o bastante. Você não precisa competir com DoorDash em descoberta, só em recompra.

2. **Inversão — Cobrar o cliente, não o restaurante:** E se o modelo de taxa de entrega invertesse? Clientes pagam um pequeno prêmio no pedido direto, restaurantes pagam zero comissão. Posicionar como "apoie o local". Aposta: clientes o bastante se importam em apoiar negócios locais para pagar US$ 1–2 a mais por pedido.

3. **Remoção de restrição — E se entrega não fosse obrigatória?** As plataformas empacotam descoberta + pedido + entrega, mas grande parte do custo (e da comissão do restaurante) é entrega. E se você só resolvesse pedido e retirada? Modelo pickup primeiro. Restaurantes ficam com 100% da receita, clientes economizam taxa de entrega. Funciona melhor em bairros densos.

4. **Combinação — Cooperativa de restaurantes:** Modelo co-op em que 20–50 restaurantes locais numa área compartilham plataforma, dividem custos e se promovem cruzado. Restaurantes individuais não pagam marketing — mas um coletivo de bairro pode. Pense "praça de alimentação local", só que digital.

5. **Mudança de público — Para clientes frequentadores:** Não tente adquirir novos clientes. Construa só para frequentadores que o restaurante já tem — quem entra toda semana. Ferramenta de fidelidade/recompra extremamente simples: "O de sempre?" recompra com um toque. Aposta 80/20: 20% dos clientes geram 80% da receita, e essas pessoas não precisam do DoorDash para descobrir o restaurante.

6. **Lente de especialista — O que donos de restaurante realmente fazem:** A maioria dos donos de restaurante pequeno não fica em dashboard. Está na cozinha. Qualquer ferramenta que exija "gerir" algo vai falhar. A abordagem vencedora pode ser algo que roda sozinho — SMS automático para frequentadores que não pedem há 2 semanas, post automático do prato do dia, recompras automáticas. Zero esforço do lado do restaurante.

As variações 5 e 6 juntas são interessantes. Em vez de tentar superar as plataformas em plataforma, você construiria algo hiper estreito: recompra e retenção só para os melhores clientes que o restaurante já tem. Sem descoberta, sem entrega, sem marketplace. Só "fazer frequentadores pedirem direto".

Quais direções te interessam?

---

### Fase 2: Avaliar e convergir

**Usuário responde:** "Adorei o ângulo dos frequentadores (5 e 6). O kit de canal direto (1) parece necessário mas chato. A ideia de co-op (4) é interessante mas complexa. Quero focar em 1 + 5 + 6 juntos."

**Resposta da skill:**

Bom instinto. Essa combinação tem uma tese clara: **ser dono do relacionamento com seus melhores clientes, tornar recompra sem fricção e exigir zero esforço do dono do restaurante.** Deixa eu stress-testar.

**Direção A: O "motor de frequentadores" (5 + 6 fundidos)**
Ferramenta focada só em clientes repetidos que o restaurante já tem. Recompra automática, engajamento automático, zero gestão.

- **Aposta central:** Os melhores 20% dos clientes de um restaurante migrarão para pedido direto se a experiência for sem fricção e pessoal. O restaurante não precisa de clientes *novos* — precisa parar de pagar 30% em clientes que já tem.
- **Valor ao usuário:** Alto e imediato. Cada recompra direta economiza 25–30% de comissão. Se um frequentador pede US$ 30/semana, são ~US$ 400/ano em taxas economizadas por cliente. 50 frequentadores = US$ 20 mil/ano. Dinheiro real para restaurante pequeno.
- **Viabilidade:** Média. Tech de pedido/pagamento é commodity. O difícil: (a) como identificar e integrar "frequentadores" sem trabalho manual do restaurante? (b) Como lidar com cold start — a primeira recompra precisa de histórico de pedidos que vive na plataforma de entrega, não com você.
- **Diferenciação:** Alta para o nicho. Plataformas otimizam dinâmica de marketplace (descoberta de cliente novo, logística de motoristas). Ninguém otimiza especificamente "fazer frequentadores pedirem direto". É pequeno demais para DoorDash ligar — por isso é uma boa cunha.
- **Premissas ocultas:**
  - Frequentadores vão instalar/usar mais um canal de pedido (premissa mais provável de estar errada)
  - Donos compartilharão contato de clientes ou deixarão você acessar
  - Pedido direto não vai canibalizar receita do salão
- **O que poderia matar:** Clientes simplesmente não trocarem de canal. Hábito é forte — mesmo que DoorDash custe mais, já está no telefone deles.

**Direção B: Híbrido canal direto + retenção (1 + 5)**
Pedido com marca do restaurante *mais* automação de retenção. Mais completo, mais complexo.

- **Aposta central:** Restaurantes precisam do canal (forma de aceitar pedidos) e do motor (forma de trazer clientes de volta por esse canal).
- **Valor ao usuário:** Teto maior, mas só se as duas partes funcionarem juntas. Só o canal é commodity (Square, Toast já fazem). Só a camada de retenção não tem canal onde reter *em cima*.
- **Viabilidade:** Menor. Você constrói dois produtos e aposta que juntos são melhores.
- **Diferenciação:** Média. A combinação é interessante, mas cada pedaço tem concorrentes.
- **Premissa oculta:** Que empacotar os dois é melhor que parecer (ex.: camada de retenção em cima do Square Online).
- **O que poderia matar:** Escopo. Fazer duas coisas bem é exponencialmente mais difícil que uma.

**Leitura honesta:** A Direção A é a aposta mais nítida. A B é mais segura porém menos diferenciada. O maior risco de A é troca de canal — levar clientes a pedir por método novo. Se você resolver isso (e a abordagem "zero esforço" da 6 pode ajudar — recompra por SMS não exige app novo), o resto segue.

Quero te contrariar em algo: você disse que a variação 1 parece "necessária mas chata." Esse instinto de incluir o que é "necessário" é como produtos perdem foco. Se o motor de frequentadores funcionar, você adiciona canal com marca depois. Mas se construir o canal primeiro, vira só mais um concorrente do Square Online.

---

### Fase 3: Afiar e entregar

**A skill produz:**

# ReOrder: mantenha seus frequentadores pedindo direto

## Declaração do problema
How might we ajudar restaurantes independentes a reter seus melhores clientes existentes via pedido direto, eliminando a comissão de 25–30% da plataforma na receita que mais importa?

## Direção recomendada
Construir um **motor de retenção só para frequentadores** — não marketplace, não plataforma completa de pedidos. Hipert focado num job: tornar sem esforço a recompra direta pelos clientes habituais.

O insight é que restaurantes não precisam de ajuda para *achar* os melhores clientes — sabem quem entra toda terça. Precisam de ajuda para mover esses relacionamentos para fora da plataforma. E a ferramenta precisa rodar sozinha, porque o dono está na cozinha, não no dashboard.

SMS primeiro (não app primeiro) provavelmente é o canal certo. Um texto "Oi, quer seu pedido de quinta de sempre do Marco's?" com confirmação num toque tem menos fricção que instalar app.

## Premissas-chave a validar
- [ ] Clientes habituais recomprarão via SMS/link direto em vez do app de entrega de sempre — testar com 5 restaurantes, 20 frequentadores cada, medir conversão em 4 semanas
- [ ] Donos conseguem identificar os melhores 20–30 frequentadores e compartilhar contato — testar perguntando a 10 donos se fariam isso
- [ ] A economia de comissão (US$ 8–10 por pedido) motiva o suficiente para donos investirem setup inicial — entrevistar 10 donos sobre dor de taxa de plataforma

## Escopo do MVP
- Recompra por SMS para frequentadores que o restaurante mesmo identifica
- Dono adiciona frequentadores manualmente (nome + telefone + pedido de costume) — setup de 15 minutos
- Cliente recebe texto com o pedido de costume, confirma com resposta, paga por link
- Restaurante recebe o pedido por texto/dashboard simples
- Sem entrega — só retirada na v1
- Sem descoberta, sem marketplace, sem app

## Não fazer (e por quê)
- **Logística de entrega** — entrega é cara, complexa e não é o problema central. Retirada primeiro valida demanda sem carga operacional.
- **Aquisição/descoberta de clientes** — jogo da plataforma. Competir em descoberta é competir com orçamento do DoorDash. Competimos em retenção.
- **Apps/sites com marca do restaurante** — commodity. Square e Toast já fazem. Outro canal com marca não resolve o problema comportamental.
- **Gestão de cardápio, integração POS** — creep de escopo. "O de usual" não precisa de cardápio dinâmico. Comece com pedidos estáticos.
- **Dashboards analíticos** — o dono está na cozinha. Construa relatório passivo (resumo semanal por SMS), não ativo (entrar e ver gráficos).

## Questões em aberto
- Qual o cenário legal/compliance de SMS marketing para clientes de restaurantes?
- Como lidar com mudanças de cardápio/preço para pedidos "do usual"?
- Há como bootstrapar a lista de frequentadores a partir de dados de POS em vez de entrada manual?
- Qual o modelo de preço? Taxa por pedido? Assinatura mensal?

---

## Exemplo 2: Ideia de recurso em produto existente (consciente da base)

**Usuário invoca:** `/ideate adding real-time collaboration to our document editor`

### Fase 1: Entender e expandir

**Resposta da skill:**

> **Como poderíamos** deixar várias pessoas trabalhando no mesmo documento ao mesmo tempo de forma que pareça natural, não caótica?

Varri sua base e vejo arquitetura de editor em blocos com API REST para persistência. Sem infraestrutura WebSocket no momento. Isso é contexto importante. Algumas perguntas:

1. **Qual o padrão de colaboração?** Editando o mesmo parágrafo ao mesmo tempo (estilo Google Docs)? Ou em seções diferentes (estilo Notion)? Ou revisando/comentando enquanto uma pessoa edita?
2. **Quantos usuários simultâneos?** 2–3 (edição em par)? 10+ (espaço de equipe)?
3. **O que está empurrando isso agora?** Pedidos de clientes? Pressão competitiva? Necessidade interna?

**Usuário responde:** "2–5 pessoas, em geral em seções diferentes. Clientes não param de pedir. Estamos perdendo negócio para o Notion porque assumem que qualquer editor moderno tem isso."

**A skill continua:**

O enquadramento de pressão competitiva importa — pode ser recurso checklist (must-have para continuar na consideração) em vez de diferenciador. Isso muda quanto investir.

Vejo que o modelo de documento usa blocos independentes com ordenação plana (`src/models/document.ts:45`). Isso é favorável — granularidade em bloco significa conflitos mais raros que edição caractere a caractere.

Aqui vão 5 variações:

1. **Travamento em nível de bloco (caminho mais simples):** Quando alguém começa a editar um bloco, ele trava para outros. Veem indicador de presença ("Alex está editando...") mas podem editar qualquer outro bloco livremente. Sem resolução de conflito necessária. Seu modelo de blocos atual suporta com mudanças mínimas — campo `locked_by` e camada WebSocket para presença.

2. **Inversão — Colaboração async primeiro:** Em vez de coedição em tempo real, aposte no async. Sugestões inline, comentários e edições propostas que o dono do documento incorpora. Como modo sugestão, mas como modelo *principal* de colaboração. Aposta: para 2–5 pessoas em seções diferentes, async pode ser *melhor* que tempo real.

3. **Simplificação — Presença sem coedição:** Mostrar quem está vendo o documento e em que seção (cursores, avatares nas margens), mas sem edição simultânea. Pessoas coordenam por voz. Soa primitivo, mas pode ser 80% do valor por 10% do custo de engenharia.

4. **Combinação — Colaboração + branches de versão:** Deixar pessoas criarem "branches" do documento, editarem independentemente e depois fazer merge. Cada uma com seu espaço, sem conflitos durante edição, e você constrói UI de merge. Aproveita seu sistema de versionamento existente.

5. **Versão 10× — Colaboração mediada por IA:** Várias pessoas descrevem o que querem num trecho, e a IA sintetiza num rascunho em que todas iteram. Ninguém edita o mesmo texto diretamente — todos influenciam. Radical, talvez cedo demais, mas vale nomear.

Dada sua arquitetura e o contexto competitivo, eu empurraria você para a variação 1 ou 3. Vocês precisam fechar negócios, o que significa entregar isso, o que significa a versão mais simples que marca o checkbox. A 1 dá coedição real. A 3 é ainda mais barata mas pode não satisfazer o checkbox "precisamos de tempo real".

---

*A Fase 2 agruparia em "coedição mínima viável (1 ou 3)" vs. "modelo de colaboração diferenciado (2 ou 4)" — avaliando marcar o checkbox competitivo rápido ou investir em algo que vire argumento de venda.*

*A Fase 3 geraria um one-pager recomendando travamento em nível de bloco como MVP, com lista "Não fazer" incluindo CRDT caractere a caractere (complexo demais), sync offline (não necessário para 2–5 usuários) e recursos de IA (prematuros).*

---

## Exemplo 3: Ideia de processo/workflow (não produto)

**Usuário invoca:** `/ideate a better way to run our weekly team retrospectives — they've gotten stale and people dread them`

### Fase 1: Entender e expandir

**Resposta da skill:**

> **Como poderíamos** fazer retrospectivas genuinamente úteis — algo que a equipe antecipa com interesse — em vez de reunião recorrente que as pessoas suportam?

Antes de expandir:

1. **O que está envelhecido nelas?** Mesmo formato sempre? Mesmas pessoas falando? Action items que nunca fazem? Temas repetitivos?
2. **Tamanho da equipe e dinâmica?** 5 pessoas que falam todas, ou 15 onde 3 dominam?
3. **Como é uma retro *boa* para você?** Já teve uma que funcionou? O que foi diferente?

**Usuário responde:** "8 pessoas, talvez 3–4 realmente falam. O formato 'o que foi bem / o que não foi / action items' há um ano. Action items se acumulam e nada muda. Acham que é teatro."

**A skill continua:**

O problema dos action items é o sinal real. Se nada muda depois da retro, as pessoas racionalmente desengajam. A reunião não está envelhecida — está **quebrada na camada de saída**. O formato pode estar ok se o acompanhamento funcionasse.

Aqui vão 6 variações:

1. **Consertar a saída, não a reunião:** Manter o formato da retro mas mudar totalmente o que acontece depois. No máximo um action item por retro. Dono e prazo definidos na reunião. A próxima retro começa com demonstração de 5 minutos da ação concluída. Se não estiver pronta, isso *vira* o tema da retro. A restrição de um item força priorização.

2. **Inversão — Matar a reunião:** Trocar a retro síncrona por async. Todos enviam reflexões por escrito na semana. Facilitador rotativo sintetiza temas e propõe uma mudança. A "reunião" é um standup de 15 minutos para concordar ou discordar. Aposta: escrita produz feedback mais honesto que falar em grupo.

3. **Mudança de público — Retro para os quietos:** Desenhar o formato para as 4–5 pessoas que não falam. Envio anônimo de tópicos. Dot-voting para priorizar. Breakouts em duplas antes da discussão em grupo. Vozes altas ainda participam, mas a estrutura impede dominação.

4. **Simplificação — A retro de uma pergunta:** Cada retro tem exatamente uma pergunta, que muda toda semana. "Qual uma coisa que te deixou mais lento?" "O que você aprendeu que o time deveria saber?" "Se pudesse mudar uma coisa em como trabalhamos, qual?" A restrição força profundidade em vez de amplitude.

5. **Combinação — Retro + experimentação:** Tratar cada saída de retro como hipótese. "Acreditamos que [mudança] vai melhorar [resultado]." Rodar como experimento de 2 semanas. Próxima retro: funcionou? Manter, ajustar ou matar. Transforma a retro em motor de melhoria contínua com accountability embutida.

6. **Lente de especialista — O que facilitadores sabem:** Facilitadores experientes dizem que o #1 assassino de retro é falta de segurança, não formato. As pessoas não dizem o que realmente está errado se temem consequências. O conserto pode não ser estrutural — pode ser começar com nota anônima de "saúde do time" (1–5) toda semana. Com segurança alta, retros melhoram naturalmente.

A tensão interessante: variações 1 e 5 consertam o problema de *saída* (nada muda). 2, 3 e 4 consertam o problema de *entrada* (mesmas vozes, mesmos temas). A 6 diz que ambos são sintoma de algo mais profundo. Onde você acha que está o gargalo real?

---

*A Fase 2 avaliaria esforço para tentar (a maioria é grátis — só mudar como roda a próxima reunião), risco (2 é a maior ruptura) e se o problema real do time é saída (action items morrem) ou entrada (falta honestidade).*

*A Fase 3 produziria um one-pager recomendando começar pela variação 1 (um action item, demo na semana seguinte) como experimento de custo zero, combinada com envio anônimo da 3. Lista "Não fazer": ferramentas novas, técnicas elaboradas de facilitação ou qualquer coisa que exija orçamento. O primeiro conserto deve levar 0 minutos de preparo e US$ 0.*

---

## O que notar nestes exemplos

1. **A reformulação muda o enquadramento.** "Ajudar restaurantes a competir" vira "reter clientes existentes." "Adicionar colaboração em tempo real" vira "trabalhar ao mesmo tempo sem caos." "Consertar retros velhas" vira "consertar a camada de saída."

2. **Perguntas diagnosticam antes de receitar.** Cada pergunta determina que *tipo* de problema é de fato. O exemplo da retro revela que o problema é follow-through de action items, não formato de reunião — e isso muda cada variação.

3. **Variações têm razões.** Cada uma explica *por que* existe (qual lente gerou), não só *o que* é. O rótulo (Inversão, Simplificação etc.) ensina o próprio usuário a pensar assim.

4. **A skill tem opinião.** "Eu empurraria você para 1 ou 3." "A 6 vale ficar com ela um tempo." Diz o que acha importante e por quê — não só opções neutras.

5. **A Fase 2 é honesta.** Ideias são chamadas por baixa diferenciação ou alta complexidade. A skill contraria: "Esse instinto de incluir o que é 'necessário' é como produtos perdem foco."

6. **A saída é acionável.** O one-pager termina com coisas que dá para *fazer* (validar premissas, construir MVP, tentar experimento), não só para *pensar*.

7. **A lista "Não fazer" faz trabalho real.** É específica e fundamentada. Cada item é algo que você *quereria* fazer mas não deve ainda.

8. **A skill se adapta ao contexto.** O exemplo consciente da base referencia arquitetura real. Ideia de processo gera experimentos de custo zero em vez de produtos. O framework é o mesmo mas a saída casa com o domínio.
