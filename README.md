# Corrección de auriculares en Windows

Cómo hacer que unos auriculares (pensado para Sennheiser, pero vale para cualquiera) suenen como deberían, con una corrección **medida en laboratorio** aplicada a **todo el sonido del PC**: Spotify, reproductores, películas, navegador...

Todo es gratis: **Equalizer APO** + **Peace** + perfiles de **AutoEq** medidos por **oratory1990**. Esta guía está escrita para una **ASUS Xonar Essence STX II**, pero salvo el paso 1 sirve para cualquier tarjeta.

> Resultado típico: graves más definidos, voces más limpias y más claras, menos "barro". No cambia el carácter del auricular de forma artificial; le quita los defectos que tiene de fábrica.

> **¿Tienes Claude (Claude Code) en tu PC?** Clona o descarga este repositorio, abre Claude en su carpeta y dile: *"Ayúdame a configurar la corrección de mis auriculares siguiendo este repositorio"*. El archivo `CLAUDE.md` tiene el procedimiento completo para el asistente: qué preguntarte, en qué orden hacer las cosas, qué no tocar sin tu permiso y los problemas conocidos.

---

## Cómo funciona

```
Spotify / AIMP / Kodi / navegador
        │   (modo compartido de Windows)
        ▼
Equalizer APO  ◄── perfil del auricular (10 filtros paramétricos medidos)
        │
        ▼
Xonar STX II ──► amplificador de auriculares ──► Sennheiser
```

- **La diana (Harman)**: curva de sonido que la mayoría de la gente prefiere en pruebas a ciegas (estudios de Sean Olive y Todd Welti, Harman International).
- **La medición (oratory1990)**: ingeniero acústico que mide auriculares con un simulador de oído profesional. Sus mediciones son de las más fiables.
- **El cálculo (AutoEq)**: proyecto de Jaakko Pasanen que compara la medición con la diana y calcula los filtros que corrigen la diferencia.
- **El motor (Equalizer APO)**: se engancha al audio de Windows y aplica esos filtros a todo lo que suena por una salida.
- **El mando (Peace)**: interfaz para Equalizer APO. Trae dentro la base de datos de AutoEq (más de 8.800 auriculares) y permite cambiar de perfil con un clic.

Es como un LUT de calibración de monitor, pero para los oídos: corrige el dispositivo de salida, no el contenido.

---

## 1. Preparar la Xonar Essence STX II

> No he probado esta guía en una STX II; los nombres de los menús pueden variar algo según la versión del driver. La idea es siempre la misma: **la tarjeta no debe tocar el sonido**, eso lo hará Equalizer APO.

### Driver: usa el oficial de ASUS

| | Oficial de ASUS | UNi Xonar (MaxedTech) |
|---|---|---|
| Versión | 8.1.11.5, Audio Center 0.3.1.11 (25-12-2019) | 1.81a, driver C-Media 1825 (2016), modificado |
| Firma digital | **Sí** | **No**: la versión para la STX II en 64 bits pide Windows en *modo de prueba* o con la comprobación de firmas desactivada |
| Windows 11 | No está en la lista de ASUS, pero los usuarios lo usan (es el de Windows 10) | La página dice que funciona como en Windows 10 |
| Lo que aporta | Lo necesario | Extras: GX, Dolby, panel C-Media, correcciones antiguas |

**Recomendación: el driver oficial.** Con esta guía, el ecualizado lo hace Equalizer APO, así que los extras del UNi no hacen falta. Y un driver sin firmar obliga a debilitar la seguridad de Windows:
- El *modo de prueba* (`testsigning`) no se puede activar con **Arranque seguro (Secure Boot)** encendido. Hay que apagarlo en la BIOS.
- Muchos juegos con antitrampas se niegan a arrancar en modo de prueba.
- La **Integridad de memoria** de Windows (Aislamiento del núcleo) puede bloquear drivers sin firmar.

Descarga oficial: <https://www.asus.com/supportonly/essence%20stx%20ii/helpdesk_download/> → Windows 10 64 bits → *Audio driver for Windows 10*.

> En Windows 11 no hay soporte oficial de ASUS para esta tarjeta. Hay usuarios que lo usan sin problemas y otros que cuentan reinicios esporádicos. **Crea un punto de restauración antes de instalar.**

**Si ahora tiene instalado el UNi Xonar y quiere pasarse al oficial:**
1. Crea un punto de restauración (`Win + R` → `sysdm.cpl` → *Protección del sistema* → *Crear*).
2. Pon a sonar cualquier archivo de audio y, con él sonando, desinstala el UNi Xonar desde *Aplicaciones instaladas* (es lo que recomiendan sus propias notas). Reinicia.
3. Si Windows estaba en **modo de prueba** (se ve una marca de agua "Modo de prueba" abajo a la derecha del escritorio): abre una consola **como administrador**, ejecuta `bcdedit /set testsigning off` y reinicia.
4. Si apagaste **Secure Boot** para el UNi, vuelve a encenderlo en la BIOS.
5. Instala el driver oficial de ASUS y reinicia.

**Si prefiere quedarse con el UNi Xonar**, la guía funciona igual: apaga los efectos tanto en el *ASUS Audio Center* como en el *C-Media Panel* (GX/Xear3D incluidos), y si Equalizer APO no carga, usa el modo SFX/EFX del paso 2. Hay un usuario que comenta en la página del UNi un "golpe" de sonido con Peace que desapareció al desinstalarlo; es un caso aislado, pero si te pasa, ya sabes de dónde puede venir.

**En el panel de la Xonar:**
1. Salida analógica en **Headphone** (auriculares).
2. **Ganancia del amplificador de auriculares** según la impedancia de los tuyos:

   | Auricular Sennheiser | Impedancia | Ajuste en la Xonar |
   |---|---|---|
   | HD 599 / 598 | 50 Ω | < 64 Ω |
   | HD 25 | 70 Ω | 64-300 Ω |
   | HD 560S | 120 Ω | 64-300 Ω |
   | HD 490 Pro | 130 Ω | 64-300 Ω |
   | HD 620S | 150 Ω | 64-300 Ω |
   | HD 600 / 650 / 660S2 / 800S | 300 Ω | 64-300 Ω (si tienes que llevar el volumen casi al máximo, 300-600 Ω) |

   Regla general: el rango que contiene la impedancia de tus auriculares. Lo ideal es escuchar con el volumen hacia la mitad del recorrido.
3. **Desactiva todos los efectos** del panel: SVN (normalizador de volumen), Dolby Headphone, modo GX, 7.1 Virtual Speaker Shifter, el ecualizador y el "entorno" del propio panel. Todo lo que altere el sonido, apagado.
4. **Frecuencia de muestreo**: 44,1 kHz si escuchas sobre todo música, 48 kHz si sobre todo vídeo. Pon **la misma** en el panel de la Xonar y en Windows (siguiente punto).

**En Windows** (`Win + R` → `mmsys.cpl` → pestaña *Reproducción* → salida de la Xonar → *Propiedades*):
- *Opciones avanzadas* → formato predeterminado: **24 bits, 44100 Hz** (o 48000, la misma que en el panel).
- *Sonido espacial* → **Desactivado**.
- La pestaña *Mejoras* déjala como esté: la gestionará Equalizer APO en el paso 2.
- Pon la salida de la Xonar como **dispositivo predeterminado**.

---

## 2. Instalar Equalizer APO

1. Descarga el instalador de la página oficial: <https://sourceforge.net/projects/equalizerapo/>
2. Al terminar se abre el **Device Selector**. Marca **solo la salida de la Xonar** por la que salen los auriculares. Desmarca todo lo demás (monitores HDMI, micrófonos, dispositivos virtuales...).
3. Marca abajo **Troubleshooting options**, haz clic en el **nombre** de la salida de la Xonar y **desmarca "Use original APO"** en *Pre-mix* y en *Post-mix*.
   Esto evita que Windows (o el driver) siga aplicando sus propios efectos detrás de tu corrección.
4. Pulsa **OK**. Reinicia el servicio de audio y hace una prueba: debe salir *"No problems were detected"*. No hace falta reiniciar el PC.

> Si la prueba falla con la Xonar, vuelve a abrir el Device Selector (menú Inicio → Equalizer APO) y en *Troubleshooting options* cambia el modo a **"Install as SFX/EFX (experimental)"**. Algunos drivers lo necesitan.

---

## 3. Instalar Peace y elegir tu perfil

1. Descarga Peace: <https://sourceforge.net/projects/peace-equalizer-apo-extension/>
2. Instálalo (puedes elegir idioma español). Al abrirlo por primera vez pregunta si puede **sobrescribir config.txt**: di que **Sí** (hace copia).
3. Elige la **interfaz completa**.
4. Pulsa el botón **AutoEQ** (abajo a la derecha). En la lista, busca tu modelo con la rueda del ratón (está ordenada alfabéticamente) y elige la fila con **oratory1990** en la columna *Medidor*. Si tu modelo no la tiene, usa **crinacle** o **Rtings**.
5. Pulsa **Uso**. La corrección se aplica al momento.
6. Pulsa **Guardar** y ponle el nombre del auricular. Así queda en la lista de configuraciones y la recuperas con un clic.

Peace **no tiene que estar abierto** para que funcione: la corrección la aplica Equalizer APO siempre. Peace solo es el panel para cambiarla.

**Si tienes varios auriculares**, guarda un preset de cada uno y cambia al que te pongas (clic en la lista; las flechas del teclado no sirven). Cada perfil tiene su propio nivel de preamplificación, así que el volumen cambia un poco entre auriculares; compénsalo con el volumen.

---

## 4. Poner las aplicaciones en modo compartido

Equalizer APO actúa sobre el mezclador de Windows. Las aplicaciones que se saltan ese mezclador (modo **exclusivo** o **ASIO**) **no reciben la corrección**.

| Aplicación | Ajuste |
|---|---|
| **Spotify** | Configuración → Salida → **desactivar "Habilitar el modo exclusivo"**. Calidad "Sin pérdida", normalizar volumen desactivado |
| **AIMP** | Opciones → Reproducción → dispositivo **"WASAPI: (salida de la Xonar)"**, no ASIO |
| **foobar2000** | Salida por **WASAPI (compartido)** o el dispositivo normal, no "exclusive" ni ASIO |
| **Kodi** | Sistema → Audio → dispositivo **"DIRECTSOUND: (salida de la Xonar)"** (en Kodi, WASAPI siempre es exclusivo) |
| Navegadores, Netflix, juegos | Ya usan el modo compartido |

**Películas que se oyen bajas en Kodi**: es normal, el cine se mezcla a un nivel mucho más bajo que la música (unos -27 LUFS frente a -9/-14). En el reproductor de Kodi → audio → **Amplificación de volumen** → +10 dB, y "Establecer como predeterminado para todos los medios". Kodi aplica un limitador para que no distorsione.

---

## 5. Herramientas de este repositorio (opcional)

No son necesarias para que funcione, pero lo hacen más cómodo. Necesitan **Python 3** (sin librerías extra) y ejecutarse **como administrador** cuando escriben en la carpeta de Equalizer APO.

| Herramienta | Para qué |
|---|---|
| `herramientas/Diagnostico-Inicial.ps1` | Punto de partida: Windows, driver de la Xonar (y si está firmado), Secure Boot, modo de prueba y qué hay instalado |
| `herramientas/autoeq_peace.py` | Busca tu auricular en la base de Peace y exporta su perfil para Equalizer APO y, opcionalmente, como preset de Peace |
| `herramientas/Crear-Accesos.ps1` | Crea en el menú Inicio un acceso directo por perfil ("EQ HD660S2", "EQ desactivado"...) para cambiar sin abrir Peace |
| `herramientas/Cambiar-EQ.ps1` | El que ejecutan esos accesos directos (cambia el perfil activo) |
| `herramientas/Comprobar-Audio.ps1` | Revisa que todo esté bien: dónde está Equalizer APO, si arrastra efectos de Windows, mejoras, formato y perfil activo |
| `herramientas/verificar_peace.py` | Comprueba que los presets de Peace coinciden filtro a filtro con los perfiles exportados |

Ejemplo, desde una consola **como administrador** en la carpeta `herramientas`:

```bash
python autoeq_peace.py buscar "HD 660S2"
python autoeq_peace.py exportar "Sennheiser HD 660S2" --medidor oratory1990 --nombre HD660S2 --peace
powershell -ExecutionPolicy Bypass -File Crear-Accesos.ps1
powershell -ExecutionPolicy Bypass -File Comprobar-Audio.ps1
```

`buscar` usa el nombre tal como aparece en la base; con el nombre exacto que te devuelve, `exportar` crea:
- `C:\Program Files\EqualizerAPO\config\perfiles\HD660S2.txt` (perfil para Equalizer APO)
- `C:\Program Files\EqualizerAPO\config\Sennheiser HD 660S2.peace` (aparece en la lista de Peace)

Los perfiles no vienen incluidos en el repositorio: se sacan de la base que trae tu propio Peace.

---

## Preguntas habituales

**¿No sería mejor un ecualizador de 16 o 31 bandas?**
No. Los 10 filtros de AutoEq son **paramétricos**: cada uno tiene su frecuencia, ganancia y anchura exactas (por ejemplo, -5,7 dB justo en 112 Hz). Un ecualizador gráfico tiene bandas fijas y solo aproxima. Probado con un HD 620S: el paramétrico corrige mejor graves y medios, que es lo importante; el gráfico solo gana un poco en agudos a base de subidas de +9 dB arriesgadas, en la zona que más cambia según cómo te asienten los auriculares.

**¿Pierdo el bit-perfect?**
Sí, a propósito: corregir es cambiar la señal. Pero lo que se gana (corregir desviaciones de varios dB que se oyen claramente) es mucho mayor que lo que se pierde (diferencias del mezclador de Windows que el oído no detecta). El bit-perfect solo sirve si quieres el sonido de fábrica sin tocar o para hacer mediciones.

**En el editor de Equalizer APO sale "Peak gain" en rojo (+0,1 dB). ¿Es grave?**
No, pero lo correcto es que no salga. Significa que en algún punto la corrección sube la señal una décima por encima del original, porque el preamp de la base AutoEQ va redondeado. Solución: bajar la preamplificación 0,1 dB en Peace. `autoeq_peace.py` ya lo hace solo al exportar (deja el pico en 0 dB o por debajo).

**¿Se oirá distinto al principio?**
Probablemente. El oído se acostumbra a cualquier curva. Escúchalo unos días con música que conozcas y luego apágalo un momento (botón verde de Peace): ahí se nota de verdad. Al comparar, iguala el volumen, porque sin EQ suena algo más alto y el oído confunde "más alto" con "mejor".

**¿Y si conecto altavoces a la misma salida?**
También recibirían la corrección de los auriculares. Apágala en Peace cuando uses altavoces. Para altavoces no hay perfil universal: la habitación influye más que el altavoz, y lo correcto es medir en tu sitio con un micrófono de medida y el programa REW.

---

## Si algo deja de funcionar

| Síntoma | Causa probable | Solución |
|---|---|---|
| De repente suena sin corrección | Una actualización del driver o de Windows recreó la salida de audio | Ejecuta de nuevo el Device Selector y repite el paso 2 |
| Spotify, Kodi o AIMP sin sonido | Recuerdan la salida antigua | Vuelve a elegir la salida de la Xonar en sus ajustes |
| Suena raro, con efecto envolvente o "en lata" | Se reactivaron efectos del panel de la Xonar o de Windows | Repite el paso 1 y el punto 3 del paso 2 |
| Los accesos directos dejan de funcionar | Peace sobrescribió config.txt | Vuelve a usar un acceso directo; los dos sistemas conviven |

`Comprobar-Audio.ps1` detecta casi todos estos casos.

---

## Créditos

- **AutoEq**, de Jaakko Pasanen: <https://github.com/jaakkopasanen/AutoEq>
- Mediciones de **oratory1990**, **crinacle**, **Rtings** y otros, a través de AutoEq.
- Diana **Harman** (Sean Olive, Todd Welti y equipo, Harman International).
- **Equalizer APO**, de Jonas Thedering.
- **Peace**, de Peter Verbeek.

Los scripts de este repositorio se publican bajo licencia MIT. Los perfiles de corrección pertenecen a sus autores y no se redistribuyen aquí.
