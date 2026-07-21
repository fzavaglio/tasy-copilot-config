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
| `widthHTML` | Largura em pixels na grid |
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
| `tooltip` / `tooltipExpressionCode` | Texto de ajuda |

**`allCriteria`**: mapa de restrições SQL adicionais indexadas por código, aplicadas à query do WDBPanel conforme o contexto.

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
