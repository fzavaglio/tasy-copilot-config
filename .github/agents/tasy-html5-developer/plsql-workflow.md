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

> A regra de schema/prefixo por base (Dev × Financial) usada nas queries está documentada em `oracle-queries-log-data.md`.

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
