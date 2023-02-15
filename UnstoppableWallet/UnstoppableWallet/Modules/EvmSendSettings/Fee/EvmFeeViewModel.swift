import RxSwift
import RxRelay
import RxCocoa

class EvmFeeViewModel {
    let service: IEvmFeeService
    let gasPriceService: IGasPriceService
    let coinService: CoinService

    private let disposeBag = DisposeBag()

    private let valueRelay = BehaviorRelay<FeeCellNew.Value?>(value: nil)
    private let spinnerVisibleRelay = BehaviorRelay<Bool>(value: false)

    init(service: IEvmFeeService, gasPriceService: IGasPriceService, coinService: CoinService) {
        self.service = service
        self.coinService = coinService
        self.gasPriceService = gasPriceService

        sync(status: service.status)
        subscribe(disposeBag, service.statusObservable) { [weak self] in
            self?.sync(status: $0)
        }
    }

    private func sync(status: DataStatus<FallibleData<EvmFeeModule.Transaction>>) {
        let spinnerVisible: Bool
        let value: FeeCellNew.Value?

        switch status {
        case .loading:
            spinnerVisible = true
            value = nil
        case .failed:
            spinnerVisible = false

            value = .error(text: "n/a".localized)
        case .completed(let fallibleTransaction):
            spinnerVisible = false

            let amountData = coinService.amountData(value: fallibleTransaction.data.gasData.fee)

            if fallibleTransaction.errors.isEmpty, let coinValue = amountData.coinValue.formattedFull {
                value = .regular(text: coinValue, secondaryText: amountData.currencyValue?.formattedFull)
            } else {
                value = .error(text: "n/a".localized)
            }
        }

        spinnerVisibleRelay.accept(spinnerVisible)
        valueRelay.accept(value)
    }

}

extension EvmFeeViewModel: IFeeViewModelNew {

    var hasInformation: Bool {
        false
    }

    var valueDriver: Driver<FeeCellNew.Value?> {
        valueRelay.asDriver()
    }

    var spinnerVisibleDriver: Driver<Bool> {
        spinnerVisibleRelay.asDriver()
    }

}
