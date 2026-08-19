---
name: corcon
description: Business knowledge for corCon module functions (Controle de Contratos, Projetos e Recursos Externos, Rouparia). Activates: When testing, navigating or developing any corCon function — corConF1, corConF2, corConRO.
---

# corCon — Contratos / Projetos / Rouparia

> Skill de módulo. Para funções específicas, criar skills individuais (ex: `corcon-f1\SKILL.md`) quando o volume de conhecimento justificar.

---

## Funções do módulo

| Função | cd_funcao | schematic | Descrição |
|---|---|---|---|
| corConF1 | 1200 | 4568 | Controle de Contratos (cadastro/manutenção de contratos) |
| corConF2 | 928 | 5280 | Controle de Projetos e Recursos Externos |
| corConRO | 1301 | 10000035 | Rouparia (movimentação de roupas, lavanderia) |

---

## corConF1 — Controle de Contratos

Função de cadastro e manutenção de contratos. O painel principal de cadastro é o WDBPanel de contratos (`ContratoWDBP.js`, controller code `833970`).

### Tipo de contrato e arrendamento mercantil

O contrato tem um **Tipo de Contrato** (`NR_SEQ_TIPO_CONTRATO`, FK para `TIPO_CONTRATO`). O tipo de contrato pode ser marcado como **arrendamento mercantil** (leasing) através da coluna `TIPO_CONTRATO.IE_ARRENDAMENTO_MERCANTIL = 'S'` (VARCHAR2(1)).

No cenário de **arrendamento mercantil**, os papéis das partes do contrato mudam:

| Campo do cadastro | Papel no arrendamento mercantil |
|---|---|
| Contratado (`CD_CGC_CONTRATADO`, pessoa jurídica) | **Arrendador** (quem cede o bem em arrendamento) |
| Contratante pessoa jurídica (`CD_CNPJ_CONTRATANTE`) | **Arrendatário** (quem recebe/utiliza o bem) |
| Contratante pessoa física (`CD_PESSOA_CONTRATANTE`), Paciente (`CD_PACIENTE`), Médico responsável (`CD_MEDICO_RESP`) | **Não se aplicam** ao arrendamento — devem ficar ocultos |

O Info button (ver `schematics-dx.md`) dos campos Contratado e Contratante (PJ) apresenta essa explicação de papéis ao usuário quando o contrato é de arrendamento.

> A identificação de que um tipo de contrato é arrendamento (para dirigir o layout condicional) é feita consultando `TIPO_CONTRATO.IE_ARRENDAMENTO_MERCANTIL` a partir do `NR_SEQ_TIPO_CONTRATO` selecionado.

### Migração de Empréstimos e Financiamentos para contratos de Arrendamento Mercantil (em andamento, card 732567)

Para contratos de Arrendamento Mercantil, o corConF1 está recebendo (migrada) a funcionalidade de parcelas/regra/índice de reajuste hoje existente na função legada Java Swing **`CorCpa_EF` — "Gestão de Empréstimos e Financiamentos"** (`cd_funcao=853`, módulo `Tasy_Cpa`). Caminho do fonte: `C:\dev\JAVA\cci-emr-java-swing\Tasy_Cpa\CorCpa_EF\src\br\com\CorCpa_EF\`.

**Tabelas envolvidas:** `EMPREST_FINANC_PARC` (parcelas), `EMPREST_FINANC_REGRA` (regra do financiamento, 1 registro por contrato), `EMPREST_FINANC_INDICE` (índices de reajuste).

**Achado chave:** as procedures PL/SQL da função origem são **100% reutilizáveis sem alteração** — o `TIPO_CONTRATO` "Arrendamento Mercantil" (nr_sequencia 188) já possui `IE_EMPREST_FINANC = 'S'`, a mesma flag que essas procedures exigem (`TIPO_CONTRATO.IE_EMPREST_FINANC`, distinta de `IE_ARRENDAMENTO_MERCANTIL`). Não é necessário alterar PL/SQL — só criar uma nova Action no backend HTML5 que invoque a procedure existente passando o `NR_SEQ_CONTRATO` do contrato do corConF1.

| Opção de mouse (a criar) | Procedure PL/SQL reutilizada | Habilitação (origem Java Swing) |
|---|---|---|
| Gerar Parcelas | `tasyfin/procedure/gerarpa/gerar_parcelas_emprest_fin.prc` (`gerar_parcelas_emprest_fin(nr_seq_contrato_p, cd_estabelecimento_p, nm_usuario_p)`) | Aba Parcelas selecionada, contrato existe, sem parcela gerada ainda |
| Desfazer Parcelas | `tasyfin/procedure/desfaze/desfazer_parc_emprest_financ.prc` (`desfazer_parc_emprest_financ(nr_seq_contrato_p)`) | Parcelas já geradas |
| Gerar Títulos Contrato / Gerar Título Parcela | `tasyfin/procedure/gerarti/gerar_tit_pagar_emprestimo.prc` (mesma procedure, com/sem `nr_seq_parcela_p`) | Parcelas existentes; regra sem índice de reajuste (ou parcela já recalculada, se houver índice) |
| Calcular Reajuste da Parcela | `tasyfin/procedure/calcula/calcular_reaj_parcela_emprest.prc` | Parcela sem título, regra com índice de reajuste informado |

**Estrutura das telas de origem (Java Swing) — referência de campos/eventos a replicar:**
- `ParcelasWJP.java` — grid/detalhe de `EMPREST_FINANC_PARC`; bloqueia edição quando parcela pré-fixada já tem título vinculado; soma `VL_PAGO`/`VL_AMORT_PAGO`/`VL_JUROS_PAGO` num rodapé.
- `RegraContratoWJP.java` — detalhe de `EMPREST_FINANC_REGRA` (1 registro/contrato); calcula `VL_TAXA_EQUIVAL` conforme `IE_TIPO_TAXA`/`IE_TIPO_PRAZO`; **valida com abort** se existir parcela gerada ao tentar editar/excluir a regra (`beforeEdit`/`beforeDelete`) — o card 732567 pede trocar essa validação abortiva por uma mensagem de confirmação não-abortiva.
- `IndiceReajusteWJP.java` — grid/detalhe de `EMPREST_FINANC_INDICE`; valida `DT_BASE_INDICE <= DT_INDICE` e impede duplicar `DT_INDICE` para o mesmo contrato; avisa (não aborta) se o índice já foi usado em algum reajuste de parcela.

> Consultar o card [732567](https://dev.azure.com/emr-cm/EMR/_workitems/edit/732567) para o detalhamento completo da especificação (regras de visibilidade de `NR_SEQUENCIA`, nova aba "Parcelas contrato" condicionada a `IE_ARRENDAMENTO_MERCANTIL='S'`, etc.).

---

## Cards já resolvidos

> Resumos de cards já trabalhados neste módulo, para localizar cenários semelhantes em cards futuros. Consultar o link do card para a análise completa.

| Card | Função | Resumo |
|---|---|---|
| [706475](https://dev.azure.com/emr-cm/EMR/_workitems/edit/706475) | corConF1 | Feature "Arrendamento Mercantil". Ao selecionar tipo de contrato com `IE_ARRENDAMENTO_MERCANTIL = 'S'`: reposicionou o campo Tipo de Contrato no topo do cadastro (em todas as visões), ocultou os campos de contratante pessoa física/paciente/médico (limpando valores apenas em modo de edição) e ajustou os Info buttons de Contratado (Arrendador) e Contratante PJ (Arrendatário). Layout condicional dirigido por consulta ao backend no `onSelectionChange` e na troca do tipo de contrato. |
