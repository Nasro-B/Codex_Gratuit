# install.ps1 - Installe les commandes cx-free dans Claude Code et Codex Home.
# Usage : pwsh -NoProfile -File "C:\Serveurs\Codex Gratuit\Claude_Commandes\install.ps1"
$ErrorActionPreference = 'Stop'
$src = $PSScriptRoot
$homeLauncher = 'C:\Serveurs\Codex Gratuit\codex-home.ps1'
$homeConfig = Join-Path $env:USERPROFILE '.codex-openai\config.toml'

$claudeCmd     = Join-Path $env:USERPROFILE '.claude\commands'
$claudeScripts = Join-Path $env:USERPROFILE '.claude\scripts'
$codexPrompts  = Join-Path $env:USERPROFILE '.codex-openai\prompts'
New-Item -ItemType Directory -Force $claudeCmd, $claudeScripts, $codexPrompts | Out-Null

# 1) Slash-commandes Claude Code
Copy-Item "$src\commands\*.md" $claudeCmd -Force
# 2) Helper PowerShell
Copy-Item "$src\scripts\*.ps1" $claudeScripts -Force
# 3) Prompts custom de Codex Home, jamais dans le home OpenAI original.
if (Test-Path "$src\prompts") { Copy-Item "$src\prompts\*.md" $codexPrompts -Force }

Write-Host "[ok] Slash-commandes Claude Code installees :" -ForegroundColor Green
Get-ChildItem "$claudeCmd\cx-free-*.md" | ForEach-Object { Write-Host ("   /" + $_.BaseName) }
Write-Host "[ok] Helper : $claudeScripts\cx-free.ps1" -ForegroundColor Green
Write-Host "[ok] Prompts Codex Home : /relire, /relire-critique" -ForegroundColor Green

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
Write-Host ("  proxy 4100/4101 : " + $(if ((Get-NetTCPConnection -LocalPort 4100 -State Listen -ErrorAction SilentlyContinue) -and (Get-NetTCPConnection -LocalPort 4101 -State Listen -ErrorAction SilentlyContinue)) { 'UP' } else { 'DOWN (demarre auto au 1er appel)' }))

Write-Host "`nRedemarre Claude Code (ou recharge la session) pour voir les /cx-free-*." -ForegroundColor Cyan
