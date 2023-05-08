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
    private let valueRelay = BehaviorRelay<FeeCell.Value?>(value: nil)
    private let spinnerVisibleRelay = BehaviorRelay<Bool>(value: false)
    private let gasLimitRelay = BehaviorRelay<String>(value: "n/a")
    private let gasPriceRelay = BehaviorRelay<Decimal?>(value: nil)
    private let cautionTypeRelay = BehaviorRelay<CautionType?>(value: nil)

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
        let gasPriceStatus = gasPriceStatus
        let cautionType: CautionType?
        let gasPrice: Decimal?

        switch gasPriceStatus {
        case .loading:
            cautionType = nil
            gasPrice = nil
        case .failed(_):
            cautionType = .error
            gasPrice = nil
        case .completed(let fallibleGasPrice):
            if case .legacy(let _gasPrice) = fallibleGasPrice.data.userDefined {
                gasPrice = feeViewItemFactory.decimalValue(value: _gasPrice)
            } else {
                gasPrice = nil
            }

            cautionType = fallibleGasPrice.cautionType
        }

        cautionTypeRelay.accept(cautionType)
        gasPriceRelay.accept(gasPrice)
    }

    private func sync(transactionStatus: DataStatus<FallibleData<EvmFeeModule.Transaction>>) {
        let spinnerVisible: Bool
        let feeValue: FeeCell.Value?
        let gasLimit: String

        switch transactionStatus {
        case .loading:
            spinnerVisible = true
            feeValue = nil
            gasLimit = "n/a".localized
        case .failed(_):
            spinnerVisible = false
            feeValue = .error(text: "n/a".localized)
            gasLimit = "n/a".localized
        case .completed(let fallibleTransaction):
            spinnerVisible = false

            let gasData = fallibleTransaction.data.gasData
            let amountData = coinService.amountData(value: gasData.estimatedFee)
            let tilda = gasData.isSurcharged
            if fallibleTransaction.errors.isEmpty, let coinValue = amountData.coinValue.formattedFull {
                feeValue = .regular(
                        text: "\(tilda ? "~" : "")\(coinValue)",
                        secondaryText: amountData.currencyValue?.formattedFull.map { "\(tilda ? "~" : "")\($0)" }
                )
            } else {
                feeValue = .error(text: "n/a".localized)
            }

            gasLimit = gasData.limit.description
        }

        spinnerVisibleRelay.accept(spinnerVisible)
        valueRelay.accept(feeValue)
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

    var cautionTypeDriver: Driver<CautionType?> {
        cautionTypeRelay.asDriver()
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
