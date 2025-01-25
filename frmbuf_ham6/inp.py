import serial
import signal
import time
from cobs import cobs
import os
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

exit_f = False
# シグナルハンドラを定義
def handler(signum, frame):
    global exit_f
    print(f'handlerが呼び出されました(signum={signum})')
    exit_f = True
# signal.SIGALRMのシグナルハンドラを登録
signal.signal(signal.SIGINT, handler)
ser = serial.Serial(port='/dev/tty.usbserial-20230306211',baudrate=115200*2, timeout=0,parity='N')
k = 0

while True:
    vram = read_img(f"res/sc8_{k}.png")
    if k < 2: k += 1
    else: k = 0

    # palette mode = 4
    ser.write(bytes([0])+cobs.encode(bytes([4])+bytes(vram[0:32])))
    if exit_f: break

    for i in range(6):
        # address mode = 2
        pos = 8192*i
        ser.write(bytes([0])+cobs.encode(bytes([2,pos&255,pos>>8])))
        if exit_f: break
        # data mode = 1
        ser.write(bytes([0])+cobs.encode(bytes([1])+bytes(vram[128+pos:128+pos+256*192//8])))
        if exit_f: break
    time.sleep(2)
    if exit_f: break
ser.close()
