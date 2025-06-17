import Combine
import Foundation
import HsExtensions
import MarketKit

class MarketTvlViewModel: ObservableObject {
    private let marketKit = Core.shared.marketKit
    private let currencyManager = Core.shared.currencyManager

    private var cancellables = Set<AnyCancellable>()
    private var tasks = Set<AnyTask>()

    private var internalState: State = .loading {
        didSet {
            syncState()
        }
    }

    @Published var state: State = .loading

    var platforms: MarketTvlViewModel.Platforms = .all {
        didSet {
            stat(page: .globalMetricsTvlInDefi, event: .switchTvlChain(chain: platforms.statPlatform))
            syncState()
        }
    }

    var sortOrder: MarketModule.SortOrder = .desc {
        didSet {
            stat(page: .globalMetricsTvlInDefi, event: .toggleSortDirection)
            syncState()
        }
    }

    @Published var timePeriod: HsTimePeriod = .day1
    @Published var diffType: DiffType = .percent {
        didSet {
            stat(page: .globalMetricsTvlInDefi, event: .toggleTvlField(field: diffType.statField))
        }
    }

    init() {
        currencyManager.$baseCurrency
            .sink { [weak self] _ in
                self?.sync()
            }
            .store(in: &cancellables)

        sync()
    }

    private func syncState() {
        switch internalState {
        case .loading:
            state = .loading
        case let .loaded(defiCoins):
            let asc = sortOrder.isAsc
            let defiCoins = defiCoins
                .filter { defiCoin in
                    switch platforms {
                    case .all: return true
                    default: return defiCoin.chains.contains(platforms.chain)
                    }
                }
                .sorted { lhsDefiCoin, rhsDefiCoin in
                    let lhsTvl = tvl(defiCoin: lhsDefiCoin, platforms: platforms) ?? 0
                    let rhsTvl = tvl(defiCoin: rhsDefiCoin, platforms: platforms) ?? 0
                    return asc ? lhsTvl < rhsTvl : lhsTvl > rhsTvl
                }
            state = .loaded(defiCoins: defiCoins)
        case let .failed(error):
            state = .failed(error: error)
        }
    }

    private func tvl(defiCoin: DefiCoin, platforms: MarketTvlViewModel.Platforms) -> Decimal? {
        switch platforms {
        case .all: return defiCoin.tvl
        default: return defiCoin.chainTvls[platforms.chain]
        }
    }
}

extension MarketTvlViewModel {
    var currency: Currency {
        currencyManager.baseCurrency
    }

    func sync() {
        tasks = Set()

        if case .failed = internalState {
            internalState = .loading
        }

        Task { [weak self, marketKit, currency] in
            do {
                let defiCoins = try await marketKit.defiCoins(currencyCode: currency.code)

                await MainActor.run { [weak self] in
                    self?.internalState = .loaded(defiCoins: defiCoins)
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.internalState = .failed(error: error)
                }
            }
        }
        .store(in: &tasks)
    }

    func values(defiCoin: DefiCoin) -> (Decimal?, DiffText.Diff?) {
        var tvl: Decimal?
        let diff: DiffText.Diff?

        switch platforms {
        case .all:
            tvl = defiCoin.tvl

            let tvlChange: Decimal? = defiCoin.tvlChangeValue(timePeriod: timePeriod)

            switch diffType {
            case .percent: diff = tvlChange.map { .percent(value: $0) }
            case .currencyValue: diff = tvlChange.map { .change(value: $0 * defiCoin.tvl / 100, currency: currency) }
            }
        default:
            tvl = defiCoin.chainTvls[platforms.chain]
            diff = nil
        }

        return (tvl, diff)
    }
}

extension MarketTvlViewModel {
    enum State {
        case loading
        case loaded(defiCoins: [DefiCoin])
        case failed(error: Error)
    }

    enum Platforms: Int, CaseIterable {
        case all
        case ethereum
        case solana
        case binance
        case avalanche
        case terra
        case fantom
        case arbitrum
        case polygon

        var chain: String {
            switch self {
            case .all: return ""
            case .ethereum: return "Ethereum"
            case .solana: return "Solana"
            case .binance: return "Binance"
            case .avalanche: return "Avalanche"
            case .terra: return "Terra"
            case .fantom: return "Fantom"
            case .arbitrum: return "Arbitrum"
            case .polygon: return "Polygon"
            }
        }

        var title: String {
            switch self {
            case .all: return "market.tvl.platform_field.all".localized
            default: return chain
            }
        }
    }

    enum DiffType: Int, CaseIterable {
        case percent
        case currencyValue

        mutating func toggle() {
            switch self {
            case .percent: self = .currencyValue
            case .currencyValue: self = .percent
            }
        }
    }
}
