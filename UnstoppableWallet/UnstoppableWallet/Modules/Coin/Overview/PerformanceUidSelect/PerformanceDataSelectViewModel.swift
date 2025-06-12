import Combine
import EvmKit
import Foundation
import HsExtensions
import MarketKit

class PerformanceDataSelectViewModel: ObservableObject {
    let coinCount = 3

    private let marketKit = App.shared.marketKit
    private let performanceDataManager = App.shared.performanceDataManager
    private let purchaseManager = App.shared.purchaseManager

    private var tasks = Set<AnyTask>()
    private var cancellables: [AnyCancellable] = []

    let timePeriods: [HsTimePeriod] = [.week1, .month1, .month3, .month6, .year1, .year3, .year5]

    @Published var searchText: String = "" {
        didSet {
            syncItems()
        }
    }

    private var internalItems: [Item] = [] {
        didSet {
            syncItems()
        }
    }

    @Published var items: [Item] = []

    @Published private(set) var selectedCoins = Set<PerformanceCoin>()
    @Published private(set) var firstPeriod: HsTimePeriod
    @Published private(set) var secondPeriod: HsTimePeriod

    private(set) var premiumEnabled: Bool

    init() {
        selectedCoins = Set(performanceDataManager.coins)
        let periods = performanceDataManager.periods
        if periods.count == 2 {
            firstPeriod = periods[0]
            secondPeriod = periods[1]
        } else {
            firstPeriod = PerformanceRow.defaultPeriods[0]
            secondPeriod = PerformanceRow.defaultPeriods[1]
        }

        premiumEnabled = purchaseManager.activated(.tokenInsights)
        purchaseManager.$activeFeatures
            .sink { [weak self] features in
                self?.premiumEnabled = features.contains(.tokenInsights)
            }
            .store(in: &cancellables)

        load()
    }

    func load() {
        do {
            let predefined: [Item] = [.gold, .sp500]
            let fullCoins = try marketKit
                .topFullCoins(limit: 100)
                .filter { coin in !predefined.map(\.uid).contains { coin.coin.uid == $0 } }

            internalItems = predefined + fullCoins.map { Item(uid: $0.coin.uid, code: $0.coin.code, title: $0.coin.name, image: .url($0.coin.imageUrl)) }
        } catch {
            internalItems = []
        }
    }

    func syncItems() {
        let text = searchText.trimmingCharacters(in: .whitespaces)

        guard !text.isEmpty else {
            items = internalItems
            return
        }

        items = internalItems.filter { item in
            item.code.localizedCaseInsensitiveContains(text) ||
                item.title.localizedCaseInsensitiveContains(text)
        }
    }
}

extension PerformanceDataSelectViewModel {
    func switchItem(uid: String, code: String) {
        if let coin = selectedCoins.first(where: { $0.uid == uid }) { // remove from array
            selectedCoins.remove(coin)
            return
        }

        if selectedCoins.count >= coinCount {
            HudHelper.instance.show(banner: .attention(string: "coin_overview.performance.only_3".localized))
        } else {
            selectedCoins.insert(PerformanceCoin(uid: uid, code: code))
        }
    }

    private func firstExcept(period: HsTimePeriod) -> HsTimePeriod {
        timePeriods.filter { $0 != period }.first ?? period
    }

    func setFirst(period: HsTimePeriod) {
        guard firstPeriod != period else {
            return
        }

        if secondPeriod == period {
            secondPeriod = firstExcept(period: period)
        }

        firstPeriod = period
    }

    func setSecond(period: HsTimePeriod) {
        guard secondPeriod != period else {
            return
        }

        if firstPeriod == period {
            firstPeriod = firstExcept(period: period)
        }

        secondPeriod = period
    }

    func setData() {
        guard selectedCoins.count == coinCount else {
            return
        }

        let sortedCoins = selectedCoins.sorted { lhs, rhs in
            let lhsIndex = internalItems.firstIndex(where: { $0.uid == lhs.uid }) ?? Int.max
            let rhsIndex = internalItems.firstIndex(where: { $0.uid == rhs.uid }) ?? Int.max
            return lhsIndex < rhsIndex
        }

        performanceDataManager.set(sortedCoins, [firstPeriod, secondPeriod])
    }
}

extension PerformanceDataSelectViewModel {
    enum ImageType: Equatable {
        case url(String)
        case local(String)

        static func == (lhs: Self, rhs: Self) -> Bool {
            switch (lhs, rhs) {
            case let (.url(lhsUrl), .url(rhsUrl)): return lhsUrl == rhsUrl
            case let (.local(lhsLocal), .local(rhsLocal)): return lhsLocal == rhsLocal
            default: return false
            }
        }
    }

    struct Item: Hashable {
        let uid: String
        let code: String
        let title: String
        let image: ImageType

        func hash(into hasher: inout Hasher) {
            hasher.combine(uid)
        }
    }
}

extension PerformanceDataSelectViewModel.Item {
    static let gold = Self(uid: PerformanceRow.gold.uid, code: PerformanceRow.gold.code, title: "Commodity", image: .local("gold_32"))
    static let sp500 = Self(uid: PerformanceRow.sp500.uid, code: PerformanceRow.sp500.code, title: "S&P 500", image: .local("sp500_32"))
}
