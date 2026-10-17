# Instrucciones para el asistente (Claude) que configura este PC

Estás ayudando a una persona a montar en **su** PC la corrección de auriculares de este repositorio: Equalizer APO + Peace + perfiles AutoEq (preferiblemente medidos por oratory1990), aplicada a todo el sonido de Windows. El autor del repositorio **no va a estar disponible**: trabajas directamente con el usuario de este PC. Todo lo necesario está aquí: la guía para personas es `README.md`, este archivo es tu procedimiento y `herramientas/` tiene los scripts, probados en un PC real con Windows 11.

Equipo previsto: **ASUS Xonar Essence STX II** + auriculares **Sennheiser** (modelo a confirmar). Puede que el usuario tenga los drivers no oficiales **UNi Xonar** (MaxedTech), que no están firmados.

## Cómo trabajar

- Habla en **español claro**, sin jerga; el usuario puede no ser técnico. Explica qué vas a hacer antes de cada paso y qué ha cambiado después.
- **Verifica cada paso** con los scripts antes de darlo por hecho. Nunca digas "listo" sin haberlo comprobado.
- Consola: Windows PowerShell 5.1 (sin `&&`; encadena con `;`). Muchos pasos necesitan **administrador**.
- Descarga solo de estas fuentes oficiales:
  - Equalizer APO: <https://sourceforge.net/projects/equalizerapo/>
  - Peace: <https://sourceforge.net/projects/peace-equalizer-apo-extension/>
  - Driver ASUS STX II: <https://www.asus.com/supportonly/essence%20stx%20ii/helpdesk_download/>

### Pide permiso explícito antes de

- Instalar, desinstalar o cambiar **drivers** (crea antes un punto de restauración).
- Desinstalar programas.
- Cambiar `bcdedit` (modo de prueba). Los cambios en la **BIOS** (Secure Boot) los hace el usuario; tú solo le explicas cómo.
- Editar la configuración de sus aplicaciones (Spotify, Kodi, AIMP...). Haz siempre copia del archivo antes.

### Nunca

- Desactivar Secure Boot, activar el modo de prueba ni desactivar la integridad de memoria **para instalar un driver**. Si el driver lo exige, la solución es el driver oficial firmado.
- Instalar Equalizer APO en todas las salidas: solo en la de los auriculares.
- Publicar ni subir a ningún sitio datos del usuario.

## Procedimiento

### 0. Diagnóstico (antes de tocar nada)

```bash
powershell -ExecutionPolicy Bypass -File herramientas\Diagnostico-Inicial.ps1
powershell -ExecutionPolicy Bypass -File herramientas\Comprobar-Audio.ps1
```

`Diagnostico-Inicial.ps1` (mejor como administrador) da: versión de Windows, driver de la Xonar (versión, firmado o no), Secure Boot, modo de prueba, integridad de memoria, qué hay instalado y las salidas de audio.

Pregunta al usuario:
1. **Modelo exacto** de sus Sennheiser (y si tiene varios).
2. **Con qué escucha**: Spotify (¿versión de la Microsoft Store o de escritorio?), foobar2000, AIMP, Kodi, navegador, juegos.
3. Si conecta **altavoces** a la misma salida (también recibirían la corrección).
4. Si usa programas de **producción musical por ASIO**: pueden cambiar la frecuencia de la tarjeta y hay que tenerlo en cuenta.

### 1. Driver de la Xonar

- **Driver firmado y oficial de ASUS** (8.1.x): adelante.
- **UNi Xonar** (sin firmar, o con Windows en *modo de prueba*): explica el riesgo (README, sección del driver) y **propón** pasar al oficial. Si acepta, sigue los pasos del README: punto de restauración → desinstalar el UNi con un audio sonando → reiniciar → `bcdedit /set testsigning off` (solo si estaba activado) → reiniciar → el usuario reactiva Secure Boot si lo había apagado → instalar el oficial → reiniciar → volver a ejecutar el diagnóstico.
- Si prefiere quedarse con el UNi: respétalo y sigue; apaga los efectos en sus dos paneles (ASUS Audio Center y C-Media Panel).
- Windows 11 no tiene soporte oficial de ASUS para esta tarjeta; el driver de Windows 10 suele funcionar. Si hay cuelgues o reinicios, díselo con claridad.

### 2. Panel de la Xonar y formato de Windows

Esto es interfaz gráfica: guía al usuario para que lo haga él, o hazlo tú si tienes control del escritorio.
- Salida analógica: **Headphone**. Ganancia según la impedancia (tabla en README).
- **Todos los efectos apagados**: SVN, Dolby Headphone, GX/Xear3D, 7.1 Virtual Speaker Shifter, EQ y entorno del panel.
- Frecuencia: **44,1 kHz** si escucha sobre todo música, 48 kHz si sobre todo vídeo. La misma en el panel y en Windows.
- `mmsys.cpl` → salida de la Xonar → *Opciones avanzadas*: 24 bits y la misma frecuencia. *Sonido espacial*: desactivado. Ponerla como predeterminada.

### 3. Equalizer APO

1. Instala (`EqualizerAPO-x64-*.exe /S` instala en silencio, pero **abre el Device Selector y se queda esperando**: lanza el instalador en segundo plano).
2. **Device Selector**: el instalador **marca todas las salidas** por defecto. Deja marcada **solo la salida de la Xonar**.
3. Marca *Troubleshooting options*, haz clic en el **nombre** de la salida de la Xonar y **desmarca "Use original APO"** en Pre-mix y Post-mix. Si no, los efectos de Windows o del driver siguen detrás de la corrección.
4. OK → prueba → debe decir *"No problems were detected"*. Si falla con la Xonar: modo **"Install as SFX/EFX (experimental)"**.
5. **Después del Device Selector, revisa las mejoras**: puede reactivar las "mejoras de Windows" en las otras salidas. Ejecuta `Comprobar-Audio.ps1`: en las demás salidas de la Xonar las mejoras deben quedar desactivadas (`mmsys.cpl` → Propiedades → Mejoras → *Deshabilitar todas las mejoras*). En la salida con Equalizer APO tienen que estar **activas** (lo necesita), y el script lo da como correcto.

Si abres el Device Selector a mano, lánzalo con el directorio de trabajo de su carpeta (`Start-Process ... -WorkingDirectory 'C:\Program Files\EqualizerAPO'`); si no, falla con *"no Qt platform plugin could be initialized"*.

### 4. Peace y el perfil del auricular

1. Instala Peace. La primera vez pregunta si puede **sobrescribir config.txt**: sí (hace copia). Interfaz completa.
2. Dos formas de cargar el perfil:
   - **A mano (usuario)**: botón **AutoEQ** → buscar el modelo (lista alfabética, rueda del ratón) → fila con **oratory1990** → **Uso** → **Guardar** con el nombre del auricular.
   - **Con las herramientas** (necesitan Python 3, ejecutar como administrador):
     ```bash
     python herramientas\autoeq_peace.py buscar "HD 600"
     python herramientas\autoeq_peace.py exportar "Sennheiser HD 600" --medidor oratory1990 --nombre HD600 --peace
     powershell -ExecutionPolicy Bypass -File herramientas\Crear-Accesos.ps1
     python herramientas\verificar_peace.py
     ```
     Luego, en Peace, **clic** en el preset nuevo de la lista.
3. Si el modelo no tiene oratory1990, usa crinacle o Rtings (avísale).

**Si controlas la interfaz por automatización**: Peace está hecho en AutoIt y **varios botones (Importar, Siguiente, Uso) no responden a clics sintéticos** (ni `mouse_event`, ni `BM_CLICK`, ni Enter). Sí funcionan los diálogos de Sí/No, Cancelar, las pestañas y la **lista de presets**. Por eso es más fiable generar el preset con `autoeq_peace.py --peace` y seleccionarlo con un clic en la lista. Las flechas del teclado no cambian de preset.

### 5. Aplicaciones en modo compartido

Todo lo que use modo **exclusivo** o **ASIO** se salta la corrección.

| App | Qué hacer | Dónde está la configuración (para comprobarla) |
|---|---|---|
| Spotify | Configuración → Salida → desactivar **modo exclusivo** | Store: `%LOCALAPPDATA%\Packages\SpotifyAB.SpotifyMusic_*\LocalState\Spotify\Users\<usuario>-user\prefs` · Escritorio: `%APPDATA%\Spotify\Users\<usuario>-user\prefs`. Clave `audio.device_selected` (`"excl":false` = compartido; guarda el **GUID** de la salida) |
| AIMP | Dispositivo `WASAPI: <salida>` (no ASIO) | `%APPDATA%\AIMP\AIMP.ini` (**UTF-16**), `DeviceName=` |
| foobar2000 | Salida WASAPI compartida o el dispositivo normal | Preferencias → Playback → Output |
| Kodi | Dispositivo `DIRECTSOUND: <salida>` (en Kodi, WASAPI = exclusivo) y amplificación +10 dB para pelis | `%APPDATA%\Kodi\userdata\guisettings.xml`: `audiooutput.audiodevice` = `DIRECTSOUND:{GUID}\|<nombre>` (GUID y nombre en `kodi.log`, bloque *Enumerated DIRECTSOUND devices*); `defaultvideosettings/volumeamplification` |

Edita los archivos **solo con la app cerrada**, con copia previa, y comprueba después que la app conserva el ajuste (ábrela y vuelve a leer el archivo).

### 6. Verificación final y entrega

1. `Comprobar-Audio.ps1` → "todo OK" (o solo avisos explicados).
2. `verificar_peace.py` si usaste las herramientas.
3. Que el usuario escuche música conocida y compare **apagando y encendiendo** el EQ (botón verde de Peace), con el volumen igualado: sin EQ suena algo más alto.
4. Explícale cómo cambiar de perfil (lista de Peace o accesos directos "EQ <modelo>") y que **Peace no tiene que estar abierto**.

## Trampas conocidas

- **Recrear salidas**: actualizar el driver, cambiar la frecuencia de la tarjeta o su modo de salida puede hacer que Windows **recree la salida con un GUID nuevo**. Consecuencias: Equalizer APO desaparece de ella (repetir el paso 3) y Spotify y Kodi apuntan a una salida que ya no existe (guardan el GUID). AIMP la guarda por nombre.
- **Peace y `config.txt`**: Peace deja `config.txt` en `Include: peace.txt` y escribe ahí el preset. `Cambiar-EQ.ps1` respeta ese esquema, así que los dos sistemas conviven.
- **Un mismo perfil para todo lo que sale por esa salida**: si hay altavoces en la misma salida, también reciben la corrección. Se apaga desde Peace.
- **"Peak gain" en rojo en el editor de Equalizer APO**: el preamp de la base AutoEQ va redondeado y deja un pico de +0,05/+0,1 dB. `autoeq_peace.py exportar` ya baja el preamp en pasos de 0,1 dB hasta que el pico quede en 0 dB o menos. Si el perfil se cargó a mano con el botón AutoEQ de Peace, baja tú la preamplificación 0,1 dB en Peace y guarda el preset.
- **Volumen distinto entre perfiles**: cada uno tiene su preamplificación negativa para no saturar. Es normal.
- **Bit-perfect**: con la corrección no lo hay, y es a propósito; ver la FAQ del README.
- Los scripts `.ps1` del repositorio están en **UTF-8 con BOM** para que PowerShell 5.1 lea bien los acentos; si los editas, mantenlo.
- **No redistribuyas los perfiles** generados (licencia de los medidores): se quedan en el PC del usuario.

## Criterio de terminado

- Driver firmado (o UNi aceptado por el usuario conociendo los riesgos).
- Efectos del panel de la Xonar y sonido espacial apagados.
- Equalizer APO **solo** en la salida de la Xonar y **sin** "Use original APO".
- Perfil del auricular aplicado y verificado.
- Sus aplicaciones en modo compartido.
- `Comprobar-Audio.ps1` correcto y el usuario contento con lo que oye.
