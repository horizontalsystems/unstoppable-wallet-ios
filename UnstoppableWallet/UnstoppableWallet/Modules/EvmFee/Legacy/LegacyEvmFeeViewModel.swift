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
        subscribe(disposeBag, gasPriceService.cautionsObservable) { [weak self] in self?.sync(errors: $0.errors, warnings: $0.warnings) }
    }

    private func sync(gasPriceStatus: DataStatus<EvmFeeModule.GasPrice>) {
        switch gasPriceStatus {
        case .completed(let gasPrice):
            if case .legacy(let legacyGasPrice) = gasPrice {

            }
        default: ()
        }
    }

    private func sync(errors: [EvmFeeModule.GasDataError], warnings: [EvmFeeModule.GasDataWarning]) {
        var cautions = [Caution]()

        for error in errors {
            switch error {
            case .insufficientBalance:
                cautions.append(Caution(text: "fee_settings.errors.insufficient_balance.info".localized(coinService.platformCoin.code), type: .error))
            default: ()
            }
        }

        for warning in warnings {
            switch warning {
            case .riskOfGettingStuck:
                cautions.append(Caution(text: "fee_settings.warnings.risk_of_getting_stuck.info", type: .warning))
            default: ()
            }
        }

        cautionsRelay.accept(cautions)
    }

    private func sync(transactionStatus: DataStatus<EvmFeeModule.Transaction>) {
        let maxFeeStatus: String

        switch transactionStatus {
        case .loading:
            maxFeeStatus = "action.loading".localized
        case .failed:
            maxFeeStatus = "n/a".localized
        case .completed(let transaction):
            maxFeeStatus = coinService.amountData(value: transaction.gasData.fee).formattedString
        }

        feeStatusRelay.accept(maxFeeStatus)
    }
}

extension LegacyEvmFeeViewModel {

}
