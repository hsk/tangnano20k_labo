import serial
import signal
import time
from cobs import cobs

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
vram = [0 for _ in range(32*32)]

while True:
    for j in range(32*32):
        vram[j]=k%10
        k += 1
    data = bytes([0])+cobs.encode(bytes(vram))
    if exit_f: break
    ser.write(data)
    #print(f"{vram}")
    #print(f"{data}")
    if exit_f: break
    time.sleep(0.05)
    if exit_f: break
ser.close()
