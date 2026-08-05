---
name: corcpa
description: Business knowledge for corCpa module functions (Contas a Pagar, Borderô a Pagar, Pagamento Escritural). Activates: When testing, navigating or developing any corCpa function.
---

# corCpa — Contas a Pagar

> Skill de módulo. Para funções específicas, criar skills individuais (ex: `corcpa-f8\SKILL.md`).

---

## Funções do módulo

| Função | cd_funcao | Descrição |
|---|---|---|
| corCpaF1 | 851 | Títulos a Pagar (manutenção de títulos; painéis: Título pagar, Alteração em lotes, Importação, Inconsistências de rateio, Liberação) |
| corCpaF4 | 854 | Consulta de Títulos a Pagar (localizador/consulta; usado como chamada externa para selecionar títulos) |
| corCpaF8 | (verificar) | Pagamento Escritural / Borderô a Pagar |
| *(outras)* | — | *(a documentar)* |

---

## Conhecimento de Negócio

### Módulo F857 — Pagamento Escritural (corCpaF8)

Estrutura de tabelas e objetos centrais do módulo:

| Objeto | Descrição |
|---|---|
| `banco_regra_barras` | Regras de vínculo automático. Campo `ie_vincular_titulo_job = 'S'` habilita execução pela JOB |
| `banco_regra_barras_atrib` | Atributos (critérios) de cada regra: `PJCDRZ`, `TPDTVA`, `TPVLST`, `TPCDCG`, `NFNRNF`... |
| `banco_regra_barras_valor` | Filtros de valor por campo: `ORI` (origem), `TIP` (tipo), `CLA` (classe) |
| `banco_escrit_barras` | Boletos importados. `nr_titulo = NULL` significa sem vínculo com título a pagar |
| `banco_escritural` | Arquivo escritural (remessa/retorno bancário) |
| `banco_escrit_lote` | Lote de importação DDA |
| `obter_titulo_regra_barras` | Procedure central: busca o título a pagar correspondente a um boleto, aplicando as regras configuradas |
| `vincular_barras_tit_pagar` | Procedure que efetiva o vínculo entre código de barras e título a pagar |
| `VERIFICA_REGRA_BARRAS` | JOB que percorre boletos sem vínculo e tenta localizar o título automaticamente |

**Atributo `PJCDRZ`:** permite localizar títulos pelo CNPJ raiz quando a filial do boleto não está cadastrada em `pessoa_juridica`. A lógica deriva o raiz via `substr(cd_cgc_p, 1, 8)` — campos `cd_cgc` são armazenados sem máscara (14 chars), nunca usar `somente_numero()` pois remove zeros à esquerda. Nunca depender apenas de `obter_cnpj_raiz()` pois retorna NULL para PJs não cadastradas.

### Origem do estabelecimento do boleto (`banco_escrit_barras`)

O boleto **não possui coluna de estabelecimento própria**. O estabelecimento vem do "pai" que o importou, por uma das duas FKs:

- `nr_seq_banco_escrit` → `banco_escritural.cd_estabelecimento`
- `nr_seq_lote` → `banco_escrit_lote.cd_estabelecimento` (coluna `NOT NULL`)

Ou seja, o estabelecimento do boleto é o do **arquivo/lote de importação do DDA**. Em bases reais, os boletos de DDA costumam vir por **lote** (`nr_seq_lote` preenchido, `nr_seq_banco_escrit` nulo), então a origem correta é `nvl(banco_escritural.cd_estabelecimento, banco_escrit_lote.cd_estabelecimento)`. O cursor da JOB `VERIFICA_REGRA_BARRAS` hoje só lê `banco_escritural.cd_estabelecimento` (fica nulo no caminho por lote).

### Parâmetro 68 e conceito de estabelecimento financeiro (`obter_titulo_regra_barras`)

O parâmetro **68 "Permitir incluir títulos de outros estabelecimentos"** da função 857 controla o filtro de estabelecimento na busca do título. Quando `= 'N'`, a procedure restringe a busca com:

```sql
and (a.cd_estabelecimento = :cd_estab_ativo_w or a.cd_estab_financeiro = :cd_estab_ativo_w)
```

**A cláusula `or a.cd_estab_financeiro` é intencional e faz parte do design** — nasceu junto com o filtro do parâmetro 68 (introduzido em 2019, OS 1903272) e nunca foi acidental. É o conceito de **estabelecimento financeiro**: um título cujo estab. financeiro e o estabelecimento logado é, financeiramente, "seu", mesmo que o `cd_estabelecimento` operacional seja outro. Vincular esse título é comportamento esperado, **não é bug**. Remover a cláusula regride todos os clientes que trabalham com estabelecimento financeiro. Se um cliente precisar restringir apenas ao estabelecimento operacional, isso é uma **melhoria** (novo parâmetro), não correção.

**Comportamento manual × JOB da `obter_titulo_regra_barras`:**

| `ie_vinculo_job_p` | Origem | Comportamento com parâmetro 68 = 'N' |
|---|---|---|
| `'N'` | Vínculo manual pelo sistema (há usuário/estab/perfil de sessão) | Aplica o filtro `cd_estabelecimento OR cd_estab_financeiro` usando o estabelecimento **logado** (`obter_estabelecimento_ativo`) |
| `'S'` | JOB `VERIFICA_REGRA_BARRAS` | **Pula o filtro de estabelecimento por completo** — intencional, pois em contexto de JOB não há estab/usuário/perfil de sessão (comentário explícito na `VERIFICA_REGRA_BARRAS`). Vincula título de qualquer estabelecimento |

**Heurística de triagem:** se a reclamação menciona especificamente *estabelecimento financeiro*, é forte indício de caminho **manual** — só o manual produz vínculos baseados em estab. financeiro. O caminho por JOB produziria vínculos com estabelecimentos **quaisquer** (nem operacional nem financeiro batendo), com "cara" diferente da queixa.

### ⚠️ Regra Crítica: nunca usar `somente_numero()` em campos CPF/CNPJ

A função `somente_numero()` converte internamente para `NUMBER` via `to_number()`, **removendo zeros à esquerda**. CPFs e CNPJs frequentemente começam com `0`, e a partir de julho/2026 os CNPJs podem conter letras (CNPJ alfanumérico).

**Verificado no banco:** os campos `cd_cgc` em `banco_escrit_barras`, `cd_pessoa_externo` e `titulo_pagar.cd_cgc` são sempre armazenados **sem máscara** (14 chars puros, com zeros à esquerda preservados). As máscaras existem apenas no frontend.

| Operação | ❌ Errado | ✅ Correto |
|---|---|---|
| Comparar CNPJ exato | `somente_numero(a.cd_cgc) = somente_numero(:cd_cgc)` | `a.cd_cgc = :cd_cgc` |
| Extrair CNPJ raiz (8 chars) | `substr(somente_numero(cd_cgc_p), 1, 8)` | `substr(cd_cgc_p, 1, 8)` |
| Verificar tamanho | `length(somente_numero(cd_cgc_p)) = 14` | `length(cd_cgc_p) = 14` |

> `somente_numero_char()` retorna `VARCHAR2` e preserva zeros à esquerda, mas ainda remove letras — não usar para CNPJ alfanumérico.

### Adiantamento Pago vinculado a Ordem de Compra (Contas a Pagar × Compras)

Quando uma Ordem de Compra tem vencimento marcado para "Gerar Adiantamentos", a liberação da OC pode gerar um `adiantamento_pago` vinculado a ela (`ordem_compra_adiant_pago`). Dois parâmetros controlam esse comportamento e se relacionam entre si:

| Parâmetro | Função | Valores |
|---|---|---|
| 105 — "Forma de geração do adiantamento pela ordem de compra" | 917 (Ordem de Compra) | `A` = Gerar somente adiantamento (sem vincular a um título) · `T` = Gerar título de adiantamento **e** o adiantamento, vinculando-os (`adiantamento_pago.nr_titulo_original` recebe o título gerado) |
| `parametros_contas_pagar.ie_deduzir_ordem_adiant` | Contas a Pagar (por estabelecimento) | `S` = deduz o saldo do adiantamento imediatamente ao vincular a OC · `N` = nunca deduz (saldo permanece aberto por definição) · `F`/`V` = deduz apenas quando a NF da OC é calculada |

**Implicação crítica:** quando o parâmetro 105 = `T` (título vinculado ao adiantamento) **e** `ie_deduzir_ordem_adiant = 'N'` para o estabelecimento, o saldo desse adiantamento **nunca chega a zero** — é o comportamento esperado da parametrização, não uma inconsistência de dados. Qualquer validação que bloqueie uma ação (ex: estorno de baixa) apenas por existir saldo em aberto nesse adiantamento vai falhar permanentemente para esse cenário. Ver `ATUALIZAR_SALDO_TIT_PAGAR` como exemplo de rotina que precisou considerar isso.

*(demais seções a preencher conforme cards trabalhados)*

### corCpaF1 — Títulos a Pagar (F851)

**Navegação por painéis:** combobox no topo esquerdo alterna entre os painéis: `Título pagar`, `Alteração em lotes`, `Importação`, `Inconsistências de rateio`, `Liberação`.

**Painel "Alteração em lotes":** permite alterar em lote atributos de vários títulos de uma vez. Possui dois grids: **"Títulos"** (os títulos selecionados para o lote) e **"Centro de custo e conta"**.

**Processo "Selecionar títulos" (montar o lote):**
1. No grid "Títulos", acionar a opção de mouse **"Selecionar títulos"**.
2. Abre a função **Consulta de Títulos a Pagar** (corCpaF4).
3. Informar período/critérios (deixar **Situação em branco** traz todas as situações) e **Filtrar**.
4. Selecionar os títulos desejados (**Selecionar** para os marcados, ou **Selecionar todos** para todos os filtrados) ou **Cancelar**.
5. Os títulos escolhidos retornam e populam o grid "Títulos" do painel "Alteração em lotes", prontos para a alteração em lote.

## Dados de Teste

*(a preencher conforme cards trabalhados)*

## Cards já resolvidos

> Resumos de bugs já corrigidos neste módulo, para localizar cenários semelhantes em cards futuros. Consultar o link do card para a análise completa.

| Card | Função | Resumo |
|---|---|---|
| [734647](https://dev.azure.com/emr-cm/EMR/_workitems/edit/734647) | corCpaF1 — Títulos a Pagar (Alteração em lotes) | Ao usar "Selecionar títulos" → "Selecionar todos" com mais de 1000 títulos, ocorria `ORA-01795` (limite de 1000 expressões em lista `IN`). O grid do lote recarregava com `nr_titulo IN (<lista>)`. Correção no backend `TituloPagarWCPAction` (corCpaF1): quebrar a lista em blocos de ≤1000 unidos por `OR`. Cenário reproduzível na base Financial ampliando o período do filtro (ex: 01/01/2000–31/12/2030, Situação Aberto) para exceder 1000 títulos. |
| [735933](https://dev.azure.com/emr-cm/EMR/_workitems/edit/735933) | Títulos a Pagar — estorno de baixa | Estorno de baixa de título liquidado a partir de adiantamento pago vinculado a OC ficava bloqueado permanentemente quando a OC estava parametrizada para vincular título+adiantamento (parâmetro 105 = `T`) e o estabelecimento não deduzia o saldo desse adiantamento (`ie_deduzir_ordem_adiant = 'N'`). Correção em `ATUALIZAR_SALDO_TIT_PAGAR`: a validação de estorno passou a considerar essa parametrização. Durante o teste, identificado e corrigido também um autodeadlock (ORA-00060) não relacionado em `ATUALIZAR_LIB_TITULO_PAGAR` (ver regra genérica em `plsql-workflow.md`). Reproduzível na base Financial com títulos vinculados a `ordem_compra_adiant_pago` cujo estabelecimento tenha `ie_deduzir_ordem_adiant = 'N'`. |
| [739682](https://dev.azure.com/emr-cm/EMR/_workitems/edit/739682) | F857 — Pagamento Escritural (`obter_titulo_regra_barras`) | **Classificado como dúvida / comportamento padrão (não bug).** Cliente reclamou que o vínculo de DDA vinculava títulos de outros estabelecimentos com o parâmetro 68 = 'N'. Causa: no caminho manual, o filtro considera `cd_estabelecimento OR cd_estab_financeiro` — inclusão do estab. financeiro é intencional desde 2019 (OS 1903272), é o conceito de estabelecimento financeiro. Não remover a cláusula (regride todos os clientes). Restrição só ao estab. operacional seria melhoria, não correção. Ver seção "Parâmetro 68 e conceito de estabelecimento financeiro". Atenção ao caminho JOB (`ie_vinculo_job_p='S'`), que pula o filtro por completo (design, sem estab de sessão). |
