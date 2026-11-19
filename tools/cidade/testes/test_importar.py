"""Testes do importador com o recorte real versionado (tools/cidade/osm/recorte.json)."""
import os
import sys
import unittest

AQUI = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, AQUI)
import geometria as G  # noqa: E402
import importar  # noqa: E402

CONFIG, RECORTE = importar.carregar()
BAIRROS = importar.importar_todos(CONFIG, RECORTE)
TOLERANCIA = 0.6


def _distancia_ao_limite(p, limite):
    return importar._distancia_ao_limite(tuple(p), [tuple(q) for q in limite])


class TestImportar(unittest.TestCase):
    def test_todos_os_bairros_do_config_foram_importados(self):
        self.assertEqual(sorted(BAIRROS), sorted(b["id"] for b in CONFIG["bairros"]))

    def test_area_reduzida_pela_escala(self):
        # Um bairro médio fica com ~280 m de lado no jogo (docs/07): dezenas de milhares de m².
        # Os maiores (Ponta da Praia, ~205 mil m²) passam um pouco de 200 mil.
        for bid, b in BAIRROS.items():
            self.assertGreater(b["area_m2"], 10000, bid)
            self.assertLess(b["area_m2"], 250000, bid)

    def test_toda_rua_fica_dentro_do_limite(self):
        for bid, b in BAIRROS.items():
            limite = [tuple(p) for p in b["limite"]]
            self.assertGreater(len(b["ruas"]), 0, bid)
            for rua in b["ruas"]:
                for p in rua["pontos"]:
                    ok = G.dentro(tuple(p), limite) or _distancia_ao_limite(p, limite) <= importar.PERTO_DO_VIZINHO
                    self.assertTrue(ok, "%s: rua %s sai do bairro em %s" % (bid, rua["nome"], p))
                self.assertGreater(rua["largura"], 0)

    def test_toda_saida_fica_no_limite(self):
        for bid, b in BAIRROS.items():
            self.assertGreater(len(b["saidas"]), 0, "%s precisa ligar com algum vizinho" % bid)
            for s in b["saidas"]:
                # O limite gravado é simplificado; a saída foi calculada no limite original.
                self.assertLess(_distancia_ao_limite(s["posicao"], b["limite"]), CONFIG["tolerancia_simplificacao"] + TOLERANCIA, bid)

    def test_monte_serrat_tem_o_pico_com_altitude_e_o_bondinho(self):
        marcos = BAIRROS["monte_serrat"]["marcos"]
        picos = [m for m in marcos if m["tipo"] == "natural=peak"]
        self.assertEqual(len(picos), 1)
        self.assertEqual(picos[0]["altitude"], 166.0)
        self.assertTrue(any(m["tipo"] == "railway=funicular" for m in marcos), "o bondinho")

    def test_limite_manual_vale_no_lugar_do_osm(self):
        # O Porto não tem limite no OpenStreetMap: o traçado à mão (lat, lon) vira o limite.
        porto = next(b for b in CONFIG["bairros"] if b["id"] == "porto")
        self.assertNotIn("limite_osm", porto)
        esperado = [G.projetar(lat, lon, CONFIG["origem"], CONFIG["escala"]) for lat, lon in porto["limite_manual"]]
        self.assertEqual(importar._limite(RECORTE, porto, CONFIG), esperado)
        self.assertGreater(len(BAIRROS["porto"]["ruas"]), 0, "o cais tem ruas")

    def test_ruas_so_dos_tipos_do_config(self):
        for b in BAIRROS.values():
            for rua in b["ruas"]:
                self.assertIn(rua["tipo"], CONFIG["ruas"])

    def test_mesmo_recorte_da_o_mesmo_resultado_e_os_arquivos_estao_em_dia(self):
        de_novo = importar.importar_todos(CONFIG, RECORTE)
        self.assertEqual(importar.texto(de_novo["valongo"]), importar.texto(BAIRROS["valongo"]))
        self.assertEqual(importar.main(["--conferir"]), 0, "rode python tools/cidade/importar.py")


if __name__ == "__main__":
    unittest.main()


class TestMapaGeral(unittest.TestCase):
    def test_slug_tira_acento_e_espaco(self):
        self.assertEqual(importar.slug("José Menino"), "jose_menino")
        self.assertEqual(importar.slug("Boqueirão"), "boqueirao")

    def test_bairros_do_config_usam_o_proprio_id_e_as_outras_regioes_o_nome(self):
        mapa = {"regioes": [
            {"type": "relation", "id": 1, "tags": {"name": "Areia Branca"},
             "geometry": [[-23.97, -46.33], [-23.97, -46.32], [-23.96, -46.32], [-23.96, -46.33], [-23.97, -46.33]]},
            {"type": "relation", "id": 18922323, "tags": {"name": "Centro"}, "geometry": [[-23.93, -46.33], [-23.93, -46.32], [-23.92, -46.32]]},
        ]}
        geral = importar.importar_mapa_geral(CONFIG, RECORTE, mapa)
        ids = [r["id"] for r in geral["regioes"]]
        self.assertIn("areia_branca", ids)
        for b in CONFIG["bairros"]:
            self.assertIn(b["id"], ids)
        self.assertEqual(ids, sorted(ids))
        areia = [r for r in geral["regioes"] if r["id"] == "areia_branca"][0]
        self.assertEqual(len(areia["limite"]), 4, "sem repetir o primeiro ponto")
        centro = [r for r in geral["regioes"] if r["id"] == "centro"][0]
        self.assertEqual(centro["nome"], "Centro")
        self.assertGreater(len(centro["limite"]), 3, "o Centro usa o limite do recorte, não o da lista")
