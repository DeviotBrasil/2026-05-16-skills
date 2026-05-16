#!/bin/bash
# Hook de início de sessão agent-skills
# Injeta a meta-skill using-agent-skills em toda sessão nova

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$(dirname "$SCRIPT_DIR")/skills"
META_SKILL="$SKILLS_DIR/using-agent-skills/SKILL.md"

if ! command -v jq >/dev/null 2>&1; then
  echo '{"priority": "INFO", "message": "agent-skills: jq é necessário para o hook session-start, mas não foi encontrado no PATH. Instale jq (ex.: brew install jq ou apt-get install jq) para habilitar a injeção da meta-skill. As skills continuam disponíveis individualmente."}'
  exit 0
fi

if [ -f "$META_SKILL" ]; then
  CONTENT=$(cat "$META_SKILL")
  # Use jq to properly escape and construct valid JSON
  jq -cn \
    --arg message "agent-skills carregado. Use o fluxograma de descoberta de skills para encontrar a skill certa para sua tarefa.

$CONTENT" \
    '{priority: "IMPORTANT", message: $message}'
else
  echo '{"priority": "INFO", "message": "agent-skills: meta-skill using-agent-skills não encontrada. As skills ainda podem estar disponíveis individualmente."}'
fi
