<#
  GxObjGen - instalador para BETA TESTERS (nao compila; so instala a DLL ja empacotada).

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

# caminho do PROPRIO script (robusto p/ varios modos de invocacao: -File, .\, ISE, etc.)
$self = $PSCommandPath
if ([string]::IsNullOrEmpty($self)) { $self = $MyInvocation.MyCommand.Path }
if ([string]::IsNullOrEmpty($self)) { $self = $MyInvocation.MyCommand.Definition }

# 0) elevacao - a instalacao escreve em Program Files + roda /install (exige admin).
#    Se rodar sem admin, o script se RE-LANCA elevado via UAC (basta confirmar o prompt).
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
if ($isAdmin) {
  Write-Host "Rodando como ADMINISTRADOR." -ForegroundColor Green
} else {
  Write-Host "Sem privilegios de admin - solicitando elevacao (confirme o prompt do UAC)..." -ForegroundColor Yellow
  if ([string]::IsNullOrEmpty($self) -or -not (Test-Path $self)) {
    Write-Host "Nao consegui localizar o caminho do script para auto-elevar." -ForegroundColor Red
    Write-Host "Abra o PowerShell COMO ADMINISTRADOR (menu Iniciar > digite 'PowerShell' > botao direito > Executar como administrador) e rode:" -ForegroundColor Cyan
    Write-Host "  powershell -ExecutionPolicy Bypass -File `"<caminho>\install.ps1`"" -ForegroundColor Cyan
    exit 1
  }
  # ArgumentList como ARRAY (robusto p/ caminhos com espaco no Windows PowerShell 5.1)
  $argList = @('-NoExit','-NoProfile','-ExecutionPolicy','Bypass','-File', $self)
  if ($GxDir) { $argList += @('-GxDir', $GxDir) }
  try {
    Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList $argList | Out-Null
    Write-Host "Uma nova janela (Administrador) foi aberta para concluir a instalacao." -ForegroundColor Green
  } catch {
    Write-Host "Elevacao cancelada/negada. Abra o PowerShell COMO ADMINISTRADOR e rode install.ps1 de novo." -ForegroundColor Red
    exit 1
  }
  exit 0   # o trabalho continua na janela elevada (-NoExit a mantem aberta)
}

# 1) DLLs empacotadas (ao lado deste script). Ha DOIS variantes com a MESMA
#    versao/funcionalidade, diferindo so no PackageCompatibility exigido pelo host:
#      - Packages\GxObjGen.dll        -> GeneXus 17 e 18 (compat 143920)
#      - Packages\gx15\GxObjGen.dll   -> GeneXus 15      (compat 123130; 5 tools de
#                                        objetos inexistentes no GX15 ficam ocultas)
#    A escolha por instalacao e feita pela versao MAJOR do genexus.exe.
$dllDefault = Join-Path $PSScriptRoot "Packages\GxObjGen.dll"
$dll15      = Join-Path $PSScriptRoot "Packages\gx15\GxObjGen.dll"
if (-not (Test-Path $dllDefault)) { throw "GxObjGen.dll (17/18) nao encontrada em $((Split-Path $dllDefault)). Extraia o ZIP inteiro antes de rodar." }
$ver = ([System.Diagnostics.FileVersionInfo]::GetVersionInfo($dllDefault)).ProductVersion
Write-Host "GxObjGen v$ver" -ForegroundColor Cyan
if (-not (Test-Path $dll15)) { Write-Host "AVISO: variante GX15 (Packages\gx15\GxObjGen.dll) ausente — GeneXus 15 sera pulado." -ForegroundColor Yellow }

# [issue #21] O PackageCompatibility e POR BUILD do GeneXus; o DLL vem carimbado com o do build de
# referencia. Se o host exigir outro numero (ex.: GX15 U8=96640 vs U12=123130), o IDE LISTA a
# extensao mas a DESABILITA em silencio. Abaixo lemos o numero que o host exige (de um assembly
# nativo) e, se diferir do declarado no DLL, patchamos os 4 bytes do valor no DLL de destino — assim
# UM DLL serve qualquer upgrade. Ler o atributo exige reflexao em processo 32-bit (assemblies x86).
$CompatReader = Join-Path $env:TEMP 'gxobjgen-compat-reader.ps1'
@'
param([string]$Dll,[string]$Gx)
$ErrorActionPreference="SilentlyContinue"
$onload={param($s,$e)$n=($e.Name -split ",")[0];foreach($d in @("$Gx\$n.dll","$Gx\Packages\$n.dll")){if(Test-Path $d){try{return [Reflection.Assembly]::ReflectionOnlyLoadFrom($d)}catch{}}};return $null}
[AppDomain]::CurrentDomain.add_ReflectionOnlyAssemblyResolve($onload)
try{$a=[Reflection.Assembly]::ReflectionOnlyLoadFrom($Dll)}catch{return}
foreach($c in $a.GetCustomAttributesData()){if($c.AttributeType.Name -eq "PackageCompatibilityAttribute"){($c.NamedArguments|Where-Object{$_.MemberName -eq "Version"}).TypedValue.Value}}
'@ | Set-Content -Path $CompatReader -Encoding ASCII

function Read-Compat([string]$Dll, [string]$Gx) {
  if (-not (Test-Path $Dll)) { return $null }
  $ps32 = Join-Path $env:WINDIR 'SysWOW64\WindowsPowerShell\v1.0\powershell.exe'
  $psExe = if (Test-Path $ps32) { $ps32 } else { 'powershell.exe' }
  try {
    $o = & $psExe -NoProfile -ExecutionPolicy Bypass -File $CompatReader -Dll $Dll -Gx $Gx 2>$null | Select-Object -First 1
    $n = 0
    if ([int]::TryParse(("$o").Trim(), [ref]$n)) { return $n }
  } catch {}
  return $null
}

function Set-CompatToHost([string]$DestDll, [string]$Gx) {
  $hostCompat = Read-Compat (Join-Path $Gx 'Artech.Architecture.Common.dll') $Gx
  $dllCompat  = Read-Compat $DestDll $Gx
  if (-not $hostCompat -or -not $dllCompat) {
    Write-Host "      (nao consegui ler o compat do host/DLL; seguindo com o valor de fabrica)" -ForegroundColor Yellow
    return
  }
  if ($hostCompat -eq $dllCompat) { Write-Host "      compat OK ($dllCompat) — ja bate com o build do host."; return }
  $bytes = [System.IO.File]::ReadAllBytes($DestDll)
  $old = [BitConverter]::GetBytes([int]$dllCompat)
  $new = [BitConverter]::GetBytes([int]$hostCompat)
  $hits = @()
  for ($i = 0; $i -le $bytes.Length - 4; $i++) {
    if ($bytes[$i] -eq $old[0] -and $bytes[$i+1] -eq $old[1] -and $bytes[$i+2] -eq $old[2] -and $bytes[$i+3] -eq $old[3]) { $hits += $i }
  }
  if ($hits.Count -eq 1) {
    $bytes[$hits[0]] = $new[0]; $bytes[$hits[0]+1] = $new[1]; $bytes[$hits[0]+2] = $new[2]; $bytes[$hits[0]+3] = $new[3]
    [System.IO.File]::WriteAllBytes($DestDll, $bytes)
    Write-Host "      compat ajustado ao host: $dllCompat -> $hostCompat." -ForegroundColor Green
  } else {
    Write-Host "      AVISO: compat nao ajustado (valor $dllCompat aparece $($hits.Count)x no DLL). A extensao pode ficar DESABILITADA no IDE — reporte na issue #21." -ForegroundColor Yellow
  }
}

# 2) alvos: -GxDir explicito, ou auto-detecta 17/18 nos caminhos padrao
if ($GxDir) { $targets = @($GxDir) }
else {
  $targets = @(
    "C:\Program Files (x86)\GeneXus\GeneXus15",
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

  # Escolhe o DLL base pela versao MAJOR do host (o compat exato e ajustado depois da copia).
  $major = (Get-Item $exe).VersionInfo.ProductMajorPart
  if ($major -eq 15) {
    if (-not (Test-Path $dll15)) { Write-Host "PULANDO: GeneXus 15 detectado mas Packages\gx15\GxObjGen.dll ausente." -ForegroundColor Yellow; continue }
    $dll = $dll15
    Write-Host "Versao detectada: GeneXus 15 -> variante GX15 (compat base 123130; ajusta ao build)." -ForegroundColor Cyan
  } else {
    $dll = $dllDefault
    Write-Host "Versao detectada: GeneXus $major -> DLL padrao (compat base 143920; ajusta ao build)." -ForegroundColor Cyan
  }

  Copy-Item $dll -Destination $dest -Force
  $pdb = [System.IO.Path]::ChangeExtension($dll, ".pdb")
  if (Test-Path $pdb) { Copy-Item $pdb -Destination $dest -Force }
  Write-Host "[1/2] Copiado GxObjGen.dll -> $dest"

  # [issue #21] ajusta o PackageCompatibility ao build EXATO do host (patcha o DLL de destino)
  Set-CompatToHost (Join-Path $dest "GxObjGen.dll") $t

  Write-Host "[2/2] Registrando: genexus.exe /install ..."
  $p = Start-Process -FilePath $exe -ArgumentList "/install" -Wait -PassThru -WindowStyle Hidden
  Write-Host "      /install ExitCode=$($p.ExitCode)"
  Write-Host "OK." -ForegroundColor Green
  $ok++
}

if ($ok -eq 0) { throw "Nada instalado (veja os avisos acima)." }
Write-Host "`nConcluido em $ok instalacao(oes). Abra o GeneXus e sua KB; a extensao sobe o servidor MCP automaticamente." -ForegroundColor Green

# [issue #15] O gateway multi-KB (porta 8780) REQUER Python no PATH. Sem Python ele nao sobe
# (silenciosamente ate a v1.11.4) e a conexao certa e a porta POR-KB mostrada no Output do IDE.
$py = $null
foreach ($exe in @('pythonw.exe','python.exe','py.exe')) {
  $cmd = Get-Command $exe -ErrorAction SilentlyContinue
  if ($cmd) { $py = $cmd.Source; break }
}
if ($py) {
  Write-Host "`nPython encontrado ($py) - o gateway multi-KB sobe na porta 8780." -ForegroundColor Green
  Write-Host "Registre no Claude Code (uma vez):  claude mcp add --transport http genexus http://127.0.0.1:8780/mcp" -ForegroundColor Green
} else {
  Write-Host "`nAVISO: Python NAO encontrado no PATH - o gateway multi-KB (porta 8780) NAO vai subir." -ForegroundColor Yellow
  Write-Host "A extensao funciona normalmente pela porta POR-KB: abra a KB e use a URL mostrada no" -ForegroundColor Yellow
  Write-Host "Output do IDE (secao 'GxObjGen MCP'), ex.:  claude mcp add --transport http genexus-<kb> http://127.0.0.1:<porta>/mcp" -ForegroundColor Yellow
  Write-Host "Para habilitar o gateway 8780: instale Python (winget install Python.Python.3.12) e reabra o GeneXus." -ForegroundColor Yellow
}
