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

    private let evmKitWrapper: EvmKitWrapper
    private let transactionFeeService: OneInchFeeService
    private let activateCoinManager: ActivateCoinManager

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

    init(evmKitWrapper: EvmKitWrapper, transactionFeeService: OneInchFeeService, activateCoinManager: ActivateCoinManager) {
        self.evmKitWrapper = evmKitWrapper
        self.transactionFeeService = transactionFeeService
        self.activateCoinManager = activateCoinManager

        subscribe(disposeBag, transactionFeeService.statusObservable) { [weak self] in self?.sync(status: $0) }

        // show initial info from parameters
        dataState = SendEvmTransactionService.DataState(
                transactionData: nil,
                additionalInfo: additionalInfo(parameters: transactionFeeService.parameters),
                decoration: swapDecoration(parameters: transactionFeeService.parameters)
        )
    }

    private var evmKit: EthereumKit.Kit {
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
        case .ethereum, .binanceSmartChain, .polygon: return .evmCoin
        case .erc20(let address): return (try? EthereumKit.Address(hex: address)).map { .eip20Coin(address: $0) }
        case .bep20(let address): return (try? EthereumKit.Address(hex: address)).map { .eip20Coin(address: $0) }
        case .mrc20(let address): return (try? EthereumKit.Address(hex: address)).map { .eip20Coin(address: $0) }
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
        if let decoration = dataState.decoration as? OneInchUnoswapMethodDecoration, let tokenOut = decoration.tokenOut {
            activateSwapCoinOut(tokenOut: tokenOut)
        }
        if let decoration = dataState.decoration as? OneInchSwapMethodDecoration {
            activateSwapCoinOut(tokenOut: decoration.tokenOut)
        }
    }

    private func activateSwapCoinOut(tokenOut: OneInchMethodDecoration.Token) {
        switch tokenOut {
        case .evmCoin: activateCoinManager.activateBaseCoin(blockchain: evmKitWrapper.blockchain)
        case .eip20Coin(let address): activateCoinManager.activateEvm20Coin(address: address.hex, blockchain: evmKitWrapper.blockchain)
        }
    }

}

extension OneInchSendEvmTransactionService: ISendEvmTransactionService {

    var stateObservable: Observable<SendEvmTransactionService.State> {
        stateRelay.asObservable()
    }

    var sendStateObservable: Observable<SendEvmTransactionService.SendState> {
        sendStateRelay.asObservable()
    }

    var ownAddress: EthereumKit.Address {
        evmKit.receiveAddress
    }

    func send() {
        guard case .ready = state, case .completed(let fallibleTransaction) = transactionFeeService.status else {
            return
        }
        let transaction = fallibleTransaction.data

        sendState = .sending

        evmKitWrapper.sendSingle(
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
