import Combine
import Foundation
import HsExtensions
import MarketKit

class MarketNewsViewModel: ObservableObject {
    private let marketKit = App.shared.marketKit

    private var tasks = Set<AnyTask>()

    @Published var state: State = .loading

    private func sync() {
        tasks = Set()

        Task { [weak self] in
            await self?._sync()
        }.store(in: &tasks)
    }

    private func _sync() async {
        if case .failed = state {
            await MainActor.run { [weak self] in
                self?.state = .loading
            }
        }

        do {
            let posts = try await marketKit.posts()

            await MainActor.run { [weak self] in
                self?.state = .loaded(posts: posts)
            }
        } catch {
            await MainActor.run { [weak self] in
                self?.state = .failed(error: error)
            }
        }
    }
}

extension MarketNewsViewModel {
    func load() {
        sync()
    }

    func refresh() async {
        await _sync()
        stat(page: .markets, section: .news, event: .refresh)
    }
}

extension MarketNewsViewModel {
    enum State {
        case loading
        case loaded(posts: [Post])
        case failed(error: Error)
    }
}
