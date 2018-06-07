// CoreBitcoin by Oleg Andreev <oleganza@gmail.com>, WTFPL.

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, BTCScriptVerification) {
    BTCScriptVerificationStrictEncoding = (1U << 1), // enforce strict conformance to DER and SEC2 for signatures and pubkeys (aka SCRIPT_VERIFY_STRICTENC)
    BTCScriptVerificationEvenS          = (1U << 2), // enforce lower S values (below curve halforder) in signatures (aka SCRIPT_VERIFY_EVEN_S, depends on STRICTENC)
};

@class BTCScript;
@class BTCTransaction;

// ScriptMachine is a stack machine (like Forth) that evaluates a predicate
// returning a bool indicating valid or not. There are no loops.
// You can -copy a machine which will copy all the parameters and the stack state.
@interface BTCScriptMachine : NSObject <NSCopying>

// "To" transaction that is signed by an inputScript.
// Required parameter.
@property(nonatomic) BTCTransaction* transaction;

// An index of the tx input in the `transaction`.
// Required parameter.
@property(nonatomic) uint32_t inputIndex;

// Overrides inputScript from transaction.inputs[inputIndex].
// Useful for testing, but useless if you need to test CHECKSIG operations. In latter case you still need a full transaction.
@property(nonatomic) BTCScript* inputScript;

// A timestamp of the current block. Default is current timestamp.
// This is used to test for P2SH scripts or other changes in the protocol that may happen in the future.
// If not specified, defaults to current timestamp thus using the latest protocol rules.
@property(nonatomic) uint32_t blockTimestamp;

// Flags affecting verification. Default is the most liberal verification.
// One can be stricter to not relay transactions with non-canonical signatures and pubkey (as BitcoinQT does).
// Defaults in CoreBitcoin: be liberal in what you accept and conservative in what you send.
// So we try to create canonical purist transactions but have no problem accepting and working with non-canonical ones.
@property(nonatomic) BTCScriptVerification verificationFlags;

// Returns a copy of a stack in its current state. Mostly used for testing.
@property(nonatomic, copy, readonly) NSArray* stack;

// Returns a copy of an altstack in its current state. Mostly used for testing.
@property(nonatomic, copy, readonly) NSArray* altstack;

// This will return nil if the transaction is nil, or inputIndex is out of bounds.
// You can use -init if you want to run scripts without signature verification (so no transaction is needed).
- (id) initWithTransaction:(BTCTransaction*)tx inputIndex:(uint32_t)inputIndex;

// Verifies input script taken from transaction's input at `inputIndex` and if it doesn't fail,
// on the same stack verifies the output script.
// Returns YES if both scripts did not fail and left boolean true as a top item on the stack.
// If any transaction or outputScript is nil, or inputIndex is out of bounds, raises and exception.
// In case of a normal failure, sets an error object.
// Output script is a redemption script from a previous transaction output referenced by this transaction's input.
// Leaves stack as is after execution.
- (BOOL) verifyWithOutputScript:(BTCScript*)outputScript error:(NSError**)errorOut;

// Runs the specified script and returns YES if it does not fail.
// Does not require transaction and inputIndex unless it hits one of signature check opcodes.
// Leaves stack as is after execution.
// This function is a utility function to test scripts. It is used internally by -verifyWithOutputScript:error:
- (BOOL) runScript:(BTCScript*)script error:(NSError**)errorOut;

@end
