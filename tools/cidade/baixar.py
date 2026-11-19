"""Baixa do OpenStreetMap (API Overpass) o recorte bruto dos bairros do config.json.

Uso (na raiz do repositório):  python tools/cidade/baixar.py
                               python tools/cidade/baixar.py --mapa-geral   # só os contornos de todas as regiões
Grava tools/cidade/osm/recorte.json. Rodar só quando quiser atualizar os dados: o
importador (importar.py) lê o arquivo salvo, sem rede, e sempre dá o mesmo resultado.
Dados © colaboradores do OpenStreetMap, licença ODbL (ver osm/LICENCA.md).
"""
import json
import os
import sys
import time
import urllib.parse
import urllib.request

AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, AQUI)
import geometria as G  # noqa: E402
SERVIDORES = [
    "https://overpass-api.de/api/interpreter",
    "https://overpass.kumi.systems/api/interpreter",
]
PEDACOS = 5
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


def _anel_da_relacao(e):
    trechos = [[(p["lat"], p["lon"]) for p in m["geometry"]] for m in e["members"]
               if m["type"] == "way" and m.get("role") == "outer" and "geometry" in m]
    return G.juntar_anel(trechos)


def baixar_mapa_geral(config):
    """Contornos de todas as regiões administrativas do município (osm/mapa_geral.json)."""
    mg = config["mapa_geral"]
    consulta = ('[out:json][timeout:120];area["name"="%s"]["admin_level"="8"]["boundary"="administrative"]->.m;'
                'relation(area.m)["boundary"="administrative"]["admin_level"="%s"];out geom;') % (mg["municipio"], mg["admin_level"])
    regioes = []
    for e in consultar(consulta)["elements"]:
        anel = _anel_da_relacao(e)
        if len(anel) < 3:
            continue
        regioes.append({"type": "relation", "id": e["id"], "tags": {"name": e.get("tags", {}).get("name", "")},
                        "geometry": [[round(lat, 7), round(lon, 7)] for lat, lon in anel]})
    saida = {
        "$comment": "Contornos das regiões de %s no OpenStreetMap (admin_level %s). © colaboradores do OpenStreetMap, ODbL. Gerado por tools/cidade/baixar.py --mapa-geral." % (mg["municipio"], mg["admin_level"]),
        "regioes": sorted(regioes, key=lambda r: r["id"]),
    }
    destino = os.path.join(AQUI, "osm", "mapa_geral.json")
    with open(destino, "w", encoding="utf-8", newline="\n") as f:
        json.dump(saida, f, ensure_ascii=False, indent=0, separators=(",", ":"))
        f.write("\n")
    print("%d regiões salvas em %s" % (len(regioes), destino))


def main():
    with open(os.path.join(AQUI, "config.json"), encoding="utf-8") as f:
        config = json.load(f)
    if "--mapa-geral" in sys.argv:
        baixar_mapa_geral(config)
        return
    # Limite de bairro: um caminho fechado (way) ou uma relação, cujos trechos "outer"
    # são juntados num anel e gravados como se fossem um caminho só.
    # Bairros sem limite no OSM trazem um "limite_manual" (lat, lon): só entram na caixa.
    vias = [b["limite_osm"].split("/")[1] for b in config["bairros"] if b.get("limite_osm", "").startswith("way/")]
    relacoes = [b["limite_osm"].split("/")[1] for b in config["bairros"] if b.get("limite_osm", "").startswith("relation/")]
    consulta = "[out:json][timeout:90];("
    if vias:
        consulta += "way(id:%s);" % ",".join(vias)
    if relacoes:
        consulta += "relation(id:%s);" % ",".join(relacoes)
    limites = []
    for e in consultar(consulta + ");out geom;")["elements"]:
        if e["type"] == "relation":
            trechos = [[(p["lat"], p["lon"]) for p in m["geometry"]] for m in e["members"]
                       if m["type"] == "way" and m.get("role") == "outer" and "geometry" in m]
            anel = G.juntar_anel(trechos)
            e = {"type": "relation", "id": e["id"], "tags": e.get("tags", {}),
                 "geometry": [{"lat": lat, "lon": lon} for lat, lon in anel]}
        limites.append(e)

    lats = [p["lat"] for e in limites for p in e["geometry"]] + [p[0] for b in config["bairros"] for p in b.get("limite_manual", [])]
    lons = [p["lon"] for e in limites for p in e["geometry"]] + [p[1] for b in config["bairros"] for p in b.get("limite_manual", [])]
    margem = config["margem_download_m"] / 110540.0
    sul, norte = min(lats) - margem, max(lats) + margem
    oeste, leste = min(lons) - margem, max(lons) + margem

    # A caixa da cidade inteira é pesada demais para o Overpass de uma vez: baixa em
    # pedaços (PEDACOS x PEDACOS) e junta, sem repetir o que cai em dois pedaços.
    vistos = {}
    for i in range(PEDACOS):
        for j in range(PEDACOS):
            s_ = sul + (norte - sul) * i / PEDACOS
            n_ = sul + (norte - sul) * (i + 1) / PEDACOS
            o_ = oeste + (leste - oeste) * j / PEDACOS
            l_ = oeste + (leste - oeste) * (j + 1) / PEDACOS
            caixa = "%.6f,%.6f,%.6f,%.6f" % (s_, o_, n_, l_)
            filtros_marcos = []
            for m in config["marcos"]:
                filtro = '["%s"="%s"]' % (m["chave"], m["valor"]) if "valor" in m else '["%s"]' % m["chave"]
                filtros_marcos.append("nwr%s(%s);" % (filtro, caixa))
            consulta = "[out:json][timeout:180];(way[\"highway\"](%s);way[\"waterway\"](%s);%s);out geom;" % (
                caixa, caixa, "".join(filtros_marcos))
            for e in consultar(consulta)["elements"]:
                vistos[(e["type"], e["id"])] = e
            print("pedaço %d/%d" % (i * PEDACOS + j + 1, PEDACOS * PEDACOS), flush=True)
    elementos = list(vistos.values())

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
