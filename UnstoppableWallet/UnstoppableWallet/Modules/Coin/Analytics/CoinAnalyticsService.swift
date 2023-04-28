import MarketKit
import CurrencyKit
import HsToolKit
import HsExtensions

class CoinAnalyticsService {
    private let fullCoin: FullCoin
    private let marketKit: MarketKit.Kit
    private let currencyKit: CurrencyKit.Kit
    private var tasks = Set<AnyTask>()

    @PostPublished private(set) var state: State = .loading

    init(fullCoin: FullCoin, marketKit: MarketKit.Kit, currencyKit: CurrencyKit.Kit) {
        self.fullCoin = fullCoin
        self.marketKit = marketKit
        self.currencyKit = currencyKit
    }

}

extension CoinAnalyticsService {

    var currency: Currency {
        currencyKit.baseCurrency
    }

    var coin: Coin {
        fullCoin.coin
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

        Task { [weak self, marketKit, fullCoin, currency] in
            do {
                let analytics = try await marketKit.analytics(coinUid: fullCoin.coin.uid, currencyCode: currency.code)
                self?.state = .success(analytics)
            } catch {
                if let responseError = error as? NetworkManager.ResponseError, responseError.statusCode == 401 {
                    do {
                        let analyticsPreview = try await marketKit.analyticsPreview(coinUid: fullCoin.coin.uid)
                        self?.state = .preview(analyticsPreview)
                    } catch {
                        self?.state = .failed(error)
                    }
                } else {
                    self?.state = .failed(error)
                }
            }
        }.store(in: &tasks)
    }

}

extension CoinAnalyticsService {

    enum State {
        case loading
        case failed(Error)
        case preview(AnalyticsPreview)
        case success(Analytics)
    }

}
