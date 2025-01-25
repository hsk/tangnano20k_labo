import os,sys
os.environ['PYGAME_HIDE_SUPPORT_PROMPT'] = "hide"
import pygame
def read_img(filename):
    img = pygame.image.load(filename)
    (w,h)=img.get_size()
    vs = []
    for c in img.get_palette():
        rgb4096 = (c[0]*16//256)*256+(c[1]*16//256)*16+(c[2]*16//256)
        vs.append(rgb4096&255)
        vs.append(rgb4096>>8)
    vs = vs[0:128]
    for i in range(6):
        for y in range(256):
            p = 0
            for x in range(w):
                v = img.get_at_mapped((x,y)) if y < h else 0
                v=((v>>(5-i))&1)
                p = (p<<1)+v
                if x&7==7:
                    vs.append(p)
                    p=0
    return vs

vs=read_img("sc8_1.png")
#print(f"{vs} len{len(vs)}")


pygame.init()    # Pygameを初期化
screen = pygame.display.set_mode((256*2, 192*2))    # 画面を作成
img1 = pygame.Surface((256,192))
img2 = pygame.Surface((256,192))
img3 = pygame.image.load("../../frmbuf_uart_cobs/res/sc8_1.jpg")
img3 = pygame.transform.smoothscale(img3,(256,192))
img4 = img3.copy()
for y in range(192):
    for x in range(256):
        v=img4.get_at((x,y))
        img4.set_at((x,y),((v[0]//16)*17,(v[1]//16)*17,(v[2]//16)*17))

(w,h)=img1.get_size()
for y in range(h):
    d = pygame.Color((0,0,0,255))
    for x in range(w):
        p = (vs[128+(y*256+x)//8]>>(7-(x&7)))&1
        p = (p<<1) | ((vs[128+8192+(y*256+x)//8]>>(7-(x&7)))&1)
        p = (p<<1) | ((vs[128+8192*2+(y*256+x)//8]>>(7-(x&7)))&1)
        p = (p<<1) | ((vs[128+8192*3+(y*256+x)//8]>>(7-(x&7)))&1)
        p = (p<<1) | ((vs[128+8192*4+(y*256+x)//8]>>(7-(x&7)))&1)
        p = (p<<1) | ((vs[128+8192*5+(y*256+x)//8]>>(7-(x&7)))&1)
        r = vs[p*2+1]&15
        g = (vs[p*2]>>4)&15
        b = vs[p*2]&15
        c = ((r<<4)|r,(g<<4)|g,(b<<4)|b,255)
        img1.set_at((x,y),c)
        l = p&15
        match p>>4:
            case 0: d = c
            case 1: d = (d[0],d[1],(l<<4)|l,255)
            case 2: d = ((l<<4)|l,d[1],d[2],255)
            case 3: d = (d[0],(l<<4)|l,d[2],255)
        img2.set_at((x,y),d)
running = True
#メインループ
while running:
    screen.fill((0,0,0))  #画面を黒で塗りつぶす
    screen.blit(img1, (0, 0))
    screen.blit(img2, (256, 0))
    screen.blit(img3, (0, 192))
    screen.blit(img4, (256, 192))
    pygame.display.update() #描画処理を実行
    for event in pygame.event.get():
        if event.type == pygame.QUIT:  # 終了イベント
            running = False
            pygame.quit()  #pygameのウィンドウを閉じる
            sys.exit() #システム終了
