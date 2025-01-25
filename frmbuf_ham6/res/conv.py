import os
os.environ['PYGAME_HIDE_SUPPORT_PROMPT'] = "hide"
import pygame
from PIL import Image
def diff(v,o):
    r = v[0]-o[0]
    g = v[1]-o[1]
    b = v[2]-o[2]
    r = r*299;g = g*587;b = b*114
    #return r*r*299+g*g*587+b*b*114
    return r*r+g*g+b*b

def conv(filename):
    img = pygame.image.load(f"../../frmbuf_uart_cobs/res/{filename}.jpg")
    #imgo = pygame.transform.smoothscale(img,(256,192))
    img = pygame.transform.smoothscale(img,(256,192))
    for y in range(192):
        for x in range(256):
            v=img.get_at((x,y))
            img.set_at((x,y),((v[0]//16)*17,(v[1]//16)*17,(v[2]//16)*17))
    imgo = img.copy()

    imgs = pygame.image.tostring(img,"RGB",False)
    Image.frombytes("RGB",(256,192),imgs).quantize(colors=16,method=0, kmeans=100,dither=1).save(f"{filename}.png")
    imgp = pygame.image.load(f"{filename}.png")
    pal2 = []
    pal = imgp.get_palette()
    for i,v in enumerate(pal):
        #print(f"pal {i}:{v}")
        pal2.append(pygame.Color(((v[0]//16)*17, (v[1]//16)*17, (v[2]//16)*17)))
    imgp.set_palette(pal2)
    for b in range(16): pal2.append(pygame.Color((0,0,b*0x11)))
    for r in range(16): pal2.append(pygame.Color((r*0x11,0,0)))
    for g in range(16): pal2.append(pygame.Color((0,g*0x11,0)))
    for i in range(64,256): pal2.append(pygame.Color((0,0,0)))
    img2 = pygame.Surface((256,192),depth=8)
    img2.set_palette(pal2)
    for y in range(192):
        d = (0,0,0,255)
        for x in range(256):
            o=imgo.get_at((x,y))
            r=(o[0],d[1],d[2],255)
            g=(d[0],o[1],d[2],255)
            b=(d[0],d[1],o[2],255)
            d=imgp.get_at((x,y))
            dd=diff(d,o)
            dr=diff(r,o)
            dg=diff(g,o)
            db=diff(b,o)
            res = 0
            if dd > dg:res = 3;dd=dg;d=g
            if dd > dr:res = 2;dd=dr;d=r
            if dd > db:res = 1;dd=db;d=b
            match res:
                case 0: img2.set_at((x,y),imgp.get_at_mapped((x,y))|res*16)
                case 1: img2.set_at((x,y),(o[2]//16)|res*16)
                case 2: img2.set_at((x,y),(o[0]//16)|res*16)
                case 3: img2.set_at((x,y),(o[1]//16)|res*16)
    pygame.image.save(img2, f"{filename}.png")
    #pygame.image.save(imgo, f"{filename}_o.png")
    #pygame.image.save(imgp, f"{filename}_p.png")
conv("sc8_0")
conv("sc8_1")
conv("sc8_2")
