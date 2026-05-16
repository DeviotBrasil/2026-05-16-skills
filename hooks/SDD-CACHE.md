# Hook sdd-cache

Cache de citações entre sessões para [`source-driven-development`](../skills/source-driven-development/SKILL.md). Evita chamadas redundantes a `WebFetch` sem enfraquecer a garantia da skill de “verificar contra a documentação atual”.

## Por quê

`source-driven-development` busca a documentação oficial para cada decisão específica de framework. Trabalhar no mesmo projeto em várias sessões significa buscar as mesmas páginas repetidamente. Guardar o conteúdo como “memória local” contradiz a skill — a documentação muda, e um cache obsoleto esconde isso.

Este hook armazena o conteúdo buscado em disco, mas **revalida com o servidor de origem a cada reutilização** via HTTP `If-None-Match` / `If-Modified-Since`. O conteúdo só é servido do cache quando o servidor responde `304 Not Modified`, o que é uma verificação atual — não uma leitura de memória estática.

## Configuração

1. Adicione os hooks em `.claude/settings.json` (ou `.claude/settings.local.json` para uso pessoal):

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "WebFetch",
        "hooks": [
          {
            "type": "command",
            "command": "bash ${CLAUDE_PROJECT_DIR}/hooks/sdd-cache-pre.sh",
            "timeout": 10
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "WebFetch",
        "hooks": [
          {
            "type": "command",
            "command": "bash ${CLAUDE_PROJECT_DIR}/hooks/sdd-cache-post.sh",
            "async": true,
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

   `${CLAUDE_PROJECT_DIR}` resolve para o diretório de onde você iniciou o Claude Code. O trecho acima funciona quando os hooks ficam dentro do mesmo projeto. Se você instalou `agent-skills` em outro lugar (ex.: plugin compartilhado em `~/agent-skills`), substitua `${CLAUDE_PROJECT_DIR}/hooks/...` pelo caminho absoluto de cada script.

2. Garanta que `.claude/sdd-cache/` está no `.gitignore` (já incluído neste repositório).

3. Use `/source-driven-development` (ou a skill) como de costume. Nenhuma mudança na skill nem no fluxo do agente — o cache é transparente.

## Modelo mental

Cache de recurso HTTP indexado por URL. A atualização é delegada à origem via `ETag` / `Last-Modified`; sem TTL, sem prompt na chave.

O corpo armazenado não é HTML bruto — `WebFetch` pós-processa cada resposta com um modelo usando o prompt do chamador; portanto o que cacheamos é uma “leitura” da página por um agente. A chave permanece só por URL para reutilizar leituras entre sessões; o prompt original fica como metadado e aparece na mensagem de hit para o próximo agente avaliar se a leitura anterior ainda serve.

## Como funciona

Uma entrada de cache por URL, armazenada como JSON em `.claude/sdd-cache/<sha>.json`:

| Evento | Ação |
|---|---|
| `PreToolUse WebFetch` | Se existir entrada, envia `HEAD` com `If-None-Match` / `If-Modified-Since`. Em `304`, bloqueia o fetch e devolve o conteúdo em cache ao agente via stderr, com o prompt original como metadado. Caso contrário, permite o fetch. |
| `PostToolUse WebFetch` | Captura a resposta, faz `HEAD` para registrar `ETag` / `Last-Modified` atuais e armazena `{url, prompt, etag, last_modified, content, fetched_at}`. |

**Regras de atualização:**

- A entrada só é servida se a origem confirmar `304 Not Modified`.
- Entradas sem cabeçalho `ETag` ou `Last-Modified` nunca são cacheadas — sem validador, o hook não pode verificar frescor depois; cachear seria confiar na memória.
- A chave de cache é `sha256(url)`. A mesma URL com prompt diferente acerta a mesma entrada; o corpo em cache reflete o prompt do primeiro fetch, e esse prompt é mostrado junto ao hit para o agente decidir reutilizar ou buscar de novo manualmente.

**O que o agente vê:**

- Cache hit: `WebFetch` é bloqueado com código de saída 2. O Claude Code entrega o stderr do hook ao agente como erro de ferramenta — é o sinal intencional de cache hit, não falha. O payload começa com `[sdd-cache] Cache hit for <url>` e envolve o corpo em cache entre `----- BEGIN CACHED CONTENT -----` / `----- END CACHED CONTENT -----` para o agente usar como se `WebFetch` tivesse acabado de retornar.
- Cache miss ou obsoleto: `WebFetch` roda normalmente; o resultado é armazenado para a próxima vez.

A skill em si não muda. Continua `DETECT → FETCH → IMPLEMENT → CITE`. O hook só altera o que acontece por baixo dos panos quando `FETCH` roda.

## Testes locais

### 1. Teste de fumaça dos scripts diretamente

```bash
# Simular payload PostToolUse: cachear uma página
echo '{
  "tool_input": {
    "url": "https://react.dev/reference/react/useActionState",
    "prompt": "extract the signature"
  },
  "tool_response": "useActionState(action, initialState) returns [state, formAction, isPending]"
}' | bash hooks/sdd-cache-post.sh

# Inspecionar a entrada armazenada
ls .claude/sdd-cache/
cat .claude/sdd-cache/*.json | jq .

# Simular o próximo PreToolUse na mesma URL + prompt
echo '{
  "tool_input": {
    "url": "https://react.dev/reference/react/useActionState",
    "prompt": "extract the signature"
  }
}' | bash hooks/sdd-cache-pre.sh
echo "exit=$?"
```

Esperado:

- O primeiro comando cria um arquivo sob `.claude/sdd-cache/` (somente se o servidor retornou `ETag` ou `Last-Modified`).
- O segundo comando sai com `2` e o conteúdo em cache em stderr quando a origem responde `304`, ou sai com `0` em silêncio caso contrário.

### 2. Ponta a ponta em sessão real

1. Registre os hooks em `.claude/settings.local.json` como acima.
2. Inicie uma sessão do Claude Code neste repositório.
3. Peça ao agente para buscar uma página de documentação (ex.: “fetch `https://react.dev/reference/react/useActionState` and summarize”).
4. Verifique se aparece um arquivo sob `.claude/sdd-cache/`.
5. Peça de novo a mesma página com o mesmo prompt.
6. Verifique se o segundo `WebFetch` é bloqueado e o conteúdo em cache é devolvido (visível na transcrição como erro de ferramenta com prefixo `[sdd-cache]`).

### 3. Verificação de frescor

Para confirmar que o cache invalida quando a documentação muda, force um `ETag` incompatível. Escolha uma entrada específica — `*.json` fica inseguro quando o cache tem mais de um arquivo:

```bash
# Troque pelo nome real do arquivo
ENTRY=.claude/sdd-cache/e49c9f378670cfbb1d7d871b6dee16d9.json

# Altere o ETag para algo que a origem não reconheça
jq '.etag = "W/\"stale-etag-forced\""' "$ENTRY" > "$ENTRY.tmp" && mv "$ENTRY.tmp" "$ENTRY"

# O próximo PreToolUse deve errar (servidor retorna 200, não 304)
echo '{"tool_input":{"url":"...", "prompt":"..."}}' | bash hooks/sdd-cache-pre.sh
echo "exit=$?"   # esperado 0 (fetch liberado)
```

### 4. Depuração

Ambos os hooks gravam eventos com timestamp em `.claude/sdd-cache/.debug.log` quando o modo debug está ativo. Ative com uma das opções:

```bash
# Opção A: variável de ambiente (por sessão)
SDD_CACHE_DEBUG=1 claude

# Opção B: arquivo sentinela (persistente)
mkdir -p .claude/sdd-cache && touch .claude/sdd-cache/.debug
# …desativar com: rm .claude/sdd-cache/.debug
```

O log captura URL, formato detectado de `tool_response`, status do HEAD e por que cada invocação acertou ou errou. Útil quando um cache miss parece inesperado (típico: a origem parou de emitir validadores).

## Limitações conhecidas

- **O corpo é moldado pelo prompt.** Um hit devolve a leitura anterior da página, com o prompt original exposto para o agente atual decidir se aplica. Se não aplicar, apague o arquivo em `.claude/sdd-cache/` para forçar novo fetch.
- **Cada gravação no cache custa um HEAD extra.** O Claude Code não expõe os cabeçalhos que o `WebFetch` já recebeu, então o hook pós refaz a consulta à origem para capturar `ETag` / `Last-Modified`. Uma ida e volta extra por miss — o preço de manter isso como hook puro sem mudanças no núcleo.
- **Servidores sem `ETag` ou `Last-Modified` nunca são cacheados.** A maioria dos sites oficiais (react.dev, docs.djangoproject.com, developer.mozilla.org) emite validadores. Sites que não emitem são sempre buscados de novo.
- **Um servidor com comportamento incorreto pode devolver `304` errado.** Isso é bug de servidor a diagnosticar, não invariante de cache a defender; não encobrimos com TTL. Apague a entrada se notar conteúdo obsoleto.
- **O cache é local e por projeto.** Não há cache compartilhado em equipe. Adicionar um exigiria armazenamento endereçável por conteúdo assinado, fora de escopo.

## Requisitos

- `jq`
- `curl`
- `shasum` ou `sha256sum` (detecção automática)
- Bash 3.2+
