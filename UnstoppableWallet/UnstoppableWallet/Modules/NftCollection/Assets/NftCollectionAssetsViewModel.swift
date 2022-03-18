import RxSwift
import RxRelay
import RxCocoa

class NftCollectionAssetsViewModel {
    private let service: NftCollectionAssetsService
    private let disposeBag = DisposeBag()

    private let loadingRelay = BehaviorRelay<Bool>(value: false)
    private let syncErrorRelay = BehaviorRelay<Bool>(value: false)

    init(service: NftCollectionAssetsService) {
        self.service = service
    }

}

extension NftCollectionAssetsViewModel {

    var loadingDriver: Driver<Bool> {
        loadingRelay.asDriver()
    }

    var syncErrorDriver: Driver<Bool> {
        syncErrorRelay.asDriver()
    }

    func onTapRetry() {
    }

}
