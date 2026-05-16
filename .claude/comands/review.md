---
description: Realize uma revisão de código em cinco eixos — correção, legibilidade, arquitetura, segurança e performance
---

Invoque a habilidade `agent-skills:code-review-and-quality`.

Revise as alterações atuais (em *stage* ou commits recentes) em todos os cinco eixos:

1. **Correção** — Corresponde à especificação? Casos de borda foram tratados? Os testes são adequados?
2. **Legibilidade** — Nomes claros? Lógica direta? Bem organizado?
3. **Arquitetura** — Segue os padrões existentes? Fronteiras limpas? Nível de abstração correto?
4. **Segurança** — Entradas validadas? Segredos protegidos? Autenticação verificada? (Use a habilidade `security-and-hardening`)
5. **Performance** — Sem consultas N+1? Sem operações ilimitadas? (Use a habilidade `performance-optimization`)

Categorize as descobertas como Crítica, Importante ou Sugestão.
Gere uma revisão estruturada com referências específicas de `arquivo:linha` e recomendações de correção.