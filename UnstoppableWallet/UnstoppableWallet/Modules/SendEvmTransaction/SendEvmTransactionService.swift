import BigInt
import EvmKit
import Foundation
import MarketKit
import OneInchKit
import RxCocoa
import RxSwift
import UniswapKit

protocol ISendEvmTransactionService {
    var state: SendEvmTransactionService.State { get }
    var stateObservable: Observable<SendEvmTransactionService.State> { get }

    var dataState: SendEvmTransactionService.DataState { get }

    var sendState: SendEvmTransactionService.SendState { get }
    var sendStateObservable: Observable<SendEvmTransactionService.SendState> { get }

    var ownAddress: EvmKit.Address { get }

    func methodName(input: Data) -> String?
    func send()
}

class SendEvmTransactionService {
    private let disposeBag = DisposeBag()

    private let sendData: SendEvmData
    private let evmKitWrapper: EvmKitWrapper
    private let settingsService: EvmSendSettingsService
    private let evmLabelManager: EvmLabelManager

    private let stateRelay = PublishRelay<State>()
    private(set) var state: State = .notReady(errors: [], warnings: []) {
        didSet {
            stateRelay.accept(state)
        }
    }

    private(set) var dataState: DataState

    private let sendStateRelay = PublishRelay<SendState>()
    private(set) var sendState: SendState = .idle {
        didSet {
            sendStateRelay.accept(sendState)
        }
    }

    init(sendData: SendEvmData, evmKitWrapper: EvmKitWrapper, settingsService: EvmSendSettingsService, evmLabelManager: EvmLabelManager) {
        self.sendData = sendData
        self.evmKitWrapper = evmKitWrapper
        self.settingsService = settingsService
        self.evmLabelManager = evmLabelManager

        dataState = DataState(
            transactionData: sendData.transactionData,
            additionalInfo: sendData.additionalInfo,
            decoration: evmKitWrapper.evmKit.decorate(transactionData: sendData.transactionData),
            nonce: settingsService.nonceService.frozen ? settingsService.nonceService.nonce : nil
        )

        subscribe(disposeBag, settingsService.statusObservable) { [weak self] in self?.sync(status: $0) }
    }

    private var evmKit: EvmKit.Kit {
        evmKitWrapper.evmKit
    }

    private var evmBalance: BigUInt {
        evmKit.accountState?.balance ?? 0
    }

    private func sync(status: DataStatus<FallibleData<EvmSendSettingsService.Transaction>>) {
        switch status {
        case .loading:
            state = .notReady(errors: [], warnings: [])
        case let .failed(error):
            syncDataState()
            state = .notReady(errors: [error], warnings: [])
        case let .completed(fallibleTransaction):
            syncDataState(transaction: fallibleTransaction.data)

            let warnings = sendData.warnings + fallibleTransaction.warnings
            let errors = sendData.errors + fallibleTransaction.errors
            if errors.isEmpty {
                state = .ready(warnings: warnings)
            } else {
                state = .notReady(errors: errors, warnings: warnings)
            }
        }
    }

    private func syncDataState(transaction: EvmSendSettingsService.Transaction? = nil) {
        let transactionData = transaction?.transactionData ?? sendData.transactionData

        dataState = DataState(
            transactionData: transactionData,
            additionalInfo: sendData.additionalInfo,
            decoration: evmKit.decorate(transactionData: transactionData),
            nonce: settingsService.nonceService.frozen ? settingsService.nonceService.nonce : nil
        )
    }
}

extension SendEvmTransactionService: ISendEvmTransactionService {
    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    var sendStateObservable: Observable<SendState> {
        sendStateRelay.asObservable()
    }

    var ownAddress: EvmKit.Address {
        evmKit.receiveAddress
    }

    var blockchainType: BlockchainType {
        evmKitWrapper.blockchainType
    }

    func methodName(input: Data) -> String? {
        evmLabelManager.methodLabel(input: input)
    }

    func send() {
        guard case .ready = state, case let .completed(fallibleTransaction) = settingsService.status else {
            return
        }
        let transaction = fallibleTransaction.data

        sendState = .sending

        evmKitWrapper.sendSingle(
            transactionData: transaction.transactionData,
            gasPrice: transaction.gasData.price,
            gasLimit: transaction.gasData.limit,
            nonce: transaction.nonce
        )
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
        .subscribe(onSuccess: { [weak self] fullTransaction in
            self?.sendState = .sent(transactionHash: fullTransaction.transaction.hash)
        }, onError: { error in
            self.sendState = .failed(error: error)
        })
        .disposed(by: disposeBag)
    }
}

extension SendEvmTransactionService {
    enum State {
        case ready(warnings: [Warning])
        case notReady(errors: [Error], warnings: [Warning])
    }

    struct DataState {
        let transactionData: TransactionData?
        let additionalInfo: SendEvmData.AdditionInfo?
        var decoration: TransactionDecoration?
        let nonce: Int?
    }

    enum SendState {
        case idle
        case sending
        case sent(transactionHash: Data)
        case failed(error: Error)
    }

    enum TransactionError: Error {
        case noTransactionData
        case insufficientBalance(requiredBalance: BigUInt)
    }
}
