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

exit_f = False
# シグナルハンドラを定義
def handler(signum, frame):
    global exit_f
    print(f'handlerが呼び出されました(signum={signum})')
    exit_f = True
    ser.close()
    exit(0)
# signal.SIGALRMのシグナルハンドラを登録
signal.signal(signal.SIGINT, handler)
ser = serial.Serial(port='/dev/tty.usbserial-20230306211',baudrate=115200*16, timeout=0,parity='N')
k = 0

while True:
    if True:
        # address
        data = bytes([0])+cobs.encode(bytes([2,0,0]))
        if exit_f: break
        ser.write(data)
        if exit_f: break
    vram = read_img2(f"res/sc8_{k}.jpg")
    if k < 2: k += 1
    else: k = 0
    # data
    data = bytes([0])+cobs.encode(bytes([1])+bytes(vram))
    if exit_f: break
    ser.write(data)
    if exit_f: break
    time.sleep(0.05)
    if exit_f: break
ser.close()
