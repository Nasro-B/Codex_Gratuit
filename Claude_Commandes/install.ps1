# install.ps1 - Installe les commandes cx-free dans Claude Code et le home personnel Codex Home.
# Usage : pwsh -NoProfile -File "C:\Serveurs\Codex Gratuit\Claude_Commandes\install.ps1" -ImportAssets
[CmdletBinding()]
param(
  [string]$HomeRoot = '',
  [switch]$ImportAssets
)

$ErrorActionPreference = 'Stop'
$src = $PSScriptRoot
$HomeRoot = if ([string]::IsNullOrWhiteSpace($HomeRoot)) {
  $configuredHomeRoot = if ([string]::IsNullOrWhiteSpace($env:CODEX_HOME_APP_ROOT)) { [Environment]::GetEnvironmentVariable('CODEX_HOME_APP_ROOT', 'User') } else { $env:CODEX_HOME_APP_ROOT }
  if ([string]::IsNullOrWhiteSpace($configuredHomeRoot)) { throw 'CODEX_HOME_APP_ROOT is required. Set it to the personal Codex Home directory.' } else { $configuredHomeRoot }
} else {
  $HomeRoot
}
$homeLauncher = Join-Path $HomeRoot 'codex-home.ps1'
$homeConfig = Join-Path $env:USERPROFILE '.codex-home\config.toml'

$claudeCmd     = Join-Path $env:USERPROFILE '.claude\commands'
$claudeScripts = Join-Path $env:USERPROFILE '.claude\scripts'
$codexPrompts  = Join-Path $env:USERPROFILE '.codex-home\prompts'
New-Item -ItemType Directory -Force $claudeCmd, $claudeScripts, $codexPrompts | Out-Null

# 1) Slash-commandes Claude Code
Copy-Item "$src\commands\*.md" $claudeCmd -Force
# 2) Helper PowerShell
Copy-Item "$src\scripts\*.ps1" $claudeScripts -Force
# 3) Prompts custom de Codex Home, jamais dans le home OpenAI original.
if (Test-Path "$src\prompts") { Copy-Item "$src\prompts\*.md" $codexPrompts -Force }

if ($ImportAssets) {
  $assetImporter = Join-Path $src '..\scripts\import-codex-assets.ps1'
  if (-not (Test-Path -LiteralPath $assetImporter)) {
    throw "Asset importer not found: $assetImporter"
  }
  Write-Host "[info] Import idempotent des plugins, competences, agents et connecteurs sans identifiants..." -ForegroundColor Cyan
  & $assetImporter
  if ($LASTEXITCODE -ne 0) {
    throw "Asset import failed with exit code $LASTEXITCODE."
  }
}

Write-Host "[ok] Slash-commandes Claude Code installees :" -ForegroundColor Green
Get-ChildItem "$claudeCmd\cx-free-*.md" | ForEach-Object { Write-Host ("   /" + $_.BaseName) }
Write-Host "[ok] Helper : $claudeScripts\cx-free.ps1" -ForegroundColor Green
Write-Host "[ok] Prompts Codex Home personnel : /relire, /relire-critique" -ForegroundColor Green

# 4) Verifs prerequis
Write-Host "`n=== Prerequis ===" -ForegroundColor Cyan
$codexOk = [bool](Get-Command codex -ErrorAction SilentlyContinue)
$litellmOk = [bool](Get-Command litellm -ErrorAction SilentlyContinue)
$launcherOk = Test-Path -LiteralPath $homeLauncher
$configOk = Test-Path -LiteralPath $homeConfig
Write-Host ("  codex CLI    : " + $(if ($codexOk) { 'OK' } else { 'MANQUANT (npm i -g @openai/codex)' }))
Write-Host ("  litellm      : " + $(if ($litellmOk) { 'OK' } else { 'MANQUANT (uv tool install litellm)' }))
Write-Host ("  codex-home   : " + $(if ($launcherOk) { 'OK' } else { 'MANQUANT : ' + $homeLauncher }))
Write-Host ("  config libre : " + $(if ($configOk) { 'OK' } else { 'MANQUANTE : ' + $homeConfig }))
Write-Host ("  runtime perso: " + $(if (Test-Path -LiteralPath (Join-Path $HomeRoot 'runtime\codex-home-proxy.ps1')) { 'OK' } else { 'MANQUANT : ' + (Join-Path $HomeRoot 'runtime') }))
Write-Host ("  proxy 4100/4101 : " + $(if ((Get-NetTCPConnection -LocalPort 4100 -State Listen -ErrorAction SilentlyContinue) -and (Get-NetTCPConnection -LocalPort 4101 -State Listen -ErrorAction SilentlyContinue)) { 'UP' } else { 'DOWN (demarre auto au 1er appel)' }))

Write-Host "`nRedemarre Claude Code (ou recharge la session) pour voir les /cx-free-*." -ForegroundColor Cyan
