"""Comprueba que cada preset .peace coincide filtro a filtro con su perfil de
config\\perfiles (generados ambos con autoeq_peace.py) y dice cuál se está aplicando.

Uso: python verificar_peace.py
"""
import configparser
import glob
import os
import re

C = r"C:\Program Files\EqualizerAPO\config"
CODIGOS = {"14": "LSC", "15": "HSC"}


def de_eapo(texto):
    pre = re.search(r"Preamp:\s*(-?[\d.]+)", texto)
    filtros = sorted((t, float(fc), float(g), float(q)) for t, fc, g, q in
                     re.findall(r"ON (PK|LSC|HSC) Fc (-?[\d.]+) Hz Gain (-?[\d.]+) dB Q ([\d.]+)", texto))
    return (float(pre.group(1)) if pre else None), filtros


def de_peace(ruta):
    cp = configparser.ConfigParser(strict=False)
    cp.optionxform = str
    cp.read(ruta, encoding="utf-8")
    pre = float(cp["General"].get("PreAmp", 0))
    fr, ga, qu = cp["Frequencies"], cp["Gains"], cp["Qualities"]
    fi = cp["Filters"] if cp.has_section("Filters") else {}
    filtros = []
    for k in fr:
        n = k.replace("Frequency", "")
        filtros.append((CODIGOS.get(fi.get("Filter" + n, ""), "PK"), float(fr[k]),
                        float(ga.get("Gain" + n, 0)), float(qu.get("Quality" + n, 1.41))))
    return pre, sorted(filtros)


perfiles = {}
for ruta in glob.glob(os.path.join(C, "perfiles", "*.txt")):
    texto = open(ruta, encoding="utf-8").read()
    modelo = re.search(r"^# (.+?) - AutoEq", texto, re.M)
    perfiles[os.path.basename(ruta)[:-4]] = (modelo.group(1) if modelo else None, de_eapo(texto))

todo_ok = True
for nombre, (modelo, ref) in sorted(perfiles.items()):
    preset = os.path.join(C, f"{modelo}.peace") if modelo else None
    if not preset or not os.path.exists(preset):
        print(f"{nombre:12s} sin preset de Peace (opcional: exportar con --peace)")
        continue
    igual = de_peace(preset) == ref
    todo_ok &= igual
    print(f"{nombre:12s} preset '{modelo}': {'IGUAL al perfil' if igual else 'DISTINTO del perfil'}")

activo_txt = ""
for f in ("peace.txt", "config.txt"):
    ruta = os.path.join(C, f)
    if os.path.exists(ruta):
        activo_txt += open(ruta, encoding="utf-8").read() + "\n"
inc = re.search(r"Include:\s*perfiles\\(.+?)\.txt", activo_txt)
if inc:
    activo = inc.group(1)
else:
    actual = de_eapo(activo_txt)
    activo = next((n for n, (_, ref) in perfiles.items() if ref == actual), None)
print("\nAplicado ahora:", activo or "ninguno de los perfiles (EQ desactivado o preset manual)")
print("Resultado:", "TODO OK" if todo_ok else "REVISAR")
