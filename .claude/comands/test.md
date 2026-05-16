---
description: Execute o fluxo de trabalho TDD — escreva testes que falhem, implemente e verifique. Para bugs, use o padrão Prove-It.
---

Invoque a habilidade `agent-skills:test-driven-development`.

Para novas funcionalidades:
1. Escreva testes que descrevam o comportamento esperado (eles devem FALHAR).
2. Implemente o código para fazê-los passar.
3. Refatore enquanto mantém os testes passando (verde).

Para correções de bugs (padrão Prove-It):
1. Escreva um teste que reproduza o bug (deve FALHAR).
2. Confirme que o teste falhou.
3. Implemente a correção.
4. Confirme que o teste passou.
5. Execute a suíte completa de testes para verificar regressões.

Para problemas relacionados ao navegador, também invoque `agent-skills:browser-testing-with-devtools` para verificar com o Chrome DevTools MCP.