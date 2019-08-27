import Foundation

class SendFeePriorityPresenter {
    weak var view: ISendFeePriorityView?
    weak var delegate: ISendFeePriorityDelegate?

    private let interactor: ISendFeePriorityInteractor
    private let router: ISendFeePriorityRouter
    private let coin: Coin

    var feeRatePriority: FeeRatePriority

    init(interactor: ISendFeePriorityInteractor, router: ISendFeePriorityRouter, coin: Coin, feeRatePriority: FeeRatePriority) {
        self.interactor = interactor
        self.router = router
        self.coin = coin
        self.feeRatePriority = feeRatePriority
    }

}

extension SendFeePriorityPresenter: ISendFeePriorityModule {

    var feeRate: Int {
        return interactor.feeRate(priority: feeRatePriority)
    }

    var duration: TimeInterval {
        return interactor.duration(priority: feeRatePriority)
    }

}

extension SendFeePriorityPresenter: ISendFeePriorityViewDelegate {

    func onFeePrioritySelectorTap() {
        router.openPriorities(selected: feeRatePriority, coin: coin, priorityDelegate: self)
    }

}

extension SendFeePriorityPresenter: IPriorityDelegate {

    func onSelect(priority: FeeRatePriority) {
        feeRatePriority = priority
        view?.setPriority()
        delegate?.onUpdateFeePriority()
    }

}
