"""Testes do relevo: o decodificador de PNG, a conta dos tiles e a grade de alturas."""
import math
import os
import struct
import sys
import unittest
import zlib

AQUI = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, AQUI)
import geometria as G  # noqa: E402
import importar  # noqa: E402
import relevo as R  # noqa: E402


def _png(largura, altura, linhas, filtros):
    """Monta um PNG RGB de 8 bits com o filtro pedido em cada linha (pixels já filtrados à mão)."""
    def bloco(tipo, corpo):
        return struct.pack(">I", len(corpo)) + tipo + corpo + struct.pack(">I", zlib.crc32(tipo + corpo) & 0xFFFFFFFF)
    bruto = b"".join(bytes([f]) + bytes(l) for f, l in zip(filtros, linhas))
    return (b"\x89PNG\r\n\x1a\n" + bloco(b"IHDR", struct.pack(">IIBBBBB", largura, altura, 8, 2, 0, 0, 0))
            + bloco(b"IDAT", zlib.compress(bruto)) + bloco(b"IEND", b""))


class TestPng(unittest.TestCase):
    def test_sem_filtro(self):
        dados = _png(2, 1, [[1, 2, 3, 4, 5, 6]], [0])
        self.assertEqual(R.ler_png(dados), (2, 1, 3, bytes([1, 2, 3, 4, 5, 6])))

    def test_filtros_sub_e_up(self):
        # Linha 1 com Sub: o segundo pixel guarda a diferença para o primeiro (10 + 5 = 15).
        # Linha 2 com Up: guarda a diferença para a linha de cima (10 + 1 = 11, 15 + 1 = 16).
        dados = _png(2, 2, [[10, 10, 10, 5, 5, 5], [1, 1, 1, 1, 1, 1]], [1, 2])
        _, _, _, pixels = R.ler_png(dados)
        self.assertEqual(list(pixels), [10, 10, 10, 15, 15, 15, 11, 11, 11, 16, 16, 16])

    def test_recusa_o_que_nao_e_png(self):
        with self.assertRaises(ValueError):
            R.ler_png(b"nada disso")


class TestTiles(unittest.TestCase):
    def test_tile_conhecido(self):
        # Ponto (0, 0) fica no canto do tile do meio do mundo.
        tx, ty, px, py = R.tile_de(0.0, 0.0, 1)
        self.assertEqual((tx, ty), (1, 1))
        self.assertAlmostEqual(px, 0.0)
        self.assertAlmostEqual(py, 0.0)

    def test_tiles_da_caixa_estao_todos_salvos(self):
        _, recorte = importar.carregar()
        for x, y in R.tiles_da_caixa(*recorte["caixa"]):
            self.assertTrue(os.path.exists(R.caminho_tile(x, y)), "falta o tile %d %d (rode baixar.py --so-relevo)" % (x, y))


class FalsoRelevo:
    """Um cone de 200 m de altura no ponto (lat0, lon0)."""
    def __init__(self, lat0, lon0):
        self.lat0, self.lon0 = lat0, lon0

    def altitude(self, lat, lon):
        return max(0.0, 200.0 - math.hypot(lat - self.lat0, lon - self.lon0) * 100000.0)


class TestGrade(unittest.TestCase):
    CONFIG, _ = importar.carregar()

    def test_grade_cobre_a_caixa_e_reduz_a_altura(self):
        caixa = (-50.0, -30.0, 50.0, 30.0)
        lat0, lon0 = G.desprojetar(0.0, 0.0, self.CONFIG["origem"], self.CONFIG["escala"])
        g = importar.grade_de_relevo(self.CONFIG, caixa, FalsoRelevo(lat0, lon0))
        passo = g["passo"]
        self.assertLessEqual(g["origem"][0], caixa[0])
        self.assertGreaterEqual(g["origem"][0] + (g["colunas"] - 1) * passo, caixa[2])
        self.assertGreaterEqual(g["origem"][1] + (g["linhas"] - 1) * passo, caixa[3])
        self.assertEqual(len(g["alturas"]), g["colunas"] * g["linhas"])
        self.assertAlmostEqual(max(g["alturas"]), 200.0 / self.CONFIG["relevo"]["escala_vertical"], delta=1.0)

    def test_desprojetar_volta_ao_ponto(self):
        lat, lon = G.desprojetar(120.0, -80.0, self.CONFIG["origem"], 3.0)
        x, z = G.projetar(lat, lon, self.CONFIG["origem"], 3.0)
        self.assertAlmostEqual(x, 120.0, places=6)
        self.assertAlmostEqual(z, -80.0, places=6)

    def test_monte_serrat_tem_o_pico_no_lugar_do_marco(self):
        b = importar.importar_todos(*importar.carregar())["monte_serrat"]
        g = b["relevo"]
        pico = [m for m in b["marcos"] if m["tipo"] == "natural=peak"][0]["posicao"]
        i = round((pico[0] - g["origem"][0]) / g["passo"])
        j = round((pico[1] - g["origem"][1]) / g["passo"])
        no_pico = g["alturas"][j * g["colunas"] + i]
        # 166 m no mapa; os dados de relevo suavizam o topo (~150 m). Na escala 1:2, ~75 m.
        self.assertGreater(no_pico, 140.0 / g["escala_vertical"])
        self.assertLess(no_pico, 175.0 / g["escala_vertical"])
        self.assertGreaterEqual(no_pico, max(g["alturas"]) - 3.0, "o pico é o ponto mais alto")


if __name__ == "__main__":
    unittest.main()
