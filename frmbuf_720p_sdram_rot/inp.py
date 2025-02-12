import serial, signal, time, os
os.environ['PYGAME_HIDE_SUPPORT_PROMPT'] = "hide"
import pygame
from cobs import cobs

def read_img(filename):
    img = pygame.image.load(filename)
    (w,h)=img.get_size()
    vs = []
    for y in range(h):
        for x in range(w):
            v=img.get_at_mapped((x,y))
            vs.append(v)
    return vs

def read_img2(filename):
    img = pygame.image.load(filename)
    img = pygame.transform.smoothscale(img,(256,192))
    (w,h)=img.get_size()
    vs = []
    for y in range(h):
        for x in range(w):
            v=img.get_at((x,y))
            vs.append((v[0]*8//256)*4*8 + (v[1]*8//256)*4 + v[2]*4//256)
    return vs
loop = True
def handler(signum, frame):
    global loop
    loop = False
signal.signal(signal.SIGINT, handler)

ser = serial.Serial(port='/dev/tty.usbserial-20230306211',baudrate=115200*16, timeout=1,parity='N')
k = 0
while loop:
    # address
    ser.write(bytes([0])+cobs.encode(bytes([2,0,0])))
    # data
    vram = read_img2(f"res/sc8_{k}.jpg")
    ser.write(bytes([0])+cobs.encode(bytes([1])+bytes(vram)))
    k = k + 1 if k < 3 else 0
    time.sleep(0.5)
ser.close()