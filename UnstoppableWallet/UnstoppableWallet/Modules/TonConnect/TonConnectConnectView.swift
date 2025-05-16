import Kingfisher
import SwiftUI

struct TonConnectConnectView: View {
    @StateObject private var viewModel: TonConnectConnectViewModel
    @Environment(\.presentationMode) private var presentationMode

    @State private var selectAccountPresented = false

    init(config: TonConnectConfig, returnDeepLink: String? = nil) {
        _viewModel = StateObject(wrappedValue: TonConnectConnectViewModel(config: config, returnDeepLink: returnDeepLink))
    }

    var body: some View {
        ThemeNavigationView {
            ThemeView {
                BottomGradientWrapper {
                    ScrollView {
                        VStack(spacing: .margin24) {
                            HStack(spacing: .margin16) {
                                KFImage.url(viewModel.manifest.iconUrl)
                                    .resizable()
                                    .placeholder { RoundedRectangle(cornerRadius: .cornerRadius16).fill(Color.themeSteel20) }
                                    .clipShape(RoundedRectangle(cornerRadius: .cornerRadius16))
                                    .frame(width: 72, height: 72)

                                Text(viewModel.manifest.name).themeHeadline1()
                            }

                            ListSection {
                                ListRow {
                                    Text("ton_connect.connect.url".localized).textSubhead2()
                                    Spacer()
                                    Text(viewModel.manifest.host).textSubhead1(color: .themeLeah)
                                }

                                if let account = viewModel.account {
                                    ClickableRow {
                                        selectAccountPresented = true
                                    } content: {
                                        Text("ton_connect.connect.wallet".localized).textSubhead2()
                                        Spacer()
                                        HStack(spacing: .margin8) {
                                            Text(account.name).textSubhead1(color: .themeLeah)
                                            Image("arrow_small_down_20").themeIcon()
                                        }
                                    }
                                    .alert(
                                        isPresented: $selectAccountPresented,
                                        title: "ton_connect.connect.wallet".localized,
                                        viewItems: viewModel.eligibleAccounts.map { .init(text: $0.name, selected: viewModel.account == $0) },
                                        onTap: { index in
                                            guard let index else {
                                                return
                                            }

                                            viewModel.account = viewModel.eligibleAccounts[index]
                                        }
                                    )
                                } else {
                                    ListRow {
                                        Text("ton_connect.connect.wallet".localized).textSubhead2()
                                        Spacer()
                                        Text("ton_connect.connect.no_eligible_wallets".localized).textSubhead2()
                                    }
                                }
                            }

                            HighlightedTextView(text: "ton_connect.connect.warning".localized)
                        }
                        .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
                    }
                } bottomContent: {
                    VStack(spacing: .margin16) {
                        Button(action: {
                            viewModel.connect()
                        }) {
                            Text("ton_connect.connect.connect".localized)
                        }
                        .buttonStyle(PrimaryButtonStyle(style: .active))
                        .disabled(viewModel.account == nil)

                        Button(action: {
                            viewModel.rejectConnection()
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("ton_connect.connect.reject".localized)
                        }
                        .buttonStyle(PrimaryButtonStyle(style: .default))
                    }
                }
            }
            .onReceive(viewModel.finishPublisher) {
                presentationMode.wrappedValue.dismiss()

                if let deeplink = viewModel.returnDeepLink, let url = URL(string: deeplink), UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                }
            }
            .navigationTitle("TON Connect")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
