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

    private let alteredStateRelay = PublishRelay<Void>()
    private let valueRelay = BehaviorRelay<FeeCellNew.Value?>(value: nil)
    private let spinnerVisibleRelay = BehaviorRelay<Bool>(value: false)
    private let gasLimitRelay = BehaviorRelay<String>(value: "n/a")
    private let currentBaseFeeRelay = BehaviorRelay<String>(value: "n/a")
    private let maxGasPriceRelay = BehaviorRelay<Decimal?>(value: nil)
    private let tipsRelay = BehaviorRelay<Decimal?>(value: nil)

    init(gasPriceService: Eip1559GasPriceService, feeService: IEvmFeeService, coinService: CoinService, feeViewItemFactory: FeeViewItemFactory) {
        self.gasPriceService = gasPriceService
        self.feeService = feeService
        self.coinService = coinService
        self.feeViewItemFactory = feeViewItemFactory

        sync(transactionStatus: feeService.status)
        sync(gasPriceStatus: gasPriceService.status)
        sync(recommendedBaseFee: gasPriceService.recommendedMaxFee)
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
        let maxFeeValue: FeeCellNew.Value?
        let gasLimit: String

        switch transactionStatus {
        case .loading:
            spinnerVisible = true
            maxFeeValue = nil
            gasLimit = "n/a".localized
        case .failed(_):
            spinnerVisible = false
            maxFeeValue = .error(text: "n/a".localized)
            gasLimit = "n/a".localized
        case let .completed(fallibleTransaction):
            spinnerVisible = false

            let gasData = fallibleTransaction.data.gasData
            let amountData = coinService.amountData(value: gasData.fee)
            if fallibleTransaction.errors.isEmpty, let coinValue = amountData.coinValue.formattedFull {
                maxFeeValue = .regular(text: coinValue, secondaryText: amountData.currencyValue?.formattedFull)
            } else {
                maxFeeValue = .error(text: "n/a".localized)
            }
            gasLimit = gasData.limit.description
        }

        spinnerVisibleRelay.accept(spinnerVisible)
        valueRelay.accept(maxFeeValue)
        gasLimitRelay.accept(gasLimit)
    }

    private func sync(gasPriceStatus: DataStatus<FallibleData<EvmFeeModule.GasPrices>>?) {
        let gasPriceStatus = gasPriceStatus ?? gasPriceService.status

        guard case .completed = gasPriceStatus else {
            maxGasPriceRelay.accept(nil)
            tipsRelay.accept(nil)
            return
        }

        maxGasPriceRelay.accept(feeViewItemFactory.decimalValue(value: gasPriceService.maxFee))
        tipsRelay.accept(feeViewItemFactory.decimalValue(value: gasPriceService.tips))
    }

    private func sync(recommendedBaseFee: Int) {
        let baseStep = recommendedBaseFee.significant(depth: FeeViewItemFactory.stepDepth)
        currentBaseFeeRelay.accept(feeViewItemFactory.description(value: recommendedBaseFee, step: baseStep))
    }

    private func sync(usingRecommended: Bool) {
        alteredStateRelay.accept(Void())
    }

}

extension Eip1559EvmFeeViewModel {

    var altered: Bool {
        !gasPriceService.usingRecommended
    }

    var alteredStateSignal: Signal<Void> {
        alteredStateRelay.asSignal()
    }

    var gasLimitDriver: Driver<String> {
        gasLimitRelay.asDriver()
    }

    var currentBaseFeeDriver: Driver<String> {
        currentBaseFeeRelay.asDriver()
    }

    var maxGasPriceDriver: Driver<Decimal?> {
        maxGasPriceRelay.asDriver()
    }

    var tipsDriver: Driver<Decimal?> {
        tipsRelay.asDriver()
    }

    func set(maxGasPrice: Decimal) {
        gasPriceService.set(maxFee: feeViewItemFactory.intValue(value: maxGasPrice))
    }

    func set(tips: Decimal) {
        gasPriceService.set(tips: feeViewItemFactory.intValue(value: tips))
    }

    func reset() {
        gasPriceService.setRecommendedGasPrice()
    }
}

extension Eip1559EvmFeeViewModel: IFeeViewModelNew {

    var showInfoIcon: Bool {
        true
    }

    var valueDriver: Driver<FeeCellNew.Value?> {
        valueRelay.asDriver()
    }

    var spinnerVisibleDriver: Driver<Bool> {
        spinnerVisibleRelay.asDriver()
    }
}
