import Combine
import HsExtensions
import MarketKit

class PerformanceDataManager {
    private let keyPerformanceCoinUids = "market-performance-coin-uids"
    private let keyPerformancePeriodsUids = "market-performance-periods"
    private let userDefaultsStorage: UserDefaultsStorage

    private let updatedSubject = PassthroughSubject<Void, Never>()

    @DistinctPublished var coins: [PerformanceCoin]
    @DistinctPublished var periods: [HsTimePeriod]

    init(userDefaultsStorage: UserDefaultsStorage) {
        self.userDefaultsStorage = userDefaultsStorage

        if let recentCoinsUidsRaw: String = userDefaultsStorage.value(for: keyPerformanceCoinUids) {
            let components = recentCoinsUidsRaw.components(separatedBy: ",")
            coins = components.chunks(2).compactMap { chunk in
                guard chunk.count == 2 else { return nil }
                return PerformanceCoin(uid: chunk[0], code: chunk[1])
            }
        } else {
            coins = PerformanceRow.defaultCoins
        }

        if let recentPeriodsRaw: String = userDefaultsStorage.value(for: keyPerformanceCoinUids) {
            let components = recentPeriodsRaw.components(separatedBy: ",")
            let periods = components.compactMap { HsTimePeriod(rawValue: $0) }

            self.periods = periods.count == 2 ? periods : PerformanceRow.defaultPeriods
        } else {
            periods = PerformanceRow.defaultPeriods
        }
    }
}

extension PerformanceDataManager {
    var updatedPublisher: AnyPublisher<Void, Never> {
        updatedSubject.eraseToAnyPublisher()
    }

    func set(_ coins: [PerformanceCoin], _ periods: [HsTimePeriod]) {
        guard !self.coins.elementsEqual(coins) || !self.periods.elementsEqual(periods) else {
            return
        }

        let flattenedArray = coins.flatMap { [$0.uid, $0.code] }
        userDefaultsStorage.set(value: flattenedArray.joined(separator: ","), for: keyPerformanceCoinUids)
        userDefaultsStorage.set(value: periods.map(\.rawValue).joined(separator: ","), for: keyPerformancePeriodsUids)

        self.coins = coins
        self.periods = periods

        updatedSubject.send()
    }
}

struct PerformanceCoin: Hashable {
    let uid: String
    let code: String

    func hash(into hasher: inout Hasher) {
        hasher.combine(uid)
    }
}
