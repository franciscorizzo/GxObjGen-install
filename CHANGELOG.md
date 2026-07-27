# Release notes — GxObjGen

Versionamento SemVer. A versão instalada aparece em `gx_whoami` (`Extensao GxObjGen: vX.Y.Z`).

## 1.12.0 — atual (beta)
**Suporte ao GeneXus 15** (antes só 17/18). Verificado em runtime: as 73 tools disponíveis no
GX15 operam de ponta a ponta (load → leitura → CRUD → specify → delete → MSBuild headless).

- **Build por-versão**: `/p:TargetGx=15` aponta o `GxDir` para o GeneXus15 e define a constante
  `GX15`. O `PackageCompatibility` é **condicional** — `123130` no GX15, `143920` no 17/18. São
  números de build distintos que o host exige; por isso o **GX15 usa um DLL próprio** (17 e 18
  seguem compartilhando o mesmo DLL).
- **Shim de API** (`Gx15Compat.cs`): `KBObject.QN()`/`.TN()` mapeiam `QualifiedNameString`/
  `TypeName` (ausentes na API mais antiga do GX15) para `QualifiedName.ToString()`/
  `TypeDescriptor.Name`. Inerte no 17/18 (usa os membros reais).
- **4 tools ocultas no GX15** (objetos que não existem nessa versão): `gx_create_or_update_`
  **designsystem** / **api** / **urlrewrite** / **usercontrol** — somem do catálogo via
  `#if !GX15`. `gx_create_or_update_theme` **permanece** (Theme existe no GX15).
- **`gx_search_indexed` no GX15**: fallback `new SearchService()` quando o host não expõe o
  singleton estático `Instance` (caso do GX15) — a busca full-text volta a funcionar.
- **MSBuild headless usa a instalação CORRETA do GeneXus** (reorg/build/export/import/schema/…):
  antes hardcodava `GeneXus18` — no GX15 a reorg rodava mas não limpava a pendência (geradores
  errados), e no GX17 usava tooling do 18. Agora resolve o diretório do **`genexus.exe` do processo
  atual**. No GX15 há ainda dois detalhes tratados: o executor da reorg é `gxnet\GXExec.exe` (fora
  do PATH por padrão) — adicionado ao PATH do processo headless; e o build **in-process**
  (`GenexusBLServices`) não existe no GX15 — cai automaticamente para o MSBuild. Verificado no GX15:
  **reorganize execute e compilação (BuildObject) completam com 0 erros**.
- **`install.ps1` detecta o GeneXus 15** e instala a variante certa pela versão MAJOR do
  `genexus.exe` (`Packages\gx15\` para o GX15; `Packages\` para 17/18).
- **Painel do IDE — header auto-atualiza** (todas as versões): o cabeçalho `MCP :porta | KB: … |
  Modo: …` ficava no estado inicial (`MCP :? | KB: (nenhuma)`) até um clique manual em "Status",
  porque não havia gancho no evento de KB-ligada/MCP-rebindado. Agora ele se recalcula a cada linha
  de log (idempotente) e mostra a porta/KB corretas assim que há atividade.
- **Gateway 8780 — robustez contra backends "zumbis"** (issue #20): abrir/fechar KBs podia deixar
  um socket de LISTEN **herdado** pelo gateway (backend de um GeneXus morto que aceita a conexão mas
  nunca responde), travando o scan de descoberta e derrubando o `tools/list`. Fix em duas frentes:
  (1) **backend** marca o socket como **não-herdável** (`SetHandleInformation`), então o gateway não
  o herda e backend morto = porta fechada = refused imediato; (2) **gateway** descobre as KBs
  **sob demanda com TTL** (não re-varre a cada request) e checa os backends já conhecidos por
  **TCP-connect silencioso** (não repete `gx_whoami`, então para de poluir o log do IDE) — o
  `gx_whoami` só roda para KBs novas; zumbis de crash/versão antiga entram numa blacklist curta.
  Verificado: com um zumbi na faixa, `tools/list` responde em ~0,5s (antes: timeout); e o gateway
  não faz mais polling de `gx_whoami` no backend quando ocioso.
- **`gx_status` — health/BUSY instantâneo** (issue #19): novo endpoint que responde na hora **mesmo
  com uma operação longa em andamento** (não passa pela fila da thread de UI). Diz se está OCIOSO ou
  OCUPADO (qual op, há quanto tempo), uptime, porta, KB e modo — o cliente passa a **distinguir
  "servidor processando" de "servidor caído"** e decide aguardar vs. abortar (fim do retry às cegas).
  `gx_specify` agora avisa na descrição que serializa e aponta o `gx_status`. Verificado: durante um
  reorg em andamento, `gx_status` respondeu em **0,07s** com o estado correto.
- **Docs: bloco de `permissions` pronto** (issue #17) no GETTING-STARTED — deixa o prefixo correto
  (`mcp__genexus__`, não `mcp__GxObjGen__`) explícito; auto-aprova leituras, pergunta nas escritas,
  bloqueia `gx_delete_cascade` e `gx_msbuild`.
- **Nota**: as tools `gx_wwp_*` exigem **WorkWithPlus instalado** na KB (não é limitação do GX15).

## 1.11.5 (beta)
Correção da issue #15 (obrigado, @bpessoni!) — gateway 8780 falhava em SILÊNCIO sem Python.

- **Causa raiz documentada**: o gateway multi-KB (porta 8780) é um script Python que a extensão
  lança — **Python no PATH é pré-requisito dele** (e não estava documentado). Sem Python, o
  gateway não subia e nada aparecia no IDE; a doc cravava 8780 → "connection refused" parecia
  MCP quebrado. O servidor por-KB (porta determinística, faixa 8787–8986) sempre funcionou.
- **Status do gateway SEMPRE no Output do IDE** (seção "GxObjGen MCP"): `ATIVO` / `iniciado` /
  `NAO INICIADO: <motivo>` (ex.: Python ausente) — com o workaround por-KB na própria mensagem.
- **Mensagem por-KB ganhou a linha do gateway** (estado real + onde ver o motivo).
- **`install.ps1` checa Python** ao final: verde (gateway ok) ou amarelo (como conectar sem ele
  + como habilitar: `winget install Python.Python.3.12`).
- **Doc alinhada**: README "duas formas de conectar"; GETTING-STARTED com o troubleshooting
  exato do sintoma ("connection refused na 8780 mas o IDE mostrou outra porta" → não reinstale).

## 1.11.4 (beta)
Onda 3 do feedback da comunidade (issues #13 e #14 — obrigado de novo, @yurecamilo! — e a
sugestão do texto do `gx_gxserver` na #12).

**Variáveis tipadas em Web Panel / qualquer objeto (issue #13):**
- **`variables[]` no `gx_create_or_update_webpanel`** — mesmo payload do procedure/API
  (`type` | `domain` | `basedOnAttribute` | `basedOnObject`, `isCollection`, Data Types do GX
  por nome; cria novas e atualiza existentes só nos campos declarados). Tipando as vars dos
  eventos, o `gx_specify` fecha limpo — sem `spc0047 not defined` / `spc0023 wrong type`.
- **`gx_set_variables` (nova tool)** — tipa/atualiza variáveis de **qualquer** objeto com
  VariablesPart (WebPanel, WebComponent, Transaction, API, Procedure...). Paridade de escrita
  com o `gx_var_inspect`. `type` é opcional (desambigua homônimos).
- Nota: nomes de variáveis *standard* do GX (`Msg`, `Today`, `Pgmname`...) são reservados —
  a criação é recusada na hora com o motivo.

**`gx_run` — E2E de Procedure com efeitos reais (issue #14):**
- **`capture=true` é o run HEADLESS real** (agora documentado): compila se preciso (BuildOne)
  e roda o **exe gerado** como processo filho — `&HttpClient` faz a requisição de verdade,
  `New`/update gravam no banco de verdade, e o stdout/stderr vem na resposta com exit code.
  Validado com listener local (POST recebido com o body exato) + row lido por um segundo exe.
- **`args` no capture** — os parâmetros do `parm()` do proc main viram linha de comando do exe.
- **`msg()` só captura na forma `msg(&x, status)`** — sem `status`, vira diálogo modal no exe
  e pendura até o timeout (agora avisado na descrição da tool).
- Os modos SEM capture (in-process, F5 do IDE) agora avisam no retorno: eles **não comprovam**
  a execução/efeitos do programa — resposta vazia não significa "não executou".

**`gx_gxserver` (parcial da issue #12):**
- O stub não afirma mais "esta KB é LOCAL" — reporta que a conexão Team Dev não é
  inspecionável por este build, que a KB **pode** estar sob GeneXus Server, e descreve o
  sintoma do lock (diálogo atrás do IDE pendurando o Save) + workaround (check-out manual).

## 1.11.3 (beta)
Onda 2 do feedback da comunidade (issues #9, #10 e #11 — obrigado de novo, @yurecamilo!).

**`variables[]` v2 (procedure/API):**
- **Atualiza variável existente** — re-rodar com `type`/`length`/`decimals`/`isCollection`
  diferentes agora APLICA a mudança e reporta `N nova(s), M atualizada(s) [&Var: antes -> depois]`.
  (Era o bug do "type GUID aceito e virou Character(40)": a var placeholder já existia e o re-run
  pulava em silêncio.) Só os campos declarados são tocados — payload só com `name` não clobba nada.
- **`domain` e `basedOnAttribute`** — tipar variável por Domain (inclusive enumerado) ou "based on"
  um atributo (herda tipo/tamanho), como já existia no Data Selector.
- **Data Types do GX por nome** — `type:"HttpRequest"` (e demais tipos do combo do IDE) agora
  funciona de verdade (mesmo parser do IDE). `&HttpRequest.GetHeader(...)` compila.
- **Type desconhecido = erro na hora** com a lista dos tipos aceitos (nada de virar Character
  em silêncio).
- `gx_var_inspect` aceita qualquer objeto com variáveis (WebPanel, WebComponent...), não só Procedure.

**`gx_build` / `gx_run`:**
- **Pré-check de reorganização pendente** — se um build/run fosse abrir o modal de reorg no IDE
  (a chamada pendurava até um timeout ambíguo), agora ele NEM INICIA e devolve o status distinto
  "REORGANIZACAO PENDENTE" com as opções.
- **`autoReorg=true`** — roda o reorganize **incremental** headless antes do build (coerente com o
  `gx_reorganize execute=true`; altera o schema, por isso é opt-in).
- **Guard de concorrência** — um build/run por vez; chamada concorrente recebe "BUILD EM ANDAMENTO"
  em vez de empilhar MSBuild zumbi.

## 1.11.2 (beta)
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
