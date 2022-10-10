import Foundation
import RxSwift
import RxCocoa
import EvmKit
import BigInt
import MarketKit
import OneInchKit
import UniswapKit
import EvmKit
import BigInt

class OneInchSendEvmTransactionService {
    private let disposeBag = DisposeBag()

    private let evmKitWrapper: EvmKitWrapper
    private let transactionFeeService: OneInchFeeService

    private let stateRelay = PublishRelay<SendEvmTransactionService.State>()
    private(set) var state: SendEvmTransactionService.State = .notReady(errors: [], warnings: []) {
        didSet {
            stateRelay.accept(state)
        }
    }

    private(set) var dataState: SendEvmTransactionService.DataState = SendEvmTransactionService.DataState(transactionData: nil, additionalInfo: nil, decoration: nil)

    private let sendStateRelay = PublishRelay<SendEvmTransactionService.SendState>()
    private(set) var sendState: SendEvmTransactionService.SendState = .idle {
        didSet {
            sendStateRelay.accept(sendState)
        }
    }

    init(evmKitWrapper: EvmKitWrapper, transactionFeeService: OneInchFeeService) {
        self.evmKitWrapper = evmKitWrapper
        self.transactionFeeService = transactionFeeService

        subscribe(disposeBag, transactionFeeService.statusObservable) { [weak self] in self?.sync(status: $0) }

        // show initial info from parameters
        dataState = SendEvmTransactionService.DataState(
                transactionData: nil,
                additionalInfo: additionalInfo(parameters: transactionFeeService.parameters),
                decoration: nil
        )
    }

    private var evmKit: EvmKit.Kit {
        evmKitWrapper.evmKit
    }

    private func sync(status: DataStatus<FallibleData<EvmFeeModule.Transaction>>) {
        switch status {
        case .loading:
            state = .notReady(errors: [], warnings: [])
        case .failed(let error):
            state = .notReady(errors: [error], warnings: [])
        case .completed(let fallibleTransaction):
            let transaction = fallibleTransaction.data

            dataState = SendEvmTransactionService.DataState(
                    transactionData: transaction.transactionData,
                    additionalInfo: additionalInfo(parameters: transactionFeeService.parameters),
                    decoration: evmKit.decorate(transactionData: transaction.transactionData)
            )

            if fallibleTransaction.errors.isEmpty {
                state = .ready(warnings: fallibleTransaction.warnings)
            } else {
                state = .notReady(errors: fallibleTransaction.errors, warnings: fallibleTransaction.warnings)
            }
        }
    }

    private func additionalInfo(parameters: OneInchSwapParameters) -> SendEvmData.AdditionInfo {
        .oneInchSwap(info:
            SendEvmData.OneInchSwapInfo(
                tokenFrom: parameters.tokenFrom,
                tokenTo: parameters.tokenTo,
                amountFrom: parameters.amountFrom,
                estimatedAmountTo: parameters.amountTo,
                slippage: parameters.slippage,
                recipient: parameters.recipient
            )
        )
    }

}

extension OneInchSendEvmTransactionService: ISendEvmTransactionService {

    var stateObservable: Observable<SendEvmTransactionService.State> {
        stateRelay.asObservable()
    }

    var sendStateObservable: Observable<SendEvmTransactionService.SendState> {
        sendStateRelay.asObservable()
    }

    var ownAddress: EvmKit.Address {
        evmKit.receiveAddress
    }

    func methodName(input: Data) -> String? {
        nil
    }

    func send() {
        guard case .ready = state, case .completed(let fallibleTransaction) = transactionFeeService.status else {
            return
        }
        let transaction = fallibleTransaction.data

        sendState = .sending

        evmKitWrapper.sendSingle(
                        transactionData: transaction.transactionData,
                        gasPrice: transaction.gasData.price,
                        gasLimit: transaction.gasData.limit
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
