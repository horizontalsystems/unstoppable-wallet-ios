import UIKit
import CurrencyKit
import MarketKit

struct TransactionInfoModule {

    static func instance(transactionRecord: TransactionRecord) -> UIViewController? {
        guard let adapter = App.shared.transactionAdapterManager.adapter(for: transactionRecord.source) else {
            return nil
        }

        let service = TransactionInfoService(transactionRecord: transactionRecord, adapter: adapter, marketKit: App.shared.marketKit, currencyKit: App.shared.currencyKit)
        let factory = TransactionInfoViewItemFactory(evmLabelManager: App.shared.evmLabelManager)
        let viewModel = TransactionInfoViewModel(service: service, factory: factory)
        let viewController = TransactionInfoViewController(adapter: adapter, viewModel: viewModel, pageTitle: "tx_info.title".localized, urlManager: UrlManager(inApp: true))

        return viewController
    }

}

extension TransactionInfoModule {

    enum Option {
        case speedUp
        case cancel

        var confirmTitle: String {
            switch self {
            case .speedUp: return "tx_info.options.speed_up"
            case .cancel: return "tx_info.options.cancel"
            }
        }

        var confirmButtonTitle: String {
            switch self {
            case .speedUp: return "send.confirmation.resend_button"
            case .cancel: return "send.confirmation.cancel_button"
            }
        }

        var description: String {
            switch self {
            case .speedUp: return "send.confirmation.resend_description"
            case .cancel: return "send.confirmation.cancel_description"
            }
        }
    }

    struct OptionViewItem {
        let title: String
        let active: Bool
        let option: Option
    }

    enum ViewItem {
        case actionTitle(iconName: String?, iconDimmed: Bool, title: String, subTitle: String?)
        case amount(iconUrl: String?, iconPlaceholderImageName: String, coinAmount: String, currencyAmount: String?, type: AmountType)
        case status(status: TransactionStatus)
        case options(actions: [OptionViewItem])
        case date(date: Date)
        case from(value: String, valueTitle: String?)
        case to(value: String, valueTitle: String?)
        case spender(value: String, valueTitle: String?)
        case recipient(value: String, valueTitle: String?)
        case id(value: String)
        case rate(value: String)
        case fee(title: String, value: String)
        case price(price: String)
        case doubleSpend(txHash: String, conflictingTxHash: String)
        case lockInfo(lockState: TransactionLockState)
        case sentToSelf
        case rawTransaction
        case memo(text: String)
        case service(value: String)
        case explorer(title: String, url: String?)
    }

    enum AmountType {
        case incoming
        case outgoing
        case neutral

        var showSign: Bool {
            switch self {
            case .incoming, .outgoing: return true
            case .neutral: return false
            }
        }
    }

}

struct TransactionInfoItem {
    let record: TransactionRecord
    var lastBlockInfo: LastBlockInfo?
    var rates: [Coin: CurrencyValue]
    let explorerTitle: String
    let explorerUrl: String?
}
