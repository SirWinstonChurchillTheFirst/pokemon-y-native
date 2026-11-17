#!/usr/bin/env python3
"""Writes an input recording for Bergamota's boot (RUNTIME_REPLAY) from a route file.

  route.py <route.txt> <out.rec>     prints the total number of frames

Route lines (frames are the game's vertical blanks, 60 a second; # starts a comment):
  wait <n>                 nothing for n frames
  press <buttons> [n]      buttons held 6 frames (or n), then 20 frames of nothing
  hold <buttons> <n>       buttons held n frames
  stick <x> <y> <n> [buttons]   the circle pad (-1..1) for n frames, with buttons if given
  spam <buttons> <count> [gap]   pressed 6 frames, count times, gap (40) frames between
  touch <x> <y> [n]        the bottom screen (320x240) touched 6 frames (or n), then 20 of nothing
Buttons: a b select start right left up down r l x y, joined with + (a+b).
"""
import sys
BITS = dict(a=1, b=2, select=4, start=8, right=0x10, left=0x20, up=0x40, down=0x80, r=0x100, l=0x200, x=0x400, y=0x800)

def bits(word):
    return sum(BITS[b] for b in word.split("+")) if word and word != "-" else 0

def main():
    frame, lines = 0, []
    def put(n, buttons=0, x=0.0, y=0.0, tx=-1, ty=-1):
        nonlocal frame
        lines.append(f"{frame} {buttons:x} {x:.4f} {y:.4f} {tx} {ty} 0.0 0.0 0.0 0.0")
        frame += n
    for raw in open(sys.argv[1], encoding="utf-8"):
        w = raw.split("#")[0].split()
        if not w:
            continue
        if w[0] == "wait":
            put(int(w[1]))
        elif w[0] == "press":
            put(int(w[2]) if len(w) > 2 else 6, bits(w[1])); put(20)
        elif w[0] == "hold":
            put(int(w[2]), bits(w[1]))
        elif w[0] == "stick":
            put(int(w[3]), bits(w[4]) if len(w) > 4 else 0, float(w[1]), float(w[2]))
        elif w[0] == "spam":   # spam <buttons> <count> [gap frames]
            for _ in range(int(w[2])):
                put(6, bits(w[1])); put(int(w[3]) if len(w) > 3 else 40)
        elif w[0] == "touch":
            put(int(w[3]) if len(w) > 3 else 6, 0, 0, 0, int(w[1]), int(w[2])); put(20)
        else:
            sys.exit(f"bad line: {raw}")
    put(1)
    open(sys.argv[2], "w", newline="\n").write("clock 3976000000000\n" + "\n".join(lines) + "\n")
    print(frame)

if __name__ == "__main__":
    main()
