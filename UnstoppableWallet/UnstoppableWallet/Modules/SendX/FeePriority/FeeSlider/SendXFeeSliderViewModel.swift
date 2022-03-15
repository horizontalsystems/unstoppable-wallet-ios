import RxSwift
import RxRelay
import RxCocoa

class SendXFeeSliderViewModel {
    private let disposeBag = DisposeBag()
    private let service: SendXFeePriorityService

    private let sliderRelay = BehaviorRelay<FeeSliderViewItem?>(value: nil)
    private var slider: FeeSliderViewItem? {
        didSet {
            sliderRelay.accept(slider)
        }
    }

    private let isHiddenRelay = BehaviorRelay<Bool>(value: false)
    private var isHidden: Bool = false {
        didSet {
            if isHidden != oldValue {
                isHiddenRelay.accept(isHidden)
            }
        }
    }

    init(service: SendXFeePriorityService) {
        self.service = service

        subscribe(disposeBag, service.priorityObservable) { [weak self] in self?.sync(priority: $0) }
    }

    private func sync(priority: FeeRatePriority) {
        guard case let .custom(value, range) = priority else {
            slider = nil
            isHidden = true
            return
        }

        slider = FeeSliderViewItem(initialValue: value, range: range, description: "sat/byte")
        isHidden = false
    }

    private func sync(feeRate: Int) {
        guard case let .custom(_, range) = service.priority else {
            return
        }

        service.priority = .custom(value: feeRate, range: range)
    }

    deinit {
        print("deinit \(self)")
    }

}

extension SendXFeeSliderViewModel {

    var isHiddenDriver: Driver<Bool> {
        isHiddenRelay.asDriver()
    }

    var sliderDriver: Driver<FeeSliderViewItem?> {
        sliderRelay.asDriver()
    }

    func subscribeTracking(cell: FeeSliderCell) {
        cell.onFinishTracking = { [weak self] feeRate in
            self?.sync(feeRate: feeRate)
        }
    }

}
