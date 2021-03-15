import Foundation
import RxSwift
import RxCocoa
import EthereumKit
import BigInt
import UniswapKit

class SendEvmTransactionViewModel {
    private let disposeBag = DisposeBag()

    private let service: SendEvmTransactionService
    private let coinServiceFactory: EvmCoinServiceFactory

    private(set) var viewItems = [ViewItem]()

    private let sendEnabledRelay = BehaviorRelay<Bool>(value: false)
    private let errorRelay = BehaviorRelay<String?>(value: nil)

    private let sendingRelay = PublishRelay<()>()
    private let sendSuccessRelay = PublishRelay<Data>()
    private let sendFailedRelay = PublishRelay<String>()

    init(service: SendEvmTransactionService, coinServiceFactory: EvmCoinServiceFactory) {
        self.service = service
        self.coinServiceFactory = coinServiceFactory

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }
        subscribe(disposeBag, service.sendStateObservable) { [weak self] in self?.sync(sendState: $0) }

        sync(state: service.state)
        sync(sendState: service.sendState)

        syncViewItems()
    }

    private func sync(state: SendEvmTransactionService.State) {
        if case .ready = state {
            sendEnabledRelay.accept(true)
        } else {
            sendEnabledRelay.accept(false)
        }

        if case .notReady(let errors) = state {
            errorRelay.accept(errors.first.map { convert(error: $0) })
        } else {
            errorRelay.accept(nil)
        }
    }

    private func sync(sendState: SendEvmTransactionService.SendState) {
        switch sendState {
        case .idle: ()
        case .sending: sendingRelay.accept(())
        case .sent(let transactionHash): sendSuccessRelay.accept(transactionHash)
        case .failed(let error): sendFailedRelay.accept(error.convertedError.smartDescription)
        }
    }

    private func convert(error: Error) -> String {
        if case SendEvmTransactionService.TransactionError.insufficientBalance(let requiredBalance) = error {
            let amountData = coinServiceFactory.baseCoinService.amountData(value: requiredBalance)
            return "ethereum_transaction.error.insufficient_balance".localized(amountData.formattedString)
        }

        if case AppError.ethereum(let reason) = error.convertedError {
            switch reason {
            case .insufficientBalanceWithFee, .executionReverted: return "ethereum_transaction.error.insufficient_balance_with_fee".localized(coinServiceFactory.baseCoinService.coin.code)
            default: ()
            }
        }

        return error.convertedError.smartDescription
    }

    private func syncViewItems() {
        if let decoration = service.decoration, let viewItems = viewItems(decoration: decoration) {
            self.viewItems = viewItems
        } else {
            viewItems = fallbackViewItems(transactionData: service.transactionData)
        }
    }

    private func viewItems(decoration: TransactionDecoration) -> [ViewItem]? {
        switch decoration {
        case let .transfer(from, to, value):
            return transferViewItems(from: from, to: to, value: value)
        case let .eip20Transfer(to, value, contractAddress):
            return eip20TransferViewItems(to: to, value: value, contractAddress: contractAddress)
        case let .eip20Approve(spender, value, contractAddress):
            return eip20ApproveViewItems(spender: spender, value: value, contractAddress: contractAddress)
        case let .swap(trade, tokenIn, tokenOut, to, deadline):
            return swapViewItems(trade: trade, tokenIn: tokenIn, tokenOut: tokenOut, to: to, deadline: deadline)
        default:
            return nil
        }
    }

    private func transferViewItems(from: EthereumKit.Address, to: EthereumKit.Address?, value: BigUInt) -> [ViewItem] {
        var viewItems: [ViewItem] = [
            .amount(amountData: coinServiceFactory.baseCoinService.amountData(value: value))
        ]

        if let domain = service.additionalItems[.domain] {
            viewItems.append(.value(title: "Domain", value: domain))
        }

        if let to = to {
            viewItems.append(.address(title: "Address", value: to.eip55))
        }

        return viewItems
    }

    private func eip20TransferViewItems(to: EthereumKit.Address, value: BigUInt, contractAddress: EthereumKit.Address) -> [ViewItem]? {
        guard let coinService = coinServiceFactory.coinService(contractAddress: contractAddress) else {
            return nil
        }

        var viewItems: [ViewItem] = [
            .amount(amountData: coinService.amountData(value: value))
        ]

        if let domain = service.additionalItems[.domain] {
            viewItems.append(.value(title: "Domain", value: domain))
        }

        viewItems.append(.address(title: "Address", value: to.eip55))

        return viewItems
    }

    private func eip20ApproveViewItems(spender: EthereumKit.Address, value: BigUInt, contractAddress: EthereumKit.Address) -> [ViewItem]? {
        guard let coinService = coinServiceFactory.coinService(contractAddress: contractAddress) else {
            return nil
        }

        return [
            .amount(amountData: coinService.amountData(value: value)),
            .address(title: "Spender", value: spender.eip55)
        ]
    }

    private func swapViewItems(trade: TransactionDecoration.Trade, tokenIn: TransactionDecoration.Token, tokenOut: TransactionDecoration.Token, to: EthereumKit.Address, deadline: BigUInt) -> [ViewItem]? {
        guard let coinServiceIn = coinService(token: tokenIn), let coinServiceOut = coinService(token: tokenOut) else {
            return nil
        }

        var viewItems = [ViewItem]()

        switch trade {
        case let .exactIn(amountIn, amountOutMin):
            viewItems.append(.amount(amountData: coinServiceIn.amountData(value: amountIn)))
            viewItems.append(.amount(amountData: coinServiceOut.amountData(value: amountOutMin)))
        case let .exactOut(amountOut, amountInMax):
            viewItems.append(.amount(amountData: coinServiceIn.amountData(value: amountInMax)))
            viewItems.append(.amount(amountData: coinServiceOut.amountData(value: amountOut)))
        }

        let additionalItems = service.additionalItems

        if let slippage = additionalItems[.swapSlippage] {
            viewItems.append(.value(title: "swap.advanced_settings.slippage".localized, value: slippage))
        }
        if let deadline = additionalItems[.swapDeadline] {
            viewItems.append(.value(title: "swap.advanced_settings.deadline".localized, value: deadline))
        }
        if let recipientDomain = additionalItems[.swapRecipientDomain] {
            viewItems.append(.value(title: "swap.advanced_settings.recipient_domain".localized, value: recipientDomain))
        }

        if to != service.ownAddress {
            viewItems.append(.address(title: "swap.advanced_settings.recipient_address".localized, value: to.eip55))
        }

        if let price = additionalItems[.swapPrice] {
            viewItems.append(.value(title: "swap.price".localized, value: price))
        }
        if let priceImpact = additionalItems[.swapPriceImpact] {
            viewItems.append(.value(title: "swap.price_impact".localized, value: priceImpact))
        }

        return viewItems
    }

    private func coinService(token: TransactionDecoration.Token) -> CoinService? {
        switch token {
        case .evmCoin: return coinServiceFactory.baseCoinService
        case .eip20Coin(let address): return coinServiceFactory.coinService(contractAddress: address)
        }
    }

    private func fallbackViewItems(transactionData: TransactionData) -> [ViewItem] {
        [
            .amount(amountData: coinServiceFactory.baseCoinService.amountData(value: transactionData.value)),
            .address(title: "To", value: transactionData.to.eip55),
            .input(value: transactionData.input.toHexString())
        ]
    }

}

extension SendEvmTransactionViewModel {

    var sendEnabledDriver: Driver<Bool> {
        sendEnabledRelay.asDriver()
    }

    var errorDriver: Driver<String?> {
        errorRelay.asDriver()
    }

    var sendingSignal: Signal<()> {
        sendingRelay.asSignal()
    }

    var sendSuccessSignal: Signal<Data> {
        sendSuccessRelay.asSignal()
    }

    var sendFailedSignal: Signal<String> {
        sendFailedRelay.asSignal()
    }

    func send() {
        service.send()
    }

}

extension SendEvmTransactionViewModel {

    enum ViewItem {
        case amount(amountData: AmountData)
        case address(title: String, value: String)
        case value(title: String, value: String)
        case input(value: String)
    }

}
