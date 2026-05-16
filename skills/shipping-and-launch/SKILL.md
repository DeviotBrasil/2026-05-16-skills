---
name: shipping-and-launch
description: Prepara lançamentos em produção. Use quando for implantar em produção. Use quando precisar de checklist pré-lançamento, ao configurar monitoramento, ao planejar rollout gradual ou quando precisar de estratégia de reversão.
---

# Entrega e lançamento

## Visão geral

Entregue com confiança. O objetivo não é só implantar — é implantar com segurança, com monitoramento ativo, plano de reversão pronto e clareza sobre o que é sucesso. Todo lançamento deve ser reversível, observável e incremental.

## Quando usar

- Implantar um recurso em produção pela primeira vez
- Liberar mudança significativa para usuários
- Migrar dados ou infraestrutura
- Abrir beta ou programa de acesso antecipado
- Qualquer implantação com risco (todas elas)

## Checklist pré-lançamento

### Qualidade de código

- [ ] Todos os testes passam (unitário, integração, e2e)
- [ ] Build conclui sem avisos
- [ ] Lint e verificação de tipos passam
- [ ] Código revisado e aprovado
- [ ] Sem comentários TODO que devam ser resolvidos antes do lançamento
- [ ] Sem `console.log` de depuração em código de produção
- [ ] Tratamento de erros cobre modos de falha esperados

### Segurança

- [ ] Sem segredos em código ou controle de versão
- [ ] `npm audit` sem vulnerabilidades críticas ou altas
- [ ] Validação de entrada em todos os endpoints voltados ao usuário
- [ ] Verificações de autenticação e autorização em vigor
- [ ] Cabeçalhos de segurança configurados (CSP, HSTS etc.)
- [ ] Rate limiting em endpoints de autenticação
- [ ] CORS configurado para origens específicas (não curinga)

### Desempenho

- [ ] Core Web Vitals dentro dos limiares "Good"
- [ ] Sem consultas N+1 em caminhos críticos
- [ ] Imagens otimizadas (compressão, tamanhos responsivos, lazy loading)
- [ ] Tamanho do bundle dentro do orçamento
- [ ] Consultas ao banco com índices adequados
- [ ] Cache configurado para ativos estáticos e consultas repetidas

### Acessibilidade

- [ ] Navegação por teclado funciona em todos os elementos interativos
- [ ] Leitor de tela transmite conteúdo e estrutura da página
- [ ] Contraste de cores atende WCAG 2.1 AA (4,5:1 para texto)
- [ ] Gerenciamento de foco correto em modais e conteúdo dinâmico
- [ ] Mensagens de erro descritivas e associadas aos campos do formulário
- [ ] Sem avisos de acessibilidade no axe-core ou Lighthouse

### Infraestrutura

- [ ] Variáveis de ambiente definidas em produção
- [ ] Migrações de banco aplicadas (ou prontas para aplicar)
- [ ] DNS e SSL configurados
- [ ] CDN configurada para ativos estáticos
- [ ] Logging e relatório de erros configurados
- [ ] Endpoint de health check existe e responde

### Documentação

- [ ] README atualizado com novos requisitos de configuração
- [ ] Documentação da API atual
- [ ] ADRs escritos para decisões arquiteturais
- [ ] Changelog atualizado
- [ ] Documentação voltada ao usuário atualizada (se aplicável)

## Estratégia de feature flags

Entregue atrás de feature flags para desacoplar implantação da liberação:

```typescript
// Feature flag check
const flags = await getFeatureFlags(userId);

if (flags.taskSharing) {
  // New feature: task sharing
  return <TaskSharingPanel task={task} />;
}

// Default: existing behavior
return null;
```

**Ciclo de vida da feature flag:**

```
1. IMPLANTAR com flag DESLIGADA → Código está em produção mas inativo
2. HABILITAR para equipe/beta → Teste interno no ambiente de produção
3. ROLLOUT GRADUAL → 5% → 25% → 50% → 100% dos usuários
4. MONITORAR em cada etapa → Taxa de erros, desempenho, feedback
5. LIMPAR → Remover flag e caminho morto após rollout completo
```

**Regras:**
- Toda feature flag tem um responsável e data de expiração
- Limpar flags em até 2 semanas após rollout completo
- Não aninhar feature flags (gera combinações exponenciais)
- Testar os dois estados da flag (ligada e desligada) no CI

## Rollout em estágios

### Sequência de rollout

```
1. IMPLANTAR em staging
   └── Suíte completa de testes em staging
   └── Smoke test manual dos fluxos críticos

2. IMPLANTAR em produção (feature flag DESLIGADA)
   └── Verificar implantação (health check)
   └── Conferir monitoramento de erros (sem erros novos)

3. HABILITAR para a equipe (flag LIGADA para usuários internos)
   └── Equipe usa o recurso em produção
   └── Janela de monitoramento de 24 h

4. ROLLOUT CANÁRIO (flag LIGADA para 5% dos usuários)
   └── Monitorar taxas de erro, latência, comportamento
   └── Comparar métricas: canário vs. linha de base
   └── Janela de monitoramento de 24–48 h
   └── Avançar só se todos os limiares passarem (ver tabela abaixo)

5. AUMENTO GRADUAL (25% → 50% → 100%)
   └── Mesmo monitoramento em cada passo
   └── Possibilidade de voltar ao percentual anterior a qualquer momento

6. ROLLOUT COMPLETO (flag LIGADA para todos)
   └── Monitorar por 1 semana
   └── Limpar feature flag
```

### Limiares de decisão de rollout

Use estes limiares para decidir avançar, segurar ou reverter em cada etapa:

| Métrica | Avançar (verde) | Segurar e investigar (amarelo) | Reverter (vermelho) |
|--------|------------------|--------------------------------|---------------------|
| Taxa de erro | Dentro de 10% da linha de base | 10–100% acima da linha de base | >2× linha de base |
| Latência P95 | Dentro de 20% da linha de base | 20–50% acima da linha de base | >50% acima da linha de base |
| Erros JS no cliente | Sem novos tipos de erro | Novos erros em <0,1% das sessões | Novos erros em >0,1% das sessões |
| Métricas de negócio | Neutro ou positivo | Queda <5% (pode ser ruído) | Queda >5% |

### Quando reverter

Reverta imediatamente se:
- A taxa de erro aumentar mais que 2× a linha de base
- A latência P95 aumentar mais que 50%
- Problemas reportados por usuários dispararem
- Forem detectados problemas de integridade de dados
- For descoberta vulnerabilidade de segurança

## Monitoramento e observabilidade

### O que monitorar

```
Métricas de aplicação:
├── Taxa de erro (total e por endpoint)
├── Tempo de resposta (p50, p95, p99)
├── Volume de requisições
├── Usuários ativos
└── Métricas-chave de negócio (conversão, engajamento)

Métricas de infraestrutura:
├── Uso de CPU e memória
├── Uso do pool de conexões do banco
├── Espaço em disco
├── Latência de rede
└── Profundidade de fila (se aplicável)

Métricas no cliente:
├── Core Web Vitals (LCP, INP, CLS)
├── Erros JavaScript
├── Taxas de erro de API na perspectiva do cliente
└── Tempo de carregamento da página
```

### Relato de erros

```typescript
// Set up error boundary with reporting
class ErrorBoundary extends React.Component {
  componentDidCatch(error: Error, info: React.ErrorInfo) {
    // Report to error tracking service
    reportError(error, {
      componentStack: info.componentStack,
      userId: getCurrentUser()?.id,
      page: window.location.pathname,
    });
  }

  render() {
    if (this.state.hasError) {
      return <ErrorFallback onRetry={() => this.setState({ hasError: false })} />;
    }
    return this.props.children;
  }
}

// Server-side error reporting
app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
  reportError(err, {
    method: req.method,
    url: req.url,
    userId: req.user?.id,
  });

  // Don't expose internals to users
  res.status(500).json({
    error: { code: 'INTERNAL_ERROR', message: 'Algo deu errado' },
  });
});
```

### Verificação pós-lançamento

Na primeira hora após o lançamento:

```
1. Verificar se o health endpoint retorna 200
2. Conferir painel de monitoramento de erros (sem novos tipos)
3. Conferir painel de latência (sem regressão)
4. Testar manualmente o fluxo crítico do usuário
5. Verificar se os logs estão fluindo e legíveis
6. Confirmar que o mecanismo de reversão funciona (dry run se possível)
```

## Estratégia de reversão

Toda implantação precisa de plano de reversão antes de ocorrer:

```markdown
## Plano de reversão para [Recurso/Lançamento]

### Condições de gatilho
- Taxa de erro > 2× linha de base
- Latência P95 > [X] ms
- Relatos de usuários sobre [problema específico]

### Passos de reversão
1. Desabilitar feature flag (se aplicável)
   OU
1. Implantar versão anterior: `git revert <commit> && git push`
2. Verificar reversão: health check, monitoramento de erros
3. Comunicar: avisar a equipe da reversão

### Considerações de banco
- Migração [X] tem reversão: `npx prisma migrate rollback`
- Dados inseridos pelo novo recurso: [preservados / limpos]

### Tempo para reverter
- Feature flag: < 1 minuto
- Reimplantar versão anterior: < 5 minutos
- Reversão de banco: < 15 minutos
```
## Ver também

- Para checagens de segurança pré-lançamento, veja `references/security-checklist.md`
- Para checklist de desempenho pré-lançamento, veja `references/performance-checklist.md`
- Para verificação de acessibilidade antes do lançamento, veja `references/accessibility-checklist.md`

## Racionalizações comuns

| Racionalização | Realidade |
|---|---|
| "Funciona em staging, vai funcionar em produção" | Produção tem dados, tráfego e casos extremos diferentes. Monitore após implantar. |
| "Não precisamos de feature flags nisso" | Todo recurso se beneficia de um kill switch. Até mudanças "simples" podem quebrar coisas. |
| "Monitoramento é overhead" | Sem monitoramento, problemas aparecem via reclamação de usuário em vez de painéis. |
| "Vamos adicionar monitoramento depois" | Adicione antes do lançamento. Não dá para depurar o que não dá para ver. |
| "Reverter é admitir falha" | Reverter é engenharia responsável. Entregar recurso quebrado é a falha. |

## Sinais de alerta

- Implantar sem plano de reversão
- Sem monitoramento ou relatório de erros em produção
- Lançamentos big-bang (tudo de uma vez, sem staging)
- Feature flags sem expiração ou responsável
- Ninguém monitorando a implantação na(s) primeira(s) hora(s)
- Configuração de produção feita de memória, não como código
- "É sexta à tarde, vamos entregar"

## Verificação

Antes de implantar:

- [ ] Checklist pré-lançamento concluído (todas as seções ok)
- [ ] Feature flag configurada (se aplicável)
- [ ] Plano de reversão documentado
- [ ] Painéis de monitoramento configurados
- [ ] Equipe avisada da implantação

Depois de implantar:

- [ ] Health check retorna 200
- [ ] Taxa de erro está normal
- [ ] Latência está normal
- [ ] Fluxo crítico do usuário funciona
- [ ] Logs estão fluindo
- [ ] Reversão testada ou verificada como pronta
