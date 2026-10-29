#!/usr/bin/env python3
"""Gera a arte do jogo (paleta dessaturada estilo Project Zomboid), tiles HD 128x64.
Uso: python3 tools/gen_art.py   (determinístico: SEED fixo)
Saídas: art/tiles.png, art/player.png, art/solar_panel.png, art/vision_cone.png,
        /workspace/art_preview.png
"""
import math, os, random
from PIL import Image, ImageDraw, ImageFilter

SEED = 1993
S = 2                      # fator de escala em relação ao protótipo 64x32
TW, TH = 64 * S, 32 * S    # 128x64
HERE = os.path.dirname(os.path.abspath(__file__))
ART = os.path.join(HERE, "..", "art")

def hx(h, a=255):
    h = h.lstrip("#"); return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)

ASPHALT = [hx("3a3b3c"), hx("4a4b4c")]; CRACK = hx("2a2a2b")
SIDEWALK = [hx("8a877f"), hx("9e9a90")]; SW_SHADOW = hx("6e6b64")
GRASS = [hx("4f5a3a"), hx("5f6b45"), hx("3d4630")]; DIRT = hx("6b5a45")
LANE = hx("b8a35a"); OUTLINE = hx("1e1c1a")

def shade(c, f):
    return tuple(max(0, min(255, int(v * f))) for v in c[:3]) + (c[3],)

def mix(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3)) + (255,)

def inside(x, y):
    """Losango iso pixel-perfect TWxTH (2:1)."""
    return abs(x + 0.5 - TW / 2) / (TW / 2) + abs(y + 0.5 - TH / 2) / (TH / 2) <= 1.0

def edge_dist(x, y):
    return 1.0 - (abs(x + 0.5 - TW / 2) / (TW / 2) + abs(y + 0.5 - TH / 2) / (TH / 2))

def iso_uv(x, y):
    """Coordenadas (0..1) ao longo das duas diagonais 2:1 do losango."""
    a = (x + 0.5 - TW / 2) / (TW / 2); b = (y + 0.5) / (TH / 2)
    return (a + b) / 2, (b - a) / 2

def new_tile():
    return Image.new("RGBA", (TW, TH), (0, 0, 0, 0))

def put(img, x, y, c):
    if 0 <= x < TW and 0 <= y < TH and inside(x, y):
        img.putpixel((x, y), c)

def crack(img, rng, length, branch=True):
    """Rachadura de 1px serrilhada; em HD pode ramificar."""
    x, y = rng.randint(TW // 5, TW * 4 // 5), rng.randint(TH // 4, TH * 3 // 4)
    for i in range(length):
        put(img, x, y, CRACK)
        if rng.random() < 0.3: put(img, x, y + 1, shade(CRACK, 1.25))   # meia-sombra
        x += rng.choice([1, 1, 2, -1]); y += rng.choice([0, 1, -1, 0])
        if branch and i == length // 2 and rng.random() < 0.6:
            bx, by = x, y
            for _ in range(length // 3):
                put(img, bx, by, CRACK); bx += rng.choice([-1, 1]); by += rng.choice([1, 0])

def asphalt(rng, worn=0):
    img = new_tile()
    for y in range(TH):
        for x in range(TW):
            if not inside(x, y): continue
            c = mix(ASPHALT[0], ASPHALT[1], rng.random() * 0.6)
            c = shade(c, 1 + rng.uniform(-0.12, 0.12))           # ruído ~12%
            if (x // 3 + y // 2 + worn) % 7 == 0 and rng.random() < 0.15:
                c = shade(c, 0.9)                                  # textura granulada fina
            if edge_dist(x, y) < 0.04: c = shade(c, 0.9)
            img.putpixel((x, y), c)
    for _ in range(rng.randint(40, 80)):                         # cascalho (com brilho + sombra)
        x, y = rng.randrange(TW), rng.randrange(TH)
        put(img, x, y, shade(ASPHALT[1], rng.uniform(1.2, 1.4)))
        put(img, x, y + 1, shade(ASPHALT[0], 0.8))
    for _ in range(rng.randint(1, 2 + worn)):
        crack(img, rng, rng.randint(12, 32))
    if rng.random() < 0.7:                                       # mancha de óleo com borda
        cx, cy, r = rng.randint(TW // 3, TW * 2 // 3), rng.randint(TH // 3, TH * 2 // 3), rng.randint(5, 11)
        for y in range(cy - r, cy + r):
            for x in range(cx - 2 * r, cx + 2 * r):
                d = ((x - cx) / (2 * r)) ** 2 + ((y - cy) / r) ** 2
                if d < 1 and rng.random() > d * 0.5 and inside(x, y):
                    f = 0.68 + d * 0.22 + (0.05 if 0.75 < d < 0.85 else 0)
                    img.putpixel((x, y), shade(img.getpixel((x, y)), f))
    return img

def sidewalk(rng, slabs=2):
    img = new_tile()
    base = SIDEWALK[rng.randint(0, 1)]
    tint = [1 + rng.uniform(-0.05, 0.05) for _ in range(slabs * slabs)]   # cada placa um tom
    for y in range(TH):
        for x in range(TW):
            if not inside(x, y): continue
            u, v = iso_uv(x, y)
            si = min(slabs - 1, int(u * slabs)) * slabs + min(slabs - 1, int(v * slabs))
            c = shade(mix(base, SIDEWALK[1], rng.random() * 0.3), tint[si] + rng.uniform(-0.05, 0.05))
            ju, jv = (u * slabs) % 1.0, (v * slabs) % 1.0
            if ju < 0.025 or jv < 0.025:                           # junta entre placas
                c = SW_SHADOW
                if rng.random() < 0.3: c = rng.choice(GRASS + [DIRT])
            elif ju < 0.045 or jv < 0.045:
                c = shade(c, 1.06)                                 # aresta clara (bisel)
            elif ju > 0.955 or jv > 0.955:
                c = shade(c, 0.88)                                 # aresta escura
            if edge_dist(x, y) < 0.04: c = shade(c, 0.85)
            img.putpixel((x, y), c)
    for _ in range(rng.randint(30, 60)):                         # poros/manchas finas
        put(img, rng.randrange(TW), rng.randrange(TH), shade(base, rng.uniform(0.82, 0.92)))
    for _ in range(rng.randint(1, 4)):                           # tufos de mato
        x, y = rng.randint(TW // 5, TW * 4 // 5), rng.randint(TH // 5, TH * 4 // 5)
        for _ in range(rng.randint(4, 10)):
            gx, gy = x + rng.randint(-2, 2), y + rng.randint(-2, 1)
            put(img, gx, gy, rng.choice(GRASS)); put(img, gx, gy - 1, GRASS[1])  # folha em pé
    if rng.random() < 0.6: crack(img, rng, rng.randint(8, 18), branch=False)
    return img

def lane(rng, backslash):
    img = asphalt(rng)
    for t in range(0, 26 * S):                                   # faixa gasta 2:1
        if 9 * S <= t <= 13 * S: continue                        # falha no tracejado
        x = 19 * S + t
        y = 10 * S + t // 2 if backslash else 22 * S - t // 2
        for dy in range(3):
            if rng.random() < (0.55 if dy == 2 else 0.75):       # tinta gasta, borda irregular
                put(img, x, y + dy, shade(LANE, rng.uniform(0.78, 1.05)))
    return img

def gen_tiles(rng):
    atlas = Image.new("RGBA", (TW * 4, TH * 3), (0, 0, 0, 0))
    for i in range(4): atlas.paste(asphalt(rng, worn=i), (i * TW, 0))
    for i in range(4): atlas.paste(sidewalk(rng, slabs=2 if i < 2 else 3), (i * TW, TH))
    for i in range(4): atlas.paste(lane(rng, backslash=i < 2), (i * TW, TH * 2))
    return atlas

def outline(img):
    """Contorno escuro (não preto) de 1px em volta dos pixels opacos."""
    out = img.copy(); w, h = img.size; px = img.load(); po = out.load()
    for y in range(h):
        for x in range(w):
            if px[x, y][3] > 200: continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and px[nx, ny][3] > 200:
                    po[x, y] = OUTLINE; break
    return out

def gen_player():
    """Sobrevivente 48x96, pés em y≈88 (origem do nó)."""
    W, H = 48, 96
    body = Image.new("RGBA", (W, H), (0, 0, 0, 0)); d = ImageDraw.Draw(body)
    skin, skin_dk = hx("c9a58a"), hx("a8876f")
    jeans, jeans_dk = hx("556070"), hx("434c5a")
    jacket, jacket_dk, jacket_lt = hx("4a5236"), hx("3b4129"), hx("5a6344")
    bag, bag_dk, hair, boots = hx("6b5a45"), hx("54463a"), hx("4a3b2e"), hx("3a3430")
    # pernas com sombra interna e dobra no joelho
    d.rectangle([16, 62, 21, 84], fill=jeans); d.rectangle([26, 62, 31, 84], fill=jeans_dk)
    d.line([(16, 72), (21, 72)], fill=jeans_dk); d.line([(26, 73), (31, 73)], fill=shade(jeans_dk, 0.85))
    d.rectangle([14, 84, 21, 88], fill=boots); d.rectangle([26, 84, 33, 88], fill=shade(boots, 0.85))
    d.line([(14, 88), (21, 88)], fill=shade(boots, 0.7))
    # jaqueta: corpo, sombra lateral, zíper, bolsos, gola
    d.rectangle([14, 30, 33, 63], fill=jacket)
    d.rectangle([28, 30, 33, 63], fill=jacket_dk)
    d.line([(24, 32), (24, 61)], fill=jacket_dk)
    d.rectangle([16, 48, 21, 53], outline=jacket_dk); d.rectangle([26, 48, 31, 53], outline=hx("333824"))
    d.rectangle([17, 28, 30, 31], fill=jacket_lt)
    d.rectangle([14, 58, 33, 63], fill=jacket_dk)                # barra
    # mochila à esquerda com alça e fivela
    d.rectangle([5, 32, 13, 55], fill=bag); d.rectangle([5, 32, 7, 55], fill=bag_dk)
    d.line([(13, 31), (17, 44)], fill=bag_dk); d.point((9, 44), fill=hx("8a877f"))
    # braço direito e mão
    d.rectangle([34, 32, 39, 52], fill=jacket_dk); d.rectangle([34, 52, 39, 56], fill=skin)
    d.line([(34, 52), (39, 52)], fill=skin_dk)
    # cabeça: rosto, sombra, cabelo, olho, nariz, orelha, barba por fazer
    d.ellipse([14, 6, 33, 28], fill=skin)
    d.chord([14, 6, 33, 28], 60, 120, fill=skin_dk)
    d.rectangle([14, 5, 31, 12], fill=hair); d.rectangle([14, 12, 16, 17], fill=hair)
    d.point((28, 17), fill=hx("2e2a26")); d.point((29, 17), fill=hx("2e2a26"))
    d.line([(32, 18), (33, 20)], fill=skin_dk)
    d.point((18, 18), fill=skin_dk); d.point((19, 19), fill=skin_dk)
    for p in [(24, 24), (26, 25), (28, 24), (22, 25)]: d.point(p, fill=skin_dk)
    body = outline(body)
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    sh = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(sh).ellipse([6, 84, 41, 94], fill=hx("1e1c1a", 110))
    sh = sh.filter(ImageFilter.GaussianBlur(1))
    img.alpha_composite(sh); img.alpha_composite(body)
    return img

def gen_solar():
    W, H = 128, 112
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0)); d = ImageDraw.Draw(img)
    d.rectangle([60, 56, 66, 100], fill=hx("5a5853")); d.line([(60, 56), (60, 100)], fill=hx("6e6b64"))
    d.rectangle([54, 98, 72, 102], fill=hx("4a4b4c"))            # base
    top = [(64, 4), (124, 34), (64, 64), (4, 34)]
    d.polygon(top, fill=hx("2f3a4a"))
    for i in range(1, 6):                                        # grade de células fina
        t = i / 6
        d.line([(64 + 60 * t, 4 + 30 * t), (4 + 60 * t, 34 + 30 * t)], fill=hx("44505e"))
        d.line([(64 - 60 * t, 4 + 30 * t), (124 - 60 * t, 34 + 30 * t)], fill=hx("44505e"))
    d.polygon(top, outline=hx("8a877f"))
    d.line([(52, 16), (78, 29)], fill=hx("7a8794")); d.line([(56, 16), (80, 28)], fill=hx("5d6a78"))
    rng = random.Random(SEED + 7)
    for _ in range(14):                                          # poeira/folhas
        d.point((rng.randint(30, 98), rng.randint(20, 48)), fill=rng.choice([DIRT, GRASS[0]]))
    img = outline(img)
    sh = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(sh).ellipse([24, 90, 104, 110], fill=hx("1e1c1a", 90))
    out = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    out.alpha_composite(sh.filter(ImageFilter.GaussianBlur(2))); out.alpha_composite(img)
    return out

def gen_vision_cone(size=512, angle_deg=90.0):
    """Cone de visão p/ PointLight2D: centro = olhos, aponta para +X (direita).
    Queda gradual com a distância e bordas angulares suaves."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0)); px = img.load()
    c = size / 2; half = math.radians(angle_deg) / 2; soft = math.radians(14)
    for y in range(size):
        for x in range(size):
            dx, dy = x + 0.5 - c, y + 0.5 - c
            r = math.hypot(dx, dy) / c
            if r >= 1.0: continue
            a = abs(math.atan2(dy, dx))
            ang = 1.0 if a <= half - soft else max(0.0, (half - a) / soft) if a < half else 0.0
            ang = ang * ang * (3 - 2 * ang)                      # smoothstep
            fall = (1 - r) ** 1.4                                # queda com a distância
            near = max(0.0, 1 - r / 0.12)                        # brilho junto ao corpo
            v = max(ang * fall, near * 0.6)
            px[x, y] = (255, 255, 255, int(255 * min(1.0, v)))
    return img

def main():
    rng = random.Random(SEED)
    os.makedirs(ART, exist_ok=True)
    tiles, player, solar = gen_tiles(rng), gen_player(), gen_solar()
    cone = gen_vision_cone()
    tiles.save(os.path.join(ART, "tiles.png")); player.save(os.path.join(ART, "player.png"))
    solar.save(os.path.join(ART, "solar_panel.png")); cone.save(os.path.join(ART, "vision_cone.png"))
    pw = tiles.width + 16 + player.width + 16 + solar.width
    prev = Image.new("RGBA", (pw + 16, max(tiles.height, solar.height) + 16), hx("5a5853"))
    prev.alpha_composite(tiles, (8, 8)); prev.alpha_composite(player, (8 + tiles.width + 16, 8))
    prev.alpha_composite(solar, (8 + tiles.width + 16 + player.width + 16, 8))
    prev.resize((prev.width * 2, prev.height * 2), Image.NEAREST).save("/workspace/art_preview.png")
    print("ok:", tiles.size, player.size, solar.size, cone.size)

if __name__ == "__main__":
    main()
