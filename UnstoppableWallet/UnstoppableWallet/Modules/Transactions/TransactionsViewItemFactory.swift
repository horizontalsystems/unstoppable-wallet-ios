import UIKit
import CurrencyKit
import MarketKit

class TransactionsViewItemFactory {
    private let evmLabelManager: EvmLabelManager

    init(evmLabelManager: EvmLabelManager) {
        self.evmLabelManager = evmLabelManager
    }

    func typeFilterItems(types: [TransactionTypeFilter]) -> [FilterHeaderView.ViewItem] {
        types.map {
            if $0 == .all {
                return .all
            } else {
                return .item(title: "transactions.types.\($0.rawValue)".localized)
            }
        }
    }

    private func coinString(from transactionValue: TransactionValue, showSign: Bool = true) -> String {
        guard let value = transactionValue.formattedShort(showSign: showSign) else {
            return "n/a".localized
        }

        return value
    }

    private func currencyString(from currencyValue: CurrencyValue) -> String {
        ValueFormatter.instance.formatShort(currencyValue: currencyValue) ?? ""
    }

    private func type(value: TransactionValue, condition: Bool = true, _ trueType: TransactionsViewModel.ValueType, _ falseType: TransactionsViewModel.ValueType? = nil) -> TransactionsViewModel.ValueType {
        guard !value.zeroValue else {
            return .neutral
        }

        return condition ? trueType : (falseType ?? trueType)
    }

    private func values(incomingValues: [TransactionValue], outgoingValues: [TransactionValue], currencyValue: CurrencyValue?) -> (TransactionsViewModel.Value?, TransactionsViewModel.Value?) {
        var primaryValue: TransactionsViewModel.Value?
        var secondaryValue: TransactionsViewModel.Value?

        if incomingValues.count == 1, outgoingValues.isEmpty {
            primaryValue = TransactionsViewModel.Value(text: coinString(from: incomingValues[0]), type: type(value: incomingValues[0], .incoming))
            if let currencyValue = currencyValue {
                secondaryValue = TransactionsViewModel.Value(text: currencyString(from: currencyValue), type: .secondary)
            }
        } else if incomingValues.isEmpty, outgoingValues.count == 1 {
            primaryValue = TransactionsViewModel.Value(text: coinString(from: outgoingValues[0]), type: type(value: outgoingValues[0], .outgoing))
            if let currencyValue = currencyValue {
                secondaryValue = TransactionsViewModel.Value(text: currencyString(from: currencyValue), type: .secondary)
            }
        } else if incomingValues.count == 1, outgoingValues.count == 1 {
            primaryValue = TransactionsViewModel.Value(text: coinString(from: incomingValues[0]), type: type(value: incomingValues[0], .incoming))
            secondaryValue = TransactionsViewModel.Value(text: coinString(from: outgoingValues[0]), type:  type(value: outgoingValues[0], .outgoing))
        } else if !incomingValues.isEmpty, outgoingValues.isEmpty {
            let coinCodes = incomingValues.map { $0.coinCode }.joined(separator: ", ")
            primaryValue = TransactionsViewModel.Value(text: coinCodes, type: .incoming)
            secondaryValue = TransactionsViewModel.Value(text: "transactions.multiple".localized, type: .secondary)
        } else if incomingValues.isEmpty, !outgoingValues.isEmpty {
            let coinCodes = outgoingValues.map { $0.coinCode }.joined(separator: ", ")
            primaryValue = TransactionsViewModel.Value(text: coinCodes, type: .outgoing)
            secondaryValue = TransactionsViewModel.Value(text: "transactions.multiple".localized, type: .secondary)
        } else {
            let outgoingCoinCodes = outgoingValues.map { $0.coinCode }.joined(separator: ", ")
            let incomingCoinCodes = incomingValues.map { $0.coinCode }.joined(separator: ", ")
            primaryValue = TransactionsViewModel.Value(text: incomingCoinCodes, type: .incoming)
            secondaryValue = TransactionsViewModel.Value(text: outgoingCoinCodes, type: .outgoing)
        }

        return (primaryValue, secondaryValue)
    }

    func viewItem(item: TransactionsService.Item) -> TransactionsViewModel.ViewItem {
        var iconType: TransactionsViewModel.IconType
        let title: String
        let subTitle: String
        var primaryValue: TransactionsViewModel.Value?
        var secondaryValue: TransactionsViewModel.Value?
        var sentToSelf = false
        var locked: Bool?

        switch item.record {
        case let record as EvmIncomingTransactionRecord:
            iconType = .icon(
                    imageUrl: record.value.coin?.imageUrl,
                    placeholderImageName: record.source.blockchain.type.placeholderImageName(tokenProtocol: record.value.tokenProtocol)
            )
            title = "transactions.receive".localized
            subTitle = "transactions.from".localized(evmLabelManager.mapped(address: record.from))

            primaryValue = TransactionsViewModel.Value(text: coinString(from: record.value), type: type(value: record.value, .incoming))

            if let currencyValue = item.currencyValue {
                secondaryValue = TransactionsViewModel.Value(text: currencyString(from: currencyValue), type: .secondary)
            }

        case let record as EvmOutgoingTransactionRecord:
            iconType = .icon(
                    imageUrl: record.value.coin?.imageUrl,
                    placeholderImageName: record.source.blockchain.type.placeholderImageName(tokenProtocol: record.value.tokenProtocol)
            )
            title = "transactions.send".localized
            subTitle = "transactions.to".localized(evmLabelManager.mapped(address: record.to))

            primaryValue = TransactionsViewModel.Value(text: coinString(from: record.value, showSign: !record.sentToSelf), type: type(value: record.value, condition: record.sentToSelf, .neutral, .outgoing))

            if let currencyValue = item.currencyValue {
                secondaryValue = TransactionsViewModel.Value(text: currencyString(from: currencyValue), type: .secondary)
            }

            sentToSelf = record.sentToSelf

        case let record as SwapTransactionRecord:
            iconType = .doubleIcon(
                    frontImageUrl: record.valueOut?.coin?.imageUrl,
                    frontPlaceholderImageName: record.source.blockchain.type.placeholderImageName(tokenProtocol: record.valueOut?.tokenProtocol),
                    backImageUrl: record.valueIn.coin?.imageUrl,
                    backPlaceholderImageName: record.source.blockchain.type.placeholderImageName(tokenProtocol: record.valueIn.tokenProtocol)
            )
            title = "transactions.swap".localized
            subTitle = evmLabelManager.mapped(address: record.exchangeAddress)

            if let valueOut = record.valueOut {
                primaryValue = TransactionsViewModel.Value(text: coinString(from: valueOut), type: type(value: valueOut, condition: record.recipient != nil, .secondary, .incoming))
            }

            secondaryValue = TransactionsViewModel.Value(text: coinString(from: record.valueIn), type: type(value: record.valueIn, .outgoing))

        case let record as UnknownSwapTransactionRecord:
            iconType = .doubleIcon(
                    frontImageUrl: record.valueOut?.coin?.imageUrl,
                    frontPlaceholderImageName: record.source.blockchain.type.placeholderImageName(tokenProtocol: record.valueOut?.tokenProtocol),
                    backImageUrl: record.valueIn?.coin?.imageUrl,
                    backPlaceholderImageName: record.source.blockchain.type.placeholderImageName(tokenProtocol: record.valueIn?.tokenProtocol)
            )
            title = "transactions.swap".localized
            subTitle = evmLabelManager.mapped(address: record.exchangeAddress)

            if let valueOut = record.valueOut {
                primaryValue = TransactionsViewModel.Value(text: coinString(from: valueOut), type: type(value: valueOut, .incoming))
            }
            if let valueIn = record.valueIn {
                secondaryValue = TransactionsViewModel.Value(text: coinString(from: valueIn), type: type(value: valueIn, .outgoing))
            }

        case let record as ApproveTransactionRecord:
            iconType = .icon(
                    imageUrl: record.value.coin?.imageUrl,
                    placeholderImageName: record.source.blockchain.type.placeholderImageName(tokenProtocol: record.value.tokenProtocol)
            )
            title = "transactions.approve".localized
            subTitle = evmLabelManager.mapped(address: record.spender)

            if record.value.isMaxValue {
                primaryValue = TransactionsViewModel.Value(text: "∞ \(record.value.coinCode)", type: .neutral)
                secondaryValue = TransactionsViewModel.Value(text: "transactions.value.unlimited".localized, type: .secondary)
            } else {
                primaryValue = TransactionsViewModel.Value(text: coinString(from: record.value, showSign: false), type: .neutral)

                if let currencyValue = item.currencyValue {
                    secondaryValue = TransactionsViewModel.Value(text: currencyString(from: currencyValue), type: .secondary)
                }
            }

        case let record as ContractCallTransactionRecord:
            iconType = .localIcon(imageName: record.source.blockchain.type.iconPlain24)
            title = record.method ?? "transactions.contract_call".localized
            subTitle = evmLabelManager.mapped(address: record.contractAddress)

            let (incomingValues, outgoingValues) = record.combinedValues
            (primaryValue, secondaryValue) = values(incomingValues: incomingValues, outgoingValues: outgoingValues, currencyValue: item.currencyValue)

        case let record as ExternalContractCallTransactionRecord:
            let (incomingValues, outgoingValues) = record.combinedValues

            if outgoingValues.isEmpty && incomingValues.count == 1 {
                let value = incomingValues[0]
                iconType = .icon(
                        imageUrl: value.coin?.imageUrl,
                        placeholderImageName: record.source.blockchain.type.placeholderImageName(tokenProtocol: value.tokenProtocol)
                )
            } else {
                iconType = .localIcon(imageName: record.source.blockchain.type.iconPlain24)
            }

            if record.outgoingEvents.isEmpty {
                title = "transactions.receive".localized
                let addresses = Array(Set(record.incomingEvents.map { $0.address }))
                if addresses.count == 1 {
                    subTitle = "transactions.from".localized(evmLabelManager.mapped(address: addresses[0]))
                } else {
                    subTitle = "transactions.multiple".localized
                }
            } else {
                title = "transactions.external_call".localized
                subTitle = "---"
            }

            (primaryValue, secondaryValue) = values(incomingValues: incomingValues, outgoingValues: outgoingValues, currencyValue: item.currencyValue)

        case let record as ContractCreationTransactionRecord:
            iconType = .localIcon(imageName: record.source.blockchain.type.iconPlain24)
            title = "transactions.contract_creation".localized
            subTitle = "---"

        case let record as BitcoinIncomingTransactionRecord:
            iconType = .icon(
                    imageUrl: record.value.coin?.imageUrl,
                    placeholderImageName: "icon_placeholder_24"
            )
            title = "transactions.receive".localized
            subTitle = record.from.flatMap { "transactions.from".localized(evmLabelManager.mapped(address: $0)) } ?? "---"

            primaryValue = TransactionsViewModel.Value(text: coinString(from: record.value), type: type(value: record.value, .incoming))
            if let currencyValue = item.currencyValue {
                secondaryValue = TransactionsViewModel.Value(text: currencyString(from: currencyValue), type: .secondary)
            }

            if let lockState = record.lockState(lastBlockTimestamp: item.lastBlockInfo?.timestamp) {
                locked = lockState.locked
            }

        case let record as BitcoinOutgoingTransactionRecord:
            iconType = .icon(
                    imageUrl: record.value.coin?.imageUrl,
                    placeholderImageName: "icon_placeholder_24"
            )
            title = "transactions.send".localized
            subTitle =  record.to.flatMap { "transactions.to".localized(evmLabelManager.mapped(address: $0)) } ?? "---"

            primaryValue = TransactionsViewModel.Value(text: coinString(from: record.value, showSign: !record.sentToSelf), type: type(value: record.value, condition: record.sentToSelf, .neutral, .outgoing))

            if let currencyValue = item.currencyValue {
                secondaryValue = TransactionsViewModel.Value(text: currencyString(from: currencyValue), type: .secondary)
            }

            sentToSelf = record.sentToSelf
            if let lockState = record.lockState(lastBlockTimestamp: item.lastBlockInfo?.timestamp) {
                locked = lockState.locked
            }

        case let record as BinanceChainIncomingTransactionRecord:
            iconType = .icon(
                    imageUrl: record.value.coin?.imageUrl,
                    placeholderImageName: record.source.blockchain.type.placeholderImageName(tokenProtocol: record.value.tokenProtocol)
            )
            title = "transactions.receive".localized
            subTitle = "transactions.from".localized(evmLabelManager.mapped(address: record.from))

            primaryValue = TransactionsViewModel.Value(text: coinString(from: record.value), type: type(value: record.value, .incoming))
            if let currencyValue = item.currencyValue {
                secondaryValue = TransactionsViewModel.Value(text: currencyString(from: currencyValue), type: .secondary)
            }

        case let record as BinanceChainOutgoingTransactionRecord:
            iconType = .icon(
                    imageUrl: record.value.coin?.imageUrl,
                    placeholderImageName: record.source.blockchain.type.placeholderImageName(tokenProtocol: record.value.tokenProtocol)
            )
            title = "transactions.send".localized
            subTitle = "transactions.to".localized(evmLabelManager.mapped(address: record.to))

            primaryValue = TransactionsViewModel.Value(text: coinString(from: record.value, showSign: !record.sentToSelf), type: type(value: record.value, condition: record.sentToSelf, .neutral, .outgoing))

            if let currencyValue = item.currencyValue {
                secondaryValue = TransactionsViewModel.Value(text: currencyString(from: currencyValue), type: .secondary)
            }

            sentToSelf = record.sentToSelf

        default:
            iconType = .localIcon(imageName: item.record.source.blockchain.type.iconPlain24)
            title = "transactions.unknown_transaction.title".localized
            subTitle = "transactions.unknown_transaction.description".localized()
        }

        let progress: Float?

        switch item.record.status(lastBlockHeight: item.lastBlockInfo?.height) {
        case .pending:
            progress = 0.2

        case .processing(let p):
            progress = Float(p) * 0.8 + 0.2

        case .failed:
            progress = nil
            iconType = .failedIcon

        case .completed:
            progress = nil
        }

        return TransactionsViewModel.ViewItem(
                uid: item.record.uid,
                date: item.record.date,
                iconType: iconType,
                progress: progress,
                blockchainImageName: nil,
                title: title,
                subTitle: subTitle,
                primaryValue: primaryValue,
                secondaryValue: secondaryValue,
                sentToSelf: sentToSelf,
                locked: locked
        )
    }

    func coinFilter(wallet: TransactionWallet) -> MarketDiscoveryFilterHeaderView.ViewItem? {
        guard let token = wallet.token else {
            return nil
        }

        return MarketDiscoveryFilterHeaderView.ViewItem(iconUrl: token.coin.imageUrl, iconPlaceholder: token.placeholderImageName, title: token.coin.code, blockchainBadge: wallet.badge)
    }

}
