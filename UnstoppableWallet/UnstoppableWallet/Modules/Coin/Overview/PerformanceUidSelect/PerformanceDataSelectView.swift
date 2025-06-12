import Kingfisher
import MarketKit
import SwiftUI

struct PerformanceDataSelectView: View {
    @StateObject private var viewModel: PerformanceDataSelectViewModel

    @Binding var isPresented: Bool
    @State var timePeriodSelectorPresented = false
    @State var selectedPeriod: Int?

    @State var subscriptionPresented = false

    init(isPresented: Binding<Bool>) {
        _viewModel = .init(wrappedValue: PerformanceDataSelectViewModel())
        _isPresented = isPresented
    }

    var body: some View {
        ThemeNavigationView {
            ThemeView {
                VStack(spacing: 0) {
                    SearchBar(text: $viewModel.searchText, prompt: "placeholder.search".localized)

                    ListSection {
                        ListRow {
                            Text("coin_overview.performance.period".localized(1)).textBody()
                            Spacer()
                            Button(action: {
                                guard viewModel.premiumEnabled else {
                                    subscriptionPresented = true
                                    stat(page: .performance, event: .openPremium(from: .periodChange))
                                    return
                                }
                                selectedPeriod = 1
                                timePeriodSelectorPresented = true
                            }) {
                                Text(viewModel.firstPeriod.shortTitle)
                            }
                            .buttonStyle(SecondaryButtonStyle(style: .default, rightAccessory: .dropDown))
                        }

                        ListRow {
                            Text("coin_overview.performance.period".localized(2)).textBody()
                            Spacer()
                            Button(action: {
                                guard viewModel.premiumEnabled else {
                                    subscriptionPresented = true
                                    stat(page: .performance, event: .openPremium(from: .periodChange))
                                    return
                                }
                                selectedPeriod = 2
                                timePeriodSelectorPresented = true
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
                            guard viewModel.premiumEnabled else {
                                subscriptionPresented = true
                                stat(page: .performance, event: .openPremium(from: .tokenChange))
                                return
                            }
                            viewModel.switchItem(uid: item.uid, code: item.code)
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
            }
        }
        .sheet(isPresented: $subscriptionPresented) {
            PurchasesView()
        }
        .alert(
            isPresented: $timePeriodSelectorPresented,
            title: "coin_overview.performance.period".localized(selectedPeriod ?? 0),
            viewItems: viewModel.timePeriods.map {
                let selected = selectedPeriod == 1 ? viewModel.firstPeriod : viewModel.secondPeriod
                return .init(text: $0.title, selected: selected == $0)
            },
            onTap: { index in
                guard let index else {
                    return
                }

                if selectedPeriod == 1 {
                    viewModel.setFirst(period: viewModel.timePeriods[index])
                } else {
                    viewModel.setSecond(period: viewModel.timePeriods[index])
                }
            }
        )
    }
}
