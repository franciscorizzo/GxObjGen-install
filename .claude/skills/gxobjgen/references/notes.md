# GxObjGen — arquitetura, gotchas e limitações conhecidas

## Arquitetura (2 camadas)
- **In-process** (dentro do `genexus.exe`, via Extensibility API): tudo de **modelo/análise** —
  criar/editar objetos, specify, get/read, analyze, reorg-**análise**. Rápido, instantâneo.
- **MSBuild headless** (processo filho, tasks `Genexus.MsBuild.Tasks`): a **execução** real —
  build/reorg-execução/run/test/export/import/version/schema. As tools `[lento: ...]` spawnam o
  MSBuild e capturam o log. **NÃO precisa fechar o IDE** (a KB SQL não tem lock exclusivo; basta o
  IDE estar ocioso). É o que o `gx_build`/`gx_reorganize(execute=true)` usam — sem diálogo.

## Gotchas operacionais
- **Reconnect após atualizar a extensão:** ao reinstalar uma versão nova, o servidor reinicia mas o
  cliente MCP mantém o tools/list antigo. As tools novas só aparecem após `/mcp` → reconectar `genexus`.
- **Latência:** tools MSBuild levam ~30-150s. Use timeoutSec adequado; não chame à toa.
- **Procedure executável:** para `gx_run` rodar uma Procedure direto, ela precisa `IsMain=True`
  (set via `gx_set_property`). Use `msg(&var, status)` p/ saída visível e `gx_run capture=true` p/
  capturar o stdout.
- **Encoding:** o transporte JSON/terminal pode corromper acentos em textos longos. No log de build é
  só cosmético.
- **Erro de validação:** quando um create/edit falha, a resposta traz o MOTIVO REAL do engine (ex.:
  função inexistente, atributo inválido) — leia a mensagem, não assuma "ok".

## Limitações conhecidas
- **`gx_schema compare`**: a task `CompareSchemas` exige `Mvp.Xml.Common 0.18.2.0`, ausente em
  algumas instalações. kb/db funcionam; compare gera os 2 schemas e reporta a limitação. Dep do produto.
- **`gx_layout_set`** (escrita visual de WebForm): o designer regenera de um modelo interno; a edição
  via layout **nem sempre persiste**. Para layout, use WorkWithPlus.
- **GXserver/commit/update** (`gx_gxserver`): exigem KB sob GeneXus Server; em KB local só há status.
  `gx_version` (frozen/dev) funciona em KB local.
- **API REST + GAM:** APIs geradas ficam protegidas por GAM OAuth2 (HTTP 401 sem token). Obter token
  exige um OAuth Client registrado no GAM.

## Modo READ-ONLY (padrão seguro)
O MCP é **read-only por padrão** (deny-by-default): só as ~31 tools de leitura/análise passam;
create/update/delete/set/edit/refactor/apply/import/build/run/test/reorganize-execute/msbuild são
BLOQUEADAS (retorno com mensagem). Para **habilitar escrita**, o usuário reabre o GeneXus com a
variável de ambiente **`GXOBJGEN_WRITE=1`** — o switch está FORA do alcance da IA (não há tool p/
ligar). O estado aparece em `gx_whoami` (`Modo: ...`) e no banner do `instructions`. Ideal: manter
read-only ao inspecionar/documentar uma KB de cliente, e só habilitar escrita quando for de fato alterar.
