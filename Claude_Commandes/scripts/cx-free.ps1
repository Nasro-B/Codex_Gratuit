# Pont Claude Code vers Codex Home headless.
# Toutes les executions utilisent le home personnel Codex Home .codex-home et le proxy 4100/4101.
[CmdletBinding()]
param(
  [ValidateSet('review', 'critique', 'task', 'agent', 'plan', 'status', 'models', 'health')]
  [string]$Mode = 'review',
  [Alias('Provider')]
  [string]$Model = 'deepseek-flash',
  [string]$Base = '',
  [string]$Prompt = '',
  [switch]$Write,
  [string]$Repo = (Get-Location).Path,
  [string]$Root = 'C:\Serveurs\Codex Gratuit',
  [string]$HomeRoot = ''
)

$ErrorActionPreference = 'Stop'
$HomeRoot = if ([string]::IsNullOrWhiteSpace($HomeRoot)) {
  $configuredHomeRoot = if ([string]::IsNullOrWhiteSpace($env:CODEX_HOME_APP_ROOT)) { [Environment]::GetEnvironmentVariable('CODEX_HOME_APP_ROOT', 'User') } else { $env:CODEX_HOME_APP_ROOT }
  if ([string]::IsNullOrWhiteSpace($configuredHomeRoot)) { throw 'CODEX_HOME_APP_ROOT is required. Set it to the personal Codex Home directory.' } else { $configuredHomeRoot }
} else {
  $HomeRoot
}
$freeHome = Join-Path $env:USERPROFILE '.codex-home'
$homeLauncher = Join-Path $HomeRoot 'codex-home.ps1'
$configPath = Join-Path $freeHome 'config.toml'
$catalogPath = Join-Path $HomeRoot 'runtime\litellm-models.json'
$bridgeModelsUri = 'http://127.0.0.1:4101/v1/models'

$targetModels = [ordered]@{
  'kimi-k2.6' = [pscustomobject]@{ Label = 'Kimi K2.6'; Context = 262144 }
  'kimi-k2.7-code' = [pscustomobject]@{ Label = 'Kimi K2.7 Code'; Context = 262144 }
  'kimi-k2.7-code-highspeed' = [pscustomobject]@{ Label = 'Kimi K2.7 Code HighSpeed'; Context = 262144 }
  'kimi-k3' = [pscustomobject]@{ Label = 'Kimi K3'; Context = 1048576 }
  'deepseek-v4-pro' = [pscustomobject]@{ Label = 'DeepSeek V4 Pro'; Context = 1048576 }
  'deepseek-v4-flash' = [pscustomobject]@{ Label = 'DeepSeek V4 Flash legacy'; Context = 1048576 }
  'deepseek-flash' = [pscustomobject]@{ Label = 'DeepSeek V4.1 Flash'; Context = 1048576 }
  'mina-flash' = [pscustomobject]@{ Label = 'Mina Flash (CloudZIR)'; Context = 64000 }
  'mina-low' = [pscustomobject]@{ Label = 'Mina Low (CloudZIR)'; Context = 128000 }
  'mina-full' = [pscustomobject]@{ Label = 'Mina Full (CloudZIR)'; Context = 256000 }
}

# Compatibilite avec les anciens arguments -Provider.
$aliases = @{
  'deepseek' = 'deepseek-flash'
  'ds' = 'deepseek-flash'
  'deepseek-pro' = 'deepseek-v4-pro'
  'kimi' = 'kimi-k2.6'
  'kimi-2.6' = 'kimi-k2.6'
  'deepseek-v4.1-flash' = 'deepseek-flash'
}

$inputModel = $Model.Trim().ToLowerInvariant()
if ($aliases.ContainsKey($inputModel)) {
  $inputModel = $aliases[$inputModel]
}
if (-not $targetModels.Contains($inputModel)) {
  throw "Modele '$Model' indisponible dans Codex Home. Utilise /cx-free-models pour la liste."
}
$resolvedModel = $inputModel

function Test-PortUp([int]$Port) {
  $connections = @(Get-NetTCPConnection -LocalAddress 127.0.0.1 -LocalPort $Port -State Listen -ErrorAction SilentlyContinue)
  return $connections.Count -gt 0
}

function Format-Context([int]$Value) {
  if ($Value -ge 1000000) {
    return ('{0:0.##}M' -f ($Value / 1000000))
  }
  if ($Value -ge 1000) {
    return ('{0:0.#}k' -f ($Value / 1000))
  }
  return [string]$Value
}

function Get-Catalog() {
  if (-not (Test-Path -LiteralPath $catalogPath)) {
    throw "Catalogue Codex Home introuvable : $catalogPath"
  }
  return (Get-Content -Raw -LiteralPath $catalogPath | ConvertFrom-Json)
}

function Show-Models() {
  $catalog = Get-Catalog
  $rows = foreach ($name in $targetModels.Keys) {
    $spec = $targetModels[$name]
    $entry = @($catalog.models | Where-Object { $_.slug -eq $name } | Select-Object -First 1)
    $context = if ($entry) { [int]$entry.context_window } else { $spec.Context }
    $modalities = if ($entry -and $entry.input_modalities) { (@($entry.input_modalities) -join ',') } else { 'text' }
    [pscustomobject]@{
      Modele = $name
      Libelle = $spec.Label
      Contexte = Format-Context $context
      Modalites = $modalities
      Etat = if ($entry) { 'configure' } else { 'absent du catalogue' }
    }
  }
  $rows | Format-Table -AutoSize
}

function Show-Status() {
  $proxy = Test-PortUp 4100
  $bridge = Test-PortUp 4101
  Write-Output "Home Codex Home : $freeHome"
  Write-Output ("Proxy LiteLLM 4100 : " + $(if ($proxy) { 'UP' } else { 'DOWN' }))
  Write-Output ("Pont API 4101 : " + $(if ($bridge) { 'UP' } else { 'DOWN' }))
  Write-Output 'Les commandes cx-free ne demarrent pas l application graphique Codex.'
  Write-Output ("Modeles : " + ($targetModels.Keys -join ', '))
}

function Start-CodexHomeHeadless() {
  if (-not (Test-Path -LiteralPath $homeLauncher)) {
    throw "Lanceur Codex Home introuvable : $homeLauncher"
  }
  if (-not (Test-Path -LiteralPath $Repo -PathType Container)) {
    throw "Depot ou dossier de travail introuvable : $Repo"
  }

  # Variable uniquement dans ce processus et ses enfants. Le home original reste intact.
  $env:CODEX_HOME = $freeHome
  $pwsh = Get-Command pwsh -ErrorAction Stop
  $pwshPath = if ($pwsh.Source) { $pwsh.Source } else { $pwsh.Path }
  $launcherOutput = @(& $pwshPath -NoLogo -NoProfile -File $homeLauncher -Model $resolvedModel -Headless 2>&1)
  $launcherCode = $LASTEXITCODE
  if ($launcherCode -ne 0) {
    $tail = ($launcherOutput | Select-Object -Last 12) -join [Environment]::NewLine
    throw ("Codex Home proxy indisponible (code {0}).{1}{2}" -f $launcherCode, [Environment]::NewLine, $tail)
  }
  if (-not (Test-Path -LiteralPath $configPath)) {
    throw "Configuration Codex Home absente apres preparation : $configPath"
  }
}

function Test-Health() {
  Start-CodexHomeHeadless
  $headers = @{ Authorization = 'Bearer sk-codex-local' }
  $response = Invoke-RestMethod -Uri $bridgeModelsUri -Headers $headers -TimeoutSec 15
  $ids = @($response.data | ForEach-Object { $_.id })
  [pscustomobject]@{
    Home = $freeHome
    Proxy4100 = if (Test-PortUp 4100) { 'UP' } else { 'DOWN' }
    Bridge4101 = if (Test-PortUp 4101) { 'UP' } else { 'DOWN' }
    SelectedModel = $resolvedModel
    SelectedModelVisible = ($ids -contains $resolvedModel)
    ModelCount = @($ids | Where-Object { $_ -ne '*' }).Count
  } | Format-List
}

function Get-ReviewPrompt([string]$ReviewMode) {
  $target = if ($Base) {
    "Compare la branche courante a '$Base' avec git diff $Base...HEAD et git log --oneline $Base..HEAD."
  } else {
    'Relis le travail non commite avec git status, git diff, git diff --cached et les fichiers non suivis pertinents.'
  }

  if ($ReviewMode -eq 'review') {
    return @"
Tu es un relecteur de code senior. Fais une revue rigoureuse des changements de ce depot, en lecture seule. $target
Lis les fichiers concernes pour le contexte, pas seulement le diff. Ne signale que des problemes reels et verifiables.
Reponds en francais :
1. Resume court.
2. Findings tries par gravite : [CRITIQUE|ELEVEE|MOYENNE|FAIBLE] fichier:ligne - probleme - correctif propose.
3. Couvre bugs, securite, erreurs reseau, cas limites, concurrence, performance et regressions.
4. Verdict : OK, a corriger ou bloquant.
"@
  }

  return @"
Tu es un relecteur de code adversarial. Cherche activement le bug le plus dangereux dans les changements de ce depot, en lecture seule. $target
Pour chaque finding, donne un scenario de reproduction concret, un impact et un correctif. Ne fabrique rien : chaque finding doit pointer un fichier et une ligne reels.
Reponds en francais :
1. Bug le plus dangereux, s'il existe.
2. Autres findings tries par gravite.
3. Angles verifies sans probleme.
4. Verdict : bloquant, a corriger ou OK.
"@
}

function Get-PlanPrompt() {
  $request = if ([string]::IsNullOrWhiteSpace($Prompt)) {
    'Analyse le depot courant et propose les prochaines ameliorations prioritaires.'
  } else {
    $Prompt
  }
  return @"
Tu es un architecte logiciel pragmatique. Analyse le depot en lecture seule et prepare un plan d implementation pour cette demande :
$request
Inspecte le code reel, les tests et la configuration utile. Ne modifie rien et n invente aucun fichier ou endpoint.
Reponds en francais avec : contexte constate, problemes prouves, plan numerote, fichiers concernes, tests a ajouter ou executer, risques et criteres d acceptation.
"@
}

function Get-AgentPrompt() {
  $mission = if ([string]::IsNullOrWhiteSpace($Prompt)) {
    'Inspecte le depot et propose la prochaine action utile.'
  } else {
    $Prompt
  }
  return @"
Tu es un agent Codex delegue depuis Claude Code. Travaille dans le depot courant avec methode et sans inventer le code ou l architecture.
Mission :
$mission

Inspecte d abord le contexte reel. Execute les verifications utiles. En lecture seule, ne modifie rien. Si l ecriture est autorisee par le sandbox, applique uniquement les changements necessaires, puis verifie-les avec des tests cibles. Rends un compte rendu en francais avec les fichiers touches, les commandes executees, les resultats, les risques et ce qui reste a faire.
"@
}

function Invoke-Codex([string]$RunMode) {
  if (-not (Get-Command codex -ErrorAction SilentlyContinue)) {
    throw 'Codex CLI introuvable dans le PATH.'
  }
  if ($RunMode -in @('task', 'agent') -and [string]::IsNullOrWhiteSpace($Prompt)) {
    throw "Le mode $RunMode exige -Prompt."
  }

  Start-CodexHomeHeadless
  $env:CODEX_HOME = $freeHome
  $sandbox = if ($RunMode -in @('task', 'agent') -and $Write) { 'workspace-write' } else { 'read-only' }
  $promptText = switch ($RunMode) {
    'review' { Get-ReviewPrompt 'review' }
    'critique' { Get-ReviewPrompt 'critique' }
    'plan' { Get-PlanPrompt }
    'agent' { Get-AgentPrompt }
    default { $Prompt }
  }

  $suffix = [Guid]::NewGuid().ToString('N')
  $outFile = Join-Path $env:TEMP ("cx-free-home-$suffix.txt")
  $logFile = Join-Path $env:TEMP ("cx-free-home-$suffix.log")
  $codexCommand = Get-Command codex -ErrorAction Stop
  $codexPath = if ($codexCommand.Source) { $codexCommand.Source } else { $codexCommand.Path }
  $codexArguments = @(
    'exec',
    '-c', 'model_provider=litellm',
    '-m', $resolvedModel,
    '--sandbox', $sandbox,
    '--skip-git-repo-check',
    '--color', 'never',
    '-C', $Repo,
    '-o', $outFile,
    $promptText
  )

  Write-Host "[cx-free] Codex Home : modele=$resolvedModel sandbox=$sandbox repo=$Repo"
  Write-Host '[cx-free] execution headless en cours via le proxy 4100/4101...'
  $code = 1
  try {
    $null | & $codexPath @codexArguments *> $logFile
    $code = $LASTEXITCODE
    Write-Host ''
    Write-Host "===== RAPPORT CODEX-HOME ($resolvedModel) ====="
    if ((Test-Path -LiteralPath $outFile) -and ((Get-Item -LiteralPath $outFile).Length -gt 0)) {
      Get-Content -Raw -LiteralPath $outFile
    } else {
      Write-Host '(aucun rapport final capture)'
    }
    if ($code -ne 0) {
      Write-Host ''
      Write-Host "----- codex a quitte avec le code $code ; fin du log -----"
      if (Test-Path -LiteralPath $logFile) {
        Get-Content -Tail 20 -LiteralPath $logFile
      }
    }
  } finally {
    Remove-Item -LiteralPath $outFile -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $logFile -ErrorAction SilentlyContinue
  }
  exit $code
}

switch ($Mode) {
  'status' { Show-Status; exit 0 }
  'models' { Show-Models; exit 0 }
  'health' { Test-Health; exit 0 }
  default { Invoke-Codex $Mode }
}
