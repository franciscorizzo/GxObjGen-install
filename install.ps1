<#
  GxObjGen — instalador para BETA TESTERS (nao compila; so instala a DLL ja empacotada).

  O que faz: copia Packages\GxObjGen.dll (deste pacote) para a subpasta 'Packages' de cada
  instalacao do GeneXus detectada (17 e/ou 18) e roda 'genexus.exe /install' para registrar.

  REQUISITOS:
   - PowerShell como ADMINISTRADOR (escreve em Program Files).
   - O GeneXus da(s) versao(oes) alvo FECHADO.

  Uso:
    # detecta e instala em todas as versoes encontradas (17 e 18):
    powershell -ExecutionPolicy Bypass -File install.ps1
    # uma pasta especifica:
    powershell -ExecutionPolicy Bypass -File install.ps1 -GxDir "C:\Program Files (x86)\GeneXus\GeneXus18"
#>
param(
  [string]$GxDir  # opcional: instalar somente nesta pasta do GeneXus
)
$ErrorActionPreference = 'Stop'

# 0) elevacao — a instalacao escreve em Program Files + roda /install (exige admin).
#    Se rodar sem admin, o script se RE-LANCA elevado via UAC (basta confirmar o prompt).
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
if (-not $isAdmin) {
  Write-Host 'Sem privilegios de admin - reabrindo elevado (confirme o prompt do UAC)...' -ForegroundColor Yellow
  $q = [char]34   # aspas dupla, p/ citar caminhos com espaco sem escape
  $psArgs = "-NoExit -NoProfile -ExecutionPolicy Bypass -File $q$PSCommandPath$q"
  if ($GxDir) { $psArgs += " -GxDir $q$GxDir$q" }
  try { Start-Process powershell -Verb RunAs -ArgumentList $psArgs }
  catch { Write-Host 'Elevacao negada/cancelada. Abra um PowerShell como Administrador e rode o install.ps1 de novo.' -ForegroundColor Red; exit 1 }
  return   # o trabalho continua na janela elevada (que fica aberta, -NoExit)
}

# 1) DLL empacotada (ao lado deste script, em Packages\)
$dll = Join-Path $PSScriptRoot "Packages\GxObjGen.dll"
if (-not (Test-Path $dll)) { throw "GxObjGen.dll nao encontrada em $((Split-Path $dll)). Extraia o ZIP inteiro antes de rodar." }
$ver = ([System.Diagnostics.FileVersionInfo]::GetVersionInfo($dll)).ProductVersion
Write-Host "GxObjGen v$ver" -ForegroundColor Cyan

# 2) alvos: -GxDir explicito, ou auto-detecta 17/18 nos caminhos padrao
if ($GxDir) { $targets = @($GxDir) }
else {
  $targets = @(
    "C:\Program Files (x86)\GeneXus\GeneXus17",
    "C:\Program Files (x86)\GeneXus\GeneXus18"
  ) | Where-Object { Test-Path (Join-Path $_ "genexus.exe") }
}
if (-not $targets -or $targets.Count -eq 0) {
  throw "Nenhuma instalacao do GeneXus encontrada. Informe o caminho com -GxDir `"C:\...\GeneXusNN`"."
}

$ok = 0
foreach ($t in $targets) {
  Write-Host "`n==== $t ====" -ForegroundColor Cyan
  $exe  = Join-Path $t "genexus.exe"
  $dest = Join-Path $t "Packages"
  if (-not (Test-Path $exe))  { Write-Host "PULANDO: genexus.exe ausente." -ForegroundColor Yellow; continue }
  if (-not (Test-Path $dest)) { Write-Host "PULANDO: pasta Packages ausente." -ForegroundColor Yellow; continue }

  $open = Get-Process -Name genexus -ErrorAction SilentlyContinue | Where-Object { $_.Path -and ($_.Path -ieq $exe) }
  if ($open) { Write-Host "PULANDO: este GeneXus esta ABERTO (PID $($open.Id -join ', ')). Feche-o e rode de novo." -ForegroundColor Yellow; continue }

  Copy-Item $dll -Destination $dest -Force
  $pdb = [System.IO.Path]::ChangeExtension($dll, ".pdb")
  if (Test-Path $pdb) { Copy-Item $pdb -Destination $dest -Force }
  Write-Host "[1/2] Copiado GxObjGen.dll -> $dest"

  Write-Host "[2/2] Registrando: genexus.exe /install ..."
  $p = Start-Process -FilePath $exe -ArgumentList "/install" -Wait -PassThru -WindowStyle Hidden
  Write-Host "      /install ExitCode=$($p.ExitCode)"
  Write-Host "OK." -ForegroundColor Green
  $ok++
}

if ($ok -eq 0) { throw "Nada instalado (veja os avisos acima)." }
Write-Host "`nConcluido em $ok instalacao(oes). Abra o GeneXus e sua KB; a extensao sobe o servidor MCP automaticamente." -ForegroundColor Green
Write-Host "Depois registre no Claude Code (uma vez):  claude mcp add --transport http genexus http://127.0.0.1:8780/mcp" -ForegroundColor Green
