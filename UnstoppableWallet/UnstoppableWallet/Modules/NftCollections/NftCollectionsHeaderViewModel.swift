import RxSwift
import RxRelay
import RxCocoa

class NftCollectionsHeaderViewModel {
    private let service: NftCollectionsService
    private let disposeBag = DisposeBag()

    private let amountRelay = BehaviorRelay<String?>(value: nil)

    init(service: NftCollectionsService) {
        self.service = service

        amountRelay.accept("$123980")
    }

}

extension NftCollectionsHeaderViewModel {

    var amountDriver: Driver<String?> {
        amountRelay.asDriver()
    }

    var priceTypeItems: [String] {
        ["Last Price", "Floor Price"]
    }

    var priceTypeIndex: Int {
        0
    }

    func onSelectPriceType(index: Int) {

    }

}
