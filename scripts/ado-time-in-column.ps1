#Requires -Version 5.1
<#
.SYNOPSIS
    Tempo de permanencia de cards do Azure DevOps em cada coluna do board e em cada valor de um campo de status.

.DESCRIPTION
    Le o historico de alteracoes de cada card (API REST de updates do work item) e monta quatro visoes (-View):
      - Resumo (padrao): total por card e coluna/status, numero de passagens, tempo na parte Done das
        colunas divididas e quanto do tempo em cada coluna o status estava como -AwaitingValue.
      - Periodos: cada passagem do card por uma coluna ou por um valor do status.
      - Consolidado: uma linha por card, com lead time, tempo em cada coluna, espera e reaberturas.
      - Agregado: por coluna, cards com tempo nela, media, mediana, maximo, soma e % do lead time.
    Por padrao o tempo e corrido. Com -BusinessTime, conta apenas o expediente (-WorkingHours) em dias uteis,
    descontando feriados nacionais, Terca de Carnaval e Corpus Christi; 1 dia = total de horas do expediente.
    Cards em um dos -FinalStates tem o tempo contado ate o ultimo fechamento; os demais, ate agora.
    A coluna vem do campo System.BoardColumn; se o card estiver em varios boards, ele reflete apenas um deles.
    Colunas em -ExcludeColumns (padrao New, de outros boards) ficam fora do consolidado, do agregado e do lead time.
    Com -OutputDirectory, grava as quatro visoes em CSV.
    Autenticacao: PAT do Azure DevOps (escopo Work Items - Read) na variavel de ambiente TASY_AZURE_DEVOPS_PAT.

.EXAMPLE
    .\ado-time-in-column.ps1 -Ids 758938

.EXAMPLE
    .\ado-time-in-column.ps1 -Ids 758938, 755539 -View Periodos -BusinessTime

.EXAMPLE
    .\ado-time-in-column.ps1 -Wiql "SELECT [System.Id] FROM WorkItems WHERE [System.WorkItemType] = 'Bug' AND [System.AssignedTo] = @Me AND [Microsoft.VSTS.Common.ClosedDate] >= '2026-09-01'" -BusinessTime -OutputDirectory .\relatorio -FilePrefix meus-bugs
#>
[CmdletBinding(DefaultParameterSetName = 'Ids')]
param(
    [Parameter(Mandatory, ParameterSetName = 'Ids')]
    [int[]]$Ids,

    [Parameter(Mandatory, ParameterSetName = 'Wiql')]
    [string]$Wiql,

    [string]$Organization = 'emr-cm',
    [string]$Project = 'EMR',
    [string]$StatusField = 'Custom.CustomerCommunicationStatus',
    [string]$AwaitingValue = 'Awaiting customer',
    [string[]]$FinalStates = @('Closed', 'Removed', 'Done'),
    [string]$TimeZoneId = 'E. South America Standard Time',
    [switch]$BusinessTime,
    [string[]]$WorkingHours = @('08:00-12:00', '13:00-17:00'),
    [string[]]$ExcludeColumns = @('New'),
    [ValidateSet('Resumo', 'Periodos', 'Consolidado', 'Agregado')]
    [string]$View = 'Resumo',
    [string]$OutputDirectory,
    [string]$FilePrefix = 'tempo-por-coluna'
)

$ErrorActionPreference = 'Stop'

if (-not $env:TASY_AZURE_DEVOPS_PAT) {
    throw 'Defina a variavel de ambiente TASY_AZURE_DEVOPS_PAT com um PAT do Azure DevOps (escopo Work Items - Read).'
}
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
$headers = @{ Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(':' + $env:TASY_AZURE_DEVOPS_PAT)) }
$apiBase = 'https://dev.azure.com/{0}/{1}/_apis/wit' -f $Organization, [uri]::EscapeDataString($Project)
$timeZone = [TimeZoneInfo]::FindSystemTimeZoneById($TimeZoneId)
$nowUtc = [datetime]::UtcNow

$windows = foreach ($range in $WorkingHours) {
    $winStart, $winEnd = $range -split '-'
    [pscustomobject]@{ Start = [timespan]::Parse($winStart); End = [timespan]::Parse($winEnd) }
}
$minutesPerDay = if ($BusinessTime) { [int]($windows | ForEach-Object { ($_.End - $_.Start).TotalMinutes } | Measure-Object -Sum).Sum } else { 1440 }

function Get-EasterSunday([int]$year) {
    $a = $year % 19; $b = [math]::Floor($year / 100); $c = $year % 100
    $h = (19 * $a + $b - [math]::Floor($b / 4) - [math]::Floor(($b - [math]::Floor(($b + 8) / 25) + 1) / 3) + 15) % 30
    $l = (32 + 2 * ($b % 4) + 2 * [math]::Floor($c / 4) - $h - ($c % 4)) % 7
    $m = [math]::Floor(($a + 11 * $h + 22 * $l) / 451)
    $n = $h + $l - 7 * $m + 114
    [datetime]::new($year, [int][math]::Floor($n / 31), [int]($n % 31) + 1)
}

$holidays = New-Object 'System.Collections.Generic.HashSet[datetime]'
if ($BusinessTime) {
    foreach ($year in 2015..($nowUtc.Year + 1)) {
        $fixed = @(@(1, 1), @(4, 21), @(5, 1), @(9, 7), @(10, 12), @(11, 2), @(11, 15), @(12, 25))
        # Consciencia Negra e feriado nacional desde 2024 (Lei 14.759/2023)
        if ($year -ge 2024) { $fixed += , @(11, 20) }
        foreach ($md in $fixed) { [void]$holidays.Add([datetime]::new($year, $md[0], $md[1])) }
        # Terca de Carnaval, Sexta-feira Santa e Corpus Christi, a partir da Pascoa
        $easter = Get-EasterSunday $year
        foreach ($offset in -47, -2, 60) { [void]$holidays.Add($easter.AddDays($offset)) }
    }
}

# Minutos entre dois instantes: corridos ou, com -BusinessTime, so dentro do expediente em dias uteis.
function Get-WorkMinutes([datetime]$fromUtc, [datetime]$toUtc) {
    if ($toUtc -le $fromUtc) { return 0.0 }
    if (-not $BusinessTime) { return ($toUtc - $fromUtc).TotalMinutes }
    $from = [TimeZoneInfo]::ConvertTimeFromUtc($fromUtc, $timeZone)
    $to = [TimeZoneInfo]::ConvertTimeFromUtc($toUtc, $timeZone)
    $total = 0.0
    for ($day = $from.Date; $day -le $to.Date; $day = $day.AddDays(1)) {
        if ($day.DayOfWeek -eq 'Saturday' -or $day.DayOfWeek -eq 'Sunday' -or $holidays.Contains($day)) { continue }
        foreach ($w in $windows) {
            $start = $day + $w.Start
            $end = $day + $w.End
            if ($start -lt $from) { $start = $from }
            if ($end -gt $to) { $end = $to }
            if ($end -gt $start) { $total += ($end - $start).TotalMinutes }
        }
    }
    $total
}

function Get-Median([double[]]$values) {
    $sorted = @($values | Sort-Object)
    if (-not $sorted.Count) { return 0 }
    $mid = [int][math]::Floor($sorted.Count / 2)
    if ($sorted.Count % 2) { $sorted[$mid] } else { ($sorted[$mid - 1] + $sorted[$mid]) / 2 }
}

function ConvertTo-UtcDate($value) {
    # O PowerShell 7 ja converte datas ISO do JSON em DateTime; o 5.1 entrega string.
    if ($value -is [datetime]) { return $value.ToUniversalTime() }
    [datetime]::Parse($value, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::AdjustToUniversal)
}

function Format-LocalDate([datetime]$utc) {
    [TimeZoneInfo]::ConvertTimeFromUtc($utc, $timeZone).ToString('yyyy-MM-dd HH:mm')
}

function ConvertTo-Minutes([double]$minutes) {
    [int][math]::Round($minutes, [MidpointRounding]::AwayFromZero)
}

function Format-Minutes([int]$minutes) {
    '{0}d {1}h {2:00}m' -f [math]::Floor($minutes / $minutesPerDay), [math]::Floor(($minutes % $minutesPerDay) / 60), ($minutes % 60)
}

function ConvertTo-Days([double]$minutes) {
    [math]::Round($minutes / $minutesPerDay, 2)
}

# Agrupa os eventos em periodos de valor constante (coluna + Done, ou valor do status), contados ate $limit.
function Get-Segments($events, [string]$kind, [datetime]$limit) {
    $segments = @()
    foreach ($e in $events) {
        if ($kind -eq 'Coluna') {
            $value = if ($e.Column) { [string]$e.Column } else { '(sem coluna)' }
            $done = $e.Done
        }
        else { $value = [string]$e.Status; $done = $false }
        if ($segments.Count -and $segments[-1].Valor -eq $value -and $segments[-1].Done -eq $done) { continue }
        $entry = (-not $segments.Count) -or ($segments[-1].Valor -ne $value)
        if ($segments.Count) { $segments[-1].End = $e.When }
        $segments += [pscustomobject]@{
            Tipo = $kind; Valor = $value; Done = $done; Entry = $entry
            Start = $e.When; End = $null; From = $null; To = $null; Minutes = 0; AwaitingMinutes = $null
        }
    }
    foreach ($s in $segments) {
        $s.From = if ($s.Start -lt $limit) { $s.Start } else { $limit }
        $s.To = if ($s.End -and $s.End -lt $limit) { $s.End } else { $limit }
        $s.Minutes = ConvertTo-Minutes (Get-WorkMinutes $s.From $s.To)
    }
    $segments
}

if ($PSCmdlet.ParameterSetName -eq 'Wiql') {
    $body = [Text.Encoding]::UTF8.GetBytes((@{ query = $Wiql } | ConvertTo-Json))
    $result = Invoke-RestMethod -Method Post -Uri "$apiBase/wiql?api-version=7.1" -Headers $headers -ContentType 'application/json; charset=utf-8' -Body $body
    $Ids = @($result.workItems | ForEach-Object { $_.id })
    if (-not $Ids.Count) { Write-Warning 'A WIQL nao retornou nenhum card.'; return }
}

$tracked = 'System.Title', 'System.State', 'System.BoardColumn', 'System.BoardColumnDone', $StatusField
$periodRows = New-Object System.Collections.Generic.List[object]
$summaryRows = New-Object System.Collections.Generic.List[object]
$cards = New-Object System.Collections.Generic.List[object]
$processed = 0

foreach ($id in $Ids) {
    $processed++
    Write-Progress -Activity 'Lendo historico dos cards' -Status "Card $id ($processed de $($Ids.Count))" -PercentComplete (100 * $processed / $Ids.Count)

    try {
        $updates = @()
        do {
            $page = Invoke-RestMethod -Uri "$apiBase/workItems/$id/updates?`$top=200&`$skip=$($updates.Count)&api-version=7.1" -Headers $headers
            $updates += $page.value
        } while ($page.count -eq 200)
    }
    catch {
        Write-Warning "Falha ao ler o historico do card ${id}: $($_.Exception.Message)"
        continue
    }

    # Estado do card apos cada alteracao, em ordem cronologica
    $current = @{}
    $events = @(foreach ($u in $updates) {
        $f = $u.fields
        if (-not $f -or -not $f.'System.ChangedDate') { continue }
        foreach ($name in $tracked) {
            if ($f.PSObject.Properties[$name]) { $current[$name] = $f.$name.newValue }
        }
        [pscustomobject]@{
            When   = ConvertTo-UtcDate $f.'System.ChangedDate'.newValue
            State  = $current['System.State']
            Column = $current['System.BoardColumn']
            Done   = [bool]$current['System.BoardColumnDone']
            Status = $current[$StatusField]
        }
    })

    $isFinal = $false
    $finalSince = $null
    $reopenings = 0
    foreach ($e in $events) {
        $nowFinal = $FinalStates -contains $e.State
        if ($nowFinal -and -not $isFinal) { $finalSince = $e.When }
        if ($isFinal -and -not $nowFinal) { $reopenings++ }
        $isFinal = $nowFinal
    }
    $limit = if ($isFinal) { $finalSince } else { $nowUtc }

    $columns = @(Get-Segments $events 'Coluna' $limit)
    $statuses = @(Get-Segments $events 'Status' $limit | Where-Object { $_.Valor })
    $awaiting = @($statuses | Where-Object { $_.Valor -eq $AwaitingValue })

    foreach ($c in $columns) {
        $overlap = 0.0
        foreach ($a in $awaiting) {
            $from = if ($a.From -gt $c.From) { $a.From } else { $c.From }
            $to = if ($a.To -lt $c.To) { $a.To } else { $c.To }
            if ($to -gt $from) { $overlap += Get-WorkMinutes $from $to }
        }
        $c.AwaitingMinutes = ConvertTo-Minutes $overlap
    }

    $title = $current['System.Title']
    $segments = $columns + $statuses

    foreach ($s in $segments) {
        $periodRows.Add([pscustomobject]@{
            WorkItemId               = $id
            Titulo                   = $title
            Tipo                     = $s.Tipo
            Valor                    = $s.Valor
            Done                     = if ($s.Tipo -ne 'Coluna') { '' } elseif ($s.Done) { 'S' } else { 'N' }
            Inicio                   = Format-LocalDate $s.Start
            Fim                      = if ($s.End) { Format-LocalDate $s.End } else { '' }
            Minutos                  = $s.Minutes
            Dias                     = ConvertTo-Days $s.Minutes
            Tempo                    = Format-Minutes $s.Minutes
            MinutosAguardandoCliente = $s.AwaitingMinutes
            Atual                    = if ($s.End) { 'N' } else { 'S' }
        })
    }

    foreach ($group in $segments | Group-Object { '{0}|{1}' -f $_.Tipo, $_.Valor }) {
        $items = $group.Group
        $isColumn = $items[0].Tipo -eq 'Coluna'
        $minutes = [int]($items | Measure-Object Minutes -Sum).Sum
        $summaryRows.Add([pscustomobject]@{
            WorkItemId               = $id
            Titulo                   = $title
            Tipo                     = $items[0].Tipo
            Valor                    = $items[0].Valor
            PrimeiraEntrada          = Format-LocalDate $items[0].Start
            Passagens                = @($items | Where-Object Entry).Count
            Minutos                  = $minutes
            Dias                     = ConvertTo-Days $minutes
            Tempo                    = Format-Minutes $minutes
            MinutosDone              = if ($isColumn) { [int]($items | Where-Object Done | Measure-Object Minutes -Sum).Sum } else { $null }
            MinutosAguardandoCliente = if ($isColumn) { [int]($items | Measure-Object AwaitingMinutes -Sum).Sum } else { $null }
        })
    }

    $columnMinutes = @{}
    foreach ($c in $columns) { $columnMinutes[$c.Valor] = [int]$columnMinutes[$c.Valor] + $c.Minutes }
    $cards.Add([pscustomobject]@{
        Id              = $id
        Title           = $title
        State           = $events[-1].State
        ClosedAt        = if ($isFinal) { Format-LocalDate $finalSince } else { '' }
        Reopenings      = $reopenings
        Columns         = $columnMinutes
        AwaitingMinutes = [int]($awaiting | Measure-Object Minutes -Sum).Sum
        Order           = @($columns | Where-Object Entry | Select-Object -ExpandProperty Valor -Unique)
    })
}
Write-Progress -Activity 'Lendo historico dos cards' -Completed

# Ordem das colunas: posicao media da primeira entrada em cada card (aproxima a ordem do board)
$positions = @{}
foreach ($card in $cards) {
    for ($i = 0; $i -lt $card.Order.Count; $i++) {
        $name = $card.Order[$i]
        if (-not $positions.ContainsKey($name)) { $positions[$name] = New-Object System.Collections.Generic.List[double] }
        $positions[$name].Add($(if ($card.Order.Count -gt 1) { $i / ($card.Order.Count - 1) } else { 0 }))
    }
}
$columnOrder = @($positions.Keys | Where-Object { $ExcludeColumns -notcontains $_ } | Sort-Object { ($positions[$_] | Measure-Object -Average).Average })
$columnOrder = @($columnOrder | Where-Object { $_ -ne '(sem coluna)' }) + @($columnOrder | Where-Object { $_ -eq '(sem coluna)' })

$consolidatedRows = @(foreach ($card in $cards) {
    $row = [ordered]@{
        WorkItemId            = $card.Id
        Titulo                = $card.Title
        Estado                = $card.State
        Fechamento            = $card.ClosedAt
        Reaberturas           = $card.Reopenings
        LeadTimeDias          = ConvertTo-Days ($columnOrder | ForEach-Object { [int]$card.Columns[$_] } | Measure-Object -Sum).Sum
        AguardandoClienteDias = ConvertTo-Days $card.AwaitingMinutes
    }
    foreach ($name in $columnOrder) { $row[$name] = ConvertTo-Days ([int]$card.Columns[$name]) }
    [pscustomobject]$row
})

$leadTotal = [double]($consolidatedRows | Measure-Object LeadTimeDias -Sum).Sum
$doneByColumn = @{}
foreach ($s in $summaryRows | Where-Object { $_.Tipo -eq 'Coluna' }) { $doneByColumn[$s.Valor] = [int]$doneByColumn[$s.Valor] + $s.MinutosDone }

$aggregateRows = @(foreach ($metric in @('LeadTimeDias') + $columnOrder + @('AguardandoClienteDias')) {
    $values = @($consolidatedRows | ForEach-Object { [double]$_.$metric } | Where-Object { $_ -gt 0 })
    $stats = $values | Measure-Object -Average -Maximum -Sum
    [pscustomobject]@{
        Metrica          = $metric
        Cards            = $values.Count
        MediaDias        = [math]::Round([double]$stats.Average, 2)
        MedianaDias      = [math]::Round((Get-Median $values), 2)
        MaxDias          = [math]::Round([double]$stats.Maximum, 2)
        SomaDias         = [math]::Round([double]$stats.Sum, 2)
        PercentualDoLead = if ($leadTotal) { [math]::Round(100 * [double]$stats.Sum / $leadTotal, 1) } else { $null }
        SomaDiasDone     = if ($columnOrder -contains $metric) { ConvertTo-Days ([int]$doneByColumn[$metric]) } else { $null }
    }
})

if ($OutputDirectory) {
    New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $encoding = if ($PSVersionTable.PSVersion.Major -ge 6) { 'utf8BOM' } else { 'UTF8' }
    $exports = [ordered]@{ resumo = $summaryRows; periodos = $periodRows; consolidado = $consolidatedRows; agregado = $aggregateRows }
    foreach ($name in $exports.Keys) {
        $exports[$name] | Export-Csv -Path (Join-Path $OutputDirectory "$FilePrefix-$name-$stamp.csv") -NoTypeInformation -UseCulture -Encoding $encoding
    }
    Write-Host "CSVs gerados em $((Resolve-Path $OutputDirectory).Path) ($FilePrefix-*-$stamp.csv)"
}

switch ($View) {
    'Periodos' { $periodRows }
    'Consolidado' { $consolidatedRows }
    'Agregado' { $aggregateRows }
    default { $summaryRows }
}
