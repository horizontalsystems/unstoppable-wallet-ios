import RxSwift
import RxRelay
import EthereumKit

class Eip1559GasPriceService {
    private static let feeHistoryBlocksCount = 10
    private static let feeHistoryRewardPercentile = [50]

    private static let tipsSafeRangeBounds = RangeBounds(lower: .distance(2_000_000_000), upper: .distance(2_000_000_000))
    private static let baseFeeAvailableRangeBounds = RangeBounds(lower: .factor(0.5), upper: .factor(3))
    private static let tipsAvailableRangeBounds = RangeBounds(lower: .fixed(0), upper: .factor(10))

    private var disposeBag = DisposeBag()

    private let evmKit: EthereumKit.Kit
    private var feeHistoryProvider: EIP1559GasPriceProvider

    private let minRecommendedBaseFee: Int?
    private let minRecommendedTips: Int?
    private var recommendedTips = 0
    var usingRecommended = true { didSet { usingRecommendedRelay.accept(usingRecommended) } }

    private(set) var recommendedBaseFee = 0 { didSet { recommendedBaseFeeRelay.accept(recommendedBaseFee) } }
    private(set) var baseFee: Int = 0
    private(set) var tips: Int = 0
    private(set) var baseFeeRange: ClosedRange<Int> = 0...0  { didSet { baseFeeRangeChangedRelay.accept(()) }}
    private(set) var tipsRange: ClosedRange<Int> = 0...0 { didSet { tipsRangeChangedRelay.accept(()) }}
    private(set) var status: DataStatus<FallibleData<GasPrice>> = .loading { didSet { statusRelay.accept(status) } }

    private let recommendedBaseFeeRelay = PublishRelay<Int>()
    private let usingRecommendedRelay = PublishRelay<Bool>()
    private let baseFeeRangeChangedRelay = PublishRelay<Void>()
    private let tipsRangeChangedRelay = PublishRelay<Void>()
    private let statusRelay = PublishRelay<DataStatus<FallibleData<GasPrice>>>()

    init(evmKit: EthereumKit.Kit, initialMaxBaseFee: Int? = nil, initialMaxTips: Int? = nil, minRecommendedBaseFee: Int? = nil, minRecommendedTips: Int? = nil) {
        self.evmKit = evmKit
        self.minRecommendedBaseFee = minRecommendedBaseFee
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
            baseFee = maxBaseFee
            sync()
        } else {
            updateFeeHistory()
        }
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
        var errors = [EvmFeeModule.GasDataError]()

        // Here, `tips` is the actual tips miners get, if the transaction included in the next block.
        // We only check tips is within safe range. Because tips incentivizes miners, whereas baseFee doesn't depend on what user selects.
        let actualTips = min(baseFee + tips - recommendedBaseFee, tips)
        let tipsSafeRange = Self.tipsSafeRangeBounds.range(around: recommendedTips)

        if actualTips < 0 {
            errors.append(.lowMaxFee)
        } else if actualTips < tipsSafeRange.lowerBound {
            warnings.append(.riskOfGettingStuck)
        }

        if actualTips > tipsSafeRange.upperBound {
            warnings.append(.overpricing)
        }

        status = .completed(FallibleData(
                data: .eip1559(maxFeePerGas: baseFee + tips, maxPriorityFeePerGas: tips), errors: errors, warnings: warnings
        ))
    }

    private func handle(feeHistory: FeeHistory) {
        let tipsConsidered = feeHistory.reward.compactMap { $0.first }
        let baseFeesConsidered = feeHistory.baseFeePerGas.suffix(2)

        guard !baseFeesConsidered.isEmpty, !tipsConsidered.isEmpty else {
            status = .failed(EIP1559GasPriceProvider.FeeHistoryError.notAvailable)
            return
        }

        recommendedBaseFee = baseFeesConsidered.max() ?? 0
        if let minRecommendedBaseFee = minRecommendedBaseFee {
            recommendedBaseFee = max(recommendedBaseFee, minRecommendedBaseFee)
        }

        recommendedTips = tipsConsidered.reduce(0, +) / tipsConsidered.count
        if let minRecommendedTips = minRecommendedTips {
            recommendedTips = max(recommendedTips, minRecommendedTips)
        }

        if usingRecommended {
            baseFee = recommendedBaseFee
            tips = recommendedTips
        }

        if !baseFeeRange.contains(recommendedBaseFee) {
            baseFeeRange = Self.baseFeeAvailableRangeBounds.range(around: recommendedBaseFee, containing: baseFee)
        }

        if !tipsRange.contains(recommendedTips) {
            tipsRange = Self.tipsAvailableRangeBounds.range(around: recommendedTips, containing: tips)
        }

        sync()
    }

}

extension Eip1559GasPriceService: IGasPriceService {

    var statusObservable: Observable<DataStatus<FallibleData<GasPrice>>> {
        statusRelay.asObservable()
    }

}

extension Eip1559GasPriceService {

    var recommendedBaseFeeObservable: Observable<Int> {
        recommendedBaseFeeRelay.asObservable()
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

    func set(baseFee: Int) {
        self.baseFee = baseFee
        usingRecommended = false
        sync()
    }

    func set(tips: Int) {
        self.tips = tips
        usingRecommended = false
        sync()
    }

    func setRecommendedGasPrice() {
        baseFee = recommendedBaseFee
        tips = recommendedTips
        usingRecommended = true
        sync()
    }

}
