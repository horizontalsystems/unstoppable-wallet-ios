import Kingfisher
import SwiftUI

struct TonConnectListView: View {
    @StateObject private var viewModel = TonConnectListViewModel()

    @State private var qrScanPresented = false
    @State private var connectConfig: TonConnectConfig?
    @State private var tonConnectApp: TonConnectApp?

    var body: some View {
        ThemeView {
            BottomGradientWrapper {
                if viewModel.items.isEmpty {
                    PlaceholderViewNew(image: Image("no_data_48"), text: "ton_connect.list.no_connected_apps".localized)
                } else {
                    ScrollView {
                        VStack(spacing: .margin24) {
                            ForEach(viewModel.items) { item in
                                VStack(spacing: 0) {
                                    ListSectionHeader(text: item.account.name)
                                    ListSection {
                                        ForEach(item.apps) { app in
                                            ClickableRow(action: {
                                                tonConnectApp = app
                                            }) {
                                                KFImage.url(app.manifest.iconUrl)
                                                    .resizable()
                                                    .placeholder { RoundedRectangle(cornerRadius: .cornerRadius4).fill(Color.themeBlade) }
                                                    .clipShape(RoundedRectangle(cornerRadius: .cornerRadius4))
                                                    .frame(width: .iconSize32, height: .iconSize32)

                                                VStack(spacing: 1) {
                                                    Text(app.manifest.name).themeBody()
                                                    Text(app.manifest.host).themeSubhead2()
                                                }

                                                Image.disclosureIcon
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
                    }
                }
            } bottomContent: {
                Button(action: {
                    qrScanPresented = true
                }) {
                    Text("ton_connect.list.new_connection".localized)
                }
                .buttonStyle(PrimaryButtonStyle(style: .yellow))
            }
        }
        .onReceive(viewModel.openCreateConnectionPublisher) { config in
            connectConfig = config
        }
        .sheet(item: $connectConfig) { config in
            TonConnectConnectView(config: config)
        }
        .sheet(isPresented: $qrScanPresented) {
            ScanQrViewNew(reportAfterDismiss: true, pasteEnabled: true) { deeplink in
                viewModel.handle(deeplink: deeplink)
            }
            .ignoresSafeArea()
        }
        .bottomSheet(item: $tonConnectApp) { app in
            BottomSheetView(
                icon: .trash,
                title: "ton_connect.list.disconnect_app".localized,
                items: [
                    .text(text: "ton_connect.list.disconnect_app.description".localized(app.manifest.name)),
                ],
                buttons: [
                    .init(style: .red, title: "ton_connect.list.disconnect_app.disconnect".localized) {
                        viewModel.disconnect(app: app)
                        tonConnectApp = nil
                    },
                ],
                onDismiss: { tonConnectApp = nil }
            )
        }
        .navigationTitle("TON Connect")
        .navigationBarTitleDisplayMode(.inline)
    }
}
