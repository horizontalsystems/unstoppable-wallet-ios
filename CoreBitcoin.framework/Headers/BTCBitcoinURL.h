// CoreBitcoin by Oleg Andreev <oleganza@gmail.com>, WTFPL.

#import <Foundation/Foundation.h>
#import <CoreBitcoin/BTCUnitsAndLimits.h>

// TODO: support handling URL from UIApplicationDelegate.

/*!
 * Class to compose and handle various Bitcoin URLs according to BIP21.
 * See: https://github.com/bitcoin/bips/blob/master/bip-0021.mediawiki
 */
@class BTCAddress;
@class BTCAssetID;
@interface BTCBitcoinURL : NSObject

/*!
 * Encoded address.
 */
@property(nonatomic, nullable) BTCAddress* address;

/*!
 * Amount in satoshis. Default is 0.
 */
@property(nonatomic) BTCAmount amount;

/*!
 * Asset ID for Open Assets URL.
 */
@property(nonatomic, nullable) BTCAssetID* assetID;

/*!
 * Label. Default is nil.
 */
@property(nonatomic, nullable) NSString* label;

/*!
 * Message. Default is nil.
 */
@property(nonatomic, nullable) NSString* message;

/*!
 * Query parameters. Default is nil.
 */
@property(nonatomic, nonnull) NSDictionary* queryParameters;

/*!
 * Payment request URL (r=...). Default is nil.
 */
@property(nonatomic, nullable) NSURL* paymentRequestURL;

/*!
 * Complete URL built from the individual properties.
 */
@property(nonatomic, readonly, nonnull) NSURL* URL;

/*!
 * Returns YES if it has a valid address or paymentRequestURL.
 */
@property(nonatomic, readonly) BOOL isValid;

/*!
 * Returns YES if it is a pure bitcoin URL. That does not specify asset_id and not uses openassets: scheme.
 */
@property(nonatomic, readonly) BOOL isValidBitcoinURL;

/*!
 * Returns YES if it is an Open Assets URL.
 */
@property(nonatomic, readonly) BOOL isValidOpenAssetsURL;

/*!
 * Makes a URL in form "bitcoin:<address>?amount=1.2345&label=<label>.
 * @param address Address to be rendered in base58 format.
 * @param amount  Amount in satoshis. Note that URI scheme dictates to render this amount as a decimal number in BTC.
 * @param label   Optional label.
 */
+ (nonnull NSURL*) URLWithAddress:(nonnull BTCAddress*)address amount:(BTCAmount)amount label:(nullable NSString*)label;

/*!
 * Instantiates if URL is a valid bitcoin: URL.
 * To be valid it should either contain a valid address, or payment request URL (r=), or both.
 */
- (nullable id) initWithURL:(nullable NSURL*)url;

/*!
 * Instantiates an empty Bitcoin URL.
 * Fill in address, amount, label and other fields and use `URL` property to get a composed URL.
 */
- (nonnull id) init;

/*!
 * Object subscripting to access query parameters more conveniently
 * @param key The key in the queryParameters
 */
- (nullable id)objectForKeyedSubscript:(nonnull id <NSCopying>)key;

/*!
 * Object subscripting to set query parameter key value pairs more conveniently
 * @param obj The value to be set for key in queryParameters
 * @param key The key for value in the queryParameters
 */
- (void)setObject:(nullable id)obj forKeyedSubscript:(nonnull id <NSCopying>)key;

@end
