import Foundation
import RxSwift
import RxCocoa
import EvmKit
import BigInt
import MarketKit
import UniswapKit
import OneInchKit

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
    private let feeService: EvmFeeService
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

    init(sendData: SendEvmData, evmKitWrapper: EvmKitWrapper, feeService: EvmFeeService, evmLabelManager: EvmLabelManager) {
        self.sendData = sendData
        self.evmKitWrapper = evmKitWrapper
        self.feeService = feeService
        self.evmLabelManager = evmLabelManager

        dataState = DataState(
                transactionData: sendData.transactionData,
                additionalInfo: sendData.additionalInfo,
                decoration: evmKitWrapper.evmKit.decorate(transactionData: sendData.transactionData)
        )

        subscribe(disposeBag, feeService.statusObservable) { [weak self] in self?.sync(status: $0) }
    }

    private var evmKit: EvmKit.Kit {
        evmKitWrapper.evmKit
    }

    private var evmBalance: BigUInt {
        evmKit.accountState?.balance ?? 0
    }

    private func sync(status: DataStatus<FallibleData<EvmFeeModule.Transaction>>) {
        switch status {
        case .loading:
            state = .notReady(errors: [], warnings: [])
        case .failed(let error):
            syncDataState()
            state = .notReady(errors: [error], warnings: [])
        case .completed(let fallibleTransaction):
            syncDataState(transaction: fallibleTransaction.data)

            let warnings = sendData.warnings + fallibleTransaction.warnings

            if fallibleTransaction.errors.isEmpty {
                state = .ready(warnings: warnings)
            } else {
                state = .notReady(errors: fallibleTransaction.errors, warnings: warnings)
            }
        }
    }

    private func syncDataState(transaction: EvmFeeModule.Transaction? = nil) {
        let transactionData = transaction?.transactionData ?? sendData.transactionData

        dataState = DataState(
                transactionData: transactionData,
                additionalInfo: sendData.additionalInfo,
                decoration: evmKit.decorate(transactionData: transactionData)
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

    func methodName(input: Data) -> String? {
        evmLabelManager.methodLabel(input: input)
    }

    func send() {
        guard case .ready = state, case .completed(let fallibleTransaction) = feeService.status else {
            return
        }
        let transaction = fallibleTransaction.data

        sendState = .sending

        evmKitWrapper.sendSingle(
                        transactionData: transaction.transactionData,
                        gasPrice: transaction.gasData.price,
                        gasLimit: transaction.gasData.limit,
                        nonce: transaction.transactionData.nonce
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
