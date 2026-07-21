#Requires -Version 5.1
# Seed inicial do repo a partir de ~/.copilot. Uso PONTUAL (nao rodar em repo ja colaborativo).
[CmdletBinding()]
param(
    [string]$Source = (Join-Path $env:USERPROFILE ".copilot"),
    [string]$Dest   = (Split-Path $PSScriptRoot -Parent)
)
$ErrorActionPreference = "Stop"
$utf8 = New-Object System.Text.UTF8Encoding($false)
function ReplaceCI([string]$t,[string]$f,[string]$r){ return [regex]::Replace($t,[regex]::Escape($f),$r.Replace("$","$$"),[System.Text.RegularExpressions.RegexOptions]::IgnoreCase) }

$gh = Join-Path $Dest ".github"
$agentsDir = Join-Path $gh "agents"
$refDir    = Join-Path $agentsDir "tasy-html5-developer"
$instrDir  = Join-Path $gh "instructions"
$skillsDir = Join-Path $gh "skills"
New-Item -ItemType Directory -Force -Path $agentsDir,$refDir,$instrDir,$skillsDir | Out-Null

Copy-Item (Join-Path $Source "agents\Tasy HTML5 Developer.agent.md") $agentsDir -Force
Copy-Item (Join-Path $Source "agents\tasy-html5-developer\*") $refDir -Recurse -Force
Copy-Item (Join-Path $Source "instructions\tasy-workflow.instructions.md") $instrDir -Force
$skills = @("corcpa","corcre","corctb","corfin","corman-f1","corman-go","corman-os","fatact","tasy-playwright","azure-devops","oracle")
foreach ($s in $skills) { $src = Join-Path $Source ("skills\" + $s); if (Test-Path $src) { Copy-Item $src $skillsDir -Recurse -Force } else { Write-Warning ("faltando: " + $s) } }

Get-ChildItem $gh -Recurse -Include *.md | ForEach-Object {
  $c = Get-Content $_.FullName -Raw; $o = $c
  $c = ReplaceCI $c ($Source + "\agents\tasy-html5-developer\") ".github/agents/tasy-html5-developer/"
  $c = ReplaceCI $c ($Source + "\instructions\") ".github/instructions/"
  $c = ReplaceCI $c ($Source + "\skills\") ".github/skills/"
  $c = ReplaceCI $c ($Source + "\") ".github/"
  if ($c -ne $o) { [System.IO.File]::WriteAllText($_.FullName,$c,$utf8) }
}

$agentFile = Join-Path $agentsDir "Tasy HTML5 Developer.agent.md"
$a = Get-Content $agentFile -Raw
$nl = [Environment]::NewLine
$novo = "## Usuario" + $nl + $nl + "Este agente e utilizado por desenvolvedores da equipe Tasy. Referencias possessivas (meus cards, meus PRs, minhas tasks) referem-se ao usuario atual (identidade do MCP do Azure DevOps)."
$a2 = [regex]::Replace($a,"## Usu.rio.*?(?=\r?\n---)",$novo.Replace("$","$$"),[System.Text.RegularExpressions.RegexOptions]::Singleline)
if ($a2 -ne $a) { [System.IO.File]::WriteAllText($agentFile,$a2,$utf8); Write-Host "identidade generalizada" } else { Write-Warning "bloco de identidade nao encontrado; ajuste manual" }

Write-Host ("Seed concluido -> " + $Dest)