import Foundation
import EvmKit
import RxRelay
import RxSwift

class Eip1559GasPriceService {
    private static let feeHistoryBlocksCount = 10
    private static let feeHistoryRewardPercentile = [50]

    private static let tipsSafeRangeBounds = RangeBounds(lower: .factor(0.9), upper: .factor(1.5))

    private var disposeBag = DisposeBag()

    private let evmKit: EvmKit.Kit
    private var feeHistoryProvider: EIP1559GasPriceProvider

    private let minRecommendedMaxFee: Int?
    private let minRecommendedTips: Int?
    private(set) var recommendedTips = 0
    var usingRecommended = true {
        didSet {
            usingRecommendedRelay.accept(usingRecommended)
        }
    }

    private(set) var recommendedMaxFee = 0 {
        didSet {
            recommendedMaxFeeRelay.accept(recommendedMaxFee)
        }
    }

    private(set) var maxFee: Int = 0
    private(set) var tips: Int = 0

    private(set) var status: DataStatus<FallibleData<EvmFeeModule.GasPrices>> = .loading {
        didSet {
            statusRelay.accept(status)
        }
    }

    private let recommendedMaxFeeRelay = PublishRelay<Int>()
    private let usingRecommendedRelay = PublishRelay<Bool>()
    private let baseFeeRangeChangedRelay = PublishRelay<Void>()
    private let tipsRangeChangedRelay = PublishRelay<Void>()
    private let statusRelay = PublishRelay<DataStatus<FallibleData<EvmFeeModule.GasPrices>>>()

    init(evmKit: EvmKit.Kit, initialMaxBaseFee: Int? = nil, initialMaxTips: Int? = nil, minRecommendedMaxFee: Int? = nil, minRecommendedTips: Int? = nil) {
        self.evmKit = evmKit
        self.minRecommendedMaxFee = minRecommendedMaxFee
        self.minRecommendedTips = minRecommendedTips

        feeHistoryProvider = EIP1559GasPriceProvider(evmKit: evmKit)
        evmKit.lastBlockHeightObservable
            .subscribe(onNext: { [weak self] _ in
                self?.updateFeeHistory()
            })
            .disposed(by: disposeBag)

        if let maxBaseFee = initialMaxBaseFee, let maxTips = initialMaxTips {
            usingRecommended = false
            tips = maxTips
            maxFee = maxBaseFee
        }

        updateFeeHistory()
    }

    private func updateFeeHistory() {
        feeHistoryProvider.feeHistorySingle(blocksCount: Self.feeHistoryBlocksCount, rewardPercentile: Self.feeHistoryRewardPercentile)
            .subscribe(onSuccess: { [weak self] history in
                self?.handle(feeHistory: history)
            }, onError: { [weak self] error in
                self?.status = .failed(error)
            })
            .disposed(by: disposeBag)
    }

    private func sync() {
        var warnings = [EvmFeeModule.GasDataWarning]()

        let recommendedBaseFee = recommendedMaxFee - recommendedTips
        let actualTips = min(maxFee - recommendedBaseFee, tips)
        let tipsSafeRange = Self.tipsSafeRangeBounds.range(around: recommendedTips)

        if actualTips < tipsSafeRange.lowerBound {
            warnings.append(.riskOfGettingStuck)
        }

        if actualTips > tipsSafeRange.upperBound {
            warnings.append(.overpricing)
        }

        status = .completed(FallibleData(
            data: EvmFeeModule.GasPrices(
                recommended: .eip1559(maxFeePerGas: recommendedMaxFee, maxPriorityFeePerGas: recommendedTips),
                userDefined: .eip1559(maxFeePerGas: maxFee, maxPriorityFeePerGas: tips)
            ),
            errors: [], warnings: warnings
        ))
    }

    private func handle(feeHistory: FeeHistory) {
        let tipsConsidered = feeHistory.reward.compactMap {
            $0.first
        }
        let baseFeesConsidered = feeHistory.baseFeePerGas.suffix(2)

        guard !baseFeesConsidered.isEmpty, !tipsConsidered.isEmpty else {
            status = .failed(EIP1559GasPriceProvider.FeeHistoryError.notAvailable)
            return
        }

        recommendedTips = tipsConsidered.reduce(0, +) / tipsConsidered.count
        if let minRecommendedTips = minRecommendedTips {
            recommendedTips = max(recommendedTips, minRecommendedTips)
        }

        recommendedMaxFee = baseFeesConsidered.max() ?? 0 + recommendedTips
        if let minRecommendedMaxFee = minRecommendedMaxFee {
            recommendedMaxFee = max(recommendedMaxFee, minRecommendedMaxFee)
        }

        if usingRecommended {
            maxFee = recommendedMaxFee
            tips = recommendedTips
        }

        sync()
    }
}

extension Eip1559GasPriceService: IGasPriceService {
    var statusObservable: Observable<DataStatus<FallibleData<EvmFeeModule.GasPrices>>> {
        statusRelay.asObservable()
    }
}

extension Eip1559GasPriceService {
    var recommendedBaseFeeObservable: Observable<Int> {
        recommendedMaxFeeRelay.asObservable()
    }

    var usingRecommendedObservable: Observable<Bool> {
        usingRecommendedRelay.asObservable()
    }

    var baseFeeRangeChangedObservable: Observable<Void> {
        baseFeeRangeChangedRelay.asObservable()
    }

    var tipsRangeChangedObservable: Observable<Void> {
        tipsRangeChangedRelay.asObservable()
    }

    func set(maxFee: Int) {
        self.maxFee = maxFee
        usingRecommended = false
        sync()
    }

    func set(tips: Int) {
        self.tips = tips
        usingRecommended = false
        sync()
    }

    func setRecommendedGasPrice() {
        maxFee = recommendedMaxFee
        tips = recommendedTips
        usingRecommended = true
        sync()
    }

}
