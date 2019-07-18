### Version


The version of CRYSTAL Kyber 768 used here is from the [optimized implementation](https://csrc.nist.gov/CSRC/media/Projects/Post-Quantum-Cryptography/documents/round-2/submissions/CRYSTALS-Kyber-Round2.zip) submitted to NIST Post-Quantum Cryptography Standardization. Note that the variant chosen here is the Keccak-variant, not 90s.

### Changes

- Removed `aes256ctr.[h,c]`
- Removed `PQCgenKAT_kem.c`
- Removed `rng.[h,c]`
- Removed `Makefile`
- Removed `sha2.h, sha256.c, sha512.c`
- Added `pk_from_sk.c`
