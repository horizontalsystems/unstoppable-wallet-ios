import CoinKit
import CurrencyKit
import EthereumKit

class TransactionInfoViewItemFactory {

    private func actionSectionItems(title: String, coinValue: CoinValue, rate: CurrencyValue?, incoming: Bool?) -> [TransactionInfoModule.ViewItem] {
        var currencyValue = rate.flatMap {
            CurrencyValue(currency: $0.currency, value: $0.value * coinValue.value)
        }

        return [
            .actionTitle(title: title, subTitle: coinValue.coin.title),
            .amount(coinValue: coinValue, currencyValue: currencyValue, incoming: incoming)
        ]
    }

    func items(transaction: TransactionRecord, rates: [Coin: CurrencyValue], lastBlockInfo: LastBlockInfo?) -> [[TransactionInfoModule.ViewItem]] {
        let status = transaction.status(lastBlockHeight: lastBlockInfo?.height)
        var middleSectionItems: [TransactionInfoModule.ViewItem] = [.date(date: transaction.date)]

        switch transaction {
        case let evmIncoming as EvmIncomingTransactionRecord:
            let coinRate = rates[evmIncoming.value.coin]

            middleSectionItems.append(.status(status: status, completed: "transactions.received".localized, pending: "transactions.receiving".localized))

            if let rate = coinRate {
                middleSectionItems.append(.rate(currencyValue: rate, coinCode: evmIncoming.value.coin.code))
            }

            middleSectionItems.append(.from(value: evmIncoming.from))
            middleSectionItems.append(.id(value: evmIncoming.transactionHash))

            return [
                actionSectionItems(title: "transactions.receive".localized, coinValue: evmIncoming.value, rate: coinRate, incoming: true),
                middleSectionItems
            ]

        case let evmOutgoing as EvmOutgoingTransactionRecord:
            let coinRate = rates[evmOutgoing.value.coin]

            middleSectionItems.append(.status(status: status, completed: "transactions.sent".localized, pending: "transactions.sending".localized))

            if let rate = rates[evmOutgoing.fee.coin] {
                let feeCurrencyValue = CurrencyValue(currency: rate.currency, value: rate.value * evmOutgoing.fee.value)
                middleSectionItems.append(.fee(coinValue: evmOutgoing.fee, currencyValue: feeCurrencyValue))
            }

            if let rate = coinRate {
                middleSectionItems.append(.rate(currencyValue: rate, coinCode: evmOutgoing.value.coin.code))
            }

            middleSectionItems.append(.to(value: evmOutgoing.to))
            middleSectionItems.append(.id(value: evmOutgoing.transactionHash))

            return [
                actionSectionItems(title: "transactions.send".localized, coinValue: evmOutgoing.value, rate: coinRate, incoming: false),
                middleSectionItems
            ]

        case let swap as SwapTransactionRecord:
            middleSectionItems.append(.status(status: status, completed: "transactions.swapped".localized, pending: "transactions.swapping".localized))

            if let rate = rates[swap.fee.coin] {
                let feeCurrencyValue = CurrencyValue(currency: rate.currency, value: rate.value * swap.fee.value)
                middleSectionItems.append(.fee(coinValue: swap.fee, currencyValue: feeCurrencyValue))
            }
            if let valueOut = swap.valueOut {
                middleSectionItems.append(.price(coinValue1: swap.valueIn, coinValue2: valueOut))
            }
            middleSectionItems.append(.id(value: swap.transactionHash))

            var sections = [
                actionSectionItems(title: "tx_info.you_pay".localized, coinValue: swap.valueIn, rate: rates[swap.valueIn.coin], incoming: false)
            ]

            if let valueOut = swap.valueOut {
                sections.append(actionSectionItems(title: "tx_info.you_get".localized, coinValue: valueOut, rate: rates[valueOut.coin], incoming: true))
            }
            sections.append(middleSectionItems)

            return sections

        case let approve as ApproveTransactionRecord:
            let coinRate = rates[approve.value.coin]

            middleSectionItems.append(.status(status: status, completed: "transactions.approve".localized, pending: "transactions.approving".localized))

            if let rate = rates[approve.fee.coin] {
                let feeCurrencyValue = CurrencyValue(currency: rate.currency, value: rate.value * approve.fee.value)
                middleSectionItems.append(.fee(coinValue: approve.fee, currencyValue: feeCurrencyValue))
            }

            if let rate = coinRate {
                middleSectionItems.append(.rate(currencyValue: rate, coinCode: approve.value.coin.code))
            }

            middleSectionItems.append(.to(value: approve.spender))
            middleSectionItems.append(.id(value: approve.transactionHash))

            return [
                actionSectionItems(title: "transactions.approve".localized, coinValue: approve.value, rate: coinRate, incoming: nil),
                middleSectionItems
            ]

        case let contractCall as ContractCallTransactionRecord:
            var sections: [[TransactionInfoModule.ViewItem]] = [
                [.actionTitle(title: contractCall.method ?? "transactions.contract_call".localized, subTitle: TransactionInfoAddressMapper.map(contractCall.contractAddress))]
            ]

            if contractCall.outgoingEip20Events.count > 0 {
                var youPaySection: [TransactionInfoModule.ViewItem] = [
                    .actionTitle(title: "tx_info.you_pay".localized, subTitle: nil)
                ]

                for event in contractCall.outgoingEip20Events {
                    let currencyValue = rates[event.value.coin].flatMap {
                        CurrencyValue(currency: $0.currency, value: $0.value * event.value.value)
                    }
                    youPaySection.append(.amount(coinValue: event.value, currencyValue: currencyValue, incoming: false))
                }

                sections.append(youPaySection)
            }

            if contractCall.incomingEip20Events.count > 0 || contractCall.incomingInternalETHs.count > 0 {
                var youGetSection: [TransactionInfoModule.ViewItem] = [
                    .actionTitle(title: "tx_info.you_get".localized, subTitle: nil)
                ]

                if let ethCoin = contractCall.incomingInternalETHs.first?.value.coin {
                    var ethValue: Decimal = 0
                    for tx in contractCall.incomingInternalETHs {
                        ethValue += tx.value.value
                    }

                    let currencyValue = rates[ethCoin].flatMap {
                        CurrencyValue(currency: $0.currency, value: $0.value * ethValue)
                    }
                    youGetSection.append(.amount(coinValue: CoinValue(coin: ethCoin, value: ethValue), currencyValue: currencyValue, incoming: true))
                }

                for event in contractCall.incomingEip20Events {
                    let currencyValue = rates[event.value.coin].flatMap {
                        CurrencyValue(currency: $0.currency, value: $0.value * event.value.value)
                    }
                    youGetSection.append(.amount(coinValue: event.value, currencyValue: currencyValue, incoming: true))
                }

                sections.append(youGetSection)
            }

            middleSectionItems.append(.status(status: status, completed: "tx_info.status.completed".localized, pending: "tx_info.status.pending".localized))

            if let rate = rates[contractCall.fee.coin] {
                let feeCurrencyValue = CurrencyValue(currency: rate.currency, value: rate.value * contractCall.fee.value)
                middleSectionItems.append(.fee(coinValue: contractCall.fee, currencyValue: feeCurrencyValue))
            }

            middleSectionItems.append(.id(value: contractCall.transactionHash))

            sections.append(middleSectionItems)

            return sections


        default: return []
        }
    }

}
