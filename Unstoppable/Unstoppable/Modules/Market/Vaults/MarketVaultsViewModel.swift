import Combine
import Foundation
import HsExtensions
import MarketKit

class MarketVaultsViewModel: ObservableObject {
    private let blockchainUids = [
        "arbitrum-one",
        "base",
        "berachain-bera",
        "binance-smart-chain",
        "celo",
        "ethereum",
        "gnosis",
        "optimistic-ethereum",
        "polygon-pos",
        "swellchain",
        "unichain",
        "world-chain",
    ]

    private let marketKit = Core.shared.marketKit
    private let currencyManager = Core.shared.currencyManager
    private let appManager = Core.shared.appManager
    private let purchaseManager = Core.shared.purchaseManager
    private var cancellables = Set<AnyCancellable>()
    private var tasks = Set<AnyTask>()

    @Published private(set) var premiumEnabled: Bool = false

    private var internalState: State = .loading {
        didSet {
            syncState()
        }
    }

    @Published var state: State = .loading

    var filter: Filter = .allAssets {
        didSet {
            stat(page: .markets, section: .vaults, event: .switchFilterType(type: filter.rawValue))
            syncState()
        }
    }

    var sortBy: SortBy = .highestApy {
        didSet {
            stat(page: .markets, section: .vaults, event: .switchSortType(sortType: sortBy.statSortType))
            syncState()
        }
    }

    var timePeriod: HsTimePeriod = .week1 {
        didSet {
            stat(page: .markets, section: .vaults, event: .switchPeriod(period: timePeriod.statPeriod))
            syncState()
        }
    }

    var blockchains: Set<Blockchain> = Set() {
        didSet {
            stat(page: .markets, section: .vaults, event: .switchBlockchains(uids: blockchains.map(\.uid)))
            syncState()
        }
    }

    let allBlockchains: [Blockchain]
    let blockchainMap: [String: Blockchain]

    init() {
        do {
            let blockchains = try marketKit.blockchains(uids: blockchainUids)
            allBlockchains = blockchainUids.compactMap { uid in blockchains.first { $0.uid == uid } }
            blockchainMap = Dictionary(uniqueKeysWithValues: blockchains.map { ($0.uid, $0) })
        } catch {
            allBlockchains = []
            blockchainMap = [:]
        }
    }

    private func syncVaults() {
        tasks = Set()

        Task { [weak self] in
            await self?._syncVaults()
        }.store(in: &tasks)
    }

    private func _syncVaults() async {
        if case .failed = state {
            await MainActor.run { [weak self] in
                self?.internalState = .loading
            }
        }

        do {
            let vaults = try await marketKit.vaults(currencyCode: currency.code)

            await MainActor.run { [weak self] in
                self?.internalState = .loaded(vaults: vaults)
            }
        } catch {
            await MainActor.run { [weak self] in
                self?.internalState = .failed(error: error)
            }
        }
    }

    private func syncState() {
        switch internalState {
        case .loading:
            state = .loading
        case let .loaded(vaults):
            var vaults = sorted(vaults: filtered(vaults: vaults))

            if !blockchains.isEmpty {
                let uids = blockchains.map(\.uid)
                vaults = vaults.filter { uids.contains($0.chain) }
            }

            state = .loaded(vaults: vaults)
        case let .failed(error):
            state = .failed(error: error)
        }
    }

    private func filtered(vaults: [Vault]) -> [Vault] {
        switch filter {
        case .allAssets: return vaults
        case .ethYield: return vaults.filter { $0.assetSymbol.lowercased().contains("eth") }
        case .usdYield: return vaults.filter { $0.assetSymbol.lowercased().contains("usd") }
        }
    }

    private func sorted(vaults: [Vault]) -> [Vault] {
        switch sortBy {
        case .highestApy: return vaults.sorted { $0.apy[timePeriod] ?? 0 > $1.apy[timePeriod] ?? 0 }
        case .highestTvl: return vaults.sorted { $0.tvl > $1.tvl }
        }
    }
}

extension MarketVaultsViewModel {
    var currency: Currency {
        currencyManager.baseCurrency
    }

    var timePeriods: [HsTimePeriod] {
        [.day1, .week1, .month1]
    }

    func load() {
        currencyManager.$baseCurrency
            .sink { [weak self] _ in self?.syncVaults() }
            .store(in: &cancellables)

        appManager.willEnterForegroundPublisher
            .sink { [weak self] in self?.syncVaults() }
            .store(in: &cancellables)

        purchaseManager.$activeFeatures
            .receive(on: DispatchQueue.main)
            .sink { [weak self] activeFeatures in
                self?.premiumEnabled = activeFeatures.contains(.tokenInsights)
            }
            .store(in: &cancellables)

        premiumEnabled = purchaseManager.activated(.tokenInsights)

        syncVaults()
    }

    func refresh() async {
        await _syncVaults()
    }
}

extension MarketVaultsViewModel {
    enum State {
        case loading
        case loaded(vaults: [Vault])
        case failed(error: Error)
    }

    enum Filter: String, CaseIterable {
        case allAssets
        case ethYield
        case usdYield

        var title: String {
            switch self {
            case .allAssets: return "market.vaults.filter.all_assets".localized
            case .ethYield: return "market.vaults.filter.eth_yield".localized
            case .usdYield: return "market.vaults.filter.usd_yield".localized
            }
        }
    }

    enum SortBy: String, CaseIterable {
        case highestApy
        case highestTvl

        var title: String {
            switch self {
            case .highestApy: return "market.vaults.sort.highest_apy".localized
            case .highestTvl: return "market.vaults.sort.highest_tvl".localized
            }
        }

        var shortTitle: String {
            switch self {
            case .highestApy: return "market.vaults.sort.highest_apy.short".localized
            case .highestTvl: return "market.vaults.sort.highest_tvl.short".localized
            }
        }
    }
}
