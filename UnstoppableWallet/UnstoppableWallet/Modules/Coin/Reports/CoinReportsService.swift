import RxSwift
import RxRelay
import MarketKit
import HsExtensions

class CoinReportsService {
    private let coinUid: String
    private let marketKit: Kit
    private var tasks = Set<AnyTask>()

    private let stateRelay = PublishRelay<DataStatus<[CoinReport]>>()
    private(set) var state: DataStatus<[CoinReport]> = .loading {
        didSet {
            stateRelay.accept(state)
        }
    }

    init(coinUid: String, marketKit: Kit) {
        self.coinUid = coinUid
        self.marketKit = marketKit

        fetch()
    }

    private func fetch() {
        tasks = Set()

        if case .failed = state {
            state = .loading
        }

        Task { [weak self, marketKit, coinUid] in
            do {
                let reports = try await marketKit.coinReports(coinUid: coinUid)
                self?.state = .completed(reports)
            } catch {
                self?.state = .failed(error)
            }
        }.store(in: &tasks)
    }

}

extension CoinReportsService {

    var stateObservable: Observable<DataStatus<[CoinReport]>> {
        stateRelay.asObservable()
    }

    func refresh() {
        fetch()
    }

}
