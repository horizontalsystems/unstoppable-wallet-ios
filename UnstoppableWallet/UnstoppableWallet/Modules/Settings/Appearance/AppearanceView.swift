import SDWebImageSwiftUI
import SwiftUI
import ThemeKit

struct AppearanceView: View {
    @ObservedObject var viewModel: AppearanceViewModel

    var body: some View {
        ScrollableThemeView {
            VStack(spacing: .margin24) {
                VStack(spacing: 0) {
                    ListSectionHeader(text: "appearance.theme".localized)
                    ListSection {
                        ForEach(viewModel.themeModes, id: \.self) { themeMode in
                            ClickableRow(action: {
                                viewModel.themMode = themeMode
                            }) {
                                icon(themeMode: themeMode).themeIcon()
                                Text(title(themeMode: themeMode)).themeBody()

                                if viewModel.themMode == themeMode {
                                    Image.checkIcon
                                }
                            }
                        }
                    }
                }

                VStack(spacing: 0) {
                    ListSectionHeader(text: "appearance.tab_settings".localized)
                    ListSection {
                        ListRow {
                            Image("markets_24").themeIcon()
                            Toggle(isOn: $viewModel.showMarketTab.animation()) {
                                Text("appearance.markets_tab".localized).themeBody()
                            }
                            .toggleStyle(SwitchToggleStyle(tint: .themeYellow))
                        }
                    }
                }

                if viewModel.showMarketTab {
                    VStack(spacing: 0) {
                        ListSectionHeader(text: "appearance.launch_screen".localized)
                        ListSection {
                            ForEach(LaunchScreen.allCases, id: \.self) { launchScreen in
                                ClickableRow(action: {
                                    viewModel.launchScreen = launchScreen
                                }) {
                                    Image(launchScreen.iconName).themeIcon()
                                    Text(launchScreen.title).themeBody()

                                    if viewModel.launchScreen == launchScreen {
                                        Image.checkIcon
                                    }
                                }
                            }
                        }
                    }
                }

                VStack(spacing: 0) {
                    ListSectionHeader(text: "appearance.balance_conversion".localized)
                    ListSection {
                        ForEach(viewModel.conversionTokens, id: \.self) { token in
                            ClickableRow(action: {
                                viewModel.conversionToken = token
                            }) {
                                WebImage(url: URL(string: token.coin.imageUrl))
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: .iconSize32, height: .iconSize32)

                                Text(token.coin.code).themeBody()

                                if viewModel.conversionToken == token {
                                    Image.checkIcon
                                }
                            }
                        }
                    }
                }

                VStack(spacing: 0) {
                    ListSectionHeader(text: "appearance.balance_value".localized)
                    ListSection {
                        ForEach(BalancePrimaryValue.allCases, id: \.self) { balancePrimaryValue in
                            ClickableRow(action: {
                                viewModel.balancePrimaryValue = balancePrimaryValue
                            }) {
                                VStack(spacing: 1) {
                                    Text(balancePrimaryValue.title).themeBody()
                                    Text(balancePrimaryValue.subtitle).themeSubhead2()
                                }

                                if viewModel.balancePrimaryValue == balancePrimaryValue {
                                    Image.checkIcon
                                }
                            }
                        }
                    }
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
                                        Image(uiImage: UIImage(named: appIcon.imageName) ?? UIImage())
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
    }

    func title(themeMode: ThemeMode) -> String {
        switch themeMode {
        case .system: return "appearance.theme.system".localized
        case .dark: return "appearance.theme.dark".localized
        case .light: return "appearance.theme.light".localized
        }
    }

    func icon(themeMode: ThemeMode) -> Image {
        switch themeMode {
        case .system: return Image("settings_24")
        case .dark: return Image("dark_24")
        case .light: return Image("light_24")
        }
    }
}
