import math
import os
import shutil
import struct
import wave
from pathlib import Path
import random

SAMPLE_RATE = 44100

def clamp16(val):
    return max(-32767, min(32767, int(val * 32767.0)))

def save_stereo_wav(paths, left, right):
    n = min(len(left), len(right))
    raw = bytearray(n * 4)
    for i in range(n):
        l_int = clamp16(left[i])
        r_int = clamp16(right[i])
        struct.pack_into("<hh", raw, i * 4, l_int, r_int)
    for p in paths:
        p.parent.mkdir(parents=True, exist_ok=True)
        with wave.open(str(p), "wb") as wf:
            wf.setnchannels(2)
            wf.setsampwidth(2)
            wf.setframerate(SAMPLE_RATE)
            wf.writeframes(raw)

def env_adsr(t, dur, a=0.01, d=0.08, s=0.5, r=0.15):
    if t < 0 or t > dur:
        return 0.0
    if t < a:
        return t / max(1e-5, a)
    if t < a + d:
        return 1.0 - (1.0 - s) * ((t - a) / max(1e-5, d))
    if t < dur - r:
        return s
    return s * max(0.0, (dur - t) / max(1e-5, r))

def env_exp(t, dur, attack=0.005, decay_rate=6.0):
    if t < 0 or t > dur:
        return 0.0
    if t < attack:
        return t / max(1e-5, attack)
    return math.exp(-decay_rate * (t - attack)) * max(0.0, 1.0 - (t / dur) ** 4)

def add_stereo_reverb(left, right, delays_ms=(29, 47, 73, 113), decay=0.32):
    out_l = list(left)
    out_r = list(right)
    n = len(out_l)
    for idx, d_ms in enumerate(delays_ms):
        d_samples = int(SAMPLE_RATE * d_ms / 1000.0)
        g = decay * (0.72 ** idx)
        for i in range(d_samples, n):
            if idx % 2 == 0:
                out_l[i] += out_r[i - d_samples] * g
                out_r[i] += out_l[i - d_samples] * g * 0.9
            else:
                out_l[i] += out_l[i - d_samples] * g * 0.9
                out_r[i] += out_r[i - d_samples] * g
    peak = max(1.0, max(max(abs(x) for x in out_l), max(abs(x) for x in out_r)))
    if peak > 0.98:
        scale = 0.95 / peak
        out_l = [x * scale for x in out_l]
        out_r = [x * scale for x in out_r]
    return out_l, out_r

def synth_ui_hover():
    dur = 0.14
    n = int(SAMPLE_RATE * dur)
    l, r = [0.0] * n, [0.0] * n
    for i in range(n):
        t = i / SAMPLE_RATE
        e = env_exp(t, dur, 0.003, 24.0)
        f = 1850.0 + 950.0 * (t / dur)
        sig = 0.42 * math.sin(2 * math.pi * f * t) + 0.18 * math.sin(2 * math.pi * f * 1.5 * t)
        l[i] = sig * e * 0.9
        r[i] = sig * e
    return add_stereo_reverb(l, r, (19, 37), 0.22)

def synth_ui_click():
    dur = 0.18
    n = int(SAMPLE_RATE * dur)
    l, r = [0.0] * n, [0.0] * n
    rng = random.Random(101)
    for i in range(n):
        t = i / SAMPLE_RATE
        e_click = env_exp(t, dur, 0.001, 45.0)
        e_tone = env_exp(t, dur, 0.002, 18.0)
        transient = (rng.uniform(-1, 1) * 0.35 + math.sin(2 * math.pi * 240 * t) * 0.65) * e_click
        chime = (math.sin(2 * math.pi * 1320 * t) * 0.45 + math.sin(2 * math.pi * 1980 * t) * 0.28) * e_tone
        sig = (transient + chime) * 0.75
        l[i] = sig
        r[i] = sig * 0.96
    return add_stereo_reverb(l, r, (23, 41), 0.25)

def synth_ui_tab():
    dur = 0.28
    n = int(SAMPLE_RATE * dur)
    l, r = [0.0] * n, [0.0] * n
    rng = random.Random(202)
    lp = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        e = env_exp(t, dur, 0.012, 10.5)
        noise = rng.uniform(-1, 1)
        cutoff = 0.12 + 0.35 * math.sin(math.pi * t / dur)
        lp = lp + cutoff * (noise - lp)
        f1 = 587.33 if t < 0.07 else 880.0
        tone = 0.38 * math.sin(2 * math.pi * f1 * t) + 0.18 * math.sin(2 * math.pi * f1 * 2 * t)
        pan = 0.5 + 0.3 * math.sin(2 * math.pi * 3.0 * t)
        sig = (lp * 0.45 + tone) * e * 0.8
        l[i] = sig * pan
        r[i] = sig * (1.0 - pan * 0.4)
    return add_stereo_reverb(l, r, (29, 53), 0.28)

def synth_sword_swing(pitch_mult=1.0, seed=1):
    dur = 0.34
    n = int(SAMPLE_RATE * dur)
    l, r = [0.0] * n, [0.0] * n
    rng = random.Random(seed)
    bp1, bp2 = 0.0, 0.0
    phase = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        u = t / dur
        whoosh_env = math.sin(math.pi * (u ** 0.7)) * env_exp(t, dur, 0.018, 5.5)
        f_sweep = (320.0 + 1600.0 * math.sin(math.pi * u)) * pitch_mult
        phase += 2 * math.pi * f_sweep / SAMPLE_RATE
        noise = rng.uniform(-1, 1)
        alpha = min(0.85, f_sweep / (SAMPLE_RATE * 0.25))
        bp1 += alpha * (noise - bp1)
        bp2 += alpha * (bp1 - bp2)
        band = bp1 - bp2
        steel = (
            0.26 * math.sin(2 * math.pi * 1480 * pitch_mult * t)
            + 0.16 * math.sin(2 * math.pi * 2340 * pitch_mult * t)
            + 0.10 * math.sin(2 * math.pi * 3720 * pitch_mult * t)
        ) * env_exp(t, dur, 0.004, 14.0)
        air = (band * 1.4 + 0.35 * math.sin(phase)) * whoosh_env
        sig = (air + steel) * 0.85
        l[i] = sig * (0.9 + 0.2 * math.cos(u * math.pi))
        r[i] = sig * (0.9 + 0.2 * math.sin(u * math.pi))
    return add_stereo_reverb(l, r, (23, 47), 0.24)

def synth_heavy_cleave():
    dur = 0.58
    n = int(SAMPLE_RATE * dur)
    l, r = [0.0] * n, [0.0] * n
    rng = random.Random(77)
    lp = 0.0
    phase = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        u = t / dur
        e = env_exp(t, dur, 0.025, 4.2)
        f_sub = 190.0 * math.exp(-3.8 * t) + 45.0
        phase += 2 * math.pi * f_sub / SAMPLE_RATE
        sub = math.tanh(1.8 * math.sin(phase)) * 0.62
        noise = rng.uniform(-1, 1)
        lp += 0.18 * (noise - lp)
        blade = (
            0.32 * math.sin(2 * math.pi * (920 - 300 * u) * t)
            + 0.22 * math.sin(2 * math.pi * (1840 - 450 * u) * t)
        ) * env_exp(t, dur, 0.01, 7.5)
        sig = (sub + lp * 0.55 + blade) * e * 0.9
        l[i] = sig
        r[i] = sig * 0.97
    return add_stereo_reverb(l, r, (31, 61, 97), 0.32)

def synth_dodge_dash():
    dur = 0.30
    n = int(SAMPLE_RATE * dur)
    l, r = [0.0] * n, [0.0] * n
    rng = random.Random(303)
    lp = 0.0
    phase = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        u = t / dur
        e = env_exp(t, dur, 0.01, 7.5)
        f = 420.0 + 1450.0 * (u ** 0.5)
        phase += 2 * math.pi * f / SAMPLE_RATE
        noise = rng.uniform(-1, 1)
        lp += 0.25 * (noise - lp)
        sig = (lp * 0.55 + math.sin(phase) * 0.38) * e * 0.8
        l[i] = sig * (1.0 - 0.3 * u)
        r[i] = sig * (0.7 + 0.3 * u)
    return add_stereo_reverb(l, r, (21, 43), 0.25)

def synth_hit_normal():
    dur = 0.26
    n = int(SAMPLE_RATE * dur)
    l, r = [0.0] * n, [0.0] * n
    rng = random.Random(404)
    phase = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        e_body = env_exp(t, dur, 0.002, 18.0)
        e_snap = env_exp(t, dur, 0.001, 42.0)
        f = 220.0 * math.exp(-22.0 * t) + 52.0
        phase += 2 * math.pi * f / SAMPLE_RATE
        body = math.tanh(2.1 * math.sin(phase)) * e_body * 0.72
        snap = (rng.uniform(-1, 1) * 0.6 + math.sin(2 * math.pi * 1650 * t) * 0.4) * e_snap * 0.55
        sig = body + snap
        l[i] = sig
        r[i] = sig * 0.95
    return add_stereo_reverb(l, r, (19, 39), 0.22)

def synth_hit_crit():
    dur = 0.42
    n = int(SAMPLE_RATE * dur)
    l, r = [0.0] * n, [0.0] * n
    rng = random.Random(505)
    phase = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        e_body = env_exp(t, dur, 0.002, 12.0)
        e_ring = env_exp(t, dur, 0.004, 8.5)
        f = 310.0 * math.exp(-18.0 * t) + 58.0
        phase += 2 * math.pi * f / SAMPLE_RATE
        punch = math.tanh(2.4 * math.sin(phase)) * e_body * 0.68
        shatter = rng.uniform(-1, 1) * env_exp(t, dur, 0.001, 28.0) * 0.48
        chord = (
            0.28 * math.sin(2 * math.pi * 1046.5 * t)
            + 0.24 * math.sin(2 * math.pi * 1318.5 * t)
            + 0.22 * math.sin(2 * math.pi * 1567.98 * t)
            + 0.18 * math.sin(2 * math.pi * 2093.0 * t)
        ) * e_ring
        sig = (punch + shatter + chord) * 0.85
        l[i] = sig
        r[i] = sig * 0.98
    return add_stereo_reverb(l, r, (27, 53, 83), 0.34)

def synth_hit_break():
    dur = 0.75
    n = int(SAMPLE_RATE * dur)
    l, r = [0.0] * n, [0.0] * n
    rng = random.Random(606)
    phase = 0.0
    shards = [1180, 1540, 1920, 2480, 3120, 3860]
    for i in range(n):
        t = i / SAMPLE_RATE
        f_drop = 180.0 * math.exp(-4.5 * t) + 34.0
        phase += 2 * math.pi * f_drop / SAMPLE_RATE
        sub = math.tanh(2.5 * math.sin(phase)) * env_exp(t, dur, 0.003, 5.0) * 0.65
        glass = 0.0
        for idx, sf in enumerate(shards):
            delay = idx * 0.018
            if t >= delay:
                glass += math.sin(2 * math.pi * (sf + 80 * math.sin(35 * t)) * (t - delay)) * env_exp(t - delay, dur, 0.002, 9.0) * 0.14
        burst = rng.uniform(-1, 1) * env_exp(t, dur, 0.002, 16.0) * 0.42
        sig = (sub + glass + burst) * 0.88
        l[i] = sig * (0.95 + 0.05 * math.sin(t * 20))
        r[i] = sig * (0.95 + 0.05 * math.cos(t * 20))
    return add_stereo_reverb(l, r, (37, 71, 113, 163), 0.42)

def synth_skill_sky_slash():
    dur = 0.52
    n = int(SAMPLE_RATE * dur)
    l, r = [0.0] * n, [0.0] * n
    rng = random.Random(707)
    lp = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        u = t / dur
        e = env_exp(t, dur, 0.012, 5.8)
        f_carrier = 660.0 + 440.0 * math.sin(math.pi * u)
        mod = math.sin(2 * math.pi * (f_carrier * 2.0) * t) * 1.4 * env_exp(t, dur, 0.005, 9.0)
        solar = math.sin(2 * math.pi * f_carrier * t + mod) * 0.45
        harmonic = (math.sin(2 * math.pi * 1320 * t) * 0.22 + math.sin(2 * math.pi * 1980 * t) * 0.15) * e
        lp += 0.22 * (rng.uniform(-1, 1) - lp)
        sig = (solar * e + harmonic + lp * 0.35 * e) * 0.88
        l[i] = sig
        r[i] = sig * 0.96
    return add_stereo_reverb(l, r, (29, 59, 97), 0.36)

def synth_skill_guardian_shield():
    dur = 0.72
    n = int(SAMPLE_RATE * dur)
    l, r = [0.0] * n, [0.0] * n
    freqs = [349.23, 440.0, 523.25, 698.46, 880.0]
    for i in range(n):
        t = i / SAMPLE_RATE
        e = env_adsr(t, dur, 0.04, 0.15, 0.65, 0.28)
        chord = 0.0
        for idx, f in enumerate(freqs):
            detune = 1.0 + (idx - 2) * 0.0025
            chord += math.sin(2 * math.pi * f * detune * t + 0.4 * math.sin(2 * math.pi * 6.0 * t)) * (0.22 - idx * 0.02)
        pulse = math.sin(2 * math.pi * (140 + 180 * (t / dur)) * t) * env_exp(t, dur, 0.01, 6.0) * 0.32
        sig = (chord * e + pulse) * 0.85
        l[i] = sig * (0.9 + 0.1 * math.sin(t * 9))
        r[i] = sig * (0.9 + 0.1 * math.cos(t * 9))
    return add_stereo_reverb(l, r, (37, 73, 119, 167), 0.44)

def synth_skill_judgment_strike():
    dur = 0.78
    n = int(SAMPLE_RATE * dur)
    l, r = [0.0] * n, [0.0] * n
    rng = random.Random(808)
    phase = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        if t < 0.18:
            u = t / 0.18
            f_whistle = 1800.0 - 1250.0 * (u ** 1.3)
            phase += 2 * math.pi * f_whistle / SAMPLE_RATE
            sig = math.sin(phase) * (0.35 + 0.55 * u)
        else:
            tb = t - 0.18
            eb = env_exp(tb, dur - 0.18, 0.003, 4.8)
            f_boom = 160.0 * math.exp(-7.0 * tb) + 38.0
            phase += 2 * math.pi * f_boom / SAMPLE_RATE
            boom = math.tanh(2.6 * math.sin(phase)) * 0.68
            chime = (
                0.26 * math.sin(2 * math.pi * 880 * tb)
                + 0.20 * math.sin(2 * math.pi * 1320 * tb)
                + 0.16 * math.sin(2 * math.pi * 1760 * tb)
            )
            crackle = rng.uniform(-1, 1) * env_exp(tb, dur - 0.18, 0.001, 14.0) * 0.45
            sig = (boom + chime + crackle) * eb
        l[i] = sig * 0.9
        r[i] = sig * 0.9
    return add_stereo_reverb(l, r, (33, 67, 109, 157), 0.42)

def synth_skill_thunder_strike():
    dur = 0.62
    n = int(SAMPLE_RATE * dur)
    l, r = [0.0] * n, [0.0] * n
    rng = random.Random(909)
    phase = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        e = env_exp(t, dur, 0.002, 5.5)
        zap_f = 950.0 * math.exp(-9.0 * t) + 120.0 + 280.0 * math.sin(2 * math.pi * 48.0 * t)
        phase += 2 * math.pi * zap_f / SAMPLE_RATE
        arc = math.tanh(2.8 * (math.sin(phase) * 0.65 + rng.uniform(-1, 1) * 0.55))
        sub = math.sin(2 * math.pi * (95.0 * math.exp(-4.0 * t) + 42.0) * t) * 0.48
        sig = (arc * 0.58 + sub) * e * 0.85
        l[i] = sig * (0.85 + 0.15 * math.sin(t * 55))
        r[i] = sig * (0.85 + 0.15 * math.cos(t * 55))
    return add_stereo_reverb(l, r, (23, 51, 89), 0.35)

def synth_skill_frost_shatter():
    dur = 0.64
    n = int(SAMPLE_RATE * dur)
    l, r = [0.0] * n, [0.0] * n
    rng = random.Random(1010)
    crystal_freqs = [1567.98, 1975.53, 2349.32, 2637.02, 3135.96, 3951.07]
    for i in range(n):
        t = i / SAMPLE_RATE
        e = env_exp(t, dur, 0.004, 5.2)
        crystals = 0.0
        for idx, cf in enumerate(crystal_freqs):
            trig = (idx * 0.022)
            if t >= trig:
                dt = t - trig
                crystals += math.sin(2 * math.pi * cf * dt) * env_exp(dt, dur - trig, 0.002, 9.5) * 0.18
        wind = rng.uniform(-1, 1) * env_exp(t, dur, 0.015, 7.5) * 0.32
        sub = math.sin(2 * math.pi * (140 * math.exp(-8 * t) + 65) * t) * env_exp(t, dur, 0.003, 9.0) * 0.38
        sig = (crystals + wind + sub) * e * 0.95
        l[i] = sig
        r[i] = sig * 0.96
    return add_stereo_reverb(l, r, (31, 67, 107, 149), 0.45)

def synth_skill_void_rift():
    dur = 0.82
    n = int(SAMPLE_RATE * dur)
    l, r = [0.0] * n, [0.0] * n
    phase = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        u = t / dur
        e = env_adsr(t, dur, 0.03, 0.18, 0.65, 0.28)
        f_warp = 135.0 - 75.0 * math.sin(math.pi * u) + 18.0 * math.sin(2 * math.pi * 14.0 * t)
        phase += 2 * math.pi * f_warp / SAMPLE_RATE
        dark_bass = math.tanh(2.4 * math.sin(phase)) * 0.62
        singularity = (
            math.sin(2 * math.pi * (440.0 - 190.0 * u) * t + 2.2 * math.sin(2 * math.pi * 7.5 * t)) * 0.34
            + math.sin(2 * math.pi * (660.0 - 260.0 * u) * t) * 0.20
        )
        sig = (dark_bass + singularity) * e * 0.88
        l[i] = sig * (0.9 + 0.1 * math.sin(t * 12))
        r[i] = sig * (0.9 + 0.1 * math.cos(t * 12))
    return add_stereo_reverb(l, r, (41, 83, 131, 181), 0.46)

def synth_boss_telegraph():
    dur = 0.46
    n = int(SAMPLE_RATE * dur)
    l, r = [0.0] * n, [0.0] * n
    for i in range(n):
        t = i / SAMPLE_RATE
        local_t = t if t < 0.22 else (t - 0.22)
        f = 880.0 if t < 0.22 else 1174.66
        e = env_exp(local_t, 0.22, 0.004, 14.0)
        sig = (0.55 * math.sin(2 * math.pi * f * local_t) + 0.28 * math.sin(2 * math.pi * f * 2 * local_t)) * e * 0.78
        l[i] = sig
        r[i] = sig
    return add_stereo_reverb(l, r, (29, 59), 0.30)

def synth_boss_roar():
    dur = 1.05
    n = int(SAMPLE_RATE * dur)
    l, r = [0.0] * n, [0.0] * n
    rng = random.Random(1212)
    phase1, phase2 = 0.0, 0.0
    lp = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        u = t / dur
        e = env_adsr(t, dur, 0.06, 0.22, 0.72, 0.32)
        f1 = 92.0 - 28.0 * u + 8.0 * math.sin(2 * math.pi * 19.0 * t)
        f2 = 138.0 - 42.0 * u + 11.0 * math.cos(2 * math.pi * 23.0 * t)
        phase1 += 2 * math.pi * f1 / SAMPLE_RATE
        phase2 += 2 * math.pi * f2 / SAMPLE_RATE
        growl = math.tanh(2.8 * (math.sin(phase1) * 0.6 + math.sin(phase2) * 0.45))
        lp += 0.14 * (rng.uniform(-1, 1) - lp)
        formant = math.sin(2 * math.pi * (380.0 - 110.0 * u) * t) * 0.28
        sig = (growl * 0.65 + lp * 0.45 + formant) * e * 0.9
        l[i] = sig
        r[i] = sig * 0.97
    return add_stereo_reverb(l, r, (43, 89, 139, 193), 0.45)

def synth_level_up():
    dur = 1.15
    n = int(SAMPLE_RATE * dur)
    l, r = [0.0] * n, [0.0] * n
    notes = [
        (0.00, 523.25),   # C5
        (0.11, 659.25),   # E5
        (0.22, 783.99),   # G5
        (0.33, 987.77),   # B5
        (0.45, 1046.50),  # C6
    ]
    for i in range(n):
        t = i / SAMPLE_RATE
        sig_l, sig_r = 0.0, 0.0
        for idx, (start_t, freq) in enumerate(notes):
            if t >= start_t:
                dt = t - start_t
                e = env_exp(dt, dur - start_t, 0.006, 3.6 if idx == 4 else 6.0)
                tone = (
                    0.42 * math.sin(2 * math.pi * freq * dt)
                    + 0.22 * math.sin(2 * math.pi * freq * 2.0 * dt)
                    + 0.12 * math.sin(2 * math.pi * freq * 3.0 * dt)
                ) * e
                pan = 0.35 + 0.15 * idx
                sig_l += tone * pan
                sig_r += tone * (1.15 - pan * 0.5)
        l[i] = sig_l * 0.72
        r[i] = sig_r * 0.72
    return add_stereo_reverb(l, r, (37, 73, 113, 163), 0.44)

def synth_quest_complete():
    dur = 1.25
    n = int(SAMPLE_RATE * dur)
    l, r = [0.0] * n, [0.0] * n
    chords = [
        (0.00, 0.32, [349.23, 440.00, 523.25]),          # F major
        (0.28, 0.32, [392.00, 493.88, 587.33]),          # G major
        (0.56, 0.69, [523.25, 659.25, 783.99, 1046.50]), # C major
    ]
    for i in range(n):
        t = i / SAMPLE_RATE
        sig = 0.0
        for start_t, length, freqs in chords:
            if t >= start_t:
                dt = t - start_t
                e = env_exp(dt, dur - start_t, 0.008, 3.8 if len(freqs) == 4 else 6.5)
                for f in freqs:
                    sig += (0.22 * math.sin(2 * math.pi * f * dt) + 0.10 * math.sin(2 * math.pi * f * 2 * dt)) * e
        l[i] = sig * 0.75
        r[i] = sig * 0.78
    return add_stereo_reverb(l, r, (41, 79, 127, 179), 0.45)

def synth_forge_anvil():
    dur = 0.85
    n = int(SAMPLE_RATE * dur)
    l, r = [0.0] * n, [0.0] * n
    rng = random.Random(1414)
    anvil_modes = [1120.0, 1780.0, 2640.0, 3520.0]
    for i in range(n):
        t = i / SAMPLE_RATE
        # Two hammer strikes at t=0.0 and t=0.28 + quench shimmer
        sig = 0.0
        for strike_idx, st in enumerate((0.0, 0.28)):
            if t >= st:
                dt = t - st
                pitch_boost = 1.0 if strike_idx == 0 else 1.18
                e_ring = env_exp(dt, dur - st, 0.001, 7.5)
                e_hit = env_exp(dt, dur - st, 0.001, 35.0)
                for m_idx, mf in enumerate(anvil_modes):
                    sig += math.sin(2 * math.pi * mf * pitch_boost * dt) * e_ring * (0.24 / (m_idx + 1))
                sig += rng.uniform(-1, 1) * e_hit * 0.42
        if t >= 0.32:
            dt = t - 0.32
            shimmer = (
                0.22 * math.sin(2 * math.pi * 1046.5 * dt)
                + 0.18 * math.sin(2 * math.pi * 1567.98 * dt)
            ) * env_exp(dt, dur - 0.32, 0.01, 4.5)
            sig += shimmer
        l[i] = sig * 0.82
        r[i] = sig * 0.82
    return add_stereo_reverb(l, r, (31, 61, 97), 0.38)

def synth_potion_heal():
    dur = 0.68
    n = int(SAMPLE_RATE * dur)
    l, r = [0.0] * n, [0.0] * n
    notes = [587.33, 739.99, 880.0, 1174.66, 1479.98]
    for i in range(n):
        t = i / SAMPLE_RATE
        sig = 0.0
        for idx, f in enumerate(notes):
            st = idx * 0.075
            if t >= st:
                dt = t - st
                e = env_exp(dt, dur - st, 0.005, 6.5)
                sig += (0.28 * math.sin(2 * math.pi * f * dt) + 0.14 * math.sin(2 * math.pi * f * 2 * dt)) * e
        l[i] = sig * 0.8
        r[i] = sig * 0.84
    return add_stereo_reverb(l, r, (29, 59, 97), 0.40)

def synth_chest_open():
    dur = 0.95
    n = int(SAMPLE_RATE * dur)
    l, r = [0.0] * n, [0.0] * n
    notes = [523.25, 659.25, 783.99, 1046.50, 1318.51, 1567.98]
    for i in range(n):
        t = i / SAMPLE_RATE
        sig = 0.0
        if t < 0.08:
            sig += math.sin(2 * math.pi * 280 * t) * env_exp(t, 0.08, 0.001, 35.0) * 0.5
        for idx, f in enumerate(notes):
            st = 0.06 + idx * 0.08
            if t >= st:
                dt = t - st
                e = env_exp(dt, dur - st, 0.004, 5.2)
                sig += (0.26 * math.sin(2 * math.pi * f * dt) + 0.14 * math.sin(2 * math.pi * f * 2 * dt)) * e
        l[i] = sig * 0.78
        r[i] = sig * 0.80
    return add_stereo_reverb(l, r, (37, 73, 119), 0.42)

def synth_shrine_bless():
    dur = 1.10
    n = int(SAMPLE_RATE * dur)
    l, r = [0.0] * n, [0.0] * n
    freqs = [440.0, 554.37, 659.25, 880.0, 1108.73]
    for i in range(n):
        t = i / SAMPLE_RATE
        e = env_adsr(t, dur, 0.05, 0.20, 0.65, 0.35)
        sig = 0.0
        for idx, f in enumerate(freqs):
            sig += math.sin(2 * math.pi * f * t + 0.3 * math.sin(2 * math.pi * 5.0 * t)) * (0.22 - idx * 0.025)
        l[i] = sig * e * 0.85
        r[i] = sig * e * 0.88
    return add_stereo_reverb(l, r, (43, 89, 139, 193), 0.48)

def synth_ambient_sky_wind():
    dur = 3.0
    n = int(SAMPLE_RATE * dur)
    l, r = [0.0] * n, [0.0] * n
    rng = random.Random(2026)
    lp_l, lp_r = 0.0, 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        u = t / dur
        fade = math.sin(math.pi * u) ** 0.35
        nl = rng.uniform(-1, 1)
        nr = rng.uniform(-1, 1)
        alpha = 0.035 + 0.02 * math.sin(2 * math.pi * u)
        lp_l += alpha * (nl - lp_l)
        lp_r += alpha * (nr - lp_r)
        pad = (
            0.12 * math.sin(2 * math.pi * 220.0 * t)
            + 0.09 * math.sin(2 * math.pi * 329.63 * t)
            + 0.07 * math.sin(2 * math.pi * 440.0 * t)
        )
        l[i] = (lp_l * 0.55 + pad) * fade * 0.55
        r[i] = (lp_r * 0.55 + pad) * fade * 0.55
    return add_stereo_reverb(l, r, (47, 97), 0.35)

def synth_bgm_goldensky():
    import numpy as np
    dur = 16.0
    n = int(SAMPLE_RATE * dur)
    t = np.linspace(0.0, dur, n, endpoint=False)
    sig_l = np.zeros(n, dtype=np.float64)
    sig_r = np.zeros(n, dtype=np.float64)

    # 4-bar chord progression (4.0s per bar): Fmaj7 -> G6 -> Em7 -> Am9
    chords = [
        (0.0, 4.0, 87.31, [174.61, 220.00, 261.63, 329.63]),
        (4.0, 4.0, 98.00, [196.00, 246.94, 293.66, 329.63]),
        (8.0, 4.0, 82.41, [164.81, 196.00, 246.94, 293.66]),
        (12.0, 4.0, 110.00, [220.00, 261.63, 329.63, 392.00]),
    ]
    for start, length, bass_f, pad_freqs in chords:
        mask = (t >= start) & (t < start + length)
        lt = t[mask] - start
        env = np.sin(np.pi * lt / length) ** 0.45
        bass = 0.22 * np.sin(2 * np.pi * bass_f * lt) + 0.08 * np.sin(2 * np.pi * bass_f * 2 * lt)
        pad_l = np.zeros_like(lt)
        pad_r = np.zeros_like(lt)
        for idx, pf in enumerate(pad_freqs):
            vib = 0.25 * np.sin(2 * np.pi * 4.2 * lt + idx)
            voice = 0.10 * np.sin(2 * np.pi * pf * lt + vib) + 0.04 * np.sin(2 * np.pi * pf * 2 * lt)
            pad_l += voice * (0.8 + 0.15 * (idx % 2))
            pad_r += voice * (0.95 - 0.15 * (idx % 2))
        sig_l[mask] += (bass + pad_l) * env
        sig_r[mask] += (bass + pad_r) * env

    # Celestial harp arpeggio (32 eighth-notes at 0.5s each)
    arp_patterns = [
        [523.25, 659.25, 783.99, 1046.50, 783.99, 659.25, 880.00, 659.25],
        [587.33, 783.99, 987.77, 1174.66, 987.77, 783.99, 880.00, 783.99],
        [493.88, 659.25, 783.99, 987.77, 783.99, 659.25, 587.33, 659.25],
        [440.00, 523.25, 659.25, 880.00, 1046.50, 880.00, 783.99, 659.25],
    ]
    for bar_idx, pat in enumerate(arp_patterns):
        for step_idx, nf in enumerate(pat):
            st = bar_idx * 4.0 + step_idx * 0.5
            end_t = min(dur, st + 0.95)
            mask = (t >= st) & (t < end_t)
            lt = t[mask] - st
            env = np.exp(-4.2 * lt) * np.minimum(1.0, lt / 0.008)
            pluck = (
                0.18 * np.sin(2 * np.pi * nf * lt)
                + 0.08 * np.sin(2 * np.pi * nf * 2.0 * lt)
                + 0.04 * np.sin(2 * np.pi * nf * 3.0 * lt)
            ) * env
            pan = 0.35 + 0.45 * ((step_idx % 4) / 3.0)
            sig_l[mask] += pluck * pan
            sig_r[mask] += pluck * (1.15 - pan * 0.6)

    return add_stereo_reverb(sig_l.tolist(), sig_r.tolist(), (43, 89, 149), 0.36)

def synth_bgm_frozencyber():
    import numpy as np
    dur = 16.0
    n = int(SAMPLE_RATE * dur)
    t = np.linspace(0.0, dur, n, endpoint=False)
    sig_l = np.zeros(n, dtype=np.float64)
    sig_r = np.zeros_like(sig_l)

    # Cyber-Glacial progression: Dm9 -> Bbmaj7 -> Fmaj7 -> Csus4
    chords = [
        (0.0, 4.0, 73.42, [293.66, 349.23, 440.00, 523.25]),
        (4.0, 4.0, 58.27, [233.08, 293.66, 349.23, 440.00]),
        (8.0, 4.0, 87.31, [261.63, 329.63, 392.00, 523.25]),
        (12.0, 4.0, 65.41, [261.63, 349.23, 392.00, 523.25]),
    ]
    for start, length, bass_f, pad_freqs in chords:
        mask = (t >= start) & (t < start + length)
        lt = t[mask] - start
        env = np.sin(np.pi * lt / length) ** 0.4
        # Rhythmic 8th-note synthwave bass pulse
        pulse_env = 0.55 + 0.45 * np.cos(2 * np.pi * 4.0 * lt)
        bass = np.tanh(1.6 * np.sin(2 * np.pi * bass_f * lt + 0.8 * np.sin(2 * np.pi * bass_f * 2 * lt))) * 0.18 * pulse_env
        pad = np.zeros_like(lt)
        for pf in pad_freqs:
            pad += 0.08 * np.sin(2 * np.pi * pf * lt + 0.3 * np.sin(2 * np.pi * 3.5 * lt))
        sig_l[mask] += (bass + pad) * env
        sig_r[mask] += (bass + pad * 0.96) * env

    # Crystalline 16th-note cyber sequence (0.25s per step)
    seq = [587.33, 698.46, 880.00, 1174.66, 1046.50, 880.00, 698.46, 880.00]
    for step in range(64):
        st = step * 0.25
        nf = seq[step % len(seq)] * (1.0 if step < 32 else 1.12246)
        end_t = min(dur, st + 0.45)
        mask = (t >= st) & (t < end_t)
        lt = t[mask] - st
        env = np.exp(-8.5 * lt) * np.minimum(1.0, lt / 0.004)
        bell = (0.14 * np.sin(2 * np.pi * nf * lt) + 0.07 * np.sin(2 * np.pi * nf * 2.5 * lt)) * env
        pan = 0.3 + 0.5 * ((step % 2))
        sig_l[mask] += bell * pan
        sig_r[mask] += bell * (1.1 - pan * 0.5)

    return add_stereo_reverb(sig_l.tolist(), sig_r.tolist(), (37, 79, 131), 0.38)

def synth_bgm_shadowrealm():
    import numpy as np
    dur = 16.0
    n = int(SAMPLE_RATE * dur)
    t = np.linspace(0.0, dur, n, endpoint=False)
    sig_l = np.zeros(n, dtype=np.float64)
    sig_r = np.zeros_like(sig_l)

    # Dark Void Choir progression: Cm(add9) -> Abmaj7(#11) -> Fm9 -> G7(b9)
    chords = [
        (0.0, 4.0, 65.41, [130.81, 196.00, 293.66, 311.13]),
        (4.0, 4.0, 51.91, [155.56, 207.65, 293.66, 392.00]),
        (8.0, 4.0, 43.65, [174.61, 207.65, 261.63, 392.00]),
        (12.0, 4.0, 49.00, [146.83, 196.00, 246.94, 415.30]),
    ]
    for start, length, bass_f, choir_freqs in chords:
        mask = (t >= start) & (t < start + length)
        lt = t[mask] - start
        env = np.sin(np.pi * lt / length) ** 0.45
        drone = np.tanh(1.8 * np.sin(2 * np.pi * bass_f * lt)) * 0.22
        choir_l = np.zeros_like(lt)
        choir_r = np.zeros_like(lt)
        for idx, cf in enumerate(choir_freqs):
            mod = 0.45 * np.sin(2 * np.pi * 2.8 * lt + idx)
            v = 0.09 * np.sin(2 * np.pi * cf * lt + mod) + 0.05 * np.sin(2 * np.pi * cf * 1.5 * lt)
            choir_l += v * (0.85 + 0.1 * (idx % 2))
            choir_r += v * (0.95 - 0.1 * (idx % 2))
        sig_l[mask] += (drone + choir_l) * env
        sig_r[mask] += (drone + choir_r) * env

    # Haunting astral chimes
    chime_notes = [783.99, 622.25, 587.33, 523.25, 622.25, 783.99, 932.33, 739.99]
    for idx, cf in enumerate(chime_notes):
        st = idx * 2.0 + 0.25
        end_t = min(dur, st + 1.8)
        mask = (t >= st) & (t < end_t)
        lt = t[mask] - st
        env = np.exp(-2.8 * lt) * np.minimum(1.0, lt / 0.01)
        chime = (0.15 * np.sin(2 * np.pi * cf * lt) + 0.07 * np.sin(2 * np.pi * cf * 2.0 * lt)) * env
        sig_l[mask] += chime * 0.75
        sig_r[mask] += chime * 0.85

    return add_stereo_reverb(sig_l.tolist(), sig_r.tolist(), (53, 107, 173), 0.44)

def synth_bgm_boss_battle():
    import numpy as np
    dur = 12.0
    n = int(SAMPLE_RATE * dur)
    t = np.linspace(0.0, dur, n, endpoint=False)
    sig_l = np.zeros(n, dtype=np.float64)
    sig_r = np.zeros_like(sig_l)

    # Epic 160 BPM Boss Battle Ostinato (4 bars of 3.0s = 12.0s loop)
    chords = [
        (0.0, 3.0, 82.41, [164.81, 246.94, 329.63, 392.00]),   # Em
        (3.0, 3.0, 65.41, [130.81, 196.00, 261.63, 392.00]),   # C
        (6.0, 3.0, 73.42, [146.83, 220.00, 293.66, 440.00]),   # D
        (9.0, 3.0, 61.74, [123.47, 185.00, 246.94, 369.99]),   # B7
    ]
    for start, length, bass_f, brass_freqs in chords:
        mask = (t >= start) & (t < start + length)
        lt = t[mask] - start
        env = np.minimum(1.0, lt / 0.03) * np.minimum(1.0, (length - lt) / 0.05)
        brass = np.zeros_like(lt)
        for bf in brass_freqs:
            brass += 0.08 * np.tanh(1.6 * np.sin(2 * np.pi * bf * lt + 0.6 * np.sin(2 * np.pi * bf * lt)))
        sig_l[mask] += brass * env
        sig_r[mask] += brass * env * 0.96

    # Driving war-drums + fast string ostinato (48 steps of 0.25s)
    ostinato = [329.63, 329.63, 392.00, 440.00, 493.88, 523.25, 493.88, 392.00, 329.63, 392.00, 493.88, 659.25]
    for step in range(48):
        st = step * 0.25
        end_t = min(dur, st + 0.24)
        mask = (t >= st) & (t < end_t)
        lt = t[mask] - st
        # War drum kick on even steps, tom/snare accent on odd steps
        if step % 2 == 0:
            f_kick = 135.0 * np.exp(-24.0 * lt) + 46.0
            drum = np.tanh(2.5 * np.sin(2 * np.pi * f_kick * lt)) * np.exp(-10.0 * lt) * 0.34
        else:
            f_tom = 210.0 * np.exp(-28.0 * lt) + 82.0
            drum = np.tanh(2.0 * np.sin(2 * np.pi * f_tom * lt)) * np.exp(-14.0 * lt) * 0.24
        nf = ostinato[step % len(ostinato)]
        str_env = np.exp(-9.0 * lt) * np.minimum(1.0, lt / 0.005)
        staccato = (0.18 * np.sin(2 * np.pi * nf * lt) + 0.09 * np.sin(2 * np.pi * nf * 2 * lt)) * str_env
        sig_l[mask] += drum + staccato * (0.85 if step % 2 == 0 else 0.55)
        sig_r[mask] += drum + staccato * (0.55 if step % 2 == 0 else 0.85)

    return add_stereo_reverb(sig_l.tolist(), sig_r.tolist(), (31, 67, 109), 0.34)

def main():
    out_dir = Path(r"C:\Users\khang\Documents\Codex\2026-10-22\new-chat\outputs\SKYBREAK_Antigravity_Handoff\07_Audio_SFX")
    out_dir.mkdir(parents=True, exist_ok=True)

    roblox_versions_root = Path(os.environ.get("LOCALAPPDATA", "")) / "Roblox" / "Versions"
    studio_sound_dirs = []
    if roblox_versions_root.exists():
        for vdir in roblox_versions_root.iterdir():
            sdir = vdir / "content" / "sounds"
            if sdir.exists():
                studio_sound_dirs.append(sdir / "skybreak")

    generators = {
        "ui_hover.wav": synth_ui_hover,
        "ui_click.wav": synth_ui_click,
        "ui_tab.wav": synth_ui_tab,
        "sword_swing_1.wav": lambda: synth_sword_swing(0.95, 11),
        "sword_swing_2.wav": lambda: synth_sword_swing(1.08, 22),
        "sword_swing_3.wav": lambda: synth_sword_swing(1.22, 33),
        "heavy_cleave.wav": synth_heavy_cleave,
        "dodge_dash.wav": synth_dodge_dash,
        "hit_normal.wav": synth_hit_normal,
        "hit_crit.wav": synth_hit_crit,
        "hit_break.wav": synth_hit_break,
        "skill_sky_slash.wav": synth_skill_sky_slash,
        "skill_guardian_shield.wav": synth_skill_guardian_shield,
        "skill_judgment_strike.wav": synth_skill_judgment_strike,
        "skill_thunder_strike.wav": synth_skill_thunder_strike,
        "skill_frost_shatter.wav": synth_skill_frost_shatter,
        "skill_void_rift.wav": synth_skill_void_rift,
        "boss_telegraph.wav": synth_boss_telegraph,
        "boss_roar.wav": synth_boss_roar,
        "level_up.wav": synth_level_up,
        "quest_complete.wav": synth_quest_complete,
        "forge_anvil.wav": synth_forge_anvil,
        "potion_heal.wav": synth_potion_heal,
        "chest_open.wav": synth_chest_open,
        "shrine_bless.wav": synth_shrine_bless,
        "ambient_sky_wind.wav": synth_ambient_sky_wind,
        "bgm_goldensky.wav": synth_bgm_goldensky,
        "bgm_frozencyber.wav": synth_bgm_frozencyber,
        "bgm_shadowrealm.wav": synth_bgm_shadowrealm,
        "bgm_boss_battle.wav": synth_bgm_boss_battle,
    }

    generated = []
    for filename, fn in generators.items():
        l, r = fn()
        targets = [out_dir / filename] + [sd / filename for sd in studio_sound_dirs]
        save_stereo_wav(targets, l, r)
        generated.append(filename)

    print(f"Synthesized {len(generated)} stereo 44.1kHz 16-bit WAV files.")
    print(f"Saved to project folder: {out_dir}")
    print(f"Installed into {len(studio_sound_dirs)} Roblox Studio content/sounds/skybreak directories.")

if __name__ == "__main__":
    main()
