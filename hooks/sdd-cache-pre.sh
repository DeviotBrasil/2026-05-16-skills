#!/bin/bash
# sdd-cache-pre.sh — Hook PreToolUse para WebFetch.
#
# Cache de recurso HTTP por URL. Frescor delegado à origem via validadores HTTP;
# 304 Not Modified é o único sinal para servir do cache.
# Em hit, sai com 2 e escreve o corpo em cache no stderr para o Claude Code
# entregar ao agente no lugar do resultado do WebFetch. Caso contrário sai 0.
#
# Sem TTL: se os validadores não pegarem mudança, nada muda. Entradas sem
# ETag ou Last-Modified nunca são cacheadas (não dá para revalidar).
#
# Corpos cacheados são moldados pelo prompt (WebFetch pós-processa via modelo),
# então a chave é só URL e o prompt original aparece na mensagem de hit
# para o próximo agente julgar se a leitura anterior ainda se aplica.
#
# Dependências: jq, curl, shasum (ou sha256sum).

set -euo pipefail

# Degradação graciosa: se faltar dependência, deixa o fetch passar.
command -v jq   >/dev/null 2>&1 || exit 0
command -v curl >/dev/null 2>&1 || exit 0
command -v shasum >/dev/null 2>&1 || command -v sha256sum >/dev/null 2>&1 || exit 0

if [ -t 0 ]; then INPUT="{}"; else INPUT=$(cat); fi

# Log de depuração: ativo com SDD_CACHE_DEBUG=1 ou arquivo sentinela
# em .claude/sdd-cache/.debug. Ligar/desligar com touch / rm.
dbg() {
  local dir="${CLAUDE_PROJECT_DIR:-$PWD}/.claude/sdd-cache"
  [ "${SDD_CACHE_DEBUG:-0}" = "1" ] || [ -f "$dir/.debug" ] || return 0
  mkdir -p "$dir"
  printf '%s [pre]  %s\n' "$(date -u +%FT%TZ)" "$*" >> "$dir/.debug.log"
}
dbg "fired"

URL=$(printf '%s' "$INPUT" | jq -r '.tool_input.url // empty' 2>/dev/null || true)
if [ -z "$URL" ]; then dbg "no url in tool_input, exit"; exit 0; fi
dbg "url=$URL"

# Chave de cache é sha256(URL), truncada a 128 bits.
hash_key() {
  if command -v shasum >/dev/null 2>&1; then
    printf '%s' "$1" | shasum -a 256 | cut -c1-32
  else
    printf '%s' "$1" | sha256sum | cut -c1-32
  fi
}

CACHE_DIR="${CLAUDE_PROJECT_DIR:-$PWD}/.claude/sdd-cache"
CACHE_FILE="$CACHE_DIR/$(hash_key "$URL").json"

if [ ! -f "$CACHE_FILE" ]; then dbg "no cache file at $CACHE_FILE, exit"; exit 0; fi
dbg "cache file exists: $CACHE_FILE"

FETCHED_AT=$(jq -r '.fetched_at // 0' "$CACHE_FILE" 2>/dev/null || echo 0)
ORIGINAL_PROMPT=$(jq -r '.prompt // empty' "$CACHE_FILE" 2>/dev/null || true)
ETAG=$(jq -r '.etag // empty' "$CACHE_FILE" 2>/dev/null || true)
LAST_MOD=$(jq -r '.last_modified // empty' "$CACHE_FILE" 2>/dev/null || true)

# Sem validador não dá verificar frescor — nunca servir do cache.
if [ -z "$ETAG" ] && [ -z "$LAST_MOD" ]; then
  dbg "cached entry has no etag/last-modified, cannot revalidate, bypass"
  exit 0
fi

HEADERS=()
[ -n "$ETAG" ]     && HEADERS+=(-H "If-None-Match: $ETAG")
[ -n "$LAST_MOD" ] && HEADERS+=(-H "If-Modified-Since: $LAST_MOD")

STATUS=$(curl -sI -o /dev/null -w "%{http_code}" \
  --max-time 5 -L \
  "${HEADERS[@]}" \
  "$URL" 2>/dev/null || echo "000")
dbg "revalidation HEAD status=$STATUS"

if [ "$STATUS" != "304" ]; then
  dbg "not 304, letting WebFetch proceed"
  exit 0
fi

# Servidor confirmou conteúdo inalterado. Servir cópia em cache ao agente.
CONTENT=$(jq -r '.content // empty' "$CACHE_FILE" 2>/dev/null || true)
if [ -z "$CONTENT" ]; then dbg "cache file has empty content field, bypass"; exit 0; fi
dbg "cache HIT, blocking WebFetch with ${#CONTENT} bytes of cached content"

VERIFIED_AT_ISO=$(date -u -r "$FETCHED_AT" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null \
              || date -u -d "@$FETCHED_AT" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null \
              || echo "unknown")

# Emitir o payload com printf para $CONTENT nunca ser interpretado pelo shell
# (docs têm backticks, $vars e barras invertidas em exemplos; heredoc sem aspas
# trataria como substituição de comando).
{
  printf '[sdd-cache] Cache hit para %s\n\n' "$URL"
  printf 'Revalidado via HTTP 304; inalterado desde %s. Use o conteúdo em\n' "$VERIFIED_AT_ISO"
  printf 'cache abaixo como se o WebFetch tivesse acabado de retorná-lo.\n\n'
  if [ -n "$ORIGINAL_PROMPT" ]; then
    printf 'Prompt original do WebFetch: "%s". Se seu ângulo for outro, avalie\n' "$ORIGINAL_PROMPT"
    printf 'se esta leitura ainda cobre o necessário.\n\n'
  fi
  printf -- '----- BEGIN CACHED CONTENT -----\n'
  printf '%s\n' "$CONTENT"
  printf -- '----- END CACHED CONTENT -----\n'
} >&2
exit 2
