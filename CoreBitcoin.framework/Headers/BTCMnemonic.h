// CoreBitcoin by Oleg Andreev <oleganza@gmail.com>, WTFPL.

#import <Foundation/Foundation.h>

typedef NS_ENUM(int8_t, BTCMnemonicWordListType) {
    // English wordlist specified by BIP39.
    BTCMnemonicWordListTypeEnglish = 0,

    // If this is specified when importing mnemonic, checksum can not be verified.
    BTCMnemonicWordListTypeUnknown = -1,
};

@class BTCKeychain;

// Implementation of BIP39: Mnemonic code for generating deterministic keys.
@interface BTCMnemonic : NSObject

// Type of the wordlist being used.
@property(nonatomic, readonly) BTCMnemonicWordListType wordListType;

// Raw entropy buffer used as an input.
@property(nonatomic, readonly) NSData* entropy;

// A list of words composed from the rawEntropy using the specified wordlist.
// This wordlist can be written down by the user and used to recover the seed.
@property(nonatomic, readonly) NSArray* words;

// Optional password. If not specified, returns an empty string.
@property(nonatomic, readonly) NSString* password;

// Returns a wallet seed computed from words and password that you can use in BIP32 or alike.
// Note: The name "seed" means an input for the external key derivation scheme (e.g. BIP32),
// not to this mnemonic implementation. Input for the mnemonic is `entropy`, `password` and `wordListType`.
@property(nonatomic, readonly) NSData* seed;

// Root keychain instantiated with a given seed.
@property(nonatomic, readonly) BTCKeychain* keychain;

// Compact binary representation of the mnemonic.
@property(nonatomic, readonly) NSData* data;

// Binary representation of the mnemonic with computed seed appended (so it can be cached).
@property(nonatomic, readonly) NSData* dataWithSeed;

// Inits mnemonic with a raw entropy buffer, optional password and a wordlist.
// If `password` is nil, it is treated as an empty string.
// `entropy` length in bits must be divisible by 32 (128, 160, 192, 224, 256 bits).
// Returns nil if entropy has incorrect size or wordlist is not supported.
- (id) initWithEntropy:(NSData*)entropy password:(NSString*)password wordListType:(BTCMnemonicWordListType)wordListType;

// Inits mnemonic with user's words, optional password and an optional wordlist type.
// If `password` is nil, it is treated as an empty string.
// If `wordListType` is BTCMnemonicWordListTypeUnknown, checksum is not verified.
// Returns nil if checksum is invalid.
- (id) initWithWords:(NSArray*)words password:(NSString*)password wordListType:(BTCMnemonicWordListType)wordListType;

// Deserializes mnemonic from its binary representation
// (which contains wordlist type, raw entropy, password and optional computed seed).
// If the data was produced by `-dataWithSeed` method, seed will not be recomputed.
- (id) initWithData:(NSData*)data;

// Clears all sensitive information from memory.
- (void) clear;

@end
