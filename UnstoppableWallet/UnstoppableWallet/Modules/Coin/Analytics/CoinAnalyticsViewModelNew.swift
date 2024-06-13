import Chart
import Combine
import Foundation
import HsExtensions
import MarketKit

class CoinAnalyticsViewModelNew: ObservableObject {
    let coin: Coin
    private let marketKit = App.shared.marketKit
    private let currencyManager = App.shared.currencyManager
    private var tasks = Set<AnyTask>()

    @Published private(set) var state: State = .loading

    private let isPurchased = true

    private let ratioFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.roundingMode = .halfUp
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    private let holderShareFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.roundingMode = .halfEven
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    init(coin: Coin) {
        self.coin = coin
    }

    private func handle(analytics: Analytics) async {
        let viewItem = viewItem(analytics: analytics)

        await MainActor.run { [weak self] in
            self?.state = .loaded(viewItem: viewItem)
        }
    }

    private func handle(analyticsPreview: AnalyticsPreview) async {
        let viewItem = previewViewItem(analyticsPreview: analyticsPreview)

        await MainActor.run { [weak self] in
            self?.state = .loaded(viewItem: viewItem)
        }
    }

    private func viewItem(analytics: Analytics) -> ViewItem {
        ViewItem(
            technicalAdvice: viewItem(technicalAdvice: analytics.technicalAdvice),
            cexVolume: rankCardViewItem(
                points: analytics.cexVolume?.aggregatedChartPoints.points,
                value: analytics.cexVolume?.aggregatedChartPoints.aggregatedValue,
                postfix: .currency,
                rank: analytics.cexVolume?.rank30d,
                rating: analytics.cexVolume?.rating
            ),
            dexVolume: rankCardViewItem(
                points: analytics.dexVolume?.aggregatedChartPoints.points,
                value: analytics.dexVolume?.aggregatedChartPoints.aggregatedValue,
                postfix: .currency,
                rank: analytics.dexVolume?.rank30d,
                rating: analytics.dexVolume?.rating
            ),
            dexLiquidity: rankCardViewItem(
                points: analytics.dexLiquidity?.chartPoints,
                value: analytics.dexLiquidity?.chartPoints.last?.value,
                postfix: .currency,
                rank: analytics.dexLiquidity?.rank,
                rating: analytics.dexLiquidity?.rating
            ),
            activeAddresses: activeAddressesViewItem(
                points: analytics.addresses?.chartPoints,
                value: analytics.addresses?.chartPoints.last?.value,
                count30d: analytics.addresses?.count30d,
                rank: analytics.addresses?.rank30d,
                rating: analytics.addresses?.rating
            ),
            transactionCount: transactionCountViewItem(
                points: analytics.transactions?.aggregatedChartPoints.points,
                value: analytics.transactions?.aggregatedChartPoints.aggregatedValue,
                volume: analytics.transactions?.volume30d,
                rank: analytics.transactions?.rank30d,
                rating: analytics.transactions?.rating
            ),
            holders: holdersViewItem(holderBlockchains: analytics.holders),
            holdersRank: analytics.holdersRank.map { .regular(value: rankString(value: $0)) },
            holdersRating: analytics.holdersRating.flatMap { CoinAnalyticsModule.Rating(rawValue: $0) }.map { .regular(value: $0) },
            tvl: tvlViewItem(
                points: analytics.tvl?.chartPoints,
                rank: analytics.tvl?.rank,
                ratio: analytics.tvl?.ratio,
                rating: analytics.tvl?.rating
            ),
            fee: valueRankViewItem(
                value: analytics.fee?.value30d,
                rank: analytics.fee?.rank30d,
                description: analytics.fee?.description
            ),
            revenue: valueRankViewItem(
                value: analytics.revenue?.value30d,
                rank: analytics.revenue?.rank30d,
                description: analytics.revenue?.description
            ),
            reports: analytics.reports
                .map { .regular(value: "\($0)") },
            investors: analytics.fundsInvested
                .flatMap { ValueFormatter.instance.formatShort(currency: currency, value: $0) }
                .map { .regular(value: $0) },
            treasuries: analytics.treasuries
                .flatMap { ValueFormatter.instance.formatShort(currency: currency, value: $0) }
                .map { .regular(value: $0) },
            audits: analytics.audits
                .map { .regular(value: $0) },
            issueBlockchains: analytics.issueBlockchains.flatMap { issueBlockchainViewItems(issueBlockchains: $0) }
        )
    }

    private func previewViewItem(analyticsPreview data: AnalyticsPreview) -> ViewItem {
        ViewItem(
            technicalAdvice: nil,
            cexVolume: data.cexVolume ? RankCardViewItem(chart: .preview, rank: data.cexVolumeRank30d ? .preview : nil, rating: data.cexVolumeRating ? .preview : nil) : nil,
            dexVolume: data.dexVolume ? RankCardViewItem(chart: .preview, rank: data.dexVolumeRank30d ? .preview : nil, rating: data.dexVolumeRating ? .preview : nil) : nil,
            dexLiquidity: data.dexLiquidity ? RankCardViewItem(chart: .preview, rank: data.dexLiquidityRank ? .preview : nil, rating: data.dexLiquidityRating ? .preview : nil) : nil,
            activeAddresses: data.addresses ? ActiveAddressesViewItem(chart: .preview, count30d: data.addressesCount30d ? .preview : nil, rank: data.addressesRank30d ? .preview : nil, rating: data.addressesRating ? .preview : nil) : nil,
            transactionCount: data.transactions ? TransactionCountViewItem(chart: .preview, volume: data.transactionsVolume30d ? .preview : nil, rank: data.transactionsRank30d ? .preview : nil, rating: data.transactionsRating ? .preview : nil) : nil,
            holders: data.holders ? .preview : nil,
            holdersRank: data.holdersRank ? .preview : nil,
            holdersRating: data.holdersRating ? .preview : nil,
            tvl: data.tvl ? TvlViewItem(chart: .preview, rank: data.tvlRank ? .preview : nil, ratio: data.tvlRatio ? .preview : nil, rating: data.tvlRating ? .preview : nil) : nil,
            fee: data.fee ? ValueRankViewItem(value: .preview, rank: data.feeRank30d ? .preview : nil, description: nil) : nil,
            revenue: data.revenue ? ValueRankViewItem(value: .preview, rank: data.revenueRank30d ? .preview : nil, description: nil) : nil,
            reports: data.reports ? .preview : nil,
            investors: data.fundsInvested ? .preview : nil,
            treasuries: data.treasuries ? .preview : nil,
            audits: nil,
            issueBlockchains: nil
        )
    }

    private func viewItem(technicalAdvice: TechnicalAdvice?) -> TechnicalAdviceViewItem? {
        guard let technicalAdvice, let advice = technicalAdvice.advice else {
            return nil
        }

        let details: [String?] = [technicalAdvice.mainAdvice, technicalAdvice.trendAdvice]

        return TechnicalAdviceViewItem(
            advice: advice,
            details: details.compactMap { $0 }.joined(separator: "\n\n")
        )
    }

    private func rankCardViewItem(points: [ChartPoint]?, value: Decimal?, postfix: ChartPreviewValuePostfix, rank: Int?, rating: String?) -> RankCardViewItem? {
        guard let points, let chartViewItem = chartViewItem(points: points, value: value, postfix: postfix) else {
            return nil
        }

        return RankCardViewItem(
            chart: .regular(value: chartViewItem),
            rank: rank.map { .regular(value: rankString(value: $0)) },
            rating: rating.flatMap { CoinAnalyticsModule.Rating(rawValue: $0) }.map { .regular(value: $0) }
        )
    }

    private func chartViewItem(points: [ChartPoint], value: Decimal? = nil, postfix: ChartPreviewValuePostfix) -> ChartViewItem? {
        guard let first = points.first, let last = points.last else {
            return nil
        }

        let chartItems = points.map {
            ChartItem(timestamp: $0.timestamp).added(name: ChartData.rate, value: $0.value)
        }

        let chartData = ChartData(items: chartItems, startWindow: first.timestamp, endWindow: last.timestamp)

        var valueString: String?

        if let value {
            switch postfix {
            case .currency: valueString = ValueFormatter.instance.formatShort(currency: currency, value: value)
            case .coin: valueString = ValueFormatter.instance.formatShort(value: value).map { [$0, coin.code].joined(separator: " ") }
            case .noPostfix: valueString = ValueFormatter.instance.formatShort(value: value)
            }
        }

        return ChartViewItem(
            value: valueString ?? "n/a".localized,
            chartData: chartData,
            chartTrend: first.value < last.value ? .up : .down
        )
    }

    private func activeAddressesViewItem(points: [ChartPoint]?, value: Decimal?, count30d: Int?, rank: Int?, rating: String?) -> ActiveAddressesViewItem? {
        guard let points, let chartViewItem = chartViewItem(points: points, value: value, postfix: .noPostfix) else {
            return nil
        }

        return ActiveAddressesViewItem(
            chart: .regular(value: chartViewItem),
            count30d: count30d.flatMap { ValueFormatter.instance.formatShort(value: Decimal($0)) }.map { .regular(value: $0) },
            rank: rank.map { .regular(value: rankString(value: $0)) },
            rating: rating.flatMap { CoinAnalyticsModule.Rating(rawValue: $0) }.map { .regular(value: $0) }
        )
    }

    private func transactionCountViewItem(points: [ChartPoint]?, value: Decimal?, volume: Decimal?, rank: Int?, rating: String?) -> TransactionCountViewItem? {
        guard let points, let chartViewItem = chartViewItem(points: points, value: value, postfix: .noPostfix) else {
            return nil
        }

        return TransactionCountViewItem(
            chart: .regular(value: chartViewItem),
            volume: volume.flatMap { ValueFormatter.instance.formatShort(value: $0) }.map { .regular(value: [$0, coin.code].joined(separator: " ")) },
            rank: rank.map { .regular(value: rankString(value: $0)) },
            rating: rating.flatMap { CoinAnalyticsModule.Rating(rawValue: $0) }.map { .regular(value: $0) }
        )
    }

    private func holdersViewItem(holderBlockchains: [Analytics.HolderBlockchain]?) -> Previewable<HoldersViewItem>? {
        struct Item {
            let blockchain: Blockchain
            let count: Decimal
        }

        guard let holderBlockchains else {
            return nil
        }

        let blockchains = blockchains(uids: holderBlockchains.filter { $0.holdersCount > 0 }.map(\.uid))

        let items = holderBlockchains.sorted { $0.holdersCount > $1.holdersCount }.compactMap { holderBlockchain -> Item? in
            guard let blockchain = blockchains.first(where: { $0.uid == holderBlockchain.uid }) else {
                return nil
            }

            return Item(blockchain: blockchain, count: holderBlockchain.holdersCount)
        }

        guard !items.isEmpty else {
            return nil
        }

        let total = items.map(\.count).reduce(0, +)

        let viewItem = HoldersViewItem(
            value: ValueFormatter.instance.formatShort(value: total),
            holderViewItems: items.map { item in
                let percent = item.count / total

                return HolderViewItem(
                    blockchain: item.blockchain,
                    value: holderShareFormatter.string(from: percent as NSNumber),
                    percent: percent
                )
            }
        )

        return .regular(value: viewItem)
    }

    private func tvlViewItem(points: [ChartPoint]?, rank: Int?, ratio: Decimal?, rating: String?) -> TvlViewItem? {
        guard let points, let chartViewItem = chartViewItem(points: points, value: points.last?.value, postfix: .currency) else {
            return nil
        }

        return TvlViewItem(
            chart: .regular(value: chartViewItem),
            rank: rank.map { .regular(value: rankString(value: $0)) },
            ratio: ratio.flatMap { ratioFormatter.string(from: $0 as NSNumber) }.map { .regular(value: $0) },
            rating: rating.flatMap { CoinAnalyticsModule.Rating(rawValue: $0) }.map { .regular(value: $0) }
        )
    }

    private func valueRankViewItem(value: Decimal?, rank: Int?, description: String?) -> ValueRankViewItem? {
        guard let value, let formattedValue = ValueFormatter.instance.formatShort(currency: currency, value: value) else {
            return nil
        }

        return ValueRankViewItem(
            value: .regular(value: formattedValue),
            rank: rank.map { .regular(value: rankString(value: $0)) },
            description: description
        )
    }

    private func issueBlockchainViewItems(issueBlockchains: [Analytics.IssueBlockchain]) -> [IssueBlockchainViewItem]? {
        let blockchains = blockchains(uids: issueBlockchains.map(\.blockchain))

        let viewItems: [IssueBlockchainViewItem] = issueBlockchains.compactMap { issueBlockchain -> IssueBlockchainViewItem? in
            guard let blockchain = blockchains.first(where: { $0.uid == issueBlockchain.blockchain }) else {
                return nil
            }

            let allItems = issueBlockchain.issues
                .map { issue in
                    IssueViewItem(
                        title: issue.title ?? issue.description ?? "",
                        description: issue.title != nil ? issue.description : nil,
                        level: .init(impact: issue.issues?.first?.impact),
                        type: issue.issue,
                        issues: issue.issues.map { $0.compactMap(\.description) } ?? []
                    )
                }
                .sorted { $0.level.rawValue < $1.level.rawValue }

            return IssueBlockchainViewItem(
                blockchain: blockchain,
                allItems: allItems,
                highRiskCount: allItems.filter { $0.level == .highRisk }.count,
                mediumRiskCount: allItems.filter { $0.level == .mediumRisk }.count,
                lowRiskCount: allItems.filter { $0.level == .attentionRequired || $0.level == .informational }.count,
                coreItems: allItems.filter { $0.type == "core" },
                generalItems: allItems.filter { $0.type == "general" }
            )
        }

        guard !viewItems.isEmpty else {
            return nil
        }

        return viewItems.sorted { $0.blockchain.type.order < $1.blockchain.type.order }
    }

    private func rankString(value: Int) -> String {
        "#\(value)"
    }

    private func blockchains(uids: [String]) -> [Blockchain] {
        do {
            return try marketKit.blockchains(uids: uids)
        } catch {
            return []
        }
    }
}

extension CoinAnalyticsViewModelNew {
    var currency: Currency {
        currencyManager.baseCurrency
    }

    func load() {
        tasks = Set()

        state = .loading

        Task { [weak self, isPurchased, marketKit, coin, currency] in
            do {
                if isPurchased {
                    let analytics = try await marketKit.analytics(coinUid: coin.uid, currencyCode: currency.code)
                    await self?.handle(analytics: analytics)
                } else {
                    let analyticsPreview = try await marketKit.analyticsPreview(coinUid: coin.uid)
                    await self?.handle(analyticsPreview: analyticsPreview)
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.state = .failed
                }
            }
        }
        .store(in: &tasks)
    }
}

extension CoinAnalyticsViewModelNew {
    enum State {
        case loading
        case loaded(viewItem: ViewItem)
        case failed
    }

    struct ViewItem {
        let technicalAdvice: TechnicalAdviceViewItem?
        let cexVolume: RankCardViewItem?
        let dexVolume: RankCardViewItem?
        let dexLiquidity: RankCardViewItem?
        let activeAddresses: ActiveAddressesViewItem?
        let transactionCount: TransactionCountViewItem?
        let holders: Previewable<HoldersViewItem>?
        let holdersRank: Previewable<String>?
        let holdersRating: Previewable<CoinAnalyticsModule.Rating>?
        let tvl: TvlViewItem?
        let fee: ValueRankViewItem?
        let revenue: ValueRankViewItem?
        let reports: Previewable<String>?
        let investors: Previewable<String>?
        let treasuries: Previewable<String>?
        let audits: Previewable<[Analytics.Audit]>?
        let issueBlockchains: [IssueBlockchainViewItem]?

        var isEmpty: Bool {
            let items: [Any?] = [technicalAdvice, cexVolume, dexVolume, dexLiquidity, activeAddresses, transactionCount, holders, tvl, revenue, reports, investors, treasuries]
            return items.compactMap { $0 }.isEmpty
        }
    }

    struct TechnicalAdviceViewItem {
        let advice: TechnicalAdvice.Advice
        let details: String
    }

    struct RankCardViewItem {
        let chart: Previewable<ChartViewItem>
        let rank: Previewable<String>?
        let rating: Previewable<CoinAnalyticsModule.Rating>?
    }

    struct ActiveAddressesViewItem {
        let chart: Previewable<ChartViewItem>
        let count30d: Previewable<String>?
        let rank: Previewable<String>?
        let rating: Previewable<CoinAnalyticsModule.Rating>?
    }

    struct TransactionCountViewItem {
        let chart: Previewable<ChartViewItem>
        let volume: Previewable<String>?
        let rank: Previewable<String>?
        let rating: Previewable<CoinAnalyticsModule.Rating>?
    }

    struct HoldersViewItem {
        let value: String?
        let holderViewItems: [HolderViewItem]
    }

    struct HolderViewItem {
        let blockchain: Blockchain
        let value: String?
        let percent: Decimal
    }

    struct TvlViewItem {
        let chart: Previewable<ChartViewItem>
        let rank: Previewable<String>?
        let ratio: Previewable<String>?
        let rating: Previewable<CoinAnalyticsModule.Rating>?
    }

    struct ValueRankViewItem {
        let value: Previewable<String>
        let rank: Previewable<String>?
        let description: String?
    }

    struct IssueBlockchainViewItem: Identifiable {
        let blockchain: Blockchain
        let allItems: [IssueViewItem]
        let highRiskCount: Int
        let mediumRiskCount: Int
        let lowRiskCount: Int
        let coreItems: [IssueViewItem]
        let generalItems: [IssueViewItem]

        var id: String {
            blockchain.uid
        }
    }

    struct IssueViewItem {
        let title: String
        let description: String?
        let level: Level
        let type: String?
        let issues: [String]

        enum Level: Int {
            case highRisk
            case mediumRisk
            case attentionRequired
            case informational
            case regular

            init(impact: String?) {
                switch impact {
                case "Critical", "High": self = .highRisk
                case "Medium": self = .mediumRisk
                case "Low": self = .attentionRequired
                case "Informational": self = .informational
                default: self = .regular
                }
            }
        }
    }

    struct ChartViewItem {
        let value: String
        let chartData: ChartData
        let chartTrend: MovementTrend
    }

    enum ChartPreviewValuePostfix {
        case currency
        case coin
        case noPostfix
    }
}
