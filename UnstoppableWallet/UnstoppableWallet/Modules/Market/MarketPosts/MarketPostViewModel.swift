import Foundation
import RxSwift
import RxRelay
import RxCocoa
import MarketKit

class MarketPostViewModel {
    private let service: MarketPostService
    private let disposeBag = DisposeBag()

    private let viewItemsRelay = BehaviorRelay<[ViewItem]?>(value: nil)
    private let loadingRelay = BehaviorRelay<Bool>(value: false)
    private let syncErrorRelay = BehaviorRelay<Bool>(value: false)

    init(service: MarketPostService) {
        self.service = service

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }

        sync(state: service.state)
    }

    private func sync(state: MarketPostService.State) {
        switch state {
        case .loading:
            viewItemsRelay.accept(nil)
            loadingRelay.accept(true)
            syncErrorRelay.accept(false)
        case .loaded(let posts):
            viewItemsRelay.accept(posts.map { viewItem(post: $0) })
            loadingRelay.accept(false)
            syncErrorRelay.accept(false)
        case .failed:
            viewItemsRelay.accept(nil)
            loadingRelay.accept(false)
            syncErrorRelay.accept(true)
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

    var viewItemsDriver: Driver<[ViewItem]?> {
        viewItemsRelay.asDriver()
    }

    var loadingDriver: Driver<Bool> {
        loadingRelay.asDriver()
    }

    var syncErrorDriver: Driver<Bool> {
        syncErrorRelay.asDriver()
    }

    func onLoad() {
        service.load()
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

}
