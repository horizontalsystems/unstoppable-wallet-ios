import Kingfisher
import MarketKit
import SwiftUI

struct CoinOverviewView: View {
    @ObservedObject var viewModel: CoinOverviewViewModel
    @ObservedObject var chartViewModel: CoinChartViewModel
    private let markdownParser = CoinPageMarkdownParser()

    @State private var tokensExpanded = false

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

    private func header(coin: Coin, rank: Int?) -> some View {
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

    private func chart() -> some View {
        VStack(spacing: .margin8) {
            ChartView(viewModel: chartViewModel, configuration: .chartWithIndicatorArea)
                .frame(maxWidth: .infinity)

            ChartIntervalsView(titles: chartViewModel.intervalTitles, selectedIndex: chartViewModel.selectedIntervalIndex) { index in
                chartViewModel.onSelectInterval(at: index)
            }
        }
        .onFirstAppear {
            chartViewModel.start()
        }
    }

    private func indicators() -> some View {
        ListSection {
            Cell(
                middle: { ThemeText("coin_overview.indicators".localized, style: .subhead) },
                right: {
                    HStack(spacing: .margin8) {
                        let indicatorsText = chartViewModel.indicatorsShown ? "coin_overview.indicators.hide".localized : "coin_overview.indicators.show".localized

                        ThemeButton(text: indicatorsText, style: .secondary, size: .small) {
                            chartViewModel.onToggleIndicators()
                        }

                        IconButton(icon: "gear", style: .secondary, size: .small) {
                            Coordinator.shared.present { isPresented in
                                ChartIndicatorsView(repository: chartViewModel.service.indicatorRepository, isPresented: isPresented)
                            }

                            stat(page: .coinOverview, event: .open(page: .indicators))
                        }
                    }
                }
            )
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

    private func marketInfoRow(title: String, badge: String? = nil, value: String) -> some View {
        Cell(
            middle: {
                HStack(spacing: .margin8) {
                    ThemeText(title, style: .subhead)

                    if let badge {
                        BadgeViewNew(badge)
                    }
                }
            },
            right: { ThemeText(value, style: .subheadSB) }
        )
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

                Cell(
                    middle: { ThemeText("coin_overview.performance.select_coins.title".localized, style: .subhead, colorStyle: .primary) },
                    right: { Image.disclosureIcon },
                    action: {
                        Coordinator.shared.present { isPresented in
                            PerformanceDataSelectView(isPresented: isPresented).ignoresSafeArea()
                        }
                        stat(page: .coinOverview, event: .open(page: .performance))
                    }
                )
            }
        }
    }

    @ViewBuilder private func tokens(tokens: [Token]) -> some View {
        let shouldTrim = tokens.count > 4
        let sortedTokens = tokens.ordered()
        let walletTokens = viewModel.walletData.wallets.map(\.token)
        let trimmedTokens = !shouldTrim || tokensExpanded ? sortedTokens : Array(sortedTokens.prefix(3))

        ListSection {
            ForEach(trimmedTokens, id: \.self) { token in
                if let reference = reference(token: token) {
                    tokenRow(token: token, walletTokens: walletTokens) {
                        CopyHelper.copyAndNotify(value: reference)
                        stat(page: .coinOverview, event: .copy(entity: .contractAddress))
                    }
                } else {
                    tokenRow(token: token, walletTokens: walletTokens, action: nil)
                }
            }

            if shouldTrim {
                Cell(
                    middle: {
                        ThemeText(tokensExpanded ? "coin_overview.show_less".localized : "coin_overview.show_more".localized, style: .headline2)
                            .frame(maxWidth: .infinity, alignment: .center)
                    },
                    action: {
                        withAnimation {
                            tokensExpanded.toggle()
                        }
                    }
                )
            }
        }
    }

    private func tokenRow(token: Token, walletTokens: [Token], action: (() -> Void)?) -> some View {
        Cell(
            left: {
                KFImage.url(URL(string: token.blockchainType.imageUrl))
                    .resizable()
                    .placeholder { RoundedRectangle(cornerRadius: .cornerRadius8).fill(Color.themeBlade) }
                    .clipShape(RoundedRectangle(cornerRadius: .cornerRadius8))
                    .frame(width: .iconSize32, height: .iconSize32)
            },
            middle: { MultiText(title: title(token: token), subtitle: subtitle(token: token)) },
            right: {
                HStack(spacing: .margin8) {
                    if let account = viewModel.walletData.account, !account.watchAccount, account.type.supports(token: token) {
                        if walletTokens.contains(token) {
                            IconButton(icon: "wallet", style: .primary, size: .small) {
                                viewModel.removeFromWallet(token: token)
                            }
                        } else {
                            IconButton(icon: "wallet_add", style: .secondary, size: .small) {
                                viewModel.addToWallet(token: token)
                            }
                        }
                    }

                    if let explorerUrl = explorerUrl(token: token) {
                        IconButton(icon: "globe", style: .secondary, size: .small) {
                            open(url: explorerUrl, statPage: .externalBlockExplorer)
                        }
                    }
                }
            },
            action: action
        )
    }

    private func description(attributedString: NSAttributedString) -> some View {
        ListSection {
            VStack(spacing: .margin24) {
                AttributedStringView(attributedString: attributedString)
                Text("coin_overview.description_warning".localized).themeSubhead2(color: .themeJacob)
            }
            .padding(.vertical, .margin12)
            .padding(.horizontal, .margin16)
        }
    }

    private func links(guideUrl: URL?, links: [LinkType: String]) -> some View {
        ListSection {
            if let guideUrl {
                NavigationLink(destination: {
                    MarkdownView(url: guideUrl)
                        .onFirstAppear {
                            stat(page: .coinOverview, event: .open(page: .guide))
                        }
                }) {
                    linkCell(icon: "book", title: "coin_overview.guide".localized)
                }
                .buttonStyle(CellButtonStyle())
            }

            if let url = links[.website], !url.isEmpty {
                linkCell(icon: "globe", title: websiteTitle(url: url)) {
                    open(url: url, statPage: .externalWebsite)
                }
            }

            if let url = links[.whitepaper], !url.isEmpty {
                linkCell(icon: "paper_contract", title: "coin_overview.whitepaper".localized) {
                    open(url: url, statPage: .externalCoinWhitePaper)
                }
            }

            if let url = links[.reddit], !url.isEmpty {
                linkCell(icon: "reddit", title: "Reddit") {
                    open(url: url, statPage: .externalReddit)
                }
            }

            if let url = links[.twitter], !url.isEmpty {
                linkCell(icon: "x_logo", title: url.stripping(prefix: "https://twitter.com/")) {
                    open(url: url.hasPrefix("https://") ? url : "https://twitter.com/\(url)", statPage: .externalTwitter)
                }
            }

            if let url = links[.telegram], !url.isEmpty {
                linkCell(icon: "telegram_logo", title: "Telegram") {
                    open(url: url.hasPrefix("https://") ? url : "https://t.me/\(url)", statPage: .externalTelegram)
                }
            }

            if let url = links[.github], !url.isEmpty {
                linkCell(icon: "github", title: "Github") {
                    open(url: url, statPage: .externalGithub)
                }
            }
        }
    }

    private func linkCell(icon: String, title: String, action: (() -> Void)? = nil) -> some View {
        Cell(
            left: { ThemeImage(icon, size: .iconSize24) },
            middle: { ThemeText(title, style: .headline2) },
            right: { Image.disclosureIcon },
            action: action
        )
    }

    private func header(text: String) -> some View {
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
        case let .zanoAsset(id): return id.shortened
        case let .thorChainAsset(denom): return denom
        case let .xrpAsset(_, issuer): return issuer.shortened
        case let .nep141(contractId): return contractId.shortened
        case let .unsupported(_, reference): return reference?.shortened
        }
    }

    private func reference(token: Token) -> String? {
        switch token.type {
        case let .eip20(address): return address
        case let .spl(address): return address
        case let .jetton(address): return address
        case let .stellar(code, issuer): return [code, issuer].joined(separator: "-")
        case let .thorChainAsset(denom): return denom
        case let .xrpAsset(currency, issuer): return [currency, issuer].joined(separator: "-")
        case let .nep141(contractId): return contractId
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
        case let .nep141(contractId): return "https://nearblocks.io/token/\(contractId)"
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

        Coordinator.shared.present(url: url)

        stat(page: .coinOverview, event: .open(page: statPage))
    }
}
