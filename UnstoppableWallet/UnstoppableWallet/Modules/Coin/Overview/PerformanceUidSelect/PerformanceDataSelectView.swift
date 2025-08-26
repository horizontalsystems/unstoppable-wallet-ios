import Kingfisher
import MarketKit
import SwiftUI

struct PerformanceDataSelectView: View {
    @StateObject private var viewModel: PerformanceDataSelectViewModel

    @Binding var isPresented: Bool

    init(isPresented: Binding<Bool>) {
        _viewModel = .init(wrappedValue: PerformanceDataSelectViewModel())
        _isPresented = isPresented
    }

    var body: some View {
        ThemeNavigationStack {
            ThemeView {
                VStack(spacing: 0) {
                    SearchBar(text: $viewModel.searchText, prompt: "placeholder.search".localized)

                    ListSection {
                        ListRow {
                            Text("coin_overview.performance.period".localized(1)).textBody()
                            Spacer()
                            Button(action: {
                                Coordinator.shared.performAfterPurchase(premiumFeature: .tokenInsights, page: .performance, trigger: .periodChange) {
                                    presentTimePeriodSelector(period: 1)
                                }
                            }) {
                                Text(viewModel.firstPeriod.shortTitle)
                            }
                            .buttonStyle(SecondaryButtonStyle(style: .default, rightAccessory: .dropDown))
                        }

                        ListRow {
                            Text("coin_overview.performance.period".localized(2)).textBody()
                            Spacer()
                            Button(action: {
                                Coordinator.shared.performAfterPurchase(premiumFeature: .tokenInsights, page: .performance, trigger: .periodChange) {
                                    presentTimePeriodSelector(period: 2)
                                }
                            }) {
                                Text(viewModel.secondPeriod.shortTitle)
                            }
                            .buttonStyle(SecondaryButtonStyle(style: .default, rightAccessory: .dropDown))
                        }
                    }
                    .padding(.top, .margin16)
                    .padding(.horizontal, .margin16)

                    HorizontalDivider()
                        .padding(.top, .margin24)

                    ListRow {
                        Text("coin_overview.performance.assets").textBody()
                        Spacer()
                        Text("\(viewModel.selectedCoins.count)/\(viewModel.coinCount)").textSubhead1()
                    }

                    ThemeList(viewModel.items, bottomSpacing: .margin16) { item in
                        ClickableRow(action: {
                            Coordinator.shared.performAfterPurchase(premiumFeature: .tokenInsights, page: .performance, trigger: .tokenChange) {
                                viewModel.switchItem(uid: item.uid, code: item.code)
                            }
                        }) {
                            switch item.image {
                            case let .url(imageUrl): IconView(url: imageUrl, type: .circle)
                            case let .local(local):
                                Image(local)
                                    .resizable()
                                    .clipShape(Circle())
                                    .frame(width: CGFloat.iconSize32, height: CGFloat.iconSize32)
                            }

                            VStack(spacing: 1) {
                                Text(item.code)
                                    .textBody()
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Text(item.title).themeSubhead2()
                            }

                            Spacer()

                            CheckBoxUiView(checked: .init(get: { viewModel.selectedCoins.map(\.uid).contains(item.uid) }, set: { _ in }))
                        }
                    }
                }
                .navigationTitle("coin_overview.performance.select_coins.title".localized)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("button.done".localized) {
                            viewModel.setData()
                            isPresented = false
                        }
                        .disabled(viewModel.selectedCoins.count != viewModel.coinCount)
                    }
                }
                .accentColor(Color.themeJacob)
            }
        }
    }

    private func presentTimePeriodSelector(period: Int) {
        Coordinator.shared.present(type: .alert) { isPresented in
            OptionAlertView(
                title: "coin_overview.performance.period".localized(period),
                viewItems: viewModel.timePeriods.map {
                    let selected = period == 1 ? viewModel.firstPeriod : viewModel.secondPeriod
                    return .init(text: $0.title, selected: selected == $0)
                },
                onSelect: { index in
                    if period == 1 {
                        viewModel.setFirst(period: viewModel.timePeriods[index])
                    } else {
                        viewModel.setSecond(period: viewModel.timePeriods[index])
                    }
                },
                isPresented: isPresented
            )
        }
    }
}
