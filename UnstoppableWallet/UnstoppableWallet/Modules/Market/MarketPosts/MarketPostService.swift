import RxSwift
import RxRelay
import MarketKit
import HsExtensions

class MarketPostService {
    private let marketKit: Kit
    private var tasks = Set<AnyTask>()

    private let stateRelay = PublishRelay<State>()
    private(set) var state: State = .loading {
        didSet {
            stateRelay.accept(state)
        }
    }

    init(marketKit: Kit) {
        self.marketKit = marketKit
    }

    private func fetch() {
        tasks = Set()

        if case .failed = state {
            state = .loading
        }

        Task { [weak self, marketKit] in
            do {
                let posts = try await marketKit.posts()
                self?.state = .loaded(posts: posts)
            } catch {
                self?.state = .failed(error: error)
            }
        }.store(in: &tasks)
    }

}

extension MarketPostService {

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    func load() {
        fetch()
    }

    func refresh() {
        fetch()
    }

}

extension MarketPostService {

    enum State {
        case loading
        case loaded(posts: [Post])
        case failed(error: Error)
    }

}
