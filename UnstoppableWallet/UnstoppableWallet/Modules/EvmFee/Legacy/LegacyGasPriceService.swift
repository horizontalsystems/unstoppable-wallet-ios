import EthereumKit
import MarketKit
import RxSwift
import RxCocoa
import BigInt

class LegacyGasPriceService {
    private var disposeBag = DisposeBag()

    private let evmKit: EthereumKit.Kit
    private let feeRateProvider: ICustomRangedFeeRateProvider

    private var recommendedGasPrice: Int = 0
    private var legacyGasPrice: Int = 0 {
        didSet {
            status = .completed(.legacy(gasPrice: legacyGasPrice))

            validate()
        }
    }

    private let statusRelay = PublishRelay<DataStatus<EvmFeeModule.GasPrice>>()
    private(set) var status: DataStatus<EvmFeeModule.GasPrice> = .loading {
        didSet {
            statusRelay.accept(status)
        }
    }

    private let cautionsSubject = PublishSubject<(errors: [EvmFeeModule.GasDataError], warnings: [EvmFeeModule.GasDataWarning])>()

    init(evmKit: EthereumKit.Kit, feeRateProvider: ICustomRangedFeeRateProvider, gasPrice: Int? = nil) {
        self.evmKit = evmKit
        self.feeRateProvider = feeRateProvider

        if let gasPrice = gasPrice {
            legacyGasPrice = gasPrice
        } else {
            setRecommendedGasPrice()
        }
    }

    private func validate() {
        var warnings = [EvmFeeModule.GasDataWarning]()

        if legacyGasPrice < recommendedGasPrice {
            warnings.append(.riskOfGettingStuck)
        }

        cautionsSubject.onNext((errors: [], warnings: warnings))
    }

}

extension LegacyGasPriceService {

    var gasPrice: EvmFeeModule.GasPrice {
        .legacy(gasPrice: legacyGasPrice)
    }

    var statusObservable: Observable<DataStatus<EvmFeeModule.GasPrice>> {
        statusRelay.asObservable()
    }

    var cautionsObservable: Observable<(errors: [EvmFeeModule.GasDataError], warnings: [EvmFeeModule.GasDataWarning])> {
        cautionsSubject.asObservable()
    }

    func setRecommendedGasPrice(gasPrice: Int) {
        recommendedGasPrice = gasPrice
    }

}

extension LegacyGasPriceService {

    func set(gasPrice: Int) {
        legacyGasPrice = gasPrice
    }

    func setRecommendedGasPrice() {
        disposeBag = DisposeBag()

        status = .loading

        feeRateProvider.feeRate(priority: .recommended)
                .subscribe(
                        onSuccess: { [weak self] gasPrice in
                            self?.recommendedGasPrice = gasPrice
                            self?.legacyGasPrice = gasPrice
                        },
                        onError: { [weak self] error in
                            self?.status = .failed(error)
                        }
                )
                .disposed(by: disposeBag)
    }

}
