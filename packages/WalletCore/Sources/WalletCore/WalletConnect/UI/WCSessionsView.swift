import Kingfisher
import SwiftUI

struct WCSessionsView: View {
    @StateObject private var viewModel = WCSessionsViewModel()

    var body: some View {
        ThemeView {
            BottomGradientWrapper {
                if viewModel.items.isEmpty {
                    PlaceholderViewNew(icon: "warning_filled", subtitle: "wallet_connect.list.empty_view_text".localized)
                } else {
                    ScrollView {
                        VStack(spacing: .margin16) {
                            ForEach(viewModel.items) { item in
                                ListSection {
                                    // an approved session is never opened as a screen (parity with Android): the row only lists it
                                    Cell(
                                        left: {
                                            KFImage.url(item.iconUrl)
                                                .resizable()
                                                .placeholder { RoundedRectangle(cornerRadius: .cornerRadius8).fill(Color.themeBlade) }
                                                .clipShape(RoundedRectangle(cornerRadius: .cornerRadius8))
                                                .frame(width: .iconSize32, height: .iconSize32)
                                        },
                                        middle: { MultiText(title: item.session.dAppName, subtitle: item.host) },
                                        right: {
                                            Button(action: { disconnect(item: item) }) {
                                                ThemeImage("trash", size: .iconSize20)
                                            }
                                        }
                                    )

                                    ForEach(item.requests) { request in
                                        Cell(
                                            middle: { ThemeText("wallet_connect.list.requests".localized, style: .subhead) },
                                            right: {
                                                ThemeText(request.label, style: .subheadSB)
                                                    .arrow(style: .disclosure)
                                            },
                                            action: { viewModel.open(request: request) }
                                        )
                                    }
                                }
                            }
                        }
                        .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
                    }
                }
            } bottomContent: {
                Button(action: { scan() }) {
                    Text("wallet_connect_list.new_connection".localized)
                }
                .buttonStyle(PrimaryButtonStyle(style: .yellow))
            }
        }
        .onAppear { viewModel.refresh() }
        .navigationTitle("wallet_connect_list.title".localized)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func scan() {
        // the same gate as in WCPresenter.pair, one screen earlier: a watch account never gets the camera
        if let account = Core.shared.accountManager.activeAccount, !account.type.supportsWalletConnect {
            WCPresenter.presentNotSupported(accountType: account.type)
            return
        }

        Coordinator.shared.present { isPresented in
            ScanQrView(reportAfterDismiss: true, isPresented: isPresented) { uri in
                viewModel.pair(uri: uri)
            }
            .ignoresSafeArea()
        }
    }

    private func disconnect(item: WCSessionsViewModel.Item) {
        WCPresenter.presentDisconnect(dAppName: item.session.dAppName, host: item.host, iconUrl: item.iconUrl?.absoluteString) {
            viewModel.disconnect(item: item)
        }
    }
}
