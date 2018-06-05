// CoreBitcoin by Oleg Andreev <oleganza@gmail.com>, WTFPL.

#import <Foundation/Foundation.h>

@class BTCKey;

// Implementation of [ECIES](http://en.wikipedia.org/wiki/Integrated_Encryption_Scheme)
// compatible with [Bitcore ECIES](https://github.com/bitpay/bitcore-ecies) implementation.
@interface BTCEncryptedMessage : NSObject

// When encrypting, sender's keypair must contain a private key.
@property(nonatomic) BTCKey* senderKey;

// When decrypting, recipient's keypair must contain a private key.
@property(nonatomic) BTCKey* recipientKey;

- (NSData*) encrypt:(NSData*)plaintext;
- (NSData*) decrypt:(NSData*)ciphertext;

@end
