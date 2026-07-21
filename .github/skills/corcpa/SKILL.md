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

### ⚠️ Regra Crítica: nunca usar `somente_numero()` em campos CPF/CNPJ

A função `somente_numero()` converte internamente para `NUMBER` via `to_number()`, **removendo zeros à esquerda**. CPFs e CNPJs frequentemente começam com `0`, e a partir de julho/2026 os CNPJs podem conter letras (CNPJ alfanumérico).

**Verificado no banco:** os campos `cd_cgc` em `banco_escrit_barras`, `cd_pessoa_externo` e `titulo_pagar.cd_cgc` são sempre armazenados **sem máscara** (14 chars puros, com zeros à esquerda preservados). As máscaras existem apenas no frontend.

| Operação | ❌ Errado | ✅ Correto |
|---|---|---|
| Comparar CNPJ exato | `somente_numero(a.cd_cgc) = somente_numero(:cd_cgc)` | `a.cd_cgc = :cd_cgc` |
| Extrair CNPJ raiz (8 chars) | `substr(somente_numero(cd_cgc_p), 1, 8)` | `substr(cd_cgc_p, 1, 8)` |
| Verificar tamanho | `length(somente_numero(cd_cgc_p)) = 14` | `length(cd_cgc_p) = 14` |

> `somente_numero_char()` retorna `VARCHAR2` e preserva zeros à esquerda, mas ainda remove letras — não usar para CNPJ alfanumérico.

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
