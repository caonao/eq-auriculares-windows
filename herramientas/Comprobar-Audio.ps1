# Comprueba (solo lectura) que la cadena de corrección de auriculares está bien:
#  - en qué salidas de Windows está instalado Equalizer APO
#  - si lleva encadenado el procesador de "mejoras" de Microsoft (no debería)
#  - mejoras de Windows y sonido espacial en las demás salidas de la misma tarjeta
#  - formato (frecuencia / bits) de cada salida
#  - qué perfil está aplicando ahora Equalizer APO
# Las salidas de otras tarjetas (monitores HDMI, dispositivos virtuales...) solo se
# listan como información.
#
# Uso: powershell -ExecutionPolicy Bypass -File Comprobar-Audio.ps1

$render = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Render'
$config = 'C:\Program Files\EqualizerAPO\config'
$avisos = 0
function OK($t) { Write-Host "OK     $t" }
function AV($t) { Write-Host "AVISO  $t" -ForegroundColor Yellow; $script:avisos++ }
function INFO($t) { Write-Host "info   $t" -ForegroundColor DarkGray }

$nombresApo = @{}
Get-ChildItem 'Registry::HKEY_CLASSES_ROOT\AudioEngine\AudioProcessingObjects' -ErrorAction SilentlyContinue | ForEach-Object {
    $nombresApo[$_.PSChildName.ToUpper()] = (Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue).FriendlyName
}

# 1) Recoger datos de todas las salidas activas
$salidas = foreach ($ep in Get-ChildItem $render) {
    if ((Get-ItemProperty $ep.PSPath).DeviceState -ne 1) { continue }
    $p = Get-ItemProperty "$($ep.PSPath)\Properties" -ErrorAction SilentlyContinue
    $fx = Get-ItemProperty "$($ep.PSPath)\FxProperties" -ErrorAction SilentlyContinue
    $apos = @()
    if ($fx) {
        foreach ($prop in $fx.PSObject.Properties) {
            foreach ($v in @($prop.Value)) {
                if ("$v" -match '^\{[0-9A-Fa-f-]{36}\}$' -and $v -ne '{00000000-0000-0000-0000-000000000000}') {
                    $apos += $nombresApo["$v".ToUpper()]
                }
            }
        }
    }
    $fmt = ''
    $b = $p.'{f19f064d-082c-4e27-bc73-6882a1bb8e4c},0'
    if ($b -and $b.Length -ge 24) {
        $bits = [BitConverter]::ToUInt16($b, 22)
        if ($b.Length -ge 28 -and [BitConverter]::ToUInt16($b, 24) -ge 22) { $bits = [BitConverter]::ToUInt16($b, 26) }
        $fmt = "{0} Hz / {1} bit" -f [BitConverter]::ToUInt32($b, 12), $bits
    }
    $hijo = Get-Item "HKLM:\SOFTWARE\EqualizerAPO\Child APOs\$($ep.PSChildName)" -ErrorAction SilentlyContinue
    [pscustomobject]@{
        Salida     = $p.'{a45c254e-df1c-4efd-8020-67d146a850e0},2'
        Tarjeta    = $p.'{b3f8fa53-0004-438e-9003-51a46e139bfc},6'
        Formato    = $fmt
        Eapo       = $apos -contains 'EqualizerAPO'
        Encadenado = [bool]($hijo -and ($hijo.GetValue('PreMixChild') -or $hijo.GetValue('PostMixChild')))
        MejorasOff = [bool]($fx -and $fx.'{1da5d803-d492-4edd-8c23-e0c0ffee7f0e},5' -eq 1)
        Espacial   = ($p.'{1da5d803-d492-4edd-8c23-e0c0ffee7f0e},2' -and $p.'{1da5d803-d492-4edd-8c23-e0c0ffee7f0e},2' -ne '{00000000-0000-0000-0000-000000000000}')
    }
}

$conEapo = @($salidas | Where-Object Eapo)
$tarjetas = @($conEapo | ForEach-Object Tarjeta | Sort-Object -Unique)

# 2) Informe
foreach ($s in $salidas | Sort-Object { -not $_.Eapo }, { $tarjetas -notcontains $_.Tarjeta }) {
    $relevante = $s.Eapo -or ($tarjetas -contains $s.Tarjeta) -or $tarjetas.Count -eq 0
    Write-Host ""
    Write-Host ("== {0} ({1})  {2}" -f $s.Salida, $s.Tarjeta, $s.Formato)
    if ($s.Eapo) {
        OK "Equalizer APO instalado en esta salida"
        if ($s.Encadenado) {
            AV "Lleva encadenado el procesador original (mejoras de Microsoft u OEM). Quítalo: DeviceSelector -> Troubleshooting options -> desmarcar 'Use original APO'"
        } else {
            OK "Sin procesador original encadenado (solo tu corrección)"
        }
        Write-Host "       (aquí las mejoras de Windows deben estar activas: Equalizer APO las necesita)"
    } elseif ($s.MejorasOff) {
        if ($relevante) { OK "Mejoras de Windows desactivadas" } else { INFO "otra tarjeta; mejoras desactivadas" }
    } else {
        if ($relevante) { AV "Mejoras de Windows activas (mmsys.cpl -> Propiedades -> Mejoras -> Deshabilitar todas las mejoras)" }
        else { INFO "otra tarjeta; mejoras activas (no afecta a los auriculares)" }
    }
    if ($s.Espacial) {
        if ($relevante) { AV "Sonido espacial activado (Propiedades -> Sonido espacial -> Desactivado)" } else { INFO "otra tarjeta; sonido espacial activado" }
    }
}

Write-Host ""
Write-Host "== Equalizer APO"
if ($conEapo.Count -eq 0) { AV "Equalizer APO no está instalado en ninguna salida activa (ejecuta DeviceSelector)" }
elseif ($conEapo.Count -gt 1) { AV "Equalizer APO está en $($conEapo.Count) salidas; lo normal es solo en la de los auriculares" }

$cfg = Join-Path $config 'config.txt'
if (Test-Path $cfg) {
    $activo = Get-Content $cfg
    $peaceTxt = Join-Path $config 'peace.txt'
    if (($activo -match '^Include:\s*peace\.txt') -and (Test-Path $peaceTxt)) { $activo = Get-Content $peaceTxt }
    $inc = $activo | Select-String '^Include:\s*perfiles\\(.+)\.txt' | Select-Object -First 1
    $filtros = @($activo | Where-Object { $_ -match '^Filter' }).Count
    if ($inc) {
        OK "Perfil activo: $($inc.Matches[0].Groups[1].Value)"
    } elseif ($filtros -gt 0) {
        $pre = ($activo | Where-Object { $_ -match '^Preamp' }) -join ''
        $igual = Get-ChildItem (Join-Path $config 'perfiles') -Filter '*.txt' -ErrorAction SilentlyContinue | Where-Object {
            ((Get-Content $_.FullName | Where-Object { $_ -match '^Preamp' }) -join '') -eq $pre
        } | Select-Object -First 1
        $extra = if ($igual) { " (mismo preamp que el perfil $($igual.BaseName))" } else { '' }
        OK "Corrección activa con $filtros filtros, cargada desde Peace$extra"
    } else {
        AV "No hay ninguna corrección activa (EQ desactivado o preset plano)"
    }
} else {
    AV "No encuentro $cfg (¿está instalado Equalizer APO?)"
}

Write-Host ""
if ($avisos -eq 0) { Write-Host "Resultado: todo OK" -ForegroundColor Green } else { Write-Host "Resultado: $avisos aviso(s)" -ForegroundColor Yellow }
