from scapy.all import *
import sys

p = Ether(src="00:00:00:00:01:00", dst="00:00:00:00:00:01") / IP(src="10.0.1.0", dst="10.0.0.1") / TCP(flags='CE') / "< P1 from Veth8: 10.0.1.0 --> 10.0.0.1!>"
# p.show()
hexdump(p)
# ls(p)
sendp(p, iface = "veth8")
