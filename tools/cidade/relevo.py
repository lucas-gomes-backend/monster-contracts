"""Relevo a partir dos "terrain tiles" públicos (formato Terrarium), só com a biblioteca padrão.

Cada tile é um PNG 256x256 em que a cor guarda a altitude:
    altitude (m) = R * 256 + G + B / 256 - 32768
Os tiles ficam versionados em tools/cidade/relevo/ (baixados por baixar.py).
"""
import math
import os
import struct
import zlib

ZOOM = 15
TAMANHO_TILE = 256
URL = "https://s3.amazonaws.com/elevation-tiles-prod/terrarium/{z}/{x}/{y}.png"
PASTA = os.path.join(os.path.dirname(os.path.abspath(__file__)), "relevo")


def ler_png(dados):
    """Decodifica um PNG de 8 bits RGB ou RGBA, sem entrelaçamento.

    Devolve (largura, altura, canais, pixels) com pixels como bytes linha a linha.
    """
    if dados[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError("não é PNG")
    pos, idat = 8, b""
    largura = altura = canais = None
    while pos < len(dados):
        tamanho, tipo = struct.unpack(">I4s", dados[pos:pos + 8])
        corpo = dados[pos + 8:pos + 8 + tamanho]
        pos += 12 + tamanho
        if tipo == b"IHDR":
            largura, altura, bits, cor, _, _, entrelacado = struct.unpack(">IIBBBBB", corpo)
            if bits != 8 or cor not in (2, 6) or entrelacado:
                raise ValueError("PNG não suportado (bits %d, cor %d)" % (bits, cor))
            canais = 3 if cor == 2 else 4
        elif tipo == b"IDAT":
            idat += corpo
        elif tipo == b"IEND":
            break
    bruto = zlib.decompress(idat)
    passo = largura * canais
    saida = bytearray(passo * altura)
    anterior = bytearray(passo)
    i = 0
    for linha in range(altura):
        filtro = bruto[i]
        atual = bytearray(bruto[i + 1:i + 1 + passo])
        i += 1 + passo
        for x in range(passo):
            a = atual[x - canais] if x >= canais else 0
            b = anterior[x]
            c = anterior[x - canais] if x >= canais else 0
            if filtro == 1:
                atual[x] = (atual[x] + a) & 0xFF
            elif filtro == 2:
                atual[x] = (atual[x] + b) & 0xFF
            elif filtro == 3:
                atual[x] = (atual[x] + (a + b) // 2) & 0xFF
            elif filtro == 4:
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                preditor = a if pa <= pb and pa <= pc else (b if pb <= pc else c)
                atual[x] = (atual[x] + preditor) & 0xFF
        saida[linha * passo:(linha + 1) * passo] = atual
        anterior = atual
    return largura, altura, canais, bytes(saida)


def tile_de(lat, lon, zoom=ZOOM):
    """(x, y) do tile e posição (px, py) em pixels dentro dele, com fração."""
    n = 2 ** zoom
    x = (lon + 180.0) / 360.0 * n
    lat_r = math.radians(lat)
    y = (1.0 - math.log(math.tan(lat_r) + 1.0 / math.cos(lat_r)) / math.pi) / 2.0 * n
    tx, ty = int(math.floor(x)), int(math.floor(y))
    return tx, ty, (x - tx) * TAMANHO_TILE, (y - ty) * TAMANHO_TILE


def tiles_da_caixa(sul, oeste, norte, leste, zoom=ZOOM):
    """Tiles que cobrem a caixa (lat/lon), em ordem."""
    x0, y0, _, _ = tile_de(norte, oeste, zoom)
    x1, y1, _, _ = tile_de(sul, leste, zoom)
    return [(x, y) for y in range(y0, y1 + 1) for x in range(x0, x1 + 1)]


def caminho_tile(x, y, zoom=ZOOM):
    return os.path.join(PASTA, "%d_%d_%d.png" % (zoom, x, y))


class Relevo:
    """Altitude em metros reais (nível do mar = 0) a partir dos tiles salvos."""

    def __init__(self, pasta=PASTA, zoom=ZOOM):
        self.pasta = pasta
        self.zoom = zoom
        self._tiles = {}

    def _alturas(self, tx, ty):
        if (tx, ty) not in self._tiles:
            caminho = os.path.join(self.pasta, "%d_%d_%d.png" % (self.zoom, tx, ty))
            with open(caminho, "rb") as f:
                largura, altura, canais, pixels = ler_png(f.read())
            grade = []
            for i in range(largura * altura):
                r, g, b = pixels[i * canais], pixels[i * canais + 1], pixels[i * canais + 2]
                grade.append(r * 256 + g + b / 256.0 - 32768.0)
            self._tiles[(tx, ty)] = (largura, grade)
        return self._tiles[(tx, ty)]

    def _pixel(self, tx, ty, px, py):
        # Um pixel pode cair no tile vizinho (borda da interpolação).
        while px < 0:
            tx, px = tx - 1, px + TAMANHO_TILE
        while px >= TAMANHO_TILE:
            tx, px = tx + 1, px - TAMANHO_TILE
        while py < 0:
            ty, py = ty - 1, py + TAMANHO_TILE
        while py >= TAMANHO_TILE:
            ty, py = ty + 1, py - TAMANHO_TILE
        largura, grade = self._alturas(tx, ty)
        return grade[py * largura + px]

    def altitude(self, lat, lon):
        """Interpolação bilinear entre os 4 pixels mais próximos."""
        tx, ty, px, py = tile_de(lat, lon, self.zoom)
        px -= 0.5
        py -= 0.5
        x0, y0 = int(math.floor(px)), int(math.floor(py))
        fx, fy = px - x0, py - y0
        h00 = self._pixel(tx, ty, x0, y0)
        h10 = self._pixel(tx, ty, x0 + 1, y0)
        h01 = self._pixel(tx, ty, x0, y0 + 1)
        h11 = self._pixel(tx, ty, x0 + 1, y0 + 1)
        return (h00 * (1 - fx) + h10 * fx) * (1 - fy) + (h01 * (1 - fx) + h11 * fx) * fy
