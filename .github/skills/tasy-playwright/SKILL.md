---
name: tasy-playwright
description: Automatically assists with testing the Tasy HTML5 system via Playwright MCP. Activates: When testing system behavior, reproducing bugs, validating fixes, or navigating the Tasy HTML5 system interactively
---

# Tasy HTML5 — Playwright Testing Skill

Ativa quando:
- Reproduzir cenários de bug descritos em cards ADO
- Validar correções diretamente no sistema
- Navegar pela tela para rastrear comportamento (tela → código → banco)
- Executar testes interativos via MCP Playwright

---

## ⚠️ Protocolo Obrigatório — Antes de Iniciar Qualquer Teste

**Sempre perguntar ao usuário antes de acessar o sistema:**

1. **Qual ambiente/URL?**
   - `http://localhost:3000/#/login` — ambiente local
   - `https://dev-tasy.whebdc.com.br/#/login` — Dev
   - `https://financial-accounting.devops.whebdc.com.br/#/` — Financial Accounting
   - Outra URL (informar)
2. **Usuário** — padrão `fzavaglio`; confirmar ou informar outro
3. **Senha** — **sempre perguntar**, nunca armazenar; solicitar que o usuário informe no chat

> **Nunca iniciar navegação, login ou qualquer interação com o sistema sem confirmar os três pontos acima.**

---

## 🔁 Protocolo de Navegação — Ver, Compreender, Agir

### Snapshot vs Screenshot — qual usar

| Ferramenta | Formato | Quando usar |
|---|---|---|
| `mcp_playwright_browser_snapshot` | YAML de acessibilidade (texto) | **Sempre** — antes de cada ação para entender o estado real |
| `mcp_playwright_browser_take_screenshot` | Imagem PNG | Para gerar evidência visual para documentação |
**Por que snapshot é preferível para navegação:**
- É texto estruturado — sempre interpretado corretamente sem depender de OCR/visão
- Contém `[ref=eXXXX]` que podem ser usados diretamente no `mcp_playwright_browser_click`
- Mostra estados explícitos: `[disabled]`, `[expanded]`, `[checked]`
- Não existe "alucinação" — o que está no YAML é o que existe no DOM
- Screenshots podem parecer corretos mas o estado real do DOM pode ser diferente

**A cada passo de interação com o sistema, seguir sempre este ciclo:**

```
1. mcp_playwright_browser_snapshot         →  obtém estado atual (YAML texto, confiável)
2. Ler o snapshot e compreender o estado   →  o que está visível, qual ref usar, há dialogs?
3. Tomar decisão lógica                    →  como um usuário real tomaria
4. Executar a ação (clicar, digitar, etc.) →  usando refs do snapshot
5. Repetir — novo snapshot para confirmar o resultado
```

> **REGRA CRÍTICA: Nunca assumir que uma ação funcionou sem confirmar com snapshot.** O estado anterior pode ter mudado (modal aberto, erro exibido, tela diferente). Muitos erros durante testes ocorrem porque o agente presume que "clicou com sucesso" sem verificar o resultado.

### O que interpretar em cada snapshot — e suas limitações

O snapshot usa a **árvore de acessibilidade ARIA** — não é visual. Não reflete z-index nem sobreposição visual.

#### O que o snapshot captura com confiança

| Sinal no snapshot | Significado |
|---|---|
| `alertdialog` ou `dialog` presente | Há um modal/localizador aberto |
| `[disabled]` num button/input | Elemento não é clicável/editável |
| `[expanded]` num combobox/menuitem | Menu ou dropdown já está aberto |
| Textbox com valor preenchido | Registro carregado no formulário |
| `"Nr ordem: 141869"` como texto | Token de filtro ativo nessa OS |
| `.slick-row` ausente | Grid vazio — nenhum resultado |
| `button [disabled]` na action bar | Formulário em modo somente-leitura |

> **Atenção:** Muitos dialogs do Tasy NÃO têm `role="alertdialog"` ou `role="dialog"`. Usar `.ngdialog-content` para detecção universal.

#### Limitações críticas — snapshot NÃO captura diretamente

| Estado | Por que não aparece | Como detectar corretamente |
|---|---|---|
| `.ngdialog-overlay` bloqueando cliques | Div sem `role` ARIA → invisível no snapshot; elementos bloqueados aparecem como se acessíveis | `page.evaluate()`: `getComputedStyle(overlay).display !== 'none'` |
| Aba `.is-disabled` | Classe CSS do framework, não refletida em ARIA | `page.evaluate()`: `.w-header-tab.is-disabled` |
| Painel "Carregando..." | Spinner é CSS puro sem texto ARIA | `page.evaluate()`: verificar `.loading`, `[aria-busy]` ou texto "Carregando" |
| Modo edição Angular (registro aberto vs. novo) | AngularJS não usa `aria-live` para isso | `page.evaluate()`: `angular.element(el).scope().registro` |
| Loading após reativação de painel | Sem indicador ARIA durante fetch | Usar `waitForTimeout` calibrado + checar se campos têm valores |

#### Armadilha com overlay + snapshot

**Problema:** Quando um `ngdialog-overlay` está ativo, o snapshot mostra os elementos por baixo como se fossem clicáveis. O agente pode achar que "o campo X está disponível" quando na verdade está bloqueado pela overlay.

**Regra:** Se uma ação falhou com timeout (overlay interceptou), verificar overlay com `page.evaluate()` **não** com `!el.offsetParent` (que retorna `null` para elementos `position:fixed` mesmo quando visíveis):

```js
// CORRETO — detectar overlay ativa que de fato bloqueia
await page.evaluate(() => {
  const el = document.querySelector('.ngdialog-overlay');
  if (!el) return false;
  const s = window.getComputedStyle(el);
  // ATENÇÃO: overlay pode estar display:block mas com zIndex:'auto' — isso NÃO bloqueia
  // Overlay que bloqueia tem zIndex alto (ex: 1040 ou mais) ou está na frente do conteúdo
  const visible = s.display !== 'none' && s.visibility !== 'hidden' && s.opacity !== '0';
  const zIdx = parseInt(s.zIndex) || 0;
  return visible && (zIdx > 100 || s.zIndex === 'auto' && /* checar se dialog filho existe */ !!el.querySelector('[class*="ngdialog-content"]'));
});
```

> **Aprendizado validado (30/06/2026):** O `ngdialog-overlay` pode permanecer no DOM com `zIndex: auto` mesmo após um dialog fechar — isso **não bloqueia cliques**. Somente overlay com z-index alto e dialog filho visível bloqueia a interação.

### Decisões práticas — como um usuário real agiria

| Situação encontrada no screenshot | Ação correta |
|---|---|
| `alertdialog` de "Objetos inválidos" pós-login | Clicar "Ok" para fechar e prosseguir |
| Sistema pergunta se deseja reabrir função já aberta | Clicar "Não" e usar a janela já aberta |
| Botão "Salvar" clicado → sistema exibiu consistência | Ler a mensagem, identificar e resolver a inconsistência antes de tentar novamente |
| Localizador aberto com grid vazio | Filtro sem resultados; ajustar critério ou limpar filtros e tentar busca ampla |
| Formulário totalmente em branco | Nenhum registro carregado; usar localizador para buscar um existente |
| Menu contextual aberto | Verificar quais itens estão habilitados/desabilitados antes de clicar |
| Tela sem resposta após clicar | Aguardar request completar; verificar console de erros se demorar |
| Dialog de confirmação ("Deseja salvar?", "Tem certeza?") | Ler o texto e clicar na opção correta conforme o objetivo do teste |

---

## Credenciais e Acesso

- **Usuário padrão:** `fzavaglio` (confirmar ou substituir antes de cada sessão)
- **Senha:** sempre solicitada ao usuário — nunca armazenada neste skill

---

## Login (via MCP)

```js
// URL e credenciais obtidas do usuário antes de iniciar
await page.goto('<URL_INFORMADA_PELO_USUARIO>');
await page.getByRole('textbox', { name: 'Nome de usuário' }).fill('<USUARIO>');
await page.getByRole('textbox', { name: 'Senha' }).fill('<SENHA_DIGITADA_NO_TERMINAL>');
await page.getByRole('button', { name: 'Entrar' }).click();
// Fechar dialog de objetos inválidos se aparecer
const okBtn = page.getByRole('button', { name: 'Ok' });
if (await okBtn.isVisible()) await okBtn.click();
```

> **Dialog pós-login** (objetos inválidos, sessão duplicada) pode aparecer vários segundos após o login. Sempre aguardar e fechar com "Ok" antes de prosseguir.

---

## Navegação para Funções

```js
await page.getByRole('textbox').fill('Ordem de Serviço');
await page.locator('a').filter({ hasText: 'Ordem de Serviço (Nova)' }).click();
```

### Nomes confirmados

| cd_funcao | Nome para busca |
|---|---|
| 299 (Delphi) | "Ordem de Serviço" |
| 297 (HTML5) | "Ordem de Serviço (Nova)" |

---

## Estrutura da Tela de uma Função

```
banner (header fixo)
  └─ botão voltar | logo Tasy | nome da função | usuário logado

generic.wschematic (container da função)
  ├─ wschematic-nav-bar
  │    └─ combobox .wschematic-dropdown (seletor de painel)
  └─ wschematic-content
       ├─ pn pn-shadow → popup-container  ← WDBPanel principal
       │    ├─ w-token-filter__tokens (filtros ativos — ex: "Nr ordem: 2412796")
       │    ├─ handlebar-overlay-dropmenu (alvo do contextmenu / botão direito)
       │    ├─ tabs (Dados de Manutenção, Detalhes, Status...)
       │    └─ action bar (Salvar, Cancelar...)
       ├─ resizer-panel-template (divisor)
       └─ pn pn-shadow (painel direito — Histórico, Anexos...)
```

**Nota corManOS (Ordem de Serviço Nova):** O WDBPanel principal NÃO tem grid de linhas no painel principal. Os registros são acessados via Localizador (popup `alertdialog`).

### WDBPanels confirmados (cd_funcao=297)

| dto-code | Descrição |
|---|---|
| `129569` | Painel principal da OS (formulário de detalhe) |
| `280733` | Segundo painel (contém lupinha do NR_SEQUENCIA) |

---

## Aguardando Estabilização da Tela

```javascript
// WDBPanel carregado + lupinha habilitada = tela pronta
await page.locator(`tasy-wdbpanel[dto-code="129569"]`).waitFor({ timeout: 20000 });
await page.locator('tasy-wtextboxlocator input[type="button"]:not([disabled])')
  .first()
  .waitFor({ state: 'visible', timeout: 20000 });
await page.waitForTimeout(2000); // margem extra
```

---

## Localizador de Registros (WStandarLocator)

```js
// 1. Abrir localizador pelo botão de lupa ao lado do campo-chave
await page.getByRole('group', { name: 'Ordem de serviço' }).getByRole('button').click();

// 2. Limpar filtro de tipo de datas (combobox "Data": opções "---", "Ordem", "Baixa")
await page.getByRole('combobox', { name: 'Data' }).click();
await page.getByRole('option', { name: '---' }).click();

// 3. Filtrar (botão dentro do alertdialog)
await page.evaluate(() => {
  const dialog = document.querySelector('[role="alertdialog"]');
  dialog?.querySelector('button.btn-green')?.click();
});

// 4. Selecionar primeira linha
await page.evaluate(() => {
  const dialog = document.querySelector('[role="alertdialog"]');
  dialog?.querySelector('.slick-row')?.click();
});

// 5. Confirmar com OK
await page.evaluate(() => {
  const dialog = document.querySelector('[role="alertdialog"]');
  Array.from(dialog?.querySelectorAll('button') || [])
    .find(b => b.textContent?.trim() === 'OK')?.click();
});
```

> **Clicar lupinha antes da tela estabilizar** abre o localizador errado. Aguardar `input[type="button"]:not([disabled])` visível primeiro. **Não usar `force: true`** no click da lupinha.

### corManOS — Localizador via `tasy-wtextboxlocator` (isolateScope)

Na função "Ordem de Serviço (Nova)" (cd_funcao=297), o localizador **não abre** com click simples (`.click()` ou `dispatchEvent`). O método correto é chamar `openSelectionLocatorIcon()` via `isolateScope()` do componente `tasy-wtextboxlocator` do campo NR_SEQUENCIA:

```js
// CORRETO para corManOS
await page.evaluate(() => {
  const locNrSeq = document.querySelectorAll('tasy-wtextboxlocator')[0]; // NR_SEQUENCIA
  const isolate = angular.element(locNrSeq).isolateScope();
  isolate.$apply(() => isolate.openSelectionLocatorIcon());
});
await page.waitForTimeout(800);
const opened = await page.evaluate(() => !!document.querySelector('[role="alertdialog"]'));
```

**Cuidados com os filtros do localizador corManOS:**
- O localizador aplica por padrão filtros de data (`DT_INICIAL`/`DT_FINAL`) e de setor — OS fora desse intervalo ou de outro setor não aparecem
- Usar **"Ações do filtro" → "Limpar filtros"** para eliminar todos os filtros antes de pesquisar
- Definir valores via `ngModel.$setViewValue()` + `scope.$apply()` (não usar `.value =` diretamente)
- O campo `NR_ORDEM` do localizador corresponde ao `NR_SEQUENCIA` da tabela `man_ordem_servico`
- O localizador filtra OS pelo **setor do usuário logado** — se a OS não aparecer, verificar se o setor do usuário tem acesso àquela OS

```js
// Limpar filtros e pesquisar por NR_SEQUENCIA específico
await page.evaluate(() => {
  const dialog = document.querySelector('[role="alertdialog"]');
  
  // 1. Limpar filtros via botão "Ações do filtro"
  dialog.querySelector('.w-filter-options__button--top')?.click();
});
await page.waitForTimeout(200);
await page.evaluate(() => {
  const dropdown = document.querySelector('.w-filter-options__dropdown, [class*="filter-options"]');
  Array.from(dropdown?.querySelectorAll('li, button, a') || [])
    .find(el => el.textContent?.trim() === 'Limpar filtros')?.click();
});
await page.waitForTimeout(300);
await page.evaluate((nrSeq) => {
  const dialog = document.querySelector('[role="alertdialog"]');
  const inp = dialog.querySelector('input[name="NR_ORDEM"]');
  const ngModel = angular.element(inp).controller('ngModel');
  ngModel.$setViewValue(String(nrSeq));
  ngModel.$render();
  angular.element(inp).scope().$apply();
  dialog.querySelector('button.btn-green')?.click(); // Filtrar
}, 144805);
```

**Selecionar row e confirmar:**
```js
// Selecionar primeira linha e clicar OK
await page.evaluate(() => {
  const dialog = document.querySelector('[role="alertdialog"]');
  dialog?.querySelector('.slick-row')?.click();
});
await page.waitForTimeout(200);
await page.evaluate(() => {
  const dialog = document.querySelector('[role="alertdialog"]');
  dialog?.querySelector('button.btn-blue')?.click(); // OK
});
```

---

## Diagnóstico: Filtro / Localizador Sem Resultados

Quando um painel ou localizador retorna zero registros e o problema não é simplesmente um filtro mal preenchido, **ir ao banco antes de tentar soluções às cegas**.

### Fluxo de diagnóstico

```
1. Identificar o dto-code do painel pelo DOM           →  atributo dto-code no tasy-wdbpanel
2. Localizar o JSON do painel no Schematics DX         →  backend/TasyAppServer/src/main/.../schematics/<módulo>/dbpanels/<code>.json
3. Extrair o SQL ou dsValores / allCriteria             →  campo "dsValores" em atributos FK, ou query da tabela do panel
4. Executar no Oracle Financial (mcp_oracle2_*)         →  com os mesmos parâmetros que o usuário passaria
5. Analisar o WHERE para entender por que zero rows     →  filtro de data, restrição de setor/estabelecimento, cadastro faltando
6. Corrigir a causa raiz                               →  ajustar filtro, cadastrar registro faltante, ajustar parâmetro
```

### Passo 1 — Identificar o painel e seu SQL

```js
// Ler dto-code de todos os painéis visíveis
await page.evaluate(() => {
  return Array.from(document.querySelectorAll('tasy-wdbpanel, [dto-code]'))
    .map(el => ({ tag: el.tagName, code: el.getAttribute('dto-code'), visible: el.offsetParent !== null }));
});
```

Com o `dto-code`, localizar o JSON:
```
emr-tasy-backend/TasyAppServer/src/main/resources/schematics/<módulo>/dbpanels/<dto-code>.json
```

O JSON contém `"nmTabela"` (tabela principal) e `"allCriteria"` (restrições adicionais). Para filtros, verificar o JSON em `filters/<code>.json` — campo `sqlRestriction` de cada atributo.

Para encontrar o SELECT completo usado pelo localizador, buscar em `dic_objeto` pela query vinculada ao painel:

```sql
-- Buscar queries vinculadas à função pelo código do painel
SELECT nm_objeto, ds_objeto
FROM dic_objeto
WHERE nm_objeto LIKE '%<NOME_OU_TRECHO>%'
AND ie_tipo_objeto = 'S'; -- S = SELECT
```

### Passo 2 — Executar a query no banco com os parâmetros reais

Montar o SELECT manualmente com os parâmetros que o sistema usaria, removendo binds dinâmicos para inspecionar o resultado:

```sql
-- Exemplo: localizador de OS retornou vazio
-- Testar a query base sem restrições de filtro
SELECT nr_sequencia, nm_solicitante, dt_abertura, cd_setor_atendimento
FROM man_ordem_servico
WHERE cd_empresa = 1
AND cd_estabelecimento = 1
ORDER BY nr_sequencia DESC
FETCH FIRST 20 ROWS ONLY;
```

```sql
-- Adicionar as restrições do filtro uma a uma para identificar qual elimina o registro
SELECT nr_sequencia, dt_abertura, cd_setor_atendimento
FROM man_ordem_servico
WHERE cd_empresa = 1
AND nr_sequencia = 144805;  -- verificar se o registro existe de fato
```

### Passo 3 — Causas comuns e como verificar

| Sintoma | Causa provável | Query de verificação |
|---|---|---|
| Filtro de data exclui o registro | `DT_ABERTURA` fora do intervalo padrão do localizador | `SELECT dt_abertura FROM man_ordem_servico WHERE nr_sequencia = X` |
| OS existe mas não aparece | Restrição de setor — usuário sem acesso ao setor da OS | `SELECT cd_setor FROM man_ordem_servico WHERE nr_sequencia = X` vs setor do usuário |
| Setor do usuário não configurado | Tabela `funcionario_estabelecimento` ou `usuario_setor` sem vínculo | `SELECT * FROM usuario_setor WHERE nm_usuario = 'fzavaglio'` |
| Registro deletado ou inativo | `IE_SITUACAO = 'I'` ou registro não existe | `SELECT ie_situacao FROM <tabela> WHERE nr_sequencia = X` |
| Campo FK sem cadastro correspondente | Lookup em tabela auxiliar sem o registro necessário | Verificar `dsValores` do atributo no JSON e executar o SELECT de lookup |
| Parâmetro de função bloqueando | Parâmetro `S`/`N` filtra o resultado por perfil/estabelecimento | Buscar `parametro_funcao` e verificar valor configurado |

### Passo 4 — Corrigir via sistema ou banco

Após identificar a causa, a correção depende do tipo:

- **Filtro de data:** limpar via "Ações do filtro → Limpar filtros" no localizador
- **Restrição de setor sem cadastro:** cadastrar o vínculo na função administrativa correspondente (ex: corSis, corCad) — **não alterar tabelas de configuração diretamente via SQL** (triggers bloqueiam)
- **Registro FK faltando:** verificar se o cadastro deve existir e criá-lo via função do sistema
- **Parâmetro de função mal configurado:** ajustar via corSis → Parâmetros de Função

> **Nunca presumir que o grid vazio é um bug** sem antes confirmar via banco que o registro deveria aparecer com aqueles critérios. A causa mais comum é configuração de ambiente (setor, parâmetro, data) que difere entre ambientes.

---

## Filtro (tasy-wfilter) — Abrir, Ampliar e Ler Contagem

### Botão de abrir o filtro — o funil azul

O botão que abre/fecha o formulário de filtro é um **ícone de funil azul** (visualmente parecido com um "Y"/funil) no **canto superior esquerdo do painel**, ao lado do título. No DOM é um `tasy-wlabel.filter-icon` com `ng-click="toggleFilter($element)"`.

- Existem **dois** elementos `tasy-wlabel.filter-icon`; um fica `ng-hide` (`canShowFilterIconBesideTitle()` false). Clicar sempre o **visível** (sem `ng-hide`).
- É um **toggle**: cada clique abre/fecha. Não confiar em `scope.visible` (fica `true` "stale" mesmo com o form fechado) — validar sempre pela presença dos inputs (ex: `input[placeholder="DD/MM/YYYY"]`).
- **Após clicar em "Filtrar" o formulário recolhe** para uma barra de tokens (ex: `De: 20/07/2026`, `Situação: Aberto`). Clicar nos tokens **não** reabre o form — reabrir pelo funil.

```js
// Abrir/fechar o filtro pelo funil (dispatchEvent no elemento visível)
await page.evaluate(() => {
  const el = Array.from(document.querySelectorAll('tasy-wlabel.filter-icon'))
    .find(e => e.offsetParent && !e.className.includes('ng-hide'));
  el && el.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true, view: window }));
});
await page.waitForTimeout(1200);
// confirmar que abriu:
const aberto = await page.evaluate(() =>
  !!Array.from(document.querySelectorAll('button')).find(b => b.offsetParent && b.textContent.trim() === 'Filtrar'));
```

### DatePicker — garantir que o modelo commitou

O `input[ng-model="input.dateValue"]` **não commita** de forma confiável só com `fill()` — e mesmo com `pressSequentially` o modelo pode não atualizar na primeira tentativa (o filtro acaba usando o valor antigo). **Sempre verificar** o modelo Angular após digitar:

```js
const de = page.locator('input[placeholder="DD/MM/YYYY"]').nth(0);
await de.click();
await de.press('Control+a');
await de.pressSequentially('01/01/2000', { delay: 40 });
await de.press('Tab');
// VERIFICAR commit (senão o filtro usa a data antiga):
const ok = await page.evaluate(() => {
  const i = document.querySelectorAll('input[placeholder="DD/MM/YYYY"]')[0];
  return angular.element(i).scope().input.dateValue; // deve refletir o novo valor
});
```

### Ler a contagem de registros do grid

O total fica num rodapé "Registros: X - Y de Z". Padrão para extrair de qualquer grid visível:

```js
const counts = await page.evaluate(() =>
  [...new Set(Array.from(document.querySelectorAll('*'))
    .filter(e => /Registros/.test(e.textContent || '') && e.querySelectorAll('*').length <= 6)
    .map(n => n.textContent.replace(/\s+/g, ' ').trim())
    .filter(t => t.length < 40))]);
// ex: ["Registros:1 - 999 de 20518", "Registros: 20518"]
```

### Ampliar filtro para gerar massa de teste (>N registros)

Para reproduzir cenários que exigem muitos registros: usar a base Oracle (`mcp_oracle2_*`, Financial) para **descobrir quantos registros existem por critério** e então montar o filtro na tela. Ex.: em títulos, "Datas de referência" ampla (01/01/2000–31/12/2030) + Situação "Aberto" retornou 20.518 títulos.

> **A UI `financial-accounting.devops.whebdc.com.br` usa o MESMO banco Oracle do `mcp_oracle2` (Financial)** — confirmado por PK batendo (título 165909 idêntico na tela e no banco). Portanto o MCP Oracle pode ser usado para desenhar/validar os dados de teste que a UI vai exibir.

---

## Menu Contextual (Botão Direito / WPUMC)

```js
// Disparar contextmenu no overlay do WDBPanel principal
await page.evaluate(() => {
  const panel = document.querySelector('.popup-container:not(.ng-hide)');
  const overlay = panel?.querySelector('.handlebar-overlay-dropmenu');
  if (!overlay) return;
  const rect = panel.getBoundingClientRect();
  overlay.dispatchEvent(new MouseEvent('contextmenu', {
    bubbles: true, cancelable: true, view: window,
    clientX: rect.left + rect.width / 2,
    clientY: rect.top + 100
  }));
});
await page.waitForTimeout(500);

// Ler todos os itens do menu
const items = await page.evaluate(() => {
  const dialog = document.querySelector('.wpopmenu-dialog');
  return Array.from(dialog?.querySelectorAll('.wpopupmenu__item') || []).map(item => ({
    label: item.querySelector('.wpopupmenu__label')?.textContent?.trim(),
    shortcut: item.querySelector('.wpopupmenu__shortcut')?.textContent?.trim() || null,
    disabled: item.classList.contains('wpopupmenu__item--disabled')
  })).filter(i => i.label);
});

// Clicar em item específico
await page.evaluate((labelText) => {
  for (const item of document.querySelectorAll('.wpopupmenu__item')) {
    if (item.querySelector('.wpopupmenu__label')?.textContent?.trim() === labelText) {
      item.click(); break;
    }
  }
}, 'Duplicar OS');
```

> O `wpopmenu-dialog` também é acessível via botão **"More actions"** no menubar da função — equivalente ao right-click.

### Right-click em grid de WCPanel (lista) — `.slick-viewport`

Para funções cujo painel é um **WCPanel com grid** (lista/consulta, ex: corCpaF1 "Alteração em lotes", corCpaF4 "Consulta de Títulos a Pagar"), o overlay `.handlebar-overlay-dropmenu` do WDBPanel **não existe**. O menu abre disparando um `MouseEvent('contextmenu')` **com coordenadas** (`clientX`/`clientY` + `button: 2`) sobre o `.slick-viewport` (ou `.grid-canvas`) **do painel específico que contém a opção** — um `dispatchEvent('contextmenu')` sem coordenadas NÃO abre o menu.

```js
await page.evaluate(() => {
  // pegar o WCPanel correto pelo dto-code (a opção pertence a UM painel específico)
  const panel = document.querySelector('tasy-wcpanel.\\38 56744')   // classe = dto-code
             || document.querySelectorAll('tasy-wcpanel')[0];
  const vp = panel.querySelector('.slick-viewport') || panel.querySelector('.grid-canvas');
  const r = vp.getBoundingClientRect();
  vp.dispatchEvent(new MouseEvent('contextmenu', {
    bubbles: true, cancelable: true, view: window, button: 2,
    clientX: r.left + 40, clientY: r.top + 10
  }));
});
await page.waitForTimeout(1000);
```

> **Padrão geral:** a opção de mouse pertence a **um painel específico** — disparar o contextmenu no grid/viewport **daquele** painel, não em qualquer área da tela. Se a função tem vários WCPanels, filtrar pelo `dto-code` do painel dono da opção.
>
> **Menu resultante (schematics novo):** aparece na árvore ARIA como `dialog > menu > menuitem "<label>"` — legível diretamente pelo `read_page`/snapshot e clicável pelo `ref`. (O schematics antigo usa `.wpopupmenu__item`; ambos coexistem.)

### WPUMCs confirmados — corManF1 (Ordem de Serviço Nova)

| w-code | Descrição |
|---|---|
| 418592 | Gerar preventiva |
| 418614 | Gerar ordem de serviço protocolo |
| 418622 | Obter anexo(s) / histórico(s) OS via WS |
| 418633 | Alterar grau satisfação |
| 956560 | Localizar ordem de serviço |

---

## Padrões de Interação com Componentes Tasy (MCP)

### Registro atual no WDBPanel (Angular scope)

```js
await page.evaluate(() => {
  const dbpanel = document.querySelector('[class*="w-dbpanel"]');
  const scope = angular?.element(dbpanel)?.scope?.();
  return scope?.registro; // todos os campos do registro atual
});
```

### Fechar detalhe e voltar ao estado inicial

```js
await page.keyboard.press('Backspace'); // hotkey closeDetail do WDBPanel
```

### Combobox (w-listbox) — obter opções

```js
await page.evaluate(() => {
  const combos = document.querySelectorAll('[role="combobox"]');
  for (const combo of combos) {
    const scope = angular?.element(combo)?.scope?.();
    if (scope?.options?.length > 0)
      return scope.options.map(o => ({ cd: o.CD, ds: o.DS }));
  }
});
```

### Panel selector — obter painéis disponíveis

```js
await page.evaluate(() => {
  const listbox = document.querySelector('.wschematic-dropdown .w-listbox');
  const scope = angular?.element(listbox)?.scope?.();
  return scope?.options; // ex: [{CD: 129546, DS: "Ordem de serviço"}]
});
```

### Inspecionar estado de componente pelo code

```js
await page.evaluate((code) => {
  const el = document.querySelector(`[data-code="${code}"], [code="${code}"]`);
  if (!el) return null;
  const scope = angular?.element(el)?.scope?.() || angular?.element(el)?.isolateScope?.();
  const keys = Object.keys(scope || {}).filter(k => !k.startsWith('$'));
  return Object.fromEntries(keys.map(k => {
    try { return [k, JSON.stringify(scope[k])?.substring(0, 100)]; } catch { return [k, 'circular']; }
  }));
}, 129546);
```

### Seletores confirmados por tipo de componente

| Componente | Seletor do input |
|---|---|
| `tasy-wtextbox` | `input[ng-model="value"]` ou `input[ng-model="viewValue"]` |
| `tasy-wtextboxlocator` (FK + lupinha) | `input[ng-model="value"]` (valor) + `input[type="button"]` (lupa) |
| `tasy-wautocomplete` | `input[ng-model="viewValue"]` |
| `tasy-wfilter` botão pesquisar | `.wfilter-bottom .btn-green` |
| DatePicker | `input[ng-model="input.dateValue"]` — **NÃO usar fill()**, usar `page.evaluate` |

### ButtonType — classes CSS

| Tipo | Classe |
|---|---|
| OK / Salvar | `.btn-blue` |
| Cancelar | `.btn-gray` |
| Filtrar / Pesquisar | `.btn-green` |

---

## Guia de Testes por Tipo de Tarefa

### 1. Reproduzir cenário de bug

1. Login → navegar para a função citada no card
2. Reproduzir os passos (preencher campos, selecionar registros, executar ações)
3. Capturar comportamento observado (snapshot, console errors, valores de scope)
4. Comparar com o esperado descrito no card

### 2. Validar correção de código

1. Confirmar que o servidor local está com o código corrigido
2. Acessar a função → executar o fluxo do bug
3. Verificar que o comportamento está correto
4. Capturar evidência (snapshot ou log de console)

### 3. Rastreio tela → código → banco

| Camada | Como verificar |
|---|---|
| **Tela** | `browser_snapshot` + `browser_evaluate` (Angular scope) |
| **JS** | `onBeforePerform`, `onAfterPerform`, `action()` no `.js` da função |
| **Backend Java** | `*Servidor.java` → `*Action.java` |
| **PL/SQL** | enum `*ProcEnum` → arquivo `.prc` no repositório |
| **Banco** | `mcp_oracle2_execute_select_query` (Financial) ou `mcp_oracle_execute_select_query` (Dev) |

### 4. Capturar erros de console

```js
const errors = [];
page.on('console', msg => { if (msg.type() === 'error') errors.push(msg.text()); });
// ... executar ações ...
return errors;
```

---

---

## Anti-patterns

| Anti-pattern | Problema | Solução |
|---|---|---|
| Agir sem verificar screenshot primeiro | Estado real da tela pode ser diferente do esperado | Sempre tirar screenshot e ver antes de agir |
| `page.mouse.click(x, y, { button: 'right' })` | AngularJS não recebe | `dispatchEvent('contextmenu')` no overlay |
| `fill()` em DatePicker | Não dispara modelo Angular | `page.evaluate()` com `angular.element(input).scope()` |
| Clicar lupinha sem aguardar estabilização | Abre localizador errado | Aguardar `input[type="button"]:not([disabled])` |
| `lupaBtn.click({ force: true })` | Clica elemento errado | Remover `force: true` |
| `.click()` simples em botão de localizador corManOS | AngularJS não dispara evento | Usar `dispatchEvent` com `mousedown + mouseup + click` no panel 280733 |
| Clicar lupinha no panel 129569 (corManOS) | Panel errado; localizador não abre | Usar panel **280733** para abrir o localizador de OS |
| Right-click antes do OK no modal | OS não carregada ainda | Fluxo: filtrar → selecionar → OK → aguardar → right-click |
| `locator.all()` + `isVisible()` para iterar | Locators podem não ser visíveis | `locator.count()` + `.nth(i)` |
| Assumir que grid tem dados sem verificar | Filtro pode não ter retornado resultados | Checar `.slick-row` antes de selecionar linha |
| `dispatchEvent('contextmenu')` sem coordenadas em grid WCPanel | Não abre o menu | `MouseEvent('contextmenu')` com `clientX/clientY` + `button:2` no `.slick-viewport` do painel |
| Reabrir filtro clicando nos tokens (`De:`, `Situação:`) | Não reabre o formulário | Clicar o **funil azul** (`tasy-wlabel.filter-icon` sem `ng-hide`) |
| Confiar em `scope.visible` do `tasy-wfilter` | Fica `true` "stale" com o form fechado | Validar pela presença dos inputs (ex: botão "Filtrar") |
| Digitar data e filtrar sem verificar o modelo | `input.dateValue` pode não commitar → usa data antiga | Conferir `angular.element(input).scope().input.dateValue` |
| Encerrar o teste ao ver loader "Por favor, aguarde..." | Operações pesadas (>1000 registros) demoram 30s+ | Aguardar em loop até o loader sumir ou surgir erro |

---

## Observações do Ambiente

- **Alertdialog de objetos inválidos** — aparece no login em alguns ambientes (especialmente local); fechar com "Ok"
- **Combobox "Data" do localizador** — opções: `---` (sem filtro), `Ordem`, `Baixa`
- **Backspace** — fecha o detalhe do WDBPanel e volta ao estado inicial
- **SlickGrid no localizador** — dados em `.slick-row` / `.slick-cell`; verificar `Registros: X - Y de Z` para total
- **Loader de requisição** — operações pesadas exibem `alertdialog` "Por favor, aguarde enquanto o sistema carrega sua requisição... N% Carregando"; pode levar 30s+ para milhares de registros. Aguardar até sumir ou surgir erro.
- **Erro de SQL no backend** — surge como `alertdialog` "Houve um erro na execução da aplicação — Detalhes: 500 Exception - Error executing SQL statement". O SQL/stack **não** aparece no diálogo (o link `wheb_arquivos.jsp` exige auth → `fetch` retorna 401). Para saber o erro exato, reproduzir a query no banco via MCP Oracle ou solicitar ao usuário para verificar o log do erro no tasyAppServer.
- **Ambientes disponíveis:**
  - `http://localhost:3000/#/login` — local
  - `https://dev-tasy.whebdc.com.br/#/login` — Dev
  - `https://financial-accounting.devops.whebdc.com.br/#/` — Financial Accounting

---

## 📚 Skills de Função — Conhecimento de Negócio

Cada função do Tasy tem uma **skill dedicada** com: identidade, chamadas externas de saída e entrada, campos relevantes, comportamentos de negócio e dados de teste.

**Ao iniciar um teste em qualquer função, carregar a skill correspondente com `read_file` antes de agir.**

### Mapa de skills por função

| Função | cd_funcao | Módulo | Skill file |
|---|---|---|---|
| Gestão de Ordens de Serviço (corManGO) | 296 | corMan | `.github/skills/corman-go\SKILL.md` |
| Ordem de Serviço (Nova) (corManOS) | 297 | corMan | `.github/skills/corman-os\SKILL.md` |
| Ordem de Serviço legado | 299 | corMan (Delphi) | — |
| Títulos a Pagar (corCpaF1) | 851 | corCpa | `.github/skills/corcpa\SKILL.md` |
| Consulta de Títulos a Pagar (corCpaF4) | 854 | corCpa | `.github/skills/corcpa\SKILL.md` |
| *(demais funções)* | — | — | *(a criar conforme necessidade)* |

> Funções sem skill ainda: criar ao trabalhar o primeiro card daquela função. Usar `corman-os\SKILL.md` como template de estrutura.

### Como carregar a skill de uma função

```
read_file(".github/skills/<nome-skill>\SKILL.md")
```

Ao navegar de uma função para outra (ex: corManGO → corManOS), carregar a skill da função de destino também.

---

## 🔄 Regra de Auto-Alimentação das Skills de Função

**Após cada sessão de teste, atualizar a skill da função trabalhada** com:

### O que registrar na skill da função (ex: `corman-os\SKILL.md`)

- **Chamada externa confirmada:** nova relação de chamada entre funções descoberta
- **Fluxo validado:** sequência de passos que funcionou para abrir/navegar
- **Seletor confirmado:** novo seletor de campo ou botão identificado
- **Dado de teste:** OS, NR_SEQUENCIA ou registro que serve como cenário confiável
- **Comportamento de negócio:** ex: dialog que aparece em determinada situação, campo que só habilita sob certa condição
- **Bug ou limitação:** ex: "digitar no campo X não recarrega o painel — usar Localizador"

### O que registrar em `/memories/repo/tasy-playwright-testing.md`

- **Padrão de interação** que funcionou onde outros falharam
- **Anti-pattern confirmado** com o motivo do problema
- **Tempo de espera calibrado** para um fluxo específico

### Critério para registrar

Registrar quando o aprendizado for:
- **Reutilizável** para sessões futuras ou outros cards
- **Não óbvio** — requereria redescoberta sem a documentação
- **Validado** — confirmado que funcionou, não apenas tentado

