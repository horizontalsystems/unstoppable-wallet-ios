// CoreBitcoin by Oleg Andreev <oleganza@gmail.com>, WTFPL.

#import <Foundation/Foundation.h>

// Encrypted message is a very compact format inspired by Bitmessage.
// Messages are encrypted with recipient's public key (Bitcoin-compatible, that is secp256k1)
// and may contain none to full recipient information (hash of their public key) depending on your application's needs.
// Also allows attaching an optional proof-of-work that is extremely fast to evaluate.
//
// Binary structure:
// 4 bytes     version prefix (also a magic number).
// 1 byte      proof-of-work difficulty target (similar to "bits" field in BTCBlockHeader). SHA512^2 of the entire encrypted message should be below target.
// 1 byte      proof-of-work nonce. When overflown, new private key should be generated and message should be re-encrypted.
// 4 bytes     timestamp to filter out replays. Helps preventing DoS even if you don't use PoW. Big-endian.
// 1 byte      recipient's address length (R bits)
// R bits      recipient's address (BTCHash160(pubkey)), from 0 to 20 bytes. Only first R bits are used.
// 1 byte      pubkey nonce length (N) // normally - 32 bytes.
// N bytes     pubkey nonce: a compressed public key used in a DH algorithm to establish a secret that is then used as a key in AES-CBC.
// 1,2,3,5,9 bytes of message length (M) as 'CompactSize' variable-length integer encoding. See BTCProtocolSerialization.
// M bytes     encrypted message
// 16 bytes    checksum: first 16 bytes of SHA256(SHA256()) of the shared secret and the decrypted message.
//             So the receiver can verify that the message was actually sent to him before even trying to parse it.
//             We do not show the checksum of the message alone as it may leak the contents (e.g. when there is a limited set of possible messages).
//             We do not add checksum of the entire message as it's a job of a transport layer.
//             Also, a reasonably difficult proof-of-work implicitly acts as a checksum of the entire message.

static unsigned char BTCFancyEncryptedMessageVersion[4] = {0xc1, 0xb9, 0xf0, 0xe3};

typedef NS_ENUM(uint8_t, BTCFancyEncryptedMessageAddressLength) {
    // No address is given, recipient must attempt to decrypt the message to figure if he is indeed a recipient.
    BTCFancyEncryptedMessageAddressLengthNone           = 0,
    
    // First 4 bits of the address. To route message efficiently to 6% of all users yet keeping recipient secret.
    BTCFancyEncryptedMessageAddressLengthLightRouting   = 4,
    
    // First 7 bits of the address. To route message to 0.8% of the users. Good anonymity of recipient is maintained if number of users is more than 200K.
    BTCFancyEncryptedMessageAddressLengthNormalRouting  = 7,
    
    // Fingerprint is a short 32-bit identifier to be compact, but yet allow fast identification like in BIP32 / BTCKeychain.
    BTCFancyEncryptedMessageAddressLengthFingerprint    = 32,
    
    // Full 160-bit address fully identifying the recipient.
    BTCFancyEncryptedMessageAddressLengthFull           = 160,
};

@class BTCKey;
@interface BTCFancyEncryptedMessage : NSObject

// Proof-of-work difficulty target.
// Set it before encrypting the message that needs some Proof-of-Work attached.
// Default is maximum target: 0xFFFFFFFF.
@property(nonatomic) uint32_t difficultyTarget;

// UNIX timestamp. Only needed for DoS prevention. For anonymity may be randomized within past hour (depends on application).
@property(nonatomic) uint32_t timestamp;

// Length of the address field in bits (0...160).
@property(nonatomic) uint8_t addressLength;

// The full or partial address. Note that only first 'addressLength' bits are meaningful, the rest is just a byte padding.
// For anonymous messages this is an empty data.
// When you instantiate unencrypted instance, addressLength is zero by default, but this property contains full address anyway.
// When encrypted only required prefix of the address will be preserved.
@property(nonatomic) NSData* address;

// Span of timestamp randomization during -encryptedDataWithKey:seed:.
// Randomization is done using the seed. Actual timestamp will fall in (now - variance)..now range.
// Default value is 0.
@property(nonatomic) uint32_t timestampVariance;


// Encrypt


// Instantiates unencrypted message with its content
- (id) initWithData:(NSData*)data;

// Encrypts message with a given recipient's public key and a unique seed.
// Explicit argument allows you to control the source of entropy and produce deterministic messages.
// Internally it is mixed with the message and its parameters to ensure uniqueness of encryption key per message.
// When in doubt, simply use nil as a seed - we will generate a random one from system RNG.
// If difficultyTarget is below 0xFF, finds a nonce key repeatedly to match the difficulty. (So you might want to run this on a separate thread.)
- (NSData*) encryptedDataWithKey:(BTCKey*)recipientKey seed:(NSData*)seed;



// Decrypt


// Instantiates encrypted message with its binary representation. Checks version, checksum and proof of work.
// To decrypt the message, use -decryptedContentsForKey:
- (id) initWithEncryptedData:(NSData*)data;

// Attempts to decrypt the message with a given private key and returns result.
- (NSData*) decryptedDataWithKey:(BTCKey*)key error:(NSError**)errorOut;



// Difficulty conversion


// Returns 1-byte representation of a target not higher than a given one.
// Maximum difficulty is the minimum target and vice versa.
+ (uint8_t) compactTargetForTarget:(uint32_t)target;


// Returns a full 32-bit target from its compact representation.
+ (uint32_t) targetForCompactTarget:(uint8_t)compactTarget;

@end
