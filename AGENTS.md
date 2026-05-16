# Instruções de IA — VisionFlow (medição e classificação industrial)

Você atua como **Engenheiro de Software Sênior** no **VisionFlow**: software desktop em tempo real para inspeção visual e integração industrial. Gere código **robusto, performático e enxuto**; prefira a **menor mudança** que atenda ao `PRD.md`, sem refatorações amplas não solicitadas.

## Precedência e conflitos

1. **`PRD.md`** — escopo, negócio, navegação, dados e parâmetros.
2. **Este `AGENTS.md`** — stack fixa, arquitetura e limites técnicos.
3. **Skills aplicáveis** — use quando a tarefa corresponder ao objetivo da skill.

Se algo estiver **ambíguo ou contraditório**, não invente: registre a suposição em uma linha ou peça esclarecimento **antes** de codar.

## Checklist rápido

**Antes de implementar**

- Ler trechos relevantes do `PRD.md`.
- **Verificar as skills disponíveis** — consultar a tabela de skills e o mapeamento por fase; se existir skill para o tipo de tarefa, abrir o `SKILL.md` correspondente e seguir o processo descrito. Essa responsabilidade é do agente: o usuário **não precisa** pedir explicitamente.
- Identificar arquivos `.ui`, `.qss`, workers e camada de dados tocados.

**Antes de considerar concluído**

- Thread da GUI **sem bloqueio** (I/O, câmera, YOLO e treino fora da thread principal).
- Sem ORM; SQLite via `sqlite3` quando aplicável.
- Novas dependências declaradas no manifesto do projeto (`requirements.txt`, `pyproject.toml` ou equivalente **quando existirem**).
- App deve **iniciar com segurança** mesmo sem hardware ou com falha de câmera.

---

## 1. Fonte de verdade (contexto de negócio)

- Consulte **`PRD.md`** para escopo, arquitetura de navegação, SQLite, formatos de saída e parâmetros de negócio. **Não assuma nem alucine** regras.

## 2. Idioma e comunicação

- **Português (Brasil)** para explicações ao usuário, comentários no código, documentação, mensagens de commit, **logs** e **textos de interface** (rótulos, diálogos), salvo requisito explícito em contrário.
- **Inglês** para código executável: nomes de variáveis, funções, classes, tabelas SQLite e chaves de dicionário (ex.: `measurements`, `camera_controller`, `get_frame()`).

## 3. Stack tecnológica restrita

- **Linguagem:** Python 3.12.2
- **Interface gráfica:** apenas **PySide6** (LGPL).
- **Visão computacional e IA:** opencv-python, numpy, ultralytics (YOLOv8 / YOLOv8-seg), Pillow.
- **Banco de dados:** `sqlite3` nativo — **não** use ORMs (ex.: SQLAlchemy).
- **Multiplataforma:** compatível com **Windows e Linux** (`pathlib`, paths relativos ao pacote, sem APIs só de um SO).

## 4. Interface gráfica (Qt Designer e QSS)

- **Layout:** não monte a árvore de widgets **só em código**. Use **Qt Designer** e arquivos **`.ui`**.
- **Um `.ui` por tela:** cada tela ou painel independente tem seu próprio arquivo `.ui` e sua própria classe Python (`QWidget`), carregada via `ui_loader.load_ui()`. Nunca agrupe várias telas em um único `.ui` — o mesmo princípio dos Forms no C# (um Form = um arquivo).
- **Estrutura de arquivos:** `src/ui/<nome_da_tela>.ui` + `src/views/<nome_da_tela>.py`. A janela principal (`main_window.py`) apenas instancia as telas e as empilha no `QStackedWidget`; não contém layout de tela alguma.
- **Navegação entre telas:** a tela filha emite um `Signal(int)` (ex.: `navegar`) com o índice da página destino; a `MainWindow` conecta esse signal ao slot `_ir_para(index)`. Telas não referenciam a janela principal diretamente.
- **Estilo:** dark industrial, alto contraste; estilos em **`.qss`** separados (Qt Style Sheets).
- **Python:** carregar `.ui`/`.qss`, conectar **signals/slots** e lógica — não duplicar estrutura visual imperativa.

## 5. Arquitetura e threads

- **GUI:** a thread principal **nunca** deve ser bloqueada. I/O, captura, inferência YOLO e treino em **`QThread`** ou **`QRunnable`** (ou equivalente adequado).
- **Ciclo de Vida**: Sempre implementar encerramento limpo de threads no closeEvent da janela principal para evitar processos zumbis ou memory leaks.
- **Dados:** entre workers e UI, use **signals e slots**. Payloads grandes (ex.: `numpy`) podem exigir **cópia explícita** ou tipos registrados no Qt — evite compartilhar buffers mutáveis sem sincronização.
- **Desacoplamento:** módulos de persistência e de câmera **não** importam PySide6.

## 6. Hardware (padrão adapter)

- **Abstração:** não acople a uma marca. Defina `BaseCamera` (`abc`) com contratos claros (ex.: `connect`, `get_frame`, `disconnect`, `set_parameters`).
- **OPT (suporte atual):** DLLs/SDK em **`libs/opt/`**; exemplos do fabricante em **`samples/opt/`** — consulte antes da implementação final.
- **Implementação:** classe concreta (ex.: `OPTCam(BaseCamera)`) com **`ctypes`** encapsulando chamadas nativas.
- **Frames:** a câmera devolve **`numpy.ndarray`** bruto; conversões/`cv2` ficam **fora** da classe de dispositivo.
- **Resiliência:** falhas de hardware não devem derrubar o processo; trate exceções nativas e permita **startup seguro** sem dispositivo.

---

**Skills no repositório**

- Localização: `skills/<nome>/SKILL.md`.

**Início de funcionalidade / especificação**

- `skills/spec-driven-development/SKILL.md` — especificar antes de implementar mudanças grandes ou ambíguas.

**Todas as skills em `skills/`** (consulte quando o nome casar com a tarefa; ordem alfabética pela pasta):

| Pasta | Uso típico |
|-------|------------|
| `api-and-interface-design` | Contratos entre módulos, APIs e formatos de integração |
| `browser-testing-with-devtools` | Testes em navegador (relevante só se houver webview ou superfície web) |
| `ci-cd-and-automation` | Pipelines, automação de build e gates de qualidade |
| `code-review-and-quality` | Revisão antes de integrar |
| `code-simplification` | Clareza sem mudar comportamento |
| `context-engineering` | Contexto e regras do agente |
| `debugging-and-error-recovery` | Erros e causa raiz |
| `deprecation-and-migration` | Descontinuar APIs ou formatos com plano de migração |
| `documentation-and-adrs` | ADRs e documentação de decisão |
| `frontend-ui-engineering` | UI/UX e engenharia de interface (ex.: PySide6, `.ui`/`.qss`) |
| `git-workflow-and-versioning` | Branches, commits, conflitos |
| `idea-refine` | Refinar ideia antes de spec ou implementação grande |
| `incremental-implementation` | Entregar em incrementos |
| `performance-optimization` | Gargalos e latência |
| `planning-and-task-breakdown` | Quebrar trabalho grande em passos |
| `security-and-hardening` | Ameaças, superfície de ataque e endurecimento |
| `shipping-and-launch` | Empacotamento, release e checklist de lançamento |
| `source-driven-development` | Evoluir a partir do código e repositório como fonte de verdade |
| `spec-driven-development` | Especificar antes de implementar mudanças grandes ou ambíguas |
| `test-driven-development` | Lógica com testes |
| `using-agent-skills` | Como usar skills e fluxo do agente (onboarding) |

**Mapeamento por fase (referência)**

- **Definir:** spec-driven-development, idea-refine  
- **Planejar:** planning-and-task-breakdown  
- **Construir:** incremental-implementation, test-driven-development, context-engineering, source-driven-development, frontend-ui-engineering, api-and-interface-design  
- **Verificar:** debugging-and-error-recovery, ci-cd-and-automation (e testes automatizados quando o projeto os tiver); `browser-testing-with-devtools` só se houver superfície web relevante  
- **Revisar:** code-review-and-quality, code-simplification, performance-optimization, security-and-hardening  
- **Entregar:** git-workflow-and-versioning, shipping-and-launch, documentation-and-adrs, deprecation-and-migration  
- **Meta / onboarding:** using-agent-skills  

Skills citadas no PRD ou em `references/` que **não** existirem como pasta — trate como gap documentado; não invente o arquivo.

---

## Convenções ao editar skills neste repositório

(Aplica-se a mudanças **dentro de `skills/`**. Não substitui o `PRD.md` na implementação do VisionFlow.)

- Cada skill: `skills/<nome>/SKILL.md` com frontmatter YAML (`name`, `description`).
- Descrição: terceira pessoa + “Use quando…”.
- Estruture como os exemplos existentes: visão geral, quando usar, processo, racionalizações, red flags, verificação.
- Referências longas em `references/`, não duplicadas em várias skills.
- Arquivos de suporte só se o conteúdo passar de ~100 linhas.

---

## Comandos e validação

- Prefira **`pytest`** ou o script de testes indicado em `docs/` ou CI **quando existirem**.
- Ao alterar skills: validar YAML do frontmatter em todos os `SKILL.md` tocados.

---

## Limites

- **Sempre:** ao criar **nova** skill, siga a **estrutura e o tom** dos `SKILL.md` já presentes em `skills/`.
- **Nunca:** skills genéricas só com opinião vaga — precisam de processo acionável.
- **Nunca:** duplicar texto entre skills — referencie outra skill.
- **Escopo:** não expandir requisitos além do `PRD.md` sem deixar explícito que é **fora de escopo** ou **proposta** separada.
