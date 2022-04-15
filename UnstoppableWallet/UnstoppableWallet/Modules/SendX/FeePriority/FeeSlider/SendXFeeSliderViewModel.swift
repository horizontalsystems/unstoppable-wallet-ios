import RxSwift
import RxRelay
import RxCocoa

class SendXFeeSliderViewModel {
    private let disposeBag = DisposeBag()
    private let service: SendXFeeSliderService

    private let sliderRelay = BehaviorRelay<FeeSliderViewItem?>(value: nil)
    private var slider: FeeSliderViewItem? {
        didSet {
            sliderRelay.accept(slider)
        }
    }

    init(service: SendXFeeSliderService) {
        self.service = service

        subscribe(disposeBag, service.itemObservable) { [weak self] in self?.sync(item: $0) }
        sync(item: service.item)
    }

    private func sync(item: SendXFeeSliderService.Item) {
        slider = FeeSliderViewItem(initialValue: item.value, range: item.range, description: "sat/byte")
    }

}

extension SendXFeeSliderViewModel {

    var sliderDriver: Driver<FeeSliderViewItem?> {
        sliderRelay.asDriver()
    }

    func subscribeTracking(cell: FeeSliderCell) {
        cell.onFinishTracking = { [weak self] feeRate in
            self?.service.set(feeRate: feeRate)
        }
    }

}
