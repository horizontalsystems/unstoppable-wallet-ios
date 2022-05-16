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
    private let evmLabelManager: EvmLabelManager

    private let sectionViewItemsRelay = BehaviorRelay<[SectionViewItem]>(value: [])

    private let sendEnabledRelay = BehaviorRelay<Bool>(value: false)
    private let cautionsRelay = BehaviorRelay<[TitledCaution]>(value: [])

    private let sendingRelay = PublishRelay<()>()
    private let sendSuccessRelay = PublishRelay<Data>()
    private let sendFailedRelay = PublishRelay<String>()

    init(service: ISendEvmTransactionService, coinServiceFactory: EvmCoinServiceFactory, cautionsFactory: SendEvmCautionsFactory, evmLabelManager: EvmLabelManager) {
        self.service = service
        self.coinServiceFactory = coinServiceFactory
        self.cautionsFactory = cautionsFactory
        self.evmLabelManager = evmLabelManager

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

        sectionViewItemsRelay.accept(items(dataState: service.dataState))
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

    private func items(dataState: SendEvmTransactionService.DataState) -> [SectionViewItem] {
        if let decoration = dataState.decoration, let items = self.items(decoration: decoration, transactionData: dataState.transactionData, additionalInfo: dataState.additionalInfo) {
            return items
        }

        if let additionalInfo = dataState.additionalInfo {
            switch additionalInfo {
            case .oneInchSwap(let info):
                return oneInchItems(oneInchSwapInfo: info)
            default: ()
            }
        }

        if let transactionData = dataState.transactionData {
            return unknownMethodItems(transactionData: transactionData, dAppInfo: dataState.additionalInfo?.dAppInfo)
        }

        return []
    }

    private func items(decoration: TransactionDecoration, transactionData: TransactionData?, additionalInfo: SendEvmData.AdditionInfo?) -> [SectionViewItem]? {
        switch decoration {
        case let decoration as OutgoingDecoration:
            return sendBaseCoinItems(
                    to: decoration.to,
                    value: decoration.value,
                    sendInfo: additionalInfo?.sendInfo
            )

        case let decoration as OutgoingEip20Decoration:
            return eip20TransferItems(
                    to: decoration.to,
                    value: decoration.value,
                    contractAddress: decoration.contractAddress,
                    nonce: transactionData?.nonce,
                    sendInfo: additionalInfo?.sendInfo
            )

        case let decoration as ApproveEip20Decoration:
            return eip20ApproveItems(
                    spender: decoration.spender,
                    value: decoration.value,
                    contractAddress: decoration.contractAddress,
                    nonce: transactionData?.nonce
            )

        case let decoration as SwapDecoration:
            return uniswapItems(
                    amountIn: decoration.amountIn,
                    amountOut: decoration.amountOut,
                    tokenIn: decoration.tokenIn,
                    tokenOut: decoration.tokenOut,
                    recipient: decoration.recipient,
                    deadline: decoration.deadline,
                    swapInfo: additionalInfo?.swapInfo
            )

        case let decoration as OneInchSwapDecoration:
            return oneInchItems(
                    tokenIn: decoration.tokenIn,
                    tokenOut: decoration.tokenOut,
                    amountIn: decoration.amountIn,
                    amountOut: decoration.amountOut,
                    recipient: decoration.recipient,
                    oneInchSwapInfo: additionalInfo?.oneInchSwapInfo
            )

        case let decoration as OneInchUnoswapDecoration:
            return oneInchItems(
                    tokenIn: decoration.tokenIn,
                    tokenOut: decoration.tokenOut,
                    amountIn: decoration.amountIn,
                    amountOut: decoration.amountOut,
                    oneInchSwapInfo: additionalInfo?.oneInchSwapInfo
            )

        case is OneInchUnknownSwapDecoration:
            return additionalInfo?.oneInchSwapInfo.map { oneInchItems(oneInchSwapInfo: $0) }

        default:
            return nil
        }
    }

    private func sendBaseCoinItems(to: EthereumKit.Address, value: BigUInt, sendInfo: SendEvmData.SendInfo?) -> [SectionViewItem] {
        let toValue = to.eip55
        let amountData = coinServiceFactory.baseCoinService.amountData(value: value)

        return [
            SectionViewItem(viewItems: [
                .subhead(
                        title: "send.confirmation.you_send".localized,
                        value: coinServiceFactory.baseCoinService.platformCoin.coin.name
                ),
                .value(
                        title: amountData.secondary?.formattedFull ?? "n/a".localized,
                        value: amountData.primary.formattedFull ?? "n/a".localized,
                        type: .outgoing
                ),
                .address(
                        title: "send.confirmation.to".localized,
                        valueTitle: sendInfo?.domain ?? evmLabelManager.mapped(address: toValue),
                        value: toValue
                ),
            ])
        ]
    }

    private func eip20TransferItems(to: EthereumKit.Address, value: BigUInt, contractAddress: EthereumKit.Address, nonce: Int?, sendInfo: SendEvmData.SendInfo?) -> [SectionViewItem]? {
        guard let coinService = coinServiceFactory.coinService(contractAddress: contractAddress) else {
            return nil
        }

        var viewItems: [ViewItem] = [
            .subhead(title: "send.confirmation.you_send".localized, value: coinService.platformCoin.coin.name),
            .value(title: coinService.amountData(value: value).secondary?.formattedFull ?? "n/a".localized, value: (coinService.amountData(value: value).primary.formattedFull ?? "n/a".localized), type: .outgoing)
        ]

        let addressValue = to.eip55
        let addressTitle = sendInfo?.domain ?? evmLabelManager.mapped(address: addressValue)
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
        let addressTitle = evmLabelManager.mapped(address: addressValue)

        var viewItems: [ViewItem] = [
            .subhead(title: "approve.confirmation.you_approve".localized, value: coinService.platformCoin.coin.name),
            .value(title: coinService.amountData(value: value).secondary?.formattedFull ?? "n/a".localized, value: (coinService.amountData(value: value).primary.formattedFull ?? "n/a".localized), type: .regular),
            .address(title: "approve.confirmation.spender".localized, valueTitle: addressTitle, value: addressValue)
        ]

        if let nonce = nonce {
            viewItems.append(.value(title: "send.confirmation.nonce".localized, value: nonce.description, type: .regular))
        }

        return [SectionViewItem(viewItems: viewItems)]
    }

    private func uniswapItems(amountIn: SwapDecoration.Amount, amountOut: SwapDecoration.Amount, tokenIn: SwapDecoration.Token, tokenOut: SwapDecoration.Token, recipient: EthereumKit.Address?, deadline: BigUInt, swapInfo: SendEvmData.SwapInfo?) -> [SectionViewItem]? {
        guard let coinServiceIn = coinService(token: tokenIn), let coinServiceOut = coinService(token: tokenOut) else {
            return nil
        }

        var sections = [SectionViewItem]()

        var inViewItems: [ViewItem] = [
            .subhead(title: "swap.you_pay".localized, value: coinServiceIn.platformCoin.coin.name)
        ]

        switch amountIn {
        case .exact(let value):
            inViewItems.append(self.value(amountData: coinServiceIn.amountData(value: value), type: .regular))
        case .extremum(let value):
            if let estimatedIn = swapInfo?.estimatedIn {
                inViewItems.append(estimatedSwapAmount(amountData: coinServiceIn.amountData(value: estimatedIn), type: .outgoing))
            }

            inViewItems.append(valueMax(amountData: coinServiceIn.amountData(value: value), type: .regular))
        }

        sections.append(SectionViewItem(viewItems: inViewItems))

        var outViewItems: [ViewItem] = [
            .subhead(title: "swap.you_get".localized, value: coinServiceOut.platformCoin.coin.name)
        ]

        switch amountOut {
        case .exact(let value):
            outViewItems.append(self.value(amountData: coinServiceOut.amountData(value: value), type: .regular))
        case .extremum(let value):
            if let estimatedOut = swapInfo?.estimatedOut {
                outViewItems.append(estimatedSwapAmount(amountData: coinServiceOut.amountData(value: estimatedOut), type: .incoming))
            }

            outViewItems.append(valueMin(amountData: coinServiceOut.amountData(value: value), type: .regular))
        }

        sections.append(SectionViewItem(viewItems: outViewItems))

        var otherViewItems = [ViewItem]()

        if let slippage = swapInfo?.slippage {
            otherViewItems.append(.value(title: "swap.advanced_settings.slippage".localized, value: slippage, type: .regular))
        }
        if let deadline = swapInfo?.deadline {
            otherViewItems.append(.value(title: "swap.advanced_settings.deadline".localized, value: deadline, type: .regular))
        }

        if let recipient = recipient {
            let addressValue = recipient.eip55
            let addressTitle = swapInfo?.recipientDomain ?? evmLabelManager.mapped(address: addressValue)
            otherViewItems.append(.address(title: "swap.advanced_settings.recipient_address".localized, valueTitle: addressTitle, value: addressValue))
        }

        if let price = swapInfo?.price {
            otherViewItems.append(.value(title: "swap.price".localized, value: price, type: .regular))
        }
        if let priceImpact = swapInfo?.priceImpact {
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

    private func oneInchItems(tokenIn: OneInchDecoration.Token, tokenOut: OneInchDecoration.Token?, amountIn: BigUInt, amountOut: OneInchDecoration.Amount, recipient: EthereumKit.Address? = nil, oneInchSwapInfo: SendEvmData.OneInchSwapInfo?) -> [SectionViewItem]? {
        var coinServiceOut = tokenOut.flatMap { coinService(token: $0) }

        if coinServiceOut == nil, let oneInchSwapInfo = oneInchSwapInfo {
            coinServiceOut = coinService(platformCoin: oneInchSwapInfo.platformCoinTo)
        }

        guard let coinServiceIn = coinService(token: tokenIn), let coinServiceOut = coinServiceOut else {
            return nil
        }

        var sections = [SectionViewItem]()

        sections.append(
                SectionViewItem(viewItems: [
                    .subhead(title: "swap.you_pay".localized, value: coinServiceIn.platformCoin.coin.code),
                    value(amountData: coinServiceIn.amountData(value: amountIn), type: .outgoing)
                ])
        )

        var outViewItems: [ViewItem] = [
            .subhead(title: "swap.you_get".localized, value: coinServiceOut.platformCoin.coin.code)
        ]

        switch amountOut {
        case .exact: () // not possible in send
        case .extremum(let value):
            if let estimatedAmountTo = oneInchSwapInfo?.estimatedAmountTo {
                outViewItems.append(estimatedSwapAmount(amountData: coinServiceOut.amountData(value: estimatedAmountTo), type: .incoming))
            }

            outViewItems.append(valueMin(amountData: coinServiceOut.amountData(value: value), type: .regular))
        }

        sections.append(SectionViewItem(viewItems: outViewItems))

        if let section = additionalSectionViewItem(oneInchSwapInfo: oneInchSwapInfo, recipient: recipient) {
            sections.append(section)
        }

        return sections
    }

    private func oneInchItems(oneInchSwapInfo: SendEvmData.OneInchSwapInfo) -> [SectionViewItem] {
        let coinServiceIn = coinService(platformCoin: oneInchSwapInfo.platformCoinFrom)
        let coinServiceOut = coinService(platformCoin: oneInchSwapInfo.platformCoinTo)

        var sections = [SectionViewItem]()

        sections.append(SectionViewItem(viewItems: [
            .subhead(title: "swap.you_pay".localized, value: coinServiceIn.platformCoin.coin.code),
            value(amountData: coinServiceIn.amountData(value: oneInchSwapInfo.amountFrom), type: .outgoing)
        ]))

        let amountOutMinDecimal = oneInchSwapInfo.estimatedAmountTo * (1 - oneInchSwapInfo.slippage / 100)
        let toAmountMin = BigUInt((amountOutMinDecimal * pow(10, oneInchSwapInfo.platformCoinTo.decimals)).roundedString(decimal: 0)) ?? 0

        sections.append(SectionViewItem(viewItems: [
            .subhead(title: "swap.you_get".localized, value: coinServiceOut.platformCoin.coin.code),
            estimatedSwapAmount(amountData: coinServiceOut.amountData(value: oneInchSwapInfo.estimatedAmountTo), type: .incoming),
            valueMin(amountData: coinServiceOut.amountData(value: toAmountMin), type: .regular)
        ]))

        if let section = additionalSectionViewItem(oneInchSwapInfo: oneInchSwapInfo, recipient: oneInchSwapInfo.recipient.flatMap { try? EthereumKit.Address(hex: $0.raw) }) {
            sections.append(section)
        }

        return sections
    }

    private func additionalSectionViewItem(oneInchSwapInfo: SendEvmData.OneInchSwapInfo?, recipient: EthereumKit.Address?) -> SectionViewItem? {
        var viewItems = [ViewItem]()

        if let slippage = oneInchSwapInfo?.slippage, let formattedSlippage = formatted(slippage: slippage) {
            viewItems.append(.value(title: "swap.advanced_settings.slippage".localized, value: formattedSlippage, type: .regular))
        }

        if let recipient = recipient {
            let addressValue = recipient.eip55
            let addressTitle = oneInchSwapInfo?.recipient?.domain ?? evmLabelManager.mapped(address: addressValue)
            viewItems.append(.address(title: "swap.advanced_settings.recipient_address".localized, valueTitle: addressTitle, value: addressValue))
        }

        if !viewItems.isEmpty {
            return SectionViewItem(viewItems: viewItems)
        } else {
            return nil
        }
    }

    private func unknownMethodItems(transactionData: TransactionData, dAppInfo: SendEvmData.DAppInfo?) -> [SectionViewItem] {
        let toValue = transactionData.to.eip55

        var viewItems: [ViewItem] = [
            value(
                    amountData: coinServiceFactory.baseCoinService.amountData(value: transactionData.value),
                    type: .outgoing
            ),
            .address(
                    title: "send.confirmation.to".localized,
                    valueTitle: evmLabelManager.mapped(address: toValue),
                    value: toValue
            )
        ]

        if let nonce = transactionData.nonce {
            viewItems.append(.value(title: "send.confirmation.nonce".localized, value: nonce.description, type: .regular))
        }

        viewItems.append(.input(value: transactionData.input.toHexString()))

        if let methodName = service.methodName(input: transactionData.input) {
            viewItems.append(.value(title: "send.confirmation.method".localized, value: methodName, type: .regular))
        }

        if let dAppName = dAppInfo?.name {
            viewItems.append(.value(title: "wallet_connect.sign.dapp_name".localized, value: dAppName, type: .regular))
        }

        return [
            SectionViewItem(viewItems: viewItems)
        ]
    }

    private func value(amountData: AmountData, postfix: String? = nil, type: ValueType) -> ViewItem {
        let title = amountData.secondary?.formattedFull ?? "n/a".localized
        let value = amountData.primary.formattedFull ?? "n/a".localized
        return .value(title: title, value: "\(value)\(postfix.map { " \($0)" } ?? "")", type: type)
    }

    private func estimatedSwapAmount(amountData: AmountData, type: ValueType) -> ViewItem {
        value(amountData: amountData, postfix: "swap.estimate_short".localized, type: type)
    }

    private func valueMin(amountData: AmountData, type: ValueType) -> ViewItem {
        value(amountData: amountData, postfix: "swap.minimum_short".localized, type: type)
    }

    private func valueMax(amountData: AmountData, type: ValueType) -> ViewItem {
        value(amountData: amountData, postfix: "swap.maximum_short".localized, type: type)
    }

    private func coinService(token: SwapDecoration.Token) -> CoinService? {
        switch token {
        case .evmCoin: return coinServiceFactory.baseCoinService
        case .eip20Coin(let address, _): return coinServiceFactory.coinService(contractAddress: address)
        }
    }

    private func coinService(token: OneInchDecoration.Token) -> CoinService? {
        switch token {
        case .evmCoin: return coinServiceFactory.baseCoinService
        case .eip20Coin(let address, _): return coinServiceFactory.coinService(contractAddress: address)
        }
    }

    private func coinService(platformCoin: PlatformCoin) -> CoinService {
        coinServiceFactory.coinService(platformCoin: platformCoin)
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
