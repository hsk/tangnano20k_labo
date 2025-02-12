import sys
with open(sys.argv[1],"rt") as f:
    bit = 0
    out = ""
    for s_line in f:
        if s_line[0:2] != "//":
            out += s_line
            for v in s_line:
                if v=="0" or v == "1": bit+=1

size = (bit+7)//8
print(f"//size    : {size:8d} bytes 0x{size:08X} bytes {bit:d} bits")

if len(sys.argv) < 3: exit(0)

position = int(sys.argv[2],0)

print(f"//posision: {position:8d} bytes 0x{position:08x} bytes ")

if position < size:
    sys.exit("ERROR: The position is smaller than the size.")

if len(sys.argv) < 4: exit(0)

print(f"{out}",end="")

for i in range(position-size):
    print(f"{0:08b}",end="" if i % 16 != 15 else "\n")

with open(sys.argv[3],"rb") as f:
    data = f.read()
for i,d in enumerate(data):
    print(f"{d:08b}",end="" if i % 16 != 15 else "\n")
print("")
