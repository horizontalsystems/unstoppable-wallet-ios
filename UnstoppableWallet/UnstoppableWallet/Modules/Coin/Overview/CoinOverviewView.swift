import Kingfisher
import MarketKit
import SwiftUI

struct CoinOverviewView: View {
    @ObservedObject var viewModel: CoinOverviewViewModel
    @ObservedObject var chartViewModel: CoinChartViewModel
    private let markdownParser = CoinPageMarkdownParser()

    @State private var tokensExpanded = false

    @Environment(\.openURL) private var openURL

    var body: some View {
        ThemeView {
            switch viewModel.state {
            case .loading:
                ProgressView()
            case let .loaded(overview):
                content(overview: overview)
            case .failed:
                SyncErrorView {
                    viewModel.load()
                }
            }
        }
    }

    @ViewBuilder private func content(overview: MarketInfoOverview) -> some View {
        let coin = overview.fullCoin.coin
        let guideUrl = guideUrl(coinUid: coin.uid)

        ScrollView {
            VStack(spacing: 0) {
                header(coin: coin, rank: overview.marketCapRank)
                chart()

                VStack(spacing: .margin24) {
                    indicators()
                    marketInfo(overview: overview)
                    VStack(spacing: .margin12) {
                        header(text: "coin.overview.roi.header".localized(coin.code.uppercased()))
                        performance(rows: overview.performance)
                    }

                    if !overview.fullCoin.tokens.isEmpty {
                        VStack(spacing: .margin12) {
                            header(text: tokensTitle(coinUid: coin.uid))
                            tokens(tokens: overview.fullCoin.tokens)
                        }
                    }

                    if !overview.description.isEmpty, let attributedString = try? markdownParser.attributedString(from: overview.description) {
                        VStack(spacing: .margin12) {
                            header(text: "coin_overview.overview".localized)
                            description(attributedString: attributedString)
                        }
                    }

                    if guideUrl != nil || !overview.links.isEmpty {
                        VStack(spacing: .margin12) {
                            header(text: "coin_overview.links".localized)
                            links(guideUrl: guideUrl, links: overview.links)
                        }
                    }
                }
                .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))

                HorizontalDivider()

                Text("powered_by".localized("CoinGecko API"))
                    .textCaption()
                    .padding(EdgeInsets(top: .margin12, leading: .margin24, bottom: .margin32, trailing: .margin24))
            }
        }
    }

    @ViewBuilder private func header(coin: Coin, rank: Int?) -> some View {
        HStack(spacing: .margin8) {
            HStack(spacing: .margin16) {
                CoinIconView(coin: coin)
                Text(coin.name).textBody()
            }

            Spacer()

            if let rank {
                Text("#\(rank)").textSubhead1()
            }
        }
        .padding(.horizontal, .margin16)
        .padding(.vertical, .margin12)
    }

    @ViewBuilder private func chart() -> some View {
        ChartView(viewModel: chartViewModel, configuration: .chartWithIndicatorArea)
            .frame(maxWidth: .infinity)
            .onFirstAppear {
                chartViewModel.start()
            }
    }

    @ViewBuilder private func indicators() -> some View {
        ListSection {
            ListRow(spacing: .margin8) {
                Text("coin_overview.indicators".localized).textSubhead2()

                Spacer()

                Button(action: {
                    chartViewModel.onToggleIndicators()
                }) {
                    Text(chartViewModel.indicatorsShown ? "coin_overview.indicators.hide".localized : "coin_overview.indicators.show".localized)
                        .animation(.none)
                }
                .buttonStyle(SecondaryButtonStyle(style: .default))

                Button(action: {
                    Coordinator.shared.present { _ in
                        ChartIndicatorsModule.view(repository: chartViewModel.service.indicatorRepository, fetcher: chartViewModel.service)
                            .ignoresSafeArea()
                    }

                    stat(page: .coinOverview, event: .open(page: .indicators))
                }) {
                    Image("setting_20").renderingMode(.template)
                }
                .buttonStyle(SecondaryCircleButtonStyle(style: .default))
            }
        }
    }

    @ViewBuilder private func marketInfo(overview: MarketInfoOverview) -> some View {
        let coinCode = overview.fullCoin.coin.code

        ListSection {
            if let value = format(value: overview.marketCap, currency: viewModel.currency) {
                marketInfoRow(title: "coin_overview.market_cap".localized, badge: overview.marketCapRank.map { "#\($0)" }, value: value)
            }

            if let value = format(value: overview.totalSupply, coinCode: coinCode) {
                marketInfoRow(title: "coin_overview.total_supply".localized, value: value)
            }

            if let value = format(value: overview.circulatingSupply, coinCode: coinCode) {
                marketInfoRow(title: "coin_overview.circulating_supply".localized, value: value)
            }

            if let value = format(value: overview.volume24h, currency: viewModel.currency) {
                marketInfoRow(title: "coin_overview.trading_volume".localized, value: value)
            }

            if let value = format(value: overview.dilutedMarketCap, currency: viewModel.currency) {
                marketInfoRow(title: "coin_overview.diluted_market_cap".localized, value: value)
            }

            if let date = overview.genesisDate {
                marketInfoRow(title: "coin_overview.genesis_date".localized, value: DateHelper.instance.formatFullDateOnly(from: date))
            }
        }
    }

    @ViewBuilder private func marketInfoRow(title: String, badge: String? = nil, value: String) -> some View {
        ListRow(spacing: .margin8) {
            Text(title).textSubhead2()

            if let badge {
                BadgeViewNew(text: badge)
            }

            Spacer()

            Text(value).textSubhead1(color: .themeLeah)
        }
    }

    @ViewBuilder private func performance(rows: [PerformanceRow]) -> some View {
        let periods = viewModel.performancePeriods

        ListSection {
            VStack(spacing: 0) {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: .heightOneDp)] + periods.map { _ in GridItem(.flexible(), spacing: .heightOneDp) }, spacing: .heightOneDp) {
                    Text("coin_page.return_of_investments".localized)
                        .textCaption()
                        .frame(maxWidth: .infinity)
                        .frame(height: .heightGrid38)
                        .background(Color.themeLawrence)

                    ForEach(periods) { period in
                        Text(period.title)
                            .textCaption()
                            .frame(maxWidth: .infinity)
                            .frame(height: .heightGrid38)
                            .background(Color.themeLawrence)
                    }

                    let performanceData = viewModel.performanceCoins.compactMap { coin in
                        if let matchingRow = rows.first(where: { $0.baseUid == coin.uid }) {
                            return (coin: coin, row: matchingRow)
                        }
                        return nil
                    }

                    ForEach(performanceData.indices, id: \.self) { index in
                        let data = performanceData[index]

                        Text(data.coin.code.uppercased())
                            .textCaptionSB(color: .themeLeah)
                            .frame(maxWidth: .infinity)
                            .frame(height: .heightGrid38)
                            .background(Color.themeLawrence)

                        ForEach(periods) { period in
                            DiffText(data.row.changes[period], font: .themeCaption)
                                .frame(maxWidth: .infinity)
                                .frame(height: .heightGrid38)
                                .background(Color.themeLawrence)
                        }
                    }
                }
                .background(Color.themeBlade)

                HorizontalDivider()

                ClickableRow(action: {
                    Coordinator.shared.present { isPresented in
                        PerformanceDataSelectView(isPresented: isPresented).ignoresSafeArea()
                    }
                    stat(page: .coinOverview, event: .open(page: .performance))
                }) {
                    HStack(spacing: .margin8) {
                        Text("coin_overview.performance.select_coins.title".localized).textSubhead2(color: .themeLeah)
                        Spacer()

                        Image.disclosureIcon
                    }
                }
            }
        }
    }

    @ViewBuilder private func tokens(tokens: [Token]) -> some View {
        let shouldTrim = tokens.count > 4
        let sortedTokens = tokens.sorted()
        let walletTokens = viewModel.walletData.wallets.map(\.token)
        let trimmedTokens = !shouldTrim || tokensExpanded ? sortedTokens : Array(sortedTokens.prefix(3))

        ListSection {
            ForEach(trimmedTokens, id: \.self) { token in
                if let reference = reference(token: token) {
                    ClickableRow {
                        CopyHelper.copyAndNotify(value: reference)
                        stat(page: .coinOverview, event: .copy(entity: .contractAddress))
                    } content: {
                        tokenRowContent(token: token, walletTokens: walletTokens)
                    }
                } else {
                    ListRow {
                        tokenRowContent(token: token, walletTokens: walletTokens)
                    }
                }
            }

            if shouldTrim {
                ClickableRow {
                    withAnimation {
                        tokensExpanded.toggle()
                    }
                } content: {
                    Text(tokensExpanded ? "coin_overview.show_less".localized : "coin_overview.show_more".localized).themeBody(alignment: .center)
                }
            }
        }
    }

    @ViewBuilder private func tokenRowContent(token: Token, walletTokens: [Token]) -> some View {
        KFImage.url(URL(string: token.blockchainType.imageUrl))
            .resizable()
            .placeholder { RoundedRectangle(cornerRadius: .cornerRadius8).fill(Color.themeBlade) }
            .clipShape(RoundedRectangle(cornerRadius: .cornerRadius8))
            .frame(width: .iconSize32, height: .iconSize32)

        VStack(spacing: 1) {
            Text(title(token: token)).themeBody()

            if let subtitle = subtitle(token: token) {
                Text(subtitle).themeSubhead2()
            }
        }

        if let account = viewModel.walletData.account, !account.watchAccount, account.type.supports(token: token) {
            if walletTokens.contains(token) {
                Button {
                    viewModel.removeFromWallet(token: token)
                } label: {
                    Image("wallet_20").renderingMode(.template)
                }
                .buttonStyle(SecondaryCircleButtonStyle(isActive: true))
            } else {
                Button {
                    viewModel.addToWallet(token: token)
                } label: {
                    Image("add_to_wallet_2_20").renderingMode(.template)
                }
                .buttonStyle(SecondaryCircleButtonStyle())
            }
        }

        if let explorerUrl = explorerUrl(token: token) {
            Button {
                open(url: explorerUrl, statPage: .externalBlockExplorer)
            } label: {
                Image("globe_20").renderingMode(.template)
            }
            .buttonStyle(SecondaryCircleButtonStyle())
        }
    }

    @ViewBuilder private func description(attributedString: NSAttributedString) -> some View {
        ListSection {
            VStack(spacing: .margin24) {
                AttributedStringView(attributedString: attributedString)
                Text("coin_overview.description_warning".localized).themeSubhead2(color: .themeJacob)
            }
            .padding(.vertical, .margin12)
            .padding(.horizontal, .margin16)
        }
    }

    @ViewBuilder private func links(guideUrl: URL?, links: [LinkType: String]) -> some View {
        ListSection {
            if let guideUrl {
                NavigationRow {
                    ThemeNavigationStack {
                        MarkdownView(url: guideUrl).ignoresSafeArea()
                    }
                    .onFirstAppear {
                        stat(page: .coinOverview, event: .open(page: .guide))
                    }
                } content: {
                    linkRowContent(image: Image("academy_1_24"), title: "coin_overview.guide".localized)
                }
            }

            if let url = links[.website], !url.isEmpty {
                ClickableRow {
                    open(url: url, statPage: .externalWebsite)
                } content: {
                    linkRowContent(image: Image("globe_24"), title: websiteTitle(url: url))
                }
            }

            if let url = links[.whitepaper], !url.isEmpty {
                ClickableRow {
                    open(url: url, statPage: .externalCoinWhitePaper)
                } content: {
                    linkRowContent(image: Image("clipboard_24"), title: "coin_overview.whitepaper".localized)
                }
            }

            if let url = links[.reddit], !url.isEmpty {
                ClickableRow {
                    open(url: url, statPage: .externalReddit)
                } content: {
                    linkRowContent(image: Image("reddit_24"), title: "Reddit")
                }
            }

            if let url = links[.twitter], !url.isEmpty {
                ClickableRow {
                    open(url: url.hasPrefix("https://") ? url : "https://twitter.com/\(url)", statPage: .externalTwitter)
                } content: {
                    linkRowContent(image: Image("twitter_24"), title: url.stripping(prefix: "https://twitter.com/"))
                }
            }

            if let url = links[.telegram], !url.isEmpty {
                ClickableRow {
                    open(url: url.hasPrefix("https://") ? url : "https://t.me/\(url)", statPage: .externalTelegram)
                } content: {
                    linkRowContent(image: Image("telegram_24"), title: "Telegram")
                }
            }

            if let url = links[.github], !url.isEmpty {
                ClickableRow {
                    open(url: url, statPage: .externalGithub)
                } content: {
                    linkRowContent(image: Image("github_24"), title: "Github")
                }
            }
        }
    }

    @ViewBuilder private func linkRowContent(image: Image, title: String) -> some View {
        image.themeIcon()
        Text(title).themeBody()
        Image.disclosureIcon
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

    private func format(value: Decimal?, coinCode: String) -> String? {
        guard let value, !value.isZero else {
            return nil
        }

        return ValueFormatter.instance.formatShort(value: value, decimalCount: 0, symbol: coinCode)
    }

    private func format(value: Decimal?, currency: Currency) -> String? {
        guard let value, !value.isZero else {
            return nil
        }

        return ValueFormatter.instance.formatShort(currency: currency, value: value)
    }

    private func title(token: Token) -> String {
        switch token.type {
        case let .derived(derivation): return derivation.mnemonicDerivation.title
        case let .addressType(type): return type.bitcoinCashCoinType.title
        default: return token.blockchain.name
        }
    }

    private func subtitle(token: Token) -> String? {
        switch token.type {
        case .native: return "coin_platforms.native".localized
        case let .derived(derivation): return derivation.mnemonicDerivation.addressType + derivation.mnemonicDerivation.recommended
        case let .addressType(type): return type.bitcoinCashCoinType.description + type.bitcoinCashCoinType.recommended
        case let .eip20(address): return address.shortened
        case let .spl(address): return address.shortened
        case let .jetton(address): return address.shortened
        case let .stellar(_, issuer): return issuer.shortened
        case let .unsupported(_, reference): return reference?.shortened
        }
    }

    private func reference(token: Token) -> String? {
        switch token.type {
        case let .eip20(address): return address
        case let .spl(address): return address
        case let .jetton(address): return address
        case let .stellar(code, issuer): return [code, issuer].joined(separator: "-")
        case let .unsupported(_, reference): return reference
        default: return nil
        }
    }

    private func explorerUrl(token: Token) -> String? {
        switch token.type {
        case let .eip20(address): return token.blockchain.explorerUrl(reference: address)
        case let .spl(address): return token.blockchain.explorerUrl(reference: address)
        case let .jetton(address): return token.blockchain.explorerUrl(reference: address)
        case let .stellar(code, issuer): return token.blockchain.explorerUrl(reference: [code, issuer].joined(separator: "-"))
        case let .unsupported(_, reference): return token.blockchain.explorerUrl(reference: reference)
        default: return nil
        }
    }

    private func tokensTitle(coinUid: String) -> String {
        switch coinUid {
        case "bitcoin", "litecoin": return "coin_overview.bips".localized
        case "bitcoin-cash": return "coin_overview.coin_types".localized
        default: return "coin_overview.blockchains".localized
        }
    }

    private func guideUrl(coinUid: String) -> URL? {
        guard let guideFileUrl = guideFileUrl(coinUid: coinUid) else {
            return nil
        }

        return URL(string: guideFileUrl, relativeTo: AppConfig.guidesIndexUrl)
    }

    private func guideFileUrl(coinUid: String) -> String? {
        switch coinUid {
        case "bitcoin": return "guides/token_guides/en/bitcoin.md"
        case "ethereum": return "guides/token_guides/en/ethereum.md"
        case "bitcoin-cash": return "guides/token_guides/en/bitcoin-cash.md"
        case "zcash": return "guides/token_guides/en/zcash.md"
        case "uniswap": return "guides/token_guides/en/uniswap.md"
        case "curve-dao-token": return "guides/token_guides/en/curve-finance.md"
        case "balancer": return "guides/token_guides/en/balancer-dex.md"
        case "synthetix-network-token": return "guides/token_guides/en/synthetix.md"
        case "tether": return "guides/token_guides/en/tether.md"
        case "maker": return "guides/token_guides/en/makerdao.md"
        case "dai": return "guides/token_guides/en/makerdao.md"
        case "aave": return "guides/token_guides/en/aave.md"
        case "compound": return "guides/token_guides/en/compound.md"
        default: return nil
        }
    }

    private func websiteTitle(url: String) -> String {
        if let url = URL(string: url), let host = url.host {
            return host.stripping(prefix: "www.")
        } else {
            return "coin_overview.website".localized
        }
    }

    private func open(url: String, statPage: StatPage) {
        guard let url = URL(string: url) else {
            return
        }

        openURL(url)

        stat(page: .coinOverview, event: .open(page: statPage))
    }
}
