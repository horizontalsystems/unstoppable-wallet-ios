import EthereumKit
import MarketKit
import RxSwift
import RxCocoa
import BigInt

class LegacyGasPriceService {
    private static let safeFeeDifference = 1
    private var disposeBag = DisposeBag()

    private let evmKit: EthereumKit.Kit
    private let feeRateProvider: ICustomRangedFeeRateProvider

    private var recommendedGasPrice: Int = 0
    private var legacyGasPrice: Int = 0 {
        didSet {
            sync()
        }
    }

    private let statusRelay = PublishRelay<DataStatus<FallibleData<EvmFeeModule.GasPrice>>>()
    private(set) var status: DataStatus<FallibleData<EvmFeeModule.GasPrice>> = .loading {
        didSet {
            statusRelay.accept(status)
        }
    }

    init(evmKit: EthereumKit.Kit, feeRateProvider: ICustomRangedFeeRateProvider, gasPrice: Int? = nil) {
        self.evmKit = evmKit
        self.feeRateProvider = feeRateProvider

        if let gasPrice = gasPrice {
            legacyGasPrice = gasPrice
        } else {
            setRecommendedGasPrice()
        }
    }

    private func sync() {
        var warnings = [EvmFeeModule.GasDataWarning]()

        if legacyGasPrice < recommendedGasPrice - Self.safeFeeDifference {
            warnings.append(.riskOfGettingStuck)
        }

        if legacyGasPrice > recommendedGasPrice + Self.safeFeeDifference {
            warnings.append(.overpricing)
        }

        status = .completed(FallibleData(
                data: .legacy(gasPrice: legacyGasPrice), errors: [], warnings: warnings
        ))
    }

}

extension LegacyGasPriceService {

    var statusObservable: Observable<DataStatus<FallibleData<EvmFeeModule.GasPrice>>> {
        statusRelay.asObservable()
    }

    public var gasPriceRange: ClosedRange<Int> {
        feeRateProvider.customFeeRange
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
