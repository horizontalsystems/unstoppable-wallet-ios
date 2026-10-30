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
                    ListSection {
                        periodRow(period: 1, title: viewModel.firstPeriod.shortTitle)
                        periodRow(period: 2, title: viewModel.secondPeriod.shortTitle)
                    }
                    .padding(.top, .margin16)
                    .padding(.horizontal, .margin16)

                    HorizontalDivider()
                        .padding(.top, .margin24)

                    Cell(
                        middle: { ThemeText("coin_overview.performance.assets".localized, style: .headline2) },
                        right: { ThemeText("\(viewModel.selectedCoins.count)/\(viewModel.coinCount)", style: .subhead) }
                    )

                    ThemeList(viewModel.items, bottomSpacing: .margin16) { item in
                        Cell(
                            left: {
                                switch item.image {
                                case let .url(imageUrl): IconView(url: imageUrl, type: .circle)
                                case let .local(local):
                                    Image(local)
                                        .resizable()
                                        .clipShape(Circle())
                                        .frame(width: CGFloat.iconSize32, height: CGFloat.iconSize32)
                                }
                            },
                            middle: { MultiText(title: item.code, subtitle: item.title) },
                            right: { CheckBoxUiView(checked: .init(get: { viewModel.selectedCoins.map(\.uid).contains(item.uid) }, set: { _ in })) },
                            action: {
                                Coordinator.shared.performAfterPurchase(premiumFeature: .tokenInsights, page: .performance, trigger: .tokenChange) {
                                    viewModel.switchItem(uid: item.uid, code: item.code)
                                }
                            }
                        )
                    }
                }
                .navigationTitle("coin_overview.performance.select_coins.title".localized)
                .searchBar(text: $viewModel.searchText, prompt: "placeholder.search".localized)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(action: {
                            viewModel.setData()
                            isPresented = false
                        }) {
                            Image("check")
                        }
                        .modifier(ConfirmationButtonStyle())
                        .disabled(viewModel.selectedCoins.count != viewModel.coinCount)
                    }
                }
            }
        }
    }

    private func periodRow(period: Int, title: String) -> some View {
        Cell(
            middle: { ThemeText("coin_overview.performance.period".localized(period), style: .headline2) },
            right: {
                DropdownButton(text: title) {
                    Coordinator.shared.performAfterPurchase(premiumFeature: .tokenInsights, page: .performance, trigger: .periodChange) {
                        presentTimePeriodSelector(period: period)
                    }
                }
            }
        )
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
