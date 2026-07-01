# GxObjGen — extensão do GeneXus para IA (beta)

GxObjGen é uma extensão que roda **dentro do GeneXus** (17 ou 18) e expõe a KB **aberta no IDE**
para o **Claude Code** via um servidor **MCP** local. Com ela, a IA lê, documenta e (opcionalmente)
altera objetos da sua KB **ao vivo** — sem exportar nada, tudo em `127.0.0.1`.

> **Beta:** obrigado por testar! Veja "Reportar problemas" no fim.

## Requisitos
- **GeneXus 17 e/ou 18** instalado.
- **Windows PowerShell** (o instalador roda como Administrador).
- **Claude Code** (CLI) para conversar com a KB.

## Instalação (3 passos)
1. **Obtenha os arquivos**: clone este repositório, ou baixe o ZIP pelo botão verde **Code → Download ZIP**
   e extraia (mantenha `install.ps1` ao lado da pasta `Packages\`).
   ```powershell
   git clone https://github.com/franciscorizzo/GxObjGen-install
   ```
2. **Feche o GeneXus** e abra um **PowerShell como Administrador** na pasta do projeto:
   ```powershell
   powershell -ExecutionPolicy Bypass -File install.ps1
   ```
   O script detecta o GeneXus 17 e/ou 18 instalado, copia a DLL e registra a extensão.
   (Para uma versão específica: `... -File install.ps1 -GxDir "C:\Program Files (x86)\GeneXus\GeneXus18"`.)
3. **Registre o MCP no Claude Code** (uma vez):
   ```
   claude mcp add --transport http genexus http://127.0.0.1:8780/mcp
   ```

## Uso
1. Abra o **GeneXus** e a **sua KB**. A extensão sobe o servidor MCP automaticamente.
2. No **Claude Code**, comece perguntando algo como *"liste as KBs conectadas"* — a IA usa a tool
   `gx_targets`. Com várias KBs abertas, cada tool aceita o parâmetro `kb` (o slug da KB); com uma
   só, é opcional. O endpoint `:8780` é um **gateway**: 1 porta para todas as KBs abertas.

## Referência para o Claude Code (recomendado)
Este repositório também inclui material que ensina o Claude Code a **usar bem** o MCP — rode o Claude
Code **dentro da pasta clonada** para ele carregar automaticamente:
- **`CLAUDE.md`** — regras de ouro (começar por `gx_whoami`, preferir `gx_search_indexed`, respeitar
  read-only, validar com `gx_specify`, nunca reportar "ok" sem checar).
- **`.claude/skills/gxobjgen/`** — a skill com o fluxo completo, pré-requisitos e gotchas. Para valer
  em qualquer pasta, copie-a para `~/.claude/skills/gxobjgen/`.
- **`docs/tools.md`** — catálogo das ~71 tools por categoria.
- **`GETTING-STARTED.md`** — primeiros passos e troubleshooting (MCP não conecta, read-only, U14…).

## Segurança — leia
- **Somente leitura por padrão** (deny-by-default). A IA pode ler/documentar/analisar, mas **não
  altera** a KB. É o modo seguro para KB de cliente.
- Para **habilitar escrita**, abra o GeneXus com a variável de ambiente **`GXOBJGEN_WRITE=1`**.
  Sem ela, qualquer tool de escrita é bloqueada com aviso.
- Tudo é **loopback** (`127.0.0.1`): nada sai da sua máquina, não há API key, não há upload da KB.

## Novidades desta versão (1.7.0)
> Histórico completo de todas as versões em [`CHANGELOG.md`](CHANGELOG.md).

- **Erro de validação real:** quando uma criação/edição falha, a IA recebe o **motivo exato**
  (ex.: função inexistente, atributo inválido) em vez de um "Validation failed" genérico.
- **Busca indexada (`gx_search_indexed`):** procura no conteúdo da KB usando o **índice do próprio
  IDE** — quase instantânea mesmo em KB grande (o "grep ao vivo" continua disponível para casar a
  linha literal exata).
- **Leitura granular:** dá para ler só um trecho de um objeto (por parte, faixa de linhas, ou a
  vizinhança de um termo) — mais rápido e barato em objetos grandes.

## Reportar problemas
Ao encontrar um bug, mande: **versão** (`gx_whoami` mostra `Extensao GxObjGen: vX.Y.Z`), **GeneXus
17/18**, o que você pediu, e a mensagem de erro. Logs do IDE em `%LOCALAPPDATA%\GeneXus`.
