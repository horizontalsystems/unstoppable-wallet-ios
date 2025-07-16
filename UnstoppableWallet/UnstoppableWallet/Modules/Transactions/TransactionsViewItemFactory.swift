import MarketKit
import UIKit

class TransactionsViewItemFactory {
    private let evmLabelManager = Core.shared.evmLabelManager
    private let contactLabelService: TransactionsContactLabelService

    init(contactLabelService: TransactionsContactLabelService) {
        self.contactLabelService = contactLabelService
    }

    func typeFilterViewItems(typeFilters: [TransactionTypeFilter]) -> [FilterView.ViewItem] {
        typeFilters.map {
            if $0 == .all {
                return .all
            } else {
                return .item(title: "transactions.types.\($0.rawValue)".localized)
            }
        }
    }

    private func mapped(address: String, blockchainType: BlockchainType) -> String {
        contactLabelService.contactData(for: address, blockchainType: blockchainType).name ?? evmLabelManager.mapped(address: address)
    }

    private func coinString(from appValue: AppValue, signType: ValueFormatter.SignType = .always) -> String {
        guard let value = appValue.formattedShort(signType: signType) else {
            return "n/a".localized
        }

        return value
    }

    private func currencyString(from currencyValue: CurrencyValue) -> String {
        ValueFormatter.instance.formatShort(currencyValue: currencyValue) ?? ""
    }

    private func type(value: AppValue, condition: Bool = true, _ trueType: TransactionsViewModel.ValueType, _ falseType: TransactionsViewModel.ValueType? = nil) -> TransactionsViewModel.ValueType {
        guard !value.zeroValue else {
            return .neutral
        }

        return condition ? trueType : (falseType ?? trueType)
    }

    private func singleValueSecondaryValue(value: AppValue, currencyValue: CurrencyValue?, nftMetadata: [NftUid: NftAssetBriefMetadata]) -> TransactionsViewModel.Value? {
        switch value.kind {
        case let .nft(nftUid, tokenName, _):
            let text = nftMetadata[nftUid]?.name ?? tokenName.map { "\($0) #\(nftUid.tokenId)" } ?? "#\(nftUid.tokenId)"
            return TransactionsViewModel.Value(text: text, type: .secondary)
        default:
            return currencyValue.map { TransactionsViewModel.Value(text: currencyString(from: $0), type: .secondary) }
        }
    }

    private func singleValueIconType(source: TransactionSource, kind: AppValue.Kind, nftMetadata: [NftUid: NftAssetBriefMetadata] = [:]) -> TransactionsViewModel.IconType {
        switch kind {
        case let .nft(nftUid, _, _):
            return .icon(
                url: nftMetadata[nftUid]?.previewImageUrl,
                alternativeUrl: nil,
                placeholderImageName: "placeholder_nft_32",
                type: .squircle
            )
        default:
            return .icon(
                url: kind.coin?.imageUrl,
                alternativeUrl: kind.coin?.image,
                placeholderImageName: source.blockchainType.placeholderImageName(tokenProtocol: kind.tokenProtocol),
                type: .circle
            )
        }
    }

    private func doubleValueIconType(source: TransactionSource, primaryValue: AppValue?, secondaryValue: AppValue?, nftMetadata: [NftUid: NftAssetBriefMetadata] = [:]) -> TransactionsViewModel.IconType {
        let frontType: IconView.IconType
        let frontUrl: String?
        var frontAlternativeUrl: String?
        let frontPlaceholder: String
        let backType: IconView.IconType
        let backUrl: String?
        var backAlternativeUrl: String?
        let backPlaceholder: String

        if let primaryValue {
            switch primaryValue.kind {
            case let .nft(nftUid, _, _):
                frontType = .squircle
                frontUrl = nftMetadata[nftUid]?.previewImageUrl
                frontPlaceholder = "placeholder_nft_32"
            default:
                frontType = .circle
                frontUrl = primaryValue.coin?.imageUrl
                frontAlternativeUrl = primaryValue.coin?.image
                frontPlaceholder = source.blockchainType.placeholderImageName(tokenProtocol: primaryValue.tokenProtocol)
            }
        } else {
            frontType = .circle
            frontUrl = nil
            frontPlaceholder = "placeholder_circle_32"
        }

        if let secondaryValue {
            switch secondaryValue.kind {
            case let .nft(nftUid, _, _):
                backType = .squircle
                backUrl = nftMetadata[nftUid]?.previewImageUrl
                backPlaceholder = "placeholder_nft_32"
            default:
                backType = .circle
                backUrl = secondaryValue.coin?.imageUrl
                backAlternativeUrl = secondaryValue.coin?.image
                backPlaceholder = source.blockchainType.placeholderImageName(tokenProtocol: secondaryValue.tokenProtocol)
            }
        } else {
            backType = .circle
            backUrl = nil
            backPlaceholder = "placeholder_circle_32"
        }

        return .doubleIcon(
            frontType: frontType,
            frontUrl: frontUrl,
            frontAlternativeUrl: frontAlternativeUrl,
            frontPlaceholder: frontPlaceholder,
            backType: backType,
            backUrl: backUrl,
            backAlternativeUrl: backAlternativeUrl,
            backPlaceholder: backPlaceholder
        )
    }

    private func iconType(source: TransactionSource, incomingValues: [AppValue], outgoingValues: [AppValue], nftMetadata: [NftUid: NftAssetBriefMetadata]) -> TransactionsViewModel.IconType {
        if incomingValues.count == 1, outgoingValues.isEmpty {
            return singleValueIconType(source: source, kind: incomingValues[0].kind, nftMetadata: nftMetadata)
        } else if incomingValues.isEmpty, outgoingValues.count == 1 {
            return singleValueIconType(source: source, kind: outgoingValues[0].kind, nftMetadata: nftMetadata)
        } else if incomingValues.count == 1, outgoingValues.count == 1 {
            return doubleValueIconType(source: source, primaryValue: incomingValues[0], secondaryValue: outgoingValues[0], nftMetadata: nftMetadata)
        } else {
            return .localIcon(imageName: source.blockchainType.iconPlain32)
        }
    }

    private func values(incomingValues: [AppValue], outgoingValues: [AppValue], currencyValue: CurrencyValue?, nftMetadata: [NftUid: NftAssetBriefMetadata]) -> (TransactionsViewModel.Value?, TransactionsViewModel.Value?) {
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
            let coinCodes = incomingValues.map(\.code).joined(separator: ", ")
            primaryValue = TransactionsViewModel.Value(text: coinCodes, type: .incoming)
            secondaryValue = TransactionsViewModel.Value(text: "transactions.multiple".localized, type: .secondary)
        } else if incomingValues.isEmpty, !outgoingValues.isEmpty {
            let coinCodes = outgoingValues.map(\.code).joined(separator: ", ")
            primaryValue = TransactionsViewModel.Value(text: coinCodes, type: .outgoing)
            secondaryValue = TransactionsViewModel.Value(text: "transactions.multiple".localized, type: .secondary)
        } else {
            if incomingValues.count == 1 {
                primaryValue = TransactionsViewModel.Value(text: coinString(from: incomingValues[0]), type: type(value: incomingValues[0], .incoming))
            } else {
                let incomingCoinCodes = incomingValues.map(\.code).joined(separator: ", ")
                primaryValue = TransactionsViewModel.Value(text: incomingCoinCodes, type: .incoming)
            }
            if outgoingValues.count == 1 {
                secondaryValue = TransactionsViewModel.Value(text: coinString(from: outgoingValues[0]), type: type(value: outgoingValues[0], .outgoing))
            } else {
                let outgoingCoinCodes = outgoingValues.map(\.code).joined(separator: ", ")
                secondaryValue = TransactionsViewModel.Value(text: outgoingCoinCodes, type: .outgoing)
            }
        }

        return (primaryValue, secondaryValue)
    }

    func viewItem(item: TransactionsViewModel.Item, balanceHidden: Bool) -> TransactionsViewModel.ViewItem {
        var iconType: TransactionsViewModel.IconType
        let title: String
        let subTitle: String
        var primaryValue: TransactionsViewModel.Value?
        var secondaryValue: TransactionsViewModel.Value?
        var doubleSpend = false
        var sentToSelf = false
        var locked: Bool?

        switch item.record {
        case let record as EvmIncomingTransactionRecord:
            iconType = singleValueIconType(source: record.source, kind: record.value.kind)
            title = "transactions.receive".localized
            subTitle = "transactions.from".localized(mapped(address: record.from, blockchainType: item.record.source.blockchainType))

            primaryValue = TransactionsViewModel.Value(text: coinString(from: record.value), type: type(value: record.value, .incoming))

            if let currencyValue = item.currencyValue {
                secondaryValue = TransactionsViewModel.Value(text: currencyString(from: currencyValue), type: .secondary)
            }

        case let record as EvmOutgoingTransactionRecord:
            iconType = singleValueIconType(source: record.source, kind: record.value.kind, nftMetadata: item.nftMetadata)
            title = "transactions.send".localized
            subTitle = "transactions.to".localized(mapped(address: record.to, blockchainType: item.record.source.blockchainType))

            primaryValue = TransactionsViewModel.Value(text: coinString(from: record.value, signType: record.sentToSelf ? .never : .always), type: type(value: record.value, condition: record.sentToSelf, .neutral, .outgoing))
            secondaryValue = singleValueSecondaryValue(value: record.value, currencyValue: item.currencyValue, nftMetadata: item.nftMetadata)

            sentToSelf = record.sentToSelf

        case let record as SwapTransactionRecord:
            iconType = doubleValueIconType(source: record.source, primaryValue: record.valueOut, secondaryValue: record.valueIn)
            title = "transactions.swap".localized
            subTitle = mapped(address: record.exchangeAddress, blockchainType: item.record.source.blockchainType)

            if let valueOut = record.valueOut {
                primaryValue = TransactionsViewModel.Value(text: coinString(from: valueOut), type: type(value: valueOut, condition: record.recipient != nil, .secondary, .incoming))
            }

            secondaryValue = TransactionsViewModel.Value(text: coinString(from: record.valueIn), type: type(value: record.valueIn, .outgoing))

        case let record as UnknownSwapTransactionRecord:
            iconType = doubleValueIconType(source: record.source, primaryValue: record.valueOut, secondaryValue: record.valueIn)
            title = "transactions.swap".localized
            subTitle = mapped(address: record.exchangeAddress, blockchainType: item.record.source.blockchainType)

            if let valueOut = record.valueOut {
                primaryValue = TransactionsViewModel.Value(text: coinString(from: valueOut), type: type(value: valueOut, .incoming))
            }
            if let valueIn = record.valueIn {
                secondaryValue = TransactionsViewModel.Value(text: coinString(from: valueIn), type: type(value: valueIn, .outgoing))
            }

        case let record as ApproveTransactionRecord:
            iconType = singleValueIconType(source: record.source, kind: record.value.kind)
            title = "transactions.approve".localized
            subTitle = mapped(address: record.spender, blockchainType: item.record.source.blockchainType)

            if record.value.isMaxValue {
                primaryValue = TransactionsViewModel.Value(text: "∞ \(record.value.code)", type: .neutral)
                secondaryValue = TransactionsViewModel.Value(text: "transactions.value.unlimited".localized, type: .secondary)
            } else {
                primaryValue = TransactionsViewModel.Value(text: coinString(from: record.value, signType: .never), type: .neutral)

                if let currencyValue = item.currencyValue {
                    secondaryValue = TransactionsViewModel.Value(text: currencyString(from: currencyValue), type: .secondary)
                }
            }

        case let record as ContractCallTransactionRecord:
            let (incomingValues, outgoingValues) = record.combinedValues

            iconType = self.iconType(source: record.source, incomingValues: incomingValues, outgoingValues: outgoingValues, nftMetadata: item.nftMetadata)
            title = record.method ?? "transactions.contract_call".localized
            subTitle = mapped(address: record.contractAddress, blockchainType: item.record.source.blockchainType)

            (primaryValue, secondaryValue) = values(incomingValues: incomingValues, outgoingValues: outgoingValues, currencyValue: item.currencyValue, nftMetadata: item.nftMetadata)

        case let record as ExternalContractCallTransactionRecord:
            let (incomingValues, outgoingValues) = record.combinedValues

            iconType = self.iconType(source: record.source, incomingValues: incomingValues, outgoingValues: outgoingValues, nftMetadata: item.nftMetadata)

            if record.outgoingEvents.isEmpty {
                title = "transactions.receive".localized
                let addresses = Array(Set(record.incomingEvents.map(\.address)))
                if addresses.count == 1 {
                    subTitle = "transactions.from".localized(mapped(address: addresses[0], blockchainType: item.record.source.blockchainType))
                } else {
                    subTitle = "transactions.multiple".localized
                }
            } else {
                title = "transactions.external_call".localized
                subTitle = "---"
            }

            (primaryValue, secondaryValue) = values(incomingValues: incomingValues, outgoingValues: outgoingValues, currencyValue: item.currencyValue, nftMetadata: item.nftMetadata)

        case let record as ContractCreationTransactionRecord:
            iconType = .localIcon(imageName: record.source.blockchainType.iconPlain32)
            title = "transactions.contract_creation".localized
            subTitle = "---"

        case let record as BitcoinIncomingTransactionRecord:
            iconType = singleValueIconType(source: record.source, kind: record.value.kind)
            title = "transactions.receive".localized
            subTitle = record.from.flatMap { "transactions.from".localized(mapped(address: $0, blockchainType: item.record.source.blockchainType)) } ?? "---"

            primaryValue = TransactionsViewModel.Value(text: coinString(from: record.value), type: type(value: record.value, .incoming))
            if let currencyValue = item.currencyValue {
                secondaryValue = TransactionsViewModel.Value(text: currencyString(from: currencyValue), type: .secondary)
            }

            doubleSpend = record.conflictingHash != nil
            if let lockState = item.transactionItem.lockState {
                locked = lockState.locked
            }

        case let record as BitcoinOutgoingTransactionRecord:
            iconType = singleValueIconType(source: record.source, kind: record.value.kind)
            title = "transactions.send".localized
            subTitle = record.to.flatMap { "transactions.to".localized(mapped(address: $0, blockchainType: item.record.source.blockchainType)) } ?? "---"

            primaryValue = TransactionsViewModel.Value(text: coinString(from: record.value, signType: record.sentToSelf ? .never : .always), type: type(value: record.value, condition: record.sentToSelf, .neutral, .outgoing))

            if let currencyValue = item.currencyValue {
                secondaryValue = TransactionsViewModel.Value(text: currencyString(from: currencyValue), type: .secondary)
            }

            doubleSpend = record.conflictingHash != nil
            sentToSelf = record.sentToSelf
            if let lockState = item.transactionItem.lockState {
                locked = lockState.locked
            }

        case let record as TronIncomingTransactionRecord:
            iconType = singleValueIconType(source: record.source, kind: record.value.kind)
            title = "transactions.receive".localized
            subTitle = "transactions.from".localized(mapped(address: record.from, blockchainType: item.record.source.blockchainType))

            primaryValue = TransactionsViewModel.Value(text: coinString(from: record.value), type: type(value: record.value, .incoming))

            if let currencyValue = item.currencyValue {
                secondaryValue = TransactionsViewModel.Value(text: currencyString(from: currencyValue), type: .secondary)
            }

        case let record as TronOutgoingTransactionRecord:
            iconType = singleValueIconType(source: record.source, kind: record.value.kind, nftMetadata: item.nftMetadata)
            title = "transactions.send".localized
            subTitle = "transactions.to".localized(mapped(address: record.to, blockchainType: item.record.source.blockchainType))

            primaryValue = TransactionsViewModel.Value(text: coinString(from: record.value, signType: record.sentToSelf ? .never : .always), type: type(value: record.value, condition: record.sentToSelf, .neutral, .outgoing))
            secondaryValue = singleValueSecondaryValue(value: record.value, currencyValue: item.currencyValue, nftMetadata: item.nftMetadata)

            sentToSelf = record.sentToSelf

        case let record as TronApproveTransactionRecord:
            iconType = singleValueIconType(source: record.source, kind: record.value.kind)
            title = "transactions.approve".localized
            subTitle = mapped(address: record.spender, blockchainType: item.record.source.blockchainType)

            if record.value.isMaxValue {
                primaryValue = TransactionsViewModel.Value(text: "∞ \(record.value.code)", type: .neutral)
                secondaryValue = TransactionsViewModel.Value(text: "transactions.value.unlimited".localized, type: .secondary)
            } else {
                primaryValue = TransactionsViewModel.Value(text: coinString(from: record.value, signType: .never), type: .neutral)

                if let currencyValue = item.currencyValue {
                    secondaryValue = TransactionsViewModel.Value(text: currencyString(from: currencyValue), type: .secondary)
                }
            }

        case let record as TronContractCallTransactionRecord:
            let (incomingValues, outgoingValues) = record.combinedValues

            iconType = self.iconType(source: record.source, incomingValues: incomingValues, outgoingValues: outgoingValues, nftMetadata: item.nftMetadata)
            title = record.method ?? "transactions.contract_call".localized
            subTitle = mapped(address: record.contractAddress, blockchainType: item.record.source.blockchainType)

            (primaryValue, secondaryValue) = values(incomingValues: incomingValues, outgoingValues: outgoingValues, currencyValue: item.currencyValue, nftMetadata: item.nftMetadata)

        case let record as TronExternalContractCallTransactionRecord:
            let (incomingValues, outgoingValues) = record.combinedValues

            iconType = self.iconType(source: record.source, incomingValues: incomingValues, outgoingValues: outgoingValues, nftMetadata: item.nftMetadata)

            if record.outgoingEvents.isEmpty {
                title = "transactions.receive".localized
                let addresses = Array(Set(record.incomingEvents.map(\.address)))
                if addresses.count == 1 {
                    subTitle = "transactions.from".localized(mapped(address: addresses[0], blockchainType: item.record.source.blockchainType))
                } else {
                    subTitle = "transactions.multiple".localized
                }
            } else {
                title = "transactions.external_call".localized
                subTitle = "---"
            }

            (primaryValue, secondaryValue) = values(incomingValues: incomingValues, outgoingValues: outgoingValues, currencyValue: item.currencyValue, nftMetadata: item.nftMetadata)

        case let record as TronTransactionRecord:
            iconType = .localIcon(imageName: item.record.source.blockchainType.iconPlain32)
            title = record.transaction.contract?.label ?? "transactions.unknown_transaction.title".localized
            subTitle = "transactions.unknown_transaction.description".localized()

        case let record as TonTransactionRecord:
            if record.actions.count == 1, let action = record.actions.first {
                switch action.type {
                case let .send(value, to, _sentToSelf, _):
                    iconType = singleValueIconType(source: record.source, kind: value.kind)
                    title = "transactions.send".localized
                    subTitle = "transactions.to".localized(mapped(address: to, blockchainType: item.record.source.blockchainType))
                    primaryValue = TransactionsViewModel.Value(text: coinString(from: value, signType: _sentToSelf ? .never : .always), type: type(value: value, condition: _sentToSelf, .neutral, .outgoing))

                    if let currencyValue = item.currencyValue {
                        secondaryValue = TransactionsViewModel.Value(text: currencyString(from: currencyValue), type: .secondary)
                    }

                    sentToSelf = _sentToSelf
                case let .receive(value, from, _):
                    iconType = singleValueIconType(source: record.source, kind: value.kind)
                    title = "transactions.receive".localized
                    subTitle = "transactions.from".localized(mapped(address: from, blockchainType: item.record.source.blockchainType))
                    primaryValue = TransactionsViewModel.Value(text: coinString(from: value), type: type(value: value, .incoming))

                    if let currencyValue = item.currencyValue {
                        secondaryValue = TransactionsViewModel.Value(text: currencyString(from: currencyValue), type: .secondary)
                    }
                case let .burn(value):
                    iconType = singleValueIconType(source: record.source, kind: value.kind)
                    title = "transactions.burn".localized
                    subTitle = value.name
                    primaryValue = TransactionsViewModel.Value(text: coinString(from: value), type: type(value: value, .outgoing))

                    if let currencyValue = item.currencyValue {
                        secondaryValue = TransactionsViewModel.Value(text: currencyString(from: currencyValue), type: .secondary)
                    }
                case let .mint(value):
                    iconType = singleValueIconType(source: record.source, kind: value.kind)
                    title = "transactions.mint".localized
                    subTitle = value.name
                    primaryValue = TransactionsViewModel.Value(text: coinString(from: value), type: type(value: value, .incoming))

                    if let currencyValue = item.currencyValue {
                        secondaryValue = TransactionsViewModel.Value(text: currencyString(from: currencyValue), type: .secondary)
                    }
                case let .swap(routerName, routerAddress, valueIn, valueOut):
                    iconType = doubleValueIconType(source: record.source, primaryValue: valueOut, secondaryValue: valueIn)
                    title = "transactions.swap".localized
                    subTitle = routerName ?? routerAddress.shortened
                    primaryValue = TransactionsViewModel.Value(text: coinString(from: valueOut), type: type(value: valueOut, .incoming))
                    secondaryValue = TransactionsViewModel.Value(text: coinString(from: valueIn), type: type(value: valueIn, .outgoing))
                case let .contractDeploy(interfaces):
                    iconType = .localIcon(imageName: item.record.source.blockchainType.iconPlain32)
                    title = "transactions.contract_deploy".localized
                    subTitle = interfaces.joined(separator: ", ")
                case let .contractCall(address, value, _):
                    iconType = .localIcon(imageName: item.record.source.blockchainType.iconPlain32)
                    title = "transactions.contract_call".localized
                    subTitle = address.shortened
                    primaryValue = TransactionsViewModel.Value(text: coinString(from: value), type: type(value: value, .outgoing))

                    if let currencyValue = item.currencyValue {
                        secondaryValue = TransactionsViewModel.Value(text: currencyString(from: currencyValue), type: .secondary)
                    }
                case let .unsupported(type):
                    iconType = .localIcon(imageName: item.record.source.blockchainType.iconPlain32)
                    title = "transactions.ton_transaction.title".localized
                    subTitle = type
                }
            } else {
                iconType = .localIcon(imageName: item.record.source.blockchainType.iconPlain32)
                title = "transactions.ton_transaction.title".localized
                subTitle = "transactions.multiple".localized
            }

        case let record as StellarTransactionRecord:
            switch record.type {
            case let .accountCreated(startingBalance, funder):
                iconType = singleValueIconType(source: record.source, kind: startingBalance.kind)
                title = "transactions.account_created".localized
                subTitle = "transactions.funder".localized(mapped(address: funder, blockchainType: item.record.source.blockchainType))
                primaryValue = TransactionsViewModel.Value(text: coinString(from: startingBalance), type: type(value: startingBalance, .incoming))

                if let currencyValue = item.currencyValue {
                    secondaryValue = TransactionsViewModel.Value(text: currencyString(from: currencyValue), type: .secondary)
                }
            case let .accountFunded(startingBalance, account):
                iconType = singleValueIconType(source: record.source, kind: startingBalance.kind)
                title = "transactions.account_created".localized
                subTitle = "transactions.account".localized(mapped(address: account, blockchainType: item.record.source.blockchainType))
                primaryValue = TransactionsViewModel.Value(text: coinString(from: startingBalance), type: type(value: startingBalance, .outgoing))

                if let currencyValue = item.currencyValue {
                    secondaryValue = TransactionsViewModel.Value(text: currencyString(from: currencyValue), type: .secondary)
                }
            case let .sendPayment(value, to, _sentToSelf):
                iconType = singleValueIconType(source: record.source, kind: value.kind)
                title = "transactions.send".localized
                subTitle = "transactions.to".localized(mapped(address: to, blockchainType: item.record.source.blockchainType))
                primaryValue = TransactionsViewModel.Value(text: coinString(from: value, signType: _sentToSelf ? .never : .always), type: type(value: value, condition: _sentToSelf, .neutral, .outgoing))

                if let currencyValue = item.currencyValue {
                    secondaryValue = TransactionsViewModel.Value(text: currencyString(from: currencyValue), type: .secondary)
                }

                sentToSelf = _sentToSelf
            case let .receivePayment(value, from):
                iconType = singleValueIconType(source: record.source, kind: value.kind)
                title = "transactions.receive".localized
                subTitle = "transactions.from".localized(mapped(address: from, blockchainType: item.record.source.blockchainType))
                primaryValue = TransactionsViewModel.Value(text: coinString(from: value), type: type(value: value, .incoming))

                if let currencyValue = item.currencyValue {
                    secondaryValue = TransactionsViewModel.Value(text: currencyString(from: currencyValue), type: .secondary)
                }
            case let .changeTrust(value, _, trustee, _):
                iconType = singleValueIconType(source: record.source, kind: value.kind)
                title = "Change Trust"
                subTitle = trustee.map { mapped(address: $0, blockchainType: item.record.source.blockchainType) } ?? ""

                if value.isMaxValue {
                    primaryValue = TransactionsViewModel.Value(text: "∞ \(value.code)", type: .neutral)
                    secondaryValue = TransactionsViewModel.Value(text: "transactions.value.unlimited".localized, type: .secondary)
                } else {
                    primaryValue = TransactionsViewModel.Value(text: coinString(from: value, signType: .never), type: .neutral)

                    if let currencyValue = item.currencyValue {
                        secondaryValue = TransactionsViewModel.Value(text: currencyString(from: currencyValue), type: .secondary)
                    }
                }
            case let .unsupported(type):
                iconType = .localIcon(imageName: item.record.source.blockchainType.iconPlain32)
                title = "transactions.stellar_transaction.title".localized
                subTitle = type
            }
        case let record as ZcashShieldingTransactionRecord:
            iconType = .localIcon(imageName: record.direction.txIconName)
            title = record.direction.txTitle
            subTitle = "transactions.transfer".localized

            primaryValue = TransactionsViewModel.Value(text: coinString(from: record.value, signType: .never), type: .neutral)

            if let currencyValue = item.currencyValue {
                secondaryValue = TransactionsViewModel.Value(text: currencyString(from: currencyValue), type: .secondary)
            }

            doubleSpend = record.conflictingHash != nil
            sentToSelf = true

            if let lockState = item.transactionItem.lockState {
                locked = lockState.locked
            }
        default:
            iconType = .localIcon(imageName: item.record.source.blockchainType.iconPlain32)
            title = "transactions.unknown_transaction.title".localized
            subTitle = "transactions.unknown_transaction.description".localized()
        }

        let progress: Float?

        switch item.transactionItem.status {
        case .pending:
            progress = 0.2

        case let .processing(p):
            progress = Float(p) * 0.8 + 0.2

        case .failed:
            progress = nil
            iconType = .failedIcon

        case .completed:
            progress = nil
        }

        if balanceHidden {
            primaryValue = TransactionsViewModel.Value(text: BalanceHiddenManager.placeholder, type: primaryValue?.type ?? .neutral)
            secondaryValue = TransactionsViewModel.Value(text: BalanceHiddenManager.placeholder, type: secondaryValue?.type ?? .neutral)
        }

        return TransactionsViewModel.ViewItem(
            id: item.record.uid,
            date: item.record.date,
            iconType: iconType,
            progress: progress,
            title: title,
            subTitle: subTitle,
            primaryValue: primaryValue,
            secondaryValue: secondaryValue,
            doubleSpend: doubleSpend,
            sentToSelf: sentToSelf,
            locked: locked,
            spam: item.record.spam
        )
    }
}
