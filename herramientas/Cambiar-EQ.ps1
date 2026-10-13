# Cambia el perfil de auriculares activo en Equalizer APO.
# Convive con Peace: deja config.txt en "Include: peace.txt" (como lo deja Peace)
# y escribe en peace.txt el Include del perfil elegido.
#
# Uso (como administrador):
#   Cambiar-EQ.ps1 -Perfil HD660S2     -> usa config\perfiles\HD660S2.txt
#   Cambiar-EQ.ps1 -Perfil SinEQ       -> quita la corrección
#
# Lo normal es instalarlo en config\perfiles\ (lo hace Crear-Accesos.ps1) y usar
# los accesos directos del menú Inicio.
param([Parameter(Mandatory)][string]$Perfil, [string]$Config = 'C:\Program Files\EqualizerAPO\config')

$config = $Config
$perfiles = Join-Path $config 'perfiles'
$utf8 = New-Object System.Text.UTF8Encoding $false

if ($Perfil -ne 'SinEQ' -and -not (Test-Path (Join-Path $perfiles "$Perfil.txt"))) {
    (New-Object -ComObject WScript.Shell).Popup("No existe el perfil $Perfil en $perfiles", 5, 'Equalizer APO', 48) | Out-Null
    exit 1
}

[System.IO.File]::WriteAllLines((Join-Path $config 'config.txt'), [string[]]@('Include: peace.txt'), $utf8)
$peace = @('Device: all', 'Channel: all')
if ($Perfil -ne 'SinEQ') { $peace += "Include: perfiles\$Perfil.txt" }
[System.IO.File]::WriteAllLines((Join-Path $config 'peace.txt'), [string[]]$peace, $utf8)

$texto = if ($Perfil -eq 'SinEQ') { 'EQ desactivado' } else { "Perfil activo: $Perfil" }
(New-Object -ComObject WScript.Shell).Popup($texto, 2, 'Equalizer APO', 64) | Out-Null
