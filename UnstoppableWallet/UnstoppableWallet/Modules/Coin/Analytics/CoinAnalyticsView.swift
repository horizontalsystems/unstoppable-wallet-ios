import Chart
import Kingfisher
import MarketKit
import SwiftUI

struct CoinAnalyticsView: View {
    private static let placeholderText = "•••"

    @ObservedObject var viewModel: CoinAnalyticsViewModel

    @State private var presentedInfo: Info?
    @State private var presentedRatingType: RatingType?
    @State private var presentedRankType: RankViewModel.RankType?
    @State private var presentedAnalysisViewItem: CoinAnalyticsViewModel.IssueBlockchainViewItem?
    @State private var presentedProChartType: CoinProChartModule.ProChartType?
    @State private var presentedHolderBlockchain: Blockchain?
    @State private var tvlRankPresented = false

    @State private var indicatorDetailsShown = false

    var body: some View {
        ThemeView {
            switch viewModel.state {
            case .loading:
                ProgressView()
            case let .loaded(analytics):
                content(viewItem: viewModel.viewItem(analytics))
            case .failed:
                SyncErrorView {
                    viewModel.load()
                }
            }
        }
    }

    @ViewBuilder private func content(viewItem: CoinAnalyticsViewModel.ViewItem) -> some View {
        ScrollView {
            VStack(spacing: .margin12) {
                if let viewItem = viewItem.technicalAdvice {
                    premium(technicalAdvice(viewItem: viewItem), statTrigger: .tradingAssistant)
                }

                if let viewItem = viewItem.cexVolume {
                    cexVolume(viewItem: viewItem)
                }

                if let viewItem = viewItem.tvl {
                    tvl(viewItem: viewItem)
                }

                if let viewItem = viewItem.dexVolume {
                    premium(dexVolume(viewItem: viewItem), statTrigger: .dexVolume)
                }

                if let viewItem = viewItem.dexLiquidity {
                    premium(dexLiquidity(viewItem: viewItem), statTrigger: .dexLiquidity)
                }

                if let viewItem = viewItem.activeAddresses {
                    premium(addresses(viewItem: viewItem), statTrigger: .activeAddresses)
                }

                if let viewItem = viewItem.transactionCount {
                    premium(transactionCount(viewItem: viewItem), statTrigger: .transactionCount)
                }

                if let holdersViewItem = viewItem.holders {
                    premium(holders(viewItem: holdersViewItem, rating: viewItem.holdersRating, rank: viewItem.holdersRank), statTrigger: .holders)
                }

                if let viewItem = viewItem.fee {
                    premium(fee(viewItem: viewItem), statTrigger: .projectFee)
                }

                if let viewItem = viewItem.revenue {
                    premium(revenue(viewItem: viewItem), statTrigger: .projectRevenue)
                }

                if let viewItems = viewItem.issueBlockchains {
                    premium(analysis(viewItems: viewItems), statTrigger: .issueBlockchains)
                }

                premium(otherData(reports: viewItem.reports, investors: viewItem.investors, treasuries: viewItem.treasuries, audits: viewItem.audits), statTrigger: .other)
            }
            .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
        }
        .sheet(item: $presentedInfo) { info in
            InfoView(items: info.items, isPresented: Binding(get: { presentedInfo != nil }, set: { if !$0 { presentedInfo = nil } }))
        }
        .sheet(item: $presentedRatingType) { type in
            CoinAnalyticsRatingInfoView(title: type.title, description: type.description, scores: type.scores, isPresented: Binding(get: { presentedRatingType != nil }, set: { if !$0 { presentedRatingType = nil } }))
        }
        .sheet(item: $presentedRankType) { type in
            RankView(type: type)
        }
        .sheet(item: $presentedAnalysisViewItem) { viewItem in
            CoinAnalyticsIssuesView(viewItem: viewItem, isPresented: Binding(get: { presentedAnalysisViewItem != nil }, set: { if !$0 { presentedAnalysisViewItem = nil } }))
        }
        .bottomSheet(item: $presentedProChartType) { type in
            CoinProChartView(coin: viewModel.coin, type: type, isPresented: Binding(get: { presentedProChartType != nil }, set: { if !$0 { presentedProChartType = nil } }))
        }
        .sheet(item: $presentedHolderBlockchain) { blockchain in
            CoinMajorHoldersView(coin: viewModel.coin, blockchain: blockchain, isPresented: Binding(get: { presentedHolderBlockchain != nil }, set: { if !$0 { presentedHolderBlockchain = nil } }))
        }
        .sheet(isPresented: $tvlRankPresented) {
            MarketTvlView()
        }
    }

    private func premium(_ content: some View, statTrigger: StatPremiumTrigger) -> some View {
        content
            .onTapGesture {
                if !viewModel.analyticsEnabled {
                    Coordinator.shared.presentPurchases()
                    stat(page: .coinAnalytics, event: .openPremium(from: statTrigger))
                }
            }
        // .allowsHitTesting(!viewModel.analyticsEnabled)
    }

    @ViewBuilder private func technicalAdvice(viewItem: CoinAnalyticsViewModel.TechnicalAdviceViewItem) -> some View {
        ListSection {
            ListRow {
                VStack(spacing: .margin12) {
                    cardHeader(
                        text: "coin_analytics.indicators.title".localized,
                        info: Info(
                            id: "indicators",
                            items: [
                                .header1(text: "coin_analytics.indicators.info.title".localized),
                                .text(text: "coin_analytics.indicators.info.description".localized),
                            ]
                        )
                    )

                    indicatorRow(advice: viewItem.advice)
                }
            }

            if viewItem.details != nil {
                ClickableRow {
                    withAnimation {
                        indicatorDetailsShown.toggle()
                    }
                } content: {
                    indicatorDetailsContent(details: viewItem.details)
                }
            } else {
                ListRow {
                    indicatorDetailsContent(details: nil)
                }
            }
        }
    }

    @ViewBuilder private func indicatorDetailsContent(details: String?) -> some View {
        VStack(spacing: .margin12) {
            HStack(spacing: .margin8) {
                Text("coin_analytics.indicators.details".localized).textBody()
                Spacer()
                Image(indicatorDetailsShown ? "arrow_big_up_20" : "arrow_big_down_20").themeIcon()
            }

            if let details, indicatorDetailsShown {
                Text(details).themeSubhead2(color: .themeBran)
            }

            Text("coin_analytics.indicators.disclaimer").themeCaption()
        }
    }

    @ViewBuilder private func cexVolume(viewItem: CoinAnalyticsViewModel.RankCardViewItem) -> some View {
        ListSection {
            chartRow(
                title: "coin_analytics.cex_volume".localized,
                info: Info(
                    id: "cex-volume",
                    items: [
                        .header1(text: "coin_analytics.cex_volume".localized),
                        .listItem(text: "coin_analytics.cex_volume.info1".localized),
                        .listItem(text: "coin_analytics.cex_volume.info2".localized),
                        .listItem(text: "coin_analytics.cex_volume.info3".localized),
                        .listItem(text: "coin_analytics.cex_volume.info4".localized),
                    ]
                ),
                premium: false,
                valueInfo: "coin_analytics.last_30d".localized,
                chartCurveType: .bars,
                proChartType: .cexVolume,
                viewItem: viewItem.chart
            )

            if let rating = viewItem.rating {
                ratingRow(rating: rating, type: .cexVolume)
            }

            if let rank = viewItem.rank {
                previewableRow(
                    title: "coin_analytics.30_day_rank".localized,
                    value: rank,
                    action: rank.previewableValue { _ in { presentedRankType = .cexVolume }}
                )
            }
        }
    }

    @ViewBuilder private func dexVolume(viewItem: CoinAnalyticsViewModel.RankCardViewItem) -> some View {
        ListSection {
            chartRow(
                title: "coin_analytics.dex_volume".localized,
                info: Info(
                    id: "dex-volume",
                    items: [
                        .header1(text: "coin_analytics.dex_volume".localized),
                        .listItem(text: "coin_analytics.dex_volume.info1".localized),
                        .listItem(text: "coin_analytics.dex_volume.info2".localized),
                        .listItem(text: "coin_analytics.dex_volume.info3".localized),
                        .listItem(text: "coin_analytics.dex_volume.info4".localized),
                        .text(text: "coin_analytics.dex_volume.tracked_dexes".localized),
                        .listItem(text: "coin_analytics.dex_volume.tracked_dexes.info1".localized),
                        .listItem(text: "coin_analytics.dex_volume.tracked_dexes.info2".localized),
                    ]
                ),
                valueInfo: "coin_analytics.last_30d".localized,
                chartCurveType: .bars,
                proChartType: .dexVolume,
                viewItem: viewItem.chart
            )

            if let rating = viewItem.rating {
                ratingRow(rating: rating, type: .dexVolume)
            }

            if let rank = viewItem.rank {
                previewableRow(
                    title: "coin_analytics.30_day_rank".localized,
                    value: rank,
                    action: rank.previewableValue { _ in { presentedRankType = .dexVolume }}
                )
            }
        }
    }

    @ViewBuilder private func tvl(viewItem: CoinAnalyticsViewModel.TvlViewItem) -> some View {
        ListSection {
            chartRow(
                title: "coin_analytics.project_tvl".localized,
                info: Info(
                    id: "tvl",
                    items: [
                        .header1(text: "coin_analytics.project_tvl.info_title".localized),
                        .listItem(text: "coin_analytics.project_tvl.info1".localized),
                        .listItem(text: "coin_analytics.project_tvl.info2".localized),
                        .listItem(text: "coin_analytics.project_tvl.info3".localized),
                        .listItem(text: "coin_analytics.project_tvl.info4".localized),
                        .listItem(text: "coin_analytics.project_tvl.info5".localized),
                    ]
                ),
                premium: false,
                valueInfo: "coin_analytics.current".localized,
                chartCurveType: .line,
                proChartType: .tvl,
                viewItem: viewItem.chart
            )

            if let rating = viewItem.rating {
                ratingRow(rating: rating, type: .tvl)
            }

            if let rank = viewItem.rank {
                previewableRow(
                    title: "coin_analytics.rank".localized,
                    value: rank,
                    action: rank.previewableValue { _ in { tvlRankPresented = true }}
                )
            }

            if let ratio = viewItem.ratio {
                previewableRow(title: "coin_analytics.tvl_ratio".localized, value: ratio)
            }
        }
    }

    @ViewBuilder private func dexLiquidity(viewItem: CoinAnalyticsViewModel.RankCardViewItem) -> some View {
        ListSection {
            chartRow(
                title: "coin_analytics.dex_liquidity".localized,
                info: Info(
                    id: "dex-liquidity",
                    items: [
                        .header1(text: "coin_analytics.dex_liquidity".localized),
                        .listItem(text: "coin_analytics.dex_liquidity.info1".localized),
                        .listItem(text: "coin_analytics.dex_liquidity.info2".localized),
                        .listItem(text: "coin_analytics.dex_liquidity.info3".localized),
                        .text(text: "coin_analytics.dex_liquidity.tracked_dexes".localized),
                        .listItem(text: "coin_analytics.dex_liquidity.tracked_dexes.info1".localized),
                        .listItem(text: "coin_analytics.dex_liquidity.tracked_dexes.info2".localized),
                    ]
                ),
                valueInfo: "coin_analytics.current".localized,
                chartCurveType: .line,
                proChartType: .dexLiquidity,
                viewItem: viewItem.chart
            )

            if let rating = viewItem.rating {
                ratingRow(rating: rating, type: .dexLiquidity)
            }

            if let rank = viewItem.rank {
                previewableRow(
                    title: "coin_analytics.rank".localized,
                    value: rank,
                    action: rank.previewableValue { _ in { presentedRankType = .dexLiquidity }}
                )
            }
        }
    }

    @ViewBuilder private func addresses(viewItem: CoinAnalyticsViewModel.ActiveAddressesViewItem) -> some View {
        ListSection {
            chartRow(
                title: "coin_analytics.active_addresses".localized,
                info: Info(
                    id: "addresses",
                    items: [
                        .header1(text: "coin_analytics.active_addresses".localized),
                        .listItem(text: "coin_analytics.active_addresses.info1".localized),
                        .listItem(text: "coin_analytics.active_addresses.info2".localized),
                        .listItem(text: "coin_analytics.active_addresses.info3".localized),
                        .listItem(text: "coin_analytics.active_addresses.info4".localized),
                        .listItem(text: "coin_analytics.active_addresses.info5".localized),
                    ]
                ),
                valueInfo: "coin_analytics.current".localized,
                chartCurveType: .line,
                proChartType: .activeAddresses,
                viewItem: viewItem.chart
            )

            if let rating = viewItem.rating {
                ratingRow(rating: rating, type: .activeAddresses)
            }

            if let count30d = viewItem.count30d {
                previewableRow(
                    title: "coin_analytics.active_addresses.30_day_unique_addresses".localized,
                    value: count30d
                )
            }

            if let rank = viewItem.rank {
                previewableRow(
                    title: "coin_analytics.30_day_rank".localized,
                    value: rank,
                    action: rank.previewableValue { _ in { presentedRankType = .address }}
                )
            }
        }
    }

    @ViewBuilder private func transactionCount(viewItem: CoinAnalyticsViewModel.TransactionCountViewItem) -> some View {
        ListSection {
            chartRow(
                title: "coin_analytics.transaction_count".localized,
                info: Info(
                    id: "transaction-count",
                    items: [
                        .header1(text: "coin_analytics.transaction_count".localized),
                        .listItem(text: "coin_analytics.transaction_count.info1".localized),
                        .listItem(text: "coin_analytics.transaction_count.info2".localized),
                        .listItem(text: "coin_analytics.transaction_count.info3".localized),
                        .listItem(text: "coin_analytics.transaction_count.info4".localized),
                        .listItem(text: "coin_analytics.transaction_count.info5".localized),
                    ]
                ),
                valueInfo: "coin_analytics.last_30d".localized,
                chartCurveType: .bars,
                proChartType: .txCount,
                viewItem: viewItem.chart
            )

            if let rating = viewItem.rating {
                ratingRow(rating: rating, type: .transactionCount)
            }

            if let volume = viewItem.volume {
                previewableRow(
                    title: "coin_analytics.30_day_volume".localized,
                    value: volume
                )
            }

            if let rank = viewItem.rank {
                previewableRow(
                    title: "coin_analytics.30_day_rank".localized,
                    value: rank,
                    action: rank.previewableValue { _ in { presentedRankType = .txCount }}
                )
            }
        }
    }

    @ViewBuilder private func holders(viewItem: Previewable<CoinAnalyticsViewModel.HoldersViewItem>, rating: Previewable<CoinAnalyticsModule.Rating>?, rank: Previewable<String>?) -> some View {
        ListSection {
            ListRow {
                VStack(spacing: .margin12) {
                    cardHeader(
                        text: "coin_analytics.holders".localized,
                        info: .init(
                            id: "holders",
                            items: [
                                .header1(text: "coin_analytics.holders".localized),
                                .listItem(text: "coin_analytics.holders.info1".localized),
                                .listItem(text: "coin_analytics.holders.info2".localized),
                                .text(text: "coin_analytics.holders.tracked_blockchains".localized),
                            ]
                        )
                    )

                    let value: String? = {
                        switch viewItem {
                        case .preview: return Self.placeholderText
                        case let .regular(viewItem): return viewItem.value
                        }
                    }()

                    if let value {
                        cardValue(text: value, info: viewItem.isPreview ? nil : "coin_analytics.current".localized)
                    }

                    let chartItems: [(Decimal, Color)] = {
                        switch viewItem {
                        case .preview: return [
                                (0.5, Color.themeGray.opacity(0.8)),
                                (0.35, Color.themeGray.opacity(0.6)),
                                (0.15, Color.themeGray.opacity(0.4)),
                            ]
                        case let .regular(viewItem):
                            var alpha: Double = 1
                            return viewItem.holderViewItems.map { viewItem in
                                let resolvedColor: Color

                                if let color = viewItem.blockchain.type.brandColorNew {
                                    resolvedColor = color
                                } else {
                                    resolvedColor = Color.themeJacob.opacity(alpha)
                                    alpha = max(alpha - 0.25, 0.25)
                                }

                                return (viewItem.percent, resolvedColor)
                            }
                        }
                    }()

                    if !chartItems.isEmpty {
                        CoinHoldersChart(items: chartItems)
                    }
                }
            }

            if let rating {
                ratingRow(rating: rating, type: .holders)
            }

            let blockchainItems: [BlockchainItem] = {
                switch viewItem {
                case .preview: return [
                        BlockchainItem(blockchain: nil, name: "Blockchain 1", value: Self.placeholderText),
                        BlockchainItem(blockchain: nil, name: "Blockchain 2", value: Self.placeholderText),
                        BlockchainItem(blockchain: nil, name: "Blockchain 3", value: Self.placeholderText),
                    ]
                case let .regular(viewItem): return viewItem.holderViewItems.map { viewItem in
                        BlockchainItem(
                            blockchain: viewItem.blockchain,
                            name: viewItem.blockchain.name,
                            value: viewItem.value
                        )
                    }
                }
            }()

            ForEach(blockchainItems) { item in
                ClickableRow(spacing: .margin8) {
                    presentedHolderBlockchain = item.blockchain
                } content: {
                    HStack(spacing: .margin16) {
                        KFImage.url(item.blockchain.flatMap { URL(string: $0.type.imageUrl) })
                            .resizable()
                            .placeholder { RoundedRectangle(cornerRadius: .cornerRadius8).fill(Color.themeBlade) }
                            .clipShape(RoundedRectangle(cornerRadius: .cornerRadius8))
                            .frame(width: .iconSize32, height: .iconSize32)

                        Text(item.name).textSubhead2()
                    }

                    Spacer()

                    if let value = item.value {
                        Text(value).textSubhead1(color: .themeLeah)
                    }

                    Image.disclosureIcon
                }
                .allowsHitTesting(viewModel.analyticsEnabled)
            }

            if let rank {
                previewableRow(
                    title: "coin_analytics.holders_rank".localized,
                    value: rank,
                    action: rank.previewableValue { _ in { presentedRankType = .holders }}
                )
            }
        }
    }

    @ViewBuilder private func fee(viewItem: CoinAnalyticsViewModel.ValueRankViewItem) -> some View {
        valueRank(
            title: "coin_analytics.project_fee".localized,
            rankType: .fee,
            viewItem: viewItem
        )
    }

    @ViewBuilder private func revenue(viewItem: CoinAnalyticsViewModel.ValueRankViewItem) -> some View {
        valueRank(
            title: "coin_analytics.project_revenue".localized,
            rankType: .revenue,
            viewItem: viewItem
        )
    }

    @ViewBuilder private func analysis(viewItems: [CoinAnalyticsViewModel.IssueBlockchainViewItem]) -> some View {
        VStack(spacing: 0) {
            ListSection {
                ListRow {
                    cardHeader(text: "coin_analytics.analysis.title".localized)
                }

                ForEach(viewItems.indices, id: \.self) { index in
                    analysisRow(viewItem: viewItems[index])
                }
            }

            Text("coin_analytics.analysis.footer".localized)
                .themeSubhead2()
                .padding(.horizontal, .margin16)
                .padding(.vertical, .margin12)
        }
    }

    @ViewBuilder private func otherData(reports: Previewable<String>?, investors: Previewable<String>?, treasuries: Previewable<String>?, audits: Previewable<[Analytics.Audit]>?) -> some View {
        if reports != nil || investors != nil || treasuries != nil || audits != nil {
            VStack(spacing: 0) {
                header(text: "coin_analytics.other_data".localized)

                ListSection {
                    if let reports {
                        previewableLink(
                            title: "coin_analytics.reports".localized,
                            value: reports
                        ) {
                            CoinReportsView(coinUid: viewModel.coin.uid)
                        }
                    }

                    if let investors {
                        previewableLink(
                            title: "coin_analytics.funding".localized,
                            value: investors
                        ) {
                            CoinInvestorsView(coinUid: viewModel.coin.uid)
                        }
                    }

                    if let treasuries {
                        previewableLink(
                            title: "coin_analytics.treasuries".localized,
                            value: treasuries
                        ) {
                            CoinTreasuriesView(coin: viewModel.coin)
                        }
                    }

                    if let audits {
                        let title = "coin_analytics.audits".localized

                        switch audits {
                        case .preview:
                            ListRow(spacing: .margin8) {
                                rowContent(title: title)
                            }
                        case let .regular(audits):
                            NavigationLink {
                                CoinAuditsView(audits: audits)
                            } label: {
                                ListRow(spacing: .margin8) {
                                    rowContent(title: title, value: "\(audits.count)", hasAction: true)
                                }
                            }
                            .buttonStyle(RowButtonStyle())
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder private func analysisRow(viewItem: CoinAnalyticsViewModel.IssueBlockchainViewItem) -> some View {
        ClickableRow {
            presentedAnalysisViewItem = viewItem
        } content: {
            VStack(spacing: .margin12) {
                HStack(spacing: .margin8) {
                    HStack(spacing: .margin16) {
                        KFImage.url(URL(string: viewItem.blockchain.type.imageUrl))
                            .resizable()
                            .placeholder { RoundedRectangle(cornerRadius: .cornerRadius8).fill(Color.themeBlade) }
                            .clipShape(RoundedRectangle(cornerRadius: .cornerRadius8))
                            .frame(width: .iconSize32, height: .iconSize32)

                        Text(viewItem.blockchain.name).textBody()
                    }

                    Spacer()

                    Text("\(viewItem.allItems.count)").textSubhead1(color: .themeLeah)
                    Image.disclosureIcon
                }

                VStack(spacing: 0) {
                    if viewItem.highRiskCount > 0 {
                        analysisItemRow(title: "coin_analytics.analysis.high_risk_items".localized, count: viewItem.highRiskCount, color: .themeLucian)
                    }

                    if viewItem.mediumRiskCount > 0 {
                        analysisItemRow(title: "coin_analytics.analysis.medium_risk_items".localized, count: viewItem.mediumRiskCount, color: .themeJacob)
                    }

                    if viewItem.lowRiskCount > 0 {
                        analysisItemRow(title: "coin_analytics.analysis.attention_required".localized, count: viewItem.lowRiskCount, color: .themeRemus)
                    }
                }
            }
        }
    }

    @ViewBuilder private func analysisItemRow(title: String, count: Int, color: Color) -> some View {
        HStack(spacing: .margin8) {
            Text(title).textSubhead2()
            Spacer()
            Text("\(count)").textSubhead1(color: color)
        }
        .padding(.vertical, .margin4)
    }

    @ViewBuilder private func chartRow(title: String, info: Info? = nil, premium: Bool = true, valueInfo: String, chartCurveType: ChartConfiguration.CurveType, proChartType: CoinProChartModule.ProChartType, viewItem: Previewable<CoinAnalyticsViewModel.ChartViewItem>) -> some View {
        ListRow {
            VStack(spacing: .margin12) {
                cardHeader(text: title, info: info, premium: premium)

                let value: String = {
                    switch viewItem {
                    case .preview: return Self.placeholderText
                    case let .regular(viewItem): return viewItem.value
                    }
                }()

                cardValue(text: value, info: valueInfo)

                let chartData: ChartData = {
                    switch viewItem {
                    case .preview: return placeholderChartData()
                    case let .regular(viewItem): return viewItem.chartData
                    }
                }()

                let chartTrend: MovementTrend = {
                    switch viewItem {
                    case .preview: return .ignored
                    case let .regular(viewItem):
                        switch chartCurveType {
                        case .line: return viewItem.chartTrend
                        case .bars, .histogram: return .neutral
                        }
                    }
                }()

                let chartConfiguration: ChartConfiguration = {
                    switch chartCurveType {
                    case .line: return .previewChart
                    case .bars, .histogram: return .previewBarChart
                    }
                }()

                RateChartViewNew(configuration: chartConfiguration, trend: chartTrend, data: chartData)
                    .frame(maxWidth: .infinity)
                    .allowsHitTesting(!premium || viewModel.analyticsEnabled)
                    .onTapGesture {
                        presentedProChartType = proChartType
                    }
            }
        }
    }

    @ViewBuilder private func valueRank(title: String, rankType: RankViewModel.RankType, viewItem: CoinAnalyticsViewModel.ValueRankViewItem) -> some View {
        VStack(spacing: 0) {
            ListSection {
                ListRow {
                    VStack(spacing: .margin12) {
                        cardHeader(text: title)

                        let value: String = {
                            switch viewItem.value {
                            case .preview: return Self.placeholderText
                            case let .regular(value): return value
                            }
                        }()

                        let valueInfo: String? = {
                            switch viewItem.value {
                            case .preview: return nil
                            case .regular: return "coin_analytics.last_30d".localized
                            }
                        }()

                        cardValue(text: value, info: valueInfo)
                    }
                }

                if let rank = viewItem.rank {
                    previewableRow(
                        title: "coin_analytics.30_day_rank".localized,
                        value: rank,
                        action: rank.previewableValue { _ in { presentedRankType = rankType }}
                    )
                }
            }

            if let description = viewItem.description {
                Text(description)
                    .themeSubhead2()
                    .padding(.horizontal, .margin16)
                    .padding(.vertical, .margin12)
            }
        }
    }

    @ViewBuilder private func cardHeader(text: String, info: Info? = nil, premium: Bool = true) -> some View {
        HStack(alignment: .center, spacing: .margin8) {
            Text(text).textSubhead1()

            if let info {
                Button {
                    presentedInfo = info
                } label: {
                    Image("circle_information_20").themeIcon()
                }
                .tappablePadding(.margin12, onTap: {
                    presentedInfo = info
                })
            }

            Spacer()

            if !viewModel.analyticsEnabled, premium {
                Text("Premium")
                    .textMicroSB(color: .themeClaude)
                    .padding(.horizontal, .margin6)
                    .padding(.vertical, .margin2)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(hex: 0xFFD000), Color(hex: 0xFFA800)]),
                            startPoint: UnitPoint(x: -0.5181, y: 0.5),
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule(style: .continuous))
            }
        }
    }

    @ViewBuilder private func cardValue(text: String, info: String? = nil) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: .margin8) {
            Text(text).textHeadline1()

            if let info {
                Text(info).textSubhead1()
            }

            Spacer()
        }
    }

    @ViewBuilder private func header(text: String) -> some View {
        VStack(spacing: 0) {
            HorizontalDivider()
                .padding(.horizontal, -.margin16)

            Text(text)
                .themeBody()
                .padding(.horizontal, .margin16)
                .padding(.vertical, .margin12)
        }
    }

    @ViewBuilder private func indicatorRow(advice: Previewable<TechnicalAdvice.Advice>) -> some View {
        switch advice {
        case .preview:
            indicatorMeter(
                text: "",
                textColor: .clear,
                textBackground: .clear,
                currentIndex: nil
            )
            .padding(.vertical, .margin24)
        case let .regular(value: advice):
            indicatorMeter(
                text: advice.title,
                textColor: advice.foregroundColor,
                textBackground: advice.backgroundColor,
                currentIndex: meterIndex(advice: advice)
            )
            .padding(.vertical, .margin24)
        }
    }

    @ViewBuilder private func ratingRow(rating: Previewable<CoinAnalyticsModule.Rating>, type: RatingType) -> some View {
        ClickableRow(spacing: .margin8) {
            presentedRatingType = type
        } content: {
            Text("coin_analytics.overall_score".localized).textSubhead2()
            Image("circle_information_20").themeIcon()

            Spacer()

            switch rating {
            case .preview:
                Text(Self.placeholderText).textSubhead1()
            case let .regular(rating):
                Text(rating.title.uppercased()).textSubhead1(color: rating.colorNew)
                rating.imageNew
            }
        }
    }

    @ViewBuilder private func previewableRow(title: String, value: Previewable<String>? = nil, action: Previewable<() -> Void>? = nil) -> some View {
        let rowValue: String? = value.map {
            switch $0 {
            case .preview: return Self.placeholderText
            case let .regular(value): return value
            }
        }

        let rowAction: (() -> Void)? = action.flatMap {
            switch $0 {
            case .preview: return nil
            case let .regular(action): return action
            }
        }

        if let rowAction {
            ClickableRow(spacing: .margin8) {
                rowAction()
            } content: {
                rowContent(title: title, value: rowValue, hasAction: true)
            }
        } else {
            ListRow(spacing: .margin8) {
                rowContent(title: title, value: rowValue)
            }
        }
    }

    @ViewBuilder private func previewableLink(title: String, value: Previewable<String>, @ViewBuilder destination: () -> some View) -> some View {
        switch value {
        case .preview:
            ListRow(spacing: .margin8) {
                rowContent(title: title, value: Self.placeholderText)
            }
        case let .regular(value):
            NavigationLink(destination: destination) {
                ListRow(spacing: .margin8) {
                    rowContent(title: title, value: value, hasAction: true)
                }
            }
            .buttonStyle(RowButtonStyle())
        }
    }

    @ViewBuilder private func rowContent(title: String, value: String? = nil, hasAction: Bool = false) -> some View {
        Text(title).textSubhead2()

        Spacer()

        if let value {
            Text(value).textSubhead1(color: .themeLeah)
        }

        if hasAction {
            Image.disclosureIcon
        }
    }

    @ViewBuilder private func indicatorMeter(text: String, textColor: Color, textBackground: Color, currentIndex: Int? = nil) -> some View {
        GeometryReader { proxy in
            let size = proxy.size

            ZStack(alignment: .bottom) {
                LinearGradient(colors: currentIndex != nil ? [.themeLucian, .themeBlade, .themeRemus] : [.themeBlade], startPoint: .leading, endPoint: .trailing)
                    .mask {
                        ZStack {
                            ForEach(0 ... 30, id: \.self) { index in
                                let degree = CGFloat(index) * 6

                                Capsule()
                                    .frame(width: 20, height: 4)
                                    .offset(x: -(size.width - 20) / 2)
                                    .rotationEffect(.init(degrees: degree))
                            }
                        }
                        .frame(width: size.width, height: size.height, alignment: .bottom)
                        .padding(.bottom, 4)
                    }
                    .overlay {
                        ZStack {
                            Circle()
                                .trim(from: 0.5, to: 1.0)
                                .stroke(Color.themeBlade, lineWidth: 2)
                                .offset(y: (size.height / 2) - 4)
                                .frame(width: 180, height: 180)
                        }
                    }

                if let currentIndex {
                    ZStack {
                        CurrentCapsule()
                            .fill(Color.themeLeah)
                            .frame(width: 32, height: 8)
                            .offset(x: -(size.width - 32) / 2)
                            .rotationEffect(.init(degrees: Double(currentIndex) * 6))
                    }
                    .frame(width: size.width, height: size.height, alignment: .bottom)
                }

                Text(text)
                    .textCaptionSB(color: textColor)
                    .padding(.horizontal, .margin16)
                    .padding(.vertical, .margin8)
                    .background(Capsule(style: .continuous).fill(textBackground))
                    .padding(.bottom, .margin8)
            }
        }
        .frame(width: 240, height: 126)
    }

    private func value(previewableChartViewItem: Previewable<CoinAnalyticsViewModel.ChartViewItem>) -> String {
        switch previewableChartViewItem {
        case .preview: return Self.placeholderText
        case let .regular(viewItem): return viewItem.value
        }
    }

    private func placeholderChartData() -> ChartData {
        var chartItems = [ChartItem]()

        for i in 0 ..< 8 {
            let baseTimeStamp = TimeInterval(i) * 100
            let baseValue = Decimal(i) * 2

            chartItems.append(contentsOf: [
                ChartItem(timestamp: baseTimeStamp).added(name: ChartData.rate, value: baseValue + 2),
                ChartItem(timestamp: baseTimeStamp + 25).added(name: ChartData.rate, value: baseValue + 6),
                ChartItem(timestamp: baseTimeStamp + 50).added(name: ChartData.rate, value: baseValue),
                ChartItem(timestamp: baseTimeStamp + 75).added(name: ChartData.rate, value: baseValue + 9),
            ])
        }

        chartItems.append(
            ChartItem(timestamp: 800).added(name: ChartData.rate, value: 16)
        )

        return ChartData(items: chartItems, startWindow: 0, endWindow: 800)
    }

    private func meterIndex(advice: TechnicalAdvice.Advice) -> Int? {
        switch advice {
        case .strongSell: return 0
        case .sell: return 7
        case .neutral: return 15
        case .buy: return 23
        case .strongBuy: return 30
        default: return nil
        }
    }
}

extension CoinAnalyticsView {
    private struct CurrentCapsule: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.addArc(center: CGPoint(x: rect.maxX - rect.maxY / 2, y: rect.midY), radius: rect.maxY / 2, startAngle: .degrees(90), endAngle: .degrees(270), clockwise: true)
            path.addArc(center: CGPoint(x: rect.minX + rect.maxY / 4, y: rect.midY), radius: rect.maxY / 4, startAngle: .degrees(270), endAngle: .degrees(90), clockwise: true)
            return path
        }
    }
}

extension CoinAnalyticsView {
    struct Info: Identifiable {
        let id: String
        let items: [InfoView.Item]
    }

    enum RatingType: Identifiable {
        case cexVolume
        case dexVolume
        case tvl
        case dexLiquidity
        case activeAddresses
        case transactionCount
        case holders

        private static let currencyFormatter: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.maximumFractionDigits = 0
            formatter.minimumFractionDigits = 0
            formatter.currencySymbol = "$"
            formatter.internationalCurrencySymbol = "$"
            return formatter
        }()

        var id: Self {
            self
        }

        var title: String {
            switch self {
            case .cexVolume: return "coin_analytics.cex_volume".localized
            case .dexVolume: return "coin_analytics.dex_volume".localized
            case .tvl: return "coin_analytics.project_tvl".localized
            case .dexLiquidity: return "coin_analytics.dex_liquidity".localized
            case .activeAddresses: return "coin_analytics.active_addresses".localized
            case .transactionCount: return "coin_analytics.transaction_count".localized
            case .holders: return "coin_analytics.holders".localized
            }
        }

        var description: String {
            switch self {
            case .cexVolume: return "coin_analytics.overall_score.cex_volume".localized
            case .dexVolume: return "coin_analytics.overall_score.dex_volume".localized
            case .tvl: return "coin_analytics.overall_score.project_tvl".localized
            case .dexLiquidity: return "coin_analytics.overall_score.dex_liquidity".localized
            case .activeAddresses: return "coin_analytics.overall_score.active_addresses".localized
            case .transactionCount: return "coin_analytics.overall_score.transaction_count".localized
            case .holders: return "coin_analytics.overall_score.holders".localized
            }
        }

        var scores: [CoinAnalyticsModule.Rating: String] {
            switch self {
            case .cexVolume: return [
                    .excellent: "> \(formatUsd(value: 10, number: "number.million"))",
                    .good: "> \(formatUsd(value: 5, number: "number.million"))",
                    .fair: "> \(formatUsd(value: 1, number: "number.million"))",
                    .poor: "< \(formatUsd(value: 1, number: "number.million"))",
                ]
            case .dexVolume: return [
                    .excellent: "> \(formatUsd(value: 1, number: "number.million"))",
                    .good: "> \(formatUsd(value: 500, number: "number.thousand"))",
                    .fair: "> \(formatUsd(value: 100, number: "number.thousand"))",
                    .poor: "< \(formatUsd(value: 100, number: "number.thousand"))",
                ]
            case .tvl: return [
                    .excellent: "> \(formatUsd(value: 200, number: "number.million"))",
                    .good: "> \(formatUsd(value: 100, number: "number.million"))",
                    .fair: "> \(formatUsd(value: 50, number: "number.million"))",
                    .poor: "< \(formatUsd(value: 50, number: "number.million"))",
                ]
            case .dexLiquidity: return [
                    .excellent: "> \(formatUsd(value: 2, number: "number.million"))",
                    .good: "> \(formatUsd(value: 1, number: "number.million"))",
                    .fair: "> \(formatUsd(value: 500, number: "number.thousand"))",
                    .poor: "< \(formatUsd(value: 500, number: "number.thousand"))",
                ]
            case .activeAddresses: return [
                    .excellent: "> 500",
                    .good: "> 200",
                    .fair: "> 100",
                    .poor: "< 100",
                ]
            case .transactionCount: return [
                    .excellent: "> \("number.thousand".localized("10"))",
                    .good: "> \("number.thousand".localized("5"))",
                    .fair: "> \("number.thousand".localized("1"))",
                    .poor: "< \("number.thousand".localized("1"))",
                ]
            case .holders: return [
                    .excellent: "> \("number.thousand".localized("100"))",
                    .good: "> \("number.thousand".localized("50"))",
                    .fair: "> \("number.thousand".localized("30"))",
                    .poor: "< \("number.thousand".localized("30"))",
                ]
            }
        }

        private func formatUsd(value: Int, number: String) -> String {
            let string = Self.currencyFormatter.string(from: value as NSNumber) ?? ""
            return number.localized(string)
        }
    }

    struct BlockchainItem: Identifiable {
        let blockchain: Blockchain?
        let name: String
        let value: String?

        var id: String {
            blockchain?.uid ?? name
        }
    }
}
