class SendFeePriorityPresenter {
    weak var view: ISendFeePriorityView?
    weak var delegate: ISendFeePriorityDelegate?

    private let interactor: ISendFeePriorityInteractor
    private let router: ISendFeePriorityRouter

    var feeRatePriority: FeeRatePriority

    init(interactor: ISendFeePriorityInteractor, router: ISendFeePriorityRouter, feeRatePriority: FeeRatePriority) {
        self.interactor = interactor
        self.router = router
        self.feeRatePriority = feeRatePriority
    }

}

extension SendFeePriorityPresenter: ISendFeePriorityModule {

    var feeRate: Int {
        return interactor.feeRate(priority: feeRatePriority)
    }

}

extension SendFeePriorityPresenter: ISendFeePriorityViewDelegate {

    func onFeePrioritySelectorTap() {
        router.openPriorities(selected: feeRatePriority, priorityDelegate: self)
    }

}

extension SendFeePriorityPresenter: IPriorityDelegate {

    func onSelect(priority: FeeRatePriority) {
        feeRatePriority = priority
        view?.setPriority()
        delegate?.onUpdate(feeRate: feeRate)
    }

}
