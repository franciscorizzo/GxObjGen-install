# Catálogo de tools do MCP GxObjGen (~71)

Referência legível das tools. A skill `gxobjgen` traz a mesma lista para o Claude Code usar em
runtime (`.claude/skills/gxobjgen/references/tools.md`). Todas chamáveis como `mcp__genexus__<nome>`;
são *deferred* — o Claude carrega o schema com `ToolSearch query="select:mcp__genexus__<nome>"` antes
de chamar. Com várias KBs abertas, passe `kb=<slug>` (veja `gx_targets`).

## Contexto / descoberta (comece aqui)
- `gx_whoami` — KB ativa, modelo, diretório, contagem de objetos, versão da extensão, modo (read-only?).
- `gx_targets` — lista as KBs conectadas ao gateway e seus slugs (para o parâmetro `kb`).
- `gx_conventions` — visão geral por tipo + módulos/pastas (o mapa da KB).
- `gx_overview` — só a contagem de objetos por tipo.
- `gx_list_objects` — lista por tipo e/ou filtro `like` (ls). Sem tipo = todos.
- `gx_search` — busca por trecho do nome, qualquer tipo (grep por nome).
- `gx_search_indexed` — **busca no CÓDIGO via índice full-text (Lucene) do IDE — quase instantânea,
  PREFIRA esta p/ localizar**. Ordena por score; `minScore` corta ruído; `onlyTitles` limita a nomes.
- `gx_search_in_source` — grep no CÓDIGO ao vivo (source/rules/events). Use só p/ a LINHA literal
  exata; em KB grande é lento (varre objeto a objeto).
- `gx_modules` — módulos e pastas. `gx_attributes` — catálogo de atributos. `gx_list_object_types`
  — classes KBObject instanciáveis.

## Criar / atualizar (idempotente)
- `gx_create_or_update_transaction` — atributos; 1º com isKey=true é a chave; FK = mesmo nome de atributo.
- `gx_create_or_update_procedure` — source + rules + `variables` (cria E ATUALIZA: só os campos declarados; tipagem por `type` eDBType OU Data Type do GX por nome ex. `HttpRequest`, `domain`, `basedOnAttribute`, `basedOnObject` p/ SDT/EO; `isCollection`; type desconhecido = erro com a lista).
- `gx_create_or_update_dataprovider` — source (igual procedure).
- `gx_create_or_update_sdt` — itens (type por item).
- `gx_create_or_update_api` — Service Source REST + variables.
- `gx_create_or_update_webpanel` — shell (layout vazio; eventos por edição).
- `gx_create_or_update_menu` — declarativo: options [{description, target, callType}].
- `gx_create_or_update_domain` / `dataselector` / `externalobject` / `query` / `theme` (CSS) /
  `designsystem` / `usercontrol` / `urlrewrite`.
- `gx_create_textobject` — genérico p/ qualquer objeto de source-de-texto sem tool dedicada.
- `gx_create_module` / `gx_create_folder` — organização.

## Validar / reorganizar / compilar / rodar
- `gx_specify` — valida/gera specs de um objeto; devolve erros/avisos do engine. **Use sempre após criar/editar.**
- `gx_reorganize` — `execute=false` analisa (in-process, rápido); `execute=true` cria/altera tabelas (MSBuild, lento). Datastore obrigatório.
- `gx_build` — compila a app (MSBuild `all`, lento; por objeto = in-process rápido). PRÉ-CHECK: reorg pendente → status distinto sem iniciar; `autoReorg=true` roda o reorganize incremental antes. 1 build por vez (guard). `gx_test` — GXtest (MSBuild, lento).
- `gx_run` — executa objeto (Web Panel→browser; Procedure→`capture=true` p/ stdout; precisa IsMain=True). Lento. Mesmo pré-check de reorg/`autoReorg`/guard do gx_build.
- `gx_datastore` — status do datastore + web server/porta (lê model.ini). `gx_kb_check` — consistência da KB (lento).
- `gx_schema` — what=kb|db|compare (XML de schema; compare exige dep que pode faltar). Lento.

## Ler / analisar
- `gx_get_properties` — escalares (Name, Description, flags, IsMain...).
- `gx_get_object_text` — partes de TEXTO (source, rules, conditions, events). Leitura PARCIAL:
  `part`, `fromLine`/`toLine`, `find`+`context` (só a vizinhança de um termo, numerada).
- `gx_read_structure` — conteúdo estrutural tipado (opções de menu, itens de SDT, params de query...).
- `gx_analyze` — **CALL TREE / raio de impacto** (árvore transitiva, indentada). mode: **impact** = *reverse call tree* (quem CHAMA/usa o objeto, transitivo — o que quebra se você mexer; sinônimos: reverse_call_tree, callers) / **hierarchy** = *call tree* (o que o objeto chama, transitivo; sinônimos: call_tree, calls) / data_context / ui_context / lint / summary.
- `gx_dependencies` — usa / usado-por. `gx_doc` — documentação markdown de um objeto.
- `gx_object_version` — versão de um objeto. `gx_history` — delta local desde uma versão.

## Editar / refatorar
- `gx_edit` — edição granular de uma parte de texto (full/append/replace/insert_after). Aceita dryRun/idempotencyKey.
- `gx_refactor` — op=rename (repercute refs) | op=move (muda módulo/pasta).
- `gx_set_property` — propriedade escalar do objeto. `gx_set_part_property` — propriedade de uma parte.
- `gx_add_part_item` — adiciona elemento a uma coleção tipada de uma parte.
- `gx_delete_object` (irreversível) / `gx_delete_cascade` (remove o objeto + dependentes, topológico).

## WorkWithPlus
- `gx_apply_workwithplus` — aplica o pattern WWP a uma Transaction (gera CRUD web). `gx_apply_pattern` — pattern genérico.
- `gx_wwp_read` (árvore XML) · `gx_wwp_get` (nó navegável) · `gx_wwp_set` (setting) · `gx_wwp_add` / `gx_wwp_remove` (nós).
- `gx_wwp_add_tree` — subárvore completa ATÔMICA (valida/salva 1 vez no fim): p/ estruturas que só
  são válidas completas, ex. **grid tab de tabela relacionada**. Com `source` (objeto-fonte) faz o
  scaffold: `{type:"gridTab", source:"Conta", props:{name,code,wcname}, children:[{type:
  "table", children:[{type:"grid", children:[{type:"gridAttribute", props:{attribute:"..."}}]}]}]}`.
  O `source` inicializa a aba e materializa o `<transaction>` (`transaction`+`level 'root:<Trn>'`);
  o `grid` + colunas vêm SEMPRE do `children`. **Tabela neta** (transação não-filha-direta, FK
  direta): funciona com `source`, ou na árvore manual com `{type:"transaction", props:{transaction:
  "<Trn>", level:"root:<Trn>"}}` (v1.11.2+). Prop inexistente → erro com os atributos válidos.
  `source`/`attFrom` também no `gx_wwp_add`. Referências aceitam `guidTipo-Nome` (do `gx_wwp_read`) ou o nome.

## Layout (WebForm)
- `gx_layout_tree` — lê a árvore de controles (XML). `gx_layout_set` — edita prop de um controle
  (NOTA: escrita visual nem sempre persiste; WWP é o caminho preferido p/ layout).

## Portabilidade / versões / orquestração
- `gx_export` / `gx_import` — .xpz (MSBuild, lento). `import preview=true` = dryRun.
- `gx_version` — action: get|create|set|revert|merge (KB local; MSBuild, lento).
- `gx_recipe` — orquestra fluxos. `scaffold_rest_api` cria TRN+SDT+DP+PROC+API numa chamada.
- `gx_msbuild` — ESCAPE HATCH: roda qualquer MSBuild task do GeneXus por nome+attrs (raro; só p/ tasks sem tool dedicada).

## Introspecção (avançado)
- `gx_object_api` — dump de construtores/propriedades/métodos de um tipo (KBObject ou classe avulsa).
- `gx_object_parts` — partes de um objeto e quais têm Source gravável. `gx_prop_inspect` /
  `gx_var_inspect` — dump de uma propriedade/variável (usado p/ decifrar como tipar/escrever).

## Status / meta
- `gx_gxserver` — status Team Dev (KB local não tem). `gx_gam` — status GAM + segurança por objeto.
- `gx_telemetry` — uptime + contagem de chamadas por tool.
