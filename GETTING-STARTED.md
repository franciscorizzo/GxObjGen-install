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

**As tools `mcp__genexus__gx_*` não aparecem / dão schema antigo.**
Rode `/mcp` no Claude Code e reconecte o servidor `genexus`. O cliente não re-busca a lista de tools
sozinho depois que o servidor reinicia (ex.: após atualizar a extensão).

**"Connection refused" / o MCP não conecta.**
Confirme que o **GeneXus está aberto com uma KB carregada** — o servidor só sobe com o IDE aberto.
A porta do gateway é `127.0.0.1:8780`. Se você registrou outra porta, ajuste com
`claude mcp add --transport http genexus http://127.0.0.1:8780/mcp`.

**A IA diz que a operação foi BLOQUEADA (read-only).**
É o padrão seguro. Para permitir escrita, **feche o GeneXus e reabra com a variável de ambiente
`GXOBJGEN_WRITE=1`** (ex.: no PowerShell: `$env:GXOBJGEN_WRITE=1; & "C:\Program Files (x86)\GeneXus\GeneXus18\genexus.exe"`).
Confirme com `gx_whoami` (mostra `Modo: leitura+escrita`).

**Tenho o GeneXus 18 Upgrade 14 (ou mais novo) — funciona?**
A extensão foi validada em GeneXus 17 e 18 U13. Ela declara uma versão de compatibilidade estável
entre versões, então **deve** carregar em upgrades mais novos. Se o IDE recusar com algo como
*"cannot load package … expecting version 'X'"*, anote o **X** e reporte — geramos um pacote ajustado.

**Como sei a versão instalada?**
`gx_whoami` mostra `Extensao GxObjGen: vX.Y.Z`.

**Várias KBs abertas ao mesmo tempo.**
Use `gx_targets` para ver os slugs e passe `kb=<slug>` em cada tool. Com uma só KB, `kb` é opcional.

## Reportar um bug ou sugestão
O canal é a aba **Issues** deste repositório. Dois jeitos:

- **Pelo Claude Code (mais fácil):** peça *"reporta esse bug"* ou *"manda essa sugestão"*. Ele coleta
  a versão (`gx_whoami`) e o contexto e abre a issue pra você (via `gh`, ou te dá um link já
  preenchido). Veja as instruções no `CLAUDE.md`.
- **Manualmente:** abra em `Issues → New issue` e escolha **🐛 Bug** ou **💡 Sugestão** — o formulário
  já pede o que precisamos.

Em qualquer caso, inclua: **versão** (`gx_whoami`), **GeneXus 17/18** (e upgrade), o que você pediu, a
**mensagem de erro** e o passo para reproduzir. Logs do IDE em `%LOCALAPPDATA%\GeneXus`.
