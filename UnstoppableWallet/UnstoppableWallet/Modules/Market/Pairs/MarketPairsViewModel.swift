import Combine
import Foundation
import HsExtensions
import MarketKit

class MarketPairsViewModel: ObservableObject {
    private let marketKit = App.shared.marketKit
    private let currencyManager = App.shared.currencyManager
    private let appManager = App.shared.appManager
    private var cancellables = Set<AnyCancellable>()
    private var tasks = Set<AnyTask>()

    private var internalState: State = .loading {
        didSet {
            syncState()
        }
    }

    @Published var state: State = .loading

    var volumeSortOrder: MarketModule.SortOrder = .desc {
        didSet {
            stat(page: .markets, section: .pairs, event: .switchSortType(sortType: volumeSortOrder.statVolumeSortType))
            syncState()
        }
    }

    private func sync() {
        tasks = Set()

        Task { [weak self] in
            await self?._sync()
        }
        .store(in: &tasks)
    }

    private func _sync() async {
        if case .failed = state {
            await MainActor.run { [weak self] in
                self?.internalState = .loading
            }
        }

        do {
            let pairs = try await marketKit.topPairs(currencyCode: currency.code)

            await MainActor.run { [weak self] in
                self?.internalState = .loaded(pairs: pairs)
            }
        } catch {
            await MainActor.run { [weak self] in
                self?.internalState = .failed(error: error)
            }
        }
    }

    private func syncState() {
        switch internalState {
        case .loading:
            state = .loading
        case let .loaded(pairs):
            state = .loaded(pairs: pairs.sorted(volumeSortOrder: volumeSortOrder))
        case let .failed(error):
            state = .failed(error: error)
        }
    }
}

extension MarketPairsViewModel {
    var currency: Currency {
        currencyManager.baseCurrency
    }

    func load() {
        currencyManager.$baseCurrency
            .sink { [weak self] _ in
                self?.sync()
            }
            .store(in: &cancellables)

        appManager.willEnterForegroundPublisher
            .sink { [weak self] in self?.sync() }
            .store(in: &cancellables)

        sync()
    }

    func refresh() async {
        await _sync()
    }
}

extension MarketPairsViewModel {
    enum State {
        case loading
        case loaded(pairs: [MarketPair])
        case failed(error: Error)
    }
}

extension [MarketPair] {
    func sorted(volumeSortOrder: MarketModule.SortOrder) -> [MarketPair] {
        sorted { lhsPair, rhsPair in
            let lhsVolume = lhsPair.volume ?? 0
            let rhsVolume = rhsPair.volume ?? 0

            switch volumeSortOrder {
            case .asc: return lhsVolume < rhsVolume
            case .desc: return lhsVolume > rhsVolume
            }
        }
    }
}
