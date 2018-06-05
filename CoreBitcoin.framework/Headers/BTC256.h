// CoreBitcoin by Oleg Andreev <oleganza@gmail.com>, WTFPL.

#import <Foundation/Foundation.h>

// A set of ubiquitous types and functions to deal with fixed-length chunks of data
// (160-bit, 256-bit and 512-bit). These are relevant almost always to hashes,
// but there's no hash-specific about them.
// The purpose of these is to avoid dynamic memory allocations via NSData when
// we need to move exactly 32 bytes around.
//
// We don't call these BTCFixedData256 because these types are way too ubiquituous
// in CoreBitcoin to have such an explicit name.
//
// Somewhat similar to uint256 in bitcoind, but here we don't try
// to pretend that these are integers and then allow arithmetic on them
// and create a mess with the byte order.
// Use BTCBigNumber to do arithmetic on big numbers and convert
// to bignum format explicitly.
// BTCBigNumber has API for converting BTC256 to a big int.
//
// We also declare BTC160 and BTC512 for use with RIPEMD-160, SHA-1 and SHA-512 hashes.


// 1. Fixed-length types

struct private_BTC160
{
    // 160 bits can't be formed with 64-bit words, so we have to use 32-bit ones instead.
    uint32_t words32[5];
} __attribute__((packed));
typedef struct private_BTC160 BTC160;

struct private_BTC256
{
    // Since all modern CPUs are 64-bit (ARM is 64-bit starting with iPhone 5s),
    // we will use 64-bit words.
    uint64_t words64[4];
} __attribute__((aligned(1)));
typedef struct private_BTC256 BTC256;

struct private_BTC512
{
    // Since all modern CPUs are 64-bit (ARM is 64-bit starting with iPhone 5s),
    // we will use 64-bit words.
    uint64_t words64[8];
} __attribute__((aligned(1)));
typedef struct private_BTC512 BTC512;


// 2. Constants

// All-zero constants
extern const BTC160 BTC160Zero;
extern const BTC256 BTC256Zero;
extern const BTC512 BTC512Zero;

// All-one constants
extern const BTC160 BTC160Max;
extern const BTC256 BTC256Max;
extern const BTC512 BTC512Max;

// First 160 bits of SHA512("CoreBitcoin/BTC160Null")
extern const BTC160 BTC160Null;

// First 256 bits of SHA512("CoreBitcoin/BTC256Null")
extern const BTC256 BTC256Null;

// Value of SHA512("CoreBitcoin/BTC512Null")
extern const BTC512 BTC512Null;


// 3. Comparison

BOOL BTC160Equal(BTC160 chunk1, BTC160 chunk2);
BOOL BTC256Equal(BTC256 chunk1, BTC256 chunk2);
BOOL BTC512Equal(BTC512 chunk1, BTC512 chunk2);

NSComparisonResult BTC160Compare(BTC160 chunk1, BTC160 chunk2);
NSComparisonResult BTC256Compare(BTC256 chunk1, BTC256 chunk2);
NSComparisonResult BTC512Compare(BTC512 chunk1, BTC512 chunk2);


// 4. Operations


// Inverse (b = ~a)
BTC160 BTC160Inverse(BTC160 chunk);
BTC256 BTC256Inverse(BTC256 chunk);
BTC512 BTC512Inverse(BTC512 chunk);

// Swap byte order
BTC160 BTC160Swap(BTC160 chunk);
BTC256 BTC256Swap(BTC256 chunk);
BTC512 BTC512Swap(BTC512 chunk);

// Bitwise AND operation (a & b)
BTC160 BTC160AND(BTC160 chunk1, BTC160 chunk2);
BTC256 BTC256AND(BTC256 chunk1, BTC256 chunk2);
BTC512 BTC512AND(BTC512 chunk1, BTC512 chunk2);

// Bitwise OR operation (a | b)
BTC160 BTC160OR(BTC160 chunk1, BTC160 chunk2);
BTC256 BTC256OR(BTC256 chunk1, BTC256 chunk2);
BTC512 BTC512OR(BTC512 chunk1, BTC512 chunk2);

// Bitwise exclusive-OR operation (a ^ b)
BTC160 BTC160XOR(BTC160 chunk1, BTC160 chunk2);
BTC256 BTC256XOR(BTC256 chunk1, BTC256 chunk2);
BTC512 BTC512XOR(BTC512 chunk1, BTC512 chunk2);

// Concatenation of two 256-bit chunks
BTC512 BTC512Concat(BTC256 chunk1, BTC256 chunk2);


// 5. Conversion functions


// Conversion to NSData
NSData* NSDataFromBTC160(BTC160 chunk);
NSData* NSDataFromBTC256(BTC256 chunk);
NSData* NSDataFromBTC512(BTC512 chunk);

// Conversion from NSData.
// If NSData is not big enough, returns BTCHash{160,256,512}Null.
BTC160 BTC160FromNSData(NSData* data);
BTC256 BTC256FromNSData(NSData* data);
BTC512 BTC512FromNSData(NSData* data);

// Returns lowercase hex representation of the chunk
NSString* NSStringFromBTC160(BTC160 chunk);
NSString* NSStringFromBTC256(BTC256 chunk);
NSString* NSStringFromBTC512(BTC512 chunk);

// Conversion from hex NSString (lower- or uppercase).
// If string is invalid or data is too short, returns BTCHash{160,256,512}Null.
BTC160 BTC160FromNSString(NSString* string);
BTC256 BTC256FromNSString(NSString* string);
BTC512 BTC512FromNSString(NSString* string);



