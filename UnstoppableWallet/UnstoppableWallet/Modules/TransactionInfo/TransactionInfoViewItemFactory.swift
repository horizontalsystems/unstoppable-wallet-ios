import EvmKit
import Foundation
import MarketKit

class TransactionInfoViewItemFactory {
    private let zeroAddress = "0x0000000000000000000000000000000000000000"

    private let evmLabelManager: EvmLabelManager
    private let contactLabelService: ContactLabelService

    private let actionEnabled: Bool
    var priceReversed = false

    init(evmLabelManager: EvmLabelManager, contactLabelService: ContactLabelService, actionEnabled: Bool) {
        self.evmLabelManager = evmLabelManager
        self.actionEnabled = actionEnabled
        self.contactLabelService = contactLabelService
    }

    private func amount(source: TransactionSource, title: String, subtitle: String?, appValue: AppValue, rate: CurrencyValue?, type: AmountType, balanceHidden: Bool) -> TransactionInfoModule.ViewItem {
        let iconUrl = appValue.coin?.imageUrl
        let iconAlternativeUrl = appValue.coin?.image
        let iconPlaceholderImageName = source.blockchainType.placeholderImageName(tokenProtocol: appValue.tokenProtocol)

        let coin = appValue.token.flatMap { $0.isCustom ? nil : $0.coin }

        if appValue.isMaxValue {
            return .amount(
                title: title,
                subtitle: subtitle,
                iconUrl: iconUrl,
                iconAlternativeUrl: iconAlternativeUrl,
                iconPlaceholderImageName: iconPlaceholderImageName,
                coinAmount: balanceHidden ? BalanceHiddenManager.placeholder : "∞ \(appValue.code)",
                currencyAmount: balanceHidden ? BalanceHiddenManager.placeholder : "transactions.value.unlimited".localized,
                type: type,
                coin: coin
            )
        } else {
            var currencyValue: CurrencyValue?

            if let rate {
                currencyValue = CurrencyValue(currency: rate.currency, value: rate.value * appValue.value)
            }

            return .amount(
                title: title,
                subtitle: subtitle,
                iconUrl: iconUrl,
                iconAlternativeUrl: iconAlternativeUrl,
                iconPlaceholderImageName: iconPlaceholderImageName,
                coinAmount: balanceHidden ? BalanceHiddenManager.placeholder : appValue.formattedFull(signType: type.signType) ?? "n/a".localized,
                currencyAmount: balanceHidden ? BalanceHiddenManager.placeholder : currencyValue.flatMap { ValueFormatter.instance.formatFull(currencyValue: $0) },
                type: type,
                coin: coin
            )
        }
    }

    private func nftAmount(source _: TransactionSource, appValue: AppValue, type: AmountType, metadata: NftAssetBriefMetadata?, balanceHidden: Bool) -> TransactionInfoModule.ViewItem {
        .nftAmount(
            iconUrl: metadata?.previewImageUrl,
            iconPlaceholderImageName: "placeholder_nft_32",
            nftAmount: balanceHidden ? BalanceHiddenManager.placeholder : appValue.formattedFull(signType: type.signType) ?? "n/a".localized,
            type: type,
            providerCollectionUid: metadata?.providerCollectionUid,
            nftUid: metadata?.nftUid
        )
    }

    private func feeString(appValue: AppValue, rate: CurrencyValue?) -> String {
        var parts = [String]()

        if let formattedCoinValue = appValue.formattedFull() {
            parts.append(formattedCoinValue)
        }

        if let rate {
            if let formattedCurrencyValue = ValueFormatter.instance.formatFull(currency: rate.currency, value: rate.value * appValue.value) {
                parts.append(formattedCurrencyValue)
            }
        }

        return parts.joined(separator: " | ")
    }

    private func priceString(valueIn: AppValue, valueOut: AppValue, coinPriceIn: CurrencyValue?) -> String? {
        guard let coinIn = valueIn.coin, let coinOut = valueOut.coin else {
            return nil
        }

        var priceDecimal = valueIn.value.magnitude / valueOut.value.magnitude
        if priceReversed {
            priceDecimal = 1 / priceDecimal
        }

        let symbolOut = priceReversed ? coinIn.code : coinOut.code
        let symbolIn = priceReversed ? coinOut.code : coinIn.code
        let price = ValueFormatter.instance.formatFull(value: priceDecimal, decimalCount: priceDecimal.decimalCount, symbol: symbolIn) ?? ""
        let rate = coinPriceIn.map { CurrencyValue(currency: $0.currency, value: abs((priceReversed ? 1 : priceDecimal) * $0.value)) }
        let rateFormatted = rate.flatMap { ValueFormatter.instance.formatFull(currencyValue: $0).map { " (\($0))" } } ?? ""

        return "\(symbolOut) = \(price)\(rateFormatted)"
    }

    private func rateString(currencyValue: CurrencyValue?, coinCode: String?) -> String {
        guard let currencyValue, let coinCode else {
            return "---"
        }

        let formattedValue = ValueFormatter.instance.formatFull(currencyValue: currencyValue) ?? ""

        return "balance.rate_per_coin".localized(formattedValue, coinCode)
    }

    private func youPayString(status: TransactionStatus) -> String {
        if case .completed = status {
            return "tx_info.you_paid".localized
        } else {
            return "tx_info.you_pay".localized
        }
    }

    private func youGetString(status: TransactionStatus) -> String {
        if case .completed = status {
            return "tx_info.you_got".localized
        } else {
            return "tx_info.you_get".localized
        }
    }

    private func fullBadge(appValue: AppValue) -> String? {
        switch appValue.kind {
        case let .token(token):
            return token.fullBadge
        case let .eip20Token(tokenName, _, _):
            return tokenName
        default:
            return nil
        }
    }

    private func sendSection(source: TransactionSource, appValue: AppValue, to: String?, rates: [Coin: CurrencyValue], nftMetadata: [NftUid: NftAssetBriefMetadata] = [:], sentToSelf: Bool = false, balanceHidden: Bool) -> [TransactionInfoModule.ViewItem] {
        var viewItems = [TransactionInfoModule.ViewItem]()

        let burn = to == zeroAddress
        var rateViewItem: TransactionInfoModule.ViewItem?

        switch appValue.kind {
        case let .nft(nftUid, tokenName, _):
            viewItems.append(
                .actionTitle(
                    iconName: burn ? "flame_24" : "arrow_medium_2_up_right_24",
                    iconDimmed: true,
                    title: burn ? "transactions.burn".localized : "transactions.send".localized,
                    subTitle: nftMetadata[nftUid]?.name ?? tokenName.map { "\($0) #\(nftUid.tokenId)" } ?? "#\(nftUid.tokenId)"
                )
            )

            viewItems.append(
                nftAmount(
                    source: source,
                    appValue: appValue,
                    type: type(appValue: appValue, condition: sentToSelf, .neutral, .outgoing),
                    metadata: nftMetadata[nftUid],
                    balanceHidden: balanceHidden
                )
            )
        default:
            let rate = appValue.coin.flatMap { rates[$0] }

            viewItems.append(
                amount(
                    source: source,
                    title: burn ? "transactions.burn".localized : "transactions.send".localized,
                    subtitle: fullBadge(appValue: appValue),
                    appValue: appValue,
                    rate: rate,
                    type: type(appValue: appValue, condition: sentToSelf, .neutral, .outgoing),
                    balanceHidden: balanceHidden
                )
            )

            rateViewItem = .rate(value: rateString(currencyValue: rate, coinCode: appValue.coin?.code))
        }

        if !burn, let to {
            let contactData = contactLabelService.contactData(for: to)
            let valueTitle = contactData.name == nil ? evmLabelManager.addressLabel(address: to) : nil

            viewItems.append(.to(value: to, valueTitle: valueTitle, contactAddress: contactData.contactAddress))

            if let name = contactData.name {
                viewItems.append(.contactName(name: name))
            }
        }

        if let rateViewItem {
            viewItems.append(rateViewItem)
        }

        return viewItems
    }

    private func type(appValue: AppValue, condition: Bool = true, _ trueType: AmountType, _ falseType: AmountType? = nil) -> AmountType {
        guard !appValue.zeroValue else {
            return .neutral
        }

        return condition ? trueType : (falseType ?? trueType)
    }

    private func receiveSection(source: TransactionSource, appValue: AppValue, from: String?, rates: [Coin: CurrencyValue], nftMetadata: [NftUid: NftAssetBriefMetadata] = [:], memo: String? = nil, status: TransactionStatus? = nil, balanceHidden: Bool) -> [TransactionInfoModule.ViewItem] {
        var viewItems = [TransactionInfoModule.ViewItem]()

        let mint = from == zeroAddress
        var rateViewItem: TransactionInfoModule.ViewItem?

        switch appValue.kind {
        case let .nft(nftUid, tokenName, _):
            viewItems.append(
                .actionTitle(
                    iconName: "arrow_medium_2_down_left_24",
                    iconDimmed: true,
                    title: mint ? "transactions.mint".localized : "transactions.receive".localized,
                    subTitle: nftMetadata[nftUid]?.name ?? tokenName.map { "\($0) #\(nftUid.tokenId)" } ?? "#\(nftUid.tokenId)"
                )
            )
            viewItems.append(
                nftAmount(
                    source: source,
                    appValue: appValue,
                    type: type(appValue: appValue, .incoming),
                    metadata: nftMetadata[nftUid],
                    balanceHidden: balanceHidden
                )
            )
        default:
            let rate = appValue.coin.flatMap { rates[$0] }

            viewItems.append(
                amount(
                    source: source,
                    title: mint ? "transactions.mint".localized : "transactions.receive".localized,
                    subtitle: fullBadge(appValue: appValue),
                    appValue: appValue,
                    rate: rate,
                    type: type(appValue: appValue, .incoming),
                    balanceHidden: balanceHidden
                )
            )

            rateViewItem = .rate(value: rateString(currencyValue: rate, coinCode: appValue.coin?.code))
        }

        if !mint, let from {
            let contactData = contactLabelService.contactData(for: from)
            let valueTitle = contactData.name == nil ? evmLabelManager.addressLabel(address: from) : nil

            viewItems.append(.from(value: from, valueTitle: valueTitle, contactAddress: contactData.contactAddress))

            if let name = contactData.name {
                viewItems.append(.contactName(name: name))
            }
        }

        if let rateViewItem {
            viewItems.append(rateViewItem)
        }

        if let memo {
            viewItems.append(.memo(text: memo))
        }

        if let status {
            viewItems.append(.status(status: status))
        }

        return viewItems
    }

    private func bitcoinViewItems(record: BitcoinTransactionRecord, lastBlockInfo: LastBlockInfo?) -> [TransactionInfoModule.ViewItem] {
        var viewItems = [TransactionInfoModule.ViewItem]()

        if record.showRawTransaction {
            viewItems.append(.rawTransaction)
        }
        if let conflictingHash = record.conflictingHash {
            viewItems.append(.doubleSpend(txHash: record.transactionHash, conflictingTxHash: conflictingHash))
        }
        if let lockState = record.lockState(lastBlockTimestamp: lastBlockInfo?.timestamp) {
            viewItems.append(.lockInfo(lockState: lockState))
        }
        if let memo = record.memo {
            viewItems.append(.memo(text: memo))
        }

        return viewItems
    }

    func items(item: TransactionInfoService.Item, balanceHidden: Bool) -> [TransactionInfoModule.SectionViewItem] {
        func _rate(_ coin: Coin?) -> CurrencyValue? {
            coin.flatMap { item.rates[$0] }
        }

        let record = item.record
        var feeViewItem: TransactionInfoModule.ViewItem?
        let status = record.status(lastBlockHeight: item.lastBlockInfo?.height)

        var sections = [TransactionInfoModule.SectionViewItem]()

        if item.record.spam {
            sections.append(.init([.warning(text: "tx_info.scam_warning".localized)]))
        }

        switch record {
        case let record as ContractCreationTransactionRecord:
            sections.append(.init([
                .actionTitle(iconName: record.source.blockchainType.iconPlain32, iconDimmed: false, title: "transactions.contract_creation".localized, subTitle: nil),
            ]))

        case let record as EvmOutgoingTransactionRecord:
            sections.append(.init(sendSection(source: record.source, appValue: record.value, to: record.to, rates: item.rates, nftMetadata: item.nftMetadata, sentToSelf: record.sentToSelf, balanceHidden: balanceHidden)))

            if record.sentToSelf {
                sections.append(.init([.sentToSelf]))
            }

        case let record as EvmIncomingTransactionRecord:
            sections.append(.init(receiveSection(source: record.source, appValue: record.value, from: record.from, rates: item.rates, balanceHidden: balanceHidden)))

        case let record as ApproveTransactionRecord:
            let appValue = record.value
            let rate = _rate(appValue.coin)
            let contactData = contactLabelService.contactData(for: record.spender)
            let valueTitle = contactData.name == nil ? evmLabelManager.addressLabel(address: record.spender) : nil

            var viewItems: [TransactionInfoModule.ViewItem] = [
                amount(source: record.source, title: "transactions.approve".localized, subtitle: fullBadge(appValue: appValue), appValue: appValue, rate: rate, type: .neutral, balanceHidden: balanceHidden),
                .spender(value: record.spender, valueTitle: valueTitle, contactAddress: contactData.contactAddress),
            ]

            if let name = contactData.name {
                viewItems.append(.contactName(name: name))
            }

            viewItems.append(.rate(value: rateString(currencyValue: rate, coinCode: appValue.coin?.code)))

            sections.append(.init(viewItems))

        case let record as SwapTransactionRecord:
            var amountViewItems: [TransactionInfoModule.ViewItem] = [
                amount(source: record.source, title: youPayString(status: status), subtitle: fullBadge(appValue: record.valueIn), appValue: record.valueIn, rate: _rate(record.valueIn.coin), type: type(appValue: record.valueIn, .outgoing), balanceHidden: balanceHidden),
            ]

            if let valueOut = record.valueOut {
                amountViewItems.append(amount(source: record.source, title: youGetString(status: status), subtitle: fullBadge(appValue: valueOut), appValue: valueOut, rate: _rate(valueOut.coin), type: type(appValue: valueOut, condition: record.recipient == nil, .incoming, .outgoing), balanceHidden: balanceHidden))
            }

            sections.append(.init(amountViewItems))

            if let recipient = record.recipient {
                let contactData = contactLabelService.contactData(for: recipient)
                let valueTitle = contactData.name == nil ? evmLabelManager.addressLabel(address: recipient) : nil
                var viewItems: [TransactionInfoModule.ViewItem] = [
                    .recipient(value: recipient, valueTitle: valueTitle, contactAddress: contactData.contactAddress),
                ]

                if let name = contactData.name {
                    viewItems.append(.contactName(name: name))
                }

                sections.append(.init(viewItems))
            }

            var viewItems: [TransactionInfoModule.ViewItem] = [
                .service(value: evmLabelManager.mapped(address: record.exchangeAddress)),
            ]

            if let valueOut = record.valueOut {
                switch status {
                case .pending, .processing, .completed:
                    if let priceString = priceString(valueIn: record.valueIn, valueOut: valueOut, coinPriceIn: _rate(record.valueIn.coin)) {
                        viewItems.append(.price(price: priceString))
                    }
                default: ()
                }
            }

            sections.append(.init(viewItems))

        case let record as UnknownSwapTransactionRecord:
            var amountViewItems = [TransactionInfoModule.ViewItem]()

            if let valueIn = record.valueIn {
                amountViewItems.append(
                    amount(source: record.source, title: youPayString(status: status), subtitle: fullBadge(appValue: valueIn), appValue: valueIn, rate: _rate(valueIn.coin), type: type(appValue: valueIn, .outgoing), balanceHidden: balanceHidden)
                )
            }

            if let valueOut = record.valueOut {
                amountViewItems.append(
                    amount(source: record.source, title: youGetString(status: status), subtitle: fullBadge(appValue: valueOut), appValue: valueOut, rate: _rate(valueOut.coin), type: type(appValue: valueOut, .incoming), balanceHidden: balanceHidden)
                )
            }

            if !amountViewItems.isEmpty {
                sections.append(.init(amountViewItems))
            }

            var viewItems: [TransactionInfoModule.ViewItem] = [
                .service(value: evmLabelManager.mapped(address: record.exchangeAddress)),
            ]

            if let valueIn = record.valueIn, let valueOut = record.valueOut {
                switch status {
                case .pending, .processing, .completed:
                    if let priceString = priceString(valueIn: valueIn, valueOut: valueOut, coinPriceIn: _rate(valueIn.coin)) {
                        viewItems.append(.price(price: priceString))
                    }
                default: ()
                }
            }

            sections.append(.init(viewItems))

        case let record as ContractCallTransactionRecord:
            sections.append(.init([
                .actionTitle(iconName: record.source.blockchainType.iconPlain32, iconDimmed: false, title: record.method ?? "transactions.contract_call".localized, subTitle: evmLabelManager.mapped(address: record.contractAddress)),
            ]))

            for event in record.outgoingEvents {
                sections.append(.init(sendSection(source: record.source, appValue: event.value, to: event.address, rates: item.rates, nftMetadata: item.nftMetadata, balanceHidden: balanceHidden)))
            }

            for event in record.incomingEvents {
                sections.append(.init(receiveSection(source: record.source, appValue: event.value, from: event.address, rates: item.rates, nftMetadata: item.nftMetadata, balanceHidden: balanceHidden)))
            }

        case let record as ExternalContractCallTransactionRecord:
            for event in record.outgoingEvents {
                sections.append(.init(sendSection(source: record.source, appValue: event.value, to: event.address, rates: item.rates, nftMetadata: item.nftMetadata, balanceHidden: balanceHidden)))
            }

            for event in record.incomingEvents {
                sections.append(.init(receiveSection(source: record.source, appValue: event.value, from: event.address, rates: item.rates, nftMetadata: item.nftMetadata, balanceHidden: balanceHidden)))
            }

        case let record as TronIncomingTransactionRecord:
            sections.append(.init(receiveSection(source: record.source, appValue: record.value, from: record.from, rates: item.rates, balanceHidden: balanceHidden)))

        case let record as TronOutgoingTransactionRecord:
            sections.append(.init(sendSection(source: record.source, appValue: record.value, to: record.to, rates: item.rates, nftMetadata: item.nftMetadata, sentToSelf: record.sentToSelf, balanceHidden: balanceHidden)))

            if record.sentToSelf {
                sections.append(.init([.sentToSelf]))
            }

        case let record as TronApproveTransactionRecord:
            let appValue = record.value
            let rate = _rate(appValue.coin)
            let contactData = contactLabelService.contactData(for: record.spender)
            let valueTitle = contactData.name == nil ? evmLabelManager.addressLabel(address: record.spender) : nil

            var viewItems: [TransactionInfoModule.ViewItem] = [
                amount(source: record.source, title: "transactions.approve".localized, subtitle: fullBadge(appValue: appValue), appValue: appValue, rate: rate, type: .neutral, balanceHidden: balanceHidden),
                .spender(value: record.spender, valueTitle: valueTitle, contactAddress: contactData.contactAddress),
            ]

            if let name = contactData.name {
                viewItems.append(.contactName(name: name))
            }

            viewItems.append(.rate(value: rateString(currencyValue: rate, coinCode: appValue.coin?.code)))

            sections.append(.init(viewItems))

        case let record as TronContractCallTransactionRecord:
            sections.append(.init([
                .actionTitle(iconName: record.source.blockchainType.iconPlain32, iconDimmed: false, title: record.method ?? "transactions.contract_call".localized, subTitle: evmLabelManager.mapped(address: record.contractAddress)),
            ]))

            for event in record.outgoingEvents {
                sections.append(.init(sendSection(source: record.source, appValue: event.value, to: event.address, rates: item.rates, nftMetadata: item.nftMetadata, balanceHidden: balanceHidden)))
            }

            for event in record.incomingEvents {
                sections.append(.init(receiveSection(source: record.source, appValue: event.value, from: event.address, rates: item.rates, nftMetadata: item.nftMetadata, balanceHidden: balanceHidden)))
            }

        case let record as TronExternalContractCallTransactionRecord:
            for event in record.outgoingEvents {
                sections.append(.init(sendSection(source: record.source, appValue: event.value, to: event.address, rates: item.rates, nftMetadata: item.nftMetadata, balanceHidden: balanceHidden)))
            }

            for event in record.incomingEvents {
                sections.append(.init(receiveSection(source: record.source, appValue: event.value, from: event.address, rates: item.rates, nftMetadata: item.nftMetadata, balanceHidden: balanceHidden)))
            }

        case let record as TronTransactionRecord:
            sections.append(.init([
                .actionTitle(iconName: record.source.blockchainType.iconPlain32, iconDimmed: false, title: record.transaction.contract?.label ?? "transactions.contract_call".localized, subTitle: ""),
            ]))

        case let record as BitcoinIncomingTransactionRecord:
            sections.append(.init(receiveSection(source: record.source, appValue: record.value, from: record.from, rates: item.rates, balanceHidden: balanceHidden)))

            let additionalViewItems = bitcoinViewItems(record: record, lastBlockInfo: item.lastBlockInfo)
            if !additionalViewItems.isEmpty {
                sections.append(.init(additionalViewItems))
            }

        case let record as BitcoinOutgoingTransactionRecord:
            sections.append(.init(sendSection(source: record.source, appValue: record.value, to: record.to, rates: item.rates, sentToSelf: record.sentToSelf, balanceHidden: balanceHidden)))

            var additionalViewItems = bitcoinViewItems(record: record, lastBlockInfo: item.lastBlockInfo)

            if record.sentToSelf {
                additionalViewItems.insert(.sentToSelf, at: 0)
            }

            if !additionalViewItems.isEmpty {
                sections.append(.init(additionalViewItems))
            }

            if let fee = record.fee {
                feeViewItem = .fee(title: "tx_info.fee".localized, value: feeString(appValue: fee, rate: _rate(fee.coin)))
            }

            if actionEnabled, record.replaceable {
                sections.append(.init([
                    .option(option: .resend(type: .speedUp)),
                    .option(option: .resend(type: .cancel)),
                ], footer: "tx_info.resend_description".localized))
            }

        case let record as TonTransactionRecord:
            for action in record.actions {
                var viewItems: [TransactionInfoModule.ViewItem]

                switch action.type {
                case let .send(value, to, sentToSelf, comment):
                    viewItems = sendSection(source: record.source, appValue: value, to: to, rates: item.rates, sentToSelf: sentToSelf, balanceHidden: balanceHidden)

                    if let comment {
                        viewItems.append(.memo(text: comment))
                    }

                    if sentToSelf {
                        viewItems.append(.sentToSelf)
                    }

                case let .receive(value, from, comment):
                    viewItems = receiveSection(source: record.source, appValue: value, from: from, rates: item.rates, balanceHidden: balanceHidden)

                    if let comment {
                        viewItems.append(.memo(text: comment))
                    }

                case let .burn(value):
                    viewItems = sendSection(source: record.source, appValue: value, to: zeroAddress, rates: item.rates, balanceHidden: balanceHidden)

                case let .mint(value):
                    viewItems = receiveSection(source: record.source, appValue: value, from: zeroAddress, rates: item.rates, balanceHidden: balanceHidden)

                case let .swap(routerName, routerAddress, valueIn, valueOut):
                    viewItems = [
                        amount(source: record.source, title: youPayString(status: status), subtitle: fullBadge(appValue: valueIn), appValue: valueIn, rate: _rate(valueIn.coin), type: type(appValue: valueIn, .outgoing), balanceHidden: balanceHidden),
                        amount(source: record.source, title: youGetString(status: status), subtitle: fullBadge(appValue: valueOut), appValue: valueOut, rate: _rate(valueOut.coin), type: type(appValue: valueOut, .incoming), balanceHidden: balanceHidden),
                        .service(value: routerName ?? routerAddress.shortened),
                    ]

                    if let priceString = priceString(valueIn: valueIn, valueOut: valueOut, coinPriceIn: _rate(valueIn.coin)) {
                        viewItems.append(.price(price: priceString))
                    }

                case let .contractDeploy(interfaces):
                    viewItems = [
                        .actionTitle(iconName: nil, iconDimmed: false, title: "transactions.contract_deploy".localized, subTitle: interfaces.joined(separator: ", ")),
                    ]

                case let .contractCall(address, value, operation):
                    viewItems = [
                        .actionTitle(iconName: record.source.blockchainType.iconPlain32, iconDimmed: false, title: "transactions.contract_call".localized, subTitle: operation),
                        .to(value: address, valueTitle: nil, contactAddress: nil),
                    ]

                    viewItems.append(contentsOf: sendSection(source: record.source, appValue: value, to: nil, rates: item.rates, balanceHidden: balanceHidden))

                case let .unsupported(type):
                    viewItems = [.fee(title: "Action", value: type)]
                }

                switch action.status {
                case .failed:
                    viewItems.append(.status(status: action.status))
                default: ()
                }

                sections.append(.init(viewItems))
            }

            feeViewItem = record.fee.map { .fee(title: "tx_info.fee".localized, value: feeString(appValue: $0, rate: _rate($0.coin))) }

        case let record as StellarTransactionRecord:
            var viewItems: [TransactionInfoModule.ViewItem]

            switch record.type {
            case let .accountCreated(startingBalance, funder):
                viewItems = receiveSection(source: record.source, appValue: startingBalance, from: funder, rates: item.rates, balanceHidden: balanceHidden)

            case let .accountFunded(startingBalance, account):
                viewItems = sendSection(source: record.source, appValue: startingBalance, to: account, rates: item.rates, balanceHidden: balanceHidden)

            case let .sendPayment(value, to, sentToSelf):
                viewItems = sendSection(source: record.source, appValue: value, to: to, rates: item.rates, sentToSelf: sentToSelf, balanceHidden: balanceHidden)

                if sentToSelf {
                    viewItems.append(.sentToSelf)
                }

            case let .receivePayment(value, from):
                viewItems = receiveSection(source: record.source, appValue: value, from: from, rates: item.rates, balanceHidden: balanceHidden)

            case let .changeTrust(value, trustor, trustee, liquidityPoolId):
                let rate = _rate(value.coin)

                viewItems = [
                    amount(source: record.source, title: "Change Trust", subtitle: nil, appValue: value, rate: rate, type: .neutral, balanceHidden: balanceHidden),
                ]

                viewItems.append(.rate(value: rateString(currencyValue: rate, coinCode: value.coin?.code)))

            case let .unsupported(type):
                viewItems = [.fee(title: "Operation", value: type)]
            }

            if let memo = record.operation.memo {
                viewItems.append(.memo(text: memo))
            }

            sections.append(.init(viewItems))

            feeViewItem = record.fee.map { .fee(title: "tx_info.fee".localized, value: feeString(appValue: $0, rate: _rate($0.coin))) }

        case let record as ZcashShieldingTransactionRecord:
            sections.append(.init([.actionTitle(iconName: record.direction.txIconName, iconDimmed: false, title: record.direction.txTitle, subTitle: nil)]))

            sections.append(.init(sendSection(source: record.source, appValue: record.value, to: nil, rates: item.rates, sentToSelf: true, balanceHidden: balanceHidden)))

            var additionalViewItems = bitcoinViewItems(record: record, lastBlockInfo: item.lastBlockInfo)
            additionalViewItems.insert(.sentToSelf, at: 0)

            sections.append(.init(additionalViewItems))

            if let fee = record.fee {
                feeViewItem = .fee(title: "tx_info.fee".localized, value: feeString(appValue: fee, rate: _rate(fee.coin)))
            }

        default: ()
        }

        var transactionViewItems: [TransactionInfoModule.ViewItem] = [
            .date(date: record.date),
            .status(status: status),
        ]

        if let evmRecord = record as? EvmTransactionRecord, evmRecord.ownTransaction, let appValue = evmRecord.fee {
            let title: String
            switch status {
            case .pending: title = "tx_info.fee.estimated".localized
            case .processing, .failed, .completed: title = "tx_info.fee".localized
            }

            feeViewItem = .fee(
                title: title,
                value: feeString(appValue: appValue, rate: _rate(appValue.coin))
            )
        }

        if let tronRecord = record as? TronTransactionRecord, tronRecord.ownTransaction, let appValue = tronRecord.fee {
            let title: String
            switch status {
            case .pending: title = "tx_info.fee.estimated".localized
            case .processing, .failed, .completed: title = "tx_info.fee".localized
            }

            feeViewItem = .fee(
                title: title,
                value: feeString(appValue: appValue, rate: _rate(appValue.coin))
            )
        }

        if let feeViewItem {
            transactionViewItems.append(feeViewItem)
        }

        transactionViewItems.append(.id(value: record.transactionHash))

        sections.append(.init(transactionViewItems))

        if actionEnabled, let evmRecord = record as? EvmTransactionRecord, evmRecord.ownTransaction, status.isPending, !evmRecord.protected {
            sections.append(.init([
                .option(option: .resend(type: .speedUp)),
                .option(option: .resend(type: .cancel)),
            ], footer: "tx_info.resend_description".localized))
        }

        sections.append(.init([
            .explorer(title: "tx_info.view_on".localized(item.explorerTitle), url: item.explorerUrl),
        ]))

        return sections
    }
}
