# Hue-shifts purple illustration pixels to brand teal (skin/gold/white untouched).
import numpy as np, sys
from pathlib import Path
from PIL import Image
D=Path(__file__).resolve().parent.parent/'hyzen_flutter/assets/illustrations'
def rgb2hsv(rgb):
    r,g,b=rgb[...,0],rgb[...,1],rgb[...,2]; mx=rgb.max(-1); mn=rgb.min(-1); d=mx-mn
    h=np.zeros_like(mx); m=d>1e-6
    rm=m&(mx==r); gm=m&(mx==g)&~rm; bm=m&~rm&~gm
    h[rm]=((g-b)[rm]/d[rm])%6; h[gm]=((b-r)[gm]/d[gm])+2; h[bm]=((r-g)[bm]/d[bm])+4
    return h*60, np.where(mx>1e-6,d/np.maximum(mx,1e-6),0), mx
def hsv2rgb(h,s,v):
    c=v*s; hp=(h%360)/60; x=c*(1-np.abs(hp%2-1)); z=np.zeros_like(h); i=np.floor(hp).astype(int)%6
    conds=[(c,x,z),(x,c,z),(z,c,x),(z,x,c),(x,z,c),(c,z,x)]
    sel=lambda k:np.select([i==j for j in range(6)],[t[k] for t in conds]); mm=v-c
    return np.stack([sel(0)+mm,sel(1)+mm,sel(2)+mm],-1)
def shift(path,size=None):
    im=Image.open(path).convert('RGBA')
    if size and im.width>size: im=im.resize((size,size),Image.LANCZOS)
    a=np.asarray(im).astype(np.float64)/255; h,s,v=rgb2hsv(a[...,:3])
    w=np.clip(1-np.abs(h-265)/45,0,1)*np.clip((s-0.06)/0.12,0,1)
    out=np.concatenate([hsv2rgb(h+(175.0-h)*w,np.clip(s*(1+0.30*w),0,1),v*(1-0.24*w*np.clip(s*2,0,1))),a[...,3:]],-1)
    img=Image.fromarray((out*255).round().clip(0,255).astype(np.uint8),'RGBA')
    if path.suffix=='.webp': img.save(path,'WEBP',quality=88)
    else: img.save(path,'PNG',optimize=True)
for n in ['home','library','downloads','search','welcome']: shift(D/f'{n}.png',720)
shift(D/'welcome_v2.webp')
print('recolored')
