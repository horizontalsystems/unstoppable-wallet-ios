import Combine
import Foundation
import HsExtensions
import MarketKit

class MarketGlobalViewModel: ObservableObject {
    private let marketKit = Core.shared.marketKit
    private let currencyManager = Core.shared.currencyManager
    private let appManager = Core.shared.appManager

    private var cancellables = Set<AnyCancellable>()
    private var tasks = Set<AnyTask>()

    @Published var marketGlobal: MarketGlobal?

    init() {
        currencyManager.$baseCurrency
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.marketGlobal = nil
                self?.syncState()
            }
            .store(in: &cancellables)

        appManager.willEnterForegroundPublisher
            .sink { [weak self] in self?.syncState() }
            .store(in: &cancellables)

        syncState()
    }

    private func syncState() {
        tasks = Set()

        Task { [weak self, marketKit, currencyManager] in
            let marketGlobal = try await marketKit.marketGlobal(currencyCode: currencyManager.baseCurrency.code)

            await MainActor.run { [weak self] in
                self?.marketGlobal = marketGlobal
            }
        }
        .store(in: &tasks)
    }
}

extension MarketGlobalViewModel {
    var currency: Currency {
        currencyManager.baseCurrency
    }
}
