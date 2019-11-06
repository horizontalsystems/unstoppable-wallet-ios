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
        interactor.feeRate(priority: feeRatePriority)
    }

    var duration: TimeInterval {
        interactor.duration(priority: feeRatePriority)
    }

}

extension SendFeePriorityPresenter: ISendFeePriorityViewDelegate {

    func onFeePrioritySelectorTap() {
        let items = FeeRatePriority.allCases.map { priority in
            PriorityItem(
                    priority: priority,
                    duration: interactor.duration(priority: priority),
                    selected: priority == feeRatePriority
            )
        }

        router.openPriorities(items: items) { [weak self] selectedItem in
            self?.feeRatePriority = selectedItem.priority
            self?.view?.setPriority()
            self?.delegate?.onUpdateFeePriority()
        }
    }

}
