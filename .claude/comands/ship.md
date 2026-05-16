---
description: Execute o checklist de pré-lançamento via distribuição paralela (fan-out) para personas especialistas e sintetize uma decisão go/no-go
---

Invoque a habilidade `agent-skills:shipping-and-launch`.

`/ship` é um **orquestrador de fan-out**. Ele executa três personas especialistas em paralelo contra a alteração atual e, em seguida, mescla seus relatórios em uma única decisão de go/no-go (vai/não vai) com um plano de rollback. As personas operam de forma independente — sem estado compartilhado, sem ordenação — o que torna a execução paralela segura e útil aqui.

## Fase A — Fan-out paralelo

Crie três subagentes simultaneamente usando a ferramenta Agent. **Emita todas as três chamadas da ferramenta Agent em um único turno do assistente para que executem em paralelo** — chamadas sequenciais anulam o propósito deste comando.

No Claude Code, cada chamada passa o `subagent_type` correspondente ao campo `name` da persona:

1. **`code-reviewer`** — Realiza uma revisão de cinco eixos (correção, legibilidade, arquitetura, segurança, performance) nas alterações em *stage* ou commits recentes. Gera o template padrão de revisão.
2. **`security-auditor`** — Realiza uma análise de vulnerabilidades e modelo de ameaças. Verifica OWASP Top 10, manipulação de segredos, auth/authz e CVEs de dependências. Gera o relatório de auditoria padrão.
3. **`test-engineer`** — Analisa a cobertura de testes da alteração. Identifica lacunas no "caminho feliz" (*happy path*), casos de borda, caminhos de erro e cenários de concorrência. Gera a análise de cobertura padrão.

Em outros ambientes sem uma ferramenta de Agent, invoque o prompt de sistema de cada persona sequencialmente e trate suas saídas como se fossem retornadas em paralelo — a fase de mesclagem ainda funcionará.

Restrições (do modelo de subagente do Claude Code):
- Subagentes não podem criar outros subagentes — não permita que uma persona delegue para outra.
- Cada subagente recebe sua própria janela de contexto e retorna apenas seu relatório para esta sessão principal.
- Se precisar de colegas que conversem entre si em vez de apenas reportar, use as Equipes de Agentes do Claude Code (consulte `references/orchestration-patterns.md`).

**Resolução de Persona.** Se você definiu seus próprios `code-reviewer`, `security-auditor` ou `test-engineer` em `.claude/agents/` ou `~/.claude/agents/`, estes terão precedência sobre as versões deste plugin — o `/ship` utiliza suas customizações automaticamente.

## Fase B — Mesclagem no contexto principal

Assim que os três relatórios retornarem, o agente principal (não uma sub-persona) os sintetiza:

1. **Qualidade do Código** — Agregue descobertas Críticas/Importantes do `code-reviewer` e quaisquer testes falhos, erros de lint ou saída de build. Resolva duplicatas entre os revisores.
2. **Segurança** — Promova quaisquer descobertas Críticas/Altas do `security-auditor` para bloqueadores de lançamento (*launch blockers*). Cruze as informações com o eixo de segurança do `code-reviewer`.
3. **Performance** — Extraia dados do eixo de performance do `code-reviewer`; verifique as Core Web Vitals se aplicável.
4. **Acessibilidade** — Verifique navegação por teclado, suporte a leitores de tela e contraste (não coberto pelas três personas — trate diretamente aqui ou invoque o checklist de acessibilidade).
5. **Infraestrutura** — Variáveis de ambiente, migrações, monitoramento e feature flags. Verifique diretamente.
6. **Documentação** — README, ADRs e changelog. Verifique diretamente.

## Fase C — Decisão e Rollback

Gere uma única saída:

```markdown
## Decisão de Envio: GO | NO-GO

### Bloqueadores (devem ser corrigidos antes do envio)
- [Persona de origem: Descoberta crítica + arquivo:linha]

### Correções recomendadas (devem ser corrigidas antes do envio)
- [Persona de origem: Descoberta importante + arquivo:linha]

### Riscos reconhecidos (enviando mesmo assim)
- [Risco + mitigação]

### Plano de Rollback
- Condições de gatilho: [quais sinais acionariam o rollback]
- Procedimento de rollback: [passos exatos]
- Objetivo de tempo de recuperação (RTO): [meta de tempo]

### Relatórios especialistas (completos)
- [relatório do code-reviewer]
- [relatório do security-auditor]
- [relatório do test-engineer]