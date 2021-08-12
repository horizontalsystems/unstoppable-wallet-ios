import CoinKit
import CurrencyKit
import EthereumKit

class TransactionInfoViewItemFactory {

    private func actionSectionItems(title: String, coinValue: CoinValue, rate: CurrencyValue?, incoming: Bool?) -> [TransactionInfoModule.ViewItem] {
        let currencyValue = rate.flatMap {
            CurrencyValue(currency: $0.currency, value: $0.value * coinValue.value)
        }

        return [
            .actionTitle(title: title, subTitle: coinValue.coin.title),
            .amount(coinAmount: coinValue.abs.formattedString, currencyAmount: currencyValue?.abs.formattedString, incoming: incoming)
        ]
    }

    private func evmResendItem(status: TransactionStatus) -> TransactionInfoModule.ViewItem? {
        switch status {
        case .pending:
            return .options(actions: [
                TransactionInfoModule.OptionViewItem(title: "SpeedUp", active: true, action: .speedUp),
                TransactionInfoModule.OptionViewItem(title: "Cancel", active: true, action: .cancel)
            ])
        default: return nil
        }
    }

    private func evmFeeItem(coinValue: CoinValue, rate: CurrencyValue?, status: TransactionStatus) -> TransactionInfoModule.ViewItem {
        let value = feeString(coinValue: coinValue, rate: rate)
        let title: String
        switch status {
        case .pending: title = "tx_info.fee.estimated".localized
        case .processing, .failed, .completed: title = "tx_info.fee".localized
        }

        return .fee(title: title, value: value)
    }

    private func feeString(coinValue: CoinValue, rate: CurrencyValue?) -> String {
        var parts = [String]()

        if let formattedCoinValue = ValueFormatter.instance.format(coinValue: coinValue) {
            parts.append(formattedCoinValue)
        }

        if let currencyValue = rate.flatMap({ CurrencyValue(currency: $0.currency, value: $0.value * coinValue.value) }),
           let formattedCurrencyValue = ValueFormatter.instance.format(currencyValue: currencyValue) {
            parts.append(formattedCurrencyValue)
        }

        return parts.joined(separator: " | ")
    }

    private func priceString(coinValue1: CoinValue, coinValue2: CoinValue) -> String {
        let priceDecimal = coinValue1.value.magnitude / coinValue2.value.magnitude
        let price = ValueFormatter.instance.format(value: priceDecimal, decimalCount: priceDecimal.decimalCount, symbol: nil) ?? ""

        return "\(coinValue2.coin.code) = \(price) \(coinValue1.coin.code)"
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

    func items(transaction: TransactionRecord, rates: [Coin: CurrencyValue], lastBlockInfo: LastBlockInfo?) -> [[TransactionInfoModule.ViewItem]] {
        let status = transaction.status(lastBlockHeight: lastBlockInfo?.height)
        var middleSectionItems: [TransactionInfoModule.ViewItem] = [.date(date: transaction.date)]

        switch transaction {
        case let evmIncoming as EvmIncomingTransactionRecord:
            let coinRate = rates[evmIncoming.value.coin]

            middleSectionItems.append(.status(status: status))

            if let rate = coinRate {
                middleSectionItems.append(.rate(value: rateString(currencyValue: rate, coinCode: evmIncoming.value.coin.code)))
            }

            middleSectionItems.append(.from(value: evmIncoming.from))
            middleSectionItems.append(.id(value: evmIncoming.transactionHash))

            return [
                actionSectionItems(title: "transactions.receive".localized, coinValue: evmIncoming.value, rate: coinRate, incoming: true),
                middleSectionItems
            ]

        case let evmOutgoing as EvmOutgoingTransactionRecord:
            let coinRate = rates[evmOutgoing.value.coin]

            middleSectionItems.append(.status(status: status))
            if let resendItem = evmResendItem(status: status) {
                middleSectionItems.append(resendItem)
            }
            middleSectionItems.append(evmFeeItem(coinValue: evmOutgoing.fee, rate: rates[evmOutgoing.fee.coin], status: status))

            if let rate = coinRate {
                middleSectionItems.append(.rate(value: rateString(currencyValue: rate, coinCode: evmOutgoing.value.coin.code)))
            }

            middleSectionItems.append(.to(value: evmOutgoing.to))
            middleSectionItems.append(.id(value: evmOutgoing.transactionHash))

            return [
                actionSectionItems(title: "transactions.send".localized, coinValue: evmOutgoing.value, rate: coinRate, incoming: false),
                middleSectionItems
            ]

        case let swap as SwapTransactionRecord:
            middleSectionItems.append(.status(status: status))
            middleSectionItems.append(evmFeeItem(coinValue: swap.fee, rate: rates[swap.fee.coin], status: status))

            if let valueOut = swap.valueOut {
                if case .failed = status {} else {
                    middleSectionItems.append(.price(price: priceString(coinValue1: swap.valueIn, coinValue2: valueOut)))
                }
            }
            middleSectionItems.append(.service(value: TransactionInfoAddressMapper.map(swap.exchangeAddress)))
            middleSectionItems.append(.id(value: swap.transactionHash))

            var sections = [
                actionSectionItems(title: youPayString(status: status), coinValue: swap.valueIn, rate: rates[swap.valueIn.coin], incoming: false)
            ]

            if let valueOut = swap.valueOut, !swap.foreignRecipient {
                sections.append(actionSectionItems(title: youGetString(status: status), coinValue: valueOut, rate: rates[valueOut.coin], incoming: true))
            }
            sections.append(middleSectionItems)

            return sections

        case let approve as ApproveTransactionRecord:
            let coinRate = rates[approve.value.coin]

            middleSectionItems.append(.status(status: status))
            if let resendItem = evmResendItem(status: status) {
                middleSectionItems.append(resendItem)
            }
            middleSectionItems.append(evmFeeItem(coinValue: approve.fee, rate: rates[approve.fee.coin], status: status))

            if let rate = coinRate {
                middleSectionItems.append(.rate(value: rateString(currencyValue: rate, coinCode: approve.value.coin.code)))
            }

            middleSectionItems.append(.to(value: approve.spender))
            middleSectionItems.append(.id(value: approve.transactionHash))

            let currencyValue = coinRate.flatMap {
                CurrencyValue(currency: $0.currency, value: $0.value * approve.value.value)
            }

            let isMaxValue = approve.value.isMaxValue
            let coinAmount = isMaxValue ? "transactions.value.unlimited".localized(approve.value.coin.code) : currencyValue?.formattedString ?? ""
            let currencyAmount = isMaxValue ? "∞" : approve.value.formattedString

            return [
                [
                    .actionTitle(title: "transactions.approve".localized, subTitle: approve.value.coin.title),
                    .amount(coinAmount: coinAmount, currencyAmount: currencyAmount, incoming: nil)
                ],
                middleSectionItems
            ]

        case let contractCall as ContractCallTransactionRecord:
            var sections: [[TransactionInfoModule.ViewItem]] = [
                [.actionTitle(title: contractCall.method ?? "transactions.contract_call".localized, subTitle: TransactionInfoAddressMapper.map(contractCall.contractAddress))]
            ]

            let transactionValue = contractCall.value

            if contractCall.outgoingEip20Events.count > 0 || (transactionValue.value != 0 && !contractCall.foreignTransaction) {
                var youPaySection: [TransactionInfoModule.ViewItem] = [
                    .actionTitle(title: youPayString(status: status), subTitle: nil)
                ]

                if transactionValue.value != 0 && !contractCall.foreignTransaction {
                    let currencyValue = rates[contractCall.value.coin].flatMap {
                        CurrencyValue(currency: $0.currency, value: $0.value * transactionValue.value)
                    }
                    youPaySection.append(.amount(coinAmount: transactionValue.abs.formattedString, currencyAmount: currencyValue?.abs.formattedString, incoming: false))
                }

                for event in contractCall.outgoingEip20Events {
                    let currencyValue = rates[event.value.coin].flatMap {
                        CurrencyValue(currency: $0.currency, value: $0.value * event.value.value)
                    }
                    youPaySection.append(.amount(coinAmount: event.value.abs.formattedString, currencyAmount: currencyValue?.abs.formattedString, incoming: false))
                }

                sections.append(youPaySection)
            }

            if contractCall.incomingEip20Events.count > 0 || contractCall.incomingInternalETHs.count > 0 {
                var youGetSection: [TransactionInfoModule.ViewItem] = [
                    .actionTitle(title: youGetString(status: status), subTitle: nil)
                ]

                if let ethCoin = contractCall.incomingInternalETHs.first?.value.coin {
                    var ethValue: Decimal = 0
                    for tx in contractCall.incomingInternalETHs {
                        ethValue += tx.value.value
                    }

                    let currencyValue = rates[ethCoin].flatMap {
                        CurrencyValue(currency: $0.currency, value: $0.value * ethValue)
                    }
                    youGetSection.append(.amount(coinAmount: CoinValue(coin: ethCoin, value: ethValue).abs.formattedString, currencyAmount: currencyValue?.abs.formattedString, incoming: true))
                }

                for event in contractCall.incomingEip20Events {
                    let currencyValue = rates[event.value.coin].flatMap {
                        CurrencyValue(currency: $0.currency, value: $0.value * event.value.value)
                    }
                    youGetSection.append(.amount(coinAmount: event.value.abs.formattedString, currencyAmount: currencyValue?.abs.formattedString, incoming: true))
                }

                sections.append(youGetSection)
            }

            middleSectionItems.append(.status(status: status))
            middleSectionItems.append(evmFeeItem(coinValue: contractCall.fee, rate: rates[contractCall.fee.coin], status: status))

            middleSectionItems.append(.id(value: contractCall.transactionHash))

            sections.append(middleSectionItems)

            return sections

        case let btcIncoming as BitcoinIncomingTransactionRecord:
            let coinRate = rates[btcIncoming.value.coin]

            middleSectionItems.append(.status(status: status))

            if let rate = coinRate {
                middleSectionItems.append(.rate(value: rateString(currencyValue: rate, coinCode: btcIncoming.value.coin.code)))
            }

            btcIncoming.from.flatMap { middleSectionItems.append(.from(value: $0)) }
            middleSectionItems.append(.id(value: btcIncoming.transactionHash))
            if let conflictingHash = btcIncoming.conflictingHash {
                middleSectionItems.append(.doubleSpend(txHash: btcIncoming.transactionHash, conflictingTxHash: conflictingHash))
            }
            if btcIncoming.showRawTransaction {
                middleSectionItems.append(.rawTransaction)
            }
            btcIncoming.lockState(lastBlockTimestamp: lastBlockInfo?.timestamp).flatMap { middleSectionItems.append(.lockInfo(lockState: $0)) }
            btcIncoming.memo.flatMap { middleSectionItems.append(.memo(text: $0)) }

            return [
                actionSectionItems(title: "transactions.receive".localized, coinValue: btcIncoming.value, rate: coinRate, incoming: true),
                middleSectionItems
            ]

        case let btcOutgoing as BitcoinOutgoingTransactionRecord:
            let coinRate = rates[btcOutgoing.value.coin]

            middleSectionItems.append(.status(status: status))

            if let fee = btcOutgoing.fee {
                middleSectionItems.append(.fee(title: "tx_info.fee".localized, value: feeString(coinValue: fee, rate: rates[fee.coin])))
            }

            if let rate = coinRate {
                middleSectionItems.append(.rate(value: rateString(currencyValue: rate, coinCode: btcOutgoing.value.coin.code)))
            }

            btcOutgoing.to.flatMap { middleSectionItems.append(.to(value: $0)) }
            middleSectionItems.append(.id(value: btcOutgoing.transactionHash))
            if let conflictingHash = btcOutgoing.conflictingHash {
                middleSectionItems.append(.doubleSpend(txHash: btcOutgoing.transactionHash, conflictingTxHash: conflictingHash))
            }
            if btcOutgoing.showRawTransaction {
                middleSectionItems.append(.rawTransaction)
            }
            btcOutgoing.lockState(lastBlockTimestamp: lastBlockInfo?.timestamp).flatMap { middleSectionItems.append(.lockInfo(lockState: $0)) }
            btcOutgoing.memo.flatMap { middleSectionItems.append(.memo(text: $0)) }

            return [
                actionSectionItems(title: "transactions.send".localized, coinValue: btcOutgoing.value, rate: coinRate, incoming: false),
                middleSectionItems
            ]

        case let tx as BinanceChainIncomingTransactionRecord:
            let coinRate = rates[tx.value.coin]

            middleSectionItems.append(.status(status: status))

            if let rate = coinRate {
                middleSectionItems.append(.rate(value: rateString(currencyValue: rate, coinCode: tx.value.coin.code)))
            }

            middleSectionItems.append(.from(value: tx.from))
            middleSectionItems.append(.id(value: tx.transactionHash))
            tx.memo.flatMap { middleSectionItems.append(.memo(text: $0)) }

            return [
                actionSectionItems(title: "transactions.receive".localized, coinValue: tx.value, rate: coinRate, incoming: true),
                middleSectionItems
            ]

        case let tx as BinanceChainOutgoingTransactionRecord:
            let coinRate = rates[tx.value.coin]

            middleSectionItems.append(.status(status: status))
            middleSectionItems.append(.fee(title: "tx_info.fee".localized, value: feeString(coinValue: tx.fee, rate: rates[tx.fee.coin])))

            if let rate = coinRate {
                middleSectionItems.append(.rate(value: rateString(currencyValue: rate, coinCode: tx.value.coin.code)))
            }

            middleSectionItems.append(.to(value: tx.to))
            middleSectionItems.append(.id(value: tx.transactionHash))
            tx.memo.flatMap { middleSectionItems.append(.memo(text: $0)) }

            return [
                actionSectionItems(title: "transactions.send".localized, coinValue: tx.value, rate: coinRate, incoming: false),
                middleSectionItems
            ]

        default: return []
        }
    }

}
