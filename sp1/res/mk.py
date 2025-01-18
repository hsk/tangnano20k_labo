import pygame

i = pygame.image.load("solvalou.png")

for y in range(i.get_height()):
    print(f"    mem['h{y:02x}] = 64'h",end="")
    for x in range(i.get_width()):
        print(f"{i.get_at_mapped((x,y)):01x}",end="")
    print(";")

pals = i.get_palette()
for i,p in enumerate(range(16)):
    print(f"    mem['h{i:02x}] = 24'h{pals[p][0]:02x}{pals[p][1]:02x}{pals[p][2]:02x};")
