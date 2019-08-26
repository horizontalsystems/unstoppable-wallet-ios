class SendFeePriorityPresenter {
    weak var view: ISendFeePriorityView?
    weak var delegate: ISendFeePriorityDelegate?

    private let interactor: SendFeePriorityInteractor
    private let router: SendFeePriorityRouter

    private var feeRatePriority: FeeRatePriority

    init(interactor: SendFeePriorityInteractor, router: SendFeePriorityRouter, feeRatePriority: FeeRatePriority) {
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
        router.openPriorities(selected: feeRatePriority)
    }

}

extension SendFeePriorityPresenter: IPriorityDelegate {

    func onSelect(priority: FeeRatePriority) {
        feeRatePriority = priority
        view?.set(priority: feeRatePriority)
        delegate?.onUpdate(feeRate: feeRate)
    }

}
