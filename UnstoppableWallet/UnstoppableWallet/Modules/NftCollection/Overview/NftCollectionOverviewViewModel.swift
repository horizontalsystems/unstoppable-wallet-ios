import RxSwift
import RxRelay
import RxCocoa

class NftCollectionOverviewViewModel {
    private let service: NftCollectionOverviewService
    private let disposeBag = DisposeBag()

    private let loadingRelay = BehaviorRelay<Bool>(value: false)
    private let syncErrorRelay = BehaviorRelay<Bool>(value: false)

    init(service: NftCollectionOverviewService) {
        self.service = service
    }

}

extension NftCollectionOverviewViewModel {

    var loadingDriver: Driver<Bool> {
        loadingRelay.asDriver()
    }

    var syncErrorDriver: Driver<Bool> {
        syncErrorRelay.asDriver()
    }

    func onTapRetry() {
    }

}
