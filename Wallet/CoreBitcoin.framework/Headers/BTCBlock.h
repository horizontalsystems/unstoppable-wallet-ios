// CoreBitcoin by Oleg Andreev <oleganza@gmail.com>, WTFPL.

#import <Foundation/Foundation.h>

@class BTCBlockHeader;
@interface BTCBlock : NSObject <NSCopying>

@property(nonatomic, readonly) BTCBlockHeader* header;
@property(nonatomic) NSArray* transactions;

@property(nonatomic, readonly) NSData* blockHash;
@property(nonatomic, readonly) NSString* blockID;
@property(nonatomic, readonly) NSData* data; // serialized form of the block

// Informational Properties
// ------------------------
// These are available via external APIs like Chain.com.

// Height of the block. Default is 0.
@property(nonatomic) NSInteger height;

// Number of confirmations. Default is NSNotFound.
@property(nonatomic) NSUInteger confirmations;

// Arbitrary information attached to this instance.
// The reference is copied when this instance is copied.
// Default is nil.
@property(nonatomic) NSDictionary* userInfo;


// Computes merkle root hash from the current transaction array.
- (NSData*) computeMerkleRootHash;

// Updates header.merkleRootHash by hashing transactions.
// Equivalent to `block.header.merkleRootHash = [block computeMerkleRootHash]`.
- (void) updateMerkleTree;

// Instantiates an empty block with a given header.
- (id) initWithHeader:(BTCBlockHeader*)header;

@end
