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

## Reportar bug ou sugestão (você pode abrir a issue pelo usuário)
Quando o usuário pedir para **reportar um bug** ou **enviar uma sugestão** sobre o GxObjGen:
1. **Colete o contexto** antes de escrever: rode `gx_whoami` (versão da extensão + KB + modo) e
   pergunte a versão do GeneXus (17/18 e upgrade) se não for óbvia. Para bug, capture o passo e a
   mensagem de erro exata.
2. **Abra a issue** no repositório `franciscorizzo/GxObjGen-install` via o GitHub CLI (peça
   confirmação do texto antes de enviar):
   ```bash
   gh issue create --repo franciscorizzo/GxObjGen-install \
     --title "<resumo curto>" \
     --label bug \            # use "enhancement" para sugestão
     --body "<versão GxObjGen, GeneXus 17/18+upgrade, o que fez, esperado vs. ocorrido, erro>"
   ```
3. **Se o `gh` não estiver instalado/autenticado**, não trave: gere um **link de nova issue já
   preenchido** para o usuário abrir no navegador (ele precisa estar logado no GitHub com acesso ao
   repo), no formato:
   `https://github.com/franciscorizzo/GxObjGen-install/issues/new?labels=bug&title=<url-encoded>&body=<url-encoded>`
4. Depois de criar, **devolva o link da issue** ao usuário.

Nunca invente versão/erro — use o que o `gx_whoami` e o usuário fornecerem.

## Compartilhar um aprendizado (realimentar as referências)
Ao descobrir um padrão útil, um gotcha ou uma receita **genérica** sobre o GxObjGen/GeneXus (algo que
ajudaria qualquer usuário, não só esta KB), você pode registrá-lo para virar referência:
1. **SANITIZE — regra inegociável.** O texto deve ser **genérico sobre a ferramenta**. **NUNCA**
   inclua nomes de objetos, atributos, lógica de negócio, dados ou segredos **desta KB** — isso é
   confidencial e não pode vazar para outros usuários. Descreva o padrão de forma abstrata
   ("ao criar Procedure que retorna SDT…"), não o caso concreto do cliente.
2. **Peça confirmação do usuário** com o texto já sanitizado antes de enviar.
3. **Abra como issue de conhecimento:**
   ```bash
   gh issue create --repo franciscorizzo/GxObjGen-install --label knowledge \
     --title "<dica curta>" --body "<aprendizado genérico + tool/contexto + como aplicar>"
   ```
   (sem `gh`, gere o link `.../issues/new?labels=knowledge&title=…&body=…`).
Esses aprendizados são triados pelo mantenedor e promovidos para a skill/`docs` nas próximas versões.
