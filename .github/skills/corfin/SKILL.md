---
name: corfin
description: Business knowledge for corFin module functions (Financeiro, Fluxo de Caixa, Tesouraria). Activates: When testing, navigating or developing any corFin function — corFinF2, corFinF3, or other corFin functions.
---

# corFin — Módulo Financeiro

> Skill de módulo. Para funções específicas, criar skills individuais (ex: `corfin-f2\SKILL.md`).

---

## Funções do módulo

| Função | cd_funcao | Descrição |
|---|---|---|
| corFinF2 | (verificar) | Caixa de Recebimento / Fluxo de Caixa |
| corFinF3 | (verificar) | (verificar) |
| *(outras)* | — | *(a documentar)* |

---

## Conhecimento de Negócio

### corFinF2 — Exemplos de Parâmetros de Função

Exemplos concretos de parâmetros já identificados nesta função (número, comportamento e efeito). Ver a skill/regra geral de parametrização (arquivo `parametrizacao.md` do agente Tasy HTML5 Developer) para a hierarquia de resolução e regras críticas genéricas.

| Parâmetro | Descrição | Efeito |
|---|---|---|
| `1` | Permitir ou bloquear edição por estabelecimento | `schematics.getParameter(1) == 'N'` → campo `CD_ESTABELECIMENTO` fica somente leitura |
| `4` | Tornar campo `CD_PESSOA_FISICA` somente leitura | `this.isParameter(4)` → `setReadOnly` no campo |
| `9` | Painel somente leitura para determinado perfil | `this.isParameter(9)` → `handler.setReadOnly` no `onSelectionChange` |
| `14` | Define fluxo de aprovação | `getParameter(14) == 'S'` → avalia parâmetro 15 para decidir rotina alternativa |
| `15` | Sub-fluxo de aprovação (depende do parâmetro 14) | `getParameter(15) == 'S'` → aciona rotina alternativa |
| `27` | Permite alterar cartões após registrados na aba Recebimentos | `'S'` → permite edição; `'N'`/ausente → bloqueia (cuidado com lógica invertida) |
| `29` | Desabilita o bloco de `CD_PESSOA_FISICA` | `!this.isParameter(29)` → adiciona blur handler no campo |
| `91` | Define quem pode editar o saldo diário (auditoria) | `'S'` → usuário atual pode editar; caso contrário, verifica permissão por perfil (consulta 122175) |

*(demais seções a preencher conforme cards trabalhados)*

## Dados de Teste

*(a preencher conforme cards trabalhados)*
