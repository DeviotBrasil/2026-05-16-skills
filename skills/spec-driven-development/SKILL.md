---
name: spec-driven-development
description: Cria especificações antes de codificar. Use ao iniciar um novo projeto, funcionalidade ou mudança significativa quando ainda não existe uma especificação. Use quando os requisitos forem incertos, ambíguos ou existirem apenas como uma ideia vaga.
---

# Desenvolvimento Baseado em Especificações (Spec-Driven Development)

## Visão Geral

Escreva uma especificação estruturada antes de escrever qualquer código. A especificação (spec) é a fonte única de verdade compartilhada entre você e o engenheiro humano — ela define o que estamos construindo, por que e como saberemos que está pronto. Codificar sem uma especificação é apenas adivinhação.

## Quando Usar

- Iniciar um novo projeto ou funcionalidade.
- Requisitos ambíguos ou incompletos.
- A mudança afeta múltiplos arquivos ou módulos.
- Você está prestes a tomar uma decisão arquitetural.
- A tarefa levaria mais de 30 minutos para ser implementada.

**Quando NÃO usar:** Correções de uma única linha, correções de erros de digitação (typos) ou mudanças onde os requisitos são inequívocos e autocontidos.

## O Fluxo de Trabalho com Portões (Gated Workflow)

O desenvolvimento baseado em especificações possui quatro fases. Não avance para a próxima fase até que a atual seja validada.

```
SPECIFY ──→ PLAN ──→ TASKS ──→ IMPLEMENT
   │          │        │          │
   ▼          ▼        ▼          ▼
 Human      Human    Human      Human
 reviews    reviews  reviews    reviews
```

### Fase 1: Especificar

Comece com uma visão de alto nível. Faça perguntas de esclarecimento ao humano até que os requisitos sejam concretos.

**Exponha suposições imediatamente.** Antes de escrever qualquer conteúdo da especificação, liste o que você está presumindo:

```
SUPOSIÇÕES QUE ESTOU FAZENDO:
1. Esta é uma aplicação web (não mobile nativo).
2. A autenticação usa cookies baseados em sessão (não JWT).
3. O banco de dados é PostgreSQL (baseado no esquema Prisma existente).
4. Estamos focando apenas em navegadores modernos (sem suporte a IE11).
→ Corrija-me agora ou prosseguirei com estas premissas.
```

Não preencha silenciosamente requisitos ambíguos. O propósito da especificação é trazer à tona mal-entendidos *antes* que o código seja escrito — suposições são a forma mais perigosa de mal-entendido.

**Escreva um documento de especificação cobrindo estas seis áreas principais:**

1. **Objetivo** — O que estamos construindo e por quê? Quem é o usuário? Como é o sucesso?

2. **Comandos** — Comandos executáveis completos com flags, não apenas nomes de ferramentas.
   ```
   Build: npm run build
   Test: npm test -- --coverage
   Lint: npm run lint --fix
   Dev: npm run dev
   ```

3. **Estrutura do Projeto** — Onde fica o código-fonte, onde os testes entram, onde a documentação pertence.

   ```
   src/           → Código-fonte da aplicação
   src/components → Componentes React
   src/lib        → Utilitários compartilhados
   tests/         → Testes unitários e de integração
   e2e/           → Testes de ponta a ponta
   docs/          → Documentação
   ```

4. **Estilo de Código** — Um snippet de código real mostrando seu estilo vale mais que três parágrafos descrevendo-o. Inclua convenções de nomenclatura, regras de formatação e exemplos de boa saída.

5. **Estratégia de Teste** — Qual framework, localização dos testes, expectativas de cobertura e quais níveis de teste para quais preocupações.

6. **Limites (Boundaries)** — Sistema de três níveis:
- **Sempre fazer:** Rodar testes antes de commits, seguir convenções de nomes, validar entradas.
- **Perguntar primeiro:** Mudanças no esquema do banco de dados, adicionar dependências, alterar config de CI.
- **Nunca fazer:** Commitar segredos, editar diretórios de terceiros (vendor), remover testes que falham sem aprovação.

**Modelo de especificação (Template):**

```markdown
# Spec: [Nome do Projeto/Funcionalidade]

## Objetivo
[O que estamos construindo e por quê. Histórias de usuário ou critérios de aceitação.]

## Stack Tecnológica
[Framework, linguagem, dependências principais com versões]

## Comandos
[Build, test, lint, dev — comandos completos]

## Estrutura do Projeto
[Layout de diretórios com descrições]

## Estilo de Código
[Snippet de exemplo + convenções principais]

## Estratégia de Teste
[Framework, locais de teste, requisitos de cobertura, níveis de teste]

## Limites
- Sempre: [...]
- Perguntar primeiro: [...]
- Nunca: [...]

## Critérios de Sucesso
[Como saberemos que está pronto — condições específicas e testáveis]

## Questões Abertas
[Qualquer coisa não resolvida que precise de entrada humana]
```

**Reformule instruções como critérios de sucesso.** Ao receber requisitos vagos, traduza-os em condições concretas:

```
REQUISITO: "Deixe o dashboard mais rápido"

CRITÉRIOS DE SUCESSO REFORMULADOS:
- LCP do Dashboard < 2.5s em conexão 4G.
- Carregamento inicial de dados completa em < 500ms.
- Sem mudança de layout durante o carregamento (CLS < 0.1).
→ Estes são os alvos corretos?
```

### Fase 2: Planejar

Com a especificação validada, gere um plano de implementação técnica:

1. Identifique os componentes principais e suas dependências.
2. Determine a ordem de implementação (o que deve ser construído primeiro).
3. Observe riscos e estratégias de mitigação.
4. Identifique o que pode ser construído em paralelo vs. o que deve ser sequencial.
5. Defina pontos de verificação entre as fases.

O plano deve ser revisável: o humano deve ser capaz de lê-lo e dizer "sim, essa é a abordagem correta" ou "não, mude X".

### Fase 3: Tarefas

Divida o plano em tarefas discretas e implementáveis:

- Cada tarefa deve ser concluível em uma única sessão focada.
- Cada tarefa tem critérios de aceitação explícitos.
- Cada tarefa inclui uma etapa de verificação (teste, build, verificação manual).
- As tarefas são ordenadas por dependência, não por importância percebida.
- Nenhuma tarefa deve exigir a alteração de mais de ~5 arquivos.

Modelo de tarefa:

```markdown
- [ ] Tarefa: [Descrição]
  - Aceitação: [O que deve ser verdade quando terminar]
  - Verificar: [Como confirmar — comando de teste, build, verificação manual]
  - Arquivos: [Quais arquivos serão afetados]
```

### Fase 4: Implementar

Execute as tarefas uma de cada vez seguindo as habilidades de `incremental-implementation` e `test-driven-development` skills. Use `context-engineering` para carregar as seções certas da especificação e arquivos de origem em cada etapa, em vez de inundar o agente com a especificação inteira.

## Mantendo a Especificação Viva

A especificação é um documento vivo, não um artefato único:

- **Atualize quando as decisões mudarem** — Se você descobrir que o modelo de dados precisa mudar, atualize a especificação primeiro, depois implemente.
- **Atualize quando o escopo mudar** — Funcionalidades adicionadas ou cortadas devem ser refletidas na especificação.
- **Commit a especificação** — A especificação pertence ao controle de versão junto com o código.
- **Referencie a especificação em PRs** — Linke de volta para a seção da especificação que cada PR implementa.

## Racionalizações Comuns

| Racionalização | Realidade |
|---|---|
| "Isso é simples, não preciso de spec" | Tarefas simples não precisam de specs longas, mas ainda precisam de critérios de aceitação. Uma spec de duas linhas está ótima. |
| "Vou escrever a spec depois de codificar" | Isso é documentação, não especificação. O valor da spec está em forçar a clareza antes do código. |
| "A spec vai nos atrasar" | Uma spec de 15 minutos evita horas de retrabalho. "Waterfall" de 15 minutos vence depuração de 15 horas. |
| "Os requisitos vão mudar de qualquer jeito" | É por isso que a spec é um documento vivo. Uma spec desatualizada ainda é melhor que nenhuma spec. |
| "O usuário sabe o que quer" | Mesmo pedidos claros têm suposições implícitas. A spec traz essas suposições à tona. |

## Sinais de Alerta (Red Flags)

- Começar a escrever código sem nenhum requisito escrito.
- Perguntar "devo apenas começar a construir?" antes de esclarecer o que significa "pronto".
- Implementar funcionalidades não mencionadas em nenhuma especificação ou lista de tarefas.
- Tomar decisões arquiteturais sem documentá-las.
- Pular a especificação porque "é óbvio o que construir".

## Verificação

Antes de prosseguir para a implementação, confirme:

- [ ] A especificação cobre as seis áreas principais.
- [ ] O humano revisou e aprovou a especificação.
- [ ] Os critérios de sucesso são específicos e testáveis.
- [ ] Os limites (Sempre/Perguntar/Nunca) estão definidos.
- [ ] A especificação foi salva em um arquivo no repositório.