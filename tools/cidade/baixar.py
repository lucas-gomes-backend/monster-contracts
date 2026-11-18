"""Baixa do OpenStreetMap (API Overpass) o recorte bruto dos bairros do config.json.

Uso (na raiz do repositório):  python tools/cidade/baixar.py
Grava tools/cidade/osm/recorte.json. Rodar só quando quiser atualizar os dados: o
importador (importar.py) lê o arquivo salvo, sem rede, e sempre dá o mesmo resultado.
Dados © colaboradores do OpenStreetMap, licença ODbL (ver osm/LICENCA.md).
"""
import json
import os
import time
import urllib.parse
import urllib.request

AQUI = os.path.dirname(os.path.abspath(__file__))
SERVIDORES = [
    "https://overpass-api.de/api/interpreter",
    "https://overpass.kumi.systems/api/interpreter",
]
CABECALHO = {"User-Agent": "monster-contracts-importador/0.1"}


def consultar(consulta):
    ultimo_erro = None
    for tentativa in range(3):
        for url in SERVIDORES:
            try:
                dados = urllib.parse.urlencode({"data": consulta}).encode()
                req = urllib.request.Request(url, data=dados, headers=CABECALHO)
                with urllib.request.urlopen(req, timeout=180) as resposta:
                    return json.load(resposta)
            except Exception as erro:  # servidor ocupado: tenta o outro, depois espera
                ultimo_erro = erro
        time.sleep(10 * (tentativa + 1))
    raise RuntimeError("Overpass não respondeu: %s" % ultimo_erro)


def _enxugar(elemento, chaves):
    """Só o que o importador usa, com coordenadas arredondadas (diffs pequenos e estáveis)."""
    saida = {"type": elemento["type"], "id": elemento["id"]}
    tags = {k: v for k, v in elemento.get("tags", {}).items() if k in chaves}
    if tags:
        saida["tags"] = tags
    if "geometry" in elemento:
        saida["geometry"] = [[round(p["lat"], 7), round(p["lon"], 7)] for p in elemento["geometry"]]
    if "lat" in elemento:
        saida["lat"], saida["lon"] = round(elemento["lat"], 7), round(elemento["lon"], 7)
    return saida


def main():
    with open(os.path.join(AQUI, "config.json"), encoding="utf-8") as f:
        config = json.load(f)
    ids = [b["limite_osm"].split("/")[1] for b in config["bairros"]]
    limites = consultar("[out:json][timeout:90];way(id:%s);out geom;" % ",".join(ids))["elements"]

    lats = [p["lat"] for e in limites for p in e["geometry"]]
    lons = [p["lon"] for e in limites for p in e["geometry"]]
    margem = config["margem_download_m"] / 110540.0
    sul, norte = min(lats) - margem, max(lats) + margem
    oeste, leste = min(lons) - margem, max(lons) + margem
    bbox = "%.6f,%.6f,%.6f,%.6f" % (sul, oeste, norte, leste)

    filtros_marcos = []
    for m in config["marcos"]:
        filtro = '["%s"="%s"]' % (m["chave"], m["valor"]) if "valor" in m else '["%s"]' % m["chave"]
        filtros_marcos.append("nwr%s(%s);" % (filtro, bbox))
    consulta = "[out:json][timeout:180];(way[\"highway\"](%s);way[\"waterway\"](%s);%s);out geom;" % (
        bbox, bbox, "".join(filtros_marcos))
    elementos = consultar(consulta)["elements"]

    chaves = {"name", "highway", "waterway", "railway", "natural", "historic", "amenity", "tourism", "ele", "tunnel", "layer"}
    recorte = {
        "$comment": "Recorte bruto do OpenStreetMap para os bairros de tools/cidade/config.json. © colaboradores do OpenStreetMap, ODbL. Gerado por tools/cidade/baixar.py.",
        "caixa": [round(sul, 6), round(oeste, 6), round(norte, 6), round(leste, 6)],
        "limites": sorted([_enxugar(e, chaves) for e in limites], key=lambda e: e["id"]),
        "elementos": sorted([_enxugar(e, chaves) for e in elementos], key=lambda e: (e["type"], e["id"])),
    }
    destino = os.path.join(AQUI, "osm", "recorte.json")
    with open(destino, "w", encoding="utf-8", newline="\n") as f:
        json.dump(recorte, f, ensure_ascii=False, indent=0, separators=(",", ":"))
        f.write("\n")
    print("%d limites e %d elementos salvos em %s" % (len(recorte["limites"]), len(recorte["elementos"]), destino))


if __name__ == "__main__":
    main()
