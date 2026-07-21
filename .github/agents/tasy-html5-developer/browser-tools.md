# Uso do Navegador Integrado e Playwright

> ReferÃªncia do agente **Tasy HTML5 Developer**. Carregar ao testar, navegar ou reproduzir cenÃ¡rios no sistema Tasy HTML5.
>
> **Protocolo de login, URL de ambiente e o padrÃ£o "snapshot vs screenshot"** jÃ¡ estÃ£o documentados na skill `tasy-playwright` â€” carregar essa skill antes de qualquer navegaÃ§Ã£o real (ela cobre o fluxo completo de MCP Playwright). Este arquivo cobre apenas as diferenÃ§as entre as duas ferramentas disponÃ­veis e o uso do navegador integrado do VS Code.

## VS Code integrado Ã— MCP Playwright â€” qual usar

O agente pode interagir com o sistema Tasy diretamente pelo navegador integrado do VS Code (`open_browser_page`, `click_element`, `type_in_page`, `read_page`, `screenshot_page`) ou pelo MCP Playwright (`mcp_playwright_browser_*`).

> **PRIORIDADE:** Para testes e navegaÃ§Ã£o no sistema Tasy, usar **sempre primeiro o navegador integrado do VS Code** (`open_browser_page`, `click_element`, `type_in_page`, `read_page`, `screenshot_page`, `navigate_page` com `pageId`). O MCP Playwright (`mcp_playwright_browser_*`, `run_playwright_code`) sÃ³ deve ser usado como **fallback**, quando uma aÃ§Ã£o especÃ­fica nÃ£o for possÃ­vel pelas ferramentas do VS Code.

> **ATENÃ‡ÃƒO:** Os dois conjuntos de ferramentas operam em instÃ¢ncias de browser **diferentes**. As ferramentas com `pageId` operam no **navegador integrado do VS Code**. As ferramentas `mcp_playwright_browser_*` e `run_playwright_code` operam em uma **instÃ¢ncia separada do Playwright** â€” NÃƒO afetam o navegador do VS Code e NÃƒO enxergam a sessÃ£o logada do usuÃ¡rio.

## Carregamento obrigatÃ³rio de Skills de mÃ³dulo antes de navegar

**Sempre que abrir o navegador para navegar, testar ou investigar qualquer funÃ§Ã£o do Tasy**, carregar o skill correspondente ao mÃ³dulo **antes** de iniciar a navegaÃ§Ã£o. As skills contÃªm as regras de negÃ³cio, fluxos de tela, campos obrigatÃ³rios e comportamentos esperados â€” sem elas, o agente navega por tentativa e erro e perde contexto crÃ­tico.

| FunÃ§Ã£o / MÃ³dulo | Skill a carregar |
|---|---|
| Ordem de ServiÃ§o (Nova) â€” cd_funcao=297 | `corman-os` |
| GestÃ£o de Ordens de ServiÃ§o â€” cd_funcao=296 | `corman-go` |
| Ordem de ServiÃ§o Legado â€” cd_funcao=299 | `corman-f1` |
| Contas a Receber / BorderÃ´ / CobranÃ§a Escritural | `corcre` |
| Financeiro / Fluxo de Caixa / Tesouraria | `corfin` |
| Contas a Pagar / BorderÃ´ a Pagar / Pagamento Escritural | `corcpa` |
| Contabilidade / Lote ContÃ¡bil | `corctb` |
| Faturamento / Gerar TÃ­tulo a Receber | `fatact` |

**Procedimento:**
1. Identificar o mÃ³dulo/funÃ§Ã£o que serÃ¡ navegada
2. Usar `read_file` para carregar o SKILL.md correspondente (`.github/skills/<nome>\SKILL.md`)
3. Abrir o navegador e iniciar a navegaÃ§Ã£o com o contexto das regras de negÃ³cio jÃ¡ carregado

> NÃ£o iniciar navegaÃ§Ã£o sem ter lido o skill do mÃ³dulo. Caso nÃ£o exista skill para o mÃ³dulo, registrar isso e navegar com cautela, documentando o que for descoberto.

## IdentificaÃ§Ã£o de elementos no navegador integrado

O navegador integrado do VS Code usa snapshots de acessibilidade com referÃªncias `[ref=eXXXX]`. O fluxo padrÃ£o para interagir com elementos:

1. `read_page` (com `pageId`) â†’ obtÃ©m o snapshot completo com todos os refs
2. Para arquivos grandes (>20KB), o resultado Ã© salvo em arquivo â€” usar `read_file` para ler o conteÃºdo
3. Identificar o `ref` do elemento desejado no snapshot
4. `click_element` com `ref=eXXXX` e `pageId` â†’ clica no elemento correto

> Preferir sempre `ref=eXXXX` em vez de seletores CSS para cliques â€” os refs sÃ£o Ãºnicos e estÃ¡veis dentro da sessÃ£o.

### LimitaÃ§Ã£o do CKEditor com input sintÃ©tico
O rich edit (CKEditor) **nÃ£o aceita input sintÃ©tico de forma fiel**: `page.keyboard.type`, `CKEDITOR.insertHtml` e eventos disparados nÃ£o marcam `ng-dirty` nem acionam os handlers de foco/blur como um gesto real. Teste de digitaÃ§Ã£o real exige o **usuÃ¡rio** fazendo o gesto. Para verificaÃ§Ã£o objetiva de gravaÃ§Ã£o, usar spy + banco:
```js
// Spy em saveRecord do painel (via handler do WDBPanel)
handler.saveRecord = (orig => function(...a){ window.__saveSpy = (window.__saveSpy||0)+1; return orig.apply(this,a); })(handler.saveRecord.bind(handler));
```
E conferir `DT_ATUALIZACAO` do registro no banco (MCP oracle2) antes/depois â€” se nÃ£o mudar, nÃ£o houve gravaÃ§Ã£o.

### Inspecionar flags de read-only de um atributo
```js
const ai = handler.getDetailHandler().getAttribute('DS_RELAT_TECNICO').attributeInfo;
ai.isReadOnly();          // read-only lÃ³gico (permissÃ£o)
ai.isInternalReadOnly();  // read-only interno (framework/grid)
```
