import struct

def hex64(obj):
    return "0x%016X" % obj

def hex32(obj):
    return "0x%08X" % obj

def hex16(obj):
    return "0x%04X" % obj

def hex8(obj):
    return "0x%02X" % obj

def hexme(obj,j):
    o = ""
    for i in range(0,j):
         o += "%02x" % struct.unpack('B',obj[i])
    return o
