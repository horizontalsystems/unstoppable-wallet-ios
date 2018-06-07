// CoreBitcoin by Oleg Andreev <oleganza@gmail.com>, WTFPL.

#import <Foundation/Foundation.h>
#import <CoreBitcoin/openssl/bn.h>

// Bitcoin-flavoured big number wrapping OpenSSL BIGNUM.
// It is doing byte ordering like bitcoind does to stay compatible.
// BTCBigNumber is immutable. BTCMutableBigNumber is its mutable counterpart.
// -copy always returns immutable instance, like in other Cocoa containers.
@class BTCBigNumber;
@class BTCMutableBigNumber;

@interface BTCBigNumber : NSObject <NSCopying, NSMutableCopying>

@property(nonatomic, readonly) uint32_t compact; // compact representation used for the difficulty target
@property(nonatomic, readonly) uint32_t uint32value;
@property(nonatomic, readonly) int32_t int32value;
@property(nonatomic, readonly) uint64_t uint64value;
@property(nonatomic, readonly) int64_t int64value;
@property(nonatomic, readonly) NSString* hexString;
@property(nonatomic, readonly) NSString* decimalString;
@property(nonatomic, readonly) NSData* signedLittleEndian;
@property(nonatomic, readonly) NSData* unsignedBigEndian;

// Deprecated. Use `-signedLittleEndian` instead.
@property(nonatomic, readonly) NSData* littleEndianData DEPRECATED_ATTRIBUTE;

// Deprecated. Use `-unsignedBigEndian` instead.
@property(nonatomic, readonly) NSData* unsignedData DEPRECATED_ATTRIBUTE;

// Pointer to an internal BIGNUM value. You should not modify it.
// To modify, use [[bn mutableCopy] mutableBIGNUM] methods.
@property(nonatomic, readonly) const BIGNUM* BIGNUM;

@property(nonatomic, readonly) BOOL isZero;
@property(nonatomic, readonly) BOOL isOne;


// BTCBigNumber returns always the same object for these constants.
// BTCMutableBigNumber returns a new object every time.
+ (instancetype) zero;        //  0
+ (instancetype) one;         //  1
+ (instancetype) negativeOne; // -1

- (id) init;
- (id) initWithCompact:(uint32_t)compact;
- (id) initWithUInt32:(uint32_t)value;
- (id) initWithInt32:(int32_t)value;
- (id) initWithUInt64:(uint64_t)value;
- (id) initWithInt64:(int64_t)value;
- (id) initWithSignedLittleEndian:(NSData*)data;
- (id) initWithUnsignedBigEndian:(NSData*)data;
- (id) initWithLittleEndianData:(NSData*)data DEPRECATED_ATTRIBUTE;
- (id) initWithUnsignedData:(NSData*)data DEPRECATED_ATTRIBUTE;


// Initialized with OpenSSL representation of bignum.
- (id) initWithBIGNUM:(const BIGNUM*)bignum;

// Inits with setString:base:
- (id) initWithString:(NSString*)string base:(NSUInteger)base;

// Same as initWithString:base:16
- (id) initWithHexString:(NSString*)hexString DEPRECATED_ATTRIBUTE;

// Same as initWithString:base:10
- (id) initWithDecimalString:(NSString*)decimalString;

- (NSString*) stringInBase:(NSUInteger)base;

// Re-declared copy and mutableCopy to provide exact return type.
- (BTCBigNumber*) copy;
- (BTCMutableBigNumber*) mutableCopy;

// TODO: maybe add support for hash, figure out what the heck is that.
//void set_hash(hash_digest load_hash);
//hash_digest hash() const;

// Returns MIN(self, other)
- (BTCBigNumber*) min:(BTCBigNumber*)other;

// Returns MAX(self, other)
- (BTCBigNumber*) max:(BTCBigNumber*)other;


- (BOOL) less:(BTCBigNumber*)other;
- (BOOL) lessOrEqual:(BTCBigNumber*)other;
- (BOOL) greater:(BTCBigNumber*)other;
- (BOOL) greaterOrEqual:(BTCBigNumber*)other;


// Divides receiver by another bignum.
// Returns an array of two new BTCBigNumber instances: @[ quotient, remainder ]
- (NSArray*) divmod:(BTCBigNumber*)other;

// Destroys sensitive data and sets the value to 0.
// It is also called on dealloc.
// This method is available for both mutable and immutable numbers by design.
- (void) clear;

@end


@interface BTCMutableBigNumber : BTCBigNumber

@property(nonatomic, readwrite) uint32_t compact; // compact representation used for the difficulty target
@property(nonatomic, readwrite) uint32_t uint32value;
@property(nonatomic, readwrite) int32_t int32value;
@property(nonatomic, readwrite) uint64_t uint64value;
@property(nonatomic, readwrite) int64_t int64value;
@property(nonatomic, readwrite) NSString* hexString;
@property(nonatomic, readwrite) NSString* decimalString;
@property(nonatomic, readwrite) NSData* signedLittleEndian;
@property(nonatomic, readwrite) NSData* unsignedBigEndian;
@property(nonatomic, readwrite) NSData* littleEndianData DEPRECATED_ATTRIBUTE;
@property(nonatomic, readwrite) NSData* unsignedData DEPRECATED_ATTRIBUTE;

@property(nonatomic, readonly) BIGNUM* mutableBIGNUM;

// BTCBigNumber returns always the same object for these constants.
// BTCMutableBigNumber returns a new object every time.
+ (instancetype) zero;        //  0
+ (instancetype) one;         //  1
+ (instancetype) negativeOne; // -1

// Supports bases from 2 to 36. For base 2 allows optional 0b prefix, base 16 allows optional 0x prefix. Spaces are ignored.
- (void) setString:(NSString*)string base:(NSUInteger)base;

// Operators modify the receiver and return self.
// To create a new instance z = x + y use copy method: z = [[x copy] add:y]
- (instancetype) add:(BTCBigNumber*)other; // +=
- (instancetype) add:(BTCBigNumber*)other mod:(BTCBigNumber*)mod;
- (instancetype) subtract:(BTCBigNumber*)other; // -=
- (instancetype) subtract:(BTCBigNumber*)other mod:(BTCBigNumber*)mod;
- (instancetype) multiply:(BTCBigNumber*)other; // *=
- (instancetype) multiply:(BTCBigNumber*)other mod:(BTCBigNumber*)mod;
- (instancetype) divide:(BTCBigNumber*)other; // /=
- (instancetype) mod:(BTCBigNumber*)other; // %=
- (instancetype) lshift:(unsigned int)shift; // <<=
- (instancetype) rshift:(unsigned int)shift; // >>=
- (instancetype) inverseMod:(BTCBigNumber*)mod; // (a^-1) mod n
- (instancetype) exp:(BTCBigNumber*)power;
- (instancetype) exp:(BTCBigNumber*)power mod:(BTCBigNumber *)mod;

@end
