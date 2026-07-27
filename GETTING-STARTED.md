# Primeiros passos & FAQ — GxObjGen (beta)

Depois de instalar (veja o `README.md`) e registrar o MCP no Claude Code, este guia ajuda a começar
e a resolver os tropeços mais comuns.

## Começando
1. Abra o **GeneXus** e a **sua KB**. A extensão sobe o servidor MCP automaticamente.
2. No **Claude Code**, no diretório onde você clonou este repositório (assim ele carrega o `CLAUDE.md`
   e a skill `gxobjgen` de referência), peça algo como:
   - *"Rode o gx_whoami e me diga qual KB está ativa e o modo."*
   - *"Liste as convenções da KB (gx_conventions)."*
   - *"Procure onde o código usa 'linkedin' (gx_search_indexed)."*
3. Para trabalhar na sua própria pasta de projeto, copie o `CLAUDE.md` e a pasta
   `.claude/skills/gxobjgen/` para lá — ou instale a skill globalmente em `~/.claude/skills/gxobjgen/`.

## FAQ / Troubleshooting

**Preciso rodar o Claude Code como administrador?**
Não. Só o **passo de instalação** (`install.ps1`) precisa de admin, porque escreve em Program Files
e registra a extensão — e o script já **se re-lança via UAC** se você rodar de um PowerShell comum.
O **Claude Code do dia a dia não precisa de admin**: depois de instalada, a extensão roda dentro do
GeneXus e o MCP é loopback. Evite pedir ao Claude Code para rodar o `install.ps1` (ele precisaria
estar elevado); prefira rodar o instalador você mesmo num PowerShell.

**As tools `mcp__genexus__gx_*` não aparecem / dão schema antigo.**
Rode `/mcp` no Claude Code e reconecte o servidor `genexus`. O cliente não re-busca a lista de tools
sozinho depois que o servidor reinicia (ex.: após atualizar a extensão).

**"tools fetch failed" (a porta 8780 responde, mas os `gx_*` não carregam).**
Importante: se `127.0.0.1:8780` responde (mesmo com um erro a um GET no navegador), a extensão **está**
instalada e o GeneXus **está** aberto — o gateway só existe dentro do IDE, não sobe sozinho. Não perca
tempo reinstalando. Rode o diagnóstico decisivo (POST de verdade, não GET):
```powershell
curl -s -X POST http://127.0.0.1:8780/mcp -H "Content-Type: application/json" -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/call\",\"params\":{\"name\":\"gx_targets\",\"arguments\":{}}}"
```
- **Lista as KBs** (slug/porta) → o gateway está OK; o "fetch failed" era só o **cache de conexão do
  Claude Code**. Reinicie a sessão do Claude Code (o registro fica no `.claude.json` do projeto e ele
  reconecta sozinho) ou rode `/mcp` → reconnect no servidor `genexus`.
- **Responde mas 0 KBs** → **abra a sua KB no GeneXus** (o gateway sobe sem KB, mas sem KB não há tools).
- **Connection refused** → aí sim o IDE/extensão não está no ar: abra o GeneXus (e confirme a instalação).

**"Connection refused" na 8780 (mas o IDE mostrou o MCP numa OUTRA porta, ex. 8879).**
Não é o MCP quebrado — é o **gateway multi-KB (8780) que não subiu**, quase sempre porque **não há
Python no PATH** (o gateway é um script Python que a extensão lança; pré-requisito só dele). O
servidor **por-KB** está vivo na porta que o Output do IDE mostrou (seção "GxObjGen MCP") — ela é
**determinística por KB** (estável entre reaberturas, faixa 8787–8986). Duas saídas:
- Use a porta por-KB (funciona sem Python): `claude mcp add --transport http genexus-<kb> http://127.0.0.1:<porta>/mcp`
- Ou instale Python (`winget install Python.Python.3.12`), reabra o GeneXus e use a 8780.
Desde a v1.11.5, a seção "GxObjGen MCP" do Output diz o status do gateway e o motivo quando ele
não sobe. NÃO reinstale a extensão por causa disso.

**"Connection refused" / o MCP não conecta (nem na porta por-KB).**
Confirme que o **GeneXus está aberto com uma KB carregada** — o servidor só sobe com o IDE aberto.
Gateway: `127.0.0.1:8780` (requer Python). Por-KB: a URL do Output do IDE. Se você registrou outra
porta, ajuste com `claude mcp add`.

**A IA diz que a operação foi BLOQUEADA (read-only).**
É o padrão seguro. Para permitir escrita, **feche o GeneXus e reabra com a variável de ambiente
`GXOBJGEN_WRITE=1`** (ex.: no PowerShell: `$env:GXOBJGEN_WRITE=1; & "C:\Program Files (x86)\GeneXus\GeneXus18\genexus.exe"`).
Confirme com `gx_whoami` (mostra `Modo: leitura+escrita`).

**Quais versões do GeneXus são suportadas?**
GeneXus **15, 17 e 18** (validada em GX15, GX17 e GX18 U13). O `install.ps1` detecta a versão e
instala a variante certa — o **GX15 usa um DLL próprio** (número de compatibilidade `123130` vs
`143920` do 17/18). No GX15, 4 tools de objetos que não existem nessa versão (designsystem/api/
urlrewrite/usercontrol) ficam ocultas; o resto funciona igual.

A extensão declara uma versão de compatibilidade por build do host, então **deve** carregar em
upgrades próximos. Se o IDE recusar com *"cannot load package … expecting version 'X'"*, anote o
**X** e reporte — geramos um pacote ajustado.

**Como sei a versão instalada?**
`gx_whoami` mostra `Extensao GxObjGen: vX.Y.Z`.

**Várias KBs abertas ao mesmo tempo.**
Use `gx_targets` para ver os slugs e passe `kb=<slug>` em cada tool. Com uma só KB, `kb` é opcional.

## Permissões recomendadas (`settings.json`)
O produto chama-se **GxObjGen**, mas o servidor MCP registra-se como **`genexus`** — as tools são
`mcp__genexus__gx_*` (e **não** `mcp__GxObjGen__*`). Uma regra de permissão com o prefixo errado
**nunca casa** e dá falsa sensação de segurança. Bloco pronto para colar no `settings.json` do Claude
Code (auto-aprova as leituras seguras, sempre pergunta nas escritas, e **bloqueia** as duas mais
perigosas):

```jsonc
{
  "permissions": {
    // AUTO-APROVA: leitura/análise (sem efeito colateral) + specify + export
    "allow": [
      "mcp__genexus__gx_whoami", "mcp__genexus__gx_status", "mcp__genexus__gx_telemetry",
      "mcp__genexus__gx_conventions", "mcp__genexus__gx_overview", "mcp__genexus__gx_modules",
      "mcp__genexus__gx_datastore", "mcp__genexus__gx_gxserver", "mcp__genexus__gx_gam",
      "mcp__genexus__gx_list_objects", "mcp__genexus__gx_list_object_types",
      "mcp__genexus__gx_search", "mcp__genexus__gx_search_indexed", "mcp__genexus__gx_search_in_source",
      "mcp__genexus__gx_get_object_text", "mcp__genexus__gx_get_properties", "mcp__genexus__gx_doc",
      "mcp__genexus__gx_analyze", "mcp__genexus__gx_dependencies", "mcp__genexus__gx_read_structure",
      "mcp__genexus__gx_object_parts", "mcp__genexus__gx_object_api", "mcp__genexus__gx_prop_inspect",
      "mcp__genexus__gx_var_inspect", "mcp__genexus__gx_layout_tree", "mcp__genexus__gx_object_version",
      "mcp__genexus__gx_history", "mcp__genexus__gx_attributes", "mcp__genexus__gx_diff",
      "mcp__genexus__gx_lint", "mcp__genexus__gx_recover", "mcp__genexus__gx_specify",
      "mcp__genexus__gx_export"
    ],
    // BLOQUEIA: irreversível em cascata + escape hatch de MSBuild arbitrário
    "deny": [
      "mcp__genexus__gx_delete_cascade",
      "mcp__genexus__gx_msbuild"
    ]
  }
}
```

Tudo o que **não** está nas listas cai no **modo padrão de permissão** (normalmente *ask*): é o caso
de toda a **escrita** (`gx_create_or_update_*`, `gx_edit`, `gx_set_*`, `gx_refactor`,
`gx_delete_object`, `gx_add_part_item`, `gx_wwp_*`, `gx_layout_set`, `gx_apply_*`, `gx_create_module`/
`_folder`/`_textobject`) e das operações **pesadas/de ambiente** (`gx_import`, `gx_build`, `gx_run`,
`gx_test`, `gx_reorganize`, `gx_version`, `gx_schema`, `gx_kb_check`) — todas **perguntam** antes.

> **GeneXus 15:** quatro tools não existem nessa versão e ficam ocultas
> (`gx_create_or_update_designsystem`/`_api`/`_urlrewrite`/`_usercontrol`) — listá-las seria inócuo
> (regra que não casa). O bloco acima é version-agnostic.

## Reportar um bug ou sugestão
O canal é a aba **Issues** deste repositório. Dois jeitos:

- **Pelo Claude Code (mais fácil):** peça *"reporta esse bug"* ou *"manda essa sugestão"*. Ele coleta
  a versão (`gx_whoami`) e o contexto e abre a issue pra você (via `gh`, ou te dá um link já
  preenchido). Veja as instruções no `CLAUDE.md`.
- **Manualmente:** abra em `Issues → New issue` e escolha **🐛 Bug** ou **💡 Sugestão** — o formulário
  já pede o que precisamos.

Descobriu um **padrão/dica genérica** que ajudaria qualquer usuário? Use o template **🧠 Aprendizado**
(ou peça ao Claude *"registra esse aprendizado"*). Ele vira referência nas próximas versões. ⚠️ Só
conhecimento **genérico** sobre a ferramenta — nunca dados ou lógica da sua KB.

Em qualquer caso, inclua: **versão** (`gx_whoami`), **GeneXus 15/17/18** (e upgrade), o que você pediu, a
**mensagem de erro** e o passo para reproduzir. Logs do IDE em `%LOCALAPPDATA%\GeneXus`.
