# Release notes — GxObjGen

Versionamento SemVer. A versão instalada aparece em `gx_whoami` (`Extensao GxObjGen: vX.Y.Z`).

## 1.11.2 — atual (beta)
WWP: grid tab de **tabela "neta"** (transação que NÃO é filha direta da root, mas tem FK direta —
ex. chave `EmpresaCNPJ+Ano+Mes+Plano` numa `WorkWithPlusEmpresa`) agora funciona — obrigado de novo,
@yurecamilo! (feedback na issue #7).
- **`level`/`defaultLevel` (e qualquer prop de tipo custom/enum/bool) agora persistem** — as props
  passaram a ser gravadas pelo mesmo caminho da desserialização do pattern (TypeConverter do
  atributo). Antes, o valor era aceito em memória e **descartado em silêncio** na serialização —
  era por isso que o `<transaction>` saía sem `level` e a validação recusava sem dizer o motivo.
- **Scaffold via `source` materializa o `<transaction>` explícito** (`transaction` + `level`
  `root:<Trn>` + defaults), o mesmo shape que o wizard "Add › Grid Tab" do IDE grava. P/ tabela
  neta é obrigatório — os defaults do WWP só resolvem transação filha direta. (Na árvore manual,
  passe `{type:"transaction", props:{transaction:"<Trn>", level:"root:<Trn>"}}`.)
- **Prop inexistente agora é recusada na hora** com a lista `nome(tipo)` dos atributos válidos do
  nó (antes um typo era engolido em silêncio e você só via uma recusa genérica no fim).
- **Referências por nome simples com resolução tipada** — `transaction:"Conta"` resolve pela
  Transaction (não pela Table homônima); vale p/ todos os `reference(...)` (attribute, gxobject...).
- Correção na doc das tools: o `source` **não** gera grid/colunas (nunca gerou) — o `grid` + colunas
  vêm no `children` do payload, como no exemplo.

## 1.11.1 (beta) — ⚠️ HOTFIX CRÍTICO (perda de dados)
**Atualize já.** Versões anteriores: `gx_reorganize` com `execute=true` executava um **Create Tables**
(recria as tabelas e **apaga todos os dados**) em vez de um **Reorganize** incremental (ALTER, que
preserva os dados). Ao adicionar um atributo e reorganizar, os registros eram perdidos.
- Corrigido: `gx_reorganize execute=true` agora faz **reorganização incremental** (ALTER/CREATE
  conforme o diff, **preserva os dados**). Validado com teste de perda de dados (dado sobrevive ao
  add-attribute + reorg).
- `gx_build action=all` foi auditado e **já era** incremental (seguro).
- Recomendação geral: rode **`gx_reorganize execute=false`** (análise) antes de qualquer reorg real.

## 1.11.0 (beta)
Grid tab relacionada em WorkWithPlus via MCP (obrigado, @yurecamilo! — issue #7).
- **`gx_wwp_add_tree`** — adiciona uma **subárvore completa** a uma instância WorkWithPlus de forma
  **atômica**: monta todos os nós em memória e valida/salva **uma única vez** no fim. Estruturas que
  só são válidas completas (ex.: grid tab de tabela relacionada) agora nascem via MCP — o
  `gx_wwp_add` nó a nó era rejeitado pela validação a cada save.
- **Scaffold do wizard via `source`** — `{type:"gridTab", source:"Conta"}` no `gx_wwp_add_tree` (ou
  `gx_wwp_add childType=gridTab source=Conta`) equivale ao "Add › Grid Tab" do IDE: gera a aba a
  partir da transação relacionada. `attFrom` desambigua qual FK usar. Complete com o `grid` e as
  colunas na mesma chamada (a validação exige um main Grid e o `wcname`/ComponentName).
- **Referências em props** — `transaction`/`attribute`/`gxobject` aceitam `guidTipo-Nome` (como
  aparece no `gx_wwp_read`) ou o nome do objeto (também em `gx_wwp_set`/`gx_wwp_add`).
- **Motivo REAL nas recusas de validação do pattern** — a mensagem traz os erros do WorkWithPlus
  (ex.: "A value is required for the property 'ComponentName'") e o XML do que foi montado; em
  recusa **nada persiste** (rollback automático).

## 1.10.0
Onda a partir do feedback da comunidade (obrigado, Ana!).
- **`gx_diff`** — compara o texto de dois objetos (diff alinhado, `-`/`+`); ótimo p/ ver o que muda
  entre implementações similares.
- **`gx_lint`** — roda o specify em **lote** e lista só os **erros/avisos** reais (ex.: `spc0038`),
  escopado por `type`/`like`, com teto. Útil antes de um build.
- **Call tree mais fácil de achar** — `gx_analyze mode=impact` (quem chama, transitivo = raio de
  impacto) e `mode=hierarchy` (o que chama) agora aceitam sinônimos `reverse_call_tree`/`call_tree`/
  `callers`, e a doc deixa isso explícito.
- **Fix instalador** — `install.ps1` reescrito em ASCII + BOM (não quebra mais no PowerShell 5.1).

## 1.9.0
Família de build/run por objeto (in-process, como o F5) — a partir de feedback da comunidade (issue #2).
- **Build de 1 objeto sem BuildAll.** `gx_build action=object` compila só o objeto (in-process, ~como o
  F5; muito mais rápido que o BuildAll). Também `action=rebuild`, `buildWithThisOnly`, `rebuildAll`.
  `action=all` (default) segue o build completo via MSBuild.
- **Modos de run.** `gx_run mode=runWithoutBuilding` (roda sem compilar) e `mode=runWithThisOnly`.
- **`gx_run capture=true`** agora **compila o objeto automaticamente** (sem BuildAll) quando o exe não
  existe, e então executa/captura.
- Observação: capturar o `msg()` de uma Procedure em apps **.NET 8** ainda não sai pelo `capture`
  (o executável não escreve no stdout nesse target) — em investigação.

## 1.8.0
Cobertura de modelagem + recuperação de deletados.
- **Domínio enumerado.** `gx_create_or_update_domain` aceita `enumValues` (lista de valores fixos:
  `{name, value, description}`) — cria um Domain enumerado.
- **Atributo tipado por Domain.** `gx_create_or_update_transaction` aceita `domain` por atributo:
  o atributo herda tipo/tamanho do Domain (inclusive os valores, se enumerado).
- **Data Selector com parâmetro-variável.** `gx_create_or_update_dataselector` aceita
  `parameters[].variable` (tipada por `domain`, `basedOnAttribute` ou `type`).
- **`gx_recover` — recuperação de objetos deletados.** `action=list` lista os objetos deletados
  recuperáveis (via histórico da KB). `action=recover` orienta a recuperação (que roda no IDE via
  `Ctrl+Shift+R` — a operação exige o contexto interativo do IDE).

## 1.7.0
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
