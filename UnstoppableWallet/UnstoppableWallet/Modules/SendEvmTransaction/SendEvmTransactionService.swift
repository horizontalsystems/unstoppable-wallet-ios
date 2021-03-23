import Foundation
import RxSwift
import RxCocoa
import EthereumKit
import BigInt
import CoinKit

class SendEvmTransactionService {
    private let disposeBag = DisposeBag()

    private let sendData: SendEvmData
    private let evmKit: EthereumKit.Kit
    private let transactionService: EvmTransactionService
    private let activateCoinManager: ActivateCoinManager

    private let stateRelay = PublishRelay<State>()
    private(set) var state: State = .notReady(errors: []) {
        didSet {
            stateRelay.accept(state)
        }
    }

    private let dataStateRelay = PublishRelay<DataState>()
    private(set) var dataState: DataState {
        didSet {
            dataStateRelay.accept(dataState)
        }
    }

    private let sendStateRelay = PublishRelay<SendState>()
    private(set) var sendState: SendState = .idle {
        didSet {
            sendStateRelay.accept(sendState)
        }
    }

    init(sendData: SendEvmData, gasPrice: Int? = nil, evmKit: EthereumKit.Kit, transactionService: EvmTransactionService, activateCoinManager: ActivateCoinManager) {
        self.sendData = sendData
        self.evmKit = evmKit
        self.transactionService = transactionService
        self.activateCoinManager = activateCoinManager

        dataState = DataState(transactionData: sendData.transactionData, additionalInfo: sendData.additionalInfo, decoration: evmKit.decorate(transactionData: sendData.transactionData))

        subscribe(disposeBag, transactionService.transactionStatusObservable) { [weak self] _ in self?.syncState() }

        transactionService.set(transactionData: sendData.transactionData)

        if let gasPrice = gasPrice {
            transactionService.set(gasPriceType: .custom(gasPrice: gasPrice))
        }
    }

    private var evmBalance: BigUInt {
        evmKit.accountState?.balance ?? 0
    }

    private func syncState() {
        switch transactionService.transactionStatus {
        case .loading:
            state = .notReady(errors: [])
        case .failed(let error):
            state = .notReady(errors: [error])
            syncDataState()
        case .completed(let transaction):
            if transaction.totalAmount > evmBalance {
                state = .notReady(errors: [TransactionError.insufficientBalance(requiredBalance: transaction.totalAmount)])
            } else {
                state = .ready
            }
            syncDataState(transaction: transaction)
        }
    }

    private func syncDataState(transaction: EvmTransactionService.Transaction? = nil) {
        let transactionData = transaction?.data ?? sendData.transactionData

        dataState = DataState(
                transactionData: transactionData,
                additionalInfo: sendData.additionalInfo,
                decoration: evmKit.decorate(transactionData: transactionData)
        )
    }

    private func handlePostSendActions() {
        if let decoration = dataState.decoration, case .swap(_, _, let tokenOut, _, _) = decoration {
            activateSwapCoinOut(tokenOut: tokenOut)
        }
    }

    private func activateSwapCoinOut(tokenOut: TransactionDecoration.Token) {
        let coinType: CoinType

        switch tokenOut {
        case .evmCoin:
            switch evmKit.networkType {
            case .ethMainNet, .kovan, .ropsten: coinType = .ethereum
            case .bscMainNet: coinType = .binanceSmartChain
            }
        case .eip20Coin(let address):
            switch evmKit.networkType {
            case .ethMainNet, .kovan, .ropsten: coinType = .erc20(address: address.hex)
            case .bscMainNet: coinType = .bep20(address: address.hex)
            }
        }

        activateCoinManager.activate(coinType: coinType)
    }

}

extension SendEvmTransactionService {

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    var dataStateObservable: Observable<DataState> {
        dataStateRelay.asObservable()
    }

    var sendStateObservable: Observable<SendState> {
        sendStateRelay.asObservable()
    }

    var ownAddress: EthereumKit.Address {
        evmKit.receiveAddress
    }

    func send() {
        guard case .ready = state, case .completed(let transaction) = transactionService.transactionStatus else {
            return
        }

        sendState = .sending

        evmKit.sendSingle(
                        transactionData: transaction.data,
                        gasPrice: transaction.gasData.gasPrice,
                        gasLimit: transaction.gasData.gasLimit
                )
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] fullTransaction in
                    self?.handlePostSendActions()
                    self?.sendState = .sent(transactionHash: fullTransaction.transaction.hash)
                }, onError: { error in
                    self.sendState = .failed(error: error)
                })
                .disposed(by: disposeBag)
    }

}

extension SendEvmTransactionService {

    enum State {
        case ready
        case notReady(errors: [Error])
    }

    struct DataState {
        let transactionData: TransactionData
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
        case insufficientBalance(requiredBalance: BigUInt)
    }

}
