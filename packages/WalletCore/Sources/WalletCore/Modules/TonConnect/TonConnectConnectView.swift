import Kingfisher
import SwiftUI

struct TonConnectConnectView: View {
    @StateObject private var viewModel: TonConnectConnectViewModel
    @Environment(\.presentationMode) private var presentationMode

    init(config: TonConnectConfig, returnDeepLink: String? = nil) {
        _viewModel = StateObject(wrappedValue: TonConnectConnectViewModel(config: config, returnDeepLink: returnDeepLink))
    }

    var body: some View {
        ThemeNavigationStack {
            ThemeView {
                BottomGradientWrapper {
                    ScrollView {
                        VStack(spacing: .margin24) {
                            HStack(spacing: .margin16) {
                                KFImage.url(viewModel.manifest.iconUrl)
                                    .resizable()
                                    .placeholder { RoundedRectangle(cornerRadius: .cornerRadius16).fill(Color.themeBlade) }
                                    .clipShape(RoundedRectangle(cornerRadius: .cornerRadius16))
                                    .frame(width: 72, height: 72)

                                Text(viewModel.manifest.name).themeHeadline1()
                            }

                            ListSection {
                                Cell(
                                    middle: { ThemeText("ton_connect.connect.url".localized, style: .subhead) },
                                    right: { ThemeText(viewModel.manifest.host, style: .subheadSB) }
                                )

                                if let account = viewModel.account {
                                    Cell(
                                        middle: { ThemeText("ton_connect.connect.wallet".localized, style: .subhead) },
                                        right: {
                                            ThemeText(account.name, style: .subheadSB)
                                                .arrow(style: .dropdown)
                                        },
                                        action: {
                                            Coordinator.shared.present(type: .alert) { isPresented in
                                                OptionAlertView(
                                                    title: "ton_connect.connect.wallet".localized,
                                                    viewItems: viewModel.eligibleAccounts.map { .init(text: $0.name, selected: viewModel.account == $0) },
                                                    onSelect: { index in
                                                        viewModel.account = viewModel.eligibleAccounts[index]
                                                    },
                                                    isPresented: isPresented
                                                )
                                            }
                                        }
                                    )
                                } else {
                                    Cell(
                                        middle: { ThemeText("ton_connect.connect.wallet".localized, style: .subhead) },
                                        right: { ThemeText("ton_connect.connect.no_eligible_wallets".localized, style: .subhead) }
                                    )
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
                        .buttonStyle(PrimaryButtonStyle(style: .yellow))
                        .disabled(viewModel.account == nil)

                        Button(action: {
                            viewModel.rejectConnection()
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("ton_connect.connect.reject".localized)
                        }
                        .buttonStyle(PrimaryButtonStyle(style: .gray))
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
