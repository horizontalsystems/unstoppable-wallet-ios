// CoreBitcoin by Oleg Andreev <oleganza@gmail.com>, WTFPL.

#import <Foundation/Foundation.h>
#import <CoreBitcoin/BTCPaymentRequest.h>
#import <CoreBitcoin/BTCPaymentMethodRequest.h>

// Interface to BIP70 payment protocol.
// Spec: https://github.com/bitcoin/bips/blob/master/bip-0070.mediawiki
//
// * BTCPaymentProtocol implements high-level request and response API.
// * BTCPaymentRequest object that represents "PaymentRequest" as described in BIP70.
// * BTCPaymentDetails object that represents "PaymentDetails" as described in BIP70.
// * BTCPayment object that represents "Payment" as described in BIP70.
// * BTCPaymentACK object that represents "PaymentACK" as described in BIP70.

@interface BTCPaymentProtocol : NSObject

// List of accepted asset types.
@property(nonnull, nonatomic, readonly) NSArray* assetTypes;

// Instantiates default BIP70 protocol that supports only Bitcoin.
- (nonnull id) init;

// Instantiates protocol instance with accepted asset types. See BTCAssetType* constants.
- (nonnull id) initWithAssetTypes:(nonnull NSArray*)assetTypes;


// Convenience API

// Loads a BTCPaymentRequest object or BTCPaymentMethodRequest from a given URL.
// May return either PaymentMethodRequest or PaymentRequest, depending on the response from the server.
// This method ignores `assetTypes` and allows both bitcoin and openassets types.
- (void) loadPaymentMethodRequestFromURL:(nonnull NSURL*)paymentMethodRequestURL completionHandler:(nonnull void(^)(BTCPaymentMethodRequest* __nullable pmr, BTCPaymentRequest* __nullable pr, NSError* __nullable error))completionHandler;

// Loads a BTCPaymentRequest object from a given URL.
- (void) loadPaymentRequestFromURL:(nonnull NSURL*)paymentRequestURL completionHandler:(nonnull void(^)(BTCPaymentRequest* __nullable pr, NSError* __nullable error))completionHandler;

// Posts completed payment object to a given payment URL (provided in BTCPaymentDetails) and
// returns a PaymentACK object.
- (void) postPayment:(nonnull BTCPayment*)payment URL:(nonnull NSURL*)paymentURL completionHandler:(nonnull void(^)(BTCPaymentACK* __nullable ack, NSError* __nullable error))completionHandler;


// Low-level API
// (use these if you have your own connection queue).

- (nullable NSURLRequest*) requestForPaymentMethodRequestWithURL:(nonnull NSURL*)url; // default timeout is 10 sec
- (nullable NSURLRequest*) requestForPaymentMethodRequestWithURL:(nonnull NSURL*)url timeout:(NSTimeInterval)timeout;
- (nullable id) polymorphicPaymentRequestFromData:(nonnull NSData*)data response:(nonnull NSURLResponse*)response error:(NSError* __nullable * __nullable)errorOut;

- (nullable NSURLRequest*) requestForPaymentRequestWithURL:(nonnull NSURL*)url; // default timeout is 10 sec
- (nullable NSURLRequest*) requestForPaymentRequestWithURL:(nonnull NSURL*)url timeout:(NSTimeInterval)timeout;
- (nullable BTCPaymentRequest*) paymentRequestFromData:(nonnull NSData*)data response:(nonnull NSURLResponse*)response error:(NSError* __nullable * __nullable)errorOut;

- (nullable NSURLRequest*) requestForPayment:(nonnull BTCPayment*)payment url:(nonnull NSURL*)paymentURL; // default timeout is 10 sec
- (nullable NSURLRequest*) requestForPayment:(nonnull BTCPayment*)payment url:(nonnull NSURL*)paymentURL timeout:(NSTimeInterval)timeout;
- (nullable BTCPaymentACK*) paymentACKFromData:(nonnull NSData*)data response:(nonnull NSURLResponse*)response error:(NSError* __nullable * __nullable)errorOut;


// Deprecated Methods

+ (void) loadPaymentRequestFromURL:(nonnull NSURL*)paymentRequestURL completionHandler:(nonnull void(^)(BTCPaymentRequest* __nullable pr, NSError* __nullable error))completionHandler DEPRECATED_ATTRIBUTE;
+ (void) postPayment:(nonnull BTCPayment*)payment URL:(nonnull NSURL*)paymentURL completionHandler:(nonnull void(^)(BTCPaymentACK* __nullable ack, NSError* __nullable error))completionHandler DEPRECATED_ATTRIBUTE;

+ (nullable NSURLRequest*) requestForPaymentRequestWithURL:(nonnull NSURL*)paymentRequestURL DEPRECATED_ATTRIBUTE; // default timeout is 10 sec
+ (nullable NSURLRequest*) requestForPaymentRequestWithURL:(nonnull NSURL*)paymentRequestURL timeout:(NSTimeInterval)timeout DEPRECATED_ATTRIBUTE;
+ (nullable BTCPaymentRequest*) paymentRequestFromData:(nonnull NSData*)data response:(nonnull NSURLResponse*)response error:(NSError* __nullable * __nullable)errorOut DEPRECATED_ATTRIBUTE;

+ (nullable NSURLRequest*) requestForPayment:(nonnull BTCPayment*)payment url:(nonnull NSURL*)paymentURL DEPRECATED_ATTRIBUTE; // default timeout is 10 sec
+ (nullable NSURLRequest*) requestForPayment:(nonnull BTCPayment*)payment url:(nonnull NSURL*)paymentURL timeout:(NSTimeInterval)timeout DEPRECATED_ATTRIBUTE;
+ (nullable BTCPaymentACK*) paymentACKFromData:(nonnull NSData*)data response:(nonnull NSURLResponse*)response error:(NSError* __nullable * __nullable)errorOut DEPRECATED_ATTRIBUTE;

@end
