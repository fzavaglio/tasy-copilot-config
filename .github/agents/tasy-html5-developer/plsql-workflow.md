# Workflow de Bugs PL/SQL, MCP Oracle e Utilitários

> Referência do agente **Tasy HTML5 Developer**. Carregar ao investigar/corrigir um bug em PL/SQL, compilar/testar objetos via MCP Oracle, ou usar utilitários genéricos do framework PL/SQL.
>
> Para consultas específicas de schema (Dev × Financial) e rastreamento de alterações de dicionário (`log_data`), ver `oracle-queries-log-data.md`.

## Workflow de Investigação e Correção de Bugs PL/SQL

Ao receber um card de bug que envolva PL/SQL, seguir este fluxo em ordem:

1. **Ler o card ADO** — extrair o nome do objeto/procedure citado na análise
2. **Localizar no repositório** — usar `file_search` em `emr-tasy-plsql/objects/` para encontrar o `.prc` ou `.fnc`
3. **Traçar a cadeia de chamadas** — identificar quem chama quem até encontrar o elo com falha
4. **Identificar a causa raiz** — entender por que o valor incorreto é produzido antes de propor solução
5. **Implementar o fix** nos arquivos `.prc`/`.fnc` locais
6. **Compilar via MCP Oracle** — usar `execute_plsql_ddl` para compilar e confirmar que não há erros
7. **Validar a lógica** — usar `execute_select_query` para testar o comportamento corrigido diretamente no banco
8. **Documentar no card ADO** — registrar um comment com causa raiz, o que foi alterado e como validar no sistema

---

## MCP Oracle — Uso e Limitações

O MCP Oracle permite compilar e testar PL/SQL diretamente no banco sem precisar da aplicação.

**Quando usar:**
- Compilar procedures/functions alteradas (`execute_plsql_ddl`)
- Validar lógica de SELECTs e comportamento de funções (`execute_select_query`)
- Executar blocos anônimos de teste (`execute_plsql_call`)

**Limitações importantes:**
- Funções de contexto de sessão da aplicação (`obter_estabelecimento_ativo`, `obter_perfil_ativo`, `wheb_usuario_pck.get_nm_usuario`) **não funcionam** fora da aplicação. Procedures que as chamam no início podem falhar ou retornar valores nulos em testes via banco — verificar se o fluxo testado as contorna (ex: `ie_vinculo_job_p = 'S'` ignora a restrição por estabelecimento)
- O teste end-to-end completo (com vínculo efetivo de dados, execução de JOBs com contexto real) deve ser realizado via sistema no ambiente do cliente
- **`execute_plsql_ddl` não aceita a barra final (`/`)** usada em scripts SQL*Plus após o `END nome_objeto;`. Enviar o código sem o `/` final — se incluído, a ferramenta retorna `PLS-00103: Encountered the symbol "/"` e o objeto fica `INVALID`. Sempre confirmar com `SELECT status FROM all_objects WHERE object_name = '<NOME>'` após compilar.

> A regra de schema/prefixo por base (Dev × Financial) usada nas queries está documentada em `oracle-queries-log-data.md`.

### ⚠️ Cuidado: `read_file` pode retornar conteúdo desatualizado após operações de git

Após `git checkout`, `git stash pop`, `git cherry-pick` ou qualquer operação que troque o conteúdo de um arquivo **fora** das ferramentas de edição (via terminal), o `read_file` pode retornar uma versão em cache do arquivo, não o conteúdo real em disco. Isso já causou edições baseadas em premissas erradas nesta sessão.

**Sempre confirmar o conteúdo real via terminal antes de editar após uma operação de git:**
```powershell
Select-String -Path <arquivo> -Pattern "<trecho a confirmar>" -Context 2,2
# ou
git show <branch>:<caminho/arquivo> | Select-String "<trecho>"
```

Se o texto buscado por `replace_string_in_file`/`multi_replace_string_in_file` não for encontrado (ou for encontrado onde não deveria), suspeitar de cache do `read_file` antes de assumir que o arquivo mudou de fato.

---

## Localizando quando um defeito foi introduzido — `OBJETO_SISTEMA_HIST` (base Dev)

A tabela `tasy.OBJETO_SISTEMA_HIST` (base **Dev**) guarda o histórico completo de cada alteração de um objeto PL/SQL (procedure/function/trigger/etc.), com o código-fonte completo da versão em `DS_SCRIPT_CRIACAO` (tipo `LONG`).

**Query para listar o histórico de um objeto** (do mais antigo para o mais recente):

```sql
SELECT nr_sequencia, dt_atualizacao, nm_usuario, nr_ordem_servico, nr_build, ds_versao_tasy
FROM tasy.objeto_sistema_hist
WHERE upper(nm_objeto) = '<NOME_OBJETO>'
ORDER BY dt_atualizacao;
```

**Para obter o código-fonte de uma revisão específica:**

```sql
SELECT ds_script_criacao FROM tasy.objeto_sistema_hist WHERE nr_sequencia = <NR_SEQUENCIA>;
```

> `DS_SCRIPT_CRIACAO` é `LONG` — cada revisão deve ser consultada individualmente (uma por `SELECT`).

### ⚠️ Regra crítica: usar busca binária, não varredura sequencial

Com múltiplas revisões (ex: 10-20+), **nunca ler os registros um a um em sequência** do mais antigo ao mais recente — isso é O(n) e desperdiça chamadas quando o objeto tem muitas revisões.

**Usar busca binária sobre a lista ordenada de revisões:**

1. Listar todas as revisões ordenadas por `dt_atualizacao` (query acima)
2. Ler o registro do **meio** da lista e verificar se a linha/trecho problemático já está presente
3. Se a linha problemática **já está presente** → o defeito foi introduzido **antes** desse registro → repetir a busca na metade **anterior**
4. Se a linha problemática **ainda não está presente** (código antigo/correto) → o defeito foi introduzido **depois** desse registro → repetir a busca na metade **posterior**
5. Intercalar dessa forma até restar um intervalo de 1-2 registros consecutivos — a revisão que primeiro introduziu a linha é a causa raiz (registrar `dt_atualizacao`, `nm_usuario`, `nr_ordem_servico`)

Isso reduz a investigação de O(n) leituras para O(log₂ n) — por exemplo, 15 revisões passam de ~9-15 leituras sequenciais para ~4 leituras com busca binária.

---

## Utilitários PL/SQL do Framework

Funções utilitárias de uso frequente no repositório `tasyfin` e módulos financeiros:

| Função | Uso |
|---|---|
| `somente_numero(valor)` | Remove caracteres não numéricos e converte para `NUMBER` — **NÃO usar em CPF/CNPJ** (remove zeros à esquerda e não suporta CNPJ alfanumérico). Usar apenas para valores puramente numéricos sem zeros à esquerda significativos. Ver regra crítica de CNPJ na skill do módulo aplicável (ex: `corcpa`). |
| `obter_cnpj_raiz(cd_cgc)` | Retorna o CNPJ raiz buscando em `pessoa_juridica` — retorna NULL se a PJ não estiver cadastrada no Tasy |
| `obter_dados_cod_barras(barras, tipo)` | Extrai campos do código de barras: `'B'`=banco, `'V'`=valor, `'DT'`=vencimento, `'C'`=conta, `'A'`=agência |
| `obter_nome_pf_pj(cd_pf, cd_cgc)` | Retorna nome da pessoa física ou jurídica |
| `gravar_log_tasy(code, msg, usuario)` | Grava log de erro/auditoria na tabela `log_tasy` |

---

## ⚠️ Regra Crítica: nunca usar código existente no mesmo objeto como referência sem revisão crítica

Ao implementar um fix baseado em trechos já existentes no mesmo arquivo:

1. **Verificar se o trecho de referência também está correto** antes de copiar o padrão — o código legado pode repetir o mesmo erro em múltiplos blocos
2. **Verificar na base como o dado é armazenado** antes de presumir pelo código (`execute_select_query` com amostras reais)
3. O exemplo existente pode ser a própria origem do bug que está sendo corrigido

---

## ⚠️ Regra Crítica: autodeadlock (ORA-00060) em trigger com `PRAGMA AUTONOMOUS_TRANSACTION`

Padrão de bug recorrente e de difícil diagnóstico: uma trigger `BEFORE UPDATE ... FOR EACH ROW` com `pragma autonomous_transaction` que chama (direta ou indiretamente) uma procedure que executa `UPDATE` + `COMMIT` na **mesma linha da mesma tabela** que está sendo atualizada pela transação principal.

**Por que trava:** a transação principal já detém o lock da linha (está no meio do próprio `UPDATE` que disparou a trigger). A transação autônoma, que é uma sessão lógica separada, precisa desse mesmo lock para completar seu `UPDATE`/`COMMIT` — mas a principal só libera o lock quando a trigger retornar, e a trigger só retorna quando a transação autônoma completar. Deadlock garantido (`ORA-00060`), não depende de concorrência externa — reproduz de forma consistente sempre que esse caminho de código é executado.

**Como identificar:** no stack trace do erro, procurar por uma trigger com `pragma autonomous_transaction` na cadeia de chamadas, e verificar se ela (ou uma procedure chamada por ela) faz `UPDATE`/`COMMIT` na própria tabela que a disparou.

**Como corrigir:** nunca fazer `UPDATE` autônomo na mesma linha que dispara a trigger. Preferir alterar os valores via `:new.<campo>` dentro da própria trigger (sem `UPDATE`/`COMMIT` explícito) — é o padrão seguro já usado em outras partes do framework para esse mesmo tipo de ajuste.

**Atenção a variáveis de contexto duplicadas:** se a trigger já validou uma condição (ex: parametrização por usuário) antes de chamar a procedure, verificar se a procedure chamada **não está revalidando a mesma condição com uma variável diferente** (ex: usuário da sessão vs. usuário gravado em um registro) — divergências assim fazem o código cair no branch perigoso mesmo quando a trigger já havia decidido pelo caminho seguro.

---

## ⚠️ Regra Crítica: coluna `LONG` no banco permite até 2 GB, mas variável PL/SQL `LONG` trava em 32760 bytes

Colunas de tabela do tipo `LONG` (ex: `DS_RELAT_TECNICO`, `DS_SCRIPT_CRIACAO`) suportam até 2 GB de dado armazenado. Porém, o subtype `LONG` usado em variáveis PL/SQL (declarado no pacote `STANDARD` como `subtype LONG is VARCHAR2(32760)`) trava em **32760 bytes** — bem abaixo do limite da coluna.

Isso significa que uma procedure que declara uma variável local `LONG` (ou `VARCHAR2` de tamanho fixo menor, ex: `VARCHAR2(32000)`) para manipular o conteúdo de uma coluna `LONG` pode estourar com `ORA-06502: PL/SQL: numeric or value error: character string buffer too small` quando o dado real ultrapassar esse limite — mesmo que o dado já esteja gravado corretamente na tabela.

**Confirmado empiricamente:**
```sql
DECLARE
    v_long LONG;
BEGIN
    v_long := RPAD('A', 32760, 'A');   -- OK
    v_long := v_long || 'B';            -- 32761 bytes
END;
-- ORA-06502: PL/SQL: numeric or value error: character string buffer too small
```

**Confirmado na documentação oficial** (Oracle Database PL/SQL Language Reference, "LONG and LONG RAW Data Types"): "the maximum size of a LONG value is 32,760 bytes (as opposed to 32,767 bytes)" e "you cannot retrieve a value longer than 32,760 bytes from a LONG column into a LONG variable" — mesmo a coluna suportando até 2 GB. A própria Oracle recomenda usar `CLOB`/`NCLOB` em vez de `LONG` para aplicações novas (exigiria `ALTER TABLE`).

**Ao investigar um `ORA-06502` envolvendo uma coluna `LONG`:** verificar o tamanho real do dado armazenado (`LENGTH(coluna)`) e comparar com o tamanho da variável/parâmetro `VARCHAR2`/`LONG` usado na procedure. Se o dado exceder ~32760 bytes, o limite é do **tipo PL/SQL**, não da coluna.

**Alternativa sem alterar a tabela (sem `ALTER TABLE`):** o pacote `DBMS_SQL` tem `DEFINE_COLUMN_LONG` + `COLUMN_VALUE_LONG`, feitos exatamente para ler uma coluna `LONG` **em pedaços** (parâmetros `offset`/`length`), sem nunca carregar o valor inteiro em uma única variável escalar PL/SQL:

1. Abrir cursor via `DBMS_SQL.OPEN_CURSOR` / `PARSE` / `EXECUTE` do `SELECT` da coluna `LONG`.
2. Chamar `DBMS_SQL.DEFINE_COLUMN_LONG` para a posição da coluna (antes do fetch).
3. Após `FETCH_ROWS`, chamar `DBMS_SQL.COLUMN_VALUE_LONG` em loop, avançando o `offset` a cada chamada, até `value_length` retornar 0.
4. Acumular cada pedaço em um **`CLOB` temporário** (`DBMS_LOB.CREATETEMPORARY` + `DBMS_LOB.WRITEAPPEND`) — `CLOB` não tem o limite de 32760/32767 bytes dos tipos escalares PL/SQL.

Esse padrão resolveria tecnicamente o card [507792](https://dev.azure.com/emr-cm/EMR/_workitems/edit/507792) (processar o histórico grande via `CLOB`/`DBMS_LOB` em vez de `VARCHAR2(32000)` na "Comunicar Histórico Executor"), sem exigir `ALTER TABLE` em `MAN_ORDEM_SERV_TECNICO`. O card foi fechado sem fix/como doubt, mas essa é a solução técnica caso o caso seja retomado — ver workaround já orientado ao cliente (tela de Anexos) na skill `corman-os`.
