#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSError.h>
#import <Foundation/NSObject.h>
#import <Foundation/NSSet.h>
#import <Foundation/NSString.h>
#import <Foundation/NSValue.h>

@class TKKTonApiAdnl, TKKBalanceStorage, TKKTonBalanceQueries, TKKDriverFactory, TKKTonTransactionQueries, TKKKitDatabaseCompanion, TKKTonTransactionAdapter, TKKKotlinThrowable, TKKKotlinArray<T>, TKKKotlinException, TKKSyncError, TKKSyncState, TKKTransactionManager, TKKBalanceManager, TKKConnectionManager, TKKTon_kotlin_block_tlbAddrStd, TKKTon_kotlin_liteclientFullAccountState, TKKTon_kotlin_liteclientLiteClient, TKKTonTransaction, TKKTonBalance, TKKKotlinUnit, TKKRuntimeTransacterTransaction, TKKRuntimeBaseTransacterImpl, TKKRuntimeTransacterImpl, TKKRuntimeQuery<__covariant RowType>, TKKSyncer, TKKTransactionSender, TKKTonKitCompanion, TKKTransactionType, TKKTonKit, TKKKotlinByteArray, TKKTransactionStorage, TKKTon_kotlin_tonapi_tlPrivateKeyEd25519, TKKKotlinEnumCompanion, TKKKotlinEnum<E>, TKKTransferCompanion, TKKTransfer, TKKKotlinByteIterator, NSData, TKKKotlinRuntimeException, TKKKotlinIllegalStateException, TKKRuntimeAfterVersion, TKKTon_kotlin_tlbTlbPrettyPrinter, TKKTon_kotlin_block_tlbAnycast, TKKTon_kotlin_block_tlbAddrStdCompanion, TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt, TKKTon_kotlin_liteclientTransactionId, TKKTon_kotlin_liteclientFullAccountStateCompanion, TKKTon_kotlin_liteclientTransactionInfo, TKKTon_kotlin_tonapi_tlLiteServerDesc, TKKTon_kotlin_tonapi_tlLiteClientConfigGlobal, TKKTon_kotlin_block_tlbBlock, TKKKotlinx_datetimeInstant, TKKTon_kotlin_liteapi_tlLiteServerVersion, TKKTon_kotlin_liteapi_tlLiteServerAccountId, TKKTon_kotlin_block_tlbMessage<X>, TKKTon_kotlin_liteapi_tlLiteServerSendMsgStatus, TKKRuntimeExecutableQuery<__covariant RowType>, TKKTon_kotlin_tonapi_tlAdnlIdShort, TKKTon_kotlin_tlByteString, TKKTon_kotlin_tonapi_tlPrivateKeyEd25519Companion, TKKTon_kotlin_tonapi_tlPublicKeyEd25519, TKKKotlinBooleanArray, TKKKotlinIntRange, TKKKotlinStringBuilder, TKKTon_kotlin_block_tlbAnycastCompanion, TKKTon_kotlin_tlbTlbConstructor<T>, TKKTon_kotlin_tonapi_tlTonNodeBlockIdExtCompanion, TKKTon_kotlin_liteclientTransactionIdCompanion, TKKTon_kotlin_liteclientTransactionInfoCompanion, TKKTon_kotlin_tonapi_tlLiteServerDescCompanion, TKKTon_kotlin_tonapi_tlDhtConfigGlobal, TKKTon_kotlin_tonapi_tlValidatorConfigGlobal, TKKTon_kotlin_tonapi_tlLiteClientConfigGlobalCompanion, TKKTon_kotlin_block_tlbBlockCompanion, TKKKotlinx_datetimeInstantCompanion, TKKTon_kotlin_liteapi_tlLiteServerVersionCompanion, TKKTon_kotlin_liteapi_tlLiteServerAccountIdCompanion, TKKTon_kotlin_tvmCellType, TKKTon_kotlin_block_tlbMessageCompanion, TKKTon_kotlin_liteapi_tlLiteServerSendMsgStatusCompanion, TKKKtor_ioOutput, TKKKtor_ioByteReadPacket, TKKTon_kotlin_liteapi_tlLiteServerGetAccountState, TKKTon_kotlin_liteapi_tlLiteServerAccountState, TKKTon_kotlin_liteapi_tlLiteServerGetAllShardsInfo, TKKTon_kotlin_liteapi_tlLiteServerAllShardsInfo, TKKTon_kotlin_liteapi_tlLiteServerGetBlock, TKKTon_kotlin_liteapi_tlLiteServerBlockData, TKKTon_kotlin_liteapi_tlLiteServerGetBlockHeader, TKKTon_kotlin_liteapi_tlLiteServerBlockHeader, TKKTon_kotlin_liteapi_tlLiteServerGetBlockProof, TKKTon_kotlin_liteapi_tlLiteServerPartialBlockProof, TKKTon_kotlin_liteapi_tlLiteServerGetConfigAll, TKKTon_kotlin_liteapi_tlLiteServerConfigInfo, TKKTon_kotlin_liteapi_tlLiteServerGetConfigParams, TKKTon_kotlin_liteapi_tlLiteServerGetMasterchainInfo, TKKTon_kotlin_liteapi_tlLiteServerMasterchainInfo, TKKTon_kotlin_liteapi_tlLiteServerGetMasterchainInfoExt, TKKTon_kotlin_liteapi_tlLiteServerMasterchainInfoExt, TKKTon_kotlin_liteapi_tlLiteServerGetOneTransaction, TKKTon_kotlin_liteapi_tlLiteServerTransactionInfo, TKKTon_kotlin_liteapi_tlLiteServerGetShardInfo, TKKTon_kotlin_liteapi_tlLiteServerShardInfo, TKKTon_kotlin_liteapi_tlLiteServerGetState, TKKTon_kotlin_liteapi_tlLiteServerBlockState, TKKTon_kotlin_liteapi_tlLiteServerGetTime, TKKTon_kotlin_liteapi_tlLiteServerCurrentTime, TKKTon_kotlin_liteapi_tlLiteServerGetTransactions, TKKTon_kotlin_liteapi_tlLiteServerTransactionList, TKKTon_kotlin_liteapi_tlLiteServerGetValidatorStats, TKKTon_kotlin_liteapi_tlLiteServerValidatorStats, TKKTon_kotlin_liteapi_tlLiteServerGetVersion, TKKTon_kotlin_liteapi_tlLiteServerListBlockTransactions, TKKTon_kotlin_liteapi_tlLiteServerBlockTransactions, TKKTon_kotlin_liteapi_tlLiteServerLookupBlock, TKKTon_kotlin_liteapi_tlLiteServerRunSmcMethod, TKKTon_kotlin_liteapi_tlLiteServerRunMethodResult, TKKTon_kotlin_liteapi_tlLiteServerSendMessage, TKKTon_kotlin_tonapi_tlAdnlIdShortCompanion, TKKTon_kotlin_tonapi_tlOverlayNode, TKKTon_kotlin_tlByteStringCompanion, TKKKtor_ioInput, TKKTon_kotlin_tlTlReader, TKKTon_kotlin_tlTlWriter, TKKTon_kotlin_tlTlConstructor<T>, TKKKotlinRandom, TKKTon_kotlin_tonapi_tlPublicKeyEd25519Companion, TKKKotlinx_serialization_coreSerializersModule, TKKKotlinx_serialization_coreSerialKind, TKKKotlinNothing, TKKKotlinBooleanIterator, TKKKotlinIntProgressionCompanion, TKKKotlinIntIterator, TKKKotlinIntProgression, TKKKotlinIntRangeCompanion, TKKKotlinCharArray, TKKTon_kotlin_bigintBigInt, TKKTon_kotlin_tlbAbstractTlbConstructorCompanion, TKKTon_kotlin_tlbAbstractTlbConstructor<T>, TKKTon_kotlin_tonapi_tlDhtNode, TKKTon_kotlin_tonapi_tlDhtNodes, TKKTon_kotlin_tonapi_tlDhtConfigGlobalCompanion, TKKTon_kotlin_tonapi_tlValidatorConfigGlobalCompanion, TKKTon_kotlin_tlbTlbCombinator<T>, TKKTon_kotlin_block_tlbVmStackNull, TKKTon_kotlin_tvmCellTypeCompanion, TKKKotlinPair<__covariant A, __covariant B>, TKKKtor_ioMemory, TKKKtor_ioChunkBuffer, TKKKtor_ioInputCompanion, TKKKtor_ioByteReadPacketCompanion, TKKTon_kotlin_liteapi_tlLiteServerGetAccountStateCompanion, TKKTon_kotlin_liteapi_tlLiteServerAccountStateCompanion, TKKTon_kotlin_liteapi_tlLiteServerGetAllShardsInfoCompanion, TKKTon_kotlin_liteapi_tlLiteServerAllShardsInfoCompanion, TKKTon_kotlin_liteapi_tlLiteServerGetBlockCompanion, TKKTon_kotlin_liteapi_tlLiteServerBlockDataCompanion, TKKTon_kotlin_liteapi_tlLiteServerGetBlockHeaderCompanion, TKKTon_kotlin_liteapi_tlLiteServerBlockHeaderCompanion, TKKTon_kotlin_liteapi_tlLiteServerGetBlockProofCompanion, TKKTon_kotlin_liteapi_tlLiteServerPartialBlockProofCompanion, TKKTon_kotlin_liteapi_tlLiteServerGetConfigAllCompanion, TKKTon_kotlin_liteapi_tlLiteServerConfigInfoCompanion, TKKTon_kotlin_liteapi_tlLiteServerGetConfigParamsCompanion, TKKTon_kotlin_tonapi_tlTonNodeZeroStateIdExt, TKKTon_kotlin_liteapi_tlLiteServerMasterchainInfoCompanion, TKKTon_kotlin_liteapi_tlLiteServerGetMasterchainInfoExtCompanion, TKKTon_kotlin_liteapi_tlLiteServerMasterchainInfoExtCompanion, TKKTon_kotlin_liteapi_tlLiteServerGetOneTransactionCompanion, TKKTon_kotlin_liteapi_tlLiteServerTransactionInfoCompanion, TKKTon_kotlin_liteapi_tlLiteServerGetShardInfoCompanion, TKKTon_kotlin_liteapi_tlLiteServerShardInfoCompanion, TKKTon_kotlin_liteapi_tlLiteServerGetStateCompanion, TKKTon_kotlin_liteapi_tlLiteServerBlockStateCompanion, TKKTon_kotlin_liteapi_tlLiteServerCurrentTimeCompanion, TKKTon_kotlin_liteapi_tlLiteServerGetTransactionsCompanion, TKKTon_kotlin_liteapi_tlLiteServerTransactionListCompanion, TKKTon_kotlin_liteapi_tlLiteServerGetValidatorStatsCompanion, TKKTon_kotlin_liteapi_tlLiteServerValidatorStatsCompanion, TKKTon_kotlin_liteapi_tlLiteServerTransactionId3, TKKTon_kotlin_liteapi_tlLiteServerListBlockTransactionsCompanion, TKKTon_kotlin_liteapi_tlLiteServerTransactionId, TKKTon_kotlin_liteapi_tlLiteServerBlockTransactionsCompanion, TKKTon_kotlin_liteapi_tlLiteServerLookupBlockCompanion, TKKTon_kotlin_liteapi_tlLiteServerRunSmcMethodCompanion, TKKTon_kotlin_liteapi_tlLiteServerRunMethodResultCompanion, TKKTon_kotlin_liteapi_tlLiteServerSendMessageCompanion, TKKTon_kotlin_tonapi_tlOverlayNodeCompanion, TKKKotlinRandomDefault, TKKKotlinCharIterator, TKKKotlinNumber, TKKTon_kotlin_tonapi_tlAdnlAddressList, TKKTon_kotlin_tonapi_tlDhtNodeCompanion, TKKTon_kotlin_tonapi_tlAdnlNode, TKKTon_kotlin_tonapi_tlDhtNodesCompanion, TKKTon_kotlin_tonapi_tlAdnlNodes, TKKTon_kotlin_tlbAbstractTlbCombinator<T>, TKKKtor_ioMemoryCompanion, TKKKtor_ioBufferCompanion, TKKKtor_ioBuffer, TKKKtor_ioChunkBufferCompanion, TKKTon_kotlin_tonapi_tlTonNodeZeroStateIdExtCompanion, TKKTon_kotlin_liteapi_tlLiteServerTransactionId3Companion, TKKTon_kotlin_liteapi_tlLiteServerTransactionIdCompanion, TKKTon_kotlin_tonapi_tlAdnlAddressListCompanion, TKKTon_kotlin_tonapi_tlAdnlNodeCompanion, TKKTon_kotlin_tonapi_tlAdnlNodesCompanion;

@protocol TKKKotlinx_coroutines_coreFlow, TKKKotlinx_coroutines_coreStateFlow, TKKRuntimeSqlDriver, TKKRuntimeTransactionWithoutReturn, TKKRuntimeTransactionWithReturn, TKKRuntimeTransacterBase, TKKRuntimeTransacter, TKKKitDatabase, TKKRuntimeSqlSchema, TKKRuntimeColumnAdapter, TKKKotlinComparable, TKKKotlinx_serialization_coreKSerializer, TKKCancellable, TKKKotlinx_coroutines_coreFlowCollector, TKKKotlinx_coroutines_coreSharedFlow, TKKRuntimeQueryListener, TKKRuntimeQueryResult, TKKRuntimeSqlPreparedStatement, TKKRuntimeSqlCursor, TKKRuntimeCloseable, TKKRuntimeTransactionCallbacks, TKKKotlinIterator, TKKTon_kotlin_bitstringBitString, TKKTon_kotlin_tlbTlbObject, TKKTon_kotlin_block_tlbMsgAddress, TKKTon_kotlin_block_tlbMsgAddressInt, TKKTon_kotlin_block_tlbMaybe, TKKTon_kotlin_tlbCellRef, TKKKtor_ioCloseable, TKKKotlinCoroutineContext, TKKKotlinx_coroutines_coreCoroutineScope, TKKTon_kotlin_liteclientLiteClientApi, TKKTon_kotlin_tonapi_tlTonNodeBlockId, TKKTon_kotlin_block_tlbVmStackValue, TKKTon_kotlin_block_tlbVmStack, TKKTon_kotlin_tvmCell, TKKTon_kotlin_tvmBagOfCells, TKKTon_kotlin_liteapi_tlLiteApiClient, TKKTon_kotlin_tonapi_tlPublicKey, TKKTon_kotlin_cryptoDecryptor, TKKTon_kotlin_tonapi_tlPrivateKey, TKKKotlinx_serialization_coreEncoder, TKKKotlinx_serialization_coreSerialDescriptor, TKKKotlinx_serialization_coreSerializationStrategy, TKKKotlinx_serialization_coreDecoder, TKKKotlinx_serialization_coreDeserializationStrategy, TKKTon_kotlin_bitstringMutableBitString, TKKKotlinIterable, TKKTon_kotlin_tvmCellBuilder, TKKTon_kotlin_tlbTlbStorer, TKKTon_kotlin_tvmCellSlice, TKKTon_kotlin_tlbTlbLoader, TKKTon_kotlin_tlbTlbCodec, TKKKotlinCoroutineContextElement, TKKKotlinCoroutineContextKey, TKKTon_kotlin_block_tlbMutableVmStack, TKKTon_kotlin_block_tlbVmStackList, TKKKotlinCollection, TKKKotlinSequence, TKKTon_kotlin_tvmCellDescriptor, TKKTon_kotlin_block_tlbCommonMsgInfo, TKKTon_kotlin_block_tlbEither, TKKTon_kotlin_tlTlCodec, TKKTon_kotlin_liteapi_tlLiteApi, TKKTon_kotlin_cryptoEncryptor, TKKTon_kotlin_tlTlObject, TKKTon_kotlin_tlTlDecoder, TKKTon_kotlin_tlTlEncoder, TKKKotlinx_serialization_coreCompositeEncoder, TKKKotlinAnnotation, TKKKotlinx_serialization_coreCompositeDecoder, TKKKotlinClosedRange, TKKKotlinOpenEndRange, TKKKotlinCharSequence, TKKKotlinAppendable, TKKTon_kotlin_tlbTlbProvider, TKKTon_kotlin_tlbTlbConstructorProvider, TKKTon_kotlin_tlbTlbCombinatorProvider, TKKTon_kotlin_block_tlbVmCont, TKKTon_kotlin_block_tlbVmStackNumber, TKKTon_kotlin_block_tlbVmTuple, TKKKtor_ioObjectPool, TKKTon_kotlin_tlTLFunction, TKKTon_kotlin_liteapi_tlLiteServerBlockLink, TKKTon_kotlin_tonapi_tlSignedTlObject, TKKKotlinx_serialization_coreSerializersModuleCollector, TKKKotlinKClass, TKKKotlinKDeclarationContainer, TKKKotlinKAnnotatedElement, TKKKotlinKClassifier, TKKTon_kotlin_tonapi_tlAdnlAddress;

NS_ASSUME_NONNULL_BEGIN
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunknown-warning-option"
#pragma clang diagnostic ignored "-Wincompatible-property-type"
#pragma clang diagnostic ignored "-Wnullability"

#pragma push_macro("_Nullable_result")
#if !__has_feature(nullability_nullable_result)
#undef _Nullable_result
#define _Nullable_result _Nullable
#endif

__attribute__((swift_name("KotlinBase")))
@interface TKKBase : NSObject
- (instancetype)init __attribute__((unavailable));
+ (instancetype)new __attribute__((unavailable));
+ (void)initialize __attribute__((objc_requires_super));
@end

@interface TKKBase (TKKBaseCopying) <NSCopying>
@end

__attribute__((swift_name("KotlinMutableSet")))
@interface TKKMutableSet<ObjectType> : NSMutableSet<ObjectType>
@end

__attribute__((swift_name("KotlinMutableDictionary")))
@interface TKKMutableDictionary<KeyType, ObjectType> : NSMutableDictionary<KeyType, ObjectType>
@end

@interface NSError (NSErrorTKKKotlinException)
@property (readonly) id _Nullable kotlinException;
@end

__attribute__((swift_name("KotlinNumber")))
@interface TKKNumber : NSNumber
- (instancetype)initWithChar:(char)value __attribute__((unavailable));
- (instancetype)initWithUnsignedChar:(unsigned char)value __attribute__((unavailable));
- (instancetype)initWithShort:(short)value __attribute__((unavailable));
- (instancetype)initWithUnsignedShort:(unsigned short)value __attribute__((unavailable));
- (instancetype)initWithInt:(int)value __attribute__((unavailable));
- (instancetype)initWithUnsignedInt:(unsigned int)value __attribute__((unavailable));
- (instancetype)initWithLong:(long)value __attribute__((unavailable));
- (instancetype)initWithUnsignedLong:(unsigned long)value __attribute__((unavailable));
- (instancetype)initWithLongLong:(long long)value __attribute__((unavailable));
- (instancetype)initWithUnsignedLongLong:(unsigned long long)value __attribute__((unavailable));
- (instancetype)initWithFloat:(float)value __attribute__((unavailable));
- (instancetype)initWithDouble:(double)value __attribute__((unavailable));
- (instancetype)initWithBool:(BOOL)value __attribute__((unavailable));
- (instancetype)initWithInteger:(NSInteger)value __attribute__((unavailable));
- (instancetype)initWithUnsignedInteger:(NSUInteger)value __attribute__((unavailable));
+ (instancetype)numberWithChar:(char)value __attribute__((unavailable));
+ (instancetype)numberWithUnsignedChar:(unsigned char)value __attribute__((unavailable));
+ (instancetype)numberWithShort:(short)value __attribute__((unavailable));
+ (instancetype)numberWithUnsignedShort:(unsigned short)value __attribute__((unavailable));
+ (instancetype)numberWithInt:(int)value __attribute__((unavailable));
+ (instancetype)numberWithUnsignedInt:(unsigned int)value __attribute__((unavailable));
+ (instancetype)numberWithLong:(long)value __attribute__((unavailable));
+ (instancetype)numberWithUnsignedLong:(unsigned long)value __attribute__((unavailable));
+ (instancetype)numberWithLongLong:(long long)value __attribute__((unavailable));
+ (instancetype)numberWithUnsignedLongLong:(unsigned long long)value __attribute__((unavailable));
+ (instancetype)numberWithFloat:(float)value __attribute__((unavailable));
+ (instancetype)numberWithDouble:(double)value __attribute__((unavailable));
+ (instancetype)numberWithBool:(BOOL)value __attribute__((unavailable));
+ (instancetype)numberWithInteger:(NSInteger)value __attribute__((unavailable));
+ (instancetype)numberWithUnsignedInteger:(NSUInteger)value __attribute__((unavailable));
@end

__attribute__((swift_name("KotlinByte")))
@interface TKKByte : TKKNumber
- (instancetype)initWithChar:(char)value;
+ (instancetype)numberWithChar:(char)value;
@end

__attribute__((swift_name("KotlinUByte")))
@interface TKKUByte : TKKNumber
- (instancetype)initWithUnsignedChar:(unsigned char)value;
+ (instancetype)numberWithUnsignedChar:(unsigned char)value;
@end

__attribute__((swift_name("KotlinShort")))
@interface TKKShort : TKKNumber
- (instancetype)initWithShort:(short)value;
+ (instancetype)numberWithShort:(short)value;
@end

__attribute__((swift_name("KotlinUShort")))
@interface TKKUShort : TKKNumber
- (instancetype)initWithUnsignedShort:(unsigned short)value;
+ (instancetype)numberWithUnsignedShort:(unsigned short)value;
@end

__attribute__((swift_name("KotlinInt")))
@interface TKKInt : TKKNumber
- (instancetype)initWithInt:(int)value;
+ (instancetype)numberWithInt:(int)value;
@end

__attribute__((swift_name("KotlinUInt")))
@interface TKKUInt : TKKNumber
- (instancetype)initWithUnsignedInt:(unsigned int)value;
+ (instancetype)numberWithUnsignedInt:(unsigned int)value;
@end

__attribute__((swift_name("KotlinLong")))
@interface TKKLong : TKKNumber
- (instancetype)initWithLongLong:(long long)value;
+ (instancetype)numberWithLongLong:(long long)value;
@end

__attribute__((swift_name("KotlinULong")))
@interface TKKULong : TKKNumber
- (instancetype)initWithUnsignedLongLong:(unsigned long long)value;
+ (instancetype)numberWithUnsignedLongLong:(unsigned long long)value;
@end

__attribute__((swift_name("KotlinFloat")))
@interface TKKFloat : TKKNumber
- (instancetype)initWithFloat:(float)value;
+ (instancetype)numberWithFloat:(float)value;
@end

__attribute__((swift_name("KotlinDouble")))
@interface TKKDouble : TKKNumber
- (instancetype)initWithDouble:(double)value;
+ (instancetype)numberWithDouble:(double)value;
@end

__attribute__((swift_name("KotlinBoolean")))
@interface TKKBoolean : TKKNumber
- (instancetype)initWithBool:(BOOL)value;
+ (instancetype)numberWithBool:(BOOL)value;
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("BalanceManager")))
@interface TKKBalanceManager : TKKBase
- (instancetype)initWithAdnl:(TKKTonApiAdnl *)adnl balanceStorage:(TKKBalanceStorage *)balanceStorage __attribute__((swift_name("init(adnl:balanceStorage:)"))) __attribute__((objc_designated_initializer));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)syncWithCompletionHandler:(void (^)(id<TKKKotlinx_coroutines_coreFlow> _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("sync(completionHandler:)")));
@property (readonly) id<TKKKotlinx_coroutines_coreStateFlow> balanceFlow __attribute__((swift_name("balanceFlow")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("BalanceStorage")))
@interface TKKBalanceStorage : TKKBase
- (instancetype)initWithBalanceQuery:(TKKTonBalanceQueries *)balanceQuery __attribute__((swift_name("init(balanceQuery:)"))) __attribute__((objc_designated_initializer));
- (NSString *)getBalance __attribute__((swift_name("getBalance()")));
- (void)setBalanceV:(NSString *)v __attribute__((swift_name("setBalance(v:)")));
@end

__attribute__((swift_name("Cancellable")))
@protocol TKKCancellable
@required
- (void)cancel __attribute__((swift_name("cancel()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("ConnectionManager")))
@interface TKKConnectionManager : TKKBase
- (instancetype)init __attribute__((swift_name("init()"))) __attribute__((objc_designated_initializer));
+ (instancetype)new __attribute__((availability(swift, unavailable, message="use object initializers instead")));
- (void)start __attribute__((swift_name("start()")));
- (void)stop __attribute__((swift_name("stop()")));
@property (readonly) id<TKKKotlinx_coroutines_coreStateFlow> isConnectedFlow __attribute__((swift_name("isConnectedFlow")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Database")))
@interface TKKDatabase : TKKBase
- (instancetype)initWithDatabaseDriverFactory:(TKKDriverFactory *)databaseDriverFactory databaseName:(NSString *)databaseName __attribute__((swift_name("init(databaseDriverFactory:databaseName:)"))) __attribute__((objc_designated_initializer));
@property (readonly) TKKTonBalanceQueries *balanceQuery __attribute__((swift_name("balanceQuery")));
@property (readonly) TKKTonTransactionQueries *transactionQuery __attribute__((swift_name("transactionQuery")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("DriverFactory")))
@interface TKKDriverFactory : TKKBase
- (instancetype)init __attribute__((swift_name("init()"))) __attribute__((objc_designated_initializer));
+ (instancetype)new __attribute__((availability(swift, unavailable, message="use object initializers instead")));
- (id<TKKRuntimeSqlDriver>)createDriverDatabaseName:(NSString *)databaseName __attribute__((swift_name("createDriver(databaseName:)")));
@end

__attribute__((swift_name("RuntimeTransacterBase")))
@protocol TKKRuntimeTransacterBase
@required
@end

__attribute__((swift_name("RuntimeTransacter")))
@protocol TKKRuntimeTransacter <TKKRuntimeTransacterBase>
@required
- (void)transactionNoEnclosing:(BOOL)noEnclosing body:(void (^)(id<TKKRuntimeTransactionWithoutReturn>))body __attribute__((swift_name("transaction(noEnclosing:body:)")));
- (id _Nullable)transactionWithResultNoEnclosing:(BOOL)noEnclosing bodyWithReturn:(id _Nullable (^)(id<TKKRuntimeTransactionWithReturn>))bodyWithReturn __attribute__((swift_name("transactionWithResult(noEnclosing:bodyWithReturn:)")));
@end

__attribute__((swift_name("KitDatabase")))
@protocol TKKKitDatabase <TKKRuntimeTransacter>
@required
@property (readonly) TKKTonBalanceQueries *tonBalanceQueries __attribute__((swift_name("tonBalanceQueries")));
@property (readonly) TKKTonTransactionQueries *tonTransactionQueries __attribute__((swift_name("tonTransactionQueries")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("KitDatabaseCompanion")))
@interface TKKKitDatabaseCompanion : TKKBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKKitDatabaseCompanion *shared __attribute__((swift_name("shared")));
- (id<TKKKitDatabase>)invokeDriver:(id<TKKRuntimeSqlDriver>)driver TonTransactionAdapter:(TKKTonTransactionAdapter *)TonTransactionAdapter __attribute__((swift_name("invoke(driver:TonTransactionAdapter:)")));
@property (readonly) id<TKKRuntimeSqlSchema> Schema __attribute__((swift_name("Schema")));
@end

__attribute__((swift_name("KotlinThrowable")))
@interface TKKKotlinThrowable : TKKBase
- (instancetype)initWithMessage:(NSString * _Nullable)message __attribute__((swift_name("init(message:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithCause:(TKKKotlinThrowable * _Nullable)cause __attribute__((swift_name("init(cause:)"))) __attribute__((objc_designated_initializer));
- (instancetype)init __attribute__((swift_name("init()"))) __attribute__((objc_designated_initializer));
+ (instancetype)new __attribute__((availability(swift, unavailable, message="use object initializers instead")));
- (instancetype)initWithMessage:(NSString * _Nullable)message cause:(TKKKotlinThrowable * _Nullable)cause __attribute__((swift_name("init(message:cause:)"))) __attribute__((objc_designated_initializer));

/**
 * @note annotations
 *   kotlin.experimental.ExperimentalNativeApi
*/
- (TKKKotlinArray<NSString *> *)getStackTrace __attribute__((swift_name("getStackTrace()")));
- (void)printStackTrace __attribute__((swift_name("printStackTrace()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) TKKKotlinThrowable * _Nullable cause __attribute__((swift_name("cause")));
@property (readonly) NSString * _Nullable message __attribute__((swift_name("message")));
- (NSError *)asError __attribute__((swift_name("asError()")));
@end

__attribute__((swift_name("KotlinException")))
@interface TKKKotlinException : TKKKotlinThrowable
- (instancetype)init __attribute__((swift_name("init()"))) __attribute__((objc_designated_initializer));
+ (instancetype)new __attribute__((availability(swift, unavailable, message="use object initializers instead")));
- (instancetype)initWithMessage:(NSString * _Nullable)message __attribute__((swift_name("init(message:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithMessage:(NSString * _Nullable)message cause:(TKKKotlinThrowable * _Nullable)cause __attribute__((swift_name("init(message:cause:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithCause:(TKKKotlinThrowable * _Nullable)cause __attribute__((swift_name("init(cause:)"))) __attribute__((objc_designated_initializer));
@end

__attribute__((swift_name("SyncError")))
@interface TKKSyncError : TKKKotlinException
- (instancetype)init __attribute__((swift_name("init()"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
+ (instancetype)new __attribute__((unavailable));
- (instancetype)initWithMessage:(NSString * _Nullable)message __attribute__((swift_name("init(message:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
- (instancetype)initWithMessage:(NSString * _Nullable)message cause:(TKKKotlinThrowable * _Nullable)cause __attribute__((swift_name("init(message:cause:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
- (instancetype)initWithCause:(TKKKotlinThrowable * _Nullable)cause __attribute__((swift_name("init(cause:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("SyncError.NoNetworkConnection")))
@interface TKKSyncErrorNoNetworkConnection : TKKSyncError
- (instancetype)init __attribute__((swift_name("init()"))) __attribute__((objc_designated_initializer));
+ (instancetype)new __attribute__((availability(swift, unavailable, message="use object initializers instead")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("SyncError.NotStarted")))
@interface TKKSyncErrorNotStarted : TKKSyncError
- (instancetype)init __attribute__((swift_name("init()"))) __attribute__((objc_designated_initializer));
+ (instancetype)new __attribute__((availability(swift, unavailable, message="use object initializers instead")));
@end

__attribute__((swift_name("SyncState")))
@interface TKKSyncState : TKKBase
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("SyncState.NotSynced")))
@interface TKKSyncStateNotSynced : TKKSyncState
- (instancetype)initWithError:(TKKKotlinThrowable *)error __attribute__((swift_name("init(error:)"))) __attribute__((objc_designated_initializer));
@property (readonly) TKKKotlinThrowable *error __attribute__((swift_name("error")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("SyncState.Synced")))
@interface TKKSyncStateSynced : TKKSyncState
- (instancetype)init __attribute__((swift_name("init()"))) __attribute__((objc_designated_initializer));
+ (instancetype)new __attribute__((availability(swift, unavailable, message="use object initializers instead")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("SyncState.Syncing")))
@interface TKKSyncStateSyncing : TKKSyncState
- (instancetype)init __attribute__((swift_name("init()"))) __attribute__((objc_designated_initializer));
+ (instancetype)new __attribute__((availability(swift, unavailable, message="use object initializers instead")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Syncer")))
@interface TKKSyncer : TKKBase
- (instancetype)initWithTransactionManager:(TKKTransactionManager *)transactionManager balanceManager:(TKKBalanceManager *)balanceManager connectionManager:(TKKConnectionManager *)connectionManager __attribute__((swift_name("init(transactionManager:balanceManager:connectionManager:)"))) __attribute__((objc_designated_initializer));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)cancelSyncerReason:(TKKKotlinThrowable *)reason completionHandler:(void (^)(NSError * _Nullable))completionHandler __attribute__((swift_name("cancelSyncer(reason:completionHandler:)")));
- (void)runSyncer __attribute__((swift_name("runSyncer()")));
- (void)start __attribute__((swift_name("start()")));
- (void)stop __attribute__((swift_name("stop()")));
@property (readonly) id<TKKKotlinx_coroutines_coreStateFlow> balanceSyncStateFlow __attribute__((swift_name("balanceSyncStateFlow")));
@property (readonly) id<TKKKotlinx_coroutines_coreStateFlow> transactionsSyncStateFlow __attribute__((swift_name("transactionsSyncStateFlow")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("TonApiAdnl")))
@interface TKKTonApiAdnl : TKKBase
- (instancetype)initWithAddrStd:(TKKTon_kotlin_block_tlbAddrStd *)addrStd __attribute__((swift_name("init(addrStd:)"))) __attribute__((objc_designated_initializer));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)getBalanceWithCompletionHandler:(void (^)(NSString * _Nullable_result, NSError * _Nullable))completionHandler __attribute__((swift_name("getBalance(completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)getFullAccountStateOrNullWithCompletionHandler:(void (^)(TKKTon_kotlin_liteclientFullAccountState * _Nullable_result, NSError * _Nullable))completionHandler __attribute__((swift_name("getFullAccountStateOrNull(completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)getLatestTransactionHashWithCompletionHandler:(void (^)(NSString * _Nullable_result, NSError * _Nullable))completionHandler __attribute__((swift_name("getLatestTransactionHash(completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)getLiteClientWithCompletionHandler:(void (^)(TKKTon_kotlin_liteclientLiteClient * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("getLiteClient(completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)transactionsTransactionHash:(NSString * _Nullable)transactionHash lt:(TKKLong * _Nullable)lt limit:(int32_t)limit completionHandler:(void (^)(NSArray<TKKTonTransaction *> * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("transactions(transactionHash:lt:limit:completionHandler:)")));
@property (readonly) TKKTon_kotlin_block_tlbAddrStd *addrStd __attribute__((swift_name("addrStd")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("TonBalance")))
@interface TKKTonBalance : TKKBase
- (instancetype)initWithId:(NSString *)id value_:(NSString * _Nullable)value_ __attribute__((swift_name("init(id:value_:)"))) __attribute__((objc_designated_initializer));
- (TKKTonBalance *)doCopyId:(NSString *)id value_:(NSString * _Nullable)value_ __attribute__((swift_name("doCopy(id:value_:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSString *id __attribute__((swift_name("id")));
@property (readonly) NSString * _Nullable value_ __attribute__((swift_name("value_")));
@end

__attribute__((swift_name("RuntimeBaseTransacterImpl")))
@interface TKKRuntimeBaseTransacterImpl : TKKBase
- (instancetype)initWithDriver:(id<TKKRuntimeSqlDriver>)driver __attribute__((swift_name("init(driver:)"))) __attribute__((objc_designated_initializer));

/**
 * @note This method has protected visibility in Kotlin source and is intended only for use by subclasses.
*/
- (NSString *)createArgumentsCount:(int32_t)count __attribute__((swift_name("createArguments(count:)")));

/**
 * @note This method has protected visibility in Kotlin source and is intended only for use by subclasses.
*/
- (void)notifyQueriesIdentifier:(int32_t)identifier tableProvider:(void (^)(TKKKotlinUnit *(^)(NSString *)))tableProvider __attribute__((swift_name("notifyQueries(identifier:tableProvider:)")));

/**
 * @note This method has protected visibility in Kotlin source and is intended only for use by subclasses.
*/
- (id _Nullable)postTransactionCleanupTransaction:(TKKRuntimeTransacterTransaction *)transaction enclosing:(TKKRuntimeTransacterTransaction * _Nullable)enclosing thrownException:(TKKKotlinThrowable * _Nullable)thrownException returnValue:(id _Nullable)returnValue __attribute__((swift_name("postTransactionCleanup(transaction:enclosing:thrownException:returnValue:)")));

/**
 * @note This property has protected visibility in Kotlin source and is intended only for use by subclasses.
*/
@property (readonly) id<TKKRuntimeSqlDriver> driver __attribute__((swift_name("driver")));
@end

__attribute__((swift_name("RuntimeTransacterImpl")))
@interface TKKRuntimeTransacterImpl : TKKRuntimeBaseTransacterImpl <TKKRuntimeTransacter>
- (instancetype)initWithDriver:(id<TKKRuntimeSqlDriver>)driver __attribute__((swift_name("init(driver:)"))) __attribute__((objc_designated_initializer));
- (void)transactionNoEnclosing:(BOOL)noEnclosing body:(void (^)(id<TKKRuntimeTransactionWithoutReturn>))body __attribute__((swift_name("transaction(noEnclosing:body:)")));
- (id _Nullable)transactionWithResultNoEnclosing:(BOOL)noEnclosing bodyWithReturn:(id _Nullable (^)(id<TKKRuntimeTransactionWithReturn>))bodyWithReturn __attribute__((swift_name("transactionWithResult(noEnclosing:bodyWithReturn:)")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("TonBalanceQueries")))
@interface TKKTonBalanceQueries : TKKRuntimeTransacterImpl
- (instancetype)initWithDriver:(id<TKKRuntimeSqlDriver>)driver __attribute__((swift_name("init(driver:)"))) __attribute__((objc_designated_initializer));
- (TKKRuntimeQuery<TKKTonBalance *> *)get __attribute__((swift_name("get()")));
- (TKKRuntimeQuery<id> *)getMapper:(id (^)(NSString *, NSString * _Nullable))mapper __attribute__((swift_name("get(mapper:)")));
- (void)insertValue_:(NSString * _Nullable)value_ __attribute__((swift_name("insert(value_:)")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("TonKit")))
@interface TKKTonKit : TKKBase
- (instancetype)initWithTransactionManager:(TKKTransactionManager *)transactionManager balanceManager:(TKKBalanceManager *)balanceManager receiveAddress:(NSString *)receiveAddress syncer:(TKKSyncer *)syncer transactionSender:(TKKTransactionSender * _Nullable)transactionSender __attribute__((swift_name("init(transactionManager:balanceManager:receiveAddress:syncer:transactionSender:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTonKitCompanion *companion __attribute__((swift_name("companion")));

/**
 * @note This method converts all Kotlin exceptions to errors.
*/
- (void)estimateFeeWithCompletionHandler:(void (^)(NSString * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("estimateFee(completionHandler:)")));

/**
 * @note This method converts all Kotlin exceptions to errors.
*/
- (void)sendRecipient:(NSString *)recipient amount:(NSString *)amount memo:(NSString * _Nullable)memo completionHandler:(void (^)(NSError * _Nullable))completionHandler __attribute__((swift_name("send(recipient:amount:memo:completionHandler:)")));
- (void)start __attribute__((swift_name("start()")));
- (void)stop __attribute__((swift_name("stop()")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)transactionsFromTransactionHash:(NSString * _Nullable)fromTransactionHash type:(TKKTransactionType * _Nullable)type limit:(int64_t)limit completionHandler:(void (^)(NSArray<TKKTonTransaction *> * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("transactions(fromTransactionHash:type:limit:completionHandler:)")));
@property (readonly) NSString *balance __attribute__((swift_name("balance")));
@property (readonly) id<TKKKotlinx_coroutines_coreStateFlow> balanceFlow __attribute__((swift_name("balanceFlow")));
@property (readonly) TKKSyncState *balanceSyncState __attribute__((swift_name("balanceSyncState")));
@property (readonly) id<TKKKotlinx_coroutines_coreStateFlow> balanceSyncStateFlow __attribute__((swift_name("balanceSyncStateFlow")));
@property (readonly, getter=doNewTransactionsFlow) id<TKKKotlinx_coroutines_coreFlow> newTransactionsFlow __attribute__((swift_name("newTransactionsFlow")));
@property (readonly) NSString *receiveAddress __attribute__((swift_name("receiveAddress")));
@property (readonly) TKKSyncState *transactionsSyncState __attribute__((swift_name("transactionsSyncState")));
@property (readonly) id<TKKKotlinx_coroutines_coreStateFlow> transactionsSyncStateFlow __attribute__((swift_name("transactionsSyncStateFlow")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("TonKit.Companion")))
@interface TKKTonKitCompanion : TKKBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTonKitCompanion *shared __attribute__((swift_name("shared")));

/**
 * @note This method converts all Kotlin exceptions to errors.
*/
- (BOOL)validateAddress:(NSString *)address error:(NSError * _Nullable * _Nullable)error __attribute__((swift_name("validate(address:)")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("TonKitFactory")))
@interface TKKTonKitFactory : TKKBase
- (instancetype)initWithDriverFactory:(TKKDriverFactory *)driverFactory connectionManager:(TKKConnectionManager *)connectionManager __attribute__((swift_name("init(driverFactory:connectionManager:)"))) __attribute__((objc_designated_initializer));
- (TKKTonKit *)createSeed:(TKKKotlinByteArray *)seed walletId:(NSString *)walletId __attribute__((swift_name("create(seed:walletId:)")));
- (TKKTonKit *)createWords:(NSArray<NSString *> *)words passphrase:(NSString *)passphrase walletId:(NSString *)walletId __attribute__((swift_name("create(words:passphrase:walletId:)")));
- (TKKTonKit *)createWatchAddress:(NSString *)address walletId:(NSString *)walletId __attribute__((swift_name("createWatch(address:walletId:)")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("TonTransaction")))
@interface TKKTonTransaction : TKKBase
- (instancetype)initWithHash:(NSString *)hash lt:(int64_t)lt timestamp:(int64_t)timestamp amount:(NSString * _Nullable)amount fee:(NSString * _Nullable)fee type:(TKKTransactionType *)type transfersJson:(NSString *)transfersJson memo:(NSString * _Nullable)memo __attribute__((swift_name("init(hash:lt:timestamp:amount:fee:type:transfersJson:memo:)"))) __attribute__((objc_designated_initializer));
- (TKKTonTransaction *)doCopyHash:(NSString *)hash lt:(int64_t)lt timestamp:(int64_t)timestamp amount:(NSString * _Nullable)amount fee:(NSString * _Nullable)fee type:(TKKTransactionType *)type transfersJson:(NSString *)transfersJson memo:(NSString * _Nullable)memo __attribute__((swift_name("doCopy(hash:lt:timestamp:amount:fee:type:transfersJson:memo:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSString * _Nullable amount __attribute__((swift_name("amount")));
@property (readonly) NSString * _Nullable fee __attribute__((swift_name("fee")));
@property (readonly, getter=hash_) NSString *hash __attribute__((swift_name("hash")));
@property (readonly) int64_t lt __attribute__((swift_name("lt")));
@property (readonly) NSString * _Nullable memo __attribute__((swift_name("memo")));
@property (readonly) int64_t timestamp __attribute__((swift_name("timestamp")));
@property (readonly) NSString *transfersJson __attribute__((swift_name("transfersJson")));
@property (readonly) TKKTransactionType *type __attribute__((swift_name("type")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("TonTransaction.Adapter")))
@interface TKKTonTransactionAdapter : TKKBase
- (instancetype)initWithTypeAdapter:(id<TKKRuntimeColumnAdapter>)typeAdapter __attribute__((swift_name("init(typeAdapter:)"))) __attribute__((objc_designated_initializer));
@property (readonly) id<TKKRuntimeColumnAdapter> typeAdapter __attribute__((swift_name("typeAdapter")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("TonTransactionQueries")))
@interface TKKTonTransactionQueries : TKKRuntimeTransacterImpl
- (instancetype)initWithDriver:(id<TKKRuntimeSqlDriver>)driver TonTransactionAdapter:(TKKTonTransactionAdapter *)TonTransactionAdapter __attribute__((swift_name("init(driver:TonTransactionAdapter:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithDriver:(id<TKKRuntimeSqlDriver>)driver __attribute__((swift_name("init(driver:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
- (TKKRuntimeQuery<TKKTonTransaction *> *)getAllLimit:(int64_t)limit __attribute__((swift_name("getAll(limit:)")));
- (TKKRuntimeQuery<id> *)getAllLimit:(int64_t)limit mapper:(id (^)(NSString *, TKKLong *, TKKLong *, NSString * _Nullable, NSString * _Nullable, TKKTransactionType *, NSString *, NSString * _Nullable))mapper __attribute__((swift_name("getAll(limit:mapper:)")));
- (TKKRuntimeQuery<TKKTonTransaction *> *)getAllByTypeType:(TKKTransactionType *)type limit:(int64_t)limit __attribute__((swift_name("getAllByType(type:limit:)")));
- (TKKRuntimeQuery<id> *)getAllByTypeType:(TKKTransactionType *)type limit:(int64_t)limit mapper:(id (^)(NSString *, TKKLong *, TKKLong *, NSString * _Nullable, NSString * _Nullable, TKKTransactionType *, NSString *, NSString * _Nullable))mapper __attribute__((swift_name("getAllByType(type:limit:mapper:)")));
- (TKKRuntimeQuery<TKKTonTransaction *> *)getByHashHash:(NSString *)hash __attribute__((swift_name("getByHash(hash:)")));
- (TKKRuntimeQuery<id> *)getByHashHash:(NSString *)hash mapper:(id (^)(NSString *, TKKLong *, TKKLong *, NSString * _Nullable, NSString * _Nullable, TKKTransactionType *, NSString *, NSString * _Nullable))mapper __attribute__((swift_name("getByHash(hash:mapper:)")));
- (TKKRuntimeQuery<TKKTonTransaction *> *)getEarlierThanTimestamp:(int64_t)timestamp lt:(int64_t)lt limit:(int64_t)limit __attribute__((swift_name("getEarlierThan(timestamp:lt:limit:)")));
- (TKKRuntimeQuery<id> *)getEarlierThanTimestamp:(int64_t)timestamp lt:(int64_t)lt limit:(int64_t)limit mapper:(id (^)(NSString *, TKKLong *, TKKLong *, NSString * _Nullable, NSString * _Nullable, TKKTransactionType *, NSString *, NSString * _Nullable))mapper __attribute__((swift_name("getEarlierThan(timestamp:lt:limit:mapper:)")));
- (TKKRuntimeQuery<TKKTonTransaction *> *)getEarlierThanByTypeType:(TKKTransactionType *)type timestamp:(int64_t)timestamp lt:(int64_t)lt limit:(int64_t)limit __attribute__((swift_name("getEarlierThanByType(type:timestamp:lt:limit:)")));
- (TKKRuntimeQuery<id> *)getEarlierThanByTypeType:(TKKTransactionType *)type timestamp:(int64_t)timestamp lt:(int64_t)lt limit:(int64_t)limit mapper:(id (^)(NSString *, TKKLong *, TKKLong *, NSString * _Nullable, NSString * _Nullable, TKKTransactionType *, NSString *, NSString * _Nullable))mapper __attribute__((swift_name("getEarlierThanByType(type:timestamp:lt:limit:mapper:)")));
- (TKKRuntimeQuery<TKKTonTransaction *> *)getEarliest __attribute__((swift_name("getEarliest()")));
- (TKKRuntimeQuery<id> *)getEarliestMapper:(id (^)(NSString *, TKKLong *, TKKLong *, NSString * _Nullable, NSString * _Nullable, TKKTransactionType *, NSString *, NSString * _Nullable))mapper __attribute__((swift_name("getEarliest(mapper:)")));
- (TKKRuntimeQuery<TKKTonTransaction *> *)getLatest __attribute__((swift_name("getLatest()")));
- (TKKRuntimeQuery<id> *)getLatestMapper:(id (^)(NSString *, TKKLong *, TKKLong *, NSString * _Nullable, NSString * _Nullable, TKKTransactionType *, NSString *, NSString * _Nullable))mapper __attribute__((swift_name("getLatest(mapper:)")));
- (void)insertHash:(NSString *)hash lt:(int64_t)lt timestamp:(int64_t)timestamp amount:(NSString * _Nullable)amount fee:(NSString * _Nullable)fee type:(TKKTransactionType *)type transfersJson:(NSString *)transfersJson memo:(NSString * _Nullable)memo __attribute__((swift_name("insert(hash:lt:timestamp:amount:fee:type:transfersJson:memo:)")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("TransactionManager")))
@interface TKKTransactionManager : TKKBase
- (instancetype)initWithAdnl:(TKKTonApiAdnl *)adnl storage:(TKKTransactionStorage *)storage __attribute__((swift_name("init(adnl:storage:)"))) __attribute__((objc_designated_initializer));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)syncWithCompletionHandler:(void (^)(id<TKKKotlinx_coroutines_coreFlow> _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("sync(completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)transactionsFromTransactionHash:(NSString * _Nullable)fromTransactionHash type:(TKKTransactionType * _Nullable)type limit:(int64_t)limit completionHandler:(void (^)(NSArray<TKKTonTransaction *> * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("transactions(fromTransactionHash:type:limit:completionHandler:)")));
@property (readonly, getter=doNewTransactionsFlow) id<TKKKotlinx_coroutines_coreFlow> newTransactionsFlow __attribute__((swift_name("newTransactionsFlow")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("TransactionSender")))
@interface TKKTransactionSender : TKKBase
- (instancetype)initWithAdnl:(TKKTonApiAdnl *)adnl privateKey:(TKKTon_kotlin_tonapi_tlPrivateKeyEd25519 *)privateKey __attribute__((swift_name("init(adnl:privateKey:)"))) __attribute__((objc_designated_initializer));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)estimateFeeWithCompletionHandler:(void (^)(NSString * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("estimateFee(completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)sendRecipient:(NSString *)recipient amount:(NSString *)amount memo:(NSString * _Nullable)memo completionHandler:(void (^)(NSError * _Nullable))completionHandler __attribute__((swift_name("send(recipient:amount:memo:completionHandler:)")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("TransactionStorage")))
@interface TKKTransactionStorage : TKKBase
- (instancetype)initWithTransactionQuery:(TKKTonTransactionQueries *)transactionQuery __attribute__((swift_name("init(transactionQuery:)"))) __attribute__((objc_designated_initializer));
- (void)addTransactions:(NSArray<TKKTonTransaction *> *)transactions __attribute__((swift_name("add(transactions:)")));
- (TKKTonTransaction * _Nullable)getEarliestTransaction __attribute__((swift_name("getEarliestTransaction()")));
- (TKKTonTransaction * _Nullable)getLatestTransaction __attribute__((swift_name("getLatestTransaction()")));
- (NSArray<TKKTonTransaction *> *)getTransactionsFromTransactionHash:(NSString * _Nullable)fromTransactionHash type:(TKKTransactionType * _Nullable)type limit:(int64_t)limit __attribute__((swift_name("getTransactions(fromTransactionHash:type:limit:)")));
@end

__attribute__((swift_name("KotlinComparable")))
@protocol TKKKotlinComparable
@required
- (int32_t)compareToOther:(id _Nullable)other __attribute__((swift_name("compareTo(other:)")));
@end

__attribute__((swift_name("KotlinEnum")))
@interface TKKKotlinEnum<E> : TKKBase <TKKKotlinComparable>
- (instancetype)initWithName:(NSString *)name ordinal:(int32_t)ordinal __attribute__((swift_name("init(name:ordinal:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKKotlinEnumCompanion *companion __attribute__((swift_name("companion")));
- (int32_t)compareToOther:(E)other __attribute__((swift_name("compareTo(other:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSString *name __attribute__((swift_name("name")));
@property (readonly) int32_t ordinal __attribute__((swift_name("ordinal")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("TransactionType")))
@interface TKKTransactionType : TKKKotlinEnum<TKKTransactionType *>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (instancetype)initWithName:(NSString *)name ordinal:(int32_t)ordinal __attribute__((swift_name("init(name:ordinal:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
@property (class, readonly) TKKTransactionType *incoming __attribute__((swift_name("incoming")));
@property (class, readonly) TKKTransactionType *outgoing __attribute__((swift_name("outgoing")));
@property (class, readonly) TKKTransactionType *unknown __attribute__((swift_name("unknown")));
+ (TKKKotlinArray<TKKTransactionType *> *)values __attribute__((swift_name("values()")));
@property (class, readonly) NSArray<TKKTransactionType *> *entries __attribute__((swift_name("entries")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Transfer")))
@interface TKKTransfer : TKKBase
- (instancetype)initWithSrc:(NSString *)src dest:(NSString *)dest amount:(NSString *)amount __attribute__((swift_name("init(src:dest:amount:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTransferCompanion *companion __attribute__((swift_name("companion")));
- (TKKTransfer *)doCopySrc:(NSString *)src dest:(NSString *)dest amount:(NSString *)amount __attribute__((swift_name("doCopy(src:dest:amount:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSString *amount __attribute__((swift_name("amount")));
@property (readonly) NSString *dest __attribute__((swift_name("dest")));
@property (readonly) NSString *src __attribute__((swift_name("src")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Transfer.Companion")))
@interface TKKTransferCompanion : TKKBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTransferCompanion *shared __attribute__((swift_name("shared")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

@interface TKKTonTransaction (Extensions)
@property (readonly) NSArray<TKKTransfer *> *transfers __attribute__((swift_name("transfers")));
@end

@interface TKKTonKit (Extensions)
- (id<TKKCancellable>)balancePublisherOnEach:(void (^)(NSString *))onEach onCompletion:(void (^)(TKKKotlinThrowable * _Nullable))onCompletion __attribute__((swift_name("balancePublisher(onEach:onCompletion:)")));
- (id<TKKCancellable>)balanceSyncStatePublisherOnEach:(void (^)(TKKSyncState *))onEach onCompletion:(void (^)(TKKKotlinThrowable * _Nullable))onCompletion __attribute__((swift_name("balanceSyncStatePublisher(onEach:onCompletion:)")));
- (id<TKKCancellable>)doNewTransactionsPublisherOnEach:(void (^)(NSArray<TKKTonTransaction *> *))onEach onCompletion:(void (^)(TKKKotlinThrowable * _Nullable))onCompletion __attribute__((swift_name("doNewTransactionsPublisher(onEach:onCompletion:)")));
- (id<TKKCancellable>)transactionsSyncStatePublisherOnEach:(void (^)(TKKSyncState *))onEach onCompletion:(void (^)(TKKKotlinThrowable * _Nullable))onCompletion __attribute__((swift_name("transactionsSyncStatePublisher(onEach:onCompletion:)")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("KotlinByteArray")))
@interface TKKKotlinByteArray : TKKBase
+ (instancetype)arrayWithSize:(int32_t)size __attribute__((swift_name("init(size:)")));
+ (instancetype)arrayWithSize:(int32_t)size init:(TKKByte *(^)(TKKInt *))init __attribute__((swift_name("init(size:init:)")));
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (int8_t)getIndex:(int32_t)index __attribute__((swift_name("get(index:)")));
- (TKKKotlinByteIterator *)iterator __attribute__((swift_name("iterator()")));
- (void)setIndex:(int32_t)index value:(int8_t)value __attribute__((swift_name("set(index:value:)")));
@property (readonly) int32_t size __attribute__((swift_name("size")));
@end

@interface TKKKotlinByteArray (Extensions)
- (NSData *)toData __attribute__((swift_name("toData()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("TickerFlowKt")))
@interface TKKTickerFlowKt : TKKBase
+ (id<TKKKotlinx_coroutines_coreFlow>)tickerFlowPeriod:(int64_t)period initialDelay:(int64_t)initialDelay __attribute__((swift_name("tickerFlow(period:initialDelay:)")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("FlowKt")))
@interface TKKFlowKt : TKKBase
+ (id<TKKCancellable>)collect:(id<TKKKotlinx_coroutines_coreFlow>)receiver onEach:(void (^)(id _Nullable))onEach onCompletion:(void (^)(TKKKotlinThrowable * _Nullable))onCompletion __attribute__((swift_name("collect(_:onEach:onCompletion:)")));
@end

__attribute__((swift_name("KotlinRuntimeException")))
@interface TKKKotlinRuntimeException : TKKKotlinException
- (instancetype)init __attribute__((swift_name("init()"))) __attribute__((objc_designated_initializer));
+ (instancetype)new __attribute__((availability(swift, unavailable, message="use object initializers instead")));
- (instancetype)initWithMessage:(NSString * _Nullable)message __attribute__((swift_name("init(message:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithMessage:(NSString * _Nullable)message cause:(TKKKotlinThrowable * _Nullable)cause __attribute__((swift_name("init(message:cause:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithCause:(TKKKotlinThrowable * _Nullable)cause __attribute__((swift_name("init(cause:)"))) __attribute__((objc_designated_initializer));
@end

__attribute__((swift_name("KotlinIllegalStateException")))
@interface TKKKotlinIllegalStateException : TKKKotlinRuntimeException
- (instancetype)init __attribute__((swift_name("init()"))) __attribute__((objc_designated_initializer));
+ (instancetype)new __attribute__((availability(swift, unavailable, message="use object initializers instead")));
- (instancetype)initWithMessage:(NSString * _Nullable)message __attribute__((swift_name("init(message:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithMessage:(NSString * _Nullable)message cause:(TKKKotlinThrowable * _Nullable)cause __attribute__((swift_name("init(message:cause:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithCause:(TKKKotlinThrowable * _Nullable)cause __attribute__((swift_name("init(cause:)"))) __attribute__((objc_designated_initializer));
@end


/**
 * @note annotations
 *   kotlin.SinceKotlin(version="1.4")
*/
__attribute__((swift_name("KotlinCancellationException")))
@interface TKKKotlinCancellationException : TKKKotlinIllegalStateException
- (instancetype)init __attribute__((swift_name("init()"))) __attribute__((objc_designated_initializer));
+ (instancetype)new __attribute__((availability(swift, unavailable, message="use object initializers instead")));
- (instancetype)initWithMessage:(NSString * _Nullable)message __attribute__((swift_name("init(message:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithMessage:(NSString * _Nullable)message cause:(TKKKotlinThrowable * _Nullable)cause __attribute__((swift_name("init(message:cause:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithCause:(TKKKotlinThrowable * _Nullable)cause __attribute__((swift_name("init(cause:)"))) __attribute__((objc_designated_initializer));
@end

__attribute__((swift_name("Kotlinx_coroutines_coreFlow")))
@protocol TKKKotlinx_coroutines_coreFlow
@required

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)collectCollector:(id<TKKKotlinx_coroutines_coreFlowCollector>)collector completionHandler:(void (^)(NSError * _Nullable))completionHandler __attribute__((swift_name("collect(collector:completionHandler:)")));
@end

__attribute__((swift_name("Kotlinx_coroutines_coreSharedFlow")))
@protocol TKKKotlinx_coroutines_coreSharedFlow <TKKKotlinx_coroutines_coreFlow>
@required
@property (readonly) NSArray<id> *replayCache __attribute__((swift_name("replayCache")));
@end

__attribute__((swift_name("Kotlinx_coroutines_coreStateFlow")))
@protocol TKKKotlinx_coroutines_coreStateFlow <TKKKotlinx_coroutines_coreSharedFlow>
@required
@property (readonly) id _Nullable value __attribute__((swift_name("value")));
@end

__attribute__((swift_name("RuntimeCloseable")))
@protocol TKKRuntimeCloseable
@required
- (void)close __attribute__((swift_name("close()")));
@end

__attribute__((swift_name("RuntimeSqlDriver")))
@protocol TKKRuntimeSqlDriver <TKKRuntimeCloseable>
@required
- (void)addListenerQueryKeys:(TKKKotlinArray<NSString *> *)queryKeys listener:(id<TKKRuntimeQueryListener>)listener __attribute__((swift_name("addListener(queryKeys:listener:)")));
- (TKKRuntimeTransacterTransaction * _Nullable)currentTransaction __attribute__((swift_name("currentTransaction()")));
- (id<TKKRuntimeQueryResult>)executeIdentifier:(TKKInt * _Nullable)identifier sql:(NSString *)sql parameters:(int32_t)parameters binders:(void (^ _Nullable)(id<TKKRuntimeSqlPreparedStatement>))binders __attribute__((swift_name("execute(identifier:sql:parameters:binders:)")));
- (id<TKKRuntimeQueryResult>)executeQueryIdentifier:(TKKInt * _Nullable)identifier sql:(NSString *)sql mapper:(id<TKKRuntimeQueryResult> (^)(id<TKKRuntimeSqlCursor>))mapper parameters:(int32_t)parameters binders:(void (^ _Nullable)(id<TKKRuntimeSqlPreparedStatement>))binders __attribute__((swift_name("executeQuery(identifier:sql:mapper:parameters:binders:)")));
- (id<TKKRuntimeQueryResult>)doNewTransaction __attribute__((swift_name("doNewTransaction()")));
- (void)notifyListenersQueryKeys:(TKKKotlinArray<NSString *> *)queryKeys __attribute__((swift_name("notifyListeners(queryKeys:)")));
- (void)removeListenerQueryKeys:(TKKKotlinArray<NSString *> *)queryKeys listener:(id<TKKRuntimeQueryListener>)listener __attribute__((swift_name("removeListener(queryKeys:listener:)")));
@end

__attribute__((swift_name("RuntimeTransactionCallbacks")))
@protocol TKKRuntimeTransactionCallbacks
@required
- (void)afterCommitFunction:(void (^)(void))function __attribute__((swift_name("afterCommit(function:)")));
- (void)afterRollbackFunction:(void (^)(void))function __attribute__((swift_name("afterRollback(function:)")));
@end

__attribute__((swift_name("RuntimeTransactionWithoutReturn")))
@protocol TKKRuntimeTransactionWithoutReturn <TKKRuntimeTransactionCallbacks>
@required
- (void)rollback __attribute__((swift_name("rollback()")));
- (void)transactionBody:(void (^)(id<TKKRuntimeTransactionWithoutReturn>))body __attribute__((swift_name("transaction(body:)")));
@end

__attribute__((swift_name("RuntimeTransactionWithReturn")))
@protocol TKKRuntimeTransactionWithReturn <TKKRuntimeTransactionCallbacks>
@required
- (void)rollbackReturnValue:(id _Nullable)returnValue __attribute__((swift_name("rollback(returnValue:)")));
- (id _Nullable)transactionBody_:(id _Nullable (^)(id<TKKRuntimeTransactionWithReturn>))body __attribute__((swift_name("transaction(body_:)")));
@end

__attribute__((swift_name("RuntimeSqlSchema")))
@protocol TKKRuntimeSqlSchema
@required
- (id<TKKRuntimeQueryResult>)createDriver:(id<TKKRuntimeSqlDriver>)driver __attribute__((swift_name("create(driver:)")));
- (id<TKKRuntimeQueryResult>)migrateDriver:(id<TKKRuntimeSqlDriver>)driver oldVersion:(int64_t)oldVersion newVersion:(int64_t)newVersion callbacks:(TKKKotlinArray<TKKRuntimeAfterVersion *> *)callbacks __attribute__((swift_name("migrate(driver:oldVersion:newVersion:callbacks:)")));
@property (readonly) int64_t version __attribute__((swift_name("version")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("KotlinArray")))
@interface TKKKotlinArray<T> : TKKBase
+ (instancetype)arrayWithSize:(int32_t)size init:(T _Nullable (^)(TKKInt *))init __attribute__((swift_name("init(size:init:)")));
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (T _Nullable)getIndex:(int32_t)index __attribute__((swift_name("get(index:)")));
- (id<TKKKotlinIterator>)iterator __attribute__((swift_name("iterator()")));
- (void)setIndex:(int32_t)index value:(T _Nullable)value __attribute__((swift_name("set(index:value:)")));
@property (readonly) int32_t size __attribute__((swift_name("size")));
@end

__attribute__((swift_name("Ton_kotlin_tlbTlbObject")))
@protocol TKKTon_kotlin_tlbTlbObject
@required
- (TKKTon_kotlin_tlbTlbPrettyPrinter *)printPrinter:(TKKTon_kotlin_tlbTlbPrettyPrinter *)printer __attribute__((swift_name("print(printer:)")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((swift_name("Ton_kotlin_block_tlbMsgAddress")))
@protocol TKKTon_kotlin_block_tlbMsgAddress <TKKTon_kotlin_tlbTlbObject>
@required
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((swift_name("Ton_kotlin_block_tlbMsgAddressInt")))
@protocol TKKTon_kotlin_block_tlbMsgAddressInt <TKKTon_kotlin_block_tlbMsgAddress>
@required
@property (readonly) id<TKKTon_kotlin_bitstringBitString> address __attribute__((swift_name("address")));
@property (readonly) int32_t workchainId __attribute__((swift_name("workchainId")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
 *   kotlinx.serialization.SerialName(value="addr_std")
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_block_tlbAddrStd")))
@interface TKKTon_kotlin_block_tlbAddrStd : TKKBase <TKKTon_kotlin_block_tlbMsgAddressInt>
- (instancetype)init __attribute__((swift_name("init()"))) __attribute__((objc_designated_initializer));
+ (instancetype)new __attribute__((availability(swift, unavailable, message="use object initializers instead")));
- (instancetype)initWithWorkchainId:(int32_t)workchainId address:(id<TKKTon_kotlin_bitstringBitString>)address __attribute__((swift_name("init(workchainId:address:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithWorkchainId:(int32_t)workchainId address_:(TKKKotlinByteArray *)address __attribute__((swift_name("init(workchainId:address_:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithAnycast:(TKKTon_kotlin_block_tlbAnycast * _Nullable)anycast workchainId:(int32_t)workchainId address:(TKKKotlinByteArray *)address __attribute__((swift_name("init(anycast:workchainId:address:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithAnycast:(TKKTon_kotlin_block_tlbAnycast * _Nullable)anycast workchainId:(int32_t)workchainId address_:(id<TKKTon_kotlin_bitstringBitString>)address __attribute__((swift_name("init(anycast:workchainId:address_:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithAnycast:(id<TKKTon_kotlin_block_tlbMaybe>)anycast workchainId:(int32_t)workchainId address__:(id<TKKTon_kotlin_bitstringBitString>)address __attribute__((swift_name("init(anycast:workchainId:address__:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_block_tlbAddrStdCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_block_tlbAddrStd *)doCopyAnycast:(id<TKKTon_kotlin_block_tlbMaybe>)anycast workchainId:(int32_t)workchainId address:(id<TKKTon_kotlin_bitstringBitString>)address __attribute__((swift_name("doCopy(anycast:workchainId:address:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (TKKTon_kotlin_tlbTlbPrettyPrinter *)printPrinter:(TKKTon_kotlin_tlbTlbPrettyPrinter *)printer __attribute__((swift_name("print(printer:)")));
- (NSString *)description __attribute__((swift_name("description()")));
- (NSString *)toStringUserFriendly:(BOOL)userFriendly urlSafe:(BOOL)urlSafe testOnly:(BOOL)testOnly bounceable:(BOOL)bounceable __attribute__((swift_name("toString(userFriendly:urlSafe:testOnly:bounceable:)")));
@property (readonly) id<TKKTon_kotlin_bitstringBitString> address __attribute__((swift_name("address")));
@property (readonly) id<TKKTon_kotlin_block_tlbMaybe> anycast __attribute__((swift_name("anycast")));
@property (readonly) int32_t workchainId __attribute__((swift_name("workchainId")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteclientFullAccountState")))
@interface TKKTon_kotlin_liteclientFullAccountState : TKKBase
- (instancetype)initWithBlockId:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)blockId address:(id<TKKTon_kotlin_block_tlbMsgAddressInt>)address lastTransactionId:(TKKTon_kotlin_liteclientTransactionId * _Nullable)lastTransactionId account:(id<TKKTon_kotlin_tlbCellRef>)account __attribute__((swift_name("init(blockId:address:lastTransactionId:account:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteclientFullAccountStateCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteclientFullAccountState *)doCopyBlockId:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)blockId address:(id<TKKTon_kotlin_block_tlbMsgAddressInt>)address lastTransactionId:(TKKTon_kotlin_liteclientTransactionId * _Nullable)lastTransactionId account:(id<TKKTon_kotlin_tlbCellRef>)account __attribute__((swift_name("doCopy(blockId:address:lastTransactionId:account:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) id<TKKTon_kotlin_tlbCellRef> account __attribute__((swift_name("account")));
@property (readonly) id<TKKTon_kotlin_block_tlbMsgAddressInt> address __attribute__((swift_name("address")));

/**
 * @note annotations
 *   kotlinx.serialization.SerialName(value="block_id")
*/
@property (readonly) TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *blockId __attribute__((swift_name("blockId")));

/**
 * @note annotations
 *   kotlinx.serialization.SerialName(value="last_transaction_id")
*/
@property (readonly) TKKTon_kotlin_liteclientTransactionId * _Nullable lastTransactionId __attribute__((swift_name("lastTransactionId")));
@end

__attribute__((swift_name("Ktor_ioCloseable")))
@protocol TKKKtor_ioCloseable
@required
- (void)close __attribute__((swift_name("close()")));
@end

__attribute__((swift_name("Kotlinx_coroutines_coreCoroutineScope")))
@protocol TKKKotlinx_coroutines_coreCoroutineScope
@required
@property (readonly) id<TKKKotlinCoroutineContext> coroutineContext __attribute__((swift_name("coroutineContext")));
@end

__attribute__((swift_name("Ton_kotlin_liteclientLiteClientApi")))
@protocol TKKTon_kotlin_liteclientLiteClientApi
@required

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)getAccountStateAccountAddress:(id<TKKTon_kotlin_block_tlbMsgAddressInt>)accountAddress completionHandler:(void (^)(TKKTon_kotlin_liteclientFullAccountState * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("getAccountState(accountAddress:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)getAccountStateAccountAddress:(id<TKKTon_kotlin_block_tlbMsgAddressInt>)accountAddress blockId:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)blockId completionHandler:(void (^)(TKKTon_kotlin_liteclientFullAccountState * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("getAccountState(accountAddress:blockId:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)getTransactionsAccountAddress:(id<TKKTon_kotlin_block_tlbMsgAddressInt>)accountAddress fromTransactionId:(TKKTon_kotlin_liteclientTransactionId *)fromTransactionId count:(int32_t)count completionHandler:(void (^)(NSArray<TKKTon_kotlin_liteclientTransactionInfo *> * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("getTransactions(accountAddress:fromTransactionId:count:completionHandler:)")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteclientLiteClient")))
@interface TKKTon_kotlin_liteclientLiteClient : TKKBase <TKKKtor_ioCloseable, TKKKotlinx_coroutines_coreCoroutineScope, TKKTon_kotlin_liteclientLiteClientApi>
- (instancetype)initWithCoroutineContext:(id<TKKKotlinCoroutineContext>)coroutineContext liteServers:(id)liteServers __attribute__((swift_name("init(coroutineContext:liteServers:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithCoroutineContext:(id<TKKKotlinCoroutineContext>)coroutineContext liteServer:(TKKKotlinArray<TKKTon_kotlin_tonapi_tlLiteServerDesc *> *)liteServer __attribute__((swift_name("init(coroutineContext:liteServer:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithCoroutineContext:(id<TKKKotlinCoroutineContext>)coroutineContext liteClientConfigGlobal:(TKKTon_kotlin_tonapi_tlLiteClientConfigGlobal *)liteClientConfigGlobal __attribute__((swift_name("init(coroutineContext:liteClientConfigGlobal:)"))) __attribute__((objc_designated_initializer));
- (void)close __attribute__((swift_name("close()")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)getAccountStateAccountAddress:(id<TKKTon_kotlin_block_tlbMsgAddressInt>)accountAddress completionHandler:(void (^)(TKKTon_kotlin_liteclientFullAccountState * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("getAccountState(accountAddress:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)getAccountStateAccountAddress:(id<TKKTon_kotlin_block_tlbMsgAddressInt>)accountAddress blockId:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)blockId completionHandler:(void (^)(TKKTon_kotlin_liteclientFullAccountState * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("getAccountState(accountAddress:blockId:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)getBlockBlockId:(id<TKKTon_kotlin_tonapi_tlTonNodeBlockId>)blockId completionHandler:(void (^)(TKKTon_kotlin_block_tlbBlock * _Nullable_result, NSError * _Nullable))completionHandler __attribute__((swift_name("getBlock(blockId:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)getBlockBlockId:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)blockId completionHandler_:(void (^)(TKKTon_kotlin_block_tlbBlock * _Nullable_result, NSError * _Nullable))completionHandler __attribute__((swift_name("getBlock(blockId:completionHandler_:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)getBlockBlockId:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)blockId timeout:(int64_t)timeout completionHandler:(void (^)(TKKTon_kotlin_block_tlbBlock * _Nullable_result, NSError * _Nullable))completionHandler __attribute__((swift_name("getBlock(blockId:timeout:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)getLastBlockIdMode:(int32_t)mode completionHandler:(void (^)(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("getLastBlockId(mode:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)getServerTimeWithCompletionHandler:(void (^)(TKKKotlinx_datetimeInstant * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("getServerTime(completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)getServerVersionWithCompletionHandler:(void (^)(TKKTon_kotlin_liteapi_tlLiteServerVersion * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("getServerVersion(completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)getTransactionsAccountAddress:(id<TKKTon_kotlin_block_tlbMsgAddressInt>)accountAddress fromTransactionId:(TKKTon_kotlin_liteclientTransactionId *)fromTransactionId count:(int32_t)count completionHandler:(void (^)(NSArray<TKKTon_kotlin_liteclientTransactionInfo *> * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("getTransactions(accountAddress:fromTransactionId:count:completionHandler:)")));
- (int64_t)latency __attribute__((swift_name("latency()")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)lookupBlockBlockId:(id<TKKTon_kotlin_tonapi_tlTonNodeBlockId>)blockId lt:(TKKLong * _Nullable)lt time:(TKKKotlinx_datetimeInstant * _Nullable)time completionHandler:(void (^)(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt * _Nullable_result, NSError * _Nullable))completionHandler __attribute__((swift_name("lookupBlock(blockId:lt:time:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)lookupBlockBlockId:(id<TKKTon_kotlin_tonapi_tlTonNodeBlockId>)blockId timeout:(int64_t)timeout completionHandler:(void (^)(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt * _Nullable_result, NSError * _Nullable))completionHandler __attribute__((swift_name("lookupBlock(blockId:timeout:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)runSmcMethodAddress:(TKKTon_kotlin_liteapi_tlLiteServerAccountId *)address method:(int64_t)method params:(TKKKotlinArray<id<TKKTon_kotlin_block_tlbVmStackValue>> *)params completionHandler:(void (^)(id<TKKTon_kotlin_block_tlbVmStack> _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("runSmcMethod(address:method:params:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)runSmcMethodAddress:(TKKTon_kotlin_liteapi_tlLiteServerAccountId *)address method:(int64_t)method params:(id)params completionHandler_:(void (^)(id<TKKTon_kotlin_block_tlbVmStack> _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("runSmcMethod(address:method:params:completionHandler_:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)runSmcMethodAddress:(TKKTon_kotlin_liteapi_tlLiteServerAccountId *)address methodName:(NSString *)methodName params:(TKKKotlinArray<id<TKKTon_kotlin_block_tlbVmStackValue>> *)params completionHandler:(void (^)(id<TKKTon_kotlin_block_tlbVmStack> _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("runSmcMethod(address:methodName:params:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)runSmcMethodAddress:(TKKTon_kotlin_liteapi_tlLiteServerAccountId *)address methodName:(NSString *)methodName params:(id)params completionHandler_:(void (^)(id<TKKTon_kotlin_block_tlbVmStack> _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("runSmcMethod(address:methodName:params:completionHandler_:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)runSmcMethodAddress:(TKKTon_kotlin_liteapi_tlLiteServerAccountId *)address blockId:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)blockId method:(int64_t)method params:(TKKKotlinArray<id<TKKTon_kotlin_block_tlbVmStackValue>> *)params completionHandler:(void (^)(id<TKKTon_kotlin_block_tlbVmStack> _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("runSmcMethod(address:blockId:method:params:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)runSmcMethodAddress:(TKKTon_kotlin_liteapi_tlLiteServerAccountId *)address blockId:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)blockId method:(int64_t)method params:(id)params completionHandler_:(void (^)(id<TKKTon_kotlin_block_tlbVmStack> _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("runSmcMethod(address:blockId:method:params:completionHandler_:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)runSmcMethodAddress:(TKKTon_kotlin_liteapi_tlLiteServerAccountId *)address blockId:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)blockId methodName:(NSString *)methodName params:(TKKKotlinArray<id<TKKTon_kotlin_block_tlbVmStackValue>> *)params completionHandler:(void (^)(id<TKKTon_kotlin_block_tlbVmStack> _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("runSmcMethod(address:blockId:methodName:params:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)runSmcMethodAddress:(TKKTon_kotlin_liteapi_tlLiteServerAccountId *)address blockId:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)blockId methodName:(NSString *)methodName params:(id)params completionHandler_:(void (^)(id<TKKTon_kotlin_block_tlbVmStack> _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("runSmcMethod(address:blockId:methodName:params:completionHandler_:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)sendMessageBody:(TKKTon_kotlin_block_tlbMessage<id<TKKTon_kotlin_tvmCell>> *)body completionHandler:(void (^)(TKKTon_kotlin_liteapi_tlLiteServerSendMsgStatus * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("sendMessage(body:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)sendMessageBoc:(id<TKKTon_kotlin_tvmBagOfCells>)boc completionHandler:(void (^)(TKKTon_kotlin_liteapi_tlLiteServerSendMsgStatus * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("sendMessage(boc:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)sendMessageCell:(id<TKKTon_kotlin_tvmCell>)cell completionHandler:(void (^)(TKKTon_kotlin_liteapi_tlLiteServerSendMsgStatus * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("sendMessage(cell:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)sendMessageBody:(id<TKKTon_kotlin_tlbCellRef>)body completionHandler_:(void (^)(TKKTon_kotlin_liteapi_tlLiteServerSendMsgStatus * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("sendMessage(body:completionHandler_:)")));
- (int64_t)setServerTimeTime:(int32_t)time __attribute__((swift_name("setServerTime(time:)")));
- (void)setServerVersionVersion:(int32_t)version capabilities:(int64_t)capabilities __attribute__((swift_name("setServerVersion(version:capabilities:)")));
@property (readonly) id<TKKKotlinCoroutineContext> coroutineContext __attribute__((swift_name("coroutineContext")));
@property (readonly) id<TKKTon_kotlin_liteapi_tlLiteApiClient> liteApi __attribute__((swift_name("liteApi")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("KotlinUnit")))
@interface TKKKotlinUnit : TKKBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)unit __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKKotlinUnit *shared __attribute__((swift_name("shared")));
- (NSString *)description __attribute__((swift_name("description()")));
@end

__attribute__((swift_name("RuntimeTransacterTransaction")))
@interface TKKRuntimeTransacterTransaction : TKKBase <TKKRuntimeTransactionCallbacks>
- (instancetype)init __attribute__((swift_name("init()"))) __attribute__((objc_designated_initializer));
+ (instancetype)new __attribute__((availability(swift, unavailable, message="use object initializers instead")));
- (void)afterCommitFunction:(void (^)(void))function __attribute__((swift_name("afterCommit(function:)")));
- (void)afterRollbackFunction:(void (^)(void))function __attribute__((swift_name("afterRollback(function:)")));

/**
 * @note This method has protected visibility in Kotlin source and is intended only for use by subclasses.
*/
- (id<TKKRuntimeQueryResult>)endTransactionSuccessful:(BOOL)successful __attribute__((swift_name("endTransaction(successful:)")));

/**
 * @note This property has protected visibility in Kotlin source and is intended only for use by subclasses.
*/
@property (readonly) TKKRuntimeTransacterTransaction * _Nullable enclosingTransaction __attribute__((swift_name("enclosingTransaction")));
@end

__attribute__((swift_name("RuntimeExecutableQuery")))
@interface TKKRuntimeExecutableQuery<__covariant RowType> : TKKBase
- (instancetype)initWithMapper:(RowType (^)(id<TKKRuntimeSqlCursor>))mapper __attribute__((swift_name("init(mapper:)"))) __attribute__((objc_designated_initializer));
- (id<TKKRuntimeQueryResult>)executeMapper:(id<TKKRuntimeQueryResult> (^)(id<TKKRuntimeSqlCursor>))mapper __attribute__((swift_name("execute(mapper:)")));
- (NSArray<RowType> *)executeAsList __attribute__((swift_name("executeAsList()")));
- (RowType)executeAsOne __attribute__((swift_name("executeAsOne()")));
- (RowType _Nullable)executeAsOneOrNull __attribute__((swift_name("executeAsOneOrNull()")));
@property (readonly) RowType (^mapper)(id<TKKRuntimeSqlCursor>) __attribute__((swift_name("mapper")));
@end

__attribute__((swift_name("RuntimeQuery")))
@interface TKKRuntimeQuery<__covariant RowType> : TKKRuntimeExecutableQuery<RowType>
- (instancetype)initWithMapper:(RowType (^)(id<TKKRuntimeSqlCursor>))mapper __attribute__((swift_name("init(mapper:)"))) __attribute__((objc_designated_initializer));
- (void)addListenerListener:(id<TKKRuntimeQueryListener>)listener __attribute__((swift_name("addListener(listener:)")));
- (void)removeListenerListener:(id<TKKRuntimeQueryListener>)listener __attribute__((swift_name("removeListener(listener:)")));
@end

__attribute__((swift_name("RuntimeColumnAdapter")))
@protocol TKKRuntimeColumnAdapter
@required
- (id)decodeDatabaseValue:(id _Nullable)databaseValue __attribute__((swift_name("decode(databaseValue:)")));
- (id _Nullable)encodeValue:(id)value __attribute__((swift_name("encode(value:)")));
@end

__attribute__((swift_name("Ton_kotlin_cryptoDecryptor")))
@protocol TKKTon_kotlin_cryptoDecryptor
@required
- (TKKKotlinByteArray *)decryptData:(TKKKotlinByteArray *)data __attribute__((swift_name("decrypt(data:)")));
- (TKKKotlinByteArray *)signMessage:(TKKKotlinByteArray *)message __attribute__((swift_name("sign(message:)")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((swift_name("Ton_kotlin_tonapi_tlPrivateKey")))
@protocol TKKTon_kotlin_tonapi_tlPrivateKey <TKKTon_kotlin_cryptoDecryptor>
@required
- (id<TKKTon_kotlin_tonapi_tlPublicKey>)publicKey __attribute__((swift_name("publicKey()")));
- (TKKTon_kotlin_tonapi_tlAdnlIdShort *)toAdnlIdShort __attribute__((swift_name("toAdnlIdShort()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
 *   kotlinx.serialization.SerialName(value="pk.ed25519")
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_tonapi_tlPrivateKeyEd25519")))
@interface TKKTon_kotlin_tonapi_tlPrivateKeyEd25519 : TKKBase <TKKTon_kotlin_tonapi_tlPrivateKey, TKKTon_kotlin_cryptoDecryptor>
- (instancetype)initWithKey:(TKKKotlinByteArray *)key __attribute__((swift_name("init(key:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithKey_:(TKKTon_kotlin_tlByteString *)key __attribute__((swift_name("init(key_:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_tonapi_tlPrivateKeyEd25519Companion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_tonapi_tlPrivateKeyEd25519 *)doCopyKey:(TKKTon_kotlin_tlByteString *)key __attribute__((swift_name("doCopy(key:)")));
- (TKKKotlinByteArray *)decryptData:(TKKKotlinByteArray *)data __attribute__((swift_name("decrypt(data:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (TKKTon_kotlin_tonapi_tlPublicKeyEd25519 *)publicKey __attribute__((swift_name("publicKey()")));
- (TKKKotlinByteArray *)sharedKeyPublicKey:(TKKTon_kotlin_tonapi_tlPublicKeyEd25519 *)publicKey __attribute__((swift_name("sharedKey(publicKey:)")));
- (TKKKotlinByteArray *)signMessage:(TKKKotlinByteArray *)message __attribute__((swift_name("sign(message:)")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) TKKTon_kotlin_tlByteString *key __attribute__((swift_name("key")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("KotlinEnumCompanion")))
@interface TKKKotlinEnumCompanion : TKKBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKKotlinEnumCompanion *shared __attribute__((swift_name("shared")));
@end

__attribute__((swift_name("Kotlinx_serialization_coreSerializationStrategy")))
@protocol TKKKotlinx_serialization_coreSerializationStrategy
@required
- (void)serializeEncoder:(id<TKKKotlinx_serialization_coreEncoder>)encoder value:(id _Nullable)value __attribute__((swift_name("serialize(encoder:value:)")));
@property (readonly) id<TKKKotlinx_serialization_coreSerialDescriptor> descriptor __attribute__((swift_name("descriptor")));
@end

__attribute__((swift_name("Kotlinx_serialization_coreDeserializationStrategy")))
@protocol TKKKotlinx_serialization_coreDeserializationStrategy
@required
- (id _Nullable)deserializeDecoder:(id<TKKKotlinx_serialization_coreDecoder>)decoder __attribute__((swift_name("deserialize(decoder:)")));
@property (readonly) id<TKKKotlinx_serialization_coreSerialDescriptor> descriptor __attribute__((swift_name("descriptor")));
@end

__attribute__((swift_name("Kotlinx_serialization_coreKSerializer")))
@protocol TKKKotlinx_serialization_coreKSerializer <TKKKotlinx_serialization_coreSerializationStrategy, TKKKotlinx_serialization_coreDeserializationStrategy>
@required
@end

__attribute__((swift_name("KotlinIterator")))
@protocol TKKKotlinIterator
@required
- (BOOL)hasNext __attribute__((swift_name("hasNext()")));
- (id _Nullable)next __attribute__((swift_name("next()")));
@end

__attribute__((swift_name("KotlinByteIterator")))
@interface TKKKotlinByteIterator : TKKBase <TKKKotlinIterator>
- (instancetype)init __attribute__((swift_name("init()"))) __attribute__((objc_designated_initializer));
+ (instancetype)new __attribute__((availability(swift, unavailable, message="use object initializers instead")));
- (TKKByte *)next __attribute__((swift_name("next()")));
- (int8_t)nextByte __attribute__((swift_name("nextByte()")));
@end

__attribute__((swift_name("Kotlinx_coroutines_coreFlowCollector")))
@protocol TKKKotlinx_coroutines_coreFlowCollector
@required

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)emitValue:(id _Nullable)value completionHandler:(void (^)(NSError * _Nullable))completionHandler __attribute__((swift_name("emit(value:completionHandler:)")));
@end

__attribute__((swift_name("RuntimeQueryListener")))
@protocol TKKRuntimeQueryListener
@required
- (void)queryResultsChanged __attribute__((swift_name("queryResultsChanged()")));
@end

__attribute__((swift_name("RuntimeQueryResult")))
@protocol TKKRuntimeQueryResult
@required

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)awaitWithCompletionHandler:(void (^)(id _Nullable_result, NSError * _Nullable))completionHandler __attribute__((swift_name("await(completionHandler:)")));
@property (readonly) id _Nullable value __attribute__((swift_name("value")));
@end

__attribute__((swift_name("RuntimeSqlPreparedStatement")))
@protocol TKKRuntimeSqlPreparedStatement
@required
- (void)bindBooleanIndex:(int32_t)index boolean:(TKKBoolean * _Nullable)boolean __attribute__((swift_name("bindBoolean(index:boolean:)")));
- (void)bindBytesIndex:(int32_t)index bytes:(TKKKotlinByteArray * _Nullable)bytes __attribute__((swift_name("bindBytes(index:bytes:)")));
- (void)bindDoubleIndex:(int32_t)index double:(TKKDouble * _Nullable)double_ __attribute__((swift_name("bindDouble(index:double:)")));
- (void)bindLongIndex:(int32_t)index long:(TKKLong * _Nullable)long_ __attribute__((swift_name("bindLong(index:long:)")));
- (void)bindStringIndex:(int32_t)index string:(NSString * _Nullable)string __attribute__((swift_name("bindString(index:string:)")));
@end

__attribute__((swift_name("RuntimeSqlCursor")))
@protocol TKKRuntimeSqlCursor
@required
- (TKKBoolean * _Nullable)getBooleanIndex:(int32_t)index __attribute__((swift_name("getBoolean(index:)")));
- (TKKKotlinByteArray * _Nullable)getBytesIndex:(int32_t)index __attribute__((swift_name("getBytes(index:)")));
- (TKKDouble * _Nullable)getDoubleIndex:(int32_t)index __attribute__((swift_name("getDouble(index:)")));
- (TKKLong * _Nullable)getLongIndex:(int32_t)index __attribute__((swift_name("getLong(index:)")));
- (NSString * _Nullable)getStringIndex:(int32_t)index __attribute__((swift_name("getString(index:)")));
- (id<TKKRuntimeQueryResult>)next __attribute__((swift_name("next()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("RuntimeAfterVersion")))
@interface TKKRuntimeAfterVersion : TKKBase
- (instancetype)initWithAfterVersion:(int64_t)afterVersion block:(void (^)(id<TKKRuntimeSqlDriver>))block __attribute__((swift_name("init(afterVersion:block:)"))) __attribute__((objc_designated_initializer));
@property (readonly) int64_t afterVersion __attribute__((swift_name("afterVersion")));
@property (readonly) void (^block)(id<TKKRuntimeSqlDriver>) __attribute__((swift_name("block")));
@end

__attribute__((swift_name("KotlinIterable")))
@protocol TKKKotlinIterable
@required
- (id<TKKKotlinIterator>)iterator __attribute__((swift_name("iterator()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable(with=NormalClass(value=org/ton/bitstring/FiftHexBitStringSerializer))
*/
__attribute__((swift_name("Ton_kotlin_bitstringBitString")))
@protocol TKKTon_kotlin_bitstringBitString <TKKKotlinIterable, TKKKotlinComparable>
@required
- (id<TKKTon_kotlin_bitstringBitString>)commonPrefixWithOther:(id<TKKTon_kotlin_bitstringBitString>)other __attribute__((swift_name("commonPrefixWith(other:)")));
- (id<TKKTon_kotlin_bitstringBitString>)commonSuffixWithOther:(id<TKKTon_kotlin_bitstringBitString>)other __attribute__((swift_name("commonSuffixWith(other:)")));
- (BOOL)endsWithSuffix:(id<TKKTon_kotlin_bitstringBitString>)suffix __attribute__((swift_name("endsWith(suffix:)")));
- (BOOL)getIndex:(int32_t)index __attribute__((swift_name("get(index:)")));
- (TKKBoolean * _Nullable)getOrNullIndex:(int32_t)index __attribute__((swift_name("getOrNull(index:)")));
- (BOOL)isEmpty __attribute__((swift_name("isEmpty()")));
- (id<TKKTon_kotlin_bitstringBitString>)orOther:(id<TKKTon_kotlin_bitstringBitString>)other __attribute__((swift_name("or(other:)")));
- (id<TKKTon_kotlin_bitstringBitString>)plusBit:(BOOL)bit __attribute__((swift_name("plus(bit:)")));
- (id<TKKTon_kotlin_bitstringBitString>)plusBits:(TKKKotlinBooleanArray *)bits __attribute__((swift_name("plus(bits:)")));
- (id<TKKTon_kotlin_bitstringBitString>)plusBytes:(TKKKotlinByteArray *)bytes __attribute__((swift_name("plus(bytes:)")));
- (id<TKKTon_kotlin_bitstringBitString>)plusBytes:(TKKKotlinByteArray *)bytes bits:(int32_t)bits __attribute__((swift_name("plus(bytes:bits:)")));
- (id<TKKTon_kotlin_bitstringBitString>)plusBits_:(id)bits __attribute__((swift_name("plus(bits_:)")));
- (id<TKKTon_kotlin_bitstringBitString>)plusBits__:(id)bits __attribute__((swift_name("plus(bits__:)")));
- (id<TKKTon_kotlin_bitstringBitString>)sliceStartIndex:(int32_t)startIndex endIndex:(int32_t)endIndex __attribute__((swift_name("slice(startIndex:endIndex:)")));
- (id<TKKTon_kotlin_bitstringBitString>)sliceIndices:(TKKKotlinIntRange *)indices __attribute__((swift_name("slice(indices:)")));
- (BOOL)startsWithPrefix:(id<TKKTon_kotlin_bitstringBitString>)prefix __attribute__((swift_name("startsWith(prefix:)")));
- (NSString *)toBinary __attribute__((swift_name("toBinary()")));
- (id<TKKTon_kotlin_bitstringBitString>)toBitString __attribute__((swift_name("toBitString()")));
- (TKKKotlinBooleanArray *)toBooleanArray __attribute__((swift_name("toBooleanArray()")));
- (TKKKotlinByteArray *)toByteArrayAugment:(BOOL)augment __attribute__((swift_name("toByteArray(augment:)")));
- (NSString *)toHex __attribute__((swift_name("toHex()")));
- (id<TKKTon_kotlin_bitstringMutableBitString>)toMutableBitString __attribute__((swift_name("toMutableBitString()")));
- (id<TKKTon_kotlin_bitstringBitString>)xorOther:(id<TKKTon_kotlin_bitstringBitString>)other __attribute__((swift_name("xor(other:)")));
@property (readonly) int32_t size __attribute__((swift_name("size")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_tlbTlbPrettyPrinter")))
@interface TKKTon_kotlin_tlbTlbPrettyPrinter : TKKBase
- (instancetype)initWithStringBuilder:(TKKKotlinStringBuilder *)stringBuilder indent:(int32_t)indent __attribute__((swift_name("init(stringBuilder:indent:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithStringBuilder:(TKKKotlinStringBuilder *)stringBuilder __attribute__((swift_name("init(stringBuilder:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithIndent:(int32_t)indent __attribute__((swift_name("init(indent:)"))) __attribute__((objc_designated_initializer));
- (instancetype)init __attribute__((swift_name("init()"))) __attribute__((objc_designated_initializer));
+ (instancetype)new __attribute__((availability(swift, unavailable, message="use object initializers instead")));
- (instancetype)initWithStringBuilder:(TKKKotlinStringBuilder *)stringBuilder indent:(int32_t)indent dummy:(BOOL)dummy __attribute__((swift_name("init(stringBuilder:indent:dummy:)"))) __attribute__((objc_designated_initializer));
- (TKKTon_kotlin_tlbTlbPrettyPrinter *)closeMsg:(NSString *)msg __attribute__((swift_name("close(msg:)")));
- (TKKTon_kotlin_tlbTlbPrettyPrinter *)fieldType:(id _Nullable)type __attribute__((swift_name("field(type:)")));
- (TKKTon_kotlin_tlbTlbPrettyPrinter *)fieldName:(NSString *)name type:(id _Nullable)type __attribute__((swift_name("field(name:type:)")));
- (TKKTon_kotlin_tlbTlbPrettyPrinter *)invokeBlock:(void (^)(TKKTon_kotlin_tlbTlbPrettyPrinter *))block __attribute__((swift_name("invoke(block:)")));
- (void)doNewLine __attribute__((swift_name("doNewLine()")));
- (TKKTon_kotlin_tlbTlbPrettyPrinter *)openMsg:(NSString *)msg __attribute__((swift_name("open(msg:)")));
- (NSString *)description __attribute__((swift_name("description()")));
- (TKKTon_kotlin_tlbTlbPrettyPrinter *)typeType:(id _Nullable)type __attribute__((swift_name("type(type:)")));
- (TKKTon_kotlin_tlbTlbPrettyPrinter *)typeName:(NSString *)name block:(void (^)(TKKTon_kotlin_tlbTlbPrettyPrinter *))block __attribute__((swift_name("type(name:block:)")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.SerialName(value="anycast_info")
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_block_tlbAnycast")))
@interface TKKTon_kotlin_block_tlbAnycast : TKKBase <TKKTon_kotlin_tlbTlbObject>
- (instancetype)initWithRewritePfx:(id<TKKTon_kotlin_bitstringBitString>)rewritePfx __attribute__((swift_name("init(rewritePfx:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithDepth:(int32_t)depth rewritePfx:(id<TKKTon_kotlin_bitstringBitString>)rewritePfx __attribute__((swift_name("init(depth:rewritePfx:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_block_tlbAnycastCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_block_tlbAnycast *)doCopyDepth:(int32_t)depth rewritePfx:(id<TKKTon_kotlin_bitstringBitString>)rewritePfx __attribute__((swift_name("doCopy(depth:rewritePfx:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (TKKTon_kotlin_tlbTlbPrettyPrinter *)printPrinter:(TKKTon_kotlin_tlbTlbPrettyPrinter *)printer __attribute__((swift_name("print(printer:)")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) int32_t depth __attribute__((swift_name("depth")));

/**
 * @note annotations
 *   kotlinx.serialization.SerialName(value="rewrite_pfx")
*/
@property (readonly) id<TKKTon_kotlin_bitstringBitString> rewritePfx __attribute__((swift_name("rewritePfx")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((swift_name("Ton_kotlin_block_tlbMaybe")))
@protocol TKKTon_kotlin_block_tlbMaybe <TKKTon_kotlin_tlbTlbObject>
@required
- (id _Nullable)get __attribute__((swift_name("get()")));
@property (readonly) id _Nullable value __attribute__((swift_name("value")));
@end

__attribute__((swift_name("Ton_kotlin_tlbTlbStorer")))
@protocol TKKTon_kotlin_tlbTlbStorer
@required
- (id<TKKTon_kotlin_tvmCell>)createCellValue:(id _Nullable)value __attribute__((swift_name("createCell(value:)")));
- (void)storeTlbCellBuilder:(id<TKKTon_kotlin_tvmCellBuilder>)cellBuilder value:(id _Nullable)value __attribute__((swift_name("storeTlb(cellBuilder:value:)")));
@end

__attribute__((swift_name("Ton_kotlin_tlbTlbLoader")))
@protocol TKKTon_kotlin_tlbTlbLoader
@required
- (id _Nullable)loadTlbCell:(id<TKKTon_kotlin_tvmCell>)cell __attribute__((swift_name("loadTlb(cell:)")));
- (id _Nullable)loadTlbCellSlice:(id<TKKTon_kotlin_tvmCellSlice>)cellSlice __attribute__((swift_name("loadTlb(cellSlice:)")));
@end

__attribute__((swift_name("Ton_kotlin_tlbTlbCodec")))
@protocol TKKTon_kotlin_tlbTlbCodec <TKKTon_kotlin_tlbTlbStorer, TKKTon_kotlin_tlbTlbLoader>
@required
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_block_tlbAddrStd.Companion")))
@interface TKKTon_kotlin_block_tlbAddrStdCompanion : TKKBase <TKKTon_kotlin_tlbTlbCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_block_tlbAddrStdCompanion *shared __attribute__((swift_name("shared")));
- (id<TKKTon_kotlin_tvmCell>)createCellValue:(TKKTon_kotlin_block_tlbAddrStd *)value __attribute__((swift_name("createCell(value:)")));
- (TKKTon_kotlin_block_tlbAddrStd *)loadTlbCell:(id<TKKTon_kotlin_tvmCell>)cell __attribute__((swift_name("loadTlb(cell:)")));
- (TKKTon_kotlin_block_tlbAddrStd *)loadTlbCellSlice:(id<TKKTon_kotlin_tvmCellSlice>)cellSlice __attribute__((swift_name("loadTlb(cellSlice:)")));

/**
 * @note annotations
 *   kotlin.jvm.JvmStatic
*/
- (TKKTon_kotlin_block_tlbAddrStd *)parseAddress:(NSString *)address __attribute__((swift_name("parse(address:)")));

/**
 * @note annotations
 *   kotlin.jvm.JvmStatic
*/
- (TKKTon_kotlin_block_tlbAddrStd *)parseRawAddress:(NSString *)address __attribute__((swift_name("parseRaw(address:)")));

/**
 * @note annotations
 *   kotlin.jvm.JvmStatic
*/
- (TKKTon_kotlin_block_tlbAddrStd *)parseUserFriendlyAddress:(NSString *)address __attribute__((swift_name("parseUserFriendly(address:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
- (void)storeTlbCellBuilder:(id<TKKTon_kotlin_tvmCellBuilder>)cellBuilder value:(TKKTon_kotlin_block_tlbAddrStd *)value __attribute__((swift_name("storeTlb(cellBuilder:value:)")));

/**
 * @note annotations
 *   kotlin.jvm.JvmStatic
*/
- (TKKTon_kotlin_tlbTlbConstructor<TKKTon_kotlin_block_tlbAddrStd *> *)tlbCodec __attribute__((swift_name("tlbCodec()")));

/**
 * @note annotations
 *   kotlin.jvm.JvmStatic
*/
- (NSString *)toStringAddress:(TKKTon_kotlin_block_tlbAddrStd *)address userFriendly:(BOOL)userFriendly urlSafe:(BOOL)urlSafe testOnly:(BOOL)testOnly bounceable:(BOOL)bounceable __attribute__((swift_name("toString(address:userFriendly:urlSafe:testOnly:bounceable:)")));
@end

__attribute__((swift_name("Ton_kotlin_tonapi_tlTonNodeBlockId")))
@protocol TKKTon_kotlin_tonapi_tlTonNodeBlockId
@required
- (int32_t)component1 __attribute__((swift_name("component1()")));
- (int64_t)component2 __attribute__((swift_name("component2()")));
- (int32_t)component3 __attribute__((swift_name("component3()")));
- (BOOL)isMasterchain __attribute__((swift_name("isMasterchain()")));
- (BOOL)isValid __attribute__((swift_name("isValid()")));
- (BOOL)isValidExt __attribute__((swift_name("isValidExt()")));
- (BOOL)isValidFull __attribute__((swift_name("isValidFull()")));
- (id<TKKTon_kotlin_tonapi_tlTonNodeBlockId>)withSeqnoSeqno:(int32_t)seqno __attribute__((swift_name("withSeqno(seqno:)")));
@property (readonly) int32_t seqno __attribute__((swift_name("seqno")));
@property (readonly) int64_t shard __attribute__((swift_name("shard")));
@property (readonly) int32_t workchain __attribute__((swift_name("workchain")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_tonapi_tlTonNodeBlockIdExt")))
@interface TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt : TKKBase <TKKTon_kotlin_tonapi_tlTonNodeBlockId>
- (instancetype)initWithWorkchain:(int32_t)workchain shard:(int64_t)shard seqno:(int32_t)seqno rootHash:(TKKKotlinByteArray *)rootHash fileHash:(TKKKotlinByteArray *)fileHash __attribute__((swift_name("init(workchain:shard:seqno:rootHash:fileHash:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithTonNodeBlockId:(id<TKKTon_kotlin_tonapi_tlTonNodeBlockId>)tonNodeBlockId rootHash:(TKKKotlinByteArray *)rootHash fileHash:(TKKKotlinByteArray *)fileHash __attribute__((swift_name("init(tonNodeBlockId:rootHash:fileHash:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithTonNodeBlockId:(id<TKKTon_kotlin_tonapi_tlTonNodeBlockId>)tonNodeBlockId rootHash:(TKKTon_kotlin_tlByteString *)rootHash fileHash_:(TKKTon_kotlin_tlByteString *)fileHash __attribute__((swift_name("init(tonNodeBlockId:rootHash:fileHash_:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithWorkchain:(int32_t)workchain shard:(int64_t)shard seqno:(int32_t)seqno rootHash:(TKKTon_kotlin_tlByteString *)rootHash fileHash_:(TKKTon_kotlin_tlByteString *)fileHash __attribute__((swift_name("init(workchain:shard:seqno:rootHash:fileHash_:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_tonapi_tlTonNodeBlockIdExtCompanion *companion __attribute__((swift_name("companion")));
- (int32_t)component1 __attribute__((swift_name("component1()")));
- (int64_t)component2 __attribute__((swift_name("component2()")));
- (int32_t)component3 __attribute__((swift_name("component3()")));
- (TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)doCopyWorkchain:(int32_t)workchain shard:(int64_t)shard seqno:(int32_t)seqno rootHash:(TKKTon_kotlin_tlByteString *)rootHash fileHash:(TKKTon_kotlin_tlByteString *)fileHash __attribute__((swift_name("doCopy(workchain:shard:seqno:rootHash:fileHash:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));

/**
 * @note annotations
 *   kotlinx.serialization.SerialName(value="file_hash")
*/
@property (readonly) TKKTon_kotlin_tlByteString *fileHash __attribute__((swift_name("fileHash")));

/**
 * @note annotations
 *   kotlinx.serialization.SerialName(value="root_hash")
*/
@property (readonly) TKKTon_kotlin_tlByteString *rootHash __attribute__((swift_name("rootHash")));

/**
 * @note annotations
 *   kotlinx.serialization.SerialName(value="seqno")
*/
@property (readonly) int32_t seqno __attribute__((swift_name("seqno")));

/**
 * @note annotations
 *   kotlinx.serialization.SerialName(value="shard")
*/
@property (readonly) int64_t shard __attribute__((swift_name("shard")));

/**
 * @note annotations
 *   kotlinx.serialization.SerialName(value="workchain")
*/
@property (readonly) int32_t workchain __attribute__((swift_name("workchain")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteclientTransactionId")))
@interface TKKTon_kotlin_liteclientTransactionId : TKKBase
- (instancetype)initWithHash:(TKKKotlinByteArray *)hash lt:(int64_t)lt __attribute__((swift_name("init(hash:lt:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithHash:(id<TKKTon_kotlin_bitstringBitString>)hash lt_:(int64_t)lt __attribute__((swift_name("init(hash:lt_:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteclientTransactionIdCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteclientTransactionId *)doCopyHash:(id<TKKTon_kotlin_bitstringBitString>)hash lt:(int64_t)lt __attribute__((swift_name("doCopy(hash:lt:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly, getter=hash_) id<TKKTon_kotlin_bitstringBitString> hash __attribute__((swift_name("hash")));
@property (readonly) int64_t lt __attribute__((swift_name("lt")));
@end

__attribute__((swift_name("Ton_kotlin_tlbCellRef")))
@protocol TKKTon_kotlin_tlbCellRef <TKKTon_kotlin_tlbTlbObject>
@required
- (id _Nullable)getValueThisRef:(id _Nullable)thisRef property:(id _Nullable)property __attribute__((swift_name("getValue(thisRef:property:)")));
- (id<TKKTon_kotlin_bitstringBitString>)hash_ __attribute__((swift_name("hash_()")));
- (id<TKKTon_kotlin_bitstringBitString>)hashCodec:(id<TKKTon_kotlin_tlbTlbCodec> _Nullable)codec __attribute__((swift_name("hash(codec:)")));
- (id<TKKTon_kotlin_tvmCell>)toCellCodec:(id<TKKTon_kotlin_tlbTlbCodec> _Nullable)codec __attribute__((swift_name("toCell(codec:)")));
@property (readonly) id _Nullable value __attribute__((swift_name("value")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteclientFullAccountState.Companion")))
@interface TKKTon_kotlin_liteclientFullAccountStateCompanion : TKKBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteclientFullAccountStateCompanion *shared __attribute__((swift_name("shared")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlin.SinceKotlin(version="1.3")
*/
__attribute__((swift_name("KotlinCoroutineContext")))
@protocol TKKKotlinCoroutineContext
@required
- (id _Nullable)foldInitial:(id _Nullable)initial operation:(id _Nullable (^)(id _Nullable, id<TKKKotlinCoroutineContextElement>))operation __attribute__((swift_name("fold(initial:operation:)")));
- (id<TKKKotlinCoroutineContextElement> _Nullable)getKey:(id<TKKKotlinCoroutineContextKey>)key __attribute__((swift_name("get(key:)")));
- (id<TKKKotlinCoroutineContext>)minusKeyKey:(id<TKKKotlinCoroutineContextKey>)key __attribute__((swift_name("minusKey(key:)")));
- (id<TKKKotlinCoroutineContext>)plusContext:(id<TKKKotlinCoroutineContext>)context __attribute__((swift_name("plus(context:)")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteclientTransactionInfo")))
@interface TKKTon_kotlin_liteclientTransactionInfo : TKKBase
- (instancetype)initWithBlockId:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)blockId id:(TKKTon_kotlin_liteclientTransactionId *)id transaction:(id<TKKTon_kotlin_tlbCellRef>)transaction __attribute__((swift_name("init(blockId:id:transaction:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteclientTransactionInfoCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteclientTransactionInfo *)doCopyBlockId:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)blockId id:(TKKTon_kotlin_liteclientTransactionId *)id transaction:(id<TKKTon_kotlin_tlbCellRef>)transaction __attribute__((swift_name("doCopy(blockId:id:transaction:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));

/**
 * @note annotations
 *   kotlinx.serialization.SerialName(value="block_id")
*/
@property (readonly) TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *blockId __attribute__((swift_name("blockId")));
@property (readonly) TKKTon_kotlin_liteclientTransactionId *id __attribute__((swift_name("id")));
@property (readonly) id<TKKTon_kotlin_tlbCellRef> transaction __attribute__((swift_name("transaction")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
 *   kotlinx.serialization.SerialName(value="liteserver.desc")
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_tonapi_tlLiteServerDesc")))
@interface TKKTon_kotlin_tonapi_tlLiteServerDesc : TKKBase
- (instancetype)initWithId:(id<TKKTon_kotlin_tonapi_tlPublicKey>)id ip:(int32_t)ip port:(int32_t)port __attribute__((swift_name("init(id:ip:port:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_tonapi_tlLiteServerDescCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_tonapi_tlLiteServerDesc *)doCopyId:(id<TKKTon_kotlin_tonapi_tlPublicKey>)id ip:(int32_t)ip port:(int32_t)port __attribute__((swift_name("doCopy(id:ip:port:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) id<TKKTon_kotlin_tonapi_tlPublicKey> id __attribute__((swift_name("id")));
@property (readonly) int32_t ip __attribute__((swift_name("ip")));
@property (readonly) int32_t port __attribute__((swift_name("port")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.SerialName(value="liteclient.config.global")
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_tonapi_tlLiteClientConfigGlobal")))
@interface TKKTon_kotlin_tonapi_tlLiteClientConfigGlobal : TKKBase
- (instancetype)initWithDht:(TKKTon_kotlin_tonapi_tlDhtConfigGlobal *)dht liteServers:(id)liteServers validator:(TKKTon_kotlin_tonapi_tlValidatorConfigGlobal *)validator __attribute__((swift_name("init(dht:liteServers:validator:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_tonapi_tlLiteClientConfigGlobalCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_tonapi_tlLiteClientConfigGlobal *)doCopyDht:(TKKTon_kotlin_tonapi_tlDhtConfigGlobal *)dht liteServers:(id)liteServers validator:(TKKTon_kotlin_tonapi_tlValidatorConfigGlobal *)validator __attribute__((swift_name("doCopy(dht:liteServers:validator:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) TKKTon_kotlin_tonapi_tlDhtConfigGlobal *dht __attribute__((swift_name("dht")));

/**
 * @note annotations
 *   kotlinx.serialization.SerialName(value="liteservers")
*/
@property (readonly) id liteServers __attribute__((swift_name("liteServers")));
@property (readonly) TKKTon_kotlin_tonapi_tlValidatorConfigGlobal *validator __attribute__((swift_name("validator")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.SerialName(value="block")
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_block_tlbBlock")))
@interface TKKTon_kotlin_block_tlbBlock : TKKBase <TKKTon_kotlin_tlbTlbObject>
- (instancetype)initWithGlobalId:(int32_t)globalId info:(id<TKKTon_kotlin_tlbCellRef>)info valueFlow:(id<TKKTon_kotlin_tlbCellRef>)valueFlow stateUpdate:(id<TKKTon_kotlin_tlbCellRef>)stateUpdate extra:(id<TKKTon_kotlin_tlbCellRef>)extra __attribute__((swift_name("init(globalId:info:valueFlow:stateUpdate:extra:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_block_tlbBlockCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_block_tlbBlock *)doCopyGlobalId:(int32_t)globalId info:(id<TKKTon_kotlin_tlbCellRef>)info valueFlow:(id<TKKTon_kotlin_tlbCellRef>)valueFlow stateUpdate:(id<TKKTon_kotlin_tlbCellRef>)stateUpdate extra:(id<TKKTon_kotlin_tlbCellRef>)extra __attribute__((swift_name("doCopy(globalId:info:valueFlow:stateUpdate:extra:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (TKKTon_kotlin_tlbTlbPrettyPrinter *)printPrinter:(TKKTon_kotlin_tlbTlbPrettyPrinter *)printer __attribute__((swift_name("print(printer:)")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) id<TKKTon_kotlin_tlbCellRef> extra __attribute__((swift_name("extra")));

/**
 * @note annotations
 *   kotlinx.serialization.SerialName(value="global_id")
*/
@property (readonly) int32_t globalId __attribute__((swift_name("globalId")));
@property (readonly) id<TKKTon_kotlin_tlbCellRef> info __attribute__((swift_name("info")));

/**
 * @note annotations
 *   kotlinx.serialization.SerialName(value="state_update")
*/
@property (readonly) id<TKKTon_kotlin_tlbCellRef> stateUpdate __attribute__((swift_name("stateUpdate")));

/**
 * @note annotations
 *   kotlinx.serialization.SerialName(value="value_flow")
*/
@property (readonly) id<TKKTon_kotlin_tlbCellRef> valueFlow __attribute__((swift_name("valueFlow")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable(with=NormalClass(value=kotlinx/datetime/serializers/InstantIso8601Serializer))
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Kotlinx_datetimeInstant")))
@interface TKKKotlinx_datetimeInstant : TKKBase <TKKKotlinComparable>
@property (class, readonly, getter=companion) TKKKotlinx_datetimeInstantCompanion *companion __attribute__((swift_name("companion")));
- (int32_t)compareToOther:(TKKKotlinx_datetimeInstant *)other __attribute__((swift_name("compareTo(other:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (TKKKotlinx_datetimeInstant *)minusDuration:(int64_t)duration __attribute__((swift_name("minus(duration:)")));
- (int64_t)minusOther:(TKKKotlinx_datetimeInstant *)other __attribute__((swift_name("minus(other:)")));
- (TKKKotlinx_datetimeInstant *)plusDuration:(int64_t)duration __attribute__((swift_name("plus(duration:)")));
- (int64_t)toEpochMilliseconds __attribute__((swift_name("toEpochMilliseconds()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) int64_t epochSeconds __attribute__((swift_name("epochSeconds")));
@property (readonly) int32_t nanosecondsOfSecond __attribute__((swift_name("nanosecondsOfSecond")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
 *   kotlinx.serialization.SerialName(value="liteServer.version")
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerVersion")))
@interface TKKTon_kotlin_liteapi_tlLiteServerVersion : TKKBase
- (instancetype)initWithMode:(int32_t)mode version:(int32_t)version capabilities:(int64_t)capabilities now:(int32_t)now __attribute__((swift_name("init(mode:version:capabilities:now:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapi_tlLiteServerVersionCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapi_tlLiteServerVersion *)doCopyMode:(int32_t)mode version:(int32_t)version capabilities:(int64_t)capabilities now:(int32_t)now __attribute__((swift_name("doCopy(mode:version:capabilities:now:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) int64_t capabilities __attribute__((swift_name("capabilities")));
@property (readonly) int32_t mode __attribute__((swift_name("mode")));
@property (readonly) int32_t now __attribute__((swift_name("now")));
@property (readonly) int32_t version __attribute__((swift_name("version")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
 *   kotlinx.serialization.SerialName(value="liteServer.accountId")
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerAccountId")))
@interface TKKTon_kotlin_liteapi_tlLiteServerAccountId : TKKBase
- (instancetype)initWithWorkchain:(int32_t)workchain id:(TKKKotlinByteArray *)id __attribute__((swift_name("init(workchain:id:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithWorkchain:(int32_t)workchain id_:(id<TKKTon_kotlin_bitstringBitString>)id __attribute__((swift_name("init(workchain:id_:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithWorkchain:(int32_t)workchain id__:(TKKTon_kotlin_tlByteString *)id __attribute__((swift_name("init(workchain:id__:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapi_tlLiteServerAccountIdCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapi_tlLiteServerAccountId *)doCopyWorkchain:(int32_t)workchain id:(TKKTon_kotlin_tlByteString *)id __attribute__((swift_name("doCopy(workchain:id:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) TKKTon_kotlin_tlByteString *id __attribute__((swift_name("id")));
@property (readonly) int32_t workchain __attribute__((swift_name("workchain")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((swift_name("Ton_kotlin_block_tlbVmStackValue")))
@protocol TKKTon_kotlin_block_tlbVmStackValue
@required
@end

__attribute__((swift_name("KotlinCollection")))
@protocol TKKKotlinCollection <TKKKotlinIterable>
@required
- (BOOL)containsElement:(id _Nullable)element __attribute__((swift_name("contains(element:)")));
- (BOOL)containsAllElements:(id)elements __attribute__((swift_name("containsAll(elements:)")));
- (BOOL)isEmpty __attribute__((swift_name("isEmpty()")));
@property (readonly) int32_t size __attribute__((swift_name("size")));
@end

__attribute__((swift_name("Ton_kotlin_block_tlbVmStack")))
@protocol TKKTon_kotlin_block_tlbVmStack <TKKKotlinCollection>
@required
- (id<TKKTon_kotlin_block_tlbVmStackValue>)getIndex_:(int32_t)index __attribute__((swift_name("get(index_:)")));
- (id<TKKTon_kotlin_block_tlbMutableVmStack>)toMutableVmStack __attribute__((swift_name("toMutableVmStack()")));
@property (readonly) int32_t depth __attribute__((swift_name("depth")));
@property (readonly) id<TKKTon_kotlin_block_tlbVmStackList> stack __attribute__((swift_name("stack")));
@end

__attribute__((swift_name("Ton_kotlin_tvmCell")))
@protocol TKKTon_kotlin_tvmCell
@required
- (id<TKKTon_kotlin_tvmCellSlice>)beginParse __attribute__((swift_name("beginParse()")));
- (int32_t)depthLevel:(int32_t)level __attribute__((swift_name("depth(level:)")));
- (id<TKKTon_kotlin_bitstringBitString>)hashLevel:(int32_t)level __attribute__((swift_name("hash(level:)")));
- (BOOL)isEmpty __attribute__((swift_name("isEmpty()")));
- (id _Nullable)parseBlock:(id _Nullable (^)(id<TKKTon_kotlin_tvmCellSlice>))block __attribute__((swift_name("parse(block:)")));
- (id<TKKKotlinSequence>)treeWalk __attribute__((swift_name("treeWalk()")));
- (id<TKKTon_kotlin_tvmCell>)virtualizeOffset:(int32_t)offset __attribute__((swift_name("virtualize(offset:)")));
@property (readonly) id<TKKTon_kotlin_bitstringBitString> bits __attribute__((swift_name("bits")));
@property (readonly) id<TKKTon_kotlin_tvmCellDescriptor> descriptor __attribute__((swift_name("descriptor")));
@property (readonly) int32_t levelMask __attribute__((swift_name("levelMask")));
@property (readonly) NSArray<id<TKKTon_kotlin_tvmCell>> *refs __attribute__((swift_name("refs")));
@property (readonly) TKKTon_kotlin_tvmCellType *type __attribute__((swift_name("type")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_block_tlbMessage")))
@interface TKKTon_kotlin_block_tlbMessage<X> : TKKBase <TKKTon_kotlin_tlbTlbObject>
- (instancetype)initWithInfo:(id<TKKTon_kotlin_block_tlbCommonMsgInfo>)info init:(id<TKKTon_kotlin_block_tlbMaybe>)init body:(id<TKKTon_kotlin_block_tlbEither>)body __attribute__((swift_name("init(info:init:body:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_block_tlbMessageCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_block_tlbMessage<X> *)doCopyInfo:(id<TKKTon_kotlin_block_tlbCommonMsgInfo>)info init:(id<TKKTon_kotlin_block_tlbMaybe>)init body:(id<TKKTon_kotlin_block_tlbEither>)body __attribute__((swift_name("doCopy(info:init:body:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (TKKTon_kotlin_tlbTlbPrettyPrinter *)printPrinter:(TKKTon_kotlin_tlbTlbPrettyPrinter *)printer __attribute__((swift_name("print(printer:)")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) id<TKKTon_kotlin_block_tlbEither> body __attribute__((swift_name("body")));
@property (readonly) id<TKKTon_kotlin_block_tlbCommonMsgInfo> info __attribute__((swift_name("info")));
@property (readonly, getter=doInit) id<TKKTon_kotlin_block_tlbMaybe> init __attribute__((swift_name("init")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
 *   kotlinx.serialization.SerialName(value="liteServer.sendMsgStatus")
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerSendMsgStatus")))
@interface TKKTon_kotlin_liteapi_tlLiteServerSendMsgStatus : TKKBase
- (instancetype)initWithStatus:(int32_t)status __attribute__((swift_name("init(status:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapi_tlLiteServerSendMsgStatusCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapi_tlLiteServerSendMsgStatus *)doCopyStatus:(int32_t)status __attribute__((swift_name("doCopy(status:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) int32_t status __attribute__((swift_name("status")));
@end

__attribute__((swift_name("Ton_kotlin_tvmBagOfCells")))
@protocol TKKTon_kotlin_tvmBagOfCells <TKKKotlinIterable>
@required
- (TKKKotlinByteArray *)toByteArray __attribute__((swift_name("toByteArray()")));
- (void)writeOutput:(TKKKtor_ioOutput *)output __attribute__((swift_name("write(output:)")));
@property (readonly) NSArray<id<TKKTon_kotlin_tvmCell>> *roots __attribute__((swift_name("roots")));
@end

__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteApi")))
@protocol TKKTon_kotlin_liteapi_tlLiteApi
@required

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)invokeFunction:(TKKTon_kotlin_liteapi_tlLiteServerGetAccountState *)function waitMasterchainSeqno:(int32_t)waitMasterchainSeqno completionHandler:(void (^)(TKKTon_kotlin_liteapi_tlLiteServerAccountState * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("invoke(function:waitMasterchainSeqno:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)invokeFunction:(TKKTon_kotlin_liteapi_tlLiteServerGetAllShardsInfo *)function completionHandler:(void (^)(TKKTon_kotlin_liteapi_tlLiteServerAllShardsInfo * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("invoke(function:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)invokeFunction:(TKKTon_kotlin_liteapi_tlLiteServerGetBlock *)function completionHandler_:(void (^)(TKKTon_kotlin_liteapi_tlLiteServerBlockData * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("invoke(function:completionHandler_:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)invokeFunction:(TKKTon_kotlin_liteapi_tlLiteServerGetBlockHeader *)function completionHandler__:(void (^)(TKKTon_kotlin_liteapi_tlLiteServerBlockHeader * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("invoke(function:completionHandler__:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)invokeFunction:(TKKTon_kotlin_liteapi_tlLiteServerGetBlockProof *)function completionHandler___:(void (^)(TKKTon_kotlin_liteapi_tlLiteServerPartialBlockProof * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("invoke(function:completionHandler___:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)invokeFunction:(TKKTon_kotlin_liteapi_tlLiteServerGetConfigAll *)function completionHandler____:(void (^)(TKKTon_kotlin_liteapi_tlLiteServerConfigInfo * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("invoke(function:completionHandler____:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)invokeFunction:(TKKTon_kotlin_liteapi_tlLiteServerGetConfigParams *)function completionHandler_____:(void (^)(TKKTon_kotlin_liteapi_tlLiteServerConfigInfo * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("invoke(function:completionHandler_____:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)invokeFunction:(TKKTon_kotlin_liteapi_tlLiteServerGetMasterchainInfo *)function waitMasterchainSeqno:(int32_t)waitMasterchainSeqno completionHandler_:(void (^)(TKKTon_kotlin_liteapi_tlLiteServerMasterchainInfo * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("invoke(function:waitMasterchainSeqno:completionHandler_:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)invokeFunction:(TKKTon_kotlin_liteapi_tlLiteServerGetMasterchainInfoExt *)function waitMasterchainSeqno:(int32_t)waitMasterchainSeqno completionHandler__:(void (^)(TKKTon_kotlin_liteapi_tlLiteServerMasterchainInfoExt * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("invoke(function:waitMasterchainSeqno:completionHandler__:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)invokeFunction:(TKKTon_kotlin_liteapi_tlLiteServerGetOneTransaction *)function completionHandler______:(void (^)(TKKTon_kotlin_liteapi_tlLiteServerTransactionInfo * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("invoke(function:completionHandler______:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)invokeFunction:(TKKTon_kotlin_liteapi_tlLiteServerGetShardInfo *)function completionHandler_______:(void (^)(TKKTon_kotlin_liteapi_tlLiteServerShardInfo * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("invoke(function:completionHandler_______:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)invokeFunction:(TKKTon_kotlin_liteapi_tlLiteServerGetState *)function completionHandler________:(void (^)(TKKTon_kotlin_liteapi_tlLiteServerBlockState * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("invoke(function:completionHandler________:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)invokeFunction:(TKKTon_kotlin_liteapi_tlLiteServerGetTime *)function completionHandler_________:(void (^)(TKKTon_kotlin_liteapi_tlLiteServerCurrentTime * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("invoke(function:completionHandler_________:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)invokeFunction:(TKKTon_kotlin_liteapi_tlLiteServerGetTransactions *)function completionHandler__________:(void (^)(TKKTon_kotlin_liteapi_tlLiteServerTransactionList * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("invoke(function:completionHandler__________:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)invokeFunction:(TKKTon_kotlin_liteapi_tlLiteServerGetValidatorStats *)function completionHandler___________:(void (^)(TKKTon_kotlin_liteapi_tlLiteServerValidatorStats * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("invoke(function:completionHandler___________:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)invokeFunction:(TKKTon_kotlin_liteapi_tlLiteServerGetVersion *)function completionHandler____________:(void (^)(TKKTon_kotlin_liteapi_tlLiteServerVersion * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("invoke(function:completionHandler____________:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)invokeFunction:(TKKTon_kotlin_liteapi_tlLiteServerListBlockTransactions *)function completionHandler_____________:(void (^)(TKKTon_kotlin_liteapi_tlLiteServerBlockTransactions * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("invoke(function:completionHandler_____________:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)invokeFunction:(TKKTon_kotlin_liteapi_tlLiteServerLookupBlock *)function waitMasterchainSeqno:(int32_t)waitMasterchainSeqno completionHandler___:(void (^)(TKKTon_kotlin_liteapi_tlLiteServerBlockHeader * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("invoke(function:waitMasterchainSeqno:completionHandler___:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)invokeFunction:(TKKTon_kotlin_liteapi_tlLiteServerRunSmcMethod *)function completionHandler______________:(void (^)(TKKTon_kotlin_liteapi_tlLiteServerRunMethodResult * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("invoke(function:completionHandler______________:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)invokeFunction:(TKKTon_kotlin_liteapi_tlLiteServerSendMessage *)function completionHandler_______________:(void (^)(TKKTon_kotlin_liteapi_tlLiteServerSendMsgStatus * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("invoke(function:completionHandler_______________:)")));
@end

__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteApiClient")))
@protocol TKKTon_kotlin_liteapi_tlLiteApiClient <TKKTon_kotlin_liteapi_tlLiteApi>
@required

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)sendQueryQueryCodec:(id<TKKTon_kotlin_tlTlCodec>)queryCodec answerCodec:(id<TKKTon_kotlin_tlTlCodec>)answerCodec query:(id _Nullable)query waitMasterchainSeqno:(int32_t)waitMasterchainSeqno completionHandler:(void (^)(id _Nullable_result, NSError * _Nullable))completionHandler __attribute__((swift_name("sendQuery(queryCodec:answerCodec:query:waitMasterchainSeqno:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)sendRawQueryQuery:(TKKKtor_ioByteReadPacket *)query completionHandler:(void (^)(TKKKtor_ioByteReadPacket * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("sendRawQuery(query:completionHandler:)")));
@end

__attribute__((swift_name("Ton_kotlin_cryptoEncryptor")))
@protocol TKKTon_kotlin_cryptoEncryptor
@required
- (TKKKotlinByteArray *)encryptData:(TKKKotlinByteArray *)data __attribute__((swift_name("encrypt(data:)")));
- (BOOL)verifyMessage:(TKKKotlinByteArray *)message signature:(TKKKotlinByteArray * _Nullable)signature __attribute__((swift_name("verify(message:signature:)")));
@end

__attribute__((swift_name("Ton_kotlin_tlTlObject")))
@protocol TKKTon_kotlin_tlTlObject
@required
- (TKKKotlinByteArray *)hash_ __attribute__((swift_name("hash_()")));
- (id<TKKTon_kotlin_tlTlCodec>)tlCodec __attribute__((swift_name("tlCodec()")));
- (TKKKotlinByteArray *)toByteArray __attribute__((swift_name("toByteArray()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((swift_name("Ton_kotlin_tonapi_tlPublicKey")))
@protocol TKKTon_kotlin_tonapi_tlPublicKey <TKKTon_kotlin_cryptoEncryptor, TKKTon_kotlin_tlTlObject>
@required
- (TKKTon_kotlin_tonapi_tlAdnlIdShort *)toAdnlIdShort __attribute__((swift_name("toAdnlIdShort()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
 *   kotlinx.serialization.SerialName(value="adnl.id.short")
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_tonapi_tlAdnlIdShort")))
@interface TKKTon_kotlin_tonapi_tlAdnlIdShort : TKKBase <TKKKotlinComparable, TKKTon_kotlin_tlTlObject>
- (instancetype)initWithId:(TKKTon_kotlin_tlByteString *)id __attribute__((swift_name("init(id:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_tonapi_tlAdnlIdShortCompanion *companion __attribute__((swift_name("companion")));
- (int32_t)compareToOther:(TKKTon_kotlin_tonapi_tlAdnlIdShort *)other __attribute__((swift_name("compareTo(other:)")));
- (TKKTon_kotlin_tonapi_tlAdnlIdShort *)doCopyId:(TKKTon_kotlin_tlByteString *)id __attribute__((swift_name("doCopy(id:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (id<TKKTon_kotlin_tlTlCodec>)tlCodec __attribute__((swift_name("tlCodec()")));
- (NSString *)description __attribute__((swift_name("description()")));
- (BOOL)verifyNode:(TKKTon_kotlin_tonapi_tlOverlayNode *)node __attribute__((swift_name("verify(node:)")));
@property (readonly) TKKTon_kotlin_tlByteString *id __attribute__((swift_name("id")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable(with=NormalClass(value=org/ton/tl/ByteStringSerializer))
*/
__attribute__((swift_name("Ton_kotlin_tlByteString")))
@interface TKKTon_kotlin_tlByteString : TKKBase <TKKKotlinComparable, TKKKotlinCollection>
@property (class, readonly, getter=companion) TKKTon_kotlin_tlByteStringCompanion *companion __attribute__((swift_name("companion")));
- (int32_t)compareToOther:(TKKTon_kotlin_tlByteString *)other __attribute__((swift_name("compareTo(other:)")));
- (BOOL)containsElement:(TKKByte *)element __attribute__((swift_name("contains(element:)")));
- (BOOL)containsAllElements:(id)elements __attribute__((swift_name("containsAll(elements:)")));
- (TKKKotlinByteArray *)doCopyIntoDestination:(TKKKotlinByteArray *)destination destinationOffset:(int32_t)destinationOffset startIndex:(int32_t)startIndex endIndex:(int32_t)endIndex __attribute__((swift_name("doCopyInto(destination:destinationOffset:startIndex:endIndex:)")));
- (TKKTon_kotlin_tlByteString *)doCopyOfNewSize:(int32_t)newSize __attribute__((swift_name("doCopyOf(newSize:)")));
- (TKKTon_kotlin_tlByteString *)doCopyOfRangeFromIndex:(int32_t)fromIndex toIndex:(int32_t)toIndex __attribute__((swift_name("doCopyOfRange(fromIndex:toIndex:)")));
- (NSString *)decodeToString __attribute__((swift_name("decodeToString()")));
- (NSString *)encodeBase64 __attribute__((swift_name("encodeBase64()")));
- (NSString *)encodeHex __attribute__((swift_name("encodeHex()")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));

/**
 * @note annotations
 *   kotlin.jvm.JvmName(name="getByte")
*/
- (int8_t)getIndex__:(int32_t)index __attribute__((swift_name("get(index__:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (TKKTon_kotlin_tlByteString *)hashSha256 __attribute__((swift_name("hashSha256()")));
- (BOOL)isEmpty __attribute__((swift_name("isEmpty()")));
- (TKKKotlinByteIterator *)iterator __attribute__((swift_name("iterator()")));
- (TKKKotlinByteArray *)toByteArray __attribute__((swift_name("toByteArray()")));
- (TKKKotlinByteArray *)toByteArrayDestination:(TKKKotlinByteArray *)destination destinationOffset:(int32_t)destinationOffset startIndex:(int32_t)startIndex endIndex:(int32_t)endIndex __attribute__((swift_name("toByteArray(destination:destinationOffset:startIndex:endIndex:)")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) int32_t size __attribute__((swift_name("size")));
@end

__attribute__((swift_name("Ton_kotlin_tlTlDecoder")))
@protocol TKKTon_kotlin_tlTlDecoder
@required
- (id _Nullable)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (id _Nullable)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (id _Nullable)decodeByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decode(byteString:)")));
- (id _Nullable)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (id _Nullable)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (id _Nullable)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (id _Nullable)decodeBoxedByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decodeBoxed(byteString:)")));
- (id _Nullable)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
@end

__attribute__((swift_name("Ton_kotlin_tlTlEncoder")))
@protocol TKKTon_kotlin_tlTlEncoder
@required
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(id _Nullable)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(id _Nullable)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(id _Nullable)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(id _Nullable)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(id _Nullable)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKTon_kotlin_tlByteString *)encodeToByteStringValue:(id _Nullable)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteString(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(id _Nullable)value __attribute__((swift_name("hash(value:)")));
@end

__attribute__((swift_name("Ton_kotlin_tlTlCodec")))
@protocol TKKTon_kotlin_tlTlCodec <TKKTon_kotlin_tlTlDecoder, TKKTon_kotlin_tlTlEncoder>
@required
@end

__attribute__((swift_name("Ton_kotlin_tlTlConstructor")))
@interface TKKTon_kotlin_tlTlConstructor<T> : TKKBase <TKKTon_kotlin_tlTlCodec>
- (instancetype)initWithSchema:(NSString *)schema id:(TKKInt * _Nullable)id __attribute__((swift_name("init(schema:id:)"))) __attribute__((objc_designated_initializer));
- (T)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(T)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) int32_t id __attribute__((swift_name("id")));
@property (readonly) NSString *schema __attribute__((swift_name("schema")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_tonapi_tlPrivateKeyEd25519.Companion")))
@interface TKKTon_kotlin_tonapi_tlPrivateKeyEd25519Companion : TKKTon_kotlin_tlTlConstructor<TKKTon_kotlin_tonapi_tlPrivateKeyEd25519 *>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (instancetype)initWithSchema:(NSString *)schema id:(TKKInt * _Nullable)id __attribute__((swift_name("init(schema:id:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_tonapi_tlPrivateKeyEd25519Companion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_tonapi_tlPrivateKeyEd25519 *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_tonapi_tlPrivateKeyEd25519 *)value __attribute__((swift_name("encode(writer:value:)")));

/**
 * @note annotations
 *   kotlin.jvm.JvmStatic
*/
- (TKKTon_kotlin_tonapi_tlPrivateKeyEd25519 *)generateRandom:(TKKKotlinRandom *)random __attribute__((swift_name("generate(random:)")));

/**
 * @note annotations
 *   kotlin.jvm.JvmStatic
*/
- (TKKTon_kotlin_tonapi_tlPrivateKeyEd25519 *)ofByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("of(byteArray:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));

/**
 * @note annotations
 *   kotlin.jvm.JvmStatic
*/
- (TKKTon_kotlin_tlTlConstructor<TKKTon_kotlin_tonapi_tlPrivateKeyEd25519 *> *)tlConstructor __attribute__((swift_name("tlConstructor()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
 *   kotlinx.serialization.SerialName(value="pub.ed25519")
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_tonapi_tlPublicKeyEd25519")))
@interface TKKTon_kotlin_tonapi_tlPublicKeyEd25519 : TKKBase <TKKTon_kotlin_tonapi_tlPublicKey, TKKTon_kotlin_cryptoEncryptor>
- (instancetype)initWithByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("init(byteArray:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithKey:(TKKTon_kotlin_tlByteString *)key __attribute__((swift_name("init(key:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_tonapi_tlPublicKeyEd25519Companion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_tonapi_tlPublicKeyEd25519 *)doCopyKey:(TKKTon_kotlin_tlByteString *)key __attribute__((swift_name("doCopy(key:)")));
- (TKKKotlinByteArray *)encryptData:(TKKKotlinByteArray *)data __attribute__((swift_name("encrypt(data:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (TKKTon_kotlin_tonapi_tlAdnlIdShort *)toAdnlIdShort __attribute__((swift_name("toAdnlIdShort()")));
- (NSString *)description __attribute__((swift_name("description()")));
- (BOOL)verifyMessage:(TKKKotlinByteArray *)message signature:(TKKKotlinByteArray * _Nullable)signature __attribute__((swift_name("verify(message:signature:)")));
@property (readonly) TKKTon_kotlin_tlByteString *key __attribute__((swift_name("key")));
@end

__attribute__((swift_name("Kotlinx_serialization_coreEncoder")))
@protocol TKKKotlinx_serialization_coreEncoder
@required
- (id<TKKKotlinx_serialization_coreCompositeEncoder>)beginCollectionDescriptor:(id<TKKKotlinx_serialization_coreSerialDescriptor>)descriptor collectionSize:(int32_t)collectionSize __attribute__((swift_name("beginCollection(descriptor:collectionSize:)")));
- (id<TKKKotlinx_serialization_coreCompositeEncoder>)beginStructureDescriptor:(id<TKKKotlinx_serialization_coreSerialDescriptor>)descriptor __attribute__((swift_name("beginStructure(descriptor:)")));
- (void)encodeBooleanValue:(BOOL)value __attribute__((swift_name("encodeBoolean(value:)")));
- (void)encodeByteValue:(int8_t)value __attribute__((swift_name("encodeByte(value:)")));
- (void)encodeCharValue:(unichar)value __attribute__((swift_name("encodeChar(value:)")));
- (void)encodeDoubleValue:(double)value __attribute__((swift_name("encodeDouble(value:)")));
- (void)encodeEnumEnumDescriptor:(id<TKKKotlinx_serialization_coreSerialDescriptor>)enumDescriptor index:(int32_t)index __attribute__((swift_name("encodeEnum(enumDescriptor:index:)")));
- (void)encodeFloatValue:(float)value __attribute__((swift_name("encodeFloat(value:)")));
- (id<TKKKotlinx_serialization_coreEncoder>)encodeInlineDescriptor:(id<TKKKotlinx_serialization_coreSerialDescriptor>)descriptor __attribute__((swift_name("encodeInline(descriptor:)")));
- (void)encodeIntValue:(int32_t)value __attribute__((swift_name("encodeInt(value:)")));
- (void)encodeLongValue:(int64_t)value __attribute__((swift_name("encodeLong(value:)")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (void)encodeNotNullMark __attribute__((swift_name("encodeNotNullMark()")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (void)encodeNull __attribute__((swift_name("encodeNull()")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (void)encodeNullableSerializableValueSerializer:(id<TKKKotlinx_serialization_coreSerializationStrategy>)serializer value:(id _Nullable)value __attribute__((swift_name("encodeNullableSerializableValue(serializer:value:)")));
- (void)encodeSerializableValueSerializer:(id<TKKKotlinx_serialization_coreSerializationStrategy>)serializer value:(id _Nullable)value __attribute__((swift_name("encodeSerializableValue(serializer:value:)")));
- (void)encodeShortValue:(int16_t)value __attribute__((swift_name("encodeShort(value:)")));
- (void)encodeStringValue:(NSString *)value __attribute__((swift_name("encodeString(value:)")));
@property (readonly) TKKKotlinx_serialization_coreSerializersModule *serializersModule __attribute__((swift_name("serializersModule")));
@end

__attribute__((swift_name("Kotlinx_serialization_coreSerialDescriptor")))
@protocol TKKKotlinx_serialization_coreSerialDescriptor
@required

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (NSArray<id<TKKKotlinAnnotation>> *)getElementAnnotationsIndex:(int32_t)index __attribute__((swift_name("getElementAnnotations(index:)")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (id<TKKKotlinx_serialization_coreSerialDescriptor>)getElementDescriptorIndex:(int32_t)index __attribute__((swift_name("getElementDescriptor(index:)")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (int32_t)getElementIndexName:(NSString *)name __attribute__((swift_name("getElementIndex(name:)")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (NSString *)getElementNameIndex:(int32_t)index __attribute__((swift_name("getElementName(index:)")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (BOOL)isElementOptionalIndex:(int32_t)index __attribute__((swift_name("isElementOptional(index:)")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
@property (readonly) NSArray<id<TKKKotlinAnnotation>> *annotations __attribute__((swift_name("annotations")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
@property (readonly) int32_t elementsCount __attribute__((swift_name("elementsCount")));
@property (readonly) BOOL isInline __attribute__((swift_name("isInline")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
@property (readonly) BOOL isNullable __attribute__((swift_name("isNullable")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
@property (readonly) TKKKotlinx_serialization_coreSerialKind *kind __attribute__((swift_name("kind")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
@property (readonly) NSString *serialName __attribute__((swift_name("serialName")));
@end

__attribute__((swift_name("Kotlinx_serialization_coreDecoder")))
@protocol TKKKotlinx_serialization_coreDecoder
@required
- (id<TKKKotlinx_serialization_coreCompositeDecoder>)beginStructureDescriptor:(id<TKKKotlinx_serialization_coreSerialDescriptor>)descriptor __attribute__((swift_name("beginStructure(descriptor:)")));
- (BOOL)decodeBoolean __attribute__((swift_name("decodeBoolean()")));
- (int8_t)decodeByte __attribute__((swift_name("decodeByte()")));
- (unichar)decodeChar __attribute__((swift_name("decodeChar()")));
- (double)decodeDouble __attribute__((swift_name("decodeDouble()")));
- (int32_t)decodeEnumEnumDescriptor:(id<TKKKotlinx_serialization_coreSerialDescriptor>)enumDescriptor __attribute__((swift_name("decodeEnum(enumDescriptor:)")));
- (float)decodeFloat __attribute__((swift_name("decodeFloat()")));
- (id<TKKKotlinx_serialization_coreDecoder>)decodeInlineDescriptor:(id<TKKKotlinx_serialization_coreSerialDescriptor>)descriptor __attribute__((swift_name("decodeInline(descriptor:)")));
- (int32_t)decodeInt __attribute__((swift_name("decodeInt()")));
- (int64_t)decodeLong __attribute__((swift_name("decodeLong()")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (BOOL)decodeNotNullMark __attribute__((swift_name("decodeNotNullMark()")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (TKKKotlinNothing * _Nullable)decodeNull __attribute__((swift_name("decodeNull()")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (id _Nullable)decodeNullableSerializableValueDeserializer:(id<TKKKotlinx_serialization_coreDeserializationStrategy>)deserializer __attribute__((swift_name("decodeNullableSerializableValue(deserializer:)")));
- (id _Nullable)decodeSerializableValueDeserializer:(id<TKKKotlinx_serialization_coreDeserializationStrategy>)deserializer __attribute__((swift_name("decodeSerializableValue(deserializer:)")));
- (int16_t)decodeShort __attribute__((swift_name("decodeShort()")));
- (NSString *)decodeString __attribute__((swift_name("decodeString()")));
@property (readonly) TKKKotlinx_serialization_coreSerializersModule *serializersModule __attribute__((swift_name("serializersModule")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("KotlinBooleanArray")))
@interface TKKKotlinBooleanArray : TKKBase
+ (instancetype)arrayWithSize:(int32_t)size __attribute__((swift_name("init(size:)")));
+ (instancetype)arrayWithSize:(int32_t)size init:(TKKBoolean *(^)(TKKInt *))init __attribute__((swift_name("init(size:init:)")));
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (BOOL)getIndex:(int32_t)index __attribute__((swift_name("get(index:)")));
- (TKKKotlinBooleanIterator *)iterator __attribute__((swift_name("iterator()")));
- (void)setIndex:(int32_t)index value:(BOOL)value __attribute__((swift_name("set(index:value:)")));
@property (readonly) int32_t size __attribute__((swift_name("size")));
@end

__attribute__((swift_name("KotlinIntProgression")))
@interface TKKKotlinIntProgression : TKKBase <TKKKotlinIterable>
@property (class, readonly, getter=companion) TKKKotlinIntProgressionCompanion *companion __attribute__((swift_name("companion")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (BOOL)isEmpty __attribute__((swift_name("isEmpty()")));
- (TKKKotlinIntIterator *)iterator __attribute__((swift_name("iterator()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) int32_t first __attribute__((swift_name("first")));
@property (readonly) int32_t last __attribute__((swift_name("last")));
@property (readonly) int32_t step __attribute__((swift_name("step")));
@end

__attribute__((swift_name("KotlinClosedRange")))
@protocol TKKKotlinClosedRange
@required
- (BOOL)containsValue:(id)value __attribute__((swift_name("contains(value:)")));
- (BOOL)isEmpty __attribute__((swift_name("isEmpty()")));
@property (readonly) id endInclusive __attribute__((swift_name("endInclusive")));
@property (readonly) id start __attribute__((swift_name("start")));
@end


/**
 * @note annotations
 *   kotlin.SinceKotlin(version="1.9")
*/
__attribute__((swift_name("KotlinOpenEndRange")))
@protocol TKKKotlinOpenEndRange
@required
- (BOOL)containsValue_:(id)value __attribute__((swift_name("contains(value_:)")));
- (BOOL)isEmpty __attribute__((swift_name("isEmpty()")));
@property (readonly) id endExclusive __attribute__((swift_name("endExclusive")));
@property (readonly) id start __attribute__((swift_name("start")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("KotlinIntRange")))
@interface TKKKotlinIntRange : TKKKotlinIntProgression <TKKKotlinClosedRange, TKKKotlinOpenEndRange>
- (instancetype)initWithStart:(int32_t)start endInclusive:(int32_t)endInclusive __attribute__((swift_name("init(start:endInclusive:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKKotlinIntRangeCompanion *companion __attribute__((swift_name("companion")));
- (BOOL)containsValue:(TKKInt *)value __attribute__((swift_name("contains(value:)")));
- (BOOL)containsValue_:(TKKInt *)value __attribute__((swift_name("contains(value_:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (BOOL)isEmpty __attribute__((swift_name("isEmpty()")));
- (NSString *)description __attribute__((swift_name("description()")));

/**
 * @note annotations
 *   kotlin.SinceKotlin(version="1.9")
*/
@property (readonly) TKKInt *endExclusive __attribute__((swift_name("endExclusive"))) __attribute__((deprecated("Can throw an exception when it's impossible to represent the value with Int type, for example, when the range includes MAX_VALUE. It's recommended to use 'endInclusive' property that doesn't throw.")));
@property (readonly) TKKInt *endInclusive __attribute__((swift_name("endInclusive")));
@property (readonly) TKKInt *start __attribute__((swift_name("start")));
@end

__attribute__((swift_name("Ton_kotlin_bitstringMutableBitString")))
@protocol TKKTon_kotlin_bitstringMutableBitString <TKKTon_kotlin_bitstringBitString>
@required
- (BOOL)setIndex:(int32_t)index element:(BOOL)element __attribute__((swift_name("set(index:element:)")));
- (void)setIndex:(int32_t)index bit:(int32_t)bit __attribute__((swift_name("set(index:bit:)")));
@end

__attribute__((swift_name("KotlinCharSequence")))
@protocol TKKKotlinCharSequence
@required
- (unichar)getIndex___:(int32_t)index __attribute__((swift_name("get(index___:)")));
- (id)subSequenceStartIndex:(int32_t)startIndex endIndex:(int32_t)endIndex __attribute__((swift_name("subSequence(startIndex:endIndex:)")));
@property (readonly) int32_t length __attribute__((swift_name("length")));
@end

__attribute__((swift_name("KotlinAppendable")))
@protocol TKKKotlinAppendable
@required
- (id<TKKKotlinAppendable>)appendValue:(unichar)value __attribute__((swift_name("append(value:)")));
- (id<TKKKotlinAppendable>)appendValue_:(id _Nullable)value __attribute__((swift_name("append(value_:)")));
- (id<TKKKotlinAppendable>)appendValue:(id _Nullable)value startIndex:(int32_t)startIndex endIndex:(int32_t)endIndex __attribute__((swift_name("append(value:startIndex:endIndex:)")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("KotlinStringBuilder")))
@interface TKKKotlinStringBuilder : TKKBase <TKKKotlinCharSequence, TKKKotlinAppendable>
- (instancetype)init __attribute__((swift_name("init()"))) __attribute__((objc_designated_initializer));
+ (instancetype)new __attribute__((availability(swift, unavailable, message="use object initializers instead")));
- (instancetype)initWithCapacity:(int32_t)capacity __attribute__((swift_name("init(capacity:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithContent:(NSString *)content __attribute__((swift_name("init(content:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithContent_:(id)content __attribute__((swift_name("init(content_:)"))) __attribute__((objc_designated_initializer));
- (TKKKotlinStringBuilder *)appendValue__:(id _Nullable)value __attribute__((swift_name("append(value__:)")));
- (TKKKotlinStringBuilder *)appendValue___:(BOOL)value __attribute__((swift_name("append(value___:)")));
- (TKKKotlinStringBuilder *)appendValue____:(int8_t)value __attribute__((swift_name("append(value____:)")));
- (TKKKotlinStringBuilder *)appendValue:(unichar)value __attribute__((swift_name("append(value:)")));
- (TKKKotlinStringBuilder *)appendValue_____:(TKKKotlinCharArray *)value __attribute__((swift_name("append(value_____:)")));
- (TKKKotlinStringBuilder *)appendValue_:(id _Nullable)value __attribute__((swift_name("append(value_:)")));
- (TKKKotlinStringBuilder *)appendValue:(id _Nullable)value startIndex:(int32_t)startIndex endIndex:(int32_t)endIndex __attribute__((swift_name("append(value:startIndex:endIndex:)")));
- (TKKKotlinStringBuilder *)appendValue______:(double)value __attribute__((swift_name("append(value______:)")));
- (TKKKotlinStringBuilder *)appendValue_______:(float)value __attribute__((swift_name("append(value_______:)")));
- (TKKKotlinStringBuilder *)appendValue________:(int32_t)value __attribute__((swift_name("append(value________:)")));
- (TKKKotlinStringBuilder *)appendValue_________:(int64_t)value __attribute__((swift_name("append(value_________:)")));
- (TKKKotlinStringBuilder *)appendValue__________:(int16_t)value __attribute__((swift_name("append(value__________:)")));
- (TKKKotlinStringBuilder *)appendValue___________:(NSString * _Nullable)value __attribute__((swift_name("append(value___________:)")));

/**
 * @note annotations
 *   kotlin.SinceKotlin(version="1.4")
*/
- (TKKKotlinStringBuilder *)appendRangeValue:(TKKKotlinCharArray *)value startIndex:(int32_t)startIndex endIndex:(int32_t)endIndex __attribute__((swift_name("appendRange(value:startIndex:endIndex:)")));

/**
 * @note annotations
 *   kotlin.SinceKotlin(version="1.4")
*/
- (TKKKotlinStringBuilder *)appendRangeValue:(id)value startIndex:(int32_t)startIndex endIndex_:(int32_t)endIndex __attribute__((swift_name("appendRange(value:startIndex:endIndex_:)")));
- (int32_t)capacity __attribute__((swift_name("capacity()")));

/**
 * @note annotations
 *   kotlin.SinceKotlin(version="1.4")
*/
- (TKKKotlinStringBuilder *)deleteAtIndex:(int32_t)index __attribute__((swift_name("deleteAt(index:)")));

/**
 * @note annotations
 *   kotlin.SinceKotlin(version="1.4")
*/
- (TKKKotlinStringBuilder *)deleteRangeStartIndex:(int32_t)startIndex endIndex:(int32_t)endIndex __attribute__((swift_name("deleteRange(startIndex:endIndex:)")));
- (void)ensureCapacityMinimumCapacity:(int32_t)minimumCapacity __attribute__((swift_name("ensureCapacity(minimumCapacity:)")));
- (unichar)getIndex___:(int32_t)index __attribute__((swift_name("get(index___:)")));

/**
 * @note annotations
 *   kotlin.SinceKotlin(version="1.4")
*/
- (int32_t)indexOfString:(NSString *)string __attribute__((swift_name("indexOf(string:)")));

/**
 * @note annotations
 *   kotlin.SinceKotlin(version="1.4")
*/
- (int32_t)indexOfString:(NSString *)string startIndex:(int32_t)startIndex __attribute__((swift_name("indexOf(string:startIndex:)")));
- (TKKKotlinStringBuilder *)insertIndex:(int32_t)index value:(id _Nullable)value __attribute__((swift_name("insert(index:value:)")));
- (TKKKotlinStringBuilder *)insertIndex:(int32_t)index value_:(BOOL)value __attribute__((swift_name("insert(index:value_:)")));
- (TKKKotlinStringBuilder *)insertIndex:(int32_t)index value__:(int8_t)value __attribute__((swift_name("insert(index:value__:)")));
- (TKKKotlinStringBuilder *)insertIndex:(int32_t)index value___:(unichar)value __attribute__((swift_name("insert(index:value___:)")));
- (TKKKotlinStringBuilder *)insertIndex:(int32_t)index value____:(TKKKotlinCharArray *)value __attribute__((swift_name("insert(index:value____:)")));
- (TKKKotlinStringBuilder *)insertIndex:(int32_t)index value_____:(id _Nullable)value __attribute__((swift_name("insert(index:value_____:)")));
- (TKKKotlinStringBuilder *)insertIndex:(int32_t)index value______:(double)value __attribute__((swift_name("insert(index:value______:)")));
- (TKKKotlinStringBuilder *)insertIndex:(int32_t)index value_______:(float)value __attribute__((swift_name("insert(index:value_______:)")));
- (TKKKotlinStringBuilder *)insertIndex:(int32_t)index value________:(int32_t)value __attribute__((swift_name("insert(index:value________:)")));
- (TKKKotlinStringBuilder *)insertIndex:(int32_t)index value_________:(int64_t)value __attribute__((swift_name("insert(index:value_________:)")));
- (TKKKotlinStringBuilder *)insertIndex:(int32_t)index value__________:(int16_t)value __attribute__((swift_name("insert(index:value__________:)")));
- (TKKKotlinStringBuilder *)insertIndex:(int32_t)index value___________:(NSString * _Nullable)value __attribute__((swift_name("insert(index:value___________:)")));

/**
 * @note annotations
 *   kotlin.SinceKotlin(version="1.4")
*/
- (TKKKotlinStringBuilder *)insertRangeIndex:(int32_t)index value:(TKKKotlinCharArray *)value startIndex:(int32_t)startIndex endIndex:(int32_t)endIndex __attribute__((swift_name("insertRange(index:value:startIndex:endIndex:)")));

/**
 * @note annotations
 *   kotlin.SinceKotlin(version="1.4")
*/
- (TKKKotlinStringBuilder *)insertRangeIndex:(int32_t)index value:(id)value startIndex:(int32_t)startIndex endIndex_:(int32_t)endIndex __attribute__((swift_name("insertRange(index:value:startIndex:endIndex_:)")));

/**
 * @note annotations
 *   kotlin.SinceKotlin(version="1.4")
*/
- (int32_t)lastIndexOfString:(NSString *)string __attribute__((swift_name("lastIndexOf(string:)")));

/**
 * @note annotations
 *   kotlin.SinceKotlin(version="1.4")
*/
- (int32_t)lastIndexOfString:(NSString *)string startIndex:(int32_t)startIndex __attribute__((swift_name("lastIndexOf(string:startIndex:)")));
- (TKKKotlinStringBuilder *)reverse __attribute__((swift_name("reverse()")));
- (void)setIndex:(int32_t)index value:(unichar)value __attribute__((swift_name("set(index:value:)")));
- (void)setLengthNewLength:(int32_t)newLength __attribute__((swift_name("setLength(newLength:)")));

/**
 * @note annotations
 *   kotlin.SinceKotlin(version="1.4")
*/
- (TKKKotlinStringBuilder *)setRangeStartIndex:(int32_t)startIndex endIndex:(int32_t)endIndex value:(NSString *)value __attribute__((swift_name("setRange(startIndex:endIndex:value:)")));
- (id)subSequenceStartIndex:(int32_t)startIndex endIndex:(int32_t)endIndex __attribute__((swift_name("subSequence(startIndex:endIndex:)")));

/**
 * @note annotations
 *   kotlin.SinceKotlin(version="1.4")
*/
- (NSString *)substringStartIndex:(int32_t)startIndex __attribute__((swift_name("substring(startIndex:)")));
- (NSString *)substringStartIndex:(int32_t)startIndex endIndex:(int32_t)endIndex __attribute__((swift_name("substring(startIndex:endIndex:)")));

/**
 * @note annotations
 *   kotlin.SinceKotlin(version="1.4")
*/
- (void)toCharArrayDestination:(TKKKotlinCharArray *)destination destinationOffset:(int32_t)destinationOffset startIndex:(int32_t)startIndex endIndex:(int32_t)endIndex __attribute__((swift_name("toCharArray(destination:destinationOffset:startIndex:endIndex:)")));
- (NSString *)description __attribute__((swift_name("description()")));
- (void)trimToSize __attribute__((swift_name("trimToSize()")));
@property (readonly) int32_t length __attribute__((swift_name("length")));
@end

__attribute__((swift_name("Ton_kotlin_tlbTlbProvider")))
@protocol TKKTon_kotlin_tlbTlbProvider <TKKTon_kotlin_tlbTlbCodec>
@required
@end

__attribute__((swift_name("Ton_kotlin_tlbTlbConstructorProvider")))
@protocol TKKTon_kotlin_tlbTlbConstructorProvider <TKKTon_kotlin_tlbTlbProvider, TKKTon_kotlin_tlbTlbCodec>
@required
- (TKKTon_kotlin_tlbTlbConstructor<id> *)tlbConstructor __attribute__((swift_name("tlbConstructor()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_block_tlbAnycast.Companion")))
@interface TKKTon_kotlin_block_tlbAnycastCompanion : TKKBase <TKKTon_kotlin_tlbTlbConstructorProvider>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_block_tlbAnycastCompanion *shared __attribute__((swift_name("shared")));
- (id<TKKTon_kotlin_tvmCell>)createCellValue:(TKKTon_kotlin_block_tlbAnycast *)value __attribute__((swift_name("createCell(value:)")));
- (TKKTon_kotlin_block_tlbAnycast *)loadTlbCell:(id<TKKTon_kotlin_tvmCell>)cell __attribute__((swift_name("loadTlb(cell:)")));
- (TKKTon_kotlin_block_tlbAnycast *)loadTlbCellSlice:(id<TKKTon_kotlin_tvmCellSlice>)cellSlice __attribute__((swift_name("loadTlb(cellSlice:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
- (void)storeTlbCellBuilder:(id<TKKTon_kotlin_tvmCellBuilder>)cellBuilder value:(TKKTon_kotlin_block_tlbAnycast *)value __attribute__((swift_name("storeTlb(cellBuilder:value:)")));
- (TKKTon_kotlin_tlbTlbConstructor<TKKTon_kotlin_block_tlbAnycast *> *)tlbConstructor __attribute__((swift_name("tlbConstructor()")));
@end

__attribute__((swift_name("Ton_kotlin_tvmCellBuilder")))
@protocol TKKTon_kotlin_tvmCellBuilder
@required
- (id<TKKTon_kotlin_tvmCell>)build __attribute__((swift_name("build()")));
- (id<TKKTon_kotlin_tvmCell>)endCell __attribute__((swift_name("endCell()")));
- (id<TKKTon_kotlin_tvmCellBuilder>)storeBitBit:(BOOL)bit __attribute__((swift_name("storeBit(bit:)")));
- (id<TKKTon_kotlin_tvmCellBuilder>)storeBitsBits:(TKKKotlinBooleanArray *)bits __attribute__((swift_name("storeBits(bits:)")));
- (id<TKKTon_kotlin_tvmCellBuilder>)storeBitsBits_:(id)bits __attribute__((swift_name("storeBits(bits_:)")));
- (id<TKKTon_kotlin_tvmCellBuilder>)storeBitsBits__:(id)bits __attribute__((swift_name("storeBits(bits__:)")));
- (id<TKKTon_kotlin_tvmCellBuilder>)storeBitsBits___:(id<TKKTon_kotlin_bitstringBitString>)bits __attribute__((swift_name("storeBits(bits___:)")));
- (id<TKKTon_kotlin_tvmCellBuilder>)storeByteByte:(int8_t)byte __attribute__((swift_name("storeByte(byte:)")));
- (id<TKKTon_kotlin_tvmCellBuilder>)storeBytesByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("storeBytes(byteArray:)")));
- (id<TKKTon_kotlin_tvmCellBuilder>)storeBytesByteArray:(TKKKotlinByteArray *)byteArray length:(int32_t)length __attribute__((swift_name("storeBytes(byteArray:length:)")));
- (id<TKKTon_kotlin_tvmCellBuilder>)storeIntValue:(int8_t)value length:(int32_t)length __attribute__((swift_name("storeInt(value:length:)")));
- (id<TKKTon_kotlin_tvmCellBuilder>)storeIntValue:(int32_t)value length_:(int32_t)length __attribute__((swift_name("storeInt(value:length_:)")));
- (id<TKKTon_kotlin_tvmCellBuilder>)storeIntValue:(int64_t)value length__:(int32_t)length __attribute__((swift_name("storeInt(value:length__:)")));
- (id<TKKTon_kotlin_tvmCellBuilder>)storeIntValue:(int16_t)value length___:(int32_t)length __attribute__((swift_name("storeInt(value:length___:)")));
- (id<TKKTon_kotlin_tvmCellBuilder>)storeIntValue:(TKKTon_kotlin_bigintBigInt *)value length____:(int32_t)length __attribute__((swift_name("storeInt(value:length____:)")));
- (id<TKKTon_kotlin_tvmCellBuilder>)storeRefRef:(id<TKKTon_kotlin_tvmCell>)ref __attribute__((swift_name("storeRef(ref:)")));
- (id<TKKTon_kotlin_tvmCellBuilder>)storeRefsRefs:(TKKKotlinArray<id<TKKTon_kotlin_tvmCell>> *)refs __attribute__((swift_name("storeRefs(refs:)")));
- (id<TKKTon_kotlin_tvmCellBuilder>)storeRefsRefs_:(id)refs __attribute__((swift_name("storeRefs(refs_:)")));
- (id<TKKTon_kotlin_tvmCellBuilder>)storeRefsRefs__:(id)refs __attribute__((swift_name("storeRefs(refs__:)")));
- (id<TKKTon_kotlin_tvmCellBuilder>)storeSliceSlice:(id<TKKTon_kotlin_tvmCellSlice>)slice __attribute__((swift_name("storeSlice(slice:)")));
- (id<TKKTon_kotlin_tvmCellBuilder>)storeUIntValue:(int8_t)value length:(int32_t)length __attribute__((swift_name("storeUInt(value:length:)")));
- (id<TKKTon_kotlin_tvmCellBuilder>)storeUIntValue:(int32_t)value length_:(int32_t)length __attribute__((swift_name("storeUInt(value:length_:)")));
- (id<TKKTon_kotlin_tvmCellBuilder>)storeUIntValue:(int64_t)value length__:(int32_t)length __attribute__((swift_name("storeUInt(value:length__:)")));
- (id<TKKTon_kotlin_tvmCellBuilder>)storeUIntValue:(int16_t)value length___:(int32_t)length __attribute__((swift_name("storeUInt(value:length___:)")));
- (id<TKKTon_kotlin_tvmCellBuilder>)storeUIntValue:(TKKTon_kotlin_bigintBigInt *)value length____:(int32_t)length __attribute__((swift_name("storeUInt(value:length____:)")));
- (id<TKKTon_kotlin_tvmCellBuilder>)storeUInt16Value:(uint16_t)value __attribute__((swift_name("storeUInt16(value:)")));
- (id<TKKTon_kotlin_tvmCellBuilder>)storeUInt32Value:(uint32_t)value __attribute__((swift_name("storeUInt32(value:)")));
- (id<TKKTon_kotlin_tvmCellBuilder>)storeUInt64Value:(uint64_t)value __attribute__((swift_name("storeUInt64(value:)")));
- (id<TKKTon_kotlin_tvmCellBuilder>)storeUInt8Value:(uint8_t)value __attribute__((swift_name("storeUInt8(value:)")));
- (id<TKKTon_kotlin_tvmCellBuilder>)storeUIntLeqValue:(int8_t)value max:(int8_t)max __attribute__((swift_name("storeUIntLeq(value:max:)")));
- (id<TKKTon_kotlin_tvmCellBuilder>)storeUIntLeqValue:(int32_t)value max_:(int32_t)max __attribute__((swift_name("storeUIntLeq(value:max_:)")));
- (id<TKKTon_kotlin_tvmCellBuilder>)storeUIntLeqValue:(int64_t)value max__:(int64_t)max __attribute__((swift_name("storeUIntLeq(value:max__:)")));
- (id<TKKTon_kotlin_tvmCellBuilder>)storeUIntLeqValue:(int16_t)value max___:(int16_t)max __attribute__((swift_name("storeUIntLeq(value:max___:)")));
- (id<TKKTon_kotlin_tvmCellBuilder>)storeUIntLeqValue:(TKKTon_kotlin_bigintBigInt *)value max____:(TKKTon_kotlin_bigintBigInt *)max __attribute__((swift_name("storeUIntLeq(value:max____:)")));
- (id<TKKTon_kotlin_tvmCellBuilder>)storeUIntLesValue:(int8_t)value max:(int8_t)max __attribute__((swift_name("storeUIntLes(value:max:)")));
- (id<TKKTon_kotlin_tvmCellBuilder>)storeUIntLesValue:(int32_t)value max_:(int32_t)max __attribute__((swift_name("storeUIntLes(value:max_:)")));
- (id<TKKTon_kotlin_tvmCellBuilder>)storeUIntLesValue:(int64_t)value max__:(int64_t)max __attribute__((swift_name("storeUIntLes(value:max__:)")));
- (id<TKKTon_kotlin_tvmCellBuilder>)storeUIntLesValue:(int16_t)value max___:(int16_t)max __attribute__((swift_name("storeUIntLes(value:max___:)")));
- (id<TKKTon_kotlin_tvmCellBuilder>)storeUIntLesValue:(TKKTon_kotlin_bigintBigInt *)value max____:(TKKTon_kotlin_bigintBigInt *)max __attribute__((swift_name("storeUIntLes(value:max____:)")));
@property id<TKKTon_kotlin_bitstringMutableBitString> bits __attribute__((swift_name("bits")));
@property (readonly) int32_t bitsPosition __attribute__((swift_name("bitsPosition")));
@property BOOL isExotic __attribute__((swift_name("isExotic")));
@property (setter=setLevelMask:) id _Nullable levelMask_ __attribute__((swift_name("levelMask_")));
@property NSMutableArray<id<TKKTon_kotlin_tvmCell>> *refs __attribute__((swift_name("refs")));
@property (readonly) int32_t remainingBits __attribute__((swift_name("remainingBits")));
@end

__attribute__((swift_name("Ton_kotlin_tvmCellSlice")))
@protocol TKKTon_kotlin_tvmCellSlice
@required
- (id<TKKTon_kotlin_bitstringBitString>)component1_ __attribute__((swift_name("component1_()")));
- (NSArray<id<TKKTon_kotlin_tvmCell>> *)component2_ __attribute__((swift_name("component2_()")));
- (void)endParse __attribute__((swift_name("endParse()")));
- (BOOL)isEmpty __attribute__((swift_name("isEmpty()")));
- (BOOL)loadBit __attribute__((swift_name("loadBit()")));
- (id<TKKTon_kotlin_bitstringBitString>)loadBitsLength:(int32_t)length __attribute__((swift_name("loadBits(length:)")));
- (TKKTon_kotlin_bigintBigInt *)loadIntLength:(int32_t)length __attribute__((swift_name("loadInt(length:)")));
- (id<TKKTon_kotlin_tvmCell>)loadRef __attribute__((swift_name("loadRef()")));
- (NSArray<id<TKKTon_kotlin_tvmCell>> *)loadRefsCount:(int32_t)count __attribute__((swift_name("loadRefs(count:)")));
- (int64_t)loadTinyIntLength:(int32_t)length __attribute__((swift_name("loadTinyInt(length:)")));
- (TKKTon_kotlin_bigintBigInt *)loadUIntLength:(int32_t)length __attribute__((swift_name("loadUInt(length:)")));
- (uint16_t)loadUInt16 __attribute__((swift_name("loadUInt16()")));
- (uint32_t)loadUInt32 __attribute__((swift_name("loadUInt32()")));
- (uint64_t)loadUInt64 __attribute__((swift_name("loadUInt64()")));
- (uint8_t)loadUInt8 __attribute__((swift_name("loadUInt8()")));
- (TKKTon_kotlin_bigintBigInt *)loadUIntLeqMax:(int32_t)max __attribute__((swift_name("loadUIntLeq(max:)")));
- (TKKTon_kotlin_bigintBigInt *)loadUIntLesMax:(int32_t)max __attribute__((swift_name("loadUIntLes(max:)")));
- (BOOL)preloadBit __attribute__((swift_name("preloadBit()")));
- (id<TKKTon_kotlin_bitstringBitString>)preloadBitsLength:(int32_t)length __attribute__((swift_name("preloadBits(length:)")));
- (TKKTon_kotlin_bigintBigInt *)preloadIntLength:(int32_t)length __attribute__((swift_name("preloadInt(length:)")));
- (id<TKKTon_kotlin_tvmCell>)preloadRef __attribute__((swift_name("preloadRef()")));
- (id _Nullable)preloadRefCellSlice:(id _Nullable (^)(id<TKKTon_kotlin_tvmCellSlice>))cellSlice __attribute__((swift_name("preloadRef(cellSlice:)")));
- (NSArray<id<TKKTon_kotlin_tvmCell>> *)preloadRefsCount:(int32_t)count __attribute__((swift_name("preloadRefs(count:)")));
- (int64_t)preloadTinyIntLength:(int32_t)length __attribute__((swift_name("preloadTinyInt(length:)")));
- (TKKTon_kotlin_bigintBigInt *)preloadUIntLength:(int32_t)length __attribute__((swift_name("preloadUInt(length:)")));
- (TKKTon_kotlin_bigintBigInt *)preloadUIntLeqMax:(int32_t)max __attribute__((swift_name("preloadUIntLeq(max:)")));
- (TKKTon_kotlin_bigintBigInt *)preloadUIntLesMax:(int32_t)max __attribute__((swift_name("preloadUIntLes(max:)")));
- (id<TKKTon_kotlin_tvmCellSlice>)skipBitsLength:(int32_t)length __attribute__((swift_name("skipBits(length:)")));
@property (readonly) id<TKKTon_kotlin_bitstringBitString> bits __attribute__((swift_name("bits")));
@property int32_t bitsPosition __attribute__((swift_name("bitsPosition")));
@property (readonly) NSArray<id<TKKTon_kotlin_tvmCell>> *refs __attribute__((swift_name("refs")));
@property int32_t refsPosition __attribute__((swift_name("refsPosition")));
@property (readonly) int32_t remainingBits __attribute__((swift_name("remainingBits")));
@end

__attribute__((swift_name("Ton_kotlin_tlbAbstractTlbConstructor")))
@interface TKKTon_kotlin_tlbAbstractTlbConstructor<T> : TKKBase
- (instancetype)initWithSchema:(NSString *)schema id:(id<TKKTon_kotlin_bitstringBitString> _Nullable)id __attribute__((swift_name("init(schema:id:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_tlbAbstractTlbConstructorCompanion *companion __attribute__((swift_name("companion")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) id<TKKTon_kotlin_bitstringBitString> id __attribute__((swift_name("id")));
@property (readonly) NSString *schema __attribute__((swift_name("schema")));
@end

__attribute__((swift_name("Ton_kotlin_tlbTlbConstructor")))
@interface TKKTon_kotlin_tlbTlbConstructor<T> : TKKTon_kotlin_tlbAbstractTlbConstructor<T> <TKKTon_kotlin_tlbTlbCodec, TKKTon_kotlin_tlbTlbConstructorProvider>
- (instancetype)initWithSchema:(NSString *)schema id:(id<TKKTon_kotlin_bitstringBitString> _Nullable)id __attribute__((swift_name("init(schema:id:)"))) __attribute__((objc_designated_initializer));
- (TKKTon_kotlin_tlbTlbConstructor<T> *)tlbConstructor __attribute__((swift_name("tlbConstructor()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_tonapi_tlTonNodeBlockIdExt.Companion")))
@interface TKKTon_kotlin_tonapi_tlTonNodeBlockIdExtCompanion : TKKBase <TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_tonapi_tlTonNodeBlockIdExtCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)decodeByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decode(byteString:)")));
- (TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)decodeBoxedByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decodeBoxed(byteString:)")));
- (TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKTon_kotlin_tlByteString *)encodeToByteStringValue:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteString(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)value __attribute__((swift_name("hash(value:)")));

/**
 * @note annotations
 *   kotlin.jvm.JvmStatic
*/
- (TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)parseString:(NSString *)string __attribute__((swift_name("parse(string:)")));

/**
 * @note annotations
 *   kotlin.jvm.JvmStatic
*/
- (TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt * _Nullable)parseOrNullString:(NSString *)string __attribute__((swift_name("parseOrNull(string:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteclientTransactionId.Companion")))
@interface TKKTon_kotlin_liteclientTransactionIdCompanion : TKKBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteclientTransactionIdCompanion *shared __attribute__((swift_name("shared")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((swift_name("KotlinCoroutineContextElement")))
@protocol TKKKotlinCoroutineContextElement <TKKKotlinCoroutineContext>
@required
@property (readonly) id<TKKKotlinCoroutineContextKey> key __attribute__((swift_name("key")));
@end

__attribute__((swift_name("KotlinCoroutineContextKey")))
@protocol TKKKotlinCoroutineContextKey
@required
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteclientTransactionInfo.Companion")))
@interface TKKTon_kotlin_liteclientTransactionInfoCompanion : TKKBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteclientTransactionInfoCompanion *shared __attribute__((swift_name("shared")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_tonapi_tlLiteServerDesc.Companion")))
@interface TKKTon_kotlin_tonapi_tlLiteServerDescCompanion : TKKBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_tonapi_tlLiteServerDescCompanion *shared __attribute__((swift_name("shared")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
 *   kotlinx.serialization.SerialName(value="dht.config.global")
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_tonapi_tlDhtConfigGlobal")))
@interface TKKTon_kotlin_tonapi_tlDhtConfigGlobal : TKKBase <TKKTon_kotlin_tlTlObject>
- (instancetype)initWithStaticNodes:(NSArray<TKKTon_kotlin_tonapi_tlDhtNode *> *)staticNodes k:(int32_t)k a:(int32_t)a __attribute__((swift_name("init(staticNodes:k:a:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithStaticNodes:(TKKTon_kotlin_tonapi_tlDhtNodes *)staticNodes k:(int32_t)k a_:(int32_t)a __attribute__((swift_name("init(staticNodes:k:a_:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_tonapi_tlDhtConfigGlobalCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_tonapi_tlDhtConfigGlobal *)doCopyStaticNodes:(TKKTon_kotlin_tonapi_tlDhtNodes *)staticNodes k:(int32_t)k a:(int32_t)a __attribute__((swift_name("doCopy(staticNodes:k:a:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (id<TKKTon_kotlin_tlTlCodec>)tlCodec __attribute__((swift_name("tlCodec()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) int32_t a __attribute__((swift_name("a")));
@property (readonly) int32_t k __attribute__((swift_name("k")));

/**
 * @note annotations
 *   kotlinx.serialization.SerialName(value="static_nodes")
*/
@property (readonly) TKKTon_kotlin_tonapi_tlDhtNodes *staticNodes __attribute__((swift_name("staticNodes")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
 *   kotlinx.serialization.SerialName(value="validator.config.global")
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_tonapi_tlValidatorConfigGlobal")))
@interface TKKTon_kotlin_tonapi_tlValidatorConfigGlobal : TKKBase
- (instancetype)initWithZeroState:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)zeroState initBlock:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)initBlock hardforks:(id)hardforks __attribute__((swift_name("init(zeroState:initBlock:hardforks:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_tonapi_tlValidatorConfigGlobalCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_tonapi_tlValidatorConfigGlobal *)doCopyZeroState:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)zeroState initBlock:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)initBlock hardforks:(id)hardforks __attribute__((swift_name("doCopy(zeroState:initBlock:hardforks:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));

/**
 * @note annotations
 *   kotlinx.serialization.SerialName(value="hardforks")
*/
@property (readonly) id hardforks __attribute__((swift_name("hardforks")));

/**
 * @note annotations
 *   kotlinx.serialization.SerialName(value="init_block")
*/
@property (readonly, getter=doInitBlock) TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *initBlock __attribute__((swift_name("initBlock")));

/**
 * @note annotations
 *   kotlinx.serialization.SerialName(value="zero_state")
*/
@property (readonly) TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *zeroState __attribute__((swift_name("zeroState")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_tonapi_tlLiteClientConfigGlobal.Companion")))
@interface TKKTon_kotlin_tonapi_tlLiteClientConfigGlobalCompanion : TKKBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_tonapi_tlLiteClientConfigGlobalCompanion *shared __attribute__((swift_name("shared")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((swift_name("Ton_kotlin_tlbTlbCombinatorProvider")))
@protocol TKKTon_kotlin_tlbTlbCombinatorProvider <TKKTon_kotlin_tlbTlbProvider, TKKTon_kotlin_tlbTlbCodec>
@required
- (TKKTon_kotlin_tlbTlbCombinator<id> *)tlbCombinator __attribute__((swift_name("tlbCombinator()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_block_tlbBlock.Companion")))
@interface TKKTon_kotlin_block_tlbBlockCompanion : TKKBase <TKKTon_kotlin_tlbTlbCombinatorProvider>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_block_tlbBlockCompanion *shared __attribute__((swift_name("shared")));
- (id<TKKTon_kotlin_tvmCell>)createCellValue:(TKKTon_kotlin_block_tlbBlock *)value __attribute__((swift_name("createCell(value:)")));
- (TKKTon_kotlin_block_tlbBlock *)loadTlbCell:(id<TKKTon_kotlin_tvmCell>)cell __attribute__((swift_name("loadTlb(cell:)")));
- (TKKTon_kotlin_block_tlbBlock *)loadTlbCellSlice:(id<TKKTon_kotlin_tvmCellSlice>)cellSlice __attribute__((swift_name("loadTlb(cellSlice:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
- (void)storeTlbCellBuilder:(id<TKKTon_kotlin_tvmCellBuilder>)cellBuilder value:(TKKTon_kotlin_block_tlbBlock *)value __attribute__((swift_name("storeTlb(cellBuilder:value:)")));
- (TKKTon_kotlin_tlbTlbCombinator<TKKTon_kotlin_block_tlbBlock *> *)tlbCombinator __attribute__((swift_name("tlbCombinator()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Kotlinx_datetimeInstant.Companion")))
@interface TKKKotlinx_datetimeInstantCompanion : TKKBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKKotlinx_datetimeInstantCompanion *shared __attribute__((swift_name("shared")));
- (TKKKotlinx_datetimeInstant *)fromEpochMillisecondsEpochMilliseconds:(int64_t)epochMilliseconds __attribute__((swift_name("fromEpochMilliseconds(epochMilliseconds:)")));
- (TKKKotlinx_datetimeInstant *)fromEpochSecondsEpochSeconds:(int64_t)epochSeconds nanosecondAdjustment:(int32_t)nanosecondAdjustment __attribute__((swift_name("fromEpochSeconds(epochSeconds:nanosecondAdjustment:)")));
- (TKKKotlinx_datetimeInstant *)fromEpochSecondsEpochSeconds:(int64_t)epochSeconds nanosecondAdjustment_:(int64_t)nanosecondAdjustment __attribute__((swift_name("fromEpochSeconds(epochSeconds:nanosecondAdjustment_:)")));
- (TKKKotlinx_datetimeInstant *)now __attribute__((swift_name("now()"))) __attribute__((unavailable("Use Clock.System.now() instead")));
- (TKKKotlinx_datetimeInstant *)parseIsoString:(NSString *)isoString __attribute__((swift_name("parse(isoString:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@property (readonly) TKKKotlinx_datetimeInstant *DISTANT_FUTURE __attribute__((swift_name("DISTANT_FUTURE")));
@property (readonly) TKKKotlinx_datetimeInstant *DISTANT_PAST __attribute__((swift_name("DISTANT_PAST")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerVersion.Companion")))
@interface TKKTon_kotlin_liteapi_tlLiteServerVersionCompanion : TKKBase <TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapi_tlLiteServerVersionCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapi_tlLiteServerVersion *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerVersion *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerVersion *)decodeByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decode(byteString:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerVersion *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerVersion *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerVersion *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerVersion *)decodeBoxedByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decodeBoxed(byteString:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerVersion *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapi_tlLiteServerVersion *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerVersion *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapi_tlLiteServerVersion *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerVersion *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_liteapi_tlLiteServerVersion *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKTon_kotlin_tlByteString *)encodeToByteStringValue:(TKKTon_kotlin_liteapi_tlLiteServerVersion *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteString(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_liteapi_tlLiteServerVersion *)value __attribute__((swift_name("hash(value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerAccountId.Companion")))
@interface TKKTon_kotlin_liteapi_tlLiteServerAccountIdCompanion : TKKTon_kotlin_tlTlConstructor<TKKTon_kotlin_liteapi_tlLiteServerAccountId *>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (instancetype)initWithSchema:(NSString *)schema id:(TKKInt * _Nullable)id __attribute__((swift_name("init(schema:id:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapi_tlLiteServerAccountIdCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapi_tlLiteServerAccountId *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerAccountId *)value __attribute__((swift_name("encode(writer:value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((swift_name("Ton_kotlin_block_tlbMutableVmStack")))
@protocol TKKTon_kotlin_block_tlbMutableVmStack <TKKTon_kotlin_block_tlbVmStack>
@required
- (void)interchangeI:(int32_t)i __attribute__((swift_name("interchange(i:)")));
- (void)interchangeI:(int32_t)i j:(int32_t)j __attribute__((swift_name("interchange(i:j:)")));
- (id<TKKTon_kotlin_block_tlbVmStackValue>)pop __attribute__((swift_name("pop()")));
- (BOOL)popBool __attribute__((swift_name("popBool()")));
- (id<TKKTon_kotlin_tvmCellBuilder>)popBuilder __attribute__((swift_name("popBuilder()")));
- (id<TKKTon_kotlin_tvmCell>)popCell __attribute__((swift_name("popCell()")));
- (id<TKKTon_kotlin_block_tlbVmCont>)popCont __attribute__((swift_name("popCont()")));
- (TKKTon_kotlin_bigintBigInt *)popInt __attribute__((swift_name("popInt()")));
- (TKKTon_kotlin_block_tlbVmStackNull *)popNull __attribute__((swift_name("popNull()")));
- (id<TKKTon_kotlin_block_tlbVmStackNumber>)popNumber __attribute__((swift_name("popNumber()")));
- (id<TKKTon_kotlin_tvmCellSlice>)popSlice __attribute__((swift_name("popSlice()")));
- (int64_t)popTinyInt __attribute__((swift_name("popTinyInt()")));
- (id<TKKTon_kotlin_block_tlbVmTuple>)popTuple __attribute__((swift_name("popTuple()")));
- (void)pushStackValue:(id<TKKTon_kotlin_block_tlbVmStackValue>)stackValue __attribute__((swift_name("push(stackValue:)")));
- (void)pushBoolBoolean:(BOOL)boolean __attribute__((swift_name("pushBool(boolean:)")));
- (void)pushBuilderCellBuilder:(id<TKKTon_kotlin_tvmCellBuilder>)cellBuilder __attribute__((swift_name("pushBuilder(cellBuilder:)")));
- (void)pushCellCell:(id<TKKTon_kotlin_tvmCell>)cell __attribute__((swift_name("pushCell(cell:)")));
- (void)pushContVmCont:(id<TKKTon_kotlin_block_tlbVmCont>)vmCont __attribute__((swift_name("pushCont(vmCont:)")));
- (void)pushIntInt:(TKKTon_kotlin_bigintBigInt *)int_ __attribute__((swift_name("pushInt(int:)")));
- (void)pushNan __attribute__((swift_name("pushNan()")));
- (void)pushNull __attribute__((swift_name("pushNull()")));
- (void)pushSliceCellSlice:(id<TKKTon_kotlin_tvmCellSlice>)cellSlice __attribute__((swift_name("pushSlice(cellSlice:)")));
- (void)pushTinyIntTinyInt:(BOOL)tinyInt __attribute__((swift_name("pushTinyInt(tinyInt:)")));
- (void)pushTinyIntTinyInt_:(int32_t)tinyInt __attribute__((swift_name("pushTinyInt(tinyInt_:)")));
- (void)pushTinyIntTinyInt__:(int64_t)tinyInt __attribute__((swift_name("pushTinyInt(tinyInt__:)")));
- (void)pushTupleVmTuple:(id<TKKTon_kotlin_block_tlbVmTuple>)vmTuple __attribute__((swift_name("pushTuple(vmTuple:)")));
- (void)swap __attribute__((swift_name("swap()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((swift_name("Ton_kotlin_block_tlbVmStackList")))
@protocol TKKTon_kotlin_block_tlbVmStackList <TKKKotlinIterable>
@required
@end

__attribute__((swift_name("KotlinSequence")))
@protocol TKKKotlinSequence
@required
- (id<TKKKotlinIterator>)iterator __attribute__((swift_name("iterator()")));
@end

__attribute__((swift_name("Ton_kotlin_tvmCellDescriptor")))
@protocol TKKTon_kotlin_tvmCellDescriptor
@required
- (int8_t)component1__ __attribute__((swift_name("component1__()")));
- (int8_t)component2__ __attribute__((swift_name("component2__()")));
@property (readonly) TKKTon_kotlin_tvmCellType *cellType __attribute__((swift_name("cellType")));
@property (readonly) int8_t d1 __attribute__((swift_name("d1")));
@property (readonly) int8_t d2 __attribute__((swift_name("d2")));
@property (readonly) int32_t dataLength __attribute__((swift_name("dataLength")));
@property (readonly) BOOL hasHashes __attribute__((swift_name("hasHashes")));
@property (readonly) int32_t hashCount __attribute__((swift_name("hashCount")));
@property (readonly) BOOL isAbsent __attribute__((swift_name("isAbsent")));
@property (readonly) BOOL isAligned __attribute__((swift_name("isAligned")));
@property (readonly) BOOL isExotic __attribute__((swift_name("isExotic")));
@property (readonly) int32_t levelMask __attribute__((swift_name("levelMask")));
@property (readonly) int32_t referenceCount __attribute__((swift_name("referenceCount")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_tvmCellType")))
@interface TKKTon_kotlin_tvmCellType : TKKKotlinEnum<TKKTon_kotlin_tvmCellType *>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (instancetype)initWithName:(NSString *)name ordinal:(int32_t)ordinal __attribute__((swift_name("init(name:ordinal:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
@property (class, readonly, getter=companion) TKKTon_kotlin_tvmCellTypeCompanion *companion __attribute__((swift_name("companion")));
@property (class, readonly) TKKTon_kotlin_tvmCellType *ordinary __attribute__((swift_name("ordinary")));
@property (class, readonly) TKKTon_kotlin_tvmCellType *prunedBranch __attribute__((swift_name("prunedBranch")));
@property (class, readonly) TKKTon_kotlin_tvmCellType *libraryReference __attribute__((swift_name("libraryReference")));
@property (class, readonly) TKKTon_kotlin_tvmCellType *merkleProof __attribute__((swift_name("merkleProof")));
@property (class, readonly) TKKTon_kotlin_tvmCellType *merkleUpdate __attribute__((swift_name("merkleUpdate")));
+ (TKKKotlinArray<TKKTon_kotlin_tvmCellType *> *)values __attribute__((swift_name("values()")));
@property (class, readonly) NSArray<TKKTon_kotlin_tvmCellType *> *entries __attribute__((swift_name("entries")));
@property (readonly) BOOL isExotic __attribute__((swift_name("isExotic")));
@property (readonly) BOOL isMerkle __attribute__((swift_name("isMerkle")));
@property (readonly) BOOL isPruned __attribute__((swift_name("isPruned")));
@property (readonly) int32_t value_ __attribute__((swift_name("value_")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((swift_name("Ton_kotlin_block_tlbCommonMsgInfo")))
@protocol TKKTon_kotlin_block_tlbCommonMsgInfo <TKKTon_kotlin_tlbTlbObject>
@required
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((swift_name("Ton_kotlin_block_tlbEither")))
@protocol TKKTon_kotlin_block_tlbEither <TKKTon_kotlin_tlbTlbObject>
@required
- (TKKKotlinPair<id, id> *)toPair __attribute__((swift_name("toPair()")));
@property (readonly) id _Nullable x __attribute__((swift_name("x")));
@property (readonly) id _Nullable y __attribute__((swift_name("y")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_block_tlbMessageCompanion")))
@interface TKKTon_kotlin_block_tlbMessageCompanion : TKKBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_block_tlbMessageCompanion *shared __attribute__((swift_name("shared")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializerTypeParamsSerializers:(TKKKotlinArray<id<TKKKotlinx_serialization_coreKSerializer>> *)typeParamsSerializers __attribute__((swift_name("serializer(typeParamsSerializers:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializerTypeSerial0:(id<TKKKotlinx_serialization_coreKSerializer>)typeSerial0 __attribute__((swift_name("serializer(typeSerial0:)")));

/**
 * @note annotations
 *   kotlin.jvm.JvmStatic
*/
- (TKKTon_kotlin_tlbTlbConstructor<TKKTon_kotlin_block_tlbMessage<id> *> *)tlbCodecX:(id<TKKTon_kotlin_tlbTlbCodec>)x __attribute__((swift_name("tlbCodec(x:)")));
@property (readonly) TKKTon_kotlin_tlbTlbConstructor<TKKTon_kotlin_block_tlbMessage<id<TKKTon_kotlin_tvmCell>> *> *Any __attribute__((swift_name("Any")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerSendMsgStatus.Companion")))
@interface TKKTon_kotlin_liteapi_tlLiteServerSendMsgStatusCompanion : TKKTon_kotlin_tlTlConstructor<TKKTon_kotlin_liteapi_tlLiteServerSendMsgStatus *>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (instancetype)initWithSchema:(NSString *)schema id:(TKKInt * _Nullable)id __attribute__((swift_name("init(schema:id:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapi_tlLiteServerSendMsgStatusCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapi_tlLiteServerSendMsgStatus *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerSendMsgStatus *)value __attribute__((swift_name("encode(writer:value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((swift_name("Ktor_ioOutput")))
@interface TKKKtor_ioOutput : TKKBase <TKKKotlinAppendable, TKKKtor_ioCloseable>
- (instancetype)init __attribute__((swift_name("init()"))) __attribute__((objc_designated_initializer)) __attribute__((deprecated("\n    We're migrating to the new kotlinx-io library.\n    This declaration is deprecated and will be removed in Ktor 4.0.0\n    If you have any problems with migration, please contact us in \n    https://youtrack.jetbrains.com/issue/KTOR-6030/Migrate-to-new-kotlinx.io-library\n    ")));
+ (instancetype)new __attribute__((availability(swift, unavailable, message="use object initializers instead")));
- (instancetype)initWithPool:(id<TKKKtor_ioObjectPool>)pool __attribute__((swift_name("init(pool:)"))) __attribute__((objc_designated_initializer)) __attribute__((deprecated("\n    We're migrating to the new kotlinx-io library.\n    This declaration is deprecated and will be removed in Ktor 4.0.0\n    If you have any problems with migration, please contact us in \n    https://youtrack.jetbrains.com/issue/KTOR-6030/Migrate-to-new-kotlinx.io-library\n    ")));
- (TKKKtor_ioOutput *)appendValue:(unichar)value __attribute__((swift_name("append(value:)")));
- (id<TKKKotlinAppendable>)appendCsq:(TKKKotlinCharArray *)csq start:(int32_t)start end:(int32_t)end __attribute__((swift_name("append(csq:start:end:)")));
- (TKKKtor_ioOutput *)appendValue_:(id _Nullable)value __attribute__((swift_name("append(value_:)")));
- (TKKKtor_ioOutput *)appendValue:(id _Nullable)value startIndex:(int32_t)startIndex endIndex:(int32_t)endIndex __attribute__((swift_name("append(value:startIndex:endIndex:)")));
- (void)close __attribute__((swift_name("close()")));

/**
 * @note This method has protected visibility in Kotlin source and is intended only for use by subclasses.
*/
- (void)closeDestination __attribute__((swift_name("closeDestination()")));
- (void)flush __attribute__((swift_name("flush()")));

/**
 * @note This method has protected visibility in Kotlin source and is intended only for use by subclasses.
*/
- (void)flushSource:(TKKKtor_ioMemory *)source offset:(int32_t)offset length:(int32_t)length __attribute__((swift_name("flush(source:offset:length:)")));
- (void)release_ __attribute__((swift_name("release()")));
- (void)writeByteV:(int8_t)v __attribute__((swift_name("writeByte(v:)")));
- (void)writePacketPacket:(TKKKtor_ioByteReadPacket *)packet __attribute__((swift_name("writePacket(packet:)")));
- (void)writePacketP:(TKKKtor_ioByteReadPacket *)p n:(int32_t)n __attribute__((swift_name("writePacket(p:n:)")));
- (void)writePacketP:(TKKKtor_ioByteReadPacket *)p n_:(int64_t)n __attribute__((swift_name("writePacket(p:n_:)")));

/**
 * @note This property has protected visibility in Kotlin source and is intended only for use by subclasses.
*/
@property (readonly) int32_t _size __attribute__((swift_name("_size")));

/**
 * @note This property has protected visibility in Kotlin source and is intended only for use by subclasses.
*/
@property (readonly) id<TKKKtor_ioObjectPool> pool __attribute__((swift_name("pool")));
@end

__attribute__((swift_name("Ktor_ioInput")))
@interface TKKKtor_ioInput : TKKBase <TKKKtor_ioCloseable>
- (instancetype)initWithHead:(TKKKtor_ioChunkBuffer *)head remaining:(int64_t)remaining pool:(id<TKKKtor_ioObjectPool>)pool __attribute__((swift_name("init(head:remaining:pool:)"))) __attribute__((objc_designated_initializer)) __attribute__((deprecated("\n    We're migrating to the new kotlinx-io library.\n    This declaration is deprecated and will be removed in Ktor 4.0.0\n    If you have any problems with migration, please contact us in \n    https://youtrack.jetbrains.com/issue/KTOR-6030/Migrate-to-new-kotlinx.io-library\n    ")));
@property (class, readonly, getter=companion) TKKKtor_ioInputCompanion *companion __attribute__((swift_name("companion")));
- (BOOL)canRead __attribute__((swift_name("canRead()")));
- (void)close __attribute__((swift_name("close()")));

/**
 * @note This method has protected visibility in Kotlin source and is intended only for use by subclasses.
*/
- (void)closeSource __attribute__((swift_name("closeSource()")));
- (int32_t)discardN:(int32_t)n __attribute__((swift_name("discard(n:)")));
- (int64_t)discardN_:(int64_t)n __attribute__((swift_name("discard(n_:)")));
- (void)discardExactN:(int32_t)n __attribute__((swift_name("discardExact(n:)")));

/**
 * @note This method has protected visibility in Kotlin source and is intended only for use by subclasses.
*/
- (TKKKtor_ioChunkBuffer * _Nullable)fill __attribute__((swift_name("fill()")));

/**
 * @note This method has protected visibility in Kotlin source and is intended only for use by subclasses.
*/
- (int32_t)fillDestination:(TKKKtor_ioMemory *)destination offset:(int32_t)offset length:(int32_t)length __attribute__((swift_name("fill(destination:offset:length:)")));
- (BOOL)hasBytesN:(int32_t)n __attribute__((swift_name("hasBytes(n:)")));

/**
 * @note This method has protected visibility in Kotlin source and is intended only for use by subclasses.
*/
- (void)markNoMoreChunksAvailable __attribute__((swift_name("markNoMoreChunksAvailable()")));
- (int64_t)peekToDestination:(TKKKtor_ioMemory *)destination destinationOffset:(int64_t)destinationOffset offset:(int64_t)offset min:(int64_t)min max:(int64_t)max __attribute__((swift_name("peekTo(destination:destinationOffset:offset:min:max:)")));
- (int32_t)peekToBuffer:(TKKKtor_ioChunkBuffer *)buffer __attribute__((swift_name("peekTo(buffer:)")));
- (int8_t)readByte __attribute__((swift_name("readByte()")));
- (NSString *)readTextMin:(int32_t)min max:(int32_t)max __attribute__((swift_name("readText(min:max:)")));
- (int32_t)readTextOut:(id<TKKKotlinAppendable>)out min:(int32_t)min max:(int32_t)max __attribute__((swift_name("readText(out:min:max:)")));
- (NSString *)readTextExactExactCharacters:(int32_t)exactCharacters __attribute__((swift_name("readTextExact(exactCharacters:)")));
- (void)readTextExactOut:(id<TKKKotlinAppendable>)out exactCharacters:(int32_t)exactCharacters __attribute__((swift_name("readTextExact(out:exactCharacters:)")));
- (void)release_ __attribute__((swift_name("release()")));
- (int32_t)tryPeek __attribute__((swift_name("tryPeek()")));
@property (readonly) BOOL endOfInput __attribute__((swift_name("endOfInput")));
@property (readonly) id<TKKKtor_ioObjectPool> pool __attribute__((swift_name("pool")));
@property (readonly) int64_t remaining __attribute__((swift_name("remaining")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ktor_ioByteReadPacket")))
@interface TKKKtor_ioByteReadPacket : TKKKtor_ioInput
- (instancetype)initWithHead:(TKKKtor_ioChunkBuffer *)head pool:(id<TKKKtor_ioObjectPool>)pool __attribute__((swift_name("init(head:pool:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithHead:(TKKKtor_ioChunkBuffer *)head remaining:(int64_t)remaining pool:(id<TKKKtor_ioObjectPool>)pool __attribute__((swift_name("init(head:remaining:pool:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
@property (class, readonly, getter=companion) TKKKtor_ioByteReadPacketCompanion *companion __attribute__((swift_name("companion")));

/**
 * @note This method has protected visibility in Kotlin source and is intended only for use by subclasses.
*/
- (void)closeSource __attribute__((swift_name("closeSource()")));
- (TKKKtor_ioByteReadPacket *)doCopy __attribute__((swift_name("doCopy()")));

/**
 * @note This method has protected visibility in Kotlin source and is intended only for use by subclasses.
*/
- (TKKKtor_ioChunkBuffer * _Nullable)fill __attribute__((swift_name("fill()")));

/**
 * @note This method has protected visibility in Kotlin source and is intended only for use by subclasses.
*/
- (int32_t)fillDestination:(TKKKtor_ioMemory *)destination offset:(int32_t)offset length:(int32_t)length __attribute__((swift_name("fill(destination:offset:length:)")));
- (NSString *)description __attribute__((swift_name("description()")));
@end

__attribute__((swift_name("Ton_kotlin_tlTLFunction")))
@protocol TKKTon_kotlin_tlTLFunction
@required
- (id<TKKTon_kotlin_tlTlCodec>)resultTlCodec __attribute__((swift_name("resultTlCodec()")));
- (id<TKKTon_kotlin_tlTlCodec>)tlCodec __attribute__((swift_name("tlCodec()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
 *   kotlinx.serialization.SerialName(value="liteServer.getAccountState")
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerGetAccountState")))
@interface TKKTon_kotlin_liteapi_tlLiteServerGetAccountState : TKKBase <TKKTon_kotlin_tlTLFunction>
- (instancetype)initWithId:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)id account:(TKKTon_kotlin_liteapi_tlLiteServerAccountId *)account __attribute__((swift_name("init(id:account:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapi_tlLiteServerGetAccountStateCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetAccountState *)doCopyId:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)id account:(TKKTon_kotlin_liteapi_tlLiteServerAccountId *)account __attribute__((swift_name("doCopy(id:account:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (id<TKKTon_kotlin_tlTlCodec>)resultTlCodec __attribute__((swift_name("resultTlCodec()")));
- (id<TKKTon_kotlin_tlTlCodec>)tlCodec __attribute__((swift_name("tlCodec()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) TKKTon_kotlin_liteapi_tlLiteServerAccountId *account __attribute__((swift_name("account")));
@property (readonly) TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *id __attribute__((swift_name("id")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
 *   kotlinx.serialization.SerialName(value="liteServer.accountState")
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerAccountState")))
@interface TKKTon_kotlin_liteapi_tlLiteServerAccountState : TKKBase
- (instancetype)initWithId:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)id shardBlock:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)shardBlock shardProof:(TKKTon_kotlin_tlByteString *)shardProof proof:(TKKTon_kotlin_tlByteString *)proof state:(TKKTon_kotlin_tlByteString *)state __attribute__((swift_name("init(id:shardBlock:shardProof:proof:state:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapi_tlLiteServerAccountStateCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapi_tlLiteServerAccountState *)doCopyId:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)id shardBlock:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)shardBlock shardProof:(TKKTon_kotlin_tlByteString *)shardProof proof:(TKKTon_kotlin_tlByteString *)proof state:(TKKTon_kotlin_tlByteString *)state __attribute__((swift_name("doCopy(id:shardBlock:shardProof:proof:state:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *id __attribute__((swift_name("id")));
@property (readonly) TKKTon_kotlin_tlByteString *proof __attribute__((swift_name("proof")));

/**
 * @note annotations
 *   kotlinx.serialization.SerialName(value="shardblk")
*/
@property (readonly) TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *shardBlock __attribute__((swift_name("shardBlock")));

/**
 * @note annotations
 *   kotlinx.serialization.SerialName(value="shard_proof")
*/
@property (readonly) TKKTon_kotlin_tlByteString *shardProof __attribute__((swift_name("shardProof")));
@property (readonly) TKKTon_kotlin_tlByteString *state __attribute__((swift_name("state")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
 *   kotlinx.serialization.SerialName(value="liteServer.getAllShardsInfo")
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerGetAllShardsInfo")))
@interface TKKTon_kotlin_liteapi_tlLiteServerGetAllShardsInfo : TKKBase <TKKTon_kotlin_tlTLFunction>
- (instancetype)initWithId:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)id __attribute__((swift_name("init(id:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapi_tlLiteServerGetAllShardsInfoCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetAllShardsInfo *)doCopyId:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)id __attribute__((swift_name("doCopy(id:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (id<TKKTon_kotlin_tlTlCodec>)resultTlCodec __attribute__((swift_name("resultTlCodec()")));
- (id<TKKTon_kotlin_tlTlCodec>)tlCodec __attribute__((swift_name("tlCodec()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *id __attribute__((swift_name("id")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
 *   kotlinx.serialization.SerialName(value="liteServer.allShardsInfo")
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerAllShardsInfo")))
@interface TKKTon_kotlin_liteapi_tlLiteServerAllShardsInfo : TKKBase
- (instancetype)initWithId:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)id proof:(TKKTon_kotlin_tlByteString *)proof data:(TKKTon_kotlin_tlByteString *)data __attribute__((swift_name("init(id:proof:data:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapi_tlLiteServerAllShardsInfoCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapi_tlLiteServerAllShardsInfo *)doCopyId:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)id proof:(TKKTon_kotlin_tlByteString *)proof data:(TKKTon_kotlin_tlByteString *)data __attribute__((swift_name("doCopy(id:proof:data:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) TKKTon_kotlin_tlByteString *data __attribute__((swift_name("data")));
@property (readonly) TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *id __attribute__((swift_name("id")));
@property (readonly) TKKTon_kotlin_tlByteString *proof __attribute__((swift_name("proof")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
 *   kotlinx.serialization.SerialName(value="liteServer.getBlock")
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerGetBlock")))
@interface TKKTon_kotlin_liteapi_tlLiteServerGetBlock : TKKBase <TKKTon_kotlin_tlTLFunction>
- (instancetype)initWithId:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)id __attribute__((swift_name("init(id:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapi_tlLiteServerGetBlockCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetBlock *)doCopyId:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)id __attribute__((swift_name("doCopy(id:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (id<TKKTon_kotlin_tlTlCodec>)resultTlCodec __attribute__((swift_name("resultTlCodec()")));
- (id<TKKTon_kotlin_tlTlCodec>)tlCodec __attribute__((swift_name("tlCodec()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *id __attribute__((swift_name("id")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
 *   kotlinx.serialization.SerialName(value="liteServer.blockData")
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerBlockData")))
@interface TKKTon_kotlin_liteapi_tlLiteServerBlockData : TKKBase
- (instancetype)initWithId:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)id data:(TKKTon_kotlin_tlByteString *)data __attribute__((swift_name("init(id:data:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapi_tlLiteServerBlockDataCompanion *companion __attribute__((swift_name("companion")));
@property (readonly) TKKTon_kotlin_tlByteString *data __attribute__((swift_name("data")));
@property (readonly) TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *id __attribute__((swift_name("id")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
 *   kotlinx.serialization.SerialName(value="liteServer.getBlockHeader")
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerGetBlockHeader")))
@interface TKKTon_kotlin_liteapi_tlLiteServerGetBlockHeader : TKKBase <TKKTon_kotlin_tlTLFunction>
- (instancetype)initWithId:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)id mode:(int32_t)mode __attribute__((swift_name("init(id:mode:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapi_tlLiteServerGetBlockHeaderCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetBlockHeader *)doCopyId:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)id mode:(int32_t)mode __attribute__((swift_name("doCopy(id:mode:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (id<TKKTon_kotlin_tlTlCodec>)resultTlCodec __attribute__((swift_name("resultTlCodec()")));
- (id<TKKTon_kotlin_tlTlCodec>)tlCodec __attribute__((swift_name("tlCodec()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *id __attribute__((swift_name("id")));
@property (readonly) int32_t mode __attribute__((swift_name("mode")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
 *   kotlinx.serialization.SerialName(value="liteServer.blockHeader")
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerBlockHeader")))
@interface TKKTon_kotlin_liteapi_tlLiteServerBlockHeader : TKKBase
- (instancetype)initWithId:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)id mode:(int32_t)mode headerProof:(TKKTon_kotlin_tlByteString *)headerProof __attribute__((swift_name("init(id:mode:headerProof:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapi_tlLiteServerBlockHeaderCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapi_tlLiteServerBlockHeader *)doCopyId:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)id mode:(int32_t)mode headerProof:(TKKTon_kotlin_tlByteString *)headerProof __attribute__((swift_name("doCopy(id:mode:headerProof:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));

/**
 * @note annotations
 *   kotlinx.serialization.SerialName(value="header_proof")
*/
@property (readonly) TKKTon_kotlin_tlByteString *headerProof __attribute__((swift_name("headerProof")));
@property (readonly) TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *id __attribute__((swift_name("id")));
@property (readonly) int32_t mode __attribute__((swift_name("mode")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
 *   kotlinx.serialization.SerialName(value="liteServer.getBlockProof")
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerGetBlockProof")))
@interface TKKTon_kotlin_liteapi_tlLiteServerGetBlockProof : TKKBase <TKKTon_kotlin_tlTLFunction>
- (instancetype)initWithKnownBlock:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)knownBlock targetBlock:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt * _Nullable)targetBlock __attribute__((swift_name("init(knownBlock:targetBlock:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithMode:(int32_t)mode knownBlock:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)knownBlock targetBlock:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt * _Nullable)targetBlock __attribute__((swift_name("init(mode:knownBlock:targetBlock:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapi_tlLiteServerGetBlockProofCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetBlockProof *)doCopyMode:(int32_t)mode knownBlock:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)knownBlock targetBlock:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt * _Nullable)targetBlock __attribute__((swift_name("doCopy(mode:knownBlock:targetBlock:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (id<TKKTon_kotlin_tlTlCodec>)resultTlCodec __attribute__((swift_name("resultTlCodec()")));
- (id<TKKTon_kotlin_tlTlCodec>)tlCodec __attribute__((swift_name("tlCodec()")));
- (NSString *)description __attribute__((swift_name("description()")));

/**
 * @note annotations
 *   kotlinx.serialization.SerialName(value="known_block")
*/
@property (readonly) TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *knownBlock __attribute__((swift_name("knownBlock")));
@property (readonly) int32_t mode __attribute__((swift_name("mode")));

/**
 * @note annotations
 *   kotlinx.serialization.SerialName(value="target_block")
*/
@property (readonly) TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt * _Nullable targetBlock __attribute__((swift_name("targetBlock")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
 *   kotlinx.serialization.SerialName(value="liteServer.partialBlockProof")
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerPartialBlockProof")))
@interface TKKTon_kotlin_liteapi_tlLiteServerPartialBlockProof : TKKBase
- (instancetype)initWithComplete:(BOOL)complete from:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)from to:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)to steps:(NSArray<id<TKKTon_kotlin_liteapi_tlLiteServerBlockLink>> *)steps __attribute__((swift_name("init(complete:from:to:steps:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapi_tlLiteServerPartialBlockProofCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapi_tlLiteServerPartialBlockProof *)doCopyComplete:(BOOL)complete from:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)from to:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)to steps:(NSArray<id<TKKTon_kotlin_liteapi_tlLiteServerBlockLink>> *)steps __attribute__((swift_name("doCopy(complete:from:to:steps:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) BOOL complete __attribute__((swift_name("complete")));
@property (readonly) TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *from __attribute__((swift_name("from")));
@property (readonly) NSArray<id<TKKTon_kotlin_liteapi_tlLiteServerBlockLink>> *steps __attribute__((swift_name("steps")));
@property (readonly) TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *to __attribute__((swift_name("to")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
 *   kotlinx.serialization.SerialName(value="liteServer.getConfigAll")
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerGetConfigAll")))
@interface TKKTon_kotlin_liteapi_tlLiteServerGetConfigAll : TKKBase <TKKTon_kotlin_tlTLFunction>
- (instancetype)initWithMode:(int32_t)mode id:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)id __attribute__((swift_name("init(mode:id:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapi_tlLiteServerGetConfigAllCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetConfigAll *)doCopyMode:(int32_t)mode id:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)id __attribute__((swift_name("doCopy(mode:id:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (id<TKKTon_kotlin_tlTlCodec>)resultTlCodec __attribute__((swift_name("resultTlCodec()")));
- (id<TKKTon_kotlin_tlTlCodec>)tlCodec __attribute__((swift_name("tlCodec()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *id __attribute__((swift_name("id")));
@property (readonly) int32_t mode __attribute__((swift_name("mode")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
 *   kotlinx.serialization.SerialName(value="liteServer.configInfo")
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerConfigInfo")))
@interface TKKTon_kotlin_liteapi_tlLiteServerConfigInfo : TKKBase
- (instancetype)initWithMode:(int32_t)mode id:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)id stateProof:(TKKTon_kotlin_tlByteString *)stateProof configProof:(TKKTon_kotlin_tlByteString *)configProof __attribute__((swift_name("init(mode:id:stateProof:configProof:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapi_tlLiteServerConfigInfoCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapi_tlLiteServerConfigInfo *)doCopyMode:(int32_t)mode id:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)id stateProof:(TKKTon_kotlin_tlByteString *)stateProof configProof:(TKKTon_kotlin_tlByteString *)configProof __attribute__((swift_name("doCopy(mode:id:stateProof:configProof:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) TKKTon_kotlin_tlByteString *configProof __attribute__((swift_name("configProof")));
@property (readonly) TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *id __attribute__((swift_name("id")));
@property (readonly) int32_t mode __attribute__((swift_name("mode")));
@property (readonly) TKKTon_kotlin_tlByteString *stateProof __attribute__((swift_name("stateProof")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerGetConfigParams")))
@interface TKKTon_kotlin_liteapi_tlLiteServerGetConfigParams : TKKBase <TKKTon_kotlin_tlTLFunction>
- (instancetype)initWithMode:(int32_t)mode id:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)id paramList:(NSArray<TKKInt *> *)paramList __attribute__((swift_name("init(mode:id:paramList:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapi_tlLiteServerGetConfigParamsCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetConfigParams *)doCopyMode:(int32_t)mode id:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)id paramList:(NSArray<TKKInt *> *)paramList __attribute__((swift_name("doCopy(mode:id:paramList:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (id<TKKTon_kotlin_tlTlCodec>)resultTlCodec __attribute__((swift_name("resultTlCodec()")));
- (id<TKKTon_kotlin_tlTlCodec>)tlCodec __attribute__((swift_name("tlCodec()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *id __attribute__((swift_name("id")));
@property (readonly) int32_t mode __attribute__((swift_name("mode")));
@property (readonly) NSArray<TKKInt *> *paramList __attribute__((swift_name("paramList")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
 *   kotlinx.serialization.SerialName(value="liteServer.getMasterchainInfo")
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerGetMasterchainInfo")))
@interface TKKTon_kotlin_liteapi_tlLiteServerGetMasterchainInfo : TKKBase <TKKTon_kotlin_tlTLFunction, TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)liteServerGetMasterchainInfo __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapi_tlLiteServerGetMasterchainInfo *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetMasterchainInfo *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetMasterchainInfo *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetMasterchainInfo *)decodeByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decode(byteString:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetMasterchainInfo *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetMasterchainInfo *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetMasterchainInfo *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetMasterchainInfo *)decodeBoxedByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decodeBoxed(byteString:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetMasterchainInfo *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapi_tlLiteServerGetMasterchainInfo *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerGetMasterchainInfo *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapi_tlLiteServerGetMasterchainInfo *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerGetMasterchainInfo *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_liteapi_tlLiteServerGetMasterchainInfo *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKTon_kotlin_tlByteString *)encodeToByteStringValue:(TKKTon_kotlin_liteapi_tlLiteServerGetMasterchainInfo *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteString(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_liteapi_tlLiteServerGetMasterchainInfo *)value __attribute__((swift_name("hash(value:)")));
- (id<TKKTon_kotlin_tlTlCodec>)resultTlCodec __attribute__((swift_name("resultTlCodec()")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializerTypeParamsSerializers:(TKKKotlinArray<id<TKKKotlinx_serialization_coreKSerializer>> *)typeParamsSerializers __attribute__((swift_name("serializer(typeParamsSerializers:)")));
- (id<TKKTon_kotlin_tlTlCodec>)tlCodec __attribute__((swift_name("tlCodec()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
 *   kotlinx.serialization.SerialName(value="liteServer.masterchainInfo")
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerMasterchainInfo")))
@interface TKKTon_kotlin_liteapi_tlLiteServerMasterchainInfo : TKKBase
- (instancetype)initWithLast:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)last stateRootHash:(TKKTon_kotlin_tlByteString *)stateRootHash init:(TKKTon_kotlin_tonapi_tlTonNodeZeroStateIdExt *)init __attribute__((swift_name("init(last:stateRootHash:init:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapi_tlLiteServerMasterchainInfoCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapi_tlLiteServerMasterchainInfo *)doCopyLast:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)last stateRootHash:(TKKTon_kotlin_tlByteString *)stateRootHash init:(TKKTon_kotlin_tonapi_tlTonNodeZeroStateIdExt *)init __attribute__((swift_name("doCopy(last:stateRootHash:init:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly, getter=doInit) TKKTon_kotlin_tonapi_tlTonNodeZeroStateIdExt *init __attribute__((swift_name("init")));
@property (readonly) TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *last __attribute__((swift_name("last")));
@property (readonly) TKKTon_kotlin_tlByteString *stateRootHash __attribute__((swift_name("stateRootHash")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
 *   kotlinx.serialization.SerialName(value="liteServer.getMasterchainInfoExt")
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerGetMasterchainInfoExt")))
@interface TKKTon_kotlin_liteapi_tlLiteServerGetMasterchainInfoExt : TKKBase <TKKTon_kotlin_tlTLFunction>
- (instancetype)initWithMode:(int32_t)mode __attribute__((swift_name("init(mode:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapi_tlLiteServerGetMasterchainInfoExtCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetMasterchainInfoExt *)doCopyMode:(int32_t)mode __attribute__((swift_name("doCopy(mode:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (id<TKKTon_kotlin_tlTlCodec>)resultTlCodec __attribute__((swift_name("resultTlCodec()")));
- (id<TKKTon_kotlin_tlTlCodec>)tlCodec __attribute__((swift_name("tlCodec()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) int32_t mode __attribute__((swift_name("mode")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
 *   kotlinx.serialization.SerialName(value="liteServer.masterchainInfoExt")
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerMasterchainInfoExt")))
@interface TKKTon_kotlin_liteapi_tlLiteServerMasterchainInfoExt : TKKBase
- (instancetype)initWithMode:(int32_t)mode version:(int32_t)version capabilities:(int64_t)capabilities last:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)last lastUTime:(int32_t)lastUTime now:(int32_t)now stateRootHash:(TKKTon_kotlin_tlByteString *)stateRootHash init:(TKKTon_kotlin_tonapi_tlTonNodeZeroStateIdExt *)init __attribute__((swift_name("init(mode:version:capabilities:last:lastUTime:now:stateRootHash:init:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapi_tlLiteServerMasterchainInfoExtCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapi_tlLiteServerMasterchainInfoExt *)doCopyMode:(int32_t)mode version:(int32_t)version capabilities:(int64_t)capabilities last:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)last lastUTime:(int32_t)lastUTime now:(int32_t)now stateRootHash:(TKKTon_kotlin_tlByteString *)stateRootHash init:(TKKTon_kotlin_tonapi_tlTonNodeZeroStateIdExt *)init __attribute__((swift_name("doCopy(mode:version:capabilities:last:lastUTime:now:stateRootHash:init:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) int64_t capabilities __attribute__((swift_name("capabilities")));
@property (readonly, getter=doInit) TKKTon_kotlin_tonapi_tlTonNodeZeroStateIdExt *init __attribute__((swift_name("init")));
@property (readonly) TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *last __attribute__((swift_name("last")));

/**
 * @note annotations
 *   kotlinx.serialization.SerialName(value="last_utime")
*/
@property (readonly) int32_t lastUTime __attribute__((swift_name("lastUTime")));
@property (readonly) int32_t mode __attribute__((swift_name("mode")));
@property (readonly) int32_t now __attribute__((swift_name("now")));

/**
 * @note annotations
 *   kotlinx.serialization.SerialName(value="state_root_hash")
*/
@property (readonly) TKKTon_kotlin_tlByteString *stateRootHash __attribute__((swift_name("stateRootHash")));
@property (readonly) int32_t version __attribute__((swift_name("version")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
 *   kotlinx.serialization.SerialName(value="liteServer.getOneTransaction")
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerGetOneTransaction")))
@interface TKKTon_kotlin_liteapi_tlLiteServerGetOneTransaction : TKKBase <TKKTon_kotlin_tlTLFunction>
- (instancetype)initWithId:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)id account:(TKKTon_kotlin_liteapi_tlLiteServerAccountId *)account lt:(int64_t)lt __attribute__((swift_name("init(id:account:lt:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapi_tlLiteServerGetOneTransactionCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetOneTransaction *)doCopyId:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)id account:(TKKTon_kotlin_liteapi_tlLiteServerAccountId *)account lt:(int64_t)lt __attribute__((swift_name("doCopy(id:account:lt:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (id<TKKTon_kotlin_tlTlCodec>)resultTlCodec __attribute__((swift_name("resultTlCodec()")));
- (id<TKKTon_kotlin_tlTlCodec>)tlCodec __attribute__((swift_name("tlCodec()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) TKKTon_kotlin_liteapi_tlLiteServerAccountId *account __attribute__((swift_name("account")));
@property (readonly) TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *id __attribute__((swift_name("id")));
@property (readonly) int64_t lt __attribute__((swift_name("lt")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
 *   kotlinx.serialization.SerialName(value="liteServer.transactionInfo")
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerTransactionInfo")))
@interface TKKTon_kotlin_liteapi_tlLiteServerTransactionInfo : TKKBase
- (instancetype)initWithId:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)id proof:(TKKTon_kotlin_tlByteString *)proof transaction:(TKKTon_kotlin_tlByteString *)transaction __attribute__((swift_name("init(id:proof:transaction:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapi_tlLiteServerTransactionInfoCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapi_tlLiteServerTransactionInfo *)doCopyId:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)id proof:(TKKTon_kotlin_tlByteString *)proof transaction:(TKKTon_kotlin_tlByteString *)transaction __attribute__((swift_name("doCopy(id:proof:transaction:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *id __attribute__((swift_name("id")));
@property (readonly) TKKTon_kotlin_tlByteString *proof __attribute__((swift_name("proof")));
@property (readonly) TKKTon_kotlin_tlByteString *transaction __attribute__((swift_name("transaction")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
 *   kotlinx.serialization.SerialName(value="liteServer.getShardInfo")
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerGetShardInfo")))
@interface TKKTon_kotlin_liteapi_tlLiteServerGetShardInfo : TKKBase <TKKTon_kotlin_tlTLFunction>
- (instancetype)initWithId:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)id workchain:(int32_t)workchain shard:(int64_t)shard exact:(BOOL)exact __attribute__((swift_name("init(id:workchain:shard:exact:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapi_tlLiteServerGetShardInfoCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetShardInfo *)doCopyId:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)id workchain:(int32_t)workchain shard:(int64_t)shard exact:(BOOL)exact __attribute__((swift_name("doCopy(id:workchain:shard:exact:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (id<TKKTon_kotlin_tlTlCodec>)resultTlCodec __attribute__((swift_name("resultTlCodec()")));
- (id<TKKTon_kotlin_tlTlCodec>)tlCodec __attribute__((swift_name("tlCodec()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) BOOL exact __attribute__((swift_name("exact")));
@property (readonly) TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *id __attribute__((swift_name("id")));
@property (readonly) int64_t shard __attribute__((swift_name("shard")));
@property (readonly) int32_t workchain __attribute__((swift_name("workchain")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
 *   kotlinx.serialization.SerialName(value="liteServer.shardInfo")
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerShardInfo")))
@interface TKKTon_kotlin_liteapi_tlLiteServerShardInfo : TKKBase
- (instancetype)initWithId:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)id shardBlock:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)shardBlock shardProof:(TKKTon_kotlin_tlByteString *)shardProof shardDescr:(TKKTon_kotlin_tlByteString *)shardDescr __attribute__((swift_name("init(id:shardBlock:shardProof:shardDescr:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapi_tlLiteServerShardInfoCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapi_tlLiteServerShardInfo *)doCopyId:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)id shardBlock:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)shardBlock shardProof:(TKKTon_kotlin_tlByteString *)shardProof shardDescr:(TKKTon_kotlin_tlByteString *)shardDescr __attribute__((swift_name("doCopy(id:shardBlock:shardProof:shardDescr:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *id __attribute__((swift_name("id")));

/**
 * @note annotations
 *   kotlinx.serialization.SerialName(value="shardblk")
*/
@property (readonly) TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *shardBlock __attribute__((swift_name("shardBlock")));

/**
 * @note annotations
 *   kotlinx.serialization.SerialName(value="shard_descr")
*/
@property (readonly) TKKTon_kotlin_tlByteString *shardDescr __attribute__((swift_name("shardDescr")));

/**
 * @note annotations
 *   kotlinx.serialization.SerialName(value="shard_proof")
*/
@property (readonly) TKKTon_kotlin_tlByteString *shardProof __attribute__((swift_name("shardProof")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
 *   kotlinx.serialization.SerialName(value="liteServer.getState")
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerGetState")))
@interface TKKTon_kotlin_liteapi_tlLiteServerGetState : TKKBase <TKKTon_kotlin_tlTLFunction>
- (instancetype)initWithId:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)id __attribute__((swift_name("init(id:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapi_tlLiteServerGetStateCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetState *)doCopyId:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)id __attribute__((swift_name("doCopy(id:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (id<TKKTon_kotlin_tlTlCodec>)resultTlCodec __attribute__((swift_name("resultTlCodec()")));
- (id<TKKTon_kotlin_tlTlCodec>)tlCodec __attribute__((swift_name("tlCodec()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *id __attribute__((swift_name("id")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
 *   kotlinx.serialization.SerialName(value="liteServer.blockState")
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerBlockState")))
@interface TKKTon_kotlin_liteapi_tlLiteServerBlockState : TKKBase
- (instancetype)initWithId:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)id rootHash:(TKKTon_kotlin_tlByteString *)rootHash fileHash:(TKKTon_kotlin_tlByteString *)fileHash data:(TKKTon_kotlin_tlByteString *)data __attribute__((swift_name("init(id:rootHash:fileHash:data:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapi_tlLiteServerBlockStateCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapi_tlLiteServerBlockState *)doCopyId:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)id rootHash:(TKKTon_kotlin_tlByteString *)rootHash fileHash:(TKKTon_kotlin_tlByteString *)fileHash data:(TKKTon_kotlin_tlByteString *)data __attribute__((swift_name("doCopy(id:rootHash:fileHash:data:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) TKKTon_kotlin_tlByteString *data __attribute__((swift_name("data")));

/**
 * @note annotations
 *   kotlinx.serialization.SerialName(value="file_hash")
*/
@property (readonly) TKKTon_kotlin_tlByteString *fileHash __attribute__((swift_name("fileHash")));
@property (readonly) TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *id __attribute__((swift_name("id")));

/**
 * @note annotations
 *   kotlinx.serialization.SerialName(value="root_hash")
*/
@property (readonly) TKKTon_kotlin_tlByteString *rootHash __attribute__((swift_name("rootHash")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
 *   kotlinx.serialization.SerialName(value="liteServer.getTime")
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerGetTime")))
@interface TKKTon_kotlin_liteapi_tlLiteServerGetTime : TKKBase <TKKTon_kotlin_tlTLFunction, TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)liteServerGetTime __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapi_tlLiteServerGetTime *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetTime *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetTime *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetTime *)decodeByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decode(byteString:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetTime *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetTime *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetTime *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetTime *)decodeBoxedByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decodeBoxed(byteString:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetTime *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapi_tlLiteServerGetTime *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerGetTime *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapi_tlLiteServerGetTime *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerGetTime *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_liteapi_tlLiteServerGetTime *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKTon_kotlin_tlByteString *)encodeToByteStringValue:(TKKTon_kotlin_liteapi_tlLiteServerGetTime *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteString(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_liteapi_tlLiteServerGetTime *)value __attribute__((swift_name("hash(value:)")));
- (id<TKKTon_kotlin_tlTlCodec>)resultTlCodec __attribute__((swift_name("resultTlCodec()")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializerTypeParamsSerializers:(TKKKotlinArray<id<TKKKotlinx_serialization_coreKSerializer>> *)typeParamsSerializers __attribute__((swift_name("serializer(typeParamsSerializers:)")));
- (id<TKKTon_kotlin_tlTlCodec>)tlCodec __attribute__((swift_name("tlCodec()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
 *   kotlinx.serialization.SerialName(value="liteServer.currentTime")
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerCurrentTime")))
@interface TKKTon_kotlin_liteapi_tlLiteServerCurrentTime : TKKBase
- (instancetype)initWithNow:(int32_t)now __attribute__((swift_name("init(now:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapi_tlLiteServerCurrentTimeCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapi_tlLiteServerCurrentTime *)doCopyNow:(int32_t)now __attribute__((swift_name("doCopy(now:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) int32_t now __attribute__((swift_name("now")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
 *   kotlinx.serialization.SerialName(value="liteServer.getTransactions")
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerGetTransactions")))
@interface TKKTon_kotlin_liteapi_tlLiteServerGetTransactions : TKKBase <TKKTon_kotlin_tlTLFunction>
- (instancetype)initWithCount:(int32_t)count account:(TKKTon_kotlin_liteapi_tlLiteServerAccountId *)account lt:(int64_t)lt hash:(TKKKotlinByteArray *)hash __attribute__((swift_name("init(count:account:lt:hash:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithCount:(int32_t)count account:(TKKTon_kotlin_liteapi_tlLiteServerAccountId *)account lt:(int64_t)lt hash_:(TKKTon_kotlin_tlByteString *)hash __attribute__((swift_name("init(count:account:lt:hash_:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapi_tlLiteServerGetTransactionsCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetTransactions *)doCopyCount:(int32_t)count account:(TKKTon_kotlin_liteapi_tlLiteServerAccountId *)account lt:(int64_t)lt hash:(TKKTon_kotlin_tlByteString *)hash __attribute__((swift_name("doCopy(count:account:lt:hash:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (id<TKKTon_kotlin_tlTlCodec>)resultTlCodec __attribute__((swift_name("resultTlCodec()")));
- (id<TKKTon_kotlin_tlTlCodec>)tlCodec __attribute__((swift_name("tlCodec()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) TKKTon_kotlin_liteapi_tlLiteServerAccountId *account __attribute__((swift_name("account")));
@property (readonly) int32_t count __attribute__((swift_name("count")));
@property (readonly, getter=hash_) TKKTon_kotlin_tlByteString *hash __attribute__((swift_name("hash")));
@property (readonly) int64_t lt __attribute__((swift_name("lt")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
 *   kotlinx.serialization.SerialName(value="liteServer.transactionList")
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerTransactionList")))
@interface TKKTon_kotlin_liteapi_tlLiteServerTransactionList : TKKBase
- (instancetype)initWithIds:(NSArray<TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *> *)ids transactions:(TKKTon_kotlin_tlByteString *)transactions __attribute__((swift_name("init(ids:transactions:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapi_tlLiteServerTransactionListCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapi_tlLiteServerTransactionList *)doCopyIds:(NSArray<TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *> *)ids transactions:(TKKTon_kotlin_tlByteString *)transactions __attribute__((swift_name("doCopy(ids:transactions:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSArray<TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *> *ids __attribute__((swift_name("ids")));
@property (readonly) TKKTon_kotlin_tlByteString *transactions __attribute__((swift_name("transactions")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
 *   kotlinx.serialization.SerialName(value="liteServer.getValidatorStats")
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerGetValidatorStats")))
@interface TKKTon_kotlin_liteapi_tlLiteServerGetValidatorStats : TKKBase <TKKTon_kotlin_tlTLFunction>
- (instancetype)initWithMode:(int32_t)mode id:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)id limit:(int32_t)limit startAfter:(TKKTon_kotlin_tlByteString * _Nullable)startAfter modifiedAfter:(TKKInt * _Nullable)modifiedAfter __attribute__((swift_name("init(mode:id:limit:startAfter:modifiedAfter:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapi_tlLiteServerGetValidatorStatsCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetValidatorStats *)doCopyMode:(int32_t)mode id:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)id limit:(int32_t)limit startAfter:(TKKTon_kotlin_tlByteString * _Nullable)startAfter modifiedAfter:(TKKInt * _Nullable)modifiedAfter __attribute__((swift_name("doCopy(mode:id:limit:startAfter:modifiedAfter:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (id<TKKTon_kotlin_tlTlCodec>)resultTlCodec __attribute__((swift_name("resultTlCodec()")));
- (id<TKKTon_kotlin_tlTlCodec>)tlCodec __attribute__((swift_name("tlCodec()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *id __attribute__((swift_name("id")));
@property (readonly) int32_t limit __attribute__((swift_name("limit")));
@property (readonly) int32_t mode __attribute__((swift_name("mode")));
@property (readonly) TKKInt * _Nullable modifiedAfter __attribute__((swift_name("modifiedAfter")));
@property (readonly) TKKTon_kotlin_tlByteString * _Nullable startAfter __attribute__((swift_name("startAfter")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
 *   kotlinx.serialization.SerialName(value="liteServer.validatorStats")
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerValidatorStats")))
@interface TKKTon_kotlin_liteapi_tlLiteServerValidatorStats : TKKBase
- (instancetype)initWithMode:(int32_t)mode id:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)id count:(int32_t)count complete:(BOOL)complete stateProof:(TKKTon_kotlin_tlByteString *)stateProof dataProof:(TKKTon_kotlin_tlByteString *)dataProof __attribute__((swift_name("init(mode:id:count:complete:stateProof:dataProof:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapi_tlLiteServerValidatorStatsCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapi_tlLiteServerValidatorStats *)doCopyMode:(int32_t)mode id:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)id count:(int32_t)count complete:(BOOL)complete stateProof:(TKKTon_kotlin_tlByteString *)stateProof dataProof:(TKKTon_kotlin_tlByteString *)dataProof __attribute__((swift_name("doCopy(mode:id:count:complete:stateProof:dataProof:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) BOOL complete __attribute__((swift_name("complete")));
@property (readonly) int32_t count __attribute__((swift_name("count")));

/**
 * @note annotations
 *   kotlinx.serialization.SerialName(value="data_proof")
*/
@property (readonly) TKKTon_kotlin_tlByteString *dataProof __attribute__((swift_name("dataProof")));
@property (readonly) TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *id __attribute__((swift_name("id")));
@property (readonly) int32_t mode __attribute__((swift_name("mode")));

/**
 * @note annotations
 *   kotlinx.serialization.SerialName(value="state_proof")
*/
@property (readonly) TKKTon_kotlin_tlByteString *stateProof __attribute__((swift_name("stateProof")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
 *   kotlinx.serialization.SerialName(value="liteServer.getVersion")
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerGetVersion")))
@interface TKKTon_kotlin_liteapi_tlLiteServerGetVersion : TKKBase <TKKTon_kotlin_tlTLFunction, TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)liteServerGetVersion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapi_tlLiteServerGetVersion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetVersion *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetVersion *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetVersion *)decodeByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decode(byteString:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetVersion *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetVersion *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetVersion *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetVersion *)decodeBoxedByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decodeBoxed(byteString:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetVersion *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapi_tlLiteServerGetVersion *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerGetVersion *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapi_tlLiteServerGetVersion *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerGetVersion *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_liteapi_tlLiteServerGetVersion *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKTon_kotlin_tlByteString *)encodeToByteStringValue:(TKKTon_kotlin_liteapi_tlLiteServerGetVersion *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteString(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_liteapi_tlLiteServerGetVersion *)value __attribute__((swift_name("hash(value:)")));
- (id<TKKTon_kotlin_tlTlCodec>)resultTlCodec __attribute__((swift_name("resultTlCodec()")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializerTypeParamsSerializers:(TKKKotlinArray<id<TKKKotlinx_serialization_coreKSerializer>> *)typeParamsSerializers __attribute__((swift_name("serializer(typeParamsSerializers:)")));
- (id<TKKTon_kotlin_tlTlCodec>)tlCodec __attribute__((swift_name("tlCodec()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
 *   kotlinx.serialization.SerialName(value="liteServer.listBlockTransactions")
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerListBlockTransactions")))
@interface TKKTon_kotlin_liteapi_tlLiteServerListBlockTransactions : TKKBase <TKKTon_kotlin_tlTLFunction>
- (instancetype)initWithId:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)id mode:(int32_t)mode count:(int32_t)count after:(TKKTon_kotlin_liteapi_tlLiteServerTransactionId3 * _Nullable)after reverseOrder:(BOOL)reverseOrder wantProof:(BOOL)wantProof __attribute__((swift_name("init(id:mode:count:after:reverseOrder:wantProof:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapi_tlLiteServerListBlockTransactionsCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapi_tlLiteServerListBlockTransactions *)doCopyId:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)id mode:(int32_t)mode count:(int32_t)count after:(TKKTon_kotlin_liteapi_tlLiteServerTransactionId3 * _Nullable)after reverseOrder:(BOOL)reverseOrder wantProof:(BOOL)wantProof __attribute__((swift_name("doCopy(id:mode:count:after:reverseOrder:wantProof:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (id<TKKTon_kotlin_tlTlCodec>)resultTlCodec __attribute__((swift_name("resultTlCodec()")));
- (id<TKKTon_kotlin_tlTlCodec>)tlCodec __attribute__((swift_name("tlCodec()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) TKKTon_kotlin_liteapi_tlLiteServerTransactionId3 * _Nullable after __attribute__((swift_name("after")));
@property (readonly) int32_t count __attribute__((swift_name("count")));
@property (readonly) TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *id __attribute__((swift_name("id")));
@property (readonly) int32_t mode __attribute__((swift_name("mode")));

/**
 * @note annotations
 *   kotlinx.serialization.SerialName(value="reverse_order")
*/
@property (readonly) BOOL reverseOrder __attribute__((swift_name("reverseOrder")));

/**
 * @note annotations
 *   kotlinx.serialization.SerialName(value="want_proof")
*/
@property (readonly) BOOL wantProof __attribute__((swift_name("wantProof")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
 *   kotlinx.serialization.SerialName(value="liteServer.blockTransactions")
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerBlockTransactions")))
@interface TKKTon_kotlin_liteapi_tlLiteServerBlockTransactions : TKKBase
- (instancetype)initWithId:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)id reqCount:(int32_t)reqCount incomplete:(BOOL)incomplete ids:(NSArray<TKKTon_kotlin_liteapi_tlLiteServerTransactionId *> *)ids proof:(TKKTon_kotlin_tlByteString *)proof __attribute__((swift_name("init(id:reqCount:incomplete:ids:proof:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapi_tlLiteServerBlockTransactionsCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapi_tlLiteServerBlockTransactions *)doCopyId:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)id reqCount:(int32_t)reqCount incomplete:(BOOL)incomplete ids:(NSArray<TKKTon_kotlin_liteapi_tlLiteServerTransactionId *> *)ids proof:(TKKTon_kotlin_tlByteString *)proof __attribute__((swift_name("doCopy(id:reqCount:incomplete:ids:proof:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *id __attribute__((swift_name("id")));
@property (readonly) NSArray<TKKTon_kotlin_liteapi_tlLiteServerTransactionId *> *ids __attribute__((swift_name("ids")));
@property (readonly) BOOL incomplete __attribute__((swift_name("incomplete")));
@property (readonly) TKKTon_kotlin_tlByteString *proof __attribute__((swift_name("proof")));

/**
 * @note annotations
 *   kotlinx.serialization.SerialName(value="req_count")
*/
@property (readonly) int32_t reqCount __attribute__((swift_name("reqCount")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
 *   kotlinx.serialization.SerialName(value="liteServer.lookupBlock")
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerLookupBlock")))
@interface TKKTon_kotlin_liteapi_tlLiteServerLookupBlock : TKKBase <TKKTon_kotlin_tlTLFunction>
- (instancetype)initWithMode:(int32_t)mode id:(id<TKKTon_kotlin_tonapi_tlTonNodeBlockId>)id lt:(TKKLong * _Nullable)lt utime:(TKKInt * _Nullable)utime __attribute__((swift_name("init(mode:id:lt:utime:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapi_tlLiteServerLookupBlockCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapi_tlLiteServerLookupBlock *)doCopyMode:(int32_t)mode id:(id<TKKTon_kotlin_tonapi_tlTonNodeBlockId>)id lt:(TKKLong * _Nullable)lt utime:(TKKInt * _Nullable)utime __attribute__((swift_name("doCopy(mode:id:lt:utime:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (id<TKKTon_kotlin_tlTlCodec>)resultTlCodec __attribute__((swift_name("resultTlCodec()")));
- (id<TKKTon_kotlin_tlTlCodec>)tlCodec __attribute__((swift_name("tlCodec()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) id<TKKTon_kotlin_tonapi_tlTonNodeBlockId> id __attribute__((swift_name("id")));
@property (readonly) TKKLong * _Nullable lt __attribute__((swift_name("lt")));
@property (readonly) int32_t mode __attribute__((swift_name("mode")));
@property (readonly) TKKInt * _Nullable utime __attribute__((swift_name("utime")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
 *   kotlinx.serialization.SerialName(value="liteServer.runSmcMethod")
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerRunSmcMethod")))
@interface TKKTon_kotlin_liteapi_tlLiteServerRunSmcMethod : TKKBase <TKKTon_kotlin_tlTLFunction>
- (instancetype)initWithMode:(int32_t)mode id:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)id account:(TKKTon_kotlin_liteapi_tlLiteServerAccountId *)account methodId:(int64_t)methodId params:(TKKTon_kotlin_tlByteString *)params __attribute__((swift_name("init(mode:id:account:methodId:params:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapi_tlLiteServerRunSmcMethodCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapi_tlLiteServerRunSmcMethod *)doCopyMode:(int32_t)mode id:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)id account:(TKKTon_kotlin_liteapi_tlLiteServerAccountId *)account methodId:(int64_t)methodId params:(TKKTon_kotlin_tlByteString *)params __attribute__((swift_name("doCopy(mode:id:account:methodId:params:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (id<TKKTon_kotlin_tlTlCodec>)resultTlCodec __attribute__((swift_name("resultTlCodec()")));
- (id<TKKTon_kotlin_tlTlCodec>)tlCodec __attribute__((swift_name("tlCodec()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) TKKTon_kotlin_liteapi_tlLiteServerAccountId *account __attribute__((swift_name("account")));
@property (readonly) TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *id __attribute__((swift_name("id")));

/**
 * @note annotations
 *   kotlinx.serialization.SerialName(value="method_id")
*/
@property (readonly) int64_t methodId __attribute__((swift_name("methodId")));
@property (readonly) int32_t mode __attribute__((swift_name("mode")));
@property (readonly) TKKTon_kotlin_tlByteString *params __attribute__((swift_name("params")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
 *   kotlinx.serialization.SerialName(value="liteServer.runMethodResult")
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerRunMethodResult")))
@interface TKKTon_kotlin_liteapi_tlLiteServerRunMethodResult : TKKBase
- (instancetype)initWithId:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)id shardBlock:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)shardBlock shardProof:(TKKKotlinByteArray * _Nullable)shardProof proof:(TKKKotlinByteArray * _Nullable)proof stateProof:(TKKKotlinByteArray * _Nullable)stateProof initC7:(TKKKotlinByteArray * _Nullable)initC7 libExtras:(TKKKotlinByteArray * _Nullable)libExtras exitCode:(int32_t)exitCode result:(TKKKotlinByteArray * _Nullable)result __attribute__((swift_name("init(id:shardBlock:shardProof:proof:stateProof:initC7:libExtras:exitCode:result:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapi_tlLiteServerRunMethodResultCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapi_tlLiteServerRunMethodResult *)doCopyMode:(int32_t)mode id:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)id shardBlock:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)shardBlock shardProof:(TKKTon_kotlin_tlByteString * _Nullable)shardProof proof:(TKKTon_kotlin_tlByteString * _Nullable)proof stateProof:(TKKTon_kotlin_tlByteString * _Nullable)stateProof initC7:(TKKTon_kotlin_tlByteString * _Nullable)initC7 libExtras:(TKKTon_kotlin_tlByteString * _Nullable)libExtras exitCode:(int32_t)exitCode result:(TKKTon_kotlin_tlByteString * _Nullable)result __attribute__((swift_name("doCopy(mode:id:shardBlock:shardProof:proof:stateProof:initC7:libExtras:exitCode:result:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));

/**
 * @note annotations
 *   kotlinx.serialization.SerialName(value="exit_code")
*/
@property (readonly) int32_t exitCode __attribute__((swift_name("exitCode")));
@property (readonly) TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *id __attribute__((swift_name("id")));

/**
 * @note annotations
 *   kotlinx.serialization.SerialName(value="init_c7")
*/
@property (readonly, getter=doInitC7) TKKTon_kotlin_tlByteString * _Nullable initC7 __attribute__((swift_name("initC7")));

/**
 * @note annotations
 *   kotlinx.serialization.SerialName(value="lib_extras")
*/
@property (readonly) TKKTon_kotlin_tlByteString * _Nullable libExtras __attribute__((swift_name("libExtras")));
@property (readonly) int32_t mode __attribute__((swift_name("mode")));
@property (readonly) TKKTon_kotlin_tlByteString * _Nullable proof __attribute__((swift_name("proof")));
@property (readonly) TKKTon_kotlin_tlByteString * _Nullable result __attribute__((swift_name("result")));

/**
 * @note annotations
 *   kotlinx.serialization.SerialName(value="shardblk")
*/
@property (readonly) TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *shardBlock __attribute__((swift_name("shardBlock")));

/**
 * @note annotations
 *   kotlinx.serialization.SerialName(value="shard_proof")
*/
@property (readonly) TKKTon_kotlin_tlByteString * _Nullable shardProof __attribute__((swift_name("shardProof")));

/**
 * @note annotations
 *   kotlinx.serialization.SerialName(value="state_proof")
*/
@property (readonly) TKKTon_kotlin_tlByteString * _Nullable stateProof __attribute__((swift_name("stateProof")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
 *   kotlinx.serialization.SerialName(value="liteServer.sendMessage")
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerSendMessage")))
@interface TKKTon_kotlin_liteapi_tlLiteServerSendMessage : TKKBase <TKKTon_kotlin_tlTLFunction>
- (instancetype)initWithBody:(TKKTon_kotlin_tlByteString *)body __attribute__((swift_name("init(body:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapi_tlLiteServerSendMessageCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapi_tlLiteServerSendMessage *)doCopyBody:(TKKTon_kotlin_tlByteString *)body __attribute__((swift_name("doCopy(body:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (id<TKKTon_kotlin_tlTlCodec>)resultTlCodec __attribute__((swift_name("resultTlCodec()")));
- (id<TKKTon_kotlin_tlTlCodec>)tlCodec __attribute__((swift_name("tlCodec()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) TKKTon_kotlin_tlByteString *body __attribute__((swift_name("body")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_tonapi_tlAdnlIdShort.Companion")))
@interface TKKTon_kotlin_tonapi_tlAdnlIdShortCompanion : TKKBase <TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_tonapi_tlAdnlIdShortCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_tonapi_tlAdnlIdShort *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_tonapi_tlAdnlIdShort *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_tonapi_tlAdnlIdShort *)decodeByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decode(byteString:)")));
- (TKKTon_kotlin_tonapi_tlAdnlIdShort *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_tonapi_tlAdnlIdShort *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_tonapi_tlAdnlIdShort *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_tonapi_tlAdnlIdShort *)decodeBoxedByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decodeBoxed(byteString:)")));
- (TKKTon_kotlin_tonapi_tlAdnlIdShort *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_tonapi_tlAdnlIdShort *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_tonapi_tlAdnlIdShort *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_tonapi_tlAdnlIdShort *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_tonapi_tlAdnlIdShort *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_tonapi_tlAdnlIdShort *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKTon_kotlin_tlByteString *)encodeToByteStringValue:(TKKTon_kotlin_tonapi_tlAdnlIdShort *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteString(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_tonapi_tlAdnlIdShort *)value __attribute__((swift_name("hash(value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));

/**
 * @note annotations
 *   kotlin.jvm.JvmStatic
*/
- (TKKTon_kotlin_tlTlConstructor<TKKTon_kotlin_tonapi_tlAdnlIdShort *> *)tlConstructor __attribute__((swift_name("tlConstructor()")));
@property (readonly) int32_t SIZE_BYTES __attribute__((swift_name("SIZE_BYTES")));
@end

__attribute__((swift_name("Ton_kotlin_tonapi_tlSignedTlObject")))
@protocol TKKTon_kotlin_tonapi_tlSignedTlObject <TKKTon_kotlin_tlTlObject>
@required
- (id<TKKTon_kotlin_tlTlObject>)signedPrivateKey:(id<TKKTon_kotlin_tonapi_tlPrivateKey>)privateKey __attribute__((swift_name("signed(privateKey:)")));
- (BOOL)verifyPublicKey:(id<TKKTon_kotlin_tonapi_tlPublicKey>)publicKey __attribute__((swift_name("verify(publicKey:)")));
@property (readonly) TKKTon_kotlin_tlByteString * _Nullable signature __attribute__((swift_name("signature")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
 *   kotlinx.serialization.SerialName(value="overlay.node")
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_tonapi_tlOverlayNode")))
@interface TKKTon_kotlin_tonapi_tlOverlayNode : TKKBase <TKKTon_kotlin_tonapi_tlSignedTlObject>
- (instancetype)initWithId:(id<TKKTon_kotlin_tonapi_tlPublicKey>)id overlay:(TKKKotlinByteArray *)overlay version:(int32_t)version signature:(TKKKotlinByteArray *)signature __attribute__((swift_name("init(id:overlay:version:signature:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithId:(id<TKKTon_kotlin_tonapi_tlPublicKey>)id overlay:(TKKTon_kotlin_tlByteString *)overlay version:(int32_t)version signature_:(TKKTon_kotlin_tlByteString *)signature __attribute__((swift_name("init(id:overlay:version:signature_:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_tonapi_tlOverlayNodeCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_tonapi_tlOverlayNode *)doCopyId:(id<TKKTon_kotlin_tonapi_tlPublicKey>)id overlay:(TKKTon_kotlin_tlByteString *)overlay version:(int32_t)version signature:(TKKTon_kotlin_tlByteString *)signature __attribute__((swift_name("doCopy(id:overlay:version:signature:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (TKKTon_kotlin_tonapi_tlOverlayNode *)signedPrivateKey:(id<TKKTon_kotlin_tonapi_tlPrivateKey>)privateKey __attribute__((swift_name("signed(privateKey:)")));
- (id<TKKTon_kotlin_tlTlCodec>)tlCodec __attribute__((swift_name("tlCodec()")));
- (NSString *)description __attribute__((swift_name("description()")));
- (BOOL)verifyPublicKey:(id<TKKTon_kotlin_tonapi_tlPublicKey>)publicKey __attribute__((swift_name("verify(publicKey:)")));
@property (readonly) id<TKKTon_kotlin_tonapi_tlPublicKey> id __attribute__((swift_name("id")));
@property (readonly) TKKTon_kotlin_tlByteString *overlay __attribute__((swift_name("overlay")));
@property (readonly) TKKTon_kotlin_tlByteString *signature __attribute__((swift_name("signature")));
@property (readonly) int32_t version __attribute__((swift_name("version")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_tlByteString.Companion")))
@interface TKKTon_kotlin_tlByteStringCompanion : TKKBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_tlByteStringCompanion *shared __attribute__((swift_name("shared")));

/**
 * @note annotations
 *   kotlin.jvm.JvmStatic
*/
- (TKKTon_kotlin_tlByteString *)ofBytes:(TKKKotlinByteArray *)bytes __attribute__((swift_name("of(bytes:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));

/**
 * @note annotations
 *   kotlin.jvm.JvmStatic
*/
- (TKKTon_kotlin_tlByteString *)decodeFromBase64:(NSString *)receiver __attribute__((swift_name("decodeFromBase64(_:)")));

/**
 * @note annotations
 *   kotlin.jvm.JvmStatic
*/
- (TKKTon_kotlin_tlByteString *)decodeFromHex:(NSString *)receiver __attribute__((swift_name("decodeFromHex(_:)")));

/**
 * @note annotations
 *   kotlin.jvm.JvmStatic
 *   kotlin.jvm.JvmName(name="of")
*/
- (TKKTon_kotlin_tlByteString *)toByteString:(TKKKotlinByteArray *)receiver fromIndex:(int32_t)fromIndex toIndex:(int32_t)toIndex __attribute__((swift_name("toByteString(_:fromIndex:toIndex:)")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_tlTlReader")))
@interface TKKTon_kotlin_tlTlReader : TKKBase
- (instancetype)initWithInput:(TKKKtor_ioInput *)input __attribute__((swift_name("init(input:)"))) __attribute__((objc_designated_initializer));
- (BOOL)readBoolean __attribute__((swift_name("readBoolean()")));
- (TKKTon_kotlin_tlByteString *)readByteString __attribute__((swift_name("readByteString()")));
- (TKKTon_kotlin_tlByteString *)readByteStringSize:(int32_t)size __attribute__((swift_name("readByteString(size:)")));
- (TKKKotlinByteArray *)readBytes __attribute__((swift_name("readBytes()")));
- (int32_t)readInt __attribute__((swift_name("readInt()")));
- (int64_t)readLong __attribute__((swift_name("readLong()")));
- (TKKKotlinByteArray *)readRawSize:(int32_t)size __attribute__((swift_name("readRaw(size:)")));
- (NSString *)readString __attribute__((swift_name("readString()")));
- (NSArray<id> *)readVectorBlock:(id _Nullable (^)(TKKTon_kotlin_tlTlReader *))block __attribute__((swift_name("readVector(block:)")));
@property (readonly) TKKKtor_ioInput *input __attribute__((swift_name("input")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_tlTlWriter")))
@interface TKKTon_kotlin_tlTlWriter : TKKBase
- (instancetype)initWithOutput:(TKKKtor_ioOutput *)output __attribute__((swift_name("init(output:)"))) __attribute__((objc_designated_initializer));
- (void)invokeBlock:(void (^)(TKKTon_kotlin_tlTlWriter *))block __attribute__((swift_name("invoke(block:)")));
- (void)writeBooleanValue:(BOOL)value __attribute__((swift_name("writeBoolean(value:)")));
- (void)writeBytesValue:(TKKKotlinByteArray *)value offset:(int32_t)offset length:(int32_t)length __attribute__((swift_name("writeBytes(value:offset:length:)")));
- (void)writeBytesValue:(TKKTon_kotlin_tlByteString *)value offset:(int32_t)offset length_:(int32_t)length __attribute__((swift_name("writeBytes(value:offset:length_:)")));
- (void)writeIntValue:(int32_t)value __attribute__((swift_name("writeInt(value:)")));
- (void)writeLongValue:(int64_t)value __attribute__((swift_name("writeLong(value:)")));
- (void)writeRawValue:(TKKKotlinByteArray *)value __attribute__((swift_name("writeRaw(value:)")));
- (void)writeRawValue_:(TKKTon_kotlin_tlByteString *)value __attribute__((swift_name("writeRaw(value_:)")));
- (void)writeStringValue:(NSString *)value __attribute__((swift_name("writeString(value:)")));
- (void)writeVectorValue:(id)value block:(void (^)(TKKTon_kotlin_tlTlWriter *, id _Nullable))block __attribute__((swift_name("writeVector(value:block:)")));
@property (readonly) TKKKtor_ioOutput *output __attribute__((swift_name("output")));
@end


/**
 * @note annotations
 *   kotlin.SinceKotlin(version="1.3")
*/
__attribute__((swift_name("KotlinRandom")))
@interface TKKKotlinRandom : TKKBase
- (instancetype)init __attribute__((swift_name("init()"))) __attribute__((objc_designated_initializer));
+ (instancetype)new __attribute__((availability(swift, unavailable, message="use object initializers instead")));
@property (class, readonly, getter=companion) TKKKotlinRandomDefault *companion __attribute__((swift_name("companion")));
- (int32_t)nextBitsBitCount:(int32_t)bitCount __attribute__((swift_name("nextBits(bitCount:)")));
- (BOOL)nextBoolean __attribute__((swift_name("nextBoolean()")));
- (TKKKotlinByteArray *)nextBytesArray:(TKKKotlinByteArray *)array __attribute__((swift_name("nextBytes(array:)")));
- (TKKKotlinByteArray *)nextBytesArray:(TKKKotlinByteArray *)array fromIndex:(int32_t)fromIndex toIndex:(int32_t)toIndex __attribute__((swift_name("nextBytes(array:fromIndex:toIndex:)")));
- (TKKKotlinByteArray *)nextBytesSize:(int32_t)size __attribute__((swift_name("nextBytes(size:)")));
- (double)nextDouble __attribute__((swift_name("nextDouble()")));
- (double)nextDoubleUntil:(double)until __attribute__((swift_name("nextDouble(until:)")));
- (double)nextDoubleFrom:(double)from until:(double)until __attribute__((swift_name("nextDouble(from:until:)")));
- (float)nextFloat __attribute__((swift_name("nextFloat()")));
- (int32_t)nextInt __attribute__((swift_name("nextInt()")));
- (int32_t)nextIntUntil:(int32_t)until __attribute__((swift_name("nextInt(until:)")));
- (int32_t)nextIntFrom:(int32_t)from until:(int32_t)until __attribute__((swift_name("nextInt(from:until:)")));
- (int64_t)nextLong __attribute__((swift_name("nextLong()")));
- (int64_t)nextLongUntil:(int64_t)until __attribute__((swift_name("nextLong(until:)")));
- (int64_t)nextLongFrom:(int64_t)from until:(int64_t)until __attribute__((swift_name("nextLong(from:until:)")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_tonapi_tlPublicKeyEd25519.Companion")))
@interface TKKTon_kotlin_tonapi_tlPublicKeyEd25519Companion : TKKTon_kotlin_tlTlConstructor<TKKTon_kotlin_tonapi_tlPublicKeyEd25519 *>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (instancetype)initWithSchema:(NSString *)schema id:(TKKInt * _Nullable)id __attribute__((swift_name("init(schema:id:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_tonapi_tlPublicKeyEd25519Companion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_tonapi_tlPublicKeyEd25519 *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_tonapi_tlPublicKeyEd25519 *)value __attribute__((swift_name("encode(writer:value:)")));

/**
 * @note annotations
 *   kotlin.jvm.JvmStatic
*/
- (TKKTon_kotlin_tonapi_tlPublicKeyEd25519 *)ofPrivateKey:(TKKTon_kotlin_tonapi_tlPrivateKeyEd25519 *)privateKey __attribute__((swift_name("of(privateKey:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((swift_name("Kotlinx_serialization_coreCompositeEncoder")))
@protocol TKKKotlinx_serialization_coreCompositeEncoder
@required
- (void)encodeBooleanElementDescriptor:(id<TKKKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index value:(BOOL)value __attribute__((swift_name("encodeBooleanElement(descriptor:index:value:)")));
- (void)encodeByteElementDescriptor:(id<TKKKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index value:(int8_t)value __attribute__((swift_name("encodeByteElement(descriptor:index:value:)")));
- (void)encodeCharElementDescriptor:(id<TKKKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index value:(unichar)value __attribute__((swift_name("encodeCharElement(descriptor:index:value:)")));
- (void)encodeDoubleElementDescriptor:(id<TKKKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index value:(double)value __attribute__((swift_name("encodeDoubleElement(descriptor:index:value:)")));
- (void)encodeFloatElementDescriptor:(id<TKKKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index value:(float)value __attribute__((swift_name("encodeFloatElement(descriptor:index:value:)")));
- (id<TKKKotlinx_serialization_coreEncoder>)encodeInlineElementDescriptor:(id<TKKKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index __attribute__((swift_name("encodeInlineElement(descriptor:index:)")));
- (void)encodeIntElementDescriptor:(id<TKKKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index value:(int32_t)value __attribute__((swift_name("encodeIntElement(descriptor:index:value:)")));
- (void)encodeLongElementDescriptor:(id<TKKKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index value:(int64_t)value __attribute__((swift_name("encodeLongElement(descriptor:index:value:)")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (void)encodeNullableSerializableElementDescriptor:(id<TKKKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index serializer:(id<TKKKotlinx_serialization_coreSerializationStrategy>)serializer value:(id _Nullable)value __attribute__((swift_name("encodeNullableSerializableElement(descriptor:index:serializer:value:)")));
- (void)encodeSerializableElementDescriptor:(id<TKKKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index serializer:(id<TKKKotlinx_serialization_coreSerializationStrategy>)serializer value:(id _Nullable)value __attribute__((swift_name("encodeSerializableElement(descriptor:index:serializer:value:)")));
- (void)encodeShortElementDescriptor:(id<TKKKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index value:(int16_t)value __attribute__((swift_name("encodeShortElement(descriptor:index:value:)")));
- (void)encodeStringElementDescriptor:(id<TKKKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index value:(NSString *)value __attribute__((swift_name("encodeStringElement(descriptor:index:value:)")));
- (void)endStructureDescriptor:(id<TKKKotlinx_serialization_coreSerialDescriptor>)descriptor __attribute__((swift_name("endStructure(descriptor:)")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (BOOL)shouldEncodeElementDefaultDescriptor:(id<TKKKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index __attribute__((swift_name("shouldEncodeElementDefault(descriptor:index:)")));
@property (readonly) TKKKotlinx_serialization_coreSerializersModule *serializersModule __attribute__((swift_name("serializersModule")));
@end

__attribute__((swift_name("Kotlinx_serialization_coreSerializersModule")))
@interface TKKKotlinx_serialization_coreSerializersModule : TKKBase

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (void)dumpToCollector:(id<TKKKotlinx_serialization_coreSerializersModuleCollector>)collector __attribute__((swift_name("dumpTo(collector:)")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (id<TKKKotlinx_serialization_coreKSerializer> _Nullable)getContextualKClass:(id<TKKKotlinKClass>)kClass typeArgumentsSerializers:(NSArray<id<TKKKotlinx_serialization_coreKSerializer>> *)typeArgumentsSerializers __attribute__((swift_name("getContextual(kClass:typeArgumentsSerializers:)")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (id<TKKKotlinx_serialization_coreSerializationStrategy> _Nullable)getPolymorphicBaseClass:(id<TKKKotlinKClass>)baseClass value:(id)value __attribute__((swift_name("getPolymorphic(baseClass:value:)")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (id<TKKKotlinx_serialization_coreDeserializationStrategy> _Nullable)getPolymorphicBaseClass:(id<TKKKotlinKClass>)baseClass serializedClassName:(NSString * _Nullable)serializedClassName __attribute__((swift_name("getPolymorphic(baseClass:serializedClassName:)")));
@end

__attribute__((swift_name("KotlinAnnotation")))
@protocol TKKKotlinAnnotation
@required
@end


/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
__attribute__((swift_name("Kotlinx_serialization_coreSerialKind")))
@interface TKKKotlinx_serialization_coreSerialKind : TKKBase
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@end

__attribute__((swift_name("Kotlinx_serialization_coreCompositeDecoder")))
@protocol TKKKotlinx_serialization_coreCompositeDecoder
@required
- (BOOL)decodeBooleanElementDescriptor:(id<TKKKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index __attribute__((swift_name("decodeBooleanElement(descriptor:index:)")));
- (int8_t)decodeByteElementDescriptor:(id<TKKKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index __attribute__((swift_name("decodeByteElement(descriptor:index:)")));
- (unichar)decodeCharElementDescriptor:(id<TKKKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index __attribute__((swift_name("decodeCharElement(descriptor:index:)")));
- (int32_t)decodeCollectionSizeDescriptor:(id<TKKKotlinx_serialization_coreSerialDescriptor>)descriptor __attribute__((swift_name("decodeCollectionSize(descriptor:)")));
- (double)decodeDoubleElementDescriptor:(id<TKKKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index __attribute__((swift_name("decodeDoubleElement(descriptor:index:)")));
- (int32_t)decodeElementIndexDescriptor:(id<TKKKotlinx_serialization_coreSerialDescriptor>)descriptor __attribute__((swift_name("decodeElementIndex(descriptor:)")));
- (float)decodeFloatElementDescriptor:(id<TKKKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index __attribute__((swift_name("decodeFloatElement(descriptor:index:)")));
- (id<TKKKotlinx_serialization_coreDecoder>)decodeInlineElementDescriptor:(id<TKKKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index __attribute__((swift_name("decodeInlineElement(descriptor:index:)")));
- (int32_t)decodeIntElementDescriptor:(id<TKKKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index __attribute__((swift_name("decodeIntElement(descriptor:index:)")));
- (int64_t)decodeLongElementDescriptor:(id<TKKKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index __attribute__((swift_name("decodeLongElement(descriptor:index:)")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (id _Nullable)decodeNullableSerializableElementDescriptor:(id<TKKKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index deserializer:(id<TKKKotlinx_serialization_coreDeserializationStrategy>)deserializer previousValue:(id _Nullable)previousValue __attribute__((swift_name("decodeNullableSerializableElement(descriptor:index:deserializer:previousValue:)")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (BOOL)decodeSequentially __attribute__((swift_name("decodeSequentially()")));
- (id _Nullable)decodeSerializableElementDescriptor:(id<TKKKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index deserializer:(id<TKKKotlinx_serialization_coreDeserializationStrategy>)deserializer previousValue:(id _Nullable)previousValue __attribute__((swift_name("decodeSerializableElement(descriptor:index:deserializer:previousValue:)")));
- (int16_t)decodeShortElementDescriptor:(id<TKKKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index __attribute__((swift_name("decodeShortElement(descriptor:index:)")));
- (NSString *)decodeStringElementDescriptor:(id<TKKKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index __attribute__((swift_name("decodeStringElement(descriptor:index:)")));
- (void)endStructureDescriptor:(id<TKKKotlinx_serialization_coreSerialDescriptor>)descriptor __attribute__((swift_name("endStructure(descriptor:)")));
@property (readonly) TKKKotlinx_serialization_coreSerializersModule *serializersModule __attribute__((swift_name("serializersModule")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("KotlinNothing")))
@interface TKKKotlinNothing : TKKBase
@end

__attribute__((swift_name("KotlinBooleanIterator")))
@interface TKKKotlinBooleanIterator : TKKBase <TKKKotlinIterator>
- (instancetype)init __attribute__((swift_name("init()"))) __attribute__((objc_designated_initializer));
+ (instancetype)new __attribute__((availability(swift, unavailable, message="use object initializers instead")));
- (TKKBoolean *)next __attribute__((swift_name("next()")));
- (BOOL)nextBoolean __attribute__((swift_name("nextBoolean()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("KotlinIntProgression.Companion")))
@interface TKKKotlinIntProgressionCompanion : TKKBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKKotlinIntProgressionCompanion *shared __attribute__((swift_name("shared")));
- (TKKKotlinIntProgression *)fromClosedRangeRangeStart:(int32_t)rangeStart rangeEnd:(int32_t)rangeEnd step:(int32_t)step __attribute__((swift_name("fromClosedRange(rangeStart:rangeEnd:step:)")));
@end

__attribute__((swift_name("KotlinIntIterator")))
@interface TKKKotlinIntIterator : TKKBase <TKKKotlinIterator>
- (instancetype)init __attribute__((swift_name("init()"))) __attribute__((objc_designated_initializer));
+ (instancetype)new __attribute__((availability(swift, unavailable, message="use object initializers instead")));
- (TKKInt *)next __attribute__((swift_name("next()")));
- (int32_t)nextInt __attribute__((swift_name("nextInt()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("KotlinIntRange.Companion")))
@interface TKKKotlinIntRangeCompanion : TKKBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKKotlinIntRangeCompanion *shared __attribute__((swift_name("shared")));
@property (readonly) TKKKotlinIntRange *EMPTY __attribute__((swift_name("EMPTY")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("KotlinCharArray")))
@interface TKKKotlinCharArray : TKKBase
+ (instancetype)arrayWithSize:(int32_t)size __attribute__((swift_name("init(size:)")));
+ (instancetype)arrayWithSize:(int32_t)size init:(id (^)(TKKInt *))init __attribute__((swift_name("init(size:init:)")));
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (unichar)getIndex:(int32_t)index __attribute__((swift_name("get(index:)")));
- (TKKKotlinCharIterator *)iterator __attribute__((swift_name("iterator()")));
- (void)setIndex:(int32_t)index value:(unichar)value __attribute__((swift_name("set(index:value:)")));
@property (readonly) int32_t size __attribute__((swift_name("size")));
@end

__attribute__((swift_name("KotlinNumber")))
@interface TKKKotlinNumber : TKKBase
- (instancetype)init __attribute__((swift_name("init()"))) __attribute__((objc_designated_initializer));
+ (instancetype)new __attribute__((availability(swift, unavailable, message="use object initializers instead")));
- (int8_t)toByte __attribute__((swift_name("toByte()")));

/**
 * @note annotations
 *   kotlin.DeprecatedSinceKotlin(warningSince="1.9", errorSince="2.3")
*/
- (unichar)toChar __attribute__((swift_name("toChar()"))) __attribute__((deprecated("Direct conversion to Char is deprecated. Use toInt().toChar() or Char constructor instead.\nIf you override toChar() function in your Number inheritor, it's recommended to gradually deprecate the overriding function and then remove it.\nSee https://youtrack.jetbrains.com/issue/KT-46465 for details about the migration")));
- (double)toDouble __attribute__((swift_name("toDouble()")));
- (float)toFloat __attribute__((swift_name("toFloat()")));
- (int32_t)toInt __attribute__((swift_name("toInt()")));
- (int64_t)toLong __attribute__((swift_name("toLong()")));
- (int16_t)toShort __attribute__((swift_name("toShort()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_bigintBigInt")))
@interface TKKTon_kotlin_bigintBigInt : TKKKotlinNumber <TKKKotlinComparable>
- (instancetype)initWithString:(NSString *)string __attribute__((swift_name("init(string:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithString:(NSString *)string radix:(int32_t)radix __attribute__((swift_name("init(string:radix:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("init(byteArray:)"))) __attribute__((objc_designated_initializer));
- (instancetype)init __attribute__((swift_name("init()"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
+ (instancetype)new __attribute__((unavailable));
- (int32_t)compareToOther:(TKKTon_kotlin_bigintBigInt *)other __attribute__((swift_name("compareTo(other:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (int8_t)toByte __attribute__((swift_name("toByte()")));
- (TKKKotlinByteArray *)toByteArray __attribute__((swift_name("toByteArray()")));
- (unichar)toChar __attribute__((swift_name("toChar()"))) __attribute__((deprecated("Direct conversion to Char is deprecated. Use toInt().toChar() or Char constructor instead.\nIf you override toChar() function in your Number inheritor, it's recommended to gradually deprecate the overriding function and then remove it.\nSee https://youtrack.jetbrains.com/issue/KT-46465 for details about the migration")));
- (double)toDouble __attribute__((swift_name("toDouble()")));
- (float)toFloat __attribute__((swift_name("toFloat()")));
- (int32_t)toInt __attribute__((swift_name("toInt()")));
- (int64_t)toLong __attribute__((swift_name("toLong()")));
- (int16_t)toShort __attribute__((swift_name("toShort()")));
- (NSString *)toStringRadix:(int32_t)radix __attribute__((swift_name("toString(radix:)")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_tlbAbstractTlbConstructorCompanion")))
@interface TKKTon_kotlin_tlbAbstractTlbConstructorCompanion : TKKBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_tlbAbstractTlbConstructorCompanion *shared __attribute__((swift_name("shared")));

/**
 * @note annotations
 *   kotlin.jvm.JvmStatic
*/
- (id<TKKTon_kotlin_bitstringBitString>)calculateIdSchema:(NSString *)schema __attribute__((swift_name("calculateId(schema:)")));
- (NSString *)formatSchemaSchema:(NSString *)schema __attribute__((swift_name("formatSchema(schema:)")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_tonapi_tlDhtNode")))
@interface TKKTon_kotlin_tonapi_tlDhtNode : TKKBase <TKKTon_kotlin_tonapi_tlSignedTlObject>
- (instancetype)initWithId:(id<TKKTon_kotlin_tonapi_tlPublicKey>)id addrList:(TKKTon_kotlin_tonapi_tlAdnlAddressList *)addrList version:(int32_t)version signature:(TKKTon_kotlin_tlByteString *)signature __attribute__((swift_name("init(id:addrList:version:signature:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_tonapi_tlDhtNodeCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_tonapi_tlDhtNode *)doCopyId:(id<TKKTon_kotlin_tonapi_tlPublicKey>)id addrList:(TKKTon_kotlin_tonapi_tlAdnlAddressList *)addrList version:(int32_t)version signature:(TKKTon_kotlin_tlByteString *)signature __attribute__((swift_name("doCopy(id:addrList:version:signature:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (TKKTon_kotlin_tonapi_tlAdnlIdShort *)key __attribute__((swift_name("key()")));
- (TKKTon_kotlin_tonapi_tlDhtNode *)signedPrivateKey:(id<TKKTon_kotlin_tonapi_tlPrivateKey>)privateKey __attribute__((swift_name("signed(privateKey:)")));
- (id<TKKTon_kotlin_tlTlCodec>)tlCodec __attribute__((swift_name("tlCodec()")));
- (TKKTon_kotlin_tonapi_tlAdnlNode *)toAdnlNode __attribute__((swift_name("toAdnlNode()")));
- (NSString *)description __attribute__((swift_name("description()")));
- (BOOL)verifyPublicKey:(id<TKKTon_kotlin_tonapi_tlPublicKey>)publicKey __attribute__((swift_name("verify(publicKey:)")));

/**
 * @note annotations
 *   kotlinx.serialization.SerialName(value="addr_list")
*/
@property (readonly) TKKTon_kotlin_tonapi_tlAdnlAddressList *addrList __attribute__((swift_name("addrList")));
@property (readonly) id<TKKTon_kotlin_tonapi_tlPublicKey> id __attribute__((swift_name("id")));
@property (readonly) TKKTon_kotlin_tlByteString *signature __attribute__((swift_name("signature")));
@property (readonly) int32_t version __attribute__((swift_name("version")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_tonapi_tlDhtNodes")))
@interface TKKTon_kotlin_tonapi_tlDhtNodes : TKKBase <TKKTon_kotlin_tlTlObject>
- (instancetype)initWithNodes:(NSArray<TKKTon_kotlin_tonapi_tlDhtNode *> *)nodes __attribute__((swift_name("init(nodes:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_tonapi_tlDhtNodesCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_tonapi_tlDhtNodes *)doCopyNodes:(NSArray<TKKTon_kotlin_tonapi_tlDhtNode *> *)nodes __attribute__((swift_name("doCopy(nodes:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (id<TKKTon_kotlin_tlTlCodec>)tlCodec __attribute__((swift_name("tlCodec()")));
- (TKKTon_kotlin_tonapi_tlAdnlNodes *)toAdnlNodes __attribute__((swift_name("toAdnlNodes()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSArray<TKKTon_kotlin_tonapi_tlDhtNode *> *nodes __attribute__((swift_name("nodes")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_tonapi_tlDhtConfigGlobal.Companion")))
@interface TKKTon_kotlin_tonapi_tlDhtConfigGlobalCompanion : TKKTon_kotlin_tlTlConstructor<TKKTon_kotlin_tonapi_tlDhtConfigGlobal *>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (instancetype)initWithSchema:(NSString *)schema id:(TKKInt * _Nullable)id __attribute__((swift_name("init(schema:id:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_tonapi_tlDhtConfigGlobalCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_tonapi_tlDhtConfigGlobal *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_tonapi_tlDhtConfigGlobal *)value __attribute__((swift_name("encode(writer:value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_tonapi_tlValidatorConfigGlobal.Companion")))
@interface TKKTon_kotlin_tonapi_tlValidatorConfigGlobalCompanion : TKKBase <TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_tonapi_tlValidatorConfigGlobalCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_tonapi_tlValidatorConfigGlobal *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_tonapi_tlValidatorConfigGlobal *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_tonapi_tlValidatorConfigGlobal *)decodeByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decode(byteString:)")));
- (TKKTon_kotlin_tonapi_tlValidatorConfigGlobal *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_tonapi_tlValidatorConfigGlobal *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_tonapi_tlValidatorConfigGlobal *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_tonapi_tlValidatorConfigGlobal *)decodeBoxedByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decodeBoxed(byteString:)")));
- (TKKTon_kotlin_tonapi_tlValidatorConfigGlobal *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_tonapi_tlValidatorConfigGlobal *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_tonapi_tlValidatorConfigGlobal *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_tonapi_tlValidatorConfigGlobal *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_tonapi_tlValidatorConfigGlobal *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_tonapi_tlValidatorConfigGlobal *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKTon_kotlin_tlByteString *)encodeToByteStringValue:(TKKTon_kotlin_tonapi_tlValidatorConfigGlobal *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteString(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_tonapi_tlValidatorConfigGlobal *)value __attribute__((swift_name("hash(value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((swift_name("Ton_kotlin_tlbAbstractTlbCombinator")))
@interface TKKTon_kotlin_tlbAbstractTlbCombinator<T> : TKKBase <TKKTon_kotlin_tlbTlbCodec>
- (instancetype)init __attribute__((swift_name("init()"))) __attribute__((objc_designated_initializer));
+ (instancetype)new __attribute__((availability(swift, unavailable, message="use object initializers instead")));
@property (readonly) id<TKKKotlinKClass> baseClass __attribute__((swift_name("baseClass")));
@end

__attribute__((swift_name("Ton_kotlin_tlbTlbCombinator")))
@interface TKKTon_kotlin_tlbTlbCombinator<T> : TKKTon_kotlin_tlbAbstractTlbCombinator<T> <TKKTon_kotlin_tlbTlbCombinatorProvider>
- (instancetype)initWithBaseClass:(id<TKKKotlinKClass>)baseClass subClasses:(TKKKotlinArray<TKKKotlinPair<id<TKKKotlinKClass>, id<TKKTon_kotlin_tlbTlbCodec>> *> *)subClasses __attribute__((swift_name("init(baseClass:subClasses:)"))) __attribute__((objc_designated_initializer));
- (instancetype)init __attribute__((swift_name("init()"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
+ (instancetype)new __attribute__((unavailable));

/**
 * @note This method has protected visibility in Kotlin source and is intended only for use by subclasses.
*/
- (id<TKKTon_kotlin_tlbTlbLoader> _Nullable)findTlbLoaderOrNullBitString:(id<TKKTon_kotlin_bitstringBitString>)bitString __attribute__((swift_name("findTlbLoaderOrNull(bitString:)")));

/**
 * @note This method has protected visibility in Kotlin source and is intended only for use by subclasses.
*/
- (id<TKKTon_kotlin_tlbTlbLoader> _Nullable)findTlbLoaderOrNullCellSlice:(id<TKKTon_kotlin_tvmCellSlice>)cellSlice __attribute__((swift_name("findTlbLoaderOrNull(cellSlice:)")));

/**
 * @note This method has protected visibility in Kotlin source and is intended only for use by subclasses.
*/
- (id<TKKTon_kotlin_tlbTlbStorer> _Nullable)findTlbStorerOrNullValue:(T)value __attribute__((swift_name("findTlbStorerOrNull(value:)")));
- (T)loadTlbCellSlice:(id<TKKTon_kotlin_tvmCellSlice>)cellSlice __attribute__((swift_name("loadTlb(cellSlice:)")));
- (void)storeTlbCellBuilder:(id<TKKTon_kotlin_tvmCellBuilder>)cellBuilder value:(T)value __attribute__((swift_name("storeTlb(cellBuilder:value:)")));
- (TKKTon_kotlin_tlbTlbCombinator<T> *)tlbCombinator __attribute__((swift_name("tlbCombinator()")));
@property (readonly) id<TKKKotlinKClass> baseClass __attribute__((swift_name("baseClass")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((swift_name("Ton_kotlin_block_tlbVmCont")))
@protocol TKKTon_kotlin_block_tlbVmCont
@required
@end


/**
 * @note annotations
 *   kotlinx.serialization.SerialName(value="vm_stk_null")
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_block_tlbVmStackNull")))
@interface TKKTon_kotlin_block_tlbVmStackNull : TKKBase <TKKTon_kotlin_block_tlbVmStackValue, TKKTon_kotlin_tlbTlbConstructorProvider>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)vmStackNull __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_block_tlbVmStackNull *shared __attribute__((swift_name("shared")));
- (id<TKKTon_kotlin_tvmCell>)createCellValue:(TKKTon_kotlin_block_tlbVmStackNull *)value __attribute__((swift_name("createCell(value:)")));
- (TKKTon_kotlin_block_tlbVmStackNull *)loadTlbCell:(id<TKKTon_kotlin_tvmCell>)cell __attribute__((swift_name("loadTlb(cell:)")));
- (TKKTon_kotlin_block_tlbVmStackNull *)loadTlbCellSlice:(id<TKKTon_kotlin_tvmCellSlice>)cellSlice __attribute__((swift_name("loadTlb(cellSlice:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializerTypeParamsSerializers:(TKKKotlinArray<id<TKKKotlinx_serialization_coreKSerializer>> *)typeParamsSerializers __attribute__((swift_name("serializer(typeParamsSerializers:)")));
- (void)storeTlbCellBuilder:(id<TKKTon_kotlin_tvmCellBuilder>)cellBuilder value:(TKKTon_kotlin_block_tlbVmStackNull *)value __attribute__((swift_name("storeTlb(cellBuilder:value:)")));
- (TKKTon_kotlin_tlbTlbConstructor<TKKTon_kotlin_block_tlbVmStackNull *> *)tlbConstructor __attribute__((swift_name("tlbConstructor()")));
- (NSString *)description __attribute__((swift_name("description()")));
@end

__attribute__((swift_name("Ton_kotlin_block_tlbVmStackNumber")))
@protocol TKKTon_kotlin_block_tlbVmStackNumber <TKKTon_kotlin_block_tlbVmStackValue>
@required
- (id<TKKTon_kotlin_block_tlbVmStackNumber>)divOther:(id<TKKTon_kotlin_block_tlbVmStackNumber>)other __attribute__((swift_name("div(other:)")));
- (id<TKKTon_kotlin_block_tlbVmStackNumber>)minusOther:(id<TKKTon_kotlin_block_tlbVmStackNumber>)other __attribute__((swift_name("minus(other:)")));
- (id<TKKTon_kotlin_block_tlbVmStackNumber>)plusOther:(id<TKKTon_kotlin_block_tlbVmStackNumber>)other __attribute__((swift_name("plus(other:)")));
- (id<TKKTon_kotlin_block_tlbVmStackNumber>)timesOther:(id<TKKTon_kotlin_block_tlbVmStackNumber>)other __attribute__((swift_name("times(other:)")));
- (TKKTon_kotlin_bigintBigInt *)toBigInt __attribute__((swift_name("toBigInt()")));
- (BOOL)toBoolean __attribute__((swift_name("toBoolean()")));
- (int32_t)toInt __attribute__((swift_name("toInt()")));
- (int64_t)toLong __attribute__((swift_name("toLong()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((swift_name("Ton_kotlin_block_tlbVmTuple")))
@protocol TKKTon_kotlin_block_tlbVmTuple
@required
- (int32_t)depth_ __attribute__((swift_name("depth()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_tvmCellType.Companion")))
@interface TKKTon_kotlin_tvmCellTypeCompanion : TKKBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_tvmCellTypeCompanion *shared __attribute__((swift_name("shared")));

/**
 * @note annotations
 *   kotlin.jvm.JvmStatic
*/
- (TKKTon_kotlin_tvmCellType *)getIndex:(int32_t)index __attribute__((swift_name("get(index:)")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("KotlinPair")))
@interface TKKKotlinPair<__covariant A, __covariant B> : TKKBase
- (instancetype)initWithFirst:(A _Nullable)first second:(B _Nullable)second __attribute__((swift_name("init(first:second:)"))) __attribute__((objc_designated_initializer));
- (TKKKotlinPair<A, B> *)doCopyFirst:(A _Nullable)first second:(B _Nullable)second __attribute__((swift_name("doCopy(first:second:)")));
- (BOOL)equalsOther:(id _Nullable)other __attribute__((swift_name("equals(other:)")));
- (int32_t)hashCode __attribute__((swift_name("hashCode()")));
- (NSString *)toString __attribute__((swift_name("toString()")));
@property (readonly) A _Nullable first __attribute__((swift_name("first")));
@property (readonly) B _Nullable second __attribute__((swift_name("second")));
@end

__attribute__((swift_name("Ktor_ioObjectPool")))
@protocol TKKKtor_ioObjectPool <TKKKtor_ioCloseable>
@required
- (id)borrow __attribute__((swift_name("borrow()")));
- (void)dispose __attribute__((swift_name("dispose()")));
- (void)recycleInstance:(id)instance __attribute__((swift_name("recycle(instance:)")));
@property (readonly) int32_t capacity __attribute__((swift_name("capacity")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ktor_ioMemory")))
@interface TKKKtor_ioMemory : TKKBase
- (instancetype)initWithPointer:(void *)pointer size:(int64_t)size __attribute__((swift_name("init(pointer:size:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKKtor_ioMemoryCompanion *companion __attribute__((swift_name("companion")));
- (void)doCopyToDestination:(TKKKtor_ioMemory *)destination offset:(int32_t)offset length:(int32_t)length destinationOffset:(int32_t)destinationOffset __attribute__((swift_name("doCopyTo(destination:offset:length:destinationOffset:)")));
- (void)doCopyToDestination:(TKKKtor_ioMemory *)destination offset:(int64_t)offset length:(int64_t)length destinationOffset_:(int64_t)destinationOffset __attribute__((swift_name("doCopyTo(destination:offset:length:destinationOffset_:)")));
- (int8_t)loadAtIndex:(int32_t)index __attribute__((swift_name("loadAt(index:)")));
- (int8_t)loadAtIndex_:(int64_t)index __attribute__((swift_name("loadAt(index_:)")));
- (TKKKtor_ioMemory *)sliceOffset:(int32_t)offset length:(int32_t)length __attribute__((swift_name("slice(offset:length:)")));
- (TKKKtor_ioMemory *)sliceOffset:(int64_t)offset length_:(int64_t)length __attribute__((swift_name("slice(offset:length_:)")));
- (void)storeAtIndex:(int32_t)index value:(int8_t)value __attribute__((swift_name("storeAt(index:value:)")));
- (void)storeAtIndex:(int64_t)index value_:(int8_t)value __attribute__((swift_name("storeAt(index:value_:)")));
@property (readonly) void *pointer __attribute__((swift_name("pointer")));
@property (readonly) int64_t size __attribute__((swift_name("size")));
@property (readonly) int32_t size32 __attribute__((swift_name("size32")));
@end

__attribute__((swift_name("Ktor_ioBuffer")))
@interface TKKKtor_ioBuffer : TKKBase
- (instancetype)initWithMemory:(TKKKtor_ioMemory *)memory __attribute__((swift_name("init(memory:)"))) __attribute__((objc_designated_initializer)) __attribute__((deprecated("\n    We're migrating to the new kotlinx-io library.\n    This declaration is deprecated and will be removed in Ktor 4.0.0\n    If you have any problems with migration, please contact us in \n    https://youtrack.jetbrains.com/issue/KTOR-6030/Migrate-to-new-kotlinx.io-library\n    ")));
@property (class, readonly, getter=companion) TKKKtor_ioBufferCompanion *companion __attribute__((swift_name("companion")));
- (void)commitWrittenCount:(int32_t)count __attribute__((swift_name("commitWritten(count:)")));
- (void)discardExactCount:(int32_t)count __attribute__((swift_name("discardExact(count:)")));
- (TKKKtor_ioBuffer *)duplicate __attribute__((swift_name("duplicate()")));

/**
 * @note This method has protected visibility in Kotlin source and is intended only for use by subclasses.
*/
- (void)duplicateToCopy:(TKKKtor_ioBuffer *)copy __attribute__((swift_name("duplicateTo(copy:)")));
- (int8_t)readByte __attribute__((swift_name("readByte()")));
- (void)reserveEndGapEndGap:(int32_t)endGap __attribute__((swift_name("reserveEndGap(endGap:)")));
- (void)reserveStartGapStartGap:(int32_t)startGap __attribute__((swift_name("reserveStartGap(startGap:)")));
- (void)reset __attribute__((swift_name("reset()")));
- (void)resetForRead __attribute__((swift_name("resetForRead()")));
- (void)resetForWrite __attribute__((swift_name("resetForWrite()")));
- (void)resetForWriteLimit:(int32_t)limit __attribute__((swift_name("resetForWrite(limit:)")));
- (void)rewindCount:(int32_t)count __attribute__((swift_name("rewind(count:)")));
- (NSString *)description __attribute__((swift_name("description()")));
- (int32_t)tryPeekByte __attribute__((swift_name("tryPeekByte()")));
- (int32_t)tryReadByte __attribute__((swift_name("tryReadByte()")));
- (void)writeByteValue:(int8_t)value __attribute__((swift_name("writeByte(value:)")));
@property (readonly) int32_t capacity __attribute__((swift_name("capacity")));
@property (readonly) int32_t endGap __attribute__((swift_name("endGap")));
@property (readonly) int32_t limit __attribute__((swift_name("limit")));
@property (readonly) TKKKtor_ioMemory *memory __attribute__((swift_name("memory")));
@property (readonly) int32_t readPosition __attribute__((swift_name("readPosition")));
@property (readonly) int32_t readRemaining __attribute__((swift_name("readRemaining")));
@property (readonly) int32_t startGap __attribute__((swift_name("startGap")));
@property (readonly) int32_t writePosition __attribute__((swift_name("writePosition")));
@property (readonly) int32_t writeRemaining __attribute__((swift_name("writeRemaining")));
@end

__attribute__((swift_name("Ktor_ioChunkBuffer")))
@interface TKKKtor_ioChunkBuffer : TKKKtor_ioBuffer
- (instancetype)initWithMemory:(TKKKtor_ioMemory *)memory origin:(TKKKtor_ioChunkBuffer * _Nullable)origin parentPool:(id<TKKKtor_ioObjectPool> _Nullable)parentPool __attribute__((swift_name("init(memory:origin:parentPool:)"))) __attribute__((objc_designated_initializer)) __attribute__((deprecated("\n    We're migrating to the new kotlinx-io library.\n    This declaration is deprecated and will be removed in Ktor 4.0.0\n    If you have any problems with migration, please contact us in \n    https://youtrack.jetbrains.com/issue/KTOR-6030/Migrate-to-new-kotlinx.io-library\n    ")));
- (instancetype)initWithMemory:(TKKKtor_ioMemory *)memory __attribute__((swift_name("init(memory:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
@property (class, readonly, getter=companion) TKKKtor_ioChunkBufferCompanion *companion __attribute__((swift_name("companion")));
- (TKKKtor_ioChunkBuffer * _Nullable)cleanNext __attribute__((swift_name("cleanNext()")));
- (TKKKtor_ioChunkBuffer *)duplicate __attribute__((swift_name("duplicate()")));
- (void)releasePool:(id<TKKKtor_ioObjectPool>)pool __attribute__((swift_name("release(pool:)")));
- (void)reset __attribute__((swift_name("reset()")));
@property (getter=next_) TKKKtor_ioChunkBuffer * _Nullable next __attribute__((swift_name("next")));
@property (readonly) TKKKtor_ioChunkBuffer * _Nullable origin __attribute__((swift_name("origin")));
@property (readonly) int32_t referenceCount __attribute__((swift_name("referenceCount")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ktor_ioInput.Companion")))
@interface TKKKtor_ioInputCompanion : TKKBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKKtor_ioInputCompanion *shared __attribute__((swift_name("shared")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ktor_ioByteReadPacket.Companion")))
@interface TKKKtor_ioByteReadPacketCompanion : TKKBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKKtor_ioByteReadPacketCompanion *shared __attribute__((swift_name("shared")));
@property (readonly) TKKKtor_ioByteReadPacket *Empty __attribute__((swift_name("Empty")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerGetAccountState.Companion")))
@interface TKKTon_kotlin_liteapi_tlLiteServerGetAccountStateCompanion : TKKBase <TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapi_tlLiteServerGetAccountStateCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetAccountState *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetAccountState *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetAccountState *)decodeByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decode(byteString:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetAccountState *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetAccountState *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetAccountState *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetAccountState *)decodeBoxedByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decodeBoxed(byteString:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetAccountState *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapi_tlLiteServerGetAccountState *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerGetAccountState *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapi_tlLiteServerGetAccountState *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerGetAccountState *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_liteapi_tlLiteServerGetAccountState *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKTon_kotlin_tlByteString *)encodeToByteStringValue:(TKKTon_kotlin_liteapi_tlLiteServerGetAccountState *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteString(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_liteapi_tlLiteServerGetAccountState *)value __attribute__((swift_name("hash(value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerAccountState.Companion")))
@interface TKKTon_kotlin_liteapi_tlLiteServerAccountStateCompanion : TKKTon_kotlin_tlTlConstructor<TKKTon_kotlin_liteapi_tlLiteServerAccountState *>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (instancetype)initWithSchema:(NSString *)schema id:(TKKInt * _Nullable)id __attribute__((swift_name("init(schema:id:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapi_tlLiteServerAccountStateCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapi_tlLiteServerAccountState *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerAccountState *)value __attribute__((swift_name("encode(writer:value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerGetAllShardsInfo.Companion")))
@interface TKKTon_kotlin_liteapi_tlLiteServerGetAllShardsInfoCompanion : TKKBase <TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapi_tlLiteServerGetAllShardsInfoCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetAllShardsInfo *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetAllShardsInfo *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetAllShardsInfo *)decodeByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decode(byteString:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetAllShardsInfo *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetAllShardsInfo *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetAllShardsInfo *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetAllShardsInfo *)decodeBoxedByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decodeBoxed(byteString:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetAllShardsInfo *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapi_tlLiteServerGetAllShardsInfo *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerGetAllShardsInfo *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapi_tlLiteServerGetAllShardsInfo *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerGetAllShardsInfo *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_liteapi_tlLiteServerGetAllShardsInfo *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKTon_kotlin_tlByteString *)encodeToByteStringValue:(TKKTon_kotlin_liteapi_tlLiteServerGetAllShardsInfo *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteString(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_liteapi_tlLiteServerGetAllShardsInfo *)value __attribute__((swift_name("hash(value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerAllShardsInfo.Companion")))
@interface TKKTon_kotlin_liteapi_tlLiteServerAllShardsInfoCompanion : TKKBase <TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapi_tlLiteServerAllShardsInfoCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapi_tlLiteServerAllShardsInfo *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerAllShardsInfo *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerAllShardsInfo *)decodeByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decode(byteString:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerAllShardsInfo *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerAllShardsInfo *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerAllShardsInfo *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerAllShardsInfo *)decodeBoxedByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decodeBoxed(byteString:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerAllShardsInfo *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapi_tlLiteServerAllShardsInfo *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerAllShardsInfo *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapi_tlLiteServerAllShardsInfo *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerAllShardsInfo *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_liteapi_tlLiteServerAllShardsInfo *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKTon_kotlin_tlByteString *)encodeToByteStringValue:(TKKTon_kotlin_liteapi_tlLiteServerAllShardsInfo *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteString(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_liteapi_tlLiteServerAllShardsInfo *)value __attribute__((swift_name("hash(value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerGetBlock.Companion")))
@interface TKKTon_kotlin_liteapi_tlLiteServerGetBlockCompanion : TKKBase <TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapi_tlLiteServerGetBlockCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetBlock *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetBlock *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetBlock *)decodeByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decode(byteString:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetBlock *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetBlock *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetBlock *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetBlock *)decodeBoxedByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decodeBoxed(byteString:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetBlock *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapi_tlLiteServerGetBlock *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerGetBlock *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapi_tlLiteServerGetBlock *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerGetBlock *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_liteapi_tlLiteServerGetBlock *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKTon_kotlin_tlByteString *)encodeToByteStringValue:(TKKTon_kotlin_liteapi_tlLiteServerGetBlock *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteString(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_liteapi_tlLiteServerGetBlock *)value __attribute__((swift_name("hash(value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerBlockData.Companion")))
@interface TKKTon_kotlin_liteapi_tlLiteServerBlockDataCompanion : TKKTon_kotlin_tlTlConstructor<TKKTon_kotlin_liteapi_tlLiteServerBlockData *>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (instancetype)initWithSchema:(NSString *)schema id:(TKKInt * _Nullable)id __attribute__((swift_name("init(schema:id:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapi_tlLiteServerBlockDataCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapi_tlLiteServerBlockData *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerBlockData *)value __attribute__((swift_name("encode(writer:value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerGetBlockHeader.Companion")))
@interface TKKTon_kotlin_liteapi_tlLiteServerGetBlockHeaderCompanion : TKKBase <TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapi_tlLiteServerGetBlockHeaderCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetBlockHeader *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetBlockHeader *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetBlockHeader *)decodeByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decode(byteString:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetBlockHeader *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetBlockHeader *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetBlockHeader *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetBlockHeader *)decodeBoxedByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decodeBoxed(byteString:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetBlockHeader *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapi_tlLiteServerGetBlockHeader *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerGetBlockHeader *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapi_tlLiteServerGetBlockHeader *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerGetBlockHeader *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_liteapi_tlLiteServerGetBlockHeader *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKTon_kotlin_tlByteString *)encodeToByteStringValue:(TKKTon_kotlin_liteapi_tlLiteServerGetBlockHeader *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteString(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_liteapi_tlLiteServerGetBlockHeader *)value __attribute__((swift_name("hash(value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerBlockHeader.Companion")))
@interface TKKTon_kotlin_liteapi_tlLiteServerBlockHeaderCompanion : TKKBase <TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapi_tlLiteServerBlockHeaderCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapi_tlLiteServerBlockHeader *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerBlockHeader *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerBlockHeader *)decodeByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decode(byteString:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerBlockHeader *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerBlockHeader *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerBlockHeader *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerBlockHeader *)decodeBoxedByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decodeBoxed(byteString:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerBlockHeader *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapi_tlLiteServerBlockHeader *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerBlockHeader *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapi_tlLiteServerBlockHeader *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerBlockHeader *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_liteapi_tlLiteServerBlockHeader *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKTon_kotlin_tlByteString *)encodeToByteStringValue:(TKKTon_kotlin_liteapi_tlLiteServerBlockHeader *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteString(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_liteapi_tlLiteServerBlockHeader *)value __attribute__((swift_name("hash(value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerGetBlockProof.Companion")))
@interface TKKTon_kotlin_liteapi_tlLiteServerGetBlockProofCompanion : TKKBase <TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapi_tlLiteServerGetBlockProofCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetBlockProof *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetBlockProof *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetBlockProof *)decodeByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decode(byteString:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetBlockProof *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetBlockProof *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetBlockProof *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetBlockProof *)decodeBoxedByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decodeBoxed(byteString:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetBlockProof *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapi_tlLiteServerGetBlockProof *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerGetBlockProof *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapi_tlLiteServerGetBlockProof *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerGetBlockProof *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_liteapi_tlLiteServerGetBlockProof *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKTon_kotlin_tlByteString *)encodeToByteStringValue:(TKKTon_kotlin_liteapi_tlLiteServerGetBlockProof *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteString(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_liteapi_tlLiteServerGetBlockProof *)value __attribute__((swift_name("hash(value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerBlockLink")))
@protocol TKKTon_kotlin_liteapi_tlLiteServerBlockLink
@required
@property (readonly) TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *from __attribute__((swift_name("from")));
@property (readonly) TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *to __attribute__((swift_name("to")));
@property (readonly) BOOL toKeyBlock __attribute__((swift_name("toKeyBlock")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerPartialBlockProof.Companion")))
@interface TKKTon_kotlin_liteapi_tlLiteServerPartialBlockProofCompanion : TKKBase <TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapi_tlLiteServerPartialBlockProofCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapi_tlLiteServerPartialBlockProof *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerPartialBlockProof *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerPartialBlockProof *)decodeByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decode(byteString:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerPartialBlockProof *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerPartialBlockProof *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerPartialBlockProof *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerPartialBlockProof *)decodeBoxedByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decodeBoxed(byteString:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerPartialBlockProof *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapi_tlLiteServerPartialBlockProof *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerPartialBlockProof *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapi_tlLiteServerPartialBlockProof *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerPartialBlockProof *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_liteapi_tlLiteServerPartialBlockProof *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKTon_kotlin_tlByteString *)encodeToByteStringValue:(TKKTon_kotlin_liteapi_tlLiteServerPartialBlockProof *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteString(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_liteapi_tlLiteServerPartialBlockProof *)value __attribute__((swift_name("hash(value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerGetConfigAll.Companion")))
@interface TKKTon_kotlin_liteapi_tlLiteServerGetConfigAllCompanion : TKKBase <TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapi_tlLiteServerGetConfigAllCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetConfigAll *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetConfigAll *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetConfigAll *)decodeByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decode(byteString:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetConfigAll *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetConfigAll *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetConfigAll *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetConfigAll *)decodeBoxedByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decodeBoxed(byteString:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetConfigAll *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapi_tlLiteServerGetConfigAll *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerGetConfigAll *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapi_tlLiteServerGetConfigAll *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerGetConfigAll *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_liteapi_tlLiteServerGetConfigAll *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKTon_kotlin_tlByteString *)encodeToByteStringValue:(TKKTon_kotlin_liteapi_tlLiteServerGetConfigAll *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteString(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_liteapi_tlLiteServerGetConfigAll *)value __attribute__((swift_name("hash(value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerConfigInfo.Companion")))
@interface TKKTon_kotlin_liteapi_tlLiteServerConfigInfoCompanion : TKKBase <TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapi_tlLiteServerConfigInfoCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapi_tlLiteServerConfigInfo *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerConfigInfo *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerConfigInfo *)decodeByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decode(byteString:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerConfigInfo *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerConfigInfo *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerConfigInfo *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerConfigInfo *)decodeBoxedByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decodeBoxed(byteString:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerConfigInfo *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapi_tlLiteServerConfigInfo *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerConfigInfo *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapi_tlLiteServerConfigInfo *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerConfigInfo *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_liteapi_tlLiteServerConfigInfo *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKTon_kotlin_tlByteString *)encodeToByteStringValue:(TKKTon_kotlin_liteapi_tlLiteServerConfigInfo *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteString(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_liteapi_tlLiteServerConfigInfo *)value __attribute__((swift_name("hash(value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerGetConfigParams.Companion")))
@interface TKKTon_kotlin_liteapi_tlLiteServerGetConfigParamsCompanion : TKKBase <TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapi_tlLiteServerGetConfigParamsCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetConfigParams *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetConfigParams *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetConfigParams *)decodeByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decode(byteString:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetConfigParams *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetConfigParams *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetConfigParams *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetConfigParams *)decodeBoxedByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decodeBoxed(byteString:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetConfigParams *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapi_tlLiteServerGetConfigParams *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerGetConfigParams *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapi_tlLiteServerGetConfigParams *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerGetConfigParams *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_liteapi_tlLiteServerGetConfigParams *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKTon_kotlin_tlByteString *)encodeToByteStringValue:(TKKTon_kotlin_liteapi_tlLiteServerGetConfigParams *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteString(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_liteapi_tlLiteServerGetConfigParams *)value __attribute__((swift_name("hash(value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_tonapi_tlTonNodeZeroStateIdExt")))
@interface TKKTon_kotlin_tonapi_tlTonNodeZeroStateIdExt : TKKBase
- (instancetype)initWithTonNodeBlockIdExt:(TKKTon_kotlin_tonapi_tlTonNodeBlockIdExt *)tonNodeBlockIdExt __attribute__((swift_name("init(tonNodeBlockIdExt:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithWorkchain:(int32_t)workchain rootHash:(TKKTon_kotlin_tlByteString *)rootHash fileHash:(TKKTon_kotlin_tlByteString *)fileHash __attribute__((swift_name("init(workchain:rootHash:fileHash:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_tonapi_tlTonNodeZeroStateIdExtCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_tonapi_tlTonNodeZeroStateIdExt *)doCopyWorkchain:(int32_t)workchain rootHash:(TKKTon_kotlin_tlByteString *)rootHash fileHash:(TKKTon_kotlin_tlByteString *)fileHash __attribute__((swift_name("doCopy(workchain:rootHash:fileHash:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (BOOL)isMasterchain __attribute__((swift_name("isMasterchain()")));
- (BOOL)isValid __attribute__((swift_name("isValid()")));
- (NSString *)description __attribute__((swift_name("description()")));

/**
 * @note annotations
 *   kotlinx.serialization.SerialName(value="file_hash")
*/
@property (readonly) TKKTon_kotlin_tlByteString *fileHash __attribute__((swift_name("fileHash")));

/**
 * @note annotations
 *   kotlinx.serialization.SerialName(value="root_hash")
*/
@property (readonly) TKKTon_kotlin_tlByteString *rootHash __attribute__((swift_name("rootHash")));
@property (readonly) int32_t workchain __attribute__((swift_name("workchain")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerMasterchainInfo.Companion")))
@interface TKKTon_kotlin_liteapi_tlLiteServerMasterchainInfoCompanion : TKKBase <TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapi_tlLiteServerMasterchainInfoCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapi_tlLiteServerMasterchainInfo *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerMasterchainInfo *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerMasterchainInfo *)decodeByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decode(byteString:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerMasterchainInfo *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerMasterchainInfo *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerMasterchainInfo *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerMasterchainInfo *)decodeBoxedByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decodeBoxed(byteString:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerMasterchainInfo *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapi_tlLiteServerMasterchainInfo *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerMasterchainInfo *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapi_tlLiteServerMasterchainInfo *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerMasterchainInfo *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_liteapi_tlLiteServerMasterchainInfo *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKTon_kotlin_tlByteString *)encodeToByteStringValue:(TKKTon_kotlin_liteapi_tlLiteServerMasterchainInfo *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteString(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_liteapi_tlLiteServerMasterchainInfo *)value __attribute__((swift_name("hash(value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerGetMasterchainInfoExt.Companion")))
@interface TKKTon_kotlin_liteapi_tlLiteServerGetMasterchainInfoExtCompanion : TKKBase <TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapi_tlLiteServerGetMasterchainInfoExtCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetMasterchainInfoExt *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetMasterchainInfoExt *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetMasterchainInfoExt *)decodeByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decode(byteString:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetMasterchainInfoExt *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetMasterchainInfoExt *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetMasterchainInfoExt *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetMasterchainInfoExt *)decodeBoxedByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decodeBoxed(byteString:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetMasterchainInfoExt *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapi_tlLiteServerGetMasterchainInfoExt *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerGetMasterchainInfoExt *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapi_tlLiteServerGetMasterchainInfoExt *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerGetMasterchainInfoExt *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_liteapi_tlLiteServerGetMasterchainInfoExt *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKTon_kotlin_tlByteString *)encodeToByteStringValue:(TKKTon_kotlin_liteapi_tlLiteServerGetMasterchainInfoExt *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteString(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_liteapi_tlLiteServerGetMasterchainInfoExt *)value __attribute__((swift_name("hash(value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerMasterchainInfoExt.Companion")))
@interface TKKTon_kotlin_liteapi_tlLiteServerMasterchainInfoExtCompanion : TKKTon_kotlin_tlTlConstructor<TKKTon_kotlin_liteapi_tlLiteServerMasterchainInfoExt *>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (instancetype)initWithSchema:(NSString *)schema id:(TKKInt * _Nullable)id __attribute__((swift_name("init(schema:id:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapi_tlLiteServerMasterchainInfoExtCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapi_tlLiteServerMasterchainInfoExt *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerMasterchainInfoExt *)value __attribute__((swift_name("encode(writer:value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerGetOneTransaction.Companion")))
@interface TKKTon_kotlin_liteapi_tlLiteServerGetOneTransactionCompanion : TKKBase <TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapi_tlLiteServerGetOneTransactionCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetOneTransaction *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetOneTransaction *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetOneTransaction *)decodeByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decode(byteString:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetOneTransaction *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetOneTransaction *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetOneTransaction *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetOneTransaction *)decodeBoxedByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decodeBoxed(byteString:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetOneTransaction *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapi_tlLiteServerGetOneTransaction *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerGetOneTransaction *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapi_tlLiteServerGetOneTransaction *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerGetOneTransaction *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_liteapi_tlLiteServerGetOneTransaction *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKTon_kotlin_tlByteString *)encodeToByteStringValue:(TKKTon_kotlin_liteapi_tlLiteServerGetOneTransaction *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteString(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_liteapi_tlLiteServerGetOneTransaction *)value __attribute__((swift_name("hash(value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerTransactionInfo.Companion")))
@interface TKKTon_kotlin_liteapi_tlLiteServerTransactionInfoCompanion : TKKBase <TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapi_tlLiteServerTransactionInfoCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapi_tlLiteServerTransactionInfo *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerTransactionInfo *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerTransactionInfo *)decodeByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decode(byteString:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerTransactionInfo *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerTransactionInfo *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerTransactionInfo *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerTransactionInfo *)decodeBoxedByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decodeBoxed(byteString:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerTransactionInfo *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapi_tlLiteServerTransactionInfo *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerTransactionInfo *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapi_tlLiteServerTransactionInfo *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerTransactionInfo *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_liteapi_tlLiteServerTransactionInfo *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKTon_kotlin_tlByteString *)encodeToByteStringValue:(TKKTon_kotlin_liteapi_tlLiteServerTransactionInfo *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteString(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_liteapi_tlLiteServerTransactionInfo *)value __attribute__((swift_name("hash(value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerGetShardInfo.Companion")))
@interface TKKTon_kotlin_liteapi_tlLiteServerGetShardInfoCompanion : TKKBase <TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapi_tlLiteServerGetShardInfoCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetShardInfo *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetShardInfo *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetShardInfo *)decodeByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decode(byteString:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetShardInfo *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetShardInfo *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetShardInfo *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetShardInfo *)decodeBoxedByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decodeBoxed(byteString:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetShardInfo *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapi_tlLiteServerGetShardInfo *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerGetShardInfo *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapi_tlLiteServerGetShardInfo *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerGetShardInfo *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_liteapi_tlLiteServerGetShardInfo *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKTon_kotlin_tlByteString *)encodeToByteStringValue:(TKKTon_kotlin_liteapi_tlLiteServerGetShardInfo *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteString(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_liteapi_tlLiteServerGetShardInfo *)value __attribute__((swift_name("hash(value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerShardInfo.Companion")))
@interface TKKTon_kotlin_liteapi_tlLiteServerShardInfoCompanion : TKKBase <TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapi_tlLiteServerShardInfoCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapi_tlLiteServerShardInfo *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerShardInfo *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerShardInfo *)decodeByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decode(byteString:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerShardInfo *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerShardInfo *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerShardInfo *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerShardInfo *)decodeBoxedByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decodeBoxed(byteString:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerShardInfo *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapi_tlLiteServerShardInfo *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerShardInfo *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapi_tlLiteServerShardInfo *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerShardInfo *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_liteapi_tlLiteServerShardInfo *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKTon_kotlin_tlByteString *)encodeToByteStringValue:(TKKTon_kotlin_liteapi_tlLiteServerShardInfo *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteString(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_liteapi_tlLiteServerShardInfo *)value __attribute__((swift_name("hash(value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerGetState.Companion")))
@interface TKKTon_kotlin_liteapi_tlLiteServerGetStateCompanion : TKKBase <TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapi_tlLiteServerGetStateCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetState *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetState *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetState *)decodeByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decode(byteString:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetState *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetState *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetState *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetState *)decodeBoxedByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decodeBoxed(byteString:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetState *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapi_tlLiteServerGetState *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerGetState *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapi_tlLiteServerGetState *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerGetState *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_liteapi_tlLiteServerGetState *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKTon_kotlin_tlByteString *)encodeToByteStringValue:(TKKTon_kotlin_liteapi_tlLiteServerGetState *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteString(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_liteapi_tlLiteServerGetState *)value __attribute__((swift_name("hash(value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerBlockState.Companion")))
@interface TKKTon_kotlin_liteapi_tlLiteServerBlockStateCompanion : TKKBase <TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapi_tlLiteServerBlockStateCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapi_tlLiteServerBlockState *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerBlockState *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerBlockState *)decodeByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decode(byteString:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerBlockState *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerBlockState *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerBlockState *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerBlockState *)decodeBoxedByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decodeBoxed(byteString:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerBlockState *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapi_tlLiteServerBlockState *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerBlockState *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapi_tlLiteServerBlockState *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerBlockState *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_liteapi_tlLiteServerBlockState *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKTon_kotlin_tlByteString *)encodeToByteStringValue:(TKKTon_kotlin_liteapi_tlLiteServerBlockState *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteString(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_liteapi_tlLiteServerBlockState *)value __attribute__((swift_name("hash(value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerCurrentTime.Companion")))
@interface TKKTon_kotlin_liteapi_tlLiteServerCurrentTimeCompanion : TKKTon_kotlin_tlTlConstructor<TKKTon_kotlin_liteapi_tlLiteServerCurrentTime *>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (instancetype)initWithSchema:(NSString *)schema id:(TKKInt * _Nullable)id __attribute__((swift_name("init(schema:id:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapi_tlLiteServerCurrentTimeCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapi_tlLiteServerCurrentTime *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerCurrentTime *)value __attribute__((swift_name("encode(writer:value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerGetTransactions.Companion")))
@interface TKKTon_kotlin_liteapi_tlLiteServerGetTransactionsCompanion : TKKBase <TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapi_tlLiteServerGetTransactionsCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetTransactions *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetTransactions *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetTransactions *)decodeByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decode(byteString:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetTransactions *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetTransactions *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetTransactions *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetTransactions *)decodeBoxedByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decodeBoxed(byteString:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetTransactions *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapi_tlLiteServerGetTransactions *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerGetTransactions *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapi_tlLiteServerGetTransactions *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerGetTransactions *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_liteapi_tlLiteServerGetTransactions *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKTon_kotlin_tlByteString *)encodeToByteStringValue:(TKKTon_kotlin_liteapi_tlLiteServerGetTransactions *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteString(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_liteapi_tlLiteServerGetTransactions *)value __attribute__((swift_name("hash(value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerTransactionList.Companion")))
@interface TKKTon_kotlin_liteapi_tlLiteServerTransactionListCompanion : TKKBase <TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapi_tlLiteServerTransactionListCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapi_tlLiteServerTransactionList *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerTransactionList *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerTransactionList *)decodeByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decode(byteString:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerTransactionList *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerTransactionList *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerTransactionList *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerTransactionList *)decodeBoxedByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decodeBoxed(byteString:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerTransactionList *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapi_tlLiteServerTransactionList *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerTransactionList *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapi_tlLiteServerTransactionList *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerTransactionList *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_liteapi_tlLiteServerTransactionList *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKTon_kotlin_tlByteString *)encodeToByteStringValue:(TKKTon_kotlin_liteapi_tlLiteServerTransactionList *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteString(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_liteapi_tlLiteServerTransactionList *)value __attribute__((swift_name("hash(value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerGetValidatorStats.Companion")))
@interface TKKTon_kotlin_liteapi_tlLiteServerGetValidatorStatsCompanion : TKKBase <TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapi_tlLiteServerGetValidatorStatsCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetValidatorStats *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetValidatorStats *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetValidatorStats *)decodeByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decode(byteString:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetValidatorStats *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetValidatorStats *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetValidatorStats *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetValidatorStats *)decodeBoxedByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decodeBoxed(byteString:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerGetValidatorStats *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapi_tlLiteServerGetValidatorStats *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerGetValidatorStats *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapi_tlLiteServerGetValidatorStats *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerGetValidatorStats *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_liteapi_tlLiteServerGetValidatorStats *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKTon_kotlin_tlByteString *)encodeToByteStringValue:(TKKTon_kotlin_liteapi_tlLiteServerGetValidatorStats *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteString(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_liteapi_tlLiteServerGetValidatorStats *)value __attribute__((swift_name("hash(value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerValidatorStats.Companion")))
@interface TKKTon_kotlin_liteapi_tlLiteServerValidatorStatsCompanion : TKKBase <TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapi_tlLiteServerValidatorStatsCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapi_tlLiteServerValidatorStats *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerValidatorStats *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerValidatorStats *)decodeByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decode(byteString:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerValidatorStats *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerValidatorStats *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerValidatorStats *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerValidatorStats *)decodeBoxedByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decodeBoxed(byteString:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerValidatorStats *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapi_tlLiteServerValidatorStats *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerValidatorStats *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapi_tlLiteServerValidatorStats *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerValidatorStats *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_liteapi_tlLiteServerValidatorStats *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKTon_kotlin_tlByteString *)encodeToByteStringValue:(TKKTon_kotlin_liteapi_tlLiteServerValidatorStats *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteString(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_liteapi_tlLiteServerValidatorStats *)value __attribute__((swift_name("hash(value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
 *   kotlinx.serialization.SerialName(value="liteServer.transactionId3")
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerTransactionId3")))
@interface TKKTon_kotlin_liteapi_tlLiteServerTransactionId3 : TKKBase
- (instancetype)initWithAccount:(TKKTon_kotlin_tlByteString *)account lt:(int64_t)lt __attribute__((swift_name("init(account:lt:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapi_tlLiteServerTransactionId3Companion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapi_tlLiteServerTransactionId3 *)doCopyAccount:(TKKTon_kotlin_tlByteString *)account lt:(int64_t)lt __attribute__((swift_name("doCopy(account:lt:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) TKKTon_kotlin_tlByteString *account __attribute__((swift_name("account")));
@property (readonly) int64_t lt __attribute__((swift_name("lt")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerListBlockTransactions.Companion")))
@interface TKKTon_kotlin_liteapi_tlLiteServerListBlockTransactionsCompanion : TKKBase <TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapi_tlLiteServerListBlockTransactionsCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapi_tlLiteServerListBlockTransactions *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerListBlockTransactions *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerListBlockTransactions *)decodeByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decode(byteString:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerListBlockTransactions *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerListBlockTransactions *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerListBlockTransactions *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerListBlockTransactions *)decodeBoxedByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decodeBoxed(byteString:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerListBlockTransactions *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapi_tlLiteServerListBlockTransactions *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerListBlockTransactions *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapi_tlLiteServerListBlockTransactions *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerListBlockTransactions *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_liteapi_tlLiteServerListBlockTransactions *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKTon_kotlin_tlByteString *)encodeToByteStringValue:(TKKTon_kotlin_liteapi_tlLiteServerListBlockTransactions *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteString(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_liteapi_tlLiteServerListBlockTransactions *)value __attribute__((swift_name("hash(value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
 *   kotlinx.serialization.SerialName(value="liteServer.transactionId")
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerTransactionId")))
@interface TKKTon_kotlin_liteapi_tlLiteServerTransactionId : TKKBase
- (instancetype)initWithAccount:(TKKKotlinByteArray * _Nullable)account lt:(TKKLong * _Nullable)lt hash:(TKKKotlinByteArray * _Nullable)hash __attribute__((swift_name("init(account:lt:hash:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapi_tlLiteServerTransactionIdCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapi_tlLiteServerTransactionId *)doCopyMode:(int32_t)mode account:(TKKTon_kotlin_tlByteString * _Nullable)account lt:(TKKLong * _Nullable)lt hash:(TKKTon_kotlin_tlByteString * _Nullable)hash __attribute__((swift_name("doCopy(mode:account:lt:hash:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) TKKTon_kotlin_tlByteString * _Nullable account __attribute__((swift_name("account")));
@property (readonly, getter=hash_) TKKTon_kotlin_tlByteString * _Nullable hash __attribute__((swift_name("hash")));
@property (readonly) TKKLong * _Nullable lt __attribute__((swift_name("lt")));
@property (readonly) int32_t mode __attribute__((swift_name("mode")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerBlockTransactions.Companion")))
@interface TKKTon_kotlin_liteapi_tlLiteServerBlockTransactionsCompanion : TKKBase <TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapi_tlLiteServerBlockTransactionsCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapi_tlLiteServerBlockTransactions *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerBlockTransactions *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerBlockTransactions *)decodeByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decode(byteString:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerBlockTransactions *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerBlockTransactions *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerBlockTransactions *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerBlockTransactions *)decodeBoxedByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decodeBoxed(byteString:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerBlockTransactions *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapi_tlLiteServerBlockTransactions *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerBlockTransactions *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapi_tlLiteServerBlockTransactions *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerBlockTransactions *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_liteapi_tlLiteServerBlockTransactions *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKTon_kotlin_tlByteString *)encodeToByteStringValue:(TKKTon_kotlin_liteapi_tlLiteServerBlockTransactions *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteString(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_liteapi_tlLiteServerBlockTransactions *)value __attribute__((swift_name("hash(value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerLookupBlock.Companion")))
@interface TKKTon_kotlin_liteapi_tlLiteServerLookupBlockCompanion : TKKBase <TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapi_tlLiteServerLookupBlockCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapi_tlLiteServerLookupBlock *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerLookupBlock *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerLookupBlock *)decodeByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decode(byteString:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerLookupBlock *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerLookupBlock *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerLookupBlock *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerLookupBlock *)decodeBoxedByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decodeBoxed(byteString:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerLookupBlock *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapi_tlLiteServerLookupBlock *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerLookupBlock *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapi_tlLiteServerLookupBlock *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerLookupBlock *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_liteapi_tlLiteServerLookupBlock *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKTon_kotlin_tlByteString *)encodeToByteStringValue:(TKKTon_kotlin_liteapi_tlLiteServerLookupBlock *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteString(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_liteapi_tlLiteServerLookupBlock *)value __attribute__((swift_name("hash(value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@property (readonly) int32_t ID_MASK __attribute__((swift_name("ID_MASK")));
@property (readonly) int32_t LT_MASK __attribute__((swift_name("LT_MASK")));
@property (readonly) int32_t UTIME_MASK __attribute__((swift_name("UTIME_MASK")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerRunSmcMethod.Companion")))
@interface TKKTon_kotlin_liteapi_tlLiteServerRunSmcMethodCompanion : TKKBase <TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapi_tlLiteServerRunSmcMethodCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapi_tlLiteServerRunSmcMethod *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerRunSmcMethod *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerRunSmcMethod *)decodeByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decode(byteString:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerRunSmcMethod *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerRunSmcMethod *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerRunSmcMethod *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerRunSmcMethod *)decodeBoxedByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decodeBoxed(byteString:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerRunSmcMethod *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapi_tlLiteServerRunSmcMethod *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerRunSmcMethod *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapi_tlLiteServerRunSmcMethod *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerRunSmcMethod *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_liteapi_tlLiteServerRunSmcMethod *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKTon_kotlin_tlByteString *)encodeToByteStringValue:(TKKTon_kotlin_liteapi_tlLiteServerRunSmcMethod *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteString(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_liteapi_tlLiteServerRunSmcMethod *)value __attribute__((swift_name("hash(value:)")));

/**
 * @note annotations
 *   kotlin.jvm.JvmStatic
*/
- (int64_t)methodIdMethodName:(NSString *)methodName __attribute__((swift_name("methodId(methodName:)")));

/**
 * @note annotations
 *   kotlin.jvm.JvmStatic
*/
- (TKKKotlinByteArray *)paramsParams:(TKKKotlinArray<id<TKKTon_kotlin_block_tlbVmStackValue>> *)params __attribute__((swift_name("params(params:)")));

/**
 * @note annotations
 *   kotlin.jvm.JvmStatic
*/
- (TKKKotlinByteArray *)paramsParams_:(id)params __attribute__((swift_name("params(params_:)")));

/**
 * @note annotations
 *   kotlin.jvm.JvmStatic
*/
- (TKKKotlinByteArray *)paramsVmStack:(id<TKKTon_kotlin_block_tlbVmStack>)vmStack __attribute__((swift_name("params(vmStack:)")));

/**
 * @note annotations
 *   kotlin.jvm.JvmStatic
*/
- (TKKKotlinByteArray *)paramsVmStackList:(id<TKKTon_kotlin_block_tlbVmStackList> _Nullable)vmStackList __attribute__((swift_name("params(vmStackList:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerRunMethodResult.Companion")))
@interface TKKTon_kotlin_liteapi_tlLiteServerRunMethodResultCompanion : TKKBase <TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapi_tlLiteServerRunMethodResultCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapi_tlLiteServerRunMethodResult *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerRunMethodResult *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerRunMethodResult *)decodeByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decode(byteString:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerRunMethodResult *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerRunMethodResult *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerRunMethodResult *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerRunMethodResult *)decodeBoxedByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decodeBoxed(byteString:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerRunMethodResult *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapi_tlLiteServerRunMethodResult *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerRunMethodResult *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapi_tlLiteServerRunMethodResult *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerRunMethodResult *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_liteapi_tlLiteServerRunMethodResult *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKTon_kotlin_tlByteString *)encodeToByteStringValue:(TKKTon_kotlin_liteapi_tlLiteServerRunMethodResult *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteString(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_liteapi_tlLiteServerRunMethodResult *)value __attribute__((swift_name("hash(value:)")));

/**
 * @note annotations
 *   kotlin.jvm.JvmStatic
*/
- (int32_t)modeHasProof:(BOOL)hasProof hasStateProof:(BOOL)hasStateProof hasResult:(BOOL)hasResult hasInitC7:(BOOL)hasInitC7 hasLibExtras:(BOOL)hasLibExtras __attribute__((swift_name("mode(hasProof:hasStateProof:hasResult:hasInitC7:hasLibExtras:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerSendMessage.Companion")))
@interface TKKTon_kotlin_liteapi_tlLiteServerSendMessageCompanion : TKKBase <TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapi_tlLiteServerSendMessageCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapi_tlLiteServerSendMessage *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerSendMessage *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerSendMessage *)decodeByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decode(byteString:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerSendMessage *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerSendMessage *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerSendMessage *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerSendMessage *)decodeBoxedByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decodeBoxed(byteString:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerSendMessage *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapi_tlLiteServerSendMessage *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerSendMessage *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapi_tlLiteServerSendMessage *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerSendMessage *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_liteapi_tlLiteServerSendMessage *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKTon_kotlin_tlByteString *)encodeToByteStringValue:(TKKTon_kotlin_liteapi_tlLiteServerSendMessage *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteString(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_liteapi_tlLiteServerSendMessage *)value __attribute__((swift_name("hash(value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_tonapi_tlOverlayNode.Companion")))
@interface TKKTon_kotlin_tonapi_tlOverlayNodeCompanion : TKKTon_kotlin_tlTlConstructor<TKKTon_kotlin_tonapi_tlOverlayNode *>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (instancetype)initWithSchema:(NSString *)schema id:(TKKInt * _Nullable)id __attribute__((swift_name("init(schema:id:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_tonapi_tlOverlayNodeCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_tonapi_tlOverlayNode *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_tonapi_tlOverlayNode *)value __attribute__((swift_name("encode(writer:value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("KotlinRandom.Default")))
@interface TKKKotlinRandomDefault : TKKKotlinRandom
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (instancetype)init __attribute__((swift_name("init()"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
+ (instancetype)new __attribute__((unavailable));
+ (instancetype)default_ __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKKotlinRandomDefault *shared __attribute__((swift_name("shared")));
- (int32_t)nextBitsBitCount:(int32_t)bitCount __attribute__((swift_name("nextBits(bitCount:)")));
- (BOOL)nextBoolean __attribute__((swift_name("nextBoolean()")));
- (TKKKotlinByteArray *)nextBytesArray:(TKKKotlinByteArray *)array __attribute__((swift_name("nextBytes(array:)")));
- (TKKKotlinByteArray *)nextBytesArray:(TKKKotlinByteArray *)array fromIndex:(int32_t)fromIndex toIndex:(int32_t)toIndex __attribute__((swift_name("nextBytes(array:fromIndex:toIndex:)")));
- (TKKKotlinByteArray *)nextBytesSize:(int32_t)size __attribute__((swift_name("nextBytes(size:)")));
- (double)nextDouble __attribute__((swift_name("nextDouble()")));
- (double)nextDoubleUntil:(double)until __attribute__((swift_name("nextDouble(until:)")));
- (double)nextDoubleFrom:(double)from until:(double)until __attribute__((swift_name("nextDouble(from:until:)")));
- (float)nextFloat __attribute__((swift_name("nextFloat()")));
- (int32_t)nextInt __attribute__((swift_name("nextInt()")));
- (int32_t)nextIntUntil:(int32_t)until __attribute__((swift_name("nextInt(until:)")));
- (int32_t)nextIntFrom:(int32_t)from until:(int32_t)until __attribute__((swift_name("nextInt(from:until:)")));
- (int64_t)nextLong __attribute__((swift_name("nextLong()")));
- (int64_t)nextLongUntil:(int64_t)until __attribute__((swift_name("nextLong(until:)")));
- (int64_t)nextLongFrom:(int64_t)from until:(int64_t)until __attribute__((swift_name("nextLong(from:until:)")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
__attribute__((swift_name("Kotlinx_serialization_coreSerializersModuleCollector")))
@protocol TKKKotlinx_serialization_coreSerializersModuleCollector
@required
- (void)contextualKClass:(id<TKKKotlinKClass>)kClass provider:(id<TKKKotlinx_serialization_coreKSerializer> (^)(NSArray<id<TKKKotlinx_serialization_coreKSerializer>> *))provider __attribute__((swift_name("contextual(kClass:provider:)")));
- (void)contextualKClass:(id<TKKKotlinKClass>)kClass serializer:(id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("contextual(kClass:serializer:)")));
- (void)polymorphicBaseClass:(id<TKKKotlinKClass>)baseClass actualClass:(id<TKKKotlinKClass>)actualClass actualSerializer:(id<TKKKotlinx_serialization_coreKSerializer>)actualSerializer __attribute__((swift_name("polymorphic(baseClass:actualClass:actualSerializer:)")));
- (void)polymorphicDefaultBaseClass:(id<TKKKotlinKClass>)baseClass defaultDeserializerProvider:(id<TKKKotlinx_serialization_coreDeserializationStrategy> _Nullable (^)(NSString * _Nullable))defaultDeserializerProvider __attribute__((swift_name("polymorphicDefault(baseClass:defaultDeserializerProvider:)"))) __attribute__((deprecated("Deprecated in favor of function with more precise name: polymorphicDefaultDeserializer")));
- (void)polymorphicDefaultDeserializerBaseClass:(id<TKKKotlinKClass>)baseClass defaultDeserializerProvider:(id<TKKKotlinx_serialization_coreDeserializationStrategy> _Nullable (^)(NSString * _Nullable))defaultDeserializerProvider __attribute__((swift_name("polymorphicDefaultDeserializer(baseClass:defaultDeserializerProvider:)")));
- (void)polymorphicDefaultSerializerBaseClass:(id<TKKKotlinKClass>)baseClass defaultSerializerProvider:(id<TKKKotlinx_serialization_coreSerializationStrategy> _Nullable (^)(id))defaultSerializerProvider __attribute__((swift_name("polymorphicDefaultSerializer(baseClass:defaultSerializerProvider:)")));
@end

__attribute__((swift_name("KotlinKDeclarationContainer")))
@protocol TKKKotlinKDeclarationContainer
@required
@end

__attribute__((swift_name("KotlinKAnnotatedElement")))
@protocol TKKKotlinKAnnotatedElement
@required
@end


/**
 * @note annotations
 *   kotlin.SinceKotlin(version="1.1")
*/
__attribute__((swift_name("KotlinKClassifier")))
@protocol TKKKotlinKClassifier
@required
@end

__attribute__((swift_name("KotlinKClass")))
@protocol TKKKotlinKClass <TKKKotlinKDeclarationContainer, TKKKotlinKAnnotatedElement, TKKKotlinKClassifier>
@required

/**
 * @note annotations
 *   kotlin.SinceKotlin(version="1.1")
*/
- (BOOL)isInstanceValue:(id _Nullable)value __attribute__((swift_name("isInstance(value:)")));
@property (readonly) NSString * _Nullable qualifiedName __attribute__((swift_name("qualifiedName")));
@property (readonly) NSString * _Nullable simpleName __attribute__((swift_name("simpleName")));
@end

__attribute__((swift_name("KotlinCharIterator")))
@interface TKKKotlinCharIterator : TKKBase <TKKKotlinIterator>
- (instancetype)init __attribute__((swift_name("init()"))) __attribute__((objc_designated_initializer));
+ (instancetype)new __attribute__((availability(swift, unavailable, message="use object initializers instead")));
- (id)next __attribute__((swift_name("next()")));
- (unichar)nextChar __attribute__((swift_name("nextChar()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_tonapi_tlAdnlAddressList")))
@interface TKKTon_kotlin_tonapi_tlAdnlAddressList : TKKBase <TKKTon_kotlin_tlTlObject>
- (instancetype)initWithAddrs:(TKKKotlinArray<id<TKKTon_kotlin_tonapi_tlAdnlAddress>> *)addrs __attribute__((swift_name("init(addrs:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithAddrs:(NSArray<id<TKKTon_kotlin_tonapi_tlAdnlAddress>> *)addrs version:(int32_t)version reinitDate:(int32_t)reinitDate priority:(int32_t)priority expireAt:(int32_t)expireAt __attribute__((swift_name("init(addrs:version:reinitDate:priority:expireAt:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_tonapi_tlAdnlAddressListCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_tonapi_tlAdnlAddressList *)doCopyAddrs:(NSArray<id<TKKTon_kotlin_tonapi_tlAdnlAddress>> *)addrs version:(int32_t)version reinitDate:(int32_t)reinitDate priority:(int32_t)priority expireAt:(int32_t)expireAt __attribute__((swift_name("doCopy(addrs:version:reinitDate:priority:expireAt:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (id<TKKTon_kotlin_tlTlCodec>)tlCodec __attribute__((swift_name("tlCodec()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSArray<id<TKKTon_kotlin_tonapi_tlAdnlAddress>> *addrs __attribute__((swift_name("addrs")));

/**
 * @note annotations
 *   kotlinx.serialization.SerialName(value="expire_at")
*/
@property (readonly) int32_t expireAt __attribute__((swift_name("expireAt")));
@property (readonly) int32_t priority __attribute__((swift_name("priority")));

/**
 * @note annotations
 *   kotlinx.serialization.SerialName(value="reinit_date")
*/
@property (readonly) int32_t reinitDate __attribute__((swift_name("reinitDate")));
@property (readonly) int32_t version __attribute__((swift_name("version")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_tonapi_tlDhtNode.Companion")))
@interface TKKTon_kotlin_tonapi_tlDhtNodeCompanion : TKKBase <TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_tonapi_tlDhtNodeCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_tonapi_tlDhtNode *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_tonapi_tlDhtNode *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_tonapi_tlDhtNode *)decodeByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decode(byteString:)")));
- (TKKTon_kotlin_tonapi_tlDhtNode *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_tonapi_tlDhtNode *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_tonapi_tlDhtNode *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_tonapi_tlDhtNode *)decodeBoxedByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decodeBoxed(byteString:)")));
- (TKKTon_kotlin_tonapi_tlDhtNode *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_tonapi_tlDhtNode *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_tonapi_tlDhtNode *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_tonapi_tlDhtNode *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_tonapi_tlDhtNode *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_tonapi_tlDhtNode *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKTon_kotlin_tlByteString *)encodeToByteStringValue:(TKKTon_kotlin_tonapi_tlDhtNode *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteString(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_tonapi_tlDhtNode *)value __attribute__((swift_name("hash(value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
 *   kotlinx.serialization.SerialName(value="adnl.node")
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_tonapi_tlAdnlNode")))
@interface TKKTon_kotlin_tonapi_tlAdnlNode : TKKBase
- (instancetype)initWithId:(id<TKKTon_kotlin_tonapi_tlPublicKey>)id addrList:(NSArray<id<TKKTon_kotlin_tonapi_tlAdnlAddress>> *)addrList __attribute__((swift_name("init(id:addrList:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithId:(id<TKKTon_kotlin_tonapi_tlPublicKey>)id addrList_:(TKKTon_kotlin_tonapi_tlAdnlAddressList *)addrList __attribute__((swift_name("init(id:addrList_:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_tonapi_tlAdnlNodeCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_tonapi_tlAdnlNode *)doCopyId:(id<TKKTon_kotlin_tonapi_tlPublicKey>)id addrList:(TKKTon_kotlin_tonapi_tlAdnlAddressList *)addrList __attribute__((swift_name("doCopy(id:addrList:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));

/**
 * @note annotations
 *   kotlinx.serialization.SerialName(value="addr_list")
*/
@property (readonly) TKKTon_kotlin_tonapi_tlAdnlAddressList *addrList __attribute__((swift_name("addrList")));
@property (readonly) id<TKKTon_kotlin_tonapi_tlPublicKey> id __attribute__((swift_name("id")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_tonapi_tlDhtNodes.Companion")))
@interface TKKTon_kotlin_tonapi_tlDhtNodesCompanion : TKKTon_kotlin_tlTlConstructor<TKKTon_kotlin_tonapi_tlDhtNodes *>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (instancetype)initWithSchema:(NSString *)schema id:(TKKInt * _Nullable)id __attribute__((swift_name("init(schema:id:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_tonapi_tlDhtNodesCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_tonapi_tlDhtNodes *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_tonapi_tlDhtNodes *)value __attribute__((swift_name("encode(writer:value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
 *   kotlinx.serialization.SerialName(value="adnl.nodes")
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_tonapi_tlAdnlNodes")))
@interface TKKTon_kotlin_tonapi_tlAdnlNodes : TKKBase
- (instancetype)initWithNodes:(NSArray<TKKTon_kotlin_tonapi_tlAdnlNode *> *)nodes __attribute__((swift_name("init(nodes:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_tonapi_tlAdnlNodesCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_tonapi_tlAdnlNodes *)doCopyNodes:(NSArray<TKKTon_kotlin_tonapi_tlAdnlNode *> *)nodes __attribute__((swift_name("doCopy(nodes:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSArray<TKKTon_kotlin_tonapi_tlAdnlNode *> *nodes __attribute__((swift_name("nodes")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ktor_ioMemory.Companion")))
@interface TKKKtor_ioMemoryCompanion : TKKBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKKtor_ioMemoryCompanion *shared __attribute__((swift_name("shared")));
@property (readonly) TKKKtor_ioMemory *Empty __attribute__((swift_name("Empty")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ktor_ioBuffer.Companion")))
@interface TKKKtor_ioBufferCompanion : TKKBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKKtor_ioBufferCompanion *shared __attribute__((swift_name("shared")));
@property (readonly) TKKKtor_ioBuffer *Empty __attribute__((swift_name("Empty")));
@property (readonly) int32_t ReservedSize __attribute__((swift_name("ReservedSize")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ktor_ioChunkBuffer.Companion")))
@interface TKKKtor_ioChunkBufferCompanion : TKKBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKKtor_ioChunkBufferCompanion *shared __attribute__((swift_name("shared")));
@property (readonly) TKKKtor_ioChunkBuffer *Empty __attribute__((swift_name("Empty")));
@property (readonly) id<TKKKtor_ioObjectPool> EmptyPool __attribute__((swift_name("EmptyPool")));
@property (readonly) id<TKKKtor_ioObjectPool> Pool __attribute__((swift_name("Pool")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_tonapi_tlTonNodeZeroStateIdExt.Companion")))
@interface TKKTon_kotlin_tonapi_tlTonNodeZeroStateIdExtCompanion : TKKTon_kotlin_tlTlConstructor<TKKTon_kotlin_tonapi_tlTonNodeZeroStateIdExt *>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (instancetype)initWithSchema:(NSString *)schema id:(TKKInt * _Nullable)id __attribute__((swift_name("init(schema:id:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_tonapi_tlTonNodeZeroStateIdExtCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_tonapi_tlTonNodeZeroStateIdExt *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_tonapi_tlTonNodeZeroStateIdExt *)value __attribute__((swift_name("encode(writer:value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerTransactionId3.Companion")))
@interface TKKTon_kotlin_liteapi_tlLiteServerTransactionId3Companion : TKKBase <TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapi_tlLiteServerTransactionId3Companion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapi_tlLiteServerTransactionId3 *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerTransactionId3 *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerTransactionId3 *)decodeByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decode(byteString:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerTransactionId3 *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerTransactionId3 *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerTransactionId3 *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerTransactionId3 *)decodeBoxedByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decodeBoxed(byteString:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerTransactionId3 *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapi_tlLiteServerTransactionId3 *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerTransactionId3 *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapi_tlLiteServerTransactionId3 *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerTransactionId3 *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_liteapi_tlLiteServerTransactionId3 *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKTon_kotlin_tlByteString *)encodeToByteStringValue:(TKKTon_kotlin_liteapi_tlLiteServerTransactionId3 *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteString(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_liteapi_tlLiteServerTransactionId3 *)value __attribute__((swift_name("hash(value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapi_tlLiteServerTransactionId.Companion")))
@interface TKKTon_kotlin_liteapi_tlLiteServerTransactionIdCompanion : TKKBase <TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapi_tlLiteServerTransactionIdCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapi_tlLiteServerTransactionId *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerTransactionId *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerTransactionId *)decodeByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decode(byteString:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerTransactionId *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerTransactionId *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerTransactionId *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerTransactionId *)decodeBoxedByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decodeBoxed(byteString:)")));
- (TKKTon_kotlin_liteapi_tlLiteServerTransactionId *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapi_tlLiteServerTransactionId *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerTransactionId *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapi_tlLiteServerTransactionId *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapi_tlLiteServerTransactionId *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_liteapi_tlLiteServerTransactionId *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKTon_kotlin_tlByteString *)encodeToByteStringValue:(TKKTon_kotlin_liteapi_tlLiteServerTransactionId *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteString(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_liteapi_tlLiteServerTransactionId *)value __attribute__((swift_name("hash(value:)")));

/**
 * @note annotations
 *   kotlin.jvm.JvmStatic
*/
- (int32_t)modeAccount:(BOOL)account lt:(BOOL)lt hash:(BOOL)hash __attribute__((swift_name("mode(account:lt:hash:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((swift_name("Ton_kotlin_tonapi_tlAdnlAddress")))
@protocol TKKTon_kotlin_tonapi_tlAdnlAddress <TKKTon_kotlin_tlTlObject>
@required
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_tonapi_tlAdnlAddressList.Companion")))
@interface TKKTon_kotlin_tonapi_tlAdnlAddressListCompanion : TKKTon_kotlin_tlTlConstructor<TKKTon_kotlin_tonapi_tlAdnlAddressList *>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (instancetype)initWithSchema:(NSString *)schema id:(TKKInt * _Nullable)id __attribute__((swift_name("init(schema:id:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_tonapi_tlAdnlAddressListCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_tonapi_tlAdnlAddressList *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_tonapi_tlAdnlAddressList *)value __attribute__((swift_name("encode(writer:value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_tonapi_tlAdnlNode.Companion")))
@interface TKKTon_kotlin_tonapi_tlAdnlNodeCompanion : TKKTon_kotlin_tlTlConstructor<TKKTon_kotlin_tonapi_tlAdnlNode *>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (instancetype)initWithSchema:(NSString *)schema id:(TKKInt * _Nullable)id __attribute__((swift_name("init(schema:id:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_tonapi_tlAdnlNodeCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_tonapi_tlAdnlNode *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_tonapi_tlAdnlNode *)value __attribute__((swift_name("encode(writer:value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_tonapi_tlAdnlNodes.Companion")))
@interface TKKTon_kotlin_tonapi_tlAdnlNodesCompanion : TKKBase <TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_tonapi_tlAdnlNodesCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_tonapi_tlAdnlNodes *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_tonapi_tlAdnlNodes *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_tonapi_tlAdnlNodes *)decodeByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decode(byteString:)")));
- (TKKTon_kotlin_tonapi_tlAdnlNodes *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_tonapi_tlAdnlNodes *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_tonapi_tlAdnlNodes *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_tonapi_tlAdnlNodes *)decodeBoxedByteString:(TKKTon_kotlin_tlByteString *)byteString __attribute__((swift_name("decodeBoxed(byteString:)")));
- (TKKTon_kotlin_tonapi_tlAdnlNodes *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_tonapi_tlAdnlNodes *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_tonapi_tlAdnlNodes *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_tonapi_tlAdnlNodes *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_tonapi_tlAdnlNodes *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_tonapi_tlAdnlNodes *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKTon_kotlin_tlByteString *)encodeToByteStringValue:(TKKTon_kotlin_tonapi_tlAdnlNodes *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteString(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_tonapi_tlAdnlNodes *)value __attribute__((swift_name("hash(value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

#pragma pop_macro("_Nullable_result")
#pragma clang diagnostic pop
NS_ASSUME_NONNULL_END
