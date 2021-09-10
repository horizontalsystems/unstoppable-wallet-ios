import UIKit
import CurrencyKit

struct TransactionInfoModule {

    static func instance(transactionItem: TransactionItem) -> UIViewController? {
        guard let adapter = App.shared.transactionAdapterManager.adapter(for: transactionItem.record.source) else {
            return nil
        }

        let service = TransactionInfoService(adapter: adapter, rateManager: App.shared.rateManagerNew, currencyKit: App.shared.currencyKit, transactionItem: transactionItem, feeCoinProvider: App.shared.feeCoinProvider, appConfigProvider: App.shared.appConfigProvider)
        let factory = TransactionInfoViewItemFactory(accountSettingManager: App.shared.accountSettingManager)
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
        case actionTitle(title: String, subTitle: String?)
        case amount(coinAmount: String, currencyAmount: String?, incoming: Bool?)
        case status(status: TransactionStatus)
        case options(actions: [OptionViewItem])
        case date(date: Date)
        case from(value: String)
        case to(value: String)
        case recipient(value: String)
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

}
