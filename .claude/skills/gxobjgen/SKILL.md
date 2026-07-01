---
name: gxobjgen
description: Criar, editar, validar, reorganizar, compilar e executar objetos de uma Knowledge Base GeneXus (17 ou 18) ABERTA no IDE, via o MCP GxObjGen (tools mcp__genexus__gx_*). Use quando o usuario quiser inspecionar, documentar, construir ou alterar uma aplicacao GeneXus (Transactions, Procedures, SDTs, Data Providers, Web Panels, APIs REST, Menus, Domains, WorkWithPlus), ou rodar reorg/build/run.
---

# gxobjgen — Operar uma KB GeneXus via MCP

O **GxObjGen** e uma extensao que roda DENTRO do `genexus.exe` e expoe um servidor MCP
(gateway em `http://127.0.0.1:8780/mcp`) para ler/criar/editar/validar/rodar objetos da Knowledge
Base **aberta no IDE**. As tools aparecem no Claude Code como **`mcp__genexus__gx_*`**.

## Pre-requisitos (checar ANTES de qualquer coisa)
1. **GeneXus aberto com a KB-alvo.** Confirme com `mcp__genexus__gx_whoami` (retorna KB/Location/
   modelo/versao/modo). Com varias KBs abertas, `mcp__genexus__gx_targets` lista os slugs e cada tool
   aceita o parametro `kb` (o slug); com uma so KB, `kb` e opcional.
2. **READ-ONLY por padrao (secure by default).** O MCP so LE por padrao — toda escrita (create/update/
   delete/set/edit/build/run/reorg-execute/import) e BLOQUEADA. O `gx_whoami` mostra `Modo:`. Se for
   escrever e estiver READ-ONLY, AVISE o usuario: ele precisa reabrir o GeneXus com a variavel de
   ambiente **`GXOBJGEN_WRITE=1`** (so ele pode habilitar; a IA nao). Para apenas ler/documentar, o
   default ja basta.
3. **Tools sao "deferred"** no Claude Code: aparecem por nome, mas o schema so carrega via
   **ToolSearch**. Antes de chamar uma tool nova:
   `ToolSearch query="select:mcp__genexus__gx_whoami,mcp__genexus__gx_conventions"` (liste as que vai usar).
4. **Se o servidor foi reiniciado/atualizado** e as tools novas nao aparecem ou dao schema antigo:
   rode **`/mcp`** e reconecte `genexus` (o cliente nao re-busca o tools/list sozinho).

## Por onde comecar numa sessao nova
1. `gx_whoami` — confirma a KB ativa, o modo (read-only?) e o contexto.
2. `gx_conventions` — visao geral por tipo de objeto + modulos/pastas (o "mapa" da KB).
3. Achar objetos: `gx_list_objects` (por tipo) ou `gx_search` (por nome, cross-type) ou
   **`gx_search_indexed`** (busca no CODIGO/conteudo via indice full-text do IDE — ~0,1-0,4s mesmo em
   KB grande; PREFIRA esta p/ localizar). `gx_search_in_source` (grep ao vivo) so quando precisar da
   LINHA literal exata — em KB grande ele varre objeto a objeto e pode levar 20s+/dar parcial (o
   preview do indice vem tokenizado: minusculo/sem acento). Dica: `minScore=0.1` corta ruido.
> O proprio MCP tambem devolve um guia no handshake `initialize` (campo instructions).

## Fluxo de criacao (o caminho feliz)
1. **Criar/atualizar** com `gx_create_or_update_*` (idempotente — re-chamar atualiza):
   transaction, procedure, sdt, dataprovider, api, webpanel, menu, domain, dataselector,
   externalobject, query, theme, designsystem, usercontrol, urlrewrite. (Para tipos sem tool
   dedicada: `gx_create_textobject`.)
2. **Validar** com `gx_specify` — devolve o feedback REAL do engine (erros/avisos). SEMPRE leia.
3. **CRUD web**: `gx_apply_workwithplus` numa Transaction gera Web Panels/filtros.
4. **Menu**: `gx_create_or_update_menu` liga as telas.
5. **API REST completa numa chamada**: `gx_recipe action=run recipe=scaffold_rest_api` cria a
   cadeia Transaction -> SDT -> Data Provider -> Procedure -> API.

## Leitura eficiente (economiza tokens em objeto grande)
`gx_get_object_text` aceita leitura PARCIAL: `part` (so uma parte, ex.: Rules/Source/Events),
`fromLine`/`toLine` (janela) e **`find`+`context`** (so a vizinhanca de cada ocorrencia, numerada,
com `>` na linha que casa — ideal p/ achar a ANCORA do `gx_edit` sem ler o objeto todo). Depois use
`gx_edit op=replace` (anchor->text) para mudar so o trecho, sem reenviar o objeto inteiro.

## Variaveis tipadas (importante)
Em procedures/APIs que retornam SDT ou usam External Objects (ex.: GAM), tipe as variaveis
**explicitamente** via `basedOnObject` (nao confie na auto-tipagem). Vale para SDT
(`basedOnObject:"MeuSDT"`, `isCollection:true`) e External Object (`basedOnObject:"GeneXusSecurity.GAMUser"`).

## Banco / build / run (LENTOS — MSBuild headless, ~30-150s, IDE fica aberto, SEM dialogo)
- `gx_reorganize(execute=false)` = analisa (rapido, in-process); **`execute=true`** = cria/altera
  tabelas (DDL real). Exige datastore configurado.
- `gx_build` = compila a app. `gx_run` = executa um objeto (Web Panel abre no browser; Procedure
  roda — use `capture=true` p/ o stdout, ex.: `msg(&x, status)`; precisa `IsMain=True`).
- `gx_test` = GXtest. `gx_export`/`gx_import` = .xpz (portabilidade/backup/git).

## Seguranca / honestidade
- Toda mutacao aceita **`dryRun`** (preview sem persistir) e **`idempotencyKey`** (anti-duplicidade).
- As respostas trazem o feedback do engine — NUNCA reporte "ok" sem checar o `gx_specify`/log.
- `gx_delete_object`/`gx_delete_cascade` sao IRREVERSIVEIS — confirme antes.

## Catalogo completo
Todas as ~71 tools por categoria, com quando usar cada uma: `references/tools.md`.
Arquitetura, gotchas e limitacoes conhecidas: `references/notes.md`.
