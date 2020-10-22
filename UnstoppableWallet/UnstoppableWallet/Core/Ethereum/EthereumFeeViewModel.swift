import RxSwift
import RxRelay
import RxCocoa

class EthereumFeeViewModel {
    private let service: EthereumTransactionService
    private let coinService: EthereumCoinService

    private let disposeBag = DisposeBag()

    private let feeStatusRelay = BehaviorRelay<String>(value: "")

    init(service: EthereumTransactionService, coinService: EthereumCoinService) {
        self.service = service
        self.coinService = coinService

        sync(transactionStatus: service.transactionStatus)

        service.transactionStatusObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] transactionStatus in
                    self?.sync(transactionStatus: transactionStatus)
                })
                .disposed(by: disposeBag)
    }

    private func sync(transactionStatus: DataStatus<EthereumTransactionService.Transaction>) {
        feeStatusRelay.accept(feeStatus(transactionStatus: transactionStatus))
    }

    private func feeStatus(transactionStatus: DataStatus<EthereumTransactionService.Transaction>) -> String {
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

extension EthereumFeeViewModel {

    var feeStatusDriver: Driver<String> {
        feeStatusRelay.asDriver()
    }

    func set(gasPriceType: EthereumTransactionService.GasPriceType) {
        service.set(gasPriceType: gasPriceType)
    }

}
