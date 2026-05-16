#!/bin/bash
# simplify-ignore.sh — Hook para Read (PreToolUse), Edit|Write (PostToolUse), Stop
#
# PreToolUse Read   → faz backup do arquivo, substitui blocos por BLOCK_<hash> no lugar
# PostToolUse Edit  → expande placeholders, refiltra para o arquivo permanecer oculto
# PostToolUse Write → expande placeholders, refiltra para o arquivo permanecer oculto
# Stop              → restaura o conteúdo real do arquivo a partir do backup
#
# O arquivo em disco SEMPRE tem placeholders enquanto a sessão está ativa.
# O conteúdo real (com alterações do modelo) fica no backup.
#
# Dependências: jq, shasum ou sha1sum (detecção automática)

set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
  printf '%s\n' "erro: jq ausente" >&2; exit 1
fi

CACHE="${CLAUDE_PROJECT_DIR:-.}/.claude/.simplify-ignore-cache"
if [ -t 0 ]; then INPUT="{}"; else INPUT=$(cat); fi

# Analisar entrada do hook — erros explícitos para set -e não sair em silêncio
# com JSON inválido e exibir diagnóstico útil.
parse_error=""
TOOL_NAME=$(printf '%s' "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null) || {
  parse_error="falha ao analisar .tool_name na entrada do hook"
  TOOL_NAME=""
}
FILE_PATH=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null) || {
  parse_error="falha ao analisar .tool_input.file_path na entrada do hook"
  FILE_PATH=""
}
if [ -n "$parse_error" ]; then
  printf 'Aviso: %s (entrada: %.120s)\n' "$parse_error" "$INPUT" >&2
fi

hash_cmd() {
  if command -v shasum >/dev/null 2>&1; then shasum
  elif command -v sha1sum >/dev/null 2>&1; then sha1sum
  else printf '%s\n' "erro: shasum ou sha1sum ausente" >&2; exit 1; fi
}
file_id() { printf '%s' "$1" | hash_cmd | cut -c1-16; }
block_hash() { printf '%s' "$1" | hash_cmd | cut -c1-8; }
# Escapar metacaracteres glob para ${var/pattern/repl} tratar pattern como literal.
# Necessário no Bash 3.2 (macOS) onde aspas não suprimem glob em padrões PE.
escape_glob() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\*/\\*}"
  s="${s//\?/\\?}"
  s="${s//\[/\\[}"
  printf '%s' "$s"
}

# ── filter_file: troca blocos simplify-ignore por placeholders BLOCK_<hash> ─
# Lê $1 (origem), escreve versão filtrada em $2 (destino), salva blocos no cache.
# Retorna 0 se achou blocos, 1 se nenhum.
filter_file() {
  local src="$1" dest="$2" fid="$3"
  : > "$dest"
  rm -f "$CACHE/${fid}".block.* "$CACHE/${fid}".reason.* "$CACHE/${fid}".prefix.* "$CACHE/${fid}".suffix.*

  local count=0 in_block=0 buf="" reason="" prefix="" suffix=""

  while IFS= read -r line || [ -n "$line" ]; do
    # Marcador de início (sem fork — usa case do bash)
    if [ $in_block -eq 0 ]; then
      case "$line" in *simplify-ignore-start*)
        in_block=1
        buf="$line"
        # Extrair prefixo/sufixo de comentário para preservar sintaxe da linguagem
        prefix="${line%%simplify-ignore-start*}"
        suffix=""
        case "$line" in *'*/'*) suffix=" */" ;; *'-->'*) suffix=" -->" ;; esac
        reason=$(printf '%s' "$line" | sed -n 's/.*simplify-ignore-start:[[:space:]]*//p' \
          | sed 's/[[:space:]]*\*\/.*$//' | sed 's/[[:space:]]*-->.*$//' | sed 's/[[:space:]]*$//')
        # Bloco de uma linha (início + fim na mesma linha)
        case "$line" in *simplify-ignore-end*)
          in_block=0
          # Escrever bloco de uma linha já e pular para não disparar
          # de novo a verificação do marcador de fim abaixo
          local h; h=$(block_hash "$buf")
          count=$((count + 1))
          printf '%s' "$buf" > "$CACHE/${fid}.block.${h}"
          [ -n "$reason" ] && printf '%s' "$reason" > "$CACHE/${fid}.reason.${h}"
          printf '%s' "$prefix" > "$CACHE/${fid}.prefix.${h}"
          printf '%s' "$suffix" > "$CACHE/${fid}.suffix.${h}"
          if [ -n "$reason" ]; then
            printf '%s\n' "${prefix}BLOCK_${h}: ${reason}${suffix}" >> "$dest"
          else
            printf '%s\n' "${prefix}BLOCK_${h}${suffix}" >> "$dest"
          fi
          buf=""; reason=""; prefix=""; suffix=""
          continue
          ;; *)
          continue
          ;;
        esac
      ;; esac
    fi
    # Acumular conteúdo do bloco
    if [ $in_block -eq 1 ]; then
      buf="${buf}
${line}"
    fi
    # Verificar marcador de fim
    case "$line" in *simplify-ignore-end*)
      if [ $in_block -eq 1 ]; then
        local h; h=$(block_hash "$buf")
        count=$((count + 1))
        printf '%s' "$buf" > "$CACHE/${fid}.block.${h}"
        [ -n "$reason" ] && printf '%s' "$reason" > "$CACHE/${fid}.reason.${h}"
        printf '%s' "$prefix" > "$CACHE/${fid}.prefix.${h}"
        printf '%s' "$suffix" > "$CACHE/${fid}.suffix.${h}"
        if [ -n "$reason" ]; then
          printf '%s\n' "${prefix}BLOCK_${h}: ${reason}${suffix}" >> "$dest"
        else
          printf '%s\n' "${prefix}BLOCK_${h}${suffix}" >> "$dest"
        fi
        in_block=0; buf=""; reason=""; prefix=""; suffix=""
        continue
      fi
      ;;
    esac
    [ $in_block -eq 0 ] && printf '%s\n' "$line" >> "$dest"
  done < "$src"

  # Bloco não fechado → despejar como está
  if [ $in_block -eq 1 ] && [ -n "$buf" ]; then
    printf 'Aviso: simplify-ignore-start não fechado em %s (bloco não ocultado)\n' "$src" >&2
    printf '%s\n' "$buf" >> "$dest"
  fi

  # Preservar newline final do arquivo de origem
  if [ -s "$dest" ] && [ -s "$src" ] && [ -n "$(tail -c 1 "$src")" ]; then
    perl -pe 'chomp if eof' "$dest" > "${dest}.nnl" && \
      cat "${dest}.nnl" > "$dest" && rm -f "${dest}.nnl"
  fi

  [ $count -gt 0 ] && return 0 || return 1
}

# ── Stop: restaurar todos os arquivos a partir do backup ──────────────────
if [ -z "$TOOL_NAME" ]; then
  [ -d "$CACHE" ] || exit 0
  for bak in "$CACHE"/*.bak; do
    [ -f "$bak" ] || continue
    fid="${bak##*/}"; fid="${fid%.bak}"
    pathfile="$CACHE/${fid}.path"
    [ -f "$pathfile" ] || { rm -f "$bak"; continue; }
    orig=$(cat "$pathfile")
    if [ -f "$orig" ]; then
      cat "$bak" > "$orig"
      rm -f "$bak" "$pathfile" "$CACHE/${fid}".block.* "$CACHE/${fid}".reason.* "$CACHE/${fid}".prefix.* "$CACHE/${fid}".suffix.*
      rmdir "$CACHE/${fid}.lock" 2>/dev/null
    else
      # Arquivo foi movido/excluído — salvar backup como .recovered, não destruir
      mkdir -p "$(dirname "${orig}.recovered")"
      mv "$bak" "${orig}.recovered"
      rm -f "$pathfile" "$CACHE/${fid}".block.* "$CACHE/${fid}".reason.* "$CACHE/${fid}".prefix.* "$CACHE/${fid}".suffix.*
      rmdir "$CACHE/${fid}.lock" 2>/dev/null
      printf 'Aviso: %s foi movido/excluído. Original recuperado em %s.recovered\n' "$orig" "$orig" >&2
    fi
  done
  # Limpar locks órfãos (criados mas crash antes do backup)
  for lockdir in "$CACHE"/*.lock; do
    [ -d "$lockdir" ] || continue
    rmdir "$lockdir" 2>/dev/null
  done
  exit 0
fi

[ -z "$FILE_PATH" ] && exit 0

# ── PreToolUse Read: filtrar no lugar ───────────────────────────────────────
if [ "$TOOL_NAME" = "Read" ]; then
  [ -f "$FILE_PATH" ] || exit 0
  case "$(basename "$FILE_PATH")" in simplify-ignore*|SIMPLIFY-IGNORE*) exit 0 ;; esac

  mkdir -p "$CACHE"
  ID=$(file_id "$FILE_PATH")

  # Se já existe backup, arquivo já está filtrado — sair
  [ -f "$CACHE/${ID}.bak" ] && exit 0

  grep -q 'simplify-ignore-start' -- "$FILE_PATH" || exit 0

  # Lock atômico: mkdir falha se outra sessão competir
  if ! mkdir "$CACHE/${ID}.lock" 2>/dev/null; then
    # Lock existe — recuperar só se obsoleto (>1 min sem backup = sobra de crash)
    if [ ! -f "$CACHE/${ID}.bak" ] && \
       [ -n "$(find "$CACHE/${ID}.lock" -maxdepth 0 -mmin +1 2>/dev/null)" ]; then
      rmdir "$CACHE/${ID}.lock" 2>/dev/null || true
      mkdir "$CACHE/${ID}.lock" 2>/dev/null || exit 0
    else
      exit 0
    fi
  fi

  # Backup do original (preservar newline final)
  cp -p "$FILE_PATH" "$CACHE/${ID}.bak" 2>/dev/null || cp "$FILE_PATH" "$CACHE/${ID}.bak"
  printf '%s' "$FILE_PATH" > "$CACHE/${ID}.path"

  # Filtrar no lugar (cat > preserva inode e permissões)
  FILTERED="$CACHE/${ID}.$$.tmp"
  rm -f "$FILTERED"
  if filter_file "$FILE_PATH" "$FILTERED" "$ID"; then
    cat "$FILTERED" > "$FILE_PATH"
    rm -f "$FILTERED"
  else
    rm -f "$FILTERED" "$CACHE/${ID}.bak" "$CACHE/${ID}.path"
    rmdir "$CACHE/${ID}.lock" 2>/dev/null
  fi
  exit 0
fi

# ── PostToolUse Edit|Write: expandir, depois refiltrar ─────────────────────
if [ "$TOOL_NAME" = "Edit" ] || [ "$TOOL_NAME" = "Write" ]; then
  ID=$(file_id "$FILE_PATH")
  [ -f "$CACHE/${ID}.bak" ] || exit 0
  ls "$CACHE/${ID}".block.* >/dev/null 2>&1 || exit 0

  # Expandir placeholders, preservando código em linha que o modelo adicionou
  EXPANDED="$CACHE/${ID}.$$.expanded"
  rm -f "$EXPANDED"
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in *BLOCK_*)
      # Expandir todos os placeholders nesta linha (vários por linha)
      for bf in "$CACHE/${ID}".block.*; do
        [ -f "$bf" ] || continue
        h="${bf##*.}"
        case "$line" in *"BLOCK_${h}"*)
          # Reconstruir o padrão exato do placeholder
          bp=""; bs=""; br=""
          [ -f "$CACHE/${ID}.prefix.${h}" ] && bp=$(cat "$CACHE/${ID}.prefix.${h}")
          [ -f "$CACHE/${ID}.suffix.${h}" ] && bs=$(cat "$CACHE/${ID}.suffix.${h}")
          [ -f "$CACHE/${ID}.reason.${h}" ] && br=$(cat "$CACHE/${ID}.reason.${h}")
          if [ -n "$br" ]; then
            placeholder="${bp}BLOCK_${h}: ${br}${bs}"
          else
            placeholder="${bp}BLOCK_${h}${bs}"
          fi
          block_content=$(cat "$bf"; printf x); block_content="${block_content%x}"
          # Escapar metacaracteres glob (* ? [ \) no padrão
          esc_placeholder=$(escape_glob "$placeholder")
          # Substituição nativa bash (// = global): troca placeholder, mantém o resto
          line="${line//$esc_placeholder/$block_content}"
          # Fallback: se o modelo alterou o texto do motivo, tentar sem motivo
          # (só se BLOCK_hash ainda estiver presente E não estava no bloco original)
          case "$block_content" in *"BLOCK_${h}"*) ;; *)
            case "$line" in *"BLOCK_${h}"*)
              printf 'Aviso: placeholder BLOCK_%s foi alterado pelo modelo, usando correspondência aproximada\n' "$h" >&2
              esc_fuzzy=$(escape_glob "${bp}BLOCK_${h}${bs}")
              line="${line//$esc_fuzzy/$block_content}"
              # Último recurso: casar só o token de hash
              case "$line" in *"BLOCK_${h}"*)
                line="${line//BLOCK_${h}/$block_content}"
              ;; esac
            ;; esac
          ;; esac
        ;; esac
      done
    ;; esac
    printf '%s\n' "$line" >> "$EXPANDED"
  done < "$FILE_PATH"
  # Preservar newline final
  if [ -s "$EXPANDED" ] && [ -s "$FILE_PATH" ] && [ -n "$(tail -c 1 "$FILE_PATH")" ]; then
    perl -pe 'chomp if eof' "$EXPANDED" > "${EXPANDED}.nnl" && \
      cat "${EXPANDED}.nnl" > "$EXPANDED" && rm -f "${EXPANDED}.nnl"
  fi
  # Avisar se o modelo removeu um bloco protegido por completo
  for bf in "$CACHE/${ID}".block.*; do
    [ -f "$bf" ] || continue
    bh="${bf##*.}"
    # Após expansão, blocos aparecem como código original (simplify-ignore-start).
    # Se nem código expandido nem placeholder estão em EXPANDED, foi apagado.
    if ! grep -qF "BLOCK_${bh}" "$EXPANDED" 2>/dev/null; then
      # Primeira linha do bloco para ver se expandiu de volta
      first_line=$(head -1 "$bf")
      if ! grep -qF "$first_line" "$EXPANDED" 2>/dev/null; then
        printf 'Aviso: bloco protegido BLOCK_%s foi removido pelo modelo\n' "$bh" >&2
      fi
    fi
  done
  # Preservar inode e permissões
  cat "$EXPANDED" > "$FILE_PATH"
  rm -f "$EXPANDED"

  # Salvar versão expandida como novo backup (arquivo "real" com mudanças do modelo)
  cp "$FILE_PATH" "$CACHE/${ID}.bak"

  # Refiltrar no lugar para o arquivo em disco manter placeholders
  FILTERED="$CACHE/${ID}.$$.tmp"
  rm -f "$FILTERED"
  if filter_file "$FILE_PATH" "$FILTERED" "$ID"; then
    cat "$FILTERED" > "$FILE_PATH"
    rm -f "$FILTERED"
  fi

  exit 0
fi
