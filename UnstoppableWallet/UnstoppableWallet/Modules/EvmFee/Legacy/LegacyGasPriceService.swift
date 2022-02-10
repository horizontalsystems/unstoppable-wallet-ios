import EthereumKit
import MarketKit
import RxSwift
import RxCocoa
import BigInt

class LegacyGasPriceService {
    private static let gasPriceSafeRangeBounds = RangeBounds(lower: .distance(1), upper: .distance(1))
    private static let gasPriceAvailableRangeBounds = RangeBounds(lower: .factor(0.7), upper: .factor(3))

    private var disposeBag = DisposeBag()

    private let evmKit: EthereumKit.Kit
    private let gasPriceProvider: LegacyGasPriceProvider


    private var recommendedGasPrice: Int = 0
    private var legacyGasPrice: Int = 0 {
        didSet {
            sync()
        }
    }

    private let statusRelay = PublishRelay<DataStatus<FallibleData<GasPrice>>>()
    private(set) var status: DataStatus<FallibleData<GasPrice>> = .loading {
        didSet {
            statusRelay.accept(status)
        }
    }

    init(evmKit: EthereumKit.Kit, initialGasPrice: Int? = nil) {
        self.evmKit = evmKit
        gasPriceProvider = LegacyGasPriceProvider(evmKit: evmKit)

        if let gasPrice = initialGasPrice {
            legacyGasPrice = gasPrice
        } else {
            setRecommendedGasPrice()
        }
    }

    private func sync() {
        var warnings = [EvmFeeModule.GasDataWarning]()

        let gasPriceSafeRange = Self.gasPriceSafeRangeBounds.range(around: recommendedGasPrice)

        if legacyGasPrice < gasPriceSafeRange.lowerBound {
            warnings.append(.riskOfGettingStuck)
        }

        if legacyGasPrice > gasPriceSafeRange.upperBound {
            warnings.append(.overpricing)
        }

        status = .completed(FallibleData(
                data: .legacy(gasPrice: legacyGasPrice), errors: [], warnings: warnings
        ))
    }

}

extension LegacyGasPriceService: IGasPriceService {

    var statusObservable: Observable<DataStatus<FallibleData<GasPrice>>> {
        statusRelay.asObservable()
    }

}

extension LegacyGasPriceService {

    var gasPriceRange: ClosedRange<Int> {
        Self.gasPriceAvailableRangeBounds.range(around: recommendedGasPrice)
    }

    func set(gasPrice: Int) {
        legacyGasPrice = gasPrice
    }

    func setRecommendedGasPrice() {
        disposeBag = DisposeBag()

        status = .loading

        gasPriceProvider.gasPriceSingle()
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
