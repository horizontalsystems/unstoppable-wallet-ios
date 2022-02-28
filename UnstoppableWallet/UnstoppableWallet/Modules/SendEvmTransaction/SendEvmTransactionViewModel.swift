import Foundation
import RxSwift
import RxCocoa
import EthereumKit
import BigInt
import UniswapKit
import OneInchKit
import Erc20Kit
import MarketKit

class SendEvmTransactionViewModel {
    private let disposeBag = DisposeBag()

    private let service: ISendEvmTransactionService
    private let coinServiceFactory: EvmCoinServiceFactory
    private let cautionsFactory: SendEvmCautionsFactory

    private let sectionViewItemsRelay = BehaviorRelay<[SectionViewItem]>(value: [])

    private let sendEnabledRelay = BehaviorRelay<Bool>(value: false)
    private let cautionsRelay = BehaviorRelay<[TitledCaution]>(value: [])

    private let sendingRelay = PublishRelay<()>()
    private let sendSuccessRelay = PublishRelay<Data>()
    private let sendFailedRelay = PublishRelay<String>()

    init(service: ISendEvmTransactionService, coinServiceFactory: EvmCoinServiceFactory, cautionsFactory: SendEvmCautionsFactory) {
        self.service = service
        self.coinServiceFactory = coinServiceFactory
        self.cautionsFactory = cautionsFactory

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }
        subscribe(disposeBag, service.sendStateObservable) { [weak self] in self?.sync(sendState: $0) }

        sync(state: service.state)
        sync(sendState: service.sendState)
    }

    private func sync(state: SendEvmTransactionService.State) {
        switch state {
        case .ready(let warnings):
            cautionsRelay.accept(cautionsFactory.items(errors: [], warnings: warnings, baseCoinService: coinServiceFactory.baseCoinService))
            sendEnabledRelay.accept(true)
        case .notReady(let errors, let warnings):
            cautionsRelay.accept(cautionsFactory.items(errors: errors, warnings: warnings, baseCoinService: coinServiceFactory.baseCoinService))
            sendEnabledRelay.accept(false)
        }

        let dataState = service.dataState
        var items: [SectionViewItem]? = nil

        if let decoration = dataState.decoration,
           let decoratedItems = self.items(
                   decoration: decoration,
                   transactionData: dataState.transactionData,
                   additionalInfo: dataState.additionalInfo) {

            items = decoratedItems
        }

        if items == nil, let data = dataState.transactionData {
            items = unknownMethodItems(transactionData: data, additionalInfo: dataState.additionalInfo)
        }

        if let items = items {
            sectionViewItemsRelay.accept(items)
        }
    }

    private func formatted(slippage: Decimal) -> String? {
        guard slippage != OneInchSettingsService.defaultSlippage else {
            return nil
        }

        return "\(slippage)%"
    }

    private func sync(sendState: SendEvmTransactionService.SendState) {
        switch sendState {
        case .idle: ()
        case .sending: sendingRelay.accept(())
        case .sent(let transactionHash): sendSuccessRelay.accept(transactionHash)
        case .failed(let error): sendFailedRelay.accept(error.convertedError.smartDescription)
        }
    }

    private func items(decoration: ContractMethodDecoration, transactionData: TransactionData?, additionalInfo: SendEvmData.AdditionInfo?) -> [SectionViewItem]? {
        if let method = decoration as? SwapMethodDecoration {
            return uniswapItems(
                    trade: method.trade,
                    tokenIn: method.tokenIn,
                    tokenOut: method.tokenOut,
                    to: method.to,
                    deadline: method.deadline,
                    additionalInfo: additionalInfo)
        }

        if let method = decoration as? OneInchUnoswapMethodDecoration {
            return swapItems(
                    tokenIn: method.tokenIn,
                    tokenOut: method.tokenOut,
                    fromAmount: method.amountIn,
                    toAmount: method.amountOut,
                    toAmountMin: method.amountOutMin,
                    additionalInfo: additionalInfo)
        }

        if let method = decoration as? OneInchSwapMethodDecoration {
            return swapItems(
                    tokenIn: method.tokenIn,
                    tokenOut: method.tokenOut,
                    to: method.recipient,
                    fromAmount: method.amountIn,
                    toAmount: method.amountOut,
                    toAmountMin: method.amountOutMin,
                    additionalInfo: additionalInfo)
        }

        if decoration is OneInchMethodDecoration {
            return swapItems(additionalInfo: additionalInfo)
        }

        guard let transactionData = transactionData else {
            return nil
        }

        switch decoration {
        case let method as TransferMethodDecoration:
            return eip20TransferItems(to: method.to, value: method.value, contractAddress: transactionData.to, nonce: transactionData.nonce, additionalInfo: additionalInfo)

        case let method as ApproveMethodDecoration:
            return eip20ApproveItems(spender: method.spender, value: method.value, contractAddress: transactionData.to, nonce: transactionData.nonce)

        case let method as RecognizedMethodDecoration:
            return recognizedMethodItems(transactionData: transactionData, method: method.method, arguments: method.arguments)

        case _ as UnknownMethodDecoration:
            return unknownMethodItems(transactionData: transactionData, additionalInfo: additionalInfo)

        default: return nil
        }
    }

    private func eip20TransferItems(to: EthereumKit.Address, value: BigUInt, contractAddress: EthereumKit.Address, nonce: Int?, additionalInfo: SendEvmData.AdditionInfo?) -> [SectionViewItem]? {
        guard let coinService = coinServiceFactory.coinService(contractAddress: contractAddress) else {
            return nil
        }

        var viewItems: [ViewItem] = [
            .subhead(title: "send.confirmation.you_send".localized, value: coinService.platformCoin.coin.name),
            .value(title: coinService.amountData(value: value).secondary?.formattedRawString ?? "n/a".localized, value: (coinService.amountData(value: value).primary.formattedString ?? "n/a".localized), type: .outgoing)
        ]

        let addressValue = to.eip55
        let addressTitle = additionalInfo?.sendInfo?.domain ?? TransactionInfoAddressMapper.map(addressValue)
        viewItems.append(.address(title: "send.confirmation.to".localized, valueTitle: addressTitle, value: addressValue))
        if let nonce = nonce {
            viewItems.append(.value(title: "send.confirmation.nonce".localized, value: nonce.description, type: .regular))
        }

        return [SectionViewItem(viewItems: viewItems)]
    }

    private func eip20ApproveItems(spender: EthereumKit.Address, value: BigUInt, contractAddress: EthereumKit.Address, nonce: Int?) -> [SectionViewItem]? {
        guard let coinService = coinServiceFactory.coinService(contractAddress: contractAddress) else {
            return nil
        }

        let addressValue = spender.eip55
        let addressTitle = TransactionInfoAddressMapper.map(addressValue)

        var viewItems: [ViewItem] = [
            .subhead(title: "approve.confirmation.you_approve".localized, value: coinService.platformCoin.coin.name),
            .value(title: coinService.amountData(value: value).secondary?.formattedRawString ?? "n/a".localized, value: (coinService.amountData(value: value).primary.formattedString ?? "n/a".localized), type: .regular),
            .address(title: "approve.confirmation.spender".localized, valueTitle: addressTitle, value: addressValue)
        ]

        if let nonce = nonce {
            viewItems.append(.value(title: "send.confirmation.nonce".localized, value: nonce.description, type: .regular))
        }

        return [SectionViewItem(viewItems: viewItems)]
    }

    private func uniswapItems(trade: SwapMethodDecoration.Trade, tokenIn: SwapMethodDecoration.Token, tokenOut: SwapMethodDecoration.Token, to: EthereumKit.Address, deadline: BigUInt, additionalInfo: SendEvmData.AdditionInfo?) -> [SectionViewItem]? {
        guard let coinServiceIn = coinService(token: tokenIn), let coinServiceOut = coinService(token: tokenOut) else {
            return nil
        }

        let info = additionalInfo?.swapInfo

        var sections = [SectionViewItem]()

        switch trade {
        case let .exactIn(amountIn, amountOutMin, _):
            sections.append(SectionViewItem(viewItems: [
                .subhead(title: "swap.you_pay".localized, value: coinServiceIn.platformCoin.coin.name),
                .value(title: coinServiceIn.amountData(value: amountIn).secondary?.formattedRawString ?? "n/a".localized, value: (coinServiceIn.amountData(value: amountIn).primary.formattedString ?? "n/a".localized), type: .regular)
            ]))

            sections.append(SectionViewItem(viewItems: [
                .subhead(title: "swap.you_get".localized, value: coinServiceOut.platformCoin.coin.name),
                estimatedSwapAmount(
                        title: info.flatMap { coinServiceOut.amountData(value: $0.estimatedOut).secondary?.formattedRawString },
                        value: info.flatMap { coinServiceOut.amountData(value: $0.estimatedOut).primary.formattedString }, type: .incoming
                ),
                .value(title: coinServiceOut.amountData(value: amountOutMin).secondary?.formattedRawString ?? "n/a".localized, value: (coinServiceOut.amountData(value: amountOutMin).primary.formattedString ?? "n/a".localized) + " " + "swap.minimum_short".localized, type: .regular)
            ]))
        case let .exactOut(amountOut, amountInMax, _):
            sections.append(SectionViewItem(viewItems: [
                .subhead(title: "swap.you_pay".localized, value: coinServiceIn.platformCoin.coin.name),
                estimatedSwapAmount(
                        title: info.flatMap { coinServiceIn.amountData(value: $0.estimatedIn).secondary?.formattedRawString },
                        value: info.flatMap { coinServiceIn.amountData(value: $0.estimatedIn).primary.formattedString }, type: .outgoing
                ),
                valueMin(title: coinServiceOut.amountData(value: amountInMax).secondary?.formattedRawString, value: coinServiceOut.amountData(value: amountInMax).primary.formattedString, type: .regular)
            ]))

            sections.append(SectionViewItem(viewItems: [
                .subhead(title: "swap.you_get".localized, value: coinServiceOut.platformCoin.coin.name),
                .value(title: coinServiceOut.amountData(value: amountOut).secondary?.formattedRawString ?? "n/a".localized, value: (coinServiceOut.amountData(value: amountOut).primary.formattedString ?? "n/a".localized), type: .regular)
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
            var type: ValueType
            switch priceImpact.level {
            case .forbidden: type = .alert
            case .warning: type = .warning
            default: type = .regular
            }

            otherViewItems.append(.value(title: "swap.price_impact".localized, value: priceImpact.value, type: type))
        }

        if !otherViewItems.isEmpty {
            sections.append(SectionViewItem(viewItems: otherViewItems))
        }

        return sections
    }

    private func swapItems(additionalInfo: SendEvmData.AdditionInfo?) -> [SectionViewItem]? {
        guard let additionalInfo = additionalInfo, let info = additionalInfo.oneInchSwapInfo else {
            return nil
        }

        guard let coinServiceIn = coinService(platformCoin: info.platformCoinFrom),
              let coinServiceOut = coinService(platformCoin: info.platformCoinTo) else {
            return nil
        }

        var sections = [SectionViewItem]()

        sections.append(SectionViewItem(viewItems: [
            .subhead(title: "swap.you_pay".localized, value: coinServiceIn.platformCoin.coin.code),
            .value(title: coinServiceIn.amountData(value: info.amountFrom).secondary?.formattedRawString ?? "n/a".localized, value: coinServiceIn.amountData(value: info.amountFrom).primary.formattedString ?? "n/a".localized, type: .outgoing)
        ]))

        let estimatedAmountData = coinServiceOut.amountData(value: info.estimatedAmountTo)
        let amountOutMinDecimal = info.estimatedAmountTo * (1 - info.slippage / 100)
        let toAmountMin = BigUInt((amountOutMinDecimal * pow(10, info.platformCoinTo.decimals)).roundedString(decimal: 0)) ?? 0
        let estimatedTo = estimatedSwapAmount(title: estimatedAmountData.secondary?.formattedRawString, value: estimatedAmountData.primary.formattedString, type: .incoming)

        sections.append(SectionViewItem(viewItems: [
            .subhead(title: "swap.you_get".localized, value: coinServiceOut.platformCoin.coin.code),
            estimatedTo,
            valueMin(title: coinServiceOut.amountData(value: toAmountMin).secondary?.formattedRawString, value: coinServiceOut.amountData(value: toAmountMin).primary.formattedString, type: .regular)
        ].compactMap { $0 }))

        var otherViewItems = [ViewItem]()

        if let slippage = formatted(slippage: info.slippage) {
            otherViewItems.append(.value(title: "swap.advanced_settings.slippage".localized, value: slippage, type: .regular))
        }

        if let toAddress = info.recipient,
           let to = try? EthereumKit.Address(hex: toAddress.raw),
           to != service.ownAddress {
            let addressValue = to.eip55
            let addressTitle = info.recipient?.domain ?? TransactionInfoAddressMapper.map(addressValue)
            otherViewItems.append(.address(title: "swap.advanced_settings.recipient_address".localized, valueTitle: addressTitle, value: addressValue))
        }

        if !otherViewItems.isEmpty {
            sections.append(SectionViewItem(viewItems: otherViewItems))
        }

        return sections
    }

    private func swapItems(tokenIn: OneInchMethodDecoration.Token, tokenOut: OneInchMethodDecoration.Token?, to: EthereumKit.Address? = nil, fromAmount: BigUInt = 0, toAmount: BigUInt?, toAmountMin: BigUInt = 0, additionalInfo: SendEvmData.AdditionInfo?) -> [SectionViewItem]? {
        let info = additionalInfo?.oneInchSwapInfo

        guard let coinServiceIn = coinService(token: tokenIn),
              let coinServiceOut = tokenOut.flatMap({ coinService(token: $0) }) ?? (info?.platformCoinTo).flatMap({ coinService(platformCoin: $0) }) else {
            return nil
        }

        var sections = [SectionViewItem]()

        sections.append(SectionViewItem(viewItems: [
            .subhead(title: "swap.you_pay".localized, value: coinServiceIn.platformCoin.coin.code),
            .value(title: coinServiceIn.amountData(value: fromAmount).secondary?.formattedRawString ?? "n/a".localized, value: coinServiceIn.amountData(value: fromAmount).primary.formattedString ?? "n/a".localized, type: .outgoing)
        ]))

        let methodEstimatedDecimal = toAmount.map { coinServiceOut.amountData(value: $0) }
        let estimatedAmountData = methodEstimatedDecimal ?? (info?.estimatedAmountTo).map { coinServiceOut.amountData(value: $0) }

        let estimatedTo = estimatedAmountData.map { estimatedSwapAmount(title: $0.secondary?.formattedRawString, value: $0.primary.formattedString, type: .incoming) }
        sections.append(SectionViewItem(viewItems: [
            .subhead(title: "swap.you_get".localized, value: coinServiceOut.platformCoin.coin.code),
            estimatedTo,
            valueMin(title: coinServiceOut.amountData(value: toAmountMin).secondary?.formattedRawString, value: coinServiceOut.amountData(value: toAmountMin).primary.formattedString, type: .regular)
        ].compactMap { $0 }))

        var otherViewItems = [ViewItem]()

        if let slippage = info?.slippage, let formattedSlippage = formatted(slippage: slippage) {
            otherViewItems.append(.value(title: "swap.advanced_settings.slippage".localized, value: formattedSlippage, type: .regular))
        }

        if let to = to, to != service.ownAddress {
            let addressValue = to.eip55
            let addressTitle = info?.recipient?.domain ?? TransactionInfoAddressMapper.map(addressValue)
            otherViewItems.append(.address(title: "swap.advanced_settings.recipient_address".localized, valueTitle: addressTitle, value: addressValue))
        }

        if !otherViewItems.isEmpty {
            sections.append(SectionViewItem(viewItems: otherViewItems))
        }

        return sections
    }

    private func recognizedMethodItems(transactionData: TransactionData, method: String, arguments: [Any]) -> [SectionViewItem] {
        let addressValue = transactionData.to.eip55

        let viewItems: [ViewItem] = [
            .value(title: coinServiceFactory.baseCoinService.amountData(value: transactionData.value).secondary?.formattedRawString ?? "n/a".localized, value: (coinServiceFactory.baseCoinService.amountData(value: transactionData.value).primary.formattedString ?? "n/a".localized), type: .outgoing),
            .address(title: "send.confirmation.to".localized, valueTitle: addressValue, value: addressValue),
            .subhead(title: "send.confirmation.to".localized, value: method),
            .input(value: transactionData.input.toHexString())
        ]

        return [SectionViewItem(viewItems: viewItems)]
    }

    private func unknownMethodItems(transactionData: TransactionData, additionalInfo: SendEvmData.AdditionInfo?) -> [SectionViewItem] {
        let addressValue = transactionData.to.eip55
        let addressTitle = additionalInfo?.sendInfo?.domain ?? TransactionInfoAddressMapper.map(addressValue)

        var youPayItem: ViewItem?
        var inputItem: ViewItem?

        if transactionData.input.isEmpty {      // ETH or BNB transfer transaction
            youPayItem = .subhead(title: "send.confirmation.you_send".localized, value: coinServiceFactory.baseCoinService.platformCoin.coin.name)
        } else {
            inputItem = .input(value: transactionData.input.toHexString())
        }

        var viewItems: [ViewItem] = [
            youPayItem,
            .value(title: coinServiceFactory.baseCoinService.amountData(value: transactionData.value).secondary?.formattedRawString ?? "n/a".localized, value: (coinServiceFactory.baseCoinService.amountData(value: transactionData.value).primary.formattedString ?? "n/a".localized), type: .outgoing),
            .address(title: "send.confirmation.to".localized, valueTitle: addressTitle, value: addressValue),
            transactionData.nonce.map { .value(title: "send.confirmation.nonce".localized, value: $0.description, type: .regular) },
            inputItem
        ].compactMap { $0 }
        if let dAppName = additionalInfo?.dAppInfo?.name {
            viewItems.append(.value(title: "wallet_connect.sign.dapp_name".localized, value: dAppName, type: .regular))
        }
        return [SectionViewItem(viewItems: viewItems)]
    }

    private func estimatedSwapAmount(title: String?, value: String?, type: ValueType) -> ViewItem {
        let title = title ?? "n/a".localized

        if let value = value {
            return .value(title: title, value: value + " " + "swap.estimate_short".localized, type: type)
        } else {
            return .value(title: title, value: "n/a".localized, type: .disabled)
        }
    }

    private func valueMin(title: String?, value: String?, type: ValueType) -> ViewItem {
        let title = title ?? "n/a".localized
        let value = value.map { $0 + " " + "swap.minimum_short".localized } ?? "n/a".localized
        return .value(title: title, value: value, type: type)
    }

    private func coinService(token: SwapMethodDecoration.Token) -> CoinService? {
        switch token {
        case .evmCoin: return coinServiceFactory.baseCoinService
        case .eip20Coin(let address): return coinServiceFactory.coinService(contractAddress: address)
        }
    }

    private func coinService(token: OneInchMethodDecoration.Token?) -> CoinService? {
        switch token {
        case .evmCoin: return coinServiceFactory.baseCoinService
        case .eip20Coin(let address): return coinServiceFactory.coinService(contractAddress: address)
        case .none: return nil
        }
    }

    private func coinService(platformCoin: PlatformCoin) -> CoinService? {
        switch platformCoin.coinType {
        case .ethereum, .binanceSmartChain, .polygon: return coinServiceFactory.baseCoinService
        case .erc20(let address): return (try? EthereumKit.Address(hex: address)).flatMap { coinServiceFactory.coinService(contractAddress: $0) }
        case .bep20(let address): return (try? EthereumKit.Address(hex: address)).flatMap { coinServiceFactory.coinService(contractAddress: $0) }
        case .mrc20(let address): return (try? EthereumKit.Address(hex: address)).flatMap { coinServiceFactory.coinService(contractAddress: $0) }
        default: return nil
        }
    }

}

extension SendEvmTransactionViewModel {

    var sectionViewItemsDriver: Driver<[SectionViewItem]> {
        sectionViewItemsRelay.asDriver()
    }

    var sendEnabledDriver: Driver<Bool> {
        sendEnabledRelay.asDriver()
    }

    var cautionsDriver: Driver<[TitledCaution]> {
        cautionsRelay.asDriver()
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
        case warning
        case alert
    }

}
