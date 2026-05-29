import RxCocoa
import RxRelay
import RxSwift

class NftCollectionViewModel {
    private let service: NftCollectionService
    private let disposeBag = DisposeBag()

    init(service: NftCollectionService) {
        self.service = service
    }
}

extension NftCollectionViewModel {}
