import Combine
import Foundation
import HsExtensions
import MarketKit
import RxSwift

class MarketGlobalViewModel: ObservableObject {
    private let marketKit = App.shared.marketKit
    private let currencyManager = App.shared.currencyManager
    private let appManager = App.shared.appManager

    private var cancellables = Set<AnyCancellable>()
    private var globalMarketDataTask: AnyTask?
    private let disposeBag = DisposeBag()

    @Published var globalMarketData: GlobalMarketData?

    init() {
        currencyManager.$baseCurrency
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.globalMarketData = nil
                self?.syncState()
            }
            .store(in: &cancellables)

        subscribe(disposeBag, appManager.willEnterForegroundObservable) { [weak self] in self?.syncState() }

        syncState()
    }

    private func syncState() {
        globalMarketDataTask = Task { [weak self, marketKit, currencyManager] in
            let marketOverview = try await marketKit.marketOverview(currencyCode: currencyManager.baseCurrency.code)

            await MainActor.run { [weak self] in
                self?.handle(marketOverview: marketOverview)
            }
        }
        .erased()
    }

    private func handle(marketOverview: MarketOverview) {
        let marketCapPoints = marketOverview.globalMarketPoints.map(\.marketCap)
        let volumePoints = marketOverview.globalMarketPoints.map(\.volume24h)
        let defiCapPoints = marketOverview.globalMarketPoints.map(\.defiMarketCap)
        let tvlInDefiPoints = marketOverview.globalMarketPoints.map(\.tvl)

        globalMarketData = GlobalMarketData(
            marketCap: globalMarketItem(points: marketCapPoints),
            volume: globalMarketItem(points: volumePoints),
            defiCap: globalMarketItem(points: defiCapPoints),
            tvlInDefi: globalMarketItem(points: tvlInDefiPoints)
        )
    }

    private func globalMarketItem(points: [Decimal]) -> GlobalMarketItem? {
        GlobalMarketItem(
            amount: points.last.flatMap { ValueFormatter.instance.formatShort(currency: currencyManager.baseCurrency, value: $0) },
            diff: diff(points: points)
        )
    }

    private func diff(points: [Decimal]) -> Decimal? {
        guard let first = points.first, let last = points.last, first != 0 else {
            return nil
        }

        return (last - first) * 100 / first
    }
}

extension MarketGlobalViewModel {
    struct GlobalMarketData {
        let marketCap: GlobalMarketItem?
        let volume: GlobalMarketItem?
        let defiCap: GlobalMarketItem?
        let tvlInDefi: GlobalMarketItem?
    }

    struct GlobalMarketItem {
        let amount: String?
        let diff: Decimal?
    }
}
