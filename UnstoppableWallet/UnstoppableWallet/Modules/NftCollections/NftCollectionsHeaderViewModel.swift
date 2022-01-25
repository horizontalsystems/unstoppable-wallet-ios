import RxSwift
import RxRelay
import RxCocoa

class NftCollectionsHeaderViewModel {
    private let service: NftCollectionsService
    private let disposeBag = DisposeBag()

    private let amountRelay = BehaviorRelay<String?>(value: nil)

    init(service: NftCollectionsService) {
        self.service = service

        subscribe(disposeBag, service.totalItemObservable) { [weak self] in self?.sync(totalItem: $0) }

        sync(totalItem: service.totalItem)
    }

    private func sync(totalItem: NftCollectionsService.TotalItem?) {
        let formattedValue = totalItem.flatMap { ValueFormatter.instance.format(currencyValue: $0.currencyValue) }
        amountRelay.accept(formattedValue)
    }

    private func title(mode: NftCollectionsService.Mode) -> String {
        switch mode {
        case .lastPrice: return "nft_collections.last_price".localized
        case .floorPrice: return "nft_collections.floor_price".localized
        }
    }

}

extension NftCollectionsHeaderViewModel {

    var amountDriver: Driver<String?> {
        amountRelay.asDriver()
    }

    var priceTypeItems: [String] {
        NftCollectionsService.Mode.allCases.map { title(mode: $0) }
    }

    var priceTypeIndex: Int {
        NftCollectionsService.Mode.allCases.firstIndex(of: service.mode) ?? 0
    }

    func onSelectPriceType(index: Int) {
        service.mode = NftCollectionsService.Mode.allCases[index]
    }

}
