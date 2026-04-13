$ErrorActionPreference = "Stop"

$cfgPath = Join-Path $PSScriptRoot "..\config.php"
if (-not (Test-Path $cfgPath)) {
  throw "Missing backend/config.php"
}

# Minimal parser for our config.php (expects simple array with quoted values)
$cfg = Get-Content $cfgPath -Raw
function Get-PhpStringValue([string]$text, [string]$key) {
  $m = [regex]::Match($text, "'$key'\s*=>\s*'([^']*)'")
  if (-not $m.Success) { return $null }
  return $m.Groups[1].Value
}

$host = Get-PhpStringValue $cfg "host"
$port = Get-PhpStringValue $cfg "port"
$db   = Get-PhpStringValue $cfg "database"
$user = Get-PhpStringValue $cfg "username"
$pass = Get-PhpStringValue $cfg "password"

if (-not $host -or -not $db -or -not $user) {
  throw "Can't read DB config from backend/config.php"
}

$schema = Join-Path $PSScriptRoot "schema.sql"
$seed   = Join-Path $PSScriptRoot "seed.sql"

Write-Host "Importing schema..."
& mysql --protocol=tcp -h $host -P 3306 -u $user "-p$pass" $db < $schema

Write-Host "Importing seed..."
& mysql --protocol=tcp -h $host -P 3306 -u $user "-p$pass" $db < $seed

Write-Host "Done."
