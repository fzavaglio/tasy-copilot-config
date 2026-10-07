# Oracle — Schemas (Dev × Financial) e Rastreamento via log_data

> Referência do agente **Tasy HTML5 Developer**. Carregar sempre que for executar consultas/scripts PL/SQL avulsos, documentar releases (Comment 4 do ADO) ou investigar alterações de dicionário.

## Regra de preferência — Financial SEMPRE para desenvolvimento/teste

> **⛔ Qualquer uso de base para desenvolvimento, teste ou consulta de registros de teste é SEMPRE na base Financial (`mcp_oracle2_*`).** Os registros de negócio da base Dev **não são dados de teste** do ambiente usado pelo usuário — conclusões tiradas deles (títulos, lotes, OS, parametrização por usuário/perfil/estabelecimento, objetos compilados) são inválidas para o cenário em análise.

**Base Financial (`mcp_oracle2_*`) — obrigatória para desenvolvimento/teste:**
- Reprodução de cenário e validação de hipótese de bug com dados
- Consulta de registros/dados de teste (títulos, lotes contábeis, OS, pessoas, atendimentos, etc.)
- Valor efetivo de parâmetro (`FUNCAO_PARAM_USUARIO`/`_PERFIL`/`_ESTAB`) e ajuste de parâmetro para teste
- Compilação (`execute_plsql_ddl`), testes de procedure/function (`execute_plsql_call`) e queries de teste avulsas
- Inserção/alteração de dados para montar cenário de teste
- `log_data` (alterações de dicionário) — a tabela em Dev está vazia

**Base Dev (`mcp_oracle_*`) — permitida para consulta de cadastros, definições e históricos (não é dado de teste):**

| Uso permitido em Dev | Exemplos |
|---|---|
| Releases | `AJUSTE_VERSAO` (Comment 4 do ADO) |
| Histórico de alterações de código | `OBJETO_SISTEMA_HIST` (quando/como um objeto PL/SQL foi alterado) |
| Cadastro de parâmetros de função | `FUNCAO_PARAMETRO` a nível de definição (`DS_PARAMETRO`, `CD_DOMINIO`, `VL_PARAMETRO_PADRAO`, `IE_SITUACAO_HTML5`), `FUNCTION_RELEASE_NOTE` |
| Cadastros de dicionário / Schematics Legado | `OBJETO_SCHEMATIC`, `OBJ_SCHEMATIC_EVENTO`, `DIC_OBJETO`, `TASY_LEGENDA`, `REGRA_CONDICAO`, cadastro de funções, tabelas, visões, etc. |

**Checklist obrigatório antes de qualquer chamada `mcp_oracle_*` (Dev):**
1. A consulta é de **cadastro, definição ou histórico** (tabela acima)? Se não → usar `mcp_oracle2_*` (Financial).
2. A consulta envolve **registros de negócio/teste** (títulos, lotes, OS, parametrização efetiva por usuário etc.), compilação ou execução de objeto? Se sim → **Financial**, sem exceção.
3. Uma sessão anterior/outro arquivo usou Dev para a mesma tabela? Isso **não** é justificativa — reavaliar pelos itens acima.

Se uma consulta de desenvolvimento/teste em Financial falhar (tabela vazia, objeto ausente, erro de permissão), **não migrar silenciosamente para Dev**: informar o usuário e perguntar como proceder.

## Schema nas queries — regra obrigatória

| Como o usuário chama | Tool prefix | Usuário da sessão | Prefixo nas queries |
|---|---|---|---|
| "base financial" / Financial (padrão) | `mcp_oracle2_*` | `Tasy` | sem prefixo |
| "base dev" / Dev (somente cadastros, definições e históricos — ver tabela acima) | `mcp_oracle_*` | `wheb_readonly` | `tasy.` obrigatório |

- A base **Financial** (`mcp_oracle2_*`) conecta com o usuário `Tasy`, portanto tabelas e objetos podem ser referenciados **sem prefixo de schema**.
- A base **Dev** (`mcp_oracle_*`) conecta com o usuário `wheb_readonly`, cujo schema padrão de sessão **não é `TASY`**. Toda referência a tabela, view ou objeto PL/SQL na base Dev **deve ser prefixada com `tasy.`** (ex: `tasy.man_ordem_servico`, `tasy.titulo_pagar`). Nunca omitir o prefixo em queries na base Dev.
- Para uso geral do MCP Oracle (quando compilar/testar objetos, limitações de contexto de sessão), ver `plsql-workflow.md`.

---

## Identificando Alterações no Dicionário de Objetos via log_data

A tabela `log_data` (base **Financial**) registra todas as alterações feitas no dicionário de objetos/dados do Tasy. Cada registro corresponde a um evento de DML (`INSERT`, `UPDATE`, `DELETE`) em uma tabela do dicionário, com o `log_info` em formato JSON contendo os valores antes e depois de cada campo.

### Estrutura do log_info

```json
{
  "event_info": {
    "sequence": "317359",
    "table_name": "FUNCAO_PARAMETRO",
    "dml_operation": "UPDATE",
    "tasy_user": "omarques",
    "service_order": "721944"
  },
  "primary_key_values": [
    { "column_name": "CD_FUNCAO", "old_value": 299, "new_value": 299 },
    { "column_name": "NR_SEQUENCIA", "old_value": 209, "new_value": 209 }
  ],
  "column_values": [
    { "column_name": "IE_SITUACAO_HTML5", "old_value": "A", "new_value": "I" },
    ...
  ]
}
```

- `event_info.service_order` — número do card ADO vinculado à alteração (definido via `tasy_dict_integration_pck.set_so()`)
- `primary_key_values` — PK do registro alterado
- `column_values` — todos os campos com `old_value` e `new_value`; somente os que diferem representam alterações reais

> **Atenção:** Usar **sempre** a base **Financial** (`mcp_oracle2_*`) — a tabela `log_data` na base Dev está vazia.

### Query padrão para buscar alterações de um card

O `log_info` é um CLOB, mas o Oracle 19c suporta `JSON_TABLE` diretamente sobre CLOBs. Isso elimina a necessidade de leitura em chunks e permite extrair o **estado final líquido** das alterações em uma única query.

**Passo 1 — Listar os eventos do card (visão geral):**

```sql
SELECT event_sequence, event_date, table_name, dml_operation, tasy_user
FROM log_data
WHERE DBMS_LOB.INSTR(log_info, '"service_order":"<NR_CARD>"') > 0
ORDER BY event_sequence;
```

**Passo 2 — Extrair estado final das alterações (query principal):**

```sql
WITH card_events AS (
    SELECT event_sequence, event_date, table_name, dml_operation, tasy_user, log_info
    FROM log_data
    WHERE DBMS_LOB.INSTR(log_info, '"service_order":"<NR_CARD>"') > 0
),
pk_desc AS (
    SELECT e.event_sequence, e.table_name,
           LISTAGG(jt.col_name || '=' || jt.col_val, ', ')
             WITHIN GROUP (ORDER BY jt.col_name) AS pk_desc
    FROM card_events e,
         JSON_TABLE(e.log_info, '$.primary_key_values[*]'
             COLUMNS (
                 col_name VARCHAR2(100) PATH '$.column_name',
                 col_val  VARCHAR2(200) PATH '$.new_value'
             )
         ) jt
    GROUP BY e.event_sequence, e.table_name
),
changed_fields AS (
    SELECT e.event_sequence, e.table_name, p.pk_desc,
           jt.column_name, jt.old_value, jt.new_value
    FROM card_events e
    JOIN pk_desc p ON p.event_sequence = e.event_sequence
    CROSS JOIN JSON_TABLE(e.log_info, '$.column_values[*]'
        COLUMNS (
            column_name VARCHAR2(100)  PATH '$.column_name',
            old_value   VARCHAR2(4000) PATH '$.old_value',
            new_value   VARCHAR2(4000) PATH '$.new_value'
        )
    ) jt
    WHERE DECODE(jt.old_value, jt.new_value, 1, 0) = 0
      AND jt.column_name NOT IN (
          'DT_ATUALIZACAO', 'DT_ATUALIZACAO_PHILIPS',
          'NM_USUARIO', 'NM_USUARIO_PHILIPS',
          'DT_ATUALIZACAO_NREC', 'NM_USUARIO_NREC'
      )
)
SELECT table_name, pk_desc, column_name,
       MIN(old_value) KEEP (DENSE_RANK FIRST ORDER BY event_sequence) AS original_value,
       MAX(new_value) KEEP (DENSE_RANK LAST  ORDER BY event_sequence) AS final_value
FROM changed_fields
GROUP BY table_name, pk_desc, column_name
HAVING DECODE(
    MIN(old_value) KEEP (DENSE_RANK FIRST ORDER BY event_sequence),
    MAX(new_value) KEEP (DENSE_RANK LAST  ORDER BY event_sequence),
    1, 0
) = 0
ORDER BY table_name, pk_desc, column_name;
```

**O que a query faz:**
- `JSON_TABLE` sobre o CLOB expande `primary_key_values` e `column_values` em linhas — sem leitura manual de chunks
- `DECODE(old, new, 1, 0) = 0` filtra apenas campos que mudaram em cada evento, excluindo metadados
- `KEEP (DENSE_RANK FIRST/LAST ORDER BY event_sequence)` consolida múltiplos eventos, pegando o primeiro `old_value` e o último `new_value`
- `HAVING DECODE(original, final, 1, 0) = 0` descarta campos que reverteram ao valor original (alterações intermediárias canceladas)

### Como interpretar os resultados

1. **Campos realmente alterados** — a query já filtra e entrega apenas as diferenças líquidas. `original_value` é o estado antes do primeiro evento do card; `final_value` é o estado após o último.
2. **Resultado vazio** — se a query não retornar linhas, o card não possui alterações de dicionário registradas em `log_data`.
3. **Campos sem diferença** — registros com `old_value == new_value` em todos os campos relevantes indicam que o registro foi aberto e salvo sem alteração real (apenas timestamps atualizados). A query exclui esses automaticamente.

### Exemplo de saída esperada

Para o card 721944, a query retornou (após consolidar 3 eventos intermediários):

| Tabela | PK | Campo | original_value | final_value |
|---|---|---|---|---|
| `FUNCAO_PARAMETRO` | CD_FUNCAO=299, NR_SEQUENCIA=209 | `IE_SITUACAO_HTML5` | `A` | `I` |

> Este padrão de consulta é usado na seção "Comment 4 — Alterações Realizadas" de `tasy-workflow.instructions.md` (seção ALTERAÇÕES DE DICIONÁRIO).
>
> **Nota sobre a ferramenta MCP:** a query acima usa `WITH` (CTE), o que **`mcp_oracle2_execute_select_query` rejeita** (`Error: Only SELECT queries are allowed`). Reescrever como subqueries aninhadas (`SELECT ... FROM (SELECT ... FROM (...) x) y`) antes de executar via essa ferramenta — a versão com `WITH` acima serve como referência lógica da consulta, não como texto pronto para colar na ferramenta.

### ⚠️ Cuidado: `service_order` pode ficar "grudado" na sessão e poluir a busca com ruído

`tasy_dict_integration_pck.set_so(<nr_card>)` define o `service_order` gravado em **todo** evento de dicionário da sessão a partir daquele ponto — e esse valor **persiste até ser trocado**, mesmo que o usuário passe a editar registros de dicionário completamente diferentes/não relacionados ao card. Isso significa que uma busca por `DBMS_LOB.INSTR(log_info, '"service_order":"<NR_CARD>"') > 0` pode retornar **muito mais eventos do que os realmente relacionados ao card** (já visto: 170+ eventos de `DIC_OBJETO` sob um único SO, sendo só 1 realmente relevante).

**Como mitigar:**
- Se o volume de eventos retornado parecer desproporcional ao escopo do card, **não confiar cegamente no filtro por `service_order`** — cruzar com a PK/tabela esperada (ex: filtrar também por `table_name = 'DIC_OBJETO'` e pelo `NR_SEQUENCIA` já conhecido do objeto/query alterada) para isolar o evento real.
- Quando já se sabe qual objeto foi alterado (ex: via investigação de código), é mais rápido e preciso consultar diretamente pelo `event_sequence`/PK específico do que confiar no filtro amplo por `service_order`.
