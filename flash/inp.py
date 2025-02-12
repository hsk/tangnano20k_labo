import serial

ser = serial.Serial('/dev/tty.usbserial-20230306211',115200, timeout=1)
while True:
    string = ser.read()
    print(f"{string.decode()}",end="")

ser.close()
