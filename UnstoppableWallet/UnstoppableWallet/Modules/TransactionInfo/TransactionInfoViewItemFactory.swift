import Foundation
import MarketKit
import CurrencyKit
import EvmKit

class TransactionInfoViewItemFactory {
    private let zeroAddress = "0x0000000000000000000000000000000000000000"

    private let evmLabelManager: EvmLabelManager
    private let actionEnabled: Bool

    init(evmLabelManager: EvmLabelManager, actionEnabled: Bool) {
        self.evmLabelManager = evmLabelManager
        self.actionEnabled = actionEnabled
    }

    private func amount(source: TransactionSource, transactionValue: TransactionValue, rate: CurrencyValue?, type: AmountType) -> TransactionInfoModule.ViewItem {
        let iconUrl = transactionValue.coin?.imageUrl
        let iconPlaceholderImageName = source.blockchainType.placeholderImageName(tokenProtocol: transactionValue.tokenProtocol)

        if transactionValue.isMaxValue {
            return .amount(
                    iconUrl: iconUrl,
                    iconPlaceholderImageName: iconPlaceholderImageName,
                    coinAmount: "∞ \(transactionValue.coinCode)",
                    currencyAmount: "transactions.value.unlimited".localized,
                    type: type
            )
        } else {
            var currencyValue: CurrencyValue?

            if let rate = rate, let value = transactionValue.decimalValue {
                currencyValue = CurrencyValue(currency: rate.currency, value: rate.value * value)
            }

            return .amount(
                    iconUrl: iconUrl,
                    iconPlaceholderImageName: iconPlaceholderImageName,
                    coinAmount: transactionValue.formattedFull(showSign: type.showSign) ?? "n/a".localized,
                    currencyAmount: currencyValue.flatMap { ValueFormatter.instance.formatFull(currencyValue: $0) },
                    type: type
            )
        }
    }

    private func nftAmount(source: TransactionSource, transactionValue: TransactionValue, type: AmountType, metadata: NftAssetBriefMetadata?) -> TransactionInfoModule.ViewItem {
        .nftAmount(
                iconUrl: metadata?.previewImageUrl,
                iconPlaceholderImageName: "placeholder_nft_24",
                nftAmount: transactionValue.formattedFull(showSign: type.showSign) ?? "n/a".localized,
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

        if let rate = rate, case .coinValue(_, let value) = transactionValue {
            if let formattedCurrencyValue = ValueFormatter.instance.formatFull(currency: rate.currency, value: rate.value * value) {
                parts.append(formattedCurrencyValue)
            }
        }

        return parts.joined(separator: " | ")
    }

    private func priceString(valueIn: TransactionValue, valueOut: TransactionValue, coinPriceIn: CurrencyValue?) -> String? {
        guard case .coinValue(let valueInToken, let valueInDecimal) = valueIn,
              case .coinValue(let valueOutToken, let valueOutDecimal) = valueOut else {
            return nil
        }

        let priceDecimal = valueInDecimal.magnitude / valueOutDecimal.magnitude
        let price = ValueFormatter.instance.formatFull(value: priceDecimal, decimalCount: priceDecimal.decimalCount, symbol: valueInToken.coin.code) ?? ""
        let rate = coinPriceIn.map { CurrencyValue(currency: $0.currency, value: abs(priceDecimal * $0.value)) }
        let rateFormatted = rate.flatMap { ValueFormatter.instance.formatFull(currencyValue: $0).map { " (\($0))"} } ?? ""

        return "\(valueOutToken.coin.code) = \(price)\(rateFormatted)"
    }

    private func rateString(currencyValue: CurrencyValue?, coinCode: String?) -> String {
        guard let currencyValue = currencyValue, let coinCode = coinCode else {
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

    private func fullName(transactionValue: TransactionValue, nftMetadata: NftAssetBriefMetadata? = nil) -> String {
        switch transactionValue {
        case .coinValue(let token, _):
            return token.coin.name
        case .tokenValue(let tokenName, _, _, _):
            return tokenName
        case .nftValue(let nftUid, _, let tokenName, _):
            return nftMetadata?.name ?? tokenName.map { "\($0) #\(nftUid.tokenId)" } ?? "#\(nftUid.tokenId)"
        case .rawValue:
            return ""
        }
    }

    private func sendSection(source: TransactionSource, transactionValue: TransactionValue, to: String?, rates: [Coin: CurrencyValue], nftMetadata: [NftUid: NftAssetBriefMetadata] = [:], sentToSelf: Bool = false) -> [TransactionInfoModule.ViewItem] {
        let burn = to == zeroAddress
        let subTitle: String
        let amountViewItem: TransactionInfoModule.ViewItem
        var toViewItem: TransactionInfoModule.ViewItem?
        var rateViewItem: TransactionInfoModule.ViewItem?

        switch transactionValue {
        case .nftValue(let nftUid, _, _, _):
            subTitle = fullName(transactionValue: transactionValue, nftMetadata: nftMetadata[nftUid])

            amountViewItem = nftAmount(
                    source: source,
                    transactionValue: transactionValue,
                    type: type(value: transactionValue, condition: sentToSelf, .neutral, .outgoing),
                    metadata: nftMetadata[nftUid]
            )
        default:
            subTitle = fullName(transactionValue: transactionValue)

            let rate = transactionValue.coin.flatMap { rates[$0] }

            amountViewItem = amount(
                    source: source,
                    transactionValue: transactionValue,
                    rate: rate,
                    type: type(value: transactionValue, condition: sentToSelf, .neutral, .outgoing)
            )

            rateViewItem = .rate(value: rateString(currencyValue: rate, coinCode: transactionValue.coin?.code))
        }

        if !burn, let to = to {
            toViewItem = .to(value: to, valueTitle: evmLabelManager.addressLabel(address: to))
        }

        let viewItems: [TransactionInfoModule.ViewItem?] = [
            .actionTitle(
                    iconName: burn ? "flame_24" : "arrow_medium_2_up_right_24",
                    iconDimmed: true,
                    title: burn ? "transactions.burn".localized : "transactions.send".localized,
                    subTitle: subTitle
            ),
            amountViewItem,
            toViewItem,
            rateViewItem
        ]

        return viewItems.compactMap { $0 }
    }

    private func type(value: TransactionValue, condition: Bool = true, _ trueType: AmountType, _ falseType: AmountType? = nil) -> AmountType {
        guard !value.zeroValue else {
            return .neutral
        }

        return condition ? trueType : (falseType ?? trueType)
    }

    private func receiveSection(source: TransactionSource, transactionValue: TransactionValue, from: String?, rates: [Coin: CurrencyValue], nftMetadata: [NftUid: NftAssetBriefMetadata] = [:]) -> [TransactionInfoModule.ViewItem] {
        let mint = from == zeroAddress
        let subTitle: String
        let amountViewItem: TransactionInfoModule.ViewItem
        var fromViewItem: TransactionInfoModule.ViewItem?
        var rateViewItem: TransactionInfoModule.ViewItem?

        switch transactionValue {
        case .nftValue(let nftUid, _, _, _):
            subTitle = fullName(transactionValue: transactionValue, nftMetadata: nftMetadata[nftUid])

            amountViewItem = nftAmount(
                    source: source,
                    transactionValue: transactionValue,
                    type: type(value: transactionValue, .incoming),
                    metadata: nftMetadata[nftUid]
            )

        default:
            subTitle = fullName(transactionValue: transactionValue)

            let rate = transactionValue.coin.flatMap { rates[$0] }

            amountViewItem = amount(
                    source: source,
                    transactionValue: transactionValue,
                    rate: rate,
                    type: type(value: transactionValue, .incoming)
            )

            rateViewItem = .rate(value: rateString(currencyValue: rate, coinCode: transactionValue.coin?.code))
        }

        if !mint, let from = from {
            fromViewItem = .from(value: from, valueTitle: evmLabelManager.addressLabel(address: from))
        }

        let viewItems: [TransactionInfoModule.ViewItem?] = [
            .actionTitle(
                    iconName: "arrow_medium_2_down_left_24",
                    iconDimmed: true,
                    title: mint ? "transactions.mint".localized : "transactions.receive".localized,
                    subTitle: subTitle
            ),
            amountViewItem,
            fromViewItem,
            rateViewItem
        ]

        return viewItems.compactMap { $0 }
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

    func items(item: TransactionInfoService.Item) -> [[TransactionInfoModule.ViewItem]] {
        func _rate(_ value: TransactionValue) -> CurrencyValue? {
            value.coin.flatMap { item.rates[$0] }
        }

        let record = item.record
        var feeViewItem: TransactionInfoModule.ViewItem?
        let status = record.status(lastBlockHeight: item.lastBlockInfo?.height)

        var sections = [[TransactionInfoModule.ViewItem]]()

        switch record {
        case let record as ContractCreationTransactionRecord:
            sections.append([
                .actionTitle(iconName: record.source.blockchainType.iconPlain24, iconDimmed: false, title: "transactions.contract_creation".localized, subTitle: nil)
            ])

        case let record as EvmOutgoingTransactionRecord:
            sections.append(sendSection(source: record.source, transactionValue: record.value, to: record.to, rates: item.rates, nftMetadata: item.nftMetadata, sentToSelf: record.sentToSelf))

            if record.sentToSelf {
                sections.append([.sentToSelf])
            }

        case let record as EvmIncomingTransactionRecord:
            sections.append(receiveSection(source: record.source, transactionValue: record.value, from: record.from, rates: item.rates))

        case let record as ApproveTransactionRecord:
            let transactionValue = record.value
            let rate = _rate(transactionValue)

            var viewItems: [TransactionInfoModule.ViewItem] = [
                .actionTitle(iconName: "check_2_24", iconDimmed: true, title: "transactions.approve".localized, subTitle: transactionValue.fullName),
                amount(source: record.source, transactionValue: transactionValue, rate: rate, type: .neutral),
                .spender(value: record.spender, valueTitle: evmLabelManager.addressLabel(address: record.spender))
            ]

            viewItems.append(.rate(value: rateString(currencyValue: rate, coinCode: transactionValue.coin?.code)))

            sections.append(viewItems)

        case let record as SwapTransactionRecord:
            sections.append([
                .actionTitle(iconName: "arrow_medium_2_up_right_24", iconDimmed: true, title: youPayString(status: status), subTitle: record.valueIn.fullName),
                amount(source: record.source, transactionValue: record.valueIn, rate: _rate(record.valueIn), type: type(value: record.valueIn, .outgoing))
            ])

            if let valueOut = record.valueOut {
                var viewItems: [TransactionInfoModule.ViewItem] = [
                    .actionTitle(iconName: "arrow_medium_2_down_left_24", iconDimmed: true, title: youGetString(status: status), subTitle: valueOut.fullName),
                    amount(source: record.source, transactionValue: valueOut, rate: _rate(valueOut), type: type(value: valueOut, condition: record.recipient == nil, .incoming, .outgoing))
                ]

                if let recipient = record.recipient {
                    viewItems.append(.recipient(value: recipient, valueTitle: evmLabelManager.addressLabel(address: recipient)))
                }

                sections.append(viewItems)
            } else if let recipient = record.recipient {
                sections.append([
                    .recipient(value: recipient, valueTitle: evmLabelManager.addressLabel(address: recipient))
                ])
            }

            var viewItems: [TransactionInfoModule.ViewItem] = [
                .service(value: evmLabelManager.mapped(address: record.exchangeAddress))
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

            sections.append(viewItems)

        case let record as UnknownSwapTransactionRecord:
            if let valueIn = record.valueIn {
                sections.append([
                    .actionTitle(iconName: "arrow_medium_2_up_right_24", iconDimmed: true, title: youPayString(status: status), subTitle: valueIn.fullName),
                    amount(source: record.source, transactionValue: valueIn, rate: _rate(valueIn), type: type(value: valueIn, .outgoing))
                ])
            }

            if let valueOut = record.valueOut {
                sections.append([
                    .actionTitle(iconName: "arrow_medium_2_down_left_24", iconDimmed: true, title: youGetString(status: status), subTitle: valueOut.fullName),
                    amount(source: record.source, transactionValue: valueOut, rate: _rate(valueOut), type: type(value: valueOut, .incoming))
                ])
            }

            var viewItems: [TransactionInfoModule.ViewItem] = [
                .service(value: evmLabelManager.mapped(address: record.exchangeAddress))
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

            sections.append(viewItems)

        case let record as ContractCallTransactionRecord:
            sections.append([
                .actionTitle(iconName: record.source.blockchainType.iconPlain24, iconDimmed: false, title: record.method ?? "transactions.contract_call".localized, subTitle: evmLabelManager.mapped(address: record.contractAddress))
            ])

            for event in record.outgoingEvents {
                sections.append(sendSection(source: record.source, transactionValue: event.value, to: event.address, rates: item.rates, nftMetadata: item.nftMetadata))
            }

            for event in record.incomingEvents {
                sections.append(receiveSection(source: record.source, transactionValue: event.value, from: event.address, rates: item.rates, nftMetadata: item.nftMetadata))
            }

        case let record as ExternalContractCallTransactionRecord:
            for event in record.outgoingEvents {
                sections.append(sendSection(source: record.source, transactionValue: event.value, to: event.address, rates: item.rates, nftMetadata: item.nftMetadata))
            }

            for event in record.incomingEvents {
                sections.append(receiveSection(source: record.source, transactionValue: event.value, from: event.address, rates: item.rates, nftMetadata: item.nftMetadata))
            }

        case let record as BitcoinIncomingTransactionRecord:
            sections.append(receiveSection(source: record.source, transactionValue: record.value, from: record.from, rates: item.rates))

            let additionalViewItems = bitcoinViewItems(record: record, lastBlockInfo: item.lastBlockInfo)
            if !additionalViewItems.isEmpty {
                sections.append(additionalViewItems)
            }

        case let record as BitcoinOutgoingTransactionRecord:
            sections.append(sendSection(source: record.source, transactionValue: record.value, to: record.to, rates: item.rates, sentToSelf: record.sentToSelf))

            var additionalViewItems = bitcoinViewItems(record: record, lastBlockInfo: item.lastBlockInfo)

            if record.sentToSelf {
                additionalViewItems.insert(.sentToSelf, at: 0)
            }

            if !additionalViewItems.isEmpty {
                sections.append(additionalViewItems)
            }

            if let fee = record.fee {
                feeViewItem = .fee(title: "tx_info.fee".localized, value: feeString(transactionValue: fee, rate: _rate(fee)))
            }

        case let record as BinanceChainIncomingTransactionRecord:
            sections.append(receiveSection(source: record.source, transactionValue: record.value, from: record.from, rates: item.rates))

            if let memo = record.memo, !memo.isEmpty {
                sections.append([.memo(text: memo)])
            }

        case let record as BinanceChainOutgoingTransactionRecord:
            sections.append(sendSection(source: record.source, transactionValue: record.value, to: record.to, rates: item.rates, sentToSelf: record.sentToSelf))

            var additionalViewItems = [TransactionInfoModule.ViewItem]()

            if record.sentToSelf {
                additionalViewItems.append(.sentToSelf)
            }

            if let memo = record.memo, !memo.isEmpty {
                sections.append([.memo(text: memo)])
            }

            if !additionalViewItems.isEmpty {
                sections.append(additionalViewItems)
            }

            feeViewItem = .fee(title: "tx_info.fee".localized, value: feeString(transactionValue: record.fee, rate: _rate(record.fee)))

        default: ()
        }

        var transactionViewItems: [TransactionInfoModule.ViewItem] = [
            .date(date: record.date),
            .status(status: status)
        ]

        if actionEnabled, let evmRecord = record as? EvmTransactionRecord, evmRecord.ownTransaction {
            switch status {
            case .pending:
                transactionViewItems.append(.options(actions: [
                    TransactionInfoModule.OptionViewItem(title: "tx_info.options.speed_up".localized, active: true, option: .speedUp),
                    TransactionInfoModule.OptionViewItem(title: "tx_info.options.cancel".localized, active: true, option: .cancel)
                ]))
            default: ()
            }

            if let transactionValue = evmRecord.fee {
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
        }

        if let feeViewItem = feeViewItem {
            transactionViewItems.append(feeViewItem)
        }

        transactionViewItems.append(.id(value: record.transactionHash))

        sections.append(transactionViewItems)

        sections.append([
            .explorer(title: "tx_info.view_on".localized(item.explorerTitle), url: item.explorerUrl)
        ])

        return sections
    }

}
