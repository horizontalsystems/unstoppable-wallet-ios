import Foundation
import CurrencyKit
import MarketKit

class SendFeePriorityPresenter {
    weak var view: ISendFeePriorityView?
    weak var delegate: ISendFeePriorityDelegate?

    private let interactor: ISendFeePriorityInteractor
    private let router: ISendFeePriorityRouter
    private let feeRateAdjustmentHelper: FeeRateAdjustmentHelper
    private let platformCoin: PlatformCoin

    private var feeRateAdjustmentInfo: FeeRateAdjustmentInfo
    private var customFeeRate: Int?
    private var fetchedFeeRate: Int?
    private var recommendedFeeRate: Int?

    private var error: Error?
    private(set) var feeRatePriority: FeeRatePriority

    var feeRate: Int? {
        customFeeRate ?? fetchedFeeRate.flatMap { rate in
            feeRateAdjustmentHelper.applyRule(coinType: platformCoin.coinType, feeRateAdjustmentInfo: feeRateAdjustmentInfo, feeRate: rate)
        }
    }

    init(interactor: ISendFeePriorityInteractor, router: ISendFeePriorityRouter, feeRateAdjustmentHelper: FeeRateAdjustmentHelper, platformCoin: PlatformCoin) {
        self.interactor = interactor
        self.router = router
        self.feeRateAdjustmentHelper = feeRateAdjustmentHelper
        self.platformCoin = platformCoin

        feeRatePriority = interactor.defaultFeeRatePriority
        feeRateAdjustmentInfo = FeeRateAdjustmentInfo(amountInfo: .notEntered, xRate: nil, currency: interactor.baseCurrency, balance: nil)
    }

}

extension SendFeePriorityPresenter: ISendFeePriorityModule {

    var feeRateState: FeeRateState {
        if let error = error {
            return .error(error)
        }
        if let feeRate = feeRate {
            return .value(feeRate)
        }
        return .loading
    }

    func fetchFeeRate() {
        fetchedFeeRate = nil
        error = nil

        interactor.syncFeeRate(priority: feeRatePriority)
    }

    func set(amountInfo: SendAmountInfo) {
        feeRateAdjustmentInfo.amountInfo = amountInfo
    }

    func set(xRate: Decimal?) {
        feeRateAdjustmentInfo.xRate = xRate
    }

    func set(balance: Decimal) {
        feeRateAdjustmentInfo.balance = balance
    }
}

extension SendFeePriorityPresenter: ISendFeePriorityViewDelegate {

    func onFeePrioritySelectorTap() {
        let items = interactor.feeRatePriorityList.map { priority in
            PriorityItem(
                    priority: priority,
                    selected: priority == feeRatePriority
            )
        }

        router.openPriorities(items: items) { [weak self] selectedItem in
            self?.updateFeeRatePriority(selectedItem: selectedItem)
        }
    }

    func selectCustom(feeRatePriority: FeeRatePriority) {
        self.feeRatePriority = feeRatePriority
        if case let .custom(value, _) = feeRatePriority {
            customFeeRate = value

            let riskOfStuck = (recommendedFeeRate ?? 0) > value
            view?.set(riskOfStuckVisible: riskOfStuck)
        }

        delegate?.onUpdateFeePriority()
    }

    func onOpenFeeInfo() {
        router.openFeeInfo()
    }

    private func updateFeeRatePriority(selectedItem: PriorityItem) {
        if case let .custom(value: defaultValue, range: range) = selectedItem.priority {
            var value = feeRate ?? defaultValue                  // set feeRate from previous choice when select to custom slider
            value = min(value, range.upperBound)                 // value can't be more than slider upper range
            feeRatePriority = .custom(value: value, range: range)

            let riskOfStuck = (recommendedFeeRate ?? 0) > value
            view?.set(customVisible: true)
            view?.set(riskOfStuckVisible: riskOfStuck)
            view?.set(customFeeRateValue: value, customFeeRateRange: range)

            view?.setPriority()

            delegate?.onUpdateFeePriority()
        } else {
            customFeeRate = nil
            feeRatePriority = selectedItem.priority

            view?.set(customVisible: false)
            view?.set(riskOfStuckVisible: selectedItem.priority == .low)

            view?.setPriority()

            fetchFeeRate()
        }
    }

}

extension SendFeePriorityPresenter: ISendFeePriorityInteractorDelegate {

    func didUpdate(feeRate: Int) {
        if feeRatePriority == .recommended || feeRatePriority == .medium {
            recommendedFeeRate = feeRate
        }

        fetchedFeeRate = feeRate

        delegate?.onUpdateFeePriority()
    }

    func didReceiveError(error: Error) {
        self.error = error.convertedError

        delegate?.onUpdateFeePriority()
    }

}
