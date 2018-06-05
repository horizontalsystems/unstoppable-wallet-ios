// CoreBitcoin by Oleg Andreev <oleganza@gmail.com>, WTFPL.

#import <Foundation/Foundation.h>
#import <CoreBitcoin/BTCUnitsAndLimits.h>

@class BTCAssetID;
@class BTCPaymentMethodItem;
@class BTCPaymentMethodAsset;
@class BTCPaymentMethodRejection;
@class BTCPaymentMethodRejectedAsset;

// Reply by the user: payment_method, methods per item, assets per method.
@interface  BTCPaymentMethod : NSObject

@property(nonatomic, nullable) NSData* merchantData;
@property(nonatomic, nullable) NSArray* /* [BTCPaymentMethodItem] */ items;

// Binary serialization in protocol buffer format.
@property(nonatomic, readonly, nonnull) NSData* data;

- (nullable id) initWithData:(nullable NSData*)data;
@end





// Proposed method to pay for a given item
@interface  BTCPaymentMethodItem : NSObject

@property(nonatomic, nonnull) NSString* itemType;
@property(nonatomic, nullable) NSData* itemIdentifier;
@property(nonatomic, nullable) NSArray* /* [BTCPaymentMethodAsset] */ assets;

// Binary serialization in protocol buffer format.
@property(nonatomic, readonly, nonnull) NSData* data;

- (nullable id) initWithData:(nullable NSData*)data;
@end





// Proposed asset and amount within BTCPaymentMethodItem.
@interface  BTCPaymentMethodAsset : NSObject

@property(nonatomic, nullable) NSString* assetType; // BTCAssetTypeBitcoin or BTCAssetTypeOpenAssets
@property(nonatomic, nullable) BTCAssetID* assetID; // nil if type is "bitcoin".
@property(nonatomic) BTCAmount amount;

// Binary serialization in protocol buffer format.
@property(nonatomic, readonly, nonnull) NSData* data;

- (nullable id) initWithData:(nullable NSData*)data;
@end






// Rejection reply by the server: rejection summary and per-asset rejection info.


@interface  BTCPaymentMethodRejection : NSObject

@property(nonatomic, nullable) NSString* memo;
@property(nonatomic) uint64_t code;
@property(nonatomic, nullable) NSArray* /* [BTCPaymentMethodRejectedAsset] */ rejectedAssets;

// Binary serialization in protocol buffer format.
@property(nonatomic, readonly, nonnull) NSData* data;

- (nullable id) initWithData:(nullable NSData*)data;
@end


@interface  BTCPaymentMethodRejectedAsset : NSObject

@property(nonatomic, nonnull) NSString* assetType;  // BTCAssetTypeBitcoin or BTCAssetTypeOpenAssets
@property(nonatomic, nullable) BTCAssetID* assetID; // nil if type is "bitcoin".
@property(nonatomic) uint64_t code;
@property(nonatomic, nullable) NSString* reason;

// Binary serialization in protocol buffer format.
@property(nonatomic, readonly, nonnull) NSData* data;

- (nullable id) initWithData:(nullable NSData*)data;
@end

