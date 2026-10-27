# Generates synthetic perspective document photos with known corners (ground truth).
import numpy as np, json, random, sys
from PIL import Image, ImageDraw, ImageFilter
random.seed(7); np.random.seed(7)
out=sys.argv[1]; N=int(sys.argv[2]) if len(sys.argv)>2 else 40
def page(w=850,h=1100,kind=0):
    tone=random.choice([(250,250,246),(244,240,228),(255,255,255),(236,238,240)])
    im=Image.new('RGB',(w,h),tone); d=ImageDraw.Draw(im)
    y=70
    while y<h-70:
        if random.random()<0.08: y+=40; continue
        x=60; L=random.randint(300,w-120)
        th=random.choice([3,4,5,6])
        col=random.choice([(30,30,30),(20,40,120),(60,60,60)])
        while x<60+L:
            wl=random.randint(15,70); d.rectangle([x,y,x+wl,y+th+6],fill=col); x+=wl+random.randint(8,14)
        y+=random.randint(22,34)
    if kind==1:  # table grid
        for gx in range(60,w-60,140): d.line([gx,80,gx,h-80],fill=(90,90,90),width=2)
        for gy in range(80,h-80,60): d.line([60,gy,w-60,gy],fill=(90,90,90),width=2)
    return im
def background(W,H):
    k=random.randint(0,3)
    if k==0: # wood
        base=np.zeros((H,W,3),np.float32); x=np.linspace(0,30,W)[None,:]+np.random.rand(H,1)*2
        v=(np.sin(x+np.sin(np.linspace(0,8,H))[:,None]*2)*0.5+0.5)
        c1=np.array([120,80,45]); c2=np.array([160,115,70])
        base=c1+(c2-c1)*v[...,None]
    elif k==1: base=np.ones((H,W,3))*np.array(random.choice([(40,42,48),(70,70,75),(25,30,35)]))
    elif k==2: base=np.ones((H,W,3))*np.array(random.choice([(200,200,195),(180,185,190)]))  # light table – hard
    else:
        base=np.random.rand(H//20+1,W//20+1,3)*120+60
        base=np.array(Image.fromarray(base.astype(np.uint8)).resize((W,H),Image.BICUBIC)).astype(np.float32)
    base+=np.random.randn(H,W,3)*6
    return Image.fromarray(base.clip(0,255).astype(np.uint8))
def coeffs(src,dst):
    A=[];B=[]
    for (x,y),(u,v) in zip(dst,src):
        A.append([x,y,1,0,0,0,-u*x,-u*y]); B.append(u)
        A.append([0,0,0,x,y,1,-v*x,-v*y]); B.append(v)
    return np.linalg.solve(np.array(A,float),np.array(B,float))
gt={}
for i in range(N):
    W,H=random.choice([(1200,1600),(1080,1440),(1600,1200)])
    bg=background(W,H)
    pg=page(kind=1 if i%5==0 else 0)
    cx,cy=W/2+random.uniform(-.08,.08)*W, H/2+random.uniform(-.08,.08)*H
    s=random.uniform(.55,.85)*min(W,H)/1100*1.25
    pw,ph=850*s,1100*s
    ang=random.uniform(-.35,.35)
    base=[(-pw/2,-ph/2),(pw/2,-ph/2),(pw/2,ph/2),(-pw/2,ph/2)]
    persp=random.uniform(0,.18)
    dst=[]
    for k,(x,y) in enumerate(base):
        if y<0: x*= (1-persp)
        x+=random.uniform(-.03,.03)*pw; y+=random.uniform(-.03,.03)*ph
        rx=x*np.cos(ang)-y*np.sin(ang); ry=x*np.sin(ang)+y*np.cos(ang)
        dst.append((cx+rx,cy+ry))
    if any(not(5<x<W-5 and 5<y<H-5) for x,y in dst): continue
    c=coeffs([(0,0),(850,0),(850,1100),(0,1100)],dst)
    warped=pg.transform((W,H),Image.PERSPECTIVE,c,Image.BICUBIC)
    mask=Image.new('L',(850,1100),255).transform((W,H),Image.PERSPECTIVE,c,Image.BICUBIC)
    # shadow
    sh=Image.new('L',(W,H),0); ImageDraw.Draw(sh).polygon([(x+12,y+16) for x,y in dst],fill=110)
    sh=sh.filter(ImageFilter.GaussianBlur(18))
    bgarr=np.array(bg).astype(np.float32)*(1-np.array(sh)[...,None]/255*0.6)
    comp=Image.composite(warped,Image.fromarray(bgarr.clip(0,255).astype(np.uint8)),mask)
    # lighting gradient + noise + blur
    a=np.array(comp).astype(np.float32)
    gx=np.linspace(random.uniform(.75,1),random.uniform(.85,1.1),W)[None,:,None]
    a*=gx; a+=np.random.randn(*a.shape)*4
    comp=Image.fromarray(a.clip(0,255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(random.uniform(.4,1.2)))
    name=f'synth_{i:02d}.jpg'; comp.save(f'{out}/{name}',quality=88)
    gt[name]=[v for x,y in dst for v in (x/W,y/H)]
json.dump(gt,open(f'{out}/gt.json','w'))
print(len(gt))
