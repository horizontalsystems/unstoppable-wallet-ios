// CoreBitcoin by Oleg Andreev <oleganza@gmail.com>, WTFPL.

#import <Foundation/Foundation.h>
#import <CoreBitcoin/BTCBase58.h>

// These categories are optional and provided for convenience only.
// For documentation look into BTCBase58.h.
// They are also used in CoreBitcoin unit tests.
@interface NSString (BTCBase58)

// Returns data for Base58 string without checksum
// Data is mutable so you can clear sensitive information as soon as possible.
- (NSMutableData*) dataFromBase58;

// Returns data for Base58 string with checksum
- (NSMutableData*) dataFromBase58Check;

@end

@interface NSMutableData (BTCBase58)

// Returns data for Base58 string without checksum
// Data is mutable so you can clear sensitive information as soon as possible.
+ (NSMutableData*) dataFromBase58CString:(const char*)cstring;

// Returns data for Base58 string with checksum
+ (NSMutableData*) dataFromBase58CheckCString:(const char*)cstring;

@end

@interface NSData (BTCBase58)

// String in Base58 without checksum, you need to free it yourself.
// It's mutable so you can clear it securely yourself.
- (char*) base58CString;

// String in Base58 with checksum, you need to free it yourself.
// It's mutable so you can clear it securely yourself.
- (char*) base58CheckCString;

// String in Base58 without checksum
- (NSString*) base58String;

// String in Base58 with checksum
- (NSString*) base58CheckString;

@end
