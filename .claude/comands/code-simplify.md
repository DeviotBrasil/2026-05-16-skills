---
description: Simplifique o código para clareza e manutenibilidade — reduza a complexidade sem alterar o comportamento
---

Invoque a habilidade `agent-skills:code-simplification`.

Simplifique o código alterado recentemente (ou o escopo especificado) preservando exatamente o comportamento original:

1. Leia o arquivo `CLAUDE.md` e estude as convenções do projeto.
2. Identifique o código-alvo — mudanças recentes, a menos que um escopo maior seja especificado.
3. Entenda o propósito do código, quem o chama, casos de borda e cobertura de testes antes de alterá-lo.
4. Busque oportunidades de simplificação:
   - Aninhamento profundo → use cláusulas de guarda (*guard clauses*) ou helpers extraídos.
   - Funções longas → divida por responsabilidade.
   - Operadores ternários aninhados → use `if/else` ou `switch`.
   - Nomes genéricos → use nomes descritivos.
   - Lógica duplicada → use funções compartilhadas.
   - Código morto → remova após confirmar que não é utilizado.
5. Aplique cada simplificação de forma incremental — execute os testes após cada mudança.
6. Verifique se todos os testes passam, se o build foi bem-sucedido e se o *diff* está limpo.

Se os testes falharem após uma simplificação, reverta a alteração e reavalie. Use `code-review-and-quality` para revisar o resultado.