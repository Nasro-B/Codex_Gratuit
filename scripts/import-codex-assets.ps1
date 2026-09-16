[CmdletBinding()]
param(
  [string]$SourceCodexHome = (Join-Path $env:USERPROFILE '.codex'),
  [string]$SourceClaudeHome = (Join-Path $env:USERPROFILE '.claude'),
  [string]$TargetCodexHome = (Join-Path $env:USERPROFILE '.codex-openai'),
  [string]$PersonalCodexHome = (Join-Path $env:USERPROFILE '.codex-home'),
  [switch]$SkipPlugins,
  [switch]$SkipConnectors,
  [switch]$SkipCxPrompts
)

$ErrorActionPreference = 'Stop'

$stats = [ordered]@{
  pluginAdded = 0
  pluginSame = 0
  pluginConflict = 0
  skillAdded = 0
  skillSame = 0
  skillConflict = 0
  agentAdded = 0
  agentSame = 0
  agentConflict = 0
  promptAdded = 0
  promptSame = 0
  promptConflict = 0
  connectorAdded = 0
  connectorSkipped = 0
  filesSkipped = 0
  sensitiveFilesSkipped = 0
}

function Add-Stat([string]$name, [int]$count = 1) {
  $stats[$name] = [int]$stats[$name] + $count
}

function Ensure-Directory([string]$path) {
  if (-not (Test-Path -LiteralPath $path)) {
    New-Item -ItemType Directory -Path $path -Force | Out-Null
  }
}

function Get-RelativePath([string]$root, [string]$path) {
  return $path.Substring($root.TrimEnd('\').Length).TrimStart('\')
}

function Get-Hash([string]$path) {
  return (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
}

function Test-SkippedPath([string]$relativePath) {
  $parts = $relativePath -split '[\\/]'
  $blockedSegments = @(
    '.git', '.tmp', 'temp', 'staging', 'telemetry', 'sessions',
    'archived_sessions', 'logs', '__pycache__'
  )
  if ($parts | Where-Object { $blockedSegments -contains $_ }) {
    return $true
  }

  $name = $parts[-1]
  if ($name -in @(
      'auth.json', 'credentials.json', 'credentials.local.json',
      'mcp-needs-auth-cache.json', 'installed_plugins.json',
      'known_marketplaces.json', 'blocklist.json', '.last_inuse_sweep',
      'settings.local.json'
    )) {
    return $true
  }
  if ($name -match '(?i)^(\.env|\.env\.[^.]+)$' -and $name -ne '.env.example') {
    return $true
  }
  if ($name -match '(?i)\.(sqlite|sqlite3|db|log|bak)$') {
    return $true
  }
  return $false
}

function Test-SafeText([string]$text) {
  $pattern = '(?im)^\s*[''"]?(api[_-]?key|access[_-]?token|refresh[_-]?token|client[_-]?secret|password|authorization|cookie|secret|token)[''"]?\s*[:=]\s*[''"]?([^''",#\r\n]+)'
  foreach ($match in [regex]::Matches($text, $pattern)) {
    $value = $match.Groups[2].Value.Trim()
    if ([string]::IsNullOrWhiteSpace($value)) {
      continue
    }
    if ($value -match '^(\$\{|\$env:|%[A-Za-z_][A-Za-z0-9_]*%|env:|process\.env|os\.environ|ENV\[|<|YOUR_|your_|null$|true$|false$|\d+$)') {
      continue
    }
    return $false
  }
  return $true
}

function Test-SafeFile([System.IO.FileInfo]$file) {
  $relativeName = $file.Name
  if ($file.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
    return $false
  }
  if ($relativeName -match '(?i)^(auth|credentials|secrets?)(\.|$)') {
    return $false
  }

  $configLike = $file.Extension -in @('.json', '.jsonc', '.toml', '.yaml', '.yml') -or
    $relativeName -match '(?i)(^|\.)mcp(_config)?\.json$'
  if (-not $configLike) {
    return $true
  }

  try {
    $text = [System.IO.File]::ReadAllText($file.FullName)
  } catch {
    return $false
  }
  return Test-SafeText $text
}

function Copy-SafeTree([string]$sourceRoot, [string]$targetRoot, [string]$kind) {
  if (-not (Test-Path -LiteralPath $sourceRoot)) {
    return
  }
  Ensure-Directory $targetRoot
  foreach ($file in Get-ChildItem -LiteralPath $sourceRoot -Recurse -File -Force -ErrorAction SilentlyContinue) {
    $relativePath = Get-RelativePath $sourceRoot $file.FullName
    if (Test-SkippedPath $relativePath) {
      Add-Stat 'filesSkipped'
      continue
    }
    if (-not (Test-SafeFile $file)) {
      Add-Stat 'sensitiveFilesSkipped'
      continue
    }

    $destination = Join-Path $targetRoot $relativePath
    Ensure-Directory (Split-Path -Parent $destination)
    if (Test-Path -LiteralPath $destination) {
      try {
        $same = (Get-Hash $file.FullName) -eq (Get-Hash $destination)
      } catch {
        $same = $false
      }
      if ($same) {
        Add-Stat ($kind + 'Same')
      } else {
        Add-Stat ($kind + 'Conflict')
      }
      continue
    }

    Copy-Item -LiteralPath $file.FullName -Destination $destination -Force
    Add-Stat ($kind + 'Added')
  }
}

function Import-PluginCache([string]$sourceRoot, [string]$targetRoot) {
  if (-not (Test-Path -LiteralPath $sourceRoot)) {
    return
  }
  Ensure-Directory $targetRoot
  foreach ($marketplace in Get-ChildItem -LiteralPath $sourceRoot -Directory -Force -ErrorAction SilentlyContinue) {
    if ($marketplace.Name -match '^(?i)(temp|staging|remote-plugin-install-staging)$') {
      continue
    }
    $targetMarketplace = Join-Path $targetRoot $marketplace.Name
    Ensure-Directory $targetMarketplace
    foreach ($plugin in Get-ChildItem -LiteralPath $marketplace.FullName -Directory -Force -ErrorAction SilentlyContinue) {
      $targetPlugin = Join-Path $targetMarketplace $plugin.Name
      if (Test-Path -LiteralPath $targetPlugin) {
        $existingFiles = @(Get-ChildItem -LiteralPath $targetPlugin -Recurse -File -Force -ErrorAction SilentlyContinue)
        $sourceFiles = @(Get-ChildItem -LiteralPath $plugin.FullName -Recurse -File -Force -ErrorAction SilentlyContinue)
        if ($existingFiles.Count -gt 0 -and $sourceFiles.Count -gt 0) {
          Add-Stat 'pluginSame'
        }
        continue
      }
      Copy-SafeTree $plugin.FullName $targetPlugin 'plugin'
    }
  }
}

function Import-SkillDirectories([string]$sourceRoot, [string]$targetRoot) {
  if (-not (Test-Path -LiteralPath $sourceRoot)) {
    return
  }
  Ensure-Directory $targetRoot
  foreach ($skill in Get-ChildItem -LiteralPath $sourceRoot -Directory -Force -ErrorAction SilentlyContinue) {
    $destination = Join-Path $targetRoot $skill.Name
    if (Test-Path -LiteralPath $destination) {
      Add-Stat 'skillSame'
      continue
    }
    Copy-SafeTree $skill.FullName $destination 'skill'
  }
}

function Escape-Toml([string]$value) {
  return $value.Replace('\', '\\').Replace('"', '\"')
}

function Convert-ClaudeAgent([System.IO.FileInfo]$sourceFile, [string]$destination) {
  $lines = [System.IO.File]::ReadAllLines($sourceFile.FullName)
  if ($lines.Count -lt 3 -or $lines[0].Trim() -ne '---') {
    return $false
  }
  $closing = -1
  for ($index = 1; $index -lt $lines.Count; $index++) {
    if ($lines[$index].Trim() -eq '---') {
      $closing = $index
      break
    }
  }
  if ($closing -lt 0) {
    return $false
  }

  $name = ''
  $description = ''
  for ($index = 1; $index -lt $closing; $index++) {
    if ($lines[$index] -match '^\s*name:\s*(.+?)\s*$') {
      $name = $Matches[1].Trim()
    } elseif ($lines[$index] -match '^\s*description:\s*(.+?)\s*$') {
      $description = $Matches[1].Trim()
    }
  }
  if ([string]::IsNullOrWhiteSpace($name)) {
    $name = [System.IO.Path]::GetFileNameWithoutExtension($sourceFile.Name)
  }
  if ([string]::IsNullOrWhiteSpace($description)) {
    $description = 'Imported Claude agent.'
  }

  $body = ($lines[($closing + 1)..($lines.Count - 1)] -join [Environment]::NewLine).Trim()
  $body = $body.Replace("'''", "''")
  $sandbox = if (($description + "`n" + $body) -match '(?i)read-only|does not edit|don''t edit|ne modifie pas') {
    'read-only'
  } else {
    'workspace-write'
  }
  $content = @(
    ('name = "' + (Escape-Toml $name) + '"'),
    ('description = "' + (Escape-Toml $description) + '"'),
    ('sandbox_mode = "' + $sandbox + '"'),
    "developer_instructions = '''",
    $body,
    "'''",
    ''
  ) -join [Environment]::NewLine
  Set-Content -LiteralPath $destination -Value $content -Encoding utf8
  return $true
}

function Import-Agents([string]$sourceRoot, [string]$targetRoot) {
  if (-not (Test-Path -LiteralPath $sourceRoot)) {
    return
  }
  Ensure-Directory $targetRoot
  $existingStems = @{}
  foreach ($file in Get-ChildItem -LiteralPath $targetRoot -File -Force -ErrorAction SilentlyContinue) {
    $existingStems[$file.BaseName.ToLowerInvariant()] = $true
  }

  foreach ($sourceFile in Get-ChildItem -LiteralPath $sourceRoot -File -Force -ErrorAction SilentlyContinue) {
    $stem = $sourceFile.BaseName.ToLowerInvariant()
    if ($sourceFile.Extension -eq '.toml') {
      $destination = Join-Path $targetRoot $sourceFile.Name
      if ($existingStems.ContainsKey($stem)) {
        Add-Stat 'agentSame'
        continue
      }
      if (Test-SafeFile $sourceFile) {
        Copy-Item -LiteralPath $sourceFile.FullName -Destination $destination -Force
        $existingStems[$stem] = $true
        Add-Stat 'agentAdded'
      } else {
        Add-Stat 'sensitiveFilesSkipped'
      }
      continue
    }

    if ($sourceFile.Extension -eq '.md') {
      if ($existingStems.ContainsKey($stem)) {
        Add-Stat 'agentConflict'
        continue
      }
      $destination = Join-Path $targetRoot ($sourceFile.BaseName + '.toml')
      if (Convert-ClaudeAgent $sourceFile $destination) {
        $existingStems[$stem] = $true
        Add-Stat 'agentAdded'
      }
    }
  }
}

function Get-TomlBlocks([string]$path) {
  $blocks = @()
  if (-not (Test-Path -LiteralPath $path)) {
    return $blocks
  }
  $currentName = $null
  $currentLines = New-Object System.Collections.Generic.List[string]
  foreach ($line in Get-Content -LiteralPath $path) {
    if ($line -match '^\s*\[([^\]]+)\]\s*$') {
      if ($null -ne $currentName) {
        $blocks += [pscustomobject]@{ Name = $currentName; Lines = @($currentLines) }
      }
      $currentName = $Matches[1]
      $currentLines = New-Object System.Collections.Generic.List[string]
      $currentLines.Add($line)
      continue
    }
    if ($null -ne $currentName) {
      $currentLines.Add($line)
    }
  }
  if ($null -ne $currentName) {
    $blocks += [pscustomobject]@{ Name = $currentName; Lines = @($currentLines) }
  }
  return $blocks
}

function Test-SafeConnectorBlock([object]$block) {
  if ($block.Name -match '^mcp_servers\..+\.(headers|env)$') {
    return $false
  }
  $text = $block.Lines -join [Environment]::NewLine
  if ($block.Name -match '^marketplaces\.' -and $text -match '(?im)^\s*source_type\s*=\s*["'']local["'']') {
    return $false
  }
  return Test-SafeText $text
}

function Import-ConnectorBlocks([string]$sourceConfig, [string]$targetConfig) {
  if (-not (Test-Path -LiteralPath $sourceConfig) -or -not (Test-Path -LiteralPath $targetConfig)) {
    return
  }
  $sourceBlocks = @(Get-TomlBlocks $sourceConfig)
  $targetNames = @{}
  $targetPluginIds = @{}
  foreach ($block in Get-TomlBlocks $targetConfig) {
    $targetNames[$block.Name] = $true
    if ($block.Name -match '^plugins\."?([^@"\.]+)@') {
      $targetPluginIds[$Matches[1].ToLowerInvariant()] = $true
    }
  }
  $append = New-Object System.Collections.Generic.List[string]
  foreach ($block in $sourceBlocks) {
    $isConnector = $block.Name -match '^mcp_servers\.[A-Za-z0-9_-]+$'
    $isMarketplace = $block.Name -match '^marketplaces\.[^\.]+$'
    $isPlugin = $block.Name -match '^plugins\.("[^"]+"|[^\.]+)$'
    if (-not ($isConnector -or $isMarketplace -or $isPlugin)) {
      continue
    }
    if ($targetNames.ContainsKey($block.Name)) {
      Add-Stat 'connectorSkipped'
      continue
    }
    if ($isPlugin -and $block.Name -match '^plugins\."?([^@"\.]+)@') {
      $pluginId = $Matches[1].ToLowerInvariant()
      if ($targetPluginIds.ContainsKey($pluginId)) {
        Add-Stat 'connectorSkipped'
        continue
      }
    }
    if ($isMarketplace -and $block.Name -match '^marketplaces\.(.+)$') {
      $marketplaceId = $Matches[1].ToLowerInvariant()
      $linkedPluginIds = @(
        $sourceBlocks |
          Where-Object { $_.Name -match ('^plugins\."?([^@"\.]+)@' + [regex]::Escape($marketplaceId) + '"?$') } |
          ForEach-Object { if ($_.Name -match '^plugins\."?([^@"\.]+)@') { $Matches[1].ToLowerInvariant() } }
      )
      if ($linkedPluginIds.Count -gt 0 -and (@($linkedPluginIds | Where-Object { -not $targetPluginIds.ContainsKey($_) }).Count -eq 0)) {
        Add-Stat 'connectorSkipped'
        continue
      }
    }
    if (-not (Test-SafeConnectorBlock $block)) {
      Add-Stat 'connectorSkipped'
      continue
    }

    $append.Add(('# Imported without authentication material: [' + $block.Name + ']'))
    foreach ($line in $block.Lines) {
      if ($block.Name -match '^mcp_servers\.' -and $line -match '^\s*(headers|env)\s*=') {
        continue
      }
      $append.Add($line)
    }
    $append.Add('')
    $targetNames[$block.Name] = $true
    if ($isPlugin -and $block.Name -match '^plugins\."?([^@"\.]+)@') {
      $targetPluginIds[$Matches[1].ToLowerInvariant()] = $true
    }
    Add-Stat 'connectorAdded'
  }
  if ($append.Count -gt 0) {
    Add-Content -LiteralPath $targetConfig -Value ([Environment]::NewLine + ($append -join [Environment]::NewLine)) -Encoding utf8
  }
}

function Import-CxPrompts([string[]]$sourceRoots, [string]$targetRoot) {
  Ensure-Directory $targetRoot
  foreach ($sourceRoot in $sourceRoots) {
    if (-not (Test-Path -LiteralPath $sourceRoot)) {
      continue
    }
    foreach ($sourceFile in Get-ChildItem -LiteralPath $sourceRoot -File -Filter 'cx-*.md' -Force -ErrorAction SilentlyContinue) {
      $destination = Join-Path $targetRoot $sourceFile.Name
      if (Test-Path -LiteralPath $destination) {
        if ((Get-Hash $sourceFile.FullName) -eq (Get-Hash $destination)) {
          Add-Stat 'promptSame'
        } else {
          Add-Stat 'promptConflict'
        }
        continue
      }
      Copy-Item -LiteralPath $sourceFile.FullName -Destination $destination -Force
      Add-Stat 'promptAdded'
    }
  }
}

if (-not (Test-Path -LiteralPath $TargetCodexHome)) {
  Ensure-Directory $TargetCodexHome
}
Ensure-Directory $PersonalCodexHome

if (-not $SkipPlugins) {
  Import-PluginCache (Join-Path $SourceCodexHome 'plugins\cache') (Join-Path $TargetCodexHome 'plugins\cache')
  Import-PluginCache (Join-Path $SourceClaudeHome 'plugins\cache') (Join-Path $TargetCodexHome 'plugins\cache')
}

Import-SkillDirectories (Join-Path $SourceCodexHome 'skills') (Join-Path $TargetCodexHome 'skills')
Import-SkillDirectories (Join-Path $SourceClaudeHome 'skills') (Join-Path $TargetCodexHome 'skills')
Import-Agents (Join-Path $SourceCodexHome 'agents') (Join-Path $TargetCodexHome 'agents')
Import-Agents (Join-Path $SourceClaudeHome 'agents') (Join-Path $TargetCodexHome 'agents')

if (-not $SkipConnectors) {
  Import-ConnectorBlocks (Join-Path $SourceCodexHome 'config.toml') (Join-Path $TargetCodexHome 'config.toml')
}

if (-not $SkipCxPrompts) {
  $repoCommands = Join-Path $PSScriptRoot '..\Claude_Commandes\commands'
  Import-CxPrompts @($repoCommands, (Join-Path $SourceClaudeHome 'commands')) (Join-Path $PersonalCodexHome 'prompts')
}

[pscustomobject]$stats | ConvertTo-Json -Compress
