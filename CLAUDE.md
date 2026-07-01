# Operar uma KB GeneXus via o MCP GxObjGen

Você tem acesso a um servidor MCP chamado **genexus** (gateway `http://127.0.0.1:8780/mcp`) que
opera a **Knowledge Base GeneXus aberta no IDE**. As tools aparecem como `mcp__genexus__gx_*`.
Há uma skill **`gxobjgen`** com o fluxo completo e o catálogo — use-a.

## Regras de ouro
1. **Comece sempre por `gx_whoami`** — confirma qual KB está ativa, a versão e o **modo**
   (read-only?). Com várias KBs abertas, use `gx_targets` e passe `kb=<slug>` nas tools.
2. **Tools são *deferred*:** carregue o schema com `ToolSearch query="select:mcp__genexus__gx_whoami,..."`
   antes de chamar. Se tools novas não aparecerem após uma atualização, peça ao usuário para rodar
   `/mcp` e reconectar `genexus`.
3. **Para LOCALIZAR código/objetos, prefira `gx_search_indexed`** (índice full-text, quase
   instantâneo). Use `gx_search_in_source` só para casar a linha literal exata.
4. **Leia objetos grandes de forma parcial:** `gx_get_object_text` com `find`+`context` (só a
   vizinhança) e depois `gx_edit op=replace` (anchor→text) — não releia nem reescreva o objeto inteiro.
5. **READ-ONLY por padrão.** Se você precisar escrever e o modo estiver read-only, **não tente
   contornar** — avise o usuário que ele precisa reabrir o GeneXus com `GXOBJGEN_WRITE=1` (só ele
   pode habilitar).
6. **Depois de criar/editar, valide com `gx_specify`** e leia o retorno do engine. **Nunca reporte
   "ok" sem checar** — a resposta traz erros/avisos reais.
7. **Prefira `dryRun`** em mutações quando estiver explorando; toda mutação aceita `dryRun` e
   `idempotencyKey`.
8. **`gx_delete_object`/`gx_delete_cascade` são irreversíveis** — confirme com o usuário antes.

## Onde olhar
- Fluxo, pré-requisitos e gotchas: skill **`gxobjgen`** (`.claude/skills/gxobjgen/SKILL.md`).
- Catálogo das ~71 tools: `docs/tools.md`.
- Primeiros passos e problemas comuns: `GETTING-STARTED.md`.
