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

    private let sectionViewItemsRelay = BehaviorRelay<[SectionViewItem]>(value: [])

    private let sendEnabledRelay = BehaviorRelay<Bool>(value: false)
    private let errorRelay = BehaviorRelay<String?>(value: nil)

    private let sendingRelay = PublishRelay<()>()
    private let sendSuccessRelay = PublishRelay<Data>()
    private let sendFailedRelay = PublishRelay<String>()

    init(service: SendEvmTransactionService, coinServiceFactory: EvmCoinServiceFactory) {
        self.service = service
        self.coinServiceFactory = coinServiceFactory

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }
        subscribe(disposeBag, service.dataStateObservable) { [weak self] in self?.sync(dataState: $0) }
        subscribe(disposeBag, service.sendStateObservable) { [weak self] in self?.sync(sendState: $0) }

        sync(state: service.state)
        sync(dataState: service.dataState)
        sync(sendState: service.sendState)
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

    private func sync(dataState: SendEvmTransactionService.DataState) {
        let items: [SectionViewItem]

        if let decoration = dataState.decoration, let decoratedItems = self.items(decoration: decoration, additionalInfo: dataState.additionalInfo) {
            items = decoratedItems
        } else {
            items = fallbackItems(transactionData: dataState.transactionData)
        }

        sectionViewItemsRelay.accept(items)
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
            }
        }

        return error.convertedError.smartDescription
    }

    private func items(decoration: TransactionDecoration, additionalInfo: SendEvmData.AdditionInfo?) -> [SectionViewItem]? {
        switch decoration {
        case let .transfer(from, to, value):
            return transferItems(from: from, to: to, value: value, additionalInfo: additionalInfo)
        case let .eip20Transfer(to, value, contractAddress):
            return eip20TransferItems(to: to, value: value, contractAddress: contractAddress, additionalInfo: additionalInfo)
        case let .eip20Approve(spender, value, contractAddress):
            return eip20ApproveItems(spender: spender, value: value, contractAddress: contractAddress)
        case let .swap(trade, tokenIn, tokenOut, to, deadline):
            return swapItems(trade: trade, tokenIn: tokenIn, tokenOut: tokenOut, to: to, deadline: deadline, additionalInfo: additionalInfo)
        }
    }

    private func transferItems(from: EthereumKit.Address, to: EthereumKit.Address?, value: BigUInt, additionalInfo: SendEvmData.AdditionInfo?) -> [SectionViewItem] {
        var viewItems: [ViewItem] = [
            .subhead(title: "send.confirmation.you_send".localized, value: coinServiceFactory.baseCoinService.coin.title),
            .value(title: "send.confirmation.amount".localized, value: coinServiceFactory.baseCoinService.amountData(value: value).formattedRawString, type: .outgoing)
        ]

        if let to = to {
            let addressValue = to.eip55
            let addressTitle = additionalInfo?.sendInfo?.domain ?? TransactionInfoAddressMapper.map(addressValue)
            viewItems.append(.address(title: "send.confirmation.to".localized, valueTitle: addressTitle, value: addressValue))
        }

        return [SectionViewItem(viewItems: viewItems)]
    }

    private func eip20TransferItems(to: EthereumKit.Address, value: BigUInt, contractAddress: EthereumKit.Address, additionalInfo: SendEvmData.AdditionInfo?) -> [SectionViewItem]? {
        guard let coinService = coinServiceFactory.coinService(contractAddress: contractAddress) else {
            return nil
        }

        var viewItems: [ViewItem] = [
            .subhead(title: "send.confirmation.you_send".localized, value: coinService.coin.title),
            .value(title: "send.confirmation.amount".localized, value: coinService.amountData(value: value).formattedRawString, type: .outgoing)
        ]

        let addressValue = to.eip55
        let addressTitle = additionalInfo?.sendInfo?.domain ?? TransactionInfoAddressMapper.map(addressValue)
        viewItems.append(.address(title: "send.confirmation.to".localized, valueTitle: addressTitle, value: addressValue))

        return [SectionViewItem(viewItems: viewItems)]
    }

    private func eip20ApproveItems(spender: EthereumKit.Address, value: BigUInt, contractAddress: EthereumKit.Address) -> [SectionViewItem]? {
        guard let coinService = coinServiceFactory.coinService(contractAddress: contractAddress) else {
            return nil
        }

        let addressValue = spender.eip55
        let addressTitle = TransactionInfoAddressMapper.map(addressValue)

        let viewItems: [ViewItem] = [
            .subhead(title: "approve.confirmation.you_approve".localized, value: coinService.coin.title),
            .value(title: "send.confirmation.amount".localized, value: coinService.amountData(value: value).formattedRawString, type: .regular),
            .address(title: "approve.confirmation.spender".localized, valueTitle: addressTitle, value: addressValue)
        ]

        return [SectionViewItem(viewItems: viewItems)]
    }

    private func swapItems(trade: TransactionDecoration.Trade, tokenIn: TransactionDecoration.Token, tokenOut: TransactionDecoration.Token, to: EthereumKit.Address, deadline: BigUInt, additionalInfo: SendEvmData.AdditionInfo?) -> [SectionViewItem]? {
        guard let coinServiceIn = coinService(token: tokenIn), let coinServiceOut = coinService(token: tokenOut) else {
            return nil
        }

        let info = additionalInfo?.swapInfo

        var sections = [SectionViewItem]()

        switch trade {
        case let .exactIn(amountIn, amountOutMin):
            sections.append(SectionViewItem(viewItems: [
                .subhead(title: "swap.you_pay".localized, value: coinServiceIn.coin.title),
                .value(title: "send.confirmation.amount".localized, value: coinServiceIn.amountData(value: amountIn).formattedRawString, type: .outgoing)
            ]))

            sections.append(SectionViewItem(viewItems: [
                .subhead(title: "swap.you_get".localized, value: coinServiceOut.coin.title),
                estimatedSwapAmount(value: info.map { coinServiceOut.amountData(value: $0.estimatedOut).formattedRawString }, type: .incoming),
                .value(title: "swap.confirmation.guaranteed".localized, value: coinServiceOut.amountData(value: amountOutMin).formattedRawString, type: .regular)
            ]))
        case let .exactOut(amountOut, amountInMax):
            sections.append(SectionViewItem(viewItems: [
                .subhead(title: "swap.you_pay".localized, value: coinServiceIn.coin.title),
                estimatedSwapAmount(value: info.map { coinServiceIn.amountData(value: $0.estimatedIn).formattedRawString }, type: .outgoing),
                .value(title: "swap.confirmation.maximum".localized, value: coinServiceIn.amountData(value: amountInMax).formattedRawString, type: .regular)
            ]))

            sections.append(SectionViewItem(viewItems: [
                .subhead(title: "swap.you_get".localized, value: coinServiceOut.coin.title),
                .value(title: "send.confirmation.amount".localized, value: coinServiceOut.amountData(value: amountOut).formattedRawString, type: .incoming)
            ]))
        }

        var otherViewItems = [ViewItem]()

        if let slippage = info?.slippage {
            otherViewItems.append(.value(title: "swap.advanced_settings.slippage".localized, value: slippage, type: .regular))
        }
        if let deadline = info?.deadline {
            otherViewItems.append(.value(title: "swap.advanced_settings.deadline".localized, value: deadline, type: .regular))
        }

        if to != service.ownAddress {
            let addressValue = to.eip55
            let addressTitle = info?.recipientDomain ?? TransactionInfoAddressMapper.map(addressValue)
            otherViewItems.append(.address(title: "swap.advanced_settings.recipient_address".localized, valueTitle: addressTitle, value: addressValue))
        }

        if let price = info?.price {
            otherViewItems.append(.value(title: "swap.price".localized, value: price, type: .regular))
        }
        if let priceImpact = info?.priceImpact {
            otherViewItems.append(.value(title: "swap.price_impact".localized, value: priceImpact, type: .regular))
        }

        if !otherViewItems.isEmpty {
            sections.append(SectionViewItem(viewItems: otherViewItems))
        }

        return sections
    }

    private func estimatedSwapAmount(value: String?, type: ValueType) -> ViewItem {
        let title = "swap.confirmation.estimated".localized

        if let value = value {
            return .value(title: title, value: value, type: type)
        } else {
            return .value(title: title, value: "n/a".localized, type: .disabled)
        }
    }

    private func coinService(token: TransactionDecoration.Token) -> CoinService? {
        switch token {
        case .evmCoin: return coinServiceFactory.baseCoinService
        case .eip20Coin(let address): return coinServiceFactory.coinService(contractAddress: address)
        }
    }

    private func fallbackItems(transactionData: TransactionData) -> [SectionViewItem] {
        let addressValue = transactionData.to.eip55

        let viewItems: [ViewItem] = [
            .value(title: "Amount", value: coinServiceFactory.baseCoinService.amountData(value: transactionData.value).formattedRawString, type: .outgoing),
            .address(title: "To", valueTitle: addressValue, value: addressValue),
            .input(value: transactionData.input.toHexString())
        ]

        return [SectionViewItem(viewItems: viewItems)]
    }

}

extension SendEvmTransactionViewModel {

    var sectionViewItemsDriver: Driver<[SectionViewItem]> {
        sectionViewItemsRelay.asDriver()
    }

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

    struct SectionViewItem {
        let viewItems: [ViewItem]
    }

    enum ViewItem {
        case subhead(title: String, value: String)
        case value(title: String, value: String, type: ValueType)
        case address(title: String, valueTitle: String, value: String)
        case input(value: String)
    }

    enum ValueType {
        case regular
        case disabled
        case outgoing
        case incoming
    }

}
