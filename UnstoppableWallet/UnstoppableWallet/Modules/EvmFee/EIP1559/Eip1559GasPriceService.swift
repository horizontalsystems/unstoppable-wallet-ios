import RxSwift
import RxRelay
import EthereumKit

class Eip1559GasPriceService {
    private static let feeHistoryBlocksCount = 10
    private static let feeHistoryRewardPercentile = [50]

    private static let baseFeeSafeRangeBounds = RangeBounds(lower: .distance(0), upper: .factor(1.1))
    private static let baseFeeAvailableRangeBounds = RangeBounds(lower: .factor(0.7), upper: .factor(3))
    private static let tipsSafeRangeBounds = RangeBounds(lower: .distance(1_000_000_000), upper: .distance(1_000_000_000))
    private static let tipsAvailableRangeBounds = RangeBounds(lower: .fixed(1_000_000_000), upper: .distance(5_000_000_000))

    private var disposeBag = DisposeBag()

    private let evmKit: EthereumKit.Kit
    private var feeHistoryProvider: EIP1559GasPriceProvider

    private var useRecommended = true
    private(set) var recommendedBaseFee = 0 { didSet { recommendedBaseFeeRelay.accept(recommendedBaseFee) } }
    private var recommendedTips = 0

    private(set) var baseFee: Int = 0
    private(set) var tips: Int = 0
    private(set) var baseFeeRange: ClosedRange<Int> = 0...0  { didSet { baseFeeRangeChangedRelay.accept(()) }}
    private(set) var tipsRange: ClosedRange<Int> = 0...0 { didSet { tipsRangeChangedRelay.accept(()) }}
    private(set) var status: DataStatus<FallibleData<GasPrice>> = .loading { didSet { statusRelay.accept(status) } }

    private let recommendedBaseFeeRelay = PublishRelay<Int>()
    private let baseFeeRangeChangedRelay = PublishRelay<Void>()
    private let tipsRangeChangedRelay = PublishRelay<Void>()
    private let statusRelay = PublishRelay<DataStatus<FallibleData<GasPrice>>>()

    init(evmKit: EthereumKit.Kit, initialMaxBaseFee: Int? = nil, initialMaxTips: Int? = nil) {
        self.evmKit = evmKit

        feeHistoryProvider = EIP1559GasPriceProvider(evmKit: evmKit)
        feeHistoryProvider.feeHistoryObservable(blocksCount: Self.feeHistoryBlocksCount, rewardPercentile: Self.feeHistoryRewardPercentile)
                .subscribe(onNext: { [weak self] history in
                    self?.handle(feeHistory: history)
                }, onError: { [weak self] error in
                    self?.status = .failed(error)
                })
                .disposed(by: disposeBag)

        if let maxBaseFee = initialMaxBaseFee, let maxTips = initialMaxTips {
            tips = maxTips
            baseFee = maxBaseFee - maxTips
            sync()
        } else {
            feeHistoryProvider.feeHistorySingle(blocksCount: Self.feeHistoryBlocksCount, rewardPercentile: Self.feeHistoryRewardPercentile)
                    .subscribe(onSuccess: { [weak self] history in
                        self?.handle(feeHistory: history)
                    }, onError: { [weak self] error in
                        self?.status = .failed(error)
                    })
                    .disposed(by: disposeBag)
        }
    }

    private func sync() {
        var warnings = [EvmFeeModule.GasDataWarning]()
        var errors = [EvmFeeModule.GasDataError]()

        let baseFeeSafeRange = Self.baseFeeSafeRangeBounds.range(around: recommendedBaseFee)
        let tipsSafeRange = Self.tipsSafeRangeBounds.range(around: recommendedTips)

        if baseFee < baseFeeSafeRange.lowerBound {
            errors.append(.lowBaseFee)
        }

        if baseFee > baseFeeSafeRange.upperBound {
            warnings.append(.overpricing)
        }

        if tips < tipsSafeRange.lowerBound {
            warnings.append(.riskOfGettingStuck)
        }

        if tips > tipsSafeRange.upperBound {
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
        recommendedTips = tipsConsidered.reduce(0, +) / tipsConsidered.count

        if !baseFeeRange.contains(recommendedBaseFee) {
            baseFeeRange = Self.baseFeeAvailableRangeBounds.range(around: recommendedBaseFee, containing: baseFee)
        }

        if !tipsRange.contains(recommendedTips) {
            tipsRange = Self.tipsAvailableRangeBounds.range(around: recommendedTips, containing: tips)
        }

        if useRecommended {
            baseFee = recommendedBaseFee
            tips = recommendedTips
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

    var baseFeeRangeChangedObservable: Observable<Void> {
        baseFeeRangeChangedRelay.asObservable()
    }

    var tipsRangeChangedObservable: Observable<Void> {
        tipsRangeChangedRelay.asObservable()
    }

    func set(baseFee: Int) {
        useRecommended = false
        self.baseFee = baseFee
        sync()
    }

    func set(tips: Int) {
        useRecommended = false
        self.tips = tips
        sync()
    }

    func setRecommendedGasPrice() {
        useRecommended = true
        baseFee = recommendedBaseFee
        tips = recommendedTips
        sync()
    }

}
