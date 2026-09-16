[CmdletBinding()]
param(
  [ValidateSet('kimi-k2.6', 'kimi-k2.7-code', 'kimi-k2.7-code-highspeed', 'kimi-k3', 'deepseek-v4-pro', 'deepseek-v4-flash', 'deepseek-flash', 'mina-flash', 'mina-low', 'mina-full')]
  [string]$Model,
  [switch]$Headless
)

$ErrorActionPreference = 'Stop'
$repositoryRoot = $PSScriptRoot
$freeHome = Join-Path $env:USERPROFILE '.codex-openai'
$configPath = Join-Path $freeHome 'config.toml'
$proxyScript = Join-Path $repositoryRoot 'codex-home-proxy.ps1'

if (-not (Test-Path -LiteralPath $configPath)) {
  throw "Codex Free configuration not found: $configPath"
}
if (-not (Test-Path -LiteralPath $proxyScript)) {
  throw "Codex Home proxy script not found: $proxyScript"
}
if ($Headless -and -not $Model) {
  throw 'Headless mode requires an explicit model.'
}

$models = @{
  'kimi-k2.6' = [pscustomobject]@{
    Label = 'Kimi K2.6'
    ProviderModel = 'moonshot/kimi-k2.6'
    RequiredEnvKey = 'MOONSHOT_API_KEY'
  }
  'kimi-k3' = [pscustomobject]@{
    Label = 'Kimi K3'
    ProviderModel = 'moonshot/kimi-k3'
    RequiredEnvKey = 'MOONSHOT_API_KEY'
  }
  'kimi-k2.7-code' = [pscustomobject]@{
    Label = 'Kimi K2.7 Code'
    ProviderModel = 'moonshot/kimi-k2.7-code'
    RequiredEnvKey = 'MOONSHOT_API_KEY'
  }
  'kimi-k2.7-code-highspeed' = [pscustomobject]@{
    Label = 'Kimi K2.7 Code HighSpeed'
    ProviderModel = 'moonshot/kimi-k2.7-code-highspeed'
    RequiredEnvKey = 'MOONSHOT_API_KEY'
  }
  'deepseek-v4-pro' = [pscustomobject]@{
    Label = 'DeepSeek V4 Pro'
    ProviderModel = 'deepseek/deepseek-v4-pro'
    RequiredEnvKey = 'DEEPSEEK_API_KEY'
  }
  'deepseek-v4-flash' = [pscustomobject]@{
    Label = 'DeepSeek V4 Flash (alias legacy)'
    ProviderModel = 'deepseek/deepseek-v4-flash'
    RequiredEnvKey = 'DEEPSEEK_API_KEY'
  }
  'deepseek-flash' = [pscustomobject]@{
    Label = 'DeepSeek V4.1 Flash'
    ProviderModel = 'deepseek/deepseek-flash'
    RequiredEnvKey = 'DEEPSEEK_API_KEY'
  }
  'mina-flash' = [pscustomobject]@{
    Label = 'Mina Flash (CloudZIR)'
    ProviderModel = 'openai/mina-flash'
    RequiredEnvKey = 'CLOUDZIR_API_KEY'
  }
  'mina-low' = [pscustomobject]@{
    Label = 'Mina Low (CloudZIR)'
    ProviderModel = 'openai/mina-low'
    RequiredEnvKey = 'CLOUDZIR_API_KEY'
  }
  'mina-full' = [pscustomobject]@{
    Label = 'Mina Full (CloudZIR)'
    ProviderModel = 'openai/mina-full'
    RequiredEnvKey = 'CLOUDZIR_API_KEY'
  }
}

if (-not $Model) {
  Write-Host ''
  Write-Host '  ===== CODEX HOME =====' -ForegroundColor Cyan
  Write-Host ''
  Write-Host '  1) Kimi K2.6'
  Write-Host '  2) Kimi K2.7 Code'
  Write-Host '  3) Kimi K2.7 Code HighSpeed'
  Write-Host '  4) Kimi K3'
  Write-Host '  5) DeepSeek V4 Pro'
  Write-Host '  6) DeepSeek V4 Flash (alias legacy)'
  Write-Host '  7) DeepSeek V4.1 Flash'
  Write-Host '  8) Mina Flash (CloudZIR)'
  Write-Host '  9) Mina Low (CloudZIR)'
  Write-Host ' 10) Mina Full (CloudZIR)'
  Write-Host ''
  $choice = Read-Host '  Choisis le modele (1-10)'
  $Model = switch ($choice) {
    '1' { 'kimi-k2.6' }
    '2' { 'kimi-k2.7-code' }
    '3' { 'kimi-k2.7-code-highspeed' }
    '4' { 'kimi-k3' }
    '5' { 'deepseek-v4-pro' }
    '6' { 'deepseek-v4-flash' }
    '7' { 'deepseek-flash' }
    '8' { 'mina-flash' }
    '9' { 'mina-low' }
    '10' { 'mina-full' }
    default { throw 'Invalid model choice.' }
  }
}

$selected = $models[$Model]

function Set-FreeHomeConfig {
  param(
    [string]$Path,
    [string]$ModelName,
    [string]$CatalogPath
  )

  $lines = Get-Content -LiteralPath $Path
  $output = New-Object System.Collections.Generic.List[string]
  $inHeader = $true
  $inLiteLlm = $false
  $catalogWritten = $false

  foreach ($line in $lines) {
    if ($line -match '^\s*\[') {
      if ($inLiteLlm -and -not $catalogWritten) {
        $output.Add("model_catalog_json = '$CatalogPath'")
      }
      $inHeader = $false
      $inLiteLlm = $line -match '^\s*\[model_providers\.litellm\]\s*$'
      $catalogWritten = $false
    }

    if ($inHeader -and $line -match '^\s*model\s*=') {
      $output.Add("model = `"$ModelName`"")
      continue
    }
    if ($inHeader -and $line -match '^\s*model_provider\s*=') {
      $output.Add('model_provider = "litellm"')
      continue
    }
    if ($inHeader -and $line -match '^\s*model_reasoning_effort\s*=') {
      $output.Add('model_reasoning_effort = "xhigh"')
      continue
    }
    if ($inLiteLlm -and $line -match '^\s*base_url\s*=') {
      $output.Add('base_url = "http://127.0.0.1:4101/v1/"')
      continue
    }
    if ($inLiteLlm -and $line -match '^\s*model_catalog_json\s*=') {
      $output.Add("model_catalog_json = '$CatalogPath'")
      $catalogWritten = $true
      continue
    }
    $output.Add($line)
  }

  if ($inLiteLlm -and -not $catalogWritten) {
    $output.Add("model_catalog_json = '$CatalogPath'")
  }
  Set-Content -LiteralPath $Path -Value $output -Encoding utf8
}

$catalogPath = Join-Path $repositoryRoot 'litellm-codex\litellm-models.json'
Set-FreeHomeConfig -Path $configPath -ModelName $Model -CatalogPath $catalogPath

# This value is process-scoped and does not alter the original Codex home.
$env:CODEX_HOME = $freeHome
& $proxyScript -WildcardModel $selected.ProviderModel -RequiredEnvKey $selected.RequiredEnvKey

if ($Headless) {
  Write-Host "[ok] Codex Home prepare pour codex exec sur '$Model'." -ForegroundColor Green
  exit 0
}

$package = Get-AppxPackage -Name 'Nasro.Codex.Free' |
  Sort-Object Version -Descending |
  Select-Object -First 1
if (-not $package) {
  throw 'The Codex Free clone package is not installed.'
}

$executable = Join-Path $package.InstallLocation 'app\ChatGPT.exe'
if (-not (Test-Path -LiteralPath $executable)) {
  throw "Clone executable not found: $executable"
}

$workingDirectory = Join-Path $package.InstallLocation 'app'
Start-Process -FilePath $executable -WorkingDirectory $workingDirectory
