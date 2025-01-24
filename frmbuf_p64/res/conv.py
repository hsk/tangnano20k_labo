import os
os.environ['PYGAME_HIDE_SUPPORT_PROMPT'] = "hide"
import pygame
from PIL import Image

def conv(filename):
    img = pygame.image.load(f"../../frmbuf_uart_cobs/res/{filename}.jpg")
    img = pygame.transform.smoothscale(img,(256,192))
    for y in range(192):
        for x in range(256):
            v=img.get_at((x,y))
            img.set_at((x,y),((v[0]*8//256)*255//7,(v[1]*8//256)*255//7,(v[2]*8//256)*255//7))

    #pygame.image.save(img,f"{filename}.png")
    #Image.open(f"{filename}.png").quantize(16).save(f"{filename}.png")
    imgs = pygame.image.tostring(img,"RGB",False)
    Image.frombytes("RGB",(256,192),imgs).quantize(colors=64,method=0, kmeans=100,dither=1).save(f"{filename}.png")

conv("sc8_0")
conv("sc8_1")
conv("sc8_2")
