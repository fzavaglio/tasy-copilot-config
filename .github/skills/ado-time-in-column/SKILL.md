---
name: ado-time-in-column
description: Calculates how long Azure DevOps cards stayed in each board column and in each Customer Communication Status value (e.g. Awaiting customer), from the work item change history. Activates: When asked for time per board column (tempo por coluna), time awaiting customer, lead time, or a report over a group of cards (agrupamento de cards).
---

# Tempo por coluna do board (Azure DevOps)

Usar o script `scripts/ado-time-in-column.ps1` do repositório tasy-copilot-config (localizar com busca de arquivo por `**/scripts/ado-time-in-column.ps1`) em vez de ler as revisões do card pelo MCP do ADO. Pelo MCP, cada revisão traz todos os campos do card (cerca de 880 KB num card com 75 revisões) e o cálculo manual fica sujeito a erro.

## Pré-requisitos

- Variável de ambiente `TASY_AZURE_DEVOPS_PAT` (a mesma do MCP do ADO), com escopo Work Items (Read).
- Se a política de execução bloquear scripts, liberar apenas para o terminal atual: `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force`.
- Pelo terminal do agente, rodar antes `$ProgressPreference = 'SilentlyContinue'` e começar cada comando com `$null = 1;`. Em execuções longas o terminal devolve o controle antes do fim; o comando seguinte é digitado adiantado e o primeiro token chega corrompido (o `$null = 1;` absorve o erro). Confirmar o término com um segundo comando (ex.: listar os CSVs gerados).

## Como executar

| Objetivo | Parâmetros |
|---|---|
| Resumo de um ou mais cards | `-Ids 758938, 755539` |
| Outra visão na saída | `-View Periodos`, `-View Consolidado` ou `-View Agregado` |
| Grupo de cards | `-Wiql "SELECT [System.Id] FROM WorkItems WHERE ..."` (WIQL plana, sem links) |
| Dias úteis de 8 horas | acrescentar `-BusinessTime` (expediente padrão 08:00-12:00 e 13:00-17:00; outro horário com `-WorkingHours`) |
| Gerar CSVs (as quatro visões) | acrescentar `-OutputDirectory <pasta>`; `-FilePrefix <nome>` separa os arquivos (ex.: um prefixo por time) |
| Outro campo de status | `-StatusField 'Custom.AwaitingFor' -AwaitingValue 'Customer'` |

Para ler no terminal: `| Format-Table Tipo, Valor, Passagens, Dias, Tempo, MinutosDone, MinutosAguardandoCliente -AutoSize | Out-String -Width 220`.

Áreas dos times (sem subáreas, por isso o filtro usa `=`):

| Time | Area path |
|---|---|
| ERP - Financeiro | `EMR\ERP - Financeiro e Contábil\ERP - Financeiro` |
| Contábil/Repasse | `EMR\ERP - Financeiro e Contábil\ERP - Contabil e Repasse` |

**Bug de cliente** = bug com referência de Jira (`Custom.ExternalID`, ex.: BTC-9710) ou de ServiceNow (`Custom.SNOWID`, ex.: PTASK0040423). Bugs internos (versionamento, verificação de versão, revisões) não têm nenhum dos dois.

Exemplo: bugs de cliente do time ERP - Financeiro fechados em 09/2026:

```
SELECT [System.Id] FROM WorkItems WHERE [System.TeamProject] = 'EMR' AND [System.WorkItemType] = 'Bug' AND [System.AreaPath] = 'EMR\ERP - Financeiro e Contábil\ERP - Financeiro' AND [System.State] = 'Closed' AND [Microsoft.VSTS.Common.ClosedDate] >= '2026-09-01' AND [Microsoft.VSTS.Common.ClosedDate] < '2026-10-01' AND ([Custom.ExternalID] <> '' OR [Custom.SNOWID] <> '')
```

No comando do terminal do agente, montar o "á" com `$([char]0xE1)` para evitar problema de acentuação.

## Saída

- **Resumo** (padrão): uma linha por card e coluna (Tipo = Coluna) e por card e valor do status (Tipo = Status), com PrimeiraEntrada, Passagens, Minutos, Dias, Tempo, MinutosDone (parte Done de coluna dividida) e MinutosAguardandoCliente (quanto do tempo na coluna o status estava como Awaiting customer).
- **Períodos**: uma linha por passagem, com Inicio, Fim, Done (S/N), Minutos, Dias, Tempo, MinutosAguardandoCliente e Atual (S no período em que o card está agora).
- **Consolidado**: uma linha por card, com Estado, Fechamento, Reaberturas, LeadTimeDias, AguardandoClienteDias e uma coluna de dias para cada coluna do board.
- **Agregado**: uma linha por coluna do board, mais lead time e espera pelo cliente, com Cards (quantos têm tempo maior que zero), MediaDias e MedianaDias (entre esses cards), MaxDias, SomaDias, PercentualDoLead e SomaDiasDone.
- CSV com o separador de lista do Windows (`;` em pt-BR) e UTF-8 com BOM, para abrir direto no Excel ou no Power BI.

## Regras de cálculo

- Tempo corrido por padrão (24h por dia, inclui fins de semana), horário de Brasília (`-TimeZoneId`), arredondado ao minuto em cada período.
- Com `-BusinessTime`: conta só o expediente em dias úteis e 1 dia = total de horas do expediente (8h no padrão, então 12h = 1,5 dia). Descontados os feriados nacionais (01/01, Sexta-feira Santa, 21/04, 01/05, 07/09, 12/10, 02/11, 15/11, 20/11 a partir de 2024 e 25/12), a Terça de Carnaval e Corpus Christi.
- Card fechado (`-FinalStates`, padrão Closed, Removed e Done): tempo contado até o último fechamento. Card aberto: até agora.
- Lead time = soma do tempo nas colunas do consolidado (todas, menos as de `-ExcludeColumns`). A espera pelo cliente é medida em paralelo às colunas e não entra na soma.
- Reaberturas = quantas vezes o card saiu de um estado final para um estado aberto.
- Coluna dividida: Doing e Done aparecem separados nos períodos (Done = S/N) e somados no resumo, com a parte Done em MinutosDone.
- Passagens conta as entradas na coluna. Ir de Doing para Done na mesma coluna não conta nova passagem.
- A coluna vem de `System.BoardColumn`. Se o card aparecer em vários boards (campos `WEF_<id>_Kanban.Column`), o campo reflete apenas um deles. No card 758938 coincidiu com o board da área ERP - Financeiro.
- Para tendências agregadas (médias por mês ou equipe) existe também o Analytics do ADO no Power BI, mas ele trabalha com fotos diárias e ignora mudanças dentro do mesmo dia.

## Interpretação

- Alterações da conta funcional "SW Process and Tools" são automações. No card 758938, a automação reabriu o card na mesma atualização em que o Customer Communication Status passou para Customer answered.
- Períodos de poucos segundos (ex.: status limpo e regravado pela automação) aparecem com 0 minutos e podem ser omitidos na apresentação.
- Board Stories do time ERP - Financeiro, na ordem: Funnel, Analyze (dividida), Ready, Develop (dividida), Test (dividida), Completed e Accepted. Para Bug, Funnel = New, Accepted = Closed e as demais = WIP. Configuração das colunas: `GET https://dev.azure.com/emr-cm/EMR/{time}/_apis/work/boards/{board}/columns?api-version=7.1`.
- Colunas de outros boards (ex.: New) ou "(sem coluna)" aparecem quando o card passou por outra área antes de chegar ao time. Por padrão, New fica fora do consolidado, do agregado e do lead time (`-ExcludeColumns`; para incluir, `-ExcludeColumns @()`), mas continua no resumo e nos períodos.
- Em card fechado, tempo em Accepted é o tempo em que ele ficou fechado antes de ser reaberto (o fechamento final conta 0).
- Nos bugs fechados em 09/2026 o Customer Communication Status quase não aparece (1 bug, 1 minuto em Awaiting customer); a espera pelo cliente estava em `Custom.AwaitingFor` = Customer. Para esse período, rodar também com `-StatusField 'Custom.AwaitingFor' -AwaitingValue 'Customer'`.

## Registrar no card

Se o usuário pedir para registrar o resultado no card, seguir as regras de formatação HTML do `tasy-workflow.instructions.md` e mostrar o texto ao usuário antes de postar. Estrutura usada no card 758938: título, linha do tempo (coluna, entrada, saída, tempo), total por coluna, observações e a seção de Awaiting customer com a coluna do board em cada período.
