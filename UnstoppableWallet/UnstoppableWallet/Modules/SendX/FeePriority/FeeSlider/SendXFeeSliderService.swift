import Foundation
import RxSwift
import RxCocoa
import RxRelay

class SendXFeeSliderService {
    private let disposeBag = DisposeBag()
    private let service: SendXFeePriorityService
    private let feeRateService: SendXFeeRateService
    private let customRangedFeeRateProvider: ICustomRangedFeeRateProvider

    private let itemRelay = PublishRelay<Item>()
    var item: Item {
        didSet {
            itemRelay.accept(item)
        }
    }

    init(service: SendXFeePriorityService, feeRateService: SendXFeeRateService, customRangedFeeRateProvider: ICustomRangedFeeRateProvider) {
        self.service = service
        self.feeRateService = feeRateService
        self.customRangedFeeRateProvider = customRangedFeeRateProvider
        item = Item(value: 1, range: customRangedFeeRateProvider.customFeeRange)

        subscribe(disposeBag, feeRateService.feeRateObservable) { [weak self] _ in self?.sync() }
    }

    private func sync() {
        let range = customRangedFeeRateProvider.customFeeRange

        let feeRate = feeRateService.feeRate.data ?? item.value
        item = Item(value: feeRate, range: range)
    }

}

extension SendXFeeSliderService {

    var itemObservable: Observable<Item> {
        itemRelay.asObservable()
    }

    func set(feeRate: Int) {
        service.priority = .custom(value: feeRate, range: customRangedFeeRateProvider.customFeeRange)
    }

}

extension SendXFeeSliderService {

    struct Item {
        let value: Int
        let range: ClosedRange<Int>
    }

}