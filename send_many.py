from scapy.all import *
import sys

p = Ether(src="00:00:00:00:01:00", dst="00:00:00:00:00:01") / IP(src="10.0.1.0", dst="10.0.0.1") / TCP(flags='CE') / "< P1 from Veth8: 10.0.1.0 --> 10.0.0.1!>"
# p.show()
hexdump(p)
# ls(p)
sendp(p, iface = "veth8")

p = Ether(src="00:00:00:00:02:00", dst="00:00:00:00:00:01") / IP(src="10.0.2.0", dst="10.0.0.1") / TCP(flags='CE') / "< P2 from Veth8: 10.0.2.0 --> 10.0.0.1!>"
# p.show()
hexdump(p)
# ls(p)
sendp(p, iface = "veth8")

p = Ether(src="00:00:00:00:03:00", dst="00:00:00:00:00:02") / IP(src="10.0.3.0", dst="10.0.0.2") / TCP(flags='CE') / "< P3 from Veth8: 10.0.3.0 --> 10.0.0.2!>"
# p.show()
hexdump(p)
# ls(p)
sendp(p, iface = "veth8")

p = Ether(src="00:00:00:00:04:00", dst="00:00:00:00:00:02") / IP(src="10.0.4.0", dst="10.0.0.2") / TCP(flags='CE') / "< P4 from Veth8: 10.0.4.0 --> 10.0.0.2!>"
# p.show()
hexdump(p)
# ls(p)
sendp(p, iface = "veth8")


