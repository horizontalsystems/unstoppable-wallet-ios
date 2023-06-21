import Combine
import EvmKit
import MarketKit
import CurrencyKit
import HsToolKit
import HsExtensions

class CoinAnalyticsService {
    private let fullCoin: FullCoin
    private let marketKit: MarketKit.Kit
    private let currencyKit: CurrencyKit.Kit
    private let subscriptionManager: SubscriptionManager
    private let accountManager: AccountManager
    private let appConfigProvider: AppConfigProvider
    private var tasks = Set<AnyTask>()
    private var cancellables = Set<AnyCancellable>()

    @PostPublished private(set) var state: State = .loading

    init(fullCoin: FullCoin, marketKit: MarketKit.Kit, currencyKit: CurrencyKit.Kit, subscriptionManager: SubscriptionManager, accountManager: AccountManager, appConfigProvider: AppConfigProvider) {
        self.fullCoin = fullCoin
        self.marketKit = marketKit
        self.currencyKit = currencyKit
        self.subscriptionManager = subscriptionManager
        self.accountManager = accountManager
        self.appConfigProvider = appConfigProvider

        subscriptionManager.$authToken
                .sink { [weak self] token in
                    if token != nil {
                        self?.sync()
                    }
                }
                .store(in: &cancellables)
    }

    private func resolveAddresses() -> [String] {
        accountManager.accounts
                .compactMap { $0.type.evmAddress(chain: App.shared.evmBlockchainManager.chain(blockchainType: .ethereum)) }
                .map { $0.hex }
    }

    private func loadPreview() {
        let addresses = resolveAddresses()

        Task { [weak self, marketKit, fullCoin] in
            do {
                let analyticsPreview = try await marketKit.analyticsPreview(coinUid: fullCoin.coin.uid, addresses: addresses)
                let subscriptionAddress = analyticsPreview.subscriptions.sorted { lhs, rhs in lhs.deadline > rhs.deadline }.first?.address
                self?.state = .preview(analyticsPreview: analyticsPreview, subscriptionAddress: subscriptionAddress)
            } catch {
                self?.state = .failed(error)
            }
        }.store(in: &tasks)
    }

}

extension CoinAnalyticsService {

    var currency: Currency {
        currencyKit.baseCurrency
    }

    var coin: Coin {
        fullCoin.coin
    }

    var analyticsLink: String {
        appConfigProvider.analyticsLink
    }

    var auditAddresses: [String]? {
        let addresses = fullCoin.tokens.compactMap { token in
            switch (token.blockchainType, token.type) {
            case (.ethereum, .eip20(let address)): return address
            case (.binanceSmartChain, .eip20(let address)): return address
            default: return nil
            }
        }

        return addresses.isEmpty ? nil : addresses
    }

    func blockchains(uids: [String]) -> [Blockchain] {
        do {
            return try marketKit.blockchains(uids: uids)
        } catch {
            return []
        }
    }

    func sync() {
        tasks = Set()

        state = .loading

        if subscriptionManager.authToken != nil {
            Task { [weak self, marketKit, fullCoin, currency] in
                do {
                    let analytics = try await marketKit.analytics(coinUid: fullCoin.coin.uid, currencyCode: currency.code)
                    self?.state = .success(analytics: analytics)
                } catch {
                    if let responseError = error as? NetworkManager.ResponseError, (responseError.statusCode == 401 || responseError.statusCode == 403) {
                        self?.subscriptionManager.invalidateAuthToken()
                        self?.loadPreview()
                    } else {
                        self?.state = .failed(error)
                    }
                }
            }.store(in: &tasks)
        } else {
            loadPreview()
        }
    }

}

extension CoinAnalyticsService {

    enum State {
        case loading
        case failed(Error)
        case preview(analyticsPreview: AnalyticsPreview, subscriptionAddress: String?)
        case success(analytics: Analytics)
    }

}
