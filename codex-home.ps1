# Compatibility wrapper from the GitHub Codex Gratuit project to the personal Codex Home app.
[CmdletBinding()]
param(
  [ValidateSet('kimi-k2.6', 'kimi-k2.7-code', 'kimi-k2.7-code-highspeed', 'kimi-k3', 'deepseek-v4-pro', 'deepseek-v4-flash', 'deepseek-flash', 'mina-flash', 'mina-low', 'mina-full')]
  [string]$Model,
  [switch]$Headless,
  [switch]$Menu
)

$ErrorActionPreference = 'Stop'
$homeRoot = if ([string]::IsNullOrWhiteSpace($env:CODEX_HOME_APP_ROOT)) {
  [Environment]::GetEnvironmentVariable('CODEX_HOME_APP_ROOT', 'User')
} else {
  $env:CODEX_HOME_APP_ROOT
}
if ([string]::IsNullOrWhiteSpace($homeRoot)) {
  throw 'CODEX_HOME_APP_ROOT is required for the personal Codex Home launcher.'
}
$personalLauncher = Join-Path $homeRoot 'codex-home.ps1'

if (-not (Test-Path -LiteralPath $personalLauncher)) {
  throw "Personal Codex Home launcher not found: $personalLauncher. Set CODEX_HOME_APP_ROOT to the personal app directory."
}

if ($Model -and $Headless -and $Menu) {
  & $personalLauncher -Model $Model -Headless -Menu
} elseif ($Model -and $Headless) {
  & $personalLauncher -Model $Model -Headless
} elseif ($Model -and $Menu) {
  & $personalLauncher -Model $Model -Menu
} elseif ($Model) {
  & $personalLauncher -Model $Model
} elseif ($Headless -and $Menu) {
  & $personalLauncher -Headless -Menu
} elseif ($Headless) {
  & $personalLauncher -Headless
} elseif ($Menu) {
  & $personalLauncher -Menu
} else {
  & $personalLauncher
}
exit $LASTEXITCODE
