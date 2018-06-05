// CoreBitcoin by Oleg Andreev <oleganza@gmail.com>, WTFPL.

#import <Foundation/Foundation.h>

// Implementation of BIP32 "Hierarchical Deterministic Wallets" (HDW)
// https://github.com/bitcoin/bips/blob/master/bip-0032.mediawiki
//
// BTCKeychain encapsulates either a pair of "extended" keys (private and public), or only a public extended key.
// "Extended key" means the key (private or public) is accompanied by extra 256 bits of entropy called "chain code" and
// some metadata about it's position in a tree of keys (depth, parent fingerprint, index).
// Keychain has two modes of operation:
// - "normal derivation" which allows to derive public keys separately from the private ones (internally i below 0x80000000).
// - "hardened derivation" which derives only private keys (for i >= 0x80000000).
// Derivation can be treated as a single key or as a new branch of keychains.

static const uint32_t BTCKeychainMaxIndex = 0x7fffffff;

@class BTCKey;
@class BTCBigNumber;
@class BTCAddress;
@class BTCNetwork;
@interface BTCKeychain : NSObject<NSCopying>

// Initializes master keychain from a seed. This is the "root" keychain of the entire hierarchy.
// Sets the network to mainnet. To specify testnet, use `-initWithSeed:network:`
- (id) initWithSeed:(NSData*)seed;

// Initializes master keychain from a seed. This is the "root" keychain of the entire hierarchy.
// Chosen network affects formatting of the extended keys.
- (id) initWithSeed:(NSData*)seed network:(BTCNetwork*)network;

// Initializes with a base58-encoded extended public or private key.
// Inherits the network from the formatted key.
- (id) initWithExtendedKey:(NSString*)extendedKey;

// Initializes keychain with a serialized extended key.
// Use BTCDataFromBase58Check() to convert from Base58 string.
- (id) initWithExtendedKeyData:(NSData*)extendedKeyData DEPRECATED_ATTRIBUTE;

// Clears all sensitive data from keychain (keychain becomes invalid)
- (void) clear;

// Network for formatting the extended keys (mainnet/testnet).
// Default is mainnet.
@property(nonatomic) BTCNetwork* network;

// Deprecated because of the badly chosen name. See `-key`.
@property(nonatomic, readonly) BTCKey* rootKey DEPRECATED_ATTRIBUTE;

// Instance of BTCKey that is a "head" of this keychain.
// If the keychain is public-only, key does not have a private component.
@property(nonatomic, readonly) BTCKey* key;

// Chain code associated with the key.
@property(nonatomic, readonly) NSData* chainCode;

// Base58-encoded extended public key.
@property(nonatomic, readonly) NSString* extendedPublicKey;

// Base58-encoded extended private key.
// Returns nil if this is a public-only keychain.
@property(nonatomic, readonly) NSString* extendedPrivateKey;

// Raw binary data for serialized extended public key.
// Use BTCBase58CheckStringWithData() to convert to Base58 form.
@property(nonatomic, readonly) NSData* extendedPublicKeyData DEPRECATED_ATTRIBUTE;

// Raw binary data for serialized extended private key.
// Returns nil if the receiver is public-only keychain.
// Use BTCBase58CheckStringWithData() to convert to Base58 form.
@property(nonatomic, readonly) NSData* extendedPrivateKeyData DEPRECATED_ATTRIBUTE;

// 160-bit identifier (aka "hash") of the keychain (RIPEMD160(SHA256(pubkey))).
@property(nonatomic, readonly) NSData* identifier;

// Fingerprint of the keychain.
@property(nonatomic, readonly) uint32_t fingerprint;

// Fingerprint of the parent keychain. For master keychain it is always 0.
@property(nonatomic, readonly) uint32_t parentFingerprint;

// Index in the parent keychain.
// If this is a master keychain, index is 0.
@property(nonatomic, readonly) uint32_t index;

// Depth. Master keychain has depth = 0.
@property(nonatomic, readonly) uint8_t depth;

// Returns YES if the keychain can derive private keys.
@property(nonatomic, readonly) BOOL isPrivate;

// Returns YES if the keychain was derived via hardened derivation from its parent.
// This means internally parameter i = 0x80000000 | self.index
// For the master keychain index is zero and isHardened=NO.
@property(nonatomic, readonly) BOOL isHardened;

// Returns a copy of the keychain stripped of the private key.
// Equivalent to [[BTCKeychain alloc] initWithExtendedKey:keychain.extendedPublicKey]
@property(nonatomic, readonly) BTCKeychain* publicKeychain;

// Returns a derived keychain.
// If hardened = YES, uses hardened derivation (possible only when private key is present; otherwise returns nil).
// Index must be less of equal BTCKeychainMaxIndex, otherwise throws an exception.
// May return nil for some indexes (when hashing leads to invalid EC points) which is very rare (chance is below 2^-127), but must be expected. In such case, simply use another index.
// By default, a normal (non-hardened) derivation is used.
- (BTCKeychain*) derivedKeychainAtIndex:(uint32_t)index;
- (BTCKeychain*) derivedKeychainAtIndex:(uint32_t)index hardened:(BOOL)hardened;

// If factorOut is not NULL, it will contain a number that is being added to the private key.
// This feature is used in BTCBlindSignature protocol.
- (BTCKeychain*) derivedKeychainAtIndex:(uint32_t)index hardened:(BOOL)hardened factor:(BTCBigNumber**)factorOut;

// Parses the BIP32 path and derives the chain of keychains accordingly.
// Path syntax: (m?/)?([0-9]+'?(/[0-9]+'?)*)?
// The following paths are valid:
//
// "" (root key)
// "m" (root key)
// "/" (root key)
// "m/0'" (hardened child #0 of the root key)
// "/0'" (hardened child #0 of the root key)
// "0'" (hardened child #0 of the root key)
// "m/44'/1'/2'" (BIP44 testnet account #2)
// "/44'/1'/2'" (BIP44 testnet account #2)
// "44'/1'/2'" (BIP44 testnet account #2)
//
// The following paths are invalid:
//
// "m / 0 / 1" (contains spaces)
// "m/b/c" (alphabetical characters instead of numerical indexes)
// "m/1.2^3" (contains illegal characters)
- (BTCKeychain*) derivedKeychainWithPath:(NSString*)path;

// Returns a derived key for a given BIP32 path.
// Equivalent to `[keychain derivedKeychainWithPath:@"..."].key`
- (BTCKey*) keyWithPath:(NSString*)path;

// Returns a derived key from this keychain.
// Equivalent to [keychain derivedKeychainAtIndex:i hardened:YES/NO].key
// If the receiver contains a private key, child key will also contain a private key.
// If the receiver contains only a public key, child key will only contain a public key. (Or nil will be returned if hardened = YES.)
// By default, a normal (non-hardened) derivation is used.
- (BTCKey*) keyAtIndex:(uint32_t)index;
- (BTCKey*) keyAtIndex:(uint32_t)index hardened:(BOOL)hardened;


// BIP44 methods.
// These methods are meant to be chained like so:
// ```
// invoiceAddress = [[rootKeychain.bitcoinMainnetKeychain keychainForAccount:1] externalKeyAtIndex:123].address
// ```

// Returns a subchain with path m/44'/0'
@property(nonatomic, readonly) BTCKeychain* bitcoinMainnetKeychain;

// Returns a subchain with path m/44'/1'
@property(nonatomic, readonly) BTCKeychain* bitcoinTestnetKeychain;

// Returns a hardened derivation for the given account index.
// Equivalent to [keychain derivedKeychainAtIndex:accountIndex hardened:YES]
- (BTCKeychain*) keychainForAccount:(uint32_t)accountIndex;

// Returns a key from an external chain (/0/i).
// BTCKey may be public-only if the receiver is public-only keychain.
- (BTCKey*) externalKeyAtIndex:(uint32_t)index;

// Returns a key from an internal (change) chain (/1/i).
// BTCKey may be public-only if the receiver is public-only keychain.
- (BTCKey*) changeKeyAtIndex:(uint32_t)index;



// Scanning methods.

// Scans child keys till one is found that matches the given address.
// Only BTCPublicKeyAddress and BTCPrivateKeyAddress are supported. For others nil is returned.
// Limit is maximum number of keys to scan. If no key is found, returns nil.
// Returns nil if the receiver does not contain private key.
- (BTCKeychain*) findKeychainForAddress:(BTCAddress*)address hardened:(BOOL)hardened limit:(NSUInteger)limit;
- (BTCKeychain*) findKeychainForAddress:(BTCAddress*)address hardened:(BOOL)hardened from:(uint32_t)startIndex limit:(NSUInteger)limit;

// Scans child keys till one is found that matches the given public key.
// Limit is maximum number of keys to scan. If no key is found, returns nil.
// Returns nil if the receiver does not contain private key.
- (BTCKeychain*) findKeychainForPublicKey:(BTCKey*)pubkey hardened:(BOOL)hardened limit:(NSUInteger)limit;
- (BTCKeychain*) findKeychainForPublicKey:(BTCKey*)pubkey hardened:(BOOL)hardened from:(uint32_t)startIndex limit:(NSUInteger)limit;

@end

