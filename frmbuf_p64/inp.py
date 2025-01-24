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
        rgb512 = (c[0]*8//256)*256+(c[1]*8//256)*16+(c[2]*8//256)
        vs.append(rgb512&255)
        vs.append(rgb512>>8)
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
    if True:
        # address mode = 2
        data = bytes([0])+cobs.encode(bytes([2,0,0]))
        if exit_f: break
        ser.write(data)
        if exit_f: break
    vram = read_img(f"res/sc8_{k}.png")
    if k < 2: k += 1
    else: k = 0

    # palette mode = 4
    data = bytes([0])+cobs.encode(bytes([4])+bytes(vram[0:128]))
    if exit_f: break
    ser.write(data)
    if exit_f: break
    # data mode = 1
    data = bytes([0])+cobs.encode(bytes([1])+bytes(vram[128:]))
    if exit_f: break
    ser.write(data)
    if exit_f: break
    time.sleep(3)
    if exit_f: break
ser.close()
