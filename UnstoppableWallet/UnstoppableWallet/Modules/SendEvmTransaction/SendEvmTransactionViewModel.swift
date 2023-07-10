import Foundation
import RxSwift
import RxCocoa
import EvmKit
import BigInt
import UniswapKit
import OneInchKit
import Eip20Kit
import NftKit
import MarketKit
import HsExtensions

class SendEvmTransactionViewModel {
    private let disposeBag = DisposeBag()

    private let service: ISendEvmTransactionService
    private let coinServiceFactory: EvmCoinServiceFactory
    private let cautionsFactory: SendEvmCautionsFactory
    private let evmLabelManager: EvmLabelManager
    private let contactLabelService: ContactLabelService

    private let sectionViewItemsRelay = BehaviorRelay<[SectionViewItem]>(value: [])

    private let sendEnabledRelay = BehaviorRelay<Bool>(value: false)
    private let cautionsRelay = BehaviorRelay<[TitledCaution]>(value: [])

    private let sendingRelay = PublishRelay<()>()
    private let sendSuccessRelay = PublishRelay<Data>()
    private let sendFailedRelay = PublishRelay<String>()

    init(service: ISendEvmTransactionService, coinServiceFactory: EvmCoinServiceFactory, cautionsFactory: SendEvmCautionsFactory, evmLabelManager: EvmLabelManager, contactLabelService: ContactLabelService) {
        self.service = service
        self.coinServiceFactory = coinServiceFactory
        self.cautionsFactory = cautionsFactory
        self.evmLabelManager = evmLabelManager
        self.contactLabelService = contactLabelService

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }
        subscribe(disposeBag, service.sendStateObservable) { [weak self] in self?.sync(sendState: $0) }

        subscribe(disposeBag, contactLabelService.stateObservable) { [weak self] _ in
            self?.reSyncServiceState()
        }

        sync(state: service.state)
        sync(sendState: service.sendState)
    }

    private func reSyncServiceState() {
        sync(state: service.state)
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

    private func dAppSection(additionalInfo: SendEvmData.AdditionInfo?) -> SectionViewItem? {
        guard case let .otherDApp(info) = additionalInfo else {
            return nil
        }
        return dAppSection(additionalInfo: info)
    }

    private func dAppSection(additionalInfo: SendEvmData.DAppInfo?) -> SectionViewItem? {
        guard let info = additionalInfo else {
            return nil
        }
        var viewItems = [ViewItem]()
        if let dAppName = info.name {
            viewItems.append(.value(title: "wallet_connect.sign.dapp_name".localized, value: dAppName, type: .regular))
        }
        if let chainName = info.chainName {
            viewItems.append(.value(title: chainName, value: info.address?.shortened ?? "", type: .regular))
        }
        if viewItems.isEmpty {
            return nil
        }
        return SectionViewItem(viewItems: viewItems)
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
        if let decoration = dataState.decoration, let items = self.items(decoration: decoration, transactionData: dataState.transactionData, additionalInfo: dataState.additionalInfo, nonce: dataState.nonce) {
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
            return unknownMethodItems(transactionData: transactionData, dAppInfo: dataState.additionalInfo?.dAppInfo, nonce: dataState.nonce)
        }

        return []
    }

    private func items(decoration: TransactionDecoration, transactionData: TransactionData?, additionalInfo: SendEvmData.AdditionInfo?, nonce: Int?) -> [SectionViewItem]? {
        switch decoration {
        case let decoration as OutgoingDecoration:
            return sendBaseCoinItems(
                    to: decoration.to,
                    value: decoration.value,
                    sendInfo: additionalInfo?.sendInfo,
                    nonce: nonce
            )

        case let decoration as OutgoingEip20Decoration:
            return eip20TransferItems(
                    to: decoration.to,
                    value: decoration.value,
                    contractAddress: decoration.contractAddress,
                    nonce: nonce,
                    sendInfo: additionalInfo?.sendInfo
            )

        case let decoration as Eip721SafeTransferFromDecoration:
            return nftTransferItems(
                    to: decoration.to,
                    value: 1,
                    nonce: nonce,
                    sendInfo: additionalInfo?.sendInfo,
                    tokenId: decoration.tokenId
            )

        case let decoration as Eip1155SafeTransferFromDecoration:
            return nftTransferItems(
                    to: decoration.to,
                    value: decoration.value,
                    nonce: nonce,
                    sendInfo: additionalInfo?.sendInfo,
                    tokenId: decoration.tokenId
            )

        case let decoration as ApproveEip20Decoration:
            return eip20ApproveItems(
                    spender: decoration.spender,
                    value: decoration.value,
                    contractAddress: decoration.contractAddress,
                    additionalInfo: additionalInfo,
                    nonce: nonce
            )

        case let decoration as SwapDecoration:
            return uniswapItems(
                    amountIn: decoration.amountIn,
                    amountOut: decoration.amountOut,
                    tokenIn: decoration.tokenIn,
                    tokenOut: decoration.tokenOut,
                    recipient: decoration.recipient,
                    deadline: decoration.deadline,
                    swapInfo: additionalInfo?.swapInfo,
                    nonce: nonce
            )

        case let decoration as OneInchSwapDecoration:
            return oneInchItems(
                    tokenIn: decoration.tokenIn,
                    tokenOut: decoration.tokenOut,
                    amountIn: decoration.amountIn,
                    amountOut: decoration.amountOut,
                    recipient: decoration.recipient,
                    oneInchSwapInfo: additionalInfo?.oneInchSwapInfo,
                    nonce: nonce
            )

        case let decoration as OneInchUnoswapDecoration:
            return oneInchItems(
                    tokenIn: decoration.tokenIn,
                    tokenOut: decoration.tokenOut,
                    amountIn: decoration.amountIn,
                    amountOut: decoration.amountOut,
                    oneInchSwapInfo: additionalInfo?.oneInchSwapInfo,
                    nonce: nonce
            )

        case is OneInchUnknownSwapDecoration:
            return additionalInfo?.oneInchSwapInfo.map { oneInchItems(oneInchSwapInfo: $0) }

        default:
            return nil
        }
    }

    private func amountViewItem(coinService: CoinService, value: BigUInt, type: AmountType) -> ViewItem {
        amountViewItem(coinService: coinService, amountData: coinService.amountData(value: value, sign: type.sign), type: type)
    }

    private func amountViewItem(coinService: CoinService, value: Decimal, type: AmountType) -> ViewItem {
        amountViewItem(coinService: coinService, amountData: coinService.amountData(value: value, sign: type.sign), type: type)
    }

    private func amountViewItem(coinService: CoinService, amountData: AmountData, type: AmountType) -> ViewItem {
        let token = coinService.token

        return .amount(
                iconUrl: token.coin.imageUrl,
                iconPlaceholderImageName: token.placeholderImageName,
                coinAmount: ValueFormatter.instance.formatFull(coinValue: amountData.coinValue) ?? "n/a".localized,
                currencyAmount: amountData.currencyValue.flatMap { ValueFormatter.instance.formatFull(currencyValue: $0) },
                type: type
        )
    }

    private func estimatedAmountViewItem(coinService: CoinService, value: Decimal, type: AmountType) -> ViewItem {
        let token = coinService.token
        let amountData = coinService.amountData(value: value, sign: type.sign)
        let coinAmount = ValueFormatter.instance.formatFull(coinValue: amountData.coinValue) ?? "n/a".localized

        return .amount(
                iconUrl: token.coin.imageUrl,
                iconPlaceholderImageName: token.placeholderImageName,
                coinAmount: "\(coinAmount) \("swap.estimate_short".localized)",
                currencyAmount: amountData.currencyValue.flatMap { ValueFormatter.instance.formatFull(currencyValue: $0) },
                type: type
        )
    }

    private func nftAmountViewItem(value: BigUInt, type: AmountType, iconUrl: String?) -> ViewItem {
        let nftAmount: String

        if let value = Decimal(bigUInt: value, decimals: 0) {
            nftAmount = "\(value) NFT"
        } else {
            nftAmount = "n/a".localized
        }

        return .nftAmount(
                iconUrl: iconUrl,
                iconPlaceholderImageName: "placeholder_nft_32",
                nftAmount: nftAmount,
                type: type
        )
    }

    private func doubleAmountViewItem(coinService: CoinService, title: String, value: BigUInt) -> ViewItem {
        let amountData = coinService.amountData(value: value, sign: .plus)

        return .doubleAmount(
                title: title,
                coinAmount: ValueFormatter.instance.formatFull(coinValue: amountData.coinValue) ?? "n/a".localized,
                currencyAmount: amountData.currencyValue.flatMap { ValueFormatter.instance.formatFull(currencyValue: $0) }
        )
    }

    private func sendBaseCoinItems(to: EvmKit.Address, value: BigUInt, sendInfo: SendEvmData.SendInfo?, nonce: Int?) -> [SectionViewItem] {
        let toValue = to.eip55
        let contactData = contactLabelService.contactData(for: toValue)

        var viewItems: [ViewItem] = [
                .subhead(
                        iconName: "arrow_medium_2_up_right_24",
                        title: "send.confirmation.you_send".localized,
                        value: coinServiceFactory.baseCoinService.token.coin.name
                ),
                amountViewItem(
                        coinService: coinServiceFactory.baseCoinService,
                        value: value,
                        type: .neutral
                ),
                .address(
                        title: "send.confirmation.to".localized,
                        value: toValue,
                        valueTitle: sendInfo?.domain ?? evmLabelManager.addressLabel(address: toValue),
                        contactAddress: contactData.contactAddress
                ),
            ]

        if let contactName = contactData.name {
            viewItems.append(.value(title: "send.confirmation.contact_name".localized, value: contactName, type: .regular))
        }

        if let nonce = nonce {
            viewItems.append(.value(title: "send.confirmation.nonce".localized, value: nonce.description, type: .regular))
        }

        return [SectionViewItem(viewItems: viewItems)]
    }

    private func eip20TransferItems(to: EvmKit.Address, value: BigUInt, contractAddress: EvmKit.Address, nonce: Int?, sendInfo: SendEvmData.SendInfo?) -> [SectionViewItem]? {
        guard let coinService = coinServiceFactory.coinService(contractAddress: contractAddress) else {
            return nil
        }

        var viewItems: [ViewItem] = [
            .subhead(
                    iconName: "arrow_medium_2_up_right_24",
                    title: "send.confirmation.you_send".localized,
                    value: coinService.token.coin.name
            ),
            amountViewItem(
                    coinService: coinService,
                    value: value,
                    type: .neutral
            )
        ]

        let addressValue = to.eip55
        let addressTitle = sendInfo?.domain ?? evmLabelManager.addressLabel(address: addressValue)

        let contactData = contactLabelService.contactData(for: addressValue)

        viewItems.append(.address(
                title: "send.confirmation.to".localized,
                value: addressValue,
                valueTitle: addressTitle,
                contactAddress: contactData.contactAddress
            )
        )
        if let contactName = contactData.name {
            viewItems.append(.value(title: "send.confirmation.contact_name".localized, value: contactName, type: .regular))
        }
        if let nonce = nonce {
            viewItems.append(.value(title: "send.confirmation.nonce".localized, value: nonce.description, type: .regular))
        }

        return [SectionViewItem(viewItems: viewItems)]
    }

    private func nftTransferItems(to: EvmKit.Address, value: BigUInt, nonce: Int?, sendInfo: SendEvmData.SendInfo?, tokenId: BigUInt) -> [SectionViewItem]? {

        var viewItems: [ViewItem] = [
            .subhead(
                    iconName: "arrow_medium_2_up_right_24",
                    title: "send.confirmation.you_send".localized,
                    value: sendInfo?.assetShortMetadata?.displayName ?? "#\(tokenId.description)"
            ),
            nftAmountViewItem(value: value, type: .neutral, iconUrl: sendInfo?.assetShortMetadata?.previewImageUrl)
        ]

        let addressValue = to.eip55
        let addressTitle = sendInfo?.domain ?? evmLabelManager.addressLabel(address: addressValue)

        let contactData = contactLabelService.contactData(for: addressValue)

        viewItems.append(.address(
                title: "send.confirmation.to".localized,
                value: addressValue,
                valueTitle: addressTitle,
                contactAddress: contactData.contactAddress
            )
        )
        if let contactName = contactData.name {
            viewItems.append(.value(title: "send.confirmation.contact_name".localized, value: contactName, type: .regular))
        }
        if let nonce = nonce {
            viewItems.append(.value(title: "send.confirmation.nonce".localized, value: nonce.description, type: .regular))
        }

        return [SectionViewItem(viewItems: viewItems)]
    }

    private func eip20ApproveItems(spender: EvmKit.Address, value: BigUInt, contractAddress: EvmKit.Address, additionalInfo: SendEvmData.AdditionInfo?, nonce: Int?) -> [SectionViewItem]? {
        guard let coinService = coinServiceFactory.coinService(contractAddress: contractAddress) else {
            return nil
        }

        let isRevokeAllowance = value == 0  // Check approved new value or revoked last allowance
        let amountItem: ViewItem
        if isRevokeAllowance {
            amountItem = .amount(
                    iconUrl: coinService.token.coin.imageUrl,
                    iconPlaceholderImageName: coinService.token.placeholderImageName,
                    coinAmount: coinService.token.coin.code,
                    currencyAmount: nil,
                    type: .neutral
            )
        } else {
            amountItem = amountViewItem(
                    coinService: coinService,
                    value: value,
                    type: .neutral
            )
        }
        let addressValue = spender.eip55
        let addressTitle = evmLabelManager.addressLabel(address: addressValue)
        let contactData = contactLabelService.contactData(for: addressValue)

        var viewItems: [ViewItem] = [
            .subhead(
                    iconName: "check_2_24",
                    title: isRevokeAllowance ? "approve.confirmation.you_revoke".localized : "approve.confirmation.you_approve".localized,
                    value: coinService.token.coin.name
            ),
            amountItem,
            .address(
                    title: "approve.confirmation.spender".localized,
                    value: addressValue,
                    valueTitle: addressTitle,
                    contactAddress: contactData.contactAddress
            )
        ]

        if let contactName = contactData.name {
            viewItems.append(.value(title: "send.confirmation.contact_name".localized, value: contactName, type: .regular))
        }

        if let nonce = nonce {
            viewItems.append(.value(title: "send.confirmation.nonce".localized, value: nonce.description, type: .regular))
        }

        var sections = [SectionViewItem(viewItems: viewItems)]
        if let section = dAppSection(additionalInfo: additionalInfo) {
            sections.append(section)
        }
        return sections
    }

    private func uniswapItems(amountIn: SwapDecoration.Amount, amountOut: SwapDecoration.Amount, tokenIn: SwapDecoration.Token, tokenOut: SwapDecoration.Token, recipient: EvmKit.Address?, deadline: BigUInt?, swapInfo: SendEvmData.SwapInfo?, nonce: Int?) -> [SectionViewItem]? {
        guard let coinServiceIn = coinService(token: tokenIn), let coinServiceOut = coinService(token: tokenOut) else {
            return nil
        }

        var sections = [SectionViewItem]()

        var inViewItems: [ViewItem] = [
            .subhead(iconName: "arrow_medium_2_up_right_24", title: "swap.you_pay".localized, value: coinServiceIn.token.coin.name)
        ]

        switch amountIn {
        case .exact(let value):
            inViewItems.append(amountViewItem(coinService: coinServiceIn, value: value, type: .neutral))
        case .extremum:
            if let estimatedIn = swapInfo?.estimatedIn {
                inViewItems.append(estimatedAmountViewItem(coinService: coinServiceIn, value: estimatedIn, type: .neutral))
            }
        }

        sections.append(SectionViewItem(viewItems: inViewItems))

        var outViewItems: [ViewItem] = [
            .subhead(iconName: "arrow_medium_2_down_left_24", title: "swap.you_get".localized, value: coinServiceOut.token.coin.name)
        ]

        switch amountOut {
        case .exact(let value):
            outViewItems.append(amountViewItem(coinService: coinServiceOut, value: value, type: .incoming))
        case .extremum:
            if let estimatedOut = swapInfo?.estimatedOut {
                outViewItems.append(estimatedAmountViewItem(coinService: coinServiceOut, value: estimatedOut, type: .incoming))
            }
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
            let addressTitle = swapInfo?.recipientDomain ?? evmLabelManager.addressLabel(address: addressValue)
            let contactData = contactLabelService.contactData(for: addressValue)

            otherViewItems.append(.address(
                    title: "swap.advanced_settings.recipient_address".localized,
                    value: addressValue,
                    valueTitle: addressTitle,
                    contactAddress: contactData.contactAddress
                )
            )
            if let contactName = contactData.name {
                otherViewItems.append(.value(title: "send.confirmation.contact_name".localized, value: contactName, type: .regular))
            }
        }

        if let price = swapInfo?.price {
            otherViewItems.append(.value(title: "swap.price".localized, value: price, type: .regular))
        }
        if let priceImpact = swapInfo?.priceImpact {
            var type: ValueType
            switch priceImpact.level {
            case .normal: type = .warning
            case .warning, .forbidden: type = .alert
            default: type = .regular
            }

            otherViewItems.append(.value(title: "swap.price_impact".localized, value: priceImpact.value, type: type))
        }

        if case .extremum(let value) = amountIn {
            otherViewItems.append(doubleAmountViewItem(coinService: coinServiceIn, title: "swap.confirmation.maximum_sent".localized, value: value))
        } else if case .extremum(let value) = amountOut {
            otherViewItems.append(doubleAmountViewItem(coinService: coinServiceOut, title: "swap.confirmation.minimum_received".localized, value: value))
        }

        if let nonce = nonce {
            otherViewItems.append(.value(title: "send.confirmation.nonce".localized, value: nonce.description, type: .regular))
        }

        if !otherViewItems.isEmpty {
            sections.append(SectionViewItem(viewItems: otherViewItems))
        }

        return sections
    }

    private func oneInchItems(tokenIn: OneInchDecoration.Token, tokenOut: OneInchDecoration.Token?, amountIn: BigUInt, amountOut: OneInchDecoration.Amount, recipient: EvmKit.Address? = nil, oneInchSwapInfo: SendEvmData.OneInchSwapInfo?, nonce: Int?) -> [SectionViewItem]? {
        var coinServiceOut = tokenOut.flatMap { coinService(token: $0) }

        if coinServiceOut == nil, let oneInchSwapInfo = oneInchSwapInfo {
            coinServiceOut = coinService(token: oneInchSwapInfo.tokenTo)
        }

        guard let coinServiceIn = coinService(token: tokenIn), let coinServiceOut = coinServiceOut else {
            return nil
        }

        var sections = [SectionViewItem]()

        sections.append(
                SectionViewItem(viewItems: [
                    .subhead(iconName: "arrow_medium_2_up_right_24", title: "swap.you_pay".localized, value: coinServiceIn.token.coin.code),
                    amountViewItem(coinService: coinServiceIn, value: amountIn, type: .neutral)
                ])
        )

        var outViewItems: [ViewItem] = [
            .subhead(iconName: "arrow_medium_2_down_left_24", title: "swap.you_get".localized, value: coinServiceOut.token.coin.code)
        ]

        switch amountOut {
        case .exact: () // not possible in send
        case .extremum:
            if let estimatedOut = oneInchSwapInfo?.estimatedAmountTo {
                outViewItems.append(estimatedAmountViewItem(coinService: coinServiceOut, value: estimatedOut, type: .incoming))
            }
        }

        if let nonce = nonce {
            outViewItems.append(.value(title: "send.confirmation.nonce".localized, value: nonce.description, type: .regular))
        }

        sections.append(SectionViewItem(viewItems: outViewItems))

        var additionalInfoItems = additionalSectionViewItem(oneInchSwapInfo: oneInchSwapInfo, recipient: recipient)
        if let oneInchSwapInfo = oneInchSwapInfo, let item = swapPriceViewItem(
                amountFrom: oneInchSwapInfo.amountFrom,
                amountTo: oneInchSwapInfo.estimatedAmountTo,
                tokenFrom: oneInchSwapInfo.tokenFrom,
                tokenTo: oneInchSwapInfo.tokenTo) {
            additionalInfoItems.append(item)
        }

        if case .extremum(let value) = amountOut {
            additionalInfoItems.append(doubleAmountViewItem(coinService: coinServiceOut, title: "swap.confirmation.minimum_received".localized, value: value))
        }

        sections.append(SectionViewItem(viewItems: additionalInfoItems))

        return sections
    }

    private func oneInchItems(oneInchSwapInfo: SendEvmData.OneInchSwapInfo) -> [SectionViewItem] {
        let coinServiceIn = coinService(token: oneInchSwapInfo.tokenFrom)
        let coinServiceOut = coinService(token: oneInchSwapInfo.tokenTo)

        var sections = [SectionViewItem]()

        sections.append(SectionViewItem(viewItems: [
            .subhead(iconName: "arrow_medium_2_up_right_24", title: "swap.you_pay".localized, value: coinServiceIn.token.coin.code),
            amountViewItem(coinService: coinServiceIn, value: oneInchSwapInfo.amountFrom, type: .neutral)
        ]))

        let amountOutMinDecimal = oneInchSwapInfo.estimatedAmountTo * (1 - oneInchSwapInfo.slippage / 100)
        let toAmountMin = BigUInt((amountOutMinDecimal * pow(10, oneInchSwapInfo.tokenTo.decimals)).hs.roundedString(decimal: 0)) ?? 0

        sections.append(SectionViewItem(viewItems: [
            .subhead(iconName: "arrow_medium_2_down_left_24", title: "swap.you_get".localized, value: coinServiceOut.token.coin.code),
            estimatedAmountViewItem(coinService: coinServiceOut, value: oneInchSwapInfo.estimatedAmountTo, type: .incoming)
        ]))

        var additionalInfoItems = additionalSectionViewItem(oneInchSwapInfo: oneInchSwapInfo, recipient: oneInchSwapInfo.recipient.flatMap { try? EvmKit.Address(hex: $0.raw) })
        if let item = swapPriceViewItem(amountFrom: oneInchSwapInfo.amountFrom, amountTo: oneInchSwapInfo.estimatedAmountTo, tokenFrom: oneInchSwapInfo.tokenFrom, tokenTo: oneInchSwapInfo.tokenTo) {
            additionalInfoItems.append(item)
        }
        additionalInfoItems.append(doubleAmountViewItem(coinService: coinServiceOut, title: "swap.confirmation.minimum_received".localized, value: toAmountMin))

        sections.append(SectionViewItem(viewItems: additionalInfoItems))

        return sections
    }

    private func swapPriceViewItem(amountFrom: Decimal, amountTo: Decimal, tokenFrom: MarketKit.Token, tokenTo: MarketKit.Token) -> ViewItem? {
        if !amountFrom.isZero && !amountTo.isZero {
            let executionPrice = amountTo / amountFrom
            let reverted = amountTo < amountFrom

            let coinValue = CoinValue(kind: .token(token: reverted ? tokenFrom : tokenTo), value: reverted ? 1 / executionPrice : executionPrice)
            let fullValue = ValueFormatter.instance.formatFull(coinValue: coinValue).map { "1 " + [(reverted ? tokenTo : tokenFrom).coin.code, $0].joined(separator: " = ") } ?? ""
            return .value(title: "swap.price".localized, value: fullValue, type: .regular)
        }
        return nil

    }

    private func additionalSectionViewItem(oneInchSwapInfo: SendEvmData.OneInchSwapInfo?, recipient: EvmKit.Address?) -> [ViewItem] {
        var viewItems = [ViewItem]()

        if let slippage = oneInchSwapInfo?.slippage, let formattedSlippage = formatted(slippage: slippage) {
            viewItems.append(.value(title: "swap.advanced_settings.slippage".localized, value: formattedSlippage, type: .regular))
        }

        let addressValue = recipient?.eip55 ?? oneInchSwapInfo?.recipient?.raw
        if let addressValue {
            let addressTitle = oneInchSwapInfo?.recipient?.domain ?? evmLabelManager.addressLabel(address: addressValue)
            let contactData = contactLabelService.contactData(for: addressValue)

            viewItems.append(.address(
                    title: "swap.advanced_settings.recipient_address".localized,
                    value: addressValue,
                    valueTitle: addressTitle,
                    contactAddress: contactData.contactAddress
                )
            )
            if let contactName = contactData.name {
                viewItems.append(.value(title: "send.confirmation.contact_name".localized, value: contactName, type: .regular))
            }
        }

        return viewItems
    }

    private func unknownMethodItems(transactionData: TransactionData, dAppInfo: SendEvmData.DAppInfo?, nonce: Int?) -> [SectionViewItem] {
        let toValue = transactionData.to.eip55
        let contactData = contactLabelService.contactData(for: toValue)

        var viewItems: [ViewItem] = [
            amountViewItem(
                    coinService: coinServiceFactory.baseCoinService,
                    value: transactionData.value,
                    type: .neutral
            ),
            .address(
                    title: "send.confirmation.to".localized,
                    value: toValue,
                    valueTitle: evmLabelManager.addressLabel(address: toValue),
                    contactAddress: contactData.contactAddress
            )
        ]

        if let contactName = contactData.name {
            viewItems.append(.value(title: "send.confirmation.contact_name".localized, value: contactName, type: .regular))
        }

        if let nonce = nonce {
            viewItems.append(.value(title: "send.confirmation.nonce".localized, value: nonce.description, type: .regular))
        }

        viewItems.append(.input(value: transactionData.input.hs.hexString))

        if let methodName = service.methodName(input: transactionData.input) {
            viewItems.append(.value(title: "send.confirmation.method".localized, value: methodName, type: .regular))
        }

        var sections = [SectionViewItem(viewItems: viewItems)]
        if let section = dAppSection(additionalInfo: dAppInfo) {
            sections.append(section)
        }

        return sections
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

    private func coinService(token: MarketKit.Token) -> CoinService {
        coinServiceFactory.coinService(token: token)
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
        case subhead(iconName: String, title: String, value: String)
        case amount(iconUrl: String?, iconPlaceholderImageName: String, coinAmount: String, currencyAmount: String?, type: AmountType)
        case nftAmount(iconUrl: String?, iconPlaceholderImageName: String, nftAmount: String, type: AmountType)
        case doubleAmount(title: String, coinAmount: String, currencyAmount: String?)
        case address(title: String, value: String, valueTitle: String?, contactAddress: ContactAddress?)
        case value(title: String, value: String, type: ValueType)
        case input(value: String)
    }

}
