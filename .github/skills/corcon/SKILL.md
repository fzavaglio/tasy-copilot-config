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

---

## Cards já resolvidos

> Resumos de cards já trabalhados neste módulo, para localizar cenários semelhantes em cards futuros. Consultar o link do card para a análise completa.

| Card | Função | Resumo |
|---|---|---|
| [706475](https://dev.azure.com/emr-cm/EMR/_workitems/edit/706475) | corConF1 | Feature "Arrendamento Mercantil". Ao selecionar tipo de contrato com `IE_ARRENDAMENTO_MERCANTIL = 'S'`: reposicionou o campo Tipo de Contrato no topo do cadastro (em todas as visões), ocultou os campos de contratante pessoa física/paciente/médico (limpando valores apenas em modo de edição) e ajustou os Info buttons de Contratado (Arrendador) e Contratante PJ (Arrendatário). Layout condicional dirigido por consulta ao backend no `onSelectionChange` e na troca do tipo de contrato. |
