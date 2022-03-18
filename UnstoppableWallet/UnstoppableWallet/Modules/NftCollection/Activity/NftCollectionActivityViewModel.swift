import RxSwift
import RxRelay
import RxCocoa

class NftCollectionActivityViewModel {
    private let service: NftCollectionActivityService
    private let disposeBag = DisposeBag()

    private let loadingRelay = BehaviorRelay<Bool>(value: false)
    private let syncErrorRelay = BehaviorRelay<Bool>(value: false)

    init(service: NftCollectionActivityService) {
        self.service = service
    }

}

extension NftCollectionActivityViewModel {

    var loadingDriver: Driver<Bool> {
        loadingRelay.asDriver()
    }

    var syncErrorDriver: Driver<Bool> {
        syncErrorRelay.asDriver()
    }

    func onTapRetry() {
    }

}
