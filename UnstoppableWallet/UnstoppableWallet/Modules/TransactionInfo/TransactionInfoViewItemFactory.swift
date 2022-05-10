import MarketKit
import CurrencyKit
import EthereumKit

class TransactionInfoViewItemFactory {
    private let evmLabelManager: EvmLabelManager

    init(evmLabelManager: EvmLabelManager) {
        self.evmLabelManager = evmLabelManager
    }

    private func amount(source: TransactionSource, transactionValue: TransactionValue, rate: CurrencyValue?, type: TransactionInfoModule.AmountType) -> TransactionInfoModule.ViewItem {
        let iconUrl = transactionValue.coin?.imageUrl
        let iconPlaceholderImageName = source.blockchain.coinPlaceholderImage

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
                    coinAmount: "\(type.prefix)\(transactionValue.abs.formattedString)",
                    currencyAmount: currencyValue?.abs.formattedString,
                    type: type
            )
        }
    }

    private func feeString(transactionValue: TransactionValue, rate: CurrencyValue?) -> String {
        var parts = [String]()

        if let formattedCoinValue = ValueFormatter.instance.format(transactionValue: transactionValue) {
            parts.append(formattedCoinValue)
        }

        if let rate = rate, case .coinValue(_, let value) = transactionValue {
            let currencyValue = CurrencyValue(currency: rate.currency, value: rate.value * value)
            if let formattedCurrencyValue = ValueFormatter.instance.format(currencyValue: currencyValue) {
                parts.append(formattedCurrencyValue)
            }
        }

        return parts.joined(separator: " | ")
    }

    private func priceString(valueIn: TransactionValue, valueOut: TransactionValue, coinPriceIn: CurrencyValue?) -> String? {
        guard case .coinValue(let valueInPlatformCoin, let valueInDecimal) = valueIn,
              case .coinValue(let valueOutPlatformCoin, let valueOutDecimal) = valueOut else {
            return nil
        }

        let priceDecimal = valueInDecimal.magnitude / valueOutDecimal.magnitude
        let price = ValueFormatter.instance.format(value: priceDecimal, decimalCount: priceDecimal.decimalCount, symbol: nil) ?? ""
        let rate = coinPriceIn.map { CurrencyValue(currency: $0.currency, value: abs(priceDecimal * $0.value)) }
        let rateFormatted = rate.flatMap { ($0.formattedString.map { " (\($0))"}) } ?? ""

        return "\(valueOutPlatformCoin.coin.code) = \(price) \(valueInPlatformCoin.coin.code)" + rateFormatted
    }

    private func rateString(currencyValue: CurrencyValue, coinCode: String) -> String {
        let formattedValue = ValueFormatter.instance.format(currencyValue: currencyValue, fractionPolicy: .threshold(high: 1000, low: 0.1), trimmable: false) ?? ""

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

    private func sendSection(source: TransactionSource, transactionValue: TransactionValue, to: String?, rates: [Coin: CurrencyValue]) -> [TransactionInfoModule.ViewItem] {
        let rate = transactionValue.coin.flatMap { rates[$0] }

        var viewItems: [TransactionInfoModule.ViewItem] = [
            .actionTitle(iconName: "arrow_medium_2_up_right_24", iconDimmed: true, title: "transactions.send".localized, subTitle: transactionValue.coinName),
            amount(source: source, transactionValue: transactionValue, rate: rate, type: .outgoing)
        ]

        if let to = to {
            viewItems.append(.to(value: to, valueTitle: evmLabelManager.addressLabel(address: to)))
        }

        if let rate = rate, let coin = transactionValue.coin {
            viewItems.append(.rate(value: rateString(currencyValue: rate, coinCode: coin.code)))
        }

        return viewItems
    }

    private func receiveSection(source: TransactionSource, transactionValue: TransactionValue, from: String?, rates: [Coin: CurrencyValue]) -> [TransactionInfoModule.ViewItem] {
        let rate = transactionValue.coin.flatMap { rates[$0] }

        var viewItems: [TransactionInfoModule.ViewItem] = [
            .actionTitle(iconName: "arrow_medium_2_down_left_24", iconDimmed: true, title: "transactions.receive".localized, subTitle: transactionValue.coinName),
            amount(source: source, transactionValue: transactionValue, rate: rate, type: .incoming)
        ]

        if let from = from {
            viewItems.append(.from(value: from, valueTitle: evmLabelManager.addressLabel(address: from)))
        }

        if let rate = rate, let coin = transactionValue.coin {
            viewItems.append(.rate(value: rateString(currencyValue: rate, coinCode: coin.code)))
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

    func items(item: TransactionInfoItem) -> [[TransactionInfoModule.ViewItem]] {
        func _rate(_ value: TransactionValue) -> CurrencyValue? {
            value.coin.flatMap { item.rates[$0] }
        }

        let record = item.record
        var feeViewItem: TransactionInfoModule.ViewItem?
        let status = record.status(lastBlockHeight: item.lastBlockInfo?.height)

        var sections = [[TransactionInfoModule.ViewItem]]()

        switch record {
        case let record as EvmOutgoingTransactionRecord:
            sections.append(sendSection(source: record.source, transactionValue: record.value, to: record.to, rates: item.rates))

            if record.sentToSelf {
                sections.append([.sentToSelf])
            }

        case let record as EvmIncomingTransactionRecord:
            sections.append(receiveSection(source: record.source, transactionValue: record.value, from: record.from, rates: item.rates))

        case let record as ApproveTransactionRecord:
            let transactionValue = record.value
            let rate = _rate(transactionValue)

            var viewItems: [TransactionInfoModule.ViewItem] = [
                .actionTitle(iconName: "check_2_24", iconDimmed: true, title: "transactions.approve".localized, subTitle: transactionValue.coinName),
                amount(source: record.source, transactionValue: transactionValue, rate: rate, type: .neutral),
                .spender(value: record.spender, valueTitle: evmLabelManager.addressLabel(address: record.spender))
            ]

            if let rate = rate, let coin = transactionValue.coin {
                viewItems.append(.rate(value: rateString(currencyValue: rate, coinCode: coin.code)))
            }

            sections.append(viewItems)

        case let record as SwapTransactionRecord:
            sections.append([
                .actionTitle(iconName: "arrow_medium_2_up_right_24", iconDimmed: true, title: youPayString(status: status), subTitle: record.valueIn.coinName),
                amount(source: record.source, transactionValue: record.valueIn, rate: _rate(record.valueIn), type: .outgoing)
            ])

            if let valueOut = record.valueOut {
                var viewItems: [TransactionInfoModule.ViewItem] = [
                    .actionTitle(iconName: "arrow_medium_2_down_left_24", iconDimmed: true, title: youGetString(status: status), subTitle: valueOut.coinName),
                    amount(source: record.source, transactionValue: valueOut, rate: _rate(valueOut), type: record.recipient == nil ? .incoming : .neutral)
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
                    .actionTitle(iconName: "arrow_medium_2_up_right_24", iconDimmed: true, title: youPayString(status: status), subTitle: valueIn.coinName),
                    amount(source: record.source, transactionValue: valueIn, rate: _rate(valueIn), type: .outgoing)
                ])
            }

            if let valueOut = record.valueOut {
                sections.append([
                    .actionTitle(iconName: "arrow_medium_2_down_left_24", iconDimmed: true, title: youGetString(status: status), subTitle: valueOut.coinName),
                    amount(source: record.source, transactionValue: valueOut, rate: _rate(valueOut), type: .incoming)
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
                .actionTitle(iconName: record.source.blockchain.image, iconDimmed: false, title: record.method ?? "transactions.contract_call".localized, subTitle: evmLabelManager.mapped(address: record.contractAddress) )
            ])

            for event in record.outgoingEvents {
                sections.append(sendSection(source: record.source, transactionValue: event.value, to: event.address, rates: item.rates))
            }

            for event in record.incomingEvents {
                sections.append(receiveSection(source: record.source, transactionValue: event.value, from: event.address, rates: item.rates))
            }

        case let record as ExternalContractCallTransactionRecord:
            for event in record.outgoingEvents {
                sections.append(sendSection(source: record.source, transactionValue: event.value, to: event.address, rates: item.rates))
            }

            for event in record.incomingEvents {
                sections.append(receiveSection(source: record.source, transactionValue: event.value, from: event.address, rates: item.rates))
            }

        case let record as BitcoinIncomingTransactionRecord:
            sections.append(receiveSection(source: record.source, transactionValue: record.value, from: record.from, rates: item.rates))

            let additionalViewItems = bitcoinViewItems(record: record, lastBlockInfo: item.lastBlockInfo)
            if !additionalViewItems.isEmpty {
                sections.append(additionalViewItems)
            }

        case let record as BitcoinOutgoingTransactionRecord:
            sections.append(sendSection(source: record.source, transactionValue: record.value, to: record.to, rates: item.rates))

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
            sections.append(sendSection(source: record.source, transactionValue: record.value, to: record.to, rates: item.rates))

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

        if let evmRecord = record as? EvmTransactionRecord, evmRecord.ownTransaction {
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
