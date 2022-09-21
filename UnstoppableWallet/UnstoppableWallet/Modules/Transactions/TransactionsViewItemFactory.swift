import UIKit
import CurrencyKit
import MarketKit
import ComponentKit

class TransactionsViewItemFactory {
    private let evmLabelManager: EvmLabelManager

    init(evmLabelManager: EvmLabelManager) {
        self.evmLabelManager = evmLabelManager
    }

    func typeFilterViewItems(typeFilters: [TransactionTypeFilter]) -> [FilterHeaderView.ViewItem] {
        typeFilters.map {
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

    private func singleValueSecondaryValue(value: TransactionValue, currencyValue: CurrencyValue?, nftMetadata: [NftUid: NftAssetBriefMetadata]) -> TransactionsViewModel.Value? {
        switch value {
        case let .nftValue(nftUid, _, tokenName, _):
            let text = nftMetadata[nftUid]?.name ?? tokenName.map { "\($0) #\(nftUid.tokenId)" } ?? "#\(nftUid.tokenId)"
            return TransactionsViewModel.Value(text: text, type: .secondary)
        default:
            return currencyValue.map { TransactionsViewModel.Value(text: currencyString(from: $0), type: .secondary) }
        }
    }

    private func singleValueIconType(source: TransactionSource, value: TransactionValue, nftMetadata: [NftUid: NftAssetBriefMetadata] = [:]) -> TransactionsViewModel.IconType {
        switch value {
        case let .nftValue(nftUid, _, _, _):
            return .icon(
                    imageUrl: nftMetadata[nftUid]?.previewImageUrl,
                    placeholderImageName: "placeholder_nft_24"
            )
        default:
            return .icon(
                    imageUrl: value.coin?.imageUrl,
                    placeholderImageName: source.blockchainType.placeholderImageName(tokenProtocol: value.tokenProtocol)
            )
        }
    }

    private func doubleValueIconType(source: TransactionSource, primaryValue: TransactionValue?, secondaryValue: TransactionValue?, nftMetadata: [NftUid: NftAssetBriefMetadata] = [:]) -> TransactionsViewModel.IconType {
        let frontType: TransactionImageComponent.ImageType
        let frontUrl: String?
        let frontPlaceholder: String
        let backType: TransactionImageComponent.ImageType
        let backUrl: String?
        let backPlaceholder: String

        if let primaryValue = primaryValue {
            switch primaryValue {
            case let .nftValue(nftUid, _, _, _):
                frontType = .squircle
                frontUrl = nftMetadata[nftUid]?.previewImageUrl
                frontPlaceholder = "placeholder_nft_24"
            default:
                frontType = .circle
                frontUrl = primaryValue.coin?.imageUrl
                frontPlaceholder = source.blockchainType.placeholderImageName(tokenProtocol: primaryValue.tokenProtocol)
            }
        } else {
            frontType = .circle
            frontUrl = nil
            frontPlaceholder = "icon_placeholder_24"
        }

        if let secondaryValue = secondaryValue {
            switch secondaryValue {
            case let .nftValue(nftUid, _, _, _):
                backType = .squircle
                backUrl = nftMetadata[nftUid]?.previewImageUrl
                backPlaceholder = "placeholder_nft_24"
            default:
                backType = .circle
                backUrl = secondaryValue.coin?.imageUrl
                backPlaceholder = source.blockchainType.placeholderImageName(tokenProtocol: secondaryValue.tokenProtocol)
            }
        } else {
            backType = .circle
            backUrl = nil
            backPlaceholder = "icon_placeholder_24"
        }

        return .doubleIcon(frontType: frontType, frontUrl: frontUrl, frontPlaceholder: frontPlaceholder, backType: backType, backUrl: backUrl, backPlaceholder: backPlaceholder)
    }

    private func iconType(source: TransactionSource, incomingValues: [TransactionValue], outgoingValues: [TransactionValue], nftMetadata: [NftUid: NftAssetBriefMetadata]) -> TransactionsViewModel.IconType {
        if incomingValues.count == 1, outgoingValues.isEmpty {
            return singleValueIconType(source: source, value: incomingValues[0], nftMetadata: nftMetadata)
        } else if incomingValues.isEmpty, outgoingValues.count == 1 {
            return singleValueIconType(source: source, value: outgoingValues[0], nftMetadata: nftMetadata)
        } else if incomingValues.count == 1, outgoingValues.count == 1 {
            return doubleValueIconType(source: source, primaryValue: incomingValues[0], secondaryValue: outgoingValues[0], nftMetadata: nftMetadata)
        } else {
            return .localIcon(imageName: source.blockchainType.iconPlain24)
        }
    }

    private func values(incomingValues: [TransactionValue], outgoingValues: [TransactionValue], currencyValue: CurrencyValue?, nftMetadata: [NftUid: NftAssetBriefMetadata]) -> (TransactionsViewModel.Value?, TransactionsViewModel.Value?) {
        var primaryValue: TransactionsViewModel.Value?
        var secondaryValue: TransactionsViewModel.Value?

        if incomingValues.count == 1, outgoingValues.isEmpty {
            let incomingValue = incomingValues[0]
            primaryValue = TransactionsViewModel.Value(text: coinString(from: incomingValue), type: type(value: incomingValue, .incoming))
            secondaryValue = singleValueSecondaryValue(value: incomingValue, currencyValue: currencyValue, nftMetadata: nftMetadata)
        } else if incomingValues.isEmpty, outgoingValues.count == 1 {
            let outgoingValue = outgoingValues[0]
            primaryValue = TransactionsViewModel.Value(text: coinString(from: outgoingValue), type: type(value: outgoingValue, .outgoing))
            secondaryValue = singleValueSecondaryValue(value: outgoingValue, currencyValue: currencyValue, nftMetadata: nftMetadata)
        } else if !incomingValues.isEmpty, outgoingValues.isEmpty {
            let coinCodes = incomingValues.map { $0.coinCode }.joined(separator: ", ")
            primaryValue = TransactionsViewModel.Value(text: coinCodes, type: .incoming)
            secondaryValue = TransactionsViewModel.Value(text: "transactions.multiple".localized, type: .secondary)
        } else if incomingValues.isEmpty, !outgoingValues.isEmpty {
            let coinCodes = outgoingValues.map { $0.coinCode }.joined(separator: ", ")
            primaryValue = TransactionsViewModel.Value(text: coinCodes, type: .outgoing)
            secondaryValue = TransactionsViewModel.Value(text: "transactions.multiple".localized, type: .secondary)
        } else {
            if incomingValues.count == 1 {
                primaryValue = TransactionsViewModel.Value(text: coinString(from: incomingValues[0]), type: type(value: incomingValues[0], .incoming))
            } else {
                let incomingCoinCodes = incomingValues.map { $0.coinCode }.joined(separator: ", ")
                primaryValue = TransactionsViewModel.Value(text: incomingCoinCodes, type: .incoming)
            }
            if outgoingValues.count == 1 {
                secondaryValue = TransactionsViewModel.Value(text: coinString(from: outgoingValues[0]), type:  type(value: outgoingValues[0], .outgoing))
            } else {
                let outgoingCoinCodes = outgoingValues.map { $0.coinCode }.joined(separator: ", ")
                secondaryValue = TransactionsViewModel.Value(text: outgoingCoinCodes, type: .outgoing)
            }
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
            iconType = singleValueIconType(source: record.source, value: record.value)
            title = "transactions.receive".localized
            subTitle = "transactions.from".localized(evmLabelManager.mapped(address: record.from))

            primaryValue = TransactionsViewModel.Value(text: coinString(from: record.value), type: type(value: record.value, .incoming))

            if let currencyValue = item.currencyValue {
                secondaryValue = TransactionsViewModel.Value(text: currencyString(from: currencyValue), type: .secondary)
            }

        case let record as EvmOutgoingTransactionRecord:
            iconType = singleValueIconType(source: record.source, value: record.value, nftMetadata: item.nftMetadata)
            title = "transactions.send".localized
            subTitle = "transactions.to".localized(evmLabelManager.mapped(address: record.to))

            primaryValue = TransactionsViewModel.Value(text: coinString(from: record.value, showSign: !record.sentToSelf), type: type(value: record.value, condition: record.sentToSelf, .neutral, .outgoing))
            secondaryValue = singleValueSecondaryValue(value: record.value, currencyValue: item.currencyValue, nftMetadata: item.nftMetadata)

            sentToSelf = record.sentToSelf

        case let record as SwapTransactionRecord:
            iconType = doubleValueIconType(source: record.source, primaryValue: record.valueOut, secondaryValue: record.valueIn)
            title = "transactions.swap".localized
            subTitle = evmLabelManager.mapped(address: record.exchangeAddress)

            if let valueOut = record.valueOut {
                primaryValue = TransactionsViewModel.Value(text: coinString(from: valueOut), type: type(value: valueOut, condition: record.recipient != nil, .secondary, .incoming))
            }

            secondaryValue = TransactionsViewModel.Value(text: coinString(from: record.valueIn), type: type(value: record.valueIn, .outgoing))

        case let record as UnknownSwapTransactionRecord:
            iconType = doubleValueIconType(source: record.source, primaryValue: record.valueOut, secondaryValue: record.valueIn)
            title = "transactions.swap".localized
            subTitle = evmLabelManager.mapped(address: record.exchangeAddress)

            if let valueOut = record.valueOut {
                primaryValue = TransactionsViewModel.Value(text: coinString(from: valueOut), type: type(value: valueOut, .incoming))
            }
            if let valueIn = record.valueIn {
                secondaryValue = TransactionsViewModel.Value(text: coinString(from: valueIn), type: type(value: valueIn, .outgoing))
            }

        case let record as ApproveTransactionRecord:
            iconType = singleValueIconType(source: record.source, value: record.value)
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
            let (incomingValues, outgoingValues) = record.combinedValues

            iconType = self.iconType(source: record.source, incomingValues: incomingValues, outgoingValues: outgoingValues, nftMetadata: item.nftMetadata)
            title = record.method ?? "transactions.contract_call".localized
            subTitle = evmLabelManager.mapped(address: record.contractAddress)

            (primaryValue, secondaryValue) = values(incomingValues: incomingValues, outgoingValues: outgoingValues, currencyValue: item.currencyValue, nftMetadata: item.nftMetadata)

        case let record as ExternalContractCallTransactionRecord:
            let (incomingValues, outgoingValues) = record.combinedValues

            iconType = self.iconType(source: record.source, incomingValues: incomingValues, outgoingValues: outgoingValues, nftMetadata: item.nftMetadata)

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

            (primaryValue, secondaryValue) = values(incomingValues: incomingValues, outgoingValues: outgoingValues, currencyValue: item.currencyValue, nftMetadata: item.nftMetadata)

        case let record as ContractCreationTransactionRecord:
            iconType = .localIcon(imageName: record.source.blockchainType.iconPlain24)
            title = "transactions.contract_creation".localized
            subTitle = "---"

        case let record as BitcoinIncomingTransactionRecord:
            iconType = singleValueIconType(source: record.source, value: record.value)
            title = "transactions.receive".localized
            subTitle = record.from.flatMap { "transactions.from".localized(evmLabelManager.mapped(address: $0)) } ?? "---"

            primaryValue = TransactionsViewModel.Value(text: coinString(from: record.value), type: type(value: record.value, .incoming))
            if let currencyValue = item.currencyValue {
                secondaryValue = TransactionsViewModel.Value(text: currencyString(from: currencyValue), type: .secondary)
            }

            if let lockState = item.transactionItem.lockState {
                locked = lockState.locked
            }

        case let record as BitcoinOutgoingTransactionRecord:
            iconType = singleValueIconType(source: record.source, value: record.value)
            title = "transactions.send".localized
            subTitle =  record.to.flatMap { "transactions.to".localized(evmLabelManager.mapped(address: $0)) } ?? "---"

            primaryValue = TransactionsViewModel.Value(text: coinString(from: record.value, showSign: !record.sentToSelf), type: type(value: record.value, condition: record.sentToSelf, .neutral, .outgoing))

            if let currencyValue = item.currencyValue {
                secondaryValue = TransactionsViewModel.Value(text: currencyString(from: currencyValue), type: .secondary)
            }

            sentToSelf = record.sentToSelf
            if let lockState = item.transactionItem.lockState {
                locked = lockState.locked
            }

        case let record as BinanceChainIncomingTransactionRecord:
            iconType = singleValueIconType(source: record.source, value: record.value)
            title = "transactions.receive".localized
            subTitle = "transactions.from".localized(evmLabelManager.mapped(address: record.from))

            primaryValue = TransactionsViewModel.Value(text: coinString(from: record.value), type: type(value: record.value, .incoming))
            if let currencyValue = item.currencyValue {
                secondaryValue = TransactionsViewModel.Value(text: currencyString(from: currencyValue), type: .secondary)
            }

        case let record as BinanceChainOutgoingTransactionRecord:
            iconType = singleValueIconType(source: record.source, value: record.value)
            title = "transactions.send".localized
            subTitle = "transactions.to".localized(evmLabelManager.mapped(address: record.to))

            primaryValue = TransactionsViewModel.Value(text: coinString(from: record.value, showSign: !record.sentToSelf), type: type(value: record.value, condition: record.sentToSelf, .neutral, .outgoing))

            if let currencyValue = item.currencyValue {
                secondaryValue = TransactionsViewModel.Value(text: currencyString(from: currencyValue), type: .secondary)
            }

            sentToSelf = record.sentToSelf

        default:
            iconType = .localIcon(imageName: item.record.source.blockchainType.iconPlain24)
            title = "transactions.unknown_transaction.title".localized
            subTitle = "transactions.unknown_transaction.description".localized()
        }

        let progress: Float?

        switch item.transactionItem.status {
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

}
