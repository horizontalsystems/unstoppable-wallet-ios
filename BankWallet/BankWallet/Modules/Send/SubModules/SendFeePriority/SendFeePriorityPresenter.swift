import Foundation

class SendFeePriorityPresenter {
    weak var view: ISendFeePriorityView?
    weak var delegate: ISendFeePriorityDelegate?

    private let interactor: ISendFeePriorityInteractor
    private let router: ISendFeePriorityRouter
    private let coin: Coin

    private var feeRateData: FeeRate?
    private var error: Error?

    var feeRatePriority: FeeRatePriority

    init(interactor: ISendFeePriorityInteractor, router: ISendFeePriorityRouter, coin: Coin, feeRatePriority: FeeRatePriority) {
        self.interactor = interactor
        self.router = router
        self.coin = coin
        self.feeRatePriority = feeRatePriority
    }

}

extension SendFeePriorityPresenter: ISendFeePriorityModule {

    var feeRate: Int? {
        feeRateData?.feeRate(priority: feeRatePriority)
    }

    var duration: TimeInterval? {
        feeRateData?.duration(priority: feeRatePriority)
    }

    var feeRateState: FeeState {
        if let error = error {
            return .error(error)
        }
        if let feeRateData = feeRateData {
            return .value(feeRateData.feeRate(priority: feeRatePriority))
        }
        return .loading
    }

    func fetchFeeRate() {
        feeRateData = nil
        error = nil

        view?.set(duration: nil)
        view?.set(enabled: false)

        interactor.syncFeeRate(priority: feeRatePriority)
    }

}

extension SendFeePriorityPresenter: ISendFeePriorityViewDelegate {

    func onFeePrioritySelectorTap() {
        guard let feeRateData = feeRateData else {
            return
        }
        let items = FeeRatePriority.allCases.map { priority in
            PriorityItem(
                    priority: priority,
                    duration: feeRateData.duration(priority: priority),
                    selected: priority == feeRatePriority
            )
        }

        router.openPriorities(items: items) { [weak self] selectedItem in
            self?.feeRatePriority = selectedItem.priority
            self?.view?.setPriority()
            self?.view?.set(duration: selectedItem.duration)
            self?.delegate?.onUpdateFeePriority()
        }
    }

}

extension SendFeePriorityPresenter: ISendFeePriorityInteractorDelegate {

    func didUpdate(feeRate: FeeRate) {
        self.feeRateData = feeRate

        view?.set(duration: feeRate.duration(priority: feeRatePriority))
        view?.set(enabled: true)

        delegate?.onUpdateFeePriority()
    }

    func didReceiveError(error: Error) {
        self.error = error

        delegate?.onUpdateFeePriority()
    }

}
