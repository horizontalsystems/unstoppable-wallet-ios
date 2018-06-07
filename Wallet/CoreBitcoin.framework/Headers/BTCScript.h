// CoreBitcoin by Oleg Andreev <oleganza@gmail.com>, WTFPL.

#import <Foundation/Foundation.h>
#import <CoreBitcoin/BTCOpcode.h>
#import <CoreBitcoin/BTCSignatureHashType.h>

typedef NS_ENUM(NSInteger, BTCScriptSimulationOptions) {
    // Default is strict conservative simulation (uncompressed pubkeys, no P2SH interpretation)
    BTCScriptSimulationDefault = 0,

    // Use compressed pubkeys instead of uncompressed ones.
    BTCScriptSimulationCompressedPublicKeys = 1 << 0,

    // Instead of failing on P2SH, assume it is 2-of-3 multisig (the most popular one).
    BTCScriptSimulationMultisigP2SH = 1 << 1,
};

@class BTCAddress;
@class BTCScriptHashAddress;
@class BTCScriptHashAddressTestnet;
@interface BTCScriptChunk : NSObject

// Return YES if it is not a pushdata chunk, that is a single byte opcode without data.
// -data returns nil when the value is YES.
@property(nonatomic, readonly) BOOL isOpcode;

// Opcode used in the chunk. Simply a first byte of its raw data.
@property(nonatomic, readonly) BTCOpcode opcode;

// Data being pushed. Returns nil if the opcode is not OP_PUSHDATA*.
@property(nonatomic, readonly) NSData* pushdata;

@end

@interface BTCScript : NSObject<NSCopying>

// Initialized an empty script.
- (id) init;

// Inits with binary data. If data is empty or nil, empty script is initialized.
// If data is invalid script (e.g. a length prefix is not followed by matching amount of data), nil is returned.
- (id) initWithData:(NSData*)data;

// Inits with data in hex.
- (id) initWithHex:(NSString*)hex;

// Initializes script with space-separated hex-encoded commands and data.
// If script is invalid, nil is returned.
// Note: the string may be ambigious. You are safe if it does not have 3..5-byte data or integers.
- (id) initWithString:(NSString*)string;

// Standard script redeeming to a pubkey hash (OP_DUP OP_HASH160 <addr> OP_EQUALVERIFY OP_CHECKSIG)
// or a P2SH address (OP_HASH160 <20-byte hash> OP_EQUAL).
- (id) initWithAddress:(BTCAddress*)address;

// Initializes a multisignature script "OP_<M> <pubkey1> ... <pubkeyN> OP_<N> OP_CHECKMULTISIG"
// N must be >= M, M and N should be from 1 to 16.
// If you need a more customized transaction with OP_CHECKMULTISIG, create it using other methods.
// publicKeys is an array of NSData objects.
- (id) initWithPublicKeys:(NSArray*)publicKeys signaturesRequired:(NSUInteger)signaturesRequired;


// Binary representation
@property(nonatomic, readonly) NSData* data;

// Hex representation
@property(nonatomic, readonly) NSString* hex;

// Space-separated hex-encoded commands and data.
// Small integers (data fitting in 4 bytes) incuding OP_<N> are represented with decimal digits.
// Other opcodes are represented with their names.
// Other data is hex-encoded.
// This representation is inherently ambiguous, so don't use it for anything serious.
@property(nonatomic, readonly) NSString* string;

// List of parsed chunks of the script (BTCScriptChunk)
@property(nonatomic, readonly) NSArray* scriptChunks;

// Returns YES if the script is considered standard and can be relayed and mined normally by enough nodes.
// Non-standard scripts are still valid if appear in blocks, but default nodes and miners will reject them.
// Some miners do mine non-standard transactions, so it's just a matter of the higher delay.
// Today standard = isPublicKey || isHash160 || isP2SH || isStandardMultisig
@property(nonatomic, readonly) BOOL isStandard;

// Returns YES if the script is "<pubkey> OP_CHECKSIG".
// This is old-style script mostly replaced by a more compact "Hash160" one.
// It is used for "send to IP" transactions. You connect to an IP address, receive
// a pubkey and send money to this key. However, this method is almost never used for security reasons.
@property(nonatomic, readonly) BOOL isPublicKeyScript;

// Deprecated. Use -isPayToPublicKeyHashScript instead.
@property(nonatomic, readonly) BOOL isHash160Script DEPRECATED_ATTRIBUTE;

// Returns YES if the script is "OP_DUP OP_HASH160 <20-byte hash> OP_EQUALVERIFY OP_CHECKSIG" (aka P2PKH)
// This is the most popular type that is used to pay to "addresses" (e.g. 1CBtcGivXmHQ8ZqdPgeMfcpQNJrqTrSAcG).
@property(nonatomic, readonly) BOOL isPayToPublicKeyHashScript;

// Returns YES if the script is "OP_HASH160 <20-byte hash> OP_EQUAL" (aka P2SH)
// This is later added script type that allows sender not to worry about complex redemption scripts (and not pay tx fees).
// Recipient must provide a serialized script which matches the hash to redeem the output.
// P2SH base58-encoded addresses start with "3" (e.g. "3NukJ6fYZJ5Kk8bPjycAnruZkE5Q7UW7i8").
@property(nonatomic, readonly) BOOL isPayToScriptHashScript;

// Returns YES if the script is "<M> <pubkey1> ... <pubkeyN> <N> OP_CHECKMULTISIG" where N is up to 3.
// Scripts with up to 3 signatures are considered standard and relayed quickly, but you can create more complex ones.
@property(nonatomic, readonly) BOOL isStandardMultisignatureScript;

// Returns YES if the script is "<M> <pubkey1> ... <pubkeyN> <N> OP_CHECKMULTISIG" with any valid N or M.
@property(nonatomic, readonly) BOOL isMultisignatureScript;

// Returns YES if the script consists of push data operations only (including OP_<N>). Aka isPushOnly in BitcoinQT.
// Used in BIP16 (P2SH).
@property(nonatomic, readonly) BOOL isDataOnly;

// Enumerates all available operations.
//   opIndex - index of the current operation: 0..(N-1) where N is number of ops.
//   opcode - an opcode or OP_INVALIDOPCODE if pushdata is not nil.
//   pushdata - data to push. If the operation is OP_PUSHDATA<1,2,4> or OP_<N>, then this will contain data to push (opcode will be OP_INVALIDOPCODE and should be ignored)
//   stop - if set to YES, stops iterating.
- (void) enumerateOperations:(void(^)(NSUInteger opIndex, BTCOpcode opcode, NSData* pushdata, BOOL* stop))block;

// Returns BTCPublicKeyAddress or BTCScriptHashAddress if the script is a standard output script for these addresses.
// If the script is something different, returns nil.
@property(nonatomic, readonly) BTCAddress* standardAddress;

// Wraps the recipient into an output P2SH script (OP_HASH160 <20-byte hash of the recipient> OP_EQUAL).
@property(nonatomic, readonly) BTCScript* scriptHashScript;

// Returns BTCScriptHashAddress that hashes this script.
// Equivalent to script.scriptHashScript.standardAddress or [BTCScriptHashAddress addressWithData:BTCHash160(script.data)]
@property(nonatomic, readonly) BTCScriptHashAddress* scriptHashAddress;
@property(nonatomic, readonly) BTCScriptHashAddressTestnet* scriptHashAddressTestnet;



#pragma mark - Simulated Scripts


// Returns a dummy script matching this script on the input with
// the same size as an intended signature script.
// Only a few standard script types are supported.
// Returns nil if could not determine a matching script.
- (BTCScript*) simulatedSignatureScriptWithOptions:(BTCScriptSimulationOptions)opts;

// Returns a simulated signature without a hashtype byte.
+ (NSData*) simulatedSignature;

// Returns a simulated signature with a hashtype byte attached.
+ (NSData*) simulatedSignatureWithHashType:(BTCSignatureHashType)hashtype;

// Returns a dummy uncompressed pubkey (65 bytes).
+ (NSData*) simulatedUncompressedPubkey;

// Returns a dummy compressed pubkey (33 bytes).
+ (NSData*) simulatedCompressedPubkey;

// Returns a dummy script that simulates m-of-n multisig script
+ (BTCScript*) simulatedMultisigScriptWithSignaturesCount:(NSInteger)m pubkeysCount:(NSInteger)n compressedPubkeys:(BOOL)compressedPubkeys;




#pragma mark - Modification API


// Adds an opcode to the script.
// Returns self.
- (BTCScript*) appendOpcode:(BTCOpcode)opcode;

// Adds arbitrary data to the script. nil does nothing, empty data is allowed.
// Returns self.
- (BTCScript*) appendData:(NSData*)data;

// Adds opcodes and data from another script.
// If script is nil, does nothing.
// Returns self.
- (BTCScript*) appendScript:(BTCScript*)otherScript;

// Removes pushdata chunks containing the specified data.
// Returns self.
- (BTCScript*) deleteOccurrencesOfData:(NSData*)data;

// Removes chunks with an opcode.
// Returns self.
- (BTCScript*) deleteOccurrencesOfOpcode:(BTCOpcode)opcode;

// Returns a sub-script from the specified index (inclusively).
// Raises an exception if index is accessed out of bounds.
// Returns an empty subscript if the index is of the last op.
- (BTCScript*) subScriptFromIndex:(NSUInteger)index;

// Returns a sub-script to the specified index (exclusively).
// Raises an exception if index is accessed out of bounds.
// Returns an empty subscript if the index is 0.
- (BTCScript*) subScriptToIndex:(NSUInteger)index;

// DEPRECATION WARNING: These methods were moved to BTCKey class.
+ (BOOL) isCanonicalPublicKey:(NSData*)data error:(NSError**)errorOut DEPRECATED_ATTRIBUTE;
+ (BOOL) isCanonicalSignature:(NSData*)data verifyEvenS:(BOOL)verifyEvenS error:(NSError**)errorOut DEPRECATED_ATTRIBUTE;


@end
