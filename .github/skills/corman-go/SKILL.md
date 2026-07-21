---
name: corman-go
description: Business knowledge for "Gestão de Ordens de Serviço" (cd_funcao=296, corMan module). Activates: When testing, navigating or developing corManGO, Gestão de OS, OS listing, OS filter, or any card related to cd_funcao 296.
---

# corManGO — Gestão de Ordens de Serviço

| Atributo | Valor |
|---|---|
| **cd_funcao** | 296 |
| **Módulo** | corMan |
| **Nome** | Gestão de Ordens de Serviço |
| **Plataforma** | HTML5 / Java |

> Função de **consulta e navegação**. Não cria nem edita OS — para isso usa corManOS (cd_funcao=297).

---

## Funções que esta função CHAMA (chamadas externas de saída)

| Função chamada | Como abre | Dados enviados |
|---|---|---|
| **corManOS** (cd_funcao=297) | Opção "Abrir esta OS" (More Actions da linha) | OS selecionada é carregada na função |
| **corManOS** (cd_funcao=297) | Opção "Nova ordem de serviço" → dialog de origem → OK | Origem (e Tipo, se Qualidade) pré-definidos |

---

## Funções que CHAMAM esta função (chamadas externas de entrada)

> corManGO é tipicamente aberta diretamente pelo menu de funções do Tasy. Não é uma chamada externa de outras funções.

---

## O que é

Painel de **listagem e filtro** de OSs com ações de contexto (More Actions e botão direito). Os resultados aparecem em SlickGrid. Permite: filtros avançados, visualização de históricos, anexos, usuários controle e navegação para a OS em corManOS.

---

## Filtro

O painel abre com o filtro fechado (ou com filtros salvos anteriormente). Clicar "Filtrar" após preencher os campos.

**Campos de filtro relevantes:**

| Campo | Tipo | Descrição | Valores confirmados |
|---|---|---|---|
| `IE_ORIGEM_OS` | combobox | Origem da OS | 1=Manutenção, 2=Ativos, 3=Philips, 4=Sistema, 5=Suporte Técnico, 6=Qualidade |
| `NR_SEQUENCIA` | textbox | Número da OS | inteiro |
| `DT_INICIO_PREVISTO` | datepicker | Data início previsto | DD/MM/YYYY |
| `DT_FIM_PREVISTO` | datepicker | Data fim previsto | DD/MM/YYYY |

> `IE_ORIGEM_OS` é combobox Angular — requer `dispatchEvent` ou ngModel. **Não usar `.fill()`**.

### Filtrar por NR_SEQUENCIA — método confirmado

O campo `NR_SEQUENCIA` tem `name="NR_SEQUENCIA"` nos inputs. As datas `DT_INICIO`/`DT_FIM` são preenchidas automaticamente com a data de hoje quando o filtro reabre — sempre limpar antes de filtrar por outros critérios.

```js
// Preencher NR_SEQUENCIA e limpar datas
await page.evaluate(() => {
  const nrSeqInput = Array.from(document.querySelectorAll('input[name="NR_SEQUENCIA"]'))
    .find(el => el.offsetParent !== null);
  if (nrSeqInput) {
    const scope = angular.element(nrSeqInput).scope();
    if (scope) scope.$apply(() => { scope.value = 141169; });
    nrSeqInput.value = '141169';
    angular.element(nrSeqInput).triggerHandler('change');
  }

  // Limpar DT_INICIO e DT_FIM
  ['DT_INICIO', 'DT_FIM'].forEach(name => {
    const el = document.querySelector(`input[name="${name}"]`);
    if (!el) return;
    const scope = angular.element(el).scope();
    if (scope) scope.$apply(() => { scope.value = null; });
    el.value = '';
    angular.element(el).triggerHandler('change');
  });
});

// Clicar Filtrar (ref do snapshot ou via role)
await page.getByRole('button', { name: 'Filtrar' }).click();
await page.waitForTimeout(4000);
```

### Filtrar por Origem via combobox confirmado

O campo Origem é `combobox "Origem"` no snapshot ARIA. O combobox já vem com "Qualidade" se o filtro foi salvo anteriormente (caso nesta sessão).

### Verificar resultados do grid

```js
const rows = document.querySelectorAll('.slick-row');
const osNumbers = Array.from(rows).map(row => {
  for (const cell of row.querySelectorAll('.slick-cell')) {
    if (/^\d{6}$/.test(cell.textContent.trim())) return cell.textContent.trim();
  }
  return null;
}).filter(Boolean);
```

---

## Ações sobre uma OS selecionada (More Actions da linha)

### Abrir OS existente em corManOS

```js
// 1. Selecionar a linha no SlickGrid
await page.evaluate(() => {
  document.querySelector('.slick-row')?.click();
});
await page.waitForTimeout(300);

// 2. Abrir More Actions (disparar em todos os botões visíveis)
await page.evaluate(() => {
  Array.from(document.querySelectorAll('[aria-label="More actions"]'))
    .forEach(btn => btn.dispatchEvent(new MouseEvent('click', { bubbles: true })));
});
await page.waitForTimeout(600);

// 3. Clicar "Abrir esta OS"
await page.evaluate(() => {
  const items = document.querySelectorAll('.handlebar-more-menu-item, .handlebar-button');
  for (const item of items) {
    if (item.offsetParent !== null && item.textContent.trim() === 'Abrir esta OS') {
      item.dispatchEvent(new MouseEvent('click', { bubbles: true }));
      break;
    }
  }
});
await page.waitForTimeout(3000);
// → corManOS abre com a OS selecionada
// → Se OS de Qualidade: pode aparecer dialog "Deseja iniciar atividade?" → Cancelar
```

### Criar nova OS

Opção de mouse **"Nova ordem de serviço"** abre dialog de seleção de origem. OSs de Qualidade requerem também o campo "Tipo". Confirmar com OK abre corManOS.

---

## Opções de mouse confirmadas

| Opção | Tipo | Observação |
|---|---|---|
| Abrir esta OS | More Actions da linha | Chama corManOS com a OS carregada |
| Nova ordem de serviço | More Actions / botão direito | Chama corManOS via dialog de origem |

---

## Comportamento — Troca de Abas

Quando corManOS está com More Actions expandido, dialog aberto ou modo edição ativo, a aba do **corManGO** recebe classe `.is-disabled` e bloqueia cliques. O snapshot ARIA não reflete esse estado.

```js
// Verificar estado das abas
await page.evaluate(() =>
  Array.from(document.querySelectorAll('.w-header-tab'))
    .map(t => ({
      text: t.querySelector('.w-header-tab__label')?.textContent?.trim(),
      isDisabled: t.classList.contains('is-disabled')
    }))
);
// Resolver: Escape → fechar menus/dialogs → cancelar edição no corManOS
```
