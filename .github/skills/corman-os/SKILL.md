---
name: corman-os
description: Business knowledge for "Ordem de Serviço (Nova)" (cd_funcao=297, corMan module). Activates: When testing, navigating or developing the corManOS function, Ordem de Serviço Nova, OS creation/editing, OS Quality tab, OS email dialog, or any card related to cd_funcao 297.
---

# corManOS — Ordem de Serviço (Nova)

| Atributo | Valor |
|---|---|
| **cd_funcao** | 297 |
| **Módulo** | corMan |
| **Nome** | Ordem de Serviço (Nova) |
| **Plataforma** | HTML5 / Java |
| **Tabela principal** | `man_ordem_servico` |

---

## Funções que esta função CHAMA (chamadas externas de saída)

| Função chamada | Como abre | Condição |
|---|---|---|
| Localizador de OS (WStandarLocator) | Lupinha do campo `NR_SEQUENCIA` | Sempre disponível na aba ativa |
| Localizador de Pessoa | Lupinha do campo `CD_PESSOA_SOLICITANTE` | Ao editar o solicitante |
| *(outras a confirmar)* | — | — |

---

## Funções que CHAMAM esta função (chamadas externas de entrada)

| Função de origem | Como chama | O que chega pré-preenchido |
|---|---|---|
| **corManGO** (cd_funcao=296) | Opção "Abrir esta OS" (More Actions da linha) | OS já selecionada e carregada |
| **corManGO** (cd_funcao=296) | Opção "Nova ordem de serviço" → dialog de origem → OK | Origem (e Tipo, se Qualidade) pré-definidos |
| Abertura direta pelo menu | Usuário busca e clica na função | Origem definida pelo parâmetro 92 (default: Manutenção) |

---

## Painéis e Visões por Origem

O painel principal usa um **combobox seletor** para alternar entre visões de acordo com a origem da OS:

| Valor do combobox | Nome da aba | `IE_ORIGEM_OS` | Tipo de OS |
|---|---|---|---|
| `129546` | Dados de Manutenção | 1 | OS de Manutenção (padrão) |
| `129547` | Philips Systems | — | OS Philips Systems |
| `129552` | Suporte Técnico | — | OS Suporte Técnico |
| `129553` | Philips SO Pred Consult | — | OS Philips (consultoria) |
| `346085` | Dados de Qualidade | 6 | OS de Qualidade |

### Como verificar a aba ativa via snapshot

O combobox aparece no início do snapshot:
```yaml
combobox [ref=eXXXX]:
  - generic: Qualidade   ← aba ativa
```

### Como verificar via Angular scope

```js
await page.evaluate(() => {
  const dropdown = document.querySelector('.wschematic-dropdown [role="combobox"]');
  return angular.element(dropdown).scope()?.selectedValue;
});
```

---

## WDBPanels confirmados (cd_funcao=297)

| dto-code | Descrição |
|---|---|
| `129569` | Painel principal da OS (formulário de detalhe) |
| `280733` | Segundo painel (contém lupinha do NR_SEQUENCIA) |
| `346093` | Painel da aba Qualidade (WDBPanel específico) |
| `132121` | Painel da aba Philips Systems (WDBPanel específico) |

---

## Aba Qualidade (346085) — campos principais

| Campo | Descrição |
|---|---|
| `NR_SEQUENCIA` | Número da OS — campo FK com lupinha |
| `CD_PESSOA_SOLICITANTE` | Código da pessoa solicitante |
| `IE_TIPO_ORDEM` | Tipo da OS (6 = Qualidade) |
| `DS_DANO_BREVE` | Descrição breve do problema |
| `DT_INICIO_DESEJADO` | Data início desejada |

### Carregar OS na aba Qualidade — usar Localizador

> **PROBLEMA CONHECIDO:** Digitar direto no campo `NR_SEQUENCIA` e clicar o botão ao lado **não atualiza** `CD_PESSOA_SOLICITANTE` nem outros campos — ficam com dados da OS anterior. Usar sempre o **Localizador (lupinha)**.

**Fluxo correto:**
1. Verificar que o combobox está em `346085` (Qualidade)
2. Abrir Localizador via `isolateScope().openSelectionLocatorIcon()`
3. Limpar filtros, pesquisar por `NR_SEQUENCIA`
4. Selecionar linha → OK
5. Aguardar 3–5 segundos para os dados carregarem

```js
// Abrir localizador — método correto para corManOS
await page.evaluate(() => {
  const loc = document.querySelectorAll('tasy-wtextboxlocator')[0];
  const isolate = angular.element(loc).isolateScope();
  isolate.$apply(() => isolate.openSelectionLocatorIcon());
});
await page.waitForTimeout(800);
```

---

## Dialogs específicos desta função

### Dialog "Deseja iniciar atividade nesta OS?"

Aparece ao abrir uma OS de Qualidade. **Sempre clicar Cancelar** em testes — clicar OK inicia uma atividade real na OS.

> **Atenção:** Este dialog NÃO tem `role="alertdialog"` ou `role="dialog"` — `querySelectorAll('[role="alertdialog"]')` não o encontra. Usar `.ngdialog-content` para detecção.

```js
// Detectar se dialog está aberto
const dialogAberto = await page.evaluate(() => {
  const dialogs = Array.from(document.querySelectorAll('.ngdialog-content'))
    .filter(el => el.offsetParent !== null);
  return dialogs.some(d => d.textContent.includes('iniciar atividade'));
});

// Clicar Cancelar
await page.evaluate(() => {
  const btns = Array.from(document.querySelectorAll('button'));
  btns.find(b => b.offsetParent !== null &&
    (b.textContent.trim() === 'Cancelar' || b.textContent.trim() === 'Não'))
    ?.dispatchEvent(new MouseEvent('click', { bubbles: true }));
});
```

### Dialog de E-mail (code=129025)

Acessado via **More Actions** do handlebar superior — **não** está no menu contextual (botão direito).

```js
// Clicar E-mail — o botão fica DIRETAMENTE na handlebar (button.handlebar-button)
// NÃO está em More Actions em todas as configurações
await page.evaluate(() => {
  const emailBtn = Array.from(document.querySelectorAll('button.handlebar-button'))
    .find(el => el.offsetParent !== null && el.textContent.trim() === 'E-mail');
  if (emailBtn) {
    emailBtn.dispatchEvent(new MouseEvent('click', { bubbles: true }));
  } else {
    // Fallback: tentar via More Actions
    Array.from(document.querySelectorAll('[aria-label="More actions"]'))
      .forEach(btn => btn.dispatchEvent(new MouseEvent('click', { bubbles: true })));
  }
});
await page.waitForTimeout(3000);

// Ler DS_EMAIL_DESTINO
const email = await page.evaluate(() =>
  document.querySelector('input[name="DS_EMAIL_DESTINO"]')?.value ?? 'não encontrado'
);
```

**Campos do dialog de E-mail:**

| Campo | Comportamento esperado |
|---|---|
| `DS_EMAIL_DESTINO` | Preenchido automaticamente com e-mail do solicitante (`obter_compl_pf`) |
| `IE_TIPO_RELATORIO` | Setado automaticamente conforme o tipo de OS |

**Query backend (dic_objeto código 209729):**
```sql
select obter_compl_pf(:cd_solicitante, 1, 'M') ds_email_destino from dual
```
O parâmetro `:cd_solicitante` vem do WDBPanel da aba ativa:
- Aba PHILIPS_SYSTEMS → `schematics.get(132121)`
- Aba QUALITY → `schematics.get(346093)` *(adicionado no fix do card 728384)*

---

## WPUMCs confirmados

| w-code | Descrição |
|---|---|
| 418592 | Gerar preventiva |
| 418614 | Gerar ordem de serviço protocolo |
| 418622 | Obter anexo(s) / histórico(s) OS via WS |
| 418633 | Alterar grau satisfação |
| 956560 | Localizar ordem de serviço |

---

## Parâmetros de função relevantes

| Nr | Descrição | Valores | Impacto |
|---|---|---|---|
| 92 | Origem padrão da OS ao abrir diretamente | código de origem | Define qual aba/visão carrega por padrão |
| 40 | Habilitar "Alterar grau satisfação" | `'E'` = só encerrada | Controla visibilidade do WPUMC 418633 |
| 82 | Permite alterar grau de satisfação | `'S'`/`'N'` | Habilita/desabilita o WPUMC |
| 214 | Restringe ao usuário solicitante | `'S'`/`'N'` | Filtra acesso |
| 181 | Permite visualizar campo "Origem Dano" (`NR_SEQ_ORIGEM_DANO`) | `'S'`/`'N'` | Quando `!= 'S'`, o campo fica oculto (`setVisible(false)`) e o label de `IE_FORMA_RECEB` é trocado. Campo aparece na aba **Detalhes**, logo após "Forma registro", com o label genérico **"Origem"** (não "Origem Dano") — cd_funcao usado na consulta do parâmetro é o legado **299**, mesmo na tela HTML5 (297) |

---

## Regra de negócio — Restrição de Origem do Dano por Grupo de Trabalho/Planejamento

A "Origem do Dano" (`NR_SEQ_ORIGEM_DANO`, tabela `man_origem_dano`) pode ser **restrita** a um ou mais Grupos de Trabalho e/ou Grupos de Planejamento específicos, via tabelas de vínculo:

| Tabela | Vínculo |
|---|---|
| `man_origem_dano_trab` | `NR_SEQ_ORIGEM_DANO` ↔ `NR_SEQ_GRUPO_TRABALHO` |
| `man_origem_dano_planej` | `NR_SEQ_ORIGEM_DANO` ↔ `NR_SEQ_GRUPO_PLANEJAMENTO` |

**Regra de visibilidade** (função `MAN_OBTER_SE_ORIG_DANO_LIB(nr_sequencia, nr_seq_grupo_trab, nr_seq_grupo_planej)`):
- Se a origem **não possui nenhum vínculo** em `man_origem_dano_trab`/`man_origem_dano_planej` → sempre visível (irrestrita), independente do grupo selecionado na OS.
- Se a origem **possui vínculo** → só aparece no combo quando o Grupo de Trabalho ou Grupo de Planejamento selecionado na OS bater com um dos vínculos cadastrados. Caso contrário, fica oculta da lista.

**Consequência para o frontend:** o combo de `NR_SEQ_ORIGEM_DANO` precisa ser **reativado (lookup refresh)** toda vez que `NR_GRUPO_TRABALHO` ou `NR_GRUPO_PLANEJ` mudarem — do contrário a lista fica desatualizada com os parâmetros antigos. O padrão correto (já usado para `NR_SEQ_CAUSA_DANO` via `activateLookupCausaDano`) é chamar `detailHandler.listBox('NR_SEQ_ORIGEM_DANO', { params: { NR_SEQ_GRUPO_TRAB, NR_SEQ_GRUPO_PLANEJ }, type: 'DEFAULT' })` nos handlers `onChangeNrGrupoPlanej` e `onChangenrGrupoTrabalho` de `ManOrdemServicoManutWDBP.js` (bug corrigido no card 731440 — ver `activateLookupOrigemDano` em `CorManOSFactory.js`).

> **Cuidado ao testar:** o combo "Grupo de trabalho" na tela pode não listar todos os grupos ativos vinculados ao estabelecimento do usuário (causa não totalmente identificada — grupo `NR_SEQUENCIA=14` "TI - Equipamentos (Hardware)", ativo e do mesmo estabelecimento dos demais, não apareceu na lista de opções durante teste). Se o grupo esperado não aparecer no combo, considerar setar o vínculo de teste em um grupo que já apareça na lista, em vez de investigar o porquê do grupo estar ausente.

---

## Comportamento — Troca de Abas

Quando corManOS está em **modo edição, More Actions aberto ou dialog ativo**, a aba do corManGO fica com classe `.is-disabled` — não clicável. O snapshot ARIA não reflete esse estado.

```js
// Verificar se aba do corManGO está bloqueada
await page.evaluate(() => {
  return Array.from(document.querySelectorAll('.w-header-tab'))
    .map(t => ({ text: t.querySelector('.w-header-tab__label')?.textContent?.trim(),
                 isDisabled: t.classList.contains('is-disabled') }));
});
// Resolver: Escape → fechar menus/dialogs → cancelar edição
```

---

## Dados de Teste — Ambiente Local (Financial)

### OS de Qualidade com solicitante com e-mail

| NR_SEQUENCIA | IE_TIPO_ORDEM | CD_PESSOA_SOLICITANTE | E-mail |
|---|---|---|---|
| 141169 | 6 | 100186 | rafael.sampaio@philips.com |
| 139878 | 6 | (verificar) | (verificar) |

> OS 141869 — solicitante 629646 **sem e-mail** — não usar para testar DS_EMAIL_DESTINO.

```sql
-- Encontrar OS de Qualidade com e-mail de solicitante
SELECT m.nr_sequencia, m.cd_pessoa_solicitante,
       obter_compl_pf(m.cd_pessoa_solicitante, 1, 'M') ds_email
FROM man_ordem_servico m
WHERE m.ie_tipo_ordem = 6
  AND obter_compl_pf(m.cd_pessoa_solicitante, 1, 'M') IS NOT NULL
  AND ROWNUM <= 10
ORDER BY m.nr_sequencia DESC;
```

---

## Histórico técnico da OS — painéis e edição em grid

Cada visão da OS tem seu próprio painel de histórico técnico (campo rich text `DS_RELAT_TECNICO`):

| Visão | WDBPanel | WRE (rich edit) |
|---|---|---|
| Manutenção | `ManOrdemServTecnicoManutWDBP` (280733) | `ManOrdemServTecnicoManutWRE` (280734) |
| Qualidade | `ManOrdemServTecnicoQuaWDBP` (346111) | — |
| BSC | `ManOrdemServTecnicoBSCWDBP` (346317) | — |
| Philips Systems | `ManOrdemServTecnicoDesenvWDBP` | — |

### IE_ORIGEM_OS (origem da OS) — mapeamento
- **4 = Manutenção** (maioria dos registros; servida pelo painel de histórico 280733).
- **6 = Qualidade**.
- **1 = Sistemas Philips** — **depreciada/uso interno**; não considerar em ajustes/testes (salvo se for causa raiz de menção indevida afetando outras origens).
- No fonte, `validatePermissionChangeHistoryOS` roteia `IE_ORIGEM_OS == '1'` para `...OSDev`; demais para `...OSMan`.

### Edição do histórico em grid e auto-save (card 734952)

- **Read-only do texto em grid:** o histórico é master-detail; em modo grid o framework marca os campos do detalhe como `internalReadOnly=true` (preview). Para permitir editar **só o texto** (`DS_RELAT_TECNICO`) em grid, `setReadOnlyRichEdit` aplica `setInternalReadOnly(value)` **além** de `setReadOnly(value)`, apenas nesse campo. Demais campos (`NR_SEQ_TIPO`, `IE_ORIGEM`) seguem editáveis só no detalhe; históricos liberados (`DT_LIBERACAO` preenchida) seguem read-only. (Mecanismo genérico em `frontend-framework.md`.)
- **Auto-save removido:** o `onBlur` do WRE chamava `saveRecord()` direto em grid (gate `canGridChange`, setado com um `focus` global indefinido → sempre truthy). Corrigido: removido o `saveRecord()` e o `canGridChange`; mantida só a marcação de dirty (`getDetailHandler().getForm().$setDirty(true)`) — a gravação passa a ser só pelo botão Salvar.
- **Padrão irmão:** Qualidade e BSC já fazem `setInternalReadOnly(true)` em grid no `onSelectionChange` (querem o texto read-only em grid). A visão Manutenção não gerenciava esse flag antes do card 734952.
- **Comparação:** na função "Comunicação Interna" (corSisF8, cd_funcao 87) o rich text `DS_COMUNICADO` é editável em grid sem tratamento algum — porque o campo está no próprio painel/grid (não é preview de detalhe de master-detail).
