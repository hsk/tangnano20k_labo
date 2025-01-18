import serial
import time
ser = serial.Serial(port='/dev/tty.usbserial-20230306211',baudrate=115200*2, timeout=0,parity='N')
k = 0
while True:
    for j in range(32*32):
        ser.write(bytes([k%10]))
        k += 1
    time.sleep(1/120)
ser.close()
