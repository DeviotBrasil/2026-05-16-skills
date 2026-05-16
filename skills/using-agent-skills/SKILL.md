---
name: using-agent-skills
description: Descobre e invoca skills de agente. Use ao iniciar uma sessão ou quando precisar descobrir qual skill se aplica à tarefa atual. É a meta-skill que rege como todas as outras skills são descobertas e invocadas.
---

# Uso de agent skills

## Visão geral

Agent Skills é um conjunto de skills de fluxo de trabalho de engenharia organizadas por fase de desenvolvimento. Cada skill codifica um processo específico que engenheiros seniores seguem. Esta meta-skill ajuda a descobrir e aplicar a skill certa para a tarefa atual.

## Descoberta de skills

Quando uma tarefa chega, identifique a fase de desenvolvimento e aplique a skill correspondente:

```
Tarefa chega
    │
    ├── Ideia vaga / precisa refinar? ──→ idea-refine
    ├── Projeto novo / funcionalidade / mudança? ──→ spec-driven-development
    ├── Já tem spec, precisa de tarefas? ──────→ planning-and-task-breakdown
    ├── Implementando código? ────────────→ incremental-implementation
    │   ├── Trabalho de UI? ─────────────────→ frontend-ui-engineering
    │   ├── Trabalho de API? ────────────────→ api-and-interface-design
    │   ├── Precisa de melhor contexto? ─────→ context-engineering
    │   └── Precisa de código validado em docs? ───→ source-driven-development
    ├── Escrevendo / rodando testes? ────────→ test-driven-development
    │   └── Baseado em navegador? ───────────→ browser-testing-with-devtools
    ├── Algo quebrou? ──────────────────────→ debugging-and-error-recovery
    ├── Revisando código? ───────────────────→ code-review-and-quality
    │   ├── Preocupação com segurança? ───────→ security-and-hardening
    │   └── Preocupação com desempenho? ────→ performance-optimization
    ├── Commit / branch? ────────────────────→ git-workflow-and-versioning
    ├── Trabalho em pipeline CI/CD? ──────────→ ci-cd-and-automation
    ├── Escrevendo docs / ADRs? ───────────→ documentation-and-adrs
    └── Deploy / lançamento? ───────────────→ shipping-and-launch
```

## Comportamentos operacionais centrais

Esses comportamentos valem sempre, em todas as skills. São inegociáveis.

### 1. Expor suposições

Antes de implementar algo não trivial, declare explicitamente suas suposições:

```
SUPOSIÇÕES QUE ESTOU FAZENDO:
1. [suposição sobre requisitos]
2. [suposição sobre arquitetura]
3. [suposição sobre escopo]
→ Corrija-me agora ou sigo com estas.
```

Não preencha silenciosamente requisitos ambíguos. O modo de falha mais comum é suposições erradas sem checagem. Expor incerteza cedo é mais barato que retrabalho.

### 2. Gerenciar confusão ativamente

Ao encontrar inconsistências, requisitos conflitantes ou especificações pouco claras:

1. **PARE.** Não avance no chute.
2. Dê nome à confusão específica.
3. Apresente o tradeoff ou faça a pergunta de esclarecimento.
4. Espere a resolução antes de continuar.

**Ruim:** Escolher silenciosamente uma interpretação e torcer para estar certo.
**Bom:** "Vejo X na spec mas Y no código existente. O que prevalece?"

### 3. Questionar quando fizer sentido

Você não é uma máquina de "sim". Quando uma abordagem tem problemas claros:

- Aponte o problema diretamente
- Explique o prejuízo concreto (quantifique quando possível — "isso adiciona ~200ms de latência" e não "pode ser mais lento")
- Proponha alternativa
- Aceite a decisão do humano se ele decidir com informação completa

Bajulação é modo de falha. "Com certeza!" seguido de implementar uma ideia ruim não ajuda ninguém. Discordância técnica honesta vale mais que acordo falso.

### 4. Impor simplicidade

A tendência natural é complicar demais. Resista ativamente.

Antes de concluir qualquer implementação, pergunte:
- Dá para fazer em menos linhas?
- Essas abstrações valem a complexidade?
- Um staff engineer olharia e diria "por que você não só..."?

Se você gera 1000 linhas e 100 bastariam, falhou. Prefira a solução óbvia e entediante. Esperteza é cara.

### 5. Manter disciplina de escopo

Toque só no que pediram.

NÃO:
- Remova comentários que não entendeu
- "Limpe" código ortogonal à tarefa
- Refatore sistemas adjacentes como efeito colateral
- Apague código que parece sem uso sem aprovação explícita
- Adicione features fora da spec porque "parecem úteis"

Seu trabalho é precisão cirúrgica, não reforma não solicitada.

### 6. Verificar, não supor

Toda skill inclui um passo de verificação. A tarefa não termina até a verificação passar. "Parece certo" nunca basta — precisa de evidência (testes passando, saída de build, dados de runtime).

## Modos de falha a evitar

São erros sutis que parecem produtividade mas geram problemas:

1. Suposições erradas sem checagem
2. Não gerenciar a própria confusão — avançar às cegas
3. Não expor inconsistências que você notou
4. Não apresentar tradeoffs em decisões não óbvias
5. Ser bajulador ("Com certeza!") com abordagens problemáticas
6. Complicar demais código e APIs
7. Modificar código ou comentários ortogonais à tarefa
8. Remover o que não entende completamente
9. Construir sem spec porque "é óbvio"
10. Pular verificação porque "parece certo"

## Regras das skills

1. **Verifique se existe skill aplicável antes de começar.** Skills codificam processos que evitam erros comuns.

2. **Skills são fluxos de trabalho, não sugestões.** Siga os passos em ordem. Não pule verificação.

3. **Várias skills podem se aplicar.** Uma feature pode envolver `idea-refine` → `spec-driven-development` → `planning-and-task-breakdown` → `incremental-implementation` → `test-driven-development` → `code-review-and-quality` → `shipping-and-launch` em sequência.

4. **Na dúvida, comece com uma spec.** Se a tarefa não for trivial e não houver spec, comece com `spec-driven-development`.

## Sequência de ciclo de vida

Para uma feature completa, a sequência típica de skills é:

```
1. idea-refine                 → Refinar ideias vagas
2. spec-driven-development     → Definir o que vamos construir
3. planning-and-task-breakdown → Quebrar em pedaços verificáveis
4. context-engineering         → Carregar o contexto certo
5. source-driven-development   → Verificar contra documentação oficial
6. incremental-implementation  → Construir fatia a fatia
7. test-driven-development     → Provar que cada fatia funciona
8. code-review-and-quality     → Revisar antes do merge
9. git-workflow-and-versioning → Histórico de commits limpo
10. documentation-and-adrs     → Documentar decisões
11. shipping-and-launch        → Deploy com segurança
```

Nem toda tarefa precisa de todas as skills. Um bugfix pode precisar só: `debugging-and-error-recovery` → `test-driven-development` → `code-review-and-quality`.

## Referência rápida

| Fase | Skill | Resumo em uma linha |
|-------|-------|---------------------|
| Definir | idea-refine | Refinar ideias com pensamento divergente e convergente estruturado |
| Definir | spec-driven-development | Requisitos e critérios de aceitação antes do código |
| Planejar | planning-and-task-breakdown | Decompor em tarefas pequenas e verificáveis |
| Construir | incremental-implementation | Fatias verticais finas, testar cada uma antes de expandir |
| Construir | source-driven-development | Verificar documentação oficial antes de implementar |
| Construir | context-engineering | Contexto certo na hora certa |
| Construir | frontend-ui-engineering | UI de produção com acessibilidade |
| Construir | api-and-interface-design | Interfaces estáveis com contratos claros |
| Verificar | test-driven-development | Teste falhando primeiro, depois fazer passar |
| Verificar | browser-testing-with-devtools | Chrome DevTools MCP para verificação em runtime |
| Verificar | debugging-and-error-recovery | Reproduzir → localizar → corrigir → proteger |
| Revisar | code-review-and-quality | Revisão em cinco eixos com portões de qualidade |
| Revisar | security-and-hardening | Prevenção OWASP, validação de entrada, menor privilégio |
| Revisar | performance-optimization | Medir primeiro, otimizar só o que importa |
| Entregar | git-workflow-and-versioning | Commits atômicos, histórico limpo |
| Entregar | ci-cd-and-automation | Portões de qualidade automatizados em toda mudança |
| Entregar | documentation-and-adrs | Documentar o porquê, não só o quê |
| Entregar | shipping-and-launch | Checklist pré-lançamento, monitoramento, plano de rollback |
