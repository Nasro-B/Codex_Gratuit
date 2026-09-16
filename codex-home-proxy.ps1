[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [ValidateSet('moonshot/kimi-k2.6', 'moonshot/kimi-k2.7-code', 'moonshot/kimi-k2.7-code-highspeed', 'moonshot/kimi-k3', 'deepseek/deepseek-v4-pro', 'deepseek/deepseek-v4-flash', 'deepseek/deepseek-flash', 'openai/mina-flash', 'openai/mina-low', 'openai/mina-full')]
  [string]$WildcardModel,

  [Parameter(Mandatory)]
  [ValidateSet('MOONSHOT_API_KEY', 'DEEPSEEK_API_KEY', 'CLOUDZIR_API_KEY')]
  [string]$RequiredEnvKey
)

$ErrorActionPreference = 'Stop'
$env:PYTHONUTF8 = '1'
$env:PYTHONIOENCODING = 'utf-8'
$repositoryRoot = $PSScriptRoot
$proxyDirectory = Join-Path $repositoryRoot 'litellm-codex'
$environmentFile = Join-Path $proxyDirectory '.env'
$configPath = Join-Path $proxyDirectory 'codex-home-config.yaml'
$bridgePath = Join-Path $repositoryRoot 'codex-home-bridge.js'
$litellmPort = 4100
$bridgePort = 4101

function Test-PortUp([int]$port) {
  $client = [Net.Sockets.TcpClient]::new()
  try {
    $connectTask = $client.ConnectAsync('127.0.0.1', $port)
    if (-not $connectTask.Wait(1000)) { return $false }
    return $client.Connected
  } catch {
    return $false
  } finally {
    $client.Dispose()
  }
}

function Import-DotEnv([string]$path) {
  foreach ($line in Get-Content -LiteralPath $path) {
    if ($line -match '^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)\s*$') {
      $name = $Matches[1]
      $value = $Matches[2].Trim()
      if (($value.Length -ge 2) -and $value.StartsWith('"') -and $value.EndsWith('"')) {
        $value = $value.Substring(1, $value.Length - 2)
      }
      if (($value.Length -ge 2) -and $value.StartsWith("'") -and $value.EndsWith("'")) {
        $value = $value.Substring(1, $value.Length - 2)
      }
      if (-not [string]::IsNullOrWhiteSpace($value)) {
        [Environment]::SetEnvironmentVariable($name, $value, 'Process')
      }
    }
  }
}

function Get-PortOwners([int]$port) {
  foreach ($connection in @(Get-NetTCPConnection -LocalAddress 127.0.0.1 -LocalPort $port -State Listen -ErrorAction SilentlyContinue)) {
    $process = Get-CimInstance Win32_Process -Filter "ProcessId=$($connection.OwningProcess)" -ErrorAction SilentlyContinue
    [pscustomobject]@{
      Port = $port
      ProcessId = $connection.OwningProcess
      CommandLine = if ($process) { $process.CommandLine } else { '' }
    }
  }
}

function Stop-CloneProxy {
  $owners = @(Get-PortOwners $litellmPort) + @(Get-PortOwners $bridgePort)
  if ($owners.Count -eq 0) { return }

  foreach ($owner in $owners) {
    if ([string]::IsNullOrWhiteSpace($owner.CommandLine) -or $owner.CommandLine.IndexOf($repositoryRoot, [StringComparison]::OrdinalIgnoreCase) -lt 0) {
      throw "Port $($owner.Port) is already used by another process. The clone was not started."
    }
  }

  $owners | Select-Object -ExpandProperty ProcessId -Unique | ForEach-Object {
    Stop-Process -Id $_ -Force -ErrorAction Stop
  }

  for ($attempt = 0; $attempt -lt 20; $attempt++) {
    if (-not (Test-PortUp $litellmPort) -and -not (Test-PortUp $bridgePort)) { return }
    Start-Sleep -Milliseconds 250
  }
  throw 'The previous Codex Home proxy did not stop cleanly.'
}

function Test-CloneProxyReady {
  if (-not (Test-PortUp $litellmPort) -or -not (Test-PortUp $bridgePort)) {
    return $false
  }

  $owners = @(Get-PortOwners $litellmPort) + @(Get-PortOwners $bridgePort)
  if ($owners.Count -eq 0) {
    throw 'Codex Home ports are open but their owners could not be identified.'
  }
  foreach ($owner in $owners) {
    if ([string]::IsNullOrWhiteSpace($owner.CommandLine) -or $owner.CommandLine.IndexOf($repositoryRoot, [StringComparison]::OrdinalIgnoreCase) -lt 0) {
      throw "Port $($owner.Port) is already used by another process. The clone was not started."
    }
  }
  return $true
}

if (-not (Test-Path -LiteralPath $environmentFile)) {
  throw "Environment file not found: $environmentFile"
}
if (-not (Test-Path -LiteralPath $bridgePath)) {
  throw "Bridge script not found: $bridgePath"
}

Import-DotEnv $environmentFile
$requiredValue = [Environment]::GetEnvironmentVariable($RequiredEnvKey, 'Process')
if ([string]::IsNullOrWhiteSpace($requiredValue)) {
  throw "Required provider key is missing from the environment file: $RequiredEnvKey"
}

$extraBody = ''
$reasoningEffort = ''
$wildcardApiBase = 'https://api.moonshot.ai/v1'
switch ($WildcardModel) {
  'moonshot/kimi-k2.6' { $extraBody = '      extra_body: {"thinking": {"type": "enabled"}}' }
  'deepseek/deepseek-v4-pro' {
    $wildcardApiBase = 'https://api.deepseek.com'
    $reasoningEffort = '      reasoning_effort: high'
    $extraBody = '      extra_body: {"thinking": {"type": "enabled"}}'
  }
  'deepseek/deepseek-v4-flash' { $wildcardApiBase = 'https://api.deepseek.com' }
  'deepseek/deepseek-flash' { $wildcardApiBase = 'https://api.deepseek.com' }
  'openai/mina-flash' { $wildcardApiBase = 'https://api.cloudzir.com/v1' }
  'openai/mina-low' { $wildcardApiBase = 'https://api.cloudzir.com/v1' }
  'openai/mina-full' { $wildcardApiBase = 'https://api.cloudzir.com/v1' }
  'moonshot/kimi-k3' { $reasoningEffort = '      reasoning_effort: max' }
}

$yaml = @"
model_list:
  - model_name: kimi-k2.6
    litellm_params:
      model: moonshot/kimi-k2.6
      api_base: https://api.moonshot.ai/v1
      api_key: os.environ/MOONSHOT_API_KEY
      use_chat_completions_api: true
      extra_body: {"thinking": {"type": "enabled"}}
    model_info:
      context_window: 262144
      max_context_window: 262144

  - model_name: kimi-k3
    litellm_params:
      model: moonshot/kimi-k3
      api_base: https://api.moonshot.ai/v1
      api_key: os.environ/MOONSHOT_API_KEY
      use_chat_completions_api: true
      reasoning_effort: max
    model_info:
      context_window: 1048576
      max_context_window: 1048576

  - model_name: kimi-k2.7-code
    litellm_params:
      model: moonshot/kimi-k2.7-code
      api_base: https://api.moonshot.ai/v1
      api_key: os.environ/MOONSHOT_API_KEY
      use_chat_completions_api: true
    model_info:
      context_window: 262144
      max_context_window: 262144

  - model_name: kimi-k2.7-code-highspeed
    litellm_params:
      model: moonshot/kimi-k2.7-code-highspeed
      api_base: https://api.moonshot.ai/v1
      api_key: os.environ/MOONSHOT_API_KEY
      use_chat_completions_api: true
    model_info:
      context_window: 262144
      max_context_window: 262144

  - model_name: deepseek-flash
    litellm_params:
      model: deepseek/deepseek-flash
      api_base: https://api.deepseek.com
      api_key: os.environ/DEEPSEEK_API_KEY
      use_chat_completions_api: true
    model_info:
      context_window: 1048576
      max_context_window: 1048576

  - model_name: deepseek-v4-flash
    litellm_params:
      model: deepseek/deepseek-v4-flash
      api_base: https://api.deepseek.com
      api_key: os.environ/DEEPSEEK_API_KEY
      use_chat_completions_api: true
    model_info:
      context_window: 1048576
      max_context_window: 1048576

  - model_name: deepseek-v4-pro
    litellm_params:
      model: deepseek/deepseek-v4-pro
      api_base: https://api.deepseek.com
      api_key: os.environ/DEEPSEEK_API_KEY
      use_chat_completions_api: true
      reasoning_effort: high
      extra_body: {"thinking": {"type": "enabled"}}
    model_info:
      context_window: 1048576
      max_context_window: 1048576

  - model_name: mina-flash
    litellm_params:
      model: openai/mina-flash
      api_base: https://api.cloudzir.com/v1
      api_key: os.environ/CLOUDZIR_API_KEY
      use_chat_completions_api: true
    model_info:
      context_window: 64000
      max_context_window: 64000

  - model_name: mina-low
    litellm_params:
      model: openai/mina-low
      api_base: https://api.cloudzir.com/v1
      api_key: os.environ/CLOUDZIR_API_KEY
      use_chat_completions_api: true
    model_info:
      context_window: 128000
      max_context_window: 128000

  - model_name: mina-full
    litellm_params:
      model: openai/mina-full
      api_base: https://api.cloudzir.com/v1
      api_key: os.environ/CLOUDZIR_API_KEY
      use_chat_completions_api: true
    model_info:
      context_window: 256000
      max_context_window: 256000

  - model_name: "*"
    litellm_params:
      model: $WildcardModel
      api_base: $wildcardApiBase
      api_key: os.environ/$RequiredEnvKey
      use_chat_completions_api: true
$reasoningEffort
$extraBody

litellm_settings:
  drop_params: true
  callbacks: codex_deepseek_fix.handler
"@
Set-Content -LiteralPath $configPath -Value $yaml -Encoding utf8

$startupMutex = [Threading.Mutex]::new($false, 'CodexHomeProxyStartup')
$lockAcquired = $false
try {
  try {
    $lockAcquired = $startupMutex.WaitOne(120000)
  } catch [Threading.AbandonedMutexException] {
    $lockAcquired = $true
  }
  if (-not $lockAcquired) { throw 'Timed out while another Codex Home proxy was starting.' }

  $proxyAlreadyReady = Test-CloneProxyReady
  if (-not $proxyAlreadyReady) {
    Stop-CloneProxy

    $node = Get-Command node -ErrorAction SilentlyContinue
    $litellm = Get-Command litellm -ErrorAction SilentlyContinue
    if (-not $node) { throw 'Node.js is required for the Codex Home bridge.' }
    if (-not $litellm) { throw 'LiteLLM is required for the Codex Home proxy.' }

    $nodePath = if ($node.Source) { $node.Source } else { $node.Path }
    $litellmPath = if ($litellm.Source) { $litellm.Source } else { $litellm.Path }

    $litellmArguments = @('--config', "`"$configPath`"", '--host', '127.0.0.1', '--port', "$litellmPort")
    Start-Process -FilePath $litellmPath -ArgumentList $litellmArguments -WorkingDirectory $proxyDirectory -WindowStyle Hidden | Out-Null
    for ($attempt = 0; $attempt -lt 240; $attempt++) {
      if (Test-PortUp $litellmPort) { break }
      Start-Sleep -Milliseconds 500
    }
    if (-not (Test-PortUp $litellmPort)) { throw 'LiteLLM did not start on port 4100 after 120 seconds.' }

    Start-Process -FilePath $nodePath -ArgumentList @('"' + $bridgePath + '"') -WorkingDirectory $repositoryRoot -WindowStyle Hidden | Out-Null
    for ($attempt = 0; $attempt -lt 20; $attempt++) {
      if (Test-PortUp $bridgePort) { break }
      Start-Sleep -Milliseconds 500
    }
    if (-not (Test-PortUp $bridgePort)) { throw 'The Codex Home bridge did not start on port 4101.' }
  }
} finally {
  if ($lockAcquired) { $startupMutex.ReleaseMutex() }
  $startupMutex.Dispose()
}
