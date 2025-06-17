import Combine

import Foundation
import HsExtensions
import MarketKit
import RxSwift

class CoinOverviewViewModel: ObservableObject {
    private let coinUid: String
    private let marketKit = App.shared.marketKit
    private let currencyManager = App.shared.currencyManager
    private let languageManager = LanguageManager.shared
    private let walletManager = App.shared.walletManager
    private let performanceDataManager = App.shared.performanceDataManager

    private var tasks = Set<AnyTask>()
    private var cancellables: [AnyCancellable] = []
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

        performanceDataManager
            .updatedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.load()
            }
            .store(in: &cancellables)
    }
}

extension CoinOverviewViewModel {
    var currency: Currency {
        currencyManager.baseCurrency
    }

    var performanceCoins: [PerformanceCoin] {
        performanceDataManager.coins
    }

    var performancePeriods: [HsTimePeriod] {
        performanceDataManager.periods
    }

    func load() {
        tasks = Set()

        state = .loading

        let uids = performanceCoins.map(\.uid)
        let periods = performancePeriods

        Task { [weak self, marketKit, coinUid, currencyManager, languageManager] in
            do {
                let overview = try await marketKit.marketInfoOverview(coinUid: coinUid, roiUids: uids, roiPeriods: periods, currencyCode: currencyManager.baseCurrency.code, languageCode: languageManager.currentLanguage)

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

extension CoinOverviewViewModel {
    enum State {
        case loading
        case loaded(overview: MarketInfoOverview)
        case failed
    }
}

extension PerformanceRow {
    static let gold = PerformanceCoin(uid: "tether-gold", code: "Gold")
    static let sp500 = PerformanceCoin(uid: "snp", code: "SP500")
    static let defaultCoins = [PerformanceCoin(uid: "bitcoin", code: "BTC"), PerformanceCoin(uid: "tether", code: "USDT"), Self.sp500]
    static let defaultPeriods: [HsTimePeriod] = [.month6, .year1]
}
