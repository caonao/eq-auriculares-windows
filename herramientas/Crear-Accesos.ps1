# Copia Cambiar-EQ.ps1 a config\perfiles\ y crea en el menú Inicio un acceso directo
# por cada perfil (config\perfiles\*.txt) más "EQ desactivado".
# Cada acceso directo pide permiso de administrador (UAC) al pulsarlo, porque la
# configuración de Equalizer APO está en Archivos de programa.
#
# Ejecutar como administrador, después de exportar los perfiles con autoeq_peace.py.
# Volver a ejecutarlo si se añaden perfiles nuevos.

param([string]$Config = 'C:\Program Files\EqualizerAPO\config', [string]$Menu = (Join-Path ([Environment]::GetFolderPath('Programs')) 'Equalizer APO - Auriculares'))
$config = $Config
$perfiles = Join-Path $config 'perfiles'
if (-not (Test-Path $perfiles)) { throw "No existe $perfiles. Exporta antes algún perfil con autoeq_peace.py." }

# El script que se ejecuta elevado vive en Program Files (solo escribible por
# administradores): un script elevado no debe estar en una carpeta del usuario.
$script = Join-Path $perfiles 'Cambiar-EQ.ps1'
Copy-Item (Join-Path $PSScriptRoot 'Cambiar-EQ.ps1') $script -Force

$menu = $Menu
New-Item -ItemType Directory -Force $menu | Out-Null
Get-ChildItem $menu -Filter '*.lnk' | Remove-Item

$ws = New-Object -ComObject WScript.Shell
$ps = "$env:WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe"
$nombres = @(Get-ChildItem $perfiles -Filter '*.txt' | ForEach-Object { $_.BaseName }) + 'SinEQ'
foreach ($n in $nombres) {
    $titulo = if ($n -eq 'SinEQ') { 'EQ desactivado' } else { "EQ $n" }
    $l = $ws.CreateShortcut((Join-Path $menu "$titulo.lnk"))
    $l.TargetPath = $ps
    $l.Arguments = "-NoProfile -WindowStyle Hidden -Command `"Start-Process powershell -Verb RunAs -WindowStyle Hidden -ArgumentList '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File \`"$script\`" -Perfil $n'`""
    $icono = Join-Path $config 'icon.ico'
    if (Test-Path $icono) { $l.IconLocation = $icono }
    $l.WindowStyle = 7
    $l.Save()
    Write-Host "Acceso directo: $titulo"
}
Write-Host "`nListo. Están en el menú Inicio, carpeta 'Equalizer APO - Auriculares'."
