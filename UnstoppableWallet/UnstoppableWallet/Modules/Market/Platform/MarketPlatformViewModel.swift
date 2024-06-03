import Combine
import Foundation
import HsExtensions
import MarketKit

class MarketPlatformViewModel: ObservableObject {
    private let marketKit = App.shared.marketKit
    private let currencyManager = App.shared.currencyManager

    let platform: TopPlatform

    private var cancellables = Set<AnyCancellable>()
    private var tasks = Set<AnyTask>()

    private var internalState: State = .loading {
        didSet {
            syncState()
        }
    }

    @Published var state: State = .loading

    var sortBy: MarketModule.SortBy = .highestCap {
        didSet {
            stat(page: .topPlatform, event: .switchSortType(sortType: sortBy.statSortType))
            syncState()
        }
    }

    init(platform: TopPlatform) {
        self.platform = platform
        currencyManager.$baseCurrency
            .sink { [weak self] _ in
                self?.sync()
            }
            .store(in: &cancellables)

        sync()
    }

    private func syncState() {
        switch internalState {
        case .loading:
            state = .loading
        case let .loaded(marketInfos):
            state = .loaded(marketInfos: marketInfos.sorted(sortBy: sortBy, timePeriod: .day1))
        case let .failed(error):
            state = .failed(error: error)
        }
    }
}

extension MarketPlatformViewModel {
    var currency: Currency {
        currencyManager.baseCurrency
    }

    var sortBys: [MarketModule.SortBy] {
        [.highestCap, .lowestCap, .gainers, .losers]
    }

    func sync() {
        tasks = Set()

        if case .failed = internalState {
            internalState = .loading
        }

        let platform = platform

        Task { [weak self, marketKit, currency] in
            do {
                let marketInfos = try await marketKit.topPlatformMarketInfos(blockchain: platform.blockchain.uid, currencyCode: currency.code)

                await MainActor.run { [weak self] in
                    self?.internalState = .loaded(marketInfos: marketInfos)
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.internalState = .failed(error: error)
                }
            }
        }
        .store(in: &tasks)
    }
}

extension MarketPlatformViewModel {
    enum State {
        case loading
        case loaded(marketInfos: [MarketInfo])
        case failed(error: Error)
    }
}
