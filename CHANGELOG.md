# Release notes — GxObjGen

Versionamento SemVer. A versão instalada aparece em `gx_whoami` (`Extensao GxObjGen: vX.Y.Z`).

## 1.7.0 — atual (beta)
Onda de robustez e eficiência.
- **Erro de validação real.** Quando uma criação/edição falha, a IA recebe o **motivo exato** do
  engine (ex.: função inexistente, atributo inválido) em vez de um "Validation failed" genérico.
- **`gx_search_indexed` — busca full-text pelo índice do IDE.** Localiza código/objetos em ~0,1–0,4s
  mesmo em KB grande (dezenas a centenas de vezes mais rápido que a varredura). Ordena por relevância;
  `minScore` corta ruído.
- **`gx_search_in_source` mais robusto** em KB grande: pula tipos sem código e tem teto de tempo
  (retorna parcial com aviso em vez de travar).
- **Leitura granular** no `gx_get_object_text`: ler só uma parte, uma faixa de linhas, ou a vizinhança
  de um termo (`find`+`context`) — mais rápido e barato em objetos grandes.

## 1.6.0
- `gx_whoami` (contexto da KB/versão/modo), `gx_doc` (documentação markdown de um objeto),
  `gx_apply_pattern` (patterns genéricos), `gx_prop_inspect`/`gx_var_inspect` (introspecção).
- Variáveis tipadas explicitamente (SDT e External Object) via `basedOnObject`.

## 1.5.0
- Manipulação de instâncias **WorkWithPlus**: `gx_wwp_read`/`_get`/`_set` (árvore do pattern via XPath;
  settings como atributos).

## 1.4.0
- `gx_read_structure`: leitor estrutural genérico (conteúdo tipado de menu/SDT/query/…).

## 1.3.0
- `gx_create_or_update_theme`: Theme declarativo via CSS.

## 1.2.0
- Camada declarativa por tipo: `gx_create_or_update_menu` / `_externalobject` / `_query` /
  `_dataselector` — você descreve a intenção, a tool cuida de parts/coleções/elementos.

## 1.1.0
- `gx_delete_cascade`, variante WorkWithPlus, introspecção do SDK (`gx_list_object_types`,
  `gx_object_parts`, `gx_object_api`, `gx_create_textobject`), `gx_set_part_property`,
  `gx_add_part_item`, autenticação opcional do MCP.

## 1.0.0
- Primeira versão: leitura e escrita de objetos textuais e estruturais básicos (Transactions,
  Procedures, SDTs, Data Providers, Web Panels, Domains…) via o servidor MCP na KB aberta.
