# Schematics DX

> Referência do agente **Tasy HTML5 Developer**. Carregar ao editar ou investigar arquivos JSON de schematics (`TasyAppServer/src/main/resources/schematics/`).

O **Schematics DX** é o sistema de configuração de telas do Tasy. Substituiu o Schematics legado (cujas configurações ficavam armazenadas em banco de dados) passando as definições para arquivos **JSON** no backend Java. Algumas funcionalidades ainda permanecem via banco.

## Migração por versão e impacto no versionamento de bugs

As funções foram migradas do Schematics Legado para o DX em **versões diferentes**. A maioria das funções foi convertida na versão 1848, mas algumas foram convertidas em versões anteriores (1842, 1845). Essa diferença impacta diretamente como um bug de Schematics é versionado:

> **Atenção: as regras abaixo sobre ausência de PR são exclusivas para correções de Schematics DX.** Para alterações de código-fonte (Java, JavaScript, PL/SQL), é sempre esperado um PR para cada versão afetada. A ausência de um PR de código-fonte para uma versão deve ser tratada como pendência.

- **Versões com DX**: a correção é feita via PR no backend (arquivo JSON do schematics). Haverá um PR de backend para cada versão convertida.
- **Versões sem DX (anteriores à conversão)**: a correção é feita no **Schematics Legado** (banco Oracle), e o fix chega ao cliente via release, sem PR de backend. O fluxo de release é mantido para todas as versões de mercado mesmo assim, a fim de evitar conflitos em alterações futuras.

**Exemplo:** função convertida para DX na versão 1848. Bug que afeta versões 1838, 1842, 1845, 1848:
- PR de backend somente para `pre_main` e `5.06.1848` (versões com DX)
- Versões 1838, 1842, 1845 recebem a correção via alteração no Schematics Legado + release

> **Como saber em qual versão a função foi convertida:** verificar se o arquivo JSON do schematics da função existe na branch da versão pretendida no repositório backend. Se o arquivo não existir na branch, aquela versão ainda usa o Schematics Legado e a correção deve ser feita via banco. Exemplo: `git show 5.03.1842:TasyAppServer/src/main/resources/schematics/corfinf2/cpanels/795296.json` — se retornar erro, a versão 1842 não tem DX para aquela função.

## Estrutura de arquivos

Os arquivos ficam em `TasyAppServer/src/main/resources/schematics/<módulo>/`. Exemplo para `corfinf2`:

```
corfinf2/
  corfinf2.json           # raiz da função: lista de dialogs, tabs, parâmetros globais
  corfinf2.es-CO.json     # override de localização (Colômbia, México, etc.)
  dbpanels/
    33724.json            # WDBPanel — campos, atributos, critérios
  filters/
    702480.json            # WFilter — campos do formulário de filtro
  dialogs/
    dlg-701981.json        # WDLG — estrutura do dialog, botões, actions
    dlg-701981.es-CO.json  # override de localização do dialog
  cpanels/
    702483.json            # CPanel — colunas de um painel de listagem
  dynamic-forms/
    ...
```

**Arquivos de localização** (`.es-CO.json`, `.pt-BR.json`, etc.) usam formato **JSON Patch** com `migrations[]` para sobrescrever propriedades específicas do JSON base, evitando duplicação. Exemplo:
```json
{
  "identifier": "es-CO",
  "migrations": [
    { "op": "replace", "path": "/children/code:702008/dictionaryCode", "value": 1218719 }
  ],
  "type": "LOCALE",
  "version": "1.9.2"
}
```

> **Cuidado ao commitar (mudanças espúrias no `.pt-BR.json`/locale):** sessões do editor de Schematics no ambiente local podem regravar automaticamente o arquivo de localização da função, adicionando migrations não relacionadas ao card (ex: `popUpHandle`, `nrSeqApres` de legendas, bump de `version`). Ao preparar o commit, **revisar o diff** desses arquivos de locale e **não incluí-los** se as mudanças não fizerem parte do card. Adicionar ao stage apenas os arquivos efetivamente alterados para a demanda — nunca `git add .`.

---

## JSON raiz da função (`corfinf2.json`)

Define os **dialogs** registrados na função e configurações globais como `avoidMemoryLeaks`.

```json
{
  "avoidMemoryLeaks": true,
  "dialogs": [
    {
      "code": 701981,
      "route": "dlg-701981",
      "title": "Change card authorization",
      "titleExpressionCode": 596471
    }
  ]
}
```

- `code` — código único do dialog, referenciado no frontend via `schematics.get(code)`
- `route` — nome do arquivo JSON do dialog dentro de `dialogs/`
- `titleExpressionCode` — código da expressão (tabela `dic_expressao`) para o título traduzido

### ⚠️ Criação de WDLG — sempre pelo builder, a partir do Schematic (root)

Uma WDLG **não deve ser criada escrevendo o arquivo `dialogs/dlg-<code>.json` na mão**. Criar apenas o arquivo não registra o dialog na lista `dialogs` do JSON raiz da função, e a rota `dlg-<code>` não é resolvida — o `openWDLG` falha com erro em tela.

O caminho correto é pelo Schematics DX Builder:

1. Abrir o builder e selecionar o nó **Schematic (root)** na árvore da esquerda (a tela fica com o título `Settings of: [<code>] <Nome da função>`).
2. Ir na aba **Dialogs** — ela lista todas as rotas já registradas (`dlg-834346`, `dlg-1265596`, ...).
3. Usar o botão **Add** no rodapé da lista para criar a nova WDLG (e **Delete** para remover).
4. Depois, selecionar a WDLG criada na árvore para montar os componentes filhos (botões OK/Cancel, WDYNAMICFORM, etc.).

O builder grava as duas pontas de uma vez: o novo `dialogs/dlg-<code>.json` **e** a entrada correspondente em `"dialogs"` no JSON raiz.

> Se por algum motivo o arquivo do dialog já existir sem o registro (ex: arquivo copiado de outra função), a correção é adicionar manualmente a entrada no array `dialogs` do JSON raiz, com `code`, `route`, `title` e `titleExpressionCode`.

---

## JSON de WDBPanel (`dbpanels/<code>.json`)

Define os campos (atributos) exibidos no painel, critérios de query e todos os metadados de cada campo.

```json
{
  "allAttributes": ["NR_SEQUENCIA", "NR_TITULO", "VL_RECEBIDO", ...],
  "allCriteria": {
    "11854": " and NR_SEQ_CAIXA_REC = :NR_SEQ_CAIXA_REC"
  },
  "attributes": [
    {
      "code": 770646934,
      "nmAtributo": "NR_SEQ_TRANS_CAIXA",
      "componente": "LISTBOX",
      "dbPanelComponentType": "LCB",
      "label": "Transação",
      "labelExpressionCode": 300322,
      "tipoAtributo": "NUMBER",
      "enabled": true,
      "readOnly": false,
      "ieVisible": true,
      "mandatory": false,
      "primaryKey": false,
      "foreignKey": false,
      "largura": 12,
      "widthHTML": 500,
      "row": 10,
      "ordem": 220,
      "tabStop": true,
      "binds": ["CD_EMPRESA", "CD_ESTABELECIMENTO", "NR_SEQ_CAIXA"],
      "dsValores": "select nr_sequencia cd, ds_transacao ds from transacao_financeira where ...",
      "tooltip": "Selecione a transação financeira...",
      "tooltipExpressionCode": 561320
    }
  ]
}
```

**Propriedades principais de um atributo:**

| Propriedade | Descrição |
|---|---|
| `code` | Código único do campo no Schematics |
| `nmAtributo` | Nome da coluna no banco de dados |
| `componente` | Tipo de componente UI: `TEXTBOX`, `LISTBOX`, `DATETIMEPICKER`, `RADIOGROUP`, `CHECKBOX`, etc. |
| `dbPanelComponentType` | Tipo interno: `DE` (descrição/FK), `LCB` (listbox), `DTP` (datepicker), etc. |
| `tipoAtributo` | Tipo de dado: `NUMBER`, `VARCHAR`, `DATE`, `VISUAL` |
| `label` / `labelExpressionCode` | Label do campo / código da expressão para i18n |
| `gridLabel` / `gridLabelExpressionCode` | Label da coluna no grid |
| `gridSequence` | Ordem no grid |
| `largura` | Largura em colunas (grid de 12) |
| `widthHTML` | Largura em pixels na grid. **Deve ser sempre múltiplo de 50** (50, 100, 150, 200...1000) — no Schematics DX Builder é um `tasy-listbox` (lista fechada), não texto livre. Um valor fora dessa lista (ex.: 120, 130, 110) não gera erro de parse no JSON, mas ao salvar o campo pelo Builder ("WDBPANEL Settings") gera `DbPanelMetaAttribute: <CAMPO> value must match one of the values in the list`. |
| `row` | Linha no layout do detalhe |
| `ordem` | Ordem de exibição |
| `enabled` / `readOnly` / `ieVisible` / `mandatory` | Estado inicial do campo |
| `primaryKey` / `foreignKey` | Indica se é PK ou FK |
| `criarDescFk` | Se `true`, o framework cria automaticamente um campo de descrição para FKs |
| `dsValores` | SQL para lookup (LISTBOX) ou para buscar descrição de FK (`tabela;campo_desc;tabela_origem;;restricao;`) |
| `binds[]` | Parâmetros do formulário injetados na query `dsValores` via `:param` |
| `sqlRestriction` | Fragmento SQL adicionado à query principal quando o campo é usado como filtro |
| `mask` | Máscara de entrada, ex: `"date(shortDate)"` |
| `sensitive` | Se `true`, mascara o valor (dados sensíveis) |
| `logOptions` | Configuração de auditoria do campo |
| `tooltip` / `tooltipExpressionCode` | Texto do **Info button** do campo (ver abaixo) |

**`allCriteria`**: mapa de restrições SQL adicionais indexadas por código, aplicadas à query do WDBPanel conforme o contexto.

### Info button (`tooltip` / `tooltipExpressionCode`)

> **Convenção Tasy:** o texto configurado em `tooltip`/`tooltipExpressionCode` é apresentado como um **Info button** (ícone de informação **i** ao lado do campo) — esse é o termo da convenção Tasy. "Tooltip" é apenas o nome técnico da propriedade no JSON; na documentação de negócio/card usar sempre **Info button**.

- `tooltip` — texto literal de fallback do Info button.
- `tooltipExpressionCode` — código da expressão (`dic_expressao`) usada para o texto traduzível do Info button. Quando preenchido, tem precedência sobre o `tooltip` literal.

Para alterar o texto de um Info button, criar/editar a expressão em `dic_expressao` e apontar o `tooltipExpressionCode` do campo para o novo código. Como o campo existe em cada visão (localidade) da função, o `tooltipExpressionCode` precisa ser atualizado em **todos os dbpanels** correspondentes.

### Ordem e agrupamento de campos (`ordem` / `nrSeqGrupo` / `row`)

A posição de um campo no formulário de detalhe é definida **exclusivamente no JSON** — não há como reposicionar em runtime (ver `frontend-framework.md`).

| Propriedade | Efeito |
|---|---|
| `ordem` | Ordem de exibição do campo dentro do seu grupo/linha. Menor `ordem` aparece primeiro. |
| `nrSeqGrupo` | Agrupa o campo a um grupo visual. Ao mover um campo para fora do seu grupo original, pode ser necessário **remover** o `nrSeqGrupo` para que ele passe a respeitar apenas a `ordem` global. |
| `row` | Linha do campo no layout do detalhe. |

> **Reposicionar um campo:** ajustar o `ordem` (e, se preciso, remover o `nrSeqGrupo`) no JSON do dbpanel. Essa alteração precisa ser replicada em **todas as visões** da função (ver seção Visões), pois cada visão tem seu próprio arquivo de dbpanel com valores de `ordem` independentes.

---

## Visões (localidades) — múltiplos dbpanels por função

Uma mesma função pode ter **vários arquivos de dbpanel**, um por **visão** (view). A visão exibida ao usuário é escolhida conforme a **localidade** (país/região) do estabelecimento — cadastro nas propriedades do usuário. Cada visão tem seu próprio JSON com valores independentes de `ordem`, `nrSeqGrupo`, `tooltipExpressionCode`, etc.

```
corconf1/dbpanels/
  77340.json    # visão base (Brasil e países sem visão própria)
  116120.json   # Colômbia
  109367.json   # Argentina
  101466.json   # Global
  ...
```

> **Consequência prática:** qualquer alteração de layout (mover campo, trocar Info button, ocultar coluna) que deva valer para todos os usuários precisa ser replicada em **cada arquivo de visão** da função. Alterar apenas o dbpanel base corrige somente as localidades que caem na visão base — as demais visões continuam com o comportamento antigo. Ao investigar por que um ajuste "não apareceu" para um usuário, verificar qual visão a localidade dele seleciona.

> A mesma função também pode renderizar diferente entre ambientes se os estabelecimentos tiverem localidades distintas (ex: ambiente local com localidade Global usando `101466.json`, enquanto outro ambiente usa a visão base `77340.json`).

---

## JSON de WFilter (`filters/<code>.json`)

Define os campos do formulário de filtro. Estrutura similar ao WDBPanel, usando `listaMetaAtributos[]`. Campos adicionais específicos do filtro:

```json
{
  "listaMetaAtributos": [
    {
      "code": 574493,
      "componente": "RADIOGROUP",
      "filterComponentType": "WJRB",
      "nmAtributo": "IE_ORIGEM_HIST",
      "label": "Origin",
      "labelExpressionCode": 294924,
      "dsValores": "(1,2,3)(Both,System,User)",
      "optionsExpressionCode": 621873,
      "sqlRestriction": "and ((:IE_ORIGEM_HIST = '1') or (:IE_ORIGEM_HIST = '2' and ie_origem = 'S') ...)",
      "vlDefault": "1",
      "ieSalvar": true,
      "ieTipoAction": "R"
    }
  ]
}
```

- `sqlRestriction` — fragmento SQL injetado na query principal quando o campo tem valor; usa `:NOME_ATRIBUTO` como bind
- `vlDefault` — valor padrão carregado ao abrir o filtro
- `ieSalvar` — se `true`, o valor é salvo como preferência do usuário
- `filterComponentType` — tipo interno do componente de filtro

---

## JSON de Dialog (`dialogs/dlg-<code>.json`)

Define a estrutura de um WDLG: título, componentes filhos, botões e as **actions** disparadas pelos botões.

```json
{
  "code": 701981,
  "componentType": "WDLG",
  "expressionCode": 596471,
  "featureCode": 813,
  "children": [
    {
      "code": 701982,
      "objectType": "BUTTON",
      "buttonType": "OK",
      "expressionCode": 311702,
      "events": [
        {
          "eventType": "C",
          "eventActions": [
            {
              "eventAction": "PROC",
              "procedureCode": 46035,
              "compReactivateCode": 701978,
              "params": [
                { "originParam": "OBJECT", "masterCode": 701978, "masterName": "NR_SEQ_MOVTO_CARTAO", "parameterName": "NR_SEQUENCIA_P" },
                { "originParam": "OBJECT", "masterCode": 701984, "masterName": "NR_AUTORIZACAO",      "parameterName": "NR_AUTORIZACAO_P" },
                { "originParam": "SYSTEM", "masterName": "NM_USUARIO",                               "parameterName": "NM_USUARIO_P" }
              ]
            }
          ]
        }
      ]
    }
  ]
}
```

**Estrutura de uma action no botão OK:**

| Propriedade | Descrição |
|---|---|
| `eventAction` | Tipo da ação: `"PROC"` (procedure), `"REACTIVATE"`, `"CLOSE"`, etc. |
| `procedureCode` | Código da procedure a ser executada |
| `compReactivateCode` | Código do componente a reativar (recarregar) após execução |
| `params[]` | Parâmetros passados à procedure |
| `originParam` | Origem do valor: `"OBJECT"` (campo de um componente) ou `"SYSTEM"` (dado da sessão, ex: `NM_USUARIO`) |
| `masterCode` | Código do componente de origem do parâmetro |
| `masterName` | Nome do campo no componente de origem |
| `parameterName` | Nome do parâmetro na procedure (sufixo `_P`) |

> Esta é a forma declarativa das **Actions**: o framework lê o JSON do dialog, e ao clicar OK executa automaticamente a procedure com os parâmetros mapeados, sem necessidade de código JavaScript. O frontend só precisa de código customizado quando a lógica vai além do que o JSON suporta.

---

## CPanel (`cpanels/<code>.json`)

Define as colunas de um painel de listagem (grid somente leitura). Cada coluna tem `nmCampoBase`, `labelColuna`, `componente`, `qtLargura` (largura em px) e `ieTotalizar` (se exibe totalizador).

---

## Dados mantidos via banco de dados

Algumas configurações ainda residem no banco Oracle:

| Tabela | Conteúdo |
|---|---|
| `dic_objeto` | Consultas SQL (SELECTs) referenciadas por nome (ex: `SELECT_784576`, `GET_MOEDA_PADRAO_EMPRESA`). Usadas pelo backend para executar `executeQueryAsHash`, `executeFunction` e lookups de campos FK |
| `dic_expressao` | Textos/labels traduzíveis, referenciados pelo `expressionCode` / `labelExpressionCode` nos JSONs |
| `dic_expressao_idioma` | Traduções de cada expressão por idioma/localização |
| `dominio` + `valor_dominio` | Valores fixos de domínio usados em `lookUpComboBox` (combos estáticos). Quando um campo não usa SQL no `dsValores`, pode referenciar um domínio |

---

## Legendas no Schematics DX — Regras e Cuidados

Legendas configuram a coloração ou ícone exibido em linhas/colunas do grid de um WDBPanel, indicando o status visual de cada registro.

### Estrutura de `colors` (captionDisplayMethod: `"STATUS"`)

Cada item do array `colors` representa uma cor aplicada quando a condição da `rule` é satisfeita. O array `rules` dentro de cada item de cor **deve ter ao menos uma condição preenchida** — se ficar vazio (`[]`), a cor nunca é aplicada e o indicador de status não aparece na tela.

```json
"colors" : [ {
  "backgroundColor" : "#00A658",
  "description" : "Finished",
  "expressionCode" : 330970,
  "nrSeqApres" : 100,
  "nrSequence" : "6271",
  "rules" : [ {
    "conditionDescription" : "Regra Finalizada",
    "conditions" : [ {
      "baseAttribute" : "DT_REAL",
      "condition" : "IS NOT NULL",
      "conditionSeq" : 175128757,
      "option" : "ATTRIBUTE WITH VALUE"
    } ],
    "ruleSeq" : 175112410
  } ]
} ]
```

### `conditionSeq` e `ruleSeq` — IDs únicos

São IDs gerados pelo Schematics Builder e não devem ser reutilizados de outras regras do JSON. Em correções manuais, usar números altos e únicos que não conflitem com os IDs existentes no arquivo.

### Regras de legenda NÃO usam `referenceObjectCode`/`scriptReference`

Esses campos são exclusivos de regras de **ativação de componentes** (menu items, WPOPUP). Nas condições dentro de `colors` e `icons` em `legends`, o framework avalia os atributos diretamente do registro do próprio WDBPanel — sem referenciar outro objeto.

### `icons` vs `colors`

| Campo | Exibe | Quando usar |
|---|---|---|
| `colors` | Cor de fundo/fonte na linha ou coluna do grid | Status simples com cor sólida |
| `icons` | Ícone SVG em célula dedicada | Status com representação visual por ícone |

Ambos seguem a mesma estrutura de `rules`. O campo `icons` exige adicionalmente `imgPath` com o caminho do SVG.

### Atenção na migração do Schematics legado para DX

A conversão automática pode gerar a estrutura da legenda corretamente (com `colors`, `code`, `nrSequence`, etc.) mas deixar `"rules": []` vazio. Ao investigar uma legenda que não aparece, **sempre verificar se os itens de cor/ícone têm regras preenchidas**.

> Para a estrutura equivalente no Schematics Legado (banco Oracle) e o diagnóstico de legendas ausentes, ver `schematics-legado.md`.

---

## Schematics DX Builder — editor visual (dentro do próprio sistema)

O Schematics DX também pode ser editado **visualmente**, sem tocar diretamente no JSON, através de um builder acessado pelo ícone de engrenagem (`.b-developer-btn.b-developer-edit`) no topo de qualquer tela de uma função convertida para DX. Isso abre a barra "Schematics DX" com o nome do card ADO vinculado à sessão de edição, botão "Properties (\<módulo\>)" e "Migration".

> **Peculiaridade técnica:** o modal principal do builder (`ngdialog-no-overlay`) nem sempre é capturado de forma confiável pelo accessibility snapshot do Playwright — a árvore existe no DOM real, mas alguns nós ficam fora da árvore de acessibilidade. Cliques por coordenada também podem dar timeout (bug de escala/transform com bounding boxes negativos). **Preferir `page.evaluate(() => el.click())` a cliques por coordenada** ao automatizar interações no builder. Para inspecionar a árvore via JS: `document.querySelectorAll('.tree-node-content')` dentro do dialog (`document.getElementById('ngdialog<N>')`).

> **Cuidado ao explorar:** clicar em "Add" já marca o formulário como modificado (dirty), mesmo sem preencher nada — ao fechar, o sistema pergunta se deseja descartar as alterações. Usar sempre "Cancel"/"Cancelar" (não "Save"/"Salvar"/"Ok") ao navegar apenas para consulta.

### Como abrir o builder para um elemento específico — "três pontinhos" (`b-developer-bar`)

Fora do modal principal, basta passar o mouse sobre qualquer área da tela (uma tab, um painel, um WDBPanel) para revelar um indicador colapsado de "**...**" no canto superior do elemento (`b-developer-bar-holder` / `b-developer-bar-gear`). Ao manter o mouse sobre esse indicador, ele expande numa barra de botões (`b-developer-btn`) com as seguintes opções — **identificáveis pela classe CSS**, já que os ícones são pequenos e similares:

| Botão | Classe CSS | Uso permitido |
|---|---|---|
| **+ (Add)** | `.b-developer-add` | ✅ Adiciona um novo elemento filho (nova tab, painel, região, WDBPanel, item de menu, etc. — conforme o nível selecionado) |
| **⚙ (Edit/Gear)** | `.b-developer-edit` | ✅ Abre o "Settings of: ..." (o mesmo modal builder já documentado acima) para o elemento existente |
| Code | `.b-developer-code` | ⛔ **Nunca usar** |
| JSON | `.b-developer-json` | ⛔ **Nunca usar** |
| Copy | `.b-developer-copy` | ⛔ **Nunca usar** |
| Cut | `.b-developer-cut` | ⛔ **Nunca usar** |
| Paste | `.b-developer-paste` | ⛔ **Nunca usar** |
| Remove | `.b-developer-remove` | ⛔ **Nunca usar** |

> **Regra crítica:** ao desenvolver telas via Schematics DX, **usar exclusivamente os botões Add (+) e Edit (engrenagem)**. As demais opções (Code, JSON, Copy, Cut, Paste, Remove) existem na mesma barra mas **não devem ser usadas em nenhuma circunstância** — risco de corromper a estrutura do schematics ou perder configuração já existente.
>
> O conjunto de botões visíveis pode variar por nível/contexto (ex: uma barra pode expor só `add`+`edit`+`json`, outra expõe todas as 7 opções) — mas a regra de ouro (só Add/Edit) vale sempre, independentemente de quais botões estiverem disponíveis naquele elemento.

### Hierarquia de componentes de uma tela

```
Painel (nível da tab)
  Tab group                      ("Horizontal-Tab" — container do conjunto de abas)
    Tab                          (uma aba individual)
      Painel                     (conteúdo da aba, pode aninhar novamente)
        Região
          WDBPanel
```

Ou seja, o padrão de navegação para adicionar uma nova tela é sempre **Tab > Painel > Região > WDBPanel**. Cada nível tem seu próprio formulário de "Settings" ao ser selecionado na árvore à esquerda do builder.

### ⚠️ Bug conhecido no builder ao criar uma nova Tab via "Add" — requer ajuste manual no JSON

Ao clicar em **Add** no dialog "Settings of: [code] Tab group" para criar uma tab nova (fluxo: Add → escolher layout `col-12` no picker → preencher Description via lookup de expressão → Ok), o builder grava a nova tab como um objeto **`TAB` direto**, filho imediato do Tab group. **Isso está incorreto** — todas as demais tabs de um Tab group (inclusive as pré-existentes) seguem o padrão **`NAVIGATOR` > `TAB` > `MASTER_REGION` > `REGION`**, nunca um `TAB` solto direto no Tab group. Ou seja, cada tab visível é na verdade um `NAVIGATOR` (`navigatorType: "TAB"`, `selectedNavigatorItem: <code do TAB filho>`) que embrulha um único `TAB` interno.

**Sintoma:** a tab criada via Add aparenta funcionar (aparece na lista/no tree do builder), mas ao tentar adicionar um componente (WDBPanel) dentro dela pela árvore do builder, o nó da `REGION` não expõe nenhum botão "Add" nem seta de expansão — trava a navegação.

**Correção aplicada (funcionou):** editar o arquivo `corconf1.json` diretamente, restruturando a tab criada pelo Add para o padrão correto:

```json
// Estrutura ERRADA gerada pelo builder (TAB direto):
{
  "objectType": "TAB",
  "code": 26044590,
  "parentObjectCode": 837249,
  "children": [ { "objectType": "MASTER_REGION", ... } ],
  "description": "Installments",
  "expressionCode": 295280,
  ...
}

// Estrutura CORRETA (NAVIGATOR envolvendo o TAB):
{
  "objectType": "NAVIGATOR",
  "navigatorType": "TAB",
  "code": 26044590,                     // reaproveita o code já gerado pelo builder
  "parentObjectCode": 837249,
  "selectedNavigatorItem": 26111314,     // aponta pro code do TAB interno (novo)
  "description": "Installments",
  "expressionCode": 295280,
  "expressionDescription": "Installments",
  "displayOrder": 25,
  "topList": false,
  "visible": "S",
  "children": [ {
    "objectType": "TAB",
    "code": 26111314,                   // novo code (próximo da sequência já usada)
    "parentObjectCode": 26044590,
    "configurable": true,
    "customProperties": { "keepScope": false },
    "hasObjSchemRules": false,
    "description": "Installments",
    "expressionCode": 295280,
    "expressionDescription": "Installments",
    "displayOrder": 0,
    "topList": false,
    "visible": "S",
    "allowCmdkCustomization": true,
    "restrictPrimaryLevel": "N",
    "restrictSecondaryLevel": "N",
    "restrictTertiaryLevel": "N",
    "children": [ {
      "objectType": "MASTER_REGION",
      "code": 26111312,                 // já existia, só precisou do fix abaixo
      "parentObjectCode": 26111314,
      "masterRegionType": "LAYOUT_A",
      "description": "MR - 1 região",
      "tabGroupSelection": true,         // faltava — MASTER_REGION sempre precisa disso
      "children": [ {
        "objectType": "REGION",
        "code": 26111313,                // já existia, sem alterações
        "parentObjectCode": 26111312,
        "description": "Região",
        "displayOrder": 1,
        "tabGroupSelection": true,
        "children": [ ]                  // aqui entra o WDBPanel, via UI (ver abaixo)
      } ]
    } ]
  } ]
}
```

**Após ajustar o JSON** (`restart`/reload do backend local pega o arquivo automaticamente), a tab passa a se comportar como qualquer outra: **aparece corretamente na tela do Tasy**, e a `REGION` finalmente aceita adicionar um componente pelo fluxo normal (ver seção "três pontinhos" acima) — **acessar a tab já renderizada no Tasy e clicar no botão "+" (Add) que aparece ao passar o mouse sobre a área vazia da região, escolhendo o componente desejado (ex: WDBPanel) no picker**. Diferente do fluxo de criação de Tab (que exige o ajuste manual documentado aqui), adicionar um COMPONENT dentro de uma REGION já existente funciona normalmente pela UI, sem precisar editar o JSON à mão.

> **Cuidado ao gerar novos `code`:** não existe (até o momento) uma forma confirmada de obter o "próximo" código válido — foi usado o próximo número em sequência a partir do maior `code` já gerado pelo builder na mesma sessão (`26111313` → `26111314`). Validar sempre o JSON resultante com `node -e "JSON.parse(require('fs').readFileSync('<arquivo>','utf8'))"` (ou equivalente) antes de considerar a edição concluída.

> **Sempre revisar o diff** de `corconf1.<locale>.json` e de `dialogs/dlg-*.json` depois de qualquer sessão no builder — cliques de navegação/exploração no builder frequentemente gravam alterações espúrias não relacionadas (`popUpHandle`, `nrSeqApres` de legendas, bump de `version`) nesses arquivos. Descartar (`git checkout --`) o que não for parte da mudança pretendida.

### Settings do "Tab group"

Dialog "Settings of: [code] Tab group": tipo "Horizontal-Tab", grid de tabs filhas (colunas Código, Descrição, Display Order, Configurable) com botões **Add**/**Delete** para criar/remover uma tab do grupo. Ao selecionar uma tab na grid, painel de detalhe à direita:
- Description (lookup de expressão)
- Display order
- Show on top / Configurable / Allow CMDK customization (checkboxes)
- Restrict... (checkboxes, contexto-dependentes)
- System default > Create as group selection (checkbox)


### Settings de "Região"

- Code (readonly), Description, Display Order
- Layout Resize (combobox, ex: "None")
- Create as group selection (checkbox, geralmente obrigatório)

### Settings de "WDBPanel"

Dialog com abas próprias: **Properties | Datasource | Activation | Reports | Context Menu (pop-up)**.

**Aba Properties** (accordion com 3 seções):
- **Main**: Code (readonly), Description, **Datasource** (combobox obrigatório apontando para um datasource já registrado)
- **Configuration**: **Criteria** (combobox de SQL, ex: `"and NR_SEQ_CONTRATO = :NR_SEQ_CONTRATO"`), **Upper DBPanel** (combobox — WDBPanel pai), Check submission of parent record (checkbox)
- **Properties**: dezenas de flags que mapeiam às propriedades do WDBPanel (equivalentes às propriedades Java Swing/JS): Action name, Pagination type, Registers p/ page, Amount of records (max), Breadcrumb title/attribute, Locate attribute name, Dynamic report comp type/key attribute, Grid editable, **Only detail mode** (= `EXIBIR_SOMENTE_DETALHE`/`setFormaExibicao(EXIBIR_SOMENTE_DETALHE)` no Java Swing), Uses pagination, Grid multiselect, Call child object automatically, Activate empty by default, Back to grid on save, Select first row on grid, Responsive, Show report settings button, Use new grid component, Check report release, Activate on detail mode, Confirm to release the record, Lazy load detail, Destroy detail, Cache detail, Unify record count SQL statement, Save grid column order, Allow batch signature, Show dynamic report, Without cache, Fill form by voice.

**Aba Datasource**: mostra um catálogo/registro de datasources já cadastrados para a função (não é exclusivo do WDBPanel selecionado). Botões **Import from**, **Copy from**, **Add**, **Delete**, **View**. É aqui que se cria um **novo datasource** (vínculo com tabela/query) antes de poder apontar um WDBPanel para ele em Properties > Main > Datasource.

**Aba Activation**: define como o WDBPanel é ativado a partir do componente pai (equivalente ao `AtivarWDBPanelSqlAtivacao` do Java Swing / `binds[]` do JSON cru):
- Criteria (mesmo combobox de SQL)
- Grid de parâmetros de ativação (colunas Origin, Parameter Code, Parameter Name, Master Object, Master Name, Function), com **Add**/**Delete**
- Detalhe de um parâmetro: Code, **Origin** (combobox, ex: "Object"), **Parameter name** (nome do bind, ex: `NR_SEQ_CONTRATO`), **Master component** (WDBPanel de origem, ex: `contratoWDBP`), **Master attribute** (campo de origem, ex: `NR_SEQUENCIA`)

**Aba Context Menu (pop-up)** — estrutura das opções de mouse — ver seção dedicada abaixo.

### Context Menu (pop-up) — opções de mouse

Árvore própria dentro da aba Context Menu de um WDBPanel:

```
Context Menu (pop-up)
  [code] <NomeWPUMC>                 (equivale à classe *WPUMC.java/WPUMC.js)
    Items
      [code] <Nome do item>          (texto exibido no menu de contexto)
        Actions                       (o que acontece ao clicar)
        Rules                         (condição de habilitação/visibilidade)
          <nome da regra>
            Conditions                (uma ou mais condições da regra)
```

**Settings do grupo WPUMC**: Code, Display Order, Description, checkbox "Create PopUp options in the handlebar" (controla se as opções também aparecem como botões na handlebar/"sanduíche", além do menu de contexto).

**Settings de um Item de menu**: Code, **Name** (texto exibido), **Order**, **Active** (checkbox), **Description expression** (lookup de `dic_expressao`, obrigatório), **Type** (combobox, ex: "Tradicional"), **Upper** (combobox — item de menu pai, para submenus), **Configurable** (combobox, ex: "Client defines as standard"), **Buttons Desck Type**/**Position on the Button Deck** (config de botão na handlebar), seção **Shortcut** (Ctrl/Shift/Alt + tecla), seção **Other options** (Default value, External call, Visible, AI Context Menu).

**Settings de uma Action** (dentro de um Item): Code (readonly), **Execution Sequence**, **Action** (combobox do tipo — ex: "Open WDLG"; o JSON cru documentado acima também usa o tipo `"PROC"`). Os campos seguintes mudam conforme o tipo:
- **Open WDLG** → campo **Object** (lookup do código do dialog a abrir)
- **PROC** (visto no JSON, formulário ainda não mapeado na tela) → deve expor `procedureCode` + grid de parâmetros
- Comum a vários tipos: **Reactivate only the selected line** (checkbox) e **Object to reactivate** (combobox — componente a recarregar, equivalente ao `compReactivateCode` do JSON)

**Settings de uma Condition** (dentro de Rules > \<regra\> > Conditions): o campo **Option** determina o tipo de condição e quais dos demais campos são relevantes:
- **Option = "Parameter"**: usa **Function** (número do `cd_funcao` + lookup), **Parameter** (número do parâmetro + lookup), **Condition** (operador, ex: `=`), **Value** (valor de comparação, ex: `S`) — equivale a `getParametroFuncao(usuario, cd_funcao, nr_parametro) == valor`
- **Option = "Number of records selected"**: usa **Selected records** (combobox com a quantidade esperada, ex: `1`) — equivale a `isLinhasSelecionadas()`/exatamente 1 registro selecionado
- Outras Options existentes (campos ainda não mapeados em detalhe): "Attribute" (testar valor de um campo do registro ativo), "Screen mode (Grid/Detail)" (testar se está em modo grid ou detalhe), "System variable", "Insert/Edit/Browser" (modo do formulário)

### ⚠️ Regra crítica de precedência: código-fonte sempre sobrescreve o Schematics

As Actions e Rules de uma opção de mouse podem ser definidas **diretamente no Schematics** (como descrito acima, sem nenhum código) **ou no código-fonte** (classe que carrega a opção de mouse — `*WPUMC.java` no Java Swing legado, ou o `WPUMC.js`/controller equivalente no HTML5). As duas formas não são mutuamente exclusivas.

**Se existir definição nos dois lugares para o mesmo código de opção de mouse, o código-fonte sempre tem precedência** — a Action/Rule do Schematics é ignorada quando o fonte já implementa a lógica de habilitação (`verificaControleItem`/`itemClicado` no Java Swing, ou o equivalente no controller HTML5) para aquele mesmo código.

> **Implicação prática ao decidir onde implementar uma opção de mouse nova:** usar o Schematics puro (sem código) só faz sentido para regras de habilitação simples (1-2 condições diretas, ex: um parâmetro de função). Quando a lógica de habilitação envolve múltiplas consultas SQL condicionais ou regras de negócio complexas (como é comum em migrações de funcionalidade), implementar via **código-fonte** no controller/WPUMC do HTML5 — a Rule/Action do Schematics, se criada, será ignorada de qualquer forma assim que o fonte assumir o controle daquele código.

### ⚠️ Cuidado crítico: pode haver mais de um "Tab group"/dropdown parecido — confirmar o caminho completo até o elemento certo

Ao clicar na engrenagem do topo (`.b-developer-btn.b-developer-edit` da toolbar geral da função), o builder abre no **root do schematic**, que pode ser um dropdown-menu de **navegação de tela** com nome parecido ao elemento que você realmente quer editar, mas **sem relação nenhuma com ele**. Exemplo real (corConF1): o root abre em `[834917] Contract Control` (dropdown com só 3 itens: Contratos / Regra geração ordem compra automática / Regra comunicação contrato) — isso **não é** o Tab group principal do contrato (que tem 24 abas: Contratos, Consulta, Regra pagamento, Anexos, etc.). São elementos diferentes que coincidentemente têm nomes parecidos.

**Antes de clicar em "Add" em qualquer nó, sempre navegar/expandir a árvore a partir do root e confirmar visualmente (breadcrumb da árvore no dialog) que chegou no elemento correto** — nunca assumir que o primeiro nível mostrado já é o alvo.

Exemplo do caminho completo real até o Tab group principal de contratos no corConF1:
```
[834917] Contract Control          (root - dropdown-menu de navegação, cuidado, não confundir com o alvo)
  [835103] Contratos                (expandir)
    [835113] Painel                 (expandir)
      [833969] Região               (expandir)
        WDBPANEL [833970] - contratoWDBP   (expandir)
          WFILTRO [833943] - filtroContratoWF   (irmão, ignorar)
          [835392] Painel de 6 colunas          (expandir)
            [837249] Tab group                  ← alvo real (24 abas do contrato)
```

**Como expandir cada nível na árvore corretamente:**
- Clicar no `<span class="arrow-right">` (dentro de `a.btn`) à esquerda do texto do nó **para apenas expandir**, sem abrir o "Settings"/"Change panel size" daquele nó.
- Selecionar o elemento sempre por **texto exato** via `document.querySelectorAll('div.tree-node-content')` comparando `textContent.trim()` — **nunca reaproveitar o atributo `id` do elemento arrow (`id="arrow_X_X_X"`) entre chamadas de automação**, pois esse `id` é posicional e é reatribuído a um nó diferente a cada re-render da árvore. Reutilizar o `id` de uma chamada anterior pode acabar clicando no nó errado (ex: abrindo "Change panel size" de outro elemento por engano).
- Uma vez que a árvore já foi expandida numa sessão do dialog, reabrir o dialog (mesmo cancelando e clicando na engrenagem de novo) **preserva o estado expandido** — não precisa re-expandir do zero a cada vez.

### Preenchendo um campo "Description"/"Description expression" (lookup de `dic_expressao`)

Campos de descrição vinculados a expressão (`containerHandlers['expressionCode']`) são um **smart locator**: basta **digitar o texto desejado diretamente no campo** e aguardar — o localizador busca expressões existentes com texto parecido automaticamente. Duas situações:
- **Se a expressão já existir**, o localizador retorna e você seleciona o resultado.
- **Se não existir nada**, abre-se uma opção de busca avançada (WDLG de pesquisa de `dic_expressao`) onde é possível **pesquisar mais amplamente** ou **criar uma nova expressão** (botão "Adicionar" dentro dessa WDLG, na seção "Expressões" — cuidado para não confundir com outros botões "Adicionar" da tela de fundo, como o de criar um novo registro da entidade principal do WDBPanel).

> **Cuidado ao localizar o botão "Adicionar" certo:** a palavra "Adicionar" pode aparecer em múltiplos lugares na tela simultaneamente (ex: também no toolbar do WDBPanel principal "Contratos"). Ao automatizar, **restringir a busca ao container do dialog/WDLG de Expressões** (não usar um seletor genérico de toda a página) para evitar clicar no botão errado.

