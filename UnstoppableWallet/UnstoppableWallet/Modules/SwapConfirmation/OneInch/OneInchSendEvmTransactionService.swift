import Foundation
import RxSwift
import RxCocoa
import EthereumKit
import BigInt
import MarketKit
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
                            transactionData: transaction.transactionData,
                            additionalInfo: additionalInfo(parameters: transactionFeeService.parameters),
                            decoration: evmKit.decorate(transactionData: transaction.transactionData)
                    )
            )
        }
    }

    private func additionalInfo(parameters: OneInchSwapParameters) -> SendEvmData.AdditionInfo {
        .oneInchSwap(info:
            SendEvmData.OneInchSwapInfo(
                platformCoinFrom: parameters.platformCoinFrom,
                platformCoinTo: parameters.platformCoinTo,
                amountFrom: parameters.amountFrom,
                estimatedAmountTo: parameters.amountTo,
                slippage: parameters.slippage,
                recipient: parameters.recipient
            )
        )
    }

    private func swapToken(platformCoin: PlatformCoin) -> OneInchMethodDecoration.Token? {
        switch platformCoin.coinType {
        case .ethereum, .binanceSmartChain: return .evmCoin
        case .erc20(let address): return (try? EthereumKit.Address(hex: address)).map { .eip20Coin(address: $0) }
        case .bep20(let address): return (try? EthereumKit.Address(hex: address)).map { .eip20Coin(address: $0) }
        default: return nil
        }
    }

    private func swapDecoration(parameters: OneInchSwapParameters) -> ContractMethodDecoration? {
        let amountOutMinDecimal = parameters.amountTo * (1 - parameters.slippage / 100)
        guard
            let amountIn = BigUInt((parameters.amountFrom * pow(10, parameters.platformCoinFrom.decimals)).roundedString(decimal: 0)),
            let amountOutMin = BigUInt((amountOutMinDecimal * pow(10, parameters.platformCoinTo.decimals)).roundedString(decimal: 0)),
            let amountOut = BigUInt((parameters.amountTo * pow(10, parameters.platformCoinTo.decimals)).roundedString(decimal: 0)),
            let tokenIn = swapToken(platformCoin: parameters.platformCoinFrom),
            let tokenOut = swapToken(platformCoin: parameters.platformCoinTo) else {

            return nil
        }

        if let recipient = parameters.recipient,
           let address = try? EthereumKit.Address(hex: recipient.raw) {
            return OneInchSwapMethodDecoration(
                    tokenIn: tokenIn,
                    tokenOut: tokenOut,
                    amountIn: amountIn,
                    amountOutMin: amountOutMin,
                    amountOut: amountOut,
                    flags: 0,
                    permit: Data(),
                    data: Data(),
                    recipient: address)
        } else {
            return OneInchUnoswapMethodDecoration(
                    tokenIn: tokenIn,
                    tokenOut: tokenOut,
                    amountIn: amountIn,
                    amountOutMin: amountOutMin,
                    amountOut: amountOut,
                    params: [])
        }
    }

    private func handlePostSendActions() {
        if let decoration = dataState.data?.decoration as? OneInchUnoswapMethodDecoration, let tokenOut = decoration.tokenOut {
            activateSwapCoinOut(tokenOut: tokenOut)
        }
        if let decoration = dataState.data?.decoration as? OneInchSwapMethodDecoration {
            activateSwapCoinOut(tokenOut: decoration.tokenOut)
        }
    }

    private func activateSwapCoinOut(tokenOut: OneInchMethodDecoration.Token) {
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
                        transactionData: transaction.transactionData,
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
