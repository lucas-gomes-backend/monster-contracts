"""Geometria do importador da cidade, só com a biblioteca padrão.

Pontos são tuplas (x, z) em metros: x = leste, z = sul (como no Godot).
"""
import math

METROS_POR_GRAU_LAT = 110540.0
METROS_POR_GRAU_LON_EQUADOR = 111320.0


def projetar(lat, lon, origem, escala):
    """Lat/lon -> (x, z) em metros reduzidos pela escala, a partir da origem.

    Projeção equirretangular local: com poucos quilômetros, o erro é menor que um metro.
    """
    x = (lon - origem["lon"]) * METROS_POR_GRAU_LON_EQUADOR * math.cos(math.radians(origem["lat"]))
    z = -(lat - origem["lat"]) * METROS_POR_GRAU_LAT
    return (x / escala, z / escala)


def desprojetar(x, z, origem, escala):
    """(x, z) do jogo -> (lat, lon). Inverso de projetar."""
    lat = origem["lat"] - z * escala / METROS_POR_GRAU_LAT
    lon = origem["lon"] + x * escala / (METROS_POR_GRAU_LON_EQUADOR * math.cos(math.radians(origem["lat"])))
    return lat, lon


def _distancia_ao_segmento(p, a, b):
    ax, az = a
    bx, bz = b
    px, pz = p
    dx, dz = bx - ax, bz - az
    comprimento2 = dx * dx + dz * dz
    if comprimento2 == 0.0:
        return math.hypot(px - ax, pz - az)
    t = max(0.0, min(1.0, ((px - ax) * dx + (pz - az) * dz) / comprimento2))
    return math.hypot(px - (ax + t * dx), pz - (az + t * dz))


def simplificar(pontos, tolerancia):
    """Douglas-Peucker: tira pontos que se afastam menos que a tolerância da linha.

    O primeiro e o último ponto sempre ficam.
    """
    if len(pontos) <= 2:
        return list(pontos)
    maior, indice = 0.0, 0
    for i in range(1, len(pontos) - 1):
        d = _distancia_ao_segmento(pontos[i], pontos[0], pontos[-1])
        if d > maior:
            maior, indice = d, i
    if maior <= tolerancia:
        return [pontos[0], pontos[-1]]
    esquerda = simplificar(pontos[: indice + 1], tolerancia)
    direita = simplificar(pontos[indice:], tolerancia)
    return esquerda[:-1] + direita


def dentro(p, poligono):
    """O ponto está dentro do polígono? (regra par-ímpar; o polígono não precisa fechar)."""
    x, z = p
    resultado = False
    n = len(poligono)
    j = n - 1
    for i in range(n):
        xi, zi = poligono[i]
        xj, zj = poligono[j]
        if (zi > z) != (zj > z):
            corte = xi + (z - zi) * (xj - xi) / (zj - zi)
            if x < corte:
                resultado = not resultado
        j = i
    return resultado


def _cruzamento(a, b, c, d):
    """Parâmetro t em [0, 1] onde o segmento a-b cruza c-d, ou None."""
    rx, rz = b[0] - a[0], b[1] - a[1]
    sx, sz = d[0] - c[0], d[1] - c[1]
    den = rx * sz - rz * sx
    if abs(den) < 1e-12:
        return None
    t = ((c[0] - a[0]) * sz - (c[1] - a[1]) * sx) / den
    u = ((c[0] - a[0]) * rz - (c[1] - a[1]) * rx) / den
    if 0.0 <= t <= 1.0 and 0.0 <= u <= 1.0:
        return t
    return None


def recortar(linha, poligono):
    """Partes de uma linha que ficam dentro do polígono.

    Devolve (trechos, saidas): trechos são listas de pontos; saidas são os pontos onde a
    linha atravessa o limite (viram passagens para o bairro vizinho).
    """
    # Corta a linha em todos os cruzamentos com o limite e decide pelo ponto médio de cada
    # pedaço. Não conta "entrou/saiu": uma rua que passa por um vértice do limite cruza duas
    # arestas no mesmo ponto, e contar inverteria dentro e fora.
    n = len(poligono)
    pontos = [linha[0]]
    for i in range(len(linha) - 1):
        a, b = linha[i], linha[i + 1]
        cortes = set()
        for j in range(n):
            t = _cruzamento(a, b, poligono[j], poligono[(j + 1) % n])
            if t is not None and 1e-9 < t < 1.0 - 1e-9:
                cortes.add(round(t, 9))
        for t in sorted(cortes):
            pontos.append((a[0] + t * (b[0] - a[0]), a[1] + t * (b[1] - a[1])))
        pontos.append(b)

    trechos, saidas = [], []
    atual = []
    dentro_antes = None
    for i in range(len(pontos) - 1):
        p, q = pontos[i], pontos[i + 1]
        if p == q:
            continue
        meio = ((p[0] + q[0]) / 2.0, (p[1] + q[1]) / 2.0)
        esta_dentro = dentro(meio, poligono)
        if dentro_antes is not None and esta_dentro != dentro_antes:
            saidas.append(p)
        if esta_dentro:
            if not atual:
                atual = [p]
            atual.append(q)
        elif atual:
            trechos.append(atual)
            atual = []
        dentro_antes = esta_dentro
    if atual:
        trechos.append(atual)
    return [t for t in trechos if len(t) >= 2 and comprimento(t) > 0.01], saidas


def comprimento(linha):
    return sum(math.hypot(linha[i + 1][0] - linha[i][0], linha[i + 1][1] - linha[i][1]) for i in range(len(linha) - 1))


def caixa(pontos):
    """(min_x, min_z, max_x, max_z) dos pontos."""
    xs = [p[0] for p in pontos]
    zs = [p[1] for p in pontos]
    return (min(xs), min(zs), max(xs), max(zs))
