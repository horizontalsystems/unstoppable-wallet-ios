// CoreBitcoin by Oleg Andreev <oleganza@gmail.com>, WTFPL.

#import <Foundation/Foundation.h>

@class BTCScript;
@class BTCOutpoint;
@class BTCTransaction;
@class BTCTransactionOutput;

// Transaction input (aka "txin") represents a reference to another transaction's output.
// Reference is defined by tx hash + tx output index.
// Signature script is used to prove ownership of the corresponding tx output.
// Sequence is used to require different signatures when tx is updated. It is only relevant when tx lockTime > 0.
@interface BTCTransactionInput : NSObject <NSCopying>

// Hash of the previous transaction.
@property(nonatomic) NSData* previousHash;

// Transaction ID referenced by this input (reversed previousHash in hex).
@property(nonatomic) NSString* previousTransactionID;

// Index of the previous transaction's output.
@property(nonatomic) uint32_t previousIndex;

// Outpoint of this input (previous hash and output index). Corresponds to COutPoint class in bitcoind.
@property(nonatomic) BTCOutpoint* outpoint;

// Script that proves ownership of the previous transaction output.
// This property is nil for coinbase inputs. See `coinbaseData` for raw binary data.
@property(nonatomic) BTCScript* signatureScript;

// Raw coinbase data if this input is coinbase.
// If `coinbaseData` is not nil, then `signatureScript` is nil.
@property(nonatomic) NSData* coinbaseData;

// Input sequence. Default is maximum value 0xFFFFFFFF.
// Sequence is used to update a timelocked tx stored in memory of the nodes. It is only relevant when tx lockTime > 0.
// Currently, for DoS and security reasons, nodes do not store timelocked transactions making the sequence number meaningless.
@property(nonatomic) uint32_t sequence;

// Serialized binary representation of the txin.
@property(nonatomic, readonly) NSData* data;


// Informational properties
// ------------------------
// These are set by external APIs such as Chain.com.


// Set when input is added via [tx addInput:input]
@property(weak, nonatomic) BTCTransaction* transaction;

// Optional reference to a corresponding output, typically an unspent output in a context of building a new transaction.
@property(nonatomic) BTCTransactionOutput* transactionOutput;

// Value in the corresponding output.
// Default is transactionOutput.value or -1.
@property(nonatomic) BTCAmount value;

// Arbitrary information attached to this instance.
// The reference is copied when this instance is copied.
// Default is nil.
@property(nonatomic) NSDictionary* userInfo;


// Parses tx input from a data buffer.
- (id) initWithData:(NSData*)data;

// Read tx input from the stream.
- (id) initWithStream:(NSInputStream*)stream;

// Constructs transaction input from a dictionary representation
- (id) initWithDictionary:(NSDictionary*)dictionary;

// Returns a dictionary representation suitable for encoding in JSON or Plist.
@property(nonatomic, readonly) NSDictionary* dictionary;

// Returns YES if this txin generates new coins.
@property(nonatomic, readonly) BOOL isCoinbase;

- (NSDictionary*) dictionaryRepresentation DEPRECATED_ATTRIBUTE;

@end

