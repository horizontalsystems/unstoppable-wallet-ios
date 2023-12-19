#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSError.h>
#import <Foundation/NSObject.h>
#import <Foundation/NSSet.h>
#import <Foundation/NSString.h>
#import <Foundation/NSValue.h>

@class TKKTonApiAdnl, TKKBalanceStorage, TKKTonBalanceQueries, TKKDriverFactory, TKKTonTransactionQueries, TKKKitDatabaseCompanion, TKKTonTransactionAdapter, TKKKotlinThrowable, TKKKotlinArray<T>, TKKKotlinException, TKKSyncError, TKKSyncState, TKKTransactionManager, TKKBalanceManager, TKKConnectionManager, TKKTon_kotlin_blockAddrStd, TKKTon_kotlin_liteclientFullAccountState, TKKTonTransaction, TKKTonBalance, TKKKotlinUnit, TKKRuntimeTransacterTransaction, TKKRuntimeBaseTransacterImpl, TKKRuntimeTransacterImpl, TKKRuntimeQuery<__covariant RowType>, TKKSyncer, TKKTransactionSender, TKKTonKitCompanion, TKKTransactionType, TKKTonKit, TKKKotlinByteArray, TKKTransactionStorage, TKKKotlinEnumCompanion, TKKKotlinEnum<E>, TKKTransferCompanion, TKKTransfer, TKKKotlinByteIterator, NSData, TKKKotlinRuntimeException, TKKKotlinIllegalStateException, TKKRuntimeAfterVersion, TKKTon_kotlin_tlbTlbPrettyPrinter, TKKTon_kotlin_blockAnycast, TKKTon_kotlin_blockAddrStdCompanion, TKKTon_kotlin_apiTonNodeBlockIdExt, TKKTon_kotlin_liteclientTransactionId, TKKTon_kotlin_liteclientFullAccountStateCompanion, TKKTon_kotlin_liteapiLiteServerGetAccountState, TKKTon_kotlin_liteapiLiteServerAccountState, TKKTon_kotlin_liteapiLiteServerGetAllShardsInfo, TKKTon_kotlin_liteapiLiteServerAllShardsInfo, TKKTon_kotlin_liteapiLiteServerGetBlock, TKKTon_kotlin_liteapiLiteServerBlockData, TKKTon_kotlin_liteapiLiteServerGetBlockHeader, TKKTon_kotlin_liteapiLiteServerBlockHeader, TKKTon_kotlin_liteapiLiteServerGetBlockProof, TKKTon_kotlin_liteapiLiteServerPartialBlockProof, TKKTon_kotlin_liteapiLiteServerGetConfigAll, TKKTon_kotlin_liteapiLiteServerConfigInfo, TKKTon_kotlin_liteapiLiteServerGetConfigParams, TKKTon_kotlin_liteapiLiteServerGetMasterchainInfo, TKKTon_kotlin_liteapiLiteServerMasterchainInfo, TKKTon_kotlin_liteapiLiteServerGetMasterchainInfoExt, TKKTon_kotlin_liteapiLiteServerMasterchainInfoExt, TKKTon_kotlin_liteapiLiteServerGetOneTransaction, TKKTon_kotlin_liteapiLiteServerTransactionInfo, TKKTon_kotlin_liteapiLiteServerGetShardInfo, TKKTon_kotlin_liteapiLiteServerShardInfo, TKKTon_kotlin_liteapiLiteServerGetState, TKKTon_kotlin_liteapiLiteServerBlockState, TKKTon_kotlin_liteapiLiteServerGetTime, TKKTon_kotlin_liteapiLiteServerCurrentTime, TKKTon_kotlin_liteapiLiteServerGetTransactions, TKKTon_kotlin_liteapiLiteServerTransactionList, TKKTon_kotlin_liteapiLiteServerGetValidatorStats, TKKTon_kotlin_liteapiLiteServerValidatorStats, TKKTon_kotlin_liteapiLiteServerGetVersion, TKKTon_kotlin_liteapiLiteServerVersion, TKKTon_kotlin_liteapiLiteServerListBlockTransactions, TKKTon_kotlin_liteapiLiteServerBlockTransactions, TKKTon_kotlin_liteapiLiteServerLookupBlock, TKKTon_kotlin_liteapiLiteServerRunSmcMethod, TKKTon_kotlin_liteapiLiteServerRunMethodResult, TKKTon_kotlin_liteapiLiteServerSendMessage, TKKTon_kotlin_liteapiLiteServerSendMsgStatus, TKKRuntimeExecutableQuery<__covariant RowType>, TKKTon_kotlin_apiPublicKeyEd25519, TKKTon_kotlin_tlByteString, TKKKotlinStringBuilder, TKKKotlinBooleanArray, TKKKotlinIntRange, TKKTon_kotlin_blockAnycastCompanion, TKKTon_kotlin_tlbTlbConstructor<T>, TKKTon_kotlin_apiTonNodeBlockIdExtCompanion, TKKTon_kotlin_liteclientTransactionIdCompanion, TKKTon_kotlin_liteapiLiteServerAccountId, TKKTon_kotlin_liteapiLiteServerGetAccountStateCompanion, TKKTon_kotlin_liteapiLiteServerAccountStateCompanion, TKKTon_kotlin_liteapiLiteServerGetAllShardsInfoCompanion, TKKTon_kotlin_liteapiLiteServerAllShardsInfoCompanion, TKKTon_kotlin_liteapiLiteServerGetBlockCompanion, TKKTon_kotlin_liteapiLiteServerBlockDataCompanion, TKKTon_kotlin_liteapiLiteServerGetBlockHeaderCompanion, TKKTon_kotlin_liteapiLiteServerBlockHeaderCompanion, TKKTon_kotlin_liteapiLiteServerGetBlockProofCompanion, TKKTon_kotlin_liteapiLiteServerPartialBlockProofCompanion, TKKTon_kotlin_liteapiLiteServerGetConfigAllCompanion, TKKTon_kotlin_liteapiLiteServerConfigInfoCompanion, TKKTon_kotlin_liteapiLiteServerGetConfigParamsCompanion, TKKKtor_ioInput, TKKTon_kotlin_tlTlReader, TKKKtor_ioOutput, TKKTon_kotlin_tlTlWriter, TKKTon_kotlin_apiTonNodeZeroStateIdExt, TKKTon_kotlin_liteapiLiteServerMasterchainInfoCompanion, TKKTon_kotlin_liteapiLiteServerGetMasterchainInfoExtCompanion, TKKTon_kotlin_liteapiLiteServerMasterchainInfoExtCompanion, TKKTon_kotlin_liteapiLiteServerGetOneTransactionCompanion, TKKTon_kotlin_liteapiLiteServerTransactionInfoCompanion, TKKTon_kotlin_liteapiLiteServerGetShardInfoCompanion, TKKTon_kotlin_liteapiLiteServerShardInfoCompanion, TKKTon_kotlin_liteapiLiteServerGetStateCompanion, TKKTon_kotlin_liteapiLiteServerBlockStateCompanion, TKKTon_kotlin_liteapiLiteServerCurrentTimeCompanion, TKKTon_kotlin_liteapiLiteServerGetTransactionsCompanion, TKKTon_kotlin_liteapiLiteServerTransactionListCompanion, TKKTon_kotlin_liteapiLiteServerGetValidatorStatsCompanion, TKKTon_kotlin_liteapiLiteServerValidatorStatsCompanion, TKKTon_kotlin_liteapiLiteServerVersionCompanion, TKKTon_kotlin_liteapiLiteServerTransactionId3, TKKTon_kotlin_liteapiLiteServerListBlockTransactionsCompanion, TKKTon_kotlin_liteapiLiteServerTransactionId, TKKTon_kotlin_liteapiLiteServerBlockTransactionsCompanion, TKKTon_kotlin_liteapiLiteServerLookupBlockCompanion, TKKTon_kotlin_liteapiLiteServerRunSmcMethodCompanion, TKKTon_kotlin_liteapiLiteServerRunMethodResultCompanion, TKKTon_kotlin_liteapiLiteServerSendMessageCompanion, TKKTon_kotlin_liteapiLiteServerSendMsgStatusCompanion, TKKTon_kotlin_apiPublicKeyEd25519Companion, TKKTon_kotlin_tlByteStringCompanion, TKKTon_kotlin_apiOverlayNode, TKKKotlinx_serialization_coreSerializersModule, TKKKotlinx_serialization_coreSerialKind, TKKKotlinNothing, TKKKotlinCharArray, TKKKotlinBooleanIterator, TKKKotlinIntProgressionCompanion, TKKKotlinIntIterator, TKKKotlinIntProgression, TKKKotlinIntRangeCompanion, TKKTon_kotlin_cellCellType, TKKTon_kotlin_bigintBigInt, TKKTon_kotlin_tlbAbstractTlbConstructorCompanion, TKKTon_kotlin_tlbAbstractTlbConstructor<T>, TKKTon_kotlin_liteapiLiteServerAccountIdCompanion, TKKTon_kotlin_tlTlConstructor<T>, TKKKtor_ioChunkBuffer, TKKKtor_ioInputCompanion, TKKKtor_ioMemory, TKKKtor_ioByteReadPacket, TKKTon_kotlin_apiTonNodeZeroStateIdExtCompanion, TKKTon_kotlin_liteapiLiteServerTransactionId3Companion, TKKTon_kotlin_liteapiLiteServerTransactionIdCompanion, TKKTon_kotlin_apiOverlayNodeCompanion, TKKKotlinCharIterator, TKKTon_kotlin_cellCellTypeCompanion, TKKKotlinNumber, TKKKtor_ioBufferCompanion, TKKKtor_ioBuffer, TKKKtor_ioChunkBufferCompanion, TKKKtor_ioMemoryCompanion, TKKKtor_ioByteReadPacketCompanion, TKKTon_kotlin_blockVmStackNull;

@protocol TKKKotlinx_coroutines_coreFlow, TKKKotlinx_coroutines_coreStateFlow, TKKRuntimeSqlDriver, TKKRuntimeTransactionWithoutReturn, TKKRuntimeTransactionWithReturn, TKKRuntimeTransacterBase, TKKRuntimeTransacter, TKKKitDatabase, TKKRuntimeSqlSchema, TKKTon_kotlin_liteapiLiteApi, TKKRuntimeColumnAdapter, TKKTon_kotlin_apiPrivateKeyEd25519, TKKKotlinComparable, TKKKotlinx_serialization_coreKSerializer, TKKCancellable, TKKKotlinx_coroutines_coreFlowCollector, TKKKotlinx_coroutines_coreSharedFlow, TKKRuntimeQueryListener, TKKRuntimeQueryResult, TKKRuntimeSqlPreparedStatement, TKKRuntimeSqlCursor, TKKRuntimeCloseable, TKKRuntimeTransactionCallbacks, TKKKotlinIterator, TKKTon_kotlin_tlbTlbObject, TKKTon_kotlin_blockMsgAddress, TKKTon_kotlin_blockMsgAddressInt, TKKTon_kotlin_bitstringBitString, TKKTon_kotlin_blockMaybe, TKKTon_kotlin_tlbCellRef, TKKTon_kotlin_apiPublicKey, TKKTon_kotlin_apiAdnlIdShort, TKKTon_kotlin_cryptoDecryptor, TKKTon_kotlin_apiPrivateKey, TKKKotlinx_serialization_coreEncoder, TKKKotlinx_serialization_coreSerialDescriptor, TKKKotlinx_serialization_coreSerializationStrategy, TKKKotlinx_serialization_coreDecoder, TKKKotlinx_serialization_coreDeserializationStrategy, TKKTon_kotlin_bitstringMutableBitString, TKKKotlinIterable, TKKTon_kotlin_cellCell, TKKTon_kotlin_cellCellBuilder, TKKTon_kotlin_tlbTlbStorer, TKKTon_kotlin_cellCellSlice, TKKTon_kotlin_tlbTlbLoader, TKKTon_kotlin_tlbTlbCodec, TKKTon_kotlin_apiTonNodeBlockId, TKKTon_kotlin_tlTlCodec, TKKTon_kotlin_tlTLFunction, TKKTon_kotlin_liteapiLiteServerBlockLink, TKKTon_kotlin_tlTlDecoder, TKKTon_kotlin_tlTlEncoder, TKKTon_kotlin_cryptoEncryptor, TKKTon_kotlin_tlTlObject, TKKKotlinx_serialization_coreCompositeEncoder, TKKKotlinAnnotation, TKKKotlinx_serialization_coreCompositeDecoder, TKKKotlinCharSequence, TKKKotlinAppendable, TKKKotlinClosedRange, TKKKotlinOpenEndRange, TKKTon_kotlin_tlbTlbProvider, TKKTon_kotlin_tlbTlbConstructorProvider, TKKKotlinSequence, TKKTon_kotlin_cellCellDescriptor, TKKKtor_ioCloseable, TKKKtor_ioObjectPool, TKKTon_kotlin_blockVmStackValue, TKKTon_kotlin_blockVmStack, TKKTon_kotlin_blockVmStackList, TKKTon_kotlin_apiSignedTlObject, TKKKotlinx_serialization_coreSerializersModuleCollector, TKKKotlinKClass, TKKTon_kotlin_blockMutableVmStack, TKKKotlinCollection, TKKKotlinKDeclarationContainer, TKKKotlinKAnnotatedElement, TKKKotlinKClassifier, TKKTon_kotlin_blockVmCont, TKKTon_kotlin_blockVmStackNumber, TKKTon_kotlin_blockVmTuple;

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
- (instancetype)initWithAddrStd:(TKKTon_kotlin_blockAddrStd *)addrStd __attribute__((swift_name("init(addrStd:)"))) __attribute__((objc_designated_initializer));

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
- (void)getLiteApiWithCompletionHandler:(void (^)(id<TKKTon_kotlin_liteapiLiteApi> _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("getLiteApi(completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)transactionsTransactionHash:(NSString * _Nullable)transactionHash lt:(TKKLong * _Nullable)lt limit:(int32_t)limit completionHandler:(void (^)(NSArray<TKKTonTransaction *> * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("transactions(transactionHash:lt:limit:completionHandler:)")));
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
- (void)sendRecipient:(NSString *)recipient amount:(NSString *)amount completionHandler:(void (^)(NSError * _Nullable))completionHandler __attribute__((swift_name("send(recipient:amount:completionHandler:)")));
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
- (instancetype)initWithHash:(NSString *)hash lt:(int64_t)lt timestamp:(int64_t)timestamp amount:(NSString * _Nullable)amount fee:(NSString * _Nullable)fee type:(TKKTransactionType *)type transfersJson:(NSString *)transfersJson __attribute__((swift_name("init(hash:lt:timestamp:amount:fee:type:transfersJson:)"))) __attribute__((objc_designated_initializer));
- (TKKTonTransaction *)doCopyHash:(NSString *)hash lt:(int64_t)lt timestamp:(int64_t)timestamp amount:(NSString * _Nullable)amount fee:(NSString * _Nullable)fee type:(TKKTransactionType *)type transfersJson:(NSString *)transfersJson __attribute__((swift_name("doCopy(hash:lt:timestamp:amount:fee:type:transfersJson:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSString * _Nullable amount __attribute__((swift_name("amount")));
@property (readonly) NSString * _Nullable fee __attribute__((swift_name("fee")));
@property (readonly, getter=hash_) NSString *hash __attribute__((swift_name("hash")));
@property (readonly) int64_t lt __attribute__((swift_name("lt")));
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
- (TKKRuntimeQuery<id> *)getAllLimit:(int64_t)limit mapper:(id (^)(NSString *, TKKLong *, TKKLong *, NSString * _Nullable, NSString * _Nullable, TKKTransactionType *, NSString *))mapper __attribute__((swift_name("getAll(limit:mapper:)")));
- (TKKRuntimeQuery<TKKTonTransaction *> *)getAllByTypeType:(TKKTransactionType *)type limit:(int64_t)limit __attribute__((swift_name("getAllByType(type:limit:)")));
- (TKKRuntimeQuery<id> *)getAllByTypeType:(TKKTransactionType *)type limit:(int64_t)limit mapper:(id (^)(NSString *, TKKLong *, TKKLong *, NSString * _Nullable, NSString * _Nullable, TKKTransactionType *, NSString *))mapper __attribute__((swift_name("getAllByType(type:limit:mapper:)")));
- (TKKRuntimeQuery<TKKTonTransaction *> *)getByHashHash:(NSString *)hash __attribute__((swift_name("getByHash(hash:)")));
- (TKKRuntimeQuery<id> *)getByHashHash:(NSString *)hash mapper:(id (^)(NSString *, TKKLong *, TKKLong *, NSString * _Nullable, NSString * _Nullable, TKKTransactionType *, NSString *))mapper __attribute__((swift_name("getByHash(hash:mapper:)")));
- (TKKRuntimeQuery<TKKTonTransaction *> *)getEarlierThanTimestamp:(int64_t)timestamp lt:(int64_t)lt limit:(int64_t)limit __attribute__((swift_name("getEarlierThan(timestamp:lt:limit:)")));
- (TKKRuntimeQuery<id> *)getEarlierThanTimestamp:(int64_t)timestamp lt:(int64_t)lt limit:(int64_t)limit mapper:(id (^)(NSString *, TKKLong *, TKKLong *, NSString * _Nullable, NSString * _Nullable, TKKTransactionType *, NSString *))mapper __attribute__((swift_name("getEarlierThan(timestamp:lt:limit:mapper:)")));
- (TKKRuntimeQuery<TKKTonTransaction *> *)getEarlierThanByTypeType:(TKKTransactionType *)type timestamp:(int64_t)timestamp lt:(int64_t)lt limit:(int64_t)limit __attribute__((swift_name("getEarlierThanByType(type:timestamp:lt:limit:)")));
- (TKKRuntimeQuery<id> *)getEarlierThanByTypeType:(TKKTransactionType *)type timestamp:(int64_t)timestamp lt:(int64_t)lt limit:(int64_t)limit mapper:(id (^)(NSString *, TKKLong *, TKKLong *, NSString * _Nullable, NSString * _Nullable, TKKTransactionType *, NSString *))mapper __attribute__((swift_name("getEarlierThanByType(type:timestamp:lt:limit:mapper:)")));
- (TKKRuntimeQuery<TKKTonTransaction *> *)getEarliest __attribute__((swift_name("getEarliest()")));
- (TKKRuntimeQuery<id> *)getEarliestMapper:(id (^)(NSString *, TKKLong *, TKKLong *, NSString * _Nullable, NSString * _Nullable, TKKTransactionType *, NSString *))mapper __attribute__((swift_name("getEarliest(mapper:)")));
- (TKKRuntimeQuery<TKKTonTransaction *> *)getLatest __attribute__((swift_name("getLatest()")));
- (TKKRuntimeQuery<id> *)getLatestMapper:(id (^)(NSString *, TKKLong *, TKKLong *, NSString * _Nullable, NSString * _Nullable, TKKTransactionType *, NSString *))mapper __attribute__((swift_name("getLatest(mapper:)")));
- (void)insertHash:(NSString *)hash lt:(int64_t)lt timestamp:(int64_t)timestamp amount:(NSString * _Nullable)amount fee:(NSString * _Nullable)fee type:(TKKTransactionType *)type transfersJson:(NSString *)transfersJson __attribute__((swift_name("insert(hash:lt:timestamp:amount:fee:type:transfersJson:)")));
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
- (instancetype)initWithAdnl:(TKKTonApiAdnl *)adnl privateKey:(id<TKKTon_kotlin_apiPrivateKeyEd25519>)privateKey __attribute__((swift_name("init(adnl:privateKey:)"))) __attribute__((objc_designated_initializer));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)estimateFeeWithCompletionHandler:(void (^)(NSString * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("estimateFee(completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)sendRecipient:(NSString *)recipient amount:(NSString *)amount completionHandler:(void (^)(NSError * _Nullable))completionHandler __attribute__((swift_name("send(recipient:amount:completionHandler:)")));
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
__attribute__((swift_name("Ton_kotlin_blockMsgAddress")))
@protocol TKKTon_kotlin_blockMsgAddress <TKKTon_kotlin_tlbTlbObject>
@required
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((swift_name("Ton_kotlin_blockMsgAddressInt")))
@protocol TKKTon_kotlin_blockMsgAddressInt <TKKTon_kotlin_blockMsgAddress>
@required
@property (readonly) int32_t workchainId __attribute__((swift_name("workchainId")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_blockAddrStd")))
@interface TKKTon_kotlin_blockAddrStd : TKKBase <TKKTon_kotlin_blockMsgAddressInt>
- (instancetype)initWithWorkchainId:(int32_t)workchainId address:(id<TKKTon_kotlin_bitstringBitString>)address __attribute__((swift_name("init(workchainId:address:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithWorkchainId:(int32_t)workchainId address_:(TKKKotlinByteArray *)address __attribute__((swift_name("init(workchainId:address_:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithAnycast:(TKKTon_kotlin_blockAnycast * _Nullable)anycast workchainId:(int32_t)workchainId address:(TKKKotlinByteArray *)address __attribute__((swift_name("init(anycast:workchainId:address:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithAnycast:(TKKTon_kotlin_blockAnycast * _Nullable)anycast workchainId:(int32_t)workchainId address_:(id<TKKTon_kotlin_bitstringBitString>)address __attribute__((swift_name("init(anycast:workchainId:address_:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithAnycast:(id<TKKTon_kotlin_blockMaybe>)anycast workchainId:(int32_t)workchainId address__:(id<TKKTon_kotlin_bitstringBitString>)address __attribute__((swift_name("init(anycast:workchainId:address__:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_blockAddrStdCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_blockAddrStd *)doCopyAnycast:(id<TKKTon_kotlin_blockMaybe>)anycast workchainId:(int32_t)workchainId address:(id<TKKTon_kotlin_bitstringBitString>)address __attribute__((swift_name("doCopy(anycast:workchainId:address:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (TKKTon_kotlin_tlbTlbPrettyPrinter *)printPrinter:(TKKTon_kotlin_tlbTlbPrettyPrinter *)printer __attribute__((swift_name("print(printer:)")));
- (NSString *)description __attribute__((swift_name("description()")));
- (NSString *)toStringUserFriendly:(BOOL)userFriendly urlSafe:(BOOL)urlSafe testOnly:(BOOL)testOnly bounceable:(BOOL)bounceable __attribute__((swift_name("toString(userFriendly:urlSafe:testOnly:bounceable:)")));
@property (readonly) id<TKKTon_kotlin_bitstringBitString> address __attribute__((swift_name("address")));
@property (readonly) id<TKKTon_kotlin_blockMaybe> anycast __attribute__((swift_name("anycast")));
@property (readonly) int32_t workchainId __attribute__((swift_name("workchainId")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteclientFullAccountState")))
@interface TKKTon_kotlin_liteclientFullAccountState : TKKBase
- (instancetype)initWithBlockId:(TKKTon_kotlin_apiTonNodeBlockIdExt *)blockId address:(TKKTon_kotlin_blockAddrStd *)address lastTransactionId:(TKKTon_kotlin_liteclientTransactionId * _Nullable)lastTransactionId account:(id<TKKTon_kotlin_tlbCellRef>)account __attribute__((swift_name("init(blockId:address:lastTransactionId:account:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteclientFullAccountStateCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteclientFullAccountState *)doCopyBlockId:(TKKTon_kotlin_apiTonNodeBlockIdExt *)blockId address:(TKKTon_kotlin_blockAddrStd *)address lastTransactionId:(TKKTon_kotlin_liteclientTransactionId * _Nullable)lastTransactionId account:(id<TKKTon_kotlin_tlbCellRef>)account __attribute__((swift_name("doCopy(blockId:address:lastTransactionId:account:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) id<TKKTon_kotlin_tlbCellRef> account __attribute__((swift_name("account")));
@property (readonly) TKKTon_kotlin_blockAddrStd *address __attribute__((swift_name("address")));
@property (readonly) TKKTon_kotlin_apiTonNodeBlockIdExt *blockId __attribute__((swift_name("blockId")));
@property (readonly) TKKTon_kotlin_liteclientTransactionId * _Nullable lastTransactionId __attribute__((swift_name("lastTransactionId")));
@end

__attribute__((swift_name("Ton_kotlin_liteapiLiteApi")))
@protocol TKKTon_kotlin_liteapiLiteApi
@required

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)invokeFunction:(TKKTon_kotlin_liteapiLiteServerGetAccountState *)function waitMasterchainSeqno:(int32_t)waitMasterchainSeqno completionHandler:(void (^)(TKKTon_kotlin_liteapiLiteServerAccountState * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("invoke(function:waitMasterchainSeqno:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)invokeFunction:(TKKTon_kotlin_liteapiLiteServerGetAllShardsInfo *)function completionHandler:(void (^)(TKKTon_kotlin_liteapiLiteServerAllShardsInfo * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("invoke(function:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)invokeFunction:(TKKTon_kotlin_liteapiLiteServerGetBlock *)function completionHandler_:(void (^)(TKKTon_kotlin_liteapiLiteServerBlockData * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("invoke(function:completionHandler_:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)invokeFunction:(TKKTon_kotlin_liteapiLiteServerGetBlockHeader *)function completionHandler__:(void (^)(TKKTon_kotlin_liteapiLiteServerBlockHeader * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("invoke(function:completionHandler__:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)invokeFunction:(TKKTon_kotlin_liteapiLiteServerGetBlockProof *)function completionHandler___:(void (^)(TKKTon_kotlin_liteapiLiteServerPartialBlockProof * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("invoke(function:completionHandler___:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)invokeFunction:(TKKTon_kotlin_liteapiLiteServerGetConfigAll *)function completionHandler____:(void (^)(TKKTon_kotlin_liteapiLiteServerConfigInfo * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("invoke(function:completionHandler____:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)invokeFunction:(TKKTon_kotlin_liteapiLiteServerGetConfigParams *)function completionHandler_____:(void (^)(TKKTon_kotlin_liteapiLiteServerConfigInfo * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("invoke(function:completionHandler_____:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)invokeFunction:(TKKTon_kotlin_liteapiLiteServerGetMasterchainInfo *)function waitMasterchainSeqno:(int32_t)waitMasterchainSeqno completionHandler_:(void (^)(TKKTon_kotlin_liteapiLiteServerMasterchainInfo * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("invoke(function:waitMasterchainSeqno:completionHandler_:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)invokeFunction:(TKKTon_kotlin_liteapiLiteServerGetMasterchainInfoExt *)function waitMasterchainSeqno:(int32_t)waitMasterchainSeqno completionHandler__:(void (^)(TKKTon_kotlin_liteapiLiteServerMasterchainInfoExt * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("invoke(function:waitMasterchainSeqno:completionHandler__:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)invokeFunction:(TKKTon_kotlin_liteapiLiteServerGetOneTransaction *)function completionHandler______:(void (^)(TKKTon_kotlin_liteapiLiteServerTransactionInfo * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("invoke(function:completionHandler______:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)invokeFunction:(TKKTon_kotlin_liteapiLiteServerGetShardInfo *)function completionHandler_______:(void (^)(TKKTon_kotlin_liteapiLiteServerShardInfo * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("invoke(function:completionHandler_______:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)invokeFunction:(TKKTon_kotlin_liteapiLiteServerGetState *)function completionHandler________:(void (^)(TKKTon_kotlin_liteapiLiteServerBlockState * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("invoke(function:completionHandler________:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)invokeFunction:(TKKTon_kotlin_liteapiLiteServerGetTime *)function completionHandler_________:(void (^)(TKKTon_kotlin_liteapiLiteServerCurrentTime * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("invoke(function:completionHandler_________:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)invokeFunction:(TKKTon_kotlin_liteapiLiteServerGetTransactions *)function completionHandler__________:(void (^)(TKKTon_kotlin_liteapiLiteServerTransactionList * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("invoke(function:completionHandler__________:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)invokeFunction:(TKKTon_kotlin_liteapiLiteServerGetValidatorStats *)function completionHandler___________:(void (^)(TKKTon_kotlin_liteapiLiteServerValidatorStats * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("invoke(function:completionHandler___________:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)invokeFunction:(TKKTon_kotlin_liteapiLiteServerGetVersion *)function completionHandler____________:(void (^)(TKKTon_kotlin_liteapiLiteServerVersion * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("invoke(function:completionHandler____________:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)invokeFunction:(TKKTon_kotlin_liteapiLiteServerListBlockTransactions *)function completionHandler_____________:(void (^)(TKKTon_kotlin_liteapiLiteServerBlockTransactions * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("invoke(function:completionHandler_____________:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)invokeFunction:(TKKTon_kotlin_liteapiLiteServerLookupBlock *)function waitMasterchainSeqno:(int32_t)waitMasterchainSeqno completionHandler___:(void (^)(TKKTon_kotlin_liteapiLiteServerBlockHeader * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("invoke(function:waitMasterchainSeqno:completionHandler___:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)invokeFunction:(TKKTon_kotlin_liteapiLiteServerRunSmcMethod *)function completionHandler______________:(void (^)(TKKTon_kotlin_liteapiLiteServerRunMethodResult * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("invoke(function:completionHandler______________:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)invokeFunction:(TKKTon_kotlin_liteapiLiteServerSendMessage *)function completionHandler_______________:(void (^)(TKKTon_kotlin_liteapiLiteServerSendMsgStatus * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("invoke(function:completionHandler_______________:)")));
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
__attribute__((swift_name("Ton_kotlin_apiPrivateKey")))
@protocol TKKTon_kotlin_apiPrivateKey <TKKTon_kotlin_cryptoDecryptor>
@required
- (id<TKKTon_kotlin_apiPublicKey>)publicKey __attribute__((swift_name("publicKey()")));
- (id<TKKTon_kotlin_apiAdnlIdShort>)toAdnlIdShort __attribute__((swift_name("toAdnlIdShort()")));
@end

__attribute__((swift_name("Ton_kotlin_apiPrivateKeyEd25519")))
@protocol TKKTon_kotlin_apiPrivateKeyEd25519 <TKKTon_kotlin_apiPrivateKey>
@required
- (TKKKotlinByteArray *)sharedKeyPublicKey:(TKKTon_kotlin_apiPublicKeyEd25519 *)publicKey __attribute__((swift_name("sharedKey(publicKey:)")));
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


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_blockAnycast")))
@interface TKKTon_kotlin_blockAnycast : TKKBase <TKKTon_kotlin_tlbTlbObject>
- (instancetype)initWithRewritePfx:(id<TKKTon_kotlin_bitstringBitString>)rewritePfx __attribute__((swift_name("init(rewritePfx:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithDepth:(int32_t)depth rewritePfx:(id<TKKTon_kotlin_bitstringBitString>)rewritePfx __attribute__((swift_name("init(depth:rewritePfx:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_blockAnycastCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_blockAnycast *)doCopyDepth:(int32_t)depth rewritePfx:(id<TKKTon_kotlin_bitstringBitString>)rewritePfx __attribute__((swift_name("doCopy(depth:rewritePfx:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (TKKTon_kotlin_tlbTlbPrettyPrinter *)printPrinter:(TKKTon_kotlin_tlbTlbPrettyPrinter *)printer __attribute__((swift_name("print(printer:)")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) int32_t depth __attribute__((swift_name("depth")));
@property (readonly) id<TKKTon_kotlin_bitstringBitString> rewritePfx __attribute__((swift_name("rewritePfx")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((swift_name("Ton_kotlin_blockMaybe")))
@protocol TKKTon_kotlin_blockMaybe <TKKTon_kotlin_tlbTlbObject>
@required
- (id _Nullable)get __attribute__((swift_name("get()")));
@property (readonly) id _Nullable value __attribute__((swift_name("value")));
@end

__attribute__((swift_name("Ton_kotlin_tlbTlbStorer")))
@protocol TKKTon_kotlin_tlbTlbStorer
@required
- (id<TKKTon_kotlin_cellCell>)createCellValue:(id _Nullable)value __attribute__((swift_name("createCell(value:)")));
- (void)storeTlbCellBuilder:(id<TKKTon_kotlin_cellCellBuilder>)cellBuilder value:(id _Nullable)value __attribute__((swift_name("storeTlb(cellBuilder:value:)")));
@end

__attribute__((swift_name("Ton_kotlin_tlbTlbLoader")))
@protocol TKKTon_kotlin_tlbTlbLoader
@required
- (id _Nullable)loadTlbCell:(id<TKKTon_kotlin_cellCell>)cell __attribute__((swift_name("loadTlb(cell:)")));
- (id _Nullable)loadTlbCellSlice:(id<TKKTon_kotlin_cellCellSlice>)cellSlice __attribute__((swift_name("loadTlb(cellSlice:)")));
@end

__attribute__((swift_name("Ton_kotlin_tlbTlbCodec")))
@protocol TKKTon_kotlin_tlbTlbCodec <TKKTon_kotlin_tlbTlbStorer, TKKTon_kotlin_tlbTlbLoader>
@required
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_blockAddrStd.Companion")))
@interface TKKTon_kotlin_blockAddrStdCompanion : TKKBase <TKKTon_kotlin_tlbTlbCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_blockAddrStdCompanion *shared __attribute__((swift_name("shared")));
- (id<TKKTon_kotlin_cellCell>)createCellValue:(TKKTon_kotlin_blockAddrStd *)value __attribute__((swift_name("createCell(value:)")));
- (TKKTon_kotlin_blockAddrStd *)loadTlbCell:(id<TKKTon_kotlin_cellCell>)cell __attribute__((swift_name("loadTlb(cell:)")));
- (TKKTon_kotlin_blockAddrStd *)loadTlbCellSlice:(id<TKKTon_kotlin_cellCellSlice>)cellSlice __attribute__((swift_name("loadTlb(cellSlice:)")));

/**
 * @note annotations
 *   kotlin.jvm.JvmStatic
*/
- (TKKTon_kotlin_blockAddrStd *)parseAddress:(NSString *)address __attribute__((swift_name("parse(address:)")));

/**
 * @note annotations
 *   kotlin.jvm.JvmStatic
*/
- (TKKTon_kotlin_blockAddrStd *)parseRawAddress:(NSString *)address __attribute__((swift_name("parseRaw(address:)")));

/**
 * @note annotations
 *   kotlin.jvm.JvmStatic
*/
- (TKKTon_kotlin_blockAddrStd *)parseUserFriendlyAddress:(NSString *)address __attribute__((swift_name("parseUserFriendly(address:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
- (void)storeTlbCellBuilder:(id<TKKTon_kotlin_cellCellBuilder>)cellBuilder value:(TKKTon_kotlin_blockAddrStd *)value __attribute__((swift_name("storeTlb(cellBuilder:value:)")));

/**
 * @note annotations
 *   kotlin.jvm.JvmStatic
*/
- (TKKTon_kotlin_tlbTlbConstructor<TKKTon_kotlin_blockAddrStd *> *)tlbCodec __attribute__((swift_name("tlbCodec()")));

/**
 * @note annotations
 *   kotlin.jvm.JvmStatic
*/
- (NSString *)toStringAddress:(TKKTon_kotlin_blockAddrStd *)address userFriendly:(BOOL)userFriendly urlSafe:(BOOL)urlSafe testOnly:(BOOL)testOnly bounceable:(BOOL)bounceable __attribute__((swift_name("toString(address:userFriendly:urlSafe:testOnly:bounceable:)")));
@end

__attribute__((swift_name("Ton_kotlin_apiTonNodeBlockId")))
@protocol TKKTon_kotlin_apiTonNodeBlockId
@required
- (int32_t)component1 __attribute__((swift_name("component1()")));
- (int64_t)component2 __attribute__((swift_name("component2()")));
- (int32_t)component3 __attribute__((swift_name("component3()")));
- (BOOL)isMasterchain __attribute__((swift_name("isMasterchain()")));
- (BOOL)isValid __attribute__((swift_name("isValid()")));
- (BOOL)isValidExt __attribute__((swift_name("isValidExt()")));
- (BOOL)isValidFull __attribute__((swift_name("isValidFull()")));
- (id<TKKTon_kotlin_apiTonNodeBlockId>)withSeqnoSeqno:(int32_t)seqno __attribute__((swift_name("withSeqno(seqno:)")));
@property (readonly) int32_t seqno __attribute__((swift_name("seqno")));
@property (readonly) int64_t shard __attribute__((swift_name("shard")));
@property (readonly) int32_t workchain __attribute__((swift_name("workchain")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_apiTonNodeBlockIdExt")))
@interface TKKTon_kotlin_apiTonNodeBlockIdExt : TKKBase <TKKTon_kotlin_apiTonNodeBlockId>
- (instancetype)initWithWorkchain:(int32_t)workchain shard:(int64_t)shard seqno:(int32_t)seqno rootHash:(TKKKotlinByteArray *)rootHash fileHash:(TKKKotlinByteArray *)fileHash __attribute__((swift_name("init(workchain:shard:seqno:rootHash:fileHash:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithTonNodeBlockId:(id<TKKTon_kotlin_apiTonNodeBlockId>)tonNodeBlockId rootHash:(TKKKotlinByteArray *)rootHash fileHash:(TKKKotlinByteArray *)fileHash __attribute__((swift_name("init(tonNodeBlockId:rootHash:fileHash:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithTonNodeBlockId:(id<TKKTon_kotlin_apiTonNodeBlockId>)tonNodeBlockId rootHash:(TKKTon_kotlin_tlByteString *)rootHash fileHash_:(TKKTon_kotlin_tlByteString *)fileHash __attribute__((swift_name("init(tonNodeBlockId:rootHash:fileHash_:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithWorkchain:(int32_t)workchain shard:(int64_t)shard seqno:(int32_t)seqno rootHash:(TKKTon_kotlin_tlByteString *)rootHash fileHash_:(TKKTon_kotlin_tlByteString *)fileHash __attribute__((swift_name("init(workchain:shard:seqno:rootHash:fileHash_:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_apiTonNodeBlockIdExtCompanion *companion __attribute__((swift_name("companion")));
- (int32_t)component1 __attribute__((swift_name("component1()")));
- (int64_t)component2 __attribute__((swift_name("component2()")));
- (int32_t)component3 __attribute__((swift_name("component3()")));
- (TKKTon_kotlin_apiTonNodeBlockIdExt *)doCopyWorkchain:(int32_t)workchain shard:(int64_t)shard seqno:(int32_t)seqno rootHash:(TKKTon_kotlin_tlByteString *)rootHash fileHash:(TKKTon_kotlin_tlByteString *)fileHash __attribute__((swift_name("doCopy(workchain:shard:seqno:rootHash:fileHash:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) TKKTon_kotlin_tlByteString *fileHash __attribute__((swift_name("fileHash")));
@property (readonly) TKKTon_kotlin_tlByteString *rootHash __attribute__((swift_name("rootHash")));
@property (readonly) int32_t seqno __attribute__((swift_name("seqno")));
@property (readonly) int64_t shard __attribute__((swift_name("shard")));
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
- (id<TKKTon_kotlin_cellCell>)toCellCodec:(id<TKKTon_kotlin_tlbTlbCodec> _Nullable)codec __attribute__((swift_name("toCell(codec:)")));
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

__attribute__((swift_name("Ton_kotlin_tlTLFunction")))
@protocol TKKTon_kotlin_tlTLFunction
@required
- (id<TKKTon_kotlin_tlTlCodec>)resultTlCodec __attribute__((swift_name("resultTlCodec()")));
- (id<TKKTon_kotlin_tlTlCodec>)tlCodec __attribute__((swift_name("tlCodec()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerGetAccountState")))
@interface TKKTon_kotlin_liteapiLiteServerGetAccountState : TKKBase <TKKTon_kotlin_tlTLFunction>
- (instancetype)initWithId:(TKKTon_kotlin_apiTonNodeBlockIdExt *)id account:(TKKTon_kotlin_liteapiLiteServerAccountId *)account __attribute__((swift_name("init(id:account:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapiLiteServerGetAccountStateCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapiLiteServerGetAccountState *)doCopyId:(TKKTon_kotlin_apiTonNodeBlockIdExt *)id account:(TKKTon_kotlin_liteapiLiteServerAccountId *)account __attribute__((swift_name("doCopy(id:account:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (id<TKKTon_kotlin_tlTlCodec>)resultTlCodec __attribute__((swift_name("resultTlCodec()")));
- (id<TKKTon_kotlin_tlTlCodec>)tlCodec __attribute__((swift_name("tlCodec()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) TKKTon_kotlin_liteapiLiteServerAccountId *account __attribute__((swift_name("account")));
@property (readonly) TKKTon_kotlin_apiTonNodeBlockIdExt *id __attribute__((swift_name("id")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerAccountState")))
@interface TKKTon_kotlin_liteapiLiteServerAccountState : TKKBase
- (instancetype)initWithId:(TKKTon_kotlin_apiTonNodeBlockIdExt *)id shardBlock:(TKKTon_kotlin_apiTonNodeBlockIdExt *)shardBlock shardProof:(TKKKotlinByteArray *)shardProof proof:(TKKKotlinByteArray *)proof state:(TKKKotlinByteArray *)state __attribute__((swift_name("init(id:shardBlock:shardProof:proof:state:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapiLiteServerAccountStateCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapiLiteServerAccountState *)doCopyId:(TKKTon_kotlin_apiTonNodeBlockIdExt *)id shardBlock:(TKKTon_kotlin_apiTonNodeBlockIdExt *)shardBlock shardProof:(TKKKotlinByteArray *)shardProof proof:(TKKKotlinByteArray *)proof state:(TKKKotlinByteArray *)state __attribute__((swift_name("doCopy(id:shardBlock:shardProof:proof:state:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) TKKTon_kotlin_apiTonNodeBlockIdExt *id __attribute__((swift_name("id")));
@property (readonly) TKKKotlinByteArray *proof __attribute__((swift_name("proof")));
@property (readonly) TKKTon_kotlin_apiTonNodeBlockIdExt *shardBlock __attribute__((swift_name("shardBlock")));
@property (readonly) TKKKotlinByteArray *shardProof __attribute__((swift_name("shardProof")));
@property (readonly) TKKKotlinByteArray *state __attribute__((swift_name("state")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerGetAllShardsInfo")))
@interface TKKTon_kotlin_liteapiLiteServerGetAllShardsInfo : TKKBase <TKKTon_kotlin_tlTLFunction>
- (instancetype)initWithId:(TKKTon_kotlin_apiTonNodeBlockIdExt *)id __attribute__((swift_name("init(id:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapiLiteServerGetAllShardsInfoCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapiLiteServerGetAllShardsInfo *)doCopyId:(TKKTon_kotlin_apiTonNodeBlockIdExt *)id __attribute__((swift_name("doCopy(id:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (id<TKKTon_kotlin_tlTlCodec>)resultTlCodec __attribute__((swift_name("resultTlCodec()")));
- (id<TKKTon_kotlin_tlTlCodec>)tlCodec __attribute__((swift_name("tlCodec()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) TKKTon_kotlin_apiTonNodeBlockIdExt *id __attribute__((swift_name("id")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerAllShardsInfo")))
@interface TKKTon_kotlin_liteapiLiteServerAllShardsInfo : TKKBase
- (instancetype)initWithId:(TKKTon_kotlin_apiTonNodeBlockIdExt *)id proof:(TKKKotlinByteArray *)proof data:(TKKKotlinByteArray *)data __attribute__((swift_name("init(id:proof:data:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapiLiteServerAllShardsInfoCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapiLiteServerAllShardsInfo *)doCopyId:(TKKTon_kotlin_apiTonNodeBlockIdExt *)id proof:(TKKKotlinByteArray *)proof data:(TKKKotlinByteArray *)data __attribute__((swift_name("doCopy(id:proof:data:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) TKKKotlinByteArray *data __attribute__((swift_name("data")));
@property (readonly) TKKTon_kotlin_apiTonNodeBlockIdExt *id __attribute__((swift_name("id")));
@property (readonly) TKKKotlinByteArray *proof __attribute__((swift_name("proof")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerGetBlock")))
@interface TKKTon_kotlin_liteapiLiteServerGetBlock : TKKBase <TKKTon_kotlin_tlTLFunction>
- (instancetype)initWithId:(TKKTon_kotlin_apiTonNodeBlockIdExt *)id __attribute__((swift_name("init(id:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapiLiteServerGetBlockCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapiLiteServerGetBlock *)doCopyId:(TKKTon_kotlin_apiTonNodeBlockIdExt *)id __attribute__((swift_name("doCopy(id:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (id<TKKTon_kotlin_tlTlCodec>)resultTlCodec __attribute__((swift_name("resultTlCodec()")));
- (id<TKKTon_kotlin_tlTlCodec>)tlCodec __attribute__((swift_name("tlCodec()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) TKKTon_kotlin_apiTonNodeBlockIdExt *id __attribute__((swift_name("id")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerBlockData")))
@interface TKKTon_kotlin_liteapiLiteServerBlockData : TKKBase
- (instancetype)initWithId:(TKKTon_kotlin_apiTonNodeBlockIdExt *)id data:(TKKKotlinByteArray *)data __attribute__((swift_name("init(id:data:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapiLiteServerBlockDataCompanion *companion __attribute__((swift_name("companion")));
@property (readonly) TKKKotlinByteArray *data __attribute__((swift_name("data")));
@property (readonly) TKKTon_kotlin_apiTonNodeBlockIdExt *id __attribute__((swift_name("id")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerGetBlockHeader")))
@interface TKKTon_kotlin_liteapiLiteServerGetBlockHeader : TKKBase <TKKTon_kotlin_tlTLFunction>
- (instancetype)initWithId:(TKKTon_kotlin_apiTonNodeBlockIdExt *)id mode:(int32_t)mode __attribute__((swift_name("init(id:mode:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapiLiteServerGetBlockHeaderCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapiLiteServerGetBlockHeader *)doCopyId:(TKKTon_kotlin_apiTonNodeBlockIdExt *)id mode:(int32_t)mode __attribute__((swift_name("doCopy(id:mode:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (id<TKKTon_kotlin_tlTlCodec>)resultTlCodec __attribute__((swift_name("resultTlCodec()")));
- (id<TKKTon_kotlin_tlTlCodec>)tlCodec __attribute__((swift_name("tlCodec()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) TKKTon_kotlin_apiTonNodeBlockIdExt *id __attribute__((swift_name("id")));
@property (readonly) int32_t mode __attribute__((swift_name("mode")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerBlockHeader")))
@interface TKKTon_kotlin_liteapiLiteServerBlockHeader : TKKBase
- (instancetype)initWithId:(TKKTon_kotlin_apiTonNodeBlockIdExt *)id mode:(int32_t)mode headerProof:(TKKKotlinByteArray *)headerProof __attribute__((swift_name("init(id:mode:headerProof:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapiLiteServerBlockHeaderCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapiLiteServerBlockHeader *)doCopyId:(TKKTon_kotlin_apiTonNodeBlockIdExt *)id mode:(int32_t)mode headerProof:(TKKKotlinByteArray *)headerProof __attribute__((swift_name("doCopy(id:mode:headerProof:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) TKKKotlinByteArray *headerProof __attribute__((swift_name("headerProof")));
@property (readonly) TKKTon_kotlin_apiTonNodeBlockIdExt *id __attribute__((swift_name("id")));
@property (readonly) int32_t mode __attribute__((swift_name("mode")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerGetBlockProof")))
@interface TKKTon_kotlin_liteapiLiteServerGetBlockProof : TKKBase <TKKTon_kotlin_tlTLFunction>
- (instancetype)initWithKnownBlock:(TKKTon_kotlin_apiTonNodeBlockIdExt *)knownBlock targetBlock:(TKKTon_kotlin_apiTonNodeBlockIdExt * _Nullable)targetBlock __attribute__((swift_name("init(knownBlock:targetBlock:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithMode:(int32_t)mode knownBlock:(TKKTon_kotlin_apiTonNodeBlockIdExt *)knownBlock targetBlock:(TKKTon_kotlin_apiTonNodeBlockIdExt * _Nullable)targetBlock __attribute__((swift_name("init(mode:knownBlock:targetBlock:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapiLiteServerGetBlockProofCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapiLiteServerGetBlockProof *)doCopyMode:(int32_t)mode knownBlock:(TKKTon_kotlin_apiTonNodeBlockIdExt *)knownBlock targetBlock:(TKKTon_kotlin_apiTonNodeBlockIdExt * _Nullable)targetBlock __attribute__((swift_name("doCopy(mode:knownBlock:targetBlock:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (id<TKKTon_kotlin_tlTlCodec>)resultTlCodec __attribute__((swift_name("resultTlCodec()")));
- (id<TKKTon_kotlin_tlTlCodec>)tlCodec __attribute__((swift_name("tlCodec()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) TKKTon_kotlin_apiTonNodeBlockIdExt *knownBlock __attribute__((swift_name("knownBlock")));
@property (readonly) int32_t mode __attribute__((swift_name("mode")));
@property (readonly) TKKTon_kotlin_apiTonNodeBlockIdExt * _Nullable targetBlock __attribute__((swift_name("targetBlock")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerPartialBlockProof")))
@interface TKKTon_kotlin_liteapiLiteServerPartialBlockProof : TKKBase
- (instancetype)initWithComplete:(BOOL)complete from:(TKKTon_kotlin_apiTonNodeBlockIdExt *)from to:(TKKTon_kotlin_apiTonNodeBlockIdExt *)to steps:(NSArray<id<TKKTon_kotlin_liteapiLiteServerBlockLink>> *)steps __attribute__((swift_name("init(complete:from:to:steps:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapiLiteServerPartialBlockProofCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapiLiteServerPartialBlockProof *)doCopyComplete:(BOOL)complete from:(TKKTon_kotlin_apiTonNodeBlockIdExt *)from to:(TKKTon_kotlin_apiTonNodeBlockIdExt *)to steps:(NSArray<id<TKKTon_kotlin_liteapiLiteServerBlockLink>> *)steps __attribute__((swift_name("doCopy(complete:from:to:steps:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) BOOL complete __attribute__((swift_name("complete")));
@property (readonly) TKKTon_kotlin_apiTonNodeBlockIdExt *from __attribute__((swift_name("from")));
@property (readonly) NSArray<id<TKKTon_kotlin_liteapiLiteServerBlockLink>> *steps __attribute__((swift_name("steps")));
@property (readonly) TKKTon_kotlin_apiTonNodeBlockIdExt *to __attribute__((swift_name("to")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerGetConfigAll")))
@interface TKKTon_kotlin_liteapiLiteServerGetConfigAll : TKKBase <TKKTon_kotlin_tlTLFunction>
- (instancetype)initWithMode:(int32_t)mode id:(TKKTon_kotlin_apiTonNodeBlockIdExt *)id __attribute__((swift_name("init(mode:id:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapiLiteServerGetConfigAllCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapiLiteServerGetConfigAll *)doCopyMode:(int32_t)mode id:(TKKTon_kotlin_apiTonNodeBlockIdExt *)id __attribute__((swift_name("doCopy(mode:id:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (id<TKKTon_kotlin_tlTlCodec>)resultTlCodec __attribute__((swift_name("resultTlCodec()")));
- (id<TKKTon_kotlin_tlTlCodec>)tlCodec __attribute__((swift_name("tlCodec()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) TKKTon_kotlin_apiTonNodeBlockIdExt *id __attribute__((swift_name("id")));
@property (readonly) int32_t mode __attribute__((swift_name("mode")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerConfigInfo")))
@interface TKKTon_kotlin_liteapiLiteServerConfigInfo : TKKBase
- (instancetype)initWithMode:(int32_t)mode id:(TKKTon_kotlin_apiTonNodeBlockIdExt *)id stateProof:(TKKKotlinByteArray *)stateProof configProof:(TKKKotlinByteArray *)configProof __attribute__((swift_name("init(mode:id:stateProof:configProof:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapiLiteServerConfigInfoCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapiLiteServerConfigInfo *)doCopyMode:(int32_t)mode id:(TKKTon_kotlin_apiTonNodeBlockIdExt *)id stateProof:(TKKKotlinByteArray *)stateProof configProof:(TKKKotlinByteArray *)configProof __attribute__((swift_name("doCopy(mode:id:stateProof:configProof:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) TKKKotlinByteArray *configProof __attribute__((swift_name("configProof")));
@property (readonly) TKKTon_kotlin_apiTonNodeBlockIdExt *id __attribute__((swift_name("id")));
@property (readonly) int32_t mode __attribute__((swift_name("mode")));
@property (readonly) TKKKotlinByteArray *stateProof __attribute__((swift_name("stateProof")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerGetConfigParams")))
@interface TKKTon_kotlin_liteapiLiteServerGetConfigParams : TKKBase <TKKTon_kotlin_tlTLFunction>
- (instancetype)initWithMode:(int32_t)mode id:(TKKTon_kotlin_apiTonNodeBlockIdExt *)id paramList:(id)paramList __attribute__((swift_name("init(mode:id:paramList:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapiLiteServerGetConfigParamsCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapiLiteServerGetConfigParams *)doCopyMode:(int32_t)mode id:(TKKTon_kotlin_apiTonNodeBlockIdExt *)id paramList:(id)paramList __attribute__((swift_name("doCopy(mode:id:paramList:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (id<TKKTon_kotlin_tlTlCodec>)resultTlCodec __attribute__((swift_name("resultTlCodec()")));
- (id<TKKTon_kotlin_tlTlCodec>)tlCodec __attribute__((swift_name("tlCodec()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) TKKTon_kotlin_apiTonNodeBlockIdExt *id __attribute__((swift_name("id")));
@property (readonly) int32_t mode __attribute__((swift_name("mode")));
@property (readonly) id paramList __attribute__((swift_name("paramList")));
@end

__attribute__((swift_name("Ton_kotlin_tlTlDecoder")))
@protocol TKKTon_kotlin_tlTlDecoder
@required
- (id _Nullable)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (id _Nullable)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (id _Nullable)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (id _Nullable)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (id _Nullable)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
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
- (TKKKotlinByteArray *)hashValue:(id _Nullable)value __attribute__((swift_name("hash(value:)")));
@end

__attribute__((swift_name("Ton_kotlin_tlTlCodec")))
@protocol TKKTon_kotlin_tlTlCodec <TKKTon_kotlin_tlTlDecoder, TKKTon_kotlin_tlTlEncoder>
@required
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerGetMasterchainInfo")))
@interface TKKTon_kotlin_liteapiLiteServerGetMasterchainInfo : TKKBase <TKKTon_kotlin_tlTLFunction, TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)liteServerGetMasterchainInfo __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapiLiteServerGetMasterchainInfo *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapiLiteServerGetMasterchainInfo *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_liteapiLiteServerGetMasterchainInfo *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_liteapiLiteServerGetMasterchainInfo *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_liteapiLiteServerGetMasterchainInfo *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_liteapiLiteServerGetMasterchainInfo *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_liteapiLiteServerGetMasterchainInfo *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapiLiteServerGetMasterchainInfo *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerGetMasterchainInfo *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapiLiteServerGetMasterchainInfo *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerGetMasterchainInfo *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_liteapiLiteServerGetMasterchainInfo *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_liteapiLiteServerGetMasterchainInfo *)value __attribute__((swift_name("hash(value:)")));
- (id<TKKTon_kotlin_tlTlCodec>)resultTlCodec __attribute__((swift_name("resultTlCodec()")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializerTypeParamsSerializers:(TKKKotlinArray<id<TKKKotlinx_serialization_coreKSerializer>> *)typeParamsSerializers __attribute__((swift_name("serializer(typeParamsSerializers:)")));
- (id<TKKTon_kotlin_tlTlCodec>)tlCodec __attribute__((swift_name("tlCodec()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerMasterchainInfo")))
@interface TKKTon_kotlin_liteapiLiteServerMasterchainInfo : TKKBase
- (instancetype)initWithLast:(TKKTon_kotlin_apiTonNodeBlockIdExt *)last stateRootHash:(TKKKotlinByteArray *)stateRootHash init:(TKKTon_kotlin_apiTonNodeZeroStateIdExt *)init __attribute__((swift_name("init(last:stateRootHash:init:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapiLiteServerMasterchainInfoCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapiLiteServerMasterchainInfo *)doCopyLast:(TKKTon_kotlin_apiTonNodeBlockIdExt *)last stateRootHash:(TKKKotlinByteArray *)stateRootHash init:(TKKTon_kotlin_apiTonNodeZeroStateIdExt *)init __attribute__((swift_name("doCopy(last:stateRootHash:init:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly, getter=doInit) TKKTon_kotlin_apiTonNodeZeroStateIdExt *init __attribute__((swift_name("init")));
@property (readonly) TKKTon_kotlin_apiTonNodeBlockIdExt *last __attribute__((swift_name("last")));
@property (readonly) TKKKotlinByteArray *stateRootHash __attribute__((swift_name("stateRootHash")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerGetMasterchainInfoExt")))
@interface TKKTon_kotlin_liteapiLiteServerGetMasterchainInfoExt : TKKBase <TKKTon_kotlin_tlTLFunction>
- (instancetype)initWithMode:(int32_t)mode __attribute__((swift_name("init(mode:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapiLiteServerGetMasterchainInfoExtCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapiLiteServerGetMasterchainInfoExt *)doCopyMode:(int32_t)mode __attribute__((swift_name("doCopy(mode:)")));
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
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerMasterchainInfoExt")))
@interface TKKTon_kotlin_liteapiLiteServerMasterchainInfoExt : TKKBase
- (instancetype)initWithMode:(int32_t)mode version:(int32_t)version capabilities:(int64_t)capabilities last:(TKKTon_kotlin_apiTonNodeBlockIdExt *)last lastUtime:(int32_t)lastUtime now:(int32_t)now stateRootHash:(TKKKotlinByteArray *)stateRootHash init:(TKKTon_kotlin_apiTonNodeZeroStateIdExt *)init __attribute__((swift_name("init(mode:version:capabilities:last:lastUtime:now:stateRootHash:init:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapiLiteServerMasterchainInfoExtCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapiLiteServerMasterchainInfoExt *)doCopyMode:(int32_t)mode version:(int32_t)version capabilities:(int64_t)capabilities last:(TKKTon_kotlin_apiTonNodeBlockIdExt *)last lastUtime:(int32_t)lastUtime now:(int32_t)now stateRootHash:(TKKKotlinByteArray *)stateRootHash init:(TKKTon_kotlin_apiTonNodeZeroStateIdExt *)init __attribute__((swift_name("doCopy(mode:version:capabilities:last:lastUtime:now:stateRootHash:init:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) int64_t capabilities __attribute__((swift_name("capabilities")));
@property (readonly, getter=doInit) TKKTon_kotlin_apiTonNodeZeroStateIdExt *init __attribute__((swift_name("init")));
@property (readonly) TKKTon_kotlin_apiTonNodeBlockIdExt *last __attribute__((swift_name("last")));
@property (readonly) int32_t lastUtime __attribute__((swift_name("lastUtime")));
@property (readonly) int32_t mode __attribute__((swift_name("mode")));
@property (readonly) int32_t now __attribute__((swift_name("now")));
@property (readonly) TKKKotlinByteArray *stateRootHash __attribute__((swift_name("stateRootHash")));
@property (readonly) int32_t version __attribute__((swift_name("version")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerGetOneTransaction")))
@interface TKKTon_kotlin_liteapiLiteServerGetOneTransaction : TKKBase <TKKTon_kotlin_tlTLFunction>
- (instancetype)initWithId:(TKKTon_kotlin_apiTonNodeBlockIdExt *)id account:(TKKTon_kotlin_liteapiLiteServerAccountId *)account lt:(int64_t)lt __attribute__((swift_name("init(id:account:lt:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapiLiteServerGetOneTransactionCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapiLiteServerGetOneTransaction *)doCopyId:(TKKTon_kotlin_apiTonNodeBlockIdExt *)id account:(TKKTon_kotlin_liteapiLiteServerAccountId *)account lt:(int64_t)lt __attribute__((swift_name("doCopy(id:account:lt:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (id<TKKTon_kotlin_tlTlCodec>)resultTlCodec __attribute__((swift_name("resultTlCodec()")));
- (id<TKKTon_kotlin_tlTlCodec>)tlCodec __attribute__((swift_name("tlCodec()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) TKKTon_kotlin_liteapiLiteServerAccountId *account __attribute__((swift_name("account")));
@property (readonly) TKKTon_kotlin_apiTonNodeBlockIdExt *id __attribute__((swift_name("id")));
@property (readonly) int64_t lt __attribute__((swift_name("lt")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerTransactionInfo")))
@interface TKKTon_kotlin_liteapiLiteServerTransactionInfo : TKKBase
- (instancetype)initWithId:(TKKTon_kotlin_apiTonNodeBlockIdExt *)id proof:(TKKKotlinByteArray *)proof transaction:(TKKKotlinByteArray *)transaction __attribute__((swift_name("init(id:proof:transaction:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapiLiteServerTransactionInfoCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapiLiteServerTransactionInfo *)doCopyId:(TKKTon_kotlin_apiTonNodeBlockIdExt *)id proof:(TKKKotlinByteArray *)proof transaction:(TKKKotlinByteArray *)transaction __attribute__((swift_name("doCopy(id:proof:transaction:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) TKKTon_kotlin_apiTonNodeBlockIdExt *id __attribute__((swift_name("id")));
@property (readonly) TKKKotlinByteArray *proof __attribute__((swift_name("proof")));
@property (readonly) TKKKotlinByteArray *transaction __attribute__((swift_name("transaction")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerGetShardInfo")))
@interface TKKTon_kotlin_liteapiLiteServerGetShardInfo : TKKBase <TKKTon_kotlin_tlTLFunction>
- (instancetype)initWithId:(TKKTon_kotlin_apiTonNodeBlockIdExt *)id workchain:(int32_t)workchain shard:(int64_t)shard exact:(BOOL)exact __attribute__((swift_name("init(id:workchain:shard:exact:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapiLiteServerGetShardInfoCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapiLiteServerGetShardInfo *)doCopyId:(TKKTon_kotlin_apiTonNodeBlockIdExt *)id workchain:(int32_t)workchain shard:(int64_t)shard exact:(BOOL)exact __attribute__((swift_name("doCopy(id:workchain:shard:exact:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (id<TKKTon_kotlin_tlTlCodec>)resultTlCodec __attribute__((swift_name("resultTlCodec()")));
- (id<TKKTon_kotlin_tlTlCodec>)tlCodec __attribute__((swift_name("tlCodec()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) BOOL exact __attribute__((swift_name("exact")));
@property (readonly) TKKTon_kotlin_apiTonNodeBlockIdExt *id __attribute__((swift_name("id")));
@property (readonly) int64_t shard __attribute__((swift_name("shard")));
@property (readonly) int32_t workchain __attribute__((swift_name("workchain")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerShardInfo")))
@interface TKKTon_kotlin_liteapiLiteServerShardInfo : TKKBase
- (instancetype)initWithId:(TKKTon_kotlin_apiTonNodeBlockIdExt *)id shardBlock:(TKKTon_kotlin_apiTonNodeBlockIdExt *)shardBlock shardProof:(TKKKotlinByteArray *)shardProof shardDescr:(TKKKotlinByteArray *)shardDescr __attribute__((swift_name("init(id:shardBlock:shardProof:shardDescr:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapiLiteServerShardInfoCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapiLiteServerShardInfo *)doCopyId:(TKKTon_kotlin_apiTonNodeBlockIdExt *)id shardBlock:(TKKTon_kotlin_apiTonNodeBlockIdExt *)shardBlock shardProof:(TKKKotlinByteArray *)shardProof shardDescr:(TKKKotlinByteArray *)shardDescr __attribute__((swift_name("doCopy(id:shardBlock:shardProof:shardDescr:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) TKKTon_kotlin_apiTonNodeBlockIdExt *id __attribute__((swift_name("id")));
@property (readonly) TKKTon_kotlin_apiTonNodeBlockIdExt *shardBlock __attribute__((swift_name("shardBlock")));
@property (readonly) TKKKotlinByteArray *shardDescr __attribute__((swift_name("shardDescr")));
@property (readonly) TKKKotlinByteArray *shardProof __attribute__((swift_name("shardProof")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerGetState")))
@interface TKKTon_kotlin_liteapiLiteServerGetState : TKKBase <TKKTon_kotlin_tlTLFunction>
- (instancetype)initWithId:(TKKTon_kotlin_apiTonNodeBlockIdExt *)id __attribute__((swift_name("init(id:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapiLiteServerGetStateCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapiLiteServerGetState *)doCopyId:(TKKTon_kotlin_apiTonNodeBlockIdExt *)id __attribute__((swift_name("doCopy(id:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (id<TKKTon_kotlin_tlTlCodec>)resultTlCodec __attribute__((swift_name("resultTlCodec()")));
- (id<TKKTon_kotlin_tlTlCodec>)tlCodec __attribute__((swift_name("tlCodec()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) TKKTon_kotlin_apiTonNodeBlockIdExt *id __attribute__((swift_name("id")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerBlockState")))
@interface TKKTon_kotlin_liteapiLiteServerBlockState : TKKBase
- (instancetype)initWithId:(TKKTon_kotlin_apiTonNodeBlockIdExt *)id rootHash:(TKKKotlinByteArray *)rootHash fileHash:(TKKKotlinByteArray *)fileHash data:(TKKKotlinByteArray *)data __attribute__((swift_name("init(id:rootHash:fileHash:data:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapiLiteServerBlockStateCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapiLiteServerBlockState *)doCopyId:(TKKTon_kotlin_apiTonNodeBlockIdExt *)id rootHash:(TKKKotlinByteArray *)rootHash fileHash:(TKKKotlinByteArray *)fileHash data:(TKKKotlinByteArray *)data __attribute__((swift_name("doCopy(id:rootHash:fileHash:data:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) TKKKotlinByteArray *data __attribute__((swift_name("data")));
@property (readonly) TKKKotlinByteArray *fileHash __attribute__((swift_name("fileHash")));
@property (readonly) TKKTon_kotlin_apiTonNodeBlockIdExt *id __attribute__((swift_name("id")));
@property (readonly) TKKKotlinByteArray *rootHash __attribute__((swift_name("rootHash")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerGetTime")))
@interface TKKTon_kotlin_liteapiLiteServerGetTime : TKKBase <TKKTon_kotlin_tlTLFunction, TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)liteServerGetTime __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapiLiteServerGetTime *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapiLiteServerGetTime *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_liteapiLiteServerGetTime *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_liteapiLiteServerGetTime *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_liteapiLiteServerGetTime *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_liteapiLiteServerGetTime *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_liteapiLiteServerGetTime *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapiLiteServerGetTime *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerGetTime *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapiLiteServerGetTime *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerGetTime *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_liteapiLiteServerGetTime *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_liteapiLiteServerGetTime *)value __attribute__((swift_name("hash(value:)")));
- (id<TKKTon_kotlin_tlTlCodec>)resultTlCodec __attribute__((swift_name("resultTlCodec()")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializerTypeParamsSerializers:(TKKKotlinArray<id<TKKKotlinx_serialization_coreKSerializer>> *)typeParamsSerializers __attribute__((swift_name("serializer(typeParamsSerializers:)")));
- (id<TKKTon_kotlin_tlTlCodec>)tlCodec __attribute__((swift_name("tlCodec()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerCurrentTime")))
@interface TKKTon_kotlin_liteapiLiteServerCurrentTime : TKKBase
- (instancetype)initWithNow:(int32_t)now __attribute__((swift_name("init(now:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapiLiteServerCurrentTimeCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapiLiteServerCurrentTime *)doCopyNow:(int32_t)now __attribute__((swift_name("doCopy(now:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) int32_t now __attribute__((swift_name("now")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerGetTransactions")))
@interface TKKTon_kotlin_liteapiLiteServerGetTransactions : TKKBase <TKKTon_kotlin_tlTLFunction>
- (instancetype)initWithCount:(int32_t)count account:(TKKTon_kotlin_liteapiLiteServerAccountId *)account lt:(int64_t)lt hash:(TKKKotlinByteArray *)hash __attribute__((swift_name("init(count:account:lt:hash:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithCount:(int32_t)count account:(TKKTon_kotlin_liteapiLiteServerAccountId *)account lt:(int64_t)lt hash_:(TKKTon_kotlin_tlByteString *)hash __attribute__((swift_name("init(count:account:lt:hash_:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapiLiteServerGetTransactionsCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapiLiteServerGetTransactions *)doCopyCount:(int32_t)count account:(TKKTon_kotlin_liteapiLiteServerAccountId *)account lt:(int64_t)lt hash:(TKKTon_kotlin_tlByteString *)hash __attribute__((swift_name("doCopy(count:account:lt:hash:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (id<TKKTon_kotlin_tlTlCodec>)resultTlCodec __attribute__((swift_name("resultTlCodec()")));
- (id<TKKTon_kotlin_tlTlCodec>)tlCodec __attribute__((swift_name("tlCodec()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) TKKTon_kotlin_liteapiLiteServerAccountId *account __attribute__((swift_name("account")));
@property (readonly) int32_t count __attribute__((swift_name("count")));
@property (readonly, getter=hash_) TKKTon_kotlin_tlByteString *hash __attribute__((swift_name("hash")));
@property (readonly) int64_t lt __attribute__((swift_name("lt")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerTransactionList")))
@interface TKKTon_kotlin_liteapiLiteServerTransactionList : TKKBase
- (instancetype)initWithIds:(NSArray<TKKTon_kotlin_apiTonNodeBlockIdExt *> *)ids transactions:(NSString *)transactions __attribute__((swift_name("init(ids:transactions:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapiLiteServerTransactionListCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapiLiteServerTransactionList *)doCopyIds:(NSArray<TKKTon_kotlin_apiTonNodeBlockIdExt *> *)ids transactions:(NSString *)transactions __attribute__((swift_name("doCopy(ids:transactions:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSArray<TKKTon_kotlin_apiTonNodeBlockIdExt *> *ids __attribute__((swift_name("ids")));
@property (readonly) NSString *transactions __attribute__((swift_name("transactions")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerGetValidatorStats")))
@interface TKKTon_kotlin_liteapiLiteServerGetValidatorStats : TKKBase <TKKTon_kotlin_tlTLFunction>
- (instancetype)initWithMode:(int32_t)mode id:(TKKTon_kotlin_apiTonNodeBlockIdExt *)id limit:(int32_t)limit startAfter:(TKKKotlinByteArray * _Nullable)startAfter modifiedAfter:(TKKInt * _Nullable)modifiedAfter __attribute__((swift_name("init(mode:id:limit:startAfter:modifiedAfter:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapiLiteServerGetValidatorStatsCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapiLiteServerGetValidatorStats *)doCopyMode:(int32_t)mode id:(TKKTon_kotlin_apiTonNodeBlockIdExt *)id limit:(int32_t)limit startAfter:(TKKKotlinByteArray * _Nullable)startAfter modifiedAfter:(TKKInt * _Nullable)modifiedAfter __attribute__((swift_name("doCopy(mode:id:limit:startAfter:modifiedAfter:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (id<TKKTon_kotlin_tlTlCodec>)resultTlCodec __attribute__((swift_name("resultTlCodec()")));
- (id<TKKTon_kotlin_tlTlCodec>)tlCodec __attribute__((swift_name("tlCodec()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) TKKTon_kotlin_apiTonNodeBlockIdExt *id __attribute__((swift_name("id")));
@property (readonly) int32_t limit __attribute__((swift_name("limit")));
@property (readonly) int32_t mode __attribute__((swift_name("mode")));
@property (readonly) TKKInt * _Nullable modifiedAfter __attribute__((swift_name("modifiedAfter")));
@property (readonly) TKKKotlinByteArray * _Nullable startAfter __attribute__((swift_name("startAfter")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerValidatorStats")))
@interface TKKTon_kotlin_liteapiLiteServerValidatorStats : TKKBase
- (instancetype)initWithMode:(int32_t)mode id:(TKKTon_kotlin_apiTonNodeBlockIdExt *)id count:(int32_t)count complete:(BOOL)complete stateProof:(TKKKotlinByteArray *)stateProof dataProof:(TKKKotlinByteArray *)dataProof __attribute__((swift_name("init(mode:id:count:complete:stateProof:dataProof:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapiLiteServerValidatorStatsCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapiLiteServerValidatorStats *)doCopyMode:(int32_t)mode id:(TKKTon_kotlin_apiTonNodeBlockIdExt *)id count:(int32_t)count complete:(BOOL)complete stateProof:(TKKKotlinByteArray *)stateProof dataProof:(TKKKotlinByteArray *)dataProof __attribute__((swift_name("doCopy(mode:id:count:complete:stateProof:dataProof:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) BOOL complete __attribute__((swift_name("complete")));
@property (readonly) int32_t count __attribute__((swift_name("count")));
@property (readonly) TKKKotlinByteArray *dataProof __attribute__((swift_name("dataProof")));
@property (readonly) TKKTon_kotlin_apiTonNodeBlockIdExt *id __attribute__((swift_name("id")));
@property (readonly) int32_t mode __attribute__((swift_name("mode")));
@property (readonly) TKKKotlinByteArray *stateProof __attribute__((swift_name("stateProof")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerGetVersion")))
@interface TKKTon_kotlin_liteapiLiteServerGetVersion : TKKBase <TKKTon_kotlin_tlTLFunction, TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)liteServerGetVersion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapiLiteServerGetVersion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapiLiteServerGetVersion *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_liteapiLiteServerGetVersion *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_liteapiLiteServerGetVersion *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_liteapiLiteServerGetVersion *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_liteapiLiteServerGetVersion *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_liteapiLiteServerGetVersion *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapiLiteServerGetVersion *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerGetVersion *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapiLiteServerGetVersion *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerGetVersion *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_liteapiLiteServerGetVersion *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_liteapiLiteServerGetVersion *)value __attribute__((swift_name("hash(value:)")));
- (id<TKKTon_kotlin_tlTlCodec>)resultTlCodec __attribute__((swift_name("resultTlCodec()")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializerTypeParamsSerializers:(TKKKotlinArray<id<TKKKotlinx_serialization_coreKSerializer>> *)typeParamsSerializers __attribute__((swift_name("serializer(typeParamsSerializers:)")));
- (id<TKKTon_kotlin_tlTlCodec>)tlCodec __attribute__((swift_name("tlCodec()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerVersion")))
@interface TKKTon_kotlin_liteapiLiteServerVersion : TKKBase
- (instancetype)initWithMode:(int32_t)mode version:(int32_t)version capabilities:(int64_t)capabilities now:(int32_t)now __attribute__((swift_name("init(mode:version:capabilities:now:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapiLiteServerVersionCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapiLiteServerVersion *)doCopyMode:(int32_t)mode version:(int32_t)version capabilities:(int64_t)capabilities now:(int32_t)now __attribute__((swift_name("doCopy(mode:version:capabilities:now:)")));
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
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerListBlockTransactions")))
@interface TKKTon_kotlin_liteapiLiteServerListBlockTransactions : TKKBase <TKKTon_kotlin_tlTLFunction>
- (instancetype)initWithId:(TKKTon_kotlin_apiTonNodeBlockIdExt *)id mode:(int32_t)mode count:(int32_t)count after:(TKKTon_kotlin_liteapiLiteServerTransactionId3 * _Nullable)after reverseOrder:(BOOL)reverseOrder wantProof:(BOOL)wantProof __attribute__((swift_name("init(id:mode:count:after:reverseOrder:wantProof:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapiLiteServerListBlockTransactionsCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapiLiteServerListBlockTransactions *)doCopyId:(TKKTon_kotlin_apiTonNodeBlockIdExt *)id mode:(int32_t)mode count:(int32_t)count after:(TKKTon_kotlin_liteapiLiteServerTransactionId3 * _Nullable)after reverseOrder:(BOOL)reverseOrder wantProof:(BOOL)wantProof __attribute__((swift_name("doCopy(id:mode:count:after:reverseOrder:wantProof:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (id<TKKTon_kotlin_tlTlCodec>)resultTlCodec __attribute__((swift_name("resultTlCodec()")));
- (id<TKKTon_kotlin_tlTlCodec>)tlCodec __attribute__((swift_name("tlCodec()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) TKKTon_kotlin_liteapiLiteServerTransactionId3 * _Nullable after __attribute__((swift_name("after")));
@property (readonly) int32_t count __attribute__((swift_name("count")));
@property (readonly) TKKTon_kotlin_apiTonNodeBlockIdExt *id __attribute__((swift_name("id")));
@property (readonly) int32_t mode __attribute__((swift_name("mode")));
@property (readonly) BOOL reverseOrder __attribute__((swift_name("reverseOrder")));
@property (readonly) BOOL wantProof __attribute__((swift_name("wantProof")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerBlockTransactions")))
@interface TKKTon_kotlin_liteapiLiteServerBlockTransactions : TKKBase
- (instancetype)initWithId:(TKKTon_kotlin_apiTonNodeBlockIdExt *)id reqCount:(int32_t)reqCount incomplete:(BOOL)incomplete ids:(NSArray<TKKTon_kotlin_liteapiLiteServerTransactionId *> *)ids proof:(TKKKotlinByteArray *)proof __attribute__((swift_name("init(id:reqCount:incomplete:ids:proof:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapiLiteServerBlockTransactionsCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapiLiteServerBlockTransactions *)doCopyId:(TKKTon_kotlin_apiTonNodeBlockIdExt *)id reqCount:(int32_t)reqCount incomplete:(BOOL)incomplete ids:(NSArray<TKKTon_kotlin_liteapiLiteServerTransactionId *> *)ids proof:(TKKKotlinByteArray *)proof __attribute__((swift_name("doCopy(id:reqCount:incomplete:ids:proof:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) TKKTon_kotlin_apiTonNodeBlockIdExt *id __attribute__((swift_name("id")));
@property (readonly) NSArray<TKKTon_kotlin_liteapiLiteServerTransactionId *> *ids __attribute__((swift_name("ids")));
@property (readonly) BOOL incomplete __attribute__((swift_name("incomplete")));
@property (readonly) TKKKotlinByteArray *proof __attribute__((swift_name("proof")));
@property (readonly) int32_t reqCount __attribute__((swift_name("reqCount")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerLookupBlock")))
@interface TKKTon_kotlin_liteapiLiteServerLookupBlock : TKKBase <TKKTon_kotlin_tlTLFunction>
- (instancetype)initWithMode:(int32_t)mode id:(id<TKKTon_kotlin_apiTonNodeBlockId>)id lt:(TKKLong * _Nullable)lt utime:(TKKInt * _Nullable)utime __attribute__((swift_name("init(mode:id:lt:utime:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapiLiteServerLookupBlockCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapiLiteServerLookupBlock *)doCopyMode:(int32_t)mode id:(id<TKKTon_kotlin_apiTonNodeBlockId>)id lt:(TKKLong * _Nullable)lt utime:(TKKInt * _Nullable)utime __attribute__((swift_name("doCopy(mode:id:lt:utime:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (id<TKKTon_kotlin_tlTlCodec>)resultTlCodec __attribute__((swift_name("resultTlCodec()")));
- (id<TKKTon_kotlin_tlTlCodec>)tlCodec __attribute__((swift_name("tlCodec()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) id<TKKTon_kotlin_apiTonNodeBlockId> id __attribute__((swift_name("id")));
@property (readonly) TKKLong * _Nullable lt __attribute__((swift_name("lt")));
@property (readonly) int32_t mode __attribute__((swift_name("mode")));
@property (readonly) TKKInt * _Nullable utime __attribute__((swift_name("utime")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerRunSmcMethod")))
@interface TKKTon_kotlin_liteapiLiteServerRunSmcMethod : TKKBase <TKKTon_kotlin_tlTLFunction>
- (instancetype)initWithMode:(int32_t)mode id:(TKKTon_kotlin_apiTonNodeBlockIdExt *)id account:(TKKTon_kotlin_liteapiLiteServerAccountId *)account methodId:(int64_t)methodId params:(TKKKotlinByteArray *)params __attribute__((swift_name("init(mode:id:account:methodId:params:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapiLiteServerRunSmcMethodCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapiLiteServerRunSmcMethod *)doCopyMode:(int32_t)mode id:(TKKTon_kotlin_apiTonNodeBlockIdExt *)id account:(TKKTon_kotlin_liteapiLiteServerAccountId *)account methodId:(int64_t)methodId params:(TKKKotlinByteArray *)params __attribute__((swift_name("doCopy(mode:id:account:methodId:params:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (id<TKKTon_kotlin_tlTlCodec>)resultTlCodec __attribute__((swift_name("resultTlCodec()")));
- (id<TKKTon_kotlin_tlTlCodec>)tlCodec __attribute__((swift_name("tlCodec()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) TKKTon_kotlin_liteapiLiteServerAccountId *account __attribute__((swift_name("account")));
@property (readonly) TKKTon_kotlin_apiTonNodeBlockIdExt *id __attribute__((swift_name("id")));
@property (readonly) int64_t methodId __attribute__((swift_name("methodId")));
@property (readonly) int32_t mode __attribute__((swift_name("mode")));
@property (readonly) TKKKotlinByteArray *params __attribute__((swift_name("params")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerRunMethodResult")))
@interface TKKTon_kotlin_liteapiLiteServerRunMethodResult : TKKBase
- (instancetype)initWithId:(TKKTon_kotlin_apiTonNodeBlockIdExt *)id shardBlock:(TKKTon_kotlin_apiTonNodeBlockIdExt *)shardBlock shardProof:(TKKKotlinByteArray * _Nullable)shardProof proof:(TKKKotlinByteArray * _Nullable)proof stateProof:(TKKKotlinByteArray * _Nullable)stateProof initC7:(TKKKotlinByteArray * _Nullable)initC7 libExtras:(TKKKotlinByteArray * _Nullable)libExtras exitCode:(int32_t)exitCode result:(TKKKotlinByteArray * _Nullable)result __attribute__((swift_name("init(id:shardBlock:shardProof:proof:stateProof:initC7:libExtras:exitCode:result:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapiLiteServerRunMethodResultCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapiLiteServerRunMethodResult *)doCopyMode:(int32_t)mode id:(TKKTon_kotlin_apiTonNodeBlockIdExt *)id shardBlock:(TKKTon_kotlin_apiTonNodeBlockIdExt *)shardBlock shardProof:(TKKKotlinByteArray * _Nullable)shardProof proof:(TKKKotlinByteArray * _Nullable)proof stateProof:(TKKKotlinByteArray * _Nullable)stateProof initC7:(TKKKotlinByteArray * _Nullable)initC7 libExtras:(TKKKotlinByteArray * _Nullable)libExtras exitCode:(int32_t)exitCode result:(TKKKotlinByteArray * _Nullable)result __attribute__((swift_name("doCopy(mode:id:shardBlock:shardProof:proof:stateProof:initC7:libExtras:exitCode:result:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) int32_t exitCode __attribute__((swift_name("exitCode")));
@property (readonly) TKKTon_kotlin_apiTonNodeBlockIdExt *id __attribute__((swift_name("id")));
@property (readonly, getter=doInitC7) TKKKotlinByteArray * _Nullable initC7 __attribute__((swift_name("initC7")));
@property (readonly) TKKKotlinByteArray * _Nullable libExtras __attribute__((swift_name("libExtras")));
@property (readonly) int32_t mode __attribute__((swift_name("mode")));
@property (readonly) TKKKotlinByteArray * _Nullable proof __attribute__((swift_name("proof")));
@property (readonly) TKKKotlinByteArray * _Nullable result __attribute__((swift_name("result")));
@property (readonly) TKKTon_kotlin_apiTonNodeBlockIdExt *shardBlock __attribute__((swift_name("shardBlock")));
@property (readonly) TKKKotlinByteArray * _Nullable shardProof __attribute__((swift_name("shardProof")));
@property (readonly) TKKKotlinByteArray * _Nullable stateProof __attribute__((swift_name("stateProof")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerSendMessage")))
@interface TKKTon_kotlin_liteapiLiteServerSendMessage : TKKBase <TKKTon_kotlin_tlTLFunction>
- (instancetype)initWithBody:(TKKKotlinByteArray *)body __attribute__((swift_name("init(body:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapiLiteServerSendMessageCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapiLiteServerSendMessage *)doCopyBody:(TKKKotlinByteArray *)body __attribute__((swift_name("doCopy(body:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (id<TKKTon_kotlin_tlTlCodec>)resultTlCodec __attribute__((swift_name("resultTlCodec()")));
- (id<TKKTon_kotlin_tlTlCodec>)tlCodec __attribute__((swift_name("tlCodec()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) TKKKotlinByteArray *body __attribute__((swift_name("body")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerSendMsgStatus")))
@interface TKKTon_kotlin_liteapiLiteServerSendMsgStatus : TKKBase
- (instancetype)initWithStatus:(int32_t)status __attribute__((swift_name("init(status:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapiLiteServerSendMsgStatusCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapiLiteServerSendMsgStatus *)doCopyStatus:(int32_t)status __attribute__((swift_name("doCopy(status:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) int32_t status __attribute__((swift_name("status")));
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
__attribute__((swift_name("Ton_kotlin_apiPublicKey")))
@protocol TKKTon_kotlin_apiPublicKey <TKKTon_kotlin_cryptoEncryptor, TKKTon_kotlin_tlTlObject>
@required
- (id<TKKTon_kotlin_apiAdnlIdShort>)toAdnlIdShort __attribute__((swift_name("toAdnlIdShort()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_apiPublicKeyEd25519")))
@interface TKKTon_kotlin_apiPublicKeyEd25519 : TKKBase <TKKTon_kotlin_apiPublicKey, TKKTon_kotlin_cryptoEncryptor>
- (instancetype)initWithKey:(TKKKotlinByteArray *)key __attribute__((swift_name("init(key:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithKey_:(TKKTon_kotlin_tlByteString *)key __attribute__((swift_name("init(key_:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_apiPublicKeyEd25519Companion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_apiPublicKeyEd25519 *)doCopyKey:(TKKTon_kotlin_tlByteString *)key __attribute__((swift_name("doCopy(key:)")));
- (TKKKotlinByteArray *)encryptData:(TKKKotlinByteArray *)data __attribute__((swift_name("encrypt(data:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (id<TKKTon_kotlin_apiAdnlIdShort>)toAdnlIdShort __attribute__((swift_name("toAdnlIdShort()")));
- (NSString *)description __attribute__((swift_name("description()")));
- (BOOL)verifyMessage:(TKKKotlinByteArray *)message signature:(TKKKotlinByteArray * _Nullable)signature __attribute__((swift_name("verify(message:signature:)")));
@property (readonly) TKKTon_kotlin_tlByteString *key __attribute__((swift_name("key")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable(with=NormalClass(value=org/ton/tl/ByteStringSerializer))
*/
__attribute__((swift_name("Ton_kotlin_tlByteString")))
@interface TKKTon_kotlin_tlByteString : TKKBase <TKKKotlinComparable>
@property (class, readonly, getter=companion) TKKTon_kotlin_tlByteStringCompanion *companion __attribute__((swift_name("companion")));
- (int32_t)compareToOther:(TKKTon_kotlin_tlByteString *)other __attribute__((swift_name("compareTo(other:)")));
- (NSString *)decodeToString __attribute__((swift_name("decodeToString()")));
- (NSString *)encodeHex __attribute__((swift_name("encodeHex()")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));

/**
 * @note annotations
 *   kotlin.jvm.JvmName(name="getByte")
*/
- (int8_t)getIndex_:(int32_t)index __attribute__((swift_name("get(index_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (TKKKotlinByteArray *)toByteArray __attribute__((swift_name("toByteArray()")));
- (TKKKotlinByteArray *)toByteArrayDestination:(TKKKotlinByteArray *)destination destinationOffset:(int32_t)destinationOffset startIndex:(int32_t)startIndex endIndex:(int32_t)endIndex __attribute__((swift_name("toByteArray(destination:destinationOffset:startIndex:endIndex:)")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) int32_t size __attribute__((swift_name("size")));
@end

__attribute__((swift_name("Ton_kotlin_apiAdnlIdShort")))
@protocol TKKTon_kotlin_apiAdnlIdShort <TKKKotlinComparable, TKKTon_kotlin_tlTlObject>
@required
- (BOOL)verifyNode:(TKKTon_kotlin_apiOverlayNode *)node __attribute__((swift_name("verify(node:)")));
@property (readonly) TKKKotlinByteArray *id __attribute__((swift_name("id")));
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

__attribute__((swift_name("KotlinCharSequence")))
@protocol TKKKotlinCharSequence
@required
- (unichar)getIndex__:(int32_t)index __attribute__((swift_name("get(index__:)")));
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
- (unichar)getIndex__:(int32_t)index __attribute__((swift_name("get(index__:)")));

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
__attribute__((swift_name("Ton_kotlin_blockAnycast.Companion")))
@interface TKKTon_kotlin_blockAnycastCompanion : TKKBase <TKKTon_kotlin_tlbTlbConstructorProvider>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_blockAnycastCompanion *shared __attribute__((swift_name("shared")));
- (id<TKKTon_kotlin_cellCell>)createCellValue:(TKKTon_kotlin_blockAnycast *)value __attribute__((swift_name("createCell(value:)")));
- (TKKTon_kotlin_blockAnycast *)loadTlbCell:(id<TKKTon_kotlin_cellCell>)cell __attribute__((swift_name("loadTlb(cell:)")));
- (TKKTon_kotlin_blockAnycast *)loadTlbCellSlice:(id<TKKTon_kotlin_cellCellSlice>)cellSlice __attribute__((swift_name("loadTlb(cellSlice:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
- (void)storeTlbCellBuilder:(id<TKKTon_kotlin_cellCellBuilder>)cellBuilder value:(TKKTon_kotlin_blockAnycast *)value __attribute__((swift_name("storeTlb(cellBuilder:value:)")));
- (TKKTon_kotlin_tlbTlbConstructor<TKKTon_kotlin_blockAnycast *> *)tlbConstructor __attribute__((swift_name("tlbConstructor()")));
@end

__attribute__((swift_name("Ton_kotlin_cellCell")))
@protocol TKKTon_kotlin_cellCell
@required
- (id<TKKTon_kotlin_cellCellSlice>)beginParse __attribute__((swift_name("beginParse()")));
- (int32_t)depthLevel:(int32_t)level __attribute__((swift_name("depth(level:)")));
- (id<TKKTon_kotlin_bitstringBitString>)hashLevel:(int32_t)level __attribute__((swift_name("hash(level:)")));
- (BOOL)isEmpty __attribute__((swift_name("isEmpty()")));
- (id _Nullable)parseBlock:(id _Nullable (^)(id<TKKTon_kotlin_cellCellSlice>))block __attribute__((swift_name("parse(block:)")));
- (id<TKKKotlinSequence>)treeWalk __attribute__((swift_name("treeWalk()")));
- (id<TKKTon_kotlin_cellCell>)virtualizeOffset:(int32_t)offset __attribute__((swift_name("virtualize(offset:)")));
@property (readonly) id<TKKTon_kotlin_bitstringBitString> bits __attribute__((swift_name("bits")));
@property (readonly) id<TKKTon_kotlin_cellCellDescriptor> descriptor __attribute__((swift_name("descriptor")));
@property (readonly) int32_t levelMask __attribute__((swift_name("levelMask")));
@property (readonly) NSArray<id<TKKTon_kotlin_cellCell>> *refs __attribute__((swift_name("refs")));
@property (readonly) TKKTon_kotlin_cellCellType *type __attribute__((swift_name("type")));
@end

__attribute__((swift_name("Ton_kotlin_cellCellBuilder")))
@protocol TKKTon_kotlin_cellCellBuilder
@required
- (id<TKKTon_kotlin_cellCell>)build __attribute__((swift_name("build()")));
- (id<TKKTon_kotlin_cellCell>)endCell __attribute__((swift_name("endCell()")));
- (id<TKKTon_kotlin_cellCellBuilder>)storeBitBit:(BOOL)bit __attribute__((swift_name("storeBit(bit:)")));
- (id<TKKTon_kotlin_cellCellBuilder>)storeBitsBits:(TKKKotlinBooleanArray *)bits __attribute__((swift_name("storeBits(bits:)")));
- (id<TKKTon_kotlin_cellCellBuilder>)storeBitsBits_:(id)bits __attribute__((swift_name("storeBits(bits_:)")));
- (id<TKKTon_kotlin_cellCellBuilder>)storeBitsBits__:(id)bits __attribute__((swift_name("storeBits(bits__:)")));
- (id<TKKTon_kotlin_cellCellBuilder>)storeBitsBits___:(id<TKKTon_kotlin_bitstringBitString>)bits __attribute__((swift_name("storeBits(bits___:)")));
- (id<TKKTon_kotlin_cellCellBuilder>)storeByteByte:(int8_t)byte __attribute__((swift_name("storeByte(byte:)")));
- (id<TKKTon_kotlin_cellCellBuilder>)storeBytesByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("storeBytes(byteArray:)")));
- (id<TKKTon_kotlin_cellCellBuilder>)storeBytesByteArray:(TKKKotlinByteArray *)byteArray length:(int32_t)length __attribute__((swift_name("storeBytes(byteArray:length:)")));
- (id<TKKTon_kotlin_cellCellBuilder>)storeIntValue:(int8_t)value length:(int32_t)length __attribute__((swift_name("storeInt(value:length:)")));
- (id<TKKTon_kotlin_cellCellBuilder>)storeIntValue:(int32_t)value length_:(int32_t)length __attribute__((swift_name("storeInt(value:length_:)")));
- (id<TKKTon_kotlin_cellCellBuilder>)storeIntValue:(int64_t)value length__:(int32_t)length __attribute__((swift_name("storeInt(value:length__:)")));
- (id<TKKTon_kotlin_cellCellBuilder>)storeIntValue:(int16_t)value length___:(int32_t)length __attribute__((swift_name("storeInt(value:length___:)")));
- (id<TKKTon_kotlin_cellCellBuilder>)storeIntValue:(TKKTon_kotlin_bigintBigInt *)value length____:(int32_t)length __attribute__((swift_name("storeInt(value:length____:)")));
- (id<TKKTon_kotlin_cellCellBuilder>)storeRefRef:(id<TKKTon_kotlin_cellCell>)ref __attribute__((swift_name("storeRef(ref:)")));
- (id<TKKTon_kotlin_cellCellBuilder>)storeRefsRefs:(TKKKotlinArray<id<TKKTon_kotlin_cellCell>> *)refs __attribute__((swift_name("storeRefs(refs:)")));
- (id<TKKTon_kotlin_cellCellBuilder>)storeRefsRefs_:(id)refs __attribute__((swift_name("storeRefs(refs_:)")));
- (id<TKKTon_kotlin_cellCellBuilder>)storeRefsRefs__:(id)refs __attribute__((swift_name("storeRefs(refs__:)")));
- (id<TKKTon_kotlin_cellCellBuilder>)storeSliceSlice:(id<TKKTon_kotlin_cellCellSlice>)slice __attribute__((swift_name("storeSlice(slice:)")));
- (id<TKKTon_kotlin_cellCellBuilder>)storeUIntValue:(int8_t)value length:(int32_t)length __attribute__((swift_name("storeUInt(value:length:)")));
- (id<TKKTon_kotlin_cellCellBuilder>)storeUIntValue:(int32_t)value length_:(int32_t)length __attribute__((swift_name("storeUInt(value:length_:)")));
- (id<TKKTon_kotlin_cellCellBuilder>)storeUIntValue:(int64_t)value length__:(int32_t)length __attribute__((swift_name("storeUInt(value:length__:)")));
- (id<TKKTon_kotlin_cellCellBuilder>)storeUIntValue:(int16_t)value length___:(int32_t)length __attribute__((swift_name("storeUInt(value:length___:)")));
- (id<TKKTon_kotlin_cellCellBuilder>)storeUIntValue:(TKKTon_kotlin_bigintBigInt *)value length____:(int32_t)length __attribute__((swift_name("storeUInt(value:length____:)")));
- (id<TKKTon_kotlin_cellCellBuilder>)storeUInt16Value:(uint16_t)value __attribute__((swift_name("storeUInt16(value:)")));
- (id<TKKTon_kotlin_cellCellBuilder>)storeUInt32Value:(uint32_t)value __attribute__((swift_name("storeUInt32(value:)")));
- (id<TKKTon_kotlin_cellCellBuilder>)storeUInt64Value:(uint64_t)value __attribute__((swift_name("storeUInt64(value:)")));
- (id<TKKTon_kotlin_cellCellBuilder>)storeUInt8Value:(uint8_t)value __attribute__((swift_name("storeUInt8(value:)")));
- (id<TKKTon_kotlin_cellCellBuilder>)storeUIntLeqValue:(int8_t)value max:(int8_t)max __attribute__((swift_name("storeUIntLeq(value:max:)")));
- (id<TKKTon_kotlin_cellCellBuilder>)storeUIntLeqValue:(int32_t)value max_:(int32_t)max __attribute__((swift_name("storeUIntLeq(value:max_:)")));
- (id<TKKTon_kotlin_cellCellBuilder>)storeUIntLeqValue:(int64_t)value max__:(int64_t)max __attribute__((swift_name("storeUIntLeq(value:max__:)")));
- (id<TKKTon_kotlin_cellCellBuilder>)storeUIntLeqValue:(int16_t)value max___:(int16_t)max __attribute__((swift_name("storeUIntLeq(value:max___:)")));
- (id<TKKTon_kotlin_cellCellBuilder>)storeUIntLeqValue:(TKKTon_kotlin_bigintBigInt *)value max____:(TKKTon_kotlin_bigintBigInt *)max __attribute__((swift_name("storeUIntLeq(value:max____:)")));
- (id<TKKTon_kotlin_cellCellBuilder>)storeUIntLesValue:(int8_t)value max:(int8_t)max __attribute__((swift_name("storeUIntLes(value:max:)")));
- (id<TKKTon_kotlin_cellCellBuilder>)storeUIntLesValue:(int32_t)value max_:(int32_t)max __attribute__((swift_name("storeUIntLes(value:max_:)")));
- (id<TKKTon_kotlin_cellCellBuilder>)storeUIntLesValue:(int64_t)value max__:(int64_t)max __attribute__((swift_name("storeUIntLes(value:max__:)")));
- (id<TKKTon_kotlin_cellCellBuilder>)storeUIntLesValue:(int16_t)value max___:(int16_t)max __attribute__((swift_name("storeUIntLes(value:max___:)")));
- (id<TKKTon_kotlin_cellCellBuilder>)storeUIntLesValue:(TKKTon_kotlin_bigintBigInt *)value max____:(TKKTon_kotlin_bigintBigInt *)max __attribute__((swift_name("storeUIntLes(value:max____:)")));
@property id<TKKTon_kotlin_bitstringMutableBitString> bits __attribute__((swift_name("bits")));
@property (readonly) int32_t bitsPosition __attribute__((swift_name("bitsPosition")));
@property BOOL isExotic __attribute__((swift_name("isExotic")));
@property (setter=setLevelMask:) id _Nullable levelMask_ __attribute__((swift_name("levelMask_")));
@property NSMutableArray<id<TKKTon_kotlin_cellCell>> *refs __attribute__((swift_name("refs")));
@end

__attribute__((swift_name("Ton_kotlin_cellCellSlice")))
@protocol TKKTon_kotlin_cellCellSlice
@required
- (id<TKKTon_kotlin_bitstringBitString>)component1_ __attribute__((swift_name("component1_()")));
- (NSArray<id<TKKTon_kotlin_cellCell>> *)component2_ __attribute__((swift_name("component2_()")));
- (void)endParse __attribute__((swift_name("endParse()")));
- (BOOL)isEmpty __attribute__((swift_name("isEmpty()")));
- (BOOL)loadBit __attribute__((swift_name("loadBit()")));
- (id<TKKTon_kotlin_bitstringBitString>)loadBitsLength:(int32_t)length __attribute__((swift_name("loadBits(length:)")));
- (TKKTon_kotlin_bigintBigInt *)loadIntLength:(int32_t)length __attribute__((swift_name("loadInt(length:)")));
- (id<TKKTon_kotlin_cellCell>)loadRef __attribute__((swift_name("loadRef()")));
- (NSArray<id<TKKTon_kotlin_cellCell>> *)loadRefsCount:(int32_t)count __attribute__((swift_name("loadRefs(count:)")));
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
- (id<TKKTon_kotlin_cellCell>)preloadRef __attribute__((swift_name("preloadRef()")));
- (id _Nullable)preloadRefCellSlice:(id _Nullable (^)(id<TKKTon_kotlin_cellCellSlice>))cellSlice __attribute__((swift_name("preloadRef(cellSlice:)")));
- (NSArray<id<TKKTon_kotlin_cellCell>> *)preloadRefsCount:(int32_t)count __attribute__((swift_name("preloadRefs(count:)")));
- (int64_t)preloadTinyIntLength:(int32_t)length __attribute__((swift_name("preloadTinyInt(length:)")));
- (TKKTon_kotlin_bigintBigInt *)preloadUIntLength:(int32_t)length __attribute__((swift_name("preloadUInt(length:)")));
- (TKKTon_kotlin_bigintBigInt *)preloadUIntLeqMax:(int32_t)max __attribute__((swift_name("preloadUIntLeq(max:)")));
- (TKKTon_kotlin_bigintBigInt *)preloadUIntLesMax:(int32_t)max __attribute__((swift_name("preloadUIntLes(max:)")));
- (id<TKKTon_kotlin_cellCellSlice>)skipBitsLength:(int32_t)length __attribute__((swift_name("skipBits(length:)")));
@property (readonly) id<TKKTon_kotlin_bitstringBitString> bits __attribute__((swift_name("bits")));
@property int32_t bitsPosition __attribute__((swift_name("bitsPosition")));
@property (readonly) NSArray<id<TKKTon_kotlin_cellCell>> *refs __attribute__((swift_name("refs")));
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
__attribute__((swift_name("Ton_kotlin_apiTonNodeBlockIdExt.Companion")))
@interface TKKTon_kotlin_apiTonNodeBlockIdExtCompanion : TKKBase <TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_apiTonNodeBlockIdExtCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_apiTonNodeBlockIdExt *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_apiTonNodeBlockIdExt *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_apiTonNodeBlockIdExt *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_apiTonNodeBlockIdExt *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_apiTonNodeBlockIdExt *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_apiTonNodeBlockIdExt *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_apiTonNodeBlockIdExt *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_apiTonNodeBlockIdExt *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_apiTonNodeBlockIdExt *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_apiTonNodeBlockIdExt *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_apiTonNodeBlockIdExt *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_apiTonNodeBlockIdExt *)value __attribute__((swift_name("hash(value:)")));

/**
 * @note annotations
 *   kotlin.jvm.JvmStatic
*/
- (TKKTon_kotlin_apiTonNodeBlockIdExt *)parseString:(NSString *)string __attribute__((swift_name("parse(string:)")));

/**
 * @note annotations
 *   kotlin.jvm.JvmStatic
*/
- (TKKTon_kotlin_apiTonNodeBlockIdExt * _Nullable)parseOrNullString:(NSString *)string __attribute__((swift_name("parseOrNull(string:)")));
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


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerAccountId")))
@interface TKKTon_kotlin_liteapiLiteServerAccountId : TKKBase
- (instancetype)initWithWorkchain:(int32_t)workchain id:(TKKKotlinByteArray *)id __attribute__((swift_name("init(workchain:id:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithWorkchain:(int32_t)workchain id_:(id<TKKTon_kotlin_bitstringBitString>)id __attribute__((swift_name("init(workchain:id_:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithWorkchain:(int32_t)workchain id__:(TKKTon_kotlin_tlByteString *)id __attribute__((swift_name("init(workchain:id__:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapiLiteServerAccountIdCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapiLiteServerAccountId *)doCopyWorkchain:(int32_t)workchain id:(TKKTon_kotlin_tlByteString *)id __attribute__((swift_name("doCopy(workchain:id:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) TKKTon_kotlin_tlByteString *id __attribute__((swift_name("id")));
@property (readonly) int32_t workchain __attribute__((swift_name("workchain")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerGetAccountState.Companion")))
@interface TKKTon_kotlin_liteapiLiteServerGetAccountStateCompanion : TKKBase <TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapiLiteServerGetAccountStateCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapiLiteServerGetAccountState *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_liteapiLiteServerGetAccountState *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_liteapiLiteServerGetAccountState *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_liteapiLiteServerGetAccountState *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_liteapiLiteServerGetAccountState *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_liteapiLiteServerGetAccountState *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapiLiteServerGetAccountState *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerGetAccountState *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapiLiteServerGetAccountState *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerGetAccountState *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_liteapiLiteServerGetAccountState *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_liteapiLiteServerGetAccountState *)value __attribute__((swift_name("hash(value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((swift_name("Ton_kotlin_tlTlConstructor")))
@interface TKKTon_kotlin_tlTlConstructor<T> : TKKBase <TKKTon_kotlin_tlTlCodec>
- (instancetype)initWithSchema:(NSString *)schema id:(TKKInt * _Nullable)id __attribute__((swift_name("init(schema:id:)"))) __attribute__((objc_designated_initializer));
- (T)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(T)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) int32_t id_ __attribute__((swift_name("id_")));
@property (readonly) NSString *schema __attribute__((swift_name("schema")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerAccountState.Companion")))
@interface TKKTon_kotlin_liteapiLiteServerAccountStateCompanion : TKKTon_kotlin_tlTlConstructor<TKKTon_kotlin_liteapiLiteServerAccountState *>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (instancetype)initWithSchema:(NSString *)schema id:(TKKInt * _Nullable)id __attribute__((swift_name("init(schema:id:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapiLiteServerAccountStateCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapiLiteServerAccountState *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerAccountState *)value __attribute__((swift_name("encode(writer:value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerGetAllShardsInfo.Companion")))
@interface TKKTon_kotlin_liteapiLiteServerGetAllShardsInfoCompanion : TKKBase <TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapiLiteServerGetAllShardsInfoCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapiLiteServerGetAllShardsInfo *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_liteapiLiteServerGetAllShardsInfo *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_liteapiLiteServerGetAllShardsInfo *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_liteapiLiteServerGetAllShardsInfo *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_liteapiLiteServerGetAllShardsInfo *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_liteapiLiteServerGetAllShardsInfo *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapiLiteServerGetAllShardsInfo *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerGetAllShardsInfo *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapiLiteServerGetAllShardsInfo *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerGetAllShardsInfo *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_liteapiLiteServerGetAllShardsInfo *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_liteapiLiteServerGetAllShardsInfo *)value __attribute__((swift_name("hash(value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerAllShardsInfo.Companion")))
@interface TKKTon_kotlin_liteapiLiteServerAllShardsInfoCompanion : TKKBase <TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapiLiteServerAllShardsInfoCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapiLiteServerAllShardsInfo *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_liteapiLiteServerAllShardsInfo *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_liteapiLiteServerAllShardsInfo *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_liteapiLiteServerAllShardsInfo *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_liteapiLiteServerAllShardsInfo *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_liteapiLiteServerAllShardsInfo *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapiLiteServerAllShardsInfo *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerAllShardsInfo *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapiLiteServerAllShardsInfo *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerAllShardsInfo *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_liteapiLiteServerAllShardsInfo *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_liteapiLiteServerAllShardsInfo *)value __attribute__((swift_name("hash(value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerGetBlock.Companion")))
@interface TKKTon_kotlin_liteapiLiteServerGetBlockCompanion : TKKBase <TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapiLiteServerGetBlockCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapiLiteServerGetBlock *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_liteapiLiteServerGetBlock *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_liteapiLiteServerGetBlock *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_liteapiLiteServerGetBlock *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_liteapiLiteServerGetBlock *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_liteapiLiteServerGetBlock *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapiLiteServerGetBlock *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerGetBlock *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapiLiteServerGetBlock *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerGetBlock *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_liteapiLiteServerGetBlock *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_liteapiLiteServerGetBlock *)value __attribute__((swift_name("hash(value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerBlockData.Companion")))
@interface TKKTon_kotlin_liteapiLiteServerBlockDataCompanion : TKKTon_kotlin_tlTlConstructor<TKKTon_kotlin_liteapiLiteServerBlockData *>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (instancetype)initWithSchema:(NSString *)schema id:(TKKInt * _Nullable)id __attribute__((swift_name("init(schema:id:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapiLiteServerBlockDataCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapiLiteServerBlockData *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerBlockData *)value __attribute__((swift_name("encode(writer:value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerGetBlockHeader.Companion")))
@interface TKKTon_kotlin_liteapiLiteServerGetBlockHeaderCompanion : TKKBase <TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapiLiteServerGetBlockHeaderCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapiLiteServerGetBlockHeader *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_liteapiLiteServerGetBlockHeader *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_liteapiLiteServerGetBlockHeader *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_liteapiLiteServerGetBlockHeader *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_liteapiLiteServerGetBlockHeader *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_liteapiLiteServerGetBlockHeader *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapiLiteServerGetBlockHeader *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerGetBlockHeader *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapiLiteServerGetBlockHeader *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerGetBlockHeader *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_liteapiLiteServerGetBlockHeader *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_liteapiLiteServerGetBlockHeader *)value __attribute__((swift_name("hash(value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerBlockHeader.Companion")))
@interface TKKTon_kotlin_liteapiLiteServerBlockHeaderCompanion : TKKBase <TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapiLiteServerBlockHeaderCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapiLiteServerBlockHeader *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_liteapiLiteServerBlockHeader *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_liteapiLiteServerBlockHeader *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_liteapiLiteServerBlockHeader *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_liteapiLiteServerBlockHeader *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_liteapiLiteServerBlockHeader *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapiLiteServerBlockHeader *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerBlockHeader *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapiLiteServerBlockHeader *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerBlockHeader *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_liteapiLiteServerBlockHeader *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_liteapiLiteServerBlockHeader *)value __attribute__((swift_name("hash(value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerGetBlockProof.Companion")))
@interface TKKTon_kotlin_liteapiLiteServerGetBlockProofCompanion : TKKBase <TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapiLiteServerGetBlockProofCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapiLiteServerGetBlockProof *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_liteapiLiteServerGetBlockProof *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_liteapiLiteServerGetBlockProof *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_liteapiLiteServerGetBlockProof *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_liteapiLiteServerGetBlockProof *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_liteapiLiteServerGetBlockProof *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapiLiteServerGetBlockProof *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerGetBlockProof *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapiLiteServerGetBlockProof *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerGetBlockProof *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_liteapiLiteServerGetBlockProof *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_liteapiLiteServerGetBlockProof *)value __attribute__((swift_name("hash(value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((swift_name("Ton_kotlin_liteapiLiteServerBlockLink")))
@protocol TKKTon_kotlin_liteapiLiteServerBlockLink
@required
@property (readonly) TKKTon_kotlin_apiTonNodeBlockIdExt *from __attribute__((swift_name("from")));
@property (readonly) TKKTon_kotlin_apiTonNodeBlockIdExt *to __attribute__((swift_name("to")));
@property (readonly) BOOL toKeyBlock __attribute__((swift_name("toKeyBlock")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerPartialBlockProof.Companion")))
@interface TKKTon_kotlin_liteapiLiteServerPartialBlockProofCompanion : TKKBase <TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapiLiteServerPartialBlockProofCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapiLiteServerPartialBlockProof *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_liteapiLiteServerPartialBlockProof *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_liteapiLiteServerPartialBlockProof *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_liteapiLiteServerPartialBlockProof *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_liteapiLiteServerPartialBlockProof *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_liteapiLiteServerPartialBlockProof *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapiLiteServerPartialBlockProof *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerPartialBlockProof *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapiLiteServerPartialBlockProof *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerPartialBlockProof *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_liteapiLiteServerPartialBlockProof *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_liteapiLiteServerPartialBlockProof *)value __attribute__((swift_name("hash(value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerGetConfigAll.Companion")))
@interface TKKTon_kotlin_liteapiLiteServerGetConfigAllCompanion : TKKBase <TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapiLiteServerGetConfigAllCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapiLiteServerGetConfigAll *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_liteapiLiteServerGetConfigAll *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_liteapiLiteServerGetConfigAll *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_liteapiLiteServerGetConfigAll *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_liteapiLiteServerGetConfigAll *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_liteapiLiteServerGetConfigAll *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapiLiteServerGetConfigAll *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerGetConfigAll *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapiLiteServerGetConfigAll *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerGetConfigAll *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_liteapiLiteServerGetConfigAll *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_liteapiLiteServerGetConfigAll *)value __attribute__((swift_name("hash(value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerConfigInfo.Companion")))
@interface TKKTon_kotlin_liteapiLiteServerConfigInfoCompanion : TKKBase <TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapiLiteServerConfigInfoCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapiLiteServerConfigInfo *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_liteapiLiteServerConfigInfo *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_liteapiLiteServerConfigInfo *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_liteapiLiteServerConfigInfo *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_liteapiLiteServerConfigInfo *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_liteapiLiteServerConfigInfo *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapiLiteServerConfigInfo *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerConfigInfo *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapiLiteServerConfigInfo *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerConfigInfo *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_liteapiLiteServerConfigInfo *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_liteapiLiteServerConfigInfo *)value __attribute__((swift_name("hash(value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerGetConfigParams.Companion")))
@interface TKKTon_kotlin_liteapiLiteServerGetConfigParamsCompanion : TKKBase <TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapiLiteServerGetConfigParamsCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapiLiteServerGetConfigParams *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_liteapiLiteServerGetConfigParams *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_liteapiLiteServerGetConfigParams *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_liteapiLiteServerGetConfigParams *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_liteapiLiteServerGetConfigParams *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_liteapiLiteServerGetConfigParams *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapiLiteServerGetConfigParams *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerGetConfigParams *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapiLiteServerGetConfigParams *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerGetConfigParams *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_liteapiLiteServerGetConfigParams *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_liteapiLiteServerGetConfigParams *)value __attribute__((swift_name("hash(value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((swift_name("Ktor_ioCloseable")))
@protocol TKKKtor_ioCloseable
@required
- (void)close __attribute__((swift_name("close()")));
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
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_apiTonNodeZeroStateIdExt")))
@interface TKKTon_kotlin_apiTonNodeZeroStateIdExt : TKKBase
- (instancetype)initWithTonNodeBlockIdExt:(TKKTon_kotlin_apiTonNodeBlockIdExt *)tonNodeBlockIdExt __attribute__((swift_name("init(tonNodeBlockIdExt:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithWorkchain:(int32_t)workchain rootHash:(TKKTon_kotlin_tlByteString *)rootHash fileHash:(TKKTon_kotlin_tlByteString *)fileHash __attribute__((swift_name("init(workchain:rootHash:fileHash:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_apiTonNodeZeroStateIdExtCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_apiTonNodeZeroStateIdExt *)doCopyWorkchain:(int32_t)workchain rootHash:(TKKTon_kotlin_tlByteString *)rootHash fileHash:(TKKTon_kotlin_tlByteString *)fileHash __attribute__((swift_name("doCopy(workchain:rootHash:fileHash:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (BOOL)isMasterchain __attribute__((swift_name("isMasterchain()")));
- (BOOL)isValid __attribute__((swift_name("isValid()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) TKKTon_kotlin_tlByteString *fileHash __attribute__((swift_name("fileHash")));
@property (readonly) TKKTon_kotlin_tlByteString *rootHash __attribute__((swift_name("rootHash")));
@property (readonly) int32_t workchain __attribute__((swift_name("workchain")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerMasterchainInfo.Companion")))
@interface TKKTon_kotlin_liteapiLiteServerMasterchainInfoCompanion : TKKBase <TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapiLiteServerMasterchainInfoCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapiLiteServerMasterchainInfo *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_liteapiLiteServerMasterchainInfo *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_liteapiLiteServerMasterchainInfo *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_liteapiLiteServerMasterchainInfo *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_liteapiLiteServerMasterchainInfo *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_liteapiLiteServerMasterchainInfo *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapiLiteServerMasterchainInfo *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerMasterchainInfo *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapiLiteServerMasterchainInfo *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerMasterchainInfo *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_liteapiLiteServerMasterchainInfo *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_liteapiLiteServerMasterchainInfo *)value __attribute__((swift_name("hash(value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerGetMasterchainInfoExt.Companion")))
@interface TKKTon_kotlin_liteapiLiteServerGetMasterchainInfoExtCompanion : TKKBase <TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapiLiteServerGetMasterchainInfoExtCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapiLiteServerGetMasterchainInfoExt *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_liteapiLiteServerGetMasterchainInfoExt *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_liteapiLiteServerGetMasterchainInfoExt *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_liteapiLiteServerGetMasterchainInfoExt *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_liteapiLiteServerGetMasterchainInfoExt *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_liteapiLiteServerGetMasterchainInfoExt *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapiLiteServerGetMasterchainInfoExt *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerGetMasterchainInfoExt *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapiLiteServerGetMasterchainInfoExt *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerGetMasterchainInfoExt *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_liteapiLiteServerGetMasterchainInfoExt *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_liteapiLiteServerGetMasterchainInfoExt *)value __attribute__((swift_name("hash(value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerMasterchainInfoExt.Companion")))
@interface TKKTon_kotlin_liteapiLiteServerMasterchainInfoExtCompanion : TKKTon_kotlin_tlTlConstructor<TKKTon_kotlin_liteapiLiteServerMasterchainInfoExt *>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (instancetype)initWithSchema:(NSString *)schema id:(TKKInt * _Nullable)id __attribute__((swift_name("init(schema:id:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapiLiteServerMasterchainInfoExtCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapiLiteServerMasterchainInfoExt *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerMasterchainInfoExt *)value __attribute__((swift_name("encode(writer:value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerGetOneTransaction.Companion")))
@interface TKKTon_kotlin_liteapiLiteServerGetOneTransactionCompanion : TKKBase <TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapiLiteServerGetOneTransactionCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapiLiteServerGetOneTransaction *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_liteapiLiteServerGetOneTransaction *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_liteapiLiteServerGetOneTransaction *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_liteapiLiteServerGetOneTransaction *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_liteapiLiteServerGetOneTransaction *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_liteapiLiteServerGetOneTransaction *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapiLiteServerGetOneTransaction *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerGetOneTransaction *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapiLiteServerGetOneTransaction *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerGetOneTransaction *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_liteapiLiteServerGetOneTransaction *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_liteapiLiteServerGetOneTransaction *)value __attribute__((swift_name("hash(value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerTransactionInfo.Companion")))
@interface TKKTon_kotlin_liteapiLiteServerTransactionInfoCompanion : TKKBase <TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapiLiteServerTransactionInfoCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapiLiteServerTransactionInfo *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_liteapiLiteServerTransactionInfo *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_liteapiLiteServerTransactionInfo *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_liteapiLiteServerTransactionInfo *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_liteapiLiteServerTransactionInfo *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_liteapiLiteServerTransactionInfo *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapiLiteServerTransactionInfo *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerTransactionInfo *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapiLiteServerTransactionInfo *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerTransactionInfo *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_liteapiLiteServerTransactionInfo *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_liteapiLiteServerTransactionInfo *)value __attribute__((swift_name("hash(value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerGetShardInfo.Companion")))
@interface TKKTon_kotlin_liteapiLiteServerGetShardInfoCompanion : TKKBase <TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapiLiteServerGetShardInfoCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapiLiteServerGetShardInfo *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_liteapiLiteServerGetShardInfo *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_liteapiLiteServerGetShardInfo *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_liteapiLiteServerGetShardInfo *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_liteapiLiteServerGetShardInfo *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_liteapiLiteServerGetShardInfo *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapiLiteServerGetShardInfo *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerGetShardInfo *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapiLiteServerGetShardInfo *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerGetShardInfo *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_liteapiLiteServerGetShardInfo *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_liteapiLiteServerGetShardInfo *)value __attribute__((swift_name("hash(value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerShardInfo.Companion")))
@interface TKKTon_kotlin_liteapiLiteServerShardInfoCompanion : TKKBase <TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapiLiteServerShardInfoCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapiLiteServerShardInfo *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_liteapiLiteServerShardInfo *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_liteapiLiteServerShardInfo *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_liteapiLiteServerShardInfo *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_liteapiLiteServerShardInfo *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_liteapiLiteServerShardInfo *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapiLiteServerShardInfo *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerShardInfo *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapiLiteServerShardInfo *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerShardInfo *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_liteapiLiteServerShardInfo *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_liteapiLiteServerShardInfo *)value __attribute__((swift_name("hash(value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerGetState.Companion")))
@interface TKKTon_kotlin_liteapiLiteServerGetStateCompanion : TKKBase <TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapiLiteServerGetStateCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapiLiteServerGetState *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_liteapiLiteServerGetState *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_liteapiLiteServerGetState *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_liteapiLiteServerGetState *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_liteapiLiteServerGetState *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_liteapiLiteServerGetState *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapiLiteServerGetState *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerGetState *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapiLiteServerGetState *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerGetState *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_liteapiLiteServerGetState *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_liteapiLiteServerGetState *)value __attribute__((swift_name("hash(value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerBlockState.Companion")))
@interface TKKTon_kotlin_liteapiLiteServerBlockStateCompanion : TKKBase <TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapiLiteServerBlockStateCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapiLiteServerBlockState *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_liteapiLiteServerBlockState *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_liteapiLiteServerBlockState *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_liteapiLiteServerBlockState *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_liteapiLiteServerBlockState *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_liteapiLiteServerBlockState *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapiLiteServerBlockState *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerBlockState *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapiLiteServerBlockState *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerBlockState *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_liteapiLiteServerBlockState *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_liteapiLiteServerBlockState *)value __attribute__((swift_name("hash(value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerCurrentTime.Companion")))
@interface TKKTon_kotlin_liteapiLiteServerCurrentTimeCompanion : TKKTon_kotlin_tlTlConstructor<TKKTon_kotlin_liteapiLiteServerCurrentTime *>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (instancetype)initWithSchema:(NSString *)schema id:(TKKInt * _Nullable)id __attribute__((swift_name("init(schema:id:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapiLiteServerCurrentTimeCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapiLiteServerCurrentTime *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerCurrentTime *)value __attribute__((swift_name("encode(writer:value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerGetTransactions.Companion")))
@interface TKKTon_kotlin_liteapiLiteServerGetTransactionsCompanion : TKKBase <TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapiLiteServerGetTransactionsCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapiLiteServerGetTransactions *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_liteapiLiteServerGetTransactions *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_liteapiLiteServerGetTransactions *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_liteapiLiteServerGetTransactions *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_liteapiLiteServerGetTransactions *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_liteapiLiteServerGetTransactions *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapiLiteServerGetTransactions *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerGetTransactions *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapiLiteServerGetTransactions *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerGetTransactions *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_liteapiLiteServerGetTransactions *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_liteapiLiteServerGetTransactions *)value __attribute__((swift_name("hash(value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerTransactionList.Companion")))
@interface TKKTon_kotlin_liteapiLiteServerTransactionListCompanion : TKKBase <TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapiLiteServerTransactionListCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapiLiteServerTransactionList *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_liteapiLiteServerTransactionList *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_liteapiLiteServerTransactionList *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_liteapiLiteServerTransactionList *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_liteapiLiteServerTransactionList *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_liteapiLiteServerTransactionList *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapiLiteServerTransactionList *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerTransactionList *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapiLiteServerTransactionList *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerTransactionList *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_liteapiLiteServerTransactionList *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_liteapiLiteServerTransactionList *)value __attribute__((swift_name("hash(value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerGetValidatorStats.Companion")))
@interface TKKTon_kotlin_liteapiLiteServerGetValidatorStatsCompanion : TKKBase <TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapiLiteServerGetValidatorStatsCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapiLiteServerGetValidatorStats *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_liteapiLiteServerGetValidatorStats *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_liteapiLiteServerGetValidatorStats *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_liteapiLiteServerGetValidatorStats *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_liteapiLiteServerGetValidatorStats *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_liteapiLiteServerGetValidatorStats *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapiLiteServerGetValidatorStats *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerGetValidatorStats *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapiLiteServerGetValidatorStats *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerGetValidatorStats *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_liteapiLiteServerGetValidatorStats *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_liteapiLiteServerGetValidatorStats *)value __attribute__((swift_name("hash(value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerValidatorStats.Companion")))
@interface TKKTon_kotlin_liteapiLiteServerValidatorStatsCompanion : TKKBase <TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapiLiteServerValidatorStatsCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapiLiteServerValidatorStats *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_liteapiLiteServerValidatorStats *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_liteapiLiteServerValidatorStats *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_liteapiLiteServerValidatorStats *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_liteapiLiteServerValidatorStats *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_liteapiLiteServerValidatorStats *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapiLiteServerValidatorStats *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerValidatorStats *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapiLiteServerValidatorStats *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerValidatorStats *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_liteapiLiteServerValidatorStats *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_liteapiLiteServerValidatorStats *)value __attribute__((swift_name("hash(value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerVersion.Companion")))
@interface TKKTon_kotlin_liteapiLiteServerVersionCompanion : TKKBase <TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapiLiteServerVersionCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapiLiteServerVersion *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_liteapiLiteServerVersion *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_liteapiLiteServerVersion *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_liteapiLiteServerVersion *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_liteapiLiteServerVersion *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_liteapiLiteServerVersion *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapiLiteServerVersion *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerVersion *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapiLiteServerVersion *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerVersion *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_liteapiLiteServerVersion *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_liteapiLiteServerVersion *)value __attribute__((swift_name("hash(value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerTransactionId3")))
@interface TKKTon_kotlin_liteapiLiteServerTransactionId3 : TKKBase
- (instancetype)initWithAccount:(TKKKotlinByteArray *)account lt:(int64_t)lt __attribute__((swift_name("init(account:lt:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapiLiteServerTransactionId3Companion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapiLiteServerTransactionId3 *)doCopyAccount:(TKKKotlinByteArray *)account lt:(int64_t)lt __attribute__((swift_name("doCopy(account:lt:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) TKKKotlinByteArray *account __attribute__((swift_name("account")));
@property (readonly) int64_t lt __attribute__((swift_name("lt")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerListBlockTransactions.Companion")))
@interface TKKTon_kotlin_liteapiLiteServerListBlockTransactionsCompanion : TKKBase <TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapiLiteServerListBlockTransactionsCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapiLiteServerListBlockTransactions *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_liteapiLiteServerListBlockTransactions *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_liteapiLiteServerListBlockTransactions *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_liteapiLiteServerListBlockTransactions *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_liteapiLiteServerListBlockTransactions *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_liteapiLiteServerListBlockTransactions *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapiLiteServerListBlockTransactions *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerListBlockTransactions *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapiLiteServerListBlockTransactions *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerListBlockTransactions *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_liteapiLiteServerListBlockTransactions *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_liteapiLiteServerListBlockTransactions *)value __attribute__((swift_name("hash(value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerTransactionId")))
@interface TKKTon_kotlin_liteapiLiteServerTransactionId : TKKBase
- (instancetype)initWithAccount:(TKKKotlinByteArray * _Nullable)account lt:(TKKLong * _Nullable)lt hash:(TKKKotlinByteArray * _Nullable)hash __attribute__((swift_name("init(account:lt:hash:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_liteapiLiteServerTransactionIdCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_liteapiLiteServerTransactionId *)doCopyMode:(int32_t)mode account:(TKKKotlinByteArray * _Nullable)account lt:(TKKLong * _Nullable)lt hash:(TKKKotlinByteArray * _Nullable)hash __attribute__((swift_name("doCopy(mode:account:lt:hash:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) TKKKotlinByteArray * _Nullable account __attribute__((swift_name("account")));
@property (readonly, getter=hash_) TKKKotlinByteArray * _Nullable hash __attribute__((swift_name("hash")));
@property (readonly) TKKLong * _Nullable lt __attribute__((swift_name("lt")));
@property (readonly) int32_t mode __attribute__((swift_name("mode")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerBlockTransactions.Companion")))
@interface TKKTon_kotlin_liteapiLiteServerBlockTransactionsCompanion : TKKBase <TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapiLiteServerBlockTransactionsCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapiLiteServerBlockTransactions *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_liteapiLiteServerBlockTransactions *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_liteapiLiteServerBlockTransactions *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_liteapiLiteServerBlockTransactions *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_liteapiLiteServerBlockTransactions *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_liteapiLiteServerBlockTransactions *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapiLiteServerBlockTransactions *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerBlockTransactions *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapiLiteServerBlockTransactions *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerBlockTransactions *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_liteapiLiteServerBlockTransactions *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_liteapiLiteServerBlockTransactions *)value __attribute__((swift_name("hash(value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerLookupBlock.Companion")))
@interface TKKTon_kotlin_liteapiLiteServerLookupBlockCompanion : TKKBase <TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapiLiteServerLookupBlockCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapiLiteServerLookupBlock *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_liteapiLiteServerLookupBlock *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_liteapiLiteServerLookupBlock *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_liteapiLiteServerLookupBlock *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_liteapiLiteServerLookupBlock *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_liteapiLiteServerLookupBlock *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapiLiteServerLookupBlock *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerLookupBlock *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapiLiteServerLookupBlock *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerLookupBlock *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_liteapiLiteServerLookupBlock *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_liteapiLiteServerLookupBlock *)value __attribute__((swift_name("hash(value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@property (readonly) int32_t ID_MASK __attribute__((swift_name("ID_MASK")));
@property (readonly) int32_t LT_MASK __attribute__((swift_name("LT_MASK")));
@property (readonly) int32_t UTIME_MASK __attribute__((swift_name("UTIME_MASK")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerRunSmcMethod.Companion")))
@interface TKKTon_kotlin_liteapiLiteServerRunSmcMethodCompanion : TKKBase <TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapiLiteServerRunSmcMethodCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapiLiteServerRunSmcMethod *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_liteapiLiteServerRunSmcMethod *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_liteapiLiteServerRunSmcMethod *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_liteapiLiteServerRunSmcMethod *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_liteapiLiteServerRunSmcMethod *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_liteapiLiteServerRunSmcMethod *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapiLiteServerRunSmcMethod *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerRunSmcMethod *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapiLiteServerRunSmcMethod *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerRunSmcMethod *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_liteapiLiteServerRunSmcMethod *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_liteapiLiteServerRunSmcMethod *)value __attribute__((swift_name("hash(value:)")));

/**
 * @note annotations
 *   kotlin.jvm.JvmStatic
*/
- (int64_t)methodIdMethodName:(NSString *)methodName __attribute__((swift_name("methodId(methodName:)")));

/**
 * @note annotations
 *   kotlin.jvm.JvmStatic
*/
- (TKKKotlinByteArray *)paramsParams:(TKKKotlinArray<id<TKKTon_kotlin_blockVmStackValue>> *)params __attribute__((swift_name("params(params:)")));

/**
 * @note annotations
 *   kotlin.jvm.JvmStatic
*/
- (TKKKotlinByteArray *)paramsParams_:(id)params __attribute__((swift_name("params(params_:)")));

/**
 * @note annotations
 *   kotlin.jvm.JvmStatic
*/
- (TKKKotlinByteArray *)paramsVmStack:(id<TKKTon_kotlin_blockVmStack>)vmStack __attribute__((swift_name("params(vmStack:)")));

/**
 * @note annotations
 *   kotlin.jvm.JvmStatic
*/
- (TKKKotlinByteArray *)paramsVmStackList:(id<TKKTon_kotlin_blockVmStackList> _Nullable)vmStackList __attribute__((swift_name("params(vmStackList:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerRunMethodResult.Companion")))
@interface TKKTon_kotlin_liteapiLiteServerRunMethodResultCompanion : TKKBase <TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapiLiteServerRunMethodResultCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapiLiteServerRunMethodResult *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_liteapiLiteServerRunMethodResult *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_liteapiLiteServerRunMethodResult *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_liteapiLiteServerRunMethodResult *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_liteapiLiteServerRunMethodResult *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_liteapiLiteServerRunMethodResult *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapiLiteServerRunMethodResult *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerRunMethodResult *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapiLiteServerRunMethodResult *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerRunMethodResult *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_liteapiLiteServerRunMethodResult *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_liteapiLiteServerRunMethodResult *)value __attribute__((swift_name("hash(value:)")));

/**
 * @note annotations
 *   kotlin.jvm.JvmStatic
*/
- (int32_t)modeHasProof:(BOOL)hasProof hasStateProof:(BOOL)hasStateProof hasResult:(BOOL)hasResult hasInitC7:(BOOL)hasInitC7 hasLibExtras:(BOOL)hasLibExtras __attribute__((swift_name("mode(hasProof:hasStateProof:hasResult:hasInitC7:hasLibExtras:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerSendMessage.Companion")))
@interface TKKTon_kotlin_liteapiLiteServerSendMessageCompanion : TKKBase <TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapiLiteServerSendMessageCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapiLiteServerSendMessage *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_liteapiLiteServerSendMessage *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_liteapiLiteServerSendMessage *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_liteapiLiteServerSendMessage *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_liteapiLiteServerSendMessage *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_liteapiLiteServerSendMessage *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapiLiteServerSendMessage *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerSendMessage *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapiLiteServerSendMessage *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerSendMessage *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_liteapiLiteServerSendMessage *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_liteapiLiteServerSendMessage *)value __attribute__((swift_name("hash(value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerSendMsgStatus.Companion")))
@interface TKKTon_kotlin_liteapiLiteServerSendMsgStatusCompanion : TKKTon_kotlin_tlTlConstructor<TKKTon_kotlin_liteapiLiteServerSendMsgStatus *>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (instancetype)initWithSchema:(NSString *)schema id:(TKKInt * _Nullable)id __attribute__((swift_name("init(schema:id:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapiLiteServerSendMsgStatusCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapiLiteServerSendMsgStatus *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerSendMsgStatus *)value __attribute__((swift_name("encode(writer:value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_apiPublicKeyEd25519.Companion")))
@interface TKKTon_kotlin_apiPublicKeyEd25519Companion : TKKBase <TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_apiPublicKeyEd25519Companion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_apiPublicKeyEd25519 *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_apiPublicKeyEd25519 *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_apiPublicKeyEd25519 *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_apiPublicKeyEd25519 *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_apiPublicKeyEd25519 *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_apiPublicKeyEd25519 *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_apiPublicKeyEd25519 *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_apiPublicKeyEd25519 *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_apiPublicKeyEd25519 *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_apiPublicKeyEd25519 *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_apiPublicKeyEd25519 *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_apiPublicKeyEd25519 *)value __attribute__((swift_name("hash(value:)")));

/**
 * @note annotations
 *   kotlin.jvm.JvmStatic
*/
- (TKKTon_kotlin_apiPublicKeyEd25519 *)ofPrivateKey:(id<TKKTon_kotlin_apiPrivateKeyEd25519>)privateKey __attribute__((swift_name("of(privateKey:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));

/**
 * @note annotations
 *   kotlin.jvm.JvmStatic
*/
- (TKKTon_kotlin_tlTlConstructor<TKKTon_kotlin_apiPublicKeyEd25519 *> *)tlConstructor __attribute__((swift_name("tlConstructor()")));
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
- (TKKTon_kotlin_tlByteString *)decodeFromHex:(NSString *)receiver __attribute__((swift_name("decodeFromHex(_:)")));

/**
 * @note annotations
 *   kotlin.jvm.JvmStatic
 *   kotlin.jvm.JvmName(name="of")
*/
- (TKKTon_kotlin_tlByteString *)toByteString:(TKKKotlinByteArray *)receiver fromIndex:(int32_t)fromIndex toIndex:(int32_t)toIndex __attribute__((swift_name("toByteString(_:fromIndex:toIndex:)")));
@end

__attribute__((swift_name("Ton_kotlin_apiSignedTlObject")))
@protocol TKKTon_kotlin_apiSignedTlObject <TKKTon_kotlin_tlTlObject>
@required
- (id<TKKTon_kotlin_tlTlObject>)signedPrivateKey:(id<TKKTon_kotlin_apiPrivateKey>)privateKey __attribute__((swift_name("signed(privateKey:)")));
- (BOOL)verifyPublicKey:(id<TKKTon_kotlin_apiPublicKey>)publicKey __attribute__((swift_name("verify(publicKey:)")));
@property (readonly) TKKKotlinByteArray * _Nullable signature __attribute__((swift_name("signature")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_apiOverlayNode")))
@interface TKKTon_kotlin_apiOverlayNode : TKKBase <TKKTon_kotlin_apiSignedTlObject>
- (instancetype)initWithId:(id<TKKTon_kotlin_apiPublicKey>)id overlay:(TKKKotlinByteArray *)overlay version:(int32_t)version signature:(TKKKotlinByteArray *)signature __attribute__((swift_name("init(id:overlay:version:signature:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TKKTon_kotlin_apiOverlayNodeCompanion *companion __attribute__((swift_name("companion")));
- (TKKTon_kotlin_apiOverlayNode *)doCopyId:(id<TKKTon_kotlin_apiPublicKey>)id overlay:(TKKKotlinByteArray *)overlay version:(int32_t)version signature:(TKKKotlinByteArray *)signature __attribute__((swift_name("doCopy(id:overlay:version:signature:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (TKKTon_kotlin_apiOverlayNode *)signedPrivateKey:(id<TKKTon_kotlin_apiPrivateKey>)privateKey __attribute__((swift_name("signed(privateKey:)")));
- (id<TKKTon_kotlin_tlTlCodec>)tlCodec __attribute__((swift_name("tlCodec()")));
- (NSString *)description __attribute__((swift_name("description()")));
- (BOOL)verifyPublicKey:(id<TKKTon_kotlin_apiPublicKey>)publicKey __attribute__((swift_name("verify(publicKey:)")));
@property (readonly) id<TKKTon_kotlin_apiPublicKey> id __attribute__((swift_name("id")));
@property (readonly) TKKKotlinByteArray *overlay __attribute__((swift_name("overlay")));
@property (readonly) TKKKotlinByteArray *signature __attribute__((swift_name("signature")));
@property (readonly) int32_t version __attribute__((swift_name("version")));
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

__attribute__((swift_name("KotlinSequence")))
@protocol TKKKotlinSequence
@required
- (id<TKKKotlinIterator>)iterator __attribute__((swift_name("iterator()")));
@end

__attribute__((swift_name("Ton_kotlin_cellCellDescriptor")))
@protocol TKKTon_kotlin_cellCellDescriptor
@required
- (int8_t)component1__ __attribute__((swift_name("component1__()")));
- (int8_t)component2__ __attribute__((swift_name("component2__()")));
@property (readonly) TKKTon_kotlin_cellCellType *cellType __attribute__((swift_name("cellType")));
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
__attribute__((swift_name("Ton_kotlin_cellCellType")))
@interface TKKTon_kotlin_cellCellType : TKKKotlinEnum<TKKTon_kotlin_cellCellType *>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (instancetype)initWithName:(NSString *)name ordinal:(int32_t)ordinal __attribute__((swift_name("init(name:ordinal:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
@property (class, readonly, getter=companion) TKKTon_kotlin_cellCellTypeCompanion *companion __attribute__((swift_name("companion")));
@property (class, readonly) TKKTon_kotlin_cellCellType *ordinary __attribute__((swift_name("ordinary")));
@property (class, readonly) TKKTon_kotlin_cellCellType *prunedBranch __attribute__((swift_name("prunedBranch")));
@property (class, readonly) TKKTon_kotlin_cellCellType *libraryReference __attribute__((swift_name("libraryReference")));
@property (class, readonly) TKKTon_kotlin_cellCellType *merkleProof __attribute__((swift_name("merkleProof")));
@property (class, readonly) TKKTon_kotlin_cellCellType *merkleUpdate __attribute__((swift_name("merkleUpdate")));
+ (TKKKotlinArray<TKKTon_kotlin_cellCellType *> *)values __attribute__((swift_name("values()")));
@property (readonly) BOOL isExotic __attribute__((swift_name("isExotic")));
@property (readonly) BOOL isMerkle __attribute__((swift_name("isMerkle")));
@property (readonly) BOOL isPruned __attribute__((swift_name("isPruned")));
@property (readonly) int32_t value_ __attribute__((swift_name("value_")));
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
- (int8_t)toByte __attribute__((swift_name("toByte()")));
- (TKKKotlinByteArray *)toByteArray __attribute__((swift_name("toByteArray()")));
- (unichar)toChar __attribute__((swift_name("toChar()")));
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

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerAccountId.Companion")))
@interface TKKTon_kotlin_liteapiLiteServerAccountIdCompanion : TKKTon_kotlin_tlTlConstructor<TKKTon_kotlin_liteapiLiteServerAccountId *>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (instancetype)initWithSchema:(NSString *)schema id:(TKKInt * _Nullable)id __attribute__((swift_name("init(schema:id:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapiLiteServerAccountIdCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapiLiteServerAccountId *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerAccountId *)value __attribute__((swift_name("encode(writer:value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
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

__attribute__((swift_name("Ktor_ioObjectPool")))
@protocol TKKKtor_ioObjectPool <TKKKtor_ioCloseable>
@required
- (id)borrow __attribute__((swift_name("borrow()")));
- (void)dispose __attribute__((swift_name("dispose()")));
- (void)recycleInstance:(id)instance __attribute__((swift_name("recycle(instance:)")));
@property (readonly) int32_t capacity __attribute__((swift_name("capacity")));
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

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_apiTonNodeZeroStateIdExt.Companion")))
@interface TKKTon_kotlin_apiTonNodeZeroStateIdExtCompanion : TKKTon_kotlin_tlTlConstructor<TKKTon_kotlin_apiTonNodeZeroStateIdExt *>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (instancetype)initWithSchema:(NSString *)schema id:(TKKInt * _Nullable)id __attribute__((swift_name("init(schema:id:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_apiTonNodeZeroStateIdExtCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_apiTonNodeZeroStateIdExt *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_apiTonNodeZeroStateIdExt *)value __attribute__((swift_name("encode(writer:value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerTransactionId3.Companion")))
@interface TKKTon_kotlin_liteapiLiteServerTransactionId3Companion : TKKBase <TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapiLiteServerTransactionId3Companion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapiLiteServerTransactionId3 *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_liteapiLiteServerTransactionId3 *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_liteapiLiteServerTransactionId3 *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_liteapiLiteServerTransactionId3 *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_liteapiLiteServerTransactionId3 *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_liteapiLiteServerTransactionId3 *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapiLiteServerTransactionId3 *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerTransactionId3 *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapiLiteServerTransactionId3 *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerTransactionId3 *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_liteapiLiteServerTransactionId3 *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_liteapiLiteServerTransactionId3 *)value __attribute__((swift_name("hash(value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_liteapiLiteServerTransactionId.Companion")))
@interface TKKTon_kotlin_liteapiLiteServerTransactionIdCompanion : TKKBase <TKKTon_kotlin_tlTlCodec>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_liteapiLiteServerTransactionIdCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_liteapiLiteServerTransactionId *)decodeInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decode(input:)")));
- (TKKTon_kotlin_liteapiLiteServerTransactionId *)decodeByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decode(byteArray:)")));
- (TKKTon_kotlin_liteapiLiteServerTransactionId *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (TKKTon_kotlin_liteapiLiteServerTransactionId *)decodeBoxedInput:(TKKKtor_ioInput *)input __attribute__((swift_name("decodeBoxed(input:)")));
- (TKKTon_kotlin_liteapiLiteServerTransactionId *)decodeBoxedByteArray:(TKKKotlinByteArray *)byteArray __attribute__((swift_name("decodeBoxed(byteArray:)")));
- (TKKTon_kotlin_liteapiLiteServerTransactionId *)decodeBoxedReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decodeBoxed(reader:)")));
- (void)encodeOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapiLiteServerTransactionId *)value __attribute__((swift_name("encode(output:value:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerTransactionId *)value __attribute__((swift_name("encode(writer:value:)")));
- (void)encodeBoxedOutput:(TKKKtor_ioOutput *)output value:(TKKTon_kotlin_liteapiLiteServerTransactionId *)value __attribute__((swift_name("encodeBoxed(output:value:)")));
- (void)encodeBoxedWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_liteapiLiteServerTransactionId *)value __attribute__((swift_name("encodeBoxed(writer:value:)")));
- (TKKKotlinByteArray *)encodeToByteArrayValue:(TKKTon_kotlin_liteapiLiteServerTransactionId *)value boxed:(BOOL)boxed __attribute__((swift_name("encodeToByteArray(value:boxed:)")));
- (TKKKotlinByteArray *)hashValue:(TKKTon_kotlin_liteapiLiteServerTransactionId *)value __attribute__((swift_name("hash(value:)")));

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
__attribute__((swift_name("Ton_kotlin_blockVmStackValue")))
@protocol TKKTon_kotlin_blockVmStackValue
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

__attribute__((swift_name("Ton_kotlin_blockVmStack")))
@protocol TKKTon_kotlin_blockVmStack <TKKKotlinCollection>
@required
- (id<TKKTon_kotlin_blockVmStackValue>)getIndex___:(int32_t)index __attribute__((swift_name("get(index___:)")));
- (id<TKKTon_kotlin_blockMutableVmStack>)toMutableVmStack __attribute__((swift_name("toMutableVmStack()")));
@property (readonly) int32_t depth __attribute__((swift_name("depth")));
@property (readonly) id<TKKTon_kotlin_blockVmStackList> stack __attribute__((swift_name("stack")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((swift_name("Ton_kotlin_blockVmStackList")))
@protocol TKKTon_kotlin_blockVmStackList <TKKKotlinIterable>
@required
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_apiOverlayNode.Companion")))
@interface TKKTon_kotlin_apiOverlayNodeCompanion : TKKTon_kotlin_tlTlConstructor<TKKTon_kotlin_apiOverlayNode *>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (instancetype)initWithSchema:(NSString *)schema id:(TKKInt * _Nullable)id __attribute__((swift_name("init(schema:id:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_apiOverlayNodeCompanion *shared __attribute__((swift_name("shared")));
- (TKKTon_kotlin_apiOverlayNode *)decodeReader:(TKKTon_kotlin_tlTlReader *)reader __attribute__((swift_name("decode(reader:)")));
- (void)encodeWriter:(TKKTon_kotlin_tlTlWriter *)writer value:(TKKTon_kotlin_apiOverlayNode *)value __attribute__((swift_name("encode(writer:value:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
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

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_cellCellType.Companion")))
@interface TKKTon_kotlin_cellCellTypeCompanion : TKKBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_cellCellTypeCompanion *shared __attribute__((swift_name("shared")));

/**
 * @note annotations
 *   kotlin.jvm.JvmStatic
*/
- (TKKTon_kotlin_cellCellType *)getIndex:(int32_t)index __attribute__((swift_name("get(index:)")));
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
__attribute__((swift_name("Ktor_ioMemory.Companion")))
@interface TKKKtor_ioMemoryCompanion : TKKBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKKtor_ioMemoryCompanion *shared __attribute__((swift_name("shared")));
@property (readonly) TKKKtor_ioMemory *Empty __attribute__((swift_name("Empty")));
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

__attribute__((swift_name("Ton_kotlin_blockMutableVmStack")))
@protocol TKKTon_kotlin_blockMutableVmStack <TKKTon_kotlin_blockVmStack>
@required
- (void)interchangeI:(int32_t)i __attribute__((swift_name("interchange(i:)")));
- (void)interchangeI:(int32_t)i j:(int32_t)j __attribute__((swift_name("interchange(i:j:)")));
- (id<TKKTon_kotlin_blockVmStackValue>)pop __attribute__((swift_name("pop()")));
- (BOOL)popBool __attribute__((swift_name("popBool()")));
- (id<TKKTon_kotlin_cellCellBuilder>)popBuilder __attribute__((swift_name("popBuilder()")));
- (id<TKKTon_kotlin_cellCell>)popCell __attribute__((swift_name("popCell()")));
- (id<TKKTon_kotlin_blockVmCont>)popCont __attribute__((swift_name("popCont()")));
- (TKKTon_kotlin_bigintBigInt *)popInt __attribute__((swift_name("popInt()")));
- (TKKTon_kotlin_blockVmStackNull *)popNull __attribute__((swift_name("popNull()")));
- (id<TKKTon_kotlin_blockVmStackNumber>)popNumber __attribute__((swift_name("popNumber()")));
- (id<TKKTon_kotlin_cellCellSlice>)popSlice __attribute__((swift_name("popSlice()")));
- (int64_t)popTinyInt __attribute__((swift_name("popTinyInt()")));
- (id<TKKTon_kotlin_blockVmTuple>)popTuple __attribute__((swift_name("popTuple()")));
- (void)pushStackValue:(id<TKKTon_kotlin_blockVmStackValue>)stackValue __attribute__((swift_name("push(stackValue:)")));
- (void)pushBoolBoolean:(BOOL)boolean __attribute__((swift_name("pushBool(boolean:)")));
- (void)pushBuilderCellBuilder:(id<TKKTon_kotlin_cellCellBuilder>)cellBuilder __attribute__((swift_name("pushBuilder(cellBuilder:)")));
- (void)pushCellCell:(id<TKKTon_kotlin_cellCell>)cell __attribute__((swift_name("pushCell(cell:)")));
- (void)pushContVmCont:(id<TKKTon_kotlin_blockVmCont>)vmCont __attribute__((swift_name("pushCont(vmCont:)")));
- (void)pushIntInt:(TKKTon_kotlin_bigintBigInt *)int_ __attribute__((swift_name("pushInt(int:)")));
- (void)pushNan __attribute__((swift_name("pushNan()")));
- (void)pushNull __attribute__((swift_name("pushNull()")));
- (void)pushSliceCellSlice:(id<TKKTon_kotlin_cellCellSlice>)cellSlice __attribute__((swift_name("pushSlice(cellSlice:)")));
- (void)pushTinyIntTinyInt:(BOOL)tinyInt __attribute__((swift_name("pushTinyInt(tinyInt:)")));
- (void)pushTinyIntTinyInt_:(int32_t)tinyInt __attribute__((swift_name("pushTinyInt(tinyInt_:)")));
- (void)pushTinyIntTinyInt__:(int64_t)tinyInt __attribute__((swift_name("pushTinyInt(tinyInt__:)")));
- (void)pushTupleVmTuple:(id<TKKTon_kotlin_blockVmTuple>)vmTuple __attribute__((swift_name("pushTuple(vmTuple:)")));
- (void)swap __attribute__((swift_name("swap()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((swift_name("Ton_kotlin_blockVmCont")))
@protocol TKKTon_kotlin_blockVmCont
@required
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ton_kotlin_blockVmStackNull")))
@interface TKKTon_kotlin_blockVmStackNull : TKKBase <TKKTon_kotlin_blockVmStackValue, TKKTon_kotlin_tlbTlbConstructorProvider>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)vmStackNull __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TKKTon_kotlin_blockVmStackNull *shared __attribute__((swift_name("shared")));
- (id<TKKTon_kotlin_cellCell>)createCellValue:(TKKTon_kotlin_blockVmStackNull *)value __attribute__((swift_name("createCell(value:)")));
- (TKKTon_kotlin_blockVmStackNull *)loadTlbCell:(id<TKKTon_kotlin_cellCell>)cell __attribute__((swift_name("loadTlb(cell:)")));
- (TKKTon_kotlin_blockVmStackNull *)loadTlbCellSlice:(id<TKKTon_kotlin_cellCellSlice>)cellSlice __attribute__((swift_name("loadTlb(cellSlice:)")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
- (id<TKKKotlinx_serialization_coreKSerializer>)serializerTypeParamsSerializers:(TKKKotlinArray<id<TKKKotlinx_serialization_coreKSerializer>> *)typeParamsSerializers __attribute__((swift_name("serializer(typeParamsSerializers:)")));
- (void)storeTlbCellBuilder:(id<TKKTon_kotlin_cellCellBuilder>)cellBuilder value:(TKKTon_kotlin_blockVmStackNull *)value __attribute__((swift_name("storeTlb(cellBuilder:value:)")));
- (TKKTon_kotlin_tlbTlbConstructor<TKKTon_kotlin_blockVmStackNull *> *)tlbConstructor __attribute__((swift_name("tlbConstructor()")));
- (NSString *)description __attribute__((swift_name("description()")));
@end

__attribute__((swift_name("Ton_kotlin_blockVmStackNumber")))
@protocol TKKTon_kotlin_blockVmStackNumber <TKKTon_kotlin_blockVmStackValue>
@required
- (id<TKKTon_kotlin_blockVmStackNumber>)divOther:(id<TKKTon_kotlin_blockVmStackNumber>)other __attribute__((swift_name("div(other:)")));
- (id<TKKTon_kotlin_blockVmStackNumber>)minusOther:(id<TKKTon_kotlin_blockVmStackNumber>)other __attribute__((swift_name("minus(other:)")));
- (id<TKKTon_kotlin_blockVmStackNumber>)plusOther:(id<TKKTon_kotlin_blockVmStackNumber>)other __attribute__((swift_name("plus(other:)")));
- (id<TKKTon_kotlin_blockVmStackNumber>)timesOther:(id<TKKTon_kotlin_blockVmStackNumber>)other __attribute__((swift_name("times(other:)")));
- (TKKTon_kotlin_bigintBigInt *)toBigInt __attribute__((swift_name("toBigInt()")));
- (BOOL)toBoolean __attribute__((swift_name("toBoolean()")));
- (int32_t)toInt __attribute__((swift_name("toInt()")));
- (int64_t)toLong __attribute__((swift_name("toLong()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((swift_name("Ton_kotlin_blockVmTuple")))
@protocol TKKTon_kotlin_blockVmTuple
@required
- (int32_t)depth_ __attribute__((swift_name("depth()")));
@end

#pragma pop_macro("_Nullable_result")
#pragma clang diagnostic pop
NS_ASSUME_NONNULL_END
