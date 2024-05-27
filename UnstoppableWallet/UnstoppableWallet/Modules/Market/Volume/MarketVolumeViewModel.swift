import Combine
import Foundation
import HsExtensions
import MarketKit

class MarketVolumeViewModel: ObservableObject {
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

    var sortOrder: MarketModule.SortOrder = .desc {
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
        case let .loaded(marketInfos):
            let sortBy: MarketModule.SortBy

            switch sortOrder {
            case .asc: sortBy = .lowestVolume
            case .desc: sortBy = .highestVolume
            }

            state = .loaded(marketInfos: marketInfos.sorted(sortBy: sortBy, timePeriod: .day1))
        case let .failed(error):
            state = .failed(error: error)
        }
    }
}

extension MarketVolumeViewModel {
    var currency: Currency {
        currencyManager.baseCurrency
    }

    func sync() {
        tasks = Set()

        if case .failed = internalState {
            internalState = .loading
        }

        Task { [weak self, marketKit, currency] in
            do {
                let marketInfos = try await marketKit.marketInfos(top: MarketModule.Top.top100.rawValue, currencyCode: currency.code)

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

extension MarketVolumeViewModel {
    enum State {
        case loading
        case loaded(marketInfos: [MarketInfo])
        case failed(error: Error)
    }
}
