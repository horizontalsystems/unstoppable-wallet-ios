import Foundation
import RxSwift

protocol IWalletView: class {
    func show(totalBalance: CurrencyValue)
    func show(walletBalances: [WalletBalanceViewItem])
    func show(syncStatus: String)
    func didRefresh()
}

protocol IWalletViewDelegate {
    func viewDidLoad()
    func refresh()
    func onReceive(for adapterId: String)
    func onPay(for adapterId: String)
}

protocol IWalletInteractor {
    func notifyWalletBalances()
}

protocol IWalletInteractorDelegate: class {
    func didInitialFetch(coinValues: [String: CoinValue], rates: [String: Double], progressSubjects: [String: BehaviorSubject<Double>], currency: Currency)
    func didUpdate(coinValue: CoinValue, adapterId: String)
    func didUpdate(rates: [String: Double])
}

protocol IWalletRouter {
    func onReceive(forAdapterId adapterId: String)
    func onSend(forAdapterId adapterId: String)
}
