#ifndef _NISTPQC_API_H
#define _NISTPQC_API_H

#include <stddef.h>
#include <stdint.h>

/**
 * Supported PQ algorithms
 **/
typedef enum {
    NISTPQC_CIPHER_SIKEP434=1,
    NISTPQC_CIPHER_SIKEP503,
    NISTPQC_CIPHER_SIKEP610,
    NISTPQC_CIPHER_SIKEP751,
    NISTPQC_CIPHER_FRODOKEM640,
    NISTPQC_CIPHER_FRODOKEM976,
    NISTPQC_CIPHER_FRODOKEM1344,
    NISTPQC_CIPHER_NTRUHPS2048509,
    NISTPQC_CIPHER_NTRUHPS2048677,
    NISTPQC_CIPHER_NTRUHPS4096821,
    NISTPQC_CIPHER_NTRUHRSS701,
    NISTPQC_CIPHER_KYBER512,
    NISTPQC_CIPHER_KYBER768,
    NISTPQC_CIPHER_KYBER1024,
    NISTPQC_CIPHER_NTRULPR653,
    NISTPQC_CIPHER_NTRULPR761,
    NISTPQC_CIPHER_NTRULPR857,
    NISTPQC_CIPHER_SNTRUP653,
    NISTPQC_CIPHER_SNTRUP761,
    NISTPQC_CIPHER_SNTRUP857,
    NISTPQC_CIPHER_LIGHTSABER,
    NISTPQC_CIPHER_SABER,
    NISTPQC_CIPHER_FIRESABER,
} nistpqc_cipher_t;

struct nistpqc_t {
    nistpqc_cipher_t cipher_id;

    /**
     * Function pointer for key-pair generation
     *
     * @note
     * The size of the public-key buffer can be obtained by
     * calling @nistpqc_t.(*public_key_size) method. Likewise, 
     * the size of the private-key buffer can be obtained by 
     * calling @nistpqc_t.(*private_key_size) method.
     *
     * @param pk  Pointer to output public-key buffer
     * @param sk  Pointer to output private-key buffer
     * @return 0 on success, non-zero otherwise
     **/
    int    (*keypair)(uint8_t *pk, uint8_t *sk);

    /**
     * Function pointer for encapsulation
     *
     * @note
     * The size of the ciphertext, shared-secret and public-key
     * buffers can be obtained by calling 
     * @nistpqc_t.(*ciphertext_size), 
     * @nistpqc_t.(*shared_secret_size), and
     * @nistpqc_t.(*public_key_size) 
     * methods respectively.
     *
     * @param ct  Pointer to the ouput ciphertext buffer
     * @param ss  Pointer to the output shared-secret buffer
     * @param pk  Pointer to the input public-key buffer
     * @return 0 on success, non-zero otherwise
     **/
    int    (*enc)(uint8_t *ct, uint8_t *ss, const uint8_t *pk);

    /**
     * Function pointer for decapsulation
     *
     * @note
     * The size of the shared-secret, ciphertext and private-key
     * buffers can be obtained by calling 
     * @nistpqc_t.(*shared_secret_size),
     * @nistpqc_t.(*ciphertext_size), and
     * @nistpqc_t.(*private_key_size) 
     * methods respectively.
     *
     * @param ss  Pointer to the output shared-secret buffer
     * @param ct  Pointer to the input ciphertext buffer
     * @param sk  Pointer to the input private-key buffer
     * @return 0 on success, non-zero otherwise
     **/
    int    (*dec)(uint8_t *ss, const uint8_t *ct, const uint8_t *sk);

    /**
     * Return the size of the shared-secret in bytes
     *
     * @return The number of bytes required to store the shared-secret
     **/
    size_t (*shared_secret_size)(void);

    /**
     * Return the size of the ciphertext in bytes
     *
     * @return The number of bytes required to store the ciphertext
     **/
    size_t (*ciphertext_size)(void);

    /**
     * Return the size of the public-key in bytes
     *
     * @return The number of bytes required to store the public-key
     **/
    size_t (*public_key_size)(void);

    /**
     * Return the size of the private-key in bytes
     *
     * @return The number of bytes required to store the private-key
     **/
    size_t (*private_key_size)(void);

    /**
     * Return the PQ algorithm name
     *
     * @return The name of the PQ algorithm
     **/
    const char* (*algorithm_name)(void);

    /**
     * Function pointer to obtain the public-key from a 
     * private-key.
     *
     * @param pk  Pointer to the output public-key buffer
     * @param sk  Pointer to the input private-key buffer
     * @return 0 on success, non-zero otherwise
     **/
    int (*public_key_from_private_key)(uint8_t *pk,
                                       const uint8_t *sk);
};

typedef struct nistpqc_t nistpqc_t;

/**
 * Initialise nistpqc_t object with a PQ cipher
 *
 * @param nistpqc  Pointer to nistpqc object
 * @param cipher   A PQ cipher, @see nistpqc_cipher_t
 * @return 1 on success, 0 otherwise
 * @relates nistpqc_t
 **/
int nistpqc_init(nistpqc_t *nistpqc, nistpqc_cipher_t cipher);

#endif /* _NISTPQC_API_H */
