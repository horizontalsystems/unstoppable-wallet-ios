import RxSwift
import RxRelay
import RxCocoa
import HsExtensions

class FeeRateService {
    private var tasks = Set<AnyTask>()

    private let provider: IFeeRateProvider

    private(set) var recommendedFeeRate: Int = 0
    private var feeRate = 0 {
        didSet {
            status = .completed(feeRate)
        }
    }

    var usingRecommended = true { didSet { usingRecommendedRelay.accept(usingRecommended) } }
    private let usingRecommendedRelay = PublishRelay<Bool>()

    private let statusRelay = PublishRelay<DataStatus<Int>>()
    private(set) var status: DataStatus<Int> = .loading {
        didSet {
            statusRelay.accept(status)
        }
    }

    init(provider: IFeeRateProvider) {
        self.provider = provider

        setRecommendedFeeRate()
    }

}

extension FeeRateService {

    var statusObservable: Observable<DataStatus<Int>> {
        statusRelay.asObservable()
    }

    var usingRecommendedObservable: Observable<Bool> {
        usingRecommendedRelay.asObservable()
    }

    func set(feeRate: Int) {
        self.feeRate = feeRate
        usingRecommended = false
    }

    func setRecommendedFeeRate() {
        tasks = Set()

        status = .loading

        Task { [weak self, provider] in
            do {
                let feeRate = try await provider.recommendedFeeRate()

                self?.recommendedFeeRate = feeRate
                self?.feeRate = feeRate
                self?.usingRecommended = true
            } catch {
                self?.status = .failed(error)
            }
        }.store(in: &tasks)
    }

}
