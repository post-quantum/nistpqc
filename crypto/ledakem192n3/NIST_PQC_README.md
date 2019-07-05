### Version

The version of LEDAkem (NIST category 3, n_0=3) used here is from the [optimized implementation](https://csrc.nist.gov/CSRC/media/Projects/Post-Quantum-Cryptography/documents/round-2/submissions/LEDAcrypt-Round2.zip) submitted to NIST Post-Quantum Cryptography Standardization.

### Changes

- Flattened directory structure, no `bin`, `include` or `library` directories
- Removed `Makefile`
- Used `sha3.c|h` from Round 1 to avoid external lib dependency
- Replace LEDA with LEDAKEM192 in `api.h`
