import RxSwift
import RxRelay
import RxCocoa

class EvmFeeViewModel {
    let service: IEvmFeeService
    let coinService: CoinService

    private let disposeBag = DisposeBag()

    private let feeStatusRelay = BehaviorRelay<String?>(value: "")
    private let editButtonVisibleRelay = BehaviorRelay<Bool>(value: true)

    init(service: IEvmFeeService, coinService: CoinService) {
        self.service = service
        self.coinService = coinService

        sync(status: service.status)
        subscribe(disposeBag, service.statusObservable) { [weak self] in self?.sync(status: $0) }
    }

    private func sync(status: DataStatus<FallibleData<EvmFeeModule.Transaction>>) {
        feeStatusRelay.accept(feeStatus(transactionStatus: status))
    }

    private func feeStatus(transactionStatus: DataStatus<FallibleData<EvmFeeModule.Transaction>>) -> String {
        switch transactionStatus {
        case .loading:
            editButtonVisibleRelay.accept(false)
            return "action.loading".localized
        case .failed:
            editButtonVisibleRelay.accept(true)
            return "n/a".localized
        case .completed(let fallibleTransaction):
            editButtonVisibleRelay.accept(true)
            return coinService.amountData(value: fallibleTransaction.data.gasData.fee).formattedString
        }
    }

}

extension EvmFeeViewModel: IFeeViewModel {

    var maxFeeDriver: Driver<String?> {
        feeStatusRelay.asDriver()
    }

    var editButtonVisibleDriver: Driver<Bool> {
        editButtonVisibleRelay.asDriver()
    }

}
