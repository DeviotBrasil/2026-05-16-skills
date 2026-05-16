---
name: code-review-and-quality
description: Realiza revisão de código em múltiplos eixos. Use antes de integrar qualquer alteração. Use ao revisar código escrito por você, outro agente ou um humano. Use quando precisar avaliar a qualidade do código em várias dimensões antes de entrar na branch principal.
---

# Revisão de código e qualidade

## Visão Geral

Revisão de código multidimensional com portões de qualidade. Toda alteração é revisada antes do merge — sem exceções. A revisão cobre cinco eixos: correção, legibilidade, arquitetura, segurança e desempenho.

**Critério de aprovação:** Aprove uma alteração quando ela melhora de forma clara a saúde geral do código, mesmo que não seja perfeita. Código perfeito não existe — o objetivo é melhoria contínua. Não bloqueie uma mudança só porque não seria exatamente assim que você escreveria. Se melhora a base de código e segue as convenções do projeto, aprove.

## Quando Usar

- Antes de integrar qualquer PR ou alteração
- Depois de concluir a implementação de uma funcionalidade
- Quando outro agente ou modelo produziu código que você precisa avaliar
- Ao refatorar código existente
- Depois de qualquer correção de bug (revise tanto o fix quanto o teste de regressão)

## A revisão em cinco eixos

Toda revisão avalia o código nestas dimensões:

### 1. Correção

O código faz o que diz que faz?

- Está alinhado à especificação ou aos requisitos da tarefa?
- Casos extremos são tratados (nulo, vazio, valores de fronteira)?
- Caminhos de erro são tratados (não só o caminho feliz)?
- Passa em todos os testes? Os testes realmente verificam o que importa?
- Há erros off-by-one, condições de corrida ou inconsistências de estado?

### 2. Legibilidade e simplicidade

Outro engenheiro (ou agente) consegue entender este código sem o autor explicar?

- Os nomes são descritivos e consistentes com as convenções do projeto? (Sem `temp`, `data`, `result` sem contexto)
- O fluxo de controle é direto (evitar ternários aninhados, callbacks profundos)?
- O código está organizado de forma lógica (código relacionado agrupado, limites de módulo claros)?
- Há truques “espertos” que deveriam ser simplificados?
- **Isso poderia ser feito em menos linhas?** (1000 linhas onde 100 bastam é falha)
- **As abstrações compensam a complexidade?** (Não generalize antes do terceiro caso de uso)
- Comentários ajudariam a esclarecer intenção não óbvia? (Mas não comente o óbvio.)
- Há artefatos de código morto: variáveis no-op (`_unused`), shims de compatibilidade retroativa ou comentários `// removed`?

### 3. Arquitetura

A alteração se encaixa no desenho do sistema?

- Segue padrões existentes ou introduz um novo? Se novo, está justificado?
- Mantém limites de módulo limpos?
- Há duplicação que deveria ser compartilhada?
- Dependências fluem na direção certa (sem dependências circulares)?
- O nível de abstração é adequado (nem over-engineering, nem acoplamento excessivo)?

### 4. Desempenho

Para profiling e otimização detalhados, veja `performance-optimization`. A alteração introduz problemas de desempenho?

- Padrões N+1 em consultas?
- Loops sem limite ou buscas de dados sem restrição?
- Operações síncronas que deveriam ser assíncronas?
- Re-renderizações desnecessárias em componentes de UI?
- Falta de paginação em endpoints de listagem?
- Objetos grandes criados em caminhos quentes (hot paths)?

## Tamanho das alterações

Mudanças pequenas e focadas são mais fáceis de revisar, mais rápidas de integrar e mais seguras de implantar. Use estes tamanhos como alvo:

```
~100 linhas alteradas   → Bom. Revisável de uma vez.
~300 linhas alteradas   → Aceitável se for uma única mudança lógica.
~1000 linhas alteradas  → Grande demais. Divida.
```

**O que conta como “uma alteração”:** Uma modificação autocontida que trata de uma coisa só, inclui testes relacionados e mantém o sistema funcional após o envio. Uma parte de uma funcionalidade — não a funcionalidade inteira.

**Estratégias de divisão quando a alteração é grande demais:**

| Estratégia | Como | Quando |
|------------|------|--------|
| **Pilha (stack)** | Envie uma mudança pequena, inicie a próxima em cima dela | Dependências sequenciais |
| **Por grupo de arquivos** | Alterações separadas para grupos que precisam de revisores diferentes | Preocupações transversais |
| **Horizontal** | Crie código compartilhado/stubs primeiro, depois consumidores | Arquitetura em camadas |
| **Vertical** | Quebre em fatias full-stack menores da funcionalidade | Trabalho de feature |

**Quando alterações grandes são aceitáveis:** Remoções completas de arquivo e refatoração automatizada em que o revisor só precisa verificar a intenção, não linha a linha.

**Separe refatoração de trabalho de feature.** Uma mudança que refatora código existente e adiciona comportamento novo são duas alterações — envie separadamente. Pequenos ajustes (renomear variáveis) podem ser incluídos a critério do revisor.

## Descrições das alterações

Toda alteração precisa de uma descrição que funcione sozinha no histórico de versão.

**Primeira linha:** Curta, imperativa, autossuficiente. “Remover o RPC FizzBuzz”, não “Removendo o RPC FizzBuzz.” Deve ser informativa o bastante para quem busca no histórico entender a mudança sem ler o diff.

**Corpo:** O que está mudando e por quê. Inclua contexto, decisões e raciocínio que não aparecem no código. Linke bugs, benchmarks ou docs de design quando fizer sentido. Reconheça limitações da abordagem quando existirem.

**Anti-padrões:** “Corrigir bug,” “Corrigir build,” “Adicionar patch,” “Mover código de A para B,” “Fase 1,” “Adicionar funções de conveniência.”

## Processo de revisão

### Etapa 1: Entender o contexto

Antes de olhar o código, entenda a intenção:

```
- O que esta alteração tenta alcançar?
- Qual especificação ou tarefa ela implementa?
- Qual é a mudança de comportamento esperada?
```

### Etapa 2: Revisar os testes primeiro

Testes revelam intenção e cobertura:

```
- Existem testes para a alteração?
- Eles testam comportamento (não detalhes de implementação)?
- Casos extremos estão cobertos?
- Os testes têm nomes descritivos?
- Os testes pegariam uma regressão se o código mudasse?
```

### Etapa 3: Revisar a implementação

Percorra o código com os cinco eixos em mente:

```
Para cada arquivo alterado:
1. Correção: Este código faz o que o teste diz que deve?
2. Legibilidade: Consigo entender sem ajuda?
3. Arquitetura: Isso se encaixa no sistema?
4. Segurança: Alguma vulnerabilidade?
5. Desempenho: Algum gargalo?
```

### Etapa 4: Classificar achados

Rotule cada comentário com severidade para o autor saber o que é obrigatório vs opcional:

| Prefixo | Significado | Ação do autor |
|---------|-------------|---------------|
| *(sem prefixo)* | Alteração obrigatória | Deve corrigir antes do merge |
| **Crítico:** | Bloqueia merge | Vulnerabilidade de segurança, perda de dados, funcionalidade quebrada |
| **Nit:** | Pequeno, opcional | Autor pode ignorar — formatação, preferências de estilo |
| **Opcional:** / **Considere:** | Sugestão | Vale considerar, mas não é obrigatório |
| **FYI** | Apenas informativo | Nenhuma ação — contexto para referência futura |

Isso evita que o autor trate todo feedback como obrigatório e perca tempo com sugestões opcionais.

### Etapa 5: Verificar a verificação

Confira a narrativa de verificação do autor:

```
- Quais testes foram executados?
- O build passou?
- A alteração foi testada manualmente?
- Há capturas de tela para mudanças de UI?
- Há comparação antes/depois?
```

## Padrão de revisão multi-modelo

Use modelos diferentes para perspectivas diferentes de revisão:

```
Modelo A escreve o código
    │
    ▼
Modelo B revisa correção e arquitetura
    │
    ▼
Modelo A trata o feedback
    │
    ▼
Humano decide no final
```

Isso pega problemas que um único modelo pode deixar passar — modelos diferentes têm pontos cegos diferentes.

**Exemplo de prompt para um agente revisor:**
```
Revise esta alteração de código quanto à correção, segurança e aderência às
convenções do projeto. A especificação diz [X]. A alteração deve [Y].
Sinalize problemas como Crítico, Importante ou Sugestão.
```

## Higiene de código morto

Depois de qualquer refatoração ou implementação, verifique código órfão:

1. Identifique código que ficou inalcançável ou não usado
2. Liste explicitamente
3. **Pergunte antes de apagar:** “Devo remover estes elementos agora não usados: [lista]?”

Não deixe código morto espalhado — confunde leitores e agentes futuros. Mas não apague em silêncio o que não tiver certeza. Em dúvida, pergunte.

```
CÓDIGO MORTO IDENTIFICADO:
- formatLegacyDate() em src/utils/date.ts — substituída por formatDate()
- componente OldTaskCard em src/components/ — substituído por TaskCard
- constante LEGACY_API_URL em src/config.ts — sem referências restantes
→ Seguro remover estes?
```

## Velocidade da revisão

Revisões lentas travam times inteiros. O custo de trocar de contexto para revisar é menor que o custo de espera imposto aos outros.

- **Responder em até um dia útil** — isso é o máximo, não a meta
- **Cadência ideal:** Responder logo após o pedido de revisão, a menos que esteja em foco profundo. Uma alteração típica deve completar várias rodadas de revisão no mesmo dia
- **Priorize respostas rápidas individuais** em vez de aprovação final imediata. Feedback rápido reduz frustração mesmo que precisem várias rodadas
- **Alterações grandes:** Peça ao autor para dividir em vez de revisar um changeset enorme

## Lidando com divergências

Ao resolver disputas de revisão, use esta hierarquia:

1. **Fatos técnicos e dados** prevalecem sobre opiniões e preferências
2. **Guias de estilo** são a autoridade absoluta em questões de estilo
3. **Design de software** deve ser avaliado por princípios de engenharia, não preferência pessoal
4. **Consistência da base de código** é aceitável se não degradar a saúde geral

**Não aceite “eu limpo depois.”** A experiência mostra que limpeza adiada raramente acontece. Exija limpeza antes do envio, salvo emergência real. Se problemas ao redor não puderem ser tratados nesta mudança, exija abertura de bug com auto-atribuição.

## Honestidade na revisão

Ao revisar código — seu, de outro agente ou humano:

- **Não carimbe de graça.** “LGTM” sem evidência de revisão não ajuda ninguém.
- **Não suavize problemas reais.** “Pode ser uma preocupação menor” quando é um bug que vai para produção é desonesto.
- **Quantifique problemas quando possível.** “Esta consulta N+1 adiciona ~50ms por item na lista” é melhor que “isso pode ficar lento.”
- **Resista a abordagens com problemas claros.** Bajulação é modo de falha em revisões. Se a implementação tem problemas, diga direto e proponha alternativas.
- **Aceite override com elegância.** Se o autor tem contexto completo e discorda, ceda ao julgamento dele. Comente o código, não as pessoas — reformule críticas pessoais para focar no código.

## Disciplina de dependências

Parte da revisão de código é revisão de dependências:

**Antes de adicionar qualquer dependência:**
1. A stack existente já resolve isso? (Muitas vezes resolve.)
2. Qual o tamanho da dependência? (Impacto no bundle.)
3. Está ativamente mantida? (Último commit, issues abertas.)
4. Tem vulnerabilidades conhecidas? (`npm audit`)
5. Qual a licença? (Deve ser compatível com o projeto.)

**Regra:** Prefira biblioteca padrão e utilitários existentes a novas dependências. Toda dependência é um passivo.

## Checklist de revisão

```markdown
## Revisão: [título do PR/alteração]

### Contexto
- [ ] Entendo o que esta alteração faz e por quê

### Correção
- [ ] A alteração corresponde à spec/tarefa
- [ ] Casos extremos tratados
- [ ] Caminhos de erro tratados
- [ ] Testes cobrem a alteração adequadamente

### Legibilidade
- [ ] Nomes claros e consistentes
- [ ] Lógica direta
- [ ] Sem complexidade desnecessária

### Arquitetura
- [ ] Segue padrões existentes
- [ ] Sem acoplamento ou dependências desnecessárias
- [ ] Nível de abstração adequado

### Segurança
- [ ] Sem segredos no código
- [ ] Entrada validada nos limites
- [ ] Sem vulnerabilidades de injeção
- [ ] Verificações de auth no lugar
- [ ] Fontes externas de dados tratadas como não confiáveis

### Desempenho
- [ ] Sem padrões N+1
- [ ] Sem operações sem limite
- [ ] Paginação em endpoints de listagem

### Verificação
- [ ] Testes passam
- [ ] Build com sucesso
- [ ] Verificação manual feita (se aplicável)

### Veredito
- [ ] **Aprovar** — Pronto para merge
- [ ] **Solicitar alterações** — Problemas devem ser corrigidos
```
## Ver também

- Para checagens de revisão de desempenho, veja `references/performance-checklist.md`

## Racionalizações Comuns

| Racionalização | Realidade |
|---|---|
| “Funciona, já basta” | Código que funciona mas é ilegível, inseguro ou arquiteturalmente errado gera dívida que se acumula. |
| “Eu escrevi, então está certo” | Autores são cegos às próprias suposições. Toda mudança se beneficia de outro par de olhos. |
| “Depois a gente limpa” | Depois nunca chega. A revisão é o portão de qualidade — use-o. Exija limpeza antes do merge, não depois. |
| “Código gerado por IA deve estar ok” | Código de IA precisa de mais escrutínio, não menos. É confiante e plausível, mesmo quando está errado. |
| “Os testes passam, então está bom” | Testes são necessários mas não suficientes. Não pegam problemas de arquitetura, segurança ou legibilidade. |

## Sinais de Alerta

- PRs integrados sem revisão
- Revisão que só verifica se os testes passam (ignorando outros eixos)
- “LGTM” sem evidência de revisão real
- Mudanças sensíveis a segurança sem revisão focada em segurança
- PRs grandes “grandes demais para revisar direito” (divida-os)
- Correções de bug sem testes de regressão
- Comentários de revisão sem rótulos de severidade — deixa obscuro o que é obrigatório vs opcional
- Aceitar “eu corrijo depois” — nunca acontece

## Verificação

Após concluir a revisão:

- [ ] Todos os problemas críticos foram resolvidos
- [ ] Todos os problemas importantes foram resolvidos ou explicitamente adiados com justificativa
- [ ] Testes passam
- [ ] Build com sucesso
- [ ] A narrativa de verificação está documentada (o que mudou, como foi verificado)
