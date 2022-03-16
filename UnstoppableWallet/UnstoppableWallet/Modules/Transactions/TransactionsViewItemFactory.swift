import UIKit
import CurrencyKit
import MarketKit

class TransactionsViewItemFactory {

    func typeFilterItems(types: [TransactionTypeFilter]) -> [FilterHeaderView.ViewItem] {
        types.map {
            if $0 == .all {
                return .all
            } else {
                return .item(title: "transactions.types.\($0.rawValue)".localized)
            }
        }
    }

    private func coinString(from transactionValue: TransactionValue) -> String {
        ValueFormatter.instance.format(transactionValue: transactionValue.abs, fractionPolicy: .threshold(high: 0.01, low: 0)) ?? ""
    }

    private func currencyString(from currencyValue: CurrencyValue) -> String {
        ValueFormatter.instance.format(currencyValue: currencyValue.abs, fractionPolicy: .threshold(high: 1000, low: 0.01)) ?? ""
    }

    func viewItem(item: TransactionItem) -> TransactionViewItem {
        var typeImage: ColoredImage
        var progress: Float?
        var title: String
        var subTitle: String
        var primaryValue: ColoredValue? = nil
        var secondaryValue: ColoredValue? = nil
        var sentToSelf: Bool = false
        var locked: Bool? = nil

        switch item.record {
        case let evmIncoming as EvmIncomingTransactionRecord:
            typeImage = ColoredImage(imageName: "arrow_medium_main_down_left_20", color: .themeRemus)
            title = "transactions.receive".localized
            subTitle = "transactions.from".localized(TransactionInfoAddressMapper.map(evmIncoming.from))

            if let currencyValue = item.currencyValue {
                primaryValue = ColoredValue(value: currencyString(from: currencyValue), color: .themeRemus)
            }

            secondaryValue = ColoredValue(value: coinString(from: evmIncoming.value), color: .themeGray)

        case let evmOutgoing as EvmOutgoingTransactionRecord:
            typeImage = ColoredImage(imageName: "arrow_medium_main_up_right_20", color: .themeJacob)
            title = "transactions.send".localized
            subTitle = "transactions.to".localized(TransactionInfoAddressMapper.map(evmOutgoing.to))

            if let currencyValue = item.currencyValue {
                primaryValue = ColoredValue(value: currencyString(from: currencyValue), color: .themeJacob)
            }

            secondaryValue = ColoredValue(value: coinString(from: evmOutgoing.value), color: .themeGray)
            sentToSelf = evmOutgoing.sentToSelf

        case let swap as SwapTransactionRecord:
            typeImage = ColoredImage(imageName: "swap_2_20", color: .themeLeah)
            title = "transactions.swap".localized
            subTitle = TransactionInfoAddressMapper.map(swap.exchangeAddress)

            primaryValue = ColoredValue(value: coinString(from: swap.valueIn), color: .themeJacob)
            secondaryValue = swap.valueOut.flatMap { ColoredValue(value: coinString(from: $0), color: swap.foreignRecipient ? .themeGray : .themeRemus) }

        case let swap as UnknownSwapTransactionRecord:
            typeImage = ColoredImage(imageName: "swap_2_20", color: .themeLeah)
            title = "transactions.swap".localized
            subTitle = TransactionInfoAddressMapper.map(swap.exchangeAddress)

            primaryValue = nil
            secondaryValue = nil

        case let approve as ApproveTransactionRecord:
            typeImage = ColoredImage(imageName: "check_2_20", color: .themeLeah)
            title = "transactions.approve".localized
            subTitle = "transactions.from".localized(TransactionInfoAddressMapper.map(approve.spender))

            if approve.value.isMaxValue {
                primaryValue = ColoredValue(value: "∞", color: .themeJacob)
                secondaryValue = ColoredValue(value: "transactions.value.unlimited".localized(approve.value.coinCode), color: .themeGray)
            } else {
                if let currencyValue = item.currencyValue {
                    primaryValue = ColoredValue(value: currencyString(from: currencyValue), color: .themeJacob)
                }
                secondaryValue = ColoredValue(value: coinString(from: approve.value), color: .themeGray)
            }

        case let contractCall as ContractCallTransactionRecord:
            typeImage = ColoredImage(imageName: "unordered_20", color: .themeLeah)
            title = contractCall.method ?? "\(contractCall.source.blockchain.title) \("transactions.contract_call".localized)"
            subTitle = TransactionInfoAddressMapper.map(contractCall.contractAddress)

        case is ContractCreationTransactionRecord:
            typeImage = ColoredImage(imageName: "unordered_20", color: .themeLeah)
            title = "transactions.contract_creation".localized
            subTitle = "---"

        case let btcIncoming as BitcoinIncomingTransactionRecord:
            typeImage = ColoredImage(imageName: "arrow_medium_main_down_left_20", color: .themeRemus)
            title = "transactions.receive".localized
            subTitle = btcIncoming.from.flatMap { "transactions.from".localized(TransactionInfoAddressMapper.map($0)) } ?? "---"

            if let currencyValue = item.currencyValue {
                primaryValue = ColoredValue(value: currencyString(from: currencyValue), color: .themeRemus)
            }

            secondaryValue = ColoredValue(value: coinString(from: btcIncoming.value), color: .themeGray)

            if let lockState = btcIncoming.lockState(lastBlockTimestamp: item.lastBlockInfo?.timestamp) {
                locked = lockState.locked
            }

        case let btcOutgoing as BitcoinOutgoingTransactionRecord:
            typeImage = ColoredImage(imageName: "arrow_medium_main_up_right_20", color: .themeJacob)
            title = "transactions.send".localized
            subTitle =  btcOutgoing.to.flatMap { "transactions.to".localized(TransactionInfoAddressMapper.map($0)) } ?? "---"

            if let currencyValue = item.currencyValue {
                primaryValue = ColoredValue(value: currencyString(from: currencyValue), color: .themeJacob)
            }

            secondaryValue = ColoredValue(value: coinString(from: btcOutgoing.value), color: .themeGray)

            sentToSelf = btcOutgoing.sentToSelf
            if let lockState = btcOutgoing.lockState(lastBlockTimestamp: item.lastBlockInfo?.timestamp) {
                locked = lockState.locked
            }

        case let bcIncoming as BinanceChainIncomingTransactionRecord:
            typeImage = ColoredImage(imageName: "arrow_medium_main_down_left_20", color: .themeRemus)
            title = "transactions.receive".localized
            subTitle = "transactions.from".localized(TransactionInfoAddressMapper.map(bcIncoming.from))

            if let currencyValue = item.currencyValue {
                primaryValue = ColoredValue(value: currencyString(from: currencyValue), color: .themeRemus)
            }

            secondaryValue = ColoredValue(value: coinString(from: bcIncoming.value), color: .themeGray)

        case let bcOutgoing as BinanceChainOutgoingTransactionRecord:
            typeImage = ColoredImage(imageName: "arrow_medium_main_up_right_20", color: .themeJacob)
            title = "transactions.send".localized
            subTitle = "transactions.to".localized(TransactionInfoAddressMapper.map(bcOutgoing.to))

            if let currencyValue = item.currencyValue {
                primaryValue = ColoredValue(value: currencyString(from: currencyValue), color: .themeJacob)
            }

            secondaryValue = ColoredValue(value: coinString(from: bcOutgoing.value), color: .themeGray)
            sentToSelf = bcOutgoing.sentToSelf

        default:
            typeImage = ColoredImage(imageName: "unordered_20", color: .themeLeah)
            title = "transactions.unknown_transaction.title".localized
            subTitle = "transactions.unknown_transaction.description".localized()
        }

        switch item.record.status(lastBlockHeight: item.lastBlockInfo?.height) {
        case .pending:
            progress = 0.2

        case .processing(let p):
            progress = Float(p) * 0.8 + 0.2

        case .failed:
            progress = nil
            typeImage = ColoredImage(imageName: "warning_2_20", color: .themeLucian)

        case .completed:
            progress = nil
        }

        return TransactionViewItem(
                uid: item.record.uid,
                date: item.record.date,
                typeImage: typeImage,
                progress: progress,
                title: title,
                subTitle: subTitle,
                primaryValue: primaryValue,
                secondaryValue: secondaryValue,
                sentToSelf: sentToSelf,
                locked: locked
        )
    }

    func coinFilter(wallet: TransactionWallet) -> MarketDiscoveryFilterHeaderView.ViewItem? {
        guard let platformCoin = wallet.coin else {
            return nil
        }

        return MarketDiscoveryFilterHeaderView.ViewItem(iconUrl: platformCoin.coin.imageUrl, iconPlaceholder: platformCoin.coinType.placeholderImageName, title: platformCoin.coin.code, blockchainBadge: wallet.badge)
    }

}
