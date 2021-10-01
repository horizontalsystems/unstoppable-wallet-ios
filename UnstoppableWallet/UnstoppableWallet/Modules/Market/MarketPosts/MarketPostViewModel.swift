import RxSwift
import RxRelay
import RxCocoa
import MarketKit

class MarketPostViewModel {
    private let service: MarketPostService
    private let disposeBag = DisposeBag()

    private let stateRelay = BehaviorRelay<State>(value: .loading)

    init(service: MarketPostService) {
        self.service = service

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }

        sync(state: service.state)
    }

    private func sync(state: MarketPostService.State) {
        switch state {
        case .loading:
            stateRelay.accept(.loading)
        case .loaded(let posts):
            stateRelay.accept(.loaded(viewItems: posts.map { viewItem(post: $0) }))
        case .failed:
            stateRelay.accept(.error(description: "market.sync_error".localized))
        }
    }

    private func viewItem(post: Post) -> ViewItem {
        ViewItem(
                source: post.source,
                title: post.title,
                body: post.body,
                timeAgo: timeAgo(interval: Date().timeIntervalSince1970 - post.timestamp),
                url: post.url
        )
    }

    private func timeAgo(interval: TimeInterval) -> String {
        var interval = Int(interval) / 60

        // interval from post in minutes
        if interval < 60 {
            return "timestamp.min_ago".localized(max(1, interval))
        }

        // interval in hours
        interval /= 60
        if interval < 24 {
            return "timestamp.hours_ago".localized(interval)
        }

        // interval in days
        interval /= 24
        return "timestamp.days_ago".localized(interval)
    }

}

extension MarketPostViewModel {

    var stateDriver: Driver<State> {
        stateRelay.asDriver()
    }

    func refresh() {
        service.refresh()
    }

}

extension MarketPostViewModel {

    struct ViewItem {
        let source: String
        let title: String
        let body: String
        let timeAgo: String
        let url: String
    }

    enum State {
        case loading
        case loaded(viewItems: [ViewItem])
        case error(description: String)
    }

}
