# Diagnóstico inicial (solo lectura): recoge en un paso lo necesario para empezar.
#  - Windows (versión y compilación)
#  - Tarjeta de sonido Xonar / C-Media: driver, versión, fecha, firmado o no
#  - Secure Boot y modo de prueba (testsigning)
#  - Integridad de memoria (HVCI)
#  - Equalizer APO, Peace y Python instalados
#  - Salidas de audio activas
#
# Uso: powershell -ExecutionPolicy Bypass -File Diagnostico-Inicial.ps1
# Mejor como administrador (si no, Secure Boot y testsigning salen como "desconocido").

$esAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
function T($t) { Write-Host ""; Write-Host "== $t" -ForegroundColor Cyan }

T "Windows"
$os = Get-CimInstance Win32_OperatingSystem
$cv = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
$nombreOs = if ([int]$cv.CurrentBuild -ge 22000) { 'Windows 11' } else { 'Windows 10' }
Write-Host ("{0} {1} (compilación {2}.{3}), {4}" -f $nombreOs, $cv.DisplayVersion, $cv.CurrentBuild, $cv.UBR, $os.OSArchitecture)
Write-Host ("Consola como administrador: {0}" -f $(if ($esAdmin) { 'sí' } else { 'no' }))

T "Tarjetas de sonido y drivers"
$drivers = Get-CimInstance Win32_PnPSignedDriver | Where-Object { $_.DeviceClass -eq 'MEDIA' -and $_.DeviceName }
foreach ($d in $drivers) {
    $fecha = if ($d.DriverDate) { ([datetime]$d.DriverDate).ToString('yyyy-MM-dd') } else { '?' }
    $firma = if ($d.IsSigned) { "firmado por $($d.Signer)" } else { 'SIN FIRMAR' }
    Write-Host ("{0} | driver {1} ({2}) | {3} | fabricante: {4}" -f $d.DeviceName, $d.DriverVersion, $fecha, $firma, $d.Manufacturer)
}
$xonar = $drivers | Where-Object { $_.DeviceName -match 'Xonar|Essence|STX|C-Media|CMI87' }
if ($xonar) {
    foreach ($x in $xonar) {
        if (-not $x.IsSigned) { Write-Host "  -> Driver de la Xonar SIN FIRMAR: casi seguro UNi Xonar (MaxedTech)." -ForegroundColor Yellow }
        elseif ($x.Manufacturer -match 'ASUS' -and $x.DriverVersion -like '8.1.*') { Write-Host "  -> Parece el driver oficial de ASUS." -ForegroundColor Green }
        else { Write-Host "  -> Driver firmado; comprobar si es el oficial de ASUS o el UNi Xonar (ver 'Programas instalados' abajo)." }
    }
} else {
    Write-Host "  -> No veo ninguna Xonar / C-Media. ¿Está la tarjeta instalada y con driver?" -ForegroundColor Yellow
}

T "Seguridad de arranque"
if ($esAdmin) {
    try { $sb = Confirm-SecureBootUEFI -ErrorAction Stop; Write-Host ("Secure Boot: {0}" -f $(if ($sb) { 'ACTIVADO' } else { 'desactivado' })) }
    catch { Write-Host "Secure Boot: no disponible (BIOS heredada o sin UEFI)" }
    $bcd = (bcdedit /enum '{current}') -join "`n"
    $ts = if ($bcd -match '(?im)^testsigning\s+(Yes|Sí|Si)') { 'ACTIVADO (Windows en modo de prueba)' } else { 'desactivado' }
    Write-Host "Modo de prueba (testsigning): $ts"
} else {
    Write-Host "Secure Boot y modo de prueba: desconocido (ejecuta como administrador)"
}
$hvci = Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity' -ErrorAction SilentlyContinue
Write-Host ("Integridad de memoria (HVCI): {0}" -f $(if ($hvci.Enabled -eq 1) { 'activada' } else { 'desactivada o no configurada' }))

T "Programas instalados relevantes"
$apps = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*' -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName -match 'Xonar|C-Media|Equalizer APO|^Peace\b|Spotify|AIMP|foobar|Kodi|^Python [\d.]+ \(' } |
    Sort-Object DisplayName -Unique
foreach ($a in $apps) { Write-Host ("{0} {1}" -f $a.DisplayName, $a.DisplayVersion) }
Write-Host ("Equalizer APO: {0}" -f $(if (Test-Path 'C:\Program Files\EqualizerAPO\EqualizerAPO.dll') { 'instalado' } else { 'no instalado' }))
Write-Host ("Peace:         {0}" -f $(if (Test-Path 'C:\Program Files\EqualizerAPO\config\Peace.exe') { 'instalado' } else { 'no instalado' }))
$py = Get-Command python, py -ErrorAction SilentlyContinue | Where-Object { $_.Source -notmatch 'WindowsApps' } | Select-Object -First 1
Write-Host ("Python:        {0}" -f $(if ($py) { $py.Source } else { 'no encontrado (solo hace falta para las herramientas opcionales)' }))

T "Salidas de audio activas"
$render = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Render'
foreach ($ep in Get-ChildItem $render) {
    if ((Get-ItemProperty $ep.PSPath).DeviceState -ne 1) { continue }
    $p = Get-ItemProperty "$($ep.PSPath)\Properties" -ErrorAction SilentlyContinue
    Write-Host ("{0} ({1})" -f $p.'{a45c254e-df1c-4efd-8020-67d146a850e0},2', $p.'{b3f8fa53-0004-438e-9003-51a46e139bfc},6')
}
Write-Host "La predeterminada se ve en mmsys.cpl (marca verde)."

Write-Host ""
Write-Host "Siguiente paso: Comprobar-Audio.ps1 para el estado de Equalizer APO y las mejoras."