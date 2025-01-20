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
vram = read_img("res/sc8.png")

while True:
    if True:
        # address
        data = bytes([0])+cobs.encode(bytes([2,0,0]))
        if exit_f: break
        ser.write(data)
        if exit_f: break
    # data
    data = bytes([0])+cobs.encode(bytes([1])+bytes(vram))
    if exit_f: break
    ser.write(data)
    if exit_f: break
    time.sleep(0.05)
    if exit_f: break
ser.close()
