// CoreBitcoin by Oleg Andreev <oleganza@gmail.com>, WTFPL.

#import <Foundation/Foundation.h>

extern NSString* const BTCErrorDomain;

typedef NS_ENUM(NSUInteger, BTCErrorCode) {
    
    // Canonical pubkey/signature check errors
    BTCErrorNonCanonicalPublicKey            = 4001,
    BTCErrorNonCanonicalScriptSignature      = 4002,
    
    // Script verification errors
    BTCErrorScriptError                      = 5001,
    
    // BTCPriceSource errors
    BTCErrorUnsupportedCurrencyCode          = 6001,

    // BIP70 Payment Protocol errors
    BTCErrorPaymentRequestInvalidResponse    = 7001,
    BTCErrorPaymentRequestTooBig             = 7002,

    // Secret Sharing errors
    BTCErrorIncompatibleSecret               = 10001,
    BTCErrorInsufficientShares               = 10002,
    BTCErrorMalformedShare                   = 10003,
};