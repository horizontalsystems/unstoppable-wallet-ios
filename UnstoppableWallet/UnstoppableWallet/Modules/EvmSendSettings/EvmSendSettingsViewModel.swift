import RxSwift
import RxCocoa

class EvmSendSettingsViewModel {
    let service: EvmSendSettingsService
    let feeViewModel: IFeeViewModel
    let nonceViewModel: NonceViewModel

    private let disposeBag = DisposeBag()

    private let coinService: CoinService
    private let cautionsFactory: SendEvmCautionsFactory
    private let cautionRelay = BehaviorRelay<TitledCaution?>(value: nil)

    init(service: EvmSendSettingsService, feeViewModel: IFeeViewModel, nonceViewModel: NonceViewModel, cautionsFactory: SendEvmCautionsFactory) {
        self.service = service
        self.feeViewModel = feeViewModel
        self.nonceViewModel = nonceViewModel
        coinService = service.feeService.coinService
        self.cautionsFactory = cautionsFactory

        subscribe(disposeBag, service.statusObservable) { [weak self] in self?.sync(transactionStatus: $0) }
        sync(transactionStatus: service.status)
    }

    private func sync(transactionStatus: DataStatus<FallibleData<EvmSendSettingsService.Transaction>>) {
        let cautions: [TitledCaution]

        switch transactionStatus {
        case .loading:
            cautions = []
        case .failed(let error):
            cautions = cautionsFactory.items(errors: [error], warnings: [], baseCoinService: coinService)
        case .completed(let fallibleTransaction):
            cautions = cautionsFactory.items(errors: fallibleTransaction.errors, warnings: fallibleTransaction.warnings, baseCoinService: coinService)
        }

        cautionRelay.accept(cautions.first)
    }

}

extension EvmSendSettingsViewModel {

    var cautionDriver: Driver<TitledCaution?> {
        cautionRelay.asDriver()
    }

}
