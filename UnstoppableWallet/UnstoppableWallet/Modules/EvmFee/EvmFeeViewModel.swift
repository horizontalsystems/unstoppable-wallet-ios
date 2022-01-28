import RxSwift
import RxRelay
import RxCocoa

class EvmFeeViewModel {
    private let customFeeUnit = "gwei"

    private let service: IEvmFeeService
    private let coinService: CoinService

    private let disposeBag = DisposeBag()

    private let feeStatusRelay = BehaviorRelay<String?>(value: "")

    init(service: IEvmFeeService, coinService: CoinService) {
        self.service = service
        self.coinService = coinService

        sync(status: service.status)
        subscribe(disposeBag, service.statusObservable) { [weak self] in self?.sync(status: $0) }
    }

    private func sync(status: DataStatus<EvmFeeModule.Transaction>) {
        feeStatusRelay.accept(feeStatus(transactionStatus: status))
    }

    private func feeStatus(transactionStatus: DataStatus<EvmFeeModule.Transaction>) -> String {
        switch transactionStatus {
        case .loading:
            return "action.loading".localized
        case .failed:
            return "n/a".localized
        case .completed(let transaction):
            return coinService.amountData(value: transaction.gasData.fee).formattedString
        }
    }

}

extension EvmFeeViewModel {

    var feeDriver: Driver<String?> {
        feeStatusRelay.asDriver()
    }

}
