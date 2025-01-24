import os,sys
os.environ['PYGAME_HIDE_SUPPORT_PROMPT'] = "hide"
import pygame
def read_img(filename):
    img = pygame.image.load(filename)
    (w,h)=img.get_size()
    vs = []
    for c in img.get_palette():
        rgb512 = (c[0]*8//256)*256+(c[1]*8//256)*16+(c[2]*8//256)
        vs.append(rgb512&255)
        vs.append(rgb512>>8)
    vs = vs[0:32]
    for i in range(4):
        for y in range(256):
            p = 0
            for x in range(w):
                v = img.get_at_mapped((x,y)) if y < h else 0
                v=((v>>(3-i))&1)
                p = (p<<1)+v
                if x&7==7:
                    vs.append(p)
                    p=0
    return vs

vs=read_img("sc8_0.png")
print(f"{vs} len{len(vs)}")


pygame.init()    # Pygameを初期化
screen = pygame.display.set_mode((256, 192))    # 画面を作成
img1 = pygame.image.load("sc8_0.png")
(w,h)=img1.get_size()
for y in range(h):
    for x in range(w):
        p = (vs[32+(y*256+x)//8]>>(7-(x&7)))&1
        p = (p<<1) | ((vs[32+8192+(y*256+x)//8]>>(7-(x&7)))&1)
        p = (p<<1) | ((vs[32+8192*2+(y*256+x)//8]>>(7-(x&7)))&1)
        p = (p<<1) | ((vs[32+8192*3+(y*256+x)//8]>>(7-(x&7)))&1)
        img1.set_at((x,y),p)
running = True
#メインループ
while running:
    screen.fill((0,0,0))  #画面を黒で塗りつぶす
    screen.blit(img1, (0, 0))
    pygame.display.update() #描画処理を実行
    for event in pygame.event.get():
        if event.type == pygame.QUIT:  # 終了イベント
            running = False
            pygame.quit()  #pygameのウィンドウを閉じる
            sys.exit() #システム終了