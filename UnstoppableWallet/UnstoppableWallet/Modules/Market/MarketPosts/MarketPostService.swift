import RxSwift
import RxRelay
import MarketKit

class MarketPostService {
    private let marketKit: Kit
    private var disposeBag = DisposeBag()

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
        disposeBag = DisposeBag()

        if case .failed = state {
            state = .loading
        }

        marketKit.postsSingle()
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                .subscribe(onSuccess: { [weak self] posts in
                    self?.state = .loaded(posts: posts)
                }, onError: { [weak self] error in
                    self?.state = .failed(error: error)
                })
                .disposed(by: disposeBag)
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
