"""Small dependency-free drawing backend for the Forever UI asset source."""
import math
import struct


class Pixels:
    def __init__(self, image): self.image=image
    def __getitem__(self, xy): return self.image.data[xy[1]*self.image.width+xy[0]]
    def __setitem__(self, xy, value): self.image.set(*xy,value)


class Canvas:
    def __init__(self, mode, size):
        self.mode=mode;self.width,self.height=size
        self.data=[0 if mode=='L' else (0,0,0,0)]*(self.width*self.height)

    def set(self,x,y,c):
        x,y=int(x),int(y)
        if c is None or x<0 or y<0 or x>=self.width or y>=self.height: return
        if self.mode!='L' and len(c)==3: c=tuple(c)+(255,)
        self.data[y*self.width+x]=c

    def load(self): return Pixels(self)

    def putalpha(self,mask):
        self.data=[tuple(c[:3])+(mask.data[i],) for i,c in enumerate(self.data)]

    def alpha_composite(self,other):
        for i,src in enumerate(other.data):
            if not src[3]: continue
            if src[3]==255: self.data[i]=src;continue
            dst=self.data[i];alpha=src[3]/255;da=dst[3]/255
            out=alpha+da*(1-alpha)
            self.data[i]=tuple(round((src[j]*alpha+dst[j]*da*(1-alpha))/out) for j in range(3))+(round(out*255),)

    def save(self,path,compression=None):
        # Uncompressed BGRA, top-left origin, eight alpha bits.
        header=struct.pack('<BBBHHBHHHHBB',0,0,2,0,0,0,0,0,self.width,self.height,32,0x28)
        rgba=bytearray()
        for r,g,b,a in self.data: rgba.extend((b,g,r,a))
        with open(path,'wb') as f: f.write(header);f.write(rgba)


class Image:
    @staticmethod
    def new(mode,size): return Canvas(mode,size)


class Draw:
    def __init__(self,image): self.image=image

    def rectangle(self,box,fill=None,outline=None,width=1):
        l,t,r,b=[round(v) for v in box]
        for y in range(max(0,t),min(self.image.height,b+1)):
            for x in range(max(0,l),min(self.image.width,r+1)):
                c=outline if outline is not None and min(x-l,r-x,y-t,b-y)<width else fill
                self.image.set(x,y,c)

    def polygon(self,pts,fill=None):
        if fill is None or len(pts)<3: return
        low=max(0,math.floor(min(p[1] for p in pts)))
        high=min(self.image.height-1,math.ceil(max(p[1] for p in pts)))
        for y in range(low,high+1):
            scan=y+.5;intersections=[]
            for i,p in enumerate(pts):
                q=pts[(i+1)%len(pts)]
                if (p[1]<=scan<q[1]) or (q[1]<=scan<p[1]):
                    intersections.append(p[0]+(scan-p[1])*(q[0]-p[0])/(q[1]-p[1]))
            intersections.sort()
            for i in range(0,len(intersections)-1,2):
                for x in range(max(0,math.ceil(intersections[i]-.5)),min(self.image.width-1,math.floor(intersections[i+1]-.5))+1):
                    self.image.set(x,y,fill)

    def line(self,pts,fill=None,width=1,joint=None):
        if fill is None:return
        if len(pts)==4 and not isinstance(pts[0],(list,tuple)): pts=[pts[:2],pts[2:]]
        radius=max(.5,width/2)
        for i in range(len(pts)-1):
            x1,y1=pts[i];x2,y2=pts[i+1]
            dx,dy=x2-x1,y2-y1;length=dx*dx+dy*dy
            for y in range(max(0,math.floor(min(y1,y2)-radius)),min(self.image.height,math.ceil(max(y1,y2)+radius)+1)):
                for x in range(max(0,math.floor(min(x1,x2)-radius)),min(self.image.width,math.ceil(max(x1,x2)+radius)+1)):
                    t=max(0,min(1,((x-x1)*dx+(y-y1)*dy)/length)) if length else 0
                    if (x-x1-t*dx)**2+(y-y1-t*dy)**2<=radius*radius:
                        self.image.set(x,y,fill)

    def ellipse(self,box,fill=None,outline=None,width=1):
        l,t,r,b=box;cx,cy=(l+r)/2,(t+b)/2;rx,ry=(r-l)/2,(b-t)/2
        for y in range(max(0,math.floor(t)),min(self.image.height,math.ceil(b)+1)):
            for x in range(max(0,math.floor(l)),min(self.image.width,math.ceil(r)+1)):
                d=((x-cx)/rx)**2+((y-cy)/ry)**2
                if d>1:continue
                inside=rx>width and ry>width and ((x-cx)/(rx-width))**2+((y-cy)/(ry-width))**2<1
                self.image.set(x,y,fill if inside or outline is None else outline)


class ImageDraw:
    Draw=Draw
