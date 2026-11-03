"""Generate original forever currency artwork; no client/system textures.

Both SVG and TGA use the same geometry and palettes. Standard library only.
Atlas: 128 x 32 RGBA; gold, silver, copper, transparent (32px cells).
"""
from pathlib import Path
import math
import struct

ROOT = Path(__file__).resolve().parent
SCALE = 4
PALETTES = [
    ("gold", "#ffec99", "#d0a024", "#704609", "#342009", "#fff7c4"),
    ("silver", "#f4ffff", "#a1b9c3", "#536772", "#263942", "#ffffff"),
    ("copper", "#ffcb8b", "#be743b", "#753b1e", "#3d2014", "#ffe4b9"),
]
CX, CY, RX, RY = 16.0, 15.5, 11.6, 14.1
RIDGES = 30
GLYPH = [(18.7, 8.9), (14.7, 8.5), (12.5, 10.9), (13.3, 13.0),
         (18.0, 15.3), (18.8, 17.3), (16.7, 20.7), (13.0, 22.0)]
DIAMOND = [(17.4, 11.2), (19.2, 12.6), (17.9, 14.3), (16.5, 12.8)]


def rgb(value):
    return tuple(int(value[i:i+2], 16) for i in (1, 3, 5))


def vertices():
    points = []
    for i in range(RIDGES * 2):
        a = -math.pi / 2 + i * math.pi / RIDGES
        radius = 1 if i % 2 == 0 else .967
        points.append((CX + RX * radius * math.cos(a), CY + RY * radius * math.sin(a)))
    return points


def line_points(points):
    return " ".join(f"{x:.3f},{y:.3f}" for x, y in points)


def ridge_lines():
    for i in range(RIDGES):
        a = -math.pi / 2 + i * 2 * math.pi / RIDGES
        start = (CX + RX * .93 * math.cos(a), CY + RY * .93 * math.sin(a))
        end = (CX + RX * .995 * math.cos(a), CY + RY * .995 * math.sin(a))
        yield start, end, math.cos(a) + math.sin(a) < -.25


def make_svg():
    defs, coins = [], []
    for index, (name, light, mid, dark, deepest, shine) in enumerate(PALETTES):
        defs.append(f'<linearGradient id="{name}-rim" x1="0" y1="0" x2="1" y2="1"><stop stop-color="{light}"/><stop offset=".46" stop-color="{mid}"/><stop offset="1" stop-color="{dark}"/></linearGradient>')
        defs.append(f'<linearGradient id="{name}-face" x1="0" y1="0" x2="1" y2="1"><stop stop-color="{mid}"/><stop offset=".4" stop-color="{light}"/><stop offset="1" stop-color="{dark}"/></linearGradient>')
        details = []
        for start, end, highlight in ridge_lines():
            color = shine if highlight else dark
            details.append(f'<line x1="{start[0]:.3f}" y1="{start[1]:.3f}" x2="{end[0]:.3f}" y2="{end[1]:.3f}" stroke="{color}" stroke-width=".5" opacity=".8"/>')
        coins.append(f'''<g transform="translate({index * 32} 0) rotate(-12 16 16)">
  <ellipse cx="16.5" cy="16.2" rx="11.7" ry="14.1" fill="{deepest}" opacity=".8"/>
  <polygon points="{line_points(vertices())}" fill="url(#{name}-rim)" stroke="{deepest}" stroke-width=".6"/>
  {''.join(details)}
  <ellipse cx="16" cy="15.5" rx="10.2" ry="12.6" fill="none" stroke="{shine}" stroke-width=".6" opacity=".8"/>
  <ellipse cx="16.1" cy="15.7" rx="8.7" ry="11" fill="url(#{name}-face)" stroke="{dark}" stroke-width=".65"/>
  <ellipse cx="15.9" cy="15.3" rx="8.1" ry="10.4" fill="none" stroke="{shine}" stroke-width=".45" opacity=".7"/>
  <polyline points="{line_points(GLYPH)}" fill="none" stroke="{dark}" stroke-width="1.6" stroke-linejoin="round" stroke-linecap="round" transform="translate(.35 .45)"/>
  <polyline points="{line_points(GLYPH)}" fill="none" stroke="{shine}" stroke-width="1.05" stroke-linejoin="round" stroke-linecap="round" opacity=".86"/>
  <polygon points="{line_points(DIAMOND)}" fill="{mid}" stroke="{dark}" stroke-width=".55"/>
  <path d="M10.9 17 L11.1 19 M20.1 10.5 L20.4 12.3" fill="none" stroke="{shine}" stroke-width=".6" opacity=".75"/>
</g>''')
    return '<?xml version="1.0" encoding="UTF-8"?>\n<svg xmlns="http://www.w3.org/2000/svg" width="128" height="32" viewBox="0 0 128 32">\n<title>forever original gold, silver and copper coins</title>\n<defs>' + ''.join(defs) + '</defs>\n' + '\n'.join(coins) + '\n</svg>\n'


def inside_polygon(x, y, points):
    inside = False
    previous = points[-1]
    for current in points:
        ax, ay = previous
        bx, by = current
        if (ay > y) != (by > y) and x < (bx-ax)*(y-ay)/(by-ay)+ax:
            inside = not inside
        previous = current
    return inside


def segment_distance(x, y, a, b):
    vx, vy = b[0]-a[0], b[1]-a[1]
    t = max(0, min(1, ((x-a[0])*vx+(y-a[1])*vy)/(vx*vx+vy*vy)))
    return math.hypot(x-a[0]-t*vx, y-a[1]-t*vy)


def ellipse(x, y, cx, cy, rx, ry):
    return ((x-cx)/rx)**2 + ((y-cy)/ry)**2


def blend(base, color, alpha=1):
    old_alpha = base[3] / 255
    out_alpha = alpha + old_alpha*(1-alpha)
    if out_alpha == 0:
        return (0,0,0,0)
    return tuple((color[i]*alpha+base[i]*old_alpha*(1-alpha))/out_alpha for i in range(3)) + (out_alpha*255,)


def gradient(x, y, colors, stops):
    t = max(0,min(1,(x+y-7)/45))
    j = next((i for i in range(len(stops)-1) if t <= stops[i+1]),len(stops)-2)
    a = (t-stops[j])/(stops[j+1]-stops[j])
    return tuple(colors[j][k]*(1-a)+colors[j+1][k]*a for k in range(3))


def draw_coin(palette):
    name, light, mid, dark, deepest, shine = palette
    light,mid,dark,deepest,shine = map(rgb,(light,mid,dark,deepest,shine))
    polygon = vertices()
    inner_polygon = [(CX+(x-CX)*.976,CY+(y-CY)*.98) for x,y in polygon]
    ridges = list(ridge_lines())
    shadow_glyph = [(x+.35,y+.45) for x,y in GLYPH]
    c,s = math.cos(math.radians(12)),math.sin(math.radians(12))
    result = []
    for oy in range(32):
        for ox in range(32):
            samples=[]
            for sy in range(SCALE):
                for sx in range(SCALE):
                    u,v = ox+(sx+.5)/SCALE-16,oy+(sy+.5)/SCALE-16
                    x,y = 16+c*u-s*v,16+s*u+c*v
                    pixel=(0,0,0,0)
                    if ellipse(x,y,16.5,16.2,11.7,14.1) <= 1:
                        pixel=blend(pixel,deepest,.8)
                    if inside_polygon(x,y,polygon):
                        pixel=blend(pixel,gradient(x,y,[light,mid,dark],[0,.46,1]))
                        if not inside_polygon(x,y,inner_polygon):
                            pixel=blend(pixel,deepest)
                        for a,b,highlight in ridges:
                            if segment_distance(x,y,a,b) <= .25:
                                pixel=blend(pixel,shine if highlight else dark,.8)
                        ring=ellipse(x,y,16,15.5,10.2,12.6)
                        if .95 <= ring <= 1.05:
                            pixel=blend(pixel,shine,.8)
                        face=ellipse(x,y,16.1,15.7,8.7,11)
                        if face <= 1.04:
                            pixel=blend(pixel,dark)
                            if face < .94:
                                pixel=blend(pixel,gradient(x,y,[mid,light,dark],[0,.4,1]))
                        ring=ellipse(x,y,15.9,15.3,8.1,10.4)
                        if .955 <= ring <= 1.045:
                            pixel=blend(pixel,shine,.7)
                        if min(segment_distance(x,y,a,b) for a,b in zip(shadow_glyph,shadow_glyph[1:])) <= .8:
                            pixel=blend(pixel,dark)
                        if min(segment_distance(x,y,a,b) for a,b in zip(GLYPH,GLYPH[1:])) <= .525:
                            pixel=blend(pixel,shine,.86)
                        if inside_polygon(x,y,DIAMOND):
                            pixel=blend(pixel,mid)
                        if min(segment_distance(x,y,a,b) for a,b in zip(DIAMOND,DIAMOND[1:]+DIAMOND[:1])) <= .275:
                            pixel=blend(pixel,dark)
                        for a,b in [[(10.9,17),(11.1,19)],[(20.1,10.5),(20.4,12.3)]]:
                            if segment_distance(x,y,a,b) <= .3:
                                pixel=blend(pixel,shine,.75)
                    samples.append(pixel)
            alpha=sum(pixel[3] for pixel in samples)
            if alpha:
                color=tuple(round(sum(pixel[i]*pixel[3] for pixel in samples)/alpha) for i in range(3))
                result.append(color+(round(alpha/len(samples)),))
            else:
                result.append((0,0,0,0))
    return result


if __name__ == "__main__":
    ROOT.mkdir(parents=True, exist_ok=True)
    (ROOT / "coins.svg").write_text(make_svg(), encoding="utf-8")
    atlas = [(0,0,0,0)] * (128*32)
    for index,palette in enumerate(PALETTES):
        coin=draw_coin(palette)
        for y in range(32):
            for x in range(32):
                atlas[y*128+index*32+x]=coin[y*32+x]
    # Uncompressed true-color TGA, top-left origin, eight alpha bits.
    header=struct.pack('<BBBHHBHHHHBB',0,0,2,0,0,0,0,0,128,32,32,0x28)
    pixels=bytes(channel for r,g,b,a in atlas for channel in (b,g,r,a))
    (ROOT / "coins.tga").write_bytes(header+pixels)
