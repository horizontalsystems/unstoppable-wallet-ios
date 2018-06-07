// CoreBitcoin by Oleg Andreev <oleganza@gmail.com>, WTFPL.

#ifndef CoreBitcoin_BTCSignatureHashType_h
#define CoreBitcoin_BTCSignatureHashType_h

// Hash type determines how OP_CHECKSIG hashes the transaction to create or
// verify the signature in a transaction input.
// Depending on hash type, transaction is modified in some way before its hash is computed.
// Hash type is 1 byte appended to a signature in a transaction input.
typedef NS_ENUM(unsigned char, BTCSignatureHashType)
{
    // First three types are mutually exclusive (tested using "type & 0x1F").
    
    // Default. Signs all inputs and outputs.
    // Other inputs have scripts and sequences zeroed out, current input has its script
    // replaced by the previous transaction's output script (or, in case of P2SH,
    // by the signatures and the redemption script).
    // If (type & 0x1F) is not NONE or SINGLE, then this type is used.
    SIGHASH_ALL          = 1,
    BTCSignatureHashTypeAll = SIGHASH_ALL,
    
    // All outputs are removed. "I don't care where it goes as long as others pay".
    // Note: this is not safe when used with ANYONECANPAY, because then anyone who relays the transaction
    // can pick your input and use in his own transaction.
    // It's also not safe if all inputs are SIGHASH_NONE as well (or it's the only input).
    SIGHASH_NONE         = 2,
    BTCSignatureHashTypeNone = SIGHASH_NONE,
    
    // Hash only the output with the same index as the current input.
    // Preceding outputs are "nullified", other outputs are removed.
    // Special case: if there is no matching output, hash is "0000000000000000000000000000000000000000000000000000000000000001" (32 bytes)
    SIGHASH_SINGLE       = 3,
    BTCSignatureHashTypeSingle = SIGHASH_SINGLE,
    
    // This mask is used to determine one of the first types independently from ANYONECANPAY option:
    // E.g. if (type & SIGHASH_OUTPUT_MASK == SIGHASH_NONE) { blank all outputs }
    SIGHASH_OUTPUT_MASK  = 0x1F,
    BTCSignatureHashTypeOutputMask = SIGHASH_OUTPUT_MASK,
    
    // Removes all inputs except for current txin before hashing.
    // This allows to sign the transaction outputs without knowing who and how adds other inputs.
    // E.g. a crowdfunding transaction with 100 BTC output can be signed independently by any number of people
    // and will become valid only when someone combines all inputs in a single transaction to make it valid.
    // Can be used together with any of the above types.
    SIGHASH_ANYONECANPAY = 0x80,
    BTCSignatureHashTypeAnyoneCanPay = SIGHASH_ANYONECANPAY,
};

#endif
