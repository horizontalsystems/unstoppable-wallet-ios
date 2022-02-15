import EthereumKit
import MarketKit
import RxSwift
import RxCocoa
import BigInt

class LegacyGasPriceService {
    private static let gasPriceSafeRangeBounds = RangeBounds(lower: .distance(1), upper: .distance(1))
    private static let gasPriceAvailableRangeBounds = RangeBounds(lower: .factor(0.6), upper: .factor(3))

    private var disposeBag = DisposeBag()

    private let evmKit: EthereumKit.Kit
    private let gasPriceProvider: LegacyGasPriceProvider
    private let minRecommendedGasPrice: Int?

    private var recommendedGasPrice: Int = 0
    private var legacyGasPrice: Int = 0 {
        didSet {
            sync()
        }
    }

    var usingRecommended = true { didSet { usingRecommendedRelay.accept(usingRecommended) } }
    private let usingRecommendedRelay = PublishRelay<Bool>()

    private let statusRelay = PublishRelay<DataStatus<FallibleData<GasPrice>>>()
    private(set) var status: DataStatus<FallibleData<GasPrice>> = .loading {
        didSet {
            statusRelay.accept(status)
        }
    }

    init(evmKit: EthereumKit.Kit, initialGasPrice: Int? = nil, minRecommendedGasPrice: Int? = nil) {
        self.evmKit = evmKit
        gasPriceProvider = LegacyGasPriceProvider(evmKit: evmKit)
        self.minRecommendedGasPrice = minRecommendedGasPrice

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

    var usingRecommendedObservable: Observable<Bool> {
        usingRecommendedRelay.asObservable()
    }

    func set(gasPrice: Int) {
        legacyGasPrice = gasPrice
        usingRecommended = false
    }

    func setRecommendedGasPrice() {
        disposeBag = DisposeBag()

        status = .loading

        gasPriceProvider.gasPriceSingle()
                .subscribe(
                        onSuccess: { [weak self] gasPrice in
                            self?.recommendedGasPrice = gasPrice
                            if let minRecommendedGasPrice = self?.minRecommendedGasPrice {
                                self?.recommendedGasPrice = max(gasPrice, minRecommendedGasPrice)
                            }
                            self?.legacyGasPrice = gasPrice
                            self?.usingRecommended = true
                        },
                        onError: { [weak self] error in
                            self?.status = .failed(error)
                        }
                )
                .disposed(by: disposeBag)
    }

}
