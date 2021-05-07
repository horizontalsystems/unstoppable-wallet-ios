import CurrencyKit
import XRatesKit
import Foundation
import RxSwift
import RxRelay

class MarketPostService {
    private var postsDisposeBag = DisposeBag()

    private let postManager: IPostsManager

    private let stateRelay = PublishRelay<State>()
    private(set) var state: State = .loading {
        didSet {
            stateRelay.accept(state)
        }
    }

    private(set) var items = [Item]()

    init(postManager: IPostsManager) {
        self.postManager = postManager

        fetch()
    }

    private func fetch() {
        postsDisposeBag = DisposeBag()

        state = .loading

        postManager.postsSingle
                .subscribe(onSuccess: { [weak self] in
                    self?.onFetchSuccess(items: $0)
                }, onError: { [weak self] error in
                    self?.onFetchFailed(error: error)
                })
                .disposed(by: postsDisposeBag)
    }

    private func onFetchSuccess(items: [CryptoNewsPost]) {
        self.items = items.map {
            Item(
                timestamp: $0.timestamp,
                imageUrl: $0.imageUrl,
                source: $0.source,
                title: $0.title,
                url: $0.url,
                body: $0.body)
        }

        state = .loaded
    }

    private func onFetchFailed(error: Error) {
        state = .failed(error: error)
    }

}

extension MarketPostService {

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    func refresh() {
        fetch()
    }

}

extension MarketPostService {

    struct Item {
        let timestamp: TimeInterval
        let imageUrl: String?
        let source: String
        let title: String
        let url: String
        let body: String
    }

    enum State {
        case loaded
        case loading
        case failed(error: Error)
    }

}
