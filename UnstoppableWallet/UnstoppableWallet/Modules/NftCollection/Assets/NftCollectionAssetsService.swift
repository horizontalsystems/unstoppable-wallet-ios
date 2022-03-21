import RxSwift
import RxRelay

class NftCollectionAssetsService {
    private let collectionUid: String
    private let provider: HsNftProvider
    private var disposeBag = DisposeBag()

    private let stateRelay = PublishRelay<State>()
    private(set) var state: State = .loading {
        didSet {
            stateRelay.accept(state)
        }
    }

    private(set) var assets = [NftAsset]()
    private var cursor: String?
    private var loadingMore = false

    private let newAssetsRelay = PublishRelay<[NftAsset]>()

    init(collectionUid: String, provider: HsNftProvider) {
        self.collectionUid = collectionUid
        self.provider = provider

        loadInitial()
    }

    private func loadInitial() {
        disposeBag = DisposeBag()

        state = .loading

        provider.assetsSingle(collectionUid: collectionUid)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] pagedAssets in
                    self?.assets = pagedAssets.assets
                    self?.cursor = pagedAssets.cursor
                    self?.state = .initialLoaded
                }, onError: { [weak self] error in
                    self?.state = .failed(error: error)
                })
                .disposed(by: disposeBag)
    }

}

extension NftCollectionAssetsService {

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    var newAssetsObservable: Observable<[NftAsset]> {
        newAssetsRelay.asObservable()
    }

    var allLoaded: Bool {
        cursor == nil
    }

    func reload() {
        loadInitial()
    }

    func loadMore() {
        guard cursor != nil else {
            return
        }

        guard !loadingMore else {
            return
        }

        loadingMore = true

        provider.assetsSingle(collectionUid: collectionUid, cursor: cursor)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] pagedAssets in
                    self?.assets += pagedAssets.assets
                    self?.cursor = pagedAssets.cursor

                    self?.newAssetsRelay.accept(pagedAssets.assets)
                    self?.loadingMore = false
                }, onError: { [weak self] error in
                    self?.loadingMore = false
                })
                .disposed(by: disposeBag)
    }

}

extension NftCollectionAssetsService {

    enum State {
        case loading
        case initialLoaded
        case failed(error: Error)
    }

}
