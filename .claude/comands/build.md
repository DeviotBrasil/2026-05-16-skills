---
description: Implemente a próxima tarefa de forma incremental — construa, teste, verifique, commite
---

Invoque a habilidade `agent-skills:incremental-implementation` em conjunto com `agent-skills:test-driven-development`.

Selecione a próxima tarefa pendente do plano. Para cada tarefa:

1. Leia os critérios de aceitação da tarefa.
2. Carregue o contexto relevante (código existente, padrões, tipos).
3. Escreva um teste que falhe para o comportamento esperado (RED).
4. Implemente o código mínimo necessário para passar no teste (GREEN).
5. Execute a suíte completa de testes para verificar se houve regressões.
6. Execute o build para verificar a compilação.
7. Realize o commit com uma mensagem descritiva.
8. Marque a tarefa como concluída e siga para a próxima.

Se qualquer etapa falhar, siga a habilidade `agent-skills:debugging-and-error-recovery`.