// CoreBitcoin by Oleg Andreev <oleganza@gmail.com>, WTFPL.

#import <Foundation/Foundation.h>
#import <CoreBitcoin/BTCUnitsAndLimits.h>

typedef NS_ENUM(NSInteger, BTCCurrencyConverterMode) {
    /*!
     * Uses the average exchange rate to convert btc to fiat and back.
     */
    BTCCurrencyConverterModeAverage  = 0,

    /*!
     * Uses the buy rate to convert btc to fiat and back.
     * Assumes "buying bitcoins" mode:
     * fiat -> btc: "How much btc will I buy for that much of fiat"
     * btc -> fiat: "How much fiat should I spend to buy that much btc"
     */
    BTCCurrencyConverterModeBuy      = 10,

    /*!
     * Uses the sell rate to convert btc to fiat and back.
     * Assumes "sell bitcoins" mode:
     * fiat -> btc: "How much btc should I sell to get this much fiat"
     * btc -> fiat: "How much fiat will I buy for that much of btc"
     */
    BTCCurrencyConverterModeSell     = 20,

    /*!
     * Instead of using simple buy rate, "eats" through order book asks.
     */
    BTCCurrencyConverterModeBuyOrderBook = 11,

    /*!
     * Instead of using simple sell rate, "eats" through order book bids.
     */
    BTCCurrencyConverterModeSellOrderBook = 21,
};

/*!
 Currency converter allows converting according currency using various modes and sources.
 */
@interface BTCCurrencyConverter : NSObject<NSCopying>

/*!
 * Conversion mode. Depending on your needs (selling or buying bitcoin) you may set various modes.
 * Default is BTCCurrencyConverterModeAverage.
 */
@property(nonatomic) BTCCurrencyConverterMode mode;

/*!
 * Average rate. When set, overwrites buy and sell rates.
 */
@property(nonatomic) NSDecimalNumber* averageRate;

/*!
 * Buy exchange rate (price for 1 BTC when you buy BTC).
 * When set, recomputes average exchange rate using sell rate.
 * If sell rate is nil, it is set to buy rate.
 */
@property(nonatomic) NSDecimalNumber* buyRate;

/*!
 * Sell exchange rate (price for 1 BTC when you sell BTC).
 * When set, recomputes average exchange rate using buy rate.
 * If buy rate is nil, it is set to sell rate.
 */
@property(nonatomic) NSDecimalNumber* sellRate;

/*!
 * List of @[ NSNumber price-per-btc, NSNumber btcs ] pairs for order book asks.
 * When set, updates buyRate to the lowest price.
 */
@property(nonatomic) NSArray* asks;

/*!
 * List of @[ NSNumber price-per-btc, NSNumber btcs ] pairs for order book bids.
 * When set, updates sellRate to the highest price.
 */
@property(nonatomic) NSArray* bids;

/*!
 * Date of last update. It is set automatically when exchange rates are updated,
 * but you can set it manually afterwards.
 */
@property(nonatomic) NSDate* date;

/*!
 * Code of the fiat currency in which prices are expressed.
 */
@property(nonatomic) NSString* currencyCode;

/*!
 * Code of the fiat currency used by exchange natively.
 * Typically, it is the same as `currencyCode`, but may differ if,
 * for instance, prices are expressed in USD, but exchange operates in EUR.
 */
@property(nonatomic) NSString* nativeCurrencyCode;

/*!
 * Name of the exchange/market that provides this exchange rate.
 * Deprecated. Use sourceName instead.
 */
@property(nonatomic) NSString* marketName DEPRECATED_ATTRIBUTE;

/*!
 * Name of the exchange market or price index that provides this exchange rate.
 */
@property(nonatomic) NSString* sourceName;

/*!
 * Serializes state into a plist/json dictionary.
 */
@property(nonatomic, readonly) NSDictionary* dictionary;

/*!
 * Serializes state into a plist/json dictionary.
 */
- (id) initWithDictionary:(NSDictionary*)dict;

/*!
 * Converts fiat amount to bitcoin amount in satoshis using specified mode.
 */
- (BTCAmount) bitcoinFromFiat:(NSDecimalNumber*)fiatAmount;

/*!
 * Converts bitcoin amount to fiat amount using specified mode.
 */
- (NSDecimalNumber*) fiatFromBitcoin:(BTCAmount)satoshis;


@end
