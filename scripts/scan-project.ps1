<#
.SYNOPSIS
  Bounded project scan for bootstrapping .agent/PROJECT_MAP.md.
.DESCRIPTION
  Lists source files, pruning dependency, build, and VCS directories before
  descending into them. Output is capped so it stays cheap to read into context.
  Prints manifest hints, not manifest contents.
.EXAMPLE
  pwsh -NoProfile -File scripts/scan-project.ps1 -Root . -MaxFiles 150
#>
[CmdletBinding()]
param(
  [string]$Root = ".",
  [int]$MaxFiles = 200,
  [int]$Depth = 6
)

$ErrorActionPreference = "SilentlyContinue"

try {
  $rootPath = (Resolve-Path -LiteralPath $Root).Path
} catch {
  Write-Output "scan-project: cannot resolve '$Root'"
  exit 1
}

$skipDirs = @(
  'node_modules','.git','.hg','.svn','dist','build','out','.next','.nuxt','.svelte-kit',
  'vendor','.venv','venv','env','__pycache__','.mypy_cache','.pytest_cache','.ruff_cache',
  'target','coverage','.nyc_output','.dart_tool','.pub-cache','Pods','.gradle','obj','bin',
  '.idea','.vscode','.turbo','.cache','.expo','.terraform','DerivedData','.parcel-cache'
)
$skipFileNames = @(
  'package-lock.json','pnpm-lock.yaml','yarn.lock','poetry.lock','Cargo.lock','composer.lock',
  'go.sum','bun.lockb','Pipfile.lock','.DS_Store','Thumbs.db'
)

# Walk manually so pruned directories are never enumerated (fast on big repos).
$found = New-Object System.Collections.Generic.List[string]
$pruned = New-Object System.Collections.Generic.List[object]
$stack = New-Object System.Collections.Generic.Stack[string]
$stack.Push($rootPath)

while ($stack.Count -gt 0) {
  $dir = $stack.Pop()
  foreach ($entry in (Get-ChildItem -LiteralPath $dir -Force -ErrorAction SilentlyContinue)) {
    if ($entry.PSIsContainer) {
      if ($skipDirs -contains $entry.Name) {
        $relPruned = $entry.FullName.Substring($rootPath.Length).TrimStart('\', '/').Replace('\', '/')
        $entryCount = @(Get-ChildItem -LiteralPath $entry.FullName -Force -ErrorAction SilentlyContinue).Count
        $pruned.Add([pscustomobject]@{ Path = $relPruned; Entries = $entryCount })
        continue
      }
      $relDir = $entry.FullName.Substring($rootPath.Length).TrimStart('\', '/')
      if ((($relDir -split '[\\/]').Count) -lt $Depth) { $stack.Push($entry.FullName) }
      continue
    }
    if ($skipFileNames -contains $entry.Name) { continue }
    $found.Add($entry.FullName)
  }
}

$sorted = @($found | Sort-Object)
$shown = @($sorted | Select-Object -First $MaxFiles)

Write-Output "ROOT:  $rootPath"
Write-Output ("FILES: {0} matched, {1} shown (cap {2}, depth {3})" -f $sorted.Count, $shown.Count, $MaxFiles, $Depth)
Write-Output ""

Write-Output "MANIFESTS"
$hints = 0
$pkgPath = Join-Path $rootPath 'package.json'
if (Test-Path -LiteralPath $pkgPath) {
  try {
    $j = Get-Content -LiteralPath $pkgPath -Raw | ConvertFrom-Json
    $scripts = if ($j.scripts) { ($j.scripts.PSObject.Properties.Name -join ', ') } else { 'none' }
    Write-Output ("  package.json   name={0}   scripts=[{1}]" -f $j.name, $scripts)
  } catch {
    Write-Output "  package.json   present (unparsed)"
  }
  $hints++
}
foreach ($f in @('pyproject.toml','requirements.txt','setup.py','Pipfile','poetry.lock')) {
  if (Test-Path -LiteralPath (Join-Path $rootPath $f)) { Write-Output "  $f   present"; $hints++ }
}
foreach ($f in @('pubspec.yaml','go.mod','Cargo.toml','Gemfile','composer.json','Makefile')) {
  if (Test-Path -LiteralPath (Join-Path $rootPath $f)) { Write-Output "  $f   present"; $hints++ }
}
foreach ($f in @('tsconfig.json','vite.config.ts','next.config.js','next.config.mjs','nuxt.config.ts')) {
  if (Test-Path -LiteralPath (Join-Path $rootPath $f)) { Write-Output "  $f   present"; $hints++ }
}
if ($hints -eq 0) { Write-Output "  (none found - the stack may be uninitialized)" }
Write-Output ""

Write-Output "PRUNED (not scanned - dependencies, build output, VCS)"
if ($pruned.Count -eq 0) {
  Write-Output "  (none)"
} else {
  foreach ($p in ($pruned | Sort-Object Path | Select-Object -First 15)) {
    Write-Output ("  {0}/  ({1} items)" -f $p.Path, $p.Entries)
  }
  if ($pruned.Count -gt 15) { Write-Output ("  ... {0} more" -f ($pruned.Count - 15)) }
}
Write-Output ""

Write-Output "FILES"
foreach ($f in $shown) {
  Write-Output ("  " + $f.Substring($rootPath.Length).TrimStart('\', '/').Replace('\', '/'))
}
if ($sorted.Count -gt $shown.Count) {
  Write-Output ("  ... {0} more not shown" -f ($sorted.Count - $shown.Count))
}
Write-Output ""
Write-Output "Next: write .agent/PROJECT_MAP.md from directories and entry points, not from every file."
