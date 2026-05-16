# Hook simplify-ignore

Proteção em nível de bloco para `/code-simplify`. Marque o código que nunca deve ser simplificado — o modelo não o verá.

## Configuração

1. Anote os blocos que deseja proteger:

```js
/* simplify-ignore-start: perf-critical */
// XOR desenrolado manualmente — 3x mais rápido que um loop
result[0] = buf[0] ^ key[0];
result[1] = buf[1] ^ key[1];
result[2] = buf[2] ^ key[2];
result[3] = buf[3] ^ key[3];
/* simplify-ignore-end */
```

2. Adicione os hooks em `.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Read",
        "hooks": [{ "type": "command", "command": "bash ${CLAUDE_PROJECT_DIR}/hooks/simplify-ignore.sh" }]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [{ "type": "command", "command": "bash ${CLAUDE_PROJECT_DIR}/hooks/simplify-ignore.sh" }]
      }
    ],
    "Stop": [
      {
        "hooks": [{ "type": "command", "command": "bash ${CLAUDE_PROJECT_DIR}/hooks/simplify-ignore.sh" }]
      }
    ]
  }
}
```

3. Execute `/code-simplify` — os blocos protegidos viram placeholders `/* BLOCK_de115a1d: perf-critical */`. O modelo raciocina sobre o código ao redor sem ver a implementação protegida.

> **Nota:** O hook guarda backups temporários em `.claude/.simplify-ignore-cache/`. Garanta que esse caminho esteja no `.gitignore`.

## Como funciona

Um script, três eventos de hook:

| Evento | Ação |
|---|---|
| `PreToolUse Read` | Faz backup do arquivo, substitui blocos por placeholders `BLOCK_<hash>` no lugar |
| `PostToolUse Edit\|Write` | Expande placeholders de volta para o código real, salva as alterações do modelo, refiltra |
| `Stop` | Restaura todos os arquivos a partir do backup ao encerrar a sessão |

Cada bloco tem hash do conteúdo (8 caracteres hex via `shasum`/`sha1sum`) para que a ida e volta seja inequívoca mesmo se o modelo duplicar ou reordenar placeholders. O cache é escopado ao projeto para evitar interferência entre sessões.

## Sintaxe de anotação

```js
/* simplify-ignore-start */           // básico — oculta o bloco
/* simplify-ignore-start: motivo */   // com motivo — aparece no placeholder
/* simplify-ignore-end */
```

Qualquer estilo de comentário funciona (`//`, `/*`, `#`, `<!--`). Vários blocos por arquivo e blocos de uma linha são suportados. Os placeholders preservam a sintaxe original do comentário (ex.: `# BLOCK_xxx` em Python, `<!-- BLOCK_xxx -->` em HTML).

## Recuperação após falha

Se o Claude Code travar sem disparar o hook Stop, os arquivos no disco podem ainda conter placeholders `BLOCK_<hash>`. Para restaurar manualmente:

```bash
echo '{}' | bash hooks/simplify-ignore.sh
```

Os backups ficam em `.claude/.simplify-ignore-cache/` dentro do diretório do projeto.

## Limitações conhecidas

- **Blocos de uma linha ocultam a linha inteira.** Se `simplify-ignore-start` e `simplify-ignore-end` estiverem na mesma linha que outro código, a linha inteira fica oculta ao modelo, não só a parte anotada. Use linhas dedicadas para as anotações.
- **Detecção de sufixo de comentário cobre só `*/` e `-->`.** Motores de template com fechamentos não padrão (ERB `%>`, Blade `--}}`) podem gerar placeholders desbalanceados. Prefira comentários no estilo `#` ou `//`.
- **A expansão de fallback é progressiva, não exata.** Se o modelo alterar a formatação de um placeholder (ex.: muda o texto do motivo), o hook tenta correspondências cada vez mais simples: placeholder completo → prefixo+hash+sufixo → só hash. O fallback só-hash pode deixar resíduos cosméticos (ex.: `:` solto ou texto do motivo). Nesse caso é impresso um aviso em stderr.
- **Renomear arquivo deixa placeholders.** Se o modelo renomear ou mover um arquivo via comando shell, o novo arquivo manterá placeholders `BLOCK_<hash>`. O código original é salvo como `<nome-antigo>.recovered` ao parar a sessão. É preciso restaurar manualmente o código recuperado no arquivo novo.

## Requisitos

- `jq`, `shasum` ou `sha1sum` (detecção automática), Bash 3.2+
