#!/usr/bin/env python
"""Generate procedural audio for RUNAWAY (no external assets needed).
Writes 16-bit mono WAV files into assets/audio/.
SFX are one-shots; music_* are designed to loop seamlessly.
"""
import os
import wave
import struct
import numpy as np

SR = 44100
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")
os.makedirs(OUT, exist_ok=True)


def write_wav(name, samples):
    samples = np.clip(samples, -1.0, 1.0)
    data = (samples * 32767.0).astype("<i2")
    path = os.path.join(OUT, name + ".wav")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())
    print("wrote", name, f"{len(samples)/SR:.2f}s")


def t(dur):
    return np.linspace(0, dur, int(SR * dur), endpoint=False)


def env_ad(n, attack, decay):
    """Attack/decay envelope over n samples."""
    e = np.ones(n)
    a = max(1, int(attack * SR))
    d = max(1, int(decay * SR))
    e[:a] = np.linspace(0, 1, a)
    e[-d:] *= np.linspace(1, 0, d)
    return e


def noise(n):
    return np.random.uniform(-1, 1, n)


def sine(freq, dur, amp=1.0, phase=0.0):
    x = t(dur)
    return amp * np.sin(2 * np.pi * freq * x + phase)


def lowpass(sig, cutoff):
    """Passe-bas un pole : arrondit la durete des aigus (cutoff en Hz)."""
    rc = 1.0 / (2 * np.pi * cutoff)
    alpha = (1.0 / SR) / (rc + 1.0 / SR)
    out = np.empty_like(sig)
    acc = 0.0
    for i in range(len(sig)):
        acc += alpha * (sig[i] - acc)
        out[i] = acc
    return out


def snap(freq, dur):
    """Cale une frequence sur un nombre entier de cycles dans la boucle
    -> la fin du fichier raccorde parfaitement au debut (pas de clic)."""
    return max(1, round(freq * dur)) / dur


# ----------------------------------------------------------------------
# SFX (one-shots)
# ----------------------------------------------------------------------

# Tir silencieux : souffle filtre court + petit "tac"
def sfx_shoot_silenced():
    n = int(SR * 0.12)
    nz = noise(n) * env_ad(n, 0.001, 0.10)
    # low-pass simple (moyenne mobile)
    k = 12
    nz = np.convolve(nz, np.ones(k) / k, mode="same")
    click = sine(1200, 0.02, 0.4) * env_ad(int(SR * 0.02), 0.0005, 0.018)
    out = nz * 0.35
    out[:len(click)] += click
    return out


# Tir garde : detonation plus forte (bruit + thump basse)
def sfx_shoot_guard():
    n = int(SR * 0.22)
    nz = noise(n) * env_ad(n, 0.0005, 0.20)
    thump = sine(90, 0.22, 0.7) * env_ad(n, 0.001, 0.20)
    crack = sine(450, 0.06, 0.5) * env_ad(int(SR * 0.06), 0.0005, 0.05)
    out = nz * 0.5 + thump
    out[:len(crack)] += crack
    return out * 0.9


# Rechargement : deux clics mecaniques
def sfx_reload():
    out = np.zeros(int(SR * 0.45))
    for off, f in [(0.0, 900), (0.22, 700)]:
        c = sine(f, 0.04, 0.5) * env_ad(int(SR * 0.04), 0.001, 0.035)
        c += noise(len(c)) * 0.15 * env_ad(len(c), 0.001, 0.035)
        s = int(off * SR)
        out[s:s + len(c)] += c
    return out * 0.8


# Coffre / objectif : petite fanfare ascendante
def sfx_vault():
    out = np.array([])
    for f in [523, 659, 784, 1047]:  # do mi sol do
        note = sine(f, 0.14, 0.4) * env_ad(int(SR * 0.14), 0.005, 0.10)
        note += sine(f * 2, 0.14, 0.12) * env_ad(int(SR * 0.14), 0.005, 0.10)
        out = np.concatenate([out, note])
    return out


# Exfiltration reussie : accord lumineux soutenu
def sfx_exfil():
    dur = 1.1
    x = t(dur)
    e = env_ad(len(x), 0.02, 0.5)
    chord = (sine(523, dur, 0.3) + sine(659, dur, 0.25) +
             sine(784, dur, 0.22) + sine(1047, dur, 0.18))
    vib = 1 + 0.01 * np.sin(2 * np.pi * 5 * x)
    return chord * e * vib * 0.6


# Joueur touche : impact sourd
def sfx_hit():
    n = int(SR * 0.25)
    thud = sine(70, 0.25, 0.8) * env_ad(n, 0.001, 0.24)
    nz = noise(n) * 0.3 * env_ad(n, 0.001, 0.08)
    return (thud + nz) * 0.8


# Garde neutralise : thump descendant
def sfx_guard_down():
    dur = 0.3
    x = t(dur)
    freq = np.linspace(220, 60, len(x))
    s = np.sin(2 * np.pi * np.cumsum(freq) / SR)
    return s * env_ad(len(x), 0.002, 0.25) * 0.6


# Alarme : bip bi-tonal (one-shot, l'etat ALERT relance la musique)
def sfx_alarm():
    out = np.array([])
    for f in [880, 660, 880, 660]:
        note = sine(f, 0.16, 0.4) * env_ad(int(SR * 0.16), 0.005, 0.04)
        out = np.concatenate([out, note])
    return out


# Clic UI
def sfx_ui_click():
    c = sine(660, 0.05, 0.4) * env_ad(int(SR * 0.05), 0.001, 0.045)
    return c


# ----------------------------------------------------------------------
# MUSIQUE (boucles seamless) : on fait correspondre la fin a un cycle entier
# ----------------------------------------------------------------------

def loop_dur_for(bpm, beats):
    return beats * 60.0 / bpm


# Calme : nappe chaude et grave, respiration lente, aucun aigu agressif
def music_calm():
    bpm = 60
    dur = loop_dur_for(bpm, 16)  # 16 s
    x = t(dur)
    # triade grave chaleureuse (Do / Sol / Do / Sol), calee sur la boucle
    voices = [(65.41, 0.20), (98.00, 0.13), (130.81, 0.09), (196.00, 0.05)]
    pad = np.zeros(len(x))
    for f, a in voices:
        f0 = snap(f, dur)
        fd = snap(f * 1.003, dur)  # leger desaccord -> chaleur (chorus)
        pad += a * 0.5 * (np.sin(2 * np.pi * f0 * x) + np.sin(2 * np.pi * fd * x))
    # respiration lente du volume (1 cycle entier -> boucle continue)
    swell = 0.55 + 0.45 * np.sin(2 * np.pi * x / dur - np.pi / 2)
    sig = lowpass(pad * swell, 700)  # supprime toute durete
    return sig * 0.5


# Suspicion : pouls grave et doux, tension contenue (sans clic)
def music_suspicion():
    bpm = 92
    dur = loop_dur_for(bpm, 16)
    x = t(dur)
    out = np.zeros(len(x))
    beat = 60.0 / bpm
    # battement de coeur grave : attaque douce, retombe a zero (pas de clic)
    for i in range(16):
        s = int(i * beat * SR)
        p = sine(98, beat * 0.6, 0.4)
        e = env_ad(len(p), 0.02, beat * 0.5)
        seg = (p * e)[:len(out) - s]
        out[s:s + len(seg)] += seg
    drone = sine(snap(146.83, dur), dur, 0.09) + sine(snap(196.0, dur), dur, 0.05)
    sig = lowpass(out * 0.5 + drone, 900)
    return sig * 0.5


# Alerte : tempo soutenu mais sans stridence (arpege adouci, basses rondes)
def music_alert():
    bpm = 132
    dur = loop_dur_for(bpm, 16)
    x = t(dur)
    out = np.zeros(len(x))
    step = 60.0 / bpm / 2.0  # double-croches
    arp = [220, 261.63, 329.63, 261.63]  # la do mi do (mineur, moins dissonant)
    nsteps = int(round(dur / step))
    for i in range(nsteps):
        s = int(i * step * SR)
        f = arp[i % len(arp)]
        note = sine(f, step, 0.26)  # plus d'harmonique octave criarde
        e = env_ad(len(note), 0.006, step * 0.7)
        seg = (note * e)[:len(out) - s]
        out[s:s + len(seg)] += seg
    # kick rond sur chaque temps
    beat = 60.0 / bpm
    for i in range(16):
        s = int(i * beat * SR)
        k = sine(55, 0.14, 0.55) * env_ad(int(SR * 0.14), 0.002, 0.13)
        seg = k[:len(out) - s]
        out[s:s + len(seg)] += seg
    bass = sine(snap(110, dur), dur, 0.08)
    sig = lowpass(out + bass, 1400)  # tempere les aigus
    return sig * 0.45


SFX = {
    "shoot_silenced": sfx_shoot_silenced,
    "shoot_guard": sfx_shoot_guard,
    "reload": sfx_reload,
    "vault": sfx_vault,
    "exfil": sfx_exfil,
    "hit": sfx_hit,
    "guard_down": sfx_guard_down,
    "alarm": sfx_alarm,
    "ui_click": sfx_ui_click,
}
MUSIC = {
    "music_calm": music_calm,
    "music_suspicion": music_suspicion,
    "music_alert": music_alert,
}

if __name__ == "__main__":
    np.random.seed(1)
    for name, fn in SFX.items():
        write_wav(name, fn())
    for name, fn in MUSIC.items():
        write_wav(name, fn())
    print("done.")
