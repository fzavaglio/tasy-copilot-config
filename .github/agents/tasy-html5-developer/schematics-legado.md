# Schematics Legado — Estrutura no Banco de Dados

> Referência do agente **Tasy HTML5 Developer**. Carregar ao investigar legendas, campos ou comportamentos de funções ainda não convertidas para o Schematics DX (ver `schematics-dx.md` para a contraparte em JSON).

O Schematics legado armazenava toda a configuração de telas em tabelas Oracle. O Schematics DX migrou essas definições para arquivos JSON, mas o entendimento do legado é necessário para diagnosticar migrações incompletas.

## Árvore principal da função — `OBJETO_SCHEMATIC`

A hierarquia de objetos de uma função fica na tabela `OBJETO_SCHEMATIC`. Cada registro representa um nó da árvore (função, região, painel, menu item, etc.):

| Coluna | Descrição |
|---|---|
| `NR_SEQUENCIA` | ID único do objeto — corresponde ao `"code"` no JSON DX |
| `DS_OBJETO` | Nome descritivo do objeto (ex: `ManOrdemAtivPrevWDBP`) |
| `CD_FUNCAO` | Código da função à qual o objeto pertence |
| `IE_TIPO_OBJETO` | Tipo do nó: `C` (componente), `R` (região), `MR` (master region), etc. |
| `IE_TIPO_COMPONENTE` | Tipo de componente: `WDBP` (WDBPanel), `WPOPUP` (menu item), `WCP` (CPanel), etc. |
| `NR_SEQ_OBJ_SUP` | ID do objeto pai — define a hierarquia da árvore |
| `NR_SEQ_FUNCAO_SCHEMATIC` | ID do registro em `FUNCAO_SCHEMATIC` — identifica a versão do schematic da função |
| `NM_TABELA` | Tabela Oracle que o WDBPanel gerencia |
| `ID_OBJETO` | Identificador textual (usado em alguns contextos específicos) |

A tabela `FUNCAO_SCHEMATIC` mapeia as funções para seus schematics:

| Coluna | Descrição |
|---|---|
| `NR_SEQUENCIA` | ID do schematic |
| `DS_SCHEMATIC` | Nome do módulo/schematic (ex: `cormanos`) |
| `CD_FUNCAO` | Código da função Tasy |
| `DS_VERSAO` | Versão do schematic |

**Correspondência legado → DX:**
- `OBJETO_SCHEMATIC.NR_SEQUENCIA` → `"code"` do componente no JSON
- `OBJETO_SCHEMATIC.DS_OBJETO` → `"description"` do componente no JSON
- `OBJETO_SCHEMATIC.NR_SEQ_OBJ_SUP` → `"parentObjectCode"` no JSON

---

## Legendas — Estrutura no Legado e Equivalência no DX

### Hierarquia de tabelas no legado

```
TASY_LEGENDA (nr_sequencia = 1342)         ← legenda registrada no painel via OBJETO_SCHEMATIC_LEGENDA
  └── TASY_PADRAO_COR (nr_sequencia = X)   ← item de cor: ds_cor_html = '#00A658', ds_item = 'Finished'
        └── REGRA_CONDICAO (nr_seq_legenda = X)  ← regra com nm_condicao descritivo
              └── REGRA_CONDICAO_ITEM (nr_seq_regra = X)
                    nm_atributo_base = 'DT_REAL'
                    ie_condicao      = 'IS NOT NULL'
```

**Vínculo do painel com a legenda** — tabela `OBJETO_SCHEMATIC_LEGENDA`:

| Coluna | Descrição |
|---|---|
| `NR_SEQ_OBJETO` | ID do WDBPanel em `OBJETO_SCHEMATIC` |
| `NR_SEQ_LEGENDA` | ID da legenda em `TASY_LEGENDA` |
| `IE_FORMA_APRES` | Forma de apresentação: `STA` (status icon), `BOR` (borda), `BUL` (bullet) |
| `IE_SITUACAO` | `S` = ativo |

**Tabela `TASY_PADRAO_COR`** — cada registro é um item de cor da legenda:

| Coluna | Descrição |
|---|---|
| `NR_SEQUENCIA` | ID do item de cor — corresponde ao `"nrSequence"` no JSON DX |
| `NR_SEQ_LEGENDA` | FK para `TASY_LEGENDA` |
| `DS_ITEM` / `CD_EXP_ITEM` | Descrição do item / código de expressão para i18n — corresponde a `"description"` / `"expressionCode"` |
| `DS_COR_HTML` | Cor hexadecimal — corresponde a `"backgroundColor"` no JSON DX |
| `NR_SEQ_APRES` | Ordem de apresentação — corresponde a `"nrSeqApres"` |

**Tabela `REGRA_CONDICAO`** — cada registro é uma regra (grupo de condições AND):

| Coluna | Descrição |
|---|---|
| `NR_SEQUENCIA` | ID da regra |
| `NR_SEQ_LEGENDA` | FK para `TASY_PADRAO_COR.NR_SEQUENCIA` (item de cor ao qual a regra pertence) |
| `NM_CONDICAO` | Descrição da regra — corresponde a `"conditionDescription"` no JSON DX |

**Tabela `REGRA_CONDICAO_ITEM`** — cada registro é uma condição individual:

| Coluna | Descrição |
|---|---|
| `NR_SEQUENCIA` | ID da condição — corresponde ao `"conditionSeq"` no JSON DX |
| `NR_SEQ_REGRA` | FK para `REGRA_CONDICAO` — corresponde a `"ruleSeq"` no JSON DX |
| `NM_ATRIBUTO_BASE` | Campo avaliado — corresponde a `"baseAttribute"` |
| `IE_CONDICAO` | Operador: `IS NOT NULL`, `=`, `>`, etc. — corresponde a `"condition"` |
| `IE_VALOR` | Valor comparado — corresponde a `"value"` |
| `IE_OPCAO_COMPARACAO` | Tipo de comparação — corresponde a `"option"` (`ATTRIBUTE WITH VALUE`) |

### Correspondência completa legado → DX

```
TASY_PADRAO_COR.NR_SEQUENCIA   → colors[].nrSequence
TASY_PADRAO_COR.DS_COR_HTML    → colors[].backgroundColor
TASY_PADRAO_COR.CD_EXP_ITEM    → colors[].expressionCode
TASY_PADRAO_COR.NR_SEQ_APRES   → colors[].nrSeqApres

REGRA_CONDICAO.NR_SEQUENCIA    → colors[].rules[].ruleSeq
REGRA_CONDICAO.NM_CONDICAO     → colors[].rules[].conditionDescription

REGRA_CONDICAO_ITEM.NR_SEQUENCIA     → colors[].rules[].conditions[].conditionSeq
REGRA_CONDICAO_ITEM.NM_ATRIBUTO_BASE → colors[].rules[].conditions[].baseAttribute
REGRA_CONDICAO_ITEM.IE_CONDICAO      → colors[].rules[].conditions[].condition
REGRA_CONDICAO_ITEM.IE_VALOR         → colors[].rules[].conditions[].value
REGRA_CONDICAO_ITEM.IE_OPCAO_COMPARACAO → colors[].rules[].conditions[].option
```

### Como diagnosticar uma legenda ausente

1. Localizar o painel em `OBJETO_SCHEMATIC` pelo `ds_objeto` ou `nr_sequencia`
2. Buscar em `OBJETO_SCHEMATIC_LEGENDA` pelo `nr_seq_objeto` para obter o `nr_seq_legenda`
3. Buscar em `TASY_PADRAO_COR` pelo `nr_seq_legenda` para ver os itens de cor e suas cores HTML
4. Buscar em `REGRA_CONDICAO` pelo `nr_seq_legenda = TASY_PADRAO_COR.NR_SEQUENCIA` para ver as regras
5. Buscar em `REGRA_CONDICAO_ITEM` pelo `nr_seq_regra` para ver as condições
6. Comparar com o JSON DX — se `rules: []` estiver vazio, a migração não converteu as condições

---

## Processo de alteração do Schematics Legado

**NÃO é possível alterar essas tabelas diretamente via SQL em banco local.** O trigger `BL$<TABELA>` bloqueia qualquer DML com:
```
ORA-20001: Base tables can't be updated on local databases.
```

**Fluxo correto para alterar o Legado:**
1. Setar o contexto de usuário e OS (para rastreabilidade — os comandos abaixo servem como referência, a execução real acontece via interface):
   ```sql
   BEGIN
       wheb_usuario_pck.set_nm_usuario('<nm_usuario>');
       tasy_dict_integration_pck.set_so(<nr_card_ado>);
   END;
   ```
2. **Fazer as alterações pela interface do Tasy** (Schematics Builder ou função correspondente). O framework executa internamente com o flag `g_updating_base_table = true` via `tasy_dict_integration_pck`, bypassing o trigger. As alterações são gravadas na tabela `LOG_DATA` (ver `oracle-queries-log-data.md`).
3. Na função **"Manutenção do Dicionário"** do Tasy, enviar o logset para a base DEV.
4. Na base DEV, integrar as alterações — esse é o "commit" no Schematics Legado.

**Packages envolvidos:**
- `wheb_usuario_pck.set_nm_usuario(nm_usuario)` — define o usuário da sessão
- `tasy_dict_integration_pck.set_so(nr_so)` — define o número do card vinculado às alterações (**OBRIGATÓRIO SER O NUMERO DO CARD ADO**)

**Hierarquia de FK para DELETE de legenda (ordem correta):**
1. `REGRA_CONDICAO_ITEM` (WHERE nr_seq_regra IN (...))
2. `REGRA_CONDICAO` (WHERE nr_sequencia IN (...))
3. `TASY_PADRAO_COR` (WHERE nr_sequencia IN (...))
4. `OBJETO_SCHEMATIC_LEGENDA` (WHERE nr_seq_legenda = X AND nr_seq_objeto = Y)
5. `TASY_LEGENDA` (WHERE nr_sequencia = X)

---

## Root Cause: quando apontar o Legado em vez da conversão DX

Quando um bug envolve uma configuração incorreta no Schematics DX (legenda, campo, layout) e o commit causador é a criação do arquivo JSON (mensagem tipo `ConvertToDX` ou `chore(corXxxFY): Convert function`), **antes de apontar a feature de conversão DX como causa raiz, consultar o Schematics Legado no banco Oracle** para verificar se o registro problemático já existia lá.

**Como verificar:**
```sql
-- Legenda e data de última alteração
SELECT nr_sequencia, ds_legenda, dt_atualizacao
FROM tasy_legenda WHERE nr_sequencia = <nr_seq_legenda>;

-- Itens de cor e datas
SELECT nr_sequencia, ds_item, dt_atualizacao
FROM tasy_padrao_cor WHERE nr_seq_legenda = <nr_seq_legenda>;

-- Vínculo com o painel
SELECT nr_seq_objeto, ie_forma_apres, ie_situacao
FROM objeto_schematic_legenda WHERE nr_seq_legenda = <nr_seq_legenda>;
```

Se o registro existir no Legado com `dt_atualizacao` anterior à conversão DX:
- A causa raiz é o Legado — descrever o registro e a data da `dt_atualizacao`
- **Não mencionar o nome do usuário** que realizou a alteração no Legado
- Referenciar a feature de conversão DX https://dev.azure.com/emr-cm/EMR/_workitems/edit/570067 apenas como o veículo que trouxe o problema para o DX

> Esta regra de causa raiz também é usada na documentação de cards ADO — ver `tasy-workflow.instructions.md` (seção "Schematics Legado — Root Cause").
