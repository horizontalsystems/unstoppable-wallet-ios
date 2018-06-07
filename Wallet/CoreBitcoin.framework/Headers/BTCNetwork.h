// CoreBitcoin by Oleg Andreev <oleganza@gmail.com>, WTFPL.

#import <Foundation/Foundation.h>
#import <CoreBitcoin/BTC256.h>

@class BTCBigNumber;
@class BTCBlock;
@interface BTCNetwork : NSObject <NSCopying>

- (id) initWithName:(NSString*)name;

// Available networks

// Main Bitcoin network, singleton instance.
+ (BTCNetwork*) mainnet;

// Testnet3 (current testnet), singleton instance.
+ (BTCNetwork*) testnet;



// Network Parameters
// Note: all properties are writable so you can tweak parameters for testing purposes.
// If you do so, you may want to use -copy.


// Returns YES if this network is testnet3 (used to tweak certain validation rules).
@property(nonatomic, readonly) BOOL isTestnet;

// Returns opposite of `isTestnet`.
@property(nonatomic, readonly) BOOL isMainnet;

// Name of the network ("mainnet", "testnet3" etc)
@property(nonatomic, copy) NSString* name;

// Name of the network for BIP70 Payment Details ("main", "test" or some custom name used in `-initWithName:`)
@property(nonatomic, copy) NSString* paymentProtocolName;

// Hash of the genesis block.
@property(nonatomic) NSData* genesisBlockHash;

// Default port for TCP connections.
@property(nonatomic) uint32_t defaultPort;

// Maximum target for the proof of work: CBigNum(~uint256(0) >> 32) for mainnet.
@property(nonatomic) BTCBigNumber* proofOfWorkLimit;

// Array of pairs @[ @(int <height>), NSData* <hash> ] sorted by height.
@property(nonatomic) NSArray* checkpoints;


// Returns a checkpoint hash if it exists or BTC256Zero if there is no checkpoint at such height.
- (NSData*) checkpointAtHeight:(int)height;

// Returns height of checkpoint or -1 if there is no such checkpoint.
- (int) heightForCheckpoint:(NSData*)checkpointHash;

@end
