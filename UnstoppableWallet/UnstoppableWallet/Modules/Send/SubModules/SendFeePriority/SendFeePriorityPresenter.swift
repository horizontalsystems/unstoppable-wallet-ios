import Foundation

class SendFeePriorityPresenter {
    weak var view: ISendFeePriorityView?
    weak var delegate: ISendFeePriorityDelegate?

    private let interactor: ISendFeePriorityInteractor
    private let router: ISendFeePriorityRouter
    private let coin: Coin

    private var feeRateData: FeeRate?
    private var error: Error?

    private(set) var feeRatePriority: FeeRatePriority

   init(interactor: ISendFeePriorityInteractor, router: ISendFeePriorityRouter, coin: Coin) {
        self.interactor = interactor
        self.router = router
        self.coin = coin

        feeRatePriority = interactor.defaultFeeRatePriority
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

        interactor.syncFeeRate()
    }

}

extension SendFeePriorityPresenter: ISendFeePriorityViewDelegate {

    func onFeePrioritySelectorTap() {
        guard let feeRateData = feeRateData else {
            return
        }
        let items = interactor.feeRatePriorityList.map { priority in
            PriorityItem(
                    priority: priority,
                    duration: feeRateData.duration(priority: priority),
                    selected: priority == feeRatePriority
            )
        }

        router.openPriorities(items: items) { [weak self] selectedItem in
            self?.updateFeeRatePriority(selectedItem: selectedItem)
        }
    }

    func selectCustom(feeRatePriority: FeeRatePriority) {
        self.feeRatePriority = feeRatePriority
        delegate?.onUpdateFeePriority()
    }

    func onOpenFeeInfo() {
        router.openFeeInfo()
    }

    private func updateFeeRatePriority(selectedItem: PriorityItem) {
        if case let .custom(value: defaultValue, range: range) = selectedItem.priority {
            var value = feeRate ?? defaultValue                  // set feeRate from previous choice when select to custom slider
            value = min(value, range.upperBound)                 // value can't be more than slider upper range

            view?.set(customVisible: true)
            view?.set(customFeeRateValue: value, customFeeRateRange: range)
            feeRatePriority = .custom(value: value, range: range)
        } else {
            view?.set(customVisible: false)
            view?.set(duration: selectedItem.duration)
            feeRatePriority = selectedItem.priority
        }
        view?.setPriority()
        delegate?.onUpdateFeePriority()
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
        self.error = error.convertedError

        delegate?.onUpdateFeePriority()
    }

}
