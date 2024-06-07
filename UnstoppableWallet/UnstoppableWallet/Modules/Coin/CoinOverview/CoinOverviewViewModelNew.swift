import Combine
import ComponentKit
import Foundation
import HsExtensions
import MarketKit
import RxSwift

class CoinOverviewViewModelNew: ObservableObject {
    private let coinUid: String
    private let marketKit = App.shared.marketKit
    private let currencyManager = App.shared.currencyManager
    private let languageManager = LanguageManager.shared
    private let walletManager = App.shared.walletManager
    private var tasks = Set<AnyTask>()
    private var disposeBag = DisposeBag()

    @Published private(set) var state: State = .loading
    @Published private(set) var walletData: WalletManager.WalletData

    init(coinUid: String) {
        self.coinUid = coinUid

        walletData = walletManager.activeWalletData

        walletManager.activeWalletDataUpdatedObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in self?.walletData = $0 })
            .disposed(by: disposeBag)
    }
}

extension CoinOverviewViewModelNew {
    var currency: Currency {
        currencyManager.baseCurrency
    }

    func load() {
        tasks = Set()

        state = .loading

        Task { [weak self, marketKit, coinUid, currencyManager, languageManager] in
            do {
                let overview = try await marketKit.marketInfoOverview(coinUid: coinUid, currencyCode: currencyManager.baseCurrency.code, languageCode: languageManager.currentLanguage)

                await MainActor.run { [weak self] in
                    self?.state = .loaded(overview: overview)
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.state = .failed
                }
            }
        }
        .store(in: &tasks)
    }

    func addToWallet(token: Token) {
        guard let account = walletData.account else {
            return
        }

        let wallet = Wallet(token: token, account: account)
        walletManager.save(wallets: [wallet])

        HudHelper.instance.show(banner: .addedToWallet)

        stat(page: .coinOverview, event: .addToWallet)
    }

    func removeFromWallet(token: Token) {
        guard let account = walletData.account else {
            return
        }

        let wallet = Wallet(token: token, account: account)
        walletManager.delete(wallets: [wallet])

        HudHelper.instance.show(banner: .removedFromWallet)

        stat(page: .coinOverview, event: .removeFromWallet)
    }
}

extension CoinOverviewViewModelNew {
    enum State {
        case loading
        case loaded(overview: MarketInfoOverview)
        case failed
    }
}
