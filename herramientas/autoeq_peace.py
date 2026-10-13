"""Saca perfiles de corrección de auriculares de la base AutoEQ que trae Peace
y los convierte para Equalizer APO (perfil .txt) y para Peace (preset .peace).

La base viene comprimida en la instalación de Peace (config\\AutoEQCompressed5.7z);
el script la descomprime con el 7za.exe que trae el propio Peace.

Ejemplos:
  python autoeq_peace.py buscar "HD 660S2"
  python autoeq_peace.py exportar "Sennheiser HD 660S2" --medidor oratory1990 --nombre HD660S2
  python autoeq_peace.py exportar "Sennheiser HD 600" --medidor oratory1990 --nombre HD600 --peace

`exportar` escribe <config>\\perfiles\\<nombre>.txt y, con --peace, también
<config>\\Sennheiser HD 600.peace para que aparezca en la lista de Peace.
Hay que ejecutarlo como administrador (la carpeta config está en Archivos de programa).
"""
import argparse
import os
import re
import subprocess
import sys
import tempfile

CONFIG = r"C:\Program Files\EqualizerAPO\config"
DIANAS = {
    "harman": "AutoEQCompressedHarman5.txt",
    "ief": "AutoEQCompressedIEF5.txt",
    "ief-graves": "AutoEQCompressedIEFBass5.txt",
}
TIPOS = {"M": "LSC", "P": "PK", "I": "HSC"}
CODIGOS_PEACE = {"LSC": 14, "HSC": 15}  # los picos (PK) no llevan código en .peace


def base_autoeq(diana):
    """Devuelve la ruta del txt de la base, descomprimiéndola si hace falta.

    Peace descomprime la base en config la primera vez que se abre su ventana AutoEQ;
    si aún no se ha abierto, sigue comprimida en AutoEQCompressed5.7z.
    """
    ya_descomprimida = os.path.join(CONFIG, DIANAS[diana])
    if os.path.exists(ya_descomprimida):
        return ya_descomprimida
    destino = os.path.join(tempfile.gettempdir(), "autoeq_peace_db")
    txt = os.path.join(destino, DIANAS[diana])
    if not os.path.exists(txt):
        archivo = os.path.join(CONFIG, "AutoEQCompressed5.7z")
        sieteza = os.path.join(CONFIG, "7za.exe")
        if not (os.path.exists(archivo) and os.path.exists(sieteza)):
            sys.exit("No encuentro la base AutoEQ de Peace. ¿Está Peace instalado en " + CONFIG + "?")
        os.makedirs(destino, exist_ok=True)
        subprocess.run([sieteza, "x", archivo, "-o" + destino, "-y"], check=True,
                       stdout=subprocess.DEVNULL)
    return txt


def leer_base(ruta):
    """Lista de (modelo, medidor, banco de pruebas, código de filtros).

    Formato de la base: 'D' = modelo, 'M' = medidor y 'W' = banco de pruebas
    (ambos aplican a los bloques siguientes), la primera línea 'A' de cada bloque
    lleva preamp + filtros paramétricos y la segunda 'A' (con 'F') un EQ de bandas fijas.
    """
    perfiles, modelo, medidor, banco = [], None, None, ""
    ya = set()
    with open(ruta, encoding="utf-8", errors="replace") as fh:
        for linea in fh:
            linea = linea.rstrip("\n")
            if linea.startswith("D"):
                modelo = linea[1:]
            elif linea.startswith("M"):
                medidor, banco = linea[1:], ""
            elif linea.startswith("W"):
                banco = linea[1:]
            elif linea.startswith("A") and "Q" in linea and modelo:
                clave = (modelo, medidor, banco)
                if clave not in ya:
                    ya.add(clave)
                    perfiles.append((modelo, medidor, banco, linea[1:]))
    return perfiles


def a_filtros(codigo):
    m = re.match(r"(-?[\d.]+)(.*)", codigo)
    preamp, resto = float(m.group(1)), m.group(2)
    filtros = [(TIPOS[t], float(fc), float(g), float(q))
               for t, fc, g, q in re.findall(r"([MPI])(-?[\d.]+)G(-?[\d.]+)Q([\d.]+)", resto)]
    return preamp, filtros


def num(x):
    return str(int(x)) if x == int(x) else str(x)


def texto_eapo(modelo, medidor, diana, preamp, filtros):
    lineas = [f"# {modelo} - AutoEq / {medidor} (diana {diana}), base AutoEQ de Peace",
              f"Preamp: {num(preamp)} dB"]
    for n, (t, fc, g, q) in enumerate(filtros, 1):
        lineas.append(f"Filter {n}: ON {t} Fc {num(fc)} Hz Gain {num(g)} dB Q {num(q)}")
    return "\n".join(lineas) + "\n"


def texto_peace(descripcion, preamp, filtros):
    f = sorted(filtros, key=lambda x: x[1])
    lineas = ["[General]", f"Description={descripcion}", f"PreAmp={num(preamp)}", "[Frequencies]"]
    lineas += [f"Frequency{i}={num(x[1])}" for i, x in enumerate(f, 1)]
    lineas += ["[Gains]"] + [f"Gain{i}={num(x[2])}" for i, x in enumerate(f, 1)]
    lineas += ["[Qualities]"] + [f"Quality{i}={num(x[3])}" for i, x in enumerate(f, 1)]
    lineas += ["[Filters]"] + [f"Filter{i}={CODIGOS_PEACE[x[0]]}" for i, x in enumerate(f, 1)
                               if x[0] in CODIGOS_PEACE]
    lineas += ["[Speakers]", "SpeakerId0=0", "SpeakerTargets0=all", "SpeakerName0=All"]
    return "\r\n".join(lineas) + "\r\n"


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--diana", choices=DIANAS, default="harman",
                    help="curva objetivo (harman por defecto, la de auriculares de diadema)")
    sub = ap.add_subparsers(dest="orden", required=True)
    b = sub.add_parser("buscar", help="lista los modelos y medidores que contienen el texto")
    b.add_argument("texto")
    e = sub.add_parser("exportar", help="escribe el perfil para Equalizer APO (y opcionalmente Peace)")
    e.add_argument("modelo", help="nombre exacto del modelo, tal como sale en 'buscar'")
    e.add_argument("--medidor", default="oratory1990")
    e.add_argument("--nombre", required=True, help="nombre corto del perfil, p. ej. HD660S2")
    e.add_argument("--peace", action="store_true", help="crear también el preset .peace")
    e.add_argument("--salida", default=CONFIG, help="carpeta config de Equalizer APO")
    a = ap.parse_args()

    perfiles = leer_base(base_autoeq(a.diana))
    if a.orden == "buscar":
        t = a.texto.lower()
        hits = [p for p in perfiles if t in p[0].lower()]
        for modelo, medidor, banco, _ in hits:
            print(f"{modelo:45s} | {medidor}{' / ' + banco if banco else ''}")
        print(f"\n{len(hits)} resultado(s). Recomendado: oratory1990 si está; si no, crinacle o Rtings.")
        return

    cand = [p for p in perfiles if p[0] == a.modelo and p[1] == a.medidor]
    if not cand:
        sys.exit(f"No hay '{a.modelo}' medido por '{a.medidor}'. Usa 'buscar' para ver las opciones.")
    if len(cand) > 1:
        print("Aviso: hay varias mediciones de ese medidor; uso la primera:", cand[0][2] or "(sin banco)")
    modelo, medidor, _, codigo = cand[0]
    preamp, filtros = a_filtros(codigo)

    carpeta = os.path.join(a.salida, "perfiles")
    os.makedirs(carpeta, exist_ok=True)
    ruta = os.path.join(carpeta, a.nombre + ".txt")
    with open(ruta, "w", encoding="utf-8") as fh:
        fh.write(texto_eapo(modelo, medidor, a.diana, preamp, filtros))
    print(f"Perfil Equalizer APO: {ruta}  (preamp {preamp} dB, {len(filtros)} filtros)")
    if a.peace:
        ruta_p = os.path.join(a.salida, modelo + ".peace")
        with open(ruta_p, "w", encoding="utf-8", newline="") as fh:
            fh.write(texto_peace(f"{modelo} - AutoEq {medidor} ({a.diana})", preamp, filtros))
        print(f"Preset de Peace:      {ruta_p}")


if __name__ == "__main__":
    main()
