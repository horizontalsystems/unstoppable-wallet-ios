// CoreBitcoin by Oleg Andreev <oleganza@gmail.com>, WTFPL.

#import <Foundation/Foundation.h>

// A collection of routines dealing with parsing and writing various protocol messages.
@interface BTCProtocolSerialization : NSObject

// This implementation of variable-length integer is known as "CompactSize" in Satoshi code (BitcoinQT).
//
//  Value           Storage length     Format
//  < 0xfd          1                  uint8_t
// <= 0xffff        3                  0xfd followed by the value as uint16_t
// <= 0xffffffff    5                  0xfe followed by the value as uint32_t
//  > 0xffffffff    9                  0xff followed by the value as uint64_t
//
// Note: BitcoinQT later added VarInt which is different, more compact format
// used in block storage. VarInt is not a part of the protocol and is not implemented here.

// Attempts to read integer from data and returns amount of bytes read.
// In case of error, returns 0.
+ (NSUInteger) readVarInt:(uint64_t*)valueOut fromData:(NSData*)data;
+ (NSUInteger) readVarInt:(uint64_t*)valueOut fromStream:(NSInputStream*)stream;

// Attempts to read string prepended by its length in varInt format.
// On success, returns data. On failure, returns nil.
// lengthOut is an optional out parameter that contains total bytes read (including the length prefix)
+ (NSData*) readVarStringFromData:(NSData*)data;
+ (NSData*) readVarStringFromData:(NSData*)data readBytes:(NSUInteger*)lengthOut;
+ (NSData*) readVarStringFromStream:(NSInputStream*)stream;

// Encodes value in a varint binary form.
+ (NSData*) dataForVarInt:(uint64_t)value;

// Prepends binary string with its length in varInt format.
+ (NSData*) dataForVarString:(NSData*)binaryString;

@end

