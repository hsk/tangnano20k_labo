import os
os.environ['PYGAME_HIDE_SUPPORT_PROMPT'] = "hide"
import pygame

def read_img(filename):
    img = pygame.image.load(filename)
    (w,h)=img.get_size()
    vs = []
    for y in range(h):
        for x in range(w):
            v=img.get_at_mapped((x,y))
            vs.append(v)
    return vs

with open("sc8_3.bin","wb") as f:
    f.write(bytes(read_img("sc8_3.png")))
