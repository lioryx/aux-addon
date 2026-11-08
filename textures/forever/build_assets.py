"""Deterministic, addon-owned vector-style UI artwork for WoW 1.12.

TGA files are the runtime exports. SVG files preserve the editable construction
geometry; this script is the source for the exact shaded/painted raster export.
No Blizzard textures, fonts, screenshots or other addon assets are imported.
"""
from pathlib import Path
import math
import random
from raster import Image, ImageDraw

ROOT = Path(__file__).resolve().parent
SVG = ROOT / "source"
SVG.mkdir(exist_ok=True)


def css(c):
    return "#%02x%02x%02x" % tuple(c[:3])


def mix(a, b, t):
    return tuple(round(x + (y - x) * t) for x, y in zip(a, b))


class Art:
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.image = Image.new("RGBA", (w, h))
        self.draw = ImageDraw.Draw(self.image)
        self.svg = []
        self.defs = []

    def poly(self, points, fill, outline=None, width=1):
        self.draw.polygon(points, fill=fill)
        if outline:
            self.draw.line(points + [points[0]], fill=outline, width=width, joint="curve")
        color = css(fill) if fill else "none"
        alpha = fill[3] / 255 if fill and len(fill) > 3 else 1
        self.svg.append('<polygon points="%s" fill="%s" fill-opacity="%.3f" stroke="%s" stroke-width="%s"/>' % (
            " ".join("%s,%s" % p for p in points), color, alpha, css(outline) if outline else "none", width))

    def rect(self, box, fill, outline=None, width=1):
        self.draw.rectangle(box, fill=fill, outline=outline, width=width)
        x, y, r, b = box
        self.svg.append('<rect x="%s" y="%s" width="%s" height="%s" fill="%s" fill-opacity="%.3f" stroke="%s" stroke-width="%s"/>' % (
            x, y, r-x+1, b-y+1, css(fill) if fill else "none", (fill[3]/255 if fill and len(fill)>3 else 1), css(outline) if outline else "none", width))

    def line(self, pts, color, width=1):
        self.draw.line(pts, fill=color, width=width, joint="curve")
        self.svg.append('<polyline points="%s" fill="none" stroke="%s" stroke-opacity="%.3f" stroke-width="%s" stroke-linejoin="round" stroke-linecap="round"/>' % (
            " ".join("%s,%s" % p for p in pts), css(color), color[3]/255 if len(color)>3 else 1, width))

    def ellipse(self, box, fill, outline=None, width=1):
        self.draw.ellipse(box, fill=fill, outline=outline, width=width)
        x,y,r,b=box
        self.svg.append('<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="%s" fill-opacity="%.3f" stroke="%s" stroke-width="%s"/>' % (
            (x+r)/2,(y+b)/2,(r-x)/2,(b-y)/2,css(fill) if fill else "none",fill[3]/255 if fill and len(fill)>3 else 1,css(outline) if outline else "none",width))

    def gradient(self, box, top, middle, bottom, mask=None):
        x,y,r,b=box
        fill=Image.new("RGBA",(self.w,self.h))
        d=ImageDraw.Draw(fill)
        for yy in range(y,b+1):
            t=(yy-y)/max(1,b-y)
            c=mix(top,middle,t*2) if t<.5 else mix(middle,bottom,(t-.5)*2)
            d.line((x,yy,r,yy),fill=c)
        if mask:
            fill.putalpha(mask)
        self.image.alpha_composite(fill)
        self.draw=ImageDraw.Draw(self.image)
        gid="g%d" % len(self.defs)
        self.defs.append('<linearGradient id="%s" x1="0" y1="0" x2="0" y2="1"><stop stop-color="%s"/><stop offset=".5" stop-color="%s"/><stop offset="1" stop-color="%s"/></linearGradient>' % (gid,css(top),css(middle),css(bottom)))
        self.svg.append('<rect x="%s" y="%s" width="%s" height="%s" fill="url(#%s)"/>' % (x,y,r-x+1,b-y+1,gid))

    def save(self, name):
        self.image.save(ROOT / (name + ".tga"), compression=None)
        (SVG / (name + ".svg")).write_text('<svg xmlns="http://www.w3.org/2000/svg" width="%s" height="%s" viewBox="0 0 %s %s"><defs>%s</defs>%s</svg>\n' % (
            self.w,self.h,self.w,self.h,"".join(self.defs),"".join(self.svg)),encoding="utf-8",newline='\n')


def background(name, base, amplitude=3):
    a=Art(256,256)
    a.gradient((0,0,255,255),tuple(x+3 for x in base),base,tuple(max(0,x-3) for x in base))
    rng=random.Random(1701)
    pixels=a.image.load()
    for y in range(256):
        for x in range(256):
            # Low contrast, softly mottled metal; no repeated high contrast motif.
            v=amplitude*(math.sin(x/39+y/61)+math.sin(x/78-y/51))*.5+rng.uniform(-1.4,1.4)
            pixels[x,y]=tuple(max(0,min(255,round(c+v))) for c in base)+(255,)
    a.defs.append('<filter id="grain"><feTurbulence type="fractalNoise" baseFrequency=".025" numOctaves="3" seed="17"/><feColorMatrix type="saturate" values="0"/><feComponentTransfer><feFuncA type="linear" slope=".045"/></feComponentTransfer></filter>')
    a.svg.append('<rect width="256" height="256" filter="url(#grain)"/>')
    a.save(name)
    return a


def octagon(w,h,inset=0,cut=4):
    l=t=inset;r=w-1-inset;b=h-1-inset
    return [(l+cut,t),(r-cut,t),(r,t+cut),(r,b-cut),(r-cut,b),(l+cut,b),(l,b-cut),(l,t+cut)]


def surface(name,w=256,h=32,palette=None,border=None):
    palette=palette or ((101,9,7),(65,1,0),(81,4,1))
    border=border or [(9,8,6),(112,106,91),(31,27,22),(171,159,129),(42,35,26),(11,10,9)]
    a=Art(w,h)
    # Six-pixel end caps. They can be kept at 1:1 scale by the Lua renderer.
    for i,c in enumerate(border):
        a.poly(octagon(w,h,i,max(1,5-i)),c)
    mask=Image.new('L',(w,h));ImageDraw.Draw(mask).polygon(octagon(w,h,6,1),fill=255)
    a.gradient((6,6,w-7,h-7),*palette,mask=mask)
    a.line([(7,6),(w-8,6)],tuple(min(255,int(v*1.3+8)) for v in palette[0]),1)
    a.line([(6,h-7),(w-7,h-7)],(18,6,3),1)
    a.save(name)
    return a


def edge_atlas(name,metal):
    a=Art(128,16)
    # Standard Backdrop edge atlas: L, R, T, B, TL, TR, BL, BR.
    # All four straight edges are vertical strips in the atlas. Backdrop rotates
    # T/B when rendering, so their bevel runs across X just like L/R. Drawing
    # horizontal bands here produces repeated teeth along the window border.
    # Each tile has a transparent interior and the same seven-pixel bevel.
    shade=[(9,8,6),metal[0],metal[1],metal[2],metal[3],(25,22,17),(7,7,6)]
    for tile in range(8):
        x=tile*16
        for i,c in enumerate(shade):
            if tile==0: a.rect((x+i,0,x+i,15),c)
            elif tile==1: a.rect((x+15-i,0,x+15-i,15),c)
            elif tile==2: a.rect((x+i,0,x+i,15),c)
            elif tile==3: a.rect((x+15-i,0,x+15-i,15),c)
            elif tile==4:
                a.line([(x+i,15),(x+i,i),(x+15,i)],c)
            elif tile==5:
                a.line([(x,i),(x+15-i,i),(x+15-i,15)],c)
            elif tile==6:
                a.line([(x+i,0),(x+i,15-i),(x+15,15-i)],c)
            else:
                a.line([(x,15-i),(x+15-i,15-i),(x+15-i,0)],c)
    a.save(name)


background('window-bg',(41,38,33),2.5)
background('panel-bg',(24,23,21),2)
edge_atlas('window-edge',[(82,58,32),(188,157,95),(110,84,47),(55,40,26)])
edge_atlas('panel-edge',[(64,62,55),(127,127,115),(74,74,66),(39,38,33)])
a=Art(256,32);a.gradient((0,0,255,31),(51,32,17),(29,19,12),(39,26,16));a.line([(0,1),(255,1)],(113,84,43));a.line([(0,29),(255,29)],(99,73,40));a.save('title-bg')
surface('button-normal')
surface('button-pressed',palette=((48,1,0),(66,2,0),(84,9,4)),border=[(7,6,5),(43,38,31),(114,100,77),(28,21,17),(66,54,36),(8,7,6)])
surface('button-disabled',palette=((45,44,40),(31,30,28),(36,35,32)),border=[(8,8,7),(68,67,60),(23,23,21),(94,91,77),(36,34,29),(11,11,10)])
surface('tab-normal',128,32,((49,46,38),(26,24,20),(22,21,18)),[(10,9,7),(80,68,44),(131,113,73),(37,32,23),(73,61,37),(16,14,10)])
surface('tab-selected',128,32,((118,91,16),(55,44,12),(81,66,15)),[(24,20,5),(151,121,28),(255,232,99),(171,145,42),(88,73,22),(35,30,9)])
surface('header',128,32,((49,48,43),(38,37,33),(31,30,26)),[(14,14,12),(91,91,82),(53,54,47),(29,29,26),(40,39,34),(32,31,27)])
surface('input-bg',128,32,((9,9,8),(7,7,6),(12,12,10)),[(12,10,8),(124,108,78),(51,45,35),(151,134,102),(48,43,33),(8,8,6)])
a=Art(256,32)
for x in range(256):
    alpha=round(175*(math.sin(math.pi*x/255)**.55))
    a.draw.line((x,0,x,31),fill=(190,145,11,alpha))
a.defs.append('<linearGradient id="gold"><stop stop-color="#be910b" stop-opacity="0"/><stop offset=".5" stop-color="#be910b" stop-opacity=".69"/><stop offset="1" stop-color="#be910b" stop-opacity="0"/></linearGradient>')
a.svg.append('<rect width="256" height="32" fill="url(#gold)"/>');a.save('row-highlight')
surface('check-off',32,32,((20,19,16),(12,12,10),(16,16,13)),[(9,9,7),(71,70,62),(127,126,109),(44,44,36)])
a=Art(32,32);a.line([(5,17),(12,24),(27,5)],(28,23,3),7);a.line([(5,15),(12,22),(27,4)],(255,218,0),5);a.line([(5,14),(12,21),(26,4)],(255,246,124),1);a.save('check-on')
a=surface('close',32,32,((135,15,8),(83,3,0),(113,8,0)),[(17,12,5),(116,92,48),(211,172,81),(70,43,17),(31,14,5)])
a.svg.append('<rect x="1" y="1" width="30" height="30" rx="4" fill="#790900" stroke="#caa14d" stroke-width="3"/>')
a.line([(10,9),(23,23)],(255,218,0),4);a.line([(22,9),(9,23)],(255,218,0),4);a.save('close')
a=Art(16,64);a.gradient((3,1,12,62),(123,91,48),(93,58,26),(106,70,31));a.rect((2,1,13,62),None,(52,37,22));a.line([(4,3),(4,60)],(156,118,62));a.line([(11,3),(11,60)],(61,38,19));a.save('scroll-thumb')
for name,points in [('arrow-up',[(2,11),(8,5),(14,11),(14,15),(8,9),(2,15)]),('arrow-down',[(2,1),(8,7),(14,1),(14,5),(8,11),(2,5)]),('arrow-right',[(4,1),(13,8),(4,15)])]:
    a=Art(16,16);a.poly([(x,y+1) for x,y in points],(15,14,11));a.poly(points,(178,165,128) if name!='arrow-right' else (241,204,27),(59,53,40));a.save(name)
for selected in [False,True]:
    a=Art(32,32);pts=[]
    for i in range(10):
        ang=-math.pi/2+i*math.pi/5;r=13 if i%2==0 else 5.8
        pts.append((round(16+math.cos(ang)*r),round(16+math.sin(ang)*r)))
    a.poly(pts,(241,202,34) if selected else (25,24,21),(255,232,122) if selected else (116,113,100),2)
    a.save('star-on' if selected else 'star-off')
a=Art(32,32);pts=[]
for i in range(46):
    angle=math.radians(45+i*6)
    pts.append((16+10*math.cos(angle),16+10*math.sin(angle)))
a.line(pts,(35,29,7),7);a.line(pts,(238,196,39),4);a.poly([(25,4),(28,14),(18,12)],(247,211,57));a.save('refresh')
a=Art(32,32)
a.line([(20,20),(28,28)],(22,21,18),7)
a.line([(19,19),(27,27)],(132,134,127),5)
a.line([(20,19),(28,27)],(193,194,182),1)
a.ellipse((3,3,23,23),None,(25,25,22),5)
a.ellipse((3,2,23,22),None,(135,138,130),3)
a.ellipse((5,4,21,20),None,(198,200,188),1)
a.save('search')
a=Art(128,128)
for i,c in [(1,(10,8,5)),(3,(113,79,39)),(5,(224,190,124)),(7,(119,86,43)),(10,(54,37,22)),(12,(12,10,7))]:
    a.ellipse((i,i,127-i,127-i),None,c,2 if i<10 else 3)
a.save('portrait-ring')

(ROOT/'ASSETS.md').write_text('''# Forever UI artwork

These are addon-owned, procedurally drawn assets, not references or copies of
system UI textures. `build_assets.py` reproduces the RGBA TGA exports; `source/`
contains editable SVG geometry. The SVG grain is a construction approximation;
the Python renderer defines the exact small-scale surface shading.

All TGA dimensions are powers of two and exports are uncompressed RGBA.

* `window-edge` and `panel-edge`: 128 x 16, eight 16 x 16 cells ordered
  left, right, top, bottom, top-left, top-right, bottom-left, bottom-right.
  All four straight-edge cells contain vertical strips: Backdrop rotates the
  top/bottom cells while tiling. At edgeSize 16 the painted bevel occupies
  seven pixels; smaller edge sizes scale it proportionally.
* Buttons, tabs, input and headers reserve six pixels for end caps. Keep the
  left/right caps fixed and stretch their center, or use nine-slice rendering.
* `check-on` is a transparent check-mark overlay for `check-off`.
* `portrait-ring` is transparent through its center; layer it over a portrait.
* `row-highlight` is a translucent gold wash with transparent horizontal ends.

No fonts, coin images or item/character artwork are included in this batch.
''',encoding='utf-8',newline='\n')
