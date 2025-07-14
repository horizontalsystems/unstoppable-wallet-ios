import Kingfisher
import SwiftUI

struct AppearanceView: View {
    @StateObject var viewModel = AppearanceViewModel()

    @Environment(\.openURL) private var openURL

    var body: some View {
        ScrollableThemeView {
            VStack(spacing: .margin24) {
                ListSection {
                    ClickableRow(spacing: .margin8) {
                        Coordinator.shared.present(type: .alert) { isPresented in
                            OptionAlertView(
                                title: "appearance.theme".localized,
                                viewItems: viewModel.themeModes.map { .init(text: title(themeMode: $0), selected: viewModel.themeMode == $0) },
                                onSelect: { index in
                                    viewModel.themeMode = viewModel.themeModes[index]
                                },
                                isPresented: isPresented
                            )
                        }
                    } content: {
                        Text("appearance.theme".localized).textBody()
                        Spacer()
                        Text(title(themeMode: viewModel.themeMode)).textSubhead1()
                        Image("arrow_small_down_20").themeIcon()
                    }
                }

                ListSection {
                    ClickableRow(spacing: .margin8, action: {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            openURL(url)
                        }
                    }) {
                        Text("settings.language".localized).textBody()
                        Spacer()

                        if let language = LanguageManager.shared.currentLanguageDisplayName {
                            Text(language).textSubhead1()
                        }

                        Image.disclosureIcon
                    }

                    NavigationRow(spacing: .margin8, destination: {
                        BaseCurrencySettingsModule.view()
                            .onFirstAppear {
                                stat(page: .appearance, event: .open(page: .baseCurrency))
                            }
                    }) {
                        Text("settings.base_currency".localized).textBody()
                        Spacer()
                        Text(viewModel.baseCurrencyCode).textSubhead1()
                        Image.disclosureIcon
                    }
                }

                VStack(spacing: 0) {
                    ListSectionHeader(text: "appearance.markets_tab".localized)
                    ListSection {
                        ListRow {
                            Toggle(isOn: $viewModel.hideMarkets.animation()) {
                                Text("appearance.hide_markets".localized).themeBody()
                            }
                            .toggleStyle(SwitchToggleStyle(tint: .themeYellow))
                        }

                        ClickableRow(spacing: .margin8) {
                            Coordinator.shared.present(type: .alert) { isPresented in
                                OptionAlertView(
                                    title: "appearance.price_change".localized,
                                    viewItems: PriceChangeMode.allCases.map { .init(text: title(priceChangeMode: $0), selected: viewModel.priceChangeMode == $0) },
                                    onSelect: { index in
                                        viewModel.priceChangeMode = PriceChangeMode.allCases[index]
                                    },
                                    isPresented: isPresented
                                )
                            }
                        } content: {
                            Text("appearance.price_change".localized).textBody()
                            Spacer()
                            Text(title(priceChangeMode: viewModel.priceChangeMode)).textSubhead1()
                            Image("arrow_small_down_20").themeIcon()
                        }
                    }
                }

                if !viewModel.hideMarkets {
                    ListSection {
                        ClickableRow(spacing: .margin8) {
                            Coordinator.shared.present(type: .alert) { isPresented in
                                OptionAlertView(
                                    title: "appearance.launch_screen".localized,
                                    viewItems: LaunchScreen.allCases.map { .init(text: $0.title, selected: viewModel.launchScreen == $0) },
                                    onSelect: { index in
                                        viewModel.launchScreen = LaunchScreen.allCases[index]
                                    },
                                    isPresented: isPresented
                                )
                            }
                        } content: {
                            Text("appearance.launch_screen".localized).textBody()
                            Spacer()
                            Text(viewModel.launchScreen.title).textSubhead1()
                            Image("arrow_small_down_20").themeIcon()
                        }
                    }
                }

                VStack(spacing: 0) {
                    ListSectionHeader(text: "appearance.balance_tab".localized)

                    ListSection {
                        ListRow {
                            Toggle(isOn: $viewModel.hideBalanceButtons.animation()) {
                                Text("appearance.hide_buttons".localized).themeBody()
                            }
                            .toggleStyle(SwitchToggleStyle(tint: .themeYellow))
                        }

                        ClickableRow(spacing: .margin8) {
                            Coordinator.shared.present(type: .alert) { isPresented in
                                OptionAlertView(
                                    title: "appearance.balance_value".localized,
                                    viewItems: BalancePrimaryValue.allCases.map { .init(text: title(balancePrimaryValue: $0), selected: viewModel.balancePrimaryValue == $0) },
                                    onSelect: { index in
                                        viewModel.balancePrimaryValue = BalancePrimaryValue.allCases[index]
                                    },
                                    isPresented: isPresented
                                )
                            }
                        } content: {
                            Text("appearance.balance_value".localized).textBody()
                            Spacer()
                            Text(title(balancePrimaryValue: viewModel.balancePrimaryValue)).textSubhead1()
                            Image("arrow_small_down_20").themeIcon()
                        }
                    }

                    ListSectionFooter(text: "appearance.balance_tab.footer".localized)
                }

                VStack(spacing: 0) {
                    ListSectionHeader(text: "appearance.app_icon".localized)
                    ListSection {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: .margin16) {
                            ForEach(AppIconManager.allAppIcons, id: \.self) { appIcon in
                                Button(action: {
                                    viewModel.appIcon = appIcon
                                }) {
                                    VStack(spacing: .margin12) {
                                        Image(appIcon.imageName)
                                            .resizable()
                                            .scaledToFit()
                                            .clipShape(RoundedRectangle(cornerRadius: .cornerRadius12, style: .continuous))
                                            .frame(width: 60, height: 60)
                                        Text(appIcon.title)
                                            .themeSubhead1(color: viewModel.appIcon == appIcon ? .themeJacob : .themeLeah, alignment: .center)
                                    }
                                }
                            }
                        }
                        .padding(.margin16)
                    }
                }
            }
            .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
        }
        .navigationTitle("appearance.title".localized)
        .navigationBarTitleDisplayMode(.inline)
    }

    func title(themeMode: ThemeMode) -> String {
        switch themeMode {
        case .system: return "appearance.theme.system".localized
        case .dark: return "appearance.theme.dark".localized
        case .light: return "appearance.theme.light".localized
        }
    }

    func title(balancePrimaryValue: BalancePrimaryValue) -> String {
        switch balancePrimaryValue {
        case .coin: return "appearance.balance_value.coin_fiat".localized
        case .currency: return "appearance.balance_value.fiat_coin".localized
        }
    }

    func title(priceChangeMode: PriceChangeMode) -> String {
        switch priceChangeMode {
        case .hour24: return "appearance.price_change.24h".localized
        case .day1: return "appearance.price_change.1d".localized
        }
    }
}
