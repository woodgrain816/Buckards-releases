# Installs Buckards for this Windows user: %LOCALAPPDATA%\Buckards (launcher,
# game page, icon) plus Desktop and Start-menu shortcuts. Run it again any time;
# it never downgrades the game page the launcher has already updated.
$ErrorActionPreference = 'Stop'
$src  = Split-Path -Parent $MyInvocation.MyCommand.Path
$dest = Join-Path $env:LOCALAPPDATA 'Buckards'
New-Item -ItemType Directory -Force $dest | Out-Null

Copy-Item (Join-Path $src 'Buckards.ps1') $dest -Force
Copy-Item (Join-Path $src 'buckards.ico') $dest -Force

function PageVersion($file) {
  if (-not (Test-Path $file)) { return [version]'0.0.0' }
  $m = Select-String -Path $file -Pattern 'const GR_VERSION = "([^"]+)"' -List
  if ($m) { try { return [version]$m.Matches[0].Groups[1].Value } catch {} }
  return [version]'0.0.0'
}
$page = Join-Path $src '..\index.html'
if (-not (Test-Path $page)) { $page = Join-Path $src 'game.html' }
if ((Test-Path $page) -and ((PageVersion $page) -ge (PageVersion (Join-Path $dest 'game.html')))) {
  Copy-Item $page (Join-Path $dest 'game.html') -Force
}

$ws = New-Object -ComObject WScript.Shell
foreach ($folder in @([Environment]::GetFolderPath('Desktop'), (Join-Path ([Environment]::GetFolderPath('Programs')) ''))) {
  $lnk = $ws.CreateShortcut((Join-Path $folder 'Buckards.lnk'))
  $lnk.TargetPath = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
  $lnk.Arguments = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$dest\Buckards.ps1`""
  $lnk.WorkingDirectory = $dest
  $lnk.IconLocation = "$dest\buckards.ico"
  $lnk.Description = 'Buckards - get the Buckos out. Auto-updates every launch.'
  $lnk.WindowStyle = 7
  $lnk.Save()
}
"Installed to $dest (Desktop + Start menu shortcuts)."
