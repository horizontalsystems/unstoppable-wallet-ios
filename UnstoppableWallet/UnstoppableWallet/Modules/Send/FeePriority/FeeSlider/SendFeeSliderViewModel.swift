import RxCocoa
import RxRelay
import RxSwift

class SendFeeSliderViewModel {
    private let disposeBag = DisposeBag()
    private let feeViewItemFactory: FeeViewItemFactory
    private let service: SendFeeSliderService

    private let sliderRelay = BehaviorRelay<FeeViewItem?>(value: nil)
    private var slider: FeeViewItem? {
        didSet {
            sliderRelay.accept(slider)
        }
    }

    init(feeViewItemFactory: FeeViewItemFactory, service: SendFeeSliderService) {
        self.feeViewItemFactory = feeViewItemFactory
        self.service = service

        subscribe(disposeBag, service.itemObservable) { [weak self] in self?.sync(item: $0) }
        sync(item: service.item)
    }

    private func sync(item: SendFeeSliderService.Item) {
        slider = feeViewItemFactory.viewItem(value: item.value, step: item.step, range: item.range)
    }
}

extension SendFeeSliderViewModel {
    var sliderDriver: Driver<FeeViewItem?> {
        sliderRelay.asDriver()
    }

    func subscribeTracking(cell: FeeSliderCell) {
        cell.onFinishTracking = { [weak self] feeRate in
            self?.service.set(feeRate: Int(feeRate))
        }
    }
}
