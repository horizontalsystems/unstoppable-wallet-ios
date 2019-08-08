class SendFeeSliderPresenter {
    weak var view: ISendFeeSliderView?
    weak var delegate: ISendFeeSliderDelegate?

    private let interactor: SendFeeSliderInteractor

    private var feeRatePriority: FeeRatePriority = .medium

    init(interactor: SendFeeSliderInteractor) {
        self.interactor = interactor
    }

}

extension SendFeeSliderPresenter: ISendFeeSliderModule {

    var feeRate: Int {
        return interactor.feeRate(priority: feeRatePriority)
    }

}

extension SendFeeSliderPresenter: ISendFeeSliderViewDelegate {

    func onFeePriorityChange(value: Int) {
        feeRatePriority = FeeRatePriority(rawValue: value) ?? .medium
        delegate?.onUpdate(feeRate: feeRate)
    }

}
