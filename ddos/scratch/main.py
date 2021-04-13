import random
import socket
import struct
import dns

def compute_checksum(msg):
    checksum = 0
    for i in range(0, len(msg), 2):
        if (i + 1) == len(msg):
            checksum += msg[i]
        else:
            checksum += msg[i] + (msg[i + 1] << 8)

    checksum = (checksum & 0xFFFF) + (checksum >> 16)
    checksum = ~checksum & 0xFFFF

    return checksum


def pack_ip_packet(**kwargs):
    """
    https://www.tutorialspoint.com/ipv4/ipv4_packet_structure.htm
    version - ihl   : B  (1 byte)
    dscp - ecn      : B  (1 byte)
    total length    : H  (2 bytes)
    identification  : H  (2 bytes)
    flags - offset  : H  (2 bytes)
    ttl             : B  (1 byte)
    protocol        : B  (1 byte)
    header checksum : H  (2 bytes)
    source address  : 4s (4 bytes)
    dest address    : 4s (4 bytes)
    """

    version_ihl = (kwargs["version"] << 4) | kwargs["ihl"]
    dscp_ecn = (kwargs["dscp"] << 7) | kwargs["ecn"]
    flags_offset = (kwargs["flags"] << 13) | kwargs["fragment_offset"]

    return struct.pack("!BBHHHBBH4s4s",
        version_ihl,
        dscp_ecn,
        kwargs["total_length"],
        kwargs["identification"],
        flags_offset,
        kwargs["time_to_live"],
        kwargs["protocol"],
        kwargs["checksum"],
        kwargs["src_addr"],
        kwargs["dest_addr"]
    )


def pack_udp_packet(**kwargs):
    """
    src port    : H (2 bytes)
    dest port   : H (2 bytes)
    length      : H (2 bytes)
    checksum    : H (2 bytes)
    """

    return struct.pack("!HHHH",
        kwargs["src_port"],
        kwargs["dest_port"],
        kwargs["length"],
        kwargs["checksum"]
    )


def make_ip_packet(**kwargs):
    """
    required fields in kwargs:
        src_addr
        dest_addr
        payload
    """
    payload = bytes(kwargs["payload"])

    fields = {
        "version": 4,
        "ihl": 5,
        "dscp": 0,
        "ecn": 0,
        "total_length": 20 + len(payload),
        "identification": random.randint(0, 65535),
        "flags": 0,
        "fragment_offset": 0,
        "time_to_live": 128,
        "protocol": socket.IPPROTO_UDP,
        "checksum": 0,
        "src_addr": socket.inet_pton(socket.AF_INET, kwargs["src_addr"]),
        "dest_addr": socket.inet_pton(socket.AF_INET, kwargs["dest_addr"])
    }

    preflight_packet = pack_ip_packet(**fields)
    fields["checksum"] = compute_checksum(preflight_packet)

    return pack_ip_packet(**fields)

def make_udp_packet(**kwargs):
    """
    required fields in kwargs:
        src_port
        dest_port
        payload
    """
    payload = bytes(kwargs["payload"])

    fields = {
        "src_port": socket.inet_pton(socket.AF_INET, kwargs["src_port"]),
        "dest_port": socket.inet_pton(socket.AF_INET, kwargs["dest_port"]),
        "length": 8 + len(payload),
        "checksum": 0 # checksum is optional in UDP
    }

    return pack_udp_packet(**fields)


def make_dns_query(**kwargs):
    """
    required fields in kwargs:
        src_addr
        dest_addr
        src_port
        dest_port
        qname
        qtype
    """
    query = dns.message.make_query(kwargs["qname"], rdtype=dns.rdatatype.TXT)
    wire = query.to_wire()

    sock = socket.socket(socket.AF_INET, socket.SOCK_RAW, socket.IPPROTO_RAW)

    # include ip header
    sock.setsockopt(socket.IPPROTO_IP, socket.IP_HDRINCL, 1)

    udp_packet = make_udp_packet(src_port=kwargs["src_port"], dest_port=kwargs["dest_port"], payload=wire)
    ip_packet = make_ip_packet(src_addr=kwargs["src_addr"], dest_addr=kwargs["dest_addr"], payload=udp_packet)

    return sock.sendto(ip_packet + udp_packet + wire, (kwargs["dest_addr"], kwargs["dest_port"]))
