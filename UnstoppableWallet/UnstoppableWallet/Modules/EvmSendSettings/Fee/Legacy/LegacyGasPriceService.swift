import BigInt
import EvmKit
import Foundation
import MarketKit
import RxCocoa
import RxSwift

class LegacyGasPriceService {
    private static let gasPriceSafeRangeBounds = RangeBounds(lower: .factor(0.9), upper: .factor(1.5))

    private var disposeBag = DisposeBag()

    private let evmKit: EvmKit.Kit
    private let gasPriceProvider: LegacyGasPriceProvider
    private let minRecommendedGasPrice: Int?

    private(set) var recommendedGasPrice: Int = 0
    private var legacyGasPrice: Int = 0 {
        didSet {
            sync()
        }
    }

    var usingRecommended = true { didSet { usingRecommendedRelay.accept(usingRecommended) } }
    private let usingRecommendedRelay = PublishRelay<Bool>()

    private let statusRelay = PublishRelay<DataStatus<FallibleData<EvmFeeModule.GasPrices>>>()
    private(set) var status: DataStatus<FallibleData<EvmFeeModule.GasPrices>> = .loading {
        didSet {
            statusRelay.accept(status)
        }
    }

    init(evmKit: EvmKit.Kit, initialGasPrice: Int? = nil, minRecommendedGasPrice: Int? = nil) {
        self.evmKit = evmKit
        gasPriceProvider = LegacyGasPriceProvider(evmKit: evmKit)
        self.minRecommendedGasPrice = minRecommendedGasPrice

        setRecommendedGasPrice(initialGasPrice: initialGasPrice)
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
                data: EvmFeeModule.GasPrices(
                        recommended: .legacy(gasPrice: recommendedGasPrice),
                        userDefined: .legacy(gasPrice: legacyGasPrice)
                ),
                errors: [], warnings: warnings
        ))
    }
}

extension LegacyGasPriceService: IGasPriceService {
    var statusObservable: Observable<DataStatus<FallibleData<EvmFeeModule.GasPrices>>> {
        statusRelay.asObservable()
    }
}

extension LegacyGasPriceService {

    var usingRecommendedObservable: Observable<Bool> {
        usingRecommendedRelay.asObservable()
    }

    func set(gasPrice: Int) {
        legacyGasPrice = gasPrice
        usingRecommended = false
    }

    func setRecommendedGasPrice(initialGasPrice: Int? = nil) {
        disposeBag = DisposeBag()

        status = .loading

        gasPriceProvider.gasPriceSingle()
            .subscribe(
                onSuccess: { [weak self] gasPrice in
                    self?.recommendedGasPrice = gasPrice
                    if let minRecommendedGasPrice = self?.minRecommendedGasPrice {
                        self?.recommendedGasPrice = max(gasPrice, minRecommendedGasPrice)
                    }
                    self?.legacyGasPrice = initialGasPrice ?? gasPrice
                    self?.usingRecommended = true
                },
                onError: { [weak self] error in
                    self?.status = .failed(error)
                }
            )
            .disposed(by: disposeBag)
    }

}
