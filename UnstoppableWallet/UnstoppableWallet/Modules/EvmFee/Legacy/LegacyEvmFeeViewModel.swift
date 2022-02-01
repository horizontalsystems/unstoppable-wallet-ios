import RxSwift
import RxRelay

class LegacyEvmFeeViewModel {
    private let disposeBag = DisposeBag()

    private let gasPriceService: LegacyGasPriceService
    private let feeService: IEvmFeeService
    private let coinService: CoinService

    private let resetButtonActiveRelay = BehaviorRelay<Bool>(value: false)
    private let feeStatusRelay = BehaviorRelay<String?>(value: "")
    private let feeSliderRelay = BehaviorRelay<SendFeeSliderViewItem?>(value: nil)
    private let cautionsRelay = PublishRelay<[Caution]>()

    init(gasPriceService: LegacyGasPriceService, feeService: IEvmFeeService, coinService: CoinService) {
        self.gasPriceService = gasPriceService
        self.feeService = feeService
        self.coinService = coinService

        sync(transactionStatus: feeService.status)

        subscribe(disposeBag, feeService.statusObservable) { [weak self] in self?.sync(transactionStatus: $0) }
        subscribe(disposeBag, gasPriceService.statusObservable) { [weak self] in self?.sync(gasPriceStatus: $0) }
    }

    private func sync(gasPriceStatus: DataStatus<FallibleData<EvmFeeModule.GasPrice>>) {
        switch gasPriceStatus {
        case .completed(let fallibleGasPrice):
            var cautions = [Caution]()

            cautionsRelay.accept(cautions)
        default: ()
        }
    }

    private func sync(transactionStatus: DataStatus<FallibleData<EvmFeeModule.Transaction>>) {
        let maxFeeStatus: String

        switch transactionStatus {
        case .loading:
            maxFeeStatus = "action.loading".localized
        case .failed:
            maxFeeStatus = "n/a".localized
        case .completed(let fallibleTransaction):
            maxFeeStatus = coinService.amountData(value: fallibleTransaction.data.gasData.fee).formattedString
        }

        feeStatusRelay.accept(maxFeeStatus)
    }
}

extension LegacyEvmFeeViewModel {

}
