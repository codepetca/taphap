# Clockwork Garden — engineering fixture v1

Original instrumental study authored specifically for this local feasibility lab
on 2026-09-12 (America/Toronto). Synthesized locally by
[`generate-phase1-track.py`](../../scripts/generate-phase1-track.py). No sampled
recordings, third-party songs, lyrics, downloaded stems, or licensed catalog
content. Its authored note score and synthesis source are included; this is a
project-original test asset, not a release-quality song or a legal clearance
claim for future commercial content. Repository LICENSE continues to apply.

One second of pickup silence, sixteen 4/4 bars at 120 quarter notes per minute,
A minor / F / C / G harmonic roots, bass, simple percussion and offbeat plucks.
34 seconds, mono, 48,000 Hz, signed 16-bit PCM, 1,632,000 frames. Peak 12,103 / 32,768.
No stochastic synthesis or external dependencies. Python 3 and standard libm
produce the recorded bytes on this host. On a different libm implementation,
require the hash check; do not silently accept new bytes as the same revision.

The explicit `beat-map.json` is authored separately from the synthesis program:
64 frame positions, downbeat indices, challenge bounds and fade length. The
verifier reads the WAV and map, checks format/length, requires 10 ms of zero
samples before each quarter attack, and finds an attack above 8 PCM units
within 12 samples after each mapped frame. All 64 attacks passed within 3
samples (0.0625 ms). This proves fixture alignment, not musical beat-analysis
accuracy for arbitrary recordings. A physical listening check is still required.

SHA-256:

- WAV: `ad8eb39d1d1074cafdbac4b362c8eddc73c092943f16900c5bf09085c91488c6`
- Map: `494190976e0cacaabf401e6101a990edc4666c8e02d1aaa2c6e0c92215540e15`

The app checks both hashes before decoding or playing. Tests retain an exact
map copy with recorded inputs; regenerate fixtures only with an explicit
fixture-revision change and rerun their expected diagnoses.
