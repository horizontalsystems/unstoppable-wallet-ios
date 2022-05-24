import RxSwift
import RxRelay
import MarketKit

class NftCollectionOverviewService {
    private let collectionUid: String
    private let marketKit: MarketKit.Kit
    private var disposeBag = DisposeBag()

    private let stateRelay = PublishRelay<DataStatus<Item>>()
    private(set) var state: DataStatus<Item> = .loading {
        didSet {
            stateRelay.accept(state)
        }
    }

    init(collectionUid: String, marketKit: MarketKit.Kit) {
        self.collectionUid = collectionUid
        self.marketKit = marketKit

        sync()
    }

    private func sync() {
        disposeBag = DisposeBag()

        state = .loading

        marketKit.nftCollectionSingle(uid: collectionUid)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] collection in
                    let item = Item(collection: collection)
                    self?.state = .completed(item)
                }, onError: { [weak self] error in
                    self?.state = .failed(error)
                })
                .disposed(by: disposeBag)
    }

}

extension NftCollectionOverviewService {

    var stateObservable: Observable<DataStatus<Item>> {
        stateRelay.asObservable()
    }

    func resync() {
        sync()
    }

}

extension NftCollectionOverviewService {

    struct Item {
        let collection: NftCollection
    }

}
