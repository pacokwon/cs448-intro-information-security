from sys import argv
from oracle_python_v1_2 import pad_oracle

def get_expected_padding(padding_count):
    """
    get_expected_padding

    examples)
    1 -> 0x01
    2 -> 0x0202
    3 -> 0x030303
    """

    expected_padding = 0x0
    for _ in range(padding_count):
        # shift left by 8 bits
        expected_padding <<= 8
        expected_padding |= padding_count

    return expected_padding

def hex_to_string(hex_num):
    """
    hex_to_string

    examples)
    0x414243 -> "ABC"
    0x636261 -> "cba"
    """

    hex_string = hex(hex_num)[2:]
    bytes_object = bytes.fromhex(hex_string)
    return bytes_object.decode('utf-8')

def strip_padding(msg):
    """
    Strip trailing paddings from string
    """
    pad_len = ord(msg[-1])
    return msg[:-pad_len]


def main(c0, c1):
    block_size = 8 # block size (in bytes)
    intermediary = 0x0

    for block_no in range(block_size):
        # 1 byte == 8 bits
        shift_count = block_no * 8
        padding_count = block_no + 1
        expected_padding = get_expected_padding(padding_count)

        # the (rightmost) part of test_c0 that we already know
        test_c0_rightmost = intermediary ^ (expected_padding >> 8)

        mask_except_block = ~(0xFF << shift_count)
        mask_rightmost = (0x1 << shift_count) - 1

        # iterate from 0 ~ 255
        for byte in range(256):
            test_c0 = (byte << shift_count) | test_c0_rightmost

            ret_pad = pad_oracle(f"{test_c0:#018x}", hex(c1)).decode('utf-8')

            # correct padding
            if ret_pad == '1':
                intermediary |= (byte ^ padding_count) << shift_count
                break

    message = strip_padding(hex_to_string(intermediary ^ c0))
    print(message)


if __name__ == '__main__':
    if len(argv) < 2:
        print('Invalid number of arguments. C0 and C1 required')
        exit(1)

    c0 = int(argv[1], 16)
    c1 = int(argv[2], 16)

    main(c0, c1)
