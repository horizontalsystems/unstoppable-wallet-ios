import Foundation
import RxSwift
import RxCocoa
import RxRelay

class SendFeeSliderService {
    private let disposeBag = DisposeBag()
    private let service: SendFeePriorityService
    private let feeRateService: SendFeeRateService
    private let customRangedFeeRateProvider: ICustomRangedFeeRateProvider

    private let itemRelay = PublishRelay<Item>()
    var item: Item {
        didSet {
            itemRelay.accept(item)
        }
    }

    init(service: SendFeePriorityService, feeRateService: SendFeeRateService, customRangedFeeRateProvider: ICustomRangedFeeRateProvider) {
        self.service = service
        self.feeRateService = feeRateService
        self.customRangedFeeRateProvider = customRangedFeeRateProvider
        item = Item(value: customRangedFeeRateProvider.customFeeRange.lowerBound, range: customRangedFeeRateProvider.customFeeRange, step: customRangedFeeRateProvider.step)

        subscribe(disposeBag, feeRateService.feeRateObservable) { [weak self] _ in self?.sync() }
    }

    private func sync() {
        let feeRate = feeRateService.feeRate.data ?? item.value
        item = Item(value: feeRate, range: customRangedFeeRateProvider.customFeeRange, step: customRangedFeeRateProvider.step)
    }

}

extension SendFeeSliderService {

    var itemObservable: Observable<Item> {
        itemRelay.asObservable()
    }

    func set(feeRate: Int) {
        service.priority = .custom(value: feeRate, range: customRangedFeeRateProvider.customFeeRange)
    }

}

extension SendFeeSliderService {

    struct Item {
        let value: Int
        let range: ClosedRange<Int>
        let step: Int
    }

}