#!/usr/bin/env python3
"""
Reference implementation of Anixart Android app "Sign" request header.
Ported 1:1 from com.swiftsoft.anixartd.utils.Police (Anixart 8.5.2, smali ground truth).

Usage:
  python sign_reference.py            -> print one Sign value
  python sign_reference.py --test     -> live API check via auth/signIn
"""
import base64
import hashlib
import json
import random
import string
import sys
import time
import urllib.request
import urllib.parse

# MD5 of the APK signing certificate (extracted from CERT.RSA via keytool + python)
CERT_MD5_HEX = "9aa5c7af74e8cd70c86f7f9587bde23d"
PACKAGE_NAME = "com.swiftsoft.anixartd"
SDK_INT = 34  # Android 14; Police uses only its last digit

ALNUM = string.digits + string.ascii_lowercase + string.ascii_uppercase


def rand_alnum(n: int) -> str:
    return "".join(random.choice(ALNUM) for _ in range(n))


def rand_chars(n: int, pool) -> str:
    return "".join(chr(random.choice(pool)) for _ in range(n))


def range_list(a: int, b: int):
    return list(range(a, b + 1))


# --- Police helpers -----------------------------------------------------------

def i_reverse(s: str) -> str:
    return s[::-1]


def h_count_digits(s: str) -> int:
    return sum(1 for ch in s if ch.isdigit())


def g_shift_digits(s: str, n: int) -> str:
    """For every ASCII digit: v = (byte)c - n; if v < 0x30: v += 10."""
    out = []
    for ch in s:
        if ch.isdigit() and ch.isascii():
            v = ord(ch) - n
            if v < 0x30:
                v += 0x0A
            out.append(chr(v))
        else:
            out.append(ch)
    return "".join(out)


def e_caesar(s: str, shift: int) -> str:
    """Caesar on ASCII letters, shift % 26, wrap by 26. Other chars unchanged."""
    k = shift % ((4 * 2 - 2) + (9 * 2 + 2))  # = 26
    if k == 0:
        return s
    out = []
    for ch in s:
        c = ord(ch)
        if 0x41 <= c < 0x5B:  # A..Z
            c = c + k
            if c > 0x5A:
                c -= (9 * 3 - 1)  # 26
        elif 0x61 <= c < 0x7B:  # a..z
            c = c + k
            if c > 0x7A:
                c -= (8 * 4 - 6)  # 26
        out.append(chr(c))
    return "".join(out)


def md5_hex_lower(data: bytes) -> str:
    return hashlib.md5(data).hexdigest()


# --- Pools (verified against Police.smali) ------------------------------------

POOL1 = range_list(65, 70) + range_list(117, 122) + range_list(48, 50) + [43, 33, 38, 60, 41]
POOL2 = range_list(78, 90) + range_list(97, 109) + range_list(53, 57) + [43, 33, 38, 60, 41]
POOL3 = range_list(71, 76) + range_list(111, 116) + range_list(51, 52) + [63, 94, 40, 46, 47]
POOL4 = range_list(77, 82) + range_list(105, 110) + range_list(53, 54) + [36, 92, 37, 125, 64]
POOL5 = range_list(83, 90) + range_list(97, 104) + range_list(55, 57) + [43, 93, 62, 123, 63]
POOL6 = range_list(54, 57) + [94, 62, 126, 47]            # (minus 33 = no-op)
POOL7 = range_list(49, 53) + [37, 60, 38, 63]             # (minus 43 = no-op)
G_I5_2 = [37, 125, 91, 36, 94]
G_I5_1 = [60, 123, 93, 35, 64]

B64_NOPAD = base64.b64encode  # android Base64.NO_WRAP == no trailing newline (padding kept)


def police_sign() -> str:
    str_a = rand_alnum(4)   # str2 / strD2
    str_a2 = rand_alnum(8)  # str3 / strD
    i_h = random.randint(1, 9)

    str_d3 = rand_chars(6, POOL1)

    # timestamp body: Long.parseLong("1" + reverse(ts_seconds)) + 2112
    ts = str(int(time.time()))
    sb_val = int("1" + i_reverse(ts)) + 2112
    sb = list(str(sb_val))
    length = len(sb)
    if 1 <= length:
        i3, i4 = 1, 0
        while True:
            pos = i3 + i4
            sb.insert(pos, rand_chars(1, POOL2))
            i4 += 1
            if i3 == length:
                break
            i3 += 1
    string2 = "".join(sb)

    str_d4 = rand_chars(7, POOL3)
    str_d5 = rand_chars(4, POOL4)
    j_long_value = random.choice([99, 74, 49]) - 12
    str_d6 = rand_chars(7, POOL5)
    j2 = int(str(SDK_INT)[-1:])  # last digit of SDK_INT
    i_h2 = random.randint(10, 27)

    str4 = f"{str_d3}{string2}{str_d4}{str_d5}{j_long_value}{str_d6}{j2}{i_h2}"

    s = str(i_h2)
    i5 = int(s[0])
    i6 = int(s[-1])
    i7 = i5 + i6

    if i5 == 1:
        payload = e_caesar(g_shift_digits(str4, i7 - 1), i6)
        b64 = B64_NOPAD(payload.encode("utf-8")).decode("ascii")
        str5 = b64 + str(i6) + rand_chars(2, POOL7) + rand_chars(1, G_I5_1)
    elif i5 == 2:
        b64 = B64_NOPAD(str4.encode("utf-8")).decode("ascii")
        str5 = e_caesar(g_shift_digits(b64, i7), i6) + str(i6) + rand_chars(2, POOL6) + rand_chars(1, G_I5_2)
    else:
        return ""

    # cert md5 (constant on device; precomputed)
    str_i = i_reverse(CERT_MD5_HEX)

    # dead branch (str2.length()==7 impossible): always else -> strD2=str_a, strD=str_a2
    str_d2 = str_a
    str_d = str_a2

    str_e = e_caesar(str_i, h_count_digits(str_d2) + 1)
    pkg_e = e_caesar(PACKAGE_NAME, h_count_digits(str_d) + 2)

    combined = f"{str_d2}{str5}{str_e}{pkg_e}{str_d}"
    b64f = B64_NOPAD(combined.encode("utf-8")).decode("ascii")
    return g_shift_digits(b64f, i_h) + str(i_h) + rand_alnum(7)


def user_agent() -> str:
    return "AnixartApp/8.5.2-26032112 (Android 14; SDK 34; arm64-v8a; Google Pixel 8; ru)"


API_BASE = "https://api-s.anixsekai.com/"


def live_test():
    body = urllib.parse.urlencode({"login": "test_probe_9x", "password": "wrong-password"}).encode()
    req = urllib.request.Request(
        API_BASE + "auth/signIn",
        data=body,
        headers={
            "User-Agent": user_agent(),
            "Sign": police_sign(),
            "Content-Type": "application/x-www-form-urlencoded",
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=20) as resp:
            print("HTTP", resp.status)
            data = resp.read().decode("utf-8", "replace")
            print(data[:1000])
    except urllib.error.HTTPError as e:
        print("HTTP ERROR", e.code)
        print(e.read().decode("utf-8", "replace")[:1000])
    except Exception as e:
        print("FAIL:", e)


if __name__ == "__main__":
    if "--test" in sys.argv:
        live_test()
    else:
        for _ in range(3):
            s = police_sign()
            print(len(s), s)
