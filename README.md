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
2. **Feche o GeneXus** e rode o instalador num PowerShell:
   ```powershell
   powershell -ExecutionPolicy Bypass -File install.ps1
   ```
   A instalação precisa de **admin** (escreve em Program Files). Se você rodar de um PowerShell
   comum, o script **se re-lança elevado via UAC** — é só confirmar o prompt; o trabalho continua
   numa janela de administrador (que fica aberta pra você ver o resultado). O script detecta o
   GeneXus 17 e/ou 18, copia a DLL e registra a extensão.
   (Para uma versão específica: `... -File install.ps1 -GxDir "C:\Program Files (x86)\GeneXus\GeneXus18"`.)
3. **Registre o MCP no Claude Code** (uma vez):
   ```
   claude mcp add --transport http genexus http://127.0.0.1:8780/mcp
   ```
   > O **Claude Code do dia a dia NÃO precisa de admin** — a elevação é só para o passo de instalação.
   > Depois, o MCP roda em loopback (`127.0.0.1`) e o Claude Code comum conversa com ele normalmente.

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

## Novidades desta versão (1.11.1)
> Histórico completo de todas as versões em [`CHANGELOG.md`](CHANGELOG.md).

- ⚠️ **HOTFIX crítico (perda de dados)** — `gx_reorganize execute=true` recriava as tabelas e apagava
  os dados; agora faz **reorganização incremental** (ALTER, preserva). **Atualize já.** (`gx_build all`
  já era seguro.) Dica: rode `gx_reorganize execute=false` antes de reorganizar de verdade.
- (1.11.0) **`gx_wwp_add_tree`** — subárvore completa numa instância WorkWithPlus de forma **atômica**
  (valida/salva 1 vez no fim): grid tab de tabela relacionada agora nasce via MCP (issue #7).
- **Scaffold do wizard via `source`** — `{type:"gridTab", source:"Conta"}` ≈ "Add › Grid Tab" do IDE
  (também `gx_wwp_add childType=gridTab source=...`; `attFrom` desambigua a FK).
- Referências (`transaction`/`attribute`/`gxobject`) aceitam `guidTipo-Nome` ou o nome do objeto.
- Recusas de validação do pattern agora trazem o **motivo real** + o XML montado (nada persiste).
- (1.10.0) `gx_diff`, `gx_lint`, call tree descobrível, fix do install.ps1. (1.9.0) Build/run por
  objeto sem BuildAll. (1.8.0) Enum/Domain, Data Selector var-param, `gx_recover`.

## Reportar problemas
Ao encontrar um bug, mande: **versão** (`gx_whoami` mostra `Extensao GxObjGen: vX.Y.Z`), **GeneXus
17/18**, o que você pediu, e a mensagem de erro. Logs do IDE em `%LOCALAPPDATA%\GeneXus`.
