import os
os.environ['PYGAME_HIDE_SUPPORT_PROMPT'] = "hide"
import pygame

img = pygame.image.load("font.png")
(w,h)=img.get_size()
for y1 in range(0,h,8):
    for x1 in range(0,w,8):
        for y in range(8):
            for x in range(8):
                v=img.get_at_mapped((x1+x,y1+y))
                print(f"{v}",end="")
            print("")
        print("")
