import RxSwift
import RxRelay
import RxCocoa

class EvmFeeViewModel {
    let service: IEvmFeeService
    let gasPriceService: IGasPriceService
    let coinService: CoinService

    private let disposeBag = DisposeBag()

    private let valueRelay = BehaviorRelay<FeeCell.Value?>(value: nil)
    private let spinnerVisibleRelay = BehaviorRelay<Bool>(value: false)
    private let editButtonVisibleRelay = BehaviorRelay<Bool>(value: false)
    private let editButtonHighlightedRelay = BehaviorRelay<Bool>(value: false)

    init(service: IEvmFeeService, gasPriceService: IGasPriceService, coinService: CoinService) {
        self.service = service
        self.coinService = coinService
        self.gasPriceService = gasPriceService

        sync(status: service.status)
        subscribe(disposeBag, service.statusObservable) { [weak self] in self?.sync(status: $0) }
    }

    private func sync(status: DataStatus<FallibleData<EvmFeeModule.Transaction>>) {
        let editButtonVisible: Bool
        let editButtonHighlighted: Bool
        let spinnerVisible: Bool
        let value: FeeCell.Value?

        switch status {
        case .loading:
            editButtonVisible = false
            editButtonHighlighted = false
            spinnerVisible = true
            value = nil
        case .failed:
            editButtonVisible = true
            editButtonHighlighted = true
            spinnerVisible = false

            value = FeeCell.Value(text: "n/a".localized, type: .error)
        case .completed(let fallibleTransaction):
            editButtonVisible = true
            editButtonHighlighted = !fallibleTransaction.errors.isEmpty || !gasPriceService.usingRecommended
            spinnerVisible = false

            let valueType: FeeCell.ValueType = fallibleTransaction.errors.isEmpty ? .regular : .error
            value = FeeCell.Value(text: coinService.amountData(value: fallibleTransaction.data.gasData.fee).formattedString, type: valueType)
        }

        editButtonVisibleRelay.accept(editButtonVisible)
        editButtonHighlightedRelay.accept(editButtonHighlighted)
        spinnerVisibleRelay.accept(spinnerVisible)
        valueRelay.accept(value)
    }

    var valueDriver: Driver<FeeCell.Value?> {
        valueRelay.asDriver()
    }

    var spinnerVisibleDriver: Driver<Bool> {
        spinnerVisibleRelay.asDriver()
    }

    var editButtonVisibleDriver: Driver<Bool> {
        editButtonVisibleRelay.asDriver()
    }

    var editButtonHighlightedDriver: Driver<Bool> {
        editButtonHighlightedRelay.asDriver()
    }

}
