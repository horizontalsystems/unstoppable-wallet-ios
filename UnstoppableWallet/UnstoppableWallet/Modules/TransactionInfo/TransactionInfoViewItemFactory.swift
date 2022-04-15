import MarketKit
import CurrencyKit
import EthereumKit

class TransactionInfoViewItemFactory {

    private func amount(transactionValue: TransactionValue, rate: CurrencyValue?, incoming: Bool? = nil) -> TransactionInfoModule.ViewItem {
        if transactionValue.isMaxValue {
            return .amount(coinAmount: "transactions.value.unlimited".localized(transactionValue.coinCode), currencyAmount: "∞", incoming: incoming)
        } else {
            var currencyValue: CurrencyValue?

            if let rate = rate, let value = transactionValue.decimalValue {
                currencyValue = CurrencyValue(currency: rate.currency, value: rate.value * value)
            }

            return .amount(coinAmount: transactionValue.abs.formattedString, currencyAmount: currencyValue?.abs.formattedString, incoming: incoming)
        }
    }

    private func actionSectionItems(title: String, transactionValue: TransactionValue, rate: CurrencyValue?, incoming: Bool?) -> [TransactionInfoModule.ViewItem] {
        var currencyValue: CurrencyValue? = nil
        if let rate = rate, case .coinValue(_, let value) = transactionValue {
            currencyValue = CurrencyValue(currency: rate.currency, value: rate.value * value)
        }

        return [
            .actionTitle(title: title, subTitle: transactionValue.coinName),
            .amount(coinAmount: transactionValue.abs.formattedString, currencyAmount: currencyValue?.abs.formattedString, incoming: incoming)
        ]
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

    private func sendSection(transactionValue: TransactionValue, to: String?, rates: [Coin: CurrencyValue]) -> [TransactionInfoModule.ViewItem] {
        let rate = transactionValue.coin.flatMap { rates[$0] }

        var viewItems: [TransactionInfoModule.ViewItem] = [
            .actionTitle(title: "transactions.send".localized, subTitle: transactionValue.coinName),
            amount(transactionValue: transactionValue, rate: rate, incoming: false)
        ]

        if let to = to {
            viewItems.append(.to(value: to))
        }

        if let rate = rate, let coin = transactionValue.coin {
            viewItems.append(.rate(value: rateString(currencyValue: rate, coinCode: coin.code)))
        }

        return viewItems
    }

    private func receiveSection(transactionValue: TransactionValue, from: String?, rates: [Coin: CurrencyValue]) -> [TransactionInfoModule.ViewItem] {
        let rate = transactionValue.coin.flatMap { rates[$0] }

        var viewItems: [TransactionInfoModule.ViewItem] = [
            .actionTitle(title: "transactions.receive".localized, subTitle: transactionValue.coinName),
            amount(transactionValue: transactionValue, rate: rate, incoming: true)
        ]

        if let from = from {
            viewItems.append(.from(value: from))
        }

        if let rate = rate, let coin = transactionValue.coin {
            viewItems.append(.rate(value: rateString(currencyValue: rate, coinCode: coin.code)))
        }

        return viewItems
    }

    private func bitcoinSection(record: BitcoinTransactionRecord, lastBlockInfo: LastBlockInfo?) -> [TransactionInfoModule.ViewItem] {
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
        var additionalSections = [[TransactionInfoModule.ViewItem]]()
        let status = record.status(lastBlockHeight: item.lastBlockInfo?.height)

        var sections = [[TransactionInfoModule.ViewItem]]()

        switch record {
        case let evmOutgoing as EvmOutgoingTransactionRecord:
            sections.append(sendSection(transactionValue: evmOutgoing.value, to: evmOutgoing.to, rates: item.rates))

        case let evmIncoming as EvmIncomingTransactionRecord:
            sections.append(receiveSection(transactionValue: evmIncoming.value, from: evmIncoming.from, rates: item.rates))

        case let approve as ApproveTransactionRecord:
            let transactionValue = approve.value
            let rate = _rate(transactionValue)

            var viewItems: [TransactionInfoModule.ViewItem] = [
                .actionTitle(title: "transactions.approve".localized, subTitle: transactionValue.coinName),
                amount(transactionValue: transactionValue, rate: rate),
                .spender(value: approve.spender)
            ]

            if let rate = rate, let coin = transactionValue.coin {
                viewItems.append(.rate(value: rateString(currencyValue: rate, coinCode: coin.code)))
            }

            sections.append(viewItems)

        case let swap as SwapTransactionRecord:
            sections.append([
                .actionTitle(title: youPayString(status: status), subTitle: swap.valueIn.coinName),
                amount(transactionValue: swap.valueIn, rate: _rate(swap.valueIn), incoming: false)
            ])

            if let valueOut = swap.valueOut {
                var viewItems: [TransactionInfoModule.ViewItem] = [
                    .actionTitle(title: youGetString(status: status), subTitle: valueOut.coinName),
                    amount(transactionValue: valueOut, rate: _rate(valueOut), incoming: swap.recipient == nil ? true : nil)
                ]

                if let recipient = swap.recipient {
                    viewItems.append(.recipient(value: recipient))
                }

                sections.append(viewItems)
            } else if let recipient = swap.recipient {
                sections.append([
                    .recipient(value: recipient)
                ])
            }

            var viewItems: [TransactionInfoModule.ViewItem] = [
                .service(value: TransactionInfoAddressMapper.map(swap.exchangeAddress))
            ]

            if let valueOut = swap.valueOut {
                switch status {
                case .pending, .processing, .completed:
                    if let priceString = priceString(valueIn: swap.valueIn, valueOut: valueOut, coinPriceIn: _rate(swap.valueIn)) {
                        viewItems.append(.price(price: priceString))
                    }
                default: ()
                }
            }

            sections.append(viewItems)

        case let swap as UnknownSwapTransactionRecord:
            if let valueIn = swap.valueIn {
                sections.append([
                    .actionTitle(title: youPayString(status: status), subTitle: valueIn.coinName),
                    amount(transactionValue: valueIn, rate: _rate(valueIn), incoming: false)
                ])
            }

            if let valueOut = swap.valueOut {
                sections.append([
                    .actionTitle(title: youGetString(status: status), subTitle: valueOut.coinName),
                    amount(transactionValue: valueOut, rate: _rate(valueOut), incoming: true)
                ])
            }

            var viewItems: [TransactionInfoModule.ViewItem] = [
                .service(value: TransactionInfoAddressMapper.map(swap.exchangeAddress))
            ]

            if let valueIn = swap.valueIn, let valueOut = swap.valueOut {
                switch status {
                case .pending, .processing, .completed:
                    if let priceString = priceString(valueIn: valueIn, valueOut: valueOut, coinPriceIn: _rate(valueIn)) {
                        viewItems.append(.price(price: priceString))
                    }
                default: ()
                }
            }

            sections.append(viewItems)

        case let contractCall as ContractCallTransactionRecord:
            sections.append([
                .actionTitle(title: contractCall.method ?? "transactions.contract_call".localized, subTitle: TransactionInfoAddressMapper.map(contractCall.contractAddress) )
            ])

            if let decimalValue = contractCall.totalValue.decimalValue, decimalValue < 0 {
                sections.append(sendSection(transactionValue: contractCall.totalValue, to: nil, rates: item.rates))
            }

            for event in contractCall.outgoingEip20Events {
                sections.append(sendSection(transactionValue: event.value, to: event.address, rates: item.rates))
            }

            if let decimalValue = contractCall.totalValue.decimalValue, decimalValue > 0 {
                sections.append(receiveSection(transactionValue: contractCall.totalValue, from: nil, rates: item.rates))
            }

            for event in contractCall.incomingEip20Events {
                sections.append(receiveSection(transactionValue: event.value, from: event.address, rates: item.rates))
            }

        case let record as ContractCallIncomingTransactionRecord:
            if let baseCoinValue = record.baseCoinValue {
                sections.append(receiveSection(transactionValue: baseCoinValue, from: nil, rates: item.rates))
            }

            for event in record.events {
                sections.append(receiveSection(transactionValue: event.value, from: event.address, rates: item.rates))
            }

        case let btcIncoming as BitcoinIncomingTransactionRecord:
            sections.append(receiveSection(transactionValue: btcIncoming.value, from: btcIncoming.from, rates: item.rates))

            let bitcoinSection = bitcoinSection(record: btcIncoming, lastBlockInfo: item.lastBlockInfo)
            if !bitcoinSection.isEmpty {
                additionalSections.append(bitcoinSection)
            }

        case let btcOutgoing as BitcoinOutgoingTransactionRecord:
            sections.append(sendSection(transactionValue: btcOutgoing.value, to: btcOutgoing.to, rates: item.rates))

            let bitcoinSection = bitcoinSection(record: btcOutgoing, lastBlockInfo: item.lastBlockInfo)
            if !bitcoinSection.isEmpty {
                additionalSections.append(bitcoinSection)
            }

            if let fee = btcOutgoing.fee {
                feeViewItem = .fee(title: "tx_info.fee".localized, value: feeString(transactionValue: fee, rate: _rate(fee)))
            }

        case let tx as BinanceChainIncomingTransactionRecord:
            sections.append(receiveSection(transactionValue: tx.value, from: tx.from, rates: item.rates))

            if let memo = tx.memo, !memo.isEmpty {
                sections.append([.memo(text: memo)])
            }

        case let tx as BinanceChainOutgoingTransactionRecord:
            sections.append(sendSection(transactionValue: tx.value, to: tx.to, rates: item.rates))

            if let memo = tx.memo, !memo.isEmpty {
                sections.append([.memo(text: memo)])
            }

            feeViewItem = .fee(title: "tx_info.fee".localized, value: feeString(transactionValue: tx.fee, rate: _rate(tx.fee)))

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

        sections.append(contentsOf: additionalSections)

        sections.append([
            .explorer(title: "tx_info.view_on".localized(item.explorerTitle), url: item.explorerUrl)
        ])

        return sections
    }

}
