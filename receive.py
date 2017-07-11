from __future__ import print_function
from scapy.all import *
import os
import sys

# Destination IP Counter
counter = 0
logFileName = "cpu.log"

if(os.path.isfile(logFileName)):
	os.remove(logFileName)

def getSrcIP(packet):
	global counter
	counter += 1
	fileLog = open(logFileName, "a")
	fileLog.write('[{}]: SrcAddr: {}\n'.format(counter, packet[0][1].src))
	return hexdump(packet)

def main():
	if len(sys.argv) != 2:
		print("ERROR: Invalid number of arguments")
		print("USAGE: sudo python receive.py vethX")
		print("INFO: Set the desired value to X's place.")
		exit(1)
	else:
		sniff_port = sys.argv[1]
		print("The sniffing port is set to: [{}]".format(sniff_port))

	# To write source IP addresses to a file change the line below to be a code line
	#sniff(iface = str(sys.argv[1]), prn=getSrcIP, filter="ip")

	# To write source IP addresses to a file change the line below to be a comment line
	sniff(iface = str(sys.argv[1]), prn = lambda x: hexdump(x))

main()
