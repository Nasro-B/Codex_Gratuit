# Compatibility wrapper from the GitHub project to the personal Codex Home proxy.
[CmdletBinding()]
param(
  [ValidateSet('moonshot/kimi-k2.6', 'moonshot/kimi-k2.7-code', 'moonshot/kimi-k2.7-code-highspeed', 'moonshot/kimi-k3', 'deepseek/deepseek-v4-pro', 'deepseek/deepseek-v4-flash', 'deepseek/deepseek-flash', 'openai/mina-flash', 'openai/mina-low', 'openai/mina-full')]
  [string]$WildcardModel = 'deepseek/deepseek-flash',
  [ValidateSet('MOONSHOT_API_KEY', 'DEEPSEEK_API_KEY', 'CLOUDZIR_API_KEY')]
  [string]$RequiredEnvKey = 'DEEPSEEK_API_KEY'
)

$ErrorActionPreference = 'Stop'
$homeRoot = if ([string]::IsNullOrWhiteSpace($env:CODEX_HOME_APP_ROOT)) {
  [Environment]::GetEnvironmentVariable('CODEX_HOME_APP_ROOT', 'User')
} else {
  $env:CODEX_HOME_APP_ROOT
}
if ([string]::IsNullOrWhiteSpace($homeRoot)) {
  throw 'CODEX_HOME_APP_ROOT is required for the personal Codex Home proxy.'
}
$personalProxy = Join-Path $homeRoot 'runtime\codex-home-proxy.ps1'

if (-not (Test-Path -LiteralPath $personalProxy)) {
  throw "Personal Codex Home proxy not found: $personalProxy. Set CODEX_HOME_APP_ROOT to the personal app directory."
}

& $personalProxy -WildcardModel $WildcardModel -RequiredEnvKey $RequiredEnvKey
exit $LASTEXITCODE
