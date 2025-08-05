import Kingfisher
import MarketKit
import SwiftUI

struct MarketVaultView: View {
    @StateObject var viewModel: MarketVaultViewModel
    @StateObject var chartViewModel: MetricChartViewModel
    @Binding var isPresented: Bool

    init(vault: Vault, blockchain: Blockchain?, isPresented: Binding<Bool>) {
        _viewModel = StateObject(wrappedValue: MarketVaultViewModel(vault: vault, blockchain: blockchain))
        _chartViewModel = StateObject(wrappedValue: MetricChartViewModel.vaultInstance(vault: vault))
        _isPresented = isPresented
    }

    var body: some View {
        ThemeNavigationStack {
            ScrollableThemeView {
                let vault = viewModel.vault

                VStack(spacing: 0) {
                    header(imageUrl: URL(string: vault.protocolLogo), name: vault.name, rank: vault.rank)
                    chart()

                    ListSection {
                        if let formatted = ValueFormatter.instance.formatShort(currency: viewModel.currency, value: vault.tvl) {
                            infoRow(title: "market.vault.tvl".localized, badge: vault.rank.map { "#\($0)" }, value: formatted)
                        }

                        if let blockchain = viewModel.blockchain {
                            infoRow(title: "market.vault.network".localized, value: blockchain.name)
                        }

                        infoRow(title: "market.vault.protocol".localized, value: vault.protocolName.capitalized)
                        infoRow(title: "market.vault.underlying_token".localized, value: vault.assetSymbol)

                        if let holders = vault.holders {
                            infoRow(title: "market.vault.hoders".localized, value: "\(holders)")
                        }
                    }
                    .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))

                    if let url = vault.url {
                        Button(action: {
                            Coordinator.shared.present(url: URL(string: url))
                            stat(page: .vault, event: .open(page: .externalDapp))
                        }) {
                            Text("market.vault.open_dapp".localized)
                        }
                        .buttonStyle(PrimaryButtonStyle(style: .gray))
                        .padding(EdgeInsets(top: 0, leading: .margin16, bottom: .margin32, trailing: .margin16))
                    }

                    HorizontalDivider()

                    Text("powered_by".localized("Vaults.fyi"))
                        .textCaption()
                        .padding(EdgeInsets(top: .margin12, leading: .margin24, bottom: .margin32, trailing: .margin24))
                }
            }
            .navigationTitle(viewModel.vault.assetSymbol)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("button.close".localized) {
                        isPresented = false
                    }
                }
            }
        }
    }

    @ViewBuilder private func header(imageUrl: URL?, name: String, rank: Int?) -> some View {
        HStack(spacing: .margin8) {
            HStack(spacing: .margin16) {
                KFImage.url(imageUrl)
                    .resizable()
                    .placeholder { RoundedRectangle(cornerRadius: .cornerRadius8).fill(Color.themeBlade) }
                    .clipShape(RoundedRectangle(cornerRadius: .cornerRadius8))
                    .frame(width: .iconSize32, height: .iconSize32)

                Text(name).textBody()
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

    @ViewBuilder private func infoRow(title: String, badge: String? = nil, value: String) -> some View {
        ListRow(spacing: .margin8) {
            Text(title).textSubhead2()

            if let badge {
                BadgeViewNew(text: badge)
            }

            Spacer()

            Text(value).textSubhead1(color: .themeLeah)
        }
    }
}
