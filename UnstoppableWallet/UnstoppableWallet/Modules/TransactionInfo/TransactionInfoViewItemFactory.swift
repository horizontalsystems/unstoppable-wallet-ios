import MarketKit
import CurrencyKit
import EthereumKit

class TransactionInfoViewItemFactory {
    private let accountSettingManager: AccountSettingManager

    init(accountSettingManager: AccountSettingManager) {
        self.accountSettingManager = accountSettingManager
    }

    private func actionSectionItems(title: String, transactionValue: TransactionValue, rate: CurrencyValue?, incoming: Bool?) -> [TransactionInfoModule.ViewItem] {
        var currencyValue: CurrencyValue? = nil
        if let rate = rate, case .coinValue(_, let value) = transactionValue {
            currencyValue = CurrencyValue(currency: rate.currency, value: rate.value * value)
        }

        let subTitle: String
        switch transactionValue {
        case .coinValue(let platformCoin, _): subTitle = platformCoin.coin.name
        case .rawValue(let coinType, _): subTitle = coinType.title
        }

        return [
            .actionTitle(title: title, subTitle: subTitle),
            .amount(coinAmount: transactionValue.abs.formattedString, currencyAmount: currencyValue?.abs.formattedString, incoming: incoming)
        ]
    }

    private func evmResendItem(status: TransactionStatus) -> TransactionInfoModule.ViewItem? {
        switch status {
        case .pending:
            return .options(actions: [
                TransactionInfoModule.OptionViewItem(title: "tx_info.options.speed_up".localized, active: true, option: .speedUp),
                TransactionInfoModule.OptionViewItem(title: "tx_info.options.cancel".localized, active: true, option: .cancel)
            ])
        default: return nil
        }
    }

    private func evmFeeItem(transactionValue: TransactionValue, rate: CurrencyValue?, status: TransactionStatus) -> TransactionInfoModule.ViewItem {
        let value = feeString(transactionValue: transactionValue, rate: rate)
        let title: String
        switch status {
        case .pending: title = "tx_info.fee.estimated".localized
        case .processing, .failed, .completed: title = "tx_info.fee".localized
        }

        return .fee(title: title, value: value)
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

    private func priceString(valueIn: TransactionValue, valueOut: TransactionValue, coinPriceIn: CurrencyValue?) -> String {
        guard case .coinValue(let valueInPlatformCoin, let valueInDecimal) = valueIn,
              case .coinValue(let valueOutPlatformCoin, let valueOutDecimal) = valueOut else {
            return "n/a"
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

    func explorerViewItem(record: TransactionRecord, testMode: Bool) -> TransactionInfoModule.ViewItem {
        let source = record.source
        let transactionHash = record.transactionHash

        let blockchain = source.blockchain
        let account = source.account

        var title: String
        var url: String?
        switch blockchain {
        case .bitcoin:
            title = "btc.com"
            url = testMode ? nil : "https://btc.com/" + transactionHash
        case .bitcoinCash:
            title = "btc.com"
            url = testMode ? nil : "https://bch.btc.com/" + transactionHash
        case .litecoin:
            title = "blockchair.com"
            url = testMode ? nil : "https://blockchair.com/litecoin/transaction/" + transactionHash
        case .dash:
            title = "dash.org"
            url = testMode ? nil : "https://insight.dash.org/insight/tx/" + transactionHash
        case .ethereum:
            let domain: String

            switch accountSettingManager.ethereumNetwork(account: account).networkType {
            case .ropsten: domain = "ropsten.etherscan.io"
            case .rinkeby: domain = "rinkeby.etherscan.io"
            case .kovan: domain = "kovan.etherscan.io"
            case .goerli: domain = "goerli.etherscan.io"
            default: domain = "etherscan.io"
            }

            title = "etherscan.io"
            url = "https://\(domain)/tx/" + transactionHash
        case .binanceSmartChain:
            let domain: String

            switch accountSettingManager.binanceSmartChainNetwork(account: account).networkType {
            default: domain = "bscscan.com"
            }

            title = "bscscan.com"
            url = testMode ? nil : "https://\(domain)/tx/" + transactionHash
        case .bep2:
            title = "binance.org"
            url = testMode ? "https://testnet-explorer.binance.org/tx/" + transactionHash : "https://explorer.binance.org/tx/" + transactionHash
        case .zcash:
            title = "blockchair.com"
            url = testMode ? nil : "https://blockchair.com/zcash/transaction/" + transactionHash
        }

        return .explorer(title: "tx_info.view_on".localized(title), url: url)
    }

    func items(transaction: TransactionRecord, rates: [Coin: CurrencyValue], lastBlockInfo: LastBlockInfo?) -> [[TransactionInfoModule.ViewItem]] {
        let status = transaction.status(lastBlockHeight: lastBlockInfo?.height)
        var middleSectionItems: [TransactionInfoModule.ViewItem] = [.date(date: transaction.date)]

        func _rate(_ value: TransactionValue) -> CurrencyValue? {
            value.coin.flatMap { rates[$0] }
        }

        func _currencyValue(_ value: TransactionValue) -> CurrencyValue? {
            if let rate = _rate(value), let value = value.decimalValue {
                return CurrencyValue(currency: rate.currency, value: rate.value * value)
            } else {
                return nil
            }
        }

        switch transaction {
        case let evmIncoming as EvmIncomingTransactionRecord:
            let coinRate = _rate(evmIncoming.value)

            middleSectionItems.append(.status(status: status))

            if let coin = evmIncoming.value.coin, let rate = coinRate {
                middleSectionItems.append(.rate(value: rateString(currencyValue: rate, coinCode: coin.code)))
            }

            middleSectionItems.append(.from(value: evmIncoming.from))
            middleSectionItems.append(.id(value: evmIncoming.transactionHash))

            return [
                actionSectionItems(title: "transactions.receive".localized, transactionValue: evmIncoming.value, rate: coinRate, incoming: true),
                middleSectionItems
            ]

        case let evmOutgoing as EvmOutgoingTransactionRecord:
            let coinRate = _rate(evmOutgoing.value)

            middleSectionItems.append(.status(status: status))
            if let resendItem = evmResendItem(status: status) {
                middleSectionItems.append(resendItem)
            }
            middleSectionItems.append(evmFeeItem(transactionValue: evmOutgoing.fee, rate: _rate(evmOutgoing.value), status: status))

            if let coin = evmOutgoing.value.coin, let rate = coinRate {
                middleSectionItems.append(.rate(value: rateString(currencyValue: rate, coinCode: coin.code)))
            }

            middleSectionItems.append(.to(value: evmOutgoing.to))
            middleSectionItems.append(.id(value: evmOutgoing.transactionHash))

            return [
                actionSectionItems(title: "transactions.send".localized, transactionValue: evmOutgoing.value, rate: coinRate, incoming: false),
                middleSectionItems
            ]

        case let swap as SwapTransactionRecord:
            middleSectionItems.append(.status(status: status))
            middleSectionItems.append(evmFeeItem(transactionValue: swap.fee, rate: _rate(swap.fee), status: status))

            if let valueOut = swap.valueOut {
                if case .failed = status {} else {
                    middleSectionItems.append(.price(price: priceString(valueIn: swap.valueIn, valueOut: valueOut, coinPriceIn: _rate(swap.valueIn))))
                }
            }
            middleSectionItems.append(.service(value: TransactionInfoAddressMapper.map(swap.exchangeAddress)))
            middleSectionItems.append(.id(value: swap.transactionHash))

            var sections = [
                actionSectionItems(title: youPayString(status: status), transactionValue: swap.valueIn, rate: _rate(swap.valueIn), incoming: false)
            ]

            if let valueOut = swap.valueOut, !swap.foreignRecipient {
                sections.append(actionSectionItems(title: youGetString(status: status), transactionValue: valueOut, rate: _rate(valueOut), incoming: true))
            }
            sections.append(middleSectionItems)

            return sections

        case let approve as ApproveTransactionRecord:
            let coinRate = _rate(approve.value)

            middleSectionItems.append(.status(status: status))
            if let resendItem = evmResendItem(status: status) {
                middleSectionItems.append(resendItem)
            }
            middleSectionItems.append(evmFeeItem(transactionValue: approve.fee, rate: _rate(approve.fee), status: status))

            if let rate = coinRate, let coin = approve.value.coin {
                middleSectionItems.append(.rate(value: rateString(currencyValue: rate, coinCode: coin.code)))
            }

            middleSectionItems.append(.to(value: approve.spender))
            middleSectionItems.append(.id(value: approve.transactionHash))

            let currencyValue = _currencyValue(approve.value)
            let isMaxValue = approve.value.isMaxValue
            let coinAmount = isMaxValue ? "transactions.value.unlimited".localized(approve.value.coinCode) : currencyValue?.formattedString ?? ""
            let currencyAmount = isMaxValue ? "∞" : approve.value.formattedString

            return [
                [
                    .actionTitle(title: "transactions.approve".localized, subTitle: approve.value.coinName),
                    .amount(coinAmount: coinAmount, currencyAmount: currencyAmount, incoming: nil)
                ],
                middleSectionItems
            ]

        case let contractCall as ContractCallTransactionRecord:
            var sections: [[TransactionInfoModule.ViewItem]] = [
                [.actionTitle(title: contractCall.method ?? "transactions.contract_call".localized, subTitle: TransactionInfoAddressMapper.map(contractCall.contractAddress))]
            ]

            let transactionValue = contractCall.value

            if contractCall.outgoingEip20Events.count > 0 || (!transactionValue.zeroValue && !contractCall.foreignTransaction) {
                var youPaySection: [TransactionInfoModule.ViewItem] = [
                    .actionTitle(title: youPayString(status: status), subTitle: nil)
                ]

                if !transactionValue.zeroValue && !contractCall.foreignTransaction {
                    let currencyValue = _currencyValue(transactionValue)
                    youPaySection.append(.amount(coinAmount: transactionValue.abs.formattedString, currencyAmount: currencyValue?.abs.formattedString, incoming: false))
                }

                for event in contractCall.outgoingEip20Events {
                    let currencyValue = _currencyValue(event.value)
                    youPaySection.append(.amount(coinAmount: event.value.abs.formattedString, currencyAmount: currencyValue?.abs.formattedString, incoming: false))
                }

                sections.append(youPaySection)
            }

            if contractCall.incomingEip20Events.count > 0 || contractCall.incomingInternalETHs.count > 0 {
                var youGetSection: [TransactionInfoModule.ViewItem] = [
                    .actionTitle(title: youGetString(status: status), subTitle: nil)
                ]

                if let incomingInternalTx = contractCall.incomingInternalETHs.first?.value, case .coinValue(let platformCoin, _) = incomingInternalTx {
                    var ethValue: Decimal = 0
                    for tx in contractCall.incomingInternalETHs {
                        ethValue += tx.value.decimalValue ?? 0
                    }

                    let transactionValue = TransactionValue.coinValue(platformCoin: platformCoin, value: ethValue)

                    let currencyValue = _currencyValue(transactionValue)
                    youGetSection.append(.amount(coinAmount: transactionValue.abs.formattedString, currencyAmount: currencyValue?.abs.formattedString, incoming: true))
                }

                for event in contractCall.incomingEip20Events {
                    let currencyValue = _currencyValue(event.value)
                    youGetSection.append(.amount(coinAmount: event.value.abs.formattedString, currencyAmount: currencyValue?.abs.formattedString, incoming: true))
                }

                sections.append(youGetSection)
            }

            middleSectionItems.append(.status(status: status))
            middleSectionItems.append(evmFeeItem(transactionValue: contractCall.fee, rate: _rate(contractCall.fee), status: status))

            middleSectionItems.append(.id(value: contractCall.transactionHash))

            sections.append(middleSectionItems)

            return sections

        case let btcIncoming as BitcoinIncomingTransactionRecord:
            let coinRate = _rate(btcIncoming.value)

            middleSectionItems.append(.status(status: status))

            if let rate = coinRate, let coin = btcIncoming.value.coin {
                middleSectionItems.append(.rate(value: rateString(currencyValue: rate, coinCode: coin.code)))
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
                actionSectionItems(title: "transactions.receive".localized, transactionValue: btcIncoming.value, rate: coinRate, incoming: true),
                middleSectionItems
            ]

        case let btcOutgoing as BitcoinOutgoingTransactionRecord:
            let coinRate = _rate(btcOutgoing.value)

            middleSectionItems.append(.status(status: status))

            if let fee = btcOutgoing.fee {
                middleSectionItems.append(.fee(title: "tx_info.fee".localized, value: feeString(transactionValue: fee, rate: _rate(fee))))
            }

            if let rate = coinRate, let coin = btcOutgoing.value.coin {
                middleSectionItems.append(.rate(value: rateString(currencyValue: rate, coinCode: coin.code)))
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
                actionSectionItems(title: "transactions.send".localized, transactionValue: btcOutgoing.value, rate: coinRate, incoming: false),
                middleSectionItems
            ]

        case let tx as BinanceChainIncomingTransactionRecord:
            let coinRate = _rate(tx.value)

            middleSectionItems.append(.status(status: status))

            if let rate = coinRate, let coin = tx.value.coin {
                middleSectionItems.append(.rate(value: rateString(currencyValue: rate, coinCode: coin.code)))
            }

            middleSectionItems.append(.from(value: tx.from))
            middleSectionItems.append(.id(value: tx.transactionHash))
            tx.memo.flatMap { middleSectionItems.append(.memo(text: $0)) }

            return [
                actionSectionItems(title: "transactions.receive".localized, transactionValue: tx.value, rate: coinRate, incoming: true),
                middleSectionItems
            ]

        case let tx as BinanceChainOutgoingTransactionRecord:
            let coinRate = _rate(tx.value)

            middleSectionItems.append(.status(status: status))
            middleSectionItems.append(.fee(title: "tx_info.fee".localized, value: feeString(transactionValue: tx.fee, rate: _rate(tx.fee))))

            if let rate = coinRate, let coin = tx.value.coin {
                middleSectionItems.append(.rate(value: rateString(currencyValue: rate, coinCode: coin.code)))
            }

            middleSectionItems.append(.to(value: tx.to))
            middleSectionItems.append(.id(value: tx.transactionHash))
            tx.memo.flatMap { middleSectionItems.append(.memo(text: $0)) }

            return [
                actionSectionItems(title: "transactions.send".localized, transactionValue: tx.value, rate: coinRate, incoming: false),
                middleSectionItems
            ]

        default: return []
        }
    }

}
