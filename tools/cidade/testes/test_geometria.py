"""Testes da geometria do importador (projeção, simplificação, dentro/fora, recorte)."""
import math
import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import geometria as G  # noqa: E402

ORIGEM = {"lat": -23.9340, "lon": -46.3290}
QUADRADO = [(0.0, 0.0), (10.0, 0.0), (10.0, 10.0), (0.0, 10.0)]


class TestProjecao(unittest.TestCase):
    def test_origem_vira_zero(self):
        x, z = G.projetar(ORIGEM["lat"], ORIGEM["lon"], ORIGEM, 3.0)
        self.assertAlmostEqual(x, 0.0)
        self.assertAlmostEqual(z, 0.0)

    def test_escala_1_para_3_e_eixos_do_godot(self):
        # 0,01 grau para o norte ~ 1105 m reais -> ~368 m no jogo, com z negativo (norte = -z).
        _, z = G.projetar(ORIGEM["lat"] + 0.01, ORIGEM["lon"], ORIGEM, 3.0)
        self.assertAlmostEqual(z, -1105.4 / 3.0, delta=0.5)
        x, _ = G.projetar(ORIGEM["lat"], ORIGEM["lon"] + 0.01, ORIGEM, 3.0)
        self.assertGreater(x, 0.0, "leste é +x")
        self.assertAlmostEqual(x, 1113.2 * math.cos(math.radians(ORIGEM["lat"])) / 3.0, delta=0.5)


class TestSimplificar(unittest.TestCase):
    def test_tira_pontos_quase_alinhados_e_mantem_as_pontas(self):
        linha = [(0, 0), (5, 0.1), (10, 0)]
        self.assertEqual(G.simplificar(linha, 0.5), [(0, 0), (10, 0)])

    def test_mantem_curva_maior_que_a_tolerancia(self):
        linha = [(0, 0), (5, 3), (10, 0)]
        self.assertEqual(G.simplificar(linha, 0.5), linha)


class TestDentro(unittest.TestCase):
    def test_dentro_e_fora(self):
        self.assertTrue(G.dentro((5, 5), QUADRADO))
        self.assertFalse(G.dentro((15, 5), QUADRADO))
        self.assertFalse(G.dentro((5, -1), QUADRADO))


class TestJuntarAnel(unittest.TestCase):
    def test_junta_trechos_em_qualquer_sentido(self):
        # Um quadrado em três pedaços, um deles ao contrário.
        trechos = [[(0, 0), (1, 0)], [(1, 1), (1, 0)], [(1, 1), (0, 1), (0, 0)]]
        anel = G.juntar_anel(trechos)
        self.assertEqual(anel[0], anel[-1])
        self.assertEqual(sorted(set(anel)), [(0, 0), (0, 1), (1, 0), (1, 1)])

    def test_fica_com_o_maior_anel(self):
        grande = [[(0, 0), (10, 0), (10, 10), (0, 10), (0, 0)]]
        ilhota = [[(20, 20), (21, 20), (21, 21), (20, 20)]]
        self.assertEqual(len(G.juntar_anel(ilhota + grande)), 5)

    def test_trechos_que_nao_fecham_dao_erro(self):
        with self.assertRaises(ValueError):
            G.juntar_anel([[(0, 0), (1, 0)], [(5, 5), (6, 6)]])


class TestRecortar(unittest.TestCase):
    def test_linha_que_atravessa_fica_so_com_a_parte_de_dentro_e_duas_saidas(self):
        trechos, saidas = G.recortar([(-5, 5), (15, 5)], QUADRADO)
        self.assertEqual(len(trechos), 1)
        self.assertAlmostEqual(G.comprimento(trechos[0]), 10.0)
        self.assertEqual(sorted(round(p[0], 6) for p in saidas), [0.0, 10.0])

    def test_linha_toda_dentro_fica_inteira_e_sem_saidas(self):
        trechos, saidas = G.recortar([(2, 2), (8, 8)], QUADRADO)
        self.assertEqual(trechos, [[(2, 2), (8, 8)]])
        self.assertEqual(saidas, [])

    def test_linha_toda_fora_some(self):
        trechos, saidas = G.recortar([(20, 20), (30, 30)], QUADRADO)
        self.assertEqual(trechos, [])
        self.assertEqual(saidas, [])

    def test_linha_que_passa_por_um_vertice_nao_inverte_dentro_e_fora(self):
        # Entra pelo canto (0, 0), que é vértice de duas arestas, e sai pelo lado direito.
        losango = [(0, 0), (10, -10), (20, 0), (10, 10)]
        trechos, _ = G.recortar([(-10, 0), (0, 0), (30, 0)], losango)
        self.assertEqual(len(trechos), 1)
        self.assertAlmostEqual(G.comprimento(trechos[0]), 20.0)
        for p in trechos[0]:
            self.assertTrue(-1e-6 <= p[0] <= 20.0 + 1e-6, "nada de fora do losango: %s" % (p,))

    def test_linha_que_entra_sai_e_entra_vira_dois_trechos(self):
        u = [(0, 0), (10, 0), (10, 10), (6, 10), (6, 3), (4, 3), (4, 10), (0, 10)]
        trechos, saidas = G.recortar([(-1, 6), (11, 6)], u)
        self.assertEqual(len(trechos), 2)
        self.assertEqual(len(saidas), 4)


if __name__ == "__main__":
    unittest.main()
