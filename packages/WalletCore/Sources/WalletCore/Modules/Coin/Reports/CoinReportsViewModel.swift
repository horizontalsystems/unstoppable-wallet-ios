import Combine
import Foundation
import HsExtensions
import MarketKit

class CoinReportsViewModel: ObservableObject {
    private let coinUid: String
    private let marketKit = Core.shared.marketKit
    private var tasks = Set<AnyTask>()

    @Published private(set) var state: State = .loading

    init(coinUid: String) {
        self.coinUid = coinUid

        sync()
    }

    private func sync() {
        tasks = Set()

        if case .failed = state {
            state = .loading
        }

        Task { [weak self, marketKit, coinUid] in
            do {
                let reports = try await marketKit.coinReports(coinUid: coinUid)

                await MainActor.run { [weak self] in
                    self?.state = .loaded(reports: reports)
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.state = .failed
                }
            }
        }
        .store(in: &tasks)
    }
}

extension CoinReportsViewModel {
    func onRetry() {
        sync()
    }
}

extension CoinReportsViewModel {
    enum State {
        case loading
        case loaded(reports: [CoinReport])
        case failed
    }
}
