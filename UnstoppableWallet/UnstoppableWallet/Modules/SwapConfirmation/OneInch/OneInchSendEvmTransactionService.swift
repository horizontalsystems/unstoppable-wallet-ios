import Foundation
import RxSwift
import RxCocoa
import EthereumKit
import BigInt
import CoinKit
import OneInchKit
import UniswapKit

import EthereumKit
import BigInt

class OneInchSendEvmTransactionService {
    private let disposeBag = DisposeBag()

    private let evmKit: EthereumKit.Kit
    private let transactionFeeService: OneInchTransactionFeeService
    private let activateCoinManager: ActivateCoinManager

    private let stateRelay = PublishRelay<SendEvmTransactionService.State>()
    private(set) var state: SendEvmTransactionService.State = .notReady(errors: []) {
        didSet {
            stateRelay.accept(state)
        }
    }

    private let dataStateRelay = PublishRelay<DataStatus<SendEvmTransactionService.DataState>>()
    private(set) var dataState: DataStatus<SendEvmTransactionService.DataState> = .failed(SendEvmTransactionService.TransactionError.noTransactionData) {
        didSet {
            dataStateRelay.accept(dataState)
        }
    }

    private let sendStateRelay = PublishRelay<SendEvmTransactionService.SendState>()
    private(set) var sendState: SendEvmTransactionService.SendState = .idle {
        didSet {
            sendStateRelay.accept(sendState)
        }
    }

    init(evmKit: EthereumKit.Kit, transactionFeeService: OneInchTransactionFeeService, activateCoinManager: ActivateCoinManager) {
        self.evmKit = evmKit
        self.transactionFeeService = transactionFeeService
        self.activateCoinManager = activateCoinManager

        subscribe(disposeBag, transactionFeeService.transactionStatusObservable) { [weak self] _ in self?.syncState() }

        // show initial info from parameters
        dataState = .completed(
                        SendEvmTransactionService.DataState(
                                transactionData: nil,
                                additionalInfo: additionalInfo(parameters: transactionFeeService.parameters),
                                decoration: swapDecoration(parameters: transactionFeeService.parameters)
                        )
        )
    }

    private var evmBalance: BigUInt {
        evmKit.accountState?.balance ?? 0
    }

    private func syncState() {
        switch transactionFeeService.transactionStatus {
        case .loading:
            state = .notReady(errors: [])
        case .failed(let error):
            state = .notReady(errors: [error])
            syncDataState()
        case .completed(let transaction):
            if transaction.totalAmount > evmBalance {
                state = .notReady(errors: [SendEvmTransactionService.TransactionError.insufficientBalance(requiredBalance: transaction.totalAmount)])
            } else {
                state = .ready
            }
            syncDataState()
        }
    }

    private func syncDataState() {
        switch transactionFeeService.transactionStatus {
        case .loading:
            dataState = .loading
        case .failed(let error):
            dataState = .failed(error)
        case .completed(let transaction):
                dataState = .completed(
                        SendEvmTransactionService.DataState(
                                transactionData: transaction.data,
                                additionalInfo: additionalInfo(parameters: transactionFeeService.parameters),
                                decoration: swapDecoration(parameters: transactionFeeService.parameters)
                        )
                )
        }
    }


    private func formatted(slippage: Decimal) -> String? {
        guard slippage != OneInchSettingsService.defaultSlippage else {
            return nil
        }

        return "\(slippage)%"
    }

    private func additionalInfo(parameters: OneInchSwapParameters) -> SendEvmData.AdditionInfo {
        let swapInfo = SendEvmData.SwapInfo(
                estimatedOut: parameters.amountTo,
                estimatedIn: parameters.amountFrom,
                slippage: formatted(slippage: parameters.slippage),
                deadline: nil,
                recipientDomain: parameters.recipient?.domain,
                price: nil,
                priceImpact: nil)

        return .swap(info: swapInfo)
    }

    private func swapToken(coin: Coin) -> SwapMethodDecoration.Token? {
        switch coin.type {
        case .ethereum, .binanceSmartChain: return .evmCoin
        case .erc20(let address): return (try? EthereumKit.Address(hex: address)).map { .eip20Coin(address: $0) }
        case .bep20(let address): return (try? EthereumKit.Address(hex: address)).map { .eip20Coin(address: $0) }
        default: return nil
        }
    }

    private func swapDecoration(parameters: OneInchSwapParameters) -> ContractMethodDecoration? {
        let amountOutMinDecimal = parameters.amountTo * (1 - parameters.slippage / 100)
        guard
            let amountIn = BigUInt((parameters.amountFrom * pow(10, parameters.coinFrom.decimal)).description),
            let amountOutMin = BigUInt((amountOutMinDecimal * pow(10, parameters.coinTo.decimal)).roundedString(decimal: 0)),
            let tokenIn = swapToken(coin: parameters.coinFrom),
            let tokenOut = swapToken(coin: parameters.coinTo) else {

            return nil
        }

        let trade = SwapMethodDecoration.Trade.exactIn(amountIn: amountIn, amountOutMin: amountOutMin)
        return SwapMethodDecoration(
                trade: trade,
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                to: parameters.recipient.flatMap { try? EthereumKit.Address(hex: $0.raw) } ?? evmKit.receiveAddress,
                deadline: 0
        )
    }

    private func handlePostSendActions() {
        if let decoration = dataState.data?.decoration as? SwapMethodDecoration {
            activateSwapCoinOut(tokenOut: decoration.tokenOut)
        }
    }

    private func activateSwapCoinOut(tokenOut: SwapMethodDecoration.Token) {
        let coinType: CoinType

        switch tokenOut {
        case .evmCoin:
            switch evmKit.networkType {
            case .ethMainNet, .ropsten, .rinkeby, .kovan, .goerli: coinType = .ethereum
            case .bscMainNet: coinType = .binanceSmartChain
            }
        case .eip20Coin(let address):
            switch evmKit.networkType {
            case .ethMainNet, .ropsten, .rinkeby, .kovan, .goerli: coinType = .erc20(address: address.hex)
            case .bscMainNet: coinType = .bep20(address: address.hex)
            }
        }

        activateCoinManager.activate(coinType: coinType)
    }

}

extension OneInchSendEvmTransactionService: ISendEvmTransactionService {

    var stateObservable: Observable<SendEvmTransactionService.State> {
        stateRelay.asObservable()
    }

    var dataStateObservable: Observable<DataStatus<SendEvmTransactionService.DataState>> {
        dataStateRelay.asObservable()
    }

    var sendStateObservable: Observable<SendEvmTransactionService.SendState> {
        sendStateRelay.asObservable()
    }

    var ownAddress: EthereumKit.Address {
        evmKit.receiveAddress
    }

    func send() {
        guard case .ready = state, case .completed(let transaction) = transactionFeeService.transactionStatus else {
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
