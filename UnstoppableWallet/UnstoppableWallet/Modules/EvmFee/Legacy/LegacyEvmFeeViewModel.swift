import RxSwift
import RxCocoa
import RxRelay
import EvmKit

class LegacyEvmFeeViewModel {
    private let disposeBag = DisposeBag()

    private let gasPriceService: LegacyGasPriceService
    private let feeService: IEvmFeeService
    private let coinService: CoinService
    private let feeViewItemFactory: FeeViewItemFactory
    private let cautionsFactory: SendEvmCautionsFactory

    private let resetButtonActiveRelay = BehaviorRelay<Bool>(value: false)
    private let valueRelay = BehaviorRelay<FeeCell.Value?>(value: nil)
    private let spinnerVisibleRelay = BehaviorRelay<Bool>(value: false)
    private let gasLimitRelay = BehaviorRelay<String>(value: "n/a")
    private let gasPriceRelay = BehaviorRelay<String>(value: "n/a")
    private let gasPriceSliderRelay = BehaviorRelay<FeeViewItem?>(value: nil)
    private let cautionRelay = BehaviorRelay<TitledCaution?>(value: nil)

    init(gasPriceService: LegacyGasPriceService, feeService: IEvmFeeService, coinService: CoinService, feeViewItemFactory: FeeViewItemFactory, cautionsFactory: SendEvmCautionsFactory) {
        self.gasPriceService = gasPriceService
        self.feeService = feeService
        self.coinService = coinService
        self.feeViewItemFactory = feeViewItemFactory
        self.cautionsFactory = cautionsFactory

        sync(transactionStatus: feeService.status)
        sync(gasPriceStatus: gasPriceService.status)
        sync(usingRecommended: gasPriceService.usingRecommended)

        subscribe(disposeBag, feeService.statusObservable) { [weak self] in self?.sync(transactionStatus: $0) }
        subscribe(disposeBag, gasPriceService.statusObservable) { [weak self] in self?.sync(gasPriceStatus: $0) }
        subscribe(disposeBag, gasPriceService.usingRecommendedObservable) { [weak self] in self?.sync(usingRecommended: $0) }
    }

    private func sync(gasPriceStatus: DataStatus<FallibleData<GasPrice>>) {
        if case .completed(let fallibleGasPrice) = gasPriceStatus, case .legacy(let gasPrice) = fallibleGasPrice.data {
            let feeStep = gasPriceService.recommendedGasPrice.significant(depth: FeeViewItemFactory.stepDepth)
            let viewItem = feeViewItemFactory.viewItem(value: gasPrice, step: feeStep, range: gasPriceService.gasPriceRange)
            gasPriceRelay.accept(viewItem.description)
            gasPriceSliderRelay.accept(viewItem)
        } else {
            gasPriceRelay.accept("n/a".localized)
            gasPriceSliderRelay.accept(nil)
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
        case .failed(let error):
            spinnerVisible = false
            maxFeeValue = FeeCell.Value(text: "n/a".localized, type: .error)
            gasLimit = "n/a".localized
            cautions = cautionsFactory.items(errors: [error], warnings: [], baseCoinService: coinService)
        case .completed(let fallibleTransaction):
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

    private func sync(usingRecommended: Bool) {
        resetButtonActiveRelay.accept(!usingRecommended)
    }

}

extension LegacyEvmFeeViewModel {

    var gasLimitDriver: Driver<String> {
        gasLimitRelay.asDriver()
    }

    var gasPriceDriver: Driver<String> {
        gasPriceRelay.asDriver()
    }

    var gasPriceSliderDriver: Driver<FeeViewItem?> {
        gasPriceSliderRelay.asDriver()
    }

    var cautionDriver: Driver<TitledCaution?> {
        cautionRelay.asDriver()
    }

    var resetButtonActiveDriver: Driver<Bool> {
        resetButtonActiveRelay.asDriver()
    }

    func set(value: Float) {
        gasPriceService.set(gasPrice: feeViewItemFactory.intValue(value: value))
    }

    func reset() {
        gasPriceService.setRecommendedGasPrice()
    }

}

extension LegacyEvmFeeViewModel: IFeeViewModel {

    var valueDriver: Driver<FeeCell.Value?> {
        valueRelay.asDriver()
    }

    var spinnerVisibleDriver: Driver<Bool> {
        spinnerVisibleRelay.asDriver()
    }

}
