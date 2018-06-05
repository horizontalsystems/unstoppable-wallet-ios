// CoreBitcoin by Oleg Andreev <oleganza@gmail.com>, WTFPL.

#import <CoreBitcoin/BTCAddress.h>

@interface BTCAssetID : BTCAddress

+ (nullable instancetype) assetIDWithHash:(nullable NSData*)data;

+ (nullable instancetype) assetIDWithString:(nullable NSString*)string;

@end
