# Afterglow, revision 1

Original instrumental composed and synthesized locally for this authorized
TapHap Phase 2 slice. No imported recordings, samples, lyrics, artist imitation,
third-party assets, services or dependencies. The complete authored score and
synthesis are in `scripts/generate-phase2-track.py`. No licensing deal or external
rights claim was made. Repository license applies; release use remains gated.

34-second mono, 48 kHz, 16-bit PCM; 1-second pickup, 16 bars with four pulses
per bar, 120 quarter notes per minute. Original warm-key melody, syncopated chord
stabs, bass and synthesized percussion. The three challenges use the same song
and audible opening, with 4-, 6- or 8-second fade-to-return sections. Song quality
and musician preference require actual product observation.

`catalog.json` contains the separately enumerated 64-position beat map and
challenge schedules. `scripts/verify-phase2-assets.py` checks PCM attacks against
an independently enumerated expected grid, dimensions, downbeats and hashes.
All 64 attacks cross a small PCM threshold one frame after the map position;
this verifies authored attacks, not perceptual/acoustic latency. Catalog and
WAV are hash-locked by the app. Reproduction uses Python standard library/libm;
verify the exact committed bytes after regeneration on another platform.
