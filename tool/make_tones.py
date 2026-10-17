#!/usr/bin/env python3
"""Generates the three built-in placeholder alarm tones (original, synthesized).

Run from the project root:  python3 tool/make_tones.py
Islamic ringtones (azan, takbeer, Quran, dua) are NOT generated: add your own
licensed recordings to assets/audio/ (see assets/audio/README.txt).
"""
import math
import pathlib
import struct
import wave

RATE = 22050
OUT = pathlib.Path("assets/audio")


def bell(freq, dur, amp=0.5):
    """A soft bell: a few harmonics with an exponential decay."""
    n = int(RATE * dur)
    out = []
    for i in range(n):
        t = i / RATE
        env = math.exp(-4.0 * t / dur) * min(1.0, t / 0.01)
        s = (
            math.sin(2 * math.pi * freq * t)
            + 0.4 * math.sin(2 * math.pi * freq * 2.01 * t)
            + 0.15 * math.sin(2 * math.pi * freq * 3.02 * t)
        )
        out.append(amp * env * s / 1.55)
    return out


def silence(dur):
    return [0.0] * int(RATE * dur)


def mix_into(track, samples, start):
    for i, v in enumerate(samples):
        j = start + i
        if j < len(track):
            track[j] += v


def write(name, samples):
    OUT.mkdir(parents=True, exist_ok=True)
    peak = max(1e-9, max(abs(s) for s in samples))
    scale = 0.9 / peak if peak > 0.9 else 1.0
    with wave.open(str(OUT / name), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(
            b"".join(
                struct.pack("<h", int(max(-1.0, min(1.0, s * scale)) * 32767))
                for s in samples
            )
        )
    print("wrote", OUT / name, f"({len(samples) / RATE:.1f}s)")


# 1. soft chime: one bell every 1.5 s, 6 s loop
track = [0.0] * (RATE * 6)
for k in range(4):
    mix_into(track, bell(880.0, 1.6), int(RATE * 1.5 * k))
write("soft_chime.wav", track)

# 2. rising bells: C5 E5 G5 C6 then a pause, 6 s loop
notes = [523.25, 659.25, 783.99, 1046.50]
track = [0.0] * (RATE * 6)
for k, f in enumerate(notes):
    mix_into(track, bell(f, 1.4), int(RATE * 0.7 * k))
write("rising_bells.wav", track)

# 3. classic beep: 4 short beeps, then a pause, 3 s loop
track = []
for _ in range(4):
    n = int(RATE * 0.18)
    for i in range(n):
        t = i / RATE
        env = min(1.0, t / 0.005) * min(1.0, (0.18 - t) / 0.005)
        track.append(0.5 * env * math.sin(2 * math.pi * 1000 * t))
    track += silence(0.12)
track += silence(3.0 - len(track) / RATE)
write("classic_beep.wav", track)
