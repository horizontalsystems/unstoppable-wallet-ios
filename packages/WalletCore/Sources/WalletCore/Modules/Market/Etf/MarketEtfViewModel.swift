import Combine
import Foundation
import HsExtensions
import MarketKit

class MarketEtfViewModel: ObservableObject {
    private let marketKit = Core.shared.marketKit
    private let currencyManager = Core.shared.currencyManager

    private var cancellables = Set<AnyCancellable>()
    private var tasks = Set<AnyTask>()

    let category: MarketEtfFetcher.EtfCategory

    private var internalState: State = .loading {
        didSet {
            syncState()
        }
    }

    @Published var state: State = .loading

    var sortBy: SortBy = .highestAssets {
        didSet {
            stat(page: .globalMetricsEtf, event: .switchSortType(sortType: sortBy.statSortBy))
            syncState()
        }
    }

    var timePeriod: TimePeriod = .period(timePeriod: .day1) {
        didSet {
            stat(page: .globalMetricsEtf, event: .switchPeriod(period: timePeriod.statPeriod))
            syncState()
        }
    }

    init(category: MarketEtfFetcher.EtfCategory) {
        self.category = category

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
        case let .loaded(rankedEtfs):
            state = .loaded(rankedEtfs: rankedEtfs.sorted(sortBy: sortBy, timePeriod: timePeriod))
        case let .failed(error):
            state = .failed(error: error)
        }
    }
}

extension MarketEtfViewModel {
    var currency: Currency {
        currencyManager.baseCurrency
    }

    var timePeriods: [TimePeriod] {
        [.period(timePeriod: .day1), .period(timePeriod: .week1), .period(timePeriod: .month1), .period(timePeriod: .month3), .all]
    }

    func sync() {
        tasks = Set()

        if case .failed = internalState {
            internalState = .loading
        }

        let category = category

        Task { [weak self, marketKit, currency] in
            do {
                let etfs = try await marketKit.etfs(category: category.rawValue, currencyCode: currency.code)
                let sortedEtfs = etfs.sorted { $0.totalAssets ?? 0 > $1.totalAssets ?? 0 }
                let rankedEtfs = sortedEtfs.enumerated().map { RankedEtf(etf: $1, rank: $0 + 1) }

                await MainActor.run { [weak self] in
                    self?.internalState = .loaded(rankedEtfs: rankedEtfs)
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

extension MarketEtfViewModel {
    enum State {
        case loading
        case loaded(rankedEtfs: [RankedEtf])
        case failed(error: Error)
    }

    enum SortBy: String, CaseIterable {
        case highestAssets = "highest_assets"
        case lowestAssets = "lowest_assets"
        case inflow
        case outflow

        var title: String {
            "market.etf.sort_by.\(rawValue)".localized
        }
    }

    enum TimePeriod: Equatable {
        case period(timePeriod: HsTimePeriod)
        case all

        var title: String {
            switch self {
            case let .period(timePeriod): return timePeriod.title
            case .all: return "market.etf.period.all".localized
            }
        }

        var shortTitle: String {
            switch self {
            case let .period(timePeriod): return timePeriod.shortTitle
            case .all: return "market.etf.period.all".localized
            }
        }
    }
}

extension MarketEtfFetcher.EtfCategory {
    var title: String {
        switch self {
        case .btc: return "Bitcoin"
        case .eth: return "Ethereum"
        }
    }

    var icon: String {
        switch self {
        case .btc: return "bitcoin"
        case .eth: return "ethereum"
        }
    }
}
