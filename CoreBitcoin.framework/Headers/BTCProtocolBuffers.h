// CoreBitcoin by Oleg Andreev <oleganza@gmail.com>, WTFPL.

#import <Foundation/Foundation.h>

// An API to parse and encode protocol buffers.
@interface BTCProtocolBuffers : NSObject

// Reading

// Returns a variable-length integer value at a given offset in source data.
+ (uint64_t) varIntAtOffset:(NSInteger*)offset fromData:(NSData*)src;

// Returns a length-delimited data at a given offset in source data.
+ (NSData *) lenghtDelimitedDataAtOffset:(NSInteger *)offset fromData:(NSData*)src;

// Returns either int or data depending on field type, and returns a field key.
+ (NSInteger) fieldAtOffset:(NSInteger *)offset int:(uint64_t *)i data:(NSData **)d fromData:(NSData*)src;

// Returns either int or fixed64 or data depending on field type, and returns a field key.
+ (NSInteger) fieldAtOffset:(NSInteger *)offset int:(uint64_t *)i fixed32:(uint32_t *)fixed32 fixed64:(uint64_t *)fixed64 data:(NSData **)d fromData:(NSData*)src;

// Writing

+ (void) writeInt:(uint64_t)i withKey:(NSInteger)key toData:(NSMutableData*)dst;
+ (void) writeFixed32:(uint32_t)i withKey:(NSInteger)key toData:(NSMutableData*)dst;
+ (void) writeFixed64:(uint64_t)i withKey:(NSInteger)key toData:(NSMutableData*)dst;
+ (void) writeLengthDelimitedData:(NSData*)data toData:(NSMutableData*)dst;
+ (void) writeData:(NSData*)d withKey:(NSInteger)key toData:(NSMutableData*)dst;
+ (void) writeString:(NSString*)string withKey:(NSInteger)key toData:(NSMutableData*)dst;

@end
