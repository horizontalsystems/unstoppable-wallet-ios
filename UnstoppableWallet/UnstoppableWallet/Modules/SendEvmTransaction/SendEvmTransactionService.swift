import Foundation
import RxSwift
import RxCocoa
import EthereumKit
import BigInt
import MarketKit
import UniswapKit
import OneInchKit

protocol ISendEvmTransactionService {
    var state: SendEvmTransactionService.State { get }
    var stateObservable: Observable<SendEvmTransactionService.State> { get }

    var dataState: DataStatus<SendEvmTransactionService.DataState> { get }
    var dataStateObservable: Observable<DataStatus<SendEvmTransactionService.DataState>> { get }

    var sendState: SendEvmTransactionService.SendState { get }
    var sendStateObservable: Observable<SendEvmTransactionService.SendState> { get }

    var ownAddress: EthereumKit.Address { get }

    func send()
}

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

    private let dataStateRelay = PublishRelay<DataStatus<DataState>>()
    private(set) var dataState: DataStatus<DataState> {
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

        dataState = .completed(
                DataState(
                        transactionData: sendData.transactionData,
                        additionalInfo: sendData.additionalInfo,
                        decoration: evmKit.decorate(transactionData: sendData.transactionData)
                )
        )

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
        let transactionData = transaction?.transactionData ?? sendData.transactionData

        dataState = .completed(
                DataState(
                        transactionData: transactionData,
                        additionalInfo: sendData.additionalInfo,
                        decoration: evmKit.decorate(transactionData: transactionData)
                )
        )
    }

    private func handlePostSendActions() {
        if let decoration = dataState.data?.decoration as? SwapMethodDecoration {
            activateUniswap(token: decoration.tokenIn)
            activateUniswap(token: decoration.tokenOut)
        }

        if let decoration = dataState.data?.decoration as? OneInchMethodDecoration {
            var tokens = [OneInchMethodDecoration.Token]()

            switch decoration {
            case let method as OneInchUnoswapMethodDecoration:
                tokens = [method.tokenIn, method.tokenOut].compactMap { $0 }
            case let method as OneInchSwapMethodDecoration:
                tokens = [method.tokenIn, method.tokenOut].compactMap { $0 }
            default: ()
            }

            tokens.forEach { activateOneInch(token: $0) }
        }
    }

    private func activateUniswap(token: SwapMethodDecoration.Token) {
        switch token {
        case .evmCoin: activateCoinManager.activate(coinType: evmCoinType())
        case .eip20Coin(let address): activateCoinManager.activate(coinType: eip20CoinType(contractAddress: address.hex))
        }
    }

    private func activateOneInch(token: OneInchMethodDecoration.Token) {
        switch token {
        case .evmCoin: activateCoinManager.activate(coinType: evmCoinType())
        case .eip20Coin(let address): activateCoinManager.activate(coinType: eip20CoinType(contractAddress: address.hex))
        }
    }

    private func eip20CoinType(contractAddress: String) -> CoinType {
        switch evmKit.networkType {
            case .ethMainNet, .ropsten, .rinkeby, .kovan, .goerli: return .erc20(address: contractAddress)
            case .bscMainNet: return .bep20(address: contractAddress)
        }
    }

    private func evmCoinType() -> CoinType {
        switch evmKit.networkType {
        case .ethMainNet, .ropsten, .rinkeby, .kovan, .goerli: return .ethereum
        case .bscMainNet: return .binanceSmartChain
        }
    }

}

extension SendEvmTransactionService: ISendEvmTransactionService {

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    var dataStateObservable: Observable<DataStatus<DataState>> {
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
                        transactionData: transaction.transactionData,
                        gasPrice: transaction.gasData.gasPrice,
                        gasLimit: transaction.gasData.gasLimit,
                        nonce: transaction.transactionData.nonce
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
        let transactionData: TransactionData?
        let additionalInfo: SendEvmData.AdditionInfo?
        var decoration: ContractMethodDecoration?
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
