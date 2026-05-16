#!/bin/bash
set -e

# Inicializa o diretório de ideias para a skill idea-refine.

IDEAS_DIR="docs/ideas"

if [ ! -d "$IDEAS_DIR" ]; then
  mkdir -p "$IDEAS_DIR"
  echo "Diretório criado: $IDEAS_DIR" >&2
else
  echo "Diretório já existe: $IDEAS_DIR" >&2
fi

echo "{\"status\": \"ready\", \"directory\": \"$IDEAS_DIR\"}"
