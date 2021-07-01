import UIKit
import CurrencyKit

struct TransactionInfoModule {

    static func instance(transaction: TransactionRecord, wallet: Wallet) -> UIViewController? {
        guard let adapter = App.shared.adapterManager.transactionsAdapter(for: wallet) else {
            return nil
        }

        let service = TransactionInfoService(adapter: adapter, rateManager: App.shared.rateManager, currencyKit: App.shared.currencyKit, feeCoinProvider: App.shared.feeCoinProvider, pasteboardManager: App.shared.pasteboardManager, appConfigProvider: App.shared.appConfigProvider, accountSettingManager: App.shared.accountSettingManager)
        let factory = TransactionInfoViewItemFactory()
        let viewModel = TransactionInfoViewModel(service: service, factory: factory, transaction: transaction, wallet: wallet)
        let viewController = TransactionInfoViewController(viewModel: viewModel, pageTitle: "tx_info.title".localized)

        return viewController
    }

}

extension TransactionInfoModule {

    enum ViewItem {
        case actionTitle(title: String, subTitle: String?)
        case amount(coinValue: CoinValue, currencyValue: CurrencyValue?, incoming: Bool?)
        case status(status: TransactionStatus, completed: String, pending: String)
        case date(date: Date)
        case from(value: String)
        case to(value: String)
        case recipient(value: String)
        case id(value: String)
        case rate(currencyValue: CurrencyValue, coinCode: String)
        case fee(coinValue: CoinValue, currencyValue: CurrencyValue?)
        case price(coinValue1: CoinValue, coinValue2: CoinValue)
        case doubleSpend
        case lockInfo(lockState: TransactionLockState)
        case sentToSelf
        case rawTransaction
        case memo(text: String)
        case explorer(title: String, url: String?)
    }

}
