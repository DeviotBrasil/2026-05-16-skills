---
name: deprecation-and-migration
description: Gerencia descontinuação e migração. Use ao remover sistemas, APIs ou recursos antigos. Use ao migrar usuários de uma implementação para outra. Use ao decidir manter ou aposentar código existente.
---

# Descontinuação e migração

## Visão geral

Código é passivo, não ativo. Toda linha tem custo contínuo de manutenção — bugs, dependências, patches de segurança e onboarding de novos engenheiros. Descontinuação é a disciplina de remover código que não paga mais o custo; migração é mover usuários com segurança do antigo para o novo.

A maioria das organizações sabe construir. Poucas sabem remover. Esta skill trata dessa lacuna.

## Quando usar

- Substituir sistema, API ou biblioteca antigo por um novo
- Aposentar recurso que não é mais necessário
- Consolidar implementações duplicadas
- Remover código morto sem dono mas do qual todos dependem
- Planejar o ciclo de vida de um sistema novo (planejar descontinuação já na concepção)
- Decidir manter sistema legado ou investir em migração

## Princípios centrais

### Código é passivo

Toda linha tem custo contínuo: testes, documentação, patches de segurança, atualização de dependências e carga cognitiva de quem trabalha por perto. O valor do código é a funcionalidade que entrega, não o código em si. Quando a mesma funcionalidade pode ser entregue com menos código, menos complexidade ou abstrações melhores — o código antigo deve ir embora.

### A lei de Hyrum dificulta remoção

Com usuários suficientes, todo comportamento observável vira dependência — inclusive bugs, peculiaridades de timing e efeitos colaterais não documentados. Por isso descontinuação exige migração ativa, não só anúncio. Usuários não "simplesmente mudam" quando dependem de comportamentos que o substituto não replica.

### Planejar descontinuação já no design

Ao construir algo novo, pergunte: "Como removeríamos isso em 3 anos?" Sistemas com interfaces limpas, feature flags e superfície mínima são mais fáceis de descontinuar que sistemas que vazam detalhes de implementação para todos os lados.

## A decisão de descontinuar

Antes de descontinuar qualquer coisa, responda:

```
1. Este sistema ainda entrega valor único?
   → Se sim, mantenha. Se não, prossiga.

2. Quantos usuários/consumidores dependem dele?
   → Quantifique o escopo da migração.

3. Existe substituto?
   → Se não, construa o substituto primeiro. Não descontinue sem alternativa.

4. Qual o custo de migração por consumidor?
   → Se trivialmente automatizável, faça. Se manual/oneroso, pese contra custo de manutenção.

5. Qual o custo contínuo de NÃO descontinuar?
   → Risco de segurança, tempo de engenheiro, custo de oportunidade da complexidade.
```

## Descontinuação obrigatória vs. consultiva

| Tipo | Quando usar | Mecanismo |
|------|-------------|-----------|
| **Consultiva** | Migração opcional, sistema antigo estável | Avisos, documentação, incentivos. Usuários migram no próprio ritmo. |
| **Obrigatória** | Sistema antigo com problemas de segurança, bloqueia progresso ou custo de manutenção insustentável | Prazo firme. Sistema antigo será removido na data X. Fornecer ferramentas de migração. |

**Default consultivo.** Obrigatório só quando custo de manutenção ou risco justificam forçar migração. Descontinuação obrigatória exige ferramentas, documentação e suporte — não dá só para anunciar prazo.

## O processo de migração

### Passo 1: Construir o substituto

Não descontinue sem alternativa funcionando. O substituto deve:

- Cobrir todos os casos de uso críticos do sistema antigo
- Ter documentação e guias de migração
- Estar comprovado em produção (não só "teoricamente melhor")

### Passo 2: Anunciar e documentar

```markdown
## Aviso de descontinuação: OldService

**Status:** Deprecated as of 2025-03-01
**Replacement:** NewService (see migration guide below)
**Removal date:** Advisory — no hard deadline yet
**Reason:** OldService requires manual scaling and lacks observability.
            NewService handles both automatically.

### Migration Guide
1. Replace `import { client } from 'old-service'` with `import { client } from 'new-service'`
2. Update configuration (see examples below)
3. Run the migration verification script: `npx migrate-check`
```

### Passo 3: Migrar de forma incremental

Migre consumidores um a um, não todos de uma vez. Para cada consumidor:

```
1. Identificar todos os pontos de contato com o sistema descontinuado
2. Atualizar para usar o substituto
3. Verificar que o comportamento casa (testes, checagens de integração)
4. Remover referências ao sistema antigo
5. Confirmar ausência de regressões
```

**Regra do churn:** Se você é dono da infraestrutura sendo descontinuada, é responsável por migrar seus usuários — ou por fornecer atualizações retrocompatíveis que não exijam migração. Não anuncie descontinuação e deixe usuários se virarem.

### Passo 4: Remover o sistema antigo

Só depois que todos migraram:

```
1. Verificar uso zero ativo (métricas, logs, análise de dependências)
2. Remover o código
3. Remover testes, documentação e configuração associados
4. Remover avisos de descontinuação
5. Comemorar — remover código é conquista
```

## Padrões de migração

### Padrão Strangler

Rodar sistemas antigo e novo em paralelo. Roteie tráfego incrementalmente do antigo para o novo. Quando o antigo tratar 0% do tráfego, remova-o.

```
Fase 1: Novo trata 0%, antigo 100%
Fase 2: Novo trata 10% (canário)
Fase 3: Novo trata 50%
Fase 4: Novo trata 100%, antigo ocioso
Fase 5: Remover sistema antigo
```

### Padrão Adapter

Crie um adaptador que traduz chamadas da interface antiga para a nova implementação. Consumidores seguem na interface antiga enquanto você migra o backend.

```typescript
// Adapter: old interface, new implementation
class LegacyTaskService implements OldTaskAPI {
  constructor(private newService: NewTaskService) {}

  // Old method signature, delegates to new implementation
  getTask(id: number): OldTask {
    const task = this.newService.findById(String(id));
    return this.toOldFormat(task);
  }
}
```

### Migração com feature flag

Use feature flags para alternar consumidores do antigo para o novo, um a um:

```typescript
function getTaskService(userId: string): TaskService {
  if (featureFlags.isEnabled('new-task-service', { userId })) {
    return new NewTaskService();
  }
  return new LegacyTaskService();
}
```

## Código zumbi

Código zumbi não tem dono mas todos dependem dele. Não é mantido ativamente, não tem mantenedor claro e acumula vulnerabilidades e problemas de compatibilidade. Sinais:

- Sem commits há 6+ meses mas consumidores ativos existem
- Sem mantenedor ou equipe atribuídos
- Testes falhando que ninguém corrige
- Dependências com vulnerabilidades conhecidas que ninguém atualiza
- Documentação referencia sistemas que não existem mais

**Resposta:** Ou atribua dono e mantenha direito, ou descontinue com plano de migração concreto. Código zumbi não pode ficar no limbo — ou recebe investimento ou recebe remoção.

## Racionalizações comuns

| Racionalização | Realidade |
|---|---|
| "Ainda funciona, por que remover?" | Código sem manutenção acumula dívida de segurança e complexidade. O custo de manutenção cresce em silêncio. |
| "Alguém pode precisar depois" | Se precisar depois, pode ser reconstruído. Manter código não usado "por precaução" custa mais que reconstruir. |
| "A migração é cara demais" | Compare custo da migração com custo de manutenção em 2–3 anos. Migração costuma ser mais barata no longo prazo. |
| "Vamos descontinuar depois que terminarmos o novo" | Planejamento de descontinuação começa no design. Quando o novo estiver pronto, surgem novas prioridades. Planeje agora. |
| "Usuários vão migrar sozinhos" | Não vão. Forneça ferramentas, documentação e incentivos — ou faça a migração você mesmo (regra do churn). |
| "Podemos manter os dois sistemas para sempre" | Dois sistemas fazendo a mesma coisa dobram manutenção, testes, documentação e onboarding. |

## Sinais de alerta

- Sistemas descontinuados sem substituto disponível
- Anúncios de descontinuação sem ferramentas ou documentação de migração
- "Descontinuação suave" consultiva há anos sem progresso
- Código zumbi sem dono e com consumidores ativos
- Novos recursos no sistema descontinuado (invista no substituto)
- Descontinuação sem medir uso atual
- Remoção de código sem verificar consumidores ativos zero

## Verificação

Após concluir uma descontinuação:

- [ ] O substituto está comprovado em produção e cobre todos os casos de uso críticos
- [ ] Existe guia de migração com passos e exemplos concretos
- [ ] Todos os consumidores ativos migraram (verificado por métricas/logs)
- [ ] Código antigo, testes, documentação e configuração foram totalmente removidos
- [ ] Não restam referências ao sistema descontinuado na base
- [ ] Avisos de descontinuação foram removidos (cumpriram o papel)
