import Combine
import Foundation
import HsExtensions
import MarketKit

class MarketEtfViewModel: ObservableObject {
    private let marketKit = App.shared.marketKit
    private let currencyManager = App.shared.currencyManager

    private var cancellables = Set<AnyCancellable>()
    private var tasks = Set<AnyTask>()

    private var internalState: State = .loading {
        didSet {
            syncState()
        }
    }

    @Published var state: State = .loading

    var sortBy: SortBy = .highestAssets {
        didSet {
            syncState()
        }
    }

    var timePeriod: TimePeriod = .period(timePeriod: .day1) {
        didSet {
            syncState()
        }
    }

    init() {
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
        case let .loaded(etfs):
            state = .loaded(etfs: etfs.sorted(sortBy: sortBy, timePeriod: timePeriod))
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

        Task { [weak self, marketKit, currency] in
            do {
                let etfs = try await marketKit.etfs(currencyCode: currency.code)

                await MainActor.run { [weak self] in
                    self?.internalState = .loaded(etfs: etfs)
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
        case loaded(etfs: [Etf])
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
            case let .period(timePeriod): return "market.time_period.\(timePeriod.rawValue)".localized
            case .all: return "market.etf.period.all".localized
            }
        }

        var shortTitle: String {
            switch self {
            case let .period(timePeriod): return "market.time_period.\(timePeriod.rawValue).short".localized
            case .all: return "market.etf.period.all".localized
            }
        }
    }
}
