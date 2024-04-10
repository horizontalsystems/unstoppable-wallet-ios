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

    private func amount(source: TransactionSource, title: String, subtitle: String?, transactionValue: TransactionValue, rate: CurrencyValue?, type: AmountType, balanceHidden: Bool) -> TransactionInfoModule.ViewItem {
        let iconUrl = transactionValue.coin?.imageUrl
        let iconPlaceholderImageName = source.blockchainType.placeholderImageName(tokenProtocol: transactionValue.tokenProtocol)

        if transactionValue.isMaxValue {
            return .amount(
                title: title,
                subtitle: subtitle,
                iconUrl: iconUrl,
                iconPlaceholderImageName: iconPlaceholderImageName,
                coinAmount: balanceHidden ? BalanceHiddenManager.placeholder : "∞ \(transactionValue.coinCode)",
                currencyAmount: balanceHidden ? BalanceHiddenManager.placeholder : "transactions.value.unlimited".localized,
                type: type,
                coinUid: transactionValue.coin?.uid
            )
        } else {
            var currencyValue: CurrencyValue?

            if let rate, let value = transactionValue.decimalValue {
                currencyValue = CurrencyValue(currency: rate.currency, value: rate.value * value)
            }

            return .amount(
                title: title,
                subtitle: subtitle,
                iconUrl: iconUrl,
                iconPlaceholderImageName: iconPlaceholderImageName,
                coinAmount: balanceHidden ? BalanceHiddenManager.placeholder : transactionValue.formattedFull(showSign: type.showSign) ?? "n/a".localized,
                currencyAmount: balanceHidden ? BalanceHiddenManager.placeholder : currencyValue.flatMap { ValueFormatter.instance.formatFull(currencyValue: $0) },
                type: type,
                coinUid: transactionValue.coin?.uid
            )
        }
    }

    private func nftAmount(source _: TransactionSource, transactionValue: TransactionValue, type: AmountType, metadata: NftAssetBriefMetadata?, balanceHidden: Bool) -> TransactionInfoModule.ViewItem {
        .nftAmount(
            iconUrl: metadata?.previewImageUrl,
            iconPlaceholderImageName: "placeholder_nft_32",
            nftAmount: balanceHidden ? BalanceHiddenManager.placeholder : transactionValue.formattedFull(showSign: type.showSign) ?? "n/a".localized,
            type: type,
            providerCollectionUid: metadata?.providerCollectionUid,
            nftUid: metadata?.nftUid
        )
    }

    private func feeString(transactionValue: TransactionValue, rate: CurrencyValue?) -> String {
        var parts = [String]()

        if let formattedCoinValue = transactionValue.formattedFull() {
            parts.append(formattedCoinValue)
        }

        if let rate, case let .coinValue(_, value) = transactionValue {
            if let formattedCurrencyValue = ValueFormatter.instance.formatFull(currency: rate.currency, value: rate.value * value) {
                parts.append(formattedCurrencyValue)
            }
        }

        return parts.joined(separator: " | ")
    }

    private func priceString(valueIn: TransactionValue, valueOut: TransactionValue, coinPriceIn: CurrencyValue?) -> String? {
        guard case let .coinValue(valueInToken, valueInDecimal) = valueIn,
              case let .coinValue(valueOutToken, valueOutDecimal) = valueOut
        else {
            return nil
        }

        var priceDecimal = valueInDecimal.magnitude / valueOutDecimal.magnitude
        if priceReversed {
            priceDecimal = 1 / priceDecimal
        }

        let symbolOut = priceReversed ? valueInToken.coin.code : valueOutToken.coin.code
        let symbolIn = priceReversed ? valueOutToken.coin.code : valueInToken.coin.code
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

    private func fullBadge(transactionValue: TransactionValue) -> String? {
        switch transactionValue {
        case let .coinValue(token, _):
            return token.fullBadge
        case let .tokenValue(tokenName, _, _, _):
            return tokenName
        default:
            return nil
        }
    }

    private func sendSection(source: TransactionSource, transactionValue: TransactionValue, to: String?, rates: [Coin: CurrencyValue], nftMetadata: [NftUid: NftAssetBriefMetadata] = [:], sentToSelf: Bool = false, balanceHidden: Bool) -> [TransactionInfoModule.ViewItem] {
        var viewItems = [TransactionInfoModule.ViewItem]()

        let burn = to == zeroAddress
        var rateViewItem: TransactionInfoModule.ViewItem?

        switch transactionValue {
        case let .nftValue(nftUid, _, tokenName, _):
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
                    transactionValue: transactionValue,
                    type: type(value: transactionValue, condition: sentToSelf, .neutral, .outgoing),
                    metadata: nftMetadata[nftUid],
                    balanceHidden: balanceHidden
                )
            )
        default:
            let rate = transactionValue.coin.flatMap { rates[$0] }

            viewItems.append(
                amount(
                    source: source,
                    title: burn ? "transactions.burn".localized : "transactions.send".localized,
                    subtitle: fullBadge(transactionValue: transactionValue),
                    transactionValue: transactionValue,
                    rate: rate,
                    type: type(value: transactionValue, condition: sentToSelf, .neutral, .outgoing),
                    balanceHidden: balanceHidden
                )
            )

            rateViewItem = .rate(value: rateString(currencyValue: rate, coinCode: transactionValue.coin?.code))
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

    private func type(value: TransactionValue, condition: Bool = true, _ trueType: AmountType, _ falseType: AmountType? = nil) -> AmountType {
        guard !value.zeroValue else {
            return .neutral
        }

        return condition ? trueType : (falseType ?? trueType)
    }

    private func receiveSection(source: TransactionSource, transactionValue: TransactionValue, from: String?, rates: [Coin: CurrencyValue], nftMetadata: [NftUid: NftAssetBriefMetadata] = [:], balanceHidden: Bool) -> [TransactionInfoModule.ViewItem] {
        var viewItems = [TransactionInfoModule.ViewItem]()

        let mint = from == zeroAddress
        var rateViewItem: TransactionInfoModule.ViewItem?

        switch transactionValue {
        case let .nftValue(nftUid, _, tokenName, _):
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
                    transactionValue: transactionValue,
                    type: type(value: transactionValue, .incoming),
                    metadata: nftMetadata[nftUid],
                    balanceHidden: balanceHidden
                )
            )
        default:
            let rate = transactionValue.coin.flatMap { rates[$0] }

            viewItems.append(
                amount(
                    source: source,
                    title: mint ? "transactions.mint".localized : "transactions.receive".localized,
                    subtitle: fullBadge(transactionValue: transactionValue),
                    transactionValue: transactionValue,
                    rate: rate,
                    type: type(value: transactionValue, .incoming),
                    balanceHidden: balanceHidden
                )
            )

            rateViewItem = .rate(value: rateString(currencyValue: rate, coinCode: transactionValue.coin?.code))
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
        func _rate(_ value: TransactionValue) -> CurrencyValue? {
            value.coin.flatMap { item.rates[$0] }
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
            sections.append(.init(sendSection(source: record.source, transactionValue: record.value, to: record.to, rates: item.rates, nftMetadata: item.nftMetadata, sentToSelf: record.sentToSelf, balanceHidden: balanceHidden)))

            if record.sentToSelf {
                sections.append(.init([.sentToSelf]))
            }

        case let record as EvmIncomingTransactionRecord:
            sections.append(.init(receiveSection(source: record.source, transactionValue: record.value, from: record.from, rates: item.rates, balanceHidden: balanceHidden)))

        case let record as ApproveTransactionRecord:
            let transactionValue = record.value
            let rate = _rate(transactionValue)
            let contactData = contactLabelService.contactData(for: record.spender)
            let valueTitle = contactData.name == nil ? evmLabelManager.addressLabel(address: record.spender) : nil

            var viewItems: [TransactionInfoModule.ViewItem] = [
                amount(source: record.source, title: "transactions.approve".localized, subtitle: fullBadge(transactionValue: transactionValue), transactionValue: transactionValue, rate: rate, type: .neutral, balanceHidden: balanceHidden),
                .spender(value: record.spender, valueTitle: valueTitle, contactAddress: contactData.contactAddress),
            ]

            if let name = contactData.name {
                viewItems.append(.contactName(name: name))
            }

            viewItems.append(.rate(value: rateString(currencyValue: rate, coinCode: transactionValue.coin?.code)))

            sections.append(.init(viewItems))

        case let record as SwapTransactionRecord:
            var amountViewItems: [TransactionInfoModule.ViewItem] = [
                amount(source: record.source, title: youPayString(status: status), subtitle: fullBadge(transactionValue: record.valueIn), transactionValue: record.valueIn, rate: _rate(record.valueIn), type: type(value: record.valueIn, .outgoing), balanceHidden: balanceHidden),
            ]

            if let valueOut = record.valueOut {
                amountViewItems.append(amount(source: record.source, title: youGetString(status: status), subtitle: fullBadge(transactionValue: valueOut), transactionValue: valueOut, rate: _rate(valueOut), type: type(value: valueOut, condition: record.recipient == nil, .incoming, .outgoing), balanceHidden: balanceHidden))
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
                    if let priceString = priceString(valueIn: record.valueIn, valueOut: valueOut, coinPriceIn: _rate(record.valueIn)) {
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
                    amount(source: record.source, title: youPayString(status: status), subtitle: fullBadge(transactionValue: valueIn), transactionValue: valueIn, rate: _rate(valueIn), type: type(value: valueIn, .outgoing), balanceHidden: balanceHidden)
                )
            }

            if let valueOut = record.valueOut {
                amountViewItems.append(
                    amount(source: record.source, title: youGetString(status: status), subtitle: fullBadge(transactionValue: valueOut), transactionValue: valueOut, rate: _rate(valueOut), type: type(value: valueOut, .incoming), balanceHidden: balanceHidden)
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
                    if let priceString = priceString(valueIn: valueIn, valueOut: valueOut, coinPriceIn: _rate(valueIn)) {
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
                sections.append(.init(sendSection(source: record.source, transactionValue: event.value, to: event.address, rates: item.rates, nftMetadata: item.nftMetadata, balanceHidden: balanceHidden)))
            }

            for event in record.incomingEvents {
                sections.append(.init(receiveSection(source: record.source, transactionValue: event.value, from: event.address, rates: item.rates, nftMetadata: item.nftMetadata, balanceHidden: balanceHidden)))
            }

        case let record as ExternalContractCallTransactionRecord:
            for event in record.outgoingEvents {
                sections.append(.init(sendSection(source: record.source, transactionValue: event.value, to: event.address, rates: item.rates, nftMetadata: item.nftMetadata, balanceHidden: balanceHidden)))
            }

            for event in record.incomingEvents {
                sections.append(.init(receiveSection(source: record.source, transactionValue: event.value, from: event.address, rates: item.rates, nftMetadata: item.nftMetadata, balanceHidden: balanceHidden)))
            }

        case let record as TronIncomingTransactionRecord:
            sections.append(.init(receiveSection(source: record.source, transactionValue: record.value, from: record.from, rates: item.rates, balanceHidden: balanceHidden)))

        case let record as TronOutgoingTransactionRecord:
            sections.append(.init(sendSection(source: record.source, transactionValue: record.value, to: record.to, rates: item.rates, nftMetadata: item.nftMetadata, sentToSelf: record.sentToSelf, balanceHidden: balanceHidden)))

            if record.sentToSelf {
                sections.append(.init([.sentToSelf]))
            }

        case let record as TronApproveTransactionRecord:
            let transactionValue = record.value
            let rate = _rate(transactionValue)
            let contactData = contactLabelService.contactData(for: record.spender)
            let valueTitle = contactData.name == nil ? evmLabelManager.addressLabel(address: record.spender) : nil

            var viewItems: [TransactionInfoModule.ViewItem] = [
                amount(source: record.source, title: "transactions.approve".localized, subtitle: fullBadge(transactionValue: transactionValue), transactionValue: transactionValue, rate: rate, type: .neutral, balanceHidden: balanceHidden),
                .spender(value: record.spender, valueTitle: valueTitle, contactAddress: contactData.contactAddress),
            ]

            if let name = contactData.name {
                viewItems.append(.contactName(name: name))
            }

            viewItems.append(.rate(value: rateString(currencyValue: rate, coinCode: transactionValue.coin?.code)))

            sections.append(.init(viewItems))

        case let record as TronContractCallTransactionRecord:
            sections.append(.init([
                .actionTitle(iconName: record.source.blockchainType.iconPlain32, iconDimmed: false, title: record.method ?? "transactions.contract_call".localized, subTitle: evmLabelManager.mapped(address: record.contractAddress)),
            ]))

            for event in record.outgoingEvents {
                sections.append(.init(sendSection(source: record.source, transactionValue: event.value, to: event.address, rates: item.rates, nftMetadata: item.nftMetadata, balanceHidden: balanceHidden)))
            }

            for event in record.incomingEvents {
                sections.append(.init(receiveSection(source: record.source, transactionValue: event.value, from: event.address, rates: item.rates, nftMetadata: item.nftMetadata, balanceHidden: balanceHidden)))
            }

        case let record as TronExternalContractCallTransactionRecord:
            for event in record.outgoingEvents {
                sections.append(.init(sendSection(source: record.source, transactionValue: event.value, to: event.address, rates: item.rates, nftMetadata: item.nftMetadata, balanceHidden: balanceHidden)))
            }

            for event in record.incomingEvents {
                sections.append(.init(receiveSection(source: record.source, transactionValue: event.value, from: event.address, rates: item.rates, nftMetadata: item.nftMetadata, balanceHidden: balanceHidden)))
            }

        case let record as TronTransactionRecord:
            sections.append(.init([
                .actionTitle(iconName: record.source.blockchainType.iconPlain32, iconDimmed: false, title: record.transaction.contract?.label ?? "transactions.contract_call".localized, subTitle: ""),
            ]))

        case let record as BitcoinIncomingTransactionRecord:
            sections.append(.init(receiveSection(source: record.source, transactionValue: record.value, from: record.from, rates: item.rates, balanceHidden: balanceHidden)))

            let additionalViewItems = bitcoinViewItems(record: record, lastBlockInfo: item.lastBlockInfo)
            if !additionalViewItems.isEmpty {
                sections.append(.init(additionalViewItems))
            }

        case let record as BitcoinOutgoingTransactionRecord:
            sections.append(.init(sendSection(source: record.source, transactionValue: record.value, to: record.to, rates: item.rates, sentToSelf: record.sentToSelf, balanceHidden: balanceHidden)))

            var additionalViewItems = bitcoinViewItems(record: record, lastBlockInfo: item.lastBlockInfo)

            if record.sentToSelf {
                additionalViewItems.insert(.sentToSelf, at: 0)
            }

            if !additionalViewItems.isEmpty {
                sections.append(.init(additionalViewItems))
            }

            if let fee = record.fee {
                feeViewItem = .fee(title: "tx_info.fee".localized, value: feeString(transactionValue: fee, rate: _rate(fee)))
            }

            if actionEnabled, record.replaceable {
                sections.append(.init([
                    .option(option: .resend(type: .speedUp)),
                    .option(option: .resend(type: .cancel)),
                ], footer: "tx_info.resend_description".localized))
            }

        case let record as BinanceChainIncomingTransactionRecord:
            sections.append(.init(receiveSection(source: record.source, transactionValue: record.value, from: record.from, rates: item.rates, balanceHidden: balanceHidden)))

            if let memo = record.memo, !memo.isEmpty {
                sections.append(.init([.memo(text: memo)]))
            }

        case let record as BinanceChainOutgoingTransactionRecord:
            sections.append(.init(sendSection(source: record.source, transactionValue: record.value, to: record.to, rates: item.rates, sentToSelf: record.sentToSelf, balanceHidden: balanceHidden)))

            var additionalViewItems = [TransactionInfoModule.ViewItem]()

            if record.sentToSelf {
                additionalViewItems.append(.sentToSelf)
            }

            if let memo = record.memo, !memo.isEmpty {
                sections.append(.init([.memo(text: memo)]))
            }

            if !additionalViewItems.isEmpty {
                sections.append(.init(additionalViewItems))
            }

            feeViewItem = .fee(title: "tx_info.fee".localized, value: feeString(transactionValue: record.fee, rate: _rate(record.fee)))

        case let record as TonIncomingTransactionRecord:
            if let transfer = record.transfer {
                sections.append(.init(receiveSection(source: record.source, transactionValue: transfer.value, from: transfer.address, rates: item.rates, balanceHidden: balanceHidden)))
            }

            if let memo = record.memo, !memo.isEmpty {
                sections.append(.init([.memo(text: memo)]))
            }
        case let record as TonOutgoingTransactionRecord:
            for transfer in record.transfers {
                sections.append(.init(sendSection(source: record.source, transactionValue: transfer.value, to: transfer.address, rates: item.rates, balanceHidden: balanceHidden)))
            }

            if let memo = record.memo, !memo.isEmpty {
                sections.append(.init([.memo(text: memo)]))
            }

            feeViewItem = record.fee.map { .fee(title: "tx_info.fee".localized, value: feeString(transactionValue: $0, rate: _rate($0))) }

        case let record as TonTransactionRecord:
            if let memo = record.memo, !memo.isEmpty {
                sections.append(.init([.memo(text: memo)]))
            }

            feeViewItem = record.fee.map { .fee(title: "tx_info.fee".localized, value: feeString(transactionValue: $0, rate: _rate($0))) }

        default: ()
        }

        var transactionViewItems: [TransactionInfoModule.ViewItem] = [
            .date(date: record.date),
            .status(status: status),
        ]

        if let evmRecord = record as? EvmTransactionRecord, evmRecord.ownTransaction, let transactionValue = evmRecord.fee {
            let title: String
            switch status {
            case .pending: title = "tx_info.fee.estimated".localized
            case .processing, .failed, .completed: title = "tx_info.fee".localized
            }

            feeViewItem = .fee(
                title: title,
                value: feeString(transactionValue: transactionValue, rate: _rate(transactionValue))
            )
        }

        if let tronRecord = record as? TronTransactionRecord, tronRecord.ownTransaction, let transactionValue = tronRecord.fee {
            let title: String
            switch status {
            case .pending: title = "tx_info.fee.estimated".localized
            case .processing, .failed, .completed: title = "tx_info.fee".localized
            }

            feeViewItem = .fee(
                title: title,
                value: feeString(transactionValue: transactionValue, rate: _rate(transactionValue))
            )
        }

        if let feeViewItem {
            transactionViewItems.append(feeViewItem)
        }

        transactionViewItems.append(.id(value: record.transactionHash))

        sections.append(.init(transactionViewItems))

        if actionEnabled, let evmRecord = record as? EvmTransactionRecord, evmRecord.ownTransaction, status.isPending {
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
