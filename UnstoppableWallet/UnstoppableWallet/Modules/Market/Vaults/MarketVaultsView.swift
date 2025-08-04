import Kingfisher
import MarketKit
import SwiftUI

struct MarketVaultsView: View {
    @ObservedObject var viewModel: MarketVaultsViewModel

    var body: some View {
        ThemeView {
            switch viewModel.state {
            case .loading:
                VStack(spacing: 0) {
                    header(disabled: true)
                    loadingList()
                }
            case let .loaded(vaults):
                VStack(spacing: 0) {
                    header()
                    list(vaults: vaults)
                }
            case .failed:
                SyncErrorView {
                    Task {
                        await viewModel.refresh()
                    }
                }
            }
        }
    }

    @ViewBuilder private func header(disabled: Bool = false) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                Button(action: {
                    Coordinator.shared.present(type: .alert) { isPresented in
                        OptionAlertView(
                            title: "market.vaults.filter".localized,
                            viewItems: MarketVaultsViewModel.Filter.allCases.map { .init(text: $0.title, selected: viewModel.filter == $0) },
                            onSelect: { index in
                                let filter = MarketVaultsViewModel.Filter.allCases[index]

                                guard viewModel.filter != filter else {
                                    return
                                }

                                Coordinator.shared.performAfterPurchase(premiumFeature: .tokenInsights, page: .vaults, trigger: .filter) {
                                    viewModel.filter = filter
                                }
                            },
                            isPresented: isPresented
                        )
                    }
                }) {
                    Text(viewModel.filter.title)
                }
                .buttonStyle(SecondaryButtonStyle(style: .default, rightAccessory: .dropDown))
                .disabled(disabled)

                Button(action: {
                    Coordinator.shared.present(type: .alert) { isPresented in
                        OptionAlertView(
                            title: "market.sort_by.title".localized,
                            viewItems: MarketVaultsViewModel.SortBy.allCases.map { .init(text: $0.title, selected: viewModel.sortBy == $0) },
                            onSelect: { index in
                                let sortBy = MarketVaultsViewModel.SortBy.allCases[index]

                                guard viewModel.sortBy != sortBy else {
                                    return
                                }

                                Coordinator.shared.performAfterPurchase(premiumFeature: .tokenInsights, page: .vaults, trigger: .sortBy) {
                                    viewModel.sortBy = sortBy
                                }
                            },
                            isPresented: isPresented
                        )
                    }
                }) {
                    Text(viewModel.sortBy.shortTitle)
                }
                .buttonStyle(SecondaryButtonStyle(style: .default, rightAccessory: .dropDown))
                .disabled(disabled)

                Button(action: {
                    Coordinator.shared.present(type: .alert) { isPresented in
                        OptionAlertView(
                            title: "market.time_period.title".localized,
                            viewItems: viewModel.timePeriods.map { .init(text: $0.title, selected: viewModel.timePeriod == $0) },
                            onSelect: { index in
                                let timePeriod = viewModel.timePeriods[index]

                                guard viewModel.timePeriod != timePeriod else {
                                    return
                                }

                                Coordinator.shared.performAfterPurchase(premiumFeature: .tokenInsights, page: .vaults, trigger: .timePeriod) {
                                    viewModel.timePeriod = timePeriod
                                }
                            },
                            isPresented: isPresented
                        )
                    }
                }) {
                    Text(viewModel.timePeriod.shortTitle)
                }
                .buttonStyle(SecondaryButtonStyle(style: .default, rightAccessory: .dropDown))
                .disabled(disabled)

                Button(action: {
                    Coordinator.shared.present { isPresented in
                        BlockchainsView(viewModel: viewModel, isPresented: isPresented)
                    }
                }) {
                    Text(blockchainsTitle)
                }
                .buttonStyle(SecondaryButtonStyle(style: .default, rightAccessory: .dropDown))
                .disabled(disabled)
            }
            .padding(.horizontal, .margin16)
            .padding(.vertical, .margin8)
        }
    }

    @ViewBuilder private func list(vaults: [Vault]) -> some View {
        ScrollViewReader { proxy in
            ThemeList {
                if viewModel.premiumEnabled {
                    ListForEach(vaults) { vault in
                        ClickableRow(action: {
                            open(vault: vault)
                        }) {
                            itemContent(vault: vault)
                        }
                    }
                } else {
                    ListForEach(Array(vaults.prefix(7))) { vault in
                        ClickableRow(action: {
                            open(vault: vault)
                        }) {
                            itemContent(vault: vault)
                        }
                    }

                    ZStack {
                        ListSection {
                            ForEach(Array(vaults.dropFirst(7).prefix(6)), id: \.self) { vault in
                                ListRow {
                                    itemContent(vault: vault)
                                }
                            }
                        }
                        .blur(radius: 5)

                        VStack(spacing: .margin24) {
                            Image("lock_48").themeIcon()

                            Text("market.vaults.premium.description".localized)
                                .textHeadline2()
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, .margin24)

                            Button(action: {
                                Coordinator.shared.presentPurchase(page: .vaults, trigger: .unlock)
                            }) {
                                Text("market.vaults.premium.unlock".localized)
                            }
                            .buttonStyle(PrimaryButtonStyle(style: .yellow))
                        }
                        .padding(.horizontal, .margin24)
                        .frame(maxHeight: .infinity)
                        .background(Color.themeLawrence.opacity(0.8))
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                }
            }
            .themeListStyle(.transparent)
            .refreshable {
                await viewModel.refresh()
            }
            .onChange(of: viewModel.filter) { _ in withAnimation { proxy.scrollTo(THEME_LIST_TOP_VIEW_ID) } }
            .onChange(of: viewModel.sortBy) { _ in withAnimation { proxy.scrollTo(THEME_LIST_TOP_VIEW_ID) } }
            .onChange(of: viewModel.timePeriod) { _ in withAnimation { proxy.scrollTo(THEME_LIST_TOP_VIEW_ID) } }
        }
    }

    @ViewBuilder private func loadingList() -> some View {
        ThemeList(Array(0 ... 10)) { _ in
            ListRow {
                itemContent(
                    imageUrl: nil,
                    assetSymbol: "USDC",
                    name: "Savings USDC",
                    chain: "Ethereum",
                    apy: 2.34,
                    tvl: 123_123_000_000
                )
                .redacted()
            }
        }
        .themeListStyle(.transparent)
        .simultaneousGesture(DragGesture(minimumDistance: 0), including: .all)
    }

    @ViewBuilder private func itemContent(vault: Vault) -> some View {
        itemContent(
            imageUrl: URL(string: vault.protocolLogo),
            assetSymbol: vault.assetSymbol,
            name: vault.name,
            chain: viewModel.blockchainMap[vault.chain]?.name,
            apy: vault.apy[viewModel.timePeriod],
            tvl: vault.tvl
        )
    }

    @ViewBuilder private func itemContent(imageUrl: URL?, assetSymbol: String, name: String, chain: String?, apy: Decimal?, tvl: Decimal) -> some View {
        KFImage.url(imageUrl)
            .resizable()
            .placeholder { RoundedRectangle(cornerRadius: .cornerRadius8).fill(Color.themeBlade) }
            .clipShape(RoundedRectangle(cornerRadius: .cornerRadius8))
            .frame(width: .iconSize32, height: .iconSize32)

        VStack(spacing: 1) {
            HStack(spacing: .margin8) {
                Text(assetSymbol).textBody()

                if let chain {
                    BadgeViewNew(text: chain)
                }

                Spacer()

                if let apy, let formatted = ValueFormatter.instance.format(percentValue: apy) {
                    Text("market.vaults.apy".localized(formatted)).textBody(color: .themeRemus)
                }
            }

            HStack(spacing: .margin8) {
                Text(name).textSubhead2()
                Spacer()
                if let formatted = ValueFormatter.instance.formatShort(currency: viewModel.currency, value: tvl) {
                    Text("market.vaults.tvl".localized(formatted)).textSubhead2()
                }
            }
        }
    }

    private func open(vault: Vault) {
        Coordinator.shared.presentAfterPurchase(premiumFeature: .tokenInsights, page: .vaults, trigger: .vault) { isPresented in
            MarketVaultView(vault: vault, blockchain: viewModel.blockchainMap[vault.chain], isPresented: isPresented)
        } onPresent: {
            stat(page: .markets, section: .vaults, event: .open(page: .vault))
        }
    }

    private var blockchainsTitle: String {
        if viewModel.blockchains.isEmpty {
            return "market.vaults.chains.all_chains".localized
        } else if viewModel.blockchains.count == 1, let blockchain = viewModel.blockchains.first {
            return blockchain.name
        } else {
            return "market.vaults.chains.n_chains".localized("\(viewModel.blockchains.count)")
        }
    }
}

extension MarketVaultsView {
    struct BlockchainsView: View {
        @ObservedObject var viewModel: MarketVaultsViewModel
        @Binding var isPresented: Bool

        var body: some View {
            ThemeNavigationStack {
                ScrollableThemeView {
                    ListSection {
                        ClickableRow(action: {
                            viewModel.blockchains = []
                        }) {
                            Text("market.vaults.chains.any").themeBody()

                            if viewModel.blockchains.isEmpty {
                                Image.checkIcon
                            }
                        }

                        ForEach(viewModel.allBlockchains, id: \.self) { blockchain in
                            ClickableRow(action: {
                                Coordinator.shared.performAfterPurchase(premiumFeature: .tokenInsights, page: .vaults, trigger: .blockchains) {
                                    if viewModel.blockchains.contains(blockchain) {
                                        viewModel.blockchains.remove(blockchain)
                                    } else {
                                        viewModel.blockchains.insert(blockchain)
                                    }
                                }
                            }) {
                                KFImage.url(URL(string: blockchain.type.imageUrl))
                                    .resizable()
                                    .placeholder { RoundedRectangle(cornerRadius: .cornerRadius8).fill(Color.themeBlade) }
                                    .clipShape(RoundedRectangle(cornerRadius: .cornerRadius8))
                                    .frame(width: .iconSize32, height: .iconSize32)

                                Text(blockchain.name).themeBody()

                                if viewModel.blockchains.contains(blockchain) {
                                    Image.checkIcon
                                }
                            }
                        }
                    }
                    .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
                }
                .navigationTitle("market.vaults.chains.title".localized)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("button.done".localized) {
                            isPresented = false
                        }
                    }
                }
            }
        }
    }
}
