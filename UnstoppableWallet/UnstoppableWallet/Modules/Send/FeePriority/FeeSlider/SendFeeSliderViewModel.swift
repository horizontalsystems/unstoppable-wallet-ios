import RxSwift
import RxRelay
import RxCocoa

class SendFeeSliderViewModel {
    private let disposeBag = DisposeBag()
    private let service: SendFeeSliderService

    private let sliderRelay = BehaviorRelay<FeeSliderViewItem?>(value: nil)
    private var slider: FeeSliderViewItem? {
        didSet {
            sliderRelay.accept(slider)
        }
    }

    init(service: SendFeeSliderService) {
        self.service = service

        subscribe(disposeBag, service.itemObservable) { [weak self] in self?.sync(item: $0) }
        sync(item: service.item)
    }

    private func sync(item: SendFeeSliderService.Item) {
        slider = FeeSliderViewItem(initialValue: item.value, range: item.range, description: "sat/byte")
    }

}

extension SendFeeSliderViewModel {

    var sliderDriver: Driver<FeeSliderViewItem?> {
        sliderRelay.asDriver()
    }

    func subscribeTracking(cell: FeeSliderCell) {
        cell.onFinishTracking = { [weak self] feeRate in
            self?.service.set(feeRate: feeRate)
        }
    }

}
