import Kingfisher
import SwiftUI

struct TonConnectListView: View {
    @StateObject private var viewModel = TonConnectListViewModel()

    var body: some View {
        ThemeView {
            BottomGradientWrapper {
                if viewModel.items.isEmpty {
                    PlaceholderViewNew(icon: "no_data_48", subtitle: "ton_connect.list.no_connected_apps".localized)
                } else {
                    ScrollView {
                        VStack(spacing: .margin24) {
                            ForEach(viewModel.items) { item in
                                VStack(spacing: 0) {
                                    ListSectionHeader(text: item.account.name)
                                    ListSection {
                                        ForEach(item.apps) { app in
                                            ClickableRow(action: {
                                                onClick(app: app)
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
                    Coordinator.shared.present { _ in
                        ScanQrViewNew(reportAfterDismiss: true, pasteEnabled: true) { deeplink in
                            viewModel.handle(deeplink: deeplink)
                        }
                        .ignoresSafeArea()
                    }
                }) {
                    Text("ton_connect.list.new_connection".localized)
                }
                .buttonStyle(PrimaryButtonStyle(style: .yellow))
            }
        }
        .onReceive(viewModel.openCreateConnectionPublisher) { config in
            Coordinator.shared.present { _ in
                TonConnectConnectView(config: config)
            }
        }
        .navigationTitle("TON Connect")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func onClick(app: TonConnectApp) {
        Coordinator.shared.present(type: .bottomSheet) { isPresented in
            BottomSheetView.instance(
                icon: .trash,
                title: "ton_connect.list.disconnect_app".localized,
                items: [
                    .text(text: "ton_connect.list.disconnect_app.description".localized(app.manifest.name)),
                    .buttonGroup(.init(buttons: [
                        .init(style: .red, title: "ton_connect.list.disconnect_app.disconnect".localized) {
                            viewModel.disconnect(app: app)
//                                                                tonConnectApp = nil
                        },
                    ])),
                ],
                isPresented: isPresented
            )
        }
    }
}
