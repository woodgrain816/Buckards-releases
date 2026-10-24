# Buckards launcher (PC). Checks the releases repo for a newer game page,
# downloads + verifies it (SHA-256), then opens the game in its own window.
# Offline or GitHub down? It just opens the copy it already has.
# Lives in %LOCALAPPDATA%\Buckards next to game.html (install_pc.ps1 puts it there).
param([switch]$NoLaunch)    # -NoLaunch: update only (for testing)
$ErrorActionPreference = 'Stop'
$dir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$game = Join-Path $dir 'game.html'
$url  = 'https://raw.githubusercontent.com/woodgrain816/Buckards-releases/main/update.json'

function PageVersion($file) {
  if (-not (Test-Path $file)) { return [version]'0.0.0' }
  $m = Select-String -Path $file -Pattern 'const GR_VERSION = "([^"]+)"' -List
  if ($m) { try { return [version]$m.Matches[0].Groups[1].Value } catch {} }
  return [version]'0.0.0'
}

try {
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  $m = Invoke-RestMethod -Uri ($url + '?t=' + [DateTime]::UtcNow.Ticks) -TimeoutSec 6 -Headers @{ 'Cache-Control' = 'no-cache' }
  if ([version]$m.version -gt (PageVersion $game)) {
    $tmp = Join-Path $dir 'game.tmp'
    Invoke-WebRequest -Uri ([Uri]::new([Uri]$url, $m.page)).AbsoluteUri -OutFile $tmp -UseBasicParsing -TimeoutSec 30
    $hash = (Get-FileHash $tmp -Algorithm SHA256).Hash
    if ($hash -ieq $m.sha256) { Move-Item $tmp $game -Force }
    else { Remove-Item $tmp -Force }
  }
} catch { }   # no internet: play what we have

if ($NoLaunch) { "game.html is v$(PageVersion $game)"; return }
$uri = ([Uri]$game).AbsoluteUri
$edge = @("${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe", "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe") | Where-Object { Test-Path $_ } | Select-Object -First 1
if ($edge) { Start-Process $edge -ArgumentList "--app=$uri", '--window-size=1500,900' }
else { Start-Process $game }
