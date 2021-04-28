import CurrencyKit
import RxSwift
import RxRelay
import RxCocoa

class MarketPostViewModel {
    private let service: MarketPostService
    private let postLimit: Int?
    private let disposeBag = DisposeBag()

    private let stateRelay = BehaviorRelay<State>(value: .loading)

    init(service: MarketPostService, postLimit: Int? = nil) {
        self.service = service
        self.postLimit = postLimit

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }

        sync(state: service.state)
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

    private var postViewItems: [ViewItem] {
        let currentTimeInterval = Date().timeIntervalSince1970

        return Array(
                service.items.map { item in
                    ViewItem(
                            source: item.source,
                            title: item.title,
                            body: item.body,
                            timestamp: timeAgo(interval: currentTimeInterval - item.timestamp),
                            url: item.url,
                            imageUrl: item.url)
                }.prefix(postLimit ?? Int.max))
    }

    private func sync(state: MarketPostService.State) {
        switch state {
        case .loading:
            switch stateRelay.value {
            case .loading, .error:
                stateRelay.accept(.loading)
            default: ()
            }
        case .loaded:
            stateRelay.accept(.loaded(posts: postViewItems))
        case .failed:
            stateRelay.accept(.error(description: "market.sync_error".localized))
        }
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
        let timestamp: String
        let url: String
        let imageUrl: String?
    }

    enum State {
        case loading
        case loaded(posts: [ViewItem])
        case error(description: String)
    }

}
