import Kingfisher
import MarketKit
import SwiftUI

struct MarketVaultsView: View {
    @ObservedObject var viewModel: MarketVaultsViewModel

    var body: some View {
        ThemeView(style: .list) {
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
        ListHeader(scrollable: true) {
            DropdownButton(text: viewModel.filter.title) {
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
            }
            .disabled(disabled)

            DropdownButton(text: viewModel.sortBy.shortTitle) {
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
            }
            .disabled(disabled)

            DropdownButton(text: viewModel.timePeriod.shortTitle) {
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
            }
            .disabled(disabled)

            DropdownButton(text: blockchainsTitle) {
                Coordinator.shared.present { isPresented in
                    BlockchainsView(viewModel: viewModel, isPresented: isPresented)
                }
            }
            .disabled(disabled)
        }
    }

    @ViewBuilder private func list(vaults: [Vault]) -> some View {
        ScrollViewReader { proxy in
            ThemeList {
                if viewModel.premiumEnabled {
                    ListForEach(vaults) { vault in
                        cell(vault: vault) {
                            open(vault: vault)
                        }
                    }
                } else {
                    ListForEach(Array(vaults.prefix(7))) { vault in
                        cell(vault: vault) {
                            open(vault: vault)
                        }
                    }

                    ZStack {
                        ListSection {
                            ForEach(Array(vaults.dropFirst(7).prefix(6)), id: \.self) { vault in
                                cell(vault: vault)
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
            cell(
                imageUrl: nil,
                assetSymbol: "USDC",
                name: "Savings USDC",
                chain: "Ethereum",
                apy: 2.34,
                tvl: 123_123_000_000
            )
            .redacted()
        }
        .scrollDisabled(true)
    }

    @ViewBuilder private func cell(vault: Vault, action: (() -> Void)? = nil) -> some View {
        cell(
            imageUrl: URL(string: vault.protocolLogo),
            assetSymbol: vault.assetSymbol,
            name: vault.name,
            chain: viewModel.blockchainMap[vault.chain]?.name,
            apy: vault.apy[viewModel.timePeriod],
            tvl: vault.tvl,
            action: action
        )
    }

    @ViewBuilder private func cell(imageUrl: URL?, assetSymbol: String, name: String, chain: String?, apy: Decimal?, tvl: Decimal, action: (() -> Void)? = nil) -> some View {
        Cell(
            left: {
                KFImage.url(imageUrl)
                    .resizable()
                    .placeholder { RoundedRectangle(cornerRadius: .cornerRadius8).fill(Color.themeBlade) }
                    .clipShape(RoundedRectangle(cornerRadius: .cornerRadius8))
                    .frame(width: .iconSize32, height: .iconSize32)
            },
            middle: {
                MultiText(
                    title: assetSymbol,
                    badge: chain,
                    subtitle: name
                )
            },
            right: {
                RightMultiText(
                    title: apy.flatMap { apy in
                        ValueFormatter.instance.format(percentValue: apy, signType: .auto).map {
                            ComponentText(text: "market.vaults.apy".localized($0), colorStyle: .init(diff: apy))
                        }
                    },
                    subtitle: ValueFormatter.instance.formatShort(currency: viewModel.currency, value: tvl).map { "market.vaults.tvl".localized($0) }
                )
            },
            action: action
        )
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
                ThemeView(style: .list) {
                    ThemeList(bottomSpacing: .margin16) {
                        Cell(
                            middle: {
                                MultiText(title: "market.vaults.chains.any".localized)
                            },
                            right: {
                                if viewModel.blockchains.isEmpty {
                                    Image.checkIcon
                                }
                            },
                            action: {
                                viewModel.blockchains = []
                            }
                        )
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)

                        ListForEach(viewModel.allBlockchains) { blockchain in
                            Cell(
                                left: {
                                    KFImage.url(URL(string: blockchain.type.imageUrl))
                                        .resizable()
                                        .placeholder { RoundedRectangle(cornerRadius: .cornerRadius8).fill(Color.themeBlade) }
                                        .clipShape(RoundedRectangle(cornerRadius: .cornerRadius8))
                                        .frame(width: .iconSize32, height: .iconSize32)
                                },
                                middle: {
                                    MultiText(title: blockchain.name)
                                },
                                right: {
                                    if viewModel.blockchains.contains(blockchain) {
                                        Image.checkIcon
                                    }
                                },
                                action: {
                                    Coordinator.shared.performAfterPurchase(premiumFeature: .tokenInsights, page: .vaults, trigger: .blockchains) {
                                        if viewModel.blockchains.contains(blockchain) {
                                            viewModel.blockchains.remove(blockchain)
                                        } else {
                                            viewModel.blockchains.insert(blockchain)
                                        }
                                    }
                                }
                            )
                        }
                    }
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
