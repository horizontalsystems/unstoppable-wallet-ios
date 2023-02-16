import Foundation
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

    private let alteredStateRelay = PublishRelay<Void>()
    private let valueRelay = BehaviorRelay<FeeCellNew.Value?>(value: nil)
    private let spinnerVisibleRelay = BehaviorRelay<Bool>(value: false)
    private let gasLimitRelay = BehaviorRelay<String>(value: "n/a")
    private let gasPriceRelay = BehaviorRelay<Decimal?>(value: nil)

    init(gasPriceService: LegacyGasPriceService, feeService: IEvmFeeService, coinService: CoinService, feeViewItemFactory: FeeViewItemFactory) {
        self.gasPriceService = gasPriceService
        self.feeService = feeService
        self.coinService = coinService
        self.feeViewItemFactory = feeViewItemFactory

        sync(transactionStatus: feeService.status)
        sync(gasPriceStatus: gasPriceService.status)
        sync(usingRecommended: gasPriceService.usingRecommended)

        subscribe(disposeBag, feeService.statusObservable) { [weak self] in self?.sync(transactionStatus: $0) }
        subscribe(disposeBag, gasPriceService.statusObservable) { [weak self] in self?.sync(gasPriceStatus: $0) }
        subscribe(disposeBag, gasPriceService.usingRecommendedObservable) { [weak self] in self?.sync(usingRecommended: $0) }
    }

    private func sync(gasPriceStatus: DataStatus<FallibleData<EvmFeeModule.GasPrices>>) {
        if case .completed(let fallibleGasPrice) = gasPriceStatus, case .legacy(let gasPrice) = fallibleGasPrice.data.userDefined {
            gasPriceRelay.accept(feeViewItemFactory.decimalValue(value: gasPrice))
        } else {
            gasPriceRelay.accept(nil)
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
        case .completed(let fallibleTransaction):
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

    private func sync(usingRecommended: Bool) {
        alteredStateRelay.accept(Void())
    }

}

extension LegacyEvmFeeViewModel {

    var altered: Bool {
        !gasPriceService.usingRecommended
    }

    var alteredStateSignal: Signal<Void> {
        alteredStateRelay.asSignal()
    }

    var gasLimitDriver: Driver<String> {
        gasLimitRelay.asDriver()
    }

    var gasPriceDriver: Driver<Decimal?> {
        gasPriceRelay.asDriver()
    }

    func set(value: Decimal) {
        gasPriceService.set(gasPrice: feeViewItemFactory.intValue(value: value))
    }

    func reset() {
        gasPriceService.setRecommendedGasPrice()
    }

}

extension LegacyEvmFeeViewModel: IFeeViewModelNew {

    var hasInformation: Bool {
        true
    }

    var valueDriver: Driver<FeeCellNew.Value?> {
        valueRelay.asDriver()
    }

    var spinnerVisibleDriver: Driver<Bool> {
        spinnerVisibleRelay.asDriver()
    }

}
