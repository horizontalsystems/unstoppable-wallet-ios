import EvmKit
import Foundation
import RxCocoa
import RxRelay
import RxSwift

class Eip1559EvmFeeViewModel {
    private let disposeBag = DisposeBag()

    private let gasPriceService: Eip1559GasPriceService
    private let feeService: IEvmFeeService
    private let coinService: CoinService
    private let feeViewItemFactory: FeeViewItemFactory
    private let cautionsFactory: SendEvmCautionsFactory

    private let resetButtonActiveRelay = BehaviorRelay<Bool>(value: false)
    private let valueRelay = BehaviorRelay<FeeCell.Value?>(value: nil)
    private let spinnerVisibleRelay = BehaviorRelay<Bool>(value: false)
    private let gasLimitRelay = BehaviorRelay<String>(value: "n/a")
    private let currentBaseFeeRelay = BehaviorRelay<String>(value: "n/a")
    private let baseFeeRelay = BehaviorRelay<String>(value: "n/a")
    private let tipsRelay = BehaviorRelay<String>(value: "n/a")
    private let baseFeeSliderRelay = BehaviorRelay<FeeViewItem?>(value: nil)
    private let tipsSliderRelay = BehaviorRelay<FeeViewItem?>(value: nil)
    private let cautionRelay = BehaviorRelay<TitledCaution?>(value: nil)

    init(gasPriceService: Eip1559GasPriceService, feeService: IEvmFeeService, coinService: CoinService, feeViewItemFactory: FeeViewItemFactory, cautionsFactory: SendEvmCautionsFactory) {
        self.gasPriceService = gasPriceService
        self.feeService = feeService
        self.coinService = coinService
        self.feeViewItemFactory = feeViewItemFactory
        self.cautionsFactory = cautionsFactory

        sync(transactionStatus: feeService.status)
        sync(gasPriceStatus: gasPriceService.status)
        sync(recommendedBaseFee: gasPriceService.recommendedBaseFee)
        sync(usingRecommended: gasPriceService.usingRecommended)

        subscribe(disposeBag, feeService.statusObservable) { [weak self] in
            self?.sync(transactionStatus: $0)
        }
        subscribe(disposeBag, gasPriceService.statusObservable) { [weak self] in
            self?.sync(gasPriceStatus: $0)
        }
        subscribe(disposeBag, gasPriceService.recommendedBaseFeeObservable) { [weak self] in
            self?.sync(recommendedBaseFee: $0)
        }
        subscribe(disposeBag, gasPriceService.baseFeeRangeChangedObservable) { [weak self] in
            self?.sync(gasPriceStatus: nil)
        }
        subscribe(disposeBag, gasPriceService.tipsRangeChangedObservable) { [weak self] in
            self?.sync(gasPriceStatus: nil)
        }
        subscribe(disposeBag, gasPriceService.usingRecommendedObservable) { [weak self] in
            self?.sync(usingRecommended: $0)
        }
    }

    private func sync(transactionStatus: DataStatus<FallibleData<EvmFeeModule.Transaction>>) {
        let spinnerVisible: Bool
        let maxFeeValue: FeeCell.Value?
        let gasLimit: String
        let cautions: [TitledCaution]

        switch transactionStatus {
        case .loading:
            spinnerVisible = true
            maxFeeValue = nil
            gasLimit = "n/a".localized
            cautions = []
        case let .failed(error):
            spinnerVisible = false
            maxFeeValue = FeeCell.Value(text: "n/a".localized, type: .error)
            gasLimit = "n/a".localized
            cautions = cautionsFactory.items(errors: [error], warnings: [], baseCoinService: coinService)
        case let .completed(fallibleTransaction):
            spinnerVisible = false

            let gasData = fallibleTransaction.data.gasData
            let valueType: FeeCell.ValueType = fallibleTransaction.errors.isEmpty ? .regular : .error
            maxFeeValue = FeeCell.Value(text: coinService.amountData(value: gasData.fee).formattedFull, type: valueType)
            gasLimit = gasData.limit.description
            cautions = cautionsFactory.items(errors: fallibleTransaction.errors, warnings: fallibleTransaction.warnings, baseCoinService: coinService)
        }

        spinnerVisibleRelay.accept(spinnerVisible)
        valueRelay.accept(maxFeeValue)
        gasLimitRelay.accept(gasLimit)
        cautionRelay.accept(cautions.first)
    }

    private func sync(gasPriceStatus: DataStatus<FallibleData<GasPrice>>?) {
        let gasPriceStatus = gasPriceStatus ?? gasPriceService.status

        guard case .completed = gasPriceStatus else {
            baseFeeRelay.accept("n/a")
            tipsRelay.accept("n/a")
            baseFeeSliderRelay.accept(nil)
            tipsSliderRelay.accept(nil)
            return
        }

        let baseStep = gasPriceService.recommendedBaseFee.significant(depth: FeeViewItemFactory.stepDepth)
        let baseFeeViewItem = feeViewItemFactory.viewItem(value: gasPriceService.baseFee, step: baseStep, range: gasPriceService.baseFeeRange)
        baseFeeRelay.accept(baseFeeViewItem.description)
        baseFeeSliderRelay.accept(baseFeeViewItem)

        let tipsStep = (gasPriceService.usingRecommended ? gasPriceService.recommendedTips : gasPriceService.tips).significant(depth: FeeViewItemFactory.stepDepth)
        let tipsViewItem = feeViewItemFactory.viewItem(value: gasPriceService.tips, step: tipsStep, range: gasPriceService.tipsRange)
        tipsRelay.accept(tipsViewItem.description)
        tipsSliderRelay.accept(tipsViewItem)
    }

    private func sync(recommendedBaseFee: Int) {
        let baseStep = recommendedBaseFee.significant(depth: FeeViewItemFactory.stepDepth)
        let baseFeeViewItem = feeViewItemFactory.viewItem(value: recommendedBaseFee, step: baseStep, range: gasPriceService.baseFeeRange)
        currentBaseFeeRelay.accept(baseFeeViewItem.description)
    }

    private func sync(usingRecommended: Bool) {
        resetButtonActiveRelay.accept(!usingRecommended)
    }

}

extension Eip1559EvmFeeViewModel {
    var gasLimitDriver: Driver<String> {
        gasLimitRelay.asDriver()
    }

    var currentBaseFeeDriver: Driver<String> {
        currentBaseFeeRelay.asDriver()
    }

    var baseFeeDriver: Driver<String> {
        baseFeeRelay.asDriver()
    }

    var tipsDriver: Driver<String> {
        tipsRelay.asDriver()
    }

    var baseFeeSliderDriver: Driver<FeeViewItem?> {
        baseFeeSliderRelay.asDriver()
    }

    var tipsSliderDriver: Driver<FeeViewItem?> {
        tipsSliderRelay.asDriver()
    }

    var cautionDriver: Driver<TitledCaution?> {
        cautionRelay.asDriver()
    }

    var resetButtonActiveDriver: Driver<Bool> {
        resetButtonActiveRelay.asDriver()
    }

    func set(baseFee: Float) {
        gasPriceService.set(baseFee: feeViewItemFactory.intValue(value: baseFee))
    }

    func set(tips: Float) {
        gasPriceService.set(tips: feeViewItemFactory.intValue(value: tips))
    }

    func reset() {
        gasPriceService.setRecommendedGasPrice()
    }
}

extension Eip1559EvmFeeViewModel: IFeeViewModel {
    var valueDriver: Driver<FeeCell.Value?> {
        valueRelay.asDriver()
    }

    var spinnerVisibleDriver: Driver<Bool> {
        spinnerVisibleRelay.asDriver()
    }
}
