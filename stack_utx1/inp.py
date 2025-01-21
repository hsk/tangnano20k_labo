import serial

readSer = serial.Serial('/dev/tty.usbserial-20230306211',115200, timeout=3)
while True:
    string = readSer.read()
    print(f"{string.decode()}",end="")

readSer.close()
