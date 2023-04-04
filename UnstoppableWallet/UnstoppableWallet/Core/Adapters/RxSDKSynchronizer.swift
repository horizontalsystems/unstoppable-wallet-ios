import Combine
import Foundation
import RxSwift
import RxCocoa
import RxRelay
import ZcashLightClientKit

class RxSDKSynchronizer {
    private let synchronizer: Synchronizer

    private var stateStreamRelay = BehaviorRelay<SynchronizerState>(value: .zero)
    private var eventStreamRelay = PublishRelay<SynchronizerEvent>()

    var cancellables: [AnyCancellable] = []

    public init(synchronizer: Synchronizer) {
        self.synchronizer = synchronizer

        synchronizer.stateStream
                .throttle(for: .seconds(0.3), scheduler: DispatchQueue.main, latest: true)
                .sink(receiveValue: { [weak self] state in
                            self?.stateStreamRelay.accept(state)
                        }
                )
                .store(in: &cancellables)

        synchronizer.eventStream
                .throttle(for: .seconds(0.1), scheduler: DispatchQueue.main, latest: true)
                .sink(receiveValue: { [weak self] event in
                    self?.eventStreamRelay.accept(event)
                }
                )
                .store(in: &cancellables)
    }
}

extension RxSDKSynchronizer {
    public var alias: ZcashSynchronizerAlias { synchronizer.alias }

    public var latestState: SynchronizerState { synchronizer.latestState }
    public var connectionState: ConnectionState { synchronizer.connectionState }

    var stateStreamObservable: Observable<SynchronizerState> {
        stateStreamRelay.asObservable()
    }

    var eventStreamObservable: Observable<SynchronizerEvent> {
        eventStreamRelay.asObservable()
    }

    public func prepare(with seed: [UInt8]?, viewingKeys: [UnifiedFullViewingKey], walletBirthday: BlockHeight) -> Single<Initializer.InitializationResult> {
        executeThrowingAction {
            try await self.synchronizer.prepare(with: seed, viewingKeys: viewingKeys, walletBirthday: walletBirthday)
        }
    }

    public func start(retry: Bool) -> Single<()> {
        executeThrowingAction {
            try await self.synchronizer.start(retry: retry)
        }
    }

    public func stop() -> Single<()> {
        executeAction {
            await self.synchronizer.stop()
        }
    }

    public func getSaplingAddress(accountIndex: Int) -> Single<SaplingAddress?> {
        executeAction {
            await self.synchronizer.getSaplingAddress(accountIndex: accountIndex)
        }
    }

    public func getUnifiedAddress(accountIndex: Int) -> Single<UnifiedAddress?> {
        executeAction {
            await self.synchronizer.getUnifiedAddress(accountIndex: accountIndex)
        }
    }

    public func getTransparentAddress(accountIndex: Int) -> Single<TransparentAddress?> {
        executeAction {
            await self.synchronizer.getTransparentAddress(accountIndex: accountIndex)
        }
    }

    public func sendToAddress(
            spendingKey: UnifiedSpendingKey,
            zatoshi: Zatoshi,
            toAddress: Recipient,
            memo: Memo?) -> Single<PendingTransactionEntity> {
        executeThrowingAction {
            try await self.synchronizer.sendToAddress(spendingKey: spendingKey, zatoshi: zatoshi, toAddress: toAddress, memo: memo)
        }
    }

    public func shieldFunds(
            spendingKey: UnifiedSpendingKey,
            memo: Memo,
            shieldingThreshold: Zatoshi) -> Single<PendingTransactionEntity> {
        executeThrowingAction {
            try await self.synchronizer.shieldFunds(spendingKey: spendingKey, memo: memo, shieldingThreshold: shieldingThreshold)
        }
    }

    public func cancelSpend(transaction: PendingTransactionEntity) -> Single<Bool> {
        executeAction {
            await self.synchronizer.cancelSpend(transaction: transaction)
        }
    }

    public func pendingTransactions() -> Single<[PendingTransactionEntity]> {
        executeAction {
            await self.synchronizer.pendingTransactions
        }
    }

    public func clearedTransactions() -> Single<[ZcashTransaction.Overview]> {
        executeAction {
            await self.synchronizer.clearedTransactions
        }
    }

    public func sentTranscations() -> Single<[ZcashTransaction.Sent]> {
        executeAction {
            await self.synchronizer.sentTransactions
        }
    }

    public func receivedTransactions() -> Single<[ZcashTransaction.Received]> {
        executeAction {
            await self.synchronizer.receivedTransactions
        }
    }

    public func paginatedTransactions(of kind: TransactionKind) -> PaginatedTransactionRepository {
        synchronizer.paginatedTransactions(of: kind)
    }

    public func getMemos(for transaction: ZcashTransaction.Overview) -> Single<[Memo]> {
        executeThrowingAction {
            try await self.synchronizer.getMemos(for: transaction)
        }
    }

    public func getMemos(for receivedTransaction: ZcashTransaction.Received) -> Single<[Memo]> {
        executeThrowingAction {
            try await self.synchronizer.getMemos(for: receivedTransaction)
        }
    }

    public func getMemos(for sentTransaction: ZcashTransaction.Sent) -> Single<[Memo]> {
        executeThrowingAction {
            try await self.synchronizer.getMemos(for: sentTransaction)
        }
    }

    public func getRecipients(for transaction: ZcashTransaction.Overview) -> Single<[TransactionRecipient]> {
        executeAction {
            await self.synchronizer.getRecipients(for: transaction)
        }
    }

    public func getRecipients(for transaction: ZcashTransaction.Sent) -> Single<[TransactionRecipient]> {
        executeAction {
            await self.synchronizer.getRecipients(for: transaction)
        }
    }

    public func allConfirmedTransactions(
            from transaction: ZcashTransaction.Overview,
            limit: Int
    ) -> Single<[ZcashTransaction.Overview]> {
        executeThrowingAction {
            try await self.synchronizer.allConfirmedTransactions(from: transaction, limit: limit)
        }
    }

    public func latestHeight() -> Single<BlockHeight> {
        executeThrowingAction {
            try await self.synchronizer.latestHeight()
        }
    }

    public func refreshUTXOs(address: TransparentAddress, from height: BlockHeight) -> Single<RefreshedUTXOs> {
        executeThrowingAction {
            try await self.synchronizer.refreshUTXOs(address: address, from: height)
        }
    }

    public func getTransparentBalance(accountIndex: Int) -> Single<WalletBalance> {
        executeThrowingAction {
            try await self.synchronizer.getTransparentBalance(accountIndex: accountIndex)
        }
    }

    public func getShieldedBalance(accountIndex: Int = 0) -> Zatoshi {
        synchronizer.getShieldedBalance(accountIndex: accountIndex)
    }

    public func getShieldedVerifiedBalance(accountIndex: Int = 0) -> Zatoshi {
        synchronizer.getShieldedVerifiedBalance(accountIndex: accountIndex)
    }

    /*
     It can be missleading that these two methods are returning Publisher even this protocol is closure based. Reason is that Synchronizer doesn't
     provide different implementations for these two methods. So Combine it is even here.
     */
    public func rewind(_ policy: RewindPolicy) -> Single<()> {
        Single.create { [weak self] observer in
            var cancellables = self?.cancellables ?? [AnyCancellable]()
            self?.synchronizer.rewind(policy)
                    .sink(
                            receiveCompletion: { result in
                                switch result {
                                case .finished:
                                    observer(.success(()))
                                case let .failure(error):
                                    observer(.error(error))
                                }
                            },
                            receiveValue: {  _ in }
                    )
                    .store(in: &cancellables)

            return Disposables.create()
        }
    }

    public func wipe() -> Single<()> {
        Single.create { [weak self] observer in
            var cancellables = self?.cancellables ?? [AnyCancellable]()
            self?.synchronizer.wipe()
                    .sink(
                            receiveCompletion: { result in
                                switch result {
                                case .finished:
                                    observer(.success(()))
                                case let .failure(error):
                                    observer(.error(error))
                                }
                            },
                            receiveValue: {  _ in }
                    )
                    .store(in: &cancellables)

            return Disposables.create()
        }
    }

}

extension RxSDKSynchronizer {
    private func executeAction(action: @escaping () async -> Void) -> Single<()> {
        Single.create { observer in
            Task {
                await action()
                observer(.success(()))
            }
            return Disposables.create()
        }
    }

    private func executeAction<R>(action: @escaping () async -> R) -> Single<R> {
        Single.create { observer in
            Task {
                let result = await action()
                observer(.success(result))
            }
            return Disposables.create()
        }
    }

    private func executeThrowingAction(action: @escaping () async throws -> Void) -> Single<()> {
        Single.create { observer in
            Task {
                do {
                    try await action()
                    observer(.success(()))
                } catch {
                    observer(.error(error))
                }
            }
            return Disposables.create()
        }
    }

    private func executeThrowingAction<R>(action: @escaping () async throws -> R) -> Single<R> {
        Single.create { observer in
            Task {
                do {
                    let result = try await action()
                    observer(.success(result))
                } catch {
                    observer(.error(error))
                }
            }
            return Disposables.create()
        }
    }

}
