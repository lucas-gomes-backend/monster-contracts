"""Importa bairros do recorte do OpenStreetMap para o jogo (docs/07, 'Ferramenta de importação').

Uso (na raiz do repositório):
  python tools/cidade/importar.py             # grava game/data/cidade/<bairro>.json
  python tools/cidade/importar.py --conferir  # só confere se os arquivos estão em dia (sai 1 se não)

Lê tools/cidade/osm/recorte.json (sem rede): o mesmo recorte dá sempre o mesmo resultado.
Para cada bairro: o limite, as ruas (recortadas no limite e simplificadas), os canais,
os marcos e as saídas (onde uma rua atravessa o limite e leva ao bairro vizinho).
"""
import json
import math
import os
import sys

AQUI = os.path.dirname(os.path.abspath(__file__))
RAIZ = os.path.dirname(os.path.dirname(AQUI))
sys.path.insert(0, AQUI)
import geometria as G  # noqa: E402
import relevo as R  # noqa: E402

DESTINO = os.path.join(RAIZ, "game", "data", "cidade")
LARGURA_CANAL = 4.0
COMPRIMENTO_MINIMO = 2.0
SAIDAS_JUNTAS = 3.0
PERTO_DO_VIZINHO = 8.0


def _r(p):
    return [round(p[0], 2), round(p[1], 2)]


def _linha(elemento, config):
    return [G.projetar(lat, lon, config["origem"], config["escala"]) for lat, lon in elemento["geometry"]]


def _poligono(recorte, osm_id, config):
    tipo, numero = osm_id.split("/")
    for e in recorte["limites"]:
        if e["type"] == tipo and str(e["id"]) == numero:
            pontos = _linha(e, config)
            if pontos[0] == pontos[-1]:
                pontos = pontos[:-1]
            return pontos
    raise ValueError("limite %s não está no recorte" % osm_id)


def _distancia_ao_limite(p, poligono):
    n = len(poligono)
    return min(G._distancia_ao_segmento(p, poligono[i], poligono[(i + 1) % n]) for i in range(n))


def _area(poligono):
    n = len(poligono)
    return abs(sum(poligono[i][0] * poligono[(i + 1) % n][1] - poligono[(i + 1) % n][0] * poligono[i][1] for i in range(n))) / 2.0


def _marco(elemento, config):
    tags = elemento.get("tags", {})
    for m in config["marcos"]:
        if m["chave"] in tags and ("valor" not in m or tags[m["chave"]] == m["valor"]):
            return "%s=%s" % (m["chave"], tags[m["chave"]])
    return ""


def grade_de_relevo(config, caixa, alturas):
    """Alturas (já na escala vertical do jogo) numa grade que cobre a caixa do bairro.

    alturas: objeto com altitude(lat, lon) em metros reais (relevo.Relevo).
    """
    passo = config["relevo"]["passo"]
    escala_v = config["relevo"]["escala_vertical"]
    x0 = math.floor(caixa[0] / passo) * passo
    z0 = math.floor(caixa[1] / passo) * passo
    colunas = int(math.ceil((caixa[2] - x0) / passo)) + 1
    linhas = int(math.ceil((caixa[3] - z0) / passo)) + 1
    valores = []
    for j in range(linhas):
        for i in range(colunas):
            lat, lon = G.desprojetar(x0 + i * passo, z0 + j * passo, config["origem"], config["escala"])
            valores.append(round(max(0.0, alturas.altitude(lat, lon)) / escala_v, 1))
    return {"origem": [round(x0, 2), round(z0, 2)], "passo": passo, "colunas": colunas, "linhas": linhas,
            "escala_vertical": escala_v, "alturas": valores}


def importar_bairro(config, recorte, bairro, vizinhos, alturas=None):
    """vizinhos: {id: polígono} dos outros bairros, para saber aonde cada saída leva."""
    limite = _poligono(recorte, bairro["limite_osm"], config)
    tol = config["tolerancia_simplificacao"]
    ruas, canais, marcos, saidas = [], [], [], []
    for e in recorte["elementos"]:
        tags = e.get("tags", {})
        if "geometry" not in e and "lat" not in e:
            continue
        tipo_rua = tags.get("highway", "")
        regra = config["ruas"].get(tipo_rua)
        if e["type"] == "way" and regra and (tags.get("name") or not regra.get("so_com_nome")):
            trechos, cruzamentos = G.recortar(_linha(e, config), limite)
            for trecho in trechos:
                trecho = G.simplificar(trecho, tol)
                if G.comprimento(trecho) >= COMPRIMENTO_MINIMO:
                    ruas.append({"osm": e["id"], "nome": tags.get("name", ""), "tipo": tipo_rua,
                                 "largura": regra["largura"], "pontos": [_r(p) for p in trecho]})
            for p in cruzamentos:
                para = ""
                for vid, vpol in sorted(vizinhos.items()):
                    if G.dentro(p, vpol) or _distancia_ao_limite(p, vpol) <= PERTO_DO_VIZINHO:
                        para = vid
                if all(math.hypot(p[0] - s["posicao"][0], p[1] - s["posicao"][1]) > SAIDAS_JUNTAS for s in saidas):
                    saidas.append({"rua": tags.get("name", tipo_rua), "osm": e["id"], "posicao": _r(p), "para": para})
            continue
        if e["type"] == "way" and tags.get("waterway") in config["canais"]:
            for trecho in G.recortar(_linha(e, config), limite)[0]:
                trecho = G.simplificar(trecho, tol)
                canais.append({"osm": e["id"], "nome": tags.get("name", ""), "tipo": tags["waterway"],
                               "largura": LARGURA_CANAL, "pontos": [_r(p) for p in trecho]})
            continue
        tipo_marco = _marco(e, config)
        if tipo_marco:
            if "lat" in e:
                pontos = [G.projetar(e["lat"], e["lon"], config["origem"], config["escala"])]
            else:
                pontos = _linha(e, config)
            centro = (sum(p[0] for p in pontos) / len(pontos), sum(p[1] for p in pontos) / len(pontos))
            if not G.dentro(centro, limite) and _distancia_ao_limite(centro, limite) > PERTO_DO_VIZINHO:
                continue
            marco = {"osm": "%s/%d" % (e["type"], e["id"]), "nome": tags.get("name", ""), "tipo": tipo_marco,
                     "posicao": _r(centro)}
            if "ele" in tags:
                try:
                    marco["altitude"] = float(tags["ele"])
                except ValueError:
                    pass
            if len(pontos) > 1 and tags.get("railway"):
                marco["pontos"] = [_r(p) for p in G.simplificar(pontos, tol)]
            marcos.append(marco)
    caixa = G.caixa(limite)
    return {
        "$comment": "Gerado por tools/cidade/importar.py a partir do OpenStreetMap (© colaboradores do OpenStreetMap, ODbL). Não edite à mão: rode o importador.",
        "id": bairro["id"],
        "nome": bairro["nome"],
        "zona": bairro["zona"],
        "escala": config["escala"],
        "area_m2": round(_area(limite), 1),
        "caixa": [round(v, 2) for v in caixa],
        "limite": [_r(p) for p in G.simplificar(limite + [limite[0]], tol)[:-1]],
        "ruas": sorted(ruas, key=lambda r: (r["osm"], r["pontos"][0])),
        "canais": sorted(canais, key=lambda c: (c["osm"], c["pontos"][0])),
        "marcos": sorted(marcos, key=lambda m: m["osm"]),
        "saidas": sorted(saidas, key=lambda s: (s["posicao"][0], s["posicao"][1])),
        "relevo": grade_de_relevo(config, caixa, alturas or R.Relevo()),
    }


def importar_todos(config, recorte):
    poligonos = {b["id"]: _poligono(recorte, b["limite_osm"], config) for b in config["bairros"]}
    resultado = {}
    for b in config["bairros"]:
        vizinhos = {k: v for k, v in poligonos.items() if k != b["id"]}
        resultado[b["id"]] = importar_bairro(config, recorte, b, vizinhos)
    return resultado


def texto(bairro):
    return json.dumps(bairro, ensure_ascii=False, indent=1) + "\n"


def carregar():
    with open(os.path.join(AQUI, "config.json"), encoding="utf-8") as f:
        config = json.load(f)
    with open(os.path.join(AQUI, "osm", "recorte.json"), encoding="utf-8") as f:
        recorte = json.load(f)
    return config, recorte


def main(argv):
    config, recorte = carregar()
    bairros = importar_todos(config, recorte)
    conferir = "--conferir" in argv
    desatualizados = []
    for bid, dados in bairros.items():
        caminho = os.path.join(DESTINO, bid + ".json")
        if conferir:
            atual = ""
            if os.path.exists(caminho):
                with open(caminho, encoding="utf-8") as f:
                    atual = f.read()
            if atual != texto(dados):
                desatualizados.append(bid)
            continue
        os.makedirs(DESTINO, exist_ok=True)
        with open(caminho, "w", encoding="utf-8", newline="\n") as f:
            f.write(texto(dados))
        print("%s: %d ruas, %d canais, %d marcos, %d saídas, %.0f m²" % (
            bid, len(dados["ruas"]), len(dados["canais"]), len(dados["marcos"]), len(dados["saidas"]), dados["area_m2"]))
    if desatualizados:
        print("Desatualizados (rode python tools/cidade/importar.py): " + ", ".join(desatualizados))
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
