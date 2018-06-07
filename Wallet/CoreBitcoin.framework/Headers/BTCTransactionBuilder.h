// CoreBitcoin by Oleg Andreev <oleganza@gmail.com>, WTFPL.

#import <Foundation/Foundation.h>
#import <CoreBitcoin/BTCUnitsAndLimits.h>
extern NSString* const BTCTransactionBuilderErrorDomain;

typedef NS_ENUM(NSUInteger, BTCTransactionBuilderError) {

    // Change address is not specified.
    BTCTransactionBuilderChangeAddressMissing = 1,

    // No unspent outputs were provided or found.
    BTCTransactionBuilderUnspentOutputsMissing = 2,

    // Unspent outputs are not sufficient to build the transaction.
    BTCTransactionBuilderInsufficientFunds = 3,
};

@class BTCKey;
@class BTCScript;
@class BTCAddress;
@class BTCTransaction;
@class BTCTransactionInput;
@class BTCTransactionOutput;
@class BTCTransactionBuilder;
@class BTCTransactionBuilderResult;

@protocol BTCTransactionBuilderDataSource <NSObject>

@required

// Called when needs inputs to spend in a transaction.
// BTCTransactionOutput instances must contain sensible `transactionHash` and `index` properties.
// Reference of BTCTransactionOutput is assigned to BTCTransactionInput so you could access it to sign the inputs.
// Unspent outputs are consumed in the same order as they are enumerated.
// For BIP32 wallets it is recommended to sort unspents by block height (oldest first) to keep the scan window short.
- (NSEnumerator* /* [BTCTransactionOutput] */) unspentOutputsForTransactionBuilder:(BTCTransactionBuilder*)txbuilder;

@optional

// Called when attempts to sign the inputs.
// Receiver should provide a key which will be used to create a proper signature script.
// Transaction builder will sign the input if it spends from one of the standard single-key scripts (p2pkh or p2pk, with compressed or uncompressed pubkeys).
// Hash type SIGHASH_ALL is used.
// Return nil if key is not available, then input will be marked as unsigned (unless signed with the next method).
- (BTCKey*) transactionBuilder:(BTCTransactionBuilder*)txbuilder keyForUnspentOutput:(BTCTransactionOutput*)txout;

// If the previous method not implemented or returns nil, or output script is not supported,
// then this method is called to allow data source to provide custom signature script.
// If this method not implemented or returns nil, then input is marked as unsigned.
- (BTCScript*) transactionBuilder:(BTCTransactionBuilder*)txbuilder signatureScriptForTransaction:(BTCTransaction*)tx script:(BTCScript*)outputScript inputIndex:(NSUInteger)inputIndex;

// Arbitrary data that acts as a random seed to shuffle inputs and outputs.
// If this method returns nil, private key (if available) will be used.
// If seed cannot be determined, then inputs and outputs are not shuffled at all to avoid matching transaction
// with this particular application ("default order" is used).
- (NSData*) shuffleSeedForTransactionBuilder:(BTCTransactionBuilder*)txbuilder;

@end

// Transaction builder allows you to compose a transaction with necessary parameters.
// It takes care of picking necessary unspent outputs and singing inputs.
@interface BTCTransactionBuilder : NSObject

// Data source that provides inputs.
// If you do not provide a dataSource, you should provide unspent outputs via `unspentOutputsEnumerator`.
@property(weak,nonatomic) id<BTCTransactionBuilderDataSource> dataSource;

// Instead of using data source, provide unspent outputs directly.
// Unspent outputs are consumed in the same order as they are enumerated.
// For BIP32 wallets it is recommended to sort unspents by block height (oldest first) to
// keep the scan window short.
@property(nonatomic) NSEnumerator* unspentOutputsEnumerator;

// Optional list of outputs for which the transaction is intended.
// If outputs is nil or empty array, will attempt to spend all input to change address ("sweeping").
// If not empty, will use the least amount of inputs to cover output values and the fee.
@property(nonatomic) NSArray* outputs;

// Change address where remaining funds should be sent.
// Either `changeAddress` or `changeScript` must not be nil.
@property(nonatomic) BTCAddress* changeAddress;

// Change script where remaining funds should be sent.
// Must not be nil. Default value is derived from `changeAddress`.
@property(nonatomic) BTCScript* changeScript;


// Attempts to build and possibly sign a transaction (if sign = YES).
// Returns a result object containing the transaction itself
// and metadata about it (fee, input and output balances, indexes of unsigned inputs).
// If failed to build a transaction, returns nil and sets error to one from BTCTransactionBuilderErrorDomain.
- (BTCTransactionBuilderResult*) buildTransaction:(NSError**)errorOut;



// Optional configuration properties
// ---------------------------------

// Fee per 1000 bytes. Default is BTCTransactionDefaultFeeRate.
@property(nonatomic) BTCAmount feeRate;

// Minimum amount of change below which transaction is not composed.
// If change amount is non-zero and below this value, more unspent outputs are used.
// If change amount is zero, change output is not even created and this property is not used.
// Default value equals feeRate.
@property(nonatomic) BTCAmount minimumChange;


// Amount of change that can be forgone as a mining fee if there are no more
// unspent outputs available. If equals zero, no amount is allowed to be forgone.
// Default value equals minimumChange.
// This means builder will never fail with BTCTransactionBuilderErrorInsufficientFunds just because it could not
// find enough unspents for big enough change. In worst case (not enough unspent to bump change) it will forgo the change
// as a part of the mining fee. Set to 0 to avoid forgoing a single satoshi.
@property(nonatomic) BTCAmount dustChange;

// Whether this builder should even attempt to sign transaction.
// Set to NO if you want a lightweight decision if there are enough funds etc
// (e.g. when doing on-the-fly calculation as user edits payment details).
// Default is YES.
@property(nonatomic) BOOL shouldSign;

// Flag determining whether builder should attempt to shuffle inputs and outputs.
// If shuffle seed is not available or private key is not provided by data source,
// then inputs/outputs will not be shuffled to avoid matching with this app's algorithm.
// Default is YES.
@property(nonatomic) BOOL shouldShuffle;

@end


// Result of building a transaction. Contains a transaction itself with various metadata.
@interface BTCTransactionBuilderResult : NSObject

// Actual transaction with complete inputs and outputs.
// If some inputs are not signed, unsignedInputsIndexes will contain their indexes.
@property(nonatomic, readonly) BTCTransaction* transaction;

// Indexes of unsigned inputs. Such inputs have BTCTransactionOutput script in place of signatureScript.
// Also, every input has a reference to unspent BTCTransactionOutput provided by data source (or unspentOutputsEnumerator).
@property(nonatomic, readonly) NSIndexSet* unsignedInputsIndexes;

// Complete fee this transaction pays to miners.
// Equals (inputsAmount - outputsAmount).
@property(nonatomic, readonly) BTCAmount fee;

// Complete amount on the inputs.
@property(nonatomic, readonly) BTCAmount inputsAmount;

// Complete amount on the outputs.
@property(nonatomic, readonly) BTCAmount outputsAmount;

@end

