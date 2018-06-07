// CoreBitcoin by Oleg Andreev <oleganza@gmail.com>, WTFPL.

#import <Foundation/Foundation.h>
#import <CoreBitcoin/BTCUnitsAndLimits.h>

typedef NS_ENUM(NSInteger, BTCNumberFormatterUnit) {
    BTCNumberFormatterUnitSatoshi  = 0, // satoshis = 0.00000001 BTC
    BTCNumberFormatterUnitBit      = 2, // bits     = 0.000001 BTC
    BTCNumberFormatterUnitMilliBTC = 5, // mBTC     = 0.001 BTC
    BTCNumberFormatterUnitBTC      = 8, // BTC      = 100 million satoshis
};

typedef NS_ENUM(NSInteger, BTCNumberFormatterSymbolStyle) {
    BTCNumberFormatterSymbolStyleNone      = 0, // no suffix
    BTCNumberFormatterSymbolStyleCode      = 1, // suffix is BTC, mBTC, Bits or SAT
    BTCNumberFormatterSymbolStyleLowercase = 2, // suffix is btc, mbtc, bits or sat
    BTCNumberFormatterSymbolStyleSymbol    = 3, // suffix is Ƀ, mɃ, ƀ or ṡ
};

extern NSString* const BTCNumberFormatterBitcoinCode;    // XBT
extern NSString* const BTCNumberFormatterSymbolBTC;      // Ƀ
extern NSString* const BTCNumberFormatterSymbolMilliBTC; // mɃ
extern NSString* const BTCNumberFormatterSymbolBit;      // ƀ
extern NSString* const BTCNumberFormatterSymbolSatoshi;  // ṡ

/*!
 * Rounds the decimal number and returns its longLongValue.
 * Do not use NSDecimalNumber.longLongValue as it will return 0 on iOS 8.0.2 if the number is not rounded first.
 */
BTCAmount BTCAmountFromDecimalNumber(NSNumber* num);

@interface BTCNumberFormatter : NSNumberFormatter

/*!
 * Instantiates and configures number formatter with given unit and suffix style.
 */
- (id) initWithBitcoinUnit:(BTCNumberFormatterUnit)unit;
- (id) initWithBitcoinUnit:(BTCNumberFormatterUnit)unit symbolStyle:(BTCNumberFormatterSymbolStyle)symbolStyle;

/*!
 * Unit size to be displayed (regardless of how it is presented)
 */
@property(nonatomic) BTCNumberFormatterUnit bitcoinUnit;

/*!
 * Style of formatting the units regardless of the unit size.
 */
@property(nonatomic) BTCNumberFormatterSymbolStyle symbolStyle;

/*!
 * Placeholder text for the input field.
 * E.g. "0 000 000.00" for 'bits' and "0.00000000" for 'BTC'.
 */
@property(nonatomic, readonly) NSString* placeholderText;

/*!
 * Returns a matching bitcoin symbol.
 * If `symbolStyle` is BTCNumberFormatterSymbolStyleNone, returns the code (BTC, mBTC, Bits or SAT).
 */
@property(nonatomic, readonly) NSString* standaloneSymbol;

/*!
 * Returns a matching bitcoin unit code (BTC, mBTC etc) regardless of the symbol style.
 */
@property(nonatomic, readonly) NSString* unitCode;

/*!
 * Formats the amount according to units and current formatting style.
 */
- (NSString *) stringFromAmount:(BTCAmount)amount;

/*!
 * Returns 0 in case of failure to parse the string.
 * To handle that case, use `-[NSNumberFormatter numberFromString:]`, but keep in mind
 * that NSNumber* will be in specified units, not in satoshis.
 */
- (BTCAmount) amountFromString:(NSString *)string;

@end
