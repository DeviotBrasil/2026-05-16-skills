#!/bin/bash
# simplify-ignore-test.sh — Testes do hook simplify-ignore
#
# Exercita filter_file extraindo definições do script do hook.
# Executar: bash hooks/simplify-ignore-test.sh

set -euo pipefail

PASS=0 FAIL=0
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

export CACHE="$TMPDIR/cache"
mkdir -p "$CACHE"

# Extract function definitions we need
hash_cmd() {
  if command -v shasum >/dev/null 2>&1; then shasum
  elif command -v sha1sum >/dev/null 2>&1; then sha1sum
  else printf '%s\n' "erro: shasum ou sha1sum ausente" >&2; exit 1; fi
}
file_id() { printf '%s' "$1" | hash_cmd | cut -c1-16; }
block_hash() { printf '%s' "$1" | hash_cmd | cut -c1-8; }
escape_glob() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\*/\\*}"
  s="${s//\?/\\?}"
  s="${s//\[/\\[}"
  printf '%s' "$s"
}

# Extrair filter_file do script do hook (de filter_file() até o } de fechamento)
eval "$(sed -n '/^filter_file()/,/^}/p' hooks/simplify-ignore.sh)"

assert_eq() {
  local label="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    PASS=$((PASS + 1))
    printf '  OK: %s\n' "$label"
  else
    FAIL=$((FAIL + 1))
    printf '  FALHA: %s\n' "$label" >&2
    printf '    esperado: %s\n' "$(printf '%s' "$expected" | cat -v)" >&2
    printf '    obtido:   %s\n' "$(printf '%s' "$actual" | cat -v)" >&2
  fi
}

# ── Teste 1: bloco de uma linha gera exatamente um placeholder ────────────
printf 'Teste 1: bloco de uma linha (início+fim na mesma linha)\n'
rm -f "$CACHE"/*

SRC="$TMPDIR/single-line.js"
DEST="$TMPDIR/single-line-filtered.js"
cat > "$SRC" <<'EOF'
const a = 1;
/* simplify-ignore-start */ const secret = 42; /* simplify-ignore-end */
const b = 2;
EOF

FID="test_single"
filter_file "$SRC" "$DEST" "$FID"

placeholder_count=$(grep -c 'BLOCK_' "$DEST")
assert_eq "exatamente uma linha de placeholder" "1" "$placeholder_count"
assert_eq "linha antes do bloco preservada" "1" "$(grep -c 'const a = 1' "$DEST")"
assert_eq "linha depois do bloco preservada" "1" "$(grep -c 'const b = 2' "$DEST")"

block_files=$(ls "$CACHE/${FID}".block.* 2>/dev/null | wc -l | tr -d ' ')
assert_eq "um arquivo de bloco no cache" "1" "$block_files"

block_content=$(cat "$CACHE/${FID}".block.*)
assert_eq "conteúdo do bloco confere" \
  "/* simplify-ignore-start */ const secret = 42; /* simplify-ignore-end */" \
  "$block_content"

# ── Teste 2: bloco multilinha ─────────────────────────────────────────────
printf '\nTeste 2: bloco multilinha\n'
rm -f "$CACHE"/*

SRC="$TMPDIR/multi-line.js"
DEST="$TMPDIR/multi-line-filtered.js"
cat > "$SRC" <<'EOF'
const a = 1;
// simplify-ignore-start
const secret1 = 42;
const secret2 = 99;
// simplify-ignore-end
const b = 2;
EOF

FID="test_multi"
filter_file "$SRC" "$DEST" "$FID"

placeholder_count=$(grep -c 'BLOCK_' "$DEST")
assert_eq "exatamente um placeholder para bloco multilinha" "1" "$placeholder_count"

output_lines=$(wc -l < "$DEST" | tr -d ' ')
assert_eq "saída tem 3 linhas (antes + placeholder + depois)" "3" "$output_lines"

# ── Teste 3: vários blocos no mesmo arquivo ──────────────────────────────
printf '\nTeste 3: vários blocos em um arquivo\n'
rm -f "$CACHE"/*

SRC="$TMPDIR/multi-block.js"
DEST="$TMPDIR/multi-block-filtered.js"
cat > "$SRC" <<'EOF'
line1
// simplify-ignore-start
blockA
// simplify-ignore-end
line2
// simplify-ignore-start
blockB
// simplify-ignore-end
line3
EOF

FID="test_multiblock"
filter_file "$SRC" "$DEST" "$FID"

placeholder_count=$(grep -c 'BLOCK_' "$DEST")
assert_eq "dois placeholders para dois blocos" "2" "$placeholder_count"

block_files=$(ls "$CACHE/${FID}".block.* 2>/dev/null | wc -l | tr -d ' ')
assert_eq "dois arquivos de bloco no cache" "2" "$block_files"

# ── Teste 4: string de motivo preservada ────────────────────────────────
printf '\nTeste 4: motivo no placeholder\n'
rm -f "$CACHE"/*

SRC="$TMPDIR/reason.js"
DEST="$TMPDIR/reason-filtered.js"
cat > "$SRC" <<'EOF'
// simplify-ignore-start: perf-critical
hot_loop();
// simplify-ignore-end
EOF

FID="test_reason"
filter_file "$SRC" "$DEST" "$FID"

assert_eq "placeholder inclui motivo" "1" "$(grep -c 'perf-critical' "$DEST")"

reason_files=$(ls "$CACHE/${FID}".reason.* 2>/dev/null | wc -l | tr -d ' ')
assert_eq "arquivo de motivo salvo" "1" "$reason_files"
assert_eq "conteúdo do motivo" "perf-critical" "$(cat "$CACHE/${FID}".reason.*)"

# ── Teste 5: preservação de newline final ────────────────────────────────
printf '\nTeste 5: preservação de newline final\n'
rm -f "$CACHE"/*

SRC="$TMPDIR/no-trailing-nl.js"
DEST="$TMPDIR/no-trailing-nl-filtered.js"
printf 'line1\n// simplify-ignore-start\nsecret\n// simplify-ignore-end' > "$SRC"

FID="test_trail"
filter_file "$SRC" "$DEST" "$FID"

# Origem sem newline final; destino também não deve ter newline final
src_has_nl=$(tail -c 1 "$SRC" | wc -l | tr -d ' ')
dest_has_nl=$(tail -c 1 "$DEST" | wc -l | tr -d ' ')
assert_eq "destino preserva ausência de newline final da origem" "$src_has_nl" "$dest_has_nl"

# ── Teste 6: sem blocos → retorna 1 ─────────────────────────────────────
printf '\nTeste 6: sem blocos retorna 1\n'
rm -f "$CACHE"/*

SRC="$TMPDIR/no-blocks.js"
DEST="$TMPDIR/no-blocks-filtered.js"
cat > "$SRC" <<'EOF'
const a = 1;
const b = 2;
EOF

FID="test_noblocks"
rc=0
filter_file "$SRC" "$DEST" "$FID" || rc=$?
assert_eq "retorna 1 quando não há blocos" "1" "$rc"

# ── Teste 7: bloco não fechado emite aviso e despeja ─────────────────────
printf '\nTeste 7: bloco não fechado\n'
rm -f "$CACHE"/*

SRC="$TMPDIR/unclosed.js"
DEST="$TMPDIR/unclosed-filtered.js"
cat > "$SRC" <<'EOF'
line1
// simplify-ignore-start
orphan code
EOF

FID="test_unclosed"
stderr_out=$(filter_file "$SRC" "$DEST" "$FID" 2>&1) || true
assert_eq "aviso emitido para bloco não fechado" "1" "$(printf '%s' "$stderr_out" | grep -c 'não fechado')"
assert_eq "código órfão despejado na saída" "1" "$(grep -c 'orphan code' "$DEST")"

# ── Teste 8: bloco de uma linha com motivo ───────────────────────────────
printf '\nTeste 8: bloco de uma linha com motivo\n'
rm -f "$CACHE"/*

SRC="$TMPDIR/single-reason.js"
DEST="$TMPDIR/single-reason-filtered.js"
cat > "$SRC" <<'EOF'
before
/* simplify-ignore-start: hot-path */ x = compute(); /* simplify-ignore-end */
after
EOF

FID="test_single_reason"
filter_file "$SRC" "$DEST" "$FID"

placeholder_count=$(grep -c 'BLOCK_' "$DEST")
assert_eq "exatamente um placeholder para linha única+motivo" "1" "$placeholder_count"
assert_eq "motivo no placeholder" "1" "$(grep -c 'hot-path' "$DEST")"

# ── Teste 9: sintaxe de comentário HTML ─────────────────────────────────
printf '\nTeste 9: sintaxe de comentário HTML\n'
rm -f "$CACHE"/*

SRC="$TMPDIR/html.html"
DEST="$TMPDIR/html-filtered.html"
cat > "$SRC" <<'EOF'
<div>
<!-- simplify-ignore-start -->
<secret-component />
<!-- simplify-ignore-end -->
</div>
EOF

FID="test_html"
filter_file "$SRC" "$DEST" "$FID"

placeholder_count=$(grep -c 'BLOCK_' "$DEST")
assert_eq "bloco HTML substituído" "1" "$placeholder_count"
assert_eq "sufixo HTML preservado" "1" "$(grep -c '\-\->' "$DEST")"

# ── Teste 10: entrada JSON inválida produz aviso (requer jq) ──────────────
if ! command -v jq >/dev/null 2>&1; then
  printf '\nTeste 10: ignorado (jq ausente no PATH)\n'
else
  printf '\nTeste 10: entrada JSON malformada produz aviso\n'
  warning_out=$(echo 'NOT_JSON{{{' | bash hooks/simplify-ignore.sh 2>&1) || true
  assert_eq "aviso em JSON inválido" "1" "$(printf '%s' "$warning_out" | grep -c 'Aviso:.*falha ao analisar')"
fi

# ── Resumo ───────────────────────────────────────────────────────────────
printf '\n══════════════════════════════════════════\n'
printf 'Resultados: %d ok, %d falhas\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
