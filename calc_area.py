#!/usr/bin/env python3
"""LG TV Area Option encoder/decoder"""

LANG_COUNTRY = {
    0: "NORDIC", 1: "NON NORDIC", 2: "EAST EU", 3: "WEST EU", 4: "ETC EU",
    5: "AJ", 6: "JA", 7: "IL", 8: "TW", 9: "CO", 10: "PA", 11: "CN",
    12: "HK", 13: "KR", 14: "US", 15: "CA", 16: "MX", 17: "HN", 18: "BR",
    19: "CL", 20: "PE", 21: "AR", 22: "EC", 23: "JP", 24: "EU", 25: "IR",
    26: "PH", 27: "BW", 28: "CS"
}

HW_GROUP = {
    0: "EU", 1: "AJ JA IL", 2: "TW CO", 3: "CN HK", 4: "KR", 5: "US", 6: "SA", 7: "JP"
}

import sys

def decode(value):
    v = int(value)
    ci = v & 0x7F
    lc = (v >> 7) & 0x1F
    hw = (v >> 12) & 0xF
    print(f"Area option: {v}")
    print(f"  continentIdx:     {ci}")
    print(f"  languageCountry:  {lc} ({LANG_COUNTRY.get(lc, '?')})")
    print(f"  hwSettingGroup:   {hw} ({HW_GROUP.get(hw, '?')})")

def encode(ci, lc, hw):
    v = int(ci) | (int(lc) << 7) | (int(hw) << 12)
    print(f"Area option: {v}")
    decode(v)

if __name__ == "__main__":
    if len(sys.argv) == 2:
        decode(sys.argv[1])
    elif len(sys.argv) == 4:
        encode(sys.argv[1], sys.argv[2], sys.argv[3])
    else:
        print("Usage:")
        print(f"  {sys.argv[0]} <area_code>                    Decode")
        print(f"  {sys.argv[0]} <continentIdx> <lang> <hw>     Encode")
        print(f"\nExamples:")
        print(f"  {sys.argv[0]} 22282        # Decode US")
        print(f"  {sys.argv[0]} 19461        # Decode EU/KR")
        print(f"  {sys.argv[0]} 10 14 5      # Encode US")
